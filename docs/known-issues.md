# 🐞 Known Issues

_No issue currently blocks a full **aarch64** or **x86_64** desktop boot._
Resolved items are kept below for the record.

---

## 🟡 No audio on the aarch64/QEMU loop — `ihdad` times out on the HDA RIRB (OPEN, 2026-07-23, U-110)

Does **not** block boot — audio is a peripheral — but it means the E-OS Control
**Sound** tab (`R-D07`) cannot have its volume control proven on the dev loop,
and any audio app is silent there.

With a QEMU HDA device present (`-device intel-hda -device hda-duplex`) the audio
stack gets **most** of the way up and then stalls at the codec handshake:

```
PCI 0000:00:04.0 8086:2668 04.03.00.01 4        ← QEMU presents an Intel HDA (ICH6)
pcid-spawner: spawn "/usr/lib/drivers/ihdad"     ← ihdad IS in the aarch64 image; pcid maps it
IHDA pci-0000-00-04.0 on: 0=10040000 IRQ: …      ← controller BAR mapped, IRQ allocated
ihdad::hda::cmdbuff: timeout on RIRB response     ← ⚠ the codec never answers (CORB/RIRB DMA)
ihdad: HDA initialization failed (I/O error); audio unavailable
audiod: No such device → exited without notifying readiness
```

The device **and** the driver are both present — the failure is `ihdad` timing
out on the codec's **RIRB** (Response Input Ring Buffer) after it posts a CORB
command. audiod then can't open `audiohw:` and exits (its `main.rs` opens
`/scheme/audiohw` *before* creating the `audio:` scheme), so `audio:` — and its
`audio:volume` control — never appears.

**Likely cause:** an aarch64-specific **DMA / cache-coherency** issue in the
CORB/RIRB ring setup. `ihdad`'s device comments list QEMU ICH9 (`8086:293E`) as a
tested target and it works on x86 QEMU, so the driver logic is sound; the ring
buffers it hands the controller aren't observed coherently on aarch64 (device-DMA
memory attributes / cache maintenance), so the RIRB write never becomes visible
and the read times out.

**Fix path (dedicated session, a `drivers` fork change):** audit `ihdad`'s
CORB/RIRB allocation for aarch64 — map the ring memory uncached/device (or
maintain caches around the controller's writes) and re-check the RIRB
write-pointer / interrupt path. Until then the Sound tab detects the absent
`audio:` scheme and says so plainly instead of showing a dead slider.

---

## 🔴 netsurf-fb crashes at startup on aarch64 (OPEN, 2026-07-12, U-039)

`netsurf-fb` is the **only ET_EXEC (non-PIE) dynamic binary** in the image, and
relibc's `ld.so` ET_EXEC support is immature. After the `R-402b` loader fixes
(weak-PLT-to-0 per the gABI + wrapping `d_val` arithmetic — which un-broke every
COSMIC app) netsurf gets **through the loader** but dies in a data abort
(`ESR 0x92000047` = write, translation fault L3) at an address **outside its own
segments**, i.e. in the shared-library mapping region — some library-side
relocation or COPY-relocation interaction unique to an ET_EXEC main.

Findings so far:
- The cross-gcc **does support PIE** (`-fPIE -pie` on a test program → `DYN`).
- Rebuilding netsurf as PIE failed three times: its `buildsystem/makefiles/
  Makefile.tools` (cross branch) reconstructs `CC__` via `which $(CC)`, which
  mangles a multi-word `CC`, and the flags never reach the final link.
- `ld.so`'s COPY-relocation path *reads* correctly (sizes asserted, copy
  direction right, skip-first lookup) — but ET_EXEC+shared-libs is its only
  user, so it remains the prime suspect.

Two fix paths (dedicated session): patch netsurf's **link rule itself** to force
`-pie` (netsurf/Makefile `$(CC) -o $(EXETARGET)` line), or audit `ld.so` ET_EXEC
handling with an in-guest test loop (cosmic-term + `curl` from a host HTTP
server — the guest has networking and a working terminal now).

Cosmetic: the crash leaves an orphaned "SDL" window on the desktop.

---

---

## ✅ Upstream-drift: unpinned `redoxfs` aborted every aarch64 boot (RESOLVED 2026-07-10, U-030)

A fresh build shipped **upstream redoxfs 0.9.1 (July HEAD)** — the recipe was
unpinned — while kernel/relibc are the June-pinned E-OS forks. The initfs
`redoxfs` (PID 17) then died **deterministically** at relibc start with `brk #1`
(`ESR_EL1=0xF2000001`, EC=0x3C) before mounting root; boot never reached login.
Reproduced identically under QEMU TCG `cortex-a72` and HVF on Apple M4, `-smp 1`
and `-smp 4`.

**Diagnosis** (disasm of the initfs binary at the fault ELR): the abort is a
shared `brk #1` landing pad in relibc's start path. `verify()` **passed**
(`X0=0` at the fault — the R-401e kernel fix works); the abort came from a later
early-startup check (`cbz x9` with `X9=0` — a NULL out of TCB/TLS setup;
`X8=0x0000800000000000` looks like a pathological computed TLS address). The
July redoxfs binary's TLS/segment layout appears to hit an edge the June
fork relibc/kernel pair mishandles.

**Fix (shipping):** `recipes/core/redoxfs` is **pinned** to `af493b9f` — the rev
the 0.1.0 SBOM records for the boot-validated image. With only that change the
same build boots to `eos login:`.

**Root cause — CONFIRMED 2026-07-10 by the fork rebase (below): relibc ABI
drift, not a TLS-math edge.** Building the July `redoxfs`/`orbital` from source
against the June sysroot relibc fails to link — `undefined reference to
redox_fcntl_v0` — a versioned relibc symbol the July `redox_scheme` needs but the
June relibc does not export. Under `REPO_BINARY` there was no link step, so the
mismatch surfaced only at runtime as the `brk #1` abort. Rebasing the forks onto
July upstream (which provides the symbol) makes the July `redoxfs`/`orbital`
build **and** boot — see the rebase note below.

## 🔬 Fork rebase onto July upstream — validated, staged, blocked on a virtio-INTx deadlock (2026-07-10)

All **four** code forks were rebased onto current `redox-os` mainline and pushed
to `eos-{kernel,base,relibc,userutils}` branch **`eos-july`**. Crucially this was
done as a **full `git rebase --onto`** carrying the *complete* E-OS fork delta —
not just the upstream-ready patch subset in `upstream/`:

| fork | eos-july rev | E-OS commits over July upstream |
|---|---|---|
| kernel | `cb14af3b` | 8 (incl. the virtual-timer fix + R-401b/d/e; the timer fix is **not** in `upstream/`) |
| base | `3e10b86f` | 13 (incl. R-402 virtio-core INTx + virtio-rng + nvmed INTx + a regenerated `Cargo.lock`) |
| relibc | `963b8f91` | 1 (the TLS patch, a one-hunk 3-way merge) |
| userutils | `260d772` | 4 (incl. the `eos login:` prompt) |

### What the rebase proved (three lessons the "quick" patch-only rebase hid)

1. **A fork carries more than its `upstream/` patches.** The first attempt applied
   only the 2 upstreamable base patches and dropped R-402 virtio-core INTx →
   `virtio-core::arch::aarch64::enable_msix` is `unimplemented!()` upstream, so
   `virtio-netd` panicked. Fixed by rebasing the *full* delta.
2. **All code forks must move together.** userutils was left on June →
   `sudo` panicked `Function not implemented` (June userutils vs July relibc ABI).
   Fixed by rebasing userutils too.
3. **The toolchain sysroot relibc must be rebuilt, and `Cargo.lock` regenerated.**
   Otherwise the July userland fails to link (`undefined reference to
   redox_fcntl_v0` — **this is U-030's confirmed root cause: relibc ABI drift**)
   and `driver-graphics` fails to compile (two `redox_syscall` versions, 0.8 vs
   0.9). Both fixed (sysroot rebuild + `cargo generate-lockfile`).

### Two layered deadlocks found and one fixed — the rebase now boots to login

The fully-rebased image builds, links, and boots with **0 unhandled exceptions**;
all drivers initialise. Boot then hit a **kernel-level deadlock** (all CPUs WFI,
QEMU 0% CPU) right after `virtio-rng` seeds. Root-caused to the aarch64 IRQ path:

- **Kernel INTx deadlock — FIXED** (`eos-kernel@bf4b264e`). On aarch64 the kernel
  deferred the GIC **EOI** of a userspace-handled level-triggered INTx to the
  driver's scheme ack. That leaves the interrupt **active** (GIC running priority
  raised) from the moment it fires until the driver acks — blocking every
  equal/lower-priority interrupt, **including the generic-timer PPI**. But the
  driver can't be scheduled to ack without the timer: a circular deadlock. Fix
  (aarch64-only; riscv64 PLIC already EOIs in-handler, x86 unchanged):
  `dtb::irqchip::trigger_virq` now **masks the line + EOIs in-kernel** before
  notifying userspace (priority drops at once, the timer keeps firing, the masked
  line won't re-fire), and the driver's ack **re-enables** the line instead of
  EOIing again. **This is an upstream-worthy fix** — a real mainline aarch64 INTx
  bug. With it, QEMU goes from 0% → ~5% CPU (the timer fires again).

- **Result: the rebased July stack boots to `eos login:`** with **0 exceptions**
  (kernel `bf4b264e`, base `3e10b86f`, relibc `963b8f91`, userutils `260d772`,
  all `eos-july`; redoxfs/orbital/orbutils on July upstream HEAD, **no pins**).
  Verified on the macOS/M4 rig (headless QEMU, serial login prompt).

- **Remaining: a `virtio-rngd`-specific userspace deadlock** (our optional R-402
  entropy driver). With a `virtio-rng` device attached, boot still freezes right
  after `virtio-rngd` seeds `/scheme/rand` — but now at **~5% CPU (timer alive),
  all userspace threads blocked** (a userspace lock/wait deadlock, not the kernel
  one). **Proof it is isolated to `virtio-rngd`:** booting the *same image* with
  **no `virtio-rng` device** reaches `eos login:` cleanly. The seed itself
  succeeds (the first `pull()` gets 32 bytes), so it is a post-seed interaction of
  `virtio-rngd` with the July relibc/redox-rt runtime, not the INTx path.

- **Resolution: `virtio-rngd` dropped from the July line — the rebase now boots
  to the greeter cleanly.** The optional R-402 `virtio-rng` entropy driver was
  reverted on `eos-base@969c64b9` (the kernel's R-401b jitter entropy still seeds
  randd, so there is no zero-seed regression). With it gone the fully-rebased July
  aarch64 image — kernel `bf4b264e`, base `969c64b9`, relibc `963b8f91`, userutils
  `260d772` (all `eos-july`); redoxfs/orbital/orbutils on July upstream HEAD, **no
  pins** — boots to the **graphical E-OS greeter with 0 exceptions and a
  `virtio-rng` device attached** (the exact config that used to deadlock), CPU
  100%+ throughout (no WFI stall). Verified on the macOS/M4 rig.

**Status: PROMOTED.** The July rebase is validated on **both arches** — aarch64
(graphical greeter, 0 exceptions, virtio-rng device attached) and x86_64 (`eos
login:`, 0 exceptions, ahci/nvme up) — and is now what `main` builds: `core/kernel`,
`core/base`, `core/relibc`, `core/userutils` pin the `eos-july` fork branches, and
`redoxfs`/`orbital`/`orbutils` are **unpinned** (back to upstream — all three U-030
workaround pins removed). Follow-ups: root-cause the `virtio-rngd` userspace
deadlock and restore R-402, and submit the upstream MRs (now including the INTx
mask/EOI fix, `kernel/0005`).

**Confirmed follow-up (2026-07-10):** `orbital` (also unpinned upstream, July
HEAD) crashes the same way **with a display attached** (ramfb GUI boot test:
`UNHANDLED EXCEPTION`, desktop never starts, boot falls back to the branded
framebuffer console — which itself renders correctly, `/etc/issue` + `eos
login:`). Fixed the same way: `recipes/gui/orbital` pinned to `3b60d28a` and
`recipes/gui/orbutils` (greeter/launcher, same risk class) to `46b6d063` — the
0.1.0-SBOM revs.

**Systemic note:** any recipe cooked from an *unpinned* upstream source can
drift against the frozen June forks. The core boot-critical set is now pinned
(kernel, base, relibc, bootloader, userutils, orbdata, redoxfs); the long-term
answer is periodic fork rebases onto upstream, not more pins.

---

## ✅ `R-401b / R-401c / R-401d` — aarch64 boot-to-login (RESOLVED 2026-06-08)

E-OS **aarch64** now boots under QEMU `virt` all the way to the graphical E-OS
COSMIC desktop (login greeter, wallpaper, taskbar, working USB keyboard).

![E-OS aarch64 desktop](../assets/screenshots/eos-aarch64-desktop.png)

The original report — a `redoxfs` root-mount Data Abort — turned out to be the
**last** symptom of a chain of **four** aarch64 bugs. The earlier diagnosis (an
upstream `redoxfs`/`relibc`/`PAGE_SIZE` memory bug) was **wrong**: `redoxfs` was the
last domino, not the cause. The tell is the serial cascade order — **`randd` crashes
first**, then a flood of `failed to generate random data: ENODEV`, then `nvmed`, then
`redoxfs`.

| # | Bug | Fix |
|---|---|---|
| `R-401b` | `randd` runs `mrs xN, RNDRRS` (FEAT_RNG, ARMv8.5) unconditionally → **UNDEF** on non-FEAT_RNG aarch64 (Cortex-A72/A53, Raspberry Pi, `-cpu cortex-a72`) → kills the `rand:` scheme → every daemon that seeds a HashMap panics `ENODEV` → cascade kills `nvmed` & `redoxfs` (the "Data Abort" in the original report). | **kernel:** trap-and-emulate `RNDR`/`RNDRRS` in the aarch64 synchronous-exception handler. |
| `R-401c` | aarch64 has **no MSI**; `nvmed` falls back to INTx but hard-codes `intx:false`, and the INTx IRQ is only *routed* when Redox boots from a **device tree**, not ACPI. | **base:** `nvmed` runs in INTx mode on non-x86. **Boot:** `-machine virt,acpi=off` forces device-tree boot, so the PCIe interrupt-map exists. |
| `R-401d` | the kernel reserved shared PCIe **INTx** GIC SPIs *exclusively* → `nvmed` failed with `open IRQ: EEXIST`. | **kernel:** allow shared phandle-IRQ opens (`irq_trigger` already fans out to every handle). |

The kernel & base fixes live in the **`Gh0s777tt/eos-kernel`** and
**`Gh0s777tt/eos-base`** forks (the `core/kernel` / `core/base` recipes are pinned
to them, so a fresh clone reproduces). Clean upstream patches + a submission guide
are in [`upstream/`](../upstream/README.md).

### Running the aarch64 image

```sh
qemu-system-aarch64 -machine virt,acpi=off -cpu cortex-a72 -m 2048 -smp 4 \
  -drive if=pflash,unit=0,file=/usr/share/AAVMF/AAVMF_CODE.fd,readonly=on,format=raw \
  -drive if=pflash,unit=1,file=AAVMF_VARS.fd,format=raw \
  -device ramfb -device qemu-xhci -device usb-kbd -device virtio-rng-pci -display none \
  -drive file=build/aarch64/eos/harddrive.img,if=none,id=disk0,format=raw \
  -device nvme,drive=disk0,serial=eos
```

> ℹ️ **`-machine virt,acpi=off` is no longer required** (as of `R-401f` — pcid now routes PCIe
> INTx from the ACPI `_PRT`). aarch64 boots under **both** ACPI (`-machine virt`) and device tree
> (`-machine virt,acpi=off`); the device-tree path stays the cleaner default. (The wallpaper
> crash once seen under ACPI was the relibc TLS bug below — fixed.) There is
> no KVM for aarch64 on an x86 host, so QEMU runs under TCG and the boot is slow (minutes).

### Remaining minor items (non-blocking)

- `netstack` / `audiod` exit on QEMU `virt` (no virtual net/audio device) — harmless.
- The emulated `RNDR`/`RNDRRS` entropy (R-401b) now folds in real **CPU-execution-timing
  jitter** (CNTVCT deltas across data-dependent work — the jitterentropy technique) on every
  read, a genuine entropy source on real non-FEAT_RNG hardware. It is still not a certified
  TRNG — a hardware RNG remains the ideal long-term source.

---

## ✅ `relibc verify()` — every aarch64 shell/desktop program aborted (RESOLVED 2026-06-08)

An earlier note here called this a "cosmetic, intermittent `/usr/bin/background`
null-deref inside relibc". That was wrong on every count:

- It is a **`brk #1`** — an explicit **abort/trap**, *not* a memory fault. The serial dump
  has `ESR_EL1` `EC=0x3C` ("BRK instruction execution"); the printed `FAR_EL1` is stale
  and irrelevant.
- It is **deterministic**, not intermittent: **every** `fork`+`exec`-spawned program
  aborted — `whoami`, `id`, `ls`, `env`, `background` (16/16). The aarch64 shell could not
  run a single external command. Only long-lived, init/`pcid`-spawned processes (drivers,
  the `ion` shell itself) survive — which is why the desktop still "rendered".
- It happens in **`relibc_start_v1`** (the program entry), *before* `main`.

**Root cause.** `relibc_start_v1` → `relibc_verify_host()` → `Sys::verify()`:

```rust
fn verify() -> bool {
    // SYS_YIELD is a no-op on Redox; the same number is a different, failing syscall
    // on Linux — a heuristic to refuse running a Redox binary on Linux.
    syscall::syscall5(syscall::number::SYS_YIELD, !0, !0, !0, !0, !0).is_ok()
}
```

On aarch64, `verify()`'s `YIELD` returns a stale `-1` (the input `x0`) instead of `0`, so it
concludes "not Redox" and aborts. (The kernel actually computes `0` correctly; the true root
cause — a signal-vs-syscall-return race — is the kernel bug fixed in `R-401e` below.)
Confirmed two ways: NOP-ing the abort
branch in `libc.so` made `whoami`/`ls`/`env` work with zero crashes, and the fault
symbolizes to the exact `brk #1` at `relibc_start_v1+0xf48` (a `handle_alloc_error`/abort
landing pad reached from the `cmn w0,#0x84; b.cs` error check right after the yield `svc`).

**Fix (relibc).** The [`Gh0s777tt/eos-relibc`](https://github.com/Gh0s777tt/eos-relibc)
fork (`eos` @ `beb93474`, recipe pinned) issues the yield for its side effect but does not
treat its unreliable result as fatal on aarch64; **x86_64 keeps the strict check**.
Verified by binary disasm + boot: `whoami`/`uname`/`ls`/`env` all run, zero aborts.
Upstream-ready patch: [`upstream/relibc/`](../upstream/relibc/).

**The real root fix (kernel) — `R-401e`, RESOLVED 2026-06-08.** The relibc change above is a
workaround; the kernel root cause is now fixed. It is *not* a "stale `x0` after `exec`": on
aarch64, `sched_yield` calls `signal_handler` **inside** the `YIELD` syscall, *before* the
SVC handler commits the return to `scratch.x0`, and aarch64 alone uses `scratch.x0` (the
return register) as `sig_archdep_reg()` (x86/x86_64 use the flags register, riscv64 a
temporary). So a signal delivered to a context during its yield saved the stale *input* `x0`
and `sigreturn` restored it over the real return (`0`) — breaking the first
signal-receiving `fork`+`exec` program (`whoami` was hit; init-spawned daemons were not).
The kernel now commits the yield return **before** the signal check (`cfg`-scoped to
aarch64), fixed in [`eos-kernel`](https://github.com/Gh0s777tt/eos-kernel) `@ 97ca1607` and
validated on the **unpatched-relibc** image (`whoami`/`uname`/`ls` run, 0 aborts). With the
kernel fixed, relibc has been **reverted to strict upstream** (`core/relibc` re-pinned to
`@ bcc1a0d4`); the production image was rebuilt with strict upstream relibc on the R-401e
kernel and boots with 0 aborts (disasm confirms the strict `verify()` abort branch is present
in the shipped `libc.so`, so it would abort 16/16 without the kernel fix). R-401e is the
upstream contribution (`upstream/kernel/0003-*`); the relibc workaround patch is retired.

---

## ✅ relibc TLS layout — every thread crashed on exit, BOTH arches (RESOLVED 2026-06-10, R-402a)

The long-deferred "intermittent `/usr/bin/background` null-deref" was root-caused with a
kernel-side fault-map dump: it is a **systemic relibc static-TLS bug** — every thread in a
thread-spawning program crashed **on exit** (`relibc::pthread::exit_current_thread` walking
the `CLEANUP_LL_HEAD` thread-local, which read garbage instead of NULL). ion background jobs
reproduce it deterministically: **5/5 on aarch64, 3/3 on x86_64** (the x86_64 case was
verified **pre-existing on unpatched upstream** relibc — it had simply never been exercised).

Two distinct mechanisms, both masked for most workloads by lucky zeroed memory:

- **aarch64/riscv64:** the linker stored x86-style end-relative `Master::offset`
  (`cum+memsz`) which the non-x86 `copy_masters`/DTV paths consume start-relative — every
  module's TLS image copied where nothing reads it (`.tdata` initializers silently zero) —
  plus the static TLSDESC descriptor missing the 16-byte aarch64 TCB bias (all
  dynamic-object TLS reads shifted −16, boundary variables reading the *neighbouring
  module's* memory), the TPOFF reloc using the x86 negative form, and `__tlsdesc_dynamic`
  subtracting the TCB pointer instead of TP (broken dlopen TLS).
- **x86/x86_64:** the backwards placement used the **raw `p_memsz`** for the
  distance-from-end while the static linker computes local-exec offsets from
  **`align_up(p_memsz, p_align)`** — for `ion` (`memsz 0x2c8`, `align 0x10`) the `.tdata`
  image landed 8 bytes above the local-exec plane, overlaying neighbouring thread-locals
  with shifted initializer bytes; Rust std's thread-dtor list head read a shifted nonzero
  constant and the std dtor walked a garbage list at thread exit (near-null fault at
  `0x70`). The x86 static-TLSDESC descriptor also had a wrong sign (corrected, though no
  current binary emits it).

**Fix:** explicit per-arch offset conventions in the
[`eos-relibc`](https://github.com/Gh0s777tt/eos-relibc) fork, branch `eos-tls` `@ 0d30e9ea`
(one clean commit over upstream `bcc1a0d4`; `core/relibc` re-pinned): x86/x86_64 keep the
backwards layout but with alignment-correct placement and a correctly signed TLSDESC;
aarch64/riscv64 use forward, `p_align`-aligned start-based offsets with the aarch64 TCB bias
in TLSDESC/TPOFF. **Verified:** the ion job repro goes **5/5 → 0 (aarch64)** and
**3/3 → 0 (x86_64)**; full production boots clean on both arches. Upstream has no fix on
`master`; the upstream-ready patch is `upstream/relibc/0001-*` and includes a regression test
(`tests/pthread/tls_initexit.c`) covering both failure modes.

## `R-F08` — Greeter/desktop VT not auto-activated on boot

**Status:** ✅ **RESOLVED `U-078` (2026-07-13)** — booting the aarch64 image now lands directly on the crimson greeter, no `Super+F3` (`assets/screenshots/eos-greeter.png`).

**Actual root cause** (found via a fresh `inputd` serial trace — it corrects the display-handoff hypothesis below): the VT2 activation is the init service `/usr/lib/init.d/30_console` running **`inputd -A 2`** (a CLI that writes a `VtActivate` control event). The installer **concatenates** all `[[files]]` entries with no dedup (`redox_installer::Config::merge` → `self.files.extend(other_files)`), self merged last. `minimal.toml` defines `30_console` **with** `inputd -A 2`; `desktop-minimal.toml` overrides it **without**. But `desktop.toml` includes BOTH `desktop-minimal.toml` AND `server.toml`, and `server.toml` also pulls `minimal.toml` — so in `desktop.toml`'s merge the order is `resolve(desktop-minimal).files ++ resolve(server).files ++ …`, and `server→minimal`'s `inputd -A 2` copy lands **after** desktop-minimal's clean one, winning on disk. At boot: bootlog activates VT1, `20_orbital` activates the greeter's VT3, then the late `30_console` (`requires_weak 10_net.target`) runs `inputd -A 2` → steals to the text console VT2.

**Fix (`U-078`):** `config/{aarch64,x86_64}/eos.toml` — the root config, merged dead-last, so its `[[files]]` win — pin `/usr/lib/init.d/30_console` **without** `inputd -A 2` (keep `nowait getty 2` so VT2 stays reachable via `Super+F2`, and `requires_weak 20_orbital` to order after the greeter). No `inputd`/recipe code change; `inputd` instrumentation reverted. Verified end-to-end: clean image boots straight to the greeter with no key press.

---

**Original diagnosis (superseded — kept for the record):** open, **P1** (first-boot UX; the desktop itself works via `Super+F3`). Root cause was believed to be an inputd/display-handoff activation.

The graphical session starts and renders correctly (`R-F07`); `Super+F3` reaches the crimson greeter, the desktop, and `eos-settings` (`assets/screenshots/`). The defect is only that the framebuffer keeps showing the text console at boot until `Super+F3`.

**Exact VT lifecycle** (from instrumented `inputd`, serial trace):
```
consumer_bootlog VT=1 -> switch_vt->1        (fbbootlogd / boot log)
consumer VT=2 (fbcond), consumer VT=3 (orbital)   [is_none guard: no auto-switch]
CONTROL activate_vt(3) pid=37 -> switch_vt->3     (orbital shows the greeter)
CONTROL activate_vt(2) pid=38 -> switch_vt->2     (VT2 STEALS the display)
```
`inputd` (`drivers/inputd/src/main.rs`) auto-activates only the FIRST VT created (`if active_vt.is_none()`, ~L178); VT1 (bootlog) grabs it. Then two clients call `activate_vt` via the control scheme: orbital (pid 37) activates its VT3 (greeter visible), and **pid 38 activates VT2 and steals focus**. Pid 38 is **`fbcond`** — the framebuffer text console (`00_fbcond.service`, `cmd="fbcond"`, `args=["2"]`, `type={scheme="fbcon"}`). Because it is a lazy `scheme`-type service it spawns *after* orbital, and opening its VT2 display activates VT2 via the same display library orbital uses. **Ruled out:** `getty 2` (removing it did not change the trace), `on_close` (never fired), keyboard. VT switching itself works via `Super+F<n>` (inputd L405: `K_SUPER`+`K_F1..F12`).

**Fix candidates** (need one build+boot cycle to verify): (a) make `fbcond` spawn **eagerly before** `20_orbital` so orbital's activation is the last one to win; (b) make `fbcond` (or the shared display-open path) **not activate** its VT when a higher graphical VT is already active; (c) drop the framebuffer text console for the graphical image variant (VT2 console then only via the serial getty + desktop terminal). **Candidate (a) TESTED 2026-07-13 → FAILED:** making `20_orbital` `requires_weak 00_fbcond.service` did not help — the RF08 trace is unchanged (orbital activates VT3, then the VT2 activator fires *after*). So the VT2 activation is **not** at consumer-open and can't be reordered by spawn order; it happens later (on the earlyfb→real-display **handoff** or on console content). The fix therefore needs a `fbcond` / display-open change to suppress activation when a higher graphical VT is already active (candidate b), or dropping the framebuffer console for the graphical variant (candidate c). **Candidate (c) TESTED 2026-07-13 → FAILED:** disabling `00_fbcond` (no-op oneshot) did not cleanly work — the greeter did not confirm-appear (the crimson poll false-matched the red bootloader menu) and it exposed a `vesad` crash. So (a) [require-fbcond-first] and (c) [drop fbcond] are both out; only **(b)** remains: change `fbcond`/the shared display-open so it does not `activate_vt` when a higher graphical VT is already active. **Separate bug found:** `vesad` (`drivers/graphics/vesad/src/main.rs:64`) parses `/scheme/sys/env` with `line.split_once('=').unwrap()` and panics on any line without `=` — worth a defensive fix regardless of R-F08. **Repro/diagnosis method:** instrument `inputd` `switch_vt`/`consumer`/control-write to append to `/scheme/debug` (serial), since inputd's own `log::debug!` goes only to logd. Capture the window without a mouse: log in on a getty, run `eos-settings &`, then `Super+F3`.
