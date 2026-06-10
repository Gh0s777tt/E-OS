# Merge-request descriptions (ready to paste)

Three independent MRs, one per repo. Each section is a complete MR: a suggested
title, the body to paste, and the branch/`git am` commands. All patches live in
[`upstream/`](README.md). The fixes were developed and verified in **E-OS** (a
downstream Redox distribution) on QEMU `virt` (aarch64, `-cpu cortex-a72`, TCG)
and q35 (x86_64, KVM); the repro for several of them is just running shell
background jobs (`prog &`) from `ion` over the serial console.

> **Apply-clean verified against current mainline (2026-06-10):** all 7 patches
> `git am` cleanly onto today's `master` — kernel `@ 56947e1a`, base `@ 4581183c`
> (+2 commits since the patches were cut), relibc `@ b390ee65` (+48 commits). No
> rebase needed; `git am` directly onto a fresh clone.

> Note on commit authorship: the patch files are authored as `E-OS`. Before
> opening each MR, you may want to reset the author to your own identity, e.g.
> `git am --committer-date-is-author-date ...` then `git commit --amend
> --reset-author` per commit, or re-export with `git format-patch` after setting
> `user.name`/`user.email`. The technical content is what matters for review.

---

## MR 1 — kernel: boot aarch64 on non-FEAT_RNG CPUs + fix a syscall/signal return clobber

**Repo:** `redox-os/kernel`  ·  **Patches:** `upstream/kernel/0001..0004`

### Title
```
aarch64: boot on non-FEAT_RNG CPUs, share PCIe INTx IRQs, fix sched_yield/signal return clobber
```

### Body
```
This series gets aarch64 booting all the way to a graphical login on CPUs
*without* FEAT_RNG (ARMv8.5) — e.g. Cortex-A72/A53, Raspberry Pi 3/4, and
QEMU `-cpu cortex-a72` — and fixes a related aarch64 syscall/signal-ordering
bug that aborted every shell/desktop program after boot.

The original symptom was a `redoxfs` root-mount "Data Abort", but that was the
last domino in a chain. The actual order on the serial console is: `randd`
crashes first, then a flood of `failed to generate random data: ENODEV`, then
`nvmed`, then `redoxfs`.

0001 — FEAT_RNG emulation
  `randd` executes `mrs xN, RNDR/RNDRRS` unconditionally. On a CPU without
  FEAT_RNG this is an UNDEFINED instruction (sync exception, EC=0) at EL0, which
  kills `randd`, so the `rand:` scheme never starts and every daemon that seeds
  a HashMap panics with ENODEV. The aarch64 synchronous-exception handler now
  traps EC=0, `ldtr`-reads the faulting instruction, and if it is
  `MRS Xt, RNDR/RNDRRS` supplies a value and advances past it.

0002 — share PCIe INTx GIC SPIs
  `scheme/irq.rs` `open_phandle_irq` reserved GIC SPIs exclusively
  (`is_reserved` -> EEXIST), but PCIe INTx# lines are shared across devices, so a
  second opener (`nvmed`) failed with EEXIST. `irq_trigger()` already fans an IRQ
  out to every registered handle, so sharing is safe — this drops the exclusive
  gate for phandle-IRQ opens.

0003 — commit sched_yield's return before the signal check
  On aarch64, `InterruptStack::sig_archdep_reg()` is `scratch.x0`, which is also
  the syscall return register (x86/x86_64 use the flags register, riscv64 a
  temporary). `sched_yield` runs `signal_handler` *inside* the YIELD syscall,
  before the SVC handler commits the return value to `scratch.x0`. A signal
  delivered to a context during its yield therefore saved the stale syscall
  *input* x0, and `sigreturn` restored it over the real return (0). The
  interrupted program then saw x0 = -1. This deterministically broke the first
  signal-receiving fork+exec program — e.g. relibc's `verify()` (SYS_YIELD with
  !0 args) aborted every shell/desktop process. The fix commits the yield's
  return into the frame before the signal check, cfg-scoped to aarch64.

0004 — real CPU-jitter entropy for the FEAT_RNG emulation
  Upgrades 0001 from a single-seed splitmix64 stopgap to per-read CPU-execution
  -timing jitter: it samples CNTVCT_EL0 deltas across short data-dependent memory
  bursts (the jitterentropy/haveged technique) and folds them into a pool, with a
  Weyl-counter + splitmix64 finalizer so output is non-repeating and non-zero even
  under deterministic emulation (QEMU TCG). This is materially stronger entropy on
  real non-FEAT_RNG hardware. It is still not a certified TRNG; a hardware RNG
  remains the ideal long-term source, and this only matters where FEAT_RNG is
  absent.

All changes are cfg-scoped to aarch64; x86_64/riscv64 are unaffected. Tested:
aarch64 boots to a graphical desktop on QEMU virt (-cpu cortex-a72), and an
x86_64 build was regression-booted to confirm no change.
```

### Apply
```sh
git clone https://gitlab.redox-os.org/redox-os/kernel.git && cd kernel
git am /path/to/upstream/kernel/0001-*.patch \
       /path/to/upstream/kernel/0002-*.patch \
       /path/to/upstream/kernel/0003-*.patch \
       /path/to/upstream/kernel/0004-*.patch
git push <your-fork> HEAD:aarch64-boot-fixes
```

---

## MR 2 — base: PCIe legacy INTx for nvmed on aarch64 (device-tree + ACPI)

**Repo:** `redox-os/base`  ·  **Patches:** `upstream/base/0001..0002`

### Title
```
aarch64: route PCIe legacy INTx for nvmed (device-tree and ACPI _PRT)
```

### Body
```
aarch64 has no MSI in this configuration, so PCIe drivers fall back to legacy
INTx. Two gaps prevented that from working; together they are why nvmed hung at
boot and why aarch64 previously needed `-machine virt,acpi=off`.

0001 — nvmed actually uses INTx on non-x86
  `drivers/storage/nvmed` hard-codes `intx: false /* FIXME */` when starting its
  executor, even though on non-x86 `pci_allocate_interrupt_vector()` always
  returns a Legacy/INTx vector. INTx is level-triggered and must be EOI'd;
  treating it as edge/MSI hangs the driver. Sets
  `intx = cfg!(not(any(target_arch="x86", target_arch="x86_64")))`.

0002 — route INTx from the ACPI _PRT (removes the acpi=off requirement)
  Under a UEFI/ACPI boot, pcid gets the ECAM from MCFG but no PCIe
  interrupt-map (that only exists under a device tree), so it could not route
  INTx at all — which is why aarch64 had to force a device-tree boot with
  `acpi=off`. pcid now reads `\_SB.PCIx._PRT` from acpid's `acpi:/symbols`,
  resolves each entry's PCI interrupt link device (`_SB.Lxxx`) to its GSI via
  the link's `_CRS` (Extended Interrupt Descriptor), and routes it to the
  matching GIC SPI by opening `irq:phandle-0` (phandle 0 = the MADT-registered
  GIC; aarch64 builds with cfg(dtb) so the phandle IRQ path is available under
  ACPI too). The _PRT is read before pcid registers its pci_fd with acpid, to
  avoid a deadlock against acpid's AML-interpreter build. The routing is
  cfg-gated to non-x86 (x86 routes legacy INTx by plain IRQ line, and
  irq:phandle-N does not exist in non-dtb kernels). No kernel or acpid change.

Tested on QEMU virt: with these (plus the kernel series) aarch64 boots to a
graphical login under BOTH `-machine virt` (ACPI) and `-machine virt,acpi=off`
(device tree); nvmed initializes, redoxfs mounts. x86_64 verified unaffected
(the _PRT path is cfg-gated off, no phandle/_PRT activity in the boot log).

Depends on the kernel "share PCIe INTx GIC SPIs" change for the shared-IRQ case.
```

### Apply
```sh
git clone https://gitlab.redox-os.org/redox-os/base.git && cd base
git am /path/to/upstream/base/0001-*.patch /path/to/upstream/base/0002-*.patch
git push <your-fork> HEAD:aarch64-pcie-intx
```

---

## MR 3 — relibc: fix static-TLS layout, alignment and TLSDESC/TPOFF offsets

**Repo:** `redox-os/relibc`  ·  **Patch:** `upstream/relibc/0001`

### Title
```
ld.so: fix static-TLS layout, alignment and TLSDESC/TPOFF offsets
```

### Body
```
The static-TLS machinery had several offset inconsistencies that made every
exiting thread crash in thread-spawning programs on BOTH aarch64 and x86_64.
Reproduced deterministically with shell background jobs on Redox (5/5 aarch64,
3/3 x86_64). It was masked for most workloads because the misplaced TLS bytes
usually landed in zeroed memory, so the crash only manifests at thread exit when
something reads a thread-local that was placed where the access does not look.

aarch64 (and riscv64) — x86 conventions in a forward-TLS world:
  - Master::offset was computed as cum + p_memsz (the x86 backwards convention,
    distance from the END of the block), but the non-x86 copy_masters/setup_dtv
    paths consume it as a START offset, so each module's TLS image was copied
    p_memsz beyond where it is read. .tdata initializers were never seen, and
    accesses near a module boundary read the neighbouring module's data —
    relibc's own CLEANUP_LL_HEAD (module offset 0) read the preceding module's
    last qword, so pthread exit walked a garbage cleanup list.
  - The static TLSDESC descriptor was missing the aarch64 16-byte TCB bias
    (TP points 16 bytes below the block), shifting every dynamic-object TLS
    access by -16.
  - TPOFF used the x86 negative formula on all arches; on aarch64 it must be
    16 + module_start + value (riscv64: module_start + value, no bias).
  - __tlsdesc_dynamic subtracted the TCB pointer instead of TP (they coincide
    only on x86_64), breaking dlopen'd TLS.
  - STATIC_TCB_MASTER.offset displaced static executables' .tdata the same way.

x86_64 (and x86) — placement ignored PT_TLS alignment:
  - The static linker computes local-exec offsets as -align_up(p_memsz, p_align)
    + off, but the module's distance-from-end used the raw p_memsz. For an exe
    whose TLS size is not a multiple of its alignment (e.g. memsz 0x2c8, align
    0x10), the .tdata image landed (align_up - memsz) bytes above the local-exec
    plane, overlaying neighbouring thread-locals with shifted initializer bytes;
    Rust std's thread-destructor list head then read a shifted nonzero constant
    and walked a garbage list at thread exit (near-null fault).
  - The static TLSDESC descriptor also added tls_offset where variant-2 TLS
    requires a negative offset from TP; no current binary emits static TLSDESC
    on x86_64 (initial-exec/local-dynamic are used), but the value is now
    correctly signed, mirroring TPOFF.

The fix makes the offset conventions explicit per arch: x86/x86_64 keep the
backwards layout but use align_up(p_memsz, p_align) for the distance-from-end
and a correctly signed TLSDESC; aarch64/riscv64 use forward, p_align-aligned
start-based offsets, with the aarch64 TCB bias in TLSDESC/TPOFF and the dynamic
resolver subtracting TP.

Verified on Redox QEMU: the background-job repro goes from 5/5 (aarch64) and
3/3 (x86_64) crashed exiting threads to 0 on both; full desktops boot on both
arches; .tdata initializers now land where they are read. The patch also adds
tests/pthread/tls_initexit.c, a regression test (registered in the suite) that
exercises both failure modes so this cannot silently regress.
```

### Apply
```sh
git clone https://gitlab.redox-os.org/redox-os/relibc.git && cd relibc
git am /path/to/upstream/relibc/0001-*.patch
git push <your-fork> HEAD:tls-layout-fixes
```

---

## Suggested submission order

1. **kernel** first (0001/0002/0004 are independent boot fixes; 0003 is the
   signal/return fix). Nothing depends on base or relibc.
2. **base** next — note in the MR that the shared-INTx case wants the kernel
   change, but the patches are independent to apply.
3. **relibc** independently — unrelated to the others (it is a generic TLS-ABI
   fix that happens to surface as a thread-exit crash; it is not aarch64-specific).
