# Merge-request descriptions (ready to paste)

Three independent MRs, one per repo. Each section is a complete MR: a suggested
title, the body to paste, and the branch/`git am` commands. All patches live in
[`upstream/`](README.md). The fixes were developed and verified in **E-OS** (a
downstream Redox distribution) on QEMU `virt` (aarch64, `-cpu cortex-a72`, TCG)
and q35 (x86_64, KVM); the repro for several of them is just running shell
background jobs (`prog &`) from `ion` over the serial console.

> **Apply-clean verified against current mainline (2026-07-11):** all 14 patches
> `git am` cleanly onto a fresh `master` clone — kernel `@ 985bc262`, base
> `@ 2f06b013`, relibc `@ 284852a0`. No rebase needed; `git am` directly onto a
> fresh clone. (Regenerated from the E-OS forks after rebasing them onto current
> mainline, so they carry the full fix set: **7 kernel, 6 base, 1 relibc**.)

> Note on commit authorship: the patch files are authored as `E-OS`. Before
> opening each MR, you may want to reset the author to your own identity, e.g.
> `git am --committer-date-is-author-date ...` then `git commit --amend
> --reset-author` per commit, or re-export with `git format-patch` after setting
> `user.name`/`user.email`. The technical content is what matters for review.

---

## MR 1 — kernel: boot aarch64 on non-FEAT_RNG CPUs + fix three aarch64 IRQ/signal bugs

**Repo:** `redox-os/kernel`  ·  **Patches:** `upstream/kernel/0001..0007`

### Title
```
aarch64: boot on non-FEAT_RNG CPUs; fix virtual-timer IRQ, shared PCIe INTx, sched_yield/signal clobber, and a level-INTx EOI deadlock
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

0005 — register the virtual timer's interrupt, not the physical one
  On cores without VHE (`use_virtual_timer` = true; e.g. Cortex-A72 and the QEMU
  virt machine) the kernel arms the *virtual* generic timer, but both timer-init
  paths registered the *non-secure physical* timer's interrupt. The virtual timer
  then fired on an interrupt nobody handled: `context::timeout::trigger` never ran
  and every `thread::sleep` blocked forever, hanging the boot at the first
  sleeping driver. Selects the interrupt to match the timer in use —
  `acpi/gtdt.rs` uses `virtual_el1_timer_gsiv` when `use_virtual_timer`, and the
  device-tree path uses PPI index 2 (virtual) instead of 1 (non-secure physical).

0006 — mask + EOI userspace level-triggered INTx in-kernel (fix a deadlock)
  For a userspace-handled level-triggered INTx the kernel deferred the GIC EOI to
  the driver's scheme ack. That leaves the interrupt *active* (GIC running
  priority raised) from the moment it fires until the driver acks — which blocks
  every equal/lower-priority interrupt, including the generic-timer PPI. But the
  driver cannot be scheduled to ack without the timer: a circular deadlock (all
  CPUs WFI). `dtb::irqchip::trigger_virq` now masks the line and EOIs in-kernel
  before notifying userspace (priority drops at once, the timer keeps firing, the
  masked line won't re-fire though the device still asserts it), and the driver's
  ack re-enables the line instead of a second EOI. aarch64-only; riscv64's PLIC
  already EOIs in its handler and x86 is unchanged.

0007 — quiet the aarch64/riscv64 debug! flood
  The `debug!` macro prints unconditionally on aarch64/riscv64 (cfg-gated to
  those arches, no level check; a no-op on x86), so it emits a DEBUG line on
  every `call_fdread` and similar hot paths — flooding the console and slowing
  every boot. Adds a crate-root `KERNEL_DEBUG` constant (default false) and gates
  the macro on it; one flip re-enables it for bring-up.

All changes are cfg-scoped to aarch64 (0006 explicitly; the timer/RNG/IRQ paths
are aarch64 device code; 0007 is aarch64/riscv64); x86_64 is unaffected. Tested:
aarch64 boots to a graphical desktop on QEMU virt (-cpu cortex-a72) and x86_64
was regression-booted to confirm no change.
```

### Apply
```sh
git clone https://gitlab.redox-os.org/redox-os/kernel.git && cd kernel
git am /path/to/upstream/kernel/000*.patch
git push <your-fork> HEAD:aarch64-boot-fixes
```

---

## MR 2 — base: aarch64 legacy PCIe INTx for nvmed + virtio, and two boot fixes

**Repo:** `redox-os/base`  ·  **Patches:** `upstream/base/0001..0006`

### Title
```
aarch64: legacy PCIe INTx for nvmed and virtio (device-tree + ACPI _PRT), plus randd RNDRRS and an ihdad boot-hang fix
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
  (0002 adds the _PRT routing; 0003 cfg-gates it to non-x86 so x86 keeps its
  plain-IRQ-line path untouched.)

0004 — virtio-core: legacy INTx support (aarch64/riscv64)
  virtio-core assumed MSI-X; on aarch64 (no MSI) it must fall back to legacy,
  level-triggered PCI INTx, which is acknowledged at both the device (read the
  ISR status register, which de-asserts the line) and the kernel IRQ scheme
  (write the count back to re-arm). Adds that path so virtio devices work on
  aarch64; MSI-X is unchanged where present.

0005 — randd: read RNDRRS unconditionally on aarch64
  Pairs with the kernel FEAT_RNG emulation (MR 1, 0001/0004): with the kernel
  trapping and emulating RNDR/RNDRRS, randd can read RNDRRS on every aarch64 core
  instead of gating on a `rand` feature bit that non-FEAT_RNG cores do not report
  — which otherwise re-introduces the insecure all-zero seed on exactly those
  cores. (Apply after the kernel series.)

0006 — ihdad: don't hang the boot on aarch64
  ihdad's HDA controller reset used `thread::sleep`, which does not wake early in
  aarch64 boot; the driver hung and stalled the sequential pcid-spawn. Bounds the
  reset with spin-waits instead and fails gracefully if the controller does not
  come up, so a missing/again-slow HDA controller cannot hang the boot.

Tested on QEMU virt: with these (plus the kernel series) aarch64 boots to a
graphical login under BOTH `-machine virt` (ACPI) and `-machine virt,acpi=off`
(device tree); nvmed and virtio init, redoxfs mounts. x86_64 verified unaffected
(the aarch64/non-x86 paths are cfg-gated off).

Depends on the kernel series (shared PCIe INTx, and the FEAT_RNG emulation for 0005).
```

### Apply
```sh
git clone https://gitlab.redox-os.org/redox-os/base.git && cd base
git am /path/to/upstream/base/000*.patch
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

## How to submit (no new account needed)

Redox develops on **gitlab.redox-os.org**. You do **not** need to register a new
account: its sign-in page offers **"Sign in with GitLab.com"** — log in with your
existing `gitlab.com` account and your Redox-instance account is created for you.
Then, per repo:

1. **Fork** `redox-os/<repo>` on gitlab.redox-os.org (Fork button).
2. Clone the upstream, `git am` the patches (commands in each MR above), and
   `git push` to your fork's branch.
3. Open the MR from your fork's branch into `redox-os/<repo>:master`, pasting the
   title/body above.

`upstream/prepare-mrs.sh` automates steps 1–2 (clone + `git am` + branch). If a
fresh Redox-instance account can't fork yet (anti-spam approval), a one-line note
on the Redox Matrix/chat unblocks it — or e-mail the patches to the maintainers
(the links are public in this repo).

## Suggested submission order

1. **kernel** first — the boot + IRQ + signal fixes; nothing depends on base or
   relibc. (0005 the timer fix and 0006 the level-INTx EOI fix are what actually
   get aarch64 to reach and hold a login.)
2. **base** next — note in the MR that it depends on the kernel series (shared
   INTx, and FEAT_RNG emulation for the randd patch).
3. **relibc** independently — unrelated to the others (a generic TLS-ABI fix that
   surfaces as a thread-exit crash on both aarch64 and x86_64; not aarch64-specific).
