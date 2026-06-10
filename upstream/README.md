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
| `kernel/0001-...RNG.patch` | redox-os/kernel | **R-401b.** `randd` executes `mrs xN, RNDR/RNDRRS` (FEAT_RNG) unconditionally; on a CPU without FEAT_RNG this is an **UNDEF** (sync exception, EC=0) at EL0, killing `randd` -> the `rand:` scheme never starts -> every daemon that seeds a HashMap panics `failed to generate random data: ENODEV`. Adds `emulate_feat_rng()` to the aarch64 synchronous-exception handler: on an EC=0 fault it `ldtr`-reads the faulting instruction, and if it is `MRS Xt, RNDR/RNDRRS` supplies a value and skips the instruction. *NOTE: `0001` uses a splitmix64 stopgap; `0004` upgrades it to real CPU-jitter entropy (below). A hardware RNG remains the ideal.* |
| `kernel/0002-...IRQ.patch` | redox-os/kernel | **R-401d.** `scheme/irq.rs` `open_phandle_irq` reserves GIC SPIs **exclusively** (`is_reserved`->`EEXIST`), but PCIe **INTx#** lines are *shared* across devices, so a second opener (e.g. `nvmed`) fails with `EEXIST`. `irq_trigger()` already fans an IRQ out to *every* handle registered for it, so sharing is safe - this drops the exclusive `EEXIST` gate. |
| `kernel/0003-...sched_yield.patch` | redox-os/kernel | **R-401e.** On aarch64, `InterruptStack::sig_archdep_reg()` is `scratch.x0` - which is *also* the syscall return register (x86/x86_64 use the flags register, riscv64 a temporary `t0`). `sched_yield` runs `signal_handler` **inside** the `YIELD` syscall, *before* the SVC handler commits the return to `scratch.x0`; so a signal delivered to a context during its yield saved the stale syscall *input* `x0` and `sigreturn` restored it over the real return (`0`). The interrupted program then saw `x0 = -1`, which deterministically broke the first signal-receiving `fork`+`exec` program - e.g. relibc's `verify()` (`SYS_YIELD` with `!0` args) aborted every shell/desktop process. Commits the yield's return into the frame before the signal check, `cfg`-scoped to aarch64. |
| `kernel/0004-...jitter.patch` | redox-os/kernel | **R-401b (entropy).** Upgrades the FEAT_RNG emulation from a single-seed splitmix64 PRNG to per-read **CPU-execution-timing jitter**: it samples CNTVCT_EL0 deltas across short data-dependent memory bursts (the jitterentropy/haveged technique) and folds them into a pool, with a Weyl-counter + splitmix64 finalizer backbone so output is always non-repeating and non-zero even under deterministic emulation (QEMU TCG). Materially stronger entropy on real non-FEAT_RNG hardware; still not a certified TRNG (a HW RNG remains ideal). |
| `base/0001-...nvmed.patch` | redox-os/base | **R-401c (driver half).** `drivers/storage/nvmed` hard-codes `intx: false /* FIXME */` when starting its executor, even though on non-x86 `pci_allocate_interrupt_vector()` always returns a **Legacy/INTx** vector (there is no MSI on aarch64). INTx is level-triggered and must be EOI'd; treating it as edge/MSI hangs the driver. Sets `intx = cfg!(not(any(target_arch="x86", target_arch="x86_64")))`. |
| `base/0002-...PRT.patch` | redox-os/base | **R-401f.** Lets aarch64 boot **without** `acpi=off`. Under ACPI, pcid gets the ECAM from MCFG but no PCIe interrupt-map (that only exists under a device tree), so it could not route legacy INTx and nvmed hung. pcid now reads `\_SB.PCIx._PRT` from acpid's `acpi:/symbols`, resolves each entry's PCI interrupt link device (`_SB.Lxxx`) to its GSI via the link's `_CRS` (Extended Interrupt Descriptor), and routes it to the matching GIC SPI by opening `irq:phandle-0` (the MADT-registered GIC). Read before pcid registers with acpid, to avoid a deadlock against acpid's AML build. No kernel/acpid change. |

## Boot-mode note (R-401c / R-401f)

The nvmed `intx` fix only helps if the INTx interrupt is actually *delivered*. Under a UEFI
**device-tree** boot the PCIe **interrupt-map** carries that routing; under a UEFI **ACPI** boot
it does not (the kernel's `hwdesc` is an RSDP, `DTB_BINARY` is empty), so pcid originally could
not route INTx and nvmed hung — which is why aarch64 once needed **`-machine virt,acpi=off`** to
force a device-tree boot.

`base/0002` (**R-401f**) removes that requirement by routing INTx from the ACPI `_PRT` (option
(a) below). aarch64 now boots under **both** ACPI and device tree; `acpi=off` is optional. (A
fuller alternative would be GIC-ITS/MSI support in the kernel.)

## How to submit

Redox develops on GitLab. For each repo, fork it on <https://gitlab.redox-os.org>, apply the
patch(es) with `git am`, and open a merge request:

```sh
# kernel (R-401b + R-401d + R-401e + R-401b entropy)
git clone https://gitlab.redox-os.org/redox-os/kernel.git && cd kernel
git am /path/to/upstream/kernel/0001-*.patch /path/to/upstream/kernel/0002-*.patch /path/to/upstream/kernel/0003-*.patch /path/to/upstream/kernel/0004-*.patch
git push <your-fork> HEAD:aarch64-fixes

# base (R-401c + R-401f)
git clone https://gitlab.redox-os.org/redox-os/base.git && cd base
git am /path/to/upstream/base/0001-*.patch /path/to/upstream/base/0002-*.patch
git push <your-fork> HEAD:aarch64-pci-intx
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

---

## relibc patch: static-TLS layout / TLSDESC / TPOFF fixes, aarch64 + x86_64 (R-402a)

A second, unrelated relibc issue IS a real relibc bug — on **both** aarch64 and x86_64,
**every thread crashed on exit** in thread-spawning programs (pthread exit walked the
`CLEANUP_LL_HEAD` thread-local, which read garbage instead of NULL; reproduced
deterministically with ion background jobs: 5/5 aarch64, 3/3 x86_64, the latter verified
pre-existing on unpatched upstream).

`relibc/0001-*.patch` fixes both mechanisms:

- **aarch64/riscv64**: end-relative x86-style `Master::offset` consumed start-relative by
  the non-x86 `copy_masters`/DTV paths (module images copied where nothing reads them —
  `.tdata` initializers silently zero), static TLSDESC missing the aarch64 16-byte TCB
  bias, x86-style negative TPOFF on all arches, and `__tlsdesc_dynamic` subtracting the
  TCB pointer instead of TP (broken dlopen TLS).
- **x86/x86_64**: module placement ignored PT_TLS **alignment** — the distance-from-end
  used the raw `p_memsz` while the static linker computes local-exec offsets from
  `align_up(p_memsz, p_align)`, so executables whose TLS size is not a multiple of its
  alignment had their `.tdata` image copied above the local-exec plane, overlaying
  neighbouring thread-locals with shifted initializer bytes (Rust std's thread-dtor list
  head then walked a garbage list at thread exit). The static TLSDESC descriptor also had
  a wrong sign (corrected; no current binary emits static TLSDESC on x86_64).

Verified on Redox QEMU: both repros go to 0 crashed threads; full desktops boot; `.tdata`
initializers land where they are read.

```sh
# relibc (R-402a)
git clone https://gitlab.redox-os.org/redox-os/relibc.git && cd relibc
git am /path/to/upstream/relibc/0001-*.patch
git push <your-fork> HEAD:tls-layout-fixes
```

The relibc patch is based on `redox-os/relibc @ bcc1a0d4` (2026-06).
