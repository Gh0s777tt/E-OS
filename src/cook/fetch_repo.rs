use std::{
    cell::RefCell,
    io::{PipeWriter, Write},
    path::{Path, PathBuf},
    rc::Rc,
    time::Duration,
};

use crate::cook::fs;
use pkg::{
    PackageName, RemotePackage, RepoManager, RepoPublicKeyFile, Repository,
    callback::{Callback, PlainCallback, SilentCallback},
    net_backend::{CurlBackend, DownloadBackend},
};

// TODO: This is a workaround, but as long as whole
// fetch operation is in single thread, this is ok
thread_local! {
static BINARY_REPO: RefCell<Option<(RepoManager, Repository)>> = RefCell::new(None);
}

fn load_cached_repo(path: &Path) -> Option<Repository> {
    let metadata = std::fs::metadata(path).ok()?;

    if !crate::config::get_config().cook.offline {
        let stale_time = std::time::SystemTime::now().checked_sub(Duration::from_secs(8 * 3600))?;
        if metadata.modified().ok()? < stale_time {
            // stale cache
            let _ = std::fs::remove_file(path);
            return None;
        }
    }

    let toml_str = std::fs::read_to_string(path).ok()?;
    Repository::from_toml(&toml_str).ok()
}

/// Path of the pinned copy of upstream's package-signing key, relative to the repository root.
const UPSTREAM_PUBKEY_PIN: &str = "keys/upstream-redox-pkg.pub.toml";

/// Install the pinned upstream package-signing key, replacing trust-on-first-use.
///
/// WHY THIS EXISTS. `RepoManager::sync_keys()` downloads the signing key from the same host that
/// serves the packages and caches it at `build/remotes/pub_key_<host>.toml`. Nothing compared that
/// key with anything. 30 of the 65 packages in a shipped image are prebuilt binaries fetched from
/// that host, so whoever controlled it supplied both the packages and the key that "verified" them.
///
/// TWO THINGS ARE NEEDED, not one. Setting `remote.pubkey` makes `sync_keys()` skip the download
/// (`repo_manager.rs:313` short-circuits on `pubkey.is_some()`), but the in-memory value is not what
/// guards extraction: `cook/cook_build.rs:718` hardcodes the *file* path and hands it to
/// `pkgar::extract` at line 748. So the pinned bytes are also written to that file, unconditionally
/// on every run — which is what stops a cache poisoned by an earlier build from surviving.
///
/// ON BOOTSTRAP, HONESTLY. A pin cannot prove the key was ever the right one; it can only stop it
/// changing unnoticed. This value was corroborated from four independent witnesses before it was
/// committed — the live host, this tree's pre-existing cache, and archived snapshots from 2023 and
/// 2024, all byte-identical. That is evidence, not proof, and `keys/README.md` says so.
fn pin_upstream_key(repo: &mut RepoManager, repo_path: &Path) {
    let pin = RepoPublicKeyFile::open(UPSTREAM_PUBKEY_PIN).unwrap_or_else(|err| {
        panic!(
            "{UPSTREAM_PUBKEY_PIN}: cannot read the pinned upstream package key ({err}).\n\
             Refusing to fall back on a key downloaded from the host that serves the packages.\n\
             If upstream rotated its key, verify the new value from more than one source and \
             update the pin in its own commit."
        )
    });

    // std::fs here, not crate::cook::fs: the local module has create_dir (single level) but the
    // remotes directory may not have a parent yet on a clean tree.
    if let Err(err) = std::fs::create_dir_all(repo_path) {
        panic!(
            "{}: cannot create the remotes directory ({err})",
            repo_path.display()
        );
    }

    for (_, remote) in repo.remote_map.iter_mut() {
        // The file is the gate, not the struct. Derive its name the way pkg-lib does
        // (`pub_key_<remote name>.toml`) rather than repeating a literal that would silently stop
        // matching if the remote ever moved; `REMOTE_PKG_PUBKEY_CACHE` is checked against this in
        // the tests below.
        let cached = repo_path.join(pubkey_cache_name(&remote.name));
        if let Err(err) = RepoPublicKeyFile::new(pin.pkey).save(&cached) {
            panic!("{}: cannot write the pinned upstream key ({err})", cached.display());
        }

        // And the struct, so sync_keys() never reaches for the network.
        if remote.pubkey.is_none() {
            remote.pubkey = Some(pin.pkey);
        }
    }
}

/// File name pkg-lib caches a remote's signing key under, kept identical to `repo_manager.rs`.
fn pubkey_cache_name(remote_name: &str) -> String {
    format!("pub_key_{remote_name}.toml")
}

fn init_binary_repo() -> (RepoManager, Repository) {
    let callback = Rc::new(RefCell::new(SilentCallback::new()));
    let download_backend = CurlBackend::new().expect("Curl not found");
    let mut repo = RepoManager::new(callback, Box::new(download_backend));
    let target = redoxer::target();
    repo.add_remote(crate::REMOTE_PKG_SOURCE, target)
        .expect("Unable to add remote");

    let repo_path = PathBuf::from(crate::REMOTE_PKG_DIR);
    repo.set_download_path(repo_path.clone());
    pin_upstream_key(&mut repo, &repo_path);
    repo.sync_keys().expect("Unable to sync keys");

    let repo_toml = load_cached_repo(&repo_path.join(format!("{target}_repo.toml")))
        .unwrap_or_else(|| {
            let repo = download_repo(&repo, repo_path)
                .map_err(|e| {
                    eprintln!(
                        "Unable to load server repo.toml, all recipes will build from source: {e}"
                    );
                    e
                })
                .unwrap_or_default();
            repo
        });
    // reset here to not clobber pty
    repo.callback = Rc::new(RefCell::new(PlainCallback::new()));
    (repo, repo_toml)
}

fn download_repo(repo: &RepoManager, repo_path: PathBuf) -> crate::Result<Repository> {
    let (toml_str, _) = repo.get_package_toml(&PackageName::new("repo").unwrap())?;
    let repo = Repository::from_toml(&toml_str)?;
    let target = redoxer::target();
    fs::serialize_and_write(&repo_path.join(format!("{target}_repo.toml")), &repo)?;
    Ok(repo)
}

pub fn get_binary_repo() -> (RepoManager, Repository) {
    BINARY_REPO.with(|cell| {
        let mut opt = cell.borrow_mut();
        if opt.is_none() {
            *opt = Some(init_binary_repo());
        }
        let (repo, repo_toml) = opt.as_ref().unwrap();
        ((*repo).clone(), repo_toml.clone())
    })
}

pub struct PlainPtyCallback {
    size: u64,
    unknown_size: bool,
    pos: u64,
    fetch_processed: usize,
    fetch_total: usize,
    interactive: bool,
    download_file: Option<String>,
    pty: PipeWriter,
}

impl PlainPtyCallback {
    pub fn new(pty: PipeWriter) -> Self {
        Self {
            size: 0,
            unknown_size: false,
            pos: 0,
            fetch_processed: 0,
            fetch_total: 0,
            interactive: false,
            download_file: None,
            pty,
        }
    }

    /// Set if user require to agree on terminal
    pub fn set_interactive(&mut self, enabled: bool) {
        self.interactive = enabled;
    }

    fn flush(&self) {
        let _ = std::io::stderr().flush();
    }

    pub fn format_size(bytes: u64) -> String {
        if bytes == 0 {
            return "0 B".to_string();
        }
        const UNITS: [&str; 5] = ["B", "KiB", "MiB", "GiB", "TiB"];
        let i = (bytes as f64).log(1024.0).floor() as usize;
        let size = bytes as f64 / 1024.0_f64.powi(i as i32);
        format!("{:.2} {}", size, UNITS[i])
    }

    fn downloading_str(&self) -> &'static str {
        "Downloading"
    }
}

const RESET_LINE: &str = "\r\x1b[2K";

impl Callback for PlainPtyCallback {
    fn fetch_start(&mut self, initial_count: usize) {
        self.fetch_total = 0;
        self.fetch_processed = 0;
        self.fetch_package_increment(0, initial_count);
    }

    fn fetch_package_name(&mut self, pkg_name: &PackageName) {
        // resuming after fetch_package_increment
        let _ = write!(&self.pty, " {}", pkg_name.as_str());
        self.flush();
    }

    fn fetch_package_increment(&mut self, added_processed: usize, added_count: usize) {
        self.fetch_processed += added_processed;
        self.fetch_total += added_count;

        let _ = write!(
            &self.pty,
            "{RESET_LINE}Fetching: [{}/{}]",
            self.fetch_processed, self.fetch_total
        );
        self.flush();
    }

    fn fetch_end(&mut self) {
        if self.fetch_processed == self.fetch_total {
            let _ = writeln!(&self.pty, "{RESET_LINE}Fetch complete.");
        } else {
            let _ = writeln!(&self.pty, "{RESET_LINE}Fetch incomplete.");
        }
    }

    fn download_start(&mut self, length: u64, file: &str) {
        self.size = length;
        self.unknown_size = length == 0;
        self.pos = 0;
        if !self.unknown_size {
            let _ = write!(&self.pty, "{RESET_LINE}{} {file}", self.downloading_str());
            self.download_file = Some(file.to_string());
            self.flush();
        }
    }

    fn download_increment(&mut self, downloaded: u64) {
        self.pos += downloaded;
        if self.unknown_size {
            self.size += downloaded;
        }
        if self.unknown_size {
            return;
        }

        // keep using MB for consistency
        let pos_mb = self.pos as f64 / 1_048_576.0;
        let size_mb = self.size as f64 / 1_048_576.0;
        let file_name = self
            .download_file
            .as_ref()
            .map(|s| s.as_str())
            .unwrap_or("");
        let _ = write!(
            &self.pty,
            "{RESET_LINE}{} {} [{:.2} MB / {:.2} MB]",
            self.downloading_str(),
            file_name,
            pos_mb,
            size_mb
        );
        self.flush();
    }

    fn download_end(&mut self) {
        if !self.unknown_size {
            let _ = writeln!(&self.pty, "");
            self.download_file = None;
        }
    }

    fn install_extract(&mut self, remote_pkg: &RemotePackage) {
        let _ = writeln!(&self.pty, "Extracting {}...", remote_pkg.package.name);
        self.flush();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Build a manager carrying the real upstream remote, with no network traffic: `add_remote`
    /// only parses the URL.
    fn manager() -> RepoManager {
        let callback = Rc::new(RefCell::new(SilentCallback::new()));
        let backend = CurlBackend::new().expect("curl not found");
        let mut repo = RepoManager::new(callback, Box::new(backend));
        repo.add_remote(crate::REMOTE_PKG_SOURCE, "x86_64-unknown-redox")
            .expect("add_remote");
        repo
    }

    fn scratch(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(name);
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).expect("create scratch dir");
        dir
    }

    /// The pin is only worth anything if it lands on the file `cook_build` actually reads. That
    /// path is a constant, while the written one is derived from the remote host, so a change to
    /// `REMOTE_PKG_SOURCE` that left the constant behind would quietly restore the download-and-
    /// trust behaviour this whole function exists to remove. Fail here instead.
    #[test]
    fn pinned_file_is_the_one_cook_build_reads() {
        let repo = manager();
        let host = repo
            .remote_map
            .values()
            .next()
            .expect("one remote")
            .name
            .clone();
        let derived = Path::new(crate::REMOTE_PKG_DIR).join(pubkey_cache_name(&host));
        assert_eq!(
            derived,
            Path::new(crate::REMOTE_PKG_PUBKEY_CACHE),
            "the pinned key is written to {derived:?} but cook_build reads \
             {:?}; update REMOTE_PKG_PUBKEY_CACHE to follow REMOTE_PKG_SOURCE",
            crate::REMOTE_PKG_PUBKEY_CACHE
        );
    }

    /// The regression that matters: an earlier build (or anyone with write access to the build
    /// tree) leaves a hostile key in the cache. Pinning must overwrite it every run, not skip the
    /// write because a file is already there.
    #[test]
    fn pin_overwrites_a_poisoned_cache() {
        let dir = scratch("eos_test_pin_overwrites_a_poisoned_cache");
        let mut repo = manager();
        let cached = dir.join(pubkey_cache_name("static.redox-os.org"));
        std::fs::write(&cached, format!("pkey = \"{}\"\n", "de".repeat(32))).expect("poison");

        pin_upstream_key(&mut repo, &dir);

        let expect = RepoPublicKeyFile::open(UPSTREAM_PUBKEY_PIN).expect("read pin");
        let got = RepoPublicKeyFile::open(&cached).expect("read cache");
        assert_eq!(got.pkey, expect.pkey, "the poisoned key survived pinning");
    }

    /// Writing the file is half of it; without this the manager still downloads a key over the
    /// network and overwrites what we just wrote.
    #[test]
    fn pin_sets_the_key_on_every_remote() {
        let dir = scratch("eos_test_pin_sets_the_key_on_every_remote");
        let mut repo = manager();
        assert!(
            repo.remote_map.values().all(|r| r.pubkey.is_none()),
            "precondition: a fresh manager holds no key"
        );

        pin_upstream_key(&mut repo, &dir);

        assert!(
            repo.remote_map.values().all(|r| r.pubkey.is_some()),
            "a remote was left without a key, so sync_keys() would still fetch one"
        );
    }
}
