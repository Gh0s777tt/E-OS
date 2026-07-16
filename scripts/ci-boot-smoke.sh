#!/usr/bin/env bash
# Boot-smoke an E-OS aarch64 image headlessly and assert it reaches userspace.
# Used by the `build-image` CI job on the self-hosted `eos-heavy` runner (macOS +
# QEMU). Mirrors the proven local harness out/rf08_boot.sh (same machine/cpu/
# firmware/device model). Exits 0 if the boot reaches the login prompt, 1 else.
#
#   scripts/ci-boot-smoke.sh <harddrive.img> [timeout_seconds]
set -uo pipefail

IMG="${1:?usage: ci-boot-smoke.sh <image> [timeout]}"
TIMEOUT="${2:-360}"
[ -f "$IMG" ] || { echo "boot-smoke: image not found: $IMG"; exit 1; }

QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
FW_CODE="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
FW_VARS_SRC="/opt/homebrew/share/qemu/edk2-arm-vars.fd"
[ -x "$QEMU" ] || { echo "boot-smoke: qemu-system-aarch64 not found"; exit 1; }

WORK="$(mktemp -d)"
QPID=""
cleanup() { [ -n "$QPID" ] && kill "$QPID" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT
cp "$FW_VARS_SRC" "$WORK/vars.fd"
SERIAL="$WORK/serial.log"; MON="$WORK/mon.sock"; : > "$SERIAL"

# Send a QEMU monitor command over the unix socket (python3, as in rf08_boot.sh —
# BSD nc's -U behaviour is unreliable for this).
mon() {
  python3 - "$MON" "$1" <<'PY' 2>/dev/null || true
import socket, sys, time
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.connect(sys.argv[1]); s.settimeout(2); time.sleep(0.3)
s.sendall((sys.argv[2] + '\n').encode()); time.sleep(0.5)
try: s.recv(65536)
except Exception: pass
s.close()
PY
}

"$QEMU" -machine virt -cpu cortex-a72 -smp 4 -m 2048 \
  -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
  -drive "if=pflash,unit=1,format=raw,file=$WORK/vars.fd" \
  -device ramfb -device qemu-xhci -device usb-kbd -device usb-tablet -device virtio-rng-pci \
  -display none -serial "file:$SERIAL" -monitor "unix:$MON,server,nowait" \
  -drive "file=$IMG,if=none,id=disk0,format=raw" -device "nvme,drive=disk0,serial=eos" &
QPID=$!
echo "boot-smoke: qemu pid $QPID, up to ${TIMEOUT}s to reach login (init ~100s)…"

strip='s/\x1b\[[0-9;?]*[a-zA-Z]//g'
sent_ret=0; deadline=$(( $(date +%s) + TIMEOUT ))
while [ "$(date +%s)" -lt "$deadline" ]; do
  sleep 3
  kill -0 "$QPID" 2>/dev/null || { echo "boot-smoke: FAIL — qemu exited early"; break; }
  txt="$(sed "$strip" "$SERIAL" 2>/dev/null)"
  # Accept the bootloader video-mode menu once (as rf08_boot.sh does).
  if [ "$sent_ret" -eq 0 ] && echo "$txt" | grep -qaiE 'Redox Loader|E-OS|Genesis|BdsDxe'; then
    mon 'sendkey ret'; sent_ret=1
  fi
  if echo "$txt" | grep -qaiE 'eos login:|^Login:|Username:'; then
    echo "boot-smoke: PASS — reached userspace login"; exit 0
  fi
  if echo "$txt" | grep -qaiE 'KERNEL PANIC|RELIBC PANIC|UNHANDLED EXCEPTION'; then
    echo "boot-smoke: FAIL — panic/exception:"; echo "$txt" | grep -aiE 'PANIC|UNHANDLED' | tail -5
    exit 1
  fi
done
# Fallback: if the menu never matched, we may never have sent ret — retry blind once.
if [ "$sent_ret" -eq 0 ]; then mon 'sendkey ret'; sleep 30
  grep -qaiE 'eos login:|Login:|Username' "$SERIAL" && { echo "boot-smoke: PASS (late)"; exit 0; }
fi
echo "boot-smoke: FAIL — no login prompt before timeout. Last serial:"
sed "$strip" "$SERIAL" | tail -25
exit 1
