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
#   MECHANISM, corrected in U-148 and then CONFIRMED DIRECTLY in U-150. The second
#   driver is NOT stuck: with driver logs at Debug it reaches "Initialized!" and
#   "Starting to listen for scheme events", its identify completions succeed (so its
#   interrupts work), and daemon.ready() runs unconditionally in DiskScheme::new
#   (driver-block/src/lib.rs:288) before that line. Making init itself verbose then
#   settled it without inference -- the trace reads:
#
#       Reached target Initfs drivers        <- pcid-spawner finished
#       Starting Rootfs (redoxfs)            <- 50_rootfs.service started
#       (nothing, ever)
#
#   So 40_drivers.target completes and the stall is INSIDE redoxfs, which logs nothing.
#   WHY redoxfs never completes, while both disk drivers' own interrupts demonstrably
#   work, is still unknown.
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
# 180s by default: most configurations reach a login prompt in under 30s, but a second
# storage device sharing the xHCI INTx line takes ~124s (R-F18) -- a real, reproducible
# degradation, not host noise. A tighter budget reports that as a failure and hides the
# actual defect behind a timeout. Rows are polled, so a fast row costs only its real time.
WAIT="${2:-180}"
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
  # Poll rather than sleep the whole budget: a fast row finishes in its own time, and the
  # elapsed seconds become data. R-F18 was found because this column exists.
  secs="$(python3 -c '
import sys, time
log, budget = sys.argv[1], int(sys.argv[2])
t0 = time.time()
while time.time() - t0 < budget:
    try:
        if "login:" in open(log, encoding="utf-8", errors="replace").read():
            print(int(time.time() - t0) + 12); break
    except OSError:
        pass
    time.sleep(1)
else:
    print("-")
' "$log" "$WAIT")"
  kill "$qpid" 2>/dev/null
  python3 -c "import time;time.sleep(1)"
  if [ "$secs" != "-" ]; then
    echo "boot:$secs"
  else
    # Keep the serial log of a failing row. Deleting it -- which this script used to do --
    # means a FAIL tells you that something broke, but never what.
    keep="${KEEP_DIR:-$(dirname "$IMG")}/repro-intx-fail-$(echo "$label" | tr -c "A-Za-z0-9" "-").log"
    cp "$log" "$keep" 2>/dev/null && echo "hang(log:$keep)" || echo "hang"
  fi
}

printf '%-46s %-6s %-9s %-9s %-7s %s\n' "CONFIGURATION" "LINE" "PREDICTED" "ACTUAL" "TIME" "VERDICT"
fail=0
check() { # $1 label  $2 line  $3 predicted  $4.. device args
  lbl="$1"; line="$2"; pred="$3"; shift 3
  raw="$(boot_once "$lbl" "$@")"
  case "$raw" in
    boot:*) act=boot; secs="${raw#boot:}s" ;;
    *)      act=hang; secs="-" ;;
  esac
  if [ "$act" = "$pred" ]; then v="ok"; else v="MISMATCH"; fail=1; fi
  printf '%-46s %-6s %-9s %-9s %-7s %s\n' "$lbl" "$line" "$pred" "$act" "$secs" "$v"
}

SRC=(-drive "file=$IMG,if=none,id=d0,format=raw")
check "source disk alone (slot 0x4)"              "0"   boot "${SRC[@]}" -device "nvme,drive=d0,serial=eos"
check "source disk alone, moved to slot 0x5"      "1"   boot "${SRC[@]}" -device "nvme,drive=d0,serial=eos,addr=0x5"

for slot in 0x5 0x6 0x7 0x8 0x9 0xc; do
  # (slot + pin) % 4, pin 0 for INTA — 0x8 and 0xc collapse back onto line 0.
  case "$slot" in
    0x5) line=1; pred=boot ;;
    0x6) line=2; pred=boot ;;
    0x7) line=3; pred=boot ;;
    0x8) line=0; pred=boot ;;
    0x9) line=1; pred=boot ;;
    0xc) line=0; pred=boot ;;
  esac
  check "+ blank second disk at slot $slot" "$line" "$pred" \
    "${SRC[@]}" -device "nvme,drive=d0,serial=eos" \
    -drive "file=$BLANK,if=none,id=d1,format=raw" -device "nvme,drive=d1,serial=tgt,addr=$slot"
done

# Not an nvmed bug: a different driver on a different line stalls identically.
check "+ blank second disk, virtio-blk at 0x5"    "1"   boot \
  "${SRC[@]}" -device "nvme,drive=d0,serial=eos" \
  -drive "file=$BLANK,if=none,id=d1,format=raw" -device "virtio-blk-pci,drive=d1,addr=0x5"

# The control that pins the defect to PCI/INTx rather than to "a second block device":
# a USB disk is not a PCI function, takes no INTx line, and boots (U-150).
check "+ blank second disk over USB (no PCI)"     "-"   boot \
  "${SRC[@]}" -device "nvme,drive=d0,serial=eos" \
  -drive "file=$BLANK,if=none,id=d1,format=raw" -device "usb-storage,drive=d1"

echo
if [ "$fail" -eq 0 ]; then
  echo "repro-intx: PASS — every configuration boots, including a second PCI storage"
  echo "repro-intx:        controller on its own INTx line. R-F16 stays fixed."
else
  echo "repro-intx: FAIL — a configuration that must boot did not. R-F16 has regressed,"
  echo "repro-intx:        or a new interrupt-routing defect has appeared. Read the logs."
fi
exit 0
