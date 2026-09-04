#![no_main]
//! Feed arbitrary bytes to the key/value parser that reads the public-key and signature files.
//!
//! Both files arrive off a mirror and are parsed BEFORE any signature is checked, so this is the
//! first code an attacker's bytes reach. The property asserted is not "it produces something
//! sensible" -- for hostile input there is no sensible output -- but that it TERMINATES without
//! panicking, and that what it returns obeys the invariants the callers rely on.

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let Ok(text) = std::str::from_utf8(data) else {
        return; // the real callers read_to_string first, so non-UTF-8 never reaches this
    };
    let map = eos_repo_sign::parse_kv(text);

    for (key, value) in &map {
        // A comment or a section header must never become a field. `verify()` looks up
        // "ed25519" and "ml-dsa-65" in this map; a forged `[ed25519 = ...]` line becoming a
        // key is the difference between reading a signature and reading an attacker's wish.
        assert!(!key.starts_with('#'), "comment became a key: {key:?}");
        assert!(!key.starts_with('['), "section header became a key: {key:?}");
        // Keys and values are trimmed, so neither may carry outer whitespace into a comparison.
        assert_eq!(key.trim(), key, "untrimmed key: {key:?}");
        assert_eq!(value.trim(), value, "untrimmed value: {value:?}");
    }
});
