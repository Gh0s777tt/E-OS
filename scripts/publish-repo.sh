#!/usr/bin/env bash
# Package an E-OS binary package repository for publishing (release asset / static host).
#
#   scripts/publish-repo.sh [TARGET]        # default: x86_64-unknown-redox
#
# Produces release/eos-repo-<TARGET>.tar.gz containing the .pkgar packages,
# the repo.toml index and the ed25519 signing public key. Upload it as a release
# asset, or unpack it on a static host so clients can fetch from
#   <host>/pkg/<TARGET>/<pkg>.pkgar   and   <host>/pkg/id_ed25519.pub.toml
# See docs/packages.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-x86_64-unknown-redox}"
REPO="repo/${TARGET}"
PUB="build/id_ed25519.pub.toml"
OUT="release/eos-repo-${TARGET}.tar.gz"

[ -d "$REPO" ] || { echo "error: $REPO not found — run a build first"; exit 1; }

mkdir -p release
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

cp "$REPO"/repo.toml "$stage"/
cp "$REPO"/*.pkgar "$stage"/
[ -f "$PUB" ] && cp "$PUB" "$stage"/ || echo "warning: $PUB missing (packages unverifiable)"

# R-703: sign the repo.toml manifest (hybrid ed25519+ML-DSA-65). Secret key is
# user-held via $EOS_REPO_SIGN_KEY (never in the repo); clients verify against the
# in-image-pinned public key. Unsigned publish only warns, so dev flows still work.
if [ -n "${EOS_REPO_SIGN_KEY:-}" ]; then
    SIGN_BIN="${EOS_REPO_SIGN_BIN:-$ROOT/tools/eos-repo-sign/target/release/eos-repo-sign}"
    [ -x "$SIGN_BIN" ] || SIGN_BIN="$(command -v eos-repo-sign 2>/dev/null || true)"
    [ -n "$SIGN_BIN" ] && [ -x "$SIGN_BIN" ] || { echo "error: eos-repo-sign not built — (cd tools/eos-repo-sign && cargo build --release)"; exit 1; }
    "$SIGN_BIN" sign "$EOS_REPO_SIGN_KEY" "$stage/repo.toml"
    SIGN_PUB="${EOS_REPO_SIGN_PUB:-$ROOT/keys/eos-repo-sign.pub.toml}"
    [ -f "$SIGN_PUB" ] && cp "$SIGN_PUB" "$stage/eos-repo-sign.pub.toml" || echo "warning: $SIGN_PUB missing — no pinned key for clients to verify repo.toml.sig"
    echo "signed repo.toml (hybrid ed25519 + ML-DSA-65) -> repo.toml.sig"
else
    echo "WARNING: EOS_REPO_SIGN_KEY unset — repo.toml packaged UNSIGNED (no PQ manifest signature; see R-703)."
fi

tar -C "$stage" -czf "$OUT" .
echo "packages: $(ls "$REPO"/*.pkgar | wc -l)"
sha256sum "$OUT"
echo "wrote $OUT  ($(du -h "$OUT" | cut -f1))"
echo "next: gh release upload <tag> $OUT   (or unpack on your static host)"
