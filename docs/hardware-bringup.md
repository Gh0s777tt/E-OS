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
- ✅ **`R-F16` — a second PCI storage controller used to stop the boot. Fixed
  (`U-153`), and worth reading anyway** — the bug was in the kernel's GIC distributor,
  and the same mistake is easy to make on any interrupt controller.

  `GICD_ISENABLER` and `GICD_ICENABLER` are **write-one-to-set** and
  **write-one-to-clear**: a written 1 acts on that IRQ, a written 0 does nothing, and a
  read returns the current *enable mask* for the 32 IRQs in that block. `irq_disable()`
  did a read-modify-write — read the mask, OR in the target bit, write it back — which
  writes a 1 to **every enabled bit in the block**, disabling all of them.

  Two PCI devices on different INTx lines land on adjacent SPIs (SPI 3 and SPI 4, both in
  block 1), so masking the second device's line while servicing its interrupt also masked
  the **boot disk's** line. Nothing re-enabled it, because that driver was not in an
  interrupt cycle. The root read never completed, `redoxfs` blocked, and the boot died in
  initfs with no panic and no error. The identical shape in `irq_enable()` is harmless —
  re-setting already-set bits is a no-op — which is why this only ever appeared as an
  unexplained hang. Fixed by writing the single bit, with no read and no merge; that
  covers GICv2 and GICv3 alike, since `gicv3.rs` delegates to the same `GicDistIf`.

  **Verified** against the image built from the bumped pin: `scripts/repro-intx-lines.sh`
  reports 10/10 boot, `ci-boot-smoke.sh` PASS.

  **The debugging lesson, which cost three failed attempts.** The `base` recipe lists
  `redoxfs` as a dependency and copies it into `initfs/bin/`. Rebuilding `r.redoxfs`
  alone therefore leaves the initfs carrying the **old** binary — so instrumentation
  appears to do nothing and you conclude the channel is dead. It is not. Rebuild
  `r.<recipe>` **and** `r.base`, and confirm with `strings` on
  `recipes/core/base/target/<arch>/build/initfs/bin/<binary>` before trusting a negative
  result. The proof that settled it: an unconditional `panic!` on the first line of
  `redoxfs`'s `main()`, after which the boot still reached a login prompt.

  **`R-F18`, still open — a shared-INTx interrupt storm.** Adding a *time-to-login*
  column to the regression guard turned up a separate defect, and `U-155` measured it to
  the root. A second NVMe sharing a line with `virtio-net` or `virtio-rng` boots in
  **16s**; sharing the **xHCI controller's** line takes **122s**. The gap is one init
  script step: `rm -rf /tmp` takes **80s** instead of **1s** — ordinary filesystem I/O on
  the **boot disk**, which sits on its own line.

  Counting settled the cause. QEMU `-d int` over an identical 45s window records **780 909**
  exceptions with no second disk, **820 745** sharing virtio-net's line, and **3 654 574**
  sharing xHCI's — a **4.5× interrupt storm** that starves unrelated work.

  The mechanism follows from that: a legacy INTx line is level-triggered and shared, and
  `irq_trigger` notifies **every** handle on it. An xHCI interrupt therefore also wakes the
  storage driver, which finds nothing to do, acks, and **unmasks a line the xHCI device is
  still asserting** — so it re-fires immediately, over and over, until the driver that owns
  the condition services it. **A driver with nothing to do must not unmask a level line
  another device is still driving.** A correct fix keeps the line masked until every handle
  has acked, or lets a driver answer *not mine*; that is a kernel interrupt-model change,
  not a one-liner, and is deliberately not attempted yet.

  Expect this on real hardware wherever storage and USB land on the same INTx line — which
  on a board with few interrupt lines is likely rather than exotic.

  An earlier reading of this (`U-154`) blamed USB HID readiness and was **wrong**: the
  `usbhidd` warning that precedes the silence fires in *every* boot, because it decodes the
  synthetic keypress the harness sends to dismiss the bootloader menu.

  **`R-F17`, the sibling defect this hunt exposed.** In the *passing* half of the
  matrix — both disks on GIC SPI 3 — the boot reaches `switchroot` and then `nvmed`
  dies: `assertion failed: amount == core::mem::size_of::<usize>()`
  (`drivers/executor/src/lib.rs:191`). The kernel's irq scheme **deliberately** returns
  `Ok(0)` from `kwrite` for a stale acknowledgement (`ack != current`), and the driver
  asserts the write consumed `size_of::<usize>()` bytes. On a shared line a stale ack is
  routine — `irq_trigger` fans one line out to *every* registered handle, which `R-401d`
  deliberately permits — so any two devices sharing an INTx line can abort a storage
  driver. **Fixed in `eos-base@7d5ca7e28e` (`U-149`)**: `Ok(0)` is now treated as *stale ack — a newer
  interrupt is already pending and will unmask* — safe because `COUNTS` is bumped only by `irq_trigger`, so
  that newer interrupt has already re-triggered this handle. Verified with a before/after negative control
  on two NVMe disks sharing GIC SPI 3. `R-F16` is untouched by it and still reproduces.

### Display / desktop
- QEMU uses **ramfb** (a simple linear framebuffer); the Crimson desktop
  (orbital) renders to it via `vesad`.
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
