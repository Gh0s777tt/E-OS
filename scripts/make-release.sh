#!/usr/bin/env bash
# make-release — assemble checksummed (optionally signed) E-OS release artifacts
# locally. GitHub Actions is disabled account-wide, so the tag->build->sign
# pipeline (R-301/R-303) cannot run; this reproduces it on any build host.
#
# It renames the built disk images to their release names, regenerates
# SHA256SUMS over the ACTUAL artifacts, and signs the checksum file when a
# minisign secret key is supplied (the key is user-held, never in the repo).
#
# Usage:
#   VERSION=0.1.0 [ARCHES="aarch64 x86_64"] \
#     [MINISIGN_SECRET_KEY=keys/eos-release.key] scripts/make-release.sh
set -euo pipefail
VERSION="${VERSION:-0.1.0}"
ARCHES="${ARCHES:-aarch64 x86_64}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/release"
mkdir -p "$OUT"
: > "$OUT/SHA256SUMS"
for arch in $ARCHES; do
  img="$ROOT/build/$arch/eos/harddrive.img"
  if [ ! -f "$img" ]; then
    echo "!! missing $img — build it first: make CI=1 ARCH=$arch CONFIG_NAME=eos all" >&2
    exit 1
  fi
  name="eos-${VERSION}-${arch}.img"
  cp -f "$img" "$OUT/$name"
  ( cd "$OUT" && sha256sum "$name" >> SHA256SUMS )
  echo "packaged $name"
done
if [ -n "${MINISIGN_SECRET_KEY:-}" ]; then
  minisign -Sm "$OUT/SHA256SUMS" -s "$MINISIGN_SECRET_KEY"
  echo "signed -> release/SHA256SUMS.minisig"
else
  rm -f "$OUT/SHA256SUMS.minisig"
  echo "WARNING: no MINISIGN_SECRET_KEY set — SHA256SUMS is UNSIGNED (removed any stale .minisig)."
fi
