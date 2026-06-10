# 🧭 Real-hardware bring-up checklist (aarch64)

> **Status: forward-looking. Nothing here is hardware-tested.** Every fix in E-OS
> so far is verified on **QEMU only** — `virt` (aarch64, `-cpu cortex-a72`, TCG)
> and `q35` (x86_64, KVM). This page maps what should carry over to real
> hardware and what definitely will not, so the first physical bring-up starts
> from a known map rather than a blank page. Treat each item as "verify", not
> "works".

QEMU `-cpu cortex-a72` was chosen precisely because it is a faithful proxy for
the **non-FEAT_RNG** aarch64 class the fixes target (Cortex-A72/A53, Raspberry
Pi 3/4). That makes the proxy good for the *CPU-feature* bugs (R-401b) but it
says nothing about board-specific peripherals.

## What carries over (and why)

| Fix | Carries to real HW? | Notes |
|---|---|---|
| **R-401b** FEAT_RNG emulation + jitter entropy | **Yes — this is the point.** | On a core *without* FEAT_RNG, `RNDR/RNDRRS` really does trap; the emulation keeps `randd` alive. On a FEAT_RNG core (ARMv8.5+, some newer server parts) the real instruction works and the trap path is never taken — confirm which class your part is. The jitter entropy (CNTVCT deltas) is a genuine source on real silicon. |
| **R-401e** sched_yield/signal return clobber | **Yes — arch bug, not board-specific.** | Pure aarch64 syscall/signal semantics; independent of peripherals. |
| **R-402a** relibc static-TLS layout | **Yes — generic TLS-ABI fix.** | Not board- or even arch-specific in spirit (also fixed x86_64). Affects every threaded program. |
| **R-401c/d** nvmed INTx + shared GIC SPI | **Only if the board has PCIe NVMe.** | QEMU virt exposes NVMe over PCIe; most SoCs (RPi3/4) have **no PCIe** and boot from SD/eMMC/USB instead, so this path may never be exercised there. It *does* matter on PCIe-bearing boards (RPi5 + NVMe HAT, SBSA servers). |
| **R-401f** ACPI `_PRT` INTx routing | **Only on UEFI/ACPI boards.** | SBSA-class servers (Ampere, etc.) boot ACPI → this applies. Device-tree SoCs use the FDT interrupt-map path instead (the same path `acpi=off` selects in QEMU). |

## Per-area checklist

### Boot path
- **Device-tree SoCs (Raspberry Pi, most embedded):** the firmware/bootloader
  hands the kernel an **FDT**. This is the same path QEMU selects under
  `-machine virt,acpi=off`, so the FDT-based GIC/timer/serial/PCIe-interrupt-map
  discovery applies directly. The ACPI `_PRT` work (R-401f) is **not** used here.
- **UEFI/SBSA servers:** ACPI boot (RSDP/MADT/GTDT). The R-401f `_PRT` path and
  the kernel's MADT GIC bring-up apply. This is the closer analog to QEMU
  `-machine virt` (ACPI).
- ☐ Confirm the bootloader (`bootloader/` recipe) supports your firmware
  handoff (UEFI vs raw FDT entry). QEMU uses AAVMF UEFI; raw-FDT boards need the
  device-tree entry path.

### Serial console (do this first — it's how you'll see *anything*)
- QEMU virt's PL011 is at a fixed address (`0x0900_0000`); the kernel finds it
  from the FDT (`serial::init`) or, under ACPI, SPCR.
- ☐ Real boards put the UART elsewhere and may use a different controller (RPi:
  PL011 *or* the mini-UART depending on config). The kernel's serial discovery
  must resolve **your** board's `stdout-path`/SPCR or the boot is **silent** —
  this is the #1 reason a first hardware boot looks "dead" when it isn't.
- ☐ Have a USB-TTL adapter on the board's debug UART before anything else.

### Storage (the root filesystem)
- QEMU uses **NVMe** (`nvmed`); the R-401c/d INTx fixes are about *that*.
- ☐ RPi3/4 boot from **SD/eMMC** (sdhci/mmc) or **USB** — different drivers
  entirely. Verify Redox has a working driver for your target's storage before
  expecting a root mount. NVMe-on-PCIe boards (RPi5 HAT, servers) reuse the
  fixed `nvmed` path.

### Interrupt controller / timer
- ☐ Confirm GIC version (v2 vs v3) and that the MADT (ACPI) or FDT exposes the
  redistributor/distributor layout the kernel expects. The kernel handles the
  standard GICv2/v3 + generic-timer case; exotic layouts may need work.

### Display / desktop
- QEMU uses **ramfb** (a simple linear framebuffer); the COSMIC desktop renders
  to it via `vesad`.
- ☐ Real boards need a real display driver (RPi VideoCore, or a UEFI GOP
  framebuffer on servers). Without a framebuffer the system still boots to a
  serial login, but there's no graphical desktop.

## Suggested first targets

1. **Raspberry Pi 4 (Cortex-A72)** — the *exact* CPU the RNG fix targets, widely
   available, device-tree boot. Best proof that R-401b matters on real silicon.
   Expect to solve **serial + SD/USB storage** first; PCIe/NVMe fixes won't apply.
2. **A UEFI aarch64 server / SBSA VM** — exercises the ACPI path (MADT GIC,
   R-401f `_PRT`, NVMe). Closest to the QEMU `-machine virt` ACPI config that is
   already verified.

## Method
- Capture the serial log from power-on; do not assume anything renders.
- Build per-arch as today (`make ARCH=aarch64 CONFIG_NAME=eos all`), then flash
  the produced image to SD/USB or boot it via the board's firmware.
- When something fails, the kernel's fatal-fault path prints `FAR`/`ELR`/`ESR`
  and (with the debug instrumentation used during R-402a) a grant map — the same
  technique that root-caused the TLS bug works on hardware.

---

*This checklist will be revised the moment any of it is actually tested on
hardware. Until then, every line is a hypothesis grounded in the QEMU work, not
a verified procedure.*
