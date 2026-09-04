#![no_main]
//! Feed arbitrary text to the hex decoder that turns every key and signature field into bytes.
//!
//! A wrong answer here is a wrong key or a wrong signature, so the properties are exact: a decode
//! either fails or produces exactly half as many bytes as it consumed characters, and whatever it
//! produces must re-encode to the same lowercase hex it came from.

use libfuzzer_sys::fuzz_target;

fuzz_target!(|data: &[u8]| {
    let Ok(text) = std::str::from_utf8(data) else {
        return;
    };
    match eos_repo_sign::hex_decode(text) {
        Err(_) => {} // refusing malformed input is the expected outcome, not a failure
        Ok(bytes) => {
            let trimmed = text.trim();
            assert_eq!(
                bytes.len() * 2,
                trimmed.len(),
                "decoded {} bytes from {} characters",
                bytes.len(),
                trimmed.len()
            );
            // Round-trip: whatever decoded must re-encode to the same value, case-folded. This is
            // what catches a nibble landing in the wrong half of a byte -- the class of bug that
            // survived mutation testing until `hex_decode_pins_the_nibble_arithmetic`.
            assert_eq!(
                eos_repo_sign::hex_encode(&bytes),
                trimmed.to_ascii_lowercase(),
                "round-trip changed the value"
            );
        }
    }
});
