#!/usr/bin/env bash
# Boot-smoke an E-OS image headlessly and assert it reaches userspace.
# Used by the `build-image` jobs on the self-hosted `eos-heavy` runner (macOS +
# QEMU). The aarch64 path mirrors the proven local harness out/rf08_boot.sh (same
# machine/cpu/firmware/device model). Exits 0 if the boot reaches the login
# prompt, 1 else.
#
#   scripts/ci-boot-smoke.sh <image> [timeout_seconds] [--arch aarch64|x86_64]
#
# x86_64 runs under TCG on an Apple Silicon runner and was long assumed too slow
# to gate on. Measured 2026-08-21: a live image reaches `eos login:` in about a
# minute, so it is worth running — see docs/ci.md. Works for both harddrive.img
# and the redox-live.iso produced by `make live` (both are raw GPT images).
set -uo pipefail

IMG="${1:?usage: ci-boot-smoke.sh <image> [timeout] [--arch aarch64|x86_64]}"
TIMEOUT="${2:-360}"
[ -f "$IMG" ] || { echo "boot-smoke: image not found: $IMG"; exit 1; }

# `--arch` may appear anywhere after the positionals; default stays aarch64 so
# existing call sites keep working unchanged.
ARCH="aarch64"
prev_arg=""   # must be initialised: the script runs under `set -u`
for a in "$@"; do case "$prev_arg" in --arch) ARCH="$a";; esac; prev_arg="$a"; done
case "$ARCH" in
  aarch64)
    QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
    FW_CODE="/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
    FW_VARS_SRC="/opt/homebrew/share/qemu/edk2-arm-vars.fd"
    # ramfb is the virt-board framebuffer; q35 has none and rejects it.
  # Hardware acceleration is OPT-IN, and deliberately not the default: E-OS is NOT stable
  # under hvf. Boot-smoke passes under it, but under sustained load
  # the guest dies with `synchronous_exception_at_el0` -- twice, in two different processes
  # (ptyd at file 77/13679, virtio-netd at 19/13679 with -smp 1), so it is not a multi-core
  # race. Recorded as R-F23. Set EOS_SMOKE_ACCEL=hvf to reproduce it; leave it unset for a
  # trustworthy run. MEASURED, not estimated: boot to login is 19s under TCG and 10s under
# hvf -- about 1.9x, not the order of magnitude the raw speed of the copy suggested.
    if [ "${EOS_SMOKE_ACCEL:-}" = "hvf" ] && [ "$(uname -m)" = "arm64" ]; then
      MACHINE_ARGS=(-machine virt,accel=hvf -cpu host -device ramfb)
    else
      MACHINE_ARGS=(-machine virt -cpu cortex-a72 -device ramfb)
    fi
    ;;
  x86_64)
    QEMU="$(command -v qemu-system-x86_64 || echo /opt/homebrew/bin/qemu-system-x86_64)"
    FW_CODE="/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
    # OVMF ships its writable vars as the i386 file even for the x86_64 build.
    FW_VARS_SRC="/opt/homebrew/share/qemu/edk2-i386-vars.fd"
    MACHINE_ARGS=(-machine q35 -cpu max)
    ;;
  *) echo "boot-smoke: unsupported --arch '$ARCH' (aarch64|x86_64)"; exit 2 ;;
esac
[ -x "$QEMU" ] || { echo "boot-smoke: qemu for $ARCH not found"; exit 1; }
[ -f "$FW_CODE" ] || { echo "boot-smoke: firmware not found: $FW_CODE"; exit 1; }

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

"$QEMU" "${MACHINE_ARGS[@]}" -smp "${EOS_SMOKE_SMP:-4}" -m 2048 \
  -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
  -drive "if=pflash,unit=1,format=raw,file=$WORK/vars.fd" \
  -device qemu-xhci -device usb-kbd -device usb-tablet -device virtio-rng-pci \
  -display none -serial "file:$SERIAL" -monitor "unix:$MON,server,nowait" \
  -drive "file=$IMG,if=none,id=disk0,format=raw" -device "nvme,drive=disk0,serial=eos" &
QPID=$!
echo "boot-smoke: $ARCH, qemu pid $QPID, up to ${TIMEOUT}s to reach login (TCG: 19s measured)…"

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
