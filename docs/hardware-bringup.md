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
- ⛔ **`R-F16` — a second storage device on a different legacy INTx line stops the
  boot, silently.** This is the single most important thing to know before taking E-OS
  to an aarch64 board with more than one storage controller.

  aarch64 has no MSI/MSI-X, so every PCI driver falls back to a legacy INTx line
  (the `R-401c` note in `nvmed` spells this out). When a second storage device lands on
  a line different from the first, the boot **stops silently in initfs**, before the
  root filesystem is mounted: no panic, no error, just a serial log that ends.

  **Mechanism — corrected in `U-148` after being published wrong twice.** The second
  driver is *not* stuck. With driver logs raised to `Debug` it reaches `Initialized!`
  and `Starting to listen for scheme events`; its `identify` completions succeed, which
  requires interrupts, so its interrupt path works. `daemon.ready()` runs
  unconditionally in `DiskScheme::new` (`driver-block/src/lib.rs:288`) *before* that log
  line, so readiness is signalled and `pcid-spawner` is not blocked. The stall is
  downstream: `50_rootfs.service` (`redoxfs`, a `oneshot`) never completes, so
  `90_initfs.target` never completes and `init` never reaches `switch_root("/usr")`.
  `redoxfs` logs nothing, which is why the failure is silent. **Why `redoxfs` never
  completes, while both drivers' own interrupts demonstrably work, is still unknown** —
  recorded as open rather than guessed at a fourth time.

  Measured on QEMU `virt`, where the INTx line is `(slot + pin) % 4` and the source
  disk sits at slot `0x4` (line 0):

  | Configuration | INTx line | Result |
  |---|---|---|
  | source disk alone (`0x4`) | 0 | boots |
  | source disk alone, moved to `0x5` | 1 | **boots** — so line 1 is not broken *per se* |
  | + second disk at `0x5` / `0x9` | 1 | stalls |
  | + second disk at `0x6` | 2 | stalls |
  | + second disk at `0x7` | 3 | stalls |
  | + second disk at `0x8` / `0xC` | 0 (shared with the source disk) | **boots** |
  | + second disk, `virtio-blk` at `0x5` | 1 | stalls |

  The two control rows are what make this a diagnosis rather than a guess: a lone
  disk on line 1 boots, so no individual line is dead — it is *two lines at once*
  that fails; and a `virtio-blk` device stalls identically, so it is not an `nvmed`
  bug but the shared INTx path underneath both drivers.

  - ☐ On a board with a single storage controller and nothing else needing INTx, you
    will not hit this. On anything with two (NVMe + USB controller, NVMe + SATA,
    two NVMe) **expect a silent hang before the root mount** until this is fixed.
  - ☐ If a board supports MSI/MSI-X, using it side-steps the whole path — that is
    why x86_64 is *expected* to be unaffected (unverified: no x86_64 image has been
    built on the current host).
  - Reproduce with `scripts/repro-intx-lines.sh <image>`; it runs the matrix above
    and prints predicted-vs-actual, so a fix shows up as every row turning to *boot*.

  **Scope of the measurement — narrower than it first looks (`U-147`).** Everything
  above was measured in the **initfs phase**, where `pcid-spawner --initfs` brings up
  the storage drivers and `init` has not yet switched to the real root. `init`
  performs *two* `switch_root` calls, and after the second one (`/usr`) `pcid-spawner`
  runs again and brings up `virtio-netd` (device 1 → line 1) and `xhcid` (device 2 →
  line 2) **successfully, while the boot disk on line 0 is already in service** — the
  boot then reaches a login prompt. So "only one INTx line ever works" is *not* an
  established fact; what is established is that **a second storage driver in the
  initfs phase, on a line different from the first, never signals readiness and stalls
  the boot**. Whether interrupts are actually delivered to those later drivers is
  untested — they reach readiness, which does not by itself prove their interrupt path
  works. Settling that needs driver `debug!` output, which today is compiled at a fixed
  `Info` level (`drivers/common/src/logger.rs` hardcodes it), so it needs a rebuild.

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
