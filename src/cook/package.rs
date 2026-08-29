use std::{
    collections::BTreeSet,
    path::{Path, PathBuf},
};

use pkg::{InstallState, Package, PackageName, PackagePrefix, PackageState};
use pkgar::{PackageFile, Transaction, ext::PackageSrcExt};
use pkgar_core::HeaderFlags;
use pkgar_keys::PublicKeyFile;

use crate::{
    Error, Result,
    config::CookConfig,
    cook::{cook_build::BuildResult, fetch, fs::*, pty::PtyOut},
    log_to_pty,
    recipe::{BuildKind, CookRecipe, OptionalPackageRecipe},
    wrap_io_err,
};

pub fn package(
    recipe: &CookRecipe,
    build_result: &BuildResult,
    cook_config: &CookConfig,
    logger: &PtyOut,
) -> Result<()> {
    let name = &recipe.name;
    let target_dir = &recipe.target_dir();
    let auto_deps = &build_result.auto_deps;
    if recipe.recipe.build.kind == BuildKind::None {
        // metapackages don't have stage dir and optional packages
        package_toml(
            target_dir.join("stage.toml"),
            recipe,
            None,
            None,
            recipe.recipe.package.dependencies.clone(),
            &auto_deps,
        )?;
        return Ok(());
    }

    let secret_path = "build/id_ed25519.toml";
    let public_path = "build/id_ed25519.pub.toml";
    // E-OS V2-MS12. Upstream silently mints a fresh package-signing keypair whenever
    // build/id_ed25519.toml is absent. That is convenient for a first build and dangerous
    // afterwards: `build/` is deleted routinely (make clean, moving the volume, a dead disk),
    // and the regenerated key is a DIFFERENT identity. Every package then goes out signed by
    // a key no client has ever seen, pkgar has no keyring and no revocation list (R-711), and
    // nothing in the build says a word about it. The key that signed the published packages
    // lived in exactly one place, with no backup, until this landed.
    //
    // So: record the expected public key in the repository (keys/eos-pkg-signing.pub.toml --
    // the PUBLIC half only) and make the two dangerous transitions loud.
    let expected_path = Path::new("keys/eos-pkg-signing.pub.toml");
    let recorded = if expected_path.is_file() {
        Some(PublicKeyFile::open(expected_path)?.pkey)
    } else {
        None
    };

    if !Path::new(secret_path).is_file() || !Path::new(public_path).is_file() {
        if let Some(expected) = recorded {
            // A key is expected but the private half is gone. Minting a new one here would
            // publish packages under a new identity and break every client that already
            // trusts the old one -- refuse instead, and say how to recover.
            return Err(Error::from(format!(
                "package-signing key is MISSING but keys/eos-pkg-signing.pub.toml expects {}.\n\
                 Refusing to mint a replacement: that would re-key every package silently and \
                 break clients that already trust the recorded key (pkgar has no revocation).\n\
                 Restore build/id_ed25519.toml from the operator's off-repo copy, or -- if the \
                 key is genuinely gone -- delete keys/eos-pkg-signing.pub.toml deliberately, \
                 rebuild, and re-publish (see ROADMAP-v2 V2-MS12).",
                hex_pkey(&expected)
            )));
        }
        if !Path::new("build").is_dir() {
            create_dir(Path::new("build"))?;
        }
        let (public_key, secret_key) = pkgar_keys::SecretKeyFile::new();
        public_key.save(public_path)?;
        secret_key.save(secret_path)?;
        log_to_pty!(
            logger,
            "V2-MS12: minted a NEW package-signing key at {} -- back it up off-repo NOW and \
             record its public half as keys/eos-pkg-signing.pub.toml, or the next `build/` wipe \
             loses the identity every published package was signed with.",
            secret_path
        );
    }
    // Note what the record says; the comparison happens AFTER signing, against the key that
    // was actually used. Checking build/id_ed25519.pub.toml here instead would be theatre:
    // packages are signed with the SECRET half, so swapping only the public file would sail
    // straight through and every package would still go out under the wrong identity.
    let expected_pkey = recorded;

    let packages = recipe.recipe.get_packages_list();

    for package in packages {
        let (stage_dir, package_file, package_meta) = package_stage_paths(package, target_dir);
        // Rebuild package if stage is newer
        if package_file.is_file() && !build_result.cached {
            log_to_pty!(logger, "DEBUG: updating '{}'", package_file.display());
            remove_all(&package_file)?;
            if package_meta.is_file() {
                remove_all(&package_meta)?;
            }
        }

        if !package_file.is_file() {
            pkgar::create_with_flags(
                secret_path,
                package_file.to_str().unwrap(),
                stage_dir.to_str().unwrap(),
                HeaderFlags::latest(
                    pkgar_core::Architecture::Independent,
                    match cook_config.compressed {
                        true => pkgar_core::Packaging::LZMA2,
                        false => pkgar_core::Packaging::Uncompressed,
                    },
                ),
            )?;

            // V2-MS12: check what the package was ACTUALLY signed with, by reading the key out
            // of the header pkgar just wrote. This is the only honest place for the comparison
            // -- signing uses the secret half, so inspecting build/id_ed25519.pub.toml instead
            // would pass even when the two halves disagree.
            if let Some(expected) = expected_pkey {
                let mut header = [0u8; 96];
                let mut f = std::fs::File::open(&package_file)
                    .map_err(|e| Error::from_io_error(e, "Opening the package just written"))?;
                std::io::Read::read_exact(&mut f, &mut header)
                    .map_err(|e| Error::from_io_error(e, "Reading the pkgar header"))?;
                // pkgar header layout: signature[64] || public_key[32] || ...
                if header[64..96] != expected[..] {
                    return Err(Error::from(format!(
                        "package {} was signed with {} but keys/eos-pkg-signing.pub.toml \
                         records {}.\n\
                         Every client fetching this repository would get packages under an \
                         identity the project does not claim. Restore the recorded key, or \
                         change the record deliberately and re-publish.",
                        package_file.display(),
                        hex_pkey(&header[64..96]),
                        hex_pkey(&expected)
                    )));
                }
            }
        }

        let deps = if package.is_some() {
            BTreeSet::from([name.with_prefix(PackagePrefix::Any)])
        } else {
            auto_deps.clone()
        };

        if !package_meta.is_file() {
            let name = match package {
                Some(p) => PackageName::new(format!("{}.{}", name.name(), p.name))?,
                None => name.clone(),
            };
            let package_deps = match package {
                Some(p) => p
                    .dependencies
                    .iter()
                    .map(|dep| {
                        if dep.name().is_empty() {
                            name.with_suffix(dep.suffix())
                        } else {
                            dep.clone()
                        }
                    })
                    .collect(),
                None => recipe.recipe.package.dependencies.clone(),
            };
            package_toml(
                package_meta,
                recipe,
                Some((Path::new(public_path), &package_file)),
                package,
                package_deps,
                &deps,
            )?;
        }
    }

    Ok(())
}

pub fn package_toml(
    toml_path: PathBuf,
    recipe: &CookRecipe,
    package_file: Option<(&Path, &PathBuf)>,
    package_suffix: Option<&OptionalPackageRecipe>,
    mut package_deps: Vec<PackageName>,
    auto_deps: &BTreeSet<PackageName>,
) -> Result<()> {
    for dep in auto_deps.iter() {
        if !package_deps.contains(dep) {
            package_deps.push(dep.clone());
        }
    }

    let (hash, network_size, storage_size) = if let Some((pkey_path, archive_path)) = package_file {
        use pkgar_core::PackageSrc;
        let pkey = pkgar_keys::PublicKeyFile::open(pkey_path)?.pkey;
        let mut package = pkgar::PackageFile::new(archive_path, &pkey)?;
        let mt = std::fs::metadata(archive_path)
            .map_err(wrap_io_err!(archive_path, "Reading metadata"))?;
        let package_size = mt.len();
        let header = package.header();
        let storage_size = match header.flags.packaging() {
            pkgar_core::Packaging::LZMA2 => {
                let mut size = header
                    .total_size()
                    .map_err(|e| Error::Pkgar(pkgar::Error::Core(e)))?
                    as u64;
                let entries = package.read_entries()?;
                for entry in entries {
                    let data_reader = package.data_reader(&entry)?;
                    size += data_reader.unpacked_size;
                    package.restore_reader(data_reader.into_inner())?;
                }
                size
            }
            _ => package_size,
        };

        (
            blake3::Hash::from_bytes(package.header().blake3)
                .to_hex()
                .to_string(),
            package_size,
            storage_size,
        )
    } else {
        ("".into(), 0, 0)
    };

    let ident_source = fetch::fetch_get_source_info(recipe)?;

    let package = Package {
        name: PackageName::new(get_package_name(
            recipe.name.without_prefix(),
            package_suffix,
        ))
        .unwrap(),
        version: recipe.guess_version().unwrap_or("TODO".into()),
        target: recipe.target.to_string(),
        blake3: hash,
        network_size,
        storage_size,
        depends: package_deps,
        commit_identifier: ident_source.commit_identifier,
        source_identifier: ident_source.source_identifier,
        time_identifier: ident_source.time_identifier,
        ..Default::default()
    };

    serialize_and_write(&toml_path, &package)?;
    return Ok(());
}

pub fn package_target(name: &PackageName) -> &'static str {
    if name.is_host() {
        redoxer::host_target()
    } else {
        redoxer::target()
    }
}

pub fn package_stage_paths(
    package: Option<&OptionalPackageRecipe>,
    target_dir: &Path,
) -> (PathBuf, PathBuf, PathBuf) {
    let mut target_dir = target_dir.to_path_buf();
    if let Some(cross_target) = crate::cross_target() {
        // TODO: automatically pass COOKBOOK_CROSS_GNU_TARGET?
        target_dir = target_dir.join(cross_target)
    }
    package_name_paths(package, &target_dir, "stage")
}

pub fn package_source_paths(
    package: Option<&OptionalPackageRecipe>,
    target_dir: &Path,
) -> (PathBuf, PathBuf, PathBuf) {
    package_name_paths(package, target_dir, "source")
}

fn package_name_paths(
    package: Option<&OptionalPackageRecipe>,
    target_dir: &Path,
    name: &str,
) -> (PathBuf, PathBuf, PathBuf) {
    let prefix_name = get_package_name(name, package);
    let package_stage = target_dir.join(&prefix_name);
    let package_file = package_stage.with_added_extension("pkgar");
    let package_meta = package_stage.with_added_extension("toml");
    (package_stage, package_file, package_meta)
}

pub fn get_package_name(name: &str, package: Option<&OptionalPackageRecipe>) -> String {
    get_package_name_inner(name, package.map(|p| p.name.as_str()))
}

fn get_package_name_inner(name: &str, package: Option<&str>) -> String {
    let mut prefix_name = name.to_string();
    if let Some(package) = package {
        prefix_name.push('.');
        prefix_name.push_str(package);
    }
    prefix_name
}

pub fn package_handle_push(
    state: &mut PackageState,
    archive_path: &Path,
    sysroot_dir: &Path,
    reinstall: bool,
) -> crate::Result<bool> {
    let archive_toml = archive_path.with_extension("toml");
    let pkey_path = "build/id_ed25519.pub.toml";
    let pkg_toml = Package::from_file(&archive_toml)?;
    // "local" is what remote name from installer is hardcoded into
    let remote_name = "local".to_string();
    let (cached, pstate) = match state.installed.get(&pkg_toml.name) {
        Some(s) if !reinstall && pkg_toml.blake3 == s.blake3 => (true, None),
        Some(s) => (false, Some((s.manual, s.dependents.clone()))),
        None => {
            // TODO: Handle manual & dependents
            (false, Some((true, BTreeSet::new())))
        }
    };

    if let Some((manual, dependents)) = pstate {
        if archive_path.is_file() {
            let pkey = PublicKeyFile::open(pkey_path)?.pkey;
            let mut package = PackageFile::new(archive_path, &pkey)?;
            Transaction::install(&mut package, sysroot_dir)?.commit()?;
            let head_path = sysroot_dir.join(format!(
                "var/lib/packages/{}.pkgar_head",
                pkg_toml.name.as_str()
            ));
            package.split(&head_path, None::<&Path>)?;
        }

        // TODO: Check if we need to inject remote key
        let install_state = InstallState::from_package(&pkg_toml, remote_name, manual, dependents);
        state.installed.insert(pkg_toml.name.clone(), install_state);
    }

    Ok(cached)
}

/// Render an Ed25519 public key as hex, so a key-mismatch message names both keys instead of
/// leaving the operator to work out which one is in play.
fn hex_pkey(key: &[u8]) -> String {
    key.iter().map(|b| format!("{b:02x}")).collect()
}
