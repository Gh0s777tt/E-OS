//! E-OS R-503 — hybrid classical + post-quantum signatures for the pkgar repo.
//!
//! The package repo's `repo.toml` lists every package's blake3 hash, so a
//! signature over it authenticates the whole repository. Today that trust
//! anchor is ed25519 (pkgar). This tool prototypes the migration to a **hybrid**
//! signature — ed25519 **and** ML-DSA-65 (FIPS 204) — so a future quantum
//! adversary can't forge the repo while classical-only verifiers keep working.
//!
//! Subcommands:
//!   keygen <secret.toml> <public.toml>          generate both keypairs
//!   sign   <secret.toml> <file>                 write <file>.sig (hybrid)
//!   verify <public.toml> <file> [--classical-only]   verify the signature(s)
//!
//! Keys and signatures are stored as hex in flat TOML-ish text so the format is
//! trivially auditable and needs no extra dependencies.

use std::process::exit;

use ed25519_dalek::{
    Signature as EdSignature, Signer as _, SigningKey as EdSigningKey,
    VerifyingKey as EdVerifyingKey,
};
use ml_dsa::{
    signature::{Keypair as _, Signer as _, Verifier as _},
    EncodedSignature, EncodedVerifyingKey, Generate, MlDsa65, Signature as PqSignature,
    SigningKey as PqSigningKey, VerifyingKey as PqVerifyingKey, B32,
};
use rand_core::OsRng;

const SIG_VERSION: u32 = 1;

fn hex_encode(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{:02x}", b));
    }
    s
}

fn hex_decode(s: &str) -> Result<Vec<u8>, String> {
    // Operate on bytes, not char slices: `&s[i..i+2]` panics on a multi-byte
    // UTF-8 char at an odd boundary, and this parses attacker-controlled .sig text.
    let b = s.trim().as_bytes();
    if !b.len().is_multiple_of(2) {
        return Err("odd-length hex".into());
    }
    let nib = |c: u8| -> Result<u8, String> {
        match c {
            b'0'..=b'9' => Ok(c - b'0'),
            b'a'..=b'f' => Ok(c - b'a' + 10),
            b'A'..=b'F' => Ok(c - b'A' + 10),
            _ => Err(format!("invalid hex byte 0x{c:02x}")),
        }
    };
    (0..b.len())
        .step_by(2)
        .map(|i| Ok((nib(b[i])? << 4) | nib(b[i + 1])?))
        .collect()
}

/// Read `key = "value"` pairs from a flat text file.
fn parse_kv(text: &str) -> std::collections::BTreeMap<String, String> {
    let mut map = std::collections::BTreeMap::new();
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') || line.starts_with('[') {
            continue;
        }
        if let Some((k, v)) = line.split_once('=') {
            let v = v.trim().trim_matches('"').trim();
            map.insert(k.trim().to_string(), v.to_string());
        }
    }
    map
}

fn get<'a>(
    map: &'a std::collections::BTreeMap<String, String>,
    key: &str,
) -> Result<&'a str, String> {
    map.get(key)
        .map(|s| s.as_str())
        .ok_or_else(|| format!("missing field '{key}'"))
}

fn die(msg: impl AsRef<str>) -> ! {
    eprintln!("eos-repo-sign: {}", msg.as_ref());
    exit(1)
}

/// Create `path` refusing to clobber an existing file (`create_new` — atomic,
/// no TOCTOU window). `owner_only` restricts the file to `0600` on Unix *at
/// creation* — a secret key must never transit through a world-readable state
/// (the default umask usually yields 0644). On non-Unix hosts the mode bits
/// don't exist; `create_new` still applies.
fn write_new_key_file(path: &str, contents: &str, owner_only: bool) -> std::io::Result<()> {
    use std::io::Write as _;
    let mut opts = std::fs::OpenOptions::new();
    opts.write(true).create_new(true);
    #[cfg(unix)]
    if owner_only {
        use std::os::unix::fs::OpenOptionsExt as _;
        opts.mode(0o600);
    }
    #[cfg(not(unix))]
    let _ = owner_only;
    let mut f = opts.open(path)?;
    f.write_all(contents.as_bytes())
}

fn keygen(secret_path: &str, public_path: &str) {
    // Refuse to overwrite before generating anything: silently rotating the
    // repo-signing key would strand every client pinning the old public key.
    for p in [secret_path, public_path] {
        if std::path::Path::new(p).exists() {
            die(format!(
                "refusing to overwrite existing {p} — move it away first if you really mean to rotate keys"
            ));
        }
    }

    // ed25519 (classical)
    let ed_sk = EdSigningKey::generate(&mut OsRng);
    let ed_vk = ed_sk.verifying_key();

    // ML-DSA-65 (post-quantum). Store the 32-byte seed as the secret so the key
    // is deterministically reproducible.
    let pq_sk = PqSigningKey::<MlDsa65>::generate();
    let pq_vk = pq_sk.verifying_key();
    let pq_seed: &B32 = pq_sk.as_seed();

    let secret = format!(
        "# E-OS repo signing SECRET keys — keep OFF-REPO, back up securely.\n\
         [secret_keys]\n\
         ed25519 = \"{}\"\n\
         ml_dsa_65_seed = \"{}\"\n",
        hex_encode(ed_sk.to_bytes().as_slice()),
        hex_encode(pq_seed.as_slice()),
    );
    let public = format!(
        "# E-OS repo signing PUBLIC keys — ship with the repo/verifier.\n\
         [public_keys]\n\
         ed25519 = \"{}\"\n\
         ml_dsa_65 = \"{}\"\n",
        hex_encode(ed_vk.to_bytes().as_slice()),
        hex_encode(pq_vk.encode().as_slice()),
    );

    write_new_key_file(secret_path, &secret, true)
        .unwrap_or_else(|e| die(format!("write {secret_path}: {e}")));
    write_new_key_file(public_path, &public, false)
        .unwrap_or_else(|e| die(format!("write {public_path}: {e}")));
    println!("eos-repo-sign: wrote secret keys -> {secret_path}");
    println!("eos-repo-sign: wrote public keys -> {public_path}");
    println!(
        "  ed25519 public key:   {} bytes\n  ml-dsa-65 public key: {} bytes",
        ed_vk.to_bytes().len(),
        pq_vk.encode().len()
    );
}

fn sign(secret_path: &str, file_path: &str) {
    let secret_text = std::fs::read_to_string(secret_path)
        .unwrap_or_else(|e| die(format!("read {secret_path}: {e}")));
    let sk = parse_kv(&secret_text);

    let ed_bytes = hex_decode(get(&sk, "ed25519").unwrap_or_else(|e| die(e)))
        .unwrap_or_else(|e| die(format!("ed25519 secret: {e}")));
    let ed_arr: [u8; 32] = ed_bytes
        .as_slice()
        .try_into()
        .unwrap_or_else(|_| die("ed25519 secret must be 32 bytes"));
    let ed_sk = EdSigningKey::from_bytes(&ed_arr);

    let seed_bytes = hex_decode(get(&sk, "ml_dsa_65_seed").unwrap_or_else(|e| die(e)))
        .unwrap_or_else(|e| die(format!("ml-dsa seed: {e}")));
    let seed = B32::try_from(seed_bytes.as_slice())
        .unwrap_or_else(|_| die("ml-dsa seed must be 32 bytes"));
    let pq_sk = PqSigningKey::<MlDsa65>::from_seed(&seed);

    let msg = std::fs::read(file_path).unwrap_or_else(|e| die(format!("read {file_path}: {e}")));

    let ed_sig: EdSignature = ed_sk.sign(&msg);
    let pq_sig: PqSignature<MlDsa65> = pq_sk.sign(&msg);

    // Publish the file NAME, not the path: this header ships to GitHub Pages, and the full
    // path leaked the operator's private temp directory (and the fact that publishing ran from
    // macOS rather than the build container) into a world-readable artefact.
    let sig_subject = std::path::Path::new(&file_path)
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| file_path.to_string());
    let out = format!(
        "# E-OS hybrid signature for {sig_subject}\n\
         [hybrid_signature]\n\
         version = {SIG_VERSION}\n\
         algorithms = [\"ed25519\", \"ml-dsa-65\"]\n\
         ed25519 = \"{}\"\n\
         ml_dsa_65 = \"{}\"\n",
        hex_encode(&ed_sig.to_bytes()),
        hex_encode(pq_sig.encode().as_slice()),
    );
    let sig_path = format!("{file_path}.sig");
    std::fs::write(&sig_path, out).unwrap_or_else(|e| die(format!("write {sig_path}: {e}")));
    println!("eos-repo-sign: signed {file_path} ({} bytes)", msg.len());
    println!(
        "  ed25519 signature:   {} bytes\n  ml-dsa-65 signature: {} bytes\n  -> {sig_path}",
        ed_sig.to_bytes().len(),
        pq_sig.encode().len(),
    );
}

fn verify(public_path: &str, file_path: &str, classical_only: bool) {
    let pub_text = std::fs::read_to_string(public_path)
        .unwrap_or_else(|e| die(format!("read {public_path}: {e}")));
    let pk = parse_kv(&pub_text);

    let sig_path = format!("{file_path}.sig");
    let sig_text =
        std::fs::read_to_string(&sig_path).unwrap_or_else(|e| die(format!("read {sig_path}: {e}")));
    let sig = parse_kv(&sig_text);

    let msg = std::fs::read(file_path).unwrap_or_else(|e| die(format!("read {file_path}: {e}")));

    // ---- ed25519 (classical) — always checked ----
    let ed_vk_bytes = hex_decode(get(&pk, "ed25519").unwrap_or_else(|e| die(e)))
        .unwrap_or_else(|e| die(format!("ed25519 pubkey: {e}")));
    let ed_vk_arr: [u8; 32] = ed_vk_bytes
        .as_slice()
        .try_into()
        .unwrap_or_else(|_| die("ed25519 pubkey must be 32 bytes"));
    let ed_vk = EdVerifyingKey::from_bytes(&ed_vk_arr)
        .unwrap_or_else(|e| die(format!("ed25519 pubkey: {e}")));
    let ed_sig_bytes = hex_decode(get(&sig, "ed25519").unwrap_or_else(|e| die(e)))
        .unwrap_or_else(|e| die(format!("ed25519 sig: {e}")));
    let ed_sig_arr: [u8; 64] = ed_sig_bytes
        .as_slice()
        .try_into()
        .unwrap_or_else(|_| die("ed25519 sig must be 64 bytes"));
    let ed_sig = EdSignature::from_bytes(&ed_sig_arr);
    // verify_strict: reject non-canonical S and small-order/mixed-order edge
    // cases — the recommended API for an authentication trust anchor.
    let ed_ok = ed_vk.verify_strict(&msg, &ed_sig).is_ok();
    println!(
        "ed25519 (classical):  {}",
        if ed_ok { "OK" } else { "FAIL" }
    );

    let mut pq_ok = true;
    if classical_only {
        println!("ml-dsa-65 (PQ):        SKIPPED (--classical-only; backward-compatible verifier)");
    } else {
        // ---- ML-DSA-65 (post-quantum) ----
        let pq_vk_bytes = hex_decode(get(&pk, "ml_dsa_65").unwrap_or_else(|e| die(e)))
            .unwrap_or_else(|e| die(format!("ml-dsa pubkey: {e}")));
        let pq_vk_enc = EncodedVerifyingKey::<MlDsa65>::try_from(pq_vk_bytes.as_slice())
            .unwrap_or_else(|_| die("ml-dsa pubkey wrong length"));
        let pq_vk = PqVerifyingKey::<MlDsa65>::decode(&pq_vk_enc);
        let pq_sig_bytes = hex_decode(get(&sig, "ml_dsa_65").unwrap_or_else(|e| die(e)))
            .unwrap_or_else(|e| die(format!("ml-dsa sig: {e}")));
        let pq_sig_enc = EncodedSignature::<MlDsa65>::try_from(pq_sig_bytes.as_slice())
            .unwrap_or_else(|_| die("ml-dsa sig wrong length"));
        let pq_sig = match PqSignature::<MlDsa65>::decode(&pq_sig_enc) {
            Some(s) => s,
            None => die("ml-dsa sig malformed"),
        };
        pq_ok = pq_vk.verify(&msg, &pq_sig).is_ok();
        println!(
            "ml-dsa-65 (PQ):        {}",
            if pq_ok { "OK" } else { "FAIL" }
        );
    }

    if ed_ok && pq_ok {
        println!("VERIFIED: {file_path}");
    } else {
        die("verification FAILED");
    }
}

#[cfg(test)]
mod tests {
    use super::{get, hex_decode, hex_encode, parse_kv};

    #[test]
    fn hex_roundtrip() {
        let data = [0x00u8, 0x0f, 0x10, 0xff, 0xa5, 0x5a];
        let hex = hex_encode(&data);
        assert_eq!(hex, "000f10ffa55a");
        assert_eq!(hex_decode(&hex).unwrap(), data);
    }

    #[test]
    fn hex_decode_empty_is_ok() {
        assert_eq!(hex_decode("").unwrap(), Vec::<u8>::new());
    }

    #[test]
    fn hex_decode_accepts_uppercase_and_surrounding_whitespace() {
        assert_eq!(
            hex_decode("  DEADbeef\n").unwrap(),
            [0xde, 0xad, 0xbe, 0xef]
        );
    }

    #[test]
    fn hex_decode_rejects_odd_length() {
        assert!(hex_decode("abc").is_err());
    }

    #[test]
    fn hex_decode_rejects_non_hex_byte() {
        assert!(hex_decode("zz").is_err());
    }

    #[test]
    fn hex_decode_multibyte_utf8_errs_without_panicking() {
        // Regression: `.sig` text is attacker-controlled. A multi-byte UTF-8 char
        // must be rejected as invalid hex, never panic on a non-char-boundary
        // slice (the reason hex_decode operates on bytes, not char slices).
        assert!(hex_decode("é").is_err()); // 0xc3 0xa9 — even length, invalid nibble
        assert!(hex_decode("aé").is_err()); // odd length
    }

    #[test]
    fn parse_kv_reads_pairs_ignoring_comments_and_sections() {
        let text = "# comment\n[section]\ned25519 = \"abc123\"\n  ml_dsa_65 =  \"def\"  \n\n";
        let m = parse_kv(text);
        assert_eq!(m.get("ed25519").map(String::as_str), Some("abc123"));
        assert_eq!(m.get("ml_dsa_65").map(String::as_str), Some("def"));
        assert_eq!(m.len(), 2);
    }

    #[test]
    fn get_reports_missing_field() {
        let m = parse_kv("a = \"1\"\n");
        assert!(get(&m, "a").is_ok());
        assert!(get(&m, "b").is_err());
    }

    #[test]
    fn write_new_key_file_refuses_clobber_and_restricts_mode() {
        let path = std::env::temp_dir().join(format!(
            "eos-repo-sign-test-{}-{:?}",
            std::process::id(),
            std::thread::current().id()
        ));
        let path_s = path.to_str().unwrap();
        let _ = std::fs::remove_file(&path);

        super::write_new_key_file(path_s, "secret\n", true).unwrap();
        // Second write must fail atomically instead of rotating the key.
        let err = super::write_new_key_file(path_s, "other\n", true).unwrap_err();
        assert_eq!(err.kind(), std::io::ErrorKind::AlreadyExists);
        assert_eq!(std::fs::read_to_string(&path).unwrap(), "secret\n");

        // On Unix the secret file must be owner-only from creation (0600).
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt as _;
            let mode = std::fs::metadata(&path).unwrap().permissions().mode();
            assert_eq!(mode & 0o777, 0o600);
        }

        std::fs::remove_file(&path).unwrap();
    }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(|s| s.as_str()) {
        Some("keygen") if args.len() == 3 => keygen(&args[1], &args[2]),
        Some("sign") if args.len() == 3 => sign(&args[1], &args[2]),
        Some("verify") if args.len() == 3 => verify(&args[1], &args[2], false),
        Some("verify") if args.len() == 4 && args[3] == "--classical-only" => {
            verify(&args[1], &args[2], true)
        }
        _ => {
            eprintln!(
                "usage:\n  \
                 eos-repo-sign keygen <secret.toml> <public.toml>\n  \
                 eos-repo-sign sign   <secret.toml> <file>\n  \
                 eos-repo-sign verify <public.toml> <file> [--classical-only]"
            );
            exit(2);
        }
    }
}
