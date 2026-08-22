#!/usr/bin/env bash
# ci-install-smoke.sh — R-601 harness: boot with a second (target) disk attached and
# assert the system still reaches a login prompt, then try to drive `installer_tui`
# over the serial console.
#
# WHY THIS EXISTS: every "daily driver" claim in this repo rests on booting a
# PRE-BUILT image. Nobody has verified that E-OS can install ITSELF onto a second
# disk and boot the result — `scripts/ci-boot-smoke.sh` attaches ONE drive and
# asserts a login prompt, which is a weaker claim.
#
#   scripts/ci-install-smoke.sh <source-image> [timeout] [--arch aarch64|x86_64]
#
# WHAT IT PROVES TODAY, AND WHAT IT DOES NOT — read this before trusting a PASS:
#
#   PROVEN: the system boots to `eos login:` with a second disk attached. That is a
#   regression test for R-F16 (below) and it is not nothing — until U-146 nobody had
#   ever booted this OS with more than one disk.
#
#   NOT PROVEN: partition -> install -> reboot -> login. The installer cannot be
#   driven from here, because interactive input over QEMU's macOS unix-socket serial
#   is not delivered to the guest — 0 RX interrupts, already recorded in
#   `config/aarch64/eos.toml` next to `30_serial-getty.service`. Output flows fine;
#   only input is dead. Finishing R-601 on this host therefore needs the keyboard
#   path (QEMU monitor `sendkey`) plus `screendump` for verification, exactly as the
#   roadmap entry says ("script-drive installer_tui, then the GUI"). This script
#   demonstrates the limitation rather than asserting it: it types, waits for an
#   echo, and reports the absence.
#
# R-F16 — WHY THE TARGET DISK SITS AT PCI SLOT 0x8: building this harness found a
# boot-stopping defect. aarch64 has no MSI/MSI-X, so every PCI driver takes a legacy
# INTx line (the R-401c note in nvmed says as much). In the initfs phase a second
# storage driver on a DIFFERENT INTx line never receives an interrupt, never
# signals readiness, and since `pcid-spawner` blocks per-device in `Daemon::spawn`
# and runs as a `oneshot` unit, `40_drivers.target` never completes, so
# `50_rootfs.service` never runs and init never reaches switchroot. The boot stops
# silently, before the root filesystem is mounted. On `-machine virt` the line is
# (slot + pin) % 4 and the source disk is at slot 0x4 (line 0), so 0x8 and 0xC also
# land on line 0 and work, while 0x5/0x6/0x7/0x9 hang. `scripts/repro-intx-lines.sh`
# runs the whole matrix. The slot default here is a WORKAROUND, not a fix.
#
# SCOPE, corrected in U-147: this is not a claim about every boot phase. init does
# two switch_root calls, and after the second one pcid-spawner brings up virtio-netd
# (line 1) and xhcid (line 2) while the boot disk holds line 0, and the boot reaches
# a login prompt. The measured defect is specific to the initfs phase.
set -uo pipefail

IMG="${1:?usage: ci-install-smoke.sh <source-image> [timeout] [--arch aarch64|x86_64]}"
TIMEOUT="${2:-300}"
TARGET_SLOT="${EOS_TARGET_SLOT:-0x8}"   # see R-F16 above
TARGET_IF="${EOS_TARGET_IF:-nvme}"      # nvme | virtio-blk (the stall reproduces with both)
ARCH="aarch64"; prev=""
for a in "$@"; do case "$prev" in --arch) ARCH="$a";; esac; prev="$a"; done
[ -f "$IMG" ] || { echo "install-smoke: image not found: $IMG"; exit 1; }

case "$ARCH" in
  aarch64) QEMU="$(command -v qemu-system-aarch64 || echo /opt/homebrew/bin/qemu-system-aarch64)"
           FW_CODE=/opt/homebrew/share/qemu/edk2-aarch64-code.fd
           FW_VARS=/opt/homebrew/share/qemu/edk2-arm-vars.fd
           MACHINE=(-machine virt -cpu cortex-a72 -device ramfb) ;;
  x86_64)  QEMU="$(command -v qemu-system-x86_64 || echo /opt/homebrew/bin/qemu-system-x86_64)"
           FW_CODE=/opt/homebrew/share/qemu/edk2-x86_64-code.fd
           FW_VARS=/opt/homebrew/share/qemu/edk2-i386-vars.fd
           # x86_64 has MSI/MSI-X, so the R-F16 slot dance should not apply there —
           # UNVERIFIED, no x86_64 image has been built on this host.
           MACHINE=(-machine q35 -cpu max) ;;
  *) echo "install-smoke: unsupported --arch '$ARCH'"; exit 2 ;;
esac
[ -x "$QEMU" ] || { echo "install-smoke: qemu for $ARCH not found"; exit 1; }

WORK="$(mktemp -d)"; QPID=""
cleanup(){ [ -n "$QPID" ] && kill "$QPID" 2>/dev/null; rm -rf "$WORK"; }
trap cleanup EXIT

TARGET="$WORK/target.img"
# 4 GiB blank target. Sparse, so it costs nothing until written. It must be
# non-zero-length or installer_tui's disk_paths() skips it (`if size > 0`).
dd if=/dev/zero of="$TARGET" bs=1m count=0 seek=4096 2>/dev/null
cp "$FW_VARS" "$WORK/vars.fd"
SER="$WORK/ser.sock"; MON="$WORK/mon.sock"

# An array, not a string: the earlier form built the -drive/-device pair inside a
# command substitution and leaned on word splitting, which breaks the moment a path
# contains a space — and this tree lives under "/Volumes/Project itp".
DRIVES=(-drive "file=$IMG,if=none,id=disk0,format=raw" -device "nvme,drive=disk0,serial=eos")
if [ -z "${EOS_NO_TARGET_DISK:-}" ]; then
  DRIVES+=(-drive "file=$TARGET,if=none,id=disk1,format=raw")
  case "$TARGET_IF" in
    nvme)       DRIVES+=(-device "nvme,drive=disk1,serial=target,addr=$TARGET_SLOT") ;;
    virtio-blk) DRIVES+=(-device "virtio-blk-pci,drive=disk1,addr=$TARGET_SLOT") ;;
    *) echo "install-smoke: unsupported EOS_TARGET_IF '$TARGET_IF'"; exit 2 ;;
  esac
  echo "install-smoke: target disk = $TARGET_IF at PCI slot $TARGET_SLOT (R-F16 workaround)"
else
  echo "install-smoke: EOS_NO_TARGET_DISK — control run, source image only"
fi

echo "install-smoke: $ARCH, booting…"
"$QEMU" "${MACHINE[@]}" -smp 4 -m 2048 \
  -drive "if=pflash,unit=0,format=raw,readonly=on,file=$FW_CODE" \
  -drive "if=pflash,unit=1,format=raw,file=$WORK/vars.fd" \
  -device qemu-xhci -device usb-kbd -device virtio-rng-pci \
  -display none -serial "unix:$SER,server,nowait" -monitor "unix:$MON,server,nowait" \
  "${DRIVES[@]}" &
QPID=$!

python3 - "$SER" "$TIMEOUT" "$WORK/serial.log" "$MON" <<'PY'
import re, socket, sys, time

sock_path, timeout, logpath, mon_path = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4]
deadline = time.time() + timeout
buf = ""
log = open(logpath, "w")

def monitor(cmd):
    """The bootloader menu reads the emulated keyboard, not the serial line, so a
    newline down the wire does nothing — ci-boot-smoke.sh reaches it the same way."""
    try:
        m = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        m.connect(mon_path); m.settimeout(2); time.sleep(0.3)
        m.sendall((cmd + "\n").encode()); time.sleep(0.5)
        try: m.recv(65536)
        except Exception: pass
        m.close()
    except Exception:
        pass

s = None
for _ in range(60):                       # qemu needs a moment to create the socket
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM); s.connect(sock_path); break
    except OSError:
        time.sleep(1)
if s is None:
    print("install-smoke: FAIL — could not attach to the serial socket"); sys.exit(1)
s.settimeout(2)

ESC = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")

def pump():
    global buf
    try:
        data = s.recv(65536)
    except (socket.timeout, OSError):
        return
    if data:
        text = ESC.sub("", data.decode("utf-8", "replace"))
        buf += text
        log.write(text); log.flush()

def expect(pattern, what, hard=True):
    rx = re.compile(pattern, re.I)
    while time.time() < deadline:
        pump()
        if rx.search(buf):
            print(f"install-smoke:   saw {what}")
            return True
    if hard:
        print(f"install-smoke: FAIL — timed out waiting for {what}")
    return False

def send(line):
    """CR, not LF, one character at a time — a getty on /scheme/debug is a
    line-discipline terminal. (Moot while RX is undelivered; kept for the real
    backend, where this is the correct way to type.)"""
    for ch in line:
        s.sendall(ch.encode()); time.sleep(0.03)
    s.sendall(b"\r"); time.sleep(0.6)

if expect(r"Arrow keys and enter select mode|Press e to edit boot environment",
          "the bootloader menu", hard=False):
    monitor("sendkey ret")

if not expect(r"eos login:|redox login:|login:", "the serial login prompt"):
    print("install-smoke: FAIL — the second disk stalled the boot; see R-F16 and try")
    print("install-smoke:        EOS_TARGET_SLOT=0x8 (an INTx line that already works).")
    sys.exit(1)

print("install-smoke: PASS(boot) — reached a login prompt with the target disk attached")

# Now establish, rather than assume, whether this serial backend delivers input.
time.sleep(2); pump()
mark = len(buf)
send("user")
probe_until = time.time() + 12
echoed = False
while time.time() < probe_until:
    pump()
    if "user" in buf[mark:]:
        echoed = True
        break

if not echoed:
    print("install-smoke: SKIP(install) — this serial backend does not deliver input to")
    print("install-smoke:   the guest (nothing echoed in 12s). Known and recorded next to")
    print("install-smoke:   30_serial-getty.service in config/aarch64/eos.toml: 0 RX")
    print("install-smoke:   interrupts over QEMU's macOS unix-socket serial. Driving the")
    print("install-smoke:   installer needs QEMU monitor `sendkey` + `screendump`, which is")
    print("install-smoke:   the remaining half of R-601. NOT an install proof.")
    sys.exit(0)

print("install-smoke:   input is delivered — continuing into the installer")
time.sleep(1); pump()
if re.search(r"password", buf[-2000:], re.I):
    send("")                              # R-602: the shipped account has no password…
    time.sleep(1); pump()
    if re.search(r"new password", buf[-2000:], re.I):
        send("eos"); send("eos")          # …and the OOBE forces one, entered twice
        print("install-smoke:   completed the first-boot password enrolment")

send("installer_tui")
if not expect(r"Select a drive from 1 to", "the installer's drive prompt"):
    sys.exit(1)
print("install-smoke: PASS(stage-1) — reached the installer with the target disk visible")
sys.exit(0)
PY
rc=$?
cp "$WORK/serial.log" "$(dirname "$IMG")/install-smoke-serial.log" 2>/dev/null
exit $rc
