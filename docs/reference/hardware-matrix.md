---
title: E-OS hardware & driver support matrix (x86_64 + aarch64)
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🧩 E-OS hardware & driver support matrix (x86_64 + aarch64)

> **Verified 2026-06-18** against the built E-OS x86_64 image
> (`build/x86_64/desktop/harddrive.img`, Redox base `84d78137`, drivers `20ffe4d`).
>
> E-OS drivers are **user-space processes** (microkernel). They live in **two**
> places, which matters for reading this table:
> * the boot **`initfs`** — storage, GPU, input and other early-boot drivers
>   (`nvmed`, `ahcid`, `ided`, `virtio-blkd`, `virtio-gpud`, `ps2d`, `vesad`, …);
> * the root filesystem **`/usr/lib/drivers`** — secondary / hot-plug drivers,
>   mapped by `/usr/lib/pcid.d/*.toml`.
>
> **Status** — ✅ **Verified**: observed binding in a live headless QEMU/KVM boot on
> this date. ▫ **Present**: driver ships + is mapped, not separately re-verified here.

## Storage

| Device | PCI ID | Driver (initfs) | Status |
|---|---|---|---|
| NVMe | `1b36:0010` | `nvmed` | ✅ **Verified** — root booted from NVMe |
| virtio-blk | `1af4:1001` | `virtio-blkd` | ✅ **Verified** — bound, read disk geometry (2 097 152 sectors × 512 B) |
| AHCI / SATA | class `01:06` | `ahcid` | ✅ **Verified** — spawned on the q35 AHCI controller |
| IDE | class `01:01` | `ided` | ▫ Present |
| USB mass-storage | — | `usbscsid` | ▫ Present |

## Graphics

| Device | PCI ID | Driver | Status |
|---|---|---|---|
| virtio-gpu | `1af4:1050` | `virtio-gpud` (initfs) | ✅ **Verified** — bound, set up display 0 (1280×800) |
| Intel HD Graphics | `8086:` Kaby/Comet/Tiger Lake + Arc | `ihdgd` | ▫ Present (real Intel iGPU/dGPU) |
| Firmware framebuffer | UEFI GOP | `vesad` + `fbcond` | ▫ Present |

## Networking

| Device | PCI ID | Driver | Status |
|---|---|---|---|
| virtio-net (transitional) | `1af4:1000` | `virtio-netd` | ✅ **Verified** — bound, MAC read |
| Intel e1000 | `8086:1004/100e/100f/109a/1503` | `e1000d` | ✅ **Verified** — bound + initialised (`8086:100e`) |
| Intel e1000e (82574L) — **default q35 NIC** | `8086:10d3` | `e1000d` (via E-OS overlay) | ✅ **Verified** — bound + initialised from the built eos image |
| Intel 10GbE (ixgbe) | `8086:` 82598/82599/X5xx | `ixgbed` | ▫ Present |
| Realtek RTL8139 | `10ec:8139` | `rtl8139d` | ✅ **Verified** — bound + initialised |
| Realtek RTL8168/8169 | `10ec:8168/8169` | `rtl8168d` | ▫ Present (no QEMU model to test) |

## Audio

| Device | PCI match | Driver | Status |
|---|---|---|---|
| Intel HD Audio | class `04:03` | `ihdad` | ✅ **Verified** — bound |
| AC'97 | class `04:01` | `ac97d` | ▫ Present |
| Sound Blaster 16 | — | `sb16d` | ▫ Present |

## USB / input

| Device | PCI match | Driver | Status |
|---|---|---|---|
| xHCI (USB 3) | class `0C:03:30` | `xhcid` | ✅ **Verified** — bound |
| USB HID / hub / mass-storage | — | `usbhidd`, `usbhubd`, `usbscsid` | ▫ Present |
| PS/2 keyboard & mouse | — | `ps2d` (initfs) | ▫ Present |

## VM guest

| Device | PCI ID | Driver | Status |
|---|---|---|---|
| VirtualBox guest device | `80ee:cafe` | `vboxd` | ▫ Present |

**Takeaway:** the full **virtio** set — `virtio-blk`, `virtio-gpu`, `virtio-net` —
binds and works, so E-OS runs as a virtio (KVM/cloud) guest with disk, display and
network. NVMe + AHCI storage and Intel-HDA audio are verified too.

(The tables above are **x86_64** on QEMU `q35` with KVM.)

---

## aarch64 (QEMU `virt`, `-cpu cortex-a72`)

The prebuilt aarch64 eos image **boots to `eos login:`** (verified 2026-06-18, ACPI
path). Drivers observed binding:

| Device | PCI ID | Driver | Status |
|---|---|---|---|
| NVMe (PCIe) | `1b36:0010` | `nvmed` | ✅ **Verified** — model + capacity read; RedoxFS root mounted (697 MiB) |
| Intel e1000 | `8086:100e` | `e1000d` | ✅ **Verified** — bound (GIC SPI IRQ via FDT) |
| xHCI (USB) | `1b36:000d` | `xhcid` | ✅ **Verified** — bound |
| ACPI `_PRT` INTx routing | — | `pcid` | ✅ **128 entries resolved** (validates **R-401f**; `acpi=off` no longer needed) |

> aarch64 has **no KVM** on an x86_64 host, so it runs under **TCG (software, slow)**.
> `-cpu max` is too slow to reach login in a sane window — use **`-cpu cortex-a72`**
> (also a faithful non-FEAT_RNG proxy for the R-401b RNG work). Audio (HDA) and
> virtio/GPU were not attached in this run.

---

## Fixed in this work

- **`e1000e` (`8086:10d3`) — the default q35 NIC — now works.** It used to enumerate
  but bind no driver. The 82574L is register-compatible with `e1000d`; once its id is
  mapped, `e1000d` binds and initialises it (BARs + IRQ). Shipped as the
  `/usr/lib/pcid.d/e1000e.toml` overlay in `config/x86_64/eos.toml`. **Verified
  end-to-end** by booting the freshly-built eos image with `qemu -device e1000e`.

## Verified gaps (R-402 next targets)

1. **Wi-Fi / Bluetooth** — unsupported upstream; large, out of near-term scope.
2. **Modern-only virtio device IDs** (`1af4:1040+`). The `pcid` maps cover only the
   *transitional* IDs. Transitional virtio (QEMU's and most clouds' default) works
   fully; a pure-modern presentation (`virtio-*-pci-non-transitional`) would not be
   matched. Lower priority since transitional is the common case. *(Tested: adding a
   modern net ID to the root-fs `pcid.d` makes `pcid` spawn the **older** `/usr/lib`
   `virtio-netd`, which then fails to init — so a clean modern path would use the
   initfs/`20ffe4d` virtio stack, not the prebuilt root-fs driver.)*

---

## Correction note (2026-06-18)

The first two revisions of this file wrongly listed **virtio-blk** and **virtio-gpu**
as unsupported "gaps." That was an inspection error: only the root filesystem's
`/usr/lib/drivers` was enumerated, **not the boot `initfs`**, where the storage and
GPU drivers actually live (and the `disk=virtio` UEFI boot used to test it failed at
*firmware* level, falling back to PXE, so it never reached the OS). A live QEMU/KVM
boot with virtio-blk + virtio-gpu + e1000e devices attached (2026-06-18) shows
`virtio-blkd` and `virtio-gpud` binding and working, and `e1000e` **not** binding.
This revision reflects that verified ground truth.

*Method: built image inspected via `redoxfs` FUSE (root fs) and live boots via
`qemu-system-x86_64 -machine q35 -enable-kvm` (headless, serial captured). PCI
enumeration and driver spawns read from the boot log. **Regenerate with
[`scripts/qemu-driver-check.sh`](../../scripts/qemu-driver-check.sh) `[x86_64|aarch64]`** —
a single kitchen-sink boot exercises every device model and prints which drivers bind.*
