#!/usr/bin/env bash
# repro-intx-lines.sh — minimal reproducer for R-F16: on aarch64, a SECOND storage
# driver brought up in the initfs phase on a legacy INTx line different from the
# first one never signals readiness, and the boot stalls before switchroot.
#
# WHY THIS EXISTS: found while building scripts/ci-install-smoke.sh. Attaching a
# second disk — the ordinary thing an installer needs — stops the boot dead, with no
# error message, before the root filesystem is ever mounted. That is a P0 for any
# machine with more than one storage controller, so the evidence needs to be
# re-runnable by anyone rather than living in a chat log.
#
# THE MECHANISM (each step verified, see CHANGELOG U-146):
#   aarch64 has no MSI/MSI-X, so every PCI driver takes a legacy INTx line (the
#   R-401c note in nvmed says as much). When a second storage device lands on a line
#   different from the first, the boot stops silently in initfs -- no panic, no error,
#   the serial log simply ends -- and the root filesystem is never mounted.
#
#   MECHANISM, corrected in U-148 after being published wrong TWICE. The second driver
#   is NOT stuck: with driver logs at Debug it reaches "Initialized!" and "Starting to
#   listen for scheme events", its identify completions succeed (so its interrupts
#   work), and daemon.ready() runs unconditionally in DiskScheme::new
#   (driver-block/src/lib.rs:288) before that line -- so readiness IS signalled and
#   pcid-spawner is NOT blocked. The stall is downstream: 50_rootfs.service (redoxfs,
#   a oneshot) never completes, so 90_initfs.target never completes and init never
#   reaches switch_root("/usr"). redoxfs logs nothing, hence the silence. WHY redoxfs
#   never completes while both drivers' interrupts demonstrably work is still unknown.
#
#   SCOPE, from U-147: this is NOT "only one INTx line ever works". init does two
#   switch_root calls, and after the second one pcid-spawner brings up virtio-netd
#   (line 1) and xhcid (line 2) while the boot disk holds line 0, and the boot reaches
#   a login prompt. The measured defect is specific to the initfs phase.
#
#   SIBLING DEFECT (R-F17), seen in the PASSING rows: with both disks on one line the
#   boot reaches switchroot and then nvmed aborts on
#   "assertion failed: amount == core::mem::size_of::<usize>()"
#   (drivers/executor/src/lib.rs:191) -- the kernel deliberately returns Ok(0) from the
#   irq kwrite for a stale ack, which a shared line makes routine, and the driver
#   asserts instead of handling it. So a "boot" row here is not a clean boot.
#
# THE PREDICTIVE MODEL: on `-machine virt` the INTx line is (slot + pin) % 4. The
# source disk sits at slot 0x4 -> line 0. So a second disk at 0x8 or 0xC also lands
# on line 0 and BOOTS; at 0x5/0x6/0x7/0x9 it lands on lines 1/2/3 and HANGS. This
# script runs that matrix and prints predicted-vs-actual, so a regression (or a fix)
# is visible at a glance.
#
#   scripts/repro-intx-lines.sh <source-image> [seconds-per-boot]
#
# NOTE the control row: a SINGLE disk moved to line 1 boots fine. That is what rules
# out "only line 0 is routed" and pins the defect to *two lines at once*.
set -uo pipefail

IMG="${1:?usage: repro-intx-lines.sh <source-image> [seconds-per-boot]}"
WAIT="${2:-75}"
[ -f "$IMG" ] || { echo "repro-intx: image not found: $IMG"; exit 1; }

QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
FW_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
FW_VARS=/opt/homebrew/share/qemu/edk2-arm-vars.fd
[ -x "$QEMU" ] || { echo "repro-intx: qemu-system-aarch64 not found"; exit 1; }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
BLANK="$WORK/blank.img"
dd if=/dev/zero of="$BLANK" bs=1m count=0 seek=4096 2>/dev/null

# Boot once and report whether a login prompt was reached. $1 = label, rest = -device args.
boot_once() {
  label="$1"; shift
  cp "$FW_VARS" "$WORK/vars.fd"
  log="$WORK/serial.log"; mon="$WORK/mon.sock"; rm -f "$log" "$mon"
  "$QEMU" -machine virt -cpu cortex-a72 -smp 4 -m 2048 \
    -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
    -drive "if=pflash,unit=1,format=raw,file=$WORK/vars.fd" \
    -device ramfb -device qemu-xhci -device usb-kbd -device virtio-rng-pci \
    -display none -serial "file:$log" -monitor "unix:$mon,server,nowait" \
    "$@" >/dev/null 2>&1 &
  qpid=$!
  # The bootloader's video-mode menu reads the emulated KEYBOARD, not the serial line,
  # so the Enter that dismisses it has to go through the QEMU monitor.
  python3 -c "import time;time.sleep(12)"
  python3 - "$mon" <<'PY'
import socket, sys, time
try:
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect(sys.argv[1])
    time.sleep(0.3); s.sendall(b"sendkey ret\n"); time.sleep(0.5); s.close()
except Exception:
    pass
PY
  python3 -c "import time;time.sleep($WAIT)"
  kill "$qpid" 2>/dev/null
  python3 -c "import time;time.sleep(1)"
  if grep -q "login:" "$log" 2>/dev/null; then echo "boot"; else echo "hang"; fi
}

printf '%-46s %-6s %-9s %-9s %s\n' "CONFIGURATION" "LINE" "PREDICTED" "ACTUAL" "VERDICT"
fail=0
check() { # $1 label  $2 line  $3 predicted  $4.. device args
  lbl="$1"; line="$2"; pred="$3"; shift 3
  act="$(boot_once "$lbl" "$@")"
  if [ "$act" = "$pred" ]; then v="ok"; else v="MISMATCH"; fail=1; fi
  printf '%-46s %-6s %-9s %-9s %s\n' "$lbl" "$line" "$pred" "$act" "$v"
}

SRC=(-drive "file=$IMG,if=none,id=d0,format=raw")
check "source disk alone (slot 0x4)"              "0"   boot "${SRC[@]}" -device "nvme,drive=d0,serial=eos"
check "source disk alone, moved to slot 0x5"      "1"   boot "${SRC[@]}" -device "nvme,drive=d0,serial=eos,addr=0x5"

for slot in 0x5 0x6 0x7 0x8 0x9 0xc; do
  # (slot + pin) % 4, pin 0 for INTA — 0x8 and 0xc collapse back onto line 0.
  case "$slot" in
    0x5) line=1; pred=hang ;;
    0x6) line=2; pred=hang ;;
    0x7) line=3; pred=hang ;;
    0x8) line=0; pred=boot ;;
    0x9) line=1; pred=hang ;;
    0xc) line=0; pred=boot ;;
  esac
  check "+ blank second disk at slot $slot" "$line" "$pred" \
    "${SRC[@]}" -device "nvme,drive=d0,serial=eos" \
    -drive "file=$BLANK,if=none,id=d1,format=raw" -device "nvme,drive=d1,serial=tgt,addr=$slot"
done

# Not an nvmed bug: a different driver on a different line stalls identically.
check "+ blank second disk, virtio-blk at 0x5"    "1"   hang \
  "${SRC[@]}" -device "nvme,drive=d0,serial=eos" \
  -drive "file=$BLANK,if=none,id=d1,format=raw" -device "virtio-blk-pci,drive=d1,addr=0x5"

echo
if [ "$fail" -eq 0 ]; then
  echo "repro-intx: R-F16 REPRODUCED — every row matched the model (different INTx line => boot stalls)."
  echo "repro-intx: a FIX should turn every 'hang' row into 'boot'; this script will then report MISMATCH."
else
  echo "repro-intx: MISMATCH — behaviour changed. Either R-F16 was fixed (all rows boot) or the model is wrong."
fi
exit 0
