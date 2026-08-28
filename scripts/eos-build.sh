#!/usr/bin/env bash
# eos-build.sh — build an E-OS image the way that actually works on this host.
#
# `make CI=1 ... all` run from the project directory FAILS here: the project lives on an exFAT
# volume, and the Makefile's own podman step tries to bind-mount that directory into the build
# container -- podman cannot (statfs error, U-209). The real build tree lives in the `eos-work`
# podman VOLUME (on the internal disk), which is what every build this session has used.
#
# This syncs the repo's tracked files into that volume, then builds inside the container with
# PODMAN_BUILD=0 (no nested podman, no exFAT mount), and exports the image next to the repo.
#
#   scripts/eos-build.sh [x86_64|aarch64]
#
# For a Secure-Boot-signed image, place the key first:  scripts/eos-sb-setup-key.sh
set -euo pipefail
ARCH="${1:-x86_64}"
case "$ARCH" in x86_64|aarch64) ;; *) echo "arch: x86_64|aarch64"; exit 2 ;; esac
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
OUT="${EOS_OUT:-$HOME/eos-artifacts}"; mkdir -p "$OUT"

echo "==> sync this repo into the build volume (the build tree is separate, see CLAUDE.md 20.1)"
scripts/eos-sync-buildtree.sh --apply >/dev/null

echo "==> build ARCH=$ARCH in the eos-work volume (this is what make-from-here cannot do)"
podman run --rm --cap-add SYS_ADMIN --device /dev/fuse --network=host --pids-limit=-1 \
  -v eos-work:/work -v eos-root:/root --env PODMAN_BUILD=0 localhost/redox-base:latest \
  bash -lc "cd /work/redox && make CI=1 ARCH=$ARCH CONFIG_NAME=eos all 2>&1 | tail -3"

echo "==> export image + live ISO"
for f in harddrive.img redox-live.iso; do
  o="$OUT/eos-$ARCH-${f/redox-live.iso/live.iso}"
  podman run --rm -v eos-work:/work localhost/redox-base:latest \
    bash -lc "cat /work/redox/build/$ARCH/eos/$f" > "$o" 2>/dev/null
  [ -s "$o" ] && echo "    $o ($(( $(wc -c < "$o") / 1048576 )) MiB)"
done
echo "Done."
