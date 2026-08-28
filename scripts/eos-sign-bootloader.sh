#!/usr/bin/env bash
# eos-sign-bootloader.sh — sign the E-OS UEFI bootloader for Secure Boot (V2-N03 / R-F27).
#
# WHY. The build produces bootloader-live.efi UNSIGNED, so a PC with Secure Boot on (the
# factory default) refuses to boot it. Signing it with a key the firmware trusts is what makes
# automatic install possible without the operator disabling Secure Boot. The signing KEY is a
# human action -- like every signing key here -- and lives off-repo; this script is the tooling
# around it, plus a selftest that proves the mechanism with a throwaway key touching no real one.
#
#   EOS_SB_SELFTEST=1 scripts/eos-sign-bootloader.sh [x86_64|aarch64]   # prove it, throwaway key
#   EOS_SB_KEY=~/keys/mok.key EOS_SB_CERT=~/keys/mok.crt \
#       scripts/eos-sign-bootloader.sh x86_64                            # real signing
#
# It never prints key material. sbsign/openssl run in a throwaway debian container so the build
# container and the host stay clean. Fails closed: no key and no selftest -> refuse.
set -uo pipefail

ARCH="${1:-x86_64}"
case "$ARCH" in x86_64|aarch64) ;; *) echo "arch: x86_64|aarch64"; exit 2 ;; esac
EFI="build/$ARCH/eos/bootloader-live.efi"          # inside the eos-work volume
VOL="${EOS_BUILD_VOLUME:-eos-work}"
IMG="docker.io/library/debian:trixie"
SELFTEST="${EOS_SB_SELFTEST:-}"

step(){ printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail(){ printf '\033[31mFAIL:\033[0m %s\n' "$1" >&2; exit 1; }

step "1/4  locate the built bootloader"
if ! podman volume exists "$VOL" 2>/dev/null; then fail "volume $VOL not found — build an image first"; fi
podman run --rm -v "$VOL":/work:ro "$IMG" test -f "/work/redox/$EFI" \
  || fail "$EFI not in the volume — run: make CI=1 ARCH=$ARCH CONFIG_NAME=eos all"
echo "    found /work/redox/$EFI"

# Resolve the signing key. Real use: operator key, off-repo. Selftest: throwaway, generated
# inside the container and shredded there.
if [ -z "$SELFTEST" ]; then
  [ -n "${EOS_SB_KEY:-}" ] && [ -n "${EOS_SB_CERT:-}" ] \
    || fail "no signing key. Set EOS_SB_KEY + EOS_SB_CERT (off-repo), or EOS_SB_SELFTEST=1 to prove the mechanism.
       Generate a real Secure Boot key once:
         openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \\
           -subj \"/CN=E-OS Secure Boot/\" -keyout ~/keys/mok.key -out ~/keys/mok.crt"
  [ -f "$EOS_SB_KEY" ]  || fail "EOS_SB_KEY not found: $EOS_SB_KEY"
  [ -f "$EOS_SB_CERT" ] || fail "EOS_SB_CERT not found: $EOS_SB_CERT"
fi

OUT="${EOS_SB_OUT:-$HOME/eos-artifacts/bootloader-live-signed-$ARCH.efi}"
mkdir -p "$(dirname "$OUT")"

step "2/4  install sbsigntool (throwaway container)"
KEYMOUNT=()
[ -z "$SELFTEST" ] && KEYMOUNT=(-v "$(dirname "$EOS_SB_KEY")":/key:ro)

podman run --rm --network=host -v "$VOL":/work:ro ${KEYMOUNT[@]+"${KEYMOUNT[@]}"} \
  -e SELFTEST="$SELFTEST" \
  -e KEYFILE="${EOS_SB_KEY:+/key/$(basename "${EOS_SB_KEY:-x}")}" \
  -e CERTFILE="${EOS_SB_CERT:+/key/$(basename "${EOS_SB_CERT:-x}")}" \
  -e SRC="/work/redox/$EFI" \
  "$IMG" bash -euo pipefail -c '
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq sbsigntool openssl >/dev/null 2>&1
    echo "    sbsign $(sbsign --version 2>&1 | grep -oE "[0-9.]+" | head -1)"
    W=$(mktemp -d); cp "$SRC" "$W/in.efi"

    if [ -n "$SELFTEST" ]; then
      echo "== 3/4 generate a THROWAWAY Secure Boot key (touches no real key) =="
      openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
        -subj "/CN=E-OS Secure Boot throwaway selftest/" \
        -keyout "$W/mok.key" -out "$W/mok.crt" >/dev/null 2>&1
      chmod 600 "$W/mok.key"
      KEYFILE="$W/mok.key"; CERTFILE="$W/mok.crt"
    else
      echo "== 3/4 sign with the operator key (off-repo) =="
    fi

    sbsign --key "$KEYFILE" --cert "$CERTFILE" --output "$W/signed.efi" "$W/in.efi" >/dev/null
    echo "    signed."

    echo "== 4/4 PROVE it: signed verifies against its cert, unsigned does not =="
    if sbverify --cert "$CERTFILE" "$W/signed.efi" >/dev/null 2>&1; then
      echo "    ✓ signed bootloader VERIFIES against the cert"
    else echo "    ✗ signed bootloader failed verification"; exit 1; fi
    if sbverify --cert "$CERTFILE" "$W/in.efi" >/dev/null 2>&1; then
      echo "    ✗ UNSIGNED bootloader wrongly verified — signing proves nothing"; exit 1
    else echo "    ✓ unsigned bootloader is REJECTED (as it must be)"; fi

    # hand the signed binary out via base64 on stdout marker (no host bind-mount: exFAT statfs)
    echo "---SIGNED-EFI-BASE64---"; base64 "$W/signed.efi"; echo "---END---"
    [ -n "$SELFTEST" ] && shred -u "$W/mok.key" 2>/dev/null || true
  ' > /tmp/eos-sb.out 2>/tmp/eos-sb.err
rc=$?
# print the container narration, but not the base64 payload
awk '/^---SIGNED-EFI-BASE64---/{skip=1} skip==0{print} /^---END---/{skip=0}' /tmp/eos-sb.out
[ "$rc" -eq 0 ] || { echo "FAIL: signing container errored"; tail -4 /tmp/eos-sb.err; exit 1; }

# wyłuskaj podpisany EFI z markera
awk '/^---SIGNED-EFI-BASE64---/{f=1;next}/^---END---/{f=0}f' /tmp/eos-sb.out | base64 -d > "$OUT" 2>/dev/null
if [ -s "$OUT" ]; then
  echo
  echo "    signed EFI -> $OUT ($(wc -c < "$OUT") B)"
else
  echo "    (selftest: podpisany EFI nie zapisany na host — dowód wykonany w kontenerze)"
fi
