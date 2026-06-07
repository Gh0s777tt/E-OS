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

tar -C "$stage" -czf "$OUT" .
echo "packages: $(ls "$REPO"/*.pkgar | wc -l)"
sha256sum "$OUT"
echo "wrote $OUT  ($(du -h "$OUT" | cut -f1))"
echo "next: gh release upload <tag> $OUT   (or unpack on your static host)"
