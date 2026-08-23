# Changelog

All notable changes to E-OS, following [Keep a Changelog](https://keepachangelog.com)
and [Semantic Versioning](https://semver.org). Every change is numbered `[U-NNN]`.
History before `U-071` predates this file. Most of it is traceable in `git log` on
`main`, but **under `R-NNN` roadmap codes, not `U-NNN` labels** — ten of the numbers
(`U-001`–`U-006`, `U-008`, `U-012`–`U-014`) appear nowhere in `main`'s history at all.
The numbered entries themselves survive on the archived pre-migration branch:
`git show origin/archive/pre-migration-de-phase1:CHANGELOG.md`. That branch is a
**disjoint history**, not an ancestor of `main`, so a citation like "CHANGELOG `U-012`"
resolves only there — it is a real record, not a fabricated one (`U-131`).

## [Unreleased]

### Added & Changed
- `[U-162]` **`R-F19` halved: the filesystem is created, the failure is in populating it** — instead of reasoning about Redox's capability model, the target disk was **kept after a failing run and inspected**. It holds **2** GPT tables, **1** `BOOTAA64.EFI` in the ESP, and **11** `RedoxFS` signatures. So `FileSystem::create` **succeeds** — the partition table, the EFI loader and the filesystem header are all written — and `Operation not permitted` comes from the callback that runs *after* creation: the mount and the file copy into the new filesystem (`with_redoxfs_mount` → `decide_mount_path` registers a scheme named `file.redox_installer_<pid>` on Redox). **Two candidates ruled out by reading rather than guessing:** `try_fast_install` returns `Ok(false)` when `DISK_LIVE_ADDR`/`DISK_LIVE_SIZE` are unset, so the live-disk mmap path is not involved on a non-live install; and `/etc/login_schemes.toml` grants `[user_schemes.root] schemes = ["*"]`, so the session's scheme allowlist is not the constraint either — which also explains why root and `sudo` fail identically (`U-161`). **Operationally recorded (§9):** the podman sparsebundle detached **three times** in this session, and the script alone does not recover it — the reliable sequence is `hdiutil detach -force` on every attachment, re-attach with `-nomount`, then `diskutil mount`, then stop and start the machine. The caches survived every time; nothing went near `--wipe-caches`.
- `[U-161]` **`R-601` drives the installer end to end for the first time — and reaches a real blocker, `R-F19`** — plus a recorded claim that turned out to be false. **The serial-input claim was wrong.** `config/aarch64/eos.toml`, the `R-601` roadmap entry and this harness's own earlier header all said QEMU's macOS unix-socket serial delivers no input to the guest (*0 RX interrupts*). Measured: typing `user` at the login prompt echoes back **character by character**. Almost certainly fixed by `U-153` — the read-modify-write on `GICD_ICENABLER` masked every enabled IRQ in a 32-line block, and the UART shared that block with the storage line. **Both of `R-601`'s blockers had one cause.** With input working, the whole flow drives over serial: login → the `R-602` first-boot password enrolment → shell → `redox_installer_tui` → drive menu → install. **The binary is `redox_installer_tui`, not `installer_tui`** — the name this harness used before, which the image answers with `ion: command not found`. **Where it stops:** the installer writes the protective MBR, the GPT, formats the ESP and writes `EFI/BOOT/BOOTAA64.EFI` (0x2f600 bytes) — then `Installing to RedoxFS partition with size 0xffcffe00` → **`failed to install: Operation not permitted (os error 1)`**. Recorded as **`R-F19`**. **A correction to my own reading of it:** an intermediate note here claimed `sudo` was at fault because a root run appeared to get further. That run was killed too early — root fails at **exactly the same step**, so privilege escalation is not the difference. **Three harness defects fixed on the way, and two of them were mine:** `expect()` searched the whole accumulated buffer, so *"the shell prompt came back"* matched a prompt printed **before** the install began, returned instantly, and the VM was killed mid-write — a check that could not fail (CLAUDE.md §4.1); and the RedoxFS password prompt is **invisible on serial** (it echoes nothing), so waiting for it always timed out — the first version only appeared to work because the broken `expect` matched a stale `[sudo] password` and sent the empty line by accident. One defect was masking the other. `expect()` now matches only output produced **after** a mark, the empty password is sent deliberately, and progress is asserted on markers the installer actually prints (`Opening disk`, `BOOTAA64.EFI`). **Stage 2 is the judge:** the harness boots the *installed* disk on its own and demands a login prompt — today it gets a UEFI `Shell>`, which is the correct answer for a filesystem that was never populated. **`R-601` stays 🚧**: partition → install → reboot → login is **still unproven**, and the remaining gap is `R-F19`, not the harness.
- `[U-160]` **CLAUDE.md gains the testing, auditing and record-keeping discipline this session kept learning the hard way** — §4 was three gates and nothing about whether the gates work. It is now *"test it, prove the test, audit the claim"* with five subsections, each grounded in a numbered entry rather than in advice: **§4.1 a test you have not seen fail is not a test** (the `gitleaks` hook that ended in `|| true`, `U-140`; the bash-4 gate that matched its own regex literal; the negative control that proved nothing because `git grep` only sees *tracked* files, `U-159`); **§4.2 prove the instrument before trusting a negative result** (three attempts spent measuring a `redoxfs` binary that never ran, because the `base` recipe copies it into `initfs/bin/` — settled by an unconditional `panic!` that the boot survived, `U-151`/`U-153`; plus the experiment invalidated by moving a QEMU `-device` and silently changing its PCI slot, `U-157`); **§4.3 measure, do not infer** (the block point read off *where the log stopped* was published wrong twice before `init`'s own narration and `/scheme/sys/irq` counters settled it); **§4.4 a change that measures nothing does not ship** (the kernel interrupt-model change reverted at 111s before / 111s after, `U-157`); **§4.5 audit — a claim without current evidence is a defect** (§10.1 sat stale claiming signing was unconfigured while every commit was in fact signed, `U-152`), including *record the dead ends too*. §2 gains four rules for writing a record someone else can check: cite the evidence inline, **scope the claim to what was measured** (`U-146`'s "two INTx lines cannot both work" needed narrowing twice), say what you did **not** verify, and correct in place leaving the correction visible. §1's Definition of Done now requires the negative control alongside the runtime proof. **Deliberately not renumbered:** folding that into item 3 rather than adding a new item 4 keeps `§1.6` meaning *Pinned & pushed* — several historical entries cite it, and renumbering would have silently invalidated them, or forced rewriting a historical record to match my edit. That is precisely what §2's fourth rule forbids.
- `[U-159]` **`R-F14` and `R-F15` closed — and the first run of each found a real defect** — step 8 of `docs/plan.md`. **Shell linting (`R-F14`).** 46 tracked scripts had never been linted. The first shellcheck run reported **188 findings**, splitting cleanly: **47 in `scripts/`** (E-OS-owned) and **141 in inherited code** (`build.sh`, the `*_bootstrap.sh`, `recipes/wip/`, `upstream/`) — so the gate scopes to `scripts/`, the same call `ci-integrity.sh` check 4 makes for the vendored `src/`. **Three errors, all real, all the same shape:** unquoted `$@` in `backtrace.sh`, unquoted `$*` in `pkg-size.sh`, and `"${CONFIGS[@]}"` interpolated into a string in `ventoy.sh` (which silently prints only the first element). **Not theoretical here:** this tree lives under `/Volumes/Project itp/…` — a path with a space — so an unquoted expansion splits a real argument on the very host the work is done on. Six warnings fixed too, the sharpest being `cd` without `|| exit` in **`ci-integrity.sh` itself**: a failed `cd` left the *gate* linting whatever directory it happened to be in and reporting PASS on the wrong tree. **A bash-4 gate, because this has cost time twice:** `scripts/check-ci-config.sh` used `declare -A` and simply did not run on the dev host's `/bin/bash` 3.2 (`eos-check.sh` had the same problem with `${ARCH^^}`, fixed in `U-124`). Rewritten as an explicit set difference, which reads better than the map-blanking it replaced, and `ci-integrity.sh` gained **check 5** to keep it that way — comment lines ignored, and the gate file excluded from its own scan because it necessarily contains the patterns it hunts. **Negative-controlled:** a planted `declare -A` fails the gate, removing it passes. The first attempt at that control was itself invalid — `git grep` only sees *tracked* files, so an untracked probe proved nothing until it was `git add -N`'d. **Rust checks on the root manifest (`R-F15`).** `rust-checks` only ever covered `tools/eos-repo-sign`; the vendored `redox_cookbook` that builds every image was never tested or audited. Its **9 unit tests pass** and now run in CI. `cargo-deny check advisories` **failed on first run**: **RUSTSEC-2026-0204**, an invalid pointer dereference in `crossbeam-epoch 0.9.18`, reached via `ignore`/`rayon-core` → `blake3` → `pkgar`. Fixed by `cargo update -p crossbeam-epoch` → **0.9.20**; advisories now clean and the 9 tests still pass. Licences and sources are deliberately **not** gated — those are upstream's choices, and gating them would re-litigate a vendored tree rather than protect this one. **Both new checks are blocking, not `|| true`** — the gitleaks lesson from `U-140` — with shellcheck *warnings* printed as advisory until the remaining 18 are driven down deliberately.
- `[U-158]` **`eos-setup-mirrors.sh` would have destroyed the published package repos, and could not be audited without a credential — both fixed; `--apply` remains a human action** — step 7 of `docs/plan.md`. **Measured first:** of the 30 repos in `repos.toml`, exactly **one** — the meta repo — has a push mirror. All **29 forks** have none, which is why every fork change this session needed a manual double push. **The mandatory exception was missing.** The plan states the `eos-pkg-*` exclusion is *mandatory or the mirror overwrites what step 3 published*; the script had no such exclusion, so `--apply` would have pointed a GitLab→GitHub push mirror at both published package repositories and overwritten them. Now skipped explicitly by `role = "pkg"`, with the reason in the code. **The dry run could not run at all.** `GITHUB_MIRROR_PAT` was required before anything happened, so the only way to see which repos are unmirrored needed a credential — backwards, since reading state should never need a secret. The check now guards only the apply path, and the credential-bearing URL is assembled **only** inside that branch: under `set -u` merely referencing the PAT aborted the dry run, and there is no reason to build a secret URL when nothing will be created. **The summary line lied.** `${APPLY:+applied }` expands whenever `APPLY` is set *at all*, including to `0`, so a dry run reported `applied created=27` for a run that created nothing. It now says `dry run: would create=…`. **Verified:** `scripts/eos-setup-mirrors.sh` with no token in the environment completes and reports **would create=27, skipped=3** (meta already mirrored, two `pkg` repos excluded). **`--apply` is deliberately not run here:** it needs a GitHub PAT, and CLAUDE.md §5 forbids handling pasted tokens outright. That step belongs to the operator; everything up to it is now safe to run and honest about what it would do.
- `[U-157]` **`R-F18`: the storming line identified by counter, and a kernel fix I wrote, tested and then **reverted** because it did nothing** — the guessing stops here. A throwaway init service dumping `/scheme/sys/irq` (kernel `COUNTS`, one line per virq) puts the number on the record: with the second NVMe at slot `0x6`, **`virq 37` reaches 11 054 068** interrupts by the time the system is up, against **8 851** for the generic timer and **4 557** for the boot disk. `virq 37` is GSI 37 / GIC SPI 5 — exactly the line the xHCI controller and that disk share. **Both drivers really do hold a handle on it:** `xhcid` calls `irq.irq_handle("xhcid")` with `InterruptMethod::Intx` (`drivers/usb/xhcid/src/main.rs:99`), so this is a genuine two-handle shared line, not a one-sided registration. **The fix I tried, and why it is not being shipped:** unmask only once *every* handle on the line has acked the current count — the standard treatment for shared level-triggered interrupts, and strictly more correct than unmasking on the first ack. Built, put in the image (verified: the patched kernel was the one that booted), measured: **111s before, 111s after** — *identical*, and the storm was unchanged. It does not help because both drivers **do** ack promptly; the line is then unmasked while the xHCI device is still asserting, because its condition has not been cleared at the device level yet. Since the change bought nothing measurable and carries a real cost — a driver that dies on a shared line would now wedge that line permanently instead of storming — it was **reverted**. An unproven behavioural change to the kernel interrupt path is not something to ship on the strength of it sounding right. **Where the fix actually belongs, for whoever takes it:** the xHCI side. `xhcid` runs a separate `IrqReactor` thread (`xhci::start_irq_reactor`); it must clear the controller's interrupt-pending status (`IMAN.IP` / `USBSTS.EINT`) **before** acking the kernel handle, otherwise the level is still asserted the moment the line is unmasked, whichever handle unmasks it. **A methodological note worth more than the finding:** one intermediate experiment here was invalid — moving `-device qemu-xhci` to the end of the QEMU command line changed its PCI slot, so it stopped sharing the line and the run 'passed' for the wrong reason. It did yield a clean control though: with xHCI *not* sharing, the same image boots in **19s** with **11** interrupts on that virq instead of 11 million.
- `[U-156]` **`R-F10` closed: the bootloader now unlocks the filesystem it was actually built against** — `eos-redoxfs` `b0f6dff6` → **`555359ef61`**, `eos-bootloader` `05dadec4` → **`b249982f29`**. The bootloader is the code that unlocks an encrypted root and loads the kernel; it declared `redoxfs = "0.8"` with no `[patch.crates-io]`, so Cargo resolved **redoxfs 0.8.0 from crates.io** while the image's filesystem is created and maintained by the pinned fork — two codebases for one on-disk format inside the TCB, not even sharing an AES path (the fork carries `--cfg aes_armv8`, `R-502`). **This was not a configuration oversight, which is presumably why it stayed open, and it had three layers, each hiding the next.** (1) `[patch.crates-io]` cannot express it: the fork is `0.9.x` against a `0.8` requirement and Cargo refuses to patch across incompatible versions, so the dependency is now pinned by `git+rev` to the same revision `recipes/core/redoxfs` uses. (2) The fork **would not build without `std`** — three `E0425 cannot find type Vec`, because `record.rs` and `filesystem.rs` imported `alloc::vec` (the module) but not `Vec` (the type); in a `std` build the prelude supplies it, so this compiled for years unnoticed, and the bootloader consumes the crate with `default-features = false`. That is the real reason the split existed. (3) With both crates in one graph, **`redox_syscall` appeared twice** — `0.5.18` for the bootloader, `0.9.3` for redoxfs — so `syscall::Error` was two distinct types and every `Disk` trait method mismatched. **Measured before deciding:** the bootloader's syscall surface is 8 files and 16 references (`Result`, `Error::new`, `ENOKEY`, `ENOENT`, `io::Pio`), and 0.9 still re-exports all of them from the crate root — unifying on `redox_syscall = "0.9"` changed **no call site**. **Verified from the bumped pins, not from a local patch:** the build tree re-fetched both revisions clean, `Cargo.lock` records `source = "git+https://github.com/Gh0s777tt/eos-redoxfs.git?rev=555359ef…"` instead of `registry+…crates.io-index`, the image rebuilt, and **`scripts/ci-boot-smoke.sh` PASS** — which is the check that matters here, since the changed component is the one that has to boot. Both forks were pushed to **both** hosts and each verified with `git ls-remote` before its pin was bumped; `pins ok=26 drift=0`.
- `[U-155]` **`R-F18` measured to the root: a shared-INTx interrupt storm, and my `U-154` hypothesis was wrong** — `U-154` guessed that `usbhidd` was slow to signal readiness and that the blocking chain `usbhidd` → `xhcid` → `pcid-spawner` → `init` stalled the boot. **It is nothing to do with USB readiness.** Rebuilding with `init`'s own `log_debug` on shows the 79–80s gap sits between two lines of an `init` script step:

  ```
  init: running: Command { cmd: "rm",    args: ["-rf", "/tmp"] }
  … 80 s …
  init: running: Command { cmd: "mkdir", args: ["-m", "a=rwxt", "/tmp"] }
  ```

  A single filesystem operation on the **boot disk** — which sits on its *own* INTx line — is what slows down. `usbhidd`'s warning was only the last line printed before the silence, and it fires in every boot because it decodes the `sendkey ret` the harness sends to dismiss the bootloader menu. **Measured across three configurations with the same image:** no second disk → `rm -rf /tmp` takes **1s**, login at 15s; second disk on `0x5` (virtio-net's line) → **1s**, login at 17s; second disk on `0x6` (**the xHCI controller's line**) → **80s**, login at 122s. **Cause confirmed by counting, not by reasoning:** QEMU `-d int` over an identical 45s window records **780 909** exceptions with no second disk, **820 745** on `0x5`, and **3 654 574** on `0x6` — **4.5×**. That is an interrupt storm, and it starves unrelated work, including boot-disk I/O. **The mechanism it points at** (stated as the reading of that data, not as a separate measurement): a legacy INTx line is level-triggered and shared. `irq_trigger` notifies **every** handle registered on it, so an xHCI interrupt also wakes the storage driver, which finds nothing to do, acks, and **unmasks a line the xHCI device is still asserting** — so it re-fires immediately, over and over, until the driver that actually owns the condition services it. A driver with nothing to do should not unmask a level line another device is still driving; a correct fix keeps the line masked until every handle has acked, or lets a driver answer *not mine*. Not attempted here — it is a kernel interrupt-model change, not a one-liner. **Unchanged:** `R-F16` stays fixed (10/10), and `R-F18` remains a degradation rather than a stall — the boot completes. All diagnostic patches lived only in the container build tree and are reverted; `base` and `kernel` are clean at their pinned revisions.
- `[U-154]` **`R-F18` located to the second: an 84-second stall inside USB HID bring-up** — no rebuild needed for this one. The in-log timestamps only cover driver lines, and the biggest gap there was 5.8s, so the missing ~100s was elsewhere; polling the serial log by **wall clock** during the boot found it exactly. On the slow configuration (second NVMe at slot `0x6`, sharing GIC SPI 5 with the xHCI controller at `00:02.0`) the boot advances normally to **23s**, then stops dead for **84 seconds** between two lines:

  ```
  [@usbhidd:138 WARN] unknown usage_page 0x7 usage 0x0
  … 84 s of nothing …
  caudiod: No such device
  ```

  **The line sequence is byte-identical to a fast boot** — same warning, same next line, nothing extra in between — so this is a pure timing difference, not a different code path. **The warning is not the cause:** it appears in *every* boot examined, fast ones included (`usage_page 0x7` is the HID Keyboard/Keypad page); it is merely the last thing printed before the silence. Total to login: **116s**, against **16s** when the second disk shares a line with `virtio-net` or `virtio-rng` instead. **Hypothesis, explicitly not yet verified:** `usbhidd` is spawned as a subdriver by `xhcid` and signals readiness only after its interrupt-IN transfer is set up, which needs an xHCI interrupt; sharing the line with a storage device delays that, and the per-device blocking readiness chain (`usbhidd` → `xhcid` → `pcid-spawner` → `init`) turns one driver's delay into a whole-boot stall. That is the same structural fragility this session already met twice, and it is stated as a hypothesis because nothing here measures it — confirming it needs `xhcid`/`usbhidd` instrumented, remembering that the initfs copy arrives via the `base` recipe (`U-153`). **Unchanged and still true:** the boot completes, so `R-F18` is a degradation rather than a stall, and `R-F16` stays fixed at 10/10.
- `[U-153]` **`R-F16` root-caused and fixed — the bug was a read-modify-write on a write-one-to-clear GIC register** — `eos-kernel` `9687852732` → **`18dce5577d`**. `GICD_ISENABLER`/`GICD_ICENABLER` are *write-one-to-set* and *write-one-to-clear*: a written 1 acts on that IRQ, a written 0 does nothing, and a read returns the current enable mask for the 32 IRQs in that block. `irq_disable()` read that mask, OR-ed in the target bit and wrote it back — writing a 1 to **every enabled bit in the block**, i.e. disabling all of them. Two PCI devices on different INTx lines land on adjacent SPIs (SPI 3 and SPI 4, both block 1), so masking the second device's line while servicing its interrupt also masked the **boot disk's** line — and nothing ever re-enabled it, because that driver was not in an interrupt cycle. The root read never completed, `redoxfs` blocked, and the boot died in initfs with no panic and no error. The identical shape in `irq_enable()` is harmless (re-setting set bits is a no-op), which is why this only ever surfaced as an unexplained hang. Fix: write the single bit, no read, no merge — covering GICv2 **and** GICv3, since `gicv3.rs` delegates to the same `GicDistIf`. **Verified against the image built from the bumped pin** (kernel source at `18dce5577d`, tree clean, the RMW pattern absent): `scripts/repro-intx-lines.sh` reports **10/10 boot**, `scripts/ci-boot-smoke.sh` PASS, `pins ok=26 drift=0`. Fork pushed to **both** hosts and verified with `git ls-remote` before the bump. **`U-151` was wrong and is corrected here.** It concluded that `redoxfs` cannot be instrumented through stdout/stderr. The real cause was a **stale binary**: the `base` recipe lists `redoxfs` as a dependency and copies it into `initfs/bin/`, so rebuilding `r.redoxfs` alone leaves the initfs carrying the **old** binary. Proven by putting an unconditional `panic!` on the first line of `redoxfs`'s `main()` — and the boot still reached a login prompt, which is impossible if that binary is the one running. Measured: the fresh package had the probe markers, `initfs/bin/redoxfs` had none and was hours older. After adding `r.base`, **all three** channels worked immediately (`/scheme/log`, `stdout`, `panic!`). Bisecting then pointed straight at the cause: `redoxfs` blocked on its **first read of the boot disk**, not the second one — exactly what a wrongly masked line produces. **New finding, `R-F18`:** verifying the fix surfaced a separate defect. Adding a *time-to-login* column to the guard shows a second NVMe sharing a line with virtio-net or virtio-rng boots in **16s**, with the boot disk **30s**, but with the **xHCI controller** **110–124s** — reproducible to within seconds, which looks like a **fixed timeout being waited out** rather than contention. The boot completes, so it is a degradation, not a stall. **The guard was improved rather than silenced:** it now polls instead of sleeping its whole budget (so a fast row costs only its real time), prints the elapsed seconds, keeps the serial log of any failing row (it used to delete every log, so a `FAIL` said *something broke* and never *what*), and defaults to 180s. That timing column is what found `R-F18` — raising the timeout alone would have turned the row green and hidden it. Note the default was **75s**, not the 110s I claimed in `U-150`; that edit never matched its pattern and silently did nothing.
- `[U-152]` **signing was already live and the docs said otherwise; the tag gap was structural; and a tag would have hung CI** — three findings from re-measuring instead of trusting the notes. **(1) `CLAUDE.md` §10.1 was stale.** It stated `commit.gpgsign`/`tag.gpgsign`/`user.signingkey` all unset, 0 keys, 0/20 commits signed. Measured today: SSH signing is configured, `allowed_signers` is set, **every commit since `1d3c62ea6` verifies `G`**, and GitLab's signature API returns `verification_status: verified` under the key *"Ghost Empire / E-Bot"*. Section rewritten against the measurement, including two things worth knowing rather than guessing: the key file is named `magazyn-wms-signing` (another project's key, reused — a naming wart, not a defect), and the **GitHub mirror is unconfirmed** because the `gh` token lacks `admin:ssh_signing_key`. **(2) The DCO line in §5 overstated the contract.** It read "DCO sign-off", implying a `Signed-off-by:` trailer. `CONTRIBUTING.md` requires no such trailer — its DCO section states *terms accepted by contributing* and asks for a cryptographic **signature** (`git commit -S`), which is exactly what is now happening. The contract was never being violated; the summary of it was wrong. **(3) The tags could never have been signed.** `v0.1.0` and `eos-base-2026-06-06` are **lightweight** tags — `git cat-file -t` reports `commit`, not `tag` — so they carry no annotation and no signature is possible; `-s` would not have helped. Resolved by **superseding, not rewriting**: `v0.1.0` stays as history (rewriting a published tag is worse than replacing it) and **`v0.2.0`** is cut annotated and signed at `main`, 232 commits on. It marks a **development milestone, not a published release** — no images are published and `R-F16` is open — and README now says exactly that, including the two-PCI-storage-controller boot limitation. **(4) A tag would have produced a pipeline that never finishes.** `docs-pdf` and `build-image` ran automatically on `$CI_COMMIT_TAG` but require the self-hosted `eos-heavy` runner, and **no self-hosted runner is attached to the project** — so both would sit `pending` forever (`allow_failure` does not rescue a job that is never picked up). Both tag rules are now `when: manual` + `allow_failure`, matching what `build-image-x86_64` already did. **Left alone deliberately, and flagged:** the *scheduled* path stays automatic, so the active **nightly heavy build** hangs the same way every night until a runner is attached — changing an active schedule's behaviour is an operator decision, not a doc fix. **Measured while pushing the tag, and now recorded in §7:** the push-mirror replicates a **branch within seconds** but a **tag only on its next run — ~5 minutes** here (`main` was mirrored immediately, `v0.2.0` appeared on the mirror at the following sync). Two minutes of silence is not a broken mirror. **Tag pipeline verified after the fix:** three light gates `success`, three heavy jobs `manual` — nothing pending, the pipeline completes. The tag itself verifies: `git cat-file -t v0.2.0` → `tag`, `git tag -v` → *Good "git" signature … ED25519*.
- `[U-151]` **a dead end on `R-F16`, recorded so the next attempt does not repeat it: `redoxfs` cannot be instrumented through stdout or stderr** — following `U-150`, the obvious next step was to make `redoxfs` narrate its disk scan. Two channels were tried as local build-tree patches, both **reverted**, and neither works: (1) writing directly to `/scheme/debug`, and (2) plain `eprintln!` — which *should* reach the console, because `init` switches its own stdio to `/scheme/log` and spawned services inherit it. **The control is what makes this conclusive:** a probe on the very first line of `redoxfs`'s `main()` produced **no output in a boot that succeeded** — so `redoxfs` unquestionably ran and mounted the root, and the channel is dead rather than the code path unreached. **An intermediate hypothesis of mine, disproved along the way:** I suspected the initfs carried a *separate, unpatched* copy of `redoxfs`; the image contains **exactly one** `redoxfs` binary (`strings` finds the usage string, the password string and my probe marker once each) and it is the patched one. **A clarification this forces on `U-150`'s wording:** `redoxfs` is silent *by construction* in the initfs phase — its own diagnostics are `log::debug!` and nothing installs a logger there — so its silence carries **no information** about how far it got. "The stall is inside `redoxfs`" still stands, because that comes from `init`'s trace (`Starting Rootfs (redoxfs)` and no completion), not from `redoxfs`'s own silence. **The channel that demonstrably does work, for whoever picks this up:** a **panic** reaches the serial console — `nvmed`'s assertion failure was visible that way in `U-148` — so bisecting `redoxfs` with deliberate `panic!` markers is the method that will actually yield data. No repository code changed here; the build tree is clean at the pinned revisions and the rebuilt image passes `scripts/ci-boot-smoke.sh`.
- `[U-150]` **`R-F16` located exactly, by making `init` say where it is — and a second-disk attachment that simply works** — `U-148` corrected the mechanism by *reasoning* about where `daemon.ready()` is called. This settles it by **measurement**: a diagnostic image with `init`'s own `log_debug` forced on (a local patch to `init/src/main.rs` in the build tree; the fork untouched, the patch reverted, a clean image rebuilt from the pinned rev and re-verified) narrates every unit, and the failing boot reads:

  ```
  Reached target Initfs drivers      <- 40_drivers.target completed; pcid-spawner finished
  Starting Rootfs (redoxfs)          <- 50_rootfs.service started
  (nothing, ever)
  ```

  So `pcid-spawner` really does finish — `U-146`/`U-147` were wrong about that and `U-148` was right — and the stall is **inside `redoxfs`**, which logs nothing at all. No inference left in that chain. **New control, and it narrows the defect further:** the same blank disk attached as **USB storage** instead of a PCI device **boots** — `Reached target Initfs drivers` → `Starting Rootfs` → `switchroot` → login. So `R-F16` is not "a second block device breaks the boot"; it needs a second **PCI function taking an INTx line**. **Practical consequence:** `scripts/ci-install-smoke.sh` now attaches the target disk over **USB by default** — the only attachment that avoids *both* known defects, since a USB disk takes no INTx line (`R-F16` cannot trigger) and cannot share one (`R-F17` cannot trigger) — with `EOS_TARGET_IF=nvme|virtio-blk` still available for reproducing them on purpose. It is also closer to how a real install happens. `scripts/repro-intx-lines.sh` gains the USB row as a control. **Still unknown, and still stated as such:** why `redoxfs` never completes when a second PCI storage device holds a different INTx line, given that both drivers' own interrupts demonstrably work. Next step is the same method one level down — make `redoxfs` narrate its disk scan. **Hygiene:** every diagnostic patch this hunt used (`drivers/common/src/logger.rs`, `init/src/main.rs`) lived only in the container build tree, never in the fork; both are reverted, the source tree is clean at the pinned `7d5ca7e28e`, and the rebuilt image passes `scripts/ci-boot-smoke.sh`.
- `[U-149]` **`R-F17` fixed: a kernel return value that is correct by design no longer kills the storage driver** — `eos-base` `66e3070b` → **`7d5ca7e28e`**. A legacy INTx line is *shared*: `irq_trigger` fans one interrupt out to **every** handle registered on it, which the kernel deliberately permits (`R-401d`). The line's counter can therefore advance between a driver's read of the ack value and its write of it, and the kernel answers that write with **`Ok(0)`** — *stale, not yours to unmask* (`kernel/src/scheme/irq.rs`: `if ack != current { return Ok(0) }`). `drivers/executor/src/lib.rs` asserted the write had consumed `size_of::<usize>()` bytes, so that entirely correct return value **aborted the driver**. On aarch64 — no MSI/MSI-X, every PCI driver on INTx — this killed `nvmed` mid-boot as soon as two devices shared a line, which is the ordinary case for a machine with more than one disk. **Why skipping is safe, not just quiet:** `COUNTS` is bumped *only* by `irq_trigger`, so a stale ack means a **newer** interrupt has already arrived — and it re-triggered this handle too, so the next `react()` acks the current count and re-enables the line. No unmask is lost; the case is self-healing. The `.unwrap()` on that write is gone as well: a daemon logs and carries on rather than turning a recoverable case into an abort (CLAUDE.md §3, the `U-085` virtio-core lesson). **Verified with a before/after negative control**, two NVMe disks sharing GIC SPI 3 (source at PCI slot `0x4`, target at `0x8`): *before* — reaches login, then `thread 'main' panicked at drivers/executor/src/lib.rs:191:17: assertion failed: amount == core::mem::size_of::<usize>()`; *after* — reaches login, **no panic**, and **zero** `irq ack` warnings, so the write returned only `0` or `size_of::<usize>()`, never a short count. **All three gates run against the image built from the bumped pin**, not from a local patch: the build tree re-fetched `7d5ca7e28e` from the GitHub mirror (`git rev-parse HEAD` in `recipes/core/base/source` confirms it, working tree clean, old `assert!` absent), `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` succeeded, `scripts/ci-boot-smoke.sh` PASS, `pins ok=26 drift=0`. Fork pushed to **both** hosts before the bump and verified with `git ls-remote` on each, per CLAUDE.md §1.6. **Deliberately not masked:** `R-F16` — the stall when the second disk sits on a *different* INTx line — is untouched and still reproduces exactly as before; `scripts/repro-intx-lines.sh` is unchanged and its rows are still valid.
- `[U-148]` **the `R-F16` mechanism I published twice was wrong — and chasing it properly turned up a second, concrete defect (`R-F17`)** — `U-146`/`U-147` both stated that the second storage driver *never signals readiness*, leaving `pcid-spawner` blocked in `Daemon::spawn`. **That is false.** Raising the driver console log level to `Debug` (a local patch to `drivers/common/src/logger.rs` in the build tree only — the fork was never touched, the patch is reverted and a clean image rebuilt) shows the second `nvmed` on a *different* INTx line reaching `Finished base initialization`, both `identify` completions, `Initialized!` and finally `Starting to listen for scheme events`. Those completions require interrupts, so **its interrupt path works**; and `daemon.ready()` is called unconditionally in `DiskScheme::new` (`driver-block/src/lib.rs:288`, right after `register_scheme_inner`) — i.e. *before* that last log line. So readiness **was** signalled and `pcid-spawner` was **not** the blocker. The stall is further down: `50_rootfs.service` (`redoxfs`, a `oneshot`) never completes, so `90_initfs.target` never completes and `init` never reaches `switch_root("/usr")`. `redoxfs` logs nothing at all, which is why the stall is silent. Confirmed by running the failing configuration for a full **three minutes**: exactly 225 log lines, no further output, ever. **Why the earlier conclusion was wrong:** I inferred the block point from *where the log stopped* instead of from where the code signals readiness, and the two are not the same place. **`R-F17`, found in the passing configuration and new:** when both disks share GIC SPI 3, the boot *does* reach `switchroot` — and then `nvmed` dies with `assertion failed: amount == core::mem::size_of::<usize>()` at `drivers/executor/src/lib.rs:191`. The kernel's irq scheme deliberately returns `Ok(0)` from `kwrite` when the acknowledged count is stale (`ack != current`, `kernel/src/scheme/irq.rs:451`), while the driver asserts the write consumed `size_of::<usize>()` bytes. Shared INTx makes a stale ack routine, because `irq_trigger` fans one line out to **every** handle registered on it (`R-401d` permits exactly that). A kernel return value that is by design becomes a driver abort. **Still unknown, and left open rather than guessed at a fourth time:** why `redoxfs` never completes when a second driver holds a *different* INTx line, given that both drivers' own interrupts demonstrably work. **Unchanged:** the nine-boot slot→line matrix and `scripts/repro-intx-lines.sh`; the symptom is exactly as reproducible as before. Docs, roadmap and both script headers corrected to describe the stall by its *observable* boundary — no switchroot, root never mounted — rather than by a mechanism I had not verified.
- `[U-147]` **correcting my own `R-F16` wording: the defect is narrower than I published** — `U-146` stated that *two PCI devices on different legacy INTx lines cannot both work*. That generalises past the evidence. Re-reading the passing boot log shows `init` performs **two** `switch_root` calls — first to `/scheme/initfs`, then to `/usr` — and only the *initfs* one brings up storage via `pcid-spawner --initfs`. **After** the second switchroot, `pcid-spawner` brings up `virtio-netd` (device 1 → line 1) and `xhcid` (device 2 → line 2) while the boot disk already holds line 0, and the boot goes on to a login prompt. So several INTx lines demonstrably coexist there. What the nine boots actually establish is narrower and still a P0: **a second storage driver in the initfs phase, on a line different from the first, never signals readiness, and `pcid-spawner` — a `oneshot` unit blocked in `Daemon::spawn` — stalls the boot before the root filesystem is mounted.** The slot-to-line mapping evidence is unchanged and still exact. **Left explicitly unresolved:** whether those post-switchroot drivers genuinely receive interrupts, or merely reach readiness without needing any — the logs cannot tell them apart, and `drivers/common/src/logger.rs` hardcodes the driver log level to `Info`, so the `debug!` lines that would settle it need an image rebuild. **Also ruled out along the way:** the ACPI `_PRT` routing is fine (`pcid: ACPI _PRT INTx routing resolved: 128 entries` appears in the stalling boot too), the kernel's `irq_xlate` is injective (SPI *n* → virq *n*+32), the irq scheme explicitly permits shared INTx opens (`R-401d`), and `set_reserved` does unmask the line — so none of those is the cause. `docs/hardware-bringup.md` and the `R-F16` roadmap entry now carry the corrected scope.
- `[U-146]` **a second disk silently stops the boot — a legacy-INTx defect found by the `R-601` harness (`R-F16`)** — building `scripts/ci-install-smoke.sh`, the missing install-to-second-disk proof, turned up something much worse than a missing test: **attaching a second disk stops the boot dead**, with no panic and no error, before the root filesystem is ever mounted. **Mechanism, traced end to end:** aarch64 has no MSI/MSI-X, so every PCI driver takes a legacy INTx line (the `R-401c` note in `nvmed` says so). A driver whose INTx line *differs from the line already in service* never receives an interrupt, so it never signals readiness; `pcid-spawner` blocks per device in `Daemon::spawn`, which is a bare `read_exact` on the child's `INIT_NOTIFY` pipe **with no timeout** (verified in `eos-base/daemon/src/lib.rs:78-99`): a child that neither signals readiness nor exits blocks the parent forever. `pcid-spawner` is wired as a `oneshot` unit, so `40_drivers.target` never completes, `50_rootfs.service` never runs, and `init` never reaches `switch_root("/usr")`. The serial log simply ends after the second driver prints its device. **How it was isolated:** a log diff against a one-disk boot showed the missing line was `init: switchroot to /usr /etc` (126 lines and a login prompt vs 93 lines and silence). **Nine boots, and the model predicts every one** — on `-machine virt` the INTx line is `(slot + pin) % 4` and the source disk at slot `0x4` is line 0, so a second disk at `0x5`/`0x6`/`0x7`/`0x9` (lines 1/2/3) stalls while `0x8`/`0xC` (line 0, *shared* with the source disk) **boots**; `0xC` and `0x9` were predicted in advance and both matched. **Two negative controls turn this from a pattern into a diagnosis:** a *lone* disk moved to line 1 boots fine, so no individual line is dead — it is two lines at once that fails; and a `virtio-blk` second device stalls identically, so it is not an `nvmed` bug but the shared INTx path beneath both drivers. **A long-standing theory was tested and disproved:** `R-601` had warned since `U-080` to "watch for raid1d holding the target disk open R+W during the probe" — a *formatted* second disk stalls exactly like a blank one, and `raid1d` starts long after `switchroot`, so it is not involved. **Second blocker, and my own mistake:** the harness was built to drive `installer_tui` over the serial console, but interactive input over QEMU's macOS unix-socket serial **is not delivered to the guest** — 0 RX interrupts, which was **already recorded in this repo** beside `30_serial-getty.service` in `config/aarch64/eos.toml`. I should have read that before writing the driver; it is exactly the pre-flight check CLAUDE.md §7 exists to force. **An open question this raises, deliberately left open rather than answered by assumption:** README advertises a **RAID-1 mirror over two disk schemes** (`raid1d`, `R-501`), and `R-501`'s own plan describes QEMU verification with *two NVMe disks*. On aarch64 that combination is exactly what `R-F16` breaks — unless both disks happen to share an INTx line. The `U-061`/`U-065` entries that the reality-ledger cites for the "5-boot QEMU sequence" resolve **neither** in `main` nor on the archived branch, so I could not check how those disks were attached, and I am not going to call a years-old claim false on that basis. Settling it (re-run the raid1d sequence, or find the evidence) is follow-up work, not something to assert either way here. **What ships:** `scripts/repro-intx-lines.sh` runs the whole matrix and prints predicted-vs-actual, so a fix shows up as every row turning to *boot*; `scripts/ci-install-smoke.sh` now boots with a second disk (pinned to slot `0x8` as a **workaround, not a fix**), asserts the login prompt, then *demonstrates* the input limitation by typing and reporting the absence of an echo instead of timing out mysteriously. It also stops building its QEMU drive arguments by word-splitting a command substitution, which breaks on this host — the tree lives under `/Volumes/Project itp`. **Verified:** all nine boots above, plus the reproducer script run end to end. **NOT verified, and stated plainly:** partition→install→reboot→login is **still unproven** — `R-601` stays 🚧, and finishing it needs the keyboard path (QEMU monitor `sendkey` + `screendump`); the fix for `R-F16` itself is untouched, it lives in the kernel/pcid INTx path; and x86_64 is only *expected* to escape this via MSI/MSI-X — no x86_64 image has been built on this host. ROADMAP now 50 ✅ / 16 🚧 / 49 ⏳.
- `[U-145]` **the 13 recipes that actually ship are pinned — and my own `WARNING` claim was wrong (`R-F11`)** — step 4 of `docs/plan.md`. Of the **74** packages in the built x86_64 repo, 10 had a `git =` source with no `rev` and 3 fetched a tarball with no `blake3`; `ca-certificates`, an unpinned TLS trust root, was among them. Git revisions were taken from the **SBOM of the verified build** — so the pin freezes *what ships today* rather than moving it to an arbitrary HEAD — and that source was cross-checked on `sdl1`, whose SBOM value `7ac3aeb7…` matches its fetched `source/` HEAD exactly. The three tarball hashes were computed from fresh downloads and then **validated by cookbook rather than by me**: clearing caches forced `cook openssh/nano/file - successful`, which routes through the `blake3` comparison that `bail`s on mismatch; zero hash errors across both build logs. **Two corrections to what I recorded in `U-141`.** First, I repeated the audit's claim that a missing hash is only a `WARNING`. Reading `src/cook/fetch.rs` shows it **`bail`s** — *"Please add blake3 = …"*. The genuine defect is narrower and worse: the whole check sits inside `if !cached`, so **anything already cooked is never re-verified**; deleting `source/` did not trigger it and neither did deleting `target/` — only removing `build/<arch>/<cfg>/repo.tag` made `make` re-run the cook stage, which is how nano and file finally got checked. Second, I called the SBOM's `source_identifier` an "independent record of a previous download" while chasing a hash mismatch on nano; it is not — for `tar` recipes that field is the recipe's *declared* `blake3` or a placeholder (`fetch.rs`: `blake3.clone().unwrap_or("no_tar_blake3_hash_info")`), so there was no discrepancy to explain and no supply-chain story behind it. **Verified:** `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` EXIT=0 with the caches cleared, **boot-smoke PASS**, `integrity` PASS, `pins --strict` ok=26/drift=0; tree-wide unpinned 1527 → 1517, the rest deliberately out of scope as inherited ports (CLAUDE.md §3). **Not claimed:** a blake3 pin freezes an artifact so it cannot silently change — it does **not** authenticate it. Verifying upstream signatures is a separate step, recorded in `R-F11`'s remainder along with making the cached path fail closed under `EOS_STRICT_FETCH=1`.
- `[U-144]` **raw IP sockets are no longer handed to every user program — and the fallback that would have undone it (`R-904a`)** — step 5 of `docs/plan.md`. `config/base.toml` granted the user namespace `ip`, which `netstack` implements as smoltcp's `RawSocket`: arbitrary IP packets, spoofed sources, crafted headers, and a clean bypass of any packet filter operating above the raw layer. Building the firewall (`R-904`) while that is granted would have produced protection anyone could step around, which is why the removal precedes it. **The part the audit's one-line recommendation missed:** removing the names from the config is *not sufficient*. `userutils`' `apply_login_schemes()` falls back to a hard-coded `DEFAULT_SCHEMES` whenever `/etc/login_schemes.toml` is missing or unparseable — and that array **also contained `ip`**, so a single malformed config would silently restore raw sockets. A fallback must never be more permissive than the config it stands in for; a parse error is precisely the moment not to widen authority. Both halves shipped together: `eos-userutils@a43ba3e` (pushed to both hosts, pin bumped `799088a1` → `a43ba3e5`) and an override of `/etc/login_schemes.toml` in both `config/*/eos.toml`. **`icmp` deliberately kept, against the audit's advice to drop both:** `ping` is shipped in `netutils` and opens `icmp:echo/<host>/ttl`, so dropping `icmp` would take `ping` away from ordinary users in exchange for closing a far narrower hole than `ip`. ICMP tunnelling stays possible and belongs to `R-904`'s design, recorded rather than glossed. **Verified in the artefact, not the diff:** the installer log shows `- /etc/login_schemes.toml size=500 B` twice from the include chain and then **`size=528 B`** — the override winning on the record; the built image contains **0** lines `"ip",` and still contains `"icmp",`; `ping` is still built for both arches; `cargo check` clean for `aarch64-unknown-redox`; `make CI=1 … all` **EXIT=0**; **boot-smoke PASS**; `pins --strict` ok=26/drift=0. **Noted for later, not acted on:** the same user list also carries `memory` and `irq`, which deserve the same scrutiny — raised here rather than quietly left.
- `[U-143]` **E-OS images no longer ship a package source that undermines their own hardening (`R-701a`)** — step 2 of `docs/plan.md`. Every image carried `/etc/pkg.d/50_redox → https://static.redox-os.org/pkg` from `config/base.toml:120-121`, inherited from upstream. On an E-OS image that is a hole in the thing the project exists for: a fresh install would `pkg install` **upstream binaries built without** `overflow-checks`, W⊕X or ASLR, over a channel whose signing key `pkg-lib` still fetches **TOFU from the very host that serves the packages**. Both `config/{aarch64,x86_64}/eos.toml` now override that path, using the pattern already proven in this tree (`eos.toml` overrides `/etc/hostname` from `base.toml`; `desktop-contain.toml` overrides `20_orbital` the same way). **The URL is commented out rather than the file deleted, and that detail matters:** reading `pkg-lib`'s `update_remotes()` first showed it skips lines starting with `#`, but also that `fs::read_dir` on `/etc/pkg.d` is fallible and a bare empty line would reach `add_remote("")` → `RepoPathInvalid` — so removing the file, the obvious move, degrades *worse* than keeping a parseable comment-only one. **Verified end to end, not structurally:** the installer log shows `- /etc/pkg.d/50_redox size=31 B` twice (from the include chain `eos.toml → desktop → desktop-minimal → minimal → base`) and then **`size=283 B`** — the override winning, on the record; the built 1.4 GB image contains `#https://static.redox-os.org/pkg` and **zero** uncommented occurrences of that URL; `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` **EXIT=0**; **boot-smoke PASS**. Split out of `R-701` as `R-701a` because it is pure subtraction requiring no key, no publish and no client work — keeping it behind the full trust chain was the same artificial dependency `U-137` removed from `R-803`. **Not claimed:** this removes a bad source, it does not add a good one. `/etc/pkg.d/50_eos` arrives with `R-008` after the repo is signed and published, and only then does `R-702` pin the key — that order is the control (`docs/plan.md` §4).
- `[U-142]` **`docs/plan.md` — who E-OS is for, what security model it is actually building, and the order where the order *is* the control** — `ROADMAP.md` lists items but cannot answer the three questions that decide whether they add up to a product. **Three editions on one base:** *Desktop* is closest to shipping and its day-one gaps have no roadmap items at all (removable-media automount, printing, accessibility, brightness, backup/recovery, trash, and an i18n catalogue — the UI already ships hard-coded Polish strings while the docs are English; the note also records that the i18n *gate* in `CLAUDE.md` was fabricated, per `U-126`). *Gaming* gets an explicit admission rather than silence: E-OS does not run games, and the blocker is a chain — no Linux ABI layer or native ports, no GPU acceleration (`R-930`), no gamepad (`usbhidd` is keyboard/mouse), and `ihdad` times out on the codec RIRB so `audiod` exits — plus two decisions worth taking while cheap (executable memory as a capability; GPU passthrough gated on IOMMU). *Server* does not exist, and the placeholder is a hazard: `config/x86_64/server-demo.toml` carries `PermitEmptyPasswords yes` one syllable from `eos.toml`, and `config/desktop.toml:3` `include`s `server.toml` so the desktop pulls the server set; it also needs a rule that a key-seeded, password-locked account **satisfies** `R-602`, whose OOBE otherwise makes unattended install impossible. **Compartmentalisation:** the scheme model reproduces most of Qubes' *visibility* model without a hypervisor but none of its *hardware* isolation, and that sentence now precedes any "Qubes-like" wording. The single largest unused asset the audit found is `recipes/core/contain` plus `config/desktop-contain.toml` — a complete sandboxed session that **brokers** the file scheme rather than passing it, with `pass_schemes`/`files`/`rofiles`/`dirs`/`rodirs` allowlists — sitting disabled behind `#contain = {}` in `config/server.toml:14`, unpinned, and absent from the built repo. Each Qubes/Tails pattern is mapped to its scheme-model equivalent with its blocker, including two marked **not to promise**: a USB qube (needs IOMMU passthrough; the achievable version gates *trust* via `eos-devd`, stopping BadUSB without claiming DMA protection) and Tor-by-default (no tor port, no firewall, `ip` in the user namespace — a guarantee that fails silently). Tails-style amnesia, by contrast, is **already built** as a side effect of the live image and needs only productising. **Ten-step order with the reason for each position** — notably: gate `main` first or every later gate is a notification; delete `50_redox` *before* the keygen because it is independent pure subtraction; keygen → publish → pin → enforce in exactly that sequence or pinning breaks updates for everyone; strip raw sockets *before* building a firewall they would bypass; and enable `contain` last, because compartmentalising while the surrounding paths are open is building a wall with the gate open. Closes with what we deliberately **do not** promise. Registered in `docs/SUMMARY.md` (else mdBook ignores it, §2) and linked from `ROADMAP.md`. **Verified before writing:** `contain` recipe and disabled state, `desktop-contain.toml` scheme lists, `server.toml`/`desktop.toml` includes, `server-demo.toml` sshd settings, and the absence of `contain.pkgar` from the built repo.
- `[U-141]` **full-ecosystem audit: the security posture document was itself the worst offender** — a six-dimension adversarial audit (13 agents) plus independent re-verification of every load-bearing claim. **The finding that had to be fixed first:** `docs/security.md`'s *Repository protections* table listed `gitleaks CI | .github/workflows/gitleaks.yml | on` and `CodeQL | .github/workflows/codeql.yml | on` — **`.github/workflows/` does not exist**, and GitHub still serves stale CodeQL results from before Actions were disabled account-wide, so a reader checking the dashboard sees green. It also claimed a *required review* that has never existed. Table rewritten against live API output: 2 rows were true, 2 false, 2 misleading. **Newly measured and now recorded:** `only_allow_merge_if_pipeline_succeeds = false` and **0 merge requests in 10 088 commits of history**, so `pin-check`/`integrity`/`rust-checks`/`secret-scan` all report *after* the push and `docs-currency` (MR-only) **has never executed once**; and no commit or tag is signed. README carried the same two overclaims ("CODEOWNERS reviews", "signed commits") and now states the gap instead. **Six verified findings added as `R-F10`…`R-F15`:** the bootloader resolves `redoxfs 0.8.0` from **crates.io** with no `[patch.crates-io]` while the image filesystem is built from the pinned fork `eos-redoxfs@b0f6dff6` — the code that unlocks an encrypted root is a different codebase from the one that creates it (`R-F10`); **13 of the 74 packages actually in the shipped x86_64 image** have no pin or no hash, `ca-certificates` among them, an unpinned TLS trust root (`R-F11`); CI gates are notifications, not gates (`R-F12`); `docs/threat-model.md` promises driver isolation the hardware cannot enforce because there is **no IOMMU** (`R-F13`); 44 shell scripts with **zero** linting, a class that has already cost this project twice via bash-4 syntax on a bash-3.2 host (`R-F14`); and `rust-checks` covers `tools/eos-repo-sign` only, leaving the `redox_cookbook` engine that builds every image unlinted and its tests unrun (`R-F15`). **Scope corrected against the audit itself:** it reported "1528/2052 recipes unpinned" — my own count agrees tree-wide (1527/2051), but those are the inherited third-party ports that CLAUDE.md §3 explicitly leaves on upstream form. Resolving the **actually built** package list turns a frightening 1527 into an actionable **13**. **Verified independently before acting:** every claim above re-checked in the tree or via live API — `config/base.toml:120-121`, `config/base.toml:44-48`, `config/desktop.toml:3`, the bootloader's `Cargo.lock`, `gh api` security settings, `glab api` project settings, and a package-by-package walk of `repo/x86_64-unknown-redox`. ROADMAP now 47 ✅ / 16 🚧 / 49 ⏳ with **12** open P0.
- `[U-140]` **the pre-commit secret gate was decorative, `unsafe` had no rule at all, and nothing was signed — all three addressed** — asked to add signing, dangerous-code and secret rules to `CLAUDE.md` "if not already there", the first job was checking what *was* there. Result: one of the three was worse than absent. **Secrets:** `lefthook`'s `pre-commit` hook ended in `|| true`, so gitleaks' exit 1 became 0 and a staged secret committed cleanly — proven in an isolated repo with a planted private key (gitleaks exit 1; the hook line exit 0). CI catches it afterwards, but by then it is pushed and mirrored and the only remedy is a history rewrite plus rotation, so the hook is the layer that actually protects anything. It now **fails closed**, including when gitleaks is absent — a silently skipped scan has the same outcome as no scan — with a deliberate `EOS_SKIP_SECRET_SCAN=1` override in the U-120 idiom. *(An earlier test of mine reported "not detected" because I used the canonical AWS documentation key, which gitleaks allowlists on purpose; retested with a pattern it does flag.)* **Dangerous code:** `CLAUDE.md` mentioned `unsafe` **zero times** and `clippy.toml` only tunes thresholds. New check 4 in `scripts/ci-integrity.sh` fails the build on any `unsafe` in E-OS-owned Rust lacking a `// SAFETY:` note in the three preceding lines. Scope deliberately excludes `src/` — that is the **vendored** `redox_cookbook` (package `redox_cookbook`, upstream author), where all nine `unsafe` blocks live in `src/cook/pty.rs`; annotating upstream code would create divergence to re-apply on every sync for no safety gain, the same reasoning that leaves third-party ports on upstream flags. E-OS-owned Rust has **zero** `unsafe` today, so the gate lands while the count is nil and can never accrue a backlog; the real `unsafe` is in the forks and gated by their CI. **Signatures:** nothing is signed and nothing can be — `commit.gpgsign`, `tag.gpgsign` and `user.signingkey` are all unset, there are **0** GPG keys, and **0 of the last 20 commits** carry a signature, while `CONTRIBUTING.md` has said "commit signing encouraged" throughout. No gate was added, because a gate that cannot pass is theatre: §10.1 states the rule, records the measurement, gives the exact one-time setup, and says plainly that **generating the key is a human action, deliberately not automated** — a signing key must never pass through tooling that logs. **Verified with negative controls on both new gates:** the `unsafe` check FAILs on a planted un-annotated block and PASSes once a SAFETY note is added (file restored, tree clean); the secret hook blocks a staged key, skips loudly under the override, and passes a clean tree. `lefthook.yml` re-parsed as YAML, `bash -n` clean, full `integrity` PASS on 4/4 checks.
- `[U-139]` **branch hygiene: 14 branches down to 5, and the mirror turns out not to replicate deletions** — the meta repo carried nine dead branches. Eight were Dependabot proposals from 2026-06-17, three of them bumping GitHub Actions in workflows that **no longer exist in `main`** (`.github/workflows/` is gone since Actions were disabled account-wide, and `dependabot.yml` already dropped that ecosystem). The ninth, `eos-base`, was an orphaned snapshot whose only two commits delete and then restore `LICENSE` — `main` is **18 556 lines ahead** of it and already carries both the AGPL `LICENSE` and `licenses/Redox-OS-MIT.txt`. **Checked before deleting, because this project has been bitten once:** `U-121` found the meta repo's `imgbot` branch carried a *unique* commit that a forced mirror-push would have erased. So each candidate was diffed against `main` first, and the five cargo proposals were checked against the live `Cargo.lock` — `main` is still on `toml 0.8.23`, `redox-pkg@209d1ed`, `redox_installer@1c2534e`, `redoxer@e4c4095`, i.e. none were ever applied. Deleting them loses nothing: Dependabot's cargo ecosystem is still configured weekly and will re-propose against the *current* base, which is strictly better than branches rooted before the LICENSE restore; and `deny.toml` runs `yanked = "deny"` with no ignores against a green pipeline, so no pending advisory was discarded. **Deliberately kept:** `main`, `lts/0.1`, and all three `archive/*` — `archive/pre-migration-de-phase1` is the disjoint history holding every pre-`U-071` record (`U-131`), so deleting it would destroy the evidence several docs cite. **Deliberately NOT deleted:** the leftover `imgbot` branches in `eos-ion` and `eos-orbdata`, which each carry one unique ImgBot commit (3 and 17 files of image optimisation). Those need the `U-121` treatment — cherry-pick, verify every image byte-for-byte, then delete — not a `--delete`. **The operational finding worth more than the cleanup:** the GitLab→GitHub push mirror **replays pushes but not deletions**. All nine branches were still on GitHub 45 s after the GitLab delete and needed an explicit `git push github --delete`. That is now written into `docs/MAINTENANCE.md`, which also had the repo count stale at 25 — `repos.toml` holds **30**. **Verified:** every SHA recorded before deletion; both hosts re-listed afterwards and now report an identical 5-branch set; `git log` confirms `HEAD` untouched. Also re-measured and recorded: **30/30 repositories report the same SHA on both hosts** for their pinned branch — checked with `git ls-remote` against both URLs rather than trusting a status page.
- `[U-138]` **CLAUDE.md gains the three sections it was missing: cadence, releases, and the host it actually runs on** — §1 said *what* must be true before something ships, but nothing said **when**, so "documented later" kept being a valid-looking answer. New **§7 Cadence** makes the docs/CHANGELOG/ROADMAP/README/commit/push/gates set land *with* the change, and opens with three pre-flight checks that each encode a real failure from this project: `git log` first (a session once re-implemented an entire entry byte-for-byte because nobody looked), confirm you are not on a stale tree, and confirm a finding **in the tree** rather than in a report — a defect was twice "confirmed" here that did not exist. It also states the rules that were previously only tribal: verify the `U-NNN` is free before using it (a duplicate has happened), bump README's `SYNC:` marker only after actually re-walking the entries it claims to cover, never mark an item ✅ whose gates you did not run, and push meta to **GitLab only** (the mirror replicates; a manual GitHub push races it) while forks need both hosts by hand. New **§8 Releases, tags and numbering** ties the four places version identity lives — tag, README `SYNC:`, CHANGELOG head, ROADMAP — and records the current drift rather than hiding it: `v0.1.0` points at `b4d2bfab8` (2026-06-07), is **unsigned**, and is **218 commits** behind `main` while README calls it the current version. New **§9 Where this actually runs** documents the real host: Apple M4 `arm64`, tree on an **exFAT** USB SSD (hence `core.symlinks=false`, `core.filemode=false`, `._*` litter, and why VM images cannot live there), container data in APFS sparsebundles that **must be mounted first**, the `eos-work`/`eos-root` volumes being the actual asset, why local `make … all` cannot work from the macOS checkout, that only `/bin/bash` 3.2 is available, and that the disk moves to a desktop machine later while x86_64 metal stays a separate rig. **Verified:** every claim in §9 was measured in this session rather than assumed — mount points, volume sizes, gate timings, the bash version, and the tag's distance from `main` (`git rev-list --count v0.1.0..HEAD` = 218).
- `[U-137]` **one malformed vendor key could take down every driver binding at boot — fixed and regression-tested (`R-803`)** — `pcid`'s `DriverConfig::match_function` parsed driver-config vendor keys with `i64::from_str_radix(..).unwrap() as u16`. Two bugs shared that line. The `.unwrap()` **panicked pcid mid-scan**, and because the matcher runs for every driver config against every device, a single malformed entry took out **all** driver binding — not just its own driver. The `i64 → u16` as-cast **silently truncated**: `"0x11111000"` parsed happily and then matched vendor `0x1000`, so an entry could bind a device it does not name. Now parsed straight into `u16`, which rejects out-of-range, with a `log::warn!` naming the driver and the bad key, then `continue` — failing closed on the *entry* keeps every well-formed driver in the same file working. This matters more the moment `R-802` makes the driver catalog a downloaded file: the matcher is the code that would parse hostile input, and it must not be the thing that bricks boot. **The negative control is the part worth reading:** four unit tests were added in the same module and pass 4/4 on the fix — but run against the **original** parser they fail 3/4, two of them by panicking at `config.rs:50:77` (the `unwrap`) and one by failing its assert (the truncation), while `well_formed_vendor_key_still_matches` passes on both. Tests that pass on old and new code alike would have proved nothing. **Gate, in order:** `cargo check` for `aarch64-unknown-redox` clean; `cargo test -p pcid --lib` 4/4 on the host inside the build container; fork pushed to **both** hosts per CLAUDE.md §1.6 (no mirror on forks) and both confirmed at `66e3070b` before the bump; `recipes/core/base/recipe.toml` + `repos.toml` bumped `d6336419` → `66e3070b`; `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` **EXIT=0**; the new warn string is present in the 1.4 GB artefact; **boot-smoke PASS** — and reaching login *is* the runtime proof, since the boot cannot get there unless pcid still binds `nvmed` through the rewritten matcher. `pins --strict` stays at ok=26/drift=0. One self-inflicted detour worth recording: the first build failed `EXIT=2` because the patched `config.rs` was still sitting in the container's `recipes/core/base/source` from the gate-1 run, so cookbook's `git checkout` of the new rev refused — discarding the local copy fixed it. **Not done:** `R-803` also asks for duplicate-entry rejection and binary-presence validation, and stays 🚧; rejecting *unsigned* catalogs is genuinely blocked on `R-802`/`R-703`. Its `needs R-801` dependency was artificial and is dropped — this change touched only the parser.
- `[U-136]` **the text every user actually reads was still advertising a desktop we don't ship and a handbook that 404s** — `U-127` corrected the "COSMIC desktop" overclaim across the docs, but missed the one place it reaches real users: the boot banner and `Welcome.txt`, shipped in every image via `recipes/other/eos/recipe.toml` (`/usr/bin/eos-welcome`) and duplicated in `config/{aarch64,x86_64}/eos.toml` (`/home/user/Welcome.txt` **and** `/home/user/Desktop/Welcome.txt`) — three copies of the same prose, the copy-paste drift the 2026-07-13 audit warned about. Four claims corrected, each checked first rather than assumed: **(1) "Desktop: COSMIC"** → the Crimson desktop on orbital with COSMIC apps as clients (`R-D12`). **(2) Handbook → `https://gh0s777tt.github.io/E-OS/`** — the GitHub Pages copy is **stale**, and the index page hides it: `/` returns **200** there, so a quick look says "fine". Fetching a page that changed recently settles it — `ci.html` is **404 on GitHub** and **200 on GitLab with the `U-133` text in it**. Pointed at `https://e-os.gitlab.io/e-os/`, which the `pages` job republishes on every push. **(3) Source → GitHub** — that is the read-only mirror (CLAUDE.md §5); pointed at `https://gitlab.com/e-os/e-os` and labelled the mirror as such. **(4) "user (no password) · root / password — change them after install!"** — stale since `R-602`: password enforcement is DONE on *every* login path, so by the time anyone reads this the OOBE has already forced the change. Now names the accounts and says the first login makes you set a password. Left alone deliberately: `eos info` / `eos doctor` (both real ion functions with dispatch in the same recipe) and "COSMIC Files" (cosmic-files genuinely is a COSMIC app). Also `docs/design-eos-control-network.md`, which still argued the DHCP↔static toggle was *deferred* with a paragraph of reasoning — `U-132` shipped it; the reasoning is kept as the right question to have asked, with the answer corrected, and the "Follow-up" section now records `R-902` closed plus the one honest debt (no screendump of the toggle). **Verified through the image, not the diff:** `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` **EXIT=0**, then grepped the 1.4 GB artefact — the new lines are present (3× the OOBE sentence: banner + both Welcome copies; 2× the GitLab docs URL; 4× "read-only mirror") and the old ones are **gone** (0 hits for `gh0s777tt.github.io/E-OS` and for `Login:  user  (no password)`); boot-smoke **PASS**. One thing I nearly "fixed" and should not have: README's `build/x86_64/desktop/harddrive.img` looked phantom next to the aarch64 `eos` path, but step 3a above it is `make CI=1 all` with no `CONFIG_NAME`, which defaults to `desktop` — the path is correct for the command it documents. `docs/hardware-matrix.md:4` *does* have the real version of that defect (calls it "the built E-OS x86_64 image" while pointing at the `desktop` config); left for the pass that also gives the matrix its missing `Arch` column.
- `[U-135]` **the pinned repo key had nowhere to land — `scripts/eos-pin-repo-key.sh` builds the missing half of R-702** — `U-134` established that both ends of the manifest-signature chain exist: the publisher signs, and `pkg-lib` verifies via `manifest_sig::verify_manifest_ed25519()`, failing closed once a key is pinned. The remaining step was described everywhere as "generate `keys/eos-repo-sign.pub.toml`" — but generating it would have changed **nothing**, because `pkg-lib` reads the key from `/etc/pkg/eos-repo-sign.pub.toml` *inside the image* (`REPO_SIGN_PUBKEY_PATH`, `pkg-lib/src/lib.rs:31`) and **no config installed anything at that path** (`grep -rn etc/pkg/eos-repo-sign config/` → 0). The key would have sat in `keys/` while every client kept warning and proceeding — a silent no-op at the end of the single highest-leverage action in the trust chain. The new script closes that: it embeds the public half into `config/{aarch64,x86_64}/eos.toml` between managed markers (the installer's `[[files]]` has no `from`/`source` field, so content must be inline), is idempotent, validates the key is 64 hex chars — the length `load_pinned_ed25519()` requires — and **refuses a secret key file**, since `keygen` marks the secret half `[secret_keys]`/`ml_dsa_65_seed` and a config is world-readable in every shipped image. R-702 is now two commands. **Verified end-to-end, not just structurally:** all four guard paths exercised (missing key → keygen instructions; secret key → refusal; 8-hex key → refusal; valid key → injected into both configs; re-run → *updated*, one block not two), then a full `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` with a throwaway key — **EXIT=0** — and the installer log shows `- /etc/pkg/eos-repo-sign.pub.toml size=117 B mode=644`, i.e. the file genuinely reaches the image at the path the client reads. The throwaway key was reverted from the configs afterwards; the tree ships no key. **Not done:** generating the real keypair — that is a human action, deliberately not automated, because the secret half must never pass through tooling that logs.
- `[U-134]` **I got the signing chain wrong in `U-126` — the client verifier exists; correcting my own overcorrection, and un-inverting the trust-chain ordering** — `U-126` rewrote `SECURITY.md`, `keys/README.md`, `docs/security.md`, `README.md`, both publish scripts and `R-703` around the claim that *"`pkg-lib` has no `verify_manifest()`"*. That claim was **false**, and the way it was reached is the point: the evidence was `git grep verify_manifest` run in the **meta repo**, which does not contain `pkg-lib` at all — it lives in the `eos-pkgutils` fork. That is precisely the error `U-126` itself convicted `docs/reality-ledger.md` of committing with `src/base-drivers/*`: citing the absence of something from a tree that never held it. **What is actually there**, at the pinned `eos-pkgutils@5978425e`: `pkg-lib/src/manifest_sig.rs` implements `verify_manifest_ed25519` (strict ed25519 over the raw manifest, hex `.sig` field parsing) with unit tests covering a tampered index, a wrong pinned key, a signature-free `.sig` and a malformed one; `pkg-lib/src/backend/pkgar_backend/mod.rs` calls it from `verify_repo_manifest`, which reads the pinned key from `install_path/REPO_SIGN_PUBKEY_PATH` and — this is the part that matters — **fails closed once a key is present**: a missing `repo.toml.sig` is `Error::RepoManifestUnsigned`, an invalid one is `Error::RepoManifestSigInvalid`. With no key pinned it prints `pkg: WARNING — no pinned repo-manifest key … repo.toml is NOT signature-verified (R-703)` and proceeds, because per-package pkgar ed25519 remains enforced. **So the gap is one artifact, not a subsystem:** `keys/eos-repo-sign.pub.toml` has never been generated, and `keys/README.md` already documents the exact `eos-repo-sign keygen` invocation that creates it. Every site `U-126` touched is corrected to say that. **Second correction, same area:** `R-702` carried `needs R-701` — the reverse of the order the reality-ledger names as *the security control* (`R-702`→`R-703`→`R-701`), because landing an update source while the key is still TOFU-fetched from the package host is worse than the current inert state. `R-702` now depends on nothing (it is just the key), and `R-701` depends on `R-702`+`R-703`. `R-703` drops from `M` to `S` and from "the whole client side remaining" to "pin a key". **Verified:** the fork was cloned (`--bare --filter=blob:none`) and the pinned rev inspected directly — `ls-tree` confirms `pkg-lib/` exists there, `git grep` at that rev finds the verifier, and the call site was read in full to establish the fail-closed-vs-warn behaviour rather than inferred from the function name. **Lesson worth keeping:** in this repo, "grep found nothing" is only evidence if you grepped the tree that would contain it — meta-repo greps cannot see fork code, and this is now the third finding of that exact shape (`U-126` ledger paths, `U-130` usbnetd, this).
- `[U-133]` **x86_64 boots, boot-smoke now covers it, and the live-USB path onto real hardware is documented** — the biggest standing risk in this project is that **zero** boot claim has ever been made on metal; every one is QEMU. The tooling gap was smaller than it looked. `make CI=1 ARCH=x86_64 CONFIG_NAME=eos live` already exists and works: it produced a 1.40 GB `redox-live.iso` (**EXIT=0**) carrying the freshly-bumped `U-132` pins (`eos-control` 17 MB, `installer-gui` 16 MB rebuilt), and the file is a **raw GPT image with a protective MBR** (`EFI PART` at offset 512, `0x55aa` in the MBR) — i.e. `dd`-able to a USB stick and UEFI-bootable, despite the `.iso` name. **It boots.** Serial from the run: `E-OS Bootloader 1.0.0 on x86_64/UEFI` → `RedoxFS …: 1397 MiB` → `Press l to disable live mode` → `live: 0/1397 MiB` … `1397/1397` → `E-OS 0.1.0 "Genesis"` → `eos login:`. **The load-bearing assumption that turned out false:** `.gitlab-ci.yml` and `docs/ci.md` both justified skipping boot-smoke on `build-image-x86_64` because *"a full x86_64 boot on Apple Silicon runs under slow TCG"* and could time out. Measured: **16 s** — the same order as the aarch64 job (which takes 16 s too). So the job had been shipping, as a green artifact, an image nobody ever booted. `scripts/ci-boot-smoke.sh` gains `--arch aarch64|x86_64` (machine/cpu/firmware per arch: `virt`/`cortex-a72`/`edk2-aarch64` vs `q35`/`max`/`edk2-x86_64` — note OVMF ships its writable vars as the **i386** file even for the x86_64 build, and `ramfb` is a virt-board device that `q35` rejects), defaulting to `aarch64` so the existing call site is untouched; the x86_64 job now runs it. `docs/install.md` gains a **Live USB** section with the build+`dd` recipe and — more usefully — an honest forecast: the upstream `HARDWARE.md` matrix's recurring result is *boots to the desktop, touchpad/USB input and networking do not work*, which matches the known gaps (`R-916` no I2C bus → no I2C-HID touchpads, `R-910` thin NIC coverage), so a greeter without a trackpad is the **expected** first result and worth reporting rather than a regression. **Verified:** both arches run through the modified script — x86_64 PASS in 10 s (`--arch x86_64`), and a regression run of the **exact CI call site** (`ci-boot-smoke.sh <img> 420`, no flag) PASS in 16 s on aarch64; `bash -n` clean; `.gitlab-ci.yml` re-parsed as YAML. The harness was first prototyped outside the repo and only folded in after both paths passed. Also folded in: `mk/qemu.mk` looked for `edk2s-x86_64-code.fd` on the Homebrew branch — a one-character typo (`edk2s`) meaning `make qemu ARCH=x86_64` found no UEFI firmware on the macOS dev host at all; the directory and the correctly-named file were both there the whole time. **Still not claimed:** nothing here touched real hardware — this makes the USB *reachable*, it does not validate it.
- `[U-132]` **the two R-902 pins are bumped and gated — the allowlist is empty for the first time since `U-114`** — `eos-control` and `eos-installer` had been held back since 2026-07-24/25 because their feature commits needed a full gate run that the (apparently) missing build container made impossible. `U-124` restored the container; this entry runs the gate. **Preconditions checked first**, since forks have no push-mirror (CLAUDE.md §1.6): both revisions were cloned from **both** hosts and confirmed present on the right branches — `eos-control@40dc67fd` on `main`, `eos-installer@ed6eb7ce` on `master`, GitHub *and* GitLab — so the recipes cannot silently fetch stale code. **What the bumps bring:** the persistent **DHCP↔static toggle** (`netcfg.rs` +448/-…, new `netcore.rs`, `eos-netcfg` subcommands, ~700 lines) and the installer GUI's **pre-install network pane** (+205 lines). **The gate, in order:** (1) `cargo check` on `aarch64-unknown-redox` — `eos-control` 1m05s, `redox_installer` 13s, `redox_installer_gui` 30s, all green (the GUI is a separate package, not a workspace member, so it needs its own check — checking only the root package would have missed the entire change); (2) host `--selftest` — `EOS-CONTROL-SELFTEST-OK`, exit 0, and the commit's own additions assert the new marker parser (`static`/` STATIC \n` → Static; ``/`nonsense` → Dhcp), the file read path including the absent case, and `valid_iface` — which matters because an interface name rides on argv into a root process and is interpolated into a scheme path; (3) `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` → **EXIT=0**, 1.40 GB image, `eos-control.pkgar` rebuilt at 16.8 MB; (4) `scripts/ci-boot-smoke.sh` → **PASS — reached userspace login**. `scripts/pin-allowlist.txt` is now empty (its header records the removal condition that was met) and `pins --strict` exits 0 at **ok=26 drift=0**. `R-902` closed. **Two things worth recording rather than smoothing over:** the host build first failed on `fontconfig` because I used default features — the fork documents `cargo build --no-default-features` for the host (the GUI half targets Redox via `eos-ui`), my invocation was wrong, not the code; and the podman machine would not start at all until `~/bin/mount-container-volumes.sh` was run, which is exactly the failure mode `U-124` documented and the first time that procedure was exercised for real. ⚠️ **Not claimed:** the toggle's **on-screen render is not screendumped**. CLAUDE.md §4 says a GUI render is proven by screendump and this one is owed — the pane and apply flow were screendumped in `U-113`, the toggle's non-visual core is `--selftest`-proven, and it ships in a boot-smoked image, but that is not the same thing.
- `[U-131]` **"history lives in the git log" was not quite true, and it was about to manufacture a false finding** — chasing the `U-130` records surfaced that the archived pre-migration branch is a **disjoint history**, not an ancestor of `main`, and that ten pre-`U-071` numbers (`U-001`–`U-006`, `U-008`, `U-012`–`U-014`) appear nowhere in `main`'s log. The work *is* there — `main` records it under `R-NNN` roadmap codes (`R-401c`/`R-401d` for the nvmed INTx and shared-PCIe-IRQ fixes, for instance) — but the `U-NNN` labels are not, so the header's flat "lives in the git log" pointer sends readers somewhere the record isn't. This matters because `docs/reality-ledger.md` cites `CHANGELOG U-011/U-012/U-013/…` as the evidence for its highest-confidence row ("aarch64 bring-up fixes are substantive and real"); anyone verifying that pointer finds nothing and would reasonably conclude the evidence was invented — the exact error this project has now made twice in the other direction (`U-126`'s `src/base-drivers` paths, `U-130`'s usbnetd comment). The header now names the archive branch and the `R-NNN` mapping. **Verified:** the ten missing numbers found by differencing the archive CHANGELOG's `U-NNN` set against every occurrence in `git log main`; `git merge-base --is-ancestor` confirms the archive branch is disjoint; spot-checked that `R-401c`/`R-401d` (the substance behind `U-012`/`U-013`) do appear in `main`'s log, so the work is traceable even where the label is not.
- `[U-130]` **`usbnetd` RX was never broken — the fix shipped a month ago and the paperwork was lost with a branch (`R-901` closed)** — `R-901` has stood open since 2026-07-13 telling readers the USB-Ethernet driver receives zero frames. It does not. RX=0 was the state at `1ed8267a8` (2026-07-12 **01:48**); the receive path was fixed the **same day** and proven, and only the CHANGELOG entries recording it were lost when `main` was re-migrated — they survive on `origin/archive/pre-migration-de-phase1` and are recovered here. **The root cause (`U-056`, `da0e04165`):** xhcid's `endpoints/<n>` handle numbers endpoints by a **global** 1-based counter running across *every* interface of the chosen config, not the position within one interface. RNDIS puts a Communications control interface (one interrupt endpoint) **before** the CDC-Data interface, so the data interface's bulk IN/OUT are global indices **2/3, not 1/2** — `usbnetd` used position+1, so it read the control interrupt endpoint and wrote the bulk-IN endpoint, and both hung. (position+1 only ever worked for `usbscsid`, whose interface happens to be first.) Fixed by mirroring xhcid's global walk; an ARP request egressed and its reply came back on the bulk-IN, both visible in a pcap. **The residual blocker (`U-057`, `60b77bc5c`):** xhcid serves its scheme single-threaded with a `block_on` per transfer, so a blocking bulk-IN read on the RX thread stalled a concurrent bulk-OUT write — and a second USB subdriver's init on the same controller. Lifted with an additive `O_NONBLOCK` arm/poll path (`open_endpoint_nonblock`, `arm_read`/`poll_read`); the blocking path is byte-for-byte unchanged, so `usbhidd`/`usbscsid`/`usbhubd` keep their exact behaviour. **Proof, recorded at the time:** QEMU aarch64 with `usb-net` + `usb-storage` together — the pcap shows a complete `DISCOVER → OFFER → REQUEST → ACK` and the netstack takes its `10.0.2.15` lease; `usbscsid` still reaches `SCSI initialized`; `login`, 0 exceptions. **The code is in the shipped image:** `eos-base@a3a98fd4` is an **ancestor of the pinned `d6336419`** — verified this session by cloning the fork and running `git merge-base --is-ancestor` (`d6336419` is also the current `eos-july` tip). The pin bump had been deferred back then "until the fork is pushed — tokens compromised", and by the time it was pushed the paperwork had been archived. **Polarity correction:** `R-901` and `docs/reality-ledger.md` both accused `usbnetd`'s own source comment of *falsely* claiming a full bidirectional handshake. The comment was **right**; the docs were stale — a caution worth keeping, since the ledger's job is to catch exactly this and it got the direction backwards. Reconciled in `README.md`, `ROADMAP.md` (`R-901` → ✅, plus its next-actions bullet), `docs/roadmap-connectivity.md` (🚧 partial/RX broken → ✅ full duplex) and `docs/reality-ledger.md` (finding struck, evidence row corrected, both stale next-action bullets retired); `docs/design-xhcid-nonblocking-transfers.md` already said IMPLEMENTED and needed no change — it was the one page that survived the migration telling the truth. **Verified:** ancestry checked against the real fork, not inferred; both archived commits read in full and their content reproduced here rather than paraphrased; `integrity`, `pin-check` and a `docs-currency` simulation PASS. **Not claimed:** the pcap was **not** re-run against a current image — that re-proof rides along with the next `build-image`, and the status above rests on the 2026-07-12 run against the exact code that is in today's pin.
- `[U-129]` **README re-verified against `U-118`…`U-128` and its `SYNC` marker finally moved** — the
  marker had been parked at `U-117`/2026-08-14 for eleven entries. It was deliberately *not* bumped
  in `U-126`–`U-128`, because bumping it asserts "README has been checked against everything up to
  here" and that check had not been done — a false marker is exactly the defect those entries were
  fixing. This entry does the check, and it found one real contradiction: `U-126` made
  `SECURITY.md`, `keys/README.md`, `docs/security.md` and both publish scripts explicit that the
  hybrid PQ signature is **publisher-side only** — no pinned key (`R-702`), no `verify_manifest()`
  (`R-703`) — while README still advertised "post-quantum-ready signing" twice with no trust
  boundary at all, i.e. the front page contradicted the security policy it links to. Both bullets
  now carry the boundary in the same words the other pages use. Also folded in: the security
  section never mentioned `U-118`'s SHA256 pinning of every fetched build binary, so that gate was
  invisible to exactly the reader who would look for it. Marker moved to `U-129`/2026-08-17.
  **Verified:** every `U-118`…`U-128` entry walked against README — `U-118`/`U-120` produced the
  two changes above; `U-119`, `U-121`, `U-123`–`U-125` are internal (tooling, CI, mirror hygiene)
  with no user-facing README claim; `U-122` is a docs cross-reference; `U-126`–`U-128` are already
  reflected. The one link this entry adds was checked against its target heading and the anchor
  **dropped** — `## 📦 Supply-chain gates (…)` does not slug to `#supply-chain-gates`, so the
  fragment would have been dead on both GitHub and the mdBook site.
- `[U-128]` **README roadmap Gantt: one missing brace made its theme directive invalid** — the
  `%%{init: …}%%` directive above the roadmap Gantt chart (`README.md`) closed with `}}%%` where
  it needed `}}}%%`: four `{` against three `}`, so the JSON never terminated. Consequence: the
  crimson theming silently did not apply to that one chart (older mermaid versions error on the
  directive outright), on the project's front page. Pre-existing — not introduced by `U-126`/
  `U-127`; found while brace-balancing every mermaid directive during the `U-127` review.
  **Verified:** a script counting `{` vs `}` in every `%%{init` line across `README.md`,
  `docs/architecture.md` and `ROADMAP.md` now reports balanced (3/3) for all six directives; the
  other five were already correct and are untouched.
- `[U-127]` **the shipping session was never "the COSMIC desktop" — the false claims corrected, the
  correct ones deliberately left alone (`R-D12`)** — the last high-severity item from the `U-126`
  audit. "COSMIC desktop" reads as *the COSMIC compositor session*, and E-OS has never run one:
  `config/desktop-minimal.toml` starts `orbital orblogin launcher` (orbital is display server,
  window manager and software compositor in one process), the E-OS DE on top is `eos-orbutils`
  (greeter, launcher, wallpaper, desktop icons), and `config/desktop.toml` adds COSMIC
  **applications** as clients — `cosmic-edit`, `cosmic-files`, `cosmic-term`, plus `cosmic-icons`
  as a theme. `cosmic-comp` is *declared* in exactly two places: `recipes/wip/`, behind
  `#TODO: performance issues, no keyboard input` and with `libinput` commented out (Redox has no
  evdev/udev), and `config/wayland.toml`, which **no** Makefile target, script or CI job
  references (default `CONFIG_NAME?=desktop`; CI pins `CONFIG_NAME: eos`). Corrected in README
  (typing tagline, shields badge, screenshot alt, screenshot caption, feature table, highlights,
  mermaid layer, spec table, quick-start comment, and the Core-Components table — which still
  billed `cosmic-*` as the "Desktop environment" and had no `orbital` row at all),
  `EOS_BUILD_STATE.md` (3), `docs/architecture.md` (2 diagram nodes + the component table),
  `docs/{install,getting-started,building,hardware-bringup,known-issues}.md`,
  `docs/reality-ledger.md` (the finding struck as RESOLVED), `config/x86_64/eos.toml` (comment
  only; its box-drawing header re-padded to 76 chars to match its neighbour — note the frame as a
  whole was already crooked at 74/76/76/79/74 before this change and still is),
  `ROADMAP.md` (2), and three files an early grep missed because it was scoped to `*.md`/`*.toml`:
  `NOTICE` ("incorporates the COSMIC desktop and apps" — an attribution document),
  `assets/eos-banner.svg` (the graphic twin of the README tagline) and
  `.github/ISSUE_TEMPLATE/bug_report.yml` (`desktop/COSMIC` → `desktop/orbital` + `apps/COSMIC`).
  New: a `docs/known-issues.md` entry recording *why* `cosmic-comp`
  is absent and what that means for `R-D01`; an UNUSED/EXPERIMENTAL header in
  `config/wayland.toml` so it stops being cited as evidence; and `R-D12` closing the gap the
  reality-ledger flagged as scheduled by no roadmap item. **Wording** was taken from the repo's
  own honest pages (`docs/screenshots.md`, `docs/design-desktop-environment.md`) — "Crimson
  desktop (orbital + `eos-orbutils`) with COSMIC apps as clients" — rather than invented.
  **Deliberately NOT changed**, because they are accurate: every reference to the COSMIC *apps*
  and `cosmic-theme` (`config/*/eos.toml`, `docs/design-desktop-environment.md`, `ROADMAP` R-D07),
  the three docs naming the upstream **COSMIC project** as third-party software
  (`docs/forks.md`, `docs/hardening.md`, `docs/faq.md`), the vendored upstream
  `docs/REDOX-README.md`, and the dated `docs/audit/` snapshot. **Verified:** the screenshot was
  opened before its caption was rewritten (it shows the crimson E-OS wallpaper, hexagon logo and
  the `eos-orbutils` taskbar — no COSMIC shell); `cosmic-comp`'s absence re-derived from
  `config/desktop*.toml`, the wip recipe and a tree-wide grep for `wayland.toml` users (zero);
  box-drawing header width re-measured (76 chars, matches its neighbour); TOML files confirmed to
  have **comment-only** diffs, so parsing cannot have regressed. The change was then put through
  an adversarial three-lens review, which caught real defects that are folded in above: the missed
  `README` component-table row, the three non-`.md`/`.toml` files, a self-contradicting "the only
  place in the tree that names `cosmic-comp`" comment this change had itself introduced into
  `config/wayland.toml` (corrected to "the only *config*"), and a new `known-issues` paragraph that
  reproduced the very app-vs-compositor conflation the entry exists to prevent — it implied
  `cosmic-settings` waits on `cosmic-comp`, when it is an orbital client deferred by a
  `fontconfig`→`host:gperf` 404 on aarch64 build hosts; an explicit callout now says so.
  `integrity`, `pin-check` and a `docs-currency` simulation PASS.
- `[U-126]` **docs honesty pass: the signing chain, the install guide, and a reality-ledger that
  had been auditing the repo with invented evidence** — a six-dimension audit (each finding
  re-checked by an adversarial reviewer) of the open docs↔code gaps produced three fixes.
  **(1) The signing chain is described as one control; it is two, and only one exists.** The
  publisher genuinely signs `repo.toml` (hybrid ed25519 + ML-DSA-65, hard-fails unsigned since
  `U-120`) — but **no client checks it**: `keys/eos-repo-sign.pub.toml` has never been generated
  or committed (`keys/` holds only the minisign release key) and `pkg-lib` has no
  `verify_manifest()` (`git grep` hits design docs only). `SECURITY.md`, `keys/README.md` and both
  publish scripts nonetheless stated client-side verification in the present tense, so a reader
  had every reason to believe the package channel was authenticated end-to-end. All of them now
  separate publisher-side (live) from client-side (`R-702` pin + `R-703` verify, neither started),
  and `docs/security.md`'s rollout stage 1 is marked half-done. `docs/packages.md` gains the
  matching caveat: the per-package pkgar ed25519 check is genuine, but the index is unverified and
  the post-install remote pubkey is still TOFU. Two design docs were stale in the **opposite**
  direction — `update-system-design.md` ("the publisher never runs it today") and
  `driver-manager-design.md` ("wire eos-repo-sign into publish-repo-pages.sh") — both corrected,
  and `ROADMAP` `R-703` now records that its publisher half is done.
  **(2) `docs/install.md` §2/§3 promised an install wizard that does not exist** — "creating
  users / passwords" and "the package set" (plus the TUI comment "prompts for disk, users,
  encryption, packages"), while `R-603` states both front-ends clone `base.toml` defaults and
  create no accounts. Replaced with what the binary does, plus an explicit warning that a fresh
  install lands on the shipped `user` (passwordless) and `root`/`password` and that the first
  login forces the change. `R-608` itself was defective and is corrected in the same pass: it
  accused §2 of inventing an interactive encryption walk-through, but the `redoxfs password`
  prompt is real (`docs/encryption.md:16`), and its `needs R-603` dependency pointlessly parked a
  text-only `[P1·S·any]` fix behind the `R-601` hardware harness — dropped.
  **(3) `docs/reality-ledger.md` — the page that exists to catch other docs lying — was itself
  running on false premises.** Worst: its i18n finding ("CLAUDE.md makes i18n key-parity a hard
  pre-commit gate and mandates Polish docs/UI, so the project violates its own gate") was not
  stale but **invented** — `grep -niE "i18n|l10n|locale|polski|polish|parity" CLAUDE.md` returns
  nothing, and `CLAUDE.md` entered the repo in `87257aca3` (2026-07-19), **six days after** the
  ledger was written (`1a40a7844`, 2026-07-13). Same class: Polish-language quotations attributed
  to that English file, here and in `ROADMAP` (`'bez luk'`, `'docs zgodne z kodem'`) — theses
  sound, quotation marks fabricated; all now cite sections instead. Four further premises are
  simply resolved (phantom `release/SHA256SUMS` — the directory is not even in the index; "the
  publisher never emits `repo.toml.sig`"; "`make-release` doesn't regenerate the SBOM";
  `roadmap-connectivity.md`'s "✅ verified" usbnetd, fixed in `U-115`), one never existed (a
  self-contradictory `U-055` CHANGELOG entry — there is no `U-055` entry), one is aimed at the
  wrong defect (hardware-matrix has no aarch64 `ahcid`/`ided` rows to be wrong; the real gap is a
  missing `Arch` column), and the ledger's own driver evidence cited `src/base-drivers/*` — a path
  `git log --all` shows was never versioned, which is precisely the error it charges
  `hardware-matrix` with. A dated second update note records all of it; the withdrawn i18n finding
  is struck in place and re-argued on its real merits (retrofit cost, not rule violation).
  **Verified:** every claim re-checked against `main` before editing — `grep` on CLAUDE.md (rc=1),
  `git log` dates for both files, `ls keys/`, `git grep verify_manifest`, `git ls-files release/`
  (empty), `config/desktop.toml` + `config/desktop-minimal.toml` for the session, and exact line
  numbers re-derived with `grep -n` (the audit's `install.md:52` was off by one — the accounts
  bullet was `:53`). `integrity`, `pin-check` and a `docs-currency` simulation PASS; `bash -n`
  clean on both touched publish scripts. **Not covered here:** the "COSMIC desktop" overclaim
  (done separately in `U-127`) and the
  usbnetd contradiction, which turns on `git merge-base --is-ancestor a3a98fd4 d6336419` in the
  `eos-base` fork and cannot be settled from this host.
- `[U-125]` **`integrity` gate: stop scanning 15 GB of vendored upstream Rust and calling it "our own
  sources"** — the R-F01 guard in `scripts/ci-integrity.sh` used `grep -rInE … --include='*.rs' .`,
  which walks the **gitignored** `prefix/` (the vendored upstream Rust stdlib) and `build/` (host
  build outputs) as well as the repo. Consequence: any working tree that had ever been built failed
  the gate — on this host it reported two upstream `stdarch` doc-examples that mention "password"
  and two `build/hostbuild-eos-control` usage strings — while CI stayed green, because a fresh clone
  has neither directory. A gate that is permanently red locally and green in CI is a gate nobody
  reads, which is precisely how a real hit would slip through. Replaced with `git grep … -- '*.rs'`
  (tracked files only), which is what the guard's own comment already claimed to check — fork
  sources land in the gitignored `recipes/*/source` and are gated by their own repos' CI, so no
  enforced coverage is lost; local behaviour now equals CI behaviour. **Verified:** gate PASSes on
  the clean tree in **0.42 s** (previously a full walk of a 24 GB tree); negative test — a planted
  `println!("password is {}", 1)` in a tracked file is still caught and reported with `file:line`,
  and the gate returns to PASS once removed.
- `[U-124]` **the U-114 outage was never data loss — the build caches were in named volumes all
  along, and the recovery script would have orphaned them** — investigating the "container is
  gone" state on the `eos-heavy` mac turned up a container called **`ec-build`** (not `eosbuild`,
  which is why every heavy job reported *no container with name or ID "eosbuild" found*), and
  more importantly that the build state lives in two persistent podman **named volumes**:
  `eos-work:/work` (28 GB — the tree, `build/`, `prefix/` for both arches) and `eos-root:/root`
  (8.7 GB — the pinned toolchain + `~/.cargo` caches). `podman rm` never touches those, so the
  ~37 GB survived the whole three-week freeze untouched. **The real defect was in the fix:**
  `scripts/eos-container-setup.sh` (U-123) created its container **without** those volumes, so
  running the documented recovery would have silently orphaned every cache and turned the next
  build into a from-scratch multi-hour run — while its `--recreate` help text simultaneously
  claimed to destroy caches it could not reach. `ec-build` was also missing `--device /dev/fuse`,
  `PODMAN_BUILD=0` and the `/root/.cargo/bin` PATH, i.e. it could exec and compile but never
  assemble a RedoxFS image. Now: the script mounts both volumes (creating them on demand, so a
  first run and a post-outage recovery take the identical path), `--recreate` rebuilds the
  container and **keeps** the caches, a new `--wipe-caches` is the explicit opt-in for the
  expensive path, the `rustinstall.sh` step is skipped when `eos-root` already carries the
  toolchain, and the run ends with a sanity check that `/dev/fuse` is present and `/work/redox`
  is non-empty. Also `scripts/eos-check.sh` — verification gate 1 — was **unrunnable on the
  primary dev host**: `${ARCH^^}` is a bash 4 expansion evaluated host-side, and macOS ships only
  `/bin/bash` 3.2, so it died with `bad substitution` before reaching the container; replaced with
  a `tr` uppercase. `docs/ci.md` gains the volume table, the orphaning trap, the two flags, and a
  note that the runner host now keeps its podman machine in an APFS sparsebundle on an external
  exFAT drive (which must be mounted before `podman machine start`). **Verified on the runner
  host:** `eosbuild` rebuilt with the correct flags against the existing volumes; gate 1
  (`cargo check -p virtio-core`) PASSes for **both** `aarch64-unknown-redox` (5.91 s cold cache
  entry, 0.06 s warm) and `x86_64-unknown-redox` (3.14 s), proving the caches are live and the
  bash fix works on the stock 3.2 shell; `--recreate` completed in 11 s with `podman volume ls`
  showing `eos-work`/`eos-root` still present and `du -sh /work/redox` still 28 GB afterwards;
  unknown-flag branch exits 2. The two `scripts/pin-allowlist.txt` holds stay in place — their
  bump needs the full image build + boot-smoke, which is now *possible* but has not been run.
- `[U-123]` **ops: the `eosbuild` container finally has a written way back** — the persistent build
  container's creation was tribal knowledge: when the podman machine on the `eos-heavy` mac was
  recreated and the container vanished (the outage behind U-114), there was **no documented
  procedure** to rebuild it. New idempotent `scripts/eos-container-setup.sh`: podman machine
  (init+start, with a pointer at the macOS Privacy & Security VM-helper approvals that can block it) →
  `redox-base` image from `podman/redox-base-containerfile` → persistent container with the exact
  `mk/podman.mk` flags (`SYS_ADMIN`+`/dev/fuse` for RedoxFS, `--network=host`, no bind mount — the
  tree lives inside because macOS virtiofs can't serve cargo's mmap reads) → **pinned** toolchain via
  `rustinstall.sh` (U-118) → seeded `/work/redox`; `--recreate` is the explicit cache-destroying
  variant. Documented in docs/ci.md next to the runner-recovery context. **Verified:** `bash -n`
  clean; every flag traced to `mk/podman.mk`/`docs/ci.md`/`build-troubleshooting.md`; the inner
  toolchain step is the U-118 script already proven end-to-end in a clean container. The full script
  can only truly run on the mac runner host — that run (and the first build after it) is the
  documented next step, not claimed here.
- `[U-122]` **docs(hardening): the supply-chain gates get their reference section** — the U-118/U-120
  work existed only in the CHANGELOG and the audit page; `docs/hardening.md` (the doc a security
  reader actually consults) now has a "Supply-chain gates" table: every binary the build fetches, the
  file that verifies it, the failure behaviour, and the two deliberate residual gaps (u-boot blobs,
  `--network=host`). **Verified:** docs-only; every row cross-checked against the shipped U-118–U-120
  implementations.
- `[U-121]` **mirror hygiene: the stray ImgBot work is merged, the divergent branch retired** — the
  GitHub-side `imgbot` branch carried a bot commit (`fede77a`, 2026-07-23) that existed **only on the
  mirror** — a mirror with a unique commit is no longer a mirror, and a forced mirror-push would have
  erased the work. The commit (46 files: lossless image optimization, `-170` lines of SVG minification,
  PNG recompression incl. `dosbox/icon.png` 118→68 KB) was **cherry-picked into `main` via GitLab**
  (`18d0a3b`, ImgBot authorship preserved), its GitHub PR #16 closed with a pointer, and the stale
  `imgbot` branches deleted on **both** hosts (the GitLab one was an older, different bot commit
  `0bb3989` — superseded). **Verified:** all 41 PNGs re-opened and dimension-compared byte-for-byte
  against pre-merge `main` (identical sizes/modes, files load), all 5 minified SVGs XML-parse; nothing
  the docs/README embed changed dimensions.
- `[U-120]` **unsigned publish is now an explicit opt-in, not a silent default (audit §4 item 4) + gitleaks
  config review** — all three release/publish paths (`publish-repo-pages.sh` — public Pages hosting,
  `publish-repo.sh` — release artifact staging, `make-release.sh` — SHA256SUMS/minisign) used to
  *warn-and-continue* when the signing-key env var was missing, so one forgotten variable published an
  unsigned, MITM-swappable index to the internet. Now a missing key **hard-fails with instructions**;
  dev flows that genuinely want an unsigned artifact must say `EOS_ALLOW_UNSIGNED=1` out loud. Also
  `.gitleaks.toml`: the dead `regexTarget` key (no `regexes` defined — pure noise) is gone and every
  allowlist entry now carries its justification inline, incl. the accepted `Cargo.lock` blind spot
  (registry-checksum false-positives) explicitly compensated by the weekly guardian's tree-wide
  credential grep. Audit page §3/§4 statuses updated to match. **Verified:** all three gate branches
  (key set / unset / unset+opt-in) exercised standalone; `bash -n` clean on every touched script; the
  CI `secret-scan` job re-validates the gitleaks config on this very push.
- `[U-119]` **eos-repo-sign: keygen can no longer leak or clobber the repo-signing key (audit §4 item 6)** —
  `keygen` previously wrote the SECRET key with the default umask (usually world-readable 0644 on Unix)
  and silently overwrote an existing key file — silent rotation would strand every client pinning the
  old public key. Now: a new `write_new_key_file` helper creates the secret with **`0600` from the
  first byte** (`OpenOptionsExt::mode` — the file never transits a world-readable state) and both
  files use **`create_new`** (atomic no-clobber, no TOCTOU window); an existing path dies with an
  explicit "move it away first if you really mean to rotate" message *before* any key material is
  generated. `tools/eos-repo-sign/README.md` updated to describe the behaviour. **Verified:** new
  regression test (`write_new_key_file_refuses_clobber_and_restricts_mode` — asserts AlreadyExists on
  the second write, content intact, and mode==0600 on Unix) + the existing 8 tests: 9/9 green with
  `cargo fmt --check` and `clippy -D warnings` clean, run in a **CI-identical `rust:slim` container**
  (the light tier re-verifies on push).
- `[U-118]` **supply-chain: every fetched build binary is now SHA256-pinned (audit §4 items 1–3)** —
  the compilers and helper tools that build the whole OS no longer rest on TLS alone. (1) **Prebuilt
  Redox toolchain** (`mk/prefix.mk`, default `PREFIX_BINARY=1`): a new manifest `mk/fetch-sha256.txt`
  pins all **12** host×target×archive combos (~1.5 GB stream-hashed); the download rule hard-fails on a
  pin mismatch (partial deleted, clear "refreshed upstream vs tampered" message), warns on unpinned
  combos, and `EOS_STRICT_FETCH=1` upgrades the warning to a failure — so exotic combos can't brick and
  an upstream toolchain refresh turns into a *loud, reviewable* re-pin instead of a silent swap. The
  experimental `PREFIX_USE_UPSTREAM_RUST_COMPILER` path now verifies all four rust-dist tarballs
  against Rust's published `.sha256` sidecars (canned `verify_rust_dist` recipe). (2) **Container
  bootstrap** (`podman/rustinstall.sh`): the classic `curl https://sh.rustup.rs | sh` is **gone** —
  rustup installs from a *versioned* `rustup-init 1.29.0` (immutable archive path; found and fixed en
  route: rustup-init is a multicall binary that dispatches on argv[0], so it must run under its real
  name, not a mktemp one), and `sccache`/`just`/`cbindgen` are pinned for **both** container arches;
  nothing untrusted is ever piped straight into `tar` or `sh` (download → verify → use). (3) **CI
  helpers** (`.gitlab-ci.yml`): `cargo-deny` (itself a security gate!), `mdbook` and `mdbook-mermaid`
  switch from `curl | tar xz` to download-verify-extract with pins beside the version vars.
  **Verified, not assumed:** the prefix.mk gate ran **live** in a container — a real 94 MB download
  passed (independently re-producing the pinned hash), a deliberately corrupted pin was **refused**
  (`make: *** Error 1`, partial deleted); all four gate branches unit-tested; `rustinstall.sh` ran
  **end-to-end** in a clean Debian container (4/4 pins OK → working `rustc 1.97.1`, `cbindgen 0.29.0`,
  `just 1.50.0`, `sccache 0.15.0`); rustup-init pins cross-checked against Rust's published sidecar
  hashes (exact match); `.gitlab-ci.yml` YAML-validated; the full Makefile parses (`make -n` dry-runs
  print the exact expected shell). Residual risk stated in the manifest header: pins are a TOFU
  snapshot from one network — re-confirming from a second network is the queued follow-up.
- `[U-117]` **docs(coverage): close the "why is this here?" gaps the audit found in our own tree** —
  `patches/` gains a README stating the load-bearing fact nothing in the repo stated: the two patches
  are **reference copies** of branding diffs whose real life is commits in the forks — *nothing applies
  them at build time* (and `ci-boot-smoke.sh` depends on the `eos login:` string one of them introduces).
  `recipes/gui/orbdata/recipe.toml` — the only fork pin of 27 with no provenance comment — now says it's
  a *modified* branding fork, not a mirror. `ARCHITECTURE.md` gains the meta-repo map a newcomer needed:
  `src/` is the **vendored upstream `redox_cookbook`** (no E-OS changes → §3 doc rules don't apply),
  plus what `recipes/ · patches/ · tools/ · mk/ · scripts/` each are. `tools/eos-repo-sign` gains its
  per-component README (CLAUDE.md §2): what/why of the hybrid ed25519+ML-DSA-65 signing, usage, and the
  key-handling sharp edges (keep the secret key off-tree; `keygen`'s umask/no-clobber issue is queued).
  **Verified:** docs-only; every stated fact cross-checked against the tree (grep: no build reference to
  `patches/`; `src/` grep shows zero E-OS markers).
- `[U-116]` **docs(claude): CLAUDE.md re-synced with reality (its own "keep this file honest" rule)** —
  the working agreement drifted from the repo in ways that would misdirect the next session: (1) §1.6/§5
  said "push GitLab AND GitHub" while docs/MAINTENANCE.md says **never dual-push** — resolved with the
  precise model, *proven live today*: the meta repo's GitLab→GitHub push-mirror replicated `U-114` in
  seconds and the manual GitHub push lost the race (`cannot lock ref`); forks still need dual-push until
  `eos-setup-mirrors.sh --apply` runs. (2) §5 named a nonexistent job — the gate is **`pin-check`**
  (which *runs* `pins --strict`) plus the omitted `integrity`; also recorded the U-114 lesson that a red
  `verify` stage silently freezes `pages`. (3) §3 "forks build overflow-checks" narrowed to the true
  scope (kernel/base/relibc + app crates per docs/hardening.md). (4) §6 ideas updated: docs-PDF and
  ARCHITECTURE.md are *done* (the PDF deliberately via `print.html`+Chromium, not the mdbook-PDF
  plugin), doc-coverage advisory is live in `docs-currency`. (5) Added the two policies a session must
  know: **upstream Redox does not accept LLM-generated contributions** (CONTRIBUTING.md) — AI-assisted
  work stays in the E-OS forks; and DCO/AGPL-3.0-or-later/dormant semantic-release+Renovate facts.
  **Verified:** every corrected claim checked against `.gitlab-ci.yml`, lefthook.yml, docs/hardening.md,
  docs/MAINTENANCE.md, CONTRIBUTING.md and today's push race.
- `[U-115]` **docs: the great re-sync — README/ROADMAP/ecosystem/forks caught up 33 entries; screenshots
  finally render on the docs site** — the 2026-08-14 six-auditor audit (see
  [docs/audit/AUDIT-2026-08-14.md](docs/audit/AUDIT-2026-08-14.md), new page, listed in SUMMARY along
  with the previously-orphaned 2026-07-13 audit) found the public story frozen at `U-080`/13 Jul while
  the code reached `U-113`/24 Jul. Fixed: **README** — SYNC header current; Highlights gain the whole
  native wave (eos-control · eos-notes+eos-ui · eos-guard · eos-sysmon · NetSurf-as-PIE browsing ·
  graphical OOBE · tray/toasts/screenshot/launcher-search); `usbnetd` claim made honest (TX ✓, RX
  broken — R-901); CI/Quality + Security sections now describe the *live* two-tier GitLab CI instead of
  "dead Actions + local scans"; Components table completed (eos-bootloader + the native apps).
  **ROADMAP** — R-0xx intro rewritten (the "every pipeline is inert" framing is history per
  reality-ledger); `R-001`/`R-004`/`R-006`/`R-007` closed with evidence (R-007 finished today: the 3
  `github_actions/*` Dependabot PRs targeting the deleted workflow were closed on the mirror);
  `R-1004`/`R-303` point at GitLab Pages + the real remaining infra (restore `eosbuild`).
  **docs/ecosystem.md** — no longer lies about being generated; the hand-copied hash column (21/22
  stale!) is **gone** — revs live only in `repos.toml`; the 5 missing native-app repos added.
  **docs/forks.md** — the 5 forks carrying E-OS commits (redoxfs · orbutils · pkgar · pkgutils ·
  installer) moved out of "pure mirrors" so nobody fast-forwards over our work.
  **Screenshots:** embeds used `../assets/…`, which mdBook can't ship — the published site 404'd every
  image. New `docs/img/` holds web-optimized copies (16 shots, 1100px/256-colour PNG: **740 KB total vs
  16 MB** originals; provenance + regen recipe in docs/img/README.md), a new
  [visual tour](docs/screenshots.md) page embeds them all, and install/known-issues embeds are fixed.
  **book.toml** edit-links now target GitLab (the mirror is read-only). `EOS_BUILD_STATE.md` no longer
  names the host user account. **Verified:** every corrected status traced to its CHANGELOG/audit
  evidence; image paths resolve inside `docs/`; findings adversarially re-verified by a second agent
  pass before editing.
- `[U-114]` **ci(pins): un-redden the daily pipeline — record the two R-902 pin holds as deliberate** —
  every scheduled pipeline on `main` had been failing since late July: `pin-check` (hard-fail, `verify`
  stage) flagged `eos-control` (`5a0c6d3 → 40dc67f`, DHCP↔static toggle) and `eos-installer`
  (`f9d82a1 → ed6eb7c`, installer network pane) as `DRIFT (recipe behind fork)`, and the failed `verify`
  stage **skipped `rust-checks` and `pages`** — freezing the published docs site into staleness as a
  side effect. Both drifted tips are **feature** commits (the R-902 network work), so per the
  Definition-of-Done a pin bump needs the full gate run (image build + `ci-boot-smoke`) — currently
  impossible because the `eosbuild` podman container on the `eos-heavy` (mac) runner **no longer
  exists** (`build-image`/`docs-pdf` traces: *"no container with name or ID \"eosbuild\" found"*).
  Fix, per `pin-allowlist.txt`'s own contract for unverified fork tips: both repos are allowlisted
  with reasons + a removal condition (bump the pins and drop the lines once the build container is
  restored). Also: `.gitignore` gains `._*` (macOS AppleDouble sidecars — the tree was carried through
  Finder onto exFAT, which sprayed ~7 000 of them). **Verified:** `bash scripts/eos-repos.sh pins
  --strict` logic re-checked against the allowlist parser (first-token match); remote audit of all
  30 `repos.toml` repos confirms GitLab↔GitHub branches/tags in sync and the other 24 pins `OK(tip)`.
  Restoring `eosbuild` on the mac (re-run `podman_bootstrap.sh` or recreate the container) is the
  remaining infra to-do to turn `build-image`/`docs-pdf` green again.
- `[U-113]` **eos-control: render-verify of the Sieć tab surfaced (and fixed) a real on-device gap (`R-902`)** —
  eos-control `9e95c32 → 5a0c6d3`. Driving the built aarch64 image in QEMU (ramfb + QMP mouse) through the
  **full desktop** — crimson greeter → first-boot OOBE (set/confirm password) → desktop → launch
  eos-control → **Sieć tab** — render-verified the read side (tiles: `eth0 · 10.0.2.15 · 255.255.255.0 ·
  gw 10.0.2.2 · DNS 9.9.9.9 · stos aktywny`, static editor pre-filled) **and** the whole static-apply
  flow (edit IP → *Zastosuj* arms → password field → *Potwierdź* → `eos-netcfg` elevates via sudo and
  exits 0 → **"Zastosowano konfigurację sieci."**). But the applied IP **didn't reflect** in the tile —
  runtime truth the source-review + host `--selftest` could not catch. **Root cause, confirmed on-device**
  (a throwaway init.d serial probe + `ls /scheme` in the user session): the desktop user's **orbital
  session namespace has no `netcfg:` scheme** — it has the `ip`/`tcp`/`udp` sockets but not the privileged
  network *config* scheme — so **every `sys::net()` read of `/scheme/netcfg/*` fails for the GUI and it
  silently falls back to `/etc/net/*`** (proven: the pre-apply DNS tile showed the file's `9.9.9.9`, while
  a root `cat` of the live `netcfg:` `resolv/nameserver` returned the DHCP-set `10.0.2.3`). The live apply,
  which runs as **root** in the `eos-netcfg` shim and *does* have `netcfg:`, changed the running stack but
  not the files the GUI reads. **Two fixes:** (1) `read_netcfg` now uses `File::open` + a manual `read()`
  loop instead of `std::fs::read_to_string` (`read_to_end`'s size-hinted path also errors on scheme files;
  `cat`'s plain loop works) — correct, though moot for the GUI since the open itself fails in the
  namespace; (2) **`eos-netcfg` now also writes `/etc/net/{ip,ip_subnet,ip_router,dns}`** after the live
  scheme writes — so an apply is **visible to the user-session GUI** (which reads those files) **and
  persists across reboot** (a bonus the netcfg-only writes lacked). Doc-comments in `sys.rs`/`netcfg.rs`
  corrected to state the namespace reality. Host build + `EOS-CONTROL-SELFTEST-OK`; rustfmt clean; the
  fix cross-compiled + cooked into the image. **Re-verified on-screen, end-to-end:** on the rebuilt image,
  editing the Sieć tab's IP to `10.0.2.50` and confirming with the password **flipped the "Adres IP" tile
  from `10.0.2.15` → `10.0.2.50`** — `eos-netcfg` wrote `/etc/net/ip` and the GUI's refresh read it back,
  the exact reflection missing before the fix (`assets/screenshots/`). (Asides the re-verify established:
  `eos-netcfg` from a root boot-probe returns non-zero — its elevation is correctly gated to a sudo-group
  user with a password, not root-at-boot; and the greeter accepts scripted input only when the password
  field holds initial focus, which varied boot-to-boot.) `R-902` stays 🚧 for the remaining DHCP toggle +
  installer panes.
- `[U-112]` **eos-control: Network settings pane — live netcfg read + static apply (`R-902`)** —
  eos-control `a76d0587 → 9e95c32`. The **"Sieć"** tab becomes a real settings pane. **Read side**
  now prefers the **live `netcfg:` scheme** smolnetd serves (was: only the persistent `/etc/net/*`
  files): interface + IPv4 from `ifaces/<if>/addr/list` (`10.0.2.15/24` → ip + derived netmask), the
  default-route gateway from the `default … via <ip>` line of `route/list`, the resolver from
  `resolv/nameserver`, and the MAC from `ifaces/<if>/mac`; each falls back to the matching `/etc/net/*`
  file (and to empty on a host), and smolnetd's placeholders (`Not configured` / `Device not found`)
  are mapped to "unknown" so they can't masquerade as a value. **Write side** applies a **static**
  IPv4 config live. The one hard constraint (recon'd from the smolnetd `netcfg` source): its `write()`
  **rejects any caller whose uid isn't 0** with `EACCES`, and eos-control runs as the desktop user — so
  the change goes through a new privileged **`eos-netcfg`** shim, the same never-run-the-GUI-as-root
  model as `eos-power` (U-109): elevate via `/scheme/sudo`, then write `ifaces/<if>/addr/set` (the
  `IpCidr`) → `route/rm 0.0.0.0/0` + `route/add default via <gw>` → `resolv/nameserver`, **in that
  order** so the gateway is on-link. The sudo→procfd→setns handshake is **factored into a shared
  `src/elevate.rs`** used by both shims (CLAUDE.md §6, shared code over copies), leaving `eos-power`
  behaviour-identical. The GUI reveals a **password field** on a two-step confirm and pipes the
  password on the shim's **stdin** (never argv); `sys::apply_static` validates IP/prefix/gateway/DNS
  **before** spawning, so a bad field is a clear message, not a half-write. `--selftest` gains an
  expanded `net_core`: it exercises every pure helper (`parse_addr_list`, `prefix_to_netmask` ↔
  `netmask_to_prefix`, `valid_ipv4`/`valid_prefix`, `parse_default_gateway`) and the read path, and
  asserts `apply_static` **rejects** bad input; the setter is only *referenced* (a valid-input call
  would reconfigure the live network mid-boot), like `power_core`/`audio_core`. **Verified:** contract
  checked against the smolnetd source (`cfg_node!` tree + `route_table` `Display`), not guessed; host
  build (`--no-default-features`) + `EOS-CONTROL-SELFTEST-OK`; rustfmt clean. **Cross-compile + integrate
  + boot proven locally (2026-07-24):** a full aarch64 image was cooked on the native-fs build path
  (podman named volume, dodging the virtiofs↔mmap blocker — cook needs `CI=1` to skip the headless-TTY
  panic, `R-103`), during which **eos-control@`9e95c32` cross-compiled for `aarch64-unknown-redox`** (slint
  + eos-ui + rusqlite + blake3 + `redox_syscall 0.9`/`libredox 0.1.18`) and installed all three bins —
  **`eos-control` + `eos-netcfg` + `eos-power`** — into the image; the resulting `harddrive.img`
  **boot-smoke PASSed** (reached `eos login:`) under QEMU-aarch64 on the host. Still deferred: the
  **interactive live-apply render** (boot to desktop → Sieć tab → type a static IP → confirm with the
  password → watch the tiles update) — boot-smoke proves the image boots, not that path; the apply is
  **not** HW-blocked (wired networking works on the QEMU loop, `R-D10`), so it is provable on this image.
  `R-902` stays 🚧 — the persistent DHCP/static toggle (`dhcpd` lifecycle + `/etc/net/*`) and the
  installer front-ends remain, tracked as the follow-up. Design: `docs/design-eos-control-network.md`.
- `[U-111]` **build: fix the Podman container build for repo paths containing a space** — `mk/podman.mk`.
  The repo lives at `.../Moje Projekty/E-OS` (a space in "Moje Projekty"). `PODMAN_VOLUMES` and the
  `mkdir -p $(PODMAN_HOME)` in the `build/container.tag` rule interpolated `$(ROOT)` **unquoted**, so
  the shell word-split `--volume /Users/.../Moje Projekty/E-OS:/mnt/redox:Z` into separate tokens →
  `podman build`/`podman run` got stray positional args and died (`Error: accepts at most 1 arg(s),
  received 2` / `invalid reference format`). Worse, the rule ran `podman image rm --force redox-base`
  **before** the (now-failing) build, so it deleted the working image and couldn't rebuild it. Fix:
  **quote the mount specs** in `PODMAN_VOLUMES` (covers both `PODMAN_RUN` and the `container.tag`
  `podman build`) and the `mkdir`/`rm -rf` of `PODMAN_HOME`, and **drop the pre-emptive `podman image
  rm`** (`podman build --tag` replaces the tag on success, so a failed build can no longer leave the
  machine image-less). Verified with `make -n ARCH=aarch64 CONFIG_NAME=eos build/container.tag` +
  `… env`: every mount now emits quoted, e.g. `--volume "/Users/.../Moje Projekty/E-OS:/mnt/redox:Z"`.
  Build-neutral (no image/recipe change); unblocks building from a space-bearing path.
- `[U-110]` **eos-control: Sound tab (master volume via audiod's `audio:volume`) — `R-D07` mixer half** —
  eos-control `aa9029a → a76d0587`. Adds a **"Dźwięk"** tab. audiod serves the `audio:` scheme; its
  **`audio:volume`** control is a plain decimal `0–100` read/written as a file, so `sys::audio()` reads
  it and `sys::set_volume()` writes the slider value back (a **mute** button sets 0 and restores the
  remembered level — audiod has no mute flag). audiod only serves `audio:` once an `audiohw:` driver is
  up, so the tab **detects an absent stack** (the open fails → `available = false`) and shows an honest
  **"Audio niedostępne"** explanation rather than a slider that controls nothing. The interface was
  recon'd from the audiod source (`scheme.rs` `Volume` handle: read → `{volume}`, write parses + clamps
  `0..=100`). `--selftest` gains `audio_core` — it exercises the pure `clamp_volume` / `parse_volume`
  helpers + the read path but only *references* `set_volume` (writing would move the live level
  mid-boot), like `power_core`; host `EOS-CONTROL-SELFTEST-OK`. **Honest gap (see
  `docs/known-issues.md` + ROADMAP `R-D07`):** on the aarch64/QEMU loop there is **no audio** — `ihdad`
  binds the QEMU Intel-HDA controller but times out on the codec **RIRB** response, so audiod exits and
  `audio:` never appears (proven by serial). So the end-to-end volume change is **provable only on real
  HDA hardware**, and the tab is designed to render its honest "unavailable" state there. The read/write
  contract is verified against the audiod source; the **gui cross-compile + boot are gated by the
  heavy CI `build-image` job** (this pin bump triggers it). **Local render-verify of the tab is
  deferred** — this build host has no cooked tree, so a screendump needs a full from-scratch OS build;
  noted honestly rather than claimed. rustfmt clean; host build + `--selftest` green.
- `[U-109]` **eos-control: power actions now WORK — `eos-power` shim + password dialog (`R-D11` ✅)** —
  eos-control `2c043b4 → aa9029a`. Completes U-108: reboot/shutdown from the GUI now actually take the
  machine down. The control `sys:kstop` is root-only and the GUI runs as the desktop user (whose
  password is **not** empty — first-boot sets it), so there was no shortcut. Done properly: a new
  **`eos-power`** bin elevates the way `sudo` does *internally* — open `/scheme/sudo`, write the
  password (the daemon checks sudo-group + the password), elevate our own procfd (`call_wo` +
  `CallFlags::FD`), `setns`, then write `sys:kstop`. The **GUI never runs as root**: it spawns
  `eos-power` and pipes the user's password to its **stdin** (so no TTY-password problem), and waits —
  Ok = authenticated + `sys:kstop` written (machine going down), Err = bad password / no permission.
  The Zasilanie tab now reveals a **password field** (`input-type: password`) once an action is armed.
  Deps for the elevation: `libredox 0.1.18 +mkns`, `redox_syscall 0.9`, the `redox_cur_procfd_v0`
  relibc hook. **Verified end-to-end (boot + click):** arming *Wyłącz*, typing the password, and
  confirming **powered the VM off — the QEMU process exited** (`assets/screenshots/eos-control-power.png`
  shows the password dialog). `--selftest` still only *references* the power fns (never invokes them);
  host `EOS-CONTROL-SELFTEST-OK`. Two bins now (eos-control + eos-power); `default-run = eos-control`.
- `[U-108]` **eos-control: Power tab (reboot / shutdown) — UI done, action needs privilege (partial)**
  — eos-control `847220c → 2c043b4`. Adds a **"Zasilanie"** tab: *Uruchom ponownie* / *Wyłącz*, each a
  **two-step confirm** (arm → "⚠ Potwierdź…", plus *Anuluj*) so a stray click can't take the machine
  down. **Verified working:** the tab renders and the two-step confirm behaves (screendumps). **Known
  limitation (honest):** the reboot/shutdown *mechanism* is `sys:kstop`, which is **root-only** —
  eos-control runs as the desktop user, so a direct write is EPERM, and elevating via `sudo` from a GUI
  fails because sudo reads its password from a **TTY the GUI process doesn't have**. So under QEMU the
  buttons don't actually reboot/poweroff; they now report **honestly** ("Wysłano żądanie… jeśli system
  nie zareaguje, w terminalu: `sudo shutdown [-r]`") instead of a false "rebooting". The mechanism
  itself is proven — **root `shutdown -r` does trigger a restart** (serial shows UEFI running again;
  note a separate EDK2 warm-reboot firmware flake under QEMU-aarch64). A real in-GUI power action needs
  a small **privileged helper**; tracked as `R-D11`. `--selftest` gains `power_core` (references the
  functions only — it runs during boot and must never invoke them); host `EOS-CONTROL-SELFTEST-OK`.
  Screendump: `assets/screenshots/eos-control-power.png`.
- `[U-107]` **eos-control: Storage tab (root filesystem usage via `statvfs`)** — eos-control
  `301e054 → 847220c`. Adds a **"Dyski"** tab showing the root filesystem's **capacity / used / free /
  use-%**. `sys::storage()` reads it via `statvfs`: on E-OS through **`libredox::call::fstatvfs`**
  (redoxfs answers with real block counts — `f_blocks`, `f_bavail`), on a host through POSIX
  `statvfs(2)`; cross-platform and never panics (a failed query → all-zero → the tab shows "—"). The
  `--selftest` gains `storage_core` (self-consistency: free ≤ total; tolerant of an unsupported
  statvfs). Sibling of the Network tab, same Tile pattern. Verified: slint UI + Rust cross-compile
  for aarch64-redox (`cook eos-control - successful`); host `--selftest` prints
  `EOS-CONTROL-SELFTEST-OK`; aarch64 image cooked; **render-verified** — the Dyski tab reads the live
  redoxfs: **Pojemność 1.4 GB · Zajęte 436.8 MB · Wolne 960.2 MB · Wykorzystanie 31 %** (the 1.4 GB
  matches `filesystem_size = 1400`; `assets/screenshots/eos-control-storage.png`).
- `[U-106]` **eos-control: Network tab (live `/etc/net` config + stack status)** — eos-control
  `7729720 → 301e054`. Adds a **"Sieć"** tab to the control panel showing the current network
  configuration read from the files the base image ships (dhcpd keeps them current): **IP**
  (`/etc/net/ip`), **gateway** (`/etc/net/ip_router`), **DNS** (`/etc/net/dns`), **subnet mask**
  (`/etc/net/ip_subnet`), plus a **stack-up** indicator derived by probing the scheme list for `ip`
  (netstack/smolnetd). `sys::net()` is plain file/dir reads — identical on E-OS and host (a host has
  no `/etc/net`, so fields degrade to empty and the stack reads "brak"); it never panics. The
  `--selftest` gains `net_core` (tolerant on a host without `/etc/net`). Directly reuses the R-D10
  investigation (the exact `/etc/net` paths + scheme names). Verified: slint UI + Rust cross-compile
  for aarch64-redox (`cook eos-control - successful`); host `--selftest` prints
  `EOS-CONTROL-SELFTEST-OK`; aarch64 image cooked from the new pin; **render-verified** — launching
  E-OS Control and opening the Sieć tab shows **IP 10.0.2.15 · Brama 10.0.2.2 · DNS 9.9.9.9 · Maska
  255.255.255.0 · Stos sieciowy: aktywny** (`assets/screenshots/eos-control-network.png`).
- `[U-105]` **netsurf: local default homepage + click-to-launch verified** — meta-repo only
  (`recipes/web/netsurf/recipe.toml`, `docs/design-netsurf-pie.md`). Verified the **real desktop
  path**: clicking the Netsurf icon on the launcher bar opens the browser (not just a shell launch) —
  no crash, window renders. But the Redox netsurf config **overrode netsurf's own `about:welcome`
  default with `https://www.redox-os.org/`**, and Redox networking (DNS/TLS/netstack) is not
  functional here yet, so a click-launch landed on a **blank white page**. A `sed` in the recipe
  restores the local `about:welcome` default (netsurf's `Makefile.config` override → `about:welcome`),
  so clicking Netsurf now renders the welcome page immediately. **Verified (boot + click-launch +
  screendump):** the bar icon opens netsurf to the local welcome page in full — nav links, headings,
  a search box, the link grid (`assets/screenshots/eos-netsurf-welcome.png`, now a clean shot).
  Web browsing over the network is a separate, larger effort tracked as `R-D10`.
- `[U-104]` **netsurf: fix the first-render crash — the browser renders now (`R-D06` ✅)** — meta-repo
  only (`recipes/web/netsurf/recipe.toml`, `docs/design-netsurf-pie.md`). After U-103 the PIE netsurf
  loaded and opened a window, but the body stayed black and it crashed on the first content render — a
  **use-after-munmap of the 800×600×4 window buffer** (`funmap length 0x1d4c00` = 1,920,000 = 800·600·4
  was the tell; fault `FAR` offset `0xf83` = near the top-left of that buffer). Chain, read from source:
  libnsfb (`surface/sdl.c`) caches `nsfb->ptr = SDL surface pixels`; the Redox SDL orbital driver backs
  that with `orb_window_data()` (orbclient's mmap of the window); a `SDL_RESIZABLE` window makes
  orbclient's `Window::events()` `unmap`+`remap` that buffer on the resize event orbital sends on first
  map — invalidating the pointer libnsfb still holds → netsurf's first plot writes into freed memory.
  Fix: a `sed` in the recipe drops `SDL_RESIZABLE` from libnsfb's two `SDL_SetVideoMode` sites, so
  orbclient's `resizable` stays false and the buffer is never remapped out from under `nsfb->ptr`.
  **Verified (boot + screendump):** netsurf renders `welcome.html` in full — toolbar, address bar, the
  NetSurf logo image, headings, links, a search box (`assets/screenshots/eos-netsurf-welcome.png`); the
  serial no longer logs an `UNHANDLED EXCEPTION` for `netsurf-fb`. Trade-off: the window is fixed-size
  for now (proper resize = libnsfb re-fetching the pointer after each remap; tracked as `R-D07`).
- `[U-103]` **netsurf: build from source as a PIE (partial — `R-D06`)** — meta-repo only
  (`recipes/web/netsurf/recipe.toml`, `scripts/redoxer-host-stub.sh`, `docs/design-netsurf-pie.md`).
  The browser died the instant it was clicked (data abort, `ESR 0x92000047`): the image shipped the
  **upstream non-PIE `ET_EXEC` prebuilt** (pulled by `--repo-binary`), and aarch64-Redox only loads PIEs.
  A from-source build was itself blocked because `host:gperf` builds via `cookbook_redoxer`, whose
  `toolchain()` tried to **download a host→host relibc toolchain that redox never publishes → 404**
  (`unable to init toolchain`). Fixes: **(1)** `scripts/redoxer-host-stub.sh` pre-creates the per-target
  `~/.redoxer/<host>/toolchain` stub so redoxer skips the misfired download (host builds use system
  `gcc`/`g++`); it never touches the real cross toolchain. **(2)** a **CC-wrapper** in the recipe forces
  `-fPIC` on every compile and `-pie` on the final link. Verified: `host:gperf` + `cook netsurf` now build
  from source; `netsurf-fb` is a `DYN`/`pie executable` (`readelf`/`file`) both staged and inside the
  image; with the recipe now differing from upstream, `--repo-binary` no longer re-downloads the prebuilt
  (local pkgar stays byte-identical). **Runtime: partial** — the PIE `netsurf-fb` now *loads, runs and
  opens an 800×600 window* on the desktop (boot + screendump; the load-time crash is gone), **but** the
  window body stays black and it then crashes during the first content render — a deterministic-location
  data abort (crash `ELR` page-offset `0x718`, `FAR` offset `0xf83`). That render crash is a separate,
  deeper netsurf-on-Redox bug and stays open under `R-D06`; full analysis in `docs/design-netsurf-pie.md`.
- `[U-102]` **Notifications: a minimal daemon + client (`eos-notifyd` / `eos-notify`)** — `R-D03`
  (eos-orbutils `60c262d → 8ad7cd8`). E-OS had no way to surface "updates available" / driver events.
  Adds two launcher-crate binaries: **`eos-notifyd`** polls `/tmp/eos-notify` for a `"title\nbody"`
  message and shows it as a crimson **top-right toast** (orbclient, `WindowFlag::Front`, rounded panel +
  accent bar, ~4 s auto-dismiss); **`eos-notify <title> [body]`** writes that file. The launcher spawns
  `eos-notifyd` alongside `desktop`/`background`. Deliberately **minimal** — the file transport is a
  placeholder for a proper `notify:` scheme / socket, and a toast blocks new ones while up — but enough
  for the update daemon (`R-705`) to notify. Verified: the launcher crate cross-compiles all five bins;
  both `eos-notify`/`eos-notifyd` staged to `/usr/bin`; aarch64 image cooked; **render-verified** —
  `eos-notify "Aktualizacje" "…"` popped the themed toast top-right (`assets/screenshots/eos-notify-toast.png`).
- `[U-101]` **Status tray: real icons + click-to-Settings** — first step of `R-D02` (eos-orbutils
  `7b1268b → 60c262d`). The launcher loaded `/usr/share/ui/icons/status/tray-{net,vol,set}.png`, but those
  files **never existed anywhere**, so the tray was invisible *and* a dead click target. Ship three 32-px
  crimson glyphs — a signal-bars network icon, a speaker with sound arcs, a settings gear — staged by the
  recipe to `/usr/share/icons/status` (which `/usr/share/ui/icons` symlinks to); and make a click anywhere
  on the tray open **E-OS Settings** (`draw()` records the tray's x-span, which depends on the clock-text
  width, and the bar's click handler hit-tests it). This lands the R-D02 "gear launches Settings" goal now
  that the Settings shell (`R-D01`) exists. Verified: aarch64 image cooked from the pin with the icons
  staged; **render-verified** — the bar now shows the three tray glyphs left of the clock, and clicking the
  tray opens the E-OS Settings window (`assets/screenshots/eos-tray-settings.png`). Live state reflection
  (net from netstack, a volume popup via audiod — audio is absent on the QEMU dev loop) is the R-D02 follow-up.
- `[U-100]` **Compositor screenshot — Super-P → `/home/user/screenshot-N.bmp`** (`R-D04`; eos-orbital
  `7ee7c04 → 38226c7`). E-OS had no screenshot tool, and a standalone one **can't** work: orbital is the
  DRM master, so the full composited desktop image exists only in orbital's own CPU shadow buffer — the
  capture has to live in the compositor. **Super-P** copies that shadow buffer (`Display::screenshot`) and
  writes it as an uncompressed 32-bit (BGRA) BMP via a tiny hand-rolled encoder — **no image-codec
  dependency** — with a per-shot counter so captures don't overwrite. Adds `Compositor::displays_mut` and
  a shortcuts-list entry. Verified: orbital cross-compiles for `aarch64-unknown-redox`; aarch64 image
  cooked from the pin; **render-verified end-to-end** — pressing Super-P created `/home/user/screenshot-0.bmp`
  of exactly **1,920,054 bytes** (= 54-byte header + 800×600×4), a valid BMP (magic `BM`, header 800×600),
  and the file, **extracted from the image via redoxfs and viewed**, shows the real desktop at that instant
  (icons, taskbar with the `U-098` local-time clock, and — since Super was held — the shortcuts overlay,
  which now lists the new *"Super-P: Screenshot"* entry). `assets/screenshots/eos-screenshot-selfshot.png`.
- `[U-099]` **Launcher Start-menu type-to-search — completes `R-D05`** (eos-orbutils `94dcc91 → 7b1268b`).
  Opening Start showed a fixed category list with no keyboard input. The top-level menu now carries a
  **search box**: typing filters a flat list of **every** app by name (case-insensitive) and shows a live
  **result count**; **Enter** launches the highlighted (or first) match, **Backspace** narrows, **Esc**
  closes, and an empty query restores the category view (nothing regresses). The query is fed from
  orbital **`TextInput`** events — a `Key` event carries only the scancode, which is why the first
  attempt (reading `key_event.character`) typed nothing. The Start window is created **once at a
  worst-case fixed height** and never resized or recreated, so it keeps focus (stays open while typing)
  and never clips results — resizing a live transparent window clipped later matches, and recreating it
  dropped focus and closed the menu. Verified: launcher cross-compiles for `aarch64-unknown-redox`;
  aarch64 image cooked from the pin; **render-verified** — the Start menu reads *"Szukaj: vi_
  (3 wyników)"* and shows all three matches (`GVim`, `Viewer`, `Vim`) with the menu staying open. With
  `U-098` this closes `R-D05` (search **+** local-time clock).
- `[U-098]` **Launcher clock: local date + timezone (was UTC `HH:MM` only)** — first half of `R-D05`.
  The bar clock computed `ts % 86400` straight from `CLOCK_REALTIME`, so it showed raw **UTC** with no
  date. The launcher (`eos-orbutils` `cf121dc → 94dcc91`) now reads a timezone offset (seconds east of
  UTC) from **`/etc/tz-offset`** — a distinct path from Debian's zone-*name* file — falling back to a
  numeric `TZ` env, default UTC; applies it; and renders the full local **`YYYY-MM-DD  HH:MM  UTC±H`**
  via a small Howard-Hinnant civil-from-epoch helper (no `chrono` dependency), at 1× font (the string is
  wider than the old `HH:MM`). Ships a default **`/etc/tz-offset = 7200`** (UTC+2, Poland CEST — correct
  for the current season) in `config/{aarch64,x86_64}/eos.toml`. A fixed offset has **no DST/named-zone**;
  that waits on a tz database + per-machine timezone at OOBE (`R-606`). Verified: launcher cross-compiles
  (`cargo check` for `aarch64-unknown-redox`); aarch64 image cooked from the pin + config; **render-verified**
  — captured at host **UTC 10:58**, the bar reads **`2026-07-19  12:58  UTC+2`** (exactly +2 h), fed by
  the shipped `/etc/tz-offset`. Remaining half of `R-D05`: type-to-search in the Start menu.
- `[U-097]` **E-OS Control v3 — rank processes by memory + a total-memory readout** (a task
  manager's first job is answering "what's eating my RAM?"; the list was in kernel order, which
  doesn't). Bumps `eos-control` recipe pin `fed7e32 → 7729720`. The Processes tab now **ranks rows
  by private memory descending** — groups by their *summed* total, instances within an expanded
  group likewise, ties broken by name so refreshes stay deterministic — so the biggest users float
  to the top. The aggregate is surfaced too: a new **"Pamięć (prywatna)"** tile on Overview and a
  **"N procesów · X pamięci · wg pamięci ↓"** footer on the Processes tab, both fed by a summed
  `Overview.mem_bytes`. Verified: cross-build links for `aarch64-unknown-redox`; host `--selftest`
  green; aarch64 image cooked from the pinned rev; **GUI render-verified** on the image — Overview
  shows *"Pamięć (prywatna) 468.4 MB"*, and the Processes list is ordered strictly by the memory
  column (`redoxfs` 81.3 MB → `virtio-netd ×3` 65.7 MB → `background ×2` 46.4 MB → `eos-control`
  39.5 MB → `login ×3` 29.2 MB) with the footer reading *"44 procesów · 468.4 MB pamięci · wg
  pamięci ↓"*. Grouping, human labels and force-kill from `U-096` remain intact.
- `[U-096]` **E-OS Control v2 — process grouping + force-kill on the Processes tab** (user's request:
  don't scatter duplicate windows like Windows' task manager, and let me force-close a stuck process).
  Bumps `eos-control` recipe pin `af7a932 → fed7e32`. **Grouping:** many instances of one program (a
  browser with several windows is the motivating case) collapse into a single `name ×N` header carrying
  the *summed* private memory and the *union* of the group's open resources; collapsed by default for a
  tidy view, expand/collapse remembered per app name — no more hunting duplicates down a flat list.
  **Force-kill:** select a process and confirm (the dialog names the exact pid + process) to end it; on
  Redox this is `libredox::call::kill` with `SIGKILL` — relibc routes it to the kernel's unblockable
  **ForceKill** (the raw `redox_syscall` crate no longer exposes `kill`), POSIX `kill(2)` on a host.
  `selftest.rs` gains an end-to-end kill proof (spawn a child, force-kill it, confirm it dies ≤3 s) and a
  byte parse/format roundtrip that underpins the group memory sums. Verified: cross-build links for
  `aarch64-unknown-redox`; host `--selftest` green (system + security + **kill** + byte roundtrip);
  aarch64 image cooked from the pinned rev; on the image, **GUI render-verified** — the Processes tab
  shows live group headers (`[init] ×3` 25.4 MB, `logd ×2` 7.5 MB) beside ungrouped single rows, and a
  selected process (`PID 52 /usr/bin/sleep`) is force-killed through the confirm dialog → status
  *"Zakończono PID 52"*; the boot/console selftest marker `EOS-CONTROL-SELFTEST-OK` proves `kill_core`
  (spawn + ForceKill + confirm-gone) on the **real E-OS kernel**. (A force-killed process may linger
  briefly as an unreaped zombie in `sys:context` until its parent reaps it — standard Unix semantics,
  not a kill failure; the manager faithfully shows what the kernel reports.)
- `[U-095]` **E-OS Control — one unified control center replaces the separate system + security tools** —
  new pinned repo `eos-control` (dev+CI: gitlab.com/e-os/eos-control, GitHub mirror; AGPL-3.0-or-later),
  recipe `recipes/gui/eos-control`, shipped in `config/{aarch64,x86_64}/eos.toml` **instead of**
  `eos-sysmon` + `eos-guard` (whose repos remain, archived). One tabbed app: **Overview** (system health),
  **Processes**, and **Security**. Rationale (the user's call — why split security/monitoring across apps?):
  on a capability-secure microkernel *what a process can touch* is at once its resource profile and its
  security profile, so they're two views of one truth. The Processes tab is a task manager meant to beat
  Windows': every process carries a **human label** ("orbital = desktop server", "pcid = PCI driver
  manager") so cryptic names never lose you, and a **capability inspector** shows, per process, exactly
  which schemes/resources it holds open (parsed from `sys:iostat`) — impossible on Windows. The Security
  tab is the ported `eos-guard` (blake3 integrity baseline + diff, permission audit, tamper-evident
  digest). Built on the shared `eos-ui`; `sys:` scheme reads on Redox, `/proc` on a host.
  `eos-control --selftest` proves both the system and security cores (`EOS-CONTROL-SELFTEST-OK`). Verified:
  cross-build + host selftest green; aarch64 image build + boot-smoke; boot probe prints the selftest
  marker on the serial; GUI render-verified (all three tabs) on the image.
- `[U-094]` **E-OS Sysmon — the third original app (system monitor), first built straight from the app
  guide** — new pinned repo `eos-sysmon` (dev+CI: gitlab.com/e-os/eos-sysmon, GitHub mirror;
  AGPL-3.0-or-later), recipe `recipes/gui/eos-sysmon`, enabled in `config/{aarch64,x86_64}/eos.toml`,
  launcher entry + crimson icon (`usr/share/ui/apps/50_eos-sysmon`). A Crimson system monitor: system
  identity, logical CPU count and the **live process list** (2 s refresh), read from the kernel `sys:`
  scheme (`sys:uname` / `sys:cpu` / `sys:context`); a host build reads `/proc` so the CLI/selftest half
  stays honest. It's the first app written **directly from the new `docs/creating-an-eos-app.md`
  skeleton** — logic (`sysinfo.rs`) split from UI, GUI behind the default `gui` feature on the shared
  `eos-ui` backend, no storage — and it cross-built for `aarch64-unknown-redox` and passed
  `EOS-SYSMON-SELFTEST-OK` on the first try, validating the guide. Verified: cross-build + host selftest
  green; aarch64 image build + boot-smoke; boot probe prints `EOS-SYSMON-SELFTEST-OK` on the serial;
  GUI render-verified on the image.
- `[U-093]` **Documentation standard + tooling — `CLAUDE.md`, `ARCHITECTURE.md`, an app guide, a docs PDF,
  and enforcement** — makes "every change updates its docs" an explicit, discoverable, partly-enforced
  standard. Adds **`CLAUDE.md`** (the working agreement: three verification gates, a Definition of Done, a
  documentation map, code/comment standards, hosting invariants — linked from `CONTRIBUTING.md`), a root
  **`ARCHITECTURE.md`** (top-down layer map + hosting, cross-linked with `docs/architecture.md`),
  **`docs/creating-an-eos-app.md`** (the `eos-ui`-based app skeleton pattern), and a downloadable
  **docs PDF**: `scripts/docs-pdf.sh` renders the mdBook `print.html` with headless Chromium (no fragile
  PDF plugin — verified locally, 3.6 MB / whole manual) and a self-hosted `docs-pdf` CI job publishes it
  (`needs: []`, `allow_failure`, tags/schedules). Enforcement: `docs-currency` now also advises on new
  public items missing a doc-comment, `eos-ui` gains `#![warn(missing_docs)]` (clean), a
  `.gitlab/merge_request_templates/Default.md` carries the Definition-of-Done checklist, and
  `scripts/eos-check.sh` gives a fast per-crate compile check before a full image rebuild. Also restores
  `docs/design-desktop-environment.md` + `docs/design-xhcid-nonblocking-transfers.md`, which the GitLab
  migration had dropped (they existed only in the stale Desktop checkout). The mdBook build was verified
  locally (35 pages, `print.html`, new pages listed in `SUMMARY.md`).
- `[U-092]` **Heavy `build-image` detached from the shared-runner light tier (`needs: []`)** — the
  self-hosted `eos-heavy` OS build + boot-smoke — the only job that actually boots the OS — spends no
  shared CI minutes, but sat in a stage after the light tier, so a `ci_quota_exceeded` failure there
  skipped it. `needs: []` (on `build-image` and the manual x86_64 variant) makes OS verification survive an
  exhausted free-tier budget. Verified: with the whole light tier failing on quota, `build-image` still ran
  and passed on `eos-heavy`. See [docs/ci.md](docs/ci.md) *CI minutes*. The cap itself is a resource choice
  (monthly reset / buy minutes / a light-tier self-hosted runner).
- `[U-091]` **`pages` must not block the OS build (`allow_failure`)** — the docs-publish job runs on
  budget-limited shared runners and failed with `stuck_pending_no_matching_runners` once free minutes were
  spent; because `docs` sits before `build`, that hard failure had skipped `build-image` and reddened
  `main`. `allow_failure: true` keeps a cosmetic docs hiccup from failing the pipeline or blocking OS
  verification.
- `[U-090]` **Guard v2 — a permission audit on every scan + a tamper-evident baseline** — two hardening
  additions to `eos-guard` (`544476b`→`0626360`, v0.1.0→v0.2.0). (1) **Permission audit:** every scan now
  flags setuid (`0o4000`), setgid (`0o2000`) and world-writable (`0o0002`) files as **OSTRZEŻENIE**
  regardless of whether they changed — so a setuid binary is surfaced on the very first scan, not only if
  it's modified (v1 only warned on world-writable *unchanged* files). (2) **Baseline integrity digest:**
  `set_baseline` records a blake3 digest over the canonical (path-sorted) baseline rows in `meta`; a scan
  recomputes it and reports **⚠ WZORZEC NARUSZONY** if the baseline was edited out of band or corrupted —
  a file-integrity monitor whose baseline can be silently rewritten is theatre. (Honest scope: the digest
  lives in the same DB, so it catches corruption and naive tampering, not an attacker who also recomputes
  it; a key-signed baseline is the `R-711` class, future work.) The `--selftest` grew matching assertions:
  a setuid file in the throwaway tree must produce a WARN, a fresh baseline must pass its own digest, and a
  raw out-of-band `UPDATE baseline SET hash=…` must be caught (`verify_baseline()` returns false). Verified:
  cross-build for `aarch64-unknown-redox` + host `GUARD-SELFTEST-OK`; eos-guard CI green; aarch64 image
  build + boot-smoke, `GUARD-SELFTEST-OK` on the serial console.
- `[U-089]` **E-OS Guard — the second E-OS original application: a filesystem integrity monitor
  (blake3 + SQLite), and the first proof that `eos-ui` carries a second app** — new pinned repo
  `eos-guard` (dev+CI: gitlab.com/e-os/eos-guard, GitHub mirror; AGPL-3.0-or-later), recipe
  `recipes/gui/eos-guard`, enabled in `config/{aarch64,x86_64}/eos.toml`, launcher entry + crimson shield
  icon (`usr/share/ui/apps/40_eos-guard`). Guard baselines directory trees — the blake3 hash + size/mode/
  mtime of every regular file, stored in SQLite/WAL at `~/.local/share/eos-guard/baseline.db` — and diffs
  a later scan against the baseline, surfacing **ZMIENIONY** (hash changed), **NOWY**, **USUNIĘTY**, and
  **OSTRZEŻENIE** (a world-writable security lint), with a colour-coded Crimson Slint UI (roots field,
  Baseline/Scan buttons, summary chips, findings list). blake3 is the portable-Rust build
  (`default-features = false` — the same hash `pkgar`/the SBOM use); SQLite is bundled with
  `-DSQLITE_DISABLE_LFS`; scans are capped at 20k files so a huge tree can't wedge the single-threaded
  event loop. **The whole GUI is one `eos_ui::init("E-OS Guard")` call** — Guard reuses the `U-088`
  shared backend with zero new platform code, validating the crate for a second consumer. `eos-guard
  --selftest` is the headless proof (baseline a throwaway tree → assert a clean re-scan is all-OK →
  mutate/add/remove files → assert the diff reports exactly 1 MODIFIED + 1 NEW + 1 REMOVED, and WAL is
  active), printing `GUARD-SELFTEST-OK`; wired into the repo CI and used as a boot probe. Verified:
  blake3 cross-compiles for `aarch64-unknown-redox`; eos-guard CI green; cross-build against the
  git-pinned `eos-ui` + host selftest green; aarch64 image build + boot-smoke, `GUARD-SELFTEST-OK` on the
  serial console, and the app window renders + scans via clicks (screendumps `assets/screenshots/`).

- `[U-071]` **E-OS Settings — native Crimson control panel (`R-D01`, Foundation B)** — new
  `eos-settings` bin in the launcher crate (eos-orbutils `061dfd3`): an orbital/orbclient panel host with
  NO libcosmic/fontconfig dependency (builds on the aarch64 host, dodges the cosmic-settings toolchain gap),
  crimson sidebar (System, Security, Updates, Drivers, Network, Display, Audio, Date&Time, User). Real
  System/Security/clock data; Update/Driver panes are honest stubs tagged with their roadmap codes. Ships
  `apps/15_eos-settings` + a crimson gear icon. Verified: compiles for aarch64-unknown-redox, links,
  installs, integrated, and RUNS against the live orbital server (PID 51, no crash). Pixel-render not
  screenshotted under QEMU due to `R-F08`.
- `[U-072]` **Graphical session no longer blocked by audio (`R-F07`) + display regression surfaced (`R-F08`)**
  — greeter `20_orbital` had `requires_weak … 20_audiod.service`; `audiod` exits without signalling readiness
  on machines without working audio (aarch64 QEMU `ihdad` I/O-fails), so the desktop session hung and the
  greeter never started — a P0 daily-driver regression hidden because recent work used the text getty.
  Dropped the audiod dependency in `config/desktop-minimal.toml`; verified `orbital` now starts
  (`/scheme/orbital` present). Open (`R-F08`): orbital runs but its output doesn't reach the QEMU ramfb
  (greeter on VT3, not visible) — see [docs/known-issues.md](docs/known-issues.md).
- `[U-073]` **R-D01 Settings render-verified end-to-end + `R-F08` root-caused** — booted the aarch64
  image to the graphical desktop (fix `R-F07`) and confirmed the `eos-settings` window renders correctly:
  crimson sidebar with all 9 panels, real System data (`aarch64`, Genesis), themed footer
  (`assets/screenshots/eos-settings-panel.png`, `eos-desktop.png`). The desktop is reached with `Super+F3`;
  `R-F08` (greeter VT not auto-activated on boot) root-caused to `inputd` activating only the first-created
  VT (the bootlog wins after the init reorg) — downgraded P0→P1 with fix candidates in
  [docs/known-issues.md](docs/known-issues.md).
- `[U-074]` **`R-F08` fully root-caused** (docs only) — instrumented `inputd` to trace the VT
  lifecycle on the serial console: the greeter renders on VT3, then the lazy `fbcond` text-console
  service (`00_fbcond`, VT2) spawns after orbital and its display-open activates VT2, stealing the
  framebuffer. `getty 2`, `on_close` and the keyboard were ruled out. Precise trace + three fix
  candidates in [docs/known-issues.md](docs/known-issues.md); no code shipped (instrumentation reverted).
- `[U-075]` **vesad: don't panic on a malformed bootloader-env line (`R-F09`)** — `vesad`
  (`drivers/graphics/vesad/src/main.rs`) parsed `/scheme/sys/env` with `line.split_once('=').unwrap()`,
  aborting the display driver on any line without `=` (found while debugging `R-F08`). Now uses `filter_map`
  to skip malformed lines. `cargo check` `aarch64-unknown-redox`: clean. Fork `eos-base` `d4f193c9`→`98f22879`;
  recipe pin bumped.
- `[U-076]` **First-boot forces a password on the shipped passwordless account (`R-602`)** — the
  `login` program (eos-userutils) now, in its blank-password branch, runs `passwd <user>` (as root, before
  the shell starts) in a loop until a password is set, so the default `user` (no password) can no longer log
  straight into a shell. **Verified end-to-end in aarch64 QEMU**: `login: user` → `E-OS first-boot setup` →
  `passwd` → `Password set.` → shell (`assets/screenshots/eos-oobe-firstboot.png`). Closes the live P0
  default-creds exposure for the text/getty login path. Fork `eos-userutils` `260d7725`→`b12240d`; recipe pin
  bumped. Follow-ups: the graphical greeter (`orblogin`) blank-password path and root's weak default
  `password` (not caught by `is_passwd_blank`).
- `[U-077]` **First-boot also forces a change of the default `root/password` (`R-602`)** — extends
  `U-076`: `login` (eos-userutils) now refuses to open a shell for an account still using the shipped
  default password. The blank-password loop and a new default-password check share one helper
  (`force_first_boot_passwd`); the check is **order-independent** — since `root`'s hash isn't blank
  (`is_passwd_blank` can't catch it), it triggers whenever `password` is actually used to log in.
  **Verified end-to-end in aarch64 QEMU**: `login: root` + `password` → `The account 'root' is using the
  default password.` → `passwd` → `Password set.` → `root:~#` shell
  (`assets/screenshots/eos-oobe-root.png`). This retires the second half of the live P0 default-creds
  exposure (`root/password`) on the text/getty path. `cargo check` `aarch64-unknown-redox`: clean. Fork
  `eos-userutils` `b12240d`→`799088a`; recipe pin bumped. Remaining `R-602` follow-up: the graphical
  greeter (`orblogin`) login path and per-machine identity (hostname/locale/keymap/machine-id/SSH keys).
- `[U-079]` **The graphical greeter now enforces the first-boot password too (`R-602`)** — closes the
  final, and since `R-F08` the **default**, exposure: the desktop greeter (`orblogin`, eos-orbutils) let a
  default-credential account (blank `user`, or `root`/"password") log **straight to the desktop** because
  it only called `verify_passwd` (a blank password verifies against `""`). It now runs the same first-boot
  rule as the text `login`, in-window: on a default-credential login it switches to **New password → Confirm
  password**, sets the password (`set_passwd` + `save`), and only then starts the session. **Verified
  end-to-end in aarch64 QEMU** (keyboard-driven): boot → greeter → empty password → `First-boot setup: /
  New password:` → `Confirm password:` → full crimson desktop (`assets/screenshots/eos-greeter-setpw.png`,
  `eos-desktop-after-oobe.png`). Fix detail worth noting: `save()` needs `Config::default().writeable(true)`
  — plain `Config::default()` opens the users DB read-only (`EBADF` on save), the same builder `passwd`
  uses. Field labels update live (the panel is re-rendered on the mode switch). Fork `eos-orbutils`
  `061dfd3`→`3ac6436`; recipe pin bumped. This makes the P0 shipped-default-credentials exposure closed on
  **every** login path (text/getty + serial + graphical greeter). Remaining `R-602`: per-machine identity
  (hostname/locale/keymap/machine-id/SSH host keys).
- `[U-084]` **Fork CI revived — pipelines run in the `e-os` namespace (9 forks) + collective build-neutral
  pin bump** — upstream `.gitlab-ci.yml` workflow rules gate pipelines to `$CI_PROJECT_NAMESPACE ==
  "redox-os"` (or to a branch name the fork doesn't develop on — `eos-pkgutils` lives on `eos`), so every
  pipeline in these forks was silently dead in the `e-os` namespace. The 9 affected forks (kernel, relibc,
  base, redoxfs, pkgutils, orbclient, orbital, orbutils, liborbital) now add a namespace-only rule ahead of
  the upstream arms (branch names vary — `eos-july`/`eos`/`master` — so the rule must not depend on them);
  QEMU-based test jobs (`redoxer exec/test`) are `allow_failure` because gitlab.com shared runners have no
  KVM — they run best-effort and cannot permanently redden the pipeline (real boot coverage stays with the
  heavy `build-image` boot-smoke). All 9 files validated via the GitLab CI lint API; pushed to GitLab +
  GitHub before the bump. The revived gates paid off on the very first runs: `fmt` caught unformatted
  E-OS code in **three** forks (pkgutils `pkg-lib`; base drivers — daemon/rtl8139d/usbnetd/pcid/raid1d/
  xhcid/virtio-core; relibc `ld_so` — all reformatted, zero semantic change), and pkgutils'
  `cargo test --locked` exposed a **stale `Cargo.lock`** from `U-081`: the R-703 ed25519 code shipped
  without its lock entries (the image build never noticed — the cook doesn't build `--locked`); the lock
  now adds exactly the ed25519-dalek dependency tree, no existing entry changes, and the CI test command
  passes (2/2). redoxfs `test:linux` is gated best-effort — the FUSE unmount races the test's
  `remove_dir` on shared runners (environment flake, not a code failure). First fully green pipelines:
  **kernel** (fmt + x86_64/aarch64/i586/riscv64gc builds; even the QEMU boot test passed on a shared
  runner), orbclient, orbital, orbutils, liborbital. Pins bumped collectively (build-neutral: CI rules +
  formatting + lockfile only), `pins --strict` 22 ok / 0 drift; verified by aarch64 container build +
  boot-smoke. Docs: [docs/ci.md](docs/ci.md) gained a *Fork pipelines* section.
- `[U-086]` **E-OS Notes — the first E-OS original application ships in the image (Slint 1.17 +
  SQLite/WAL over a custom Orbital backend)** — new pinned repo `eos-notes` (dev+CI:
  gitlab.com/e-os/eos-notes, GitHub mirror recipes fetch from; AGPL-3.0-or-later), recipe
  `recipes/gui/eos-notes`, enabled in `config/{aarch64,x86_64}/eos.toml`, launcher entry + crimson icon
  (`usr/share/ui/apps/30_eos-notes`). Sidebar with substring search, autosaving title+body editor,
  WAL-mode SQLite at `~/.local/share/eos-notes/notes.db`; `eos-notes --selftest` is the headless storage
  proof (create → reopen → readback → search → delete + `journal_mode == wal`), gated in the repo CI and
  used as a boot probe. **The stack choice is the real story:** the backlog's *iced* is a dead end (the
  Redox iced fork is 0.6 — no multiline text widget; modern iced/libcosmic is blocked by host:gperf on
  the aarch64 build host), and BOTH winit paths fail on today's Redox — slint ≥1.13's winit backend does
  not even compile for Redox (unconditional x11 imports, orbital lacks pump_events), while the
  upstream-proven slint 1.1.1 + winit 0.28 pair aborts at runtime because its event loop opens the
  legacy `event:` scheme the modern kernel removed (ENOSYS). E-OS therefore drives modern Slint through
  its **own `slint::platform::Platform` over orbclient** (`src/orbital_platform.rs`:
  MinimalSoftwareWindow + SoftwareRenderer → ARGB swizzle into the orbital window; orbital events →
  slint pointer/key/scroll/resize; timers drive animations), with the image's DejaVu TTFs registered
  into fontique at startup (fontique has no Redox font discovery — an empty collection panics the
  renderer) and a `/scheme/orbital` DISPLAY default for shell launches. Bundled SQLite builds with
  `-DSQLITE_DISABLE_LFS` (relibc ships no LFS64 aliases); the GUI sits behind the default `gui` feature
  so hosts/CI build the CLI half with `--no-default-features`. **Verified:** eos-notes CI green; aarch64
  image build + boot-smoke PASS; the boot probe prints `EOS-NOTES-SELFTEST-OK` on the serial console
  (0 panics); GUI render-verified on the image — the window shows sidebar/editor and a live `0 notatek`
  status straight from SQLite (screendumps `assets/screenshots/eos-notes-v1.png` and
  `eos-notes-desktop-icon.png`). Full interactive verification (mouse + typing) landed in `U-087`.
- `[U-088]` **`eos-ui` — the Slint-on-Orbital backend is now a shared crate; `eos-notes` consumes it** —
  extracted the ~200-line custom `slint::platform::Platform` (software renderer over orbclient:
  pointer/keyboard/scroll/resize + the `TextInput` glyph path) and the fontique bootstrap out of
  `eos-notes` into a new reusable library, new repo `eos-ui` (dev+CI: gitlab.com/e-os/eos-ui, GitHub
  mirror; AGPL-3.0-or-later). A GUI app is now one `eos_ui::init("Title")` call away from a window
  (no-op on non-Redox hosts, so a host development build still works). `eos-notes` drops its inlined
  `orbital_platform.rs` + `register_system_fonts` and takes `eos-ui` as a rev-pinned git dependency
  (`c53180d`); `orbclient` and the `unstable-fontique-010` feature move into `eos-ui`. Done now — before
  the second GUI app (guard/veil) exists — so the backend is written once, not copy-pasted. The window
  title is parameterized (was hard-coded `E-OS Notes`); behaviour is otherwise identical. Verified:
  `eos-ui` cross-checks clean for `aarch64-unknown-redox` and its CI is green; `eos-notes`
  (`bad75e5`→`9f9eae6`) cross-builds against the git-pinned `eos-ui` + host selftest green; aarch64 image
  build + boot-smoke, `EOS-NOTES-SELFTEST-OK` on the serial, and the app window still renders.
  `eos-ui` is tracked in `repos.toml` (a git dependency locked by each consumer's `Cargo.lock`, not a
  standalone image package).
- `[U-087]` **E-OS Notes verified fully interactive — and a headless GUI click-harness that proves it** —
  drove the built image end-to-end with real input events: the mouse cursor tracks, the desktop
  **E-OS Notes** icon highlights on hover, a **double-click opens the app window**, the sidebar `+` button
  **creates a note** (status flips `0 notatek`→`1 notatek`, a dated row appears — a live SQLite `INSERT`
  with a correct `2026-07-18` timestamp, i.e. `U-083`'s RTC working), and **typed text now lands in the
  title/body fields**. Two findings on the way: (1) the earlier "mouse doesn't work" belief was a
  **harness bug, not E-OS** — QEMU HMP `mouse_move` is *relative* and never drives an absolute device;
  QMP `input-send-event` with `abs` axes reaches the usb-tablet fine (cursor moved to exactly the sent
  `value·resolution/32767`). (2) A real backend bug: **typed glyphs never reached a focused field** —
  orbital delivers printable characters as a separate `TextInputEvent` (inputd runs the scancode through
  the active keymap, then *clears* `character` on the following `KeyEvent`, which carries only
  navigation), and the orbclient platform backend only handled `KeyEvent`. Now it handles
  `EventOption::TextInput` → `WindowEvent::KeyPressed` (Enter/Backspace/arrows still come through the
  KeyEvent scancode path; no double-insert since those KeyEvents carry `character='\0'`). eos-notes
  `5ca5c49`→`bad75e5`. **Proven end-to-end on the built image** (`assets/screenshots/eos-notes-typed.png`):
  launched `eos-notes` from the GUI terminal → clicked `+` (a note appears, `Zapisano`/saved) → clicked the
  title, typed **`ghost`** → clicked the body, typed **`eos dziala`** (with a space) — both land in the
  fields, autosaved to SQLite. Harness notes for the next run: log in by **clicking** the greeter's
  Password field + Login button (keyboard focus on the modal greeter is unreliable); the desktop-icon
  double-click is flaky under QMP timing (launch from the taskbar terminal instead); `sendkey` only
  covers lowercase/space/minus (a QEMU-monitor limit, not E-OS). Verified: cross-build + host selftest
  green, aarch64 image build + boot-smoke, interactive click/type screendumps.

### Fixed
- `[U-085]` **Standalone installer writes the right EFI boot file without env `TARGET`; virtio drivers no
  longer abort on a legacy-only device** — two backlog follow-ups, pins bumped. **eos-installer**
  `75b6bd5`→`f9d82a1`: `get_target()` read only the `TARGET` env var (with a compile-time fallback) and
  defaulted to `x86_64-unknown-redox` — a standalone run without the env wrote `BOOTX64.EFI` into an
  aarch64 disk's ESP, which boots to the EFI shell. The target now resolves as `TARGET` env >
  `[general] target` (new config field, set in `config/*/eos.toml`) > compile-time `TARGET` > warned
  default, and is carried explicitly via `DiskOption::target` (TUI/GUI in-image installs keep the baked
  compile-time target). **Proven at the artifact level** (fixed installer, local cookbook, no `TARGET` in
  the env): config `target=aarch64-unknown-redox` → `EFI/BOOT/BOOTAA64.EFI`, PE machine ARM64; no target
  anywhere → a warning + the historical `BOOTX64.EFI` (PE x86-64). The fork's `gui-build` CI job also got
  an image (it ran on the runner default, no cargo — permanently red). **eos-base** `544d76d`→`d633641`:
  `virtio-core::probe_device` expect-panicked (= abort) when a device exposed no modern (virtio 1.0) PCI
  capabilities, so a pure-legacy virtio device took the driver down (the `T9`/harness class). Missing
  capabilities now map to the existing `Error::InCapable`; the first legacy-only boot-probe then caught the
  second half of the bug — the drivers' own `daemon_runner` wrappers `.unwrap()`-ed the returned error,
  turning it right back into an abort — so virtio-netd/blkd/gpud now log the error and `process::exit(1)`
  cleanly. QEMU exposes a transitional device only with `disable-legacy=off,disable-modern=off`.
  Verified: aarch64 container build + boot-smoke PASS, plus a legacy-only boot-probe
  (`virtio-net-pci,disable-modern=on` attached): serial shows `virtio-core: … legacy-only devices are
  unsupported` → `virtio-netd: exiting: the device is incapable of Common` → a clean spawner-logged exit,
  0 panics, boot reaches `eos login:`.
- `[U-083]` **aarch64 system clock no longer stuck at 1970 on an ACPI boot — TLS cert validation unblocked** —
  the kernel only programs the RTC on a Device-Tree boot (`rtc::init`, reached from `init_devicetree`); the
  E-OS aarch64 image boots via UEFI/ACPI (since `R-401f`), so `init_devicetree` never ran, the clock stayed at
  the Unix epoch, and every TLS certificate-validity check failed (a silent blocker for HTTPS, package updates,
  and the browser). Fixed **without a kernel/ABI change**: the **bootloader** (`eos-bootloader`
  `f1ba665`→`05dadec`) already runs in UEFI, so it reads the firmware wall-clock via Runtime Services `GetTime`
  and exports it to the kernel env as `BOOT_TIME=<unix_secs>` (new `Os::boot_time_epoch()`, overridden only for
  UEFI; `days_from_civil` converts the broken-down UTC). **`rtcd`** (`eos-base` `dd41f1da`→`efc07c3e`), which was
  a no-op on aarch64, now reads `BOOT_TIME` from `/scheme/sys/env` and writes the offset to
  `/scheme/sys/update_time_offset` — the same sink x86 uses for the CMOS RTC. Platform-independent (works on
  QEMU + real UEFI hardware); absent `BOOT_TIME` (e.g. a BIOS boot) is a no-op. Both pieces compile-verified
  (bootloader for `aarch64-unknown-uefi`, rtcd for `aarch64-unknown-redox`) before pinning.
- `[U-082]` **Installer GUI produced a non-bootable disk; randd trusted failed rdrand (`G1`, entropy)** —
  two audit-surfaced fork fixes, pins bumped. **eos-installer** `05bf2eb`→`75b6bd5`: the GUI installer read
  the bootloader from the stale path `<root>/boot/bootloader.{bios,efi}` (removed years ago — the `bootloader`
  package installs to `usr/lib/boot/`, and the TUI already reads from there). The `else` branch silently
  substituted an empty buffer, so a GUI install wrote a **0-byte `EFI/BOOT/*.EFI`** and the disk would not
  boot; the GUI now reads `usr/lib/boot/` like the TUI. **eos-base** `a5cf1b0c`→`dd41f1da`: `randd` read the
  x86 `rdrand` instruction without checking the carry flag (CF=0 ⇒ generation failed, destination is 0) and
  marked the RNG seeded regardless — it now retries up to 10× per word, reads CF via `setc`, and only sets
  `have_seeded` when every word succeeded. Verified: aarch64 heavy build + boot-smoke; the x86 `rdrand` path
  is exercised by the manual `build-image-x86_64` job (it is `cfg(target_arch = "x86_64")`).
- `[U-081]` **Security-fix pins land in the image — base/redoxfs/pkgutils bumped (K-01, K-06, UB fix, R-703)** —
  three deferred fork fixes, verified by the heavy-tier CI build + QEMU boot-smoke, are now pinned into the
  built image: **eos-base** `98f22879`→`a5cf1b0c` (K-01: `raid1d` validates the superblock before assembling;
  K-06: `randd` mixes CNTVCT+splitmix jitter into the seed after the RNDRRS loop; `pcid` resolves link-GSI by
  walking ACPI resource descriptors instead of scanning raw `0x89` bytes), **eos-redoxfs** `ce461328`→`ec25394`
  (vendored `cpufeatures`: `from_utf8_unchecked` on `/scheme/sys/cpu` replaced with validated `from_utf8` —
  removes UB on malformed scheme output), **eos-pkgutils** `master@7e89ac2e`→`eos@5643d21` (R-703: client-side
  ed25519 verification of the `repo.toml` manifest signature + regression test rejecting a tampered index).
  The GitHub mirrors for `eos-base`/`eos-redoxfs` (which recipes fetch from) were fast-forward-synced first —
  they lagged the GitLab source of truth. `repos.toml` pins regenerated to match.
- `[U-080]` **Live-ISO text console (VT2) works again — `getty 2` no longer starved at boot (`R-601`)** —
  on the live ISO the fbcon text console (`Super+F2`) was black: `getty 2` never ran, so install-to-disk could
  not be driven from a text login. Root-caused (4-way parallel source analysis + empirical mount-diff) to the
  E-OS-custom `25_raid1d.service` being declared **`type = "notify"`**. `init` drains services on a single
  thread and blocks on a `notify` service until it signals readiness; `raid1d` calls `daemon.ready()` only
  **after** `assemble()` probes every `/scheme/disk.*` (open R+W + read the trailing 4 KiB superblock). On the
  live medium that probe hits the physical NVMe the bootloader read from, whose I/O stalls on an INTx IRQ that
  never routes on aarch64 (the `R-401d`/`R-501` platform bug) — so `raid1d` never signals ready, `init`'s drain
  freezes, and `30_console` (queued immediately after it, and after both the greeter `20_orbital` and the
  dep-free `30_serial-getty.service`) never spawns `getty 2`. The on-disk filesystem is byte-identical between
  live and installed (verified by mounting both images and diffing `/usr/lib/init.d` — every file md5-identical),
  which **corrects** the earlier "a live init.d fallback lacks `getty 2`" hypothesis: the fault was purely
  runtime. **Fix:** `config/{aarch64,x86_64}/eos.toml` set `25_raid1d.service` to **`type = "oneshot_async"`** —
  nothing does `requires_weak 25_raid1d` and root is mounted by `50_rootfs` in the initfs phase (never from
  `disk.raid1`), so `init` gains nothing by awaiting raid1d and can spawn it and move on. **Verified end-to-end
  in aarch64 QEMU**: the live ISO's `Super+F2` now shows the full getty
  (`assets/screenshots/eos-live-vt2-getty.png`) — E-OS issue banner + `eos login:` (bright 3846 px vs 0 before)
  — with the greeter (VT3) and bootlog (VT1) unchanged and boot still landing straight on the greeter (`R-F08`
  intact). Config-only, no `init`/`raid1d` code change; both arches in parity. Unblocks the `R-601`
  install-to-disk harness. Deeper hardening tracked as a follow-up (raid1d should `ready()` before
  `assemble()`, and `init`'s notify wait should time out so no single service can freeze boot).
- `[U-078]` **Boot lands directly on the graphical greeter — no more `Super+F3` (`R-F08`)** — the
  aarch64 image now boots straight to the crimson E-OS greeter (`assets/screenshots/eos-greeter.png`),
  zero key presses. Real root cause, found via an `inputd` serial trace (it **corrects** the earlier
  display-handoff hypothesis in `U-073`/`U-074`): the VT-2 activation is the init service
  `/usr/lib/init.d/30_console` running **`inputd -A 2`**. The installer concatenates all `[[files]]`
  with no dedup (`redox_installer`'s `Config::merge` → `files.extend`), and because `desktop.toml`
  includes BOTH `desktop-minimal.toml` and `server.toml` (each pulling `minimal.toml`), the
  `server→minimal` copy of `30_console` (with `inputd -A 2`) lands **last** on disk and wins — stealing
  the foreground to the text console (VT2) *after* `20_orbital` activates the greeter's VT3. **Fix:**
  `config/{aarch64,x86_64}/eos.toml` (the root config, merged dead-last) pins `30_console` **without**
  `inputd -A 2` — the VT2 getty stays reachable via `Super+F2`, and `requires_weak 20_orbital` orders it
  after the greeter. Config-only; no `inputd`/recipe code change (instrumentation reverted). Both arches
  kept in parity. Full trace + reasoning in [docs/known-issues.md](docs/known-issues.md).
