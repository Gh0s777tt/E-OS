#!/usr/bin/env bash
# Demonstrates the E-OS package-index signature: it verifies a good index and
# REFUSES a tampered one. The refusal is the point — a check that can only pass
# is not a check (CLAUDE.md 5.4).
set -euo pipefail

BIN="tools/eos-repo-sign/target/release/eos-repo-sign"
PUB="keys/eos-repo-sign.pub.toml"

[ -x "$BIN" ] || { echo "build it first:  (cd tools/eos-repo-sign && cargo build --release)"; exit 1; }
[ -f "$PUB" ] || { echo "missing public key: $PUB"; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
printf 'demo = "an index-shaped file"\n' > "$tmp/repo.toml"

echo "== this example needs a secret key to sign with =="
if [ -z "${EOS_REPO_SIGN_KEY:-}" ]; then
    echo "   EOS_REPO_SIGN_KEY is unset, so only the PUBLIC half can be demonstrated."
    echo "   Verifying an unsigned file must fail:"
    if "$BIN" verify "$PUB" "$tmp/repo.toml" 2>/dev/null; then
        echo "   UNEXPECTED: verification passed on an unsigned file"; exit 1
    fi
    echo "   OK — refused, as it should."
    exit 0
fi

echo "== sign =="
"$BIN" sign "$EOS_REPO_SIGN_KEY" "$tmp/repo.toml"

echo "== verify the untouched file — expect OK =="
"$BIN" verify "$PUB" "$tmp/repo.toml"

echo "== flip one byte, verify again — expect FAIL =="
printf 'X' >> "$tmp/repo.toml"
if "$BIN" verify "$PUB" "$tmp/repo.toml" 2>/dev/null; then
    echo "UNEXPECTED: a tampered file verified"; exit 1
fi
echo "OK — both algorithms refused the tampered file."
