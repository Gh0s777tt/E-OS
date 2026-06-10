# 📓 Changelog

All notable changes to **E-OS** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Legend:** `Added` · `Changed` · `Deprecated` · `Removed` · `Fixed` · `Security`
> Each release is numbered (`SemVer`) and code-named. Entries are intentionally
> verbose — every line should tell you *what* changed and *why*.

---

## [Unreleased]

### Added
- `[U-001]` Project automation: GitHub Actions CI, **CodeQL** code scanning,
  **gitleaks** secret scanning and **Dependabot** dependency updates.
- `[U-002]` `CODEOWNERS`, issue/PR templates, `FUNDING.yml`.
- `[U-004]` **Custom build config** `config/x86_64/eos.toml` — the E-OS desktop
  variant (`make CI=1 CONFIG_NAME=eos all`).
- `[U-005]` **OS-level rebranding** via `postinstall` file overrides:
  `/etc/os-release`, `/etc/issue` login banner, hostname and `/etc/motd` → E-OS.
- `[U-006]` First desktop screenshot — `assets/screenshots/eos-cosmic-desktop.png`
  (COSMIC running on E-OS under QEMU/KVM).
- `[U-007]` **Red/black E-OS bootloader** — `"E-OS Bootloader"` banner + red-on-black
  theme (selection black-on-red), built from source. Change set:
  `patches/bootloader-eos-red-black.patch`; screenshot `assets/screenshots/eos-bootloader.png`.
- `[U-008]` **aarch64 boots to the full branded desktop** (2026-06-08). E-OS now
  reaches the graphical E-OS COSMIC desktop on **aarch64** under QEMU `virt` (with
  `-machine virt,acpi=off`); it previously died at early boot. Screenshot
  `assets/screenshots/eos-aarch64-desktop.png`. Both x86_64 and aarch64 build from
  the same recipes and boot to the desktop.
- `[U-009]` **Downstream kernel/base/relibc forks** carrying the aarch64 (and one
  cross-arch relibc) fixes — [`Gh0s777tt/eos-kernel`](https://github.com/Gh0s777tt/eos-kernel)
  (`master` @ `35bdc7d3`), [`Gh0s777tt/eos-base`](https://github.com/Gh0s777tt/eos-base)
  (`main` @ `6c695a10`), and [`Gh0s777tt/eos-relibc`](https://github.com/Gh0s777tt/eos-relibc)
  (`eos-tls` @ `c17cde00`). The `core/kernel` + `core/base` + `core/relibc` recipes are
  **pinned** to them. Reproducibility **empirically verified** (2026-06-10): a forced clean
  re-fetch of all three forks (`u.*` to delete the cached sources, the state of a fresh clone)
  re-cooked straight from the GitHub origins and rebuilt an aarch64 image that boots to login
  with 0 aborts — plus an x86_64 regression build.
- `[U-010]` **Upstream-ready patches + submission guide** — `upstream/` holds clean
  `git am` patches (4 kernel, 2 base) and a `gitlab.redox-os.org` merge-request guide.
- `[U-017]` **Downstream relibc fork — RETIRED.** It briefly carried an aarch64 `verify()`
  workaround, but `R-401e` (`[U-018]`) fixes the true cause in the **kernel**, so
  `core/relibc` is back on **strict upstream relibc** (`@ bcc1a0d4`) and the fork is no
  longer used. The upstream-ready fix is now the kernel patch `upstream/kernel/0003-*`.

### Changed
- `[U-003]` Documentation expanded under `docs/` (architecture, building, security, FAQ).
- `[U-014]` `core/kernel` + `core/base` recipes now build from the E-OS forks (pinned
  by commit) instead of tracking upstream HEAD. `docs/known-issues.md` rewritten
  (R-401b/c/d **resolved**, with the true root cause and the aarch64 QEMU command);
  `ROADMAP.md` `R-401b` → ✅.

### Fixed
- `[U-011]` **`R-401b` — the real aarch64 boot blocker (mis-diagnosed for a whole
  prior session).** `randd` executed `mrs xN, RNDRRS` (FEAT_RNG / ARMv8.5)
  **unconditionally** → an UNDEFINED instruction on non-FEAT_RNG CPUs (Cortex-A72/A53,
  Raspberry Pi, `-cpu cortex-a72`) → `randd` died → the `rand:` scheme never started →
  every daemon that seeds a HashMap panicked `failed to generate random data: ENODEV`
  → no boot. The original report blamed an upstream `redoxfs`/`PAGE_SIZE` memory bug;
  that was **wrong** — redoxfs was the *last* domino. **Fix:** the kernel now traps the
  UNDEF and **emulates RNDR/RNDRRS** in the aarch64 synchronous-exception handler. The
  emulation folds in real **CPU-jitter entropy** per read (CNTVCT timing deltas — the
  jitterentropy technique — not a single-seed PRNG); `eos-kernel @ 35bdc7d3`,
  `upstream/kernel/0004`.
- `[U-012]` **`R-401c` — nvmed never received its PCIe interrupt on aarch64.** aarch64
  has **no MSI**; nvmed hard-coded `intx:false`, and INTx is only *routed* when Redox
  boots from a **device tree**, not ACPI. **Fix:** nvmed runs in **INTx mode** on
  non-x86 (base), and the image boots with **`-machine virt,acpi=off`** so the PCIe
  interrupt-map is present.
- `[U-013]` **`R-401d` — shared PCIe INTx IRQ rejected.** The kernel reserved shared
  INTx GIC SPIs **exclusively**, so `nvmed` failed `open IRQ: EEXIST`. **Fix:** allow
  shared phandle-IRQ opens (the kernel's `irq_trigger` already fans an IRQ out to
  every registered handle).
- `[U-016]` **The aarch64 shell/desktop could not run *any* external program — a
  mis-diagnosed relibc abort.** The prior session logged this as a "cosmetic,
  intermittent `/usr/bin/background` null-deref inside relibc"; it is in fact a
  **deterministic `brk #1` abort** (an explicit trap, *not* a memory fault — `ESR_EL1`
  `EC=0x3C`) that hit **every** `fork`+`exec`-spawned binary — `whoami`, `ls`, `env`,
  `background`, the whole desktop session (16/16 reproductions). Root cause:
  `relibc_start_v1` → `relibc_verify_host` → `Sys::verify()` issues `SYS_YIELD` (a
  Redox-vs-Linux host check) and aborts unless it returns `Ok`; on aarch64 a freshly
  `fork`+`exec`'d process's **first** syscall returns a stale `-1` (the input, never
  overwritten by the kernel) instead of `YIELD`'s `0`, so the check spuriously failed.
  **Fix:** the **`Gh0s777tt/eos-relibc`** fork issues the yield for its side effect but
  does not treat its unreliable result as fatal on aarch64 (x86_64 keeps the strict
  check). Verified by binary disasm **and** boot: `whoami`/`uname`/`ls`/`env` all run with
  **zero aborts**. The deeper kernel bug (the first syscall after `exec` returns a stale
  `x0` on aarch64) is now **fixed at the source in `[U-018]`** — and the real cause turned
  out *not* to be a stale `x0` but a signal-vs-syscall-return ordering bug. With the kernel
  fixed (`[U-018]`), relibc has been **reverted to strict upstream** (`@ bcc1a0d4`) — the
  workaround is gone.
- `[U-018]` **`R-401e` — the aarch64 kernel root cause behind the `verify()` abort
  (`[U-016]`), now fixed in the kernel.** The "first syscall after `exec` returns a stale
  `x0`" diagnosis from the prior session was **wrong**. Real cause: `sched_yield` calls
  `signal_handler` *inside* the `SYS_YIELD` syscall, **before** the aarch64 SVC handler
  commits the syscall return to `scratch.x0`. On aarch64 *alone*, `sig_archdep_reg()` is
  `scratch.x0` — which is **also** the syscall return register (x86/x86_64 use the flags
  register, riscv64 a temporary `t0`). So a signal delivered to a context **during** its
  yield saved the stale syscall *input* `x0` (`verify()`'s `YIELD` passes `!0` in every
  arg) and `sigreturn` restored it over the real return (`0`) — the interrupted program
  then saw `x0 = -1` and aborted. Only `fork`+`exec`'d processes with a signal pending
  during their first yield were hit, which is exactly why shell-spawned `whoami` failed but
  init-spawned daemons did not. **Fix** ([`Gh0s777tt/eos-kernel`](https://github.com/Gh0s777tt/eos-kernel)
  `master` @ `97ca1607`, `core/kernel` recipe re-pinned): commit the yield's return (`0`)
  into the frame **before** the signal check, `cfg`-scoped to aarch64 (the only arch where
  `x0` is the return register). **Validated** by booting the fixed kernel on the
  **unpatched-relibc** image — `whoami`/`uname`/`ls` all run with **0 aborts** (was 16/16) —
  so the kernel fix alone is sufficient. The relibc `[U-016]`/`[U-017]` workaround has
  accordingly been **reverted to strict upstream relibc** (`core/relibc` re-pinned to
  `@ bcc1a0d4`), and R-401e added to `upstream/kernel/0003-*` (the relibc workaround patch
  retired). Verified end-to-end: the rebuilt production image boots **strict** upstream relibc
  on the R-401e kernel with **0 aborts** — disasm confirms the strict `verify()` abort branch
  (`svc; cmn w0,#0x84; b.cs`) is present in the shipped `libc.so`, so it would abort 16/16
  without the kernel fix. **x86_64 non-regression confirmed** — rebuilt + KVM-boot-verified
  with the same recipes (kernel `@ 97ca1607`, strict upstream relibc): `whoami`/`uname` run,
  0 aborts, `uname` reports the x86_64 kernel `@ 97ca1607`; R-401e is `cfg`-scoped so x86_64
  is unaffected.
- `[U-019]` **`R-401f` — aarch64 no longer needs `-machine virt,acpi=off`.** Under a UEFI/ACPI
  boot, `pcid` got the ECAM from MCFG but **no PCIe interrupt-map** (that only exists under a
  device tree), so it could not route legacy **INTx** — `nvmed` hung waiting for its IRQ, which is
  exactly why aarch64 had to force a device-tree boot with `acpi=off`. **Fix** (pcid-only;
  [`Gh0s777tt/eos-base`](https://github.com/Gh0s777tt/eos-base) `@ 6c695a10`): pcid reads
  `\_SB.PCIx._PRT` from acpid's `acpi:/symbols`, resolves each entry's PCI interrupt link device
  (`_SB.Lxxx`) to its GSI via the link's `_CRS` (Extended-Interrupt descriptor), and routes it to
  the matching **GIC SPI** by opening `irq:phandle-0` (phandle 0 = the MADT-registered GIC; aarch64
  builds with `cfg(dtb)` so the phandle IRQ path is available under ACPI). The `_PRT` is read
  **before** pcid registers with acpid, to avoid a deadlock against acpid's AML-interpreter build.
  No kernel or acpid change. **Verified** on the production image: boots with **both** `-machine
  virt` (ACPI) **and** `-machine virt,acpi=off` (device tree) — `nvmed` initializes, redoxfs
  mounts, login reached, `whoami`=`user` in both. (The `/usr/bin/background` data-abort
  occasionally seen in these boots was a then-undiagnosed relibc TLS bug, unrelated to R-401f —
  since root-caused and **fixed in `[U-020]`**.) **Cross-arch
  gate**: the `_PRT` routing is `cfg!`-gated to **non-x86** — on x86/x86_64 legacy INTx is routed
  by plain IRQ line (PIC/IOAPIC) and `irq:phandle-N` does not exist in non-`dtb` kernels, so those
  arches keep their existing path untouched (and pcid no longer risks triggering acpid's AML build
  before registering its `pci_fd`). **x86_64 non-regression verified** with the new base under KVM:
  login reached, 0 aborts, and zero `phandle`/`_PRT` activity in the boot log; aarch64 ACPI boot
  re-verified on the gated rev (`_PRT` routing resolves, nvmed up, login, `whoami`=`user`).
  Upstream: `upstream/base/0002` (single squashed patch, gate included).
- `[U-020]` **`R-402a` — the "intermittent `/usr/bin/background` crash" was a systemic relibc
  TLS-ABI bug on BOTH arches: every thread crashed on exit.** Hunted with a kernel-side fault-map dump
  (`EOS-FAULT`/`EOS-MAP`): ion's background-job threads crashed **deterministically (5/5)** at the
  same PC — symbolized to `relibc::pthread::exit_current_thread` walking `CLEANUP_LL_HEAD`, a
  `#[thread_local]` that read garbage (`8`) instead of NULL. Root cause: relibc's static-TLS
  machinery reused **x86 conventions on aarch64**, leaving three planes inconsistent — module
  images copied at `cum+memsz` (end-relative `Master::offset`) while local-exec reads expect
  `TP+16+offset`, TLSDESC descriptors missing the 16-byte TCB bias (every dynamic TLS access
  shifted −16, boundary variables reading the *neighbouring module's* data), the TPOFF reloc using
  the x86 negative form, `__tlsdesc_dynamic` subtracting the TCB pointer instead of TP (broken
  dlopen TLS), and static binaries' `.tdata` displaced the same way (initializers silently read
  as zeros). "Intermittent" was an illusion: only thread-spawning programs (ion jobs, the
  wallpaper renderer) hit thread-exit, deterministically per build. **The same repro then exposed
  x86_64** — 3/3 ion job threads crashed with a near-null fault at `0x70`, **baseline-verified
  pre-existing on strict unpatched upstream** (no prior x86_64 test had ever spawned `&` jobs).
  Probing it the same way (memory-map dump → symbolization → ld.so module-table trace →
  pthread-key trace) pinned a *different* mechanism: relibc's backwards x86 placement used the
  **raw `p_memsz`** for the distance-from-end while the static linker computes local-exec offsets
  from **`align_up(p_memsz, p_align)`** — for ion (`memsz 0x2c8`, `align 0x10`) the `.tdata` image
  lands 8 bytes above the local-exec plane, overlaying neighbouring thread-locals with shifted
  initializer bytes; Rust std's thread-dtor list head read a shifted nonzero constant and the std
  dtor walked a garbage list at thread exit. (The x86 static-TLSDESC descriptor also had a wrong
  sign — corrected too, though no current binary emits it.) **Fix**
  ([`Gh0s777tt/eos-relibc`](https://github.com/Gh0s777tt/eos-relibc) branch `eos-tls`
  `@ c17cde00`, one clean commit over upstream `bcc1a0d4`, `core/relibc` re-pinned): explicit
  per-arch offset conventions — x86/x86_64 keep the backwards layout but with **alignment-correct
  placement** and a correctly signed TLSDESC; aarch64/riscv64 use forward, `p_align`-aligned
  start-based offsets with the aarch64 TCB bias in TLSDESC/TPOFF, and the dynamic resolver
  subtracts TP. **Verified**: the ion job repro goes **5/5 → 0 (aarch64)** and **3/3 → 0
  (x86_64)**; full production boots on both arches stay clean. Upstream has no fix for this
  (checked `master`); upstream-ready patch in `upstream/relibc/0001-*`. Upstream bug-fix patch
  count is now **4 kernel + 2 base + 1 relibc**.

### Known
- `[U-015]` aarch64 now boots under **both** ACPI (`-machine virt`) and device tree
  (`-machine virt,acpi=off`); the `acpi=off` workaround is **no longer required** as of
  `[U-019]` (`R-401f`). The GitLab mirror (`gitlab.com/Gh0s777tt/e-os`) is kept **in sync**
  with GitHub.

### Planned
- See **[ROADMAP.md](ROADMAP.md)** for what's coming in `v0.2.0` and beyond.

---

## [0.1.0] — "Genesis" — 2026-06-06

> 🎉 **First verified-bootable E-OS base.** E-OS is re-founded on **modern upstream
> Redox OS** (the 2019 mirror is archived) and boots end-to-end under QEMU/KVM.

### Added
- `[0.1.0-001]` **Modern Redox base.** Re-based onto upstream Redox build system
  commit `84d78137` (`0.9.0-6174`), Rust toolchain `nightly-2026-05-24`, full
  **COSMIC desktop** config (`config/desktop.toml`).
- `[0.1.0-002]` **Reproducible build environment**: WSL2 Ubuntu + rootless
  **Podman 5.7** (crun), **QEMU 10.2.1** with KVM. Documented in
  [`EOS_BUILD_STATE.md`](EOS_BUILD_STATE.md).
- `[0.1.0-003]` **Verified boot.** `build/x86_64/desktop/harddrive.img` (681 MB,
  RedoxFS 647 MiB) boots: UEFI → bootloader → kernel → init → drivers
  (`nvmed`, `ahcid`, `xhcid`, `ihdad`, `e1000d`) → `login:` prompt.
- `[0.1.0-004]` **E-OS brand & repo identity** — Netflix-red/black README,
  documentation set, changelog, roadmap, branding assets.

### Changed
- `[0.1.0-005]` **License → AGPL-3.0.** E-OS as a whole is now strong-copyleft
  (anti-appropriation). Inherited Redox components remain **MIT**; original
  notices preserved in `licenses/Redox-OS-MIT.txt` and [`NOTICE`](NOTICE).
- `[0.1.0-006]` Original Redox `README` preserved at `docs/REDOX-README.md`.

### Fixed
- `[0.1.0-007]` **Headless build crash.** `repo cook` panicked
  `slice index starts at 1 but ends at 0` (`src/bin/repo.rs:1693`) when its TUI
  ran without a real terminal (`panel_height == 0`). **Resolution:** build with
  **`CI=1`** to disable the TUI (`config.rs`: `tui = !(CI set & non-empty)`).
- `[0.1.0-008]` **KVM permissions** for `make qemu` — user added to the `kvm`
  group (`/dev/kvm` is `root:kvm 0660`).

### Security
- `[0.1.0-009]` Strong-copyleft licensing (AGPL-3.0) adopted as a deliberate
  anti-appropriation measure for the distribution.

### Provenance
- Verified base saved on both remotes as branch **`eos-base`** + tag
  **`eos-base-2026-06-06`** (commit `60ba2d1e`). The 2019 Redox mirror is
  retained on the legacy `master` (GitLab) / `0.4.1` (GitHub) branches.

---

[Unreleased]: https://github.com/Gh0s777tt/E-OS/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Gh0s777tt/E-OS/releases/tag/v0.1.0
