#!/usr/bin/env bash
# eos-secureboot-proof.sh — prove, end to end, that the E-OS bootloader boots under real
# UEFI Secure Boot firmware once signed and trusted, and is rejected otherwise (V2-N03 / R-F27).
#
# Runs three cases under QEMU with edk2 Secure Boot firmware, using THROWAWAY keys (no real
# key is touched), and asserts the outcomes:
#
#   1. firmware trusts OUR key  + bootloader signed by OUR key    -> ACCEPTED (boots)
#   2. firmware trusts OUR key  + bootloader UNSIGNED             -> REJECTED
#   3. firmware trusts a FOREIGN key + bootloader signed by OURS  -> REJECTED
#
# Case 3 is the control that makes the proof honest: it shows acceptance needs the firmware to
# TRUST the key, not merely that the binary carries a signature. (An earlier control that only
# enabled Secure Boot without enrolling a Platform Key was invalid -- no PK means setup mode,
# where everything boots; U-206.)
#
#   scripts/eos-secureboot-proof.sh            # x86_64 (the arch with locked-down Secure Boot)
#
# macOS host: needs qemu-system-x86_64 + edk2 Secure Boot firmware (both from homebrew qemu),
# and podman for the debian signing container. Artefacts land in $EOS_SB_DIR (default
# ~/eos-artifacts/sbproof) and are throwaway.
set -uo pipefail

ARCH=x86_64
VOL="${EOS_BUILD_VOLUME:-eos-work}"
DIR="${EOS_SB_DIR:-$HOME/eos-artifacts/sbproof}"
QEMU="$(command -v qemu-system-x86_64 || echo /opt/homebrew/bin/qemu-system-x86_64)"
FW="${EOS_SB_FW:-/opt/homebrew/share/qemu/edk2-x86_64-secure-code.fd}"
VARST="${EOS_SB_VARS_TEMPLATE:-/opt/homebrew/share/qemu/edk2-i386-vars.fd}"
DEB="docker.io/library/debian:trixie"

fail(){ printf '\033[31mFAIL:\033[0m %s\n' "$1" >&2; exit 1; }
[ -x "$QEMU" ] || fail "qemu-system-x86_64 not found"
[ -f "$FW" ]   || fail "Secure Boot firmware not found: $FW"
[ -f "$VARST" ]|| fail "vars template not found: $VARST"

rm -rf "$DIR"; mkdir -p "$DIR"
cp "$VARST" "$DIR/vars-template.fd"

echo "==> building artefacts (throwaway keys) in a debian container"
podman run --rm --network=host -v "$VOL":/work:ro -v "$DIR":/out "$DEB" bash -euo pipefail -c '
  apt-get update -qq >/dev/null 2>&1
  apt-get install -y -qq sbsigntool openssl python3-virt-firmware mtools dosfstools >/dev/null 2>&1
  W=$(mktemp -d)
  cp /work/redox/build/x86_64/eos/bootloader-live.efi "$W/in.efi"
  # our key, and a foreign key for the control
  openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=E-OS SB proof/"     -keyout "$W/our.key"     -out "$W/our.crt"     >/dev/null 2>&1
  openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=foreign not-ours/" -keyout "$W/foreign.key" -out "$W/foreign.crt" >/dev/null 2>&1
  sbsign --key "$W/our.key" --cert "$W/our.crt" --output "$W/signed.efi" "$W/in.efi" >/dev/null
  sbverify --cert "$W/our.crt" "$W/signed.efi" >/dev/null || { echo "offline verify failed"; exit 1; }
  GO=11111111-2222-3333-4444-555555555555; GF=99999999-8888-7777-6666-555555555555
  virt-fw-vars -i /out/vars-template.fd -o /out/vars-our.fd     --set-pk "$GO" "$W/our.crt"     --add-kek "$GO" "$W/our.crt"     --add-db "$GO" "$W/our.crt"     --secure-boot >/dev/null 2>&1
  virt-fw-vars -i /out/vars-template.fd -o /out/vars-foreign.fd --set-pk "$GF" "$W/foreign.crt" --add-kek "$GF" "$W/foreign.crt" --add-db "$GF" "$W/foreign.crt" --secure-boot >/dev/null 2>&1
  for pair in "signed:$W/signed.efi" "unsigned:$W/in.efi"; do
    n=${pair%%:*}; src=${pair#*:}
    dd if=/dev/zero of="/out/esp-$n.img" bs=1M count=20 status=none
    mkfs.vfat "/out/esp-$n.img" >/dev/null
    mmd -i "/out/esp-$n.img" ::/EFI ::/EFI/BOOT
    mcopy -i "/out/esp-$n.img" "$src" ::/EFI/BOOT/BOOTX64.EFI
  done
  shred -u "$W/our.key" "$W/foreign.key" 2>/dev/null || true
' || fail "artefact build failed"

run(){ # $1=vars $2=esp $3=tag
  cp "$DIR/$1" "$DIR/vars-run.fd"
  "$QEMU" -machine q35 -m 512 \
    -drive if=pflash,unit=0,format=raw,readonly=on,file="$FW" \
    -drive if=pflash,unit=1,format=raw,file="$DIR/vars-run.fd" \
    -drive format=raw,file="$DIR/$2" \
    -display none -serial "file:$DIR/$3.serial" -no-reboot >/dev/null 2>&1 &
  local qp=$!; sleep 22; kill "$qp" 2>/dev/null; wait "$qp" 2>/dev/null
}
booted(){ grep -aqiE "E-OS Bootloader|Looking for RedoxFS" "$DIR/$1.serial" 2>/dev/null; }

echo "==> case 1: our key trusted + signed  (expect ACCEPTED)"
run vars-our.fd     esp-signed.img   c1
echo "==> case 2: our key trusted + unsigned (expect REJECTED)"
run vars-our.fd     esp-unsigned.img c2
echo "==> case 3: FOREIGN key trusted + our signed (expect REJECTED)"
run vars-foreign.fd esp-signed.img   c3

f=0
if booted c1; then echo "  [1] ACCEPTED  ✓"; else echo "  [1] rejected  ✗ expected accept"; f=1; fi
if booted c2; then echo "  [2] accepted  ✗ expected reject"; f=1; else echo "  [2] REJECTED  ✓"; fi
if booted c3; then echo "  [3] accepted  ✗ expected reject"; f=1; else echo "  [3] REJECTED  ✓"; fi
echo
[ "$f" -eq 0 ] && echo "secureboot-proof: PASS — signature AND trusted key both required to boot" \
              || { echo "secureboot-proof: FAIL"; exit 1; }
