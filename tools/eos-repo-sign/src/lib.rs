//! The parsing surface of `eos-repo-sign`, behind a library target so it can be FUZZED.
//!
//! Everything here runs before a signature has been checked. The public-key file, the signature
//! file and the manifest all arrive off a mirror, and all three are read first -- parsing before
//! verifying is unavoidable, which is why this is the code worth attacking rather than trusting.
//!
//! These functions were private to the binary until 2026-09-04. A fuzzer cannot link against a
//! binary crate, so `fuzz/fuzz_targets/` had nothing to call and SC-2 read 0 of 1 parsers covered.
//! They are MOVED here, not copied: `main.rs` uses them from this library, so there is exactly one
//! definition and the hostile-input tests keep attacking the code that ships.

pub fn hex_encode(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{:02x}", b));
    }
    s
}

pub fn hex_decode(s: &str) -> Result<Vec<u8>, String> {
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
pub fn parse_kv(text: &str) -> std::collections::BTreeMap<String, String> {
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

pub fn get<'a>(
    map: &'a std::collections::BTreeMap<String, String>,
    key: &str,
) -> Result<&'a str, String> {
    map.get(key)
        .map(|s| s.as_str())
        .ok_or_else(|| format!("missing field '{key}'"))
}

/// Both signatures must verify. This is the whole point of a hybrid signature, and it is a
/// separate function only so that a test can reach it.
///
/// It was inline until 2026-09-04, when `cargo-mutants` reported
/// `replace && with || in verify` as MISSED -- meaning nothing in the suite could tell
/// "both signatures verified" from "either signature verified". A manifest carrying one good
/// signature and one forged one would have passed, which is precisely the attack the second
/// algorithm is there to stop: ed25519 against a future quantum adversary, ML-DSA against a
/// classical break of ed25519. `||` would have made the pair no stronger than its weaker half.
///
/// The `--classical-only` path sets `pq_ok = true` deliberately; that escape is the caller's
/// decision and is logged there, not weakened here.
pub fn hybrid_ok(ed_ok: bool, pq_ok: bool) -> bool {
    ed_ok && pq_ok
}
