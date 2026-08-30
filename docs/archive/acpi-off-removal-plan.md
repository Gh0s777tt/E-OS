---
title: Plan: remove the aarch64 -machine virt,acpi=off requirement
status: archived
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Plan: remove the aarch64 `-machine virt,acpi=off` requirement

**Status: IMPLEMENTED 2026-06-08 as `R-401f` (pcid-only) — aarch64 boots without `acpi=off`.**
See CHANGELOG `[U-019]`. The plan below is kept for history; the shipped approach matches it but
was simpler than feared: the kernel already brought up the GIC from the ACPI MADT and exposes
`irq:phandle-0` (aarch64 builds with `cfg(dtb)`), and acpid already serves the AML namespace, so
**no kernel or acpid change was needed** — pcid reads the static `\_SB.PCIx._PRT` + each link
device's `_CRS` directly from acpid's `acpi:/symbols` and routes INTx to the matching GIC SPI.

E-OS aarch64 currently boots only with QEMU `-machine virt,acpi=off`. That flag forces a
**device-tree** boot, which is the only path on which Redox populates the PCIe
**interrupt-map** that `pcid` needs to route legacy **INTx** interrupts; without it `nvmed`
never receives its IRQ and the boot hangs. (Real aarch64 hardware boots from device-tree, so
this affects only the QEMU-virt UEFI/ACPI scenario.)

## Root cause (code-grounded)

- `drivers/pcid/src/main.rs` `enable_function()` resolves INTx by looking the device address +
  pin up in `pcie.interrupt_map` (the FDT `interrupt-map`). Under ACPI that vector is **empty**
  (`cfg_access/mod.rs` `Mcfg::with` gives ECAM but no interrupt-map), so `mapping = None` →
  `LegacyInterruptLine { irq, phandled: None }` → no GIC SPI is opened → `nvmed` blocks forever
  on its IRQ event queue.
- ACPI expresses PCI interrupt routing via `\_SB.PCIx._PRT`, not an FDT interrupt-map.

## Implementation plan (3 components)

### 1. acpid — evaluate `_PRT`, expose a routing table
- acpid already has a full AML `Interpreter` (`drivers/acpid/src/acpi.rs`, the `acpi` crate) and
  serves the `acpi:` scheme (`scheme.rs`).
- Add evaluation of `\_SB.PCIx._PRT` for each PCI root bridge. `_PRT` is a Package of
  `{Address (dev<<16|0xffff), Pin (0-3), Source, SourceIndex}` entries.
  - **QEMU virt (simple case):** `Source` is 0 and `SourceIndex` is the **GSI** directly — a
    static table, no link devices. This is the bounded case to implement first.
  - **General case (real firmware):** `Source` names a PCI interrupt link device
    (`\_SB.LNKx`); its current GSI comes from evaluating that device's `_CRS` (and is set via
    `_SRS`). This requires link-device resolution — the larger/harder part.
- Expose the resolved `{bus, dev, pin} -> GSI, trigger/polarity}` table over the `acpi:` scheme
  (e.g. a new `acpi:/prt` node returning the table, or a query request).

### 2. pcid — consume `_PRT` under ACPI
- In `enable_function()` (main.rs:200-228), when `pcie.interrupt_map` is empty (ACPI boot),
  query acpid's `_PRT` table for `(bus, dev, pin)` → GSI instead of the FDT lookup.
- Return a `LegacyInterruptLine` carrying the **raw GSI** (extend the type / add an ACPI variant
  alongside the existing `phandled` FDT variant), and open the IRQ by GSI (below).

### 3. kernel — open an IRQ by raw GSI under ACPI
- `scheme/irq.rs` opens IRQs by FDT **phandle** (`open_phandle_irq`); under ACPI there is no
  phandle. Under `cfg!(not(dtb))` the IRQ primitives come from `crate::arch::interrupt::irq`.
- Ensure the GIC **distributor** has the SPI for that GSI enabled/configured (from the ACPI
  **MADT**; confirm the aarch64 ACPI boot path sets up the GIC distributor, not just the
  per-CPU PPIs that the timer uses), and add/confirm an `irq:` open-by-GSI path (a numeric SPI),
  analogous to `open_phandle_irq` but keyed on the GSI.

## Test plan
- Boot QEMU `virt` **without** `acpi=off`; confirm `pcid` routes nvmed's INTx, nvmed gets its
  IRQ, redoxfs mounts, and boot reaches login. (Currently hangs at nvmed — slow TCG.)
- **Regression:** confirm `acpi=off` (device-tree) boot still works unchanged on both this and
  x86_64.

## Risks
- Touches core boot/IRQ across **three** codebases (kernel + acpid + pcid) and the AML
  interpreter; real risk of regressing the **working** `acpi=off` boot.
- AML link-device (`_SB.LNKx._CRS/_SRS`) resolution can be a deep subsystem if the general case
  is needed; QEMU-virt's static `_PRT` avoids it but real firmware may not.
- Verifiable only via slow no-acpi TCG boots.

## Recommendation
**Defer.** Low value (real aarch64 hardware boots from device-tree; `acpi=off` is a documented,
harmless QEMU-virt flag), high effort (multi-subsystem, multi-session), and meaningful
regression risk to the currently-working boot. Implement deliberately as its own focused effort
if/when ACPI-boot support becomes a real requirement — ideally upstreaming the `_PRT` work into
`redox-os/acpid` + `redox-os/drivers` rather than carrying it downstream.
