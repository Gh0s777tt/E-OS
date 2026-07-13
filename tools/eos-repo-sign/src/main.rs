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
    if b.len() % 2 != 0 {
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

fn get<'a>(map: &'a std::collections::BTreeMap<String, String>, key: &str) -> Result<&'a str, String> {
    map.get(key).map(|s| s.as_str()).ok_or_else(|| format!("missing field '{key}'"))
}

fn die(msg: impl AsRef<str>) -> ! {
    eprintln!("eos-repo-sign: {}", msg.as_ref());
    exit(1)
}

fn keygen(secret_path: &str, public_path: &str) {
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

    std::fs::write(secret_path, secret).unwrap_or_else(|e| die(format!("write {secret_path}: {e}")));
    std::fs::write(public_path, public).unwrap_or_else(|e| die(format!("write {public_path}: {e}")));
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
    let ed_arr: [u8; 32] = ed_bytes.as_slice().try_into().unwrap_or_else(|_| die("ed25519 secret must be 32 bytes"));
    let ed_sk = EdSigningKey::from_bytes(&ed_arr);

    let seed_bytes = hex_decode(get(&sk, "ml_dsa_65_seed").unwrap_or_else(|e| die(e)))
        .unwrap_or_else(|e| die(format!("ml-dsa seed: {e}")));
    let seed = B32::try_from(seed_bytes.as_slice())
        .unwrap_or_else(|_| die("ml-dsa seed must be 32 bytes"));
    let pq_sk = PqSigningKey::<MlDsa65>::from_seed(&seed);

    let msg = std::fs::read(file_path).unwrap_or_else(|e| die(format!("read {file_path}: {e}")));

    let ed_sig: EdSignature = ed_sk.sign(&msg);
    let pq_sig: PqSignature<MlDsa65> = pq_sk.sign(&msg);

    let out = format!(
        "# E-OS hybrid signature for {file_path}\n\
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
    let sig_text = std::fs::read_to_string(&sig_path)
        .unwrap_or_else(|e| die(format!("read {sig_path}: {e}")));
    let sig = parse_kv(&sig_text);

    let msg = std::fs::read(file_path).unwrap_or_else(|e| die(format!("read {file_path}: {e}")));

    // ---- ed25519 (classical) — always checked ----
    let ed_vk_bytes = hex_decode(get(&pk, "ed25519").unwrap_or_else(|e| die(e)))
        .unwrap_or_else(|e| die(format!("ed25519 pubkey: {e}")));
    let ed_vk_arr: [u8; 32] = ed_vk_bytes.as_slice().try_into().unwrap_or_else(|_| die("ed25519 pubkey must be 32 bytes"));
    let ed_vk = EdVerifyingKey::from_bytes(&ed_vk_arr).unwrap_or_else(|e| die(format!("ed25519 pubkey: {e}")));
    let ed_sig_bytes = hex_decode(get(&sig, "ed25519").unwrap_or_else(|e| die(e)))
        .unwrap_or_else(|e| die(format!("ed25519 sig: {e}")));
    let ed_sig_arr: [u8; 64] = ed_sig_bytes.as_slice().try_into().unwrap_or_else(|_| die("ed25519 sig must be 64 bytes"));
    let ed_sig = EdSignature::from_bytes(&ed_sig_arr);
    // verify_strict: reject non-canonical S and small-order/mixed-order edge
    // cases — the recommended API for an authentication trust anchor.
    let ed_ok = ed_vk.verify_strict(&msg, &ed_sig).is_ok();
    println!("ed25519 (classical):  {}", if ed_ok { "OK" } else { "FAIL" });

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
        println!("ml-dsa-65 (PQ):        {}", if pq_ok { "OK" } else { "FAIL" });
    }

    if ed_ok && pq_ok {
        println!("VERIFIED: {file_path}");
    } else {
        die("verification FAILED");
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
