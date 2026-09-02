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

# R-601c. The arch block is lifted from ci-boot-smoke.sh rather than re-derived: those
# values are already proven on this host, and a second, independently-guessed copy is how
# two harnesses come to disagree about the same machine. Three details are not free choices:
#   * OVMF ships its writable vars as the i386 file even for the x86_64 build;
#   * ramfb is the virt-board framebuffer -- q35 has none and REJECTS the device, so it
#     cannot simply be passed on both arches;
#   * -cpu max on q35, because Redox needs features cortex-a72's x86 counterpart lacks.
case "$ARCH" in
  aarch64)
    QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
    FW_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
    FW_VARS=/opt/homebrew/share/qemu/edk2-arm-vars.fd
    ;;
  x86_64)
    QEMU="$(command -v qemu-system-x86_64 || echo /opt/homebrew/bin/qemu-system-x86_64)"
    FW_CODE=/opt/homebrew/share/qemu/edk2-x86_64-code.fd
    FW_VARS=/opt/homebrew/share/qemu/edk2-i386-vars.fd
    ;;
  *) echo "install-smoke: unsupported --arch '$ARCH' (aarch64|x86_64)"; exit 2 ;;
esac
[ -x "$QEMU" ] || { echo "install-smoke: qemu for $ARCH not found: $QEMU"; exit 1; }
[ -f "$FW_CODE" ] || { echo "install-smoke: firmware not found: $FW_CODE"; exit 1; }
[ -f "$FW_VARS" ] || { echo "install-smoke: firmware vars not found: $FW_VARS"; exit 1; }

# The harness needs ~5.5 GiB of scratch: a full copy of the source image plus a 4 GiB target.
# It used to take that from the system temp without asking, and when the system temp was full
# the failure did not mention disk space at all -- `cp` failed, qemu was handed a ZERO-BYTE
# firmware vars file, and the run reported:
#
#     qemu-system-x86_64: system firmware block device pflash1 has invalid size 0
#
# A reader chasing that message looks at firmware and QEMU, which are both fine. So: the work
# directory can be pointed somewhere with room (EOS_SMOKE_WORK), and the space is checked
# BEFORE anything is copied, so the run says what is actually wrong.
WORK="$(mktemp -d "${EOS_SMOKE_WORK:-${TMPDIR:-/tmp}}/eos-install-smoke.XXXXXX")"
NEED_MIB=6000
avail_mib() { df -m "$1" 2>/dev/null | awk 'NR==2 {print $4}'; }
HAVE="$(avail_mib "$WORK")"
if [ -n "$HAVE" ] && [ "$HAVE" -lt "$NEED_MIB" ]; then
  echo "install-smoke: FAIL (instrument) -- $WORK has ${HAVE} MiB free, this run needs ~${NEED_MIB} MiB." >&2
  echo "               A source-image copy plus a 4 GiB target do not fit. Point the scratch" >&2
  echo "               directory somewhere with room: EOS_SMOKE_WORK=/path $0 ..." >&2
  rmdir "$WORK" 2>/dev/null
  exit 2
fi
QPID=""; QLOG=""
# Keep the evidence when a run fails. Deleting $WORK unconditionally -- which this used to
# do -- means a failure tells you THAT something broke and never what: R-F25 was chased for
# three runs with no serial log, no qemu log and no exit status, because all three were
# removed the moment the script exited.
# WHERE it lands matters as much as WHETHER it is kept. The default used to be next to the
# source image, which in CI is the runner's build directory on the BOOT volume -- measured
# 2026-09-01 at 2.2 GiB free against a 1.7 GiB copy. A failure would then take the disk down
# with it, and the next job would report "no space left on device" for something unrelated:
# an error blamed on a place that had nothing to do with it. The scratch directory is already
# pointed somewhere with room (EOS_SMOKE_WORK), so evidence follows it.
#
# WHAT is kept is trimmed for the same reason. src.img is a copy of an input that still exists,
# and target.img is 4 GiB sparse; neither is what you read first. Logs, the monitor socket
# transcript and the UEFI vars are what diagnose a run. Set EOS_SMOKE_KEEP_IMAGES=1 when the
# disks themselves are the question -- e.g. checking what the installer actually wrote.
keep_work() {
  dest="${EOS_SMOKE_KEEP:-${EOS_SMOKE_WORK:-$(dirname "$IMG")}}/install-smoke-failed"
  rm -rf "$dest" 2>/dev/null
  mkdir -p "$dest" 2>/dev/null || return 0
  if [ "${EOS_SMOKE_KEEP_IMAGES:-0}" = "1" ]; then
    cp -R "$WORK"/. "$dest" 2>/dev/null
  else
    # everything except the two disk images
    find "$WORK" -maxdepth 1 -type f ! -name 'src.img' ! -name 'target.img' \
      -exec cp {} "$dest/" \; 2>/dev/null
  fi
  echo "install-smoke: evidence kept in $dest ($(du -sh "$dest" 2>/dev/null | cut -f1))"
  [ "${EOS_SMOKE_KEEP_IMAGES:-0}" = "1" ] || \
    echo "install-smoke:   disk images NOT kept — re-run with EOS_SMOKE_KEEP_IMAGES=1 for those"
}
cleanup() { [ -n "$QPID" ] && kill "$QPID" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

# The source image is COPIED: the installer writes to the target, but the run also sets a
# password and otherwise mutates the source. A harness must not leave its input changed.
cp "$IMG" "$WORK/src.img" || { echo "install-smoke: FAIL (instrument) -- could not copy the source image into $WORK" >&2; exit 2; }
# 4 GiB blank target. Sparse, so it costs nothing until written, and non-zero-length or
# the installer's disk_paths() skips it (`if size > 0`).
dd if=/dev/zero of="$WORK/target.img" bs=1m count=0 seek=4096 2>/dev/null
cp "$FW_VARS" "$WORK/vars.fd" || { echo "install-smoke: FAIL (instrument) -- could not copy firmware vars into $WORK" >&2; exit 2; }
[ -s "$WORK/vars.fd" ] || { echo "install-smoke: FAIL (instrument) -- firmware vars copy is EMPTY; qemu would report 'pflash1 has invalid size 0'" >&2; exit 2; }

# Hardware acceleration is OPT-IN, and deliberately not the default: E-OS is NOT stable
# under hvf. Boot-smoke passes under it, but under sustained load
# the guest dies with `synchronous_exception_at_el0` -- twice, in two different processes
# (ptyd at file 77/13679, virtio-netd at 19/13679 with -smp 1), so it is not a multi-core
# race. Recorded as R-F23. Set EOS_SMOKE_ACCEL=hvf to reproduce it; leave it unset for a
# trustworthy run. MEASURED, not estimated: boot to login is 19s under TCG and 10s under
# hvf -- about 1.9x, not the order of magnitude the raw speed of the copy suggested.
# The video device is folded INTO this array rather than kept in a second one, and that is
# not a style choice. A separate `VIDEO_ARGS=()` for x86_64 is an EMPTY array, and expanding
# an empty array under `set -u` is an "unbound variable" fatal in bash 3.2 -- which is what
# /bin/bash is on the reference host. Measured, after I wrote exactly that bug: the harness
# died with `line 100: VIDEO_ARGS[@]: unbound variable` before qemu ever started, and
# ci-integrity check 5 still reported "no bash-4-only syntax". ci-boot-smoke.sh has never had
# this defect because it never split the arrays; re-deriving instead of copying is what
# introduced it here.
if [ "$ARCH" = "x86_64" ]; then
  # No hvf at all on this path: the reference host is arm64, so x86_64 is emulation by
  # definition. ramfb is deliberately absent -- it is the virt-board framebuffer and q35
  # REJECTS it, so passing it on both arches would fail to start the guest.
  ACCEL_ARGS=(-machine q35 -cpu max)
elif [ "${EOS_SMOKE_ACCEL:-}" = "hvf" ] && [ "$(uname -m)" = "arm64" ]; then
  ACCEL_ARGS=(-machine virt,accel=hvf -cpu host -device ramfb)
else
  ACCEL_ARGS=(-machine virt -cpu cortex-a72 -device ramfb)
fi

boot() { # $1=vars $2=serial-sock $3=monitor-sock  $4.. = drives
  local vars="$1" ser="$2" mon="$3"; shift 3
  "$QEMU" "${ACCEL_ARGS[@]}" -smp "${EOS_SMOKE_SMP:-4}" -m "${EOS_SMOKE_MEM:-2048}" \
    -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
    -drive "if=pflash,unit=1,format=raw,file=$vars" \
    -device qemu-xhci -device usb-kbd -device virtio-rng-pci \
    -display none -serial "unix:$ser,server,nowait" -monitor "unix:$mon,server,nowait" \
    "$@" >"$WORK/qemu-$(basename "$ser" .sock).log" 2>&1 &
  QPID=$!
  QLOG="$WORK/qemu-$(basename "$ser" .sock).log"
}

# The driver's step windows were measured on aarch64, where this host runs QEMU close to
# native. x86_64 is emulation on an arm64 box, and the difference is not a constant offset:
# MEASURED, the same flow needed THREE login attempts because attempts 1 and 2 timed out at
# the shell prompt and the password confirmation before the guest had warmed up. Scaling the
# windows says "same steps, slower machine"; raising every constant would instead slow the
# FAILURE path down on the arch where the numbers are already right.
if [ "$ARCH" = "x86_64" ]; then
  export EOS_SMOKE_SLOW="${EOS_SMOKE_SLOW:-3}"
  echo "install-smoke: x86_64 under TCG — step windows scaled x$EOS_SMOKE_SLOW"
fi

echo "install-smoke: stage 1 — install onto a blank second disk"
boot "$WORK/vars.fd" "$WORK/s1.sock" "$WORK/m1.sock" \
  -drive "file=$WORK/src.img,if=none,id=d0,format=raw" -device "nvme,drive=d0,serial=eos" \
  -drive "file=$WORK/target.img,if=none,id=d1,format=raw" -device "nvme,drive=d1,serial=tgt"

# The 6th argument is the target disk. The driver stats it either side of the deliberate
# wrong-name refusal, so "nothing was written" is measured rather than inferred from the
# install starting afterwards (R-604a asked for both halves; only one was ever shown).
python3 -u "$(dirname "$0")/install-smoke-drive.py" install \
  "$WORK/m1.sock" "$WORK/s1.sock" "$BUDGET" "$WORK/stage1.log" "$WORK/target.img"
rc=$?
# Report what happened to QEMU instead of inferring it from the process being gone. The
# guest dying and the harness killing it look identical from outside; the exit status and
# qemu's own output tell them apart (R-F25). Until now this ran with >/dev/null 2>&1, so
# every message qemu produced was discarded -- the silence was ours, not qemu's.
if [ -n "$QPID" ] && ! kill -0 "$QPID" 2>/dev/null; then
  wait "$QPID" 2>/dev/null; qrc=$?
  echo "install-smoke: qemu exited on its own, status $qrc"
  [ -s "$QLOG" ] && { echo "install-smoke: --- qemu output ---"; tail -5 "$QLOG"; }
fi
kill "$QPID" 2>/dev/null; QPID=""; sleep 1
cp "$WORK/stage1.log" "$(dirname "$IMG")/install-smoke-stage1.log" 2>/dev/null
[ "$rc" -eq 0 ] || { keep_work; echo "install-smoke: FAIL — install stage did not complete"; exit 1; }

echo "install-smoke: stage 2 — boot the INSTALLED disk on its own"
cp "$FW_VARS" "$WORK/vars2.fd"
boot "$WORK/vars2.fd" "$WORK/s2.sock" "$WORK/m2.sock" \
  -drive "file=$WORK/target.img,if=none,id=d0,format=raw" -device "nvme,drive=d0,serial=eos"

python3 -u "$(dirname "$0")/install-smoke-drive.py" verify \
  "$WORK/m2.sock" "$WORK/s2.sock" "$BUDGET" "$WORK/stage2.log"
rc=$?
cp "$WORK/stage2.log" "$(dirname "$IMG")/install-smoke-stage2.log" 2>/dev/null
if [ "$rc" -eq 0 ]; then
  echo "install-smoke: PASS — installed to a second disk and booted it to a login prompt"
else
  echo "install-smoke: FAIL — the installed disk did not reach a login prompt"
fi
exit $rc
