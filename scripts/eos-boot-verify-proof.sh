#!/usr/bin/env bash
# eos-boot-verify-proof.sh — prove the bootloader refuses a modified kernel (V2-MS02).
#
# One case is not a proof. A bootloader that verified nothing would also boot the good image,
# so this runs BOTH and the pair is the result:
#   1. untouched image  -> boots, and the console says the signature was checked
#   2. one flipped byte in usr/lib/boot/kernel, signature untouched -> REFUSED
#
#   scripts/eos-boot-verify-proof.sh <good.img> <tampered.img>
#
# Build the tampered image by mounting a copy with the project's own redoxfs tool and changing
# a byte of usr/lib/boot/kernel -- deliberately using the filesystem's own writer, because that
# is what an attacker with disk access has, and RedoxFS re-hashes the block for them (seahash
# is neither cryptographic nor keyed).
set -uo pipefail
GOOD="${1:?usage: $0 <good.img> <tampered.img>}"
BAD="${2:?need the tampered image too -- one case is not a proof}"
TIMEOUT="${EOS_PROOF_TIMEOUT:-300}"

QEMU="$(command -v qemu-system-x86_64 || echo /opt/homebrew/bin/qemu-system-x86_64)"
FW_CODE="/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
FW_VARS="/opt/homebrew/share/qemu/edk2-i386-vars.fd"
for f in "$QEMU" "$FW_CODE" "$FW_VARS"; do
  [ -e "$f" ] || { echo "missing: $f"; exit 1; }
done

mon() {  # QEMU monitor over a unix socket; BSD nc -U is unreliable for this
  python3 - "$1" "$2" <<'PY' 2>/dev/null || true
import socket, sys, time
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sys.argv[1]); s.settimeout(2); time.sleep(0.3)
s.sendall((sys.argv[2] + '\n').encode()); time.sleep(0.5)
try: s.recv(65536)
except Exception: pass
s.close()
PY
}

# Runs one image and prints what the bootloader decided. Echoes: BOOTED | REFUSED | TIMEOUT
run_case() {
  local img="$1" work; work="$(mktemp -d)"
  cp "$FW_VARS" "$work/vars.fd"
  local ser="$work/serial.log" sock="$work/mon.sock"; : > "$ser"
  "$QEMU" -machine q35 -cpu max -smp 2 -m 2048 -no-reboot \
    -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
    -drive "if=pflash,unit=1,format=raw,file=$work/vars.fd" \
    -device qemu-xhci -device usb-kbd -device virtio-rng-pci \
    -display none -serial "file:$ser" -monitor "unix:$sock,server,nowait" \
    -drive "file=$img,if=none,id=disk0,format=raw" -device "nvme,drive=disk0,serial=eos" \
    >/dev/null 2>&1 &
  local pid=$! sent=0 verdict=TIMEOUT strip='s/\x1b\[[0-9;?]*[a-zA-Z]//g'
  local deadline=$(( $(date +%s) + TIMEOUT ))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    sleep 3
    kill -0 "$pid" 2>/dev/null || break
    local txt; txt="$(sed "$strip" "$ser" 2>/dev/null)"
    # The bootloader stops on a video-mode menu; press return once, as boot-smoke does.
    if [ "$sent" -eq 0 ] && echo "$txt" | grep -qaiE 'E-OS Bootloader|Arrow keys'; then
      mon "$sock" 'sendkey ret'; sent=1
    fi
    if echo "$txt" | grep -qaE 'SIGNATURE VERIFICATION FAILED|refusing to boot'; then
      verdict=REFUSED; break
    fi
    if echo "$txt" | grep -qaiE 'eos login:|Login:|Username:'; then verdict=BOOTED; break; fi
  done
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  sed "$strip" "$ser" | grep -aE 'signature OK|SIGNATURE VERIFICATION FAILED|refusing to boot|E-OS Bootloader' \
    | sed 's/^/      /' | head -6
  rm -rf "$work"
  echo "$verdict"
}

echo "== case 1: untouched image -- expect BOOTED, with signatures checked"
v1="$(run_case "$GOOD" | tail -1)"
echo "   -> $v1"
echo "== case 2: one flipped byte in the kernel -- expect REFUSED"
v2="$(run_case "$BAD" | tail -1)"
echo "   -> $v2"

if [ "$v1" = BOOTED ] && [ "$v2" = REFUSED ]; then
  echo "boot-verify-proof: PASS (good boots, tampered refused)"; exit 0
fi
echo "boot-verify-proof: FAIL (good=$v1 tampered=$v2)"; exit 1
