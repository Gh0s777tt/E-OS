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

# eos-root is mounted as well as $VOL, and that is not belt-and-braces: cargo and rustup live
# in the eos-root volume at /root/.cargo, so a /work-only container cannot run `make` at all --
# mk/depends.mk:11 stops with `rustup not found`. This helper was /work-only, which made every
# `make` query through it fail with status 2; with `2>/dev/null` on the caller and `set -e` on
# the script, that killed eos-build.sh right after the sync line, silently, for BOTH arches.
# The same trap is already written down five lines below for the host-tools step. It was worth
# reading twice.
inbox(){ podman run --rm -v "$VOL":/work -v eos-root:/root localhost/redox-base:latest bash -lc "$1"; }

echo "==> sync this repo into the build volume (the build tree is separate, see CLAUDE.md 20.1)"
scripts/eos-sync-buildtree.sh --apply >/dev/null

# Ask the build for the medium's filename instead of repeating the pattern here (R-611a).
# The rename that introduced it touched 13 places in Makefile/mk and ~17 more in scripts,
# redox.ipxe and docs; a second copy of the pattern would guarantee a third rename misses one.
MEDIUM_NAME="$(inbox "cd /work/redox && make -s print-installer-medium ARCH=$ARCH CONFIG_NAME=eos PODMAN_BUILD=0" 2>/dev/null | tr -d '\r' | xargs -r basename)"
if [ -z "$MEDIUM_NAME" ]; then
  echo "!! could not read the installer-medium name from the build (make print-installer-medium)" >&2
  exit 1
fi
echo "==> installation medium for this build: $MEDIUM_NAME"

# `make all` is happy to say "Nothing to be done" and leave images from an EARLIER build in
# place -- which once exported images carrying a throwaway Secure Boot signature minutes after
# the operator's real key had been installed (U-210). An exported image is only trustworthy if
# THIS run produced it, so stamp the images before the build and compare after.
before="$(inbox "stat -c %Y $BUILD/harddrive.img $BUILD/$MEDIUM_NAME 2>/dev/null | tr '\n' ' '" || true)"
key_present="$(inbox 'test -f /work/redox/build/sb-signing/mok.crt && echo yes || echo no')"

# Nothing in mk/*.mk builds the host tools: REPO_BIN is just a path to ./target/release/repo,
# and make uses whatever binary happens to sit there. So an edit to src/bin/repo_builder.rs --
# the program that WRITES repo.toml -- has no effect until someone rebuilds by hand, and there is
# no warning: the build succeeds, the index looks fine, and the new field is simply absent.
# Measured: a full build ran against a repo_builder binary from the previous day and emitted an
# index with no serial, while the source in the same tree had the code to emit one. Rebuild the
# host tools first, every time; cargo no-ops when nothing changed, so this costs nothing.
echo "==> rebuild the host tools (make does not do this, and a stale one fails silently)"
# Two things this step got wrong on the first attempt, both worth stating so they are not
# reintroduced: cargo lives in the eos-root volume at /root/.cargo, so the /work-only helper
# cannot see it; and piping the build through `tail` inside the container hands back TAIL's exit
# status, so `cargo: command not found` scrolled past under `set -e` without stopping anything.
# Keep the pipeline's real status, and check the binary afterwards rather than trusting the run.
podman run --rm --network=host -v "$VOL":/work -v eos-root:/root localhost/redox-base:latest \
  bash -lc 'set -o pipefail; cd /work/redox && cargo build --release --bin repo --bin repo_builder --bin cookbook_redoxer 2>&1 | tail -2' \
  || { echo "!! host tools failed to build -- refusing to run make against stale binaries"; exit 1; }

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
  bash -lc "cd /work/redox && make CI=1 ARCH=$ARCH CONFIG_NAME=eos all build/$ARCH/eos/$MEDIUM_NAME 2>&1 | tail -3"

after="$(inbox "stat -c %Y $BUILD/harddrive.img $BUILD/$MEDIUM_NAME 2>/dev/null | tr '\n' ' '" || true)"
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
# The redirection creates the destination BEFORE the container command runs, so a missing source
# left a 0-BYTE FILE behind -- and said nothing, because stderr went to /dev/null and the size
# test merely stayed quiet. Under `set -e` the failing `cat` then aborted the run, so the script
# ended without "Done." while an empty .iso sat in the artifact directory looking like a
# deliverable. `all` builds only harddrive.img, so this triggered every time the ISO target was
# not asked for. An artifact nobody can tell is broken is worse than one that is missing: check
# the source first, stage through .partial, keep nothing empty, and fail loudly.
export_rc=0
for f in harddrive.img "$MEDIUM_NAME"; do
  # The medium is already named eos-<ver>-<arch>-installer.img, so it is exported under its
  # own name; only harddrive.img still needs the eos-<arch>- prefix bolted on.
  case "$f" in
    harddrive.img) o="$OUT/eos-$ARCH-$f" ;;
    *)             o="$OUT/$f" ;;
  esac
  if ! inbox "test -s $BUILD/$f" >/dev/null 2>&1; then
    echo "!! $f was not produced by this build -- NOT exporting $(basename "$o")"
    rm -f "$o"
    export_rc=1
    continue
  fi
  if ! podman run --rm -v "$VOL":/work localhost/redox-base:latest \
       bash -lc "cat $BUILD/$f" > "$o.partial"; then
    rm -f "$o.partial"; echo "!! export of $f failed"; export_rc=1; continue
  fi
  if [ -s "$o.partial" ]; then
    mv "$o.partial" "$o"
    echo "    $o ($(( $(wc -c < "$o") / 1048576 )) MiB)"
  else
    rm -f "$o.partial"; echo "!! $f exported as 0 bytes -- discarded"; export_rc=1
  fi
done
[ "$export_rc" = 0 ] || { echo "!! export incomplete -- see above"; exit 1; }
echo "Done."
