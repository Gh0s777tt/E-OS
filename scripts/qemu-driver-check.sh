#!/usr/bin/env bash
# qemu-driver-check.sh — boot a built E-OS image under QEMU with a range of
# device models and report which drivers bind. Regenerates the data behind
# docs/reference/hardware-matrix.md.
#
#   Usage: scripts/qemu-driver-check.sh [x86_64|aarch64]
#
# x86_64 boots under KVM (q35) with one NVMe root plus many extra devices
# attached, so a SINGLE boot exercises nvmed, virtio-blkd, virtio-gpud, e1000d
# (both e1000 and the e1000e/82574L default q35 NIC), rtl8139d, virtio-netd,
# xhcid and ihdad. aarch64 has no KVM on an x86_64 host, so it boots the live
# ISO under TCG with -cpu cortex-a72 (-cpu max is too slow to reach login).
set -u
ARCH="${1:-x86_64}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
LOG="$(mktemp)"
SCRATCH="$(mktemp)"; truncate -s 64M "$SCRATCH"   # spare disk for virtio-blk

cleanup() { rm -f "$LOG" "$SCRATCH"; }
trap cleanup EXIT

report() {
  echo
  echo "==== drivers that bound (pcid spawns) ===="
  grep -aoE 'drivers/[a-z0-9-]+"' "$LOG" | sed -E 's#drivers/##; s/"//' | sort -u
  echo "==== driver init / identity lines ===="
  grep -aE '@(nvmed|e1000d|rtl8139d|virtio_blkd|virtio_gpud|virtio_netd|ihdad|xhcid)' "$LOG" \
    | sed -E 's/\x1b\[[0-9;]*m//g' | sed -E 's/^.*\] //' | head -20
  echo "==== reached login? ===="
  if grep -aqE 'eos login:|redox login:' "$LOG"; then echo "yes"; else echo "no (timed out before login)"; fi
}

case "$ARCH" in
  x86_64)
    IMG="build/x86_64/eos/harddrive.img"
    [ -f "$IMG" ] || IMG="build/x86_64/desktop/harddrive.img"
    [ -f "$IMG" ] || { echo "no x86_64 image — run: make CONFIG_NAME=eos all"; exit 1; }
    echo "Booting $IMG (q35/KVM, kitchen-sink devices, headless, 60s)..."
    timeout 60 qemu-system-x86_64 -machine q35 -enable-kvm -cpu host -smp 4 -m 2048 \
      -bios /usr/share/ovmf/OVMF.fd -nographic -vga none \
      -drive file="$IMG",format=raw,if=none,id=d0 -device nvme,drive=d0,serial=NVME \
      -drive file="$SCRATCH",format=raw,if=virtio \
      -device virtio-gpu-pci -device qemu-xhci -device ich9-intel-hda -device hda-output \
      -device e1000,netdev=n1    -netdev user,id=n1 \
      -device e1000e,netdev=n2   -netdev user,id=n2 \
      -device rtl8139,netdev=n3  -netdev user,id=n3 \
      -device virtio-net,netdev=n4 -netdev user,id=n4 \
      </dev/null >"$LOG" 2>&1
    echo "(qemu exited $?)"
    ;;
  aarch64)
    IMG="$(make -s print-installer-medium ARCH=aarch64 CONFIG_NAME=eos PODMAN_BUILD=0)"
    [ -f "$IMG" ] || { echo "no aarch64 installer medium — run: make ARCH=aarch64 CONFIG_NAME=eos live  # build/aarch64/eos/redox-live.iso"; exit 1; }
    echo "Booting $IMG (virt/TCG, -cpu cortex-a72, headless, ~520s)..."
    timeout 520 qemu-system-aarch64 -machine virt -cpu cortex-a72 -smp 1 -m 2048 \
      -bios /usr/share/AAVMF/AAVMF_CODE.fd -nographic -vga none \
      -drive file="$IMG",format=raw,if=none,id=d0 -device nvme,drive=d0,serial=NVME \
      -device qemu-xhci -device e1000,netdev=n1 -netdev user,id=n1 \
      </dev/null >"$LOG" 2>&1
    echo "(qemu exited $?)"
    ;;
  *) echo "usage: $0 [x86_64|aarch64]"; exit 2 ;;
esac

report
