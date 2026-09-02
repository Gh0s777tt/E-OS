#!/usr/bin/env bash
# eos-sb-setup-key.sh — place a Secure Boot signing key where the bootloader recipe signs from,
# so the next `make all` produces an image whose bootloader is signed (V2-N03 / R-F27).
#
# The bootloader recipe signs usr/lib/boot/bootloader{,.live}.efi during `cook` when it finds a
# key at build/sb-signing/{mok.key,mok.crt} in the build tree (gitignored, off the repo). This
# helper copies the operator's off-repo key there, or generates a throwaway for a proof build.
# Signing happens IN THE PACKAGE, which is the only place the live ISO's ESP bootloader comes
# from -- the installer fetches it from the bootloader pkgar, not from --write-bootloader (U-207).
#
#   EOS_SB_SELFTEST=1 scripts/eos-sb-setup-key.sh          # throwaway key + a cert to enroll
#   EOS_SB_KEY=~/keys/mok.key EOS_SB_CERT=~/keys/mok.crt scripts/eos-sb-setup-key.sh
#   scripts/eos-sb-setup-key.sh --clear                    # remove the key (builds go back to unsigned)
#
# Then: make CI=1 ARCH=x86_64 CONFIG_NAME=eos all
# The private key sits in the build volume only for the build; --clear removes it afterwards.
set -uo pipefail
VOL="${EOS_BUILD_VOLUME:-eos-work}"
DEB="docker.io/library/debian:trixie"

# The bootloader is signed only on a fresh `cook`. If its package is cached (built earlier
# without a key), `make all` will NOT re-cook it and the bootloader stays UNSIGNED -- found the
# hard way when a rebuilt installed image booted to Access Denied under Secure Boot (U-208).
# So placing a key must also invalidate the bootloader package, forcing a re-cook next build.
force_recook(){
  podman run --rm -v "$VOL":/work localhost/redox-base:latest bash -lc '
    cd /work/redox && (./target/release/repo clean bootloader 2>/dev/null || true)
    rm -rf recipes/core/bootloader/target' 2>/dev/null || true
  echo "bootloader package invalidated -- the next build re-cooks and signs it"
}

if [ "${1:-}" = "--clear" ]; then
  podman run --rm -v "$VOL":/work "$DEB" bash -lc 'rm -rf /work/redox/build/sb-signing && echo cleared'
  echo "Secure Boot key removed from the build tree; the next build leaves the bootloader unsigned."
  exit 0
fi

if [ -n "${EOS_SB_SELFTEST:-}" ]; then
  podman run --rm -v "$VOL":/work "$DEB" bash -euo pipefail -c '
    apt-get update -qq >/dev/null 2>&1; apt-get install -y -qq openssl >/dev/null 2>&1
    mkdir -p /work/redox/build/sb-signing
    openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
      -subj "/CN=E-OS Secure Boot selftest/" \
      -keyout /work/redox/build/sb-signing/mok.key -out /work/redox/build/sb-signing/mok.crt >/dev/null 2>&1
    chmod 600 /work/redox/build/sb-signing/mok.key
    cp /work/redox/build/sb-signing/mok.crt /work/redox/build/sb-mok.crt
    echo "throwaway key in place; enroll build/sb-mok.crt in firmware to boot the result"'
  echo "Done (throwaway). Now: make CI=1 ARCH=x86_64 CONFIG_NAME=eos all"
  exit 0
fi

[ -n "${EOS_SB_KEY:-}" ] && [ -n "${EOS_SB_CERT:-}" ] \
  || { echo "Set EOS_SB_KEY + EOS_SB_CERT (off-repo), or EOS_SB_SELFTEST=1. Generate a real key once:"; \
       echo "  openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \\"; \
       echo "    -subj \"/CN=E-OS Secure Boot/\" -keyout ~/keys/mok.key -out ~/keys/mok.crt"; exit 1; }
[ -f "$EOS_SB_KEY" ] && [ -f "$EOS_SB_CERT" ] || { echo "key/cert not found"; exit 1; }
podman run --rm -v "$VOL":/work -v "$(dirname "$EOS_SB_KEY")":/k:ro -v "$(dirname "$EOS_SB_CERT")":/c:ro "$DEB" bash -euo pipefail -c '
  mkdir -p /work/redox/build/sb-signing
  cp "/k/'"$(basename "$EOS_SB_KEY")"'" /work/redox/build/sb-signing/mok.key
  cp "/c/'"$(basename "$EOS_SB_CERT")"'" /work/redox/build/sb-signing/mok.crt
  chmod 600 /work/redox/build/sb-signing/mok.key
  echo "operator key in place"' || {
    echo "FAIL: the container that places the Secure Boot key errored -- key NOT installed" >&2
    exit 1
  }
# The script runs under `set -uo pipefail` WITHOUT -e, so a failed `podman run` used to fall
# straight through to force_recook and "Done." -- announcing that an operator key was in place
# when it was not. And an exit code is not the artefact: check that the key and certificate
# actually landed in the build tree, which is where every later step looks for them.
podman run --rm -v "$VOL":/work "$DEB" bash -c '
  test -s /work/redox/build/sb-signing/mok.key && test -s /work/redox/build/sb-signing/mok.crt' || {
  echo "FAIL: the container reported success but build/sb-signing/ has no key+cert" >&2
  exit 1
}
force_recook
echo "Done. Now: make CI=1 ARCH=x86_64 CONFIG_NAME=eos all   (then scripts/eos-sb-setup-key.sh --clear)"
