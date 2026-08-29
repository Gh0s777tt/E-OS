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
VOL="${EOS_BUILD_VOLUME:-eos-work}"
BUILD="/work/redox/build/$ARCH/eos"

inbox(){ podman run --rm -v "$VOL":/work localhost/redox-base:latest bash -lc "$1"; }

echo "==> sync this repo into the build volume (the build tree is separate, see CLAUDE.md 20.1)"
scripts/eos-sync-buildtree.sh --apply >/dev/null

# `make all` is happy to say "Nothing to be done" and leave images from an EARLIER build in
# place -- which once exported images carrying a throwaway Secure Boot signature minutes after
# the operator's real key had been installed (U-210). An exported image is only trustworthy if
# THIS run produced it, so stamp the images before the build and compare after.
before="$(inbox "stat -c %Y $BUILD/harddrive.img $BUILD/redox-live.iso 2>/dev/null | tr '\n' ' '" || true)"
key_present="$(inbox 'test -f /work/redox/build/sb-signing/mok.crt && echo yes || echo no')"

echo "==> build ARCH=$ARCH in the eos-work volume (this is what make-from-here cannot do)"
# V2-MS15: the repo index carries a monotonic serial so a client can refuse a replayed older
# index. It has to be counted HERE, in the real repository -- the build tree inside the volume is
# a different git history that never receives commits, so counting there would hand every publish
# the same number and arm nothing. Empty if this is somehow not a checkout; the builder then says
# so loudly rather than inventing a value.
serial="$(git rev-list --count HEAD 2>/dev/null || true)"
podman run --rm --cap-add SYS_ADMIN --device /dev/fuse --network=host --pids-limit=-1 \
  -v "$VOL":/work -v eos-root:/root --env PODMAN_BUILD=0 \
  --env EOS_REPO_SERIAL="$serial" localhost/redox-base:latest \
  bash -lc "cd /work/redox && make CI=1 ARCH=$ARCH CONFIG_NAME=eos all 2>&1 | tail -3"

after="$(inbox "stat -c %Y $BUILD/harddrive.img $BUILD/redox-live.iso 2>/dev/null | tr '\n' ' '" || true)"
if [ "$before" = "$after" ] && [ -n "$before" ]; then
  echo "!! make produced NOTHING: the images in the build tree are unchanged by this run."
  if [ "$key_present" = yes ]; then
    echo "!! A Secure Boot key IS in place, so these cached images may carry an older signature"
    echo "!! (or none). Refusing to export them. Force a re-cook and build again:"
    echo "!!   scripts/eos-sb-setup-key.sh   # re-places the key AND invalidates the bootloader"
    exit 1
  fi
  echo "!! Nothing changed since the last build; exporting the cached images unchanged."
fi

# When a key is in place, the point of the build was a signed bootloader. Prove it here rather
# than discovering "Access Denied" on the target machine (U-208).
if [ "$key_present" = yes ]; then
  echo "==> verify the staged bootloaders against the key that is currently in the tree"
  inbox '
    cd /work/redox; crt=build/sb-signing/mok.crt; rc=0
    command -v sbverify >/dev/null 2>&1 || { apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq sbsigntool >/dev/null 2>&1; }
    for b in $(find recipes/core/bootloader/target -path "*stage/usr/lib/boot/bootloader*.efi" 2>/dev/null); do
      if sbverify --cert "$crt" "$b" >/dev/null 2>&1
        then echo "    signed by the current cert: ${b##*/}"
        else echo "    NOT signed by the current cert: $b"; rc=1
      fi
    done
    [ "$rc" = 0 ] || echo "    -> run scripts/eos-sb-setup-key.sh to invalidate the package, then rebuild"
    exit $rc' || exit 1
fi

echo "==> export image + live ISO"
for f in harddrive.img redox-live.iso; do
  o="$OUT/eos-$ARCH-${f/redox-live.iso/live.iso}"
  podman run --rm -v "$VOL":/work localhost/redox-base:latest \
    bash -lc "cat $BUILD/$f" > "$o" 2>/dev/null
  [ -s "$o" ] && echo "    $o ($(( $(wc -c < "$o") / 1048576 )) MiB)"
done
echo "Done."
