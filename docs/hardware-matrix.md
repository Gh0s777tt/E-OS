# 🧩 E-OS hardware & driver support matrix (x86_64)

> **Generated 2026-06-18** from the built E-OS x86_64 image
> (`build/x86_64/desktop/harddrive.img`): the on-disk PCI→driver map
> (`/usr/lib/pcid.d/*.toml`) plus the installed driver binaries
> (`/usr/lib/drivers/`), cross-checked with a live QEMU/KVM boot.
>
> E-OS drivers are **user-space processes** (microkernel); the `pcid` daemon
> matches PCI devices to a driver by class / vendor / device ID.
>
> **Status legend** — **✅ Verified**: observed binding in a headless QEMU boot on
> this date. **▫ Present**: the driver binary + PCI mapping ship in the image but
> were not separately re-verified here. Storage and input drivers live in the boot
> `initfs`, not in `/usr/lib/drivers`.

## Networking

| Device | PCI ID(s) | Driver | Status |
|---|---|---|---|
| Intel e1000 | `8086:1004/100e/100f/109a/1503` | `e1000d` | ▫ Present (QEMU's default NIC) |
| Intel 10GbE (ixgbe) | `8086:` 82598/82599/X5xx family | `ixgbed` | ▫ Present |
| Realtek RTL8139 | `10ec:8139` | `rtl8139d` | ▫ Present |
| Realtek RTL8168/8169 | `10ec:8168/8169` | `rtl8168d` | ▫ Present |
| virtio-net (transitional) | `1af4:1000` | `virtio-netd` | ✅ **Verified** — bound, MAC `52:54:00:12:34:56` read |

## Storage

| Device | Driver | Status |
|---|---|---|
| NVMe | `nvmed` (initfs) | ✅ **Verified** — root filesystem booted from NVMe |
| AHCI / SATA | `ahcid` (initfs) | ▫ Present (Redox base boot driver) |
| USB mass-storage | `usbscsid` | ▫ Present |

## Audio

| Device | PCI match | Driver | Status |
|---|---|---|---|
| Intel HD Audio | class `04:03` | `ihdad` | ✅ **Verified** — bound (`IHDA … IRQ 11`) |
| AC'97 | class `04:01` | `ac97d` | ▫ Present |
| Sound Blaster 16 | — | `sb16d` | ▫ Present |

## Graphics

| Device | PCI ID(s) | Driver | Status |
|---|---|---|---|
| Intel HD Graphics | `8086:` Kaby/Comet/Tiger Lake + Arc/Alchemist | `ihdgd` | ▫ Present (real Intel iGPU/dGPU) |
| Firmware framebuffer | UEFI GOP (set up by the bootloader) | `vesad` + `fbcond` | ▫ Present — how COSMIC renders under QEMU |

## USB / input

| Device | PCI match | Driver | Status |
|---|---|---|---|
| xHCI (USB 3) | class `0C:03:30` | `xhcid` | ✅ **Verified** — bound (`XHCI … IRQ 10`) |
| USB HID / hub / mass-storage | — | `usbhidd`, `usbhubd`, `usbscsid` | ▫ Present |
| PS/2 keyboard & mouse | — | `ps2d` (initfs) | ▫ Present |

## VM guest

| Device | PCI ID | Driver | Status |
|---|---|---|---|
| VirtualBox guest device | `80ee:cafe` | `vboxd` | ▫ Present |

---

## Gaps — R-402 next targets

Ordered by impact for running E-OS as a **cloud / VM guest**, the most common
deployment surface and where coverage is weakest:

1. **virtio-blk (virtio storage) — _no driver_.** `virtio-blkd` is absent from the
   image (only `virtio-netd` exists). E-OS cannot use a virtio-blk root disk — the
   default disk on most clouds and KVM/libvirt setups. **Highest-value gap.**
   (Booting from NVMe and AHCI works.)
2. **virtio-gpu — _no driver_.** `gpu=virtio` has no backing driver; the COSMIC
   desktop needs the Intel iGPU driver or a firmware framebuffer (GOP / ramfb).
3. **Modern virtio (1.0+) device IDs.** `virtio-netd` maps only the *transitional*
   ID `1af4:1000`. Pure-modern presentations (`1af4:1041`,
   `virtio-*-pci-non-transitional`) are not in `pcid.d`. The driver *code* binds and
   works (verified against QEMU's default transitional virtio-net), so broadening the
   ID list is likely a small, testable `pcid.d` change.
4. **e1000e** (`8086:10d3`, …) — only the older `e1000` family is mapped.
5. **Wi-Fi / Bluetooth** — unsupported upstream; large, out of near-term scope.

### Suggested first implementation — `virtio-blkd`
Upstream Redox already ships a `virtio-core` crate (the basis of `virtio-netd`), so a
block driver is largely: a virtqueue on `virtio-core` exposing a `disk:`/`block:`
scheme, a `pcid.d/virtio-blkd.toml` mapping (`1af4:1001` transitional + `1af4:1042`
modern), and inclusion in the **storage `initfs`** so it can host root. It is fully
QEMU-testable with `make qemu disk=virtio`.

---

*Method: image mounted read-only via the `redoxfs` FUSE tool; PCI maps read from
`/usr/lib/pcid.d`; live boot via `qemu-system-x86_64 -machine q35 -enable-kvm`
headless (`-nographic`), serial captured and parsed. This matrix should be
re-generated whenever the driver set or pinned forks change.*
