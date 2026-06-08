# Upstream patches - aarch64 fixes

These patches make **Redox OS boot on aarch64 CPUs without FEAT_RNG (ARMv8.5)** - e.g.
Cortex-A72/A53, Raspberry Pi 3/4, and QEMU `-cpu cortex-a72` - all the way to a graphical
login, and fix a related aarch64 syscall/signal-ordering bug that aborted every
shell/desktop program after boot. They were developed for **E-OS** (a downstream Redox
distribution) but are upstream-clean and apply to mainline `redox-os/kernel` and
`redox-os/base`.

Before these, aarch64 died almost immediately; once booted, it could not run a single
`fork`+`exec`'d program. The failures were a chain of bugs, each masking the next; these
patches fix them in the kernel and base (no relibc change is needed - see the note below).

## The patches

| Patch | Repo | What it fixes |
|---|---|---|
| `kernel/0001-...RNG.patch` | redox-os/kernel | **R-401b.** `randd` executes `mrs xN, RNDR/RNDRRS` (FEAT_RNG) unconditionally; on a CPU without FEAT_RNG this is an **UNDEF** (sync exception, EC=0) at EL0, killing `randd` -> the `rand:` scheme never starts -> every daemon that seeds a HashMap panics `failed to generate random data: ENODEV`. Adds `emulate_feat_rng()` to the aarch64 synchronous-exception handler: on an EC=0 fault it `ldtr`-reads the faulting instruction, and if it is `MRS Xt, RNDR/RNDRRS` supplies a value (splitmix64 seeded from CNTPCT) and skips the instruction. *NOTE: that PRNG is a stopgap so the system boots; a real entropy source (jitter / HW RNG) is the proper long-term fix.* |
| `kernel/0002-...IRQ.patch` | redox-os/kernel | **R-401d.** `scheme/irq.rs` `open_phandle_irq` reserves GIC SPIs **exclusively** (`is_reserved`->`EEXIST`), but PCIe **INTx#** lines are *shared* across devices, so a second opener (e.g. `nvmed`) fails with `EEXIST`. `irq_trigger()` already fans an IRQ out to *every* handle registered for it, so sharing is safe - this drops the exclusive `EEXIST` gate. |
| `kernel/0003-...sched_yield.patch` | redox-os/kernel | **R-401e.** On aarch64, `InterruptStack::sig_archdep_reg()` is `scratch.x0` - which is *also* the syscall return register (x86/x86_64 use the flags register, riscv64 a temporary `t0`). `sched_yield` runs `signal_handler` **inside** the `YIELD` syscall, *before* the SVC handler commits the return to `scratch.x0`; so a signal delivered to a context during its yield saved the stale syscall *input* `x0` and `sigreturn` restored it over the real return (`0`). The interrupted program then saw `x0 = -1`, which deterministically broke the first signal-receiving `fork`+`exec` program - e.g. relibc's `verify()` (`SYS_YIELD` with `!0` args) aborted every shell/desktop process. Commits the yield's return into the frame before the signal check, `cfg`-scoped to aarch64. |
| `base/0001-...nvmed.patch` | redox-os/base | **R-401c (driver half).** `drivers/storage/nvmed` hard-codes `intx: false /* FIXME */` when starting its executor, even though on non-x86 `pci_allocate_interrupt_vector()` always returns a **Legacy/INTx** vector (there is no MSI on aarch64). INTx is level-triggered and must be EOI'd; treating it as edge/MSI hangs the driver. Sets `intx = cfg!(not(any(target_arch="x86", target_arch="x86_64")))`. |

## Boot-mode note (R-401c, the other half)

The nvmed `intx` fix only helps if the INTx interrupt is actually *delivered*. On aarch64
that needs the PCIe **interrupt-map**, which Redox only has when it boots from a **device
tree** (`/scheme/kernel.dtb`). Under a UEFI **ACPI** boot the kernel's `hwdesc` is an RSDP
and `DTB_BINARY` is empty, so pcid can't route INTx and nvmed never gets its IRQ.

Workaround (no code change): boot QEMU `virt` with **`-machine virt,acpi=off`**, which makes
AAVMF install the `EFI_DTB_TABLE_GUID` config table; the bootloader's `find_dtb` (which
already prefers DTB on aarch64) then boots the device-tree path and everything routes
correctly. A proper upstream fix would be either (a) ACPI `_PRT` parsing in pcid, or
(b) GIC-ITS/MSI support in the kernel.

## How to submit

Redox develops on GitLab. For each repo, fork it on <https://gitlab.redox-os.org>, apply the
patch(es) with `git am`, and open a merge request:

```sh
# kernel (R-401b + R-401d + R-401e)
git clone https://gitlab.redox-os.org/redox-os/kernel.git && cd kernel
git am /path/to/upstream/kernel/0001-*.patch /path/to/upstream/kernel/0002-*.patch /path/to/upstream/kernel/0003-*.patch
git push <your-fork> HEAD:aarch64-fixes

# base (R-401c)
git clone https://gitlab.redox-os.org/redox-os/base.git && cd base
git am /path/to/upstream/base/0001-*.patch
git push <your-fork> HEAD:aarch64-nvmed-intx
```

Patches are based on `redox-os/kernel @ 56947e1a` and `redox-os/base @ 9dd6901d` (2026-06).

---

## Note: the relibc `verify()` abort is fixed in the kernel (R-401e), not relibc

After the boot fixes, aarch64 reached login but **no `fork`+`exec`-spawned program could
run**: `whoami`, `ls`, `env`, and the desktop's wallpaper renderer all aborted at startup
with a `brk #1` trap (`ESR_EL1` EC=`0x3C`, *not* a memory fault). Deterministic, 16/16.
(A prior diagnosis called this a "cosmetic intermittent background null-deref" - it is
neither cosmetic, intermittent, nor a deref.)

`relibc_start_v1` -> `relibc_verify_host()` -> `Sys::verify()` issues `SYS_YIELD` as a
Redox-vs-Linux host check and aborts unless it returns `Ok`. On aarch64 the `YIELD`
returned a stale `-1` instead of `0`, so `verify()` mis-fired and aborted before `main`.

E-OS first shipped a relibc workaround (tolerate the unreliable result on aarch64), but the
**true root cause is in the kernel** and is fixed by **`kernel/0003` (R-401e)** above: a
signal delivered during the in-flight `YIELD` clobbered the syscall return value through the
aarch64 `sig_archdep_reg`/`x0` aliasing. With that kernel fix, the strict upstream `verify()`
works unmodified - so **no relibc patch is needed**, and E-OS has reverted to strict upstream
relibc. (The earlier relibc workaround patch has been retired in favour of the kernel fix.)
