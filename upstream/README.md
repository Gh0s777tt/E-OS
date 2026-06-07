# Upstream patches — aarch64 boot fixes

These three patches make **Redox OS boot on aarch64 CPUs without FEAT_RNG (ARMv8.5)** — e.g. Cortex‑A72/A53, Raspberry Pi 3/4, and QEMU `-cpu cortex-a72` — all the way to a graphical login. They were developed for **E‑OS** (a downstream Redox distribution) but are upstream‑clean and apply to mainline `redox-os/kernel` and `redox-os/base`.

Before these, aarch64 died almost immediately. The failures were a chain of four bugs, each masking the next; these patches fix three of them (the fourth, R‑401c, is a boot‑mode workaround documented below, not a code change here).

## The patches

| Patch | Repo | What it fixes |
|---|---|---|
| `kernel/0001-…RNG.patch` | redox-os/kernel | **R‑401b.** `randd` executes `mrs xN, RNDR/RNDRRS` (FEAT_RNG) unconditionally; on a CPU without FEAT_RNG this is an **UNDEF** (sync exception, EC=0) at EL0, killing `randd` → the `rand:` scheme never starts → every daemon that seeds a HashMap panics `failed to generate random data: ENODEV`. Adds `emulate_feat_rng()` to the aarch64 synchronous‑exception handler: on an EC=0 fault it `ldtr`‑reads the faulting instruction, and if it is `MRS Xt, RNDR/RNDRRS` supplies a value (splitmix64 seeded from CNTPCT) and skips the instruction. *NOTE: that PRNG is a stopgap so the system boots; a real entropy source (jitter / HW RNG) is the proper long‑term fix.* |
| `kernel/0002-…IRQ.patch` | redox-os/kernel | **R‑401d.** `scheme/irq.rs` `open_phandle_irq` reserves GIC SPIs **exclusively** (`is_reserved`→`EEXIST`), but PCIe **INTx#** lines are *shared* across devices, so a second opener (e.g. `nvmed`) fails with `EEXIST`. `irq_trigger()` already fans an IRQ out to *every* handle registered for it, so sharing is safe — this drops the exclusive `EEXIST` gate. |
| `base/0001-…nvmed.patch` | redox-os/base | **R‑401c (driver half).** `drivers/storage/nvmed` hard‑codes `intx: false /* FIXME */` when starting its executor, even though on non‑x86 `pci_allocate_interrupt_vector()` always returns a **Legacy/INTx** vector (there is no MSI on aarch64). INTx is level‑triggered and must be EOI'd; treating it as edge/MSI hangs the driver. Sets `intx = cfg!(not(any(target_arch="x86", target_arch="x86_64")))`. |

## Boot‑mode note (R‑401c, the other half)

The nvmed `intx` fix only helps if the INTx interrupt is actually *delivered*. On aarch64 that needs the PCIe **interrupt‑map**, which Redox only has when it boots from a **device tree** (`/scheme/kernel.dtb`). Under a UEFI **ACPI** boot the kernel’s `hwdesc` is an RSDP and `DTB_BINARY` is empty, so pcid can’t route INTx and nvmed never gets its IRQ.

Workaround (no code change): boot QEMU `virt` with **`-machine virt,acpi=off`**, which makes AAVMF install the `EFI_DTB_TABLE_GUID` config table; the bootloader’s `find_dtb` (which already prefers DTB on aarch64) then boots the device‑tree path and everything routes correctly. A proper upstream fix would be either (a) ACPI `_PRT` parsing in pcid, or (b) GIC‑ITS/MSI support in the kernel.

## How to submit

Redox develops on GitLab. For each repo, fork it on <https://gitlab.redox-os.org>, apply the patch(es) with `git am`, and open a merge request:

```sh
# kernel
git clone https://gitlab.redox-os.org/redox-os/kernel.git && cd kernel
git am /path/to/upstream/kernel/0001-*.patch /path/to/upstream/kernel/0002-*.patch
git push <your-fork> HEAD:aarch64-feat-rng-and-shared-intx

# base
git clone https://gitlab.redox-os.org/redox-os/base.git && cd base
git am /path/to/upstream/base/0001-*.patch
git push <your-fork> HEAD:aarch64-nvmed-intx
```

Patches are based on `redox-os/kernel @ 56947e1a` and `redox-os/base @ 9dd6901d` (2026‑06).
