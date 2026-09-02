#!/usr/bin/env bash
# eos-boot-setup-key.sh — place the boot-verification key so the next build produces an image
# whose bootloader verifies the kernel and initfs it loads (V2-MS02).
#
# Three recipes cooperate, and all three read from build/boot-signing/ (gitignored, off-repo):
#   bootloader — injects boot.pub.bin into the binary and compiles verification in
#   kernel     — signs usr/lib/boot/kernel      -> kernel.sig
#   base       — signs usr/lib/boot/initfs      -> initfs.sig
# With no key, all three degrade together: nothing is signed and the bootloader does not verify.
# That pairing is deliberate -- signing without verifying, or verifying without signing, would
# produce an image that cannot boot.
#
#   EOS_BOOT_SELFTEST=1 scripts/eos-boot-setup-key.sh        # throwaway key, for a proof build
#   EOS_BOOT_KEY=~/keys/boot.key scripts/eos-boot-setup-key.sh
#   scripts/eos-boot-setup-key.sh --clear                    # back to unverified builds
#
# Generating the REAL key is the operator's action and is deliberately not automated here:
#   openssl genpkey -algorithm ed25519 -out ~/keys/boot.key
set -uo pipefail
VOL="${EOS_BUILD_VOLUME:-eos-work}"
DEB="docker.io/library/debian:trixie"

# Signing happens during `cook`. A cached kernel/base/bootloader package is NOT re-cooked, so
# without this the build would silently ship the previous, unsigned payloads -- the exact trap
# that made a rebuilt image boot to Access Denied under Secure Boot (U-208).
force_recook(){
  podman run --rm -v "$VOL":/work localhost/redox-base:latest bash -lc '
    cd /work/redox
    for p in bootloader kernel base; do
      ./target/release/repo clean "$p" 2>/dev/null || true
      rm -rf "recipes/core/$p/target"
    done
    # Cleaning the packages is NOT enough. `make` gates the whole cook stage on the stamp file
    # build/<arch>/<config>/repo.tag: while that exists and is newer than its prerequisites,
    # make skips cooking entirely and assembles an image from whatever is already around --
    # measured, after a fork bump, as a build that never fetched the new revision and produced
    # an image from the previous code without one word of warning. The images are file targets
    # for the same reason, so they go too.
    rm -f build/*/*/repo.tag build/*/*/harddrive.img build/*/*/eos-*-installer.img' 2>/dev/null || true
  echo "bootloader, kernel and base invalidated; repo.tag and images removed -- the next build re-cooks"
}

if [ "${1:-}" = "--clear" ]; then
  podman run --rm -v "$VOL":/work "$DEB" bash -lc 'rm -rf /work/redox/build/boot-signing && echo cleared'
  force_recook
  echo "Boot key removed; the next build neither signs nor verifies kernel/initfs."
  exit 0
fi

if [ -n "${EOS_BOOT_SELFTEST:-}" ]; then
  podman run --rm -v "$VOL":/work "$DEB" bash -euo pipefail -c '
    apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq openssl python3 >/dev/null 2>&1
    mkdir -p /work/redox/build/boot-signing
    openssl genpkey -algorithm ed25519 -out /work/redox/build/boot-signing/boot.key 2>/dev/null
    openssl pkey -in /work/redox/build/boot-signing/boot.key -pubout -outform DER 2>/dev/null \
      | tail -c 32 > /work/redox/build/boot-signing/boot.pub.bin
    chmod 600 /work/redox/build/boot-signing/boot.key
    echo "throwaway boot key in place ($(wc -c < /work/redox/build/boot-signing/boot.pub.bin | tr -d " ") B public)"'
  # `set -uo pipefail` has no -e, so a failed container used to fall through to force_recook
  # and an unconditional "Done (throwaway)" -- claiming a boot-verification key was in place
  # when none had been generated. And the exit code is not the artefact: the public key is the
  # thing every later step reads, so check that it exists and is the right size.
  podman run --rm -v "$VOL":/work "$DEB" bash -c '
    test -s /work/redox/build/boot-signing/boot.key || exit 1
    [ "$(wc -c < /work/redox/build/boot-signing/boot.pub.bin)" = "32" ]' || {
    echo "FAIL: no usable throwaway boot key in build/boot-signing/ (expected a 32-byte ed25519 public key)" >&2
    exit 1
  }
  force_recook
  echo "Done (throwaway). Now: scripts/eos-build.sh x86_64"
  exit 0
fi

[ -n "${EOS_BOOT_KEY:-}" ] || {
  echo "Set EOS_BOOT_KEY to an off-repo Ed25519 private key, or EOS_BOOT_SELFTEST=1."
  echo "Generate the real one once, yourself:"
  echo "  mkdir -p ~/keys && openssl genpkey -algorithm ed25519 -out ~/keys/boot.key"
  exit 1
}
[ -f "$EOS_BOOT_KEY" ] || { echo "key not found: $EOS_BOOT_KEY"; exit 1; }

podman run --rm -v "$VOL":/work -v "$(dirname "$EOS_BOOT_KEY")":/k:ro "$DEB" bash -euo pipefail -c '
  apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq openssl >/dev/null 2>&1
  mkdir -p /work/redox/build/boot-signing
  cp "/k/'"$(basename "$EOS_BOOT_KEY")"'" /work/redox/build/boot-signing/boot.key
  chmod 600 /work/redox/build/boot-signing/boot.key
  openssl pkey -in /work/redox/build/boot-signing/boot.key -pubout -outform DER 2>/dev/null \
    | tail -c 32 > /work/redox/build/boot-signing/boot.pub.bin
  [ "$(wc -c < /work/redox/build/boot-signing/boot.pub.bin | tr -d " ")" = 32 ] \
    || { echo "could not derive a 32-byte Ed25519 public key -- is this an Ed25519 key?"; exit 1; }
  echo "operator boot key in place"'
rc=$?
[ $rc -eq 0 ] || exit $rc
force_recook
echo "Done. Now: scripts/eos-build.sh x86_64   (then scripts/eos-boot-setup-key.sh --clear)"
