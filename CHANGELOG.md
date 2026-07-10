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
  (`eos-tls` @ `0d30e9ea`). The `core/kernel` + `core/base` + `core/relibc` recipes are
  **pinned** to them. Reproducibility **empirically verified** (2026-06-10): a forced clean
  re-fetch of all three forks (`u.*` to delete the cached sources, the state of a fresh clone)
  re-cooked straight from the GitHub origins and rebuilt an aarch64 image that boots to login
  with 0 aborts — plus an x86_64 regression build.
- `[U-010]` **Upstream-ready patches + submission guide** — `upstream/` holds clean
  `git am` patches (4 kernel, 2 base, 1 relibc) and a `gitlab.redox-os.org` merge-request
  guide, plus `upstream/MR-DESCRIPTIONS.md` (paste-ready MR titles/bodies). All seven
  re-verified to `git am` cleanly onto current mainline (2026-06-10).
- `[U-017]` **Downstream relibc fork — RETIRED.** It briefly carried an aarch64 `verify()`
  workaround, but `R-401e` (`[U-018]`) fixes the true cause in the **kernel**, so
  `core/relibc` is back on **strict upstream relibc** (`@ bcc1a0d4`) and the fork is no
  longer used. The upstream-ready fix is now the kernel patch `upstream/kernel/0003-*`.
- `[U-021]` **Hardware support matrix** — `docs/hardware-matrix.md` records the driver
  coverage verified by live QEMU boots on **x86_64** (q35/KVM) and **aarch64** (`virt`,
  `-cpu cortex-a72`): nvmed, ahcid, virtio-blk/gpu/net, e1000/e1000e, rtl8139, ihda, xhci.
  `scripts/qemu-driver-check.sh [x86_64|aarch64]` regenerates it from a single
  kitchen-sink boot.
- `[U-031]` **x86_64 regression build + both-arch boot verification on macOS.** After
  U-029/U-030, rebuilt **both** arches from source (all seven forks forced via `scr.*`)
  and boot-tested them on the Apple-Silicon rig: **x86_64** (q35/TCG, headless) reaches
  `eos login:` with the `E-OS Bootloader` banner and 0 unhandled exceptions;
  **aarch64** (virt/TCG, ramfb) reaches the graphical **red/black E-OS greeter** with 0
  exceptions once `orbital`/`orbutils` are pinned (`assets/screenshots/eos-aarch64-greeter-macos-build.png`).
- `[U-032]` **Upstream patch set re-verified against July mainline.** The 7 upstream-ready
  patches were re-checked against current `redox-os` `master` (kernel `fbfe439`, base
  `9e12870`, relibc `d589900`): 4 kernel + 2 base still `git am` cleanly, the 1 relibc
  patch needs only a trivial 3-way merge (an upstream `.expect()`→`.expect_notls()`
  rename), and **none** of the fixes have landed upstream — so the forks remain
  necessary. `upstream/README.md` verification note updated.
- `[U-040]` **`R-209` — the `eos` system command.** `recipes/other/eos` now ships
  `/usr/bin/eos`: `eos info` (E-OS/kernel/build details), `eos doctor` (quick health
  check — entropy source, home, hostname), `eos welcome`, `eos help`. Written in ion
  syntax verified construct-by-construct against ion's own test corpus (`fn`, `if/else
  if`, `test $x = "y"`, `test -f/-e/-d`, `$len(@args)`, `@args[1]`) and confirmed present
  in the built image. **Runtime boot-verification is still pending:** the July kernel
  emits a `debug!` on every `call_fdread`, which floods the serial console under QEMU
  TCG and starves the login getty's input — so an automated serial-login test can't
  drive it yet. Quieting the kernel's default log level is the follow-up (it also slows
  every TCG boot). `eos-welcome`'s app list was corrected to what actually ships.
- `[U-041]` **`R-207` follow-up — COSMIC GUI apps blocked on the aarch64 build host.**
  `cosmic-store`/`settings`/`reader` pull `fontconfig` → `host:gperf`, whose redoxer
  host toolchain Redox publishes **only for x86_64-linux** build hosts. On this Apple
  Silicon (aarch64) build host the toolchain fetch 404s; the apps build fine on an
  x86_64-linux host (the WSL2 rig). The config note records this accurately; the CLI
  toolbox (nano/vim/git/curl/wget/ripgrep/nushell/openssh) ships on both arches.
- `[U-039]` **Upstream patch set refreshed & expanded to 13 patches — ready to submit.**
  Regenerated `upstream/` from the rebased forks (`eos-july`): **6 kernel, 6 base, 1
  relibc**, up from 7. Two new kernel fixes found during the rebase are now included —
  the virtual-timer IRQ registration (`kernel/0005`) and the level-INTx EOI deadlock
  (`kernel/0006`) — plus previously-uncontributed base fixes (`_PRT` cfg-gate,
  virtio-core INTx, randd RNDRRS, ihdad boot-hang). **All 13 `git am` cleanly onto a
  fresh mainline clone** (kernel `@ 20a813c5`, base `@ 2f06b013`, relibc `@ 284852a0`);
  none have landed upstream. `upstream/MR-DESCRIPTIONS.md` and `README.md` updated with
  the new patches and a no-new-account submission path (sign in to gitlab.redox-os.org
  with an existing gitlab.com account). Submission itself is the maintainer's account
  step — the patches are prepared and verified. — the whole boot→desktop
  stack is now under `Gh0s777tt`.** Mirrored the **16** Redox-authored components E-OS
  ships (that weren't already forked) into `Gh0s777tt/eos-*` and re-pointed their recipes,
  each pinned to an exact rev: `redoxfs`, `orbital`, `orbutils`, `orbterm`, `orbclient`,
  `liborbital`, `ion`, `coreutils`, `extrautils`, `netutils`, `netdb`, `pkgutils`, `pkgar`,
  `installer`, `redoxer`, `redox-fatfs`. Together with the 6 modified forks, **all 22
  Redox-authored packages in the E-OS image build from E-OS-owned repos** — editable
  freely, reproducible, independent of `gitlab.redox-os.org`. The ~1900 third-party
  software ports (vim/curl/gcc/COSMIC-from-pop-os/…) are deliberately **not** vendored —
  they are upstream projects, not Redox. New `docs/forks.md` (the full map + policy) and
  `scripts/sync-forks.sh` (report/fast-forward the pure mirrors vs upstream).
- `[U-037]` **`R-207` — usable CLI toolbox out of the box.** A fresh E-OS install shipped
  only an editor, file manager, terminal and netsurf. `config/*/eos.toml` now adds a
  practical CLI toolbox — `nano`, `vim`, `git`, `curl`, `wget`, `ripgrep`, `nushell`,
  `openssh` (both arches; filesystem grown 700 → 1400 MiB; `eos-welcome` updated). The
  extra COSMIC GUI apps (store/settings/reader) are **deferred**: their cookbook build
  pulls `fontconfig`, which needs the `gperf` host tool (`recipes/wip`) that the
  `REPO_BINARY` resolver does not auto-build — a follow-up. `cosmic-monitor` is dropped
  outright (its version fails to compile against the current `libcosmic`).
- `[U-036]` **`main` PROMOTED to the July fork rebase — all upstream-drift workaround
  pins removed.** With both arches validated (aarch64 greeter + x86_64 `eos login:`, 0
  exceptions each), the recipes now build the rebased forks: `core/kernel` →
  `eos-july@bf4b264e`, `core/base` → `eos-july@969c64b9`, `core/relibc` →
  `eos-july@963b8f91`, `core/userutils` → `eos-july@260d7725`, and `redoxfs`/`orbital`/
  `orbutils` are **unpinned** (the three U-030 SBOM pins are gone — the rebase resolved
  the relibc-ABI drift that required them). E-OS's forks are now current with July
  mainline, carry the same fixes plus the new INTx deadlock fix, and ship no workaround
  pins. `docs/known-issues.md` marks the rebase promoted.
- `[U-035]` **July rebase now boots to the greeter on aarch64 — `virtio-rngd` dropped
  from the July line.** After the INTx fix (U-034) the only remaining blocker was a
  `virtio-rngd`-specific userspace deadlock (proven isolated: the same image with no
  `virtio-rng` device reached login). Root-causing it needs userspace thread-state
  instrumentation; pragmatically, the **optional** R-402 `virtio-rng` entropy driver was
  reverted on `eos-base@969c64b9` (the kernel R-401b jitter entropy still seeds randd —
  no zero-seed regression). The fully-rebased July aarch64 image (kernel `bf4b264e`, base
  `969c64b9`, relibc `963b8f91`, userutils `260d772`, all `eos-july`; redoxfs/orbital/
  orbutils on July HEAD, **no workaround pins**) now boots to the **graphical E-OS
  greeter with 0 exceptions and a `virtio-rng` device attached** — the exact config that
  used to deadlock — CPU 100%+ throughout. **The July rebase is complete and validated on
  aarch64.** Remaining before promoting it over the June forks on `main`: an x86_64
  cross-build/boot check (in progress). `virtio-rngd` root-cause and the upstream MRs
  (now including the INTx fix) are follow-ups.
- `[U-034]` **aarch64 kernel INTx deadlock fixed — the rebased July stack now boots to
  login.** Root-caused the WFI deadlock (U-033): on aarch64 the kernel deferred the GIC
  **EOI** of a userspace-handled level-triggered INTx to the driver's scheme ack,
  leaving the interrupt active (GIC priority raised) and blocking the generic-timer PPI
  until the driver acks — but the driver can't be scheduled to ack without the timer, a
  circular deadlock. Fix (`eos-kernel@bf4b264e`, aarch64-only; riscv64 PLIC already EOIs
  in-handler, x86 unchanged): `dtb::irqchip::trigger_virq` masks + EOIs the line
  in-kernel before notifying userspace, and the driver's ack re-enables it instead of a
  double-EOI. **An upstream-worthy mainline aarch64 bug fix.** With it the rebased July
  stack (kernel `bf4b264e`, base `3e10b86f`, relibc `963b8f91`, userutils `260d772`, all
  `eos-july`; redoxfs/orbital/orbutils on July HEAD, no pins) **boots to `eos login:`
  with 0 exceptions** (verified headless on macOS/M4). **One isolated item remains:** a
  `virtio-rngd`-specific userspace deadlock (our optional R-402 driver) — with a
  `virtio-rng` device attached the boot freezes post-seed at ~5% CPU (timer alive, all
  userspace blocked); the *same image* with no `virtio-rng` device reaches login cleanly,
  so it is a `virtio-rngd`/July-runtime interaction, not the INTx path. `main` stays on
  the validated June forks + pins. Details: `docs/known-issues.md`.
- `[U-033]` **Fork rebase onto July upstream — executed in full, root cause of U-030
  confirmed, promotion blocked on a virtio-INTx deadlock.** All **four** code forks
  were rebased onto current mainline via a full `git rebase --onto` carrying the
  **complete** E-OS delta (not just the `upstream/` patch subset) and pushed to
  `eos-{kernel,base,relibc,userutils}` branch `eos-july` (kernel `cb14af3b`/8 commits,
  base `3e10b86f`/13, relibc `963b8f91`/1, userutils `260d772`/4). The exercise
  **confirmed U-030's root cause is relibc ABI drift** (`undefined reference to
  redox_fcntl_v0` when the July userland links against the June sysroot) and surfaced
  three rebase lessons the earlier patch-only attempt hid: a fork carries more than its
  `upstream/` patches (dropping R-402 virtio-core INTx made `virtio-netd` panic on
  `enable_msix unimplemented!()`); all code forks must move together (June userutils vs
  July relibc made `sudo` panic `Function not implemented`); the toolchain **sysroot
  relibc must be rebuilt** and **`Cargo.lock` regenerated** (else `driver-graphics`
  fails on two `redox_syscall` versions). The fully-rebased image **builds, links, and
  boots with 0 unhandled exceptions** (all drivers init: nvmed INTx, `virtio-net` MAC,
  `virtio-rng` seed) — but then **deadlocks**: after `virtio-rng` seeds, all CPUs go to
  WFI (QEMU 0% CPU) waiting on the shared `virtio-rng`/`virtio-netd` **INTx** line, and
  never reach the greeter. **`main` stays on the validated June forks + pins** (greeter,
  0 exceptions); the rebase is complete on the `eos-july` branches, blocked on the
  shared-INTx deadlock (kernel/driver debugging needed — the shared-INTx patch
  `kernel/0002` is implicated). Details: `docs/known-issues.md`.
- `[U-030]` **Upstream-drift boot blocker: unpinned `redoxfs` (0.9.1, July HEAD)
  aborted every aarch64 boot against the June-pinned forks — root-caused by
  disasm, fixed by pinning to the SBOM-validated rev.** The initfs `redoxfs`
  (PID 17) died deterministically at relibc start (`brk #1`, EC=0x3C) before
  mounting root, under TCG `cortex-a72` **and** HVF/M4, `-smp 1` **and** `4`.
  Disassembly at the fault ELR showed the shared abort landing pad: `verify()`
  **passed** (`X0=0` — R-401e works), the abort came from a later TCB/TLS-setup
  NULL check (`cbz x9`, `X9=0`, `X8=0x0000800000000000`). Pinning
  `recipes/core/redoxfs` to `af493b9f` (the 0.1.0 SBOM rev) makes the same build
  boot to `eos login:`. Deeper TLS-layout interaction deferred to the planned
  fork rebase; `orbital` (same drift class) logged one non-blocking exception
  headless and is a watch item. Details: `docs/known-issues.md`. *(First E-OS
  image built AND boot-verified on macOS/Apple Silicon — Podman VM build,
  QEMU TCG boot.)*
- `[U-029]` **Fresh-clone builds silently shipped UPSTREAM binaries for all six
  pinned forks — found by the first macOS build, fixed in CI + docs.** Under
  `REPO_BINARY=1` the cook resolver compares local `source_info.toml` with the
  packaged state; on a fresh clone the pinned-source recipes were never fetched,
  so there is nothing to compare and the resolver silently takes the upstream
  binary — the built image had `eos login:`=0, `E-OS Bootloader`=0,
  `redox login:`=1 and **no R-401\*/R-402a fixes** (an aarch64 image that may not
  boot; `make f.<pkg>` alone doesn't help — with `--repo-binary` it reports
  `cached` without fetching source). This also invalidated the CI image guarantee:
  `build.yml` forced only the three branding forks (`scr.bootloader/userutils/orbdata`),
  so CI images shipped upstream kernel/base/relibc. **Fixed:** `build.yml` now
  forces all six (`scr.kernel scr.base scr.relibc scr.bootloader scr.userutils
  scr.orbdata`) and gained a verification step comparing each package's
  `source_identifier` in `repo/<target>/<pkg>.toml` against the pinned fork rev;
  the trap + both fixes documented in `docs/build-troubleshooting.md`. *(The 0.1.0
  release-image builds were done on the dev rig with sources fetched, so they were
  not affected; the risk was fresh clones and CI.)*
- `[U-028]` **`R-1003` — public package-repo hosting infrastructure.** Per-arch
  GitHub Pages hosting repos created with Pages enabled
  ([`eos-pkg-x86_64`](https://github.com/Gh0s777tt/eos-pkg-x86_64),
  [`eos-pkg-aarch64`](https://github.com/Gh0s777tt/eos-pkg-aarch64)) — Pages was
  chosen because the `pkg` client requires the nested `<base>/<target>/<pkg>.pkgar`
  layout that flat release assets cannot serve. New publisher
  `scripts/publish-repo-pages.sh`: stages `pkg/<target>/` + the public signing key,
  rejects >100 MB blobs (GitHub's limit) up front, and force-pushes one orphan
  commit per publish so the hosting repos never accumulate history. Stable URLs:
  `https://gh0s777tt.github.io/eos-pkg-<arch>/pkg`. `docs/packages.md` updated;
  `/etc/pkg.d/50_eos` is deliberately not pre-wired into images until the repo is
  populated (a dead repo URL would degrade `pkg`).
- `[U-027]` **`R-206` — `eos` meta-package + first-boot welcome (BOOT-VERIFIED
  2026-07-10** — aarch64 QEMU serial session: `eos login:` → `eos-welcome` prints
  the full quick start; `uname -a` reports the fork kernel `6ee1f796`; `whoami`
  runs clean — **the first E-OS image built and verified entirely on
  macOS/Apple Silicon).** New source-less recipe `recipes/other/eos` (the `myfiles`
  pattern) ships `/usr/bin/eos-welcome` — an ion-compatible quick-start command
  (getting around, install-to-disk with encryption, accounts, docs links) — plus
  `/usr/share/eos/eos-release`. Registered as `eos = {}` in both
  `config/x86_64/eos.toml` and `config/aarch64/eos.toml`; the configs also add
  `/home/user/Welcome.txt` (the proven `demo.toml` pattern, visible in COSMIC Files)
  and extend `/etc/motd` (printed by `login`) with a pointer to `eos-welcome`.
- `[U-022]` **`docs/build-troubleshooting.md`** — fix for the `make CONFIG_NAME=eos all`
  "Package `ncursesw` not found" failure (cook `r.terminfo` + deps first; `terminfo` has
  no `source_info.toml` under `REPO_BINARY`, so the resolver marks it and its dependent
  `ncursesw` outdated and never publishes them), plus the headless-QEMU smoke-test recipe.

### Changed
- `[U-003]` Documentation expanded under `docs/` (architecture, building, security, FAQ).
- `[U-014]` `core/kernel` + `core/base` recipes now build from the E-OS forks (pinned
  by commit) instead of tracking upstream HEAD. `docs/known-issues.md` rewritten
  (R-401b/c/d **resolved**, with the true root cause and the aarch64 QEMU command);
  `ROADMAP.md` `R-401b` → ✅.
- `[U-026]` The three branding recipes (`core/bootloader`, `core/userutils`,
  `gui/orbdata`) are now **rev-pinned** to their fork heads like kernel/base/relibc —
  previously they tracked a branch, so a push to a fork could silently change the build.

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
  `@ 0d30e9ea`, one clean commit over upstream `bcc1a0d4`, `core/relibc` re-pinned): explicit
  per-arch offset conventions — x86/x86_64 keep the backwards layout but with **alignment-correct
  placement** and a correctly signed TLSDESC; aarch64/riscv64 use forward, `p_align`-aligned
  start-based offsets with the aarch64 TCB bias in TLSDESC/TPOFF, and the dynamic resolver
  subtracts TP. **Verified**: the ion job repro goes **5/5 → 0 (aarch64)** and **3/3 → 0
  (x86_64)**; full production boots on both arches stay clean. Upstream has no fix for this
  (checked `master`); upstream-ready patch in `upstream/relibc/0001-*`. The patch also adds a
  **regression test** (`tests/pthread/tls_initexit.c`, registered in the relibc suite) that
  exercises both failure modes — thread-local `.tdata` initializers read by spawned threads,
  and a clean thread exit (the cleanup-stack/destructor walks over the TLS block) — so this
  can never silently come back. Upstream bug-fix patch count is now **4 kernel + 2 base + 1
  relibc**.
- `[U-023]` **e1000e — the default `q35` NIC — now binds.** QEMU's `q35` default NIC is
  the Intel 82574L (`8086:10d3`); the stock `e1000d` PCI map omitted it, so default-q35
  networking bound no driver. `e1000d` is register-compatible with the 82574L, so a
  `/usr/lib/pcid.d/e1000e.toml` overlay (`config/x86_64/eos.toml`) makes it bind and
  initialise the card — verified end-to-end on the built eos image (`qemu -device e1000e`).
- `[U-024]` **Restored license files.** `LICENSE` (AGPL-3.0) + `licenses/Redox-OS-MIT.txt`
  on the meta repo and `LICENSE` (MIT) on the six `eos-*` forks had been removed; restored
  from git history so AGPL-3.0 distribution and Redox's MIT attribution are intact again.
- `[U-025]` **License restore completed on non-default branches.** `[U-024]` only covered
  the default branches; `LICENSE` was still missing on `lts/0.1`, `eos-base`,
  `archive/redox-0.4.1` and `archive/redox-mirror-2019` (meta repo, both remotes) and on
  `eos-relibc` branch `eos-tls` (the branch the `core/relibc` recipe pins). Restored on
  all of them (cherry-pick of `48ec6293` / reverts of the "Delete LICENSE" commits).

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
