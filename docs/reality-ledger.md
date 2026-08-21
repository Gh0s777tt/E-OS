# 📒 Reality ledger — what is genuinely done vs claimed

> `R-001`. Single source of truth reconciling ROADMAP/README/CHANGELOG claims against what actually runs, after the discovery that **GitHub Actions is disabled account-wide** (so every CI-dependent claim is inert) and that nearly all runtime verification is **aarch64 QEMU-TCG** on the Apple-Silicon dev host. Generated 2026-07-13.

> **Update note — 2026-07-23 (delta since generation).** The body below is the
> 2026-07-13 snapshot; several premises have since changed and are corrected here
> (the forward-looking risk/gap analysis mostly still holds). For the current
> record see `CHANGELOG` `U-071`…`U-111` and `ROADMAP`.
> - **CI is no longer dead / the GitLab mirror is no longer phantom.** GitLab
>   `gitlab.com/e-os/e-os` is now the **source of truth** with a live **two-tier
>   GitLab CI** — light gates (secret-scan, integrity, `pins --strict`,
>   `rust-checks`, docs-currency) on shared runners (`U-070`) and the heavy
>   **`build-image` + boot-smoke** on the self-hosted `eos-heavy` runner detached
>   with `needs: []` (`U-092`); GitHub `Gh0s777tt/*` is the mirror recipes fetch
>   from. So the "dead Actions → every CI claim inert" and "single origin=GitHub /
>   phantom mirror" framing (top premise, "dead CI" bullets, the mirror + CI rows
>   in *Claimed but broken*) **no longer applies** — those are resolved (`R-006`,
>   the GitLab-CI half of `R-003`/`R-005`).
> - **netsurf ET_EXEC crash is RESOLVED** (`R-D06`, `U-103`/`U-104`): netsurf is
>   rebuilt from source as a **PIE**, renders `welcome.html`, and browses the live
>   web (`R-D10`). The "netsurf ET_EXEC crash" cited as an open substrate defect
>   below is fixed (see `docs/known-issues.md`).
> - **Still true / still open:** the local-build reality is now sharper —
>   `make … all` **cannot** run from the macOS checkout at all (podman-macOS
>   virtiofs can't serve cargo/rustc mmap reads; see `docs/build-troubleshooting.md`),
>   so image builds are authoritative **only on Linux/CI**. The trust-chain
>   ordering (`R-702`→`R-703`→`R-701`), live default-credentials (`R-602`),
>   install.md overstatement (`R-608`), and the
>   trusted-time / recovery-path gaps below remain open.

> **Second update note — 2026-08-15 (`U-126`): premises audited against the tree, several are false.**
> This page is published on the docs site *and* is treated as the definition of several
> roadmap items, so a stale premise here becomes a mis-scoped ticket. Six independent
> audits (each re-checked by an adversarial reviewer) re-ran every claim below against
> `main`. Corrections, in descending severity:
>
> - **The i18n premise was never true — not stale, invented.** The "CLAUDE.md makes i18n
>   key-parity a hard gate and mandates Polish docs/UI" claim (below, and in *Coverage
>   gaps*) has no basis: `grep -niE "i18n|l10n|locale|polski|polish|parity" CLAUDE.md`
>   returns **nothing**, and the chronology rules out any earlier wording — `CLAUDE.md`
>   entered the repo in `87257aca3` (2026-07-19), **six days after** this page was written
>   (`1a40a7844`, 2026-07-13). No i18n gate exists in `lefthook.yml` or any CI job either.
>   The i18n *gap* is real and worth scheduling; the "project violates its own gate"
>   framing is not. Corrected in place below.
> - **Quotes attributed to `CLAUDE.md` in Polish are fabricated.** `'docs muszą być zawsze
>   zgodne z kodem'` (below), and in ROADMAP `'bez luk'` / `'docs zgodne z kodem'`, appear
>   nowhere in that (English) file. The underlying *theses* are sound — §2 and §4 do
>   require docs to track code — so the fix is to cite sections, not invent quotations.
> - **`release/SHA256SUMS` phantom-artifact claim: resolved.** The `release/` directory
>   exists neither in the tree nor in the index (`git ls-files release/` is empty); it was
>   removed and `.gitignore`d, and `install.md` now uses the real `build/<arch>/eos/`
>   path. *Residue:* `ROADMAP.md` and `docs/feature-proposals.md` still state it in the
>   present tense.
> - **"The publisher never emits `repo.toml.sig`": resolved.** Both publish scripts sign
>   via `tools/eos-repo-sign`, and since `U-120` an unsigned publish hard-fails. The real
>   gap moved to the client: no pinned key (`R-702`), no `verify_manifest()` (`R-703`).
> - **"`make-release` doesn't regenerate the SBOM per build": resolved** — it does, and
>   folds it into the same signed `SHA256SUMS`.
> - **`roadmap-connectivity.md` "✅ done … verified" for usbnetd: fixed in `U-115`** — it
>   then read "🚧 partial … **RX is broken**". *(Superseded 2026-08-17, `U-130`: that
>   correction swapped one stale status for another. RX was fixed on 2026-07-12 and the
>   proof was lost with a branch, not the fix — the row now reads ✅ full duplex.)*
> - **The `CHANGELOG U-055` self-contradiction does not exist** — there is no `U-055` entry
>   in `CHANGELOG.md` (history before `U-071` lives in the git log). Two sequential commits,
>   not one contradictory entry.
> - **hardware-matrix: the specific accusation is wrong, a real defect sits next to it.**
>   The tables are explicitly x86_64, and there are no aarch64 `ahcid`/`ided` rows to be
>   wrong. `ac97d`/`vboxd` *were* built for x86 — they are dead on **aarch64** only, along
>   with `sb16d`, `ps2d` and `ided`, which this page omits. The rows need an `Arch` column,
>   not a truth correction.
> - **Evidence paths `src/base-drivers/*` do not exist and never did** (`git log --all --
>   src/base-drivers` is empty). That code lives in the `eos-base` fork and is fetched into
>   a gitignored directory — the same "cites a path that isn't there" error this page
>   charges `hardware-matrix` with. Corrected below.

## Genuinely done and verified (the strong foundation)

| Item | Evidence | Confidence |
|---|---|---|
| Boots to login/greeter on aarch64 (QEMU virt/TCG, dev host) AND x86_64 (separate rig), 0 unhandled exceptions, on the fully-hardened kernel | `docs/known-issues.md L1-3,L140-147; CHANGELOG U-047 (x86_64 hardened boot), U-031 (both-arch macOS boot)` | high |
| aarch64 bring-up fixes are substantive and real, not cosmetic: kernel RNDR/RNDRRS trap-emulation (R-401b), nvmed INTx + shared-phandle IRQ (R-401c/d), ACPI _PRT INTx routing so acpi=off no longer needed (R-401f), the sched_yield signal-vs-x0-commit kernel race (R-401e), and the INTx mask/EOI deadlock fix | `CHANGELOG U-011/U-012/U-013/U-018/U-019/U-034` — those numbered entries live on the **archived** `origin/archive/pre-migration-de-phase1` branch, not in `main`'s CHANGELOG or log (`U-131`); `main` records the same work as `R-401b`–`R-401f`. Also `docs/known-issues.md` L164-205; forks eos-kernel@97ca1607/bf4b264e, eos-base@6c695a10 | high |
| relibc static-TLS ABI bug (every thread crashed on exit, BOTH arches) root-caused and fixed with a regression test; ld.so weak-PLT + d_val overflow fixes un-broke every COSMIC app | `CHANGELOG U-020 (R-402a), U-058 (R-402b); docs/known-issues.md L273-308; eos-relibc branch eos-tls @0d30e9ea` | high |
| Fala-B memory-safety hardening owned by E-OS, boot-verified on both arches: overflow-checks across kernel+base+relibc, user-space mmap ASLR (empirically proven across two boots), simultaneous W⊕X at the syscall boundary, ld.so linked at vaddr0 so its base randomizes, guard bands | `CHANGELOG U-044/U-045/U-046/U-051/U-052; ROADMAP R-306; docs/hardening.md` | high |
| Full-disk encryption (RedoxFS AES-XTS) boots end-to-end: bootloader prompts for password, unlocks AES-XTS root, reaches login on both arches; surfaced+fixed a real UEFI ENOKEY bootloader bug then rebased the fork onto mainline | `CHANGELOG U-049/U-050; ROADMAP R-305; docs/encryption.md; build/aarch64/eos-enc/harddrive.img + build/x86_64/eos-enc/harddrive.img present` | high |
| raid1d — a real new userspace RAID-1 mirror driver crate in eos-base (write-both/read-fallback, degraded boot, resync/rebuild, split-brain safety), verified in a 5-boot QEMU sequence | `CHANGELOG U-061/U-065 (R-501/R-501b); eos-base@1ab5035f: drivers/storage/raid1d` (fork, not this repo — see the 2026-08-15 note) | high |
| Hybrid post-quantum signing tool (ed25519 + ML-DSA-65) — real host-side Rust tool, built, verified against the actual repo.toml incl. classical-only fallback and tamper detection | `CHANGELOG U-064 (R-503); tools/eos-repo-sign/ (built target present); repo/aarch64-unknown-redox/repo.toml` | high |
| Vendoring: all 22 Redox-authored packages build from Gh0s777tt/eos-* forks; a local pkgar repo is produced (73 pkgs aarch64, 72 x86_64, with repo.toml) | `ROADMAP R-208; docs/forks.md; repo/{aarch64,x86_64}-unknown-redox/*.pkgar + repo.toml on disk` | high |
| USB stack progress: usbscsid mass-storage re-enabled via a real daemon INIT_NOTIFY fix (reads block 0); usbnetd RNDIS driver enumerates, runs handshake, reads MAC, and does **full duplex** — a complete DHCP handshake, pcap-verified (`U-056`/`U-057`, restored in `U-130`) | `git log 0ab0c6300/1ed8267a8 (usbnetd), U-054-era commits (usbscsid); eos-base fork: drivers/net/usbnetd, drivers/storage/usbscsid` (fork, not this repo; there is no `U-055` CHANGELOG entry — see the 2026-08-15 note) | high |
| LTS branch and Dependabot are live (independent of Actions): origin/lts/0.1 exists; Dependabot has opened cargo + github_actions update branches | `git branch -a: remotes/origin/lts/0.1, remotes/origin/dependabot/*; ROADMAP R-1002` | high |
| SBOM (CycloneDX) files exist for 0.1.0 both arches; minisign public key present | `sbom/eos-0.1.0-{aarch64,x86_64}.cdx.json; keys/eos-release.pub (RWRK7Vdg...)` | medium |

## Claimed but broken / overstated — must be reconciled

- ⚠️ docs/install.md (shipping, not the stale vendored fork) §2 states the Installer walks the user through creating users/passwords and choosing the package set; the built GUI does drive-select + password only. A direct violation of CLAUDE.md §2 (docs must track the change that touched them) on live, user-facing docs — R-608 addresses it but it is currently false. *(The Polish quotation previously attributed to CLAUDE.md here was fabricated; the thesis stands, the quote never existed.)*
- ⚠️ README/CHANGELOG U-015 AND ROADMAP R-1002 ('pushed to both remotes') claim a synced GitLab mirror; the repo has a single origin=GitHub remote. The phantom mirror now appears in TWO synced docs, contradicting the actual remote config. R-006 addresses.
- ⚠️ SECURITY.md/README advertise CodeQL + gitleaks + cargo-audit scanning and minisign release-signing as active security posture; all run only via GitHub Actions, which is disabled account-wide, so none execute and even manual downloads have no live signed checksums to verify. R-003/R-005 address; currently inconsistent.
- ⚠️ release/SHA256SUMS (dated Jul-5) lists eos-0.1.0-<arch>.img that exist nowhere; the real output is build/<arch>/eos/harddrive.img (1400 MiB, rebuilt Jul-11/12), so install.md's sha256sum -c / dd steps reference a non-existent file and would fail even after a rename (checksums must be regenerated). R-002/R-003.
- ✅ ~~docs/install.md:81 and desktop docs describe 'the COSMIC desktop' … No R-Dxx item schedules a correction of this overclaim.~~ **RESOLVED 2026-08-15 (`U-127`, `R-D12`).** The finding was right about the fact — `cosmic-comp` runs on neither arch, the session is orbital + eos-orbutils with COSMIC apps as clients, and `wayland.toml` is unused — and right that nothing scheduled the fix. Both halves are now closed: the overclaim is corrected across README (including its Core-Components table and banner tagline), `EOS_BUILD_STATE.md`, six `docs/` pages, `config/x86_64/eos.toml`, `NOTICE`, `assets/eos-banner.svg`, the GitHub issue template and ROADMAP; `cosmic-comp`'s absence is a recorded entry in `docs/known-issues.md`; `config/wayland.toml` is marked UNUSED in place; and `R-D12` records it. *(Two details of the original wording were off: the line number was `:86`, not `:81`, and "desktop docs" were **not** guilty — `design-desktop-environment.md` and `screenshots.md` already described orbital honestly and supplied the wording used for the fix.)*
- ⚠️ docs/hardware-matrix.md marks ac97d and vboxd (and initfs ahcid/ided on aarch64) as '▫ Present'; those binaries are absent from the build tree entirely, so a matching device would fail Command::new and stay unbound — the rows are factually wrong (binary absent), not merely 'unverified'. R-803 validates presence at bind time but no item corrects the matrix doc itself.
- ✅ ~~usbnetd status is stated three contradictory ways: source main.rs:17-19 *falsely* claims a full bidirectional DHCP handshake, roadmap-connectivity.md marks it done, CHANGELOG U-055 admits RX=0.~~ **RESOLVED 2026-08-17 (`U-130`) — and this finding had the polarity backwards.** The source comment was **right**; the docs were stale. RX=0 was a snapshot from 2026-07-12 01:48; the root cause (xhcid global endpoint numbering — RNDIS bulk IN/OUT are indices 2/3, not 1/2) was found and fixed the same day (`U-056`), the residual xhcid deadlock lifted by `O_NONBLOCK` bulk-IN (`U-057`), and a pcap showed the full `DISCOVER → OFFER → REQUEST → ACK`. The fix is in the shipped image: `eos-base@a3a98fd4` is an ancestor of the pinned `d6336419`. Only the CHANGELOG entries were lost — they live on `origin/archive/pre-migration-de-phase1` and are restored in `U-130`. *(There is also no `U-055` entry in CHANGELOG.md at all — see the 2026-08-15 note.)*
- ⚠️ Working tree is ahead of published origin (README-sync commit ee0f15cd unpushed; main 1 commit ahead), so GitHub shows an older state than the audited docs describe. R-007.
- ⚠️ ~~CLAUDE.md lists i18n key-parity as a mandatory pre-commit gate and Polish as the UI/doc language, so the project is out of compliance with its own stated gate.~~ **WITHDRAWN 2026-08-15 (`U-126`) — the premise was invented:** CLAUDE.md contains no i18n, locale, parity or Polish-language rule (grep returns nothing), and it entered the repo six days *after* this page was written. What survives is a plain gap, not a violation: the shipping shell is English/UTC, four new GUIs are on the roadmap, and no roadmap item establishes i18n scaffolding. See *Coverage gaps* below.

## Overpromises to correct in docs

- 'Daily-driver' framing for v1.0 'Prime' while literally zero real-hardware validation has ever occurred. Every 'boot-verified' claim is aarch64 QEMU-TCG on the Mac; x86_64 is a separate rig; power management is shutdown-only (no S3/S0ix/cpufreq/battery per hardware-triage). A machine that cannot sleep, report battery, or has never touched metal is not yet a daily-driver — the roadmap tiers the hardware honestly but keeps the top-line 'daily-driver' promise ahead of any metal proof.
- Sequencing hazard that reads as a security overpromise: R-701 ('wire a working E-OS-owned update source', P0, depends only on R-002) can land BEFORE R-702 (pin key) and R-703 (verify manifest). Shipping R-701 alone wires an update source that is still TOFU-keyed and serves an unauthenticated manifest — actively worse than today's inert state. The 'signed updates from our source' promise is only true once R-702+R-703 ship WITH R-701, not before.
- R-503 hybrid PQ signing continues to be presented as a delivered marquee win. It is a disconnected build-host prototype: the publisher never emits repo.toml.sig and no client verifies it (R-703 is what would connect it). Until R-703, advertising 'post-quantum-protected updates' is security theater — the digest's own verifier flags this and it must be marked tooling-done / runtime-inert everywhere it appears.
- Design doc places the privileged eos-updated daemon 'into base initfs services'. Putting a network-facing, root-writing update daemon in the initfs (the boot-critical minimal image) inflates initfs trust surface and boot fragility; this placement is asserted, not justified, and likely overreaches — it belongs in rootfs services, not initfs.
- R-610 ('repoint installer build-deps to E-OS forks', effort M) presumes E-OS-controlled forks of arg_parser/liblibc/pkgutils/redoxfs exist or are cheap to create. The 22 existing forks are Redox-authored *packages*; these are build-time git crates pinned to gitlab.redox-os.org. Forking and maintaining the toolchain-dependency layer is plausibly larger than M and is a prerequisite for the 'build from OUR signed source' thesis at the dependency layer.
- R-701 marked effort 'S'. It bundles: generate an off-repo signing key with custody, run the first non-Actions publish, wire /etc/pkg.d/50_eos into both arch configs, AND repoint/remove the default 50_redox upstream source with graceful degrade. That is not Small; underestimating it hides the fact that the whole delivery backend (Foundation A) is the long pole for both flagship subsystems.
- Driver Manager 'detect all hardware' is scoped honestly in the design doc (PCI+USB only, report-only for the rest) but the user-facing 'never hunt drivers online' anti-scam pitch still implies broad coverage. The devices that actually drive users to scam driver sites — Wi-Fi, Bluetooth, GPU, touchpads (I2C-HID, blocked on absent I2C bus) — are exactly the ones with no driver, so the security win must be scoped to wired PCI/USB or it overpromises.

## Top risks

- 🔴 Two physically separate critical paths, and the metal one has done ZERO hardware testing. x86_64 parity + 100% of real-hardware validation (installer on real firmware, drivers on real silicon, FDE, TPM, Wi-Fi/BT, S3, 4Kn disks) are all blocked on a single Windows/WSL x86 rig that has never validated anything on metal, with dead CI to automate it. The daily-driver goal's longest pole is entirely off the Apple-Silicon dev loop and unproven.
- 🔴 Live default-credentials exposure in every shipped image TODAY: eos.aarch64.toml:82/:106 bake a passwordless `user` and root/password, and docs tell users to fix it by hand. Post-FDE-unlock this defeats the whole encrypted-daily-driver premise. R-602 OOBE gates it but every release until then is exposed — arguably higher live severity than the un-wired update path.
- 🔴 Trust-chain ordering: wiring an update/driver source (R-701) before pinning the key (R-702) and verifying the manifest (R-703) makes security strictly worse — TOFU key fetched from the package host + unauthenticated per-package manifests + default source still pointing at upstream static.redox-os.org enables MITM/rollback/freeze on first contact. The one root-of-trust flaw the digest elevates (unpinned TOFU key, not just the unsigned manifest) must be fixed first or the flagship 'signed source' becomes a liability.
- 🔴 New privileged remote attack surface on a young microkernel: a root eos-updated daemon with a /scheme control API plus a DOWNLOADABLE driver catalog fed into a matcher that panics on malformed input (i64::from_str_radix().unwrap(), R-803) — a hostile catalog entry bricks ALL boot-time driver binding. Same unchecked-arithmetic class recurs (pkgar read_at, raid1d byte_off); a single clippy::arithmetic_side_effects + catalog-signing gate is higher-leverage than point fixes.
- 🔴 Bus factor / single-substrate reproducibility: effectively one maintainer, dead CI (all builds/scans/publishes manual), and nearly every 'verified' claim resting on aarch64 QEMU-TCG. Regressions in wired-net, x86_64, and anything not in the default dev-loop boot go unnoticed (e.g. default aarch64 virt boot has no NIC, so netstack isn't even exercised).
- 🔴 Scope realism: the flagship trio is deep greenfield — native Settings shell (XL), update system with staged apply + journaled rollback + apply-on-reboot (XL+XL+XL), driver manager with per-driver repackaging across three catalog owners and two image roots (L) — layered on a substrate with open defects (virtio-rng driver deleted, no I2C bus, no GPU accel; *two items were listed here in error and are now closed — the netsurf ET_EXEC crash per the 2026-07-23 note, and usbnetd RX=0 per `U-130`*). High risk of over-commitment against the v0.2.0 (2026-07) and v1.0 horizons.
- 🔴 Freshness/anti-rollback without trusted time: R-704 depends on timestamps but there is no NTP/RTC-sync source, so freshness enforcement is unreliable and downgrade protection reduces to the monotonic index alone — an unstated dependency that weakens the update-security guarantee.
- 🔴 pkgar single-key trust with no on-device rotation/revocation (R-711 is only P2): a compromised signing key cannot be distrusted from inside the OS, and the R-503 PQ migration has no enforcement hook — a structural weakness underneath the entire signed-delivery story.

## Highest-leverage next actions (Mac-doable)

- Ship the cheap trust-gating fixes sitting in reused code first: R-F01 (delete the two plaintext-password println! in eos-installer — the case the `scripts/ci-integrity.sh` guard exists for; CLAUDE.md itself states no such rule, so the guard *is* the rule), R-F03 (fix pkgar-core read_at truncation panic + checked_add on offset+header_len, with a truncated-package unit test), and R-F04 (raid1d checked_add + generalized fallback) — then turn on clippy::arithmetic_side_effects to catch the whole unchecked-arithmetic class repo-wide.
- R-005 + R-001 + R-002 + R-003 together: stand up launchd-timed gitleaks/cargo-audit/cargo-deny + a `println!.*password` grep gate (replacing dead Actions), write the reality-ledger verification matrix, add a local `make release` that regenerates SHA256SUMS over the ACTUAL harddrive.img and minisigns locally, then downgrade every false CI-build / live-Pages / scanning-active / GitLab-mirror claim in README/SECURITY.md and fix install.md's phantom-artifact verify/dd steps.
- R-D01: begin the native orbital/orbclient E-OS Settings shell (no libcosmic/fontconfig/gperf, so it builds on the aarch64 host and dodges both the host-toolchain 404 and dead CI). It is the single hard dependency under Settings→Update (R-708) and Settings→Drivers (R-806); nothing flagship-visible can ship without it. Decide the i18n string-catalog format at the SAME time — not because a gate demands it (none exists), but because it is the last moment it is cheap.
- Fix the update TRUST CHAIN before wiring the source: implement R-702 (pin the E-OS pubkey into the image, enforce https:// in add_remote, verify the pubkey-cache provenance, kill TOFU) and R-703 (publisher emits repo.toml.sig via eos-repo-sign; pkg-lib verifies it before trusting any per-package toml) — and only then land R-701 (generate key, first non-Actions publish, wire+repoint /etc/pkg.d off the upstream 50_redox default). Ordering is the security control here.
- R-601 → R-602: build the QEMU install-to-second-disk boot-verify harness (prove partition→install→reboot→greeter on aarch64) and the first-boot OOBE wizard that forces a password change — closing the daily-driver install claim AND retiring the live passwordless-user/root:password exposure that FDE cannot mask.
- R-801 + R-803: build eos-devd (/scheme/devices read-side inventory, buildable on aarch64/QEMU now) and harden the pcid matcher against untrusted catalog input — replace the from_str_radix().unwrap(), reject unsigned/oversized/duplicate entries, and validate binary presence to kill the dead ac97d/vboxd/ahcid/ided catalog rows before any catalog becomes downloadable.
- ~~R-901: fix usbnetd RX=0~~ — **not a bug** (`U-130`): fixed 2026-07-12, code in the shipped pin, records restored. The genuine residual is re-running the pcap against a current image, which rides along with the next `build-image`.
- Add the two missing scaffolding items now, before GUIs proliferate: an i18n string-catalog + key-parity check (a gate worth *adding* — contrary to what this page used to claim, none exists today) and a threat-model.md update covering the new privileged eos-updated/eos-devd daemons and their /scheme control APIs — both are pure-Mac work and cheap now, expensive to retrofit.

## Coverage gaps the roadmap must not forget

- i18n/l10n workstream is entirely absent. *(Corrected 2026-08-15, `U-126`: this bullet used to justify itself with a fabricated CLAUDE.md quote — 'Parytet i18n (wszystkie języki mają te same klucze)' — and a claimed mandate for Polish docs/UI. No such rule exists in CLAUDE.md, in `lefthook.yml`, or in any CI job. The gap is real on its own merits; the "project's own gate" argument was not.)* The roadmap adds four brand-new GUIs (R-D01 Settings shell, R-708 Update pane, R-806 Driver Manager, R-902 Network pane) with zero localization scaffolding — no string-catalog format, no key-parity check, and the shipping clock is UTC-only English. Retrofitting localization across four shipped GUIs is markedly more expensive than choosing a catalog format before the first one lands; that, not a rule violation, is the argument for doing it now.
- No trusted-time / NTP source. R-704 anti-rollback freshness leans on a 'monotonic index+timestamp', but there is no RTC-sync or NTP client anywhere (clock is UTC HH:MM, no date). Without trusted time, timestamp-based freshness is unenforceable and the index becomes the only real anti-rollback signal — this dependency is never surfaced.
- No recovery/rescue path. R-707 gives apply-on-reboot with boot-fallback for kernel/base, but there is no offline rescue console / repair-from-install-media flow for a system that is broken but still boots (bad non-base update, corrupted config, forgotten FDE password). A daily-driver needs a documented recovery story; none exists.
- No fuzzing / parser-hardening workstream for attacker-controlled input. pkgar headers, per-package *.toml manifests, and the future downloaded driver catalog (R-802) are all parsed from untrusted network data, and the tree already has a live parse panic (pkgar read_at, R-F03) and an unwrap-panic matcher (R-803). A cargo-fuzz/proptest gate over pkgar-core + the catalog loader is missing as a standing item.
- No threat-model update item for the new privileged surface. eos-updated runs privileged with a /scheme/eos-update control API, eos-devd exposes /scheme/devices, and the driver catalog becomes downloadable untrusted input — none of docs/threat-model.md, security.md, or hardening.md has a roadmap item to extend the model to these new daemons/schemes.
- No accessibility (a11y) consideration for any GUI — no screen-reader/keyboard-nav/contrast requirements on the Settings/Update/Driver/Network panes.
- No SBOM-regeneration or release-notes-generation process. SBOMs exist only for 0.1.0 as static files; R-002 make-release does not include regenerating CycloneDX SBOM per build, so SBOMs will silently go stale as packages change.
- No keymap/keyboard-layout infrastructure behind R-603's 'pick keyboard layout' installer step — Redox keymap support is thin, so collecting the choice may have nothing to apply it to (latent overpromise inside an installer gap).
- No user-data backup / migration story (home dirs, config) across reinstalls or A/B updates.
- No mapping defined from the roadmap's R-NNN codes to CLAUDE.md's mandated sequential [U-NNN] CHANGELOG numbering; R-F05 only patches the existing U-038 gap / duplicate U-039 but the going-forward numbering scheme for all this new work is undefined.
