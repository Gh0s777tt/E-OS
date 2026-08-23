#!/usr/bin/env bash
# ci-install-smoke.sh — the end-to-end R-601 proof: boot the image, drive the installer
# onto a second disk, then boot THAT disk and assert it reaches a login prompt.
#
# WHY THIS EXISTS: every "daily driver" claim rests on booting a PRE-BUILT image.
# ci-boot-smoke.sh attaches one drive and asserts a login prompt, which is a different
# and much weaker claim than "this system can install itself and boot the result".
#
#   scripts/ci-install-smoke.sh <source-image> [seconds] [--arch aarch64]
#
# TWO BLOCKERS USED TO MAKE THIS IMPOSSIBLE, AND BOTH ARE GONE (U-161):
#
#   1. A second disk stalled the boot outright (R-F16). Fixed in U-153: a
#      read-modify-write on the write-one-to-clear GICD_ICENABLER disabled every enabled
#      interrupt in a 32-IRQ block instead of one.
#
#   2. "Serial input is not delivered to the guest -- 0 RX interrupts." That was recorded
#      beside 30_serial-getty.service and repeated in R-601 and in this file's own earlier
#      header. It is FALSE now, and almost certainly for the same reason: the UART's line
#      shared a block with the storage IRQ, so the same RMW masked it. Measured: typing
#      `user` at the login prompt echoes back character by character.
#
# The installer binary is `redox_installer_tui` -- NOT `installer_tui`, which this file
# used to invoke and which does not exist in the image (`ion: command not found`).
set -uo pipefail

IMG="${1:?usage: ci-install-smoke.sh <source-image> [seconds] [--arch aarch64]}"
BUDGET="${2:-600}"
ARCH="aarch64"; prev=""
for a in "$@"; do case "$prev" in --arch) ARCH="$a";; esac; prev="$a"; done
[ -f "$IMG" ] || { echo "install-smoke: image not found: $IMG"; exit 1; }
[ "$ARCH" = "aarch64" ] || { echo "install-smoke: only aarch64 is wired up"; exit 2; }

QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
FW_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
FW_VARS=/opt/homebrew/share/qemu/edk2-arm-vars.fd
[ -x "$QEMU" ] || { echo "install-smoke: qemu-system-aarch64 not found"; exit 1; }

WORK="$(mktemp -d)"; QPID=""
cleanup() { [ -n "$QPID" ] && kill "$QPID" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

# The source image is COPIED: the installer writes to the target, but the run also sets a
# password and otherwise mutates the source. A harness must not leave its input changed.
cp "$IMG" "$WORK/src.img"
# 4 GiB blank target. Sparse, so it costs nothing until written, and non-zero-length or
# the installer's disk_paths() skips it (`if size > 0`).
dd if=/dev/zero of="$WORK/target.img" bs=1m count=0 seek=4096 2>/dev/null
cp "$FW_VARS" "$WORK/vars.fd"

boot() { # $1=vars $2=serial-sock $3=monitor-sock  $4.. = drives
  local vars="$1" ser="$2" mon="$3"; shift 3
  "$QEMU" -machine virt -cpu cortex-a72 -smp 4 -m 2048 \
    -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
    -drive "if=pflash,unit=1,format=raw,file=$vars" \
    -device ramfb -device qemu-xhci -device usb-kbd -device virtio-rng-pci \
    -display none -serial "unix:$ser,server,nowait" -monitor "unix:$mon,server,nowait" \
    "$@" >/dev/null 2>&1 &
  QPID=$!
}

echo "install-smoke: stage 1 — install onto a blank second disk"
boot "$WORK/vars.fd" "$WORK/s1.sock" "$WORK/m1.sock" \
  -drive "file=$WORK/src.img,if=none,id=d0,format=raw" -device "nvme,drive=d0,serial=eos" \
  -drive "file=$WORK/target.img,if=none,id=d1,format=raw" -device "nvme,drive=d1,serial=tgt"

python3 "$(dirname "$0")/install-smoke-drive.py" install \
  "$WORK/m1.sock" "$WORK/s1.sock" "$BUDGET" "$WORK/stage1.log"
rc=$?
kill "$QPID" 2>/dev/null; QPID=""; sleep 1
cp "$WORK/stage1.log" "$(dirname "$IMG")/install-smoke-stage1.log" 2>/dev/null
[ "$rc" -eq 0 ] || { echo "install-smoke: FAIL — install stage did not complete"; exit 1; }

echo "install-smoke: stage 2 — boot the INSTALLED disk on its own"
cp "$FW_VARS" "$WORK/vars2.fd"
boot "$WORK/vars2.fd" "$WORK/s2.sock" "$WORK/m2.sock" \
  -drive "file=$WORK/target.img,if=none,id=d0,format=raw" -device "nvme,drive=d0,serial=eos"

python3 "$(dirname "$0")/install-smoke-drive.py" verify \
  "$WORK/m2.sock" "$WORK/s2.sock" "$BUDGET" "$WORK/stage2.log"
rc=$?
cp "$WORK/stage2.log" "$(dirname "$IMG")/install-smoke-stage2.log" 2>/dev/null
if [ "$rc" -eq 0 ]; then
  echo "install-smoke: PASS — installed to a second disk and booted it to a login prompt"
else
  echo "install-smoke: FAIL — the installed disk did not reach a login prompt"
fi
exit $rc
