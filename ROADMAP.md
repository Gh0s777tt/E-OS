# E-OS Roadmap

**Last reviewed:** 2026-09-03 · **Owner:** Gh0s777tt · **Status:** current · **Language:** English
**Tree state, measured 2026-09-03:** branch `main` = `02cfbb283`. 85 merge requests merged, none open.
`scripts/verify.sh`: **18 stages, 18 PASS, 0 FAIL, 0 SKIPPED** — on the `eos-heavy` runner as the
`local-gates` job, not only on a laptop (`TQ-011`).
`scripts/eos-repos.sh pins --strict`: **30 OK, 0 drift** (was 26 — seven repositories were added on
2026-09-03 and one fork pin moved).
`scripts/ci-integrity.sh`: **19 checks** plus the instrument probe as check 0.

> **A rendered view of this file lives at [`docs/roadmap/index.html`](docs/roadmap/index.html)** and is
> published by the `pages` job at `/roadmap/`. It is a *view*, not a second plan: check 19 compares the
> marks it shows against §3.4 at every integrity run, so the two cannot drift apart in silence.

> **This file replaces both predecessors: the time-ordered `ROADMAP.md` and the subject-ordered,
> Polish-language `ROADMAP-v2.md`.** Each of those two documents declared the *other* retired —
> a loop that made both unciteable. The loop is closed here: this is the single roadmap and the
> single place where the status of an identifier is maintained. Its Polish substance is
> **translated** into this file, not summarised. From 2026-08-31 `ROADMAP-v2.md` was a short
> redirect stub pointing here; on 2026-09-03 the owner asked for **one** roadmap file and the stub
> was removed ([Annex C](#annex-c--retired-documents-and-retired-identifiers)); its
> full text remains in git at `87e8194b1`.

This project's own rule applies to its own roadmap: **a control that cannot fail is not a control,
and a plan that cannot be falsified is not a plan.** Every row below carries evidence — a commit,
a `U-NNN` changelog entry, a file and line — or an explicit `[UNVERIFIED]` marker naming the command
that would settle it. Rows that were wrong are corrected in place with the correction left visible,
because the retraction record is the reason the register is worth reading.

---

## Contents

**How to read**
- [0. Reading instructions](#0-reading-instructions)

**The time view — scheduling only, no status of its own**
- [1. Delivered](#1-delivered) — incl. [1.4 Gate-quality audit](#14-gate-quality-audit-2026-09-02)
- [2. Release milestones ahead](#2-release-milestones-ahead)
- [3. Now, next, later](#3-now-next-later) — starts with [3.0 What is left, ordered from the quickest to the heaviest](#30-what-is-left--every-open-item-ordered-from-the-quickest-to-the-heaviest)
- [4. Where work can happen](#4-where-work-can-happen)

**The subject register — the single source of status**
- [5. Trust chain: boot, package channel, keys](#5-trust-chain-boot-package-channel-keys)
- [6. Installer, wizard and updates](#6-installer-wizard-and-updates) — incl. [6.6 first-boot credentials: password quality and PIN](#66-first-boot-credentials-password-quality-and-pin--r-602ar-602f)
- [7. Desktop shell and applications](#7-desktop-shell-and-applications) — incl. [7.5 products: in the image, on Windows and Linux, and the four new ones](#75-products--in-the-image-on-windows-and-linux-and-the-four-new-ones--pr-)
- [8. Drivers and hardware](#8-drivers-and-hardware)
- [9. Security posture by audit finding](#9-security-posture-by-audit-finding)
- [10. Correctness and regression register](#10-correctness-and-regression-register)
- [11. Platform, process and release](#11-platform-process-and-release) — incl. [11.4 everything on E-OS](#114-everything-on-e-os-the-server-edition-and-the-cloud-platform--cs-), [11.5 the project website](#115-the-project-website--ws-), [11.6 a documented system API](#116-a-documented-system-api--api-)
- [12. Standards and compliance](#12-standards-and-compliance)
  - also in 11: [11.3 testing, coverage and the automation to add](#113-testing-coverage-and-gates--the-standing-state-and-the-automation-to-add--tq-) · [11.7 repository hygiene](#117-repository-hygiene--what-left-the-tree-what-waits-for-the-owner-what-keeps-it-clean--rh-)

**What we do not claim**
- [13. Dropped and refused](#13-dropped-and-refused)
- [14. What this plan deliberately does NOT promise](#14-what-this-plan-deliberately-does-not-promise) — incl. [14.7 about "everything on E-OS"](#147-about-everything-on-e-os-the-server-edition-the-cloud-platform-and-the-website)
- [15. What has not been verified, and the command to verify it](#15-what-has-not-been-verified-and-the-command-to-verify-it)
- [16. Vision and positioning](#16-vision-and-positioning)

**Merged plans — carried in full from `docs/archive/` on 2026-09-03**
- [17. Who E-OS is for, what security model it builds, and the order of work](#17-who-e-os-is-for-what-security-model-it-builds-and-the-order-of-work)
- [18. The road from QEMU to a physical computer](#18-the-road-from-qemu-to-a-physical-computer)
- [19. Connectivity: USB, wired LAN, Bluetooth](#19-connectivity-usb-wired-lan-bluetooth)
- [20. Delivered capability plans, kept for their scope](#20-delivered-capability-plans-kept-for-their-scope--r-50x-and-the-acpi-off-removal)
- [21. The fourteen feature proposals of 2026-07-13, and what became of each](#21-the-fourteen-feature-proposals-of-2026-07-13-and-what-became-of-each)

**Annexes**
- [Annex A — full identifier index](#annex-a--full-identifier-index)
- [Annex B — identifier collisions and decisions D1–D7](#annex-b--identifier-collisions-and-decisions-d1d7)
- [Annex C — retired documents and retired identifiers](#annex-c--retired-documents-and-retired-identifiers)

---

## 0. Reading instructions

### 0.1 One legend, and only one

The two predecessor documents between them used **three** status alphabets, and the old
`ROADMAP.md` used two of them inside a single file — the header declared `✅ 🚧 📋 ❌` while its own
`R-*` registry used `✅ 🚧 ⏳ 💡 ❌`. That is resolved. This document has exactly one set:

| glyph | meaning |
|---|---|
| ✅ | **done** — with evidence in the tree, in a commit, or in a `U-NNN` entry |
| 🟡 | **partial** — some halves delivered and named, others open and named |
| 🔴 | **planned** — accepted work, not started or not finished |
| 💡 | **idea** — not scheduled; usually blocked on a substrate that does not exist |
| ❌ | **withdrawn** — with the reason, kept rather than deleted |

Mapping from the old alphabets, applied throughout: `🚧 → 🟡`, `⏳ → 🔴`, `📋 → 🔴`.

**Where the work can happen** — this is a separate axis from status and mixing them is how
"planned" silently came to mean "impossible here":

| marker | meaning |
|---|---|
| 🖥️ | the Apple-Silicon dev host: podman + QEMU/TCG |
| 🐧 | needs Linux or WSL2 (or a KVM runner) |
| ⚙️ | needs physical hardware; **QEMU cannot settle it** |
| 🔑 | needs an action by the operator (keys, accounts, legal entity) — never automated |

**Work notation** `[priority·size·where]`, e.g. `[P0·M·🖥️]`. Priority `P0`–`P3`, size `XS`–`XL`.

**Capability marker** — carried on every item that promises a mechanism, taken from the four
installer specifications. Without this column a register quietly promises a Linux installer on a
system that has none of the Linux parts:

| marker | meaning |
|---|---|
| **WORKS TODAY** | exists and runs, with file:line, binary name or `U-NNN` evidence |
| **BUILDABLE** | can be built on Redox with no new subsystem |
| **NEW SUBSYSTEM** | needs something Redox does not have at all |
| **NOT FEASIBLE TODAY** | depends on an ecosystem that does not exist and will not soon |

### 0.2 Structure: one register, one view over it

The two predecessors were not two versions of one document. They were **two indexes over one body
of work** — one by *when*, one by *subject* — and trying to linearise them is what produced the
mutual-supersession loop. The fix, applied here:

- **The subject register (§5–§12) is authoritative.** Every identifier has exactly one row, in
  exactly one place, holding its status, its evidence and its capability marker.
- **The time view (§1–§4) is derived.** "Delivered", "Short/Mid/Long term" and the installer
  milestones M1–M8 *reference* register ids and carry only scheduling columns — priority, owner,
  effort, where, traces-to. They restate no status.

Every contradiction catalogued during this merge came from a status living in two places. That
cannot recur in a document with one register.

### 0.3 Identifier namespaces, and the three collisions

Eleven namespaces are live in this project (five were listed here until 2026-09-03). Two of them collide with documents outside the register,
and one collides with the audit. **A reader who meets `R-704` or `R-802` without knowing this will
misread it**, so this is a reading instruction, not a footnote.

| namespace | what it numbers | where it is defined |
|---|---|---|
| `R-*` | the work register — features, subsystems, defects | this file (§5–§12) |
| `V2-*` | Secure Boot milestones, storage drivers, buses, security suite, notebook, standards | this file (§5.2, §7.3, §7.4, §8.3, §12) |
| `S-*` / `M-*` / `L-*` | scheduling rows on the time axis, traced to audit findings | this file (§3.1–§3.3) |
| `EA-*` / `EB-*` / `EC-*` | installer / wizard / live-update epic backlog (**renamed this merge**) | this file (§3.5) |
| `C-*` / `G-*` / `A §…` | audit findings | [`docs/audit/`](docs/audit/) |
| `CS-*` / `WS-*` / `API-*` / `PR-*` | cloud and server edition · website · system API · products | this file (§11.4, §11.5, §11.6, §7.5) |
| `TQ-*` / `RH-*` | test and security-coverage automation · repository hygiene | this file (§11.3, §11.7) |
| `M1`…`M8` · `EP-*` · `E0`…`E8` · `D1`…`D7` · `T2`…`T4` · `Q1`…`Q15` | installer milestones (no hyphen — §3.4) · installer epics (§6.1) · update-system stages (§6.4) · Annex B decisions · hardware tiers (§8.4) · owner decisions (§3.0.7) | tokens, not register rows: they carry no status of their own |

**The three collisions, all confirmed in the tree this session:**

1. **`R-70x`** — [`docs/architecture/update-system.md`](docs/architecture/update-system.md) lines
   172–179 use `R-701`…`R-708` for *different work* than the register does. `R-704` means
   "rollback" there and "**anti**-rollback" here — near-opposite meanings.
2. **`R-80x`** — [`docs/architecture/driver-manager.md:16`](docs/architecture/driver-manager.md)
   states verbatim: *"Scope codes: R-800 … R-814 (this document defines the range)"* — fifteen
   numbers reserved for meanings the register does not share.
3. **`A-*`/`B-*`/`C-*` versus the audit's `C-1`…`C-21`** — in the old epic tables `C-1` meant
   "publish the x86_64 repository"; in [`docs/audit/03-security-audit-2026-08-30.md`](docs/audit/03-security-audit-2026-08-30.md)
   `C-1` means "pin the upstream package key". Neither predecessor named this collision.
   **Resolved here** by renaming the epic namespace to `EA-*`/`EB-*`/`EC-*` (§3.5, Annex C).

**The register's numbering wins** for collisions 1 and 2 (decision **D1**, Annex B). The two design
documents keep their numbers and gain a banner. Full analysis, the measured non-uniform offsets and
decisions **D1**–**D7** are in [Annex B](#annex-b--identifier-collisions-and-decisions-d1d7).

### 0.4 What counts as evidence

- **A green build is not evidence.** Measured three times in one day (`U-224`): the build succeeded
  and the change was absent from the artefact, because `make` does not rebuild host tools.
- **Evidence is the artefact**: `strings` on the binary, `grep` on the generated file, the image
  mounted and read, the pcap, the screendump. Not the exit code.
- **Every control needs a negative test.** Where an item claims a gate, the row says how the gate
  was seen to fail. A gate never seen red is a hypothesis.
- **`[UNVERIFIED]`** means: not confirmed in this tree. Every such marker is followed by the command
  that would settle it. §15 collects them.
- **⚙️ never counts as verified from QEMU.** Firmware, 4Kn disks and real silicon are settled on
  metal or not at all.

---

## 1. Delivered

The reader meets evidence before plans. These three tables are the hardest part of the document to
reconstruct — raw commit hashes and `U-NNN` keys — and they are the only place several `V2-MS*`
milestones appear as *delivered with evidence* rather than as design rows.

### 1.1 v0.1.0 — "Genesis" (2026-06-07)

| Item | Evidence |
|---|---|
| E-OS identity, branding, security and automation baseline | `cad6d4895` |
| Build configuration and OS-level rebrand | `0d14ebc12` |
| Red/black bootloader theme, greeter and wallpaper, built from source | `897fa66d6`, `5dc7e14e9` |
| Console login branded `eos login:` | `919a84809` |
| aarch64 desktop configuration | `82af7a440` |
| Recipes repointed at E-OS source forks | `4a09cf7c3` |
| CycloneDX SBOM, checksums, release pipeline | `f17427863` |
| minisign-signed release checksums + public key | `630d98e40` |
| Threat model, hardening and disk-encryption guides | `5f61baeef` |
| mdBook documentation site | `60d938127` |
| `time` bumped for CVE-2026-25727 | `0d90e5c71` |

### 1.2 v0.2.0 (2026-08-22)

233 commits; 82 recorded changelog entries. Highlights, each traceable:

| Item | Evidence |
|---|---|
| **eos-notes** — first E-OS application (Slint + SQLite/WAL) | `U-086` |
| **eos-ui** — shared Slint-on-Orbital backend | `U-088` |
| **eos-guard** — filesystem integrity monitor | `U-089` |
| **eos-sysmon** — system monitor | `U-094` |
| **eos-control** — unified control centre; supersedes guard + sysmon as shipped apps | `U-095` |
| Control centre panes: processes, storage, network, power, sound | `U-096`–`U-113` |
| Desktop: launcher search, clock, status tray, notifications, screenshot | `U-098`–`U-102` |
| NetSurf built from source as PIE — **regressed in the shipped artefact**, see `R-D06` / #28; the row stays as the v0.2.0 record | `U-103`, `U-105` |
| Graphical and text OOBE forcing a password on first boot | `U-076`, `U-077`, `U-079` |
| Secure Boot: bootloader signed, live ISO and installed system proven | `U-206`–`U-208` |
| Supply chain: every fetched build binary SHA256-pinned | `U-118` |
| Unsigned publish requires an explicit opt-in | `U-120` |
| Upstream package source no longer shipped active | `U-143` |
| Raw IP sockets removed from unprivileged users | `U-144` |
| Repo type enforced from the manifest; first x86_64 build and boot | `U-169` |
| Install proven end to end: partition → install → reboot → login | `U-176` |
| First signed repository, verified both ways | `U-198` |

### 1.3 Since v0.2.0 — unreleased

| Item | Register id | Evidence |
|---|---|---|
| SBAT stamped into both UEFI bootloaders **before** signing | `V2-MS01` | `U-218` |
| Bootloader verifies kernel and initfs by signature | `V2-MS02` | `U-212` |
| Hermetic Secure Boot signing (`sbsigntool` from the base image, no `apt-get` at cook time) | `V2-MS05` | `U-218` |
| Package-signing-key guard; false premise corrected | `V2-MS12a` | `U-213` |
| blake3 from the signed index enforced on installed bytes | `V2-MS13` | `U-223` |
| `pkg install` authenticates the index too | `V2-MS14` | `U-223` |
| Rollback and freeze protection in the index (`serial`, `expires`) | `V2-MS15` | `U-223` |
| Repo-signing key pinned in the image, key pair verified | `R-702` | `U-224` |
| Kernel `Iopl` privilege fix — raw port I/O requires root | — | `U-219` |
| POSIX.1-2024 measured end to end: 4267/5650 | `V2-STD01` | `U-220`–`U-222` |
| Full audit: inventory, code, features, security, gaps | — | `U-224`, [`docs/audit/`](docs/audit/) |
| First non-Actions signed repository publish — 78 packages, 893 MB, live | `R-008` | `U-209` |
| `50_eos` wired and active on aarch64, pinned key measured in the running image | `R-701` (half) | `U-210` |
| M1 installer work merged and pinned: `eos-installer` → `74726c889b`, `eos-pkgutils` → `ec08f22aa6` | `R-611a`, `R-607a`, `R-612a` | 2026-08-30 |
| `R-601c` proven on **x86_64**: install-smoke runs medium → install → boot, exit 0 | `R-601c` | #6, #24 |
| Exactly one getty per serial console on both arches — the second `login` was eating typed input | — | #24 |
| Encrypted-install case in the harness, with its own negative control | `R-601e` (part) | §1.4 |
| **Gate-quality audit**: 328 agents over every script, CI file, hook and makefile; 34 confirmed defects fixed | — | §1.4 |
| **One roadmap file**: six archived plans merged in full (§17–§21), `ROADMAP-v2.md` removed, 48 citations rewritten | `RH-001`, `RH-002` | 2026-09-03, §11.7 |
| Three new integrity gates, each red on its first run: roadmap structure (16), assets (17), `SUMMARY.md` (18) | — | §11.3.1 |
| `CLAUDE.md` §5.11: every change kind has a named check; §9 corrected (`verify.sh` exists) | — | 2026-09-03 |
| Products measured off-Redox: `eos-ui`/`eos-notes`/`eos-control` `cargo check` clean on macOS; no host window backend; `eos-ui` pinned from the GitHub mirror | `PR-006`, `PR-007` | §7.5.2 |

> **Correction carried forward, not quietly dropped.** `ROADMAP-v2.md` §9 opened by stating that
> `ROADMAP.md` "counted 143 items: 67 done, 16 in progress, 43 planned, 16 ideas, 1 withdrawn …
> all 75 unfinished ones are below." Neither number matched the file it described: the predecessor
> registry held **110** entries, 68 of them unfinished. `ROADMAP.md` had been rebuilt *after* v2
> quoted it. That sentence is not carried forward; this document is its own census, and
> [Annex A](#annex-a--full-identifier-index) is the proof.

### 1.4 Gate-quality audit (2026-09-02)

Two multi-agent rounds read **every** gate in the repository and asked one question of each:
*can this check fail?* Round 1 covered all 65 scripts (7539 lines as they stood that morning; the fixes below have since
lengthened them) and `.gitlab-ci.yml`;
round 2 covered the eight GitHub Actions workflows, `.pre-commit-config.yaml`, `lefthook.yml`,
`scripts/hooks/pre-push`, `Makefile` with `mk/*.mk`, and `tools/eos-repo-sign`.

**328 agents · 101 raw findings · 34 confirmed** after three independent adversarial verifiers
per finding (67 refuted). Each fix below carries a measurement in both directions — the state
before, the state after, and a negative control showing the gate now goes red for the right
reason. Two of the fixes were found by their own gate immediately after it started working.

| gate | what it could not do | how it was measured |
|---|---|---|
| `scripts/hooks/pre-push` | secret scan **failed open**: no `gitleaks` on PATH skipped the whole `if`, exit 0 | before: status 0 and **zero** mentions of gitleaks in the output |
| `ci-integrity.sh` check 9 (R-701a) | matched the config's own **comments**, so it could not fail on any config built from that template | replace the one real key pin with a decoy → still `ok`; after the fix → `FAIL` |
| `release.yml` | signed and attested releases with **no executed verification** — `cosign verify-blob` existed only in a comment | cosign stub: signing with a drifted identity → 0; with the new step → 1 |
| `eos-build.sh` Secure Boot gate | `for` over zero matches ran zero times, `rc` stayed 0 | directory hidden → status 0 and **zero lines of output**; after → status 1 |
| `eos-sign-bootloader.sh` | printed the *selftest* message in **real signing** mode and exited 0 | real mode, no artefact: before 0, after 1 |
| `ci-boot-smoke.sh` | its own documented invocation reported success **without entering the loop** | bash 3.2 exits a script **0** on `set -u` inside `$(( ))` — `echo "$UNSET"` → 1, `x=$(( 1 + UNSET ))` → **0** |
| `eos-build.sh` make step | `make \| tail -3` across the container boundary returned `tail`'s status | `bash -lc "false \| tail -3"` → 0; with `pipefail` → 1 |
| `ci-integrity.sh` checks 12–15 | nested inside check 11's `else`, so they ran only while check 11 passed | before: 10 `ok` lines and none of the four; after: 14 |
| `eos-repos.sh` `pins --strict` | returned 0 having compared **no forks**, printing `pins ok=0` while doing it | empty manifest: before 0, after 1 |
| `repro-intx-lines.sh` | the boot-regression GUARD ended in an unconditional `exit 0` | forced failure: before 0, after 1 |
| `eos-check-tar-pins.py` | an unparseable recipe vanished from the closure through two compounding silences | broken TOML: 77 → 76 recipes walked, still `ok` |
| `eos-check-doc-paths.py` | a URL anywhere in a line disabled the check for that whole line | narrowing it immediately found a real dead reference in `.github/workflows/docs.yml:6` |
| `eos-check-repo-types.py` | a `type` outside `"ABCD"` was compared with nothing yet counted as checked | type `Z`: `OK — 31 repositories, types agree`, status 0 |
| `eos-mirror-drift.sh` | repositories it could not measure did not affect the exit code | a permanent failure looked exactly like a transient network one: green |
| `sync-forks.sh` | `git rev-parse` on a missing ref prints the **argument itself** on stdout, so `u` was two lines | an up-to-date fork was **never** reported as such |
| `eos-sync-buildtree.sh` | staged in a pipeline subshell: failed `cp` ignored, missing files dropped silently | comparison ran on a smaller set than the count it had just printed |
| `mk/prefix.mk` | `rm -f …/rust-src-install.tar.xz**:**` deleted a file that never existed | the real tarball survived every toolchain version change |
| `mk/repo.mk` | `$(MAKE) mount; touch …` — the semicolon threw the mount's status away | a failed mount left the success tag behind |
| `mk/podman.mk` | `EOS_STRICT_FETCH=1` never reached the container where the fetch happens | `podman run` without `--env`: `EOS_STRICT_FETCH=<unset>` |
| `mk/config.mk` | capability detection lost to a command-line flag (GNU make precedence) | `make PREFIX_BINARY=1 SCCACHE_BUILD=1` left both at **1** despite both "not found" messages |
| `make-release.sh`, `.gitlab-ci.yml` | a **signed** SBOM could list nothing; `ls -la` on a just-created directory cannot fail | `gen-sbom.py` on an empty dir: exit 0, valid CycloneDX, `"components": []` |

**What this unblocks.** Not new features — the ability to believe the existing ones. Concretely:

- **`R-601c` is closeable at all.** The x86_64 harness passed 2 runs in 7 before #24; 6 in 6 after.
  Without that, no x86_64 row in M1 could rest on evidence.
- **Nightly CI becomes worth reading.** `eos-build.sh` returning `tail`'s status meant a failed
  build reported success; four `ci-integrity` checks ran only in one branch; the boot gate could
  report success without starting. A green nightly now means more than it did.
- **The release signature means what it says.** The pipeline verifies its own `cosign` bundles
  against the identity it publishes, and refuses an SBOM with no components.
- **The pre-push secret scan actually blocks.** It was the last line before a secret reached the
  mirror, and it was failing open.
- **`EOS_STRICT_FETCH=1` can now be set in CI** and will do something — closing the "Remaining"
  note on `S-7`/toolchain pinning rather than leaving a flag that silently does nothing.

**What this does not do.** It does not add a single feature, does not touch the kernel, and does
not change what the images contain. Four host traps were recorded (`CLAUDE.md` P-12…P-15); the
audit's own completeness critic named `tools/eos-repo-sign`'s `verify()` as still untested.

---

---

## 2. Release milestones ahead

History is in §1; this is the forward table. It restates no status — each row points at the
register rows that decide it.

| version | what it brings | gate on it |
|---|---|---|
| **v0.1.0 "Genesis"** | Redox base on the new upstream, boot to login, AGPL licence | ✅ shipped (§1.1) |
| **v0.2.0 "Identity"** | Crimson desktop, OOBE password enforcement, branding, rebranded strings | tagged; `R-201`, `R-207` still open |
| **v0.3.0 "Fortify"** | signed images, SBOM, reproducible release pipeline | signatures done; `R-303` / `V2-MS07` / `V2-MS08` open |
| **v0.4.0 "Reach"** | x86_64 parity, hardware matrix, full driver coverage | `R-402`, `R-403`, `R-607b`, `R-923` |
| **v1.0.0 "Prime"** | stable ABI, LTS policy, package repository | `R-1002` (ABI commitment), `R-1003` (x86_64 publish + ecosystem) |

**Rule that governs the ordering, taken from `system-updates.md` §9 and applied to every milestone
in this document:** *each milestone leaves the system better even if the next one never happens.*

---

## 3. Now, next, later

Scheduling only. Status lives in the register; the **Item** column links there.

### 3.0 What is left — every open item, ordered from the quickest to the heaviest

The registers below are the source of truth for status; this list exists so the question "what is
actually left, and what do I get for each piece?" has one answer that reads top to bottom. **Order =
cost, rising.** Within a band, the row that unblocks more comes first. Each row says what the change
**adds or changes** — not what it is called. Rewritten 2026-09-03; the previous version (2026-09-02)
listed the blocked items and the owner's decisions, which are now §3.0.6 and §3.0.7.

Bands: **A** minutes to a day · **B** days · **C** weeks · **D** a quarter or more · **E** blocked on
something other than work. Owner marks: 🖥️ doable on this Mac · 🐧 needs Linux · ⚙️ needs hardware ·
🔑 the operator, never a tool.

#### 3.0.1 Band A — minutes to a day

| # | id | what it adds or changes | unlocks | who |
|---|---|---|---|---|
| A1 | `PR-006` | products pin `eos-ui` from GitLab instead of the GitHub mirror; a `ci-integrity` line refuses `github.com/Gh0s777tt` in any type-A manifest | `ADR-0001` holds for the products, not only the recipes | 🖥️ |
| A2 | `TQ-004` | `cargo-audit` and `cargo-geiger` installed and wired into `verify.sh` with install hints | SC-1 and an offline advisory scan; every later `TQ` row | 🖥️ |
| A3 | `TQ-008` | security lints as errors per own crate (`unsafe_op_in_unsafe_fn`, `undocumented_unsafe_blocks`, `missing_docs`, `unwrap_used` in trust code) | `API-003`; SC-1 enforced at compile time | 🖥️ |
| A4 | `PR-007` | a host window backend behind `cfg(not(target_os = "redox"))` in `eos-ui`; Notes and Control open a window on Linux and macOS | `PR-008`; the first product download that is not E-OS | 🖥️ |
| A5 | `RH-006` | hooks actually installed on the development host; `.pre-commit-config.yaml` invoked by lefthook as its header prescribes; a `verify.sh` stage that goes red when they are not | the fail-closed secret scan runs *before* a push, on this machine | 🖥️ |
| A6 | `RH-005` | a lefthook command that refuses a staged cache/sidecar/artefact | `git add -A` cannot sweep a `.pyc` in again | 🖥️ |
| A7 | `RH-003` | the 25 orphan assets cited or moved out; check 17 fails closed on orphans | 1.6 MB of unowned files stop accumulating | 🔑 then 🖥️ |
| A8 | `RH-008` | `docs/architecture/overview.md` folded into `ARCHITECTURE.md`, twelve links rewritten | one architecture entry point | 🖥️ |
| A9 | `S-12` | `eos-pkgutils` bumped for `rustls-webpki`, `ring`, `rand` (six advisories inside `/usr/bin/pkg`) | a clean `osv-scanner` on the package manager | 🖥️ |
| A10 | `S-14` | `osv-scanner` in `.gitlab-ci.yml` and `lefthook.yml`, not only `verify.sh` and GitHub | the same scan in every runner | 🖥️ |
| A11 | `S-20` | SBOM regenerated and committed per tag (`sbom/` holds only 0.1.0) | `V2-MS08`'s "ageing" note closes; releases carry a current bill of materials | 🖥️ |
| A12 | `S-18` | one source of the product version (three disagree: `mk/config.mk:189`, `config/*/eos.toml`, the tag) | `S-20`, `R-611a` naming, the website's "what's new" | 🖥️ |
| A13 | `R-602g` (decision Q2 first) | `redox_users` forked as a type-C repo with `[patch.crates-io]` so runtime hashing is argon2id at the installer's cost — or an upstream MR | #27 closed; `R-602a` can quote one cost | 🖥️ |
| A14 | `R-F28` | `scripts/ventoy.sh` knows `eos` | a repeatable USB medium instead of `dd` | 🖥️ |
| A15 | `PR-001` | product pages generated from `config/*/eos.toml` + `repos.toml` | `WS-008`, `PR-005`; three hand lists stop disagreeing | 🖥️ |
| A16 | `S-15` | apt versions pinned in the three containerfiles | one reproducibility obstacle (`L-3`) fewer | 🖥️ |
| A17 | `M-5` | `semgrep` gating in CI (it is a `verify.sh` stage and a GitHub job; not in `.gitlab-ci.yml`) | SAST in the runner that gates merges, once quota returns | 🖥️ |

#### 3.0.2 Band B — days

| # | id | what it adds or changes | unlocks | who |
|---|---|---|---|---|
| B1 | `TQ-001` | one coverage page for every own crate, generated; floors that can fail | `TQ-010`; the README stops typing numbers | 🖥️ |
| B2 | `TQ-002` | the security-coverage script: SC-1, SC-3, SC-4 measured from the tree; SC-2/SC-5 `SKIPPED` with exit 2 until their tools exist | "security coverage" becomes a number with a floor | 🖥️ |
| B3 | `TQ-003` + `PR-009` | first tests in `eos-ui`, `eos-notes`, `eos-control` (0 today) with `llvm-cov` floors at the first measured value | products enter the coverage page; regressions visible | 🖥️ |
| B4 | `TQ-009` | the scripts' negative tests collected in one suite `verify.sh` runs | every gate's "can it fail?" proof re-runs on every commit | 🖥️ |
| B5 | `R-602a`, `R-602b`, `R-602c` (decisions Q3, Q4) | password meter from the measured hash cost, a blocklist, guidance text in installer, greeter and `passwd` — one policy crate | the owner's password request; `WS-*` account pages reuse the same crate | 🖥️ |
| B6 | `R-602d`, `R-602e`, `R-602f` (Q1, Q5) | PIN as a separate slot for screen unlock with a persisted try counter; encrypted at rest under the FDE key; harness password changed with the floor | the owner's PIN request without weakening FDE | 🖥️ |
| B7 | `PR-005` | the wizard's package-selection screen writing the chosen `[packages.*]` set; the answer file carries it | products switchable at install; server edition installs without a desktop | 🖥️ |
| B8 | `PR-008` | per-OS packages for Notes (Linux tar+checksum, Windows zip+checksum, macOS app zip) and a Linux developer build of Control, signed, listed behind the developer-only toggle, built on the `eos-heavy` runner | the first Windows/Linux downloads | 🖥️/🐧 |
| B8a | `TQ-011` | a `local-gates` job on the `eos-heavy` runner running `verify.sh` on every MR and on `main` — the only runner that has executed anything since 2026-09-01 | the 16 stages judge every merge again instead of failing on quota in 0 s | 🖥️ |
| B9 | `S-8` | `blake3` verified regardless of `is_deps` (`src/cook/fetch.rs:541`) | dependency tarballs stop bypassing the integrity check | 🖥️ |
| B10 | `S-13` | tests for `repo_builder.rs` and `cook/package.rs` (the code that writes and signs the index has zero) | `TQ-006`'s mutation run has something to kill | 🖥️ |
| B11 | `S-16` | a current `git` built for the image (ships 2.13.1 from 2017) | `CS-005`, developer use of the image | 🖥️ |
| B12 | `S-11` + `EC-2` | aarch64 index republished with `serial`/`expires` | freeze protection live on the one published channel | 🔑 |
| B13 | `TQ-007` | negative-input manifests for the three trust crates and the check that reads them | SC-4 with a floor | 🖥️ |
| B14 | `M-9` | mirror-head parity check (`eos-pkg-aarch64` already diverged) | a fork that silently builds stale code is caught | 🖥️ |
| B15 | `M-6` | semantics of `debug`, `memory`, `irq`, `serio`, `sys` for unprivileged users settled; the unnecessary dropped | `M-1` has a defined user namespace to narrow from | 🖥️ |
| B16 | `API-001`, `API-002` | the inherited scheme surface documented from the kernel tree; `.sig`/manifest format written down from `main.rs:193-202` | the "full system API" the owner asked for starts with what exists | 🖥️ |
| B17 | `R-D06`/`R-F30` | NetSurf built from source as a PIE with a gate on the shipped artefact | #28 closed; the browser row stops being an upstream prebuilt | 🖥️ |
| B18 | `R-807` | the persisted "device present, no driver" inventory | the first metal run (E1) produces a list, not a guess | 🖥️ |
| B19 | `R-815` (ATAPI half) | one QEMU run with `-drive media=cdrom` on AHCI: does `ahcid`'s never-run `disk_atapi.rs` read a data disc (§15 row 27) | the optical position in §14.4 becomes a measurement; `PR-022`'s disc-imaging column has a substrate or an honest "no" | 🖥️ |

#### 3.0.3 Band C — weeks

| # | id | what it adds or changes | unlocks | who |
|---|---|---|---|---|
| C1 | `TQ-005`, `TQ-006` | fuzz targets for the trust parsers on a scheduled runner; mutation score on `verify()` | the audit's last named untested function measured | 🖥️ |
| C2 | `PR-004` | E-OS Guard's engine as one crate — `eos-fsintegrity`, a workspace member of `eos-guard` used by `eos-control` at a pinned revision (done 2026-09-04, `eos-guard!6` + `eos-control!6`); the FDE / RAID-1 / repository trust lines shown in Guard's window since 2026-09-05 (`eos-guard!7`, `3bcde7d9`) — in `eos-control`'s Security tab only if decision #19 puts Settings there; `R-306` has no runtime source and is not shown | the security product the owner asked to name; §21 proposal 3 finished for Guard, row 3 stays partly ✅ | 🖥️ |
| C3 | `PR-013` | the app store: metadata in the signed index, a generator in `cookbook`, a browse/install/remove pane | the owner's store request on the trust channel that exists | 🖥️ |
| C4 | `WS-001`…`WS-007` (Q6, Q7) | the static half of the website in a new repo: i18n from the first commit, product pages from `PR-001`, changelog, legal, the developer-only download gate, search, accessibility; hosted locally first, as the owner said | a site that can be shown before any server exists | 🖥️ |
| C5 | `CS-009` → `CS-001` | the `wip/` build gate answers per recipe; a `config/*/eos-server.toml` that installs unattended with a key, no greeter, headless smoke (`CS-010`) | Tier 1 of the cloud plan; `PR-012`'s server | 🖥️ |
| C6 | `M-2` | a persistent audit log daemon with rotation | there is something to read after an incident | 🖥️ |
| C7 | `M-3` / `R-904` | a packet-filter layer over the netstack, or an explicit decision to disable `sshd` by default | the server edition's P0; `WS-005`'s exposure bounded | 🖥️ |
| C8 | `R-801`, `R-802`, `R-804`, `R-805`, `R-806`, `R-817` | `eos-devd`, the signed driver catalogue, per-driver `pkgar`, spawn-on-demand, the Drivers pane, the offline driver bundle | the Driver Manager (§18.4, §21 rows 1/4/10/11) — the owner's requirement C (2026-09-04) in full; scan-on-demand, E-OS-only (§13, §14.5) | 🖥️ |
| C9 | `R-706`, `R-707`, `EC-4`…`EC-6`, M5–M7 | staged transactional apply with rollback; kernel/base on reboot with fallback; the Update pane | `L-1`; a bad update no longer bricks a real install | 🖥️ |
| C10 | `R-601d`, `R-601e`, M2–M4 | GUI↔TUI parity gate; interruption, BIOS and wrong-disk cases; the wizard state machine; profiles and unattended mode | the installer programme's software half closed | 🖥️ |
| C11 | `R-903` | IPv6 end to end (`proto-ipv6`, netcfg, SLAAC, DHCPv6) | modern networks; `CS-004` | 🖥️ |
| C12 | `R-D13` | an i18n catalogue with a pl/en key-parity gate | `WS-002` shares it; the Polish-only strings go | 🖥️ |
| C13 | `PR-010`, `PR-011` | `eos-sheets` (grid, ~40 functions, CSV) and `eos-slides` (boxes, presenter view, PDF export) as new repos on `eos-ui` | the owner's office request, MVP-sized | 🖥️ |
| C14 | `V2-MS04`, `V2-MS09` | the Secure Boot proof as a CI job; the lockdown statement for user-space | shim-review readiness that is code, not paperwork | 🖥️/🐧 |
| C15 | `R-911` | `usbaudiod` (UAC1 out → in → UAC2) | USB headsets; §19.1 row 4 | 🖥️ |
| C16 | `API-003`…`API-006` | rustdoc/pages that actually run; the stability policy; the E-OS-owned API stabilised for 1.0 | `R-1002` | 🖥️ |
| C17 | `PR-020` (Q16, Q17) | the antivirus's on-demand scanner: `boreal` engine (36-crate Redox graph measured, `deny.toml` green on three targets), in the image by default (both `eos.toml`, `optional-apps.toml` entry, headless `EOS-AV-SELFTEST-OK`) and on Linux/Windows via `PR-008`; rule bundle as a data-only pkgar on Redox, minisign-verified download on hosts | the owner's antivirus; the word printed because the thing ships; `V2-S02`'s YARA matcher for free | 🖥️ |
| C18 | `PR-021` | the archiver: 7z r/w solid+AES, ZIP AE-2/ZIP64, tar.*, CAB r/w, ARJ/LHA/ISO read, split volumes, PAR2-class sidecar, scan-before-extract via `PR-020`'s lib, launcher manifest, CLI, WebDAV target — all pure Rust, checked for `x86_64-unknown-redox` on the host; RAR cell waits on Q20 | the owner's RAR/ISO/ZIP request minus the snake oil (§13); the first product that gives Redox a per-entry scan point | 🖥️ (🔑 for RAR) |
| C19 | `PR-021b` | scheduled, restorable backups on the archiver engine; a timer shared with `R-705`; local → WebDAV → `CS-002` targets | `L-4` closed with a register row; the audit's "brak narzędzia i brak harmonogramu" answered | 🖥️ |
| C20 | `R-818`, `R-819`, `R-D16` | the image-backed `disk.image*` scheme, read-only ISO 9660/UDF schemes, and the mount manager with its `eos-mount` shim, Storage pane, polled tray and Eject | a stick or an image mounts on E-OS for the first time; `EC-7`'s medium; `PR-022`'s Redox back-end | 🖥️ |

#### 3.0.4 Band D — a quarter or more

| # | id | what it adds or changes | unlocks | who |
|---|---|---|---|---|
| D1 | `PR-012` | the cloud drive: WebDAV server in Rust on the server edition with quota and server-side encryption; sync client for E-OS, Linux, Windows | the owner's drive request; the first E-OS-hosted service | 🖥️ then ⚙️ |
| D2 | `CS-002`…`CS-008` | object storage, managed SQL, networking/VPN/LB, monitoring, IAM, billing, serverless — Tier 1 on E-OS | the cloud platform's usable core | 🖥️/⚙️ |
| D3 | `M-1`, `R-1010`, `CS-101`…`CS-103` | per-application scheme policy; `contain` enabled and given a lifecycle; an orchestrator | application isolation; Tier 2 | 🖥️ |
| D4 | `L-1`, `M8`, `R-609` | A/B slots, deltas, key rotation; repartitioning in the installer | atomic updates on real disks | 🖥️ |
| D5 | `L-3`, `V2-MS07` | byte reproducibility of image and EFI binary | any external review; shim submission | 🐧 |
| D6 | `PR-004b` | the antivirus's on-access half (`PR-020`): a Linux `fanotify` helper behind a privileged install path `PR-008`'s `.tar.gz` does not give — and, separately, Windows (a signed kernel minifilter, not Rust-only); Redox has no entry until a file-event bus exists (§7.3) | "real-time protection" on the two hosts, labelled honestly; nothing on Redox | 🐧 / 🔑 |
| D7 | `R-910`, `R-916`, `R-912`, `V2-D02` | multi-gig NICs, the I2C bus and I2C-HID, RAID beyond mirror, NVMe depth | laptops (touchpads), modern desktops, real SSDs | ⚙️ |
| D8 | `R-920` (B0–B5), `R-921`, `L-2`, `L-6` | Bluetooth from HCI to A2DP; the first Wi-Fi chipset | wireless at all | ⚙️ |
| D9 | `R-930`, §18.5 | virtio-gpu 3D, Intel modesetting, an acceleration substrate | graphics beyond the framebuffer; the gaming chain's second link | 🖥️ then ⚙️ |
| D10 | `CS-201`…`CS-205` (Q11) | a hypervisor for Redox — an upstream RFC first; interim TCG | VMs, Windows/Linux guests, Tier 3 | 🖥️ then ⚙️ |
| D11 | `WS-008`…`WS-012` (Q8) | the dynamic half of the website on E-OS: accounts, mail, tickets, AI chat — after `CS-001` and TLS on E-OS | the Microsoft-style site the owner described, on E-OS | 🖥️/⚙️ |
| D12 | `PR-022` | the disc-image product on three back-ends (Redox schemes; Windows Virtual Disk API; Linux `udisksctl`), the container layer, data-disc imaging, ISO creation, the in-OS stick writer | the owner's disc-image request, without a driver installed anywhere | 🖥️ |

#### 3.0.5 Band E — blocked on something other than work

| # | id | what it adds or changes | blocked by | who |
|---|---|---|---|---|
| E1 | `R-607b`, §18.0 | the first boot on a physical PC and the symptom form filled in — the only open row in M1 | one desktop computer | ⚙️ 🔑 |
| E2 | `S-1` | branch protection: no direct pushes to `main` | the operator's click | 🔑 |
| E3 | `S-19` | a second maintainer or a written recovery procedure | a person | 🔑 |
| E4 | `R-009` | GitLab CI that runs — shared minutes are exhausted intermittently; the GitHub mirror's workflows execute | quota or an own runner | 🔑 |
| E5 | `V2-MS06`, `M-4`, `V2-MS12b` | keys on a hardware token; signing separated from the build host; package-key custody | tokens and a second machine | 🔑 |
| E6 | `V2-MS10`, `V2-MS11`, `L-5` | a legal entity, an EV certificate, chainload through shim | money and paperwork | 🔑 |
| E7 | `L-7` | OpenSSF Scorecard registration | the operator | 🔑 |
| E8 | `RH-004` | the checkout leaves exFAT | the operator moves the tree | 🔑 |
| E9 | #26 | ✅ **fixed 2026-09-03** — and the issue was **wider than recorded**: after forcing a re-cook (`repo.tag` removed, P-2) **aarch64 fails identically**, so it was never x86_64-specific. Cause: `cosmic-edit`'s generated `auto_deps.toml` demands `libonig` and `libxkbcommon` as **runtime** dependencies, and the cook closure follows **build** dependencies — `libxkbcommon` is one and was always cooked, `libonig` is not and never was. The recipe exists at `recipes/wip/libs/other/libonig` (`#TODO: promote`); `[packages.libonig]` in both configs pulls it into the closure. Counter-control (§5.9 level 4): the `auto_deps.toml` that demands it is dated **2026-09-03 01:09**, before the change that exposed it | — | 🖥️ |
| E10 | #25 (`eos-installer` !6) | flushed disk-password prompts in the installer | #26 (needs a booted x86_64 image to exercise) | 🖥️ |
| E11 | `R-815` (optical, physical) | a real SATA/USB optical drive: eject, media-change polling, the removable flag, and the ATAPI read on silicon rather than QEMU | `PR-022` imaging and Eject on metal | one PC with an optical drive | ⚙️ |

#### 3.0.6 Open defects with evidence, ready to be worked

- **#26** and **#25** — above, E9/E10.
- **#27** — passwords set in the running system are hashed argon2i m=4096 (`rust-argon2 0.8.3`
  default), not the argon2id m=19456 the README claimed; `R-602g` (A14) is its fix.
- **#28** — the shipped NetSurf is the upstream prebuilt, no PIE; `R-D06` 🟡 until `R-F30` (B17).
- **`tools/eos-repo-sign::verify()` has no test** — named by the audit's completeness critic; `TQ-006` (C1).
- **Two roadmap rows carried ✅ with no evidence** (`R-301`, `R-502b`) — found by check 16 on its first
  run and fixed in the same change.
- **One byte-identical screenshot under two names** — found by check 17, the unreferenced copy removed.
- **Fourteen documentation pages were never published** — found by check 18, listed in `SUMMARY.md`.
- **No git hook is installed on the development host** — `RH-006` (A5).

#### 3.0.7 The owner's decisions — asked 2026-09-02/03, **answered 2026-09-03**

The twenty-three questions are kept with their answers (Q1–Q15 answered 2026-09-03, Q16–Q23 asked on 2026-09-04 — Q16 and Q17 answered, Q18–Q23 pending), because each answer is now a rule and the row it governs cites this list.
governs cites this list.

| # | question | answer (owner) | where it lands |
|---|---|---|---|
| 1 | PIN and disk encryption | **screen unlock only** — never `sudo`/`passwd`/FDE | `R-602d`, §14.7 |
| 2 | `R-602g` fix path | **fork and release ourselves** — `eos-users` (type C) created, `v0.4.6-eos.1` to follow | `R-602g`, §6.6 |
| 3 | credential-policy library home | a `lib` target in the **`eos-userutils` fork** | `R-602a`, `R-602c`, `R-602f` |
| 4 | length floor, blocklist, harness password | **yes to a floor** (12 characters; PIN 6 digits), blocklist shipped, harness password changes in the same MR | `R-602b`, `R-602e` |
| 5 | try counter | per-account file; **root may delete it** | `R-602d` |
| 6 | where the website lives | separate repository **`eos-website`** (created) | `WS-001` |
| 7 | hosting today | **Pages for now** (GitLab Pages, `pages` job on `eos-heavy`) | `WS-005` |
| 8 | AI chat | **own model**, design only for now; **a ticket system is built now** (`eos-support` issues + prefilled links) | `WS-010`, `WS-009` |
| 9 | cloud platform name | **E-Cloud** | §11.4 |
| 10 | `CS-009` before Tier 1 | **agreed** | `CS-009` |
| 11 | hypervisor | **RFC to upstream** before code | `CS-201` |
| 12 | products | **per recommendation**: E-OS Guard ships, `eos-sysmon` archived, no "antivirus", `R-D06` 🟡 until `R-F30` — **the "no antivirus" half was superseded by Q16 on 2026-09-04**; the rest stands | `PR-002`, `PR-003`, `PR-004` |
| 13 | four new repositories | **create now and keep in sync** — created on both hosts | §7.5.4, `RH-*` |
| 14 | `docs/prompts/` | **outside the repository** — moved to the owner's local storage | `RH-009` |
| 15 | deletion list | **delete everything unnecessary** — executed, archived locally first | §11.7.1 |
| 16 | Guard and antivirus *(asked and answered 2026-09-04)* | **Guard stays a separate product, per the recommendation** — and **a separate antivirus is to be built**, as its own product rather than a mode of Guard. This reverses the "no antivirus" half of Q12 | `PR-004`, `PR-004b`, `PR-020` |
| 17 | Antivirus shipping shape *(stated by the owner 2026-09-04, alongside Q16)* | **By default an E-OS application shipped in and for the system** — a `[packages.*]` entry in both configs, declinable at install like every product (`PR-005`, `PR-018`) — **and installable on Linux and Windows** through the same packaging path the other products use (`PR-008`), with the Windows job a real gate rather than Guard's `when: manual`. Not a decision on the engine or the product name: the engine is a measurement recorded in `PR-020` (`boreal`, one crate on all three targets) and the name has not been asked | `PR-020`, `PR-004b`, C17, D6, §13, §14.5 |
| 18 | "Like Windows Update" *(asked 2026-09-04, requirement B)* — does it mean **unattended apply and automatic restart**? The design refuses exactly that and the roadmap never said so: `docs/adr/0009-system-update-mechanism.md:267-270` ("pobieranie automatyczne, stosowanie za zgodą"), `:308` ("«automatycznie» znaczy wyłącznie «automatycznie pobrane»"), `system-updates.md` §7.3 ("nigdy nie omija zgody na restart"); `grep -n -iE 'unattended|auto-?restart|automatic restart' ROADMAP.md` → hits only about unattended *install* (`R-616b`, `EA-5`, M4). Mechanism behind the refusal: FDE prompts for the passphrase at every boot, and `sys:kstop` is root-only (`eos-kernel/src/scheme/sys/mod.rs:139-140`) | **recommended, pending the owner:** download automatically; apply only with consent; **never restart unattended** (on an FDE machine it ends at the passphrase prompt with nobody there); scheduled installs are best-effort **relative to boot** until `R-820` exists; `critical` packages skip deferral, never verification, never the restart consent | `R-705`, `R-708`, `R-704`, §14.4 |
| 19 | Home of `Settings → Update` (`R-708`) and `Settings → Drivers` (`R-806`) — i.e. which binary **is** `R-D01`: `eos-settings` (orbutils, orbclient; carries the only placeholder "Aktualizacje" panel, `launcher/src/settings.rs:127-135`) or `eos-control` (Slint on `eos-ui`; owns the password-gated `/scheme/sudo` shims `eos-power`/`eos-netcfg`, `R-D11`, `eos-control-work/Cargo.toml:15-25`). §7.2 and §16.1 name the first, §21 row 2 the second; both ship in both arch configs | **recommended, pending the owner:** `eos-control` hosts `R-708` and `R-806` (the apply step must never run in the GUI process, and the shim exists only there); the `eos-settings` "Aktualizacje" panel becomes a launcher into it or is removed. After the answer, `R-D01`, §16.1 and §21 row 2 are corrected to name **one** binary | `R-D01`, `R-708`, `R-806`, §16.1, §21 row 2 |
| 20 | RAR *(asked 2026-09-04 by `PR-021`, unanswered)* — may a **non-free, field-of-use-restricted** engine be linked into a type-A AGPL product? `unrar-rs` 0.7 (read only; builds for Redox, 72 packages, no `cc`) carries RARLAB's restriction "applies to anything that links this crate" — not GPL, whatever `cargo info` prints — and the tree already refused a linked dependency at a lower bar (ClamAV: "GPL-2 C in an AGPL tree"). Alternative: the clean-room `rars` 0.9.3 reads **and writes** RAR 1.3–7 (builds for Redox, 43 packages, `cargo deny` ok on metadata) but its `COPYING` (WTFPL + "don't blame me") contradicts its `Cargo.toml` (MIT OR Apache-2.0), RARLAB asserts the algorithm is proprietary, and no court has tested a clean-room writer. Three answers: (a) `rars`, read + write, after the author settles the licence text; (b) `unrar-rs`, read only, with a `[[licenses.exceptions]]` entry, the restriction in `NOTICE`, and a permanent bar on a RAR writer; (c) no RAR at all | *(open)* | `PR-021` RAR cell, `deny.toml`, §14.5 |
| 21 | Vendor clouds in the archiver and backups (Google Drive, Dropbox, OneDrive, Box) *(asked 2026-09-04, unanswered)* — each needs a registered developer application, a client secret in custody and a consent-screen review: 🔑 operator actions this project has never automated and has no legal entity for (§5.1.3); technically it is the same TLS client that already links on Redox through the `ring` fork, plus an OAuth loopback redirect that NetSurf has never been shown to capture. Will the owner register the applications, or does "multi-cloud" mean WebDAV (`eos-drive` `PR-012`, Nextcloud-class servers) — deliverable today on all three targets? | *(open)* | `PR-021`, `PR-021b`, §14.5 |
| 22 | Disc images and virtual drives *(requirement E, asked 2026-09-04)* — a separate product (`PR-022`) with the Redox back-end as three OS components; copy-protection and media-type emulation, MDX, driver-installed virtual drives and Blu-ray/AACS refused; no burning, no DVD boot; and the product's name and repository | **pending, 🔑** — recommendation: yes to the refusals (a signed kernel driver plus circumvention on Windows, no consumer on E-OS) and to the three-component split; the name is the owner's to give | `PR-022`, `R-818`, `R-819`, `R-D16`, `R-815`, §13, §14.5 |
| 23 | Context-menu style scope *(asked 2026-09-04)* — the user-chosen style (Windows list / Linux list / radial) reaches **E-OS products and the E-OS shell only** (recommended: `R-D15` + `R-D17`, M+M, no new fork), **or** also the file manager's menus, which means either (a) a type-C fork of libcosmic (**XL**, a whole GPL-3 iced toolkit under E-OS maintenance, and still no radial without rewriting iced overlays) or (b) reviving the deprecated, currently un-built orbutils `file_manager` (`[[bin]]` commented out at `orbutils/Cargo.toml:23-27`, no menu code at all) on the `R-D17` twin renderer (**L–XL**, loses cosmic-files' sidebar/search UX) | *(pending)* — recommendation: accept the narrower scope now; revisit when a file manager becomes an E-OS product | `R-D15`, `R-D17`, §13, `docs/architecture/desktop-environment.md` Phase 3 |

### 3.1 Short term (1–3 months) — `S-1`…`S-20`

Ordered by cost-to-value. **Eight of these twenty rows were re-verified against the tree on
2026-08-31 and had already been delivered** — carrying them forward as "planned" would have put
eight false claims into a fresh document. Their evidence is in the *Verified* column.

| # | Item | Verified 2026-08-31 | Priority | Owner | Effort | Traces to |
|---|---|---|---|---|---|---|
| S-1 | **Block direct pushes to `main`** — every commit in project history went straight to `main`; 0 merge requests until this cycle | open | **High** | operator 🔑 | 15 min | `C-6`, `G-5` |
| S-2 | **Make an unverified boot build explicit** | **done** — `recipes/core/bootloader/recipe.toml:33` — no boot key ⇒ hard failure; the escape hatch is exactly `EOS_ALLOW_UNVERIFIED_BOOT=1` | **High** | Gh0s777tt | 30 min | `C-2`, `G-4` |
| S-3 | **Fix the `repo` TUI panic** | **done** — `src/bin/repo.rs` ~:1945 stores `None` on a no-match search; the comment names all six indexing sites (:1700, :1742, :1972, :2002, :2019) | **High** | Gh0s777tt | 15 min | `A §5.3` |
| S-4 | **Allowlist `keys/eos-pkg-signing.pub.toml` in gitleaks** | **done** — `.gitleaks.toml:41` `'''^keys/eos-pkg-signing\.pub\.toml$'''` | **High** | Gh0s777tt | 15 min | `C-19` |
| S-5 | **Give `$(FSTOOLS_TAG)` source prerequisites** | **done** — `mk/fstools.mk:20` defines `FSTOOLS_RECIPE_SRC`; `:24` makes `$(FSTOOLS)` depend on it | **High** | Gh0s777tt | 1 h | `C`, `A §5.1`, `G-15` |
| S-6 | **Point the README bootstrap at the in-repo script** | **done** — `README.md` quick start is `git clone https://gitlab.com/e-os/e-os.git && cd e-os`; no `curl … \| bash` remains | **High** | Gh0s777tt | 15 min | `A §2.3` |
| S-7 | **Pin `blake3` for `mpc`; unpinned tarball a hard error** | **done** — `recipes/libs/mpc/recipe.toml:19` pins `86d083c4…` with its chain of trust; the hard-error half is `ci-integrity.sh` **check 12** → `scripts/eos-check-tar-pins.py` | **High** | Gh0s777tt | 1 h | `C-1b`, `A §5.4b` |
| S-8 | **Verify `blake3` regardless of `is_deps`** | open — `src/cook/fetch.rs:541` `let check_source = !recipe.is_deps;` unchanged | **High** | Gh0s777tt | 3 h | `C-1c`, `A §5.4c` |
| S-9 | **Pin the upstream package key** → [`R-701a`](#53-package-channel-and-update-trust--r-7xx), [`V2-MS13`](#52-secure-boot-milestones--v2-ms) | **done** — `R-701a` ✅ (`U-143`, `U-183`, `ci-integrity.sh` check 9) and `V2-MS13` ✅ (`U-223`); the row said "open" until 2026-09-03 while both targets were closed | **High** | Gh0s777tt | 4 h | `C-1`, `G-2` |
| S-10 | **Publish the x86_64 package repository and enable `50_eos`** → [`R-701`](#53-package-channel-and-update-trust--r-7xx) | open — `config/x86_64/eos.toml:767` ships `50_eos` with the URL **commented out**; aarch64 is active | **High** | operator 🔑 | 1 d | `C-4`, `G-1` |
| S-11 | **Republish the aarch64 index with `serial`/`expires`** | open — the live index predates `V2-MS15` | Medium | operator 🔑 | 1 d | `C-12` |
| S-12 | **Bump `eos-pkgutils`** for `rustls-webpki`, `ring`, `rand` | open — `rustls-webpki 0.103.4` with six advisories ships inside `/usr/bin/pkg` | **High** | Gh0s777tt | 2 h | `C-3`, `G-13` |
| S-13 | **Tests for `repo_builder.rs` and `cook/package.rs`** | open — the code that writes and signs the index has zero | **High** | Gh0s777tt | 2 d | `G-9` |
| S-14 | **`osv-scanner` in CI and in `lefthook`** | **partial** — it is a `verify.sh` stage and a GitHub `security.yml` job; it is **not** in `.gitlab-ci.yml` and **not** in `lefthook.yml` | Medium | Gh0s777tt | 1 h | `C-13` |
| S-15 | **Pin apt versions in the container files** | open — `podman/redox-base-containerfile:18`, `:95`, `redox-toolchain-containerfile:18`, `redox-gdb-containerfile:16` all install without versions | Medium | Gh0s777tt | 2 h | `C-17`, `G-16` |
| S-16 | **Build a current `git`** | open — the image ships `git 2.13.1` (2017) as a fetched upstream binary | **High** | Gh0s777tt | 4 h | `C-8`, `G-8` |
| S-17 | **Repoint 22 recipes from the GitHub mirror to `gitlab.com/e-os`** | **done** — `grep -rl Gh0s777tt recipes/` → **0 files** | Medium | Gh0s777tt | 2 h | `G-10`, `ADR-0001` |
| S-18 | **One source of product version** | open, and **worse than recorded**: three disagreeing sources, not two — `mk/config.mk:189` `EOS_VERSION?=0.2.0`, `config/{aarch64,x86_64}/eos.toml` `VERSION_ID="0.1.0"`, root `Cargo.toml:3` `version = "0.1.0"`, against signed tag `v0.2.0` | Medium | Gh0s777tt | 1 h | `G-17` |
| S-19 | **Second maintainer or a written recovery procedure** | open — single-person project, no break-glass path; see also `R-614c` | **High** | operator 🔑 | 1 d | `C-18`, `G-12` |
| S-20 | **SBOM generated and committed per tag** | open — `sbom/` holds only `eos-0.1.0-aarch64.cdx.json` and `eos-0.1.0-x86_64.cdx.json` | Medium | Gh0s777tt | 2 h | `C-14` |

### 3.2 Mid term (3–6 months) — `M-1`…`M-9`

| # | Item | Priority | Owner | Effort | Traces to |
|---|---|---|---|---|---|
| M-1 | **Application sandboxing** — per-process scheme sets, starting with NetSurf, which today holds the same 25 schemes as the shell including `file`, `proc` and `sudo`. Depends on [`R-1010`](#11-platform-process-and-release) | **High** | Gh0s777tt | 1–2 weeks | `C-5`, `G-3` |
| M-2 | **Persistent audit log** — a logging daemon with rotation; there is nothing to read after an incident | **High** | Gh0s777tt | 1 week | `C-9`, `G-6` |
| M-3 | **Packet filtering**, or an explicit decision to disable `sshd` by default → [`R-904`](#84-connectivity-and-honest-hardware-tiers--r-9xx) | **High** | Gh0s777tt | 2 weeks | `C-10`, `G-7` |
| M-4 | **Separate signing from the build machine** — four private keys live on the host that is also the CI heavy runner → [`V2-MS12b`](#54-keys-custody-and-rotation) | Medium | operator 🔑 | 1 week | `C-11`, `G-11` |
| M-5 | **SAST in CI** (`semgrep`) — clippy is a linter, not a SAST | Medium | Gh0s777tt | 4 h | `C-15`, `G-19` |
| M-6 | **Settle the semantics of `debug`, `memory`, `irq`, `serio`, `sys`** for unprivileged users and drop what is unnecessary | **High** | Gh0s777tt | 2 d | `C-21` |
| M-7 | **`linked_list_allocator` ≥ 0.10.2** — `RUSTSEC-2022-0063`; none of its three paths is reachable in this usage, so this is debt, **not** a reachable exploit. The audit argues this finding *down* and that is carried over unchanged | Medium | Gh0s777tt | 2 h | `C-16` |
| M-8 | **`V2-MS04`, `V2-MS06`, `V2-MS08`, `V2-MS09`** — remaining shim-review preparation. *Listed individually here on purpose:* the old range notation "`V2-MS06`–`V2-MS09`" left `V2-MS07` and `V2-MS08` with no owner and no horizon. `V2-MS07` (byte reproducibility) sat in this row **and** in `L-3` until 2026-09-03 — two horizons for one item; it is `L-3` only now, with `R-303` | Medium | Gh0s777tt | — | `ADR-0006` |
| M-9 | **Mirror-head parity check** — nothing compares GitLab and GitHub heads; one live divergence already exists (`eos-pkg-aarch64`, disjoint histories) | Medium | Gh0s777tt | 4 h | audit `00 §5.2` |

### 3.3 Long term (6–12+ months) — `L-1`…`L-7`

| # | Item | Priority | Owner | Traces to |
|---|---|---|---|---|
| L-1 | **Atomic updates with rollback** — the single largest gap against Silverblue, NixOS and GrapheneOS → [`R-706`](#53-package-channel-and-update-trust--r-7xx), [`R-707`](#53-package-channel-and-update-trust--r-7xx) | **High** | Gh0s777tt | audit `04 §4` |
| L-2 | **Wi-Fi** — no wireless driver ships → [`R-921`](#84-connectivity-and-honest-hardware-tiers--r-9xx) | **High** | Gh0s777tt ⚙️ | audit `02 §6` |
| L-3 | **Reproducible builds** — five measured obstacles, from unpinned apt to embedded timestamps → [`R-303`](#11-platform-process-and-release), [`V2-MS07`](#52-secure-boot-milestones--v2-ms) | Medium | Gh0s777tt | `A §2.1` |
| L-4 | **Backup tooling** → [`PR-021b`](#754-the-register) *(register home minted 2026-09-04; until then this row referenced no register id, which §0.2 forbids)* | Medium | Gh0s777tt | audit `02 §3` |
| L-5 | **`V2-MS10` / `V2-MS11`** — legal entity, EV certificate, shim chainload. Non-technical blockers first | Low | operator 🔑 | `ADR-0006` |
| L-6 | **Bluetooth, NVMe depth, non-Intel GPU drivers** → [`R-920`](#84-connectivity-and-honest-hardware-tiers--r-9xx), [`V2-D02`](#83-storage-drivers-and-blocking-buses), [`R-930`](#84-connectivity-and-honest-hardware-tiers--r-9xx) | Medium | — ⚙️ | audit `02 §6` |
| L-7 | **OpenSSF Scorecard registration** | Low | operator 🔑 | audit `C` checklist |

### 3.4 Installer programme milestones — M1–M8

Three epics (§6.1) broken into eight milestones with explicit dependencies. **These are `M1`…`M8`
of the installer programme and are a different series from `M-1`…`M-9` in §3.2** — the hyphen is
load-bearing; the two series were never reconciled in either predecessor and the difference is
named here rather than left to be discovered.

| milestone | what it delivers | requires | where | state |
|---|---|---|---|---|
| **M1 — "a USB stick that installs to a real disk"** | the smallest vertical slice: named, signed medium → boots on a physical PC → installs to an internal disk → reboot **with the medium removed** → `eos login:` | `ADR-0007`, `ADR-0008`; `R-601` ✅; `V2-N03` ✅; **one physical x86_64 machine** | 🖥️🐧⚙️🔑 | 🟡 — **10 of 11 tasks closed (2026-09-02; was 3).** Open: `R-607b` (first run on metal, which needs a physical PC and cannot be closed from QEMU). |
| **M2 — "an interrupted install does not leave a brick"** | five-phase transaction with a journal on the ESP, resumability, block-path payload verification, rescue mode, medium check | **M1** (medium check compares against `SHA256SUMS` from `R-611b`), `installer.md` §6.2 (**decision with no ADR**, Annex B D6), `R-607a` ✅ | 🖥️⚙️ | 🔴 |
| **M3 — "wizard: one truth for GUI and TUI"** | state machine S0–S10, disk-selection logic in the **library**, `R-604` barriers, accounts/hostname/locale, per-machine identity, GUI↔TUI parity gate | **M1**, `ADR-0011`, `ADR-0010`, `R-D08`, `R-604a` from M1 | 🖥️ | 🔴 |
| **M4 — "profiles and unattended mode"** | profile/feature data model in TOML with inheritance and locks, validator, migrations, diff screen, answer file written by the wizard, i18n | **M3**, `installer-profiles.md` §1.1/§1.3 (**decision with no ADR**), `R-D13`, `R-711`, `R-1010` | 🖥️ | 🔴 |
| **M5 — "updates: stop losing data and close verification"** (E0+E1) | atomic state write, `curl` with limits and resume, per-package `package_serial`, no pinned key ⇒ **refusal**, e2e decision tests | `ADR-0009`; `R-703` 🟡, `R-702` ✅, `V2-MS13`–`V2-MS15` ✅ | 🖥️ | 🔴 |
| **M6 — "daemon and journalled transaction"** (E2+E3) | `eos-updated` + `/scheme/eos-update` + CLI; intent journal, copies of replaced files, `eos-update rollback`, power-loss recovery | **M5**, `R-D03`; **`R-706` shares journal semantics with `R-612c`** — one format, not two | 🖥️ | 🔴 |
| **M7 — "base and kernel on reboot + pane"** (E4+E5) | `pending/`, bootloader flag, boot-attempt counter, automatic return to `kernel.prev`, pane in `R-D01`, flow documentation | **M6**, `R-D01` ✅, **⚙️ metal** — the bootloader is not provable in a Mac-QEMU GUI loop | ⚙️ | 🔴 |
| **M8 — "key rotation, deltas, A/B slots"** (E6+E7+E8) | keyring with `not_before`/`not_after`/`revoked`; range fetch by `Entry.offset`; second root and slot selection in the bootloader | **M7** (`R-707`), **M2** and **M4** through `R-609` | ⚙️ | 💡 |

**Dependencies that are easy to miss, so they are written out:**

- **M8 needs M2, not only M7.** The installer creates exactly three partitions and hands the whole
  tail of the disk to one RedoxFS (`installer.rs:565-660`). A/B cannot be added to a machine
  installed today without repartitioning — that is work in the **installer** (`R-609`), not in the
  update system.
- **M1 does not need M5.** Installation from the medium is offline by design, so the missing
  x86_64 update channel (`C-4`) does not block M1. It blocks everything *after* installation.
- **M3 needs `R-604a` from M1, not the reverse.** Disk identification is in M1 because nobody may
  be pointed at a physical disk without it; the rest of `R-604` moves to M3.
- **M2 needs `R-607a` (block size), not all of `R-607`.** The software half is 🖥️ and cheap; the
  hardware matrix `R-607b` is ⚙️ and stretches across M1…M7.

**M1 acceptance criterion, in one falsifiable sentence:** on **one** physical x86_64 PC, an image
written to a USB stick with `dd` starts from firmware, the installer sees the internal disk and
identifies it by more than a number, the installation succeeds, and the machine **with the stick
removed** boots to `eos login:`. A failed run is also a result **if it records where it stopped**;
the symptom form is in [§18.0.5](#180-stage-0--first-boot-on-metal--one-evening--do-this-first-r-607b).

**M1 status, measured 2026-08-31:** 11 tasks tracked as GitLab issues, **6 closed** (#1 `R-611a`, #2 `R-611b`, #3 `R-611c`, #7 `R-607a`, #8 `R-612a`, #10 `R-608` part), 5 open. Tasks 1 (`R-611a`), 7 (`R-607a`) and 8
(`R-612a`) are ✅ — the merge requests are merged and the pins are bumped (`eos-installer` →
`74726c889b`, `eos-pkgutils` → `ec08f22aa6`, branch `eos` for the latter, not `master`).
**Task 11 (`R-607b`, the first run on a physical PC) is not done, requires hardware, and is the
only one that settles the acceptance criterion.** Nine of eleven tasks are 🖥️-provable; the one
that decides is ⚙️. `installer.md` §9.3 lists nine things QEMU will not show, the first of which is
*"whether the firmware will boot our medium at all"* — in practice the most common failure and by
definition absent from an emulator. Task-level detail is in §6.3.

> **Historical note kept, because it was wrong and the correction is the point.** An earlier
> version of this table explained why tasks 1, 7 and 8 were 🚧: the code lived on unmerged
> branches and `repos.toml` still pinned `c8d32ad39e…`. **That note is stale as of 2026-08-30** —
> `repos.toml:116` = `74726c889bdf61ff683558227fe95178061a88e8` (bumped to `2aae3ace0bbfa756644197a31c8b330ffe4269b2` on 2026-09-01 with R-604a) and `repos.toml:176` =
> `ec08f22aa63d2e96e8f8100afd91b6d94172e943`, and `recipes/core/installer/recipe.toml:5` carries
> the same installer rev. As written the old section said ✅ and 🚧 about the same three tasks.

### 3.5 Installer / wizard / live-update epic backlog — `EA-*`, `EB-*`, `EC-*`

**Renamed this merge from `A-*`/`B-*`/`C-*`.** The old prefixes collided visually with the audit's
`C-1`…`C-21` findings — `C-1` meant two different things in two live documents. Mapping in
[Annex C](#annex-c--retired-documents-and-retired-identifiers).

> These epics were derived from the shipped installer, the audit findings and the milestone
> registry, at a time when the referenced "PROMPT 5" specification was unavailable. The four
> specifications now exist ([`installer.md`](docs/architecture/installer.md),
> [`installer-wizard.md`](docs/architecture/installer-wizard.md),
> [`installer-profiles.md`](docs/architecture/installer-profiles.md),
> [`system-updates.md`](docs/architecture/system-updates.md)) and §6 is built from them. **This
> table is retained for the work it names that §6 does not** — it should be reconciled against
> those specifications before work starts.

**EA — OS installer.** Today: `redox_installer`, `redox_installer_tui` and `redox_installer_gui`
ship in the image; a full partition → install → reboot → login cycle is proven (`U-176`); AES-XTS
is offered at install.

| # | Sub-task | Priority | Register home |
|---|---|---|---|
| EA-1 | Full-disk encryption **on by default**, with an explicit opt-out | High | new scope on `R-603b` (S5 screen) |
| EA-2 | Verify the KDF that derives the AES-XTS key from the passphrase — currently unaudited | **High** | `ADR-0010`; no register row yet — **open scope**, see §15 |
| EA-3 | Post-install integrity check: kernel and initfs verify against the pinned boot key before first reboot | High | `R-612b` |
| EA-4 | Install-time package-channel selection, defaulting to the signed E-OS repository | High | `R-605` |
| EA-5 | Unattended install from an answer file | Low | `R-616b` |
| EA-6 | Installer refuses to proceed when the image's own signature chain cannot be verified | Medium | `R-613` |

**EB — installation wizard (first-run experience).** Today: the graphical greeter and the text
login both force a password on first boot (`U-076`–`U-079`); `eos-welcome` prints a quick-start.

| # | Sub-task | Priority | Register home |
|---|---|---|---|
| EB-1 | Timezone and locale at first run — today `/etc/tz-offset` is baked at build time | Medium | `R-603d` |
| EB-2 | Network configuration in the wizard, reusing the `eos-control` network pane | Medium | `R-902` (delivered), wizard side open |
| EB-3 | Offer to enable the package channel and show which key will be trusted | High | `R-605` |
| EB-4 | Present the security posture honestly at first run: what is verified and what is not | Medium | §14; no register row — **open scope** |
| EB-5 | Optional second administrative account — mitigates the break-glass gap on the device side | Low | `R-614c`, `S-19` |

**EC — live system updates.** Today the mechanism is complete and **switched off** on x86_64:
`pkg` enforces the signed index, blake3 on bytes, rollback and freeze counters — and
`config/x86_64/eos.toml:767` ships `50_eos` with its URL commented out, so an installed x86_64
system cannot update at all.

| # | Sub-task | Priority | Register home |
|---|---|---|---|
| EC-1 | **Publish the x86_64 repository and enable `50_eos`** | **High** | `R-701`, `S-10` |
| EC-2 | Republish aarch64 with `serial`/`expires` | Medium | `S-11` |
| EC-3 | Scheduled update check with a user-visible notification via `eos-notifyd` | Medium | `R-705`, `R-D03` |
| EC-4 | **Atomic apply with rollback** — `pkg` mutates the live system in place | **High** | `R-706` |
| EC-5 | Staged download and verification before any file is replaced | High | `R-706` |
| EC-6 | Update path for bootloader and kernel that preserves the signature chain | **High** | `R-707` |
| EC-7 | Offline update from removable media, signature-verified | Low | **split on 2026-09-04, no longer open scope:** the *source* half is folded into `R-705` as the signed local-mirror source (index-enforced, never through the no-remotes exemption — `pkgar_backend/mod.rs:160-170`); the *medium* half — mounting and hash-checking the stick — is `R-D16`; `R-614b` stays the *rescue* case (ESP/kernel repair), a different thing; the driver sub-scope is `R-817` |

**Critical path:** `EC-1 → EC-4 → EC-6`. Nothing else in EC matters until a channel exists.

---

## 4. Where work can happen

This decides what can be touched today and what waits for another host or for a physical machine.
It is the mechanism, not just the list — the *why* is what keeps someone from retrying a build
that cannot succeed here.

### 4.1 🖥️ Possible on this Mac (podman + QEMU/TCG)

- Build **and run** the **aarch64** image — the full, proven path.
- Build and run **x86_64** under TCG emulation (slow, but working since `U-172`).
- Build the base COSMIC applications (`cosmic-edit`, `cosmic-files`, `cosmic-term`).
- Write a USB stick from the installer medium with `dd`.
- The whole self-checking toolchain: gates, signatures, reproducers, `verify.sh`.

### 4.2 🐧 Needs Linux (or Windows + WSL2)

- **The extended COSMIC applications** (`cosmic-store`, `cosmic-settings`, `cosmic-reader`): their
  `fontconfig → host:gperf` toolchain is published **only** for `x86_64-linux`, so on this
  aarch64 Mac it 404s. This is the concrete reason `R-D01` exists as a native control panel rather
  than a `cosmic-settings` port.
- **Fast accelerated emulation (KVM).** macOS offers only `hvf`, which collapses under load
  (`R-F23`) and buys ~1.9×; usable x86_64 CI speed needs a KVM runner.

### 4.3 ⚙️ Needs physical hardware

- **First boot on metal.** Nothing in this repository has ever run on physical hardware. Every
  green tick above is QEMU.
- Proof that x86_64 works on a real PC (built and boot-smoked under emulation, never on metal).
- Validation of `vesad`/GOP, NVMe/AHCI, `xhcid` and the NICs — meaningful only against firmware.
- **A desktop machine, not a laptop**, because no I2C bus exists, therefore no touchpad
  (`R-916`/`V2-N01`). Secure Boot is **no longer a reason** — the bootloader is signed; on a
  foreign x86_64 machine what remains is one owner action (enrolling the certificate).

### 4.4 🔑 Needs the operator, never a tool

- Generating any signing key (`keys/README.md`, `CLAUDE.md` §5.7). A tool that logs must not touch
  key material.
- `eos-setup-mirrors.sh --apply` — needs a GitHub PAT.
- The GitLab project setting `only_allow_merge_if_pipeline_succeeds` (`R-F12`).
- Legal entity, EV certificate, second security contact (`V2-MS10`).

---

## 5. Trust chain: boot, package channel, keys

### 5.1 Secure Boot audited against `rhboot/shim-review`

The goal, stated plainly: *"so that our system runs on any hardware the way it should."* What
follows is an audit of every requirement in [`rhboot/shim-review`](https://github.com/rhboot/shim-review)
— the repository cloned locally and read in full (README, 39 question blocks, `docs/submitting.md`,
`docs/reviewer-guidelines.md`, `ISSUE_TEMPLATE.md`) — plus the certificate situation as of
August 2026. Nothing in the predecessor English roadmap corresponded to this.

#### 5.1.1 What we already have — measured, not asserted

| shim-review requirement | E-OS | evidence |
|---|---|---|
| Bootloader source public and pinned | ✅ | `recipes/core/bootloader/recipe.toml:4-6` → `eos-bootloader` rev `d4217442` (bumped 2026-09-01 in `7ea482a60`, the no-LTO aarch64 build); toolchain pinned `nightly-2026-05-24` |
| Built from source, not fetched as a binary | ✅ | `cookbook.lock:7-8` `fsrule = "source"`; enforced by `ci-integrity.sh` check 6 |
| Whole boot chain open source | ✅ | AGPL-3.0 (`LICENSE`); bootloader fork MIT; all 28 forks public |
| The project signs its own EFI artefacts | ✅ | `recipes/core/bootloader/recipe.toml:110-130` — `sbsign` at `cook` time, `sbverify` immediately after |
| Secure Boot proven **with a negative control** | ✅ | `scripts/eos-secureboot-proof.sh`: our key + signed → boots; our key + unsigned → rejected; foreign key + our signature → rejected |
| Both media covered | ✅ | `U-208`: live ISO **and** the installed `harddrive.img` boot under Secure Boot; foreign key → `Access Denied` |
| Signed with the operator's real key | ✅ | `U-210`: `CN=E-OS Secure Boot`, valid to 2036-08-25; `sbverify` OK on both bootloaders |
| `SectionAlignment` ≥ 4096 | ✅ | **measured**: `SectionAlignment=4096` — a hard Microsoft requirement, satisfied |
| No W+X section | ✅ | **measured**: `.text` R-X, `.data` RW-, `.rdata`/`.reloc` R-- — none combines write with execute |
| `NX_COMPAT` bit | ✅ | **measured**: `DllCharacteristics=0x8160` → `NX_COMPAT` set, plus `DYNAMIC_BASE` and `HIGH_ENTROPY_VA` |
| Security contact and process | 🟡 | `SECURITY.md` has private reporting and an SLA (ack ≤72 h, assessment ≤7 d, plan ≤30 d); missing a second contact and a CVE path |
| Trust in our own updates | ✅ | hybrid ed25519 + ML-DSA-65 key pinned in the image (`keys/eos-repo-sign.pub.toml`, installed at `/etc/pkg/eos-repo-sign.pub.toml`) |

> Worth saying outright: **the three hard Microsoft requirements about the shape of the PE binary
> are already met**, and nobody had checked them before. On that axis the E-OS bootloader is ready.

#### 5.1.2 What is technically missing

| gap | what it means | size |
|---|---|---|
| `.sbat` section | shim 16.1 **refuses to load** an image with no `.sbat` (`pe.c:489-497`, `EFI_SECURITY_VIOLATION`). **Since delivered as `V2-MS01`** (`U-218`) | S |
| Chain through shim | the shim model requires `shim.efi` as first stage, and the second stage must call shim's verification protocol (`shim_lock` / `EFI_SECURITY2_ARCH_PROTOCOL`) for everything it loads onward — `V2-MS11` | L |
| Bootloader must verify what it loads | it checked **only magic bytes** — `\x7FELF` for the kernel, `RedoxFtw` for initfs. Exactly what reviewers call "executing unauthenticated code". **Since delivered as `V2-MS02`** (`U-212`) | L |
| No "lockdown" equivalent | question 16 of the template carries the hint *"If it does not, we are not likely to sign your shim"*. `eos-kernel` has no loadable modules — it is a microkernel — so the question translates to user-space drivers, and that story does not exist yet — `V2-MS09` | XL |
| Key protection | today a plain RSA-2048 file with no passphrase (`-nodes`). Microsoft requires a **FIPS 140-2 Level 2** hardware module and two-factor authorisation — `V2-MS06` | M |
| Signed SPDX SBOM in a `.sbom` section | mandatory since 2025-10-20; the company name in the SBOM must match the EV certificate **exactly** — `V2-MS08` | S–M |
| Revocation mechanism | *"strong revocation mechanism for everything the shim loads, directly and subsequently"* — hashes of old binaries into DBX | L |
| Byte reproducibility | a hard threshold: *"nobody will trust and sign a binary that is not reproducible"*. `R-303` states plainly that image timestamps still differ — `V2-MS07` | M |
| Secure Boot gate in CI | no job in `.gitlab-ci.yml` calls `eos-secureboot-proof.sh`; the proof exists only on the maintainer's laptop — `V2-MS04` | M |
| Three documents contradicted the code | `docs/security/threat-model.md`, `docs/security/hardening.md` and the hardware plan (now §18) still claimed nothing signs the bootloader. A reviewer reads the security documents, and a contradiction with the code is a maturity warning. **Since fixed as `V2-MS03`** (`U-211`, `U-216`) | XS |

#### 5.1.3 What is missing beyond engineering — the real blocker

None of these is a code problem, and no amount of programming removes them:

| requirement | text | E-OS |
|---|---|---|
| Legal entity | *"Company/tax register entries or equivalent"* — a registration a reviewer can verify | 🔴 none |
| EV certificate | required to sign the `.cab` in the Microsoft Hardware Dev Center; the submission must name issuer **and** subject | 🔴 none |
| Two security contacts | two people, PGP keys, verification by encrypted mail with random words | 🔴 one person |
| Project longevity | reviewer guidelines, verbatim: *"A tiny 1-man outfit may just go away without warning"* | 🔴 single-person project |
| Justify that a shim is needed at all | `docs/submitting.md` opens with *"Are you 100% sure that you need this? … for small deployments it's often possible (and easier!) to add public keys directly into firmware"* — a description of what E-OS **already does** | 🟡 must be argued |
| Unusual second stage | *"we really only have experience with using GRUB2 or systemd-boot … asking us to endorse anything else is going to require some convincing"*; reviewers have a dedicated `custom second-stage` label | 🔴 our own bootloader, in Rust |

#### 5.1.4 Certificate status, August 2026 — and why it changes the arithmetic

| certificate | validity | role |
|---|---|---|
| `Microsoft Corporation UEFI CA 2011` | **expired 2026-06-27** | signed every Linux shim until now |
| `Microsoft UEFI CA 2023` | to 2038-06-13 | **the only** certificate Microsoft signs shims with today |
| `Microsoft Corporation KEK CA 2011` | **expired 2026-06-24** | authorised writes to `db`/`dbx` |
| `Microsoft Corporation KEK 2K CA 2023` | to 2038-03-02 | successor |

Three consequences that must be stated together:

1. **The dual-signing window is closed.** Microsoft: *"Update 6/26/26: Approved Signing
   Submissions now only return binaries signed with the 2023 UEFI CA."* A shim issued to E-OS today
   would be signed **only** with the 2023 key.
2. **A machine whose `db` holds only CA 2011 will NOT boot such a shim.** That is the exact opposite
   of "works on any hardware": the shim path today gives **narrower** coverage than it did in 2024,
   and it widens only as the installed base is replaced.
3. **Expiry is not revocation.** Firmware checks presence in `db` and absence from `dbx`; it does
   **not** check the validity date. Machines that boot today keep booting, and Microsoft explicitly
   advises against removing CA 2011 from `db`.

#### 5.1.5 Conclusion and recommendation

**The shim path is not reachable for E-OS today**, and what blocks it is non-technical — legal
entity, EV certificate, HSM, two contacts, longevity — not missing code. Measured review time when
everything is in place: **from ~5.5 weeks to ~7 months** (273 submissions labelled "accepted",
42 open), with **three independent reviews, one of them accredited**.

The recommendation is therefore two-track, and it does **not** invalidate
[`ADR-0005`](docs/adr/0005-secure-boot-without-microsoft.md):

- **Track A (in force, working today):** our own key, trust controlled by the owner. This is
  **done and proven** (§5.1.1). On aarch64 and on our own hardware it installs with no BIOS
  interaction; on a foreign x86_64 machine it costs the owner one step.
- **Track B (preparation, without commitment):** do the items from §5.1.2 that **pay for themselves
  regardless** of whether a Microsoft submission ever happens — SBAT, signature verification in the
  bootloader, key on a token, reproducibility, the CI gate, and fixing the three lying documents.
  Each of them raises E-OS security **now**.

Recorded as [`ADR-0006`](docs/adr/0006-path-to-microsoft-verification.md).

### 5.2 Secure Boot milestones — `V2-MS`

The "why this is worth doing independently of Microsoft" column is the reason this table is a plan
and not a wish list.

| id | what | why worth it independently | where | state |
|---|---|---|---|---|
| `V2-MS01` | **`.sbat` section** in both UEFI bootloaders | ✅ **done** (`U-218`): 158 B, `eos-bootloader,1,E-OS,…`, added **before** signing since Authenticode covers the whole binary; both signatures still valid, BIOS path untouched. Gives us our own version-revocation path instead of waiting on DBX | 🖥️ | ✅ |
| `V2-MS02` | **Bootloader verifies kernel and initfs** by signature, not magic bytes | ✅ **done and proven** (`U-212`): untouched image boots, one changed byte in the kernel → refusal. Scope deliberately narrow — see §14 | 🖥️🔑 | ✅ |
| `V2-MS03` | **Fix three documents** — `threat-model.md`, `hardening.md`, `hardware-plan.md` | ✅ **done** (`U-211`); they claimed nobody signs the bootloader, untrue since `U-207`. `U-216` additionally corrected `docs/reference/keys-and-tokens.md`, wrong on two points about trust layer 2 | 🖥️ | ✅ |
| `V2-MS04` | **Secure Boot gate in CI** — wire `eos-secureboot-proof.sh` into `.gitlab-ci.yml` | the proof stops depending on one laptop. **Downstream of `R-009` — partly**: the `eos-heavy` tier **does run** (the nightly `build-image` passed 2026-09-01), so this gate could live there today; what blocks it is the shared tier and the fact that no job calls `eos-secureboot-proof.sh` (`grep -n` → 0 hits). With the light tier dead changes nothing until capacity returns | 🐧 | 🔴 |
| `V2-MS05` | **Hermetic signing** — `sbsigntool` from the base image instead of `apt-get` during `cook` | ✅ **done** (`U-218`): the version of the tool that signs the boot chain is now part of the pinned build description, and the step needs no network | 🖥️ | ✅ |
| `V2-MS06` | **Key on a hardware token** (PKCS#11, YubiKey/Nitrokey) instead of a passphrase-less file | the key that signs the boot chain is a plain file today | 🔑 | 🔴 |
| `V2-MS07` | **Byte reproducibility** of the image and the EFI binary, plus published hashes | `R-303`; a precondition of any review, and needed for releases regardless | 🐧 | 🔴 |
| `V2-MS08` | **SPDX SBOM generated on every build** (today static for 0.1.0 and quietly ageing — `sbom/` holds only the two 0.1.0 files) | an honest bill of materials; a Microsoft requirement since 10/2025 | 🖥️ | 🔴 |
| `V2-MS09` | **Lockdown equivalent** for a microkernel: describe and enforce what user-space may not do once SB is on | the one shim-review question that comes with "or we will not sign you" | 🖥️ | 🔴 |
| `V2-MS10` | **Business decision**: legal entity + EV certificate + second security contact | only this unblocks a submission; it is not programming work | 🔑 | 🔴 |
| `V2-MS11` | **Chainload through shim** + verification protocol (only after `V2-MS10`) | last step of track B; pointless without `V2-MS10` | 🖥️ | 💡 |
| `V2-MS12a` | **Package-signing-key guard** — detects loss of and drift in the key | ✅ **done** (`U-213`). *Split from `V2-MS12` in this merge:* the old single number carried both the guard (delivered) and the custody problem (open), so one identifier wore two statuses and the Delivered table and the register disagreed about it | 🖥️ | ✅ |
| `V2-MS12b` | **Custody of the package-signing key** — cookbook **generates it itself**, it is stored in **plaintext** (`skey`, 128 hex chars) | 🟡 **[P2]** A verified backup **exists** (`U-216`): `~/.eos-keys/eos-pkg-signing.secret.toml`, byte-identical checksum, on a **different volume** than the original. Remaining: (a) a third copy **off this Mac** — both copies are on one computer today (`C-11`); (b) making it an operator key, but **after `V2-MS13`**, because rotation alone closes nothing and costs a 642 MB republish | 🔑 | 🟡 |
| `V2-MS13` | **Enforce blake3 from the signed manifest at install time** | ✅ **done** (`U-223`). **This was the real hole, not `V2-MS12`.** Before it, `PkgarBackend::install()` checked a package **only** with a key fetched from the same host; both blake3 comparisons in `pkg-lib` (`library.rs:144`, `package_state.rs:278`) decide "should I update", not integrity. Whoever took over the package host could keep the original `repo.toml`+`.sig`, swap `id_ed25519.pub.toml` for their own and re-sign the packages — the client would install arbitrary code and the pinned hybrid key would stop nothing. Live on aarch64, because that source is active | 🖥️ | ✅ |
| `V2-MS14` | **`pkg install <name>` did not verify the manifest at all** — only `update` and `-a` did (`pkg-cli/src/main.rs:187-191`) | ✅ **done** (`U-223`): the user's most common operation used to bypass the only working verification | 🖥️ | ✅ |
| `V2-MS15` | **No rollback/freeze protection, contrary to the public claim** — `repo.toml` carried only `build_id`: no timestamp, no counter, no expiry, so a host could serve an old, **correctly signed** index+package pair indefinitely | ✅ **done** (`U-223`): `serial` + `expires`. The README published by `publish-repo-pages.sh` had been promising freeze and rollback protection that **did not exist** — outward-facing text | 🖥️ | ✅ |

### 5.3 Package channel and update trust — `R-7xx`

A hardened CLI substrate exists (`pkg` with an update subcommand; pkgar enforces per-package
ed25519 + blake3 before commit). What sits above it is the open work.

> **Numbering warning:** `R-701`…`R-708` mean **different things** in
> [`docs/architecture/update-system.md`](docs/architecture/update-system.md) §7. `R-704` there means
> *rollback*; here it means *anti-rollback*. See [Annex B](#annex-b--identifier-collisions-and-decisions-d1d7).

| id | item | capability | state |
|---|---|---|---|
| `R-701a` | **Stop trusting the upstream package host.** `config/base.toml` shipped `/etc/pkg.d/50_redox → https://static.redox-os.org/pkg`. Both `config/{aarch64,x86_64}/eos.toml` now override that path with the URL **commented out** — commented, not deleted, because `update_remotes()` skips `#` lines while an empty line reaches `add_remote("")` → `RepoPathInvalid`; a parseable comment-only file is the graceful degrade. **Verified in the running image**, not in the source: `grep -c "^[^#]" /etc/pkg.d/50_redox` → `0`, and `/etc/pkg.d/` holds nothing else. **Gated**, because a one-time verification does not survive the next edit: `ci-integrity.sh` **check 9** requires every `config/*/eos*.toml` to override `50_redox` and forbids that override carrying an active URL. The first version of that gate was wrong and was rewritten — it scanned every file and tripped on `config/base.toml`, which is correctly covered, and a gate that fires on a handled case teaches people to ignore it. **Seen failing** before being called a gate: uncommenting the URL → *"active package remote"*; removing the override → *"does not override … so base.toml's upstream remote ships"*; restored → PASS `[P0·S·🖥️]` (`U-143`, `U-183`) | **WORKS TODAY** | ✅ |
| `R-701` | **Wire a working, E-OS-owned update source.** Publish done (`R-008`/`U-209`), `50_eos` **active on aarch64** with the pinned key measured in the running image (`U-210`: `cat /etc/pkg.d/50_eos` → the URL; `/etc/pkg/eos-repo-sign.pub.toml` present). `pkg update` **reaches the TCP layer** — DNS resolves and it connects to github.io — but a **complete `repo.toml` fetch and signature verification was never captured**: aarch64 under TCG plus TLS to github.io is too slow and unstable in the probe harness. **x86_64 remains unpublished and its `50_eos` is commented out** (`config/x86_64/eos.toml:810-814` — `#https://gh0s777tt.github.io/eos-pkg-x86_64/pkg`; an earlier version cited `:767`), which is audit finding `C-4`. Ordering corrected in `U-134`: this used to depend only on `R-002`, which would have let it land *before* the key was pinned — strictly worse than the inert state it replaced. **Channels (added 2026-09-04, requirement B):** a channel is nothing but the URL in `/etc/pkg.d/50_eos` — the client already reads every non-`#` line of every file there (`pkg-lib/src/repo_manager.rs:209-233`, keyed by host) — so *stable / testing / edge / lts* are **four published addresses**, not code; today only `eos-pkg-aarch64` exists on the publisher and the other three are **🔑 operator work** on the `S-10`/`S-11` pattern. Every new channel host must be added to `scripts/ci-integrity.sh` check 9 (`:226-276`, accepts only `gh0s777tt\.github\.io/eos-pkg-`) or it ships as an unauthenticated source. `R-1002` is the LTS *branch and policy*, not a channel address `[P0·S·🖥️🔑]` | **WORKS TODAY** (aarch64) · **BUILDABLE** (x86_64) · **🔑** (testing/edge/lts addresses) | 🟡 |
| `R-702` | **Pin the repo public key; kill TOFU.** ✅ — **and this is one of the four places the two predecessor documents disagreed.** The old `ROADMAP.md` carried 🚧 in its `R-7xx` section while its own Delivered table already carried "✅ `U-224`"; it contradicted itself. Resolved in favour of ✅ on the evidence: `keys/eos-repo-sign.pub.toml` exists, `config/aarch64/eos.toml:818` and `config/x86_64/eos.toml:849` both install it at `/etc/pkg/eos-repo-sign.pub.toml`, measured in the running system at **4075 B**, byte-identical to the repository file, and the `no pinned repo-manifest key` warning is gone from the log. The key pair was **verified with a test signature** (`U-224`): ed25519 and ML-DSA-65 both pass against the public half, and after flipping one byte both refuse with exit code 1. **What ✅ does not mean, and this residual must survive:** *pinned*, not *enforced end to end*. The closing proof — a live fetch that a wrong key rejects — was never captured, because no remote source was configured when the measurement was taken. That proof belongs to `R-703` `[P0·M·🖥️]` | **WORKS TODAY** | ✅ |
| `R-703` | **Client-side signed-manifest verification.** Publisher half done: `publish-repo-pages.sh`/`publish-repo.sh` emit `repo.toml.sig` via `eos-repo-sign`, and an unsigned publish hard-fails since `U-120`. Client half also done, and this entry claimed otherwise until `U-134`: `pkg-lib` fetches and verifies `repo.toml.sig` — `verify_repo_manifest` → `manifest_sig::verify_manifest_ed25519` — with tamper, wrong-key and malformed-signature tests, at the pinned `eos-pkgutils`. **Remaining:** a captured live end-to-end fetch+verify (see `R-701`), and promoting ML-DSA-65 from advisory to required per `R-503` `[P0·S·🖥️]` | **WORKS TODAY**, unproven live | 🟡 |
| `R-704` | **Anti-rollback / freshness + hash pinning.** The **index** is protected (`V2-MS15` ✅ — `serial`, `expires`); the **package** is not: a correctly signed **older** pkgar still installs. Add a per-package monotonic serial, reject downgrades, pin each downloaded package hash to the manifest hash. **Added 2026-09-04 (requirement B):** the index gains only **additive top-level fields** on `Repository` (`pkg-lib/src/package.rs:373-399`) with `#[serde(default)]` — `critical = ["pkg", …]` (emergency updates; the rule lives in `R-705`) and `rollout_percent` (💡 until `R-606`) — covered by the manifest signature like `serial`/`expires`. **The `packages` map keeps its `BTreeMap<String, String>` value type** (`package.rs:378-380`): a per-package table would be a wire-format break, and a parse failure of the signed index is a hard update failure on every client of the live aarch64 channel (`R-701` 🟡). Round-trip test in the `package.rs:687-723` pattern: an old index parses with the new client, a new index parses with the old. **Per-channel watermark:** `etc/pkg/repo-state.toml` holds one global `serial` (`lib.rs:40`; `pkgar_backend/mod.rs:184-190,201-212`), so switching edge → stable is refused as a rollback today; key the watermark by host (`extract_host`, `repo_manager.rs:236-243`) so a channel change starts its own ratchet instead of reading as a downgrade `[P1·M·🖥️]` · needs `R-703` | **BUILDABLE** | 🔴 |
| `R-705` | **`eos-update` daemon plus a thin CLI** — check → resolve → verify → download → stage → apply, with a scheduling timer, desktop "updates available" notification, a persisted journal and privilege re-exec. **Scope widened 2026-09-04 (requirement B, "update from within the OS"; decision #18):** the daemon also owns the **policy layer** of `system-updates.md` §7.4, which had no register row (`grep -n -iE 'eos-update\.toml|deferral|maintenance window|pin_serial' ROADMAP.md` → 0 register hits before this change). It reads and enforces `/etc/eos-update.toml` — auto-download on/off, defer N days, `pin_serial`, maintenance window — where `pin_serial` is one comparison next to the never-lowered watermark in `etc/pkg/repo-state.toml` (`pkg-lib/src/lib.rs:40`, `backend/pkgar_backend/mod.rs:184-212`); parser `toml` 1.1.5 (MIT OR Apache-2.0, pure Rust, already a `pkg-lib` dependency) `cargo check --target x86_64-unknown-redox` → Finished in the probe crate `xbuild-probe-B-system-updates`. **The scheduler is relative to boot** (first check 15 min after boot, then every 24 h of uptime, a monotonic loop inside an `init` `oneshot_async` service — there is no cron and no timer unit); absolute-time maintenance windows are **💡 until `R-820`** (network time). **Defaults fixed by #18:** download automatically, apply only with consent, **never restart unattended** — `sys:kstop` is root-only (`eos-kernel/src/scheme/sys/mod.rs:139-140`) and the GUI reaches it only through the `R-D11` shim. A package named in the index's `critical` list (`R-704`) bypasses the deferral window, never verification and never the restart consent. **Offline source (was `EC-7`, folded here — no third place):** a signed local mirror on removable media is a *remote in trust terms* — index-enforced, `repo.toml.sig` + serial checked — and never enters through the no-remotes exemption (`pkgar_backend/mod.rs:160-170`); a bare path is `RepoPathInvalid` today (`repo_manager.rs:236-243`), so this is a new source kind, and with no hot-plug bus the user browses to the medium. Staged-rollout bucketing (`blake3(machine_id ‖ serial) mod 100`, zero telemetry) is **💡 until `R-606`** — `machine-uid` 0.6.0 has no Redox `target_os` arm (measured `E0432` at its `src/lib.rs:264`). **Not measured without the container:** curl range/resume in the image, SNTP over slirp, the local-mirror negative control (§15 rows 25–26). Size raised L → XL for the policy engine and the mirror source. Windows/Linux builds: not applicable — OS update policy belongs to the host OS `[P1·XL·🖥️]` · needs `R-703`, `R-D03`; time-window features need `R-820`; rollouts need `R-606` | **BUILDABLE** (policy, mirror, critical) · **💡** (rollouts → `R-606`; maintenance windows → `R-820`) | 🔴 |
| `R-706` | **Staged transactional apply plus one-step rollback.** `transaction.commit()` mutates the live filesystem through an in-memory rename loop with no persisted journal, so a crash mid-loop half-applies with no recovery. Download and verify into staging, snapshot replaced files and `package.toml`, commit under a journal, expose `eos-update rollback`. **Shares its journal format with `R-612c`** — one semantics of resumption, not two. **Rollback by snapshot is impossible and is not the plan:** RedoxFS is internally copy-on-write but exposes **no snapshot API**, and `clone.rs` clones a file tree, not a point in time `[P1·XL·🖥️]` · needs `R-705` | **BUILDABLE**; `fsync` durability on RedoxFS `[UNVERIFIED]` | 🔴 |
| `R-707` | **Base/kernel apply-on-reboot with boot fallback.** Kernel, base and relibc are upgraded by live in-place file replacement — a bad kernel or a power cut can brick a real disk. Stage into `pending/`, flag the bootloader, verify on next boot, auto-revert after N failed boots, keep `kernel`+`kernel.sig` atomic. The **boot-attempt counter is a NEW SUBSYSTEM**: it needs a write path from the bootloader, and whether one exists is `[UNVERIFIED]` (§15 row 12). **ESP visibility, settled 2026-09-04 (ADR-0009 D7's open choice):** the running `eos` image cannot see the ESP — `grep -rn fatfs config/ recipes/ --include='*.toml'` → `redox-fatfs = {}` only in `config/x86_64/ci.toml:215`, absent from every `eos.toml` chain — so the `pending/` marker and the counter have no writable home from user space today. Chosen shape: **`fatfs` 0.3 (MIT) linked into `eos-updated`**, not a `redox-fatfs` scheme in the image — only one root process ever writes the ESP, which sidesteps ADR-0009 note 6's two-writers hazard; measured `cargo add fatfs@0.3 && cargo check --target x86_64-unknown-redox` → Finished (bitflags, byteorder, chrono, log — pure Rust), and the installer already does exactly this from user space in the shipping image (`eos-installer-work/Cargo.toml:28`, `src/installer.rs:609-612` over an `fscommon::StreamSlice`); partitions are addressable by root as `{nsid}p{n}` block paths (`driver-block/src/lib.rs` ~`:465`). **Not measured without the container:** that root in QEMU can open the ESP partition and `fatfs` lists `EFI/BOOT/`, and whether the bootloader reads any flag (§15 rows 12, 24) `[P2·XL·⚙️]` · needs `R-706` | **BUILDABLE** (ESP write, `fatfs` crate) + **NEW SUBSYSTEM** (counter, bootloader side) | 🔴 |
| `R-708` | **"Settings → Update" pane** in the E-OS Settings shell: check/download/verify/apply with progress, changelog, history and rollback; refuses to apply unless manifest signature, per-package ed25519 and anti-rollback all pass; writes an audit log. **Scope widened 2026-09-04 (requirement B; decisions #18, #19):** the pane shows exactly the three visible steps of `system-updates.md` §8.1 — *Download → Verified, ready → Apply / Restart* — and for every package outside class `app` it says **"restart required"**, never "seamless" (no supervisor before `R-816`, §14.4). It edits the same `/etc/eos-update.toml` that `R-705` enforces (auto-download, deferral, `pin_serial`; maintenance window only once `R-820` exists) and offers the **channel picker** over the `R-701` addresses with an explicit confirmation, because with no MAC (`R-1010` off, finding `C-5`) root switches channels freely and the pane must not pretend otherwise. A `critical` package (`R-704`) is shown as a **modal inside the pane**, not as an `R-D03` toast — the toast daemon has no queue and no actions yet. Failure messages follow the §8.4 classes (signature, freshness, hash, space, network) verbatim. **The apply step never runs in the GUI process:** it re-execs through a `/scheme/sudo` shim exactly as `eos-power` does (`R-D11`; `eos-control-work/Cargo.toml:15-25`, `src/elevate.rs`). **Host binary is open (#19):** a placeholder "Aktualizacje" panel already ships in `eos-settings` (`eos-orbutils-work/launcher/src/settings.rs:41-51,127-135`, head `5931fc1`: one note row *"w budowie (R-7xx)"* plus one `Źródło` row per `/etc/pkg.d` entry, **no function**), while the elevation shim lives only in `eos-control` (Slint, head `202c584`: tabs Overview/Network/Storage/Sound/Processes/Security, no Update tab). Windows/Linux builds: not applicable — an OS-update pane has no meaning on a host OS (`PR-008`) `[P1·L·🖥️]` · needs `R-705`, `R-D01`, decision #19 | **BUILDABLE** (shell ✅, placeholder present, no function) | 🔴 |
| `R-709` | **End-to-end integration tests for the update decision** — zero e2e coverage today; exercise `update()` against a `repo.toml` with mismatched hashes and assert signature-failure rejection `[P2·S·🖥️]` · needs `R-703` | **BUILDABLE** | 🔴 |
| `R-710` | **A/B root slots plus delta updates** — parent heading only. Split into `R-710a`/`R-710b` by decision **D4**, because the halves have different dependencies `[P3·XL·⚙️]` | — | 💡 |
| `R-710a` | **Delta / differential fetch.** **Does not need `R-707`.** Not a new format: pkgar is uncompressed and carries `offset` + `size` + `blake3`, so range requests by `Entry.offset` are enough `[P2·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-710b` | **A/B root slots.** Needs `R-707` **and** `R-609`: the installer creates exactly three partitions and gives the whole tail of the disk to one RedoxFS, so A/B is a **partitioning** change `[P3·XL·⚙️]` | **BUILDABLE**, not on a machine installed today | 💡 |
| `R-711` | **On-device key rotation and revocation.** pkgar binds a package to exactly one embedded key, with no keyring and no revocation list. Target: `/etc/pkg/keys.d/` with `not_before`/`not_after`/`revoked`, covered by the index signature. Required for the `R-503` PQ migration to be enforceable, and a precondition of `R-603e` — a profile signature with no revocation is irrevocable `[P2·M·🖥️]` · needs `R-702` | **BUILDABLE** | 🔴 |
| `R-712` | **User and administrator documentation** of the check/verify/apply/rollback flow and its trust model `[P2·S·🖥️]` · needs `R-705` | **BUILDABLE** | 🔴 |

### 5.4 Keys, custody and rotation

| id | item | state |
|---|---|---|
| `R-503` | **Hybrid post-quantum package signing, ed25519 + ML-DSA-65.** Delivered; `tools/eos-repo-sign` is E-OS's own code (9 tests, 41.06 % line coverage against a 38 % floor). Cross-referenced from many places; **remaining scope is promoting ML-DSA-65 from advisory to required at the client**, which is tracked in `R-703` | ✅ (with the named remainder) |
| `R-502` | **RedoxFS AES-XTS full-disk encryption** with ARMv8 crypto-extension acceleration. Delivered; referenced as the engine several "notebook features" should be wired to rather than rewritten (§7.4) | ✅ |
| `R-502b` | **Hardware SHA acceleration** — parent scope of `R-914`; kept as a cross-reference, not re-minted (Annex C.1) | cross-reference only — the work is `R-914`, open |
| `R-301` | **Signed release checksums for `harddrive.img`.** Closed in an earlier roadmap generation. Kept here because `R-611` cites it to prove it is not a duplicate: `R-301` covers the **pre-installed image**, `R-611` covers the **installation medium** — two different files | ✅ `f17427863`, `630d98e40` (v0.3.0 "Fortify" commits) |
| `R-F26` | **Release signing key rotated** — see §10 | ✅ |
| `V2-MS12b` | **Package-key custody** — see §5.2 | 🟡 |
| `V2-MS06` | **Boot-signing key on a hardware token** — see §5.2 | 🔴 |

**Target state**, stated so nobody reads the present as the plan: an HSM or Vault. Today the secret
half lives outside the repository in the operator's hands (`keys/README.md`); only public halves are
in the tree. **Key generation is a human action and is deliberately not automated** (`CLAUDE.md`
§5.7, §14).

---

## 6. Installer, wizard and updates

A capable install engine ships (`redox_installer` 0.2.42: GPT + EFI/BIOS, RedoxFS, AES-XTS FDE,
ed25519 pkgar verification, fast clone), and a full partition → install → reboot → login cycle is
proven under QEMU. What is missing is everything that makes it a **product**: a named and signed
medium, a transaction that survives interruption, a wizard that collects more than a disk and a
password, and an update path that does not mutate a live system in place.

**Source specifications** — this section turns four design documents into epics → milestones →
individually falsifiable tasks; it does not restate their design:
[`installer.md`](docs/architecture/installer.md) ·
[`installer-wizard.md`](docs/architecture/installer-wizard.md) ·
[`installer-profiles.md`](docs/architecture/installer-profiles.md) ·
[`system-updates.md`](docs/architecture/system-updates.md). Decisions:
`ADR-0007`–`ADR-0011`, plus **two decisions that have no ADR** and are named in Annex B (D6).

### 6.1 Three epics

| epic | what it delivers | specification | families | state |
|---|---|---|---|---|
| **EP-1 — the installation medium as a product** | a USB stick a real person downloads, checks by signature, writes and installs from, onto a real disk | `installer.md` | `R-601`, `R-604`, `R-607`, `R-608`, `R-609`, **`R-611`–`R-615`**, `R-F28` | 🔴 |
| **EP-2 — installation wizard and profile model** | one engine, two front-ends with no drift; feature and profile data as **one** source of truth for the wizard, the documentation and unattended mode | `installer-wizard.md`, `installer-profiles.md` | `R-603`, `R-604`, `R-605`, `R-606`, `R-608`, `R-609`, `R-616`, `R-D08`, `R-711`, `R-1010`, **`R-815`**, **`R-D13`** | 🔴 |
| **EP-3 — updates: transaction, activation on reboot, A/B slots** | an update whose interruption does not leave a brick; rollback in one command; A/B only at the end | `system-updates.md` | `R-704`–`R-712`, `R-710a`/`R-710b`, **`R-816`**, resting on `R-701`, `R-303`, `R-503`, `R-606`, `V2-MS12b` | 🔴 |

**Why three and not one:** they have different evidentiary standings. EP-1 ends on ⚙️ metal and
without it is unproven. EP-2 is entirely 🖥️-provable under QEMU. EP-3 is 🖥️-provable through stage
E3 and needs ⚙️ from E4 (`R-707`), because the bootloader cannot be proven in a Mac-QEMU GUI loop.

**What these epics deliberately exclude:** Secure Boot beyond what it implies for the medium
(settled in `ADR-0005`/`ADR-0006`, track B in §5.2), and the driver layer (`R-8xx`) except the
**two** items those documents require and which had no home: `R-815` (an administrative command
channel to disks, a precondition of full disk identification) and `R-816` (a process supervisor, a
precondition of the `service` package class). Both belong to `R-8xx` because they concern drivers
and service lifecycle, not installation.

### 6.2 Installer and first boot — `R-6xx`

| id | item | capability | state |
|---|---|---|---|
| `R-601` | **QEMU install-to-second-disk boot-verify harness.** ✅ **PROVEN** (`U-176`): `scripts/ci-install-smoke.sh` reports *"PASS — installed to a second disk and booted it to a login prompt"*, **three times in a row** — partition → install → reboot → login, end to end, for the first time in the project's history. Getting there ran through five defects, **none of them visible until the previous one was removed**: `R-F16` (a silent boot stall from a GIC read-modify-write) → `R-F19` (the unmount error masked the install result) → `R-F21` (package database at a path that no longer exists) → `R-F22` (the copy collided with the configuration layer) → `R-F24` (the fast path never ran). The long-standing "raid1d holds the target disk" theory was tested and **disproved**. Conditions: boot from `redox-live.iso` (live mode on by default), `EOS_SMOKE_MEM=4096`, TCG emulation. ✅ is **the `U-176` proof**; the coverage gaps below are `R-601a`–`R-601e`, not a retraction `[P0·M·🖥️]` | **WORKS TODAY** | ✅ |
| `R-601a` | `build-image` / `build-image-x86_64` also build the installation medium and export it as an artefact. ✅ **done 2026-09-01** (#4): the medium is built (`.gitlab-ci.yml:430`, `:534`), boot-smoked, checksummed, signed, and now published — both images compressed `zstd -3 -T0`, 345 MB of artefact against a 1 GiB cap, `201 Created` in the nightly run. Checksums stay over the RAW images: what a person verifies is the file they write to a disk. | **WORKS TODAY** | ✅ |
| `R-601b` | `scripts/ci-install-smoke.sh` starts **from the medium**, not from `harddrive.img`, and is wired into scheduled CI. ✅ **done 2026-09-01** (#5): `grep -c "install-smoke" .gitlab-ci.yml` → **10**; the harness starts from `$MEDIUM` in the nightly `build-image` (`:459`, `:569`) and passed end to end on aarch64 — `install-smoke: PASS — installed to a second disk and booted it to a login prompt`. Negative control: run the harness against an image with no installer → FAIL, not "PASS out of silence" `[P1·M·🐧]` | **WORKS TODAY** | ✅ |
| `R-601c` | The same harness runs on **x86_64**. ✅ **done 2026-09-02** (#6, #24): a clean x86_64 build runs `scripts/ci-install-smoke.sh` through to *"PASS — installed to a second disk and booted it to a login prompt"*, exit code 0, including stage 2 (the installed disk boots on its own). Two causes, both confirmed by reverting them: (a) the `getty` terminal-size probe swallowed typed input — `266c4f4` in `eos-userutils` (!49); (b) a **second** getty on the same serial console, so a second `login` ate the next line typed and answered *"Login incorrect"* — with it the run passed **2 times out of 7**, without it **5 out of 5** (#24). The earlier stall was **not** a stray newline left by `login`: instrumentation that drained stdin immediately before `passwd` found the queue **empty** `[P0·M·🖥️]` | **WORKS TODAY** | ✅ |
| `R-601d` | GUI ↔ TUI parity gate: both front-ends must cover the same state set `[P2·S·🖥️]` | **BUILDABLE** | 🔴 |
| `R-601e` | Missing harness cases — **FDE ✅ 2026-09-02** (`EOS_SMOKE_FDE=1`: prompt → wrong password refused → right password → `eos login:`, with `EOS_SMOKE_FDE_NEGATIVE=1` as the control, §1.4); still missing: interruption in phase 1/3, two disks with the wrong one chosen, a 4Kn disk, BIOS boot. **The interruption case is the only test of the M2 transaction** `[P1·M·🖥️]` | **BUILDABLE** | 🟡 |
| `R-602` | **First-boot OOBE wizard.** Password enforcement is **done and verified on every login path**. Text/getty and serial (`U-076`, `U-077`): a shared `force_first_boot_passwd` helper forces `passwd` before the shell for the passwordless `user` **and** any account still on the shipped default, order-independent so it catches `root/password`. Graphical greeter (`U-079`): `orblogin` — the default path since `R-F08` — no longer lets a default-credential account reach the desktop; it switches in-window to New password → Confirm, `set_passwd`+`save` (`Config::writeable(true)`, else EBADF), then starts the session. The live P0 default-credentials exposure is closed on both paths. **Remaining: per-machine identity** (hostname, locale, keymap, machine-id, SSH host keys) → `R-606` `[P0·L·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-603` | **Enrich the installer front-ends: account, hostname, locale.** Both GUI and TUI clone `base.toml` defaults and create no accounts (`installer_tui` TODO#3 unimplemented). Collect username+password, hostname, timezone, locale and keyboard, and feed `config.users`/`hostname` instead of the baked defaults `[P1·L·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603a` | **Move disk-selection logic out of the front-end into the library.** `installer_tui` has its own `disk_paths()` and `choose_disk()`, so GUI and TUI can diverge — a measured debt, not a hypothesis. The engine-with-two-front-ends shape already **exists** (`src/lib.rs` + `src/bin/installer.rs` + `src/bin/installer_tui.rs`, with the GUI a separate crate depending on `redox_installer` by path) `[P1·L·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603b` | Wizard state machine S0–S10: transition rules, point of no return, validation, and an S8 diff-and-risk screen `[P1·L·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603c` | Profile and feature data model in TOML: `serde` types plus a resolver (`installer-profiles.md` §3). **Inheritance with locks:** the `include = [...]` mechanism **exists** (`config/x86_64/eos.toml:7` → `["../desktop.toml"]`, and `config/desktop.toml:3` → `["desktop-minimal.toml", "server.toml"]`, so the chain is already two levels deep) but it merges *files*, not *decisions*, and has no locks `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603d` | Account, hostname, timezone and keyboard layout collected by **both** front-ends and fed to `config.users`/`hostname`. A timezone **database is a NEW SUBSYSTEM** — today `/etc/tz-offset` is a constant number. Keyboard layouts `[UNVERIFIED]`: check `eos-orbital`, `eos-orbdata` `[P1·L·🖥️]` | **BUILDABLE** + **NEW SUBSYSTEM** (tz db) | 🔴 |
| `R-603e` | On-device verification of the **profile** signature. Needs `R-711`: without a keyring a profile signature is irrevocable `[P2·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-604` | **Destructive-action guardrails.** Whole-disk erase hides behind a bare numeric menu with no disk identification. Parent of `R-604a`–`R-604d` `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-604a` | Disk picker shows **device path, size, interface type and removability**; erase is confirmed by **retyping the device path**, not by picking a number. Negative control: two disks in QEMU, type the wrong name → refusal, zero writes. Today the harness expects the literal `Select a drive from 1 to`, and **the number in that menu changes between runs** if PCI enumeration order changes `[P0·M·🖥️]` | **BUILDABLE** | ✅ **done 2026-09-01** (#9): the screen ran on Redox for the first time and refused a name matching no disk. Both halves of the negative control are now MEASURED, not inferred — the driver stats the target either side of the refusal and requires zero allocated blocks. Pinned at `eos-installer 2aae3ace0bbf`; `pin-allowlist.txt` is empty again. |
| `R-604b` | Diff screen before any write: the exact list of operations; writing starts only after it `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-604c` | Refuse dangerous targets — the disk carrying the medium, or the only disk holding another OS — without an explicit override. Needs `R-607a` `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-604d` | Per-policy-weakening confirmation: extend the erase barrier to hardening downgrades on the same screen `[P2·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-605` | **Point the installer's online path at the signed E-OS repository, architecture-aware.** The network path fetches from upstream `https://static.redox-os.org/pkg` with a hard-coded aarch64 target and an unwrap on fetch. **WORKS TODAY on aarch64** (the source is active); **BUILDABLE on x86_64** and blocked by `C-4` `[P1·M·🖥️]` · needs `R-008` ✅, `R-703` | **WORKS TODAY** / **BUILDABLE** | 🔴 |
| `R-606` | **Per-machine identity at install:** a unique hostname (**every** install is `eos` today), `machine-id`, managed SSH host keys (openssh ships, keys are unmanaged) `[P1·S·🖥️]` · needs `R-602` | **BUILDABLE** | 🔴 |
| `R-607` | **Real block size (4Kn) plus a real-firmware install matrix.** Parent; split by decision **D3** into `R-607a` and `R-607b` because the halves have different evidentiary standings and different priorities — one identifier carrying both forced the whole thing to `[P2·metal]`, although the software half is cheap and blocks M1 | — | 🟡 |
| `R-607a` | **`DiskWrapper::open` asks the device for the real block size**; on a 4Kn disk the installer **refuses** instead of computing GPT geometry against a wrong 512. ✅ **done** — merged and pinned 2026-08-30 (`eos-installer` `74726c889b`). This revives the dead `_ => bail!` at `installer.rs:604`, because `disk_wrapper.rs:28` had `let block_size = 512;` hard-coded. Textbook *a control that cannot fail is not a control*. Negative control: QEMU with `logical_block_size=4096` — before, the install proceeds with wrong LBA arithmetic; after, an explicit refusal; the mutation that let 4096 through killed exactly one of three tests. **`[UNVERIFIED in-tree]`**: `recipes/core/installer/` holds only `recipe.toml`, so ✅ rests on the pin bump, not on code read in this tree — expand with `scripts/eos-sync-buildtree.sh --apply` and read `disk_wrapper.rs:28` `[P0·M·🖥️]` | **BUILDABLE** | ✅ |
| `R-607b` | **Hardware half: the real-firmware install matrix.** M1 needs its **first row** — one physical PC. M2 needs the rest: AMI/Insyde/Phoenix firmware, NVMe/AHCI/USB, 512e and 4Kn, legacy BIOS, a disk carrying Windows and one carrying Linux. Today [`docs/reference/hardware-matrix.md`](docs/reference/hardware-matrix.md) has **zero E-OS rows** — it is measured under QEMU, and `HARDWARE.md` carries upstream data. **Ten matrix rows are ten separate measurements, not one box to tick** `[P0·M·⚙️]` | **BUILDABLE**, ⚙️ only | 🔴 |
| `R-608` | **Correct `docs/getting-started/install.md` so it matches the shipped installer.** ✅ **done 2026-08-31.** The §2 accusation about account creation was already answered by the explicit ⚠️ callout in the page (*"It does not create accounts, and it does not let you pick packages"*). The M1 half — artefact name and write procedure true after `R-611a` — is now met: `grep -c 'redox-live.iso' docs/getting-started/install.md` → **0**, the build command is `make … live` with `make print-installer-medium` for the name, and the `dd` procedure covers both the build tree and a checked release artefact. **A third defect was found and fixed while verifying this one:** §3 gave `redox_installer <config.toml> <disk>`, which is **reversed** — measured in the pinned installer revision `74726c889b`, `src/bin/installer.rs:208` takes `parser.args.first()` as the path handed to `install(config, path)`, so the old line pointed the installer at the reader's TOML file. Scope corrected 2026-08-15 (`U-126`): the encryption-walkthrough accusation was **wrong**, the `redoxfs password` prompt is real `[P1·S·🖥️]` | **WORKS TODAY** | ✅ |
| `R-608a` | **Generate the installer documentation from the same feature data the wizard uses**, so drift becomes impossible. The precedent is measured: `R-608` exists **only** because a document described features the binary does not have `[P1·S·🖥️]` | **BUILDABLE** | 🔴 |
| `R-609` | **Manual partitioning / install-alongside (dual-boot).** Today whole-disk erase is the only mode. **Becomes a precondition of `R-710b`**, because A/B is a partitioning change `[P3·XL·🖥️]` · needs `R-604` | **BUILDABLE** | 💡 |
| `R-609d` | S4 partitioning modes: manual GPT editor, reuse of an existing ESP (writing **only** into `EFI/EOS/`), install into free space, other-OS detection by ESP. NTFS/ext4 resize is **NOT FEASIBLE TODAY** — we cannot even read those filesystems. This is `R-609` written out, not new work `[P3·XL·🖥️]` | **BUILDABLE** / **NOT FEASIBLE TODAY** (resize) | 🔴 |
| `R-610` | **Repoint the installer's build dependencies onto E-OS-controlled forks.** `redox_installer` pins git crates to `gitlab.redox-os.org` (`arg_parser`, `liblibc`, `pkgutils`, `redoxfs` 0.3), so "we build from OUR signed source" holds at the runtime remote but not at the build-dependency layer `[P1·M·🖥️]` · needs `R-F02` ✅ | **BUILDABLE** | 🔴 |
| `R-611` | **The installation medium as a release product.** Parent of `a`–`d`. Not a duplicate of `R-301`: that closed item covers the **pre-installed image**, this one the **installation medium** — two different files. Extending a closed item would have hidden that | **BUILDABLE** | 🟡 |
| `R-611a` | `mk/disk.mk` produces `eos-<ver>-<arch>-installer.img` instead of `redox-live.iso`. ✅ **done** — `mk/config.mk:198` `INSTALLER_MEDIUM_NAME=eos-$(EOS_VERSION)-$(ARCH)-installer.img`, `make print-installer-medium` at `Makefile:14`, and `scripts/eos-build.sh:31` reads that name and `:72` builds the target. **The reason is not "it isn't an ISO"** — the file *is* ISO 9660 (§14). The reason is that `.iso` promises a disc that will not boot, and `redox-live.iso` says neither whose system it is, nor which version, nor that it installs `[P1·S·🖥️]` | **BUILDABLE** | ✅ |
| `R-611b` | `scripts/make-release.sh` packs the medium **alongside** `harddrive.img`, hashes it into `SHA256SUMS` and is therefore covered by the minisign signature over that file. **Done 2026-08-31.** The medium's *name* comes from `mk/config.mk` through `make print-installer-medium`, so the naming rule keeps one home. Two further defects were measured and closed in the same change: the script hard-coded `build/$arch/eos/` while `.config` sets `CONFIG_NAME` with `?=`, so `CONFIG_NAME=desktop` would have mixed two configs into one `SHA256SUMS`; and `VERSION` defaulted to `0.1.0` while the build stamped `EOS_VERSION=0.2.0` into the medium's filename, so it now defaults to `make print-eos-version` and **refuses** a version it did not build. Proof by control test: on the pre-change script the new suite scores **5 failed / 2 passed**, the two passes being the controls `[P0·S·🖥️🔑]` | **WORKS TODAY** | ✅ |
| `R-611c` | The medium carries `EFI/EOS/eos-secureboot.der` plus `EFI/EOS/README.txt` explaining how to enrol the certificate in firmware. ✅ **done 2026-08-31** — `scripts/eos-esp-add-cert.sh`, called from both `eos-build.sh` and the CI build jobs so there is one implementation rather than two that drift. The ESP offset is **read from the GPT**, not assumed at 1 MiB, because `R-609` plans to repartition. Measured on both arches: `eos-secureboot.der` 813 B, `README.txt` 1535 B, 788 480 B still free on the 1 MiB ESP. The check the task asks for runs **inside** the script against the files actually on the medium: shipped certificate verifies `BOOTX64.EFI` (x86_64) and `BOOTAA64.EFI` (aarch64); a freshly minted foreign certificate is **refused**. Mutation: shipping a foreign certificate instead of ours gives *"the shipped certificate does NOT verify the shipped bootloader"* and exit 1 — the gate can fail `[P1·S·🖥️]` | **WORKS TODAY** | ✅ |
| `R-611d` | Fix the El Torito boot-catalogue entry for the **EFI** platform, which currently points at zero bytes. **This is not "build a hybrid image"** — the hybrid is measured and present (§14); one catalogue entry is wrong. An entry pointing at zeros is a control pretending to be a capability. Deliberately **excluded from M1** — convenience for Ventoy and VMs, not a precondition — and scheduled in **M2** `[P2·S·🖥️]` | **BUILDABLE** | 🔴 |
| `R-611e` | **The medium identifies itself as E-OS, not as Redox OS.** ✅ **done 2026-09-01.** The ISO 9660 volume identifier is the name a person meets when the stick is plugged in -- file manager, `lsblk`, the firmware's boot menu. `R-611a` renamed the FILE; this was the same claim one level deeper. Set in `eos-bootloader/asm/x86-unknown-none/iso.asm:15`, which is **x86_64 only**: measured, the aarch64 medium has **no ISO structure at all** (offset `0x8000` is zeros). Risk analysis for a boot-area change: the field is **write-only** -- nothing in the fork and nothing in this tree reads or compares it. Proven on the rebuilt artefact, both halves: label `'Redox OS'` -> `'E-OS'` at offset `0x8028`, **and** `boot-smoke: PASS -- reached userspace login`. **Identifier note:** the fork commit message says `R-611d` in error -- that id was already taken by the El Torito fix above. The published commit is not rewritten (§5.7); this row is the correction `[P2·S·🖥️]` | **WORKS TODAY** | ✅ |
| `R-612` | **Installation transaction.** Parent of `a`–`d`. Not `R-706`: that is the **update** transaction in `pkg-lib`; this is the **installation** transaction in `redox_installer` — different code, different moment. What they share is the **journal format**, and `R-612c` carries that as a requirement so two semantics of resumption never appear | **BUILDABLE** | 🟡 |
| `R-612a` | **Invert the write order:** ESP and bootloader land only **after** the root, so an interrupted install does not leave a disk that *looks* bootable. ✅ **done** ([eos-installer !3](https://gitlab.com/e-os/eos-installer/-/merge_requests/3)), merged and pinned 2026-08-30. Measured in both directions, killing the installer at the same point (`timeout -s KILL 5` at "Installing to RedoxFS"), inspecting the **1 MiB ESP region** rather than the whole image: old code → `FAT12, 1× BOOTX64`; new → `no filesystem, 0× BOOTX64`; a completed install → `FAT12, 1× BOOTX64`. **`[UNVERIFIED in-tree]`** for the same reason as `R-607a` — read `installer.rs:604` and the write ordering after `--apply` `[P0·S·🖥️]` | **BUILDABLE** | ✅ |
| `R-612b` | Phase 2 "verify" before commit: re-read the payload, blake3 per package on the file path. The primitive **WORKS TODAY** (`V2-MS13`/`U-223`); what is missing is making it a transaction phase `[P1·M·🖥️]` | **WORKS TODAY** → **BUILDABLE** | 🔴 |
| `R-612c` | `EFI/EOS/install-journal.toml` on the ESP: an intent record before each phase, `fsync`, a completion marker after. **Same format as `R-706`'s journal** `[P2·L·🖥️]` | **BUILDABLE** | 🔴 |
| `R-612d` | Resumability: at start the installer reads the journal from the ESP of every visible disk and offers *resume* or *discard*. Needs `R-612c` `[P2·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-613` | Checksum the whole copied region on the **block path** (`try_fast_install`) against the image sum signed in trust layer 4. The file path is covered by `V2-MS13`/`V2-MS14`; the block path copies **bytes from RAM**, not packages, so that verification cannot apply — and the block path is the **default**, because the difference is ~6 min against ~6.8 h (`U-176`). **`[UNVERIFIED]` what `try_fast_install()` verifies today** — check `installer.rs` around line 765 `[P0·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-614` | **The medium as a rescue system.** Parent of `a`–`c`. A separate rescue medium is **refused** (`installer.md` §10 item 7): a second artefact means a second checksum, a second signature and a second thing that goes stale. This is content of *this* medium, so there is no other item it could sit on | **BUILDABLE** | 🔴 |
| `R-614a` | Medium menu: *install* / *rescue* / *verify medium*; the check hashes against a `SHA256SUMS` carried on the medium whose signature is verified with `keys/eos-release.pub`. Needs `R-611b` `[P2·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-614b` | Offline repair: rebuild the ESP and bootloader, restore kernel and initfs **together with their `.sig`**, reset the password after mounting the root `[P2·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-614c` | Break-glass account / password reset from the medium. Tied to audit finding `C-18` and to `S-19`; the finding text is now readable in the tree (`docs/audit/03-security-audit-2026-08-30.md`) rather than cited second-hand `[P2·S·🖥️]` | **BUILDABLE** | 🔴 |
| `R-615` | **An `fsck` for RedoxFS.** It does not exist, so the only answer to post-power-loss corruption is reinstalling. `installer.md` §8.1 found **no `R-*` item** for it — a gap in the roadmap as much as in the code — so the item is minted here. **The supporting measurement (`build/fstools/bin/` holding only `redoxfs` and `redoxfs-mkfs`) is not reproducible in a clean tree**: `build/` currently holds `container.tag`, `hostbuild-eos-control` and `id_ed25519.pub.toml`, and `build/fstools/` does not exist. Re-measure after `make fstools` `[P2·XL·🖥️]` | **NEW SUBSYSTEM** | 🔴 |
| `R-616` | **Profile model and unattended installation.** Parent, **minted by decision D7** in this merge. `R-609` means *manual partitioning / install alongside*; a profile validator, an answer file and Gamer/Business/Ghost profiles are **not partitioning**, so hanging them off `R-609` gave that number a third meaning — the exact defect Annex B exists to fix. `R-616` was the first free number in the family and was verified free | — | 🔴 |
| `R-616a` | Profile and feature validator distinguishing `bad` (the file is wrong) from `cannot` (the system cannot do it). *Was `R-609a`* `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-616b` | Answer file: a `[setup]` section, destruction consent for unattended mode, and **the wizard writing the file out**. *Was `R-609b`.* **Partly WORKS TODAY** — `redox_installer --config=file.toml` *is* an unattended install; what is missing is the wizard emitting the file and the TUI/GUI loading one `[P1·M·🖥️]` | **WORKS TODAY** (partly) | 🔴 |
| `R-616c` | Gamer / Business / Ghost profiles — **only the content that can actually be delivered**. Mixed capability: Ghost — Tor **NEW SUBSYSTEM**, VPN **NEW SUBSYSTEM**, amnesic mode **NOT FEASIBLE TODAY**; Business — firewall **NEW SUBSYSTEM** (`R-904`, `C-10`), audit log **NEW SUBSYSTEM** (`C-9`), domain/LDAP/MDM **NOT FEASIBLE TODAY**. **A disagreement between two specifications, to be removed at approval:** `installer-wizard.md` §14 classifies the firewall as **BUILDABLE — `R-904`**, `installer-profiles.md` §8 item 22 as **NEW SUBSYSTEM** (*"Redox has no netfilter"*). The register takes the `installer-profiles.md` reading because it carries the justification; the correction belongs in `installer-wizard.md`. *Was `R-609c`* `[P2·M·🖥️]` | mixed | 🔴 |

### 6.3 M1 tasks, individually falsifiable

This is the most operationally valuable table in either predecessor and it is reproduced in full,
with the **proof it is done — and how it fails** column intact. Status source is §6.2; this table
is the schedule.

| # | id | task | proof it is done — and how it fails | work |
|---|---|---|---|---|
| 1 | `R-611a` ✅ | `mk/disk.mk` target produces `eos-<ver>-<arch>-installer.img` | `make CI=1 ARCH=x86_64 CONFIG_NAME=eos live` yields the new name; **fails** if a target still refers to the old path. Before the change, `grep -c redox-live Makefile mk/*.mk` → **13 hits in 4 files**, so this was never a one-liner | `[P1·S·🖥️]` |
| 2 | `R-611b` ✅ | `make-release.sh` packs, hashes and signs the medium | ✅ met — `scripts/eos-test-make-release.sh`, wired into `verify.sh` as stage `release-pack`; 7 cases, 4 of them refusals | `[P0·S·🖥️🔑]` |
| 3 | `R-611c` ✅ | medium carries `eos-secureboot.der` + README | ✅ met — both PASS lines emitted by `scripts/eos-esp-add-cert.sh`, on both arches | `[P1·S·🖥️]` |
| 4 | `R-601a` ✅ | CI builds and exports the medium | measured today `grep -c "redox-live" .gitlab-ci.yml` → **0**; after the change, removing the step turns the job red | `[P1·S·🐧]` |
| 5 | `R-601b` ✅ | install-smoke starts from the medium, on a schedule | ✅ done 2026-09-01: `grep -c "install-smoke" .gitlab-ci.yml` → **10**; negative control run — an image with nothing to install gives `FAIL — timed out waiting for the login prompt`, `EXIT=1` | `[P1·M·🐧]` |
| 6 | `R-601c` ✅ | the same harness on x86_64 | ✅ met 2026-09-02 (#6, #24) — *"PASS — installed to a second disk and booted it to a login prompt"*, exit 0, stage 2 included. Two negative controls: revert `266c4f4` (the `getty` input fix) → *"saw a rejected login"*, FAIL; restore the duplicate serial getty → 2 passes in 7 runs, against 5 in 5 without it | `[P0·M·🖥️]` |
| 7 | `R-607a` ✅ | real block size; refuse rather than mis-compute on 4Kn | QEMU `logical_block_size=4096`: before → wrong LBA arithmetic proceeds; after → explicit refusal | `[P0·M·🖥️]` |
| 8 | `R-612a` ✅ | invert the write order, root before ESP | kill at the same point; ESP region: old → `FAT12, 1× BOOTX64`; new → `no filesystem, 0× BOOTX64` | `[P0·S·🖥️]` |
| 9 | `R-604a` ✅ | disk picker identifies the disk; confirm by retyping the path | ✅ met 2026-09-01 (#9) — two disks offered by path, wrong name refused, target byte-for-byte untouched (0 blocks), installed disk boots on its own | `[P0·M·🖥️]` |
| 10 | `R-608` *(part)* ✅ | `install.md` tells the truth about the artefact name and write procedure | ✅ met — `grep -c 'redox-live.iso' docs/getting-started/install.md` → **0** | `[P1·XS·🖥️]` |
| 11 | `R-607b` *(one row)* | **first run on metal** — one PC, symptom form filled in, result recorded as the **first E-OS row** in the hardware matrix | today the matrix has zero E-OS rows. Criterion: boots → sees the disk → installs → reboots without the medium → login | `[P0·M·⚙️]` |

> **Correction to task 8, written after implementation, kept visible.** The original description
> had two errors, both found only while implementing it.
> 1. **The quoted evidence did not support the thesis.** The sentence *"stage 2 then found an
>    unbootable disk"* from `scripts/install-smoke-drive.py:87` describes a **bug in the first
>    version of the harness** (it matched the pre-install prompt, returned immediately and killed
>    the machine mid-write), not the installer's write order. The thesis was true — the order was
>    confirmed in code (`with_whole_disk`: GPT → ESP → RedoxFS) — but the proof was substituted.
> 2. **The promised effect is unachievable.** "An interruption leaves a disk that **still boots the
>    old system**" cannot hold at any ordering of these writes: the GPT must exist before anything
>    reaches a partition, so the old partition table is gone long before the ESP, and the new root
>    overwrites old data. The achievable — and implemented — property is different but real:
>    **"obviously not installed" instead of "looks installed and isn't"**; the firmware finds no
>    boot entry and falls through to the next medium, i.e. the stick the install was started from.

### 6.4 M2–M8 task tables

**M2 — an interrupted install does not leave a brick:** `R-612b`, `R-613`, `R-612c`, `R-612d`,
`R-614a`, `R-614b`, `R-614c`, `R-604b`, `R-604c`, `R-615`, `R-611d`, and the remaining rows of
`R-607b`. Statuses in §6.2.

**M3 — one truth for GUI and TUI:** `R-603a`, `R-603b`, `R-603c`, `R-603d`, `R-603e`, `R-606`,
`R-605`, `R-D08`, `R-601d`, `R-601e`, `R-815`.

> **M3 works without `R-815`.** Disk identification then degrades to path, size, interface type and
> removability — **less** than the requirement asks for (model, serial number, SMART). That has to
> be written **on the screen**, not discovered in a bug report.

**M4 — profiles and unattended mode:** `R-603c` (inheritance with locks), `R-616a`, `R-608a`,
`R-D13`, `R-616b`, `R-604d`, `R-616c`, and `R-1010` as the sandbox precondition for profile import.

**M5–M8 — EP-3 by the stages E0–E8 of `system-updates.md` §9:**

| milestone | stages | items | capability breakdown |
|---|---|---|---|
| **M5** | E0, E1 | `R-706` (part), `R-705` (part), **`R-704`**, `R-709` | atomic state write **BUILDABLE** · `curl` limits **BUILDABLE** · per-package anti-rollback **BUILDABLE** (index already protected, `V2-MS15` ✅) · refuse without a pinned key **BUILDABLE** (key pinned, `R-702` ✅) |
| **M6** | E2, E3 | **`R-705`**, **`R-706`** | daemon + scheme **BUILDABLE** · intent journal **BUILDABLE** (`fsync` durability on RedoxFS `[UNVERIFIED]`, `ADR-0009`) · rollback **by snapshot — ruled out**, RedoxFS has no such primitive |
| **M7** | E4, E5 | **`R-707`**, **`R-708`**, **`R-712`** | `pending/` staging **BUILDABLE** · **boot-attempt counter NEW SUBSYSTEM** (`ADR-0009` requires a write path from the bootloader; whether one exists is `[UNVERIFIED]`) · pane in `R-D01` **BUILDABLE** (shell ✅) |
| **M8** | E6, E7, E8 | **`R-711`**, **`R-710a`**, **`R-710b`** + **`R-609`** | keyring/revocation **BUILDABLE** · **deltas BUILDABLE, not a new format** (pkgar is uncompressed, with `offset`+`size`+`blake3`) · **A/B slots BUILDABLE but not on a machine installed today** (needs repartitioning, `R-609`) · `ostree`/`systemd-sysupdate` as a base — **NOT FEASIBLE TODAY** |

**Off this path, but the sense of EP-3 depends on it:** `R-701` (x86_64 channel — none active today,
`C-4`), `R-303`/`V2-MS07` (reproducibility), `V2-MS12b` (custody of the package-signing key —
plaintext today), `R-606` (per-machine identity — without it there are no staged rollouts), `R-503`
(promoting ML-DSA-65 from advisory to required at the client).

**Also outside the path, because the requirement asks about it directly:** live kernel patching in
the `kpatch`/`livepatch` style — **NOT FEASIBLE TODAY** (no `ftrace`, no loadable modules, no
runtime symbol relocation; `system-updates.md` §6.2). The microkernel equivalent — **restarting a
driver without restarting the system** — is **BUILDABLE**, but it needs a process supervisor that
**does not exist and had no register item**: `init` knows exactly two service types (`oneshot`,
`oneshot_async`) and supervises nothing after start. That is `R-816` (§8.2).

### 6.5 Dependency graph

```
EP-1 medium:
  R-611a name ─→ R-611b sum+signature ─→ R-614a medium check
  R-611a ─→ R-601a CI builds it ─→ R-601b harness from the medium ─→ R-601c x86_64
  R-607a block size ──┬─→ R-604c refusals
                      └─→ R-607b matrix on metal (⚙️)
  R-612a order root→ESP ─→ R-612b verify ─→ R-612c journal ─→ R-612d resume
  R-613 block-path sum ─→ R-612b
  R-604a identification ─→ R-604b diff screen ─→ R-604d per policy weakening

  M1 = {R-611a,b,c · R-601a,b,c · R-607a · R-612a · R-604a · R-608(part) · R-607b(1 row)}
  M2 = {R-612b,c,d · R-613 · R-614a,b,c · R-604b,c · R-615 · R-611d · R-607b(rest)}   needs M1

EP-2 wizard:
  R-603a engine/front-end boundary ─→ R-603b state machine ─→ R-603c data model
  R-D08 GUI flow ─→ R-601d parity gate
  R-603c ─→ R-608a docs from data  ·  R-603c ─→ R-616b answer file
  R-711 keyring ─→ R-603e profile signature  ·  R-D13 i18n ─→ M4
  R-815 disk command channel ─→ full identification in R-604a, closes R-607a  (⚙️)
  R-1010 contain ─→ sandboxed profile import (M4)

  M3 needs M1, ADR-0011, R-D08
  M4 needs M3, ADR-0010, R-D13, R-711, R-1010

EP-3 updates (stages from system-updates.md §9):
  E0 atomic write ─→ E1 R-704 anti-rollback + R-709 tests
     └─→ E2 R-705 daemon ─→ E3 R-706 journal ─→ E4 R-707 reboot (⚙️) ─→ E5 R-708 pane
                                                        └─→ E8 R-710b A/B slots (⚙️)
  E6 R-711 keyring and E7 R-710a deltas are PARALLEL — neither needs R-707
  R-609 partitioning ───────────────────────────────────→ E8 R-710b
  R-816 process supervisor ─→ `service` package class (ADR-0009 D6); until it exists,
                              everything outside class `app` goes the system-restart route

  M5={E0,E1}  M6={E2,E3} needs M5  M7={E4,E5} needs M6 + ⚙️
  M8={E6,E7,E8} needs M7 AND M2 and M4 through R-609
```

---

### 6.6 First-boot credentials: password quality and PIN — `R-602a`…`R-602f`

Premise, owner's words (2026-09-02): passwords and PINs must never be stored in the clear.
State today: they are not stored in the clear — but they are hashed on **two different paths with
two different strengths** (#27, measured 2026-09-02). Image-build time (`installer`, `rust-argon2
3.0.0`): argon2id, m=19456 KiB, t=2. Runtime — `passwd`, the forced first-boot enrolment, the
`orblogin` greeter — all go through `redox_users 0.4.6` → `rust-argon2 0.8.3`, whose
`Config::default()` is **argon2i, m=4096, t=3** (`lib.rs:271`, `config.rs:97-102`). A third hashing implementation also ships: `relibc`'s `crypt(3)`
(`src/header/crypt/argon2.rs`, RustCrypto `argon2 0.5.3` via `password-hash`) for C callers —
its parameters were not measured and are **[UNVERIFIED]**; `R-602g` must cover it or say why not.
What exists as "judgement" is one literal: `orblogin/main.rs:164-179` refuses `""` and `"password"` (*"weak password"*), and `login.rs:195-243` forces a change for the same two — one blocklist entry, in two places, with no shared code. Beyond that, nothing:
no length floor, no strength estimate, no blocklist, no PIN concept. Measured 2026-09-02:
`grep -rn "strength|weak|entropy|zxcvbn|min_len|pin"` over the userutils and installer sources
returns only comments about getty.

**The number that shapes this whole section.** At the image's argon2id parameters one hash costs
**14–15 ms** on one core of the build container (two runs: 15.3 and 14.06 ms; the runtime argon2i
path measured 4.03 ms). Exhausting a 4-digit PIN space offline therefore
takes **153 s**; 6 digits, **4.2 h**; the 10 000 most common passwords, **153 s** — on one core,
so divide by the cores an attacker has. A PIN is not a password with fewer characters; it is a
credential that only survives if the number of guesses is capped somewhere the attacker cannot
copy. That means: **online only** (screen unlock, greeter), with a try counter and back-off in the
OS, and **never** as the disk-encryption secret or as the sole credential on an unencrypted disk.

| id | item | today | to build | size |
|---|---|---|---|---|
| `R-602g` | **One hashing strength on every path** *(decided 2026-09-03: fork `redox_users` as the type-C repo `eos-users` and **release it ourselves** (`v0.4.6-eos.1`), no waiting for upstream; repository created 2026-09-03 — Q2)* — make every runtime `set_passwd` produce argon2id at the image parameters; negative control: a runtime-set hash must start with `$argon2id$` and carry `m=19456`, **and** an image-time hash must still verify (`rust-argon2 0.8.3` parses `Argon2id` on verify, `variant.rs:63`, so old `/etc/shadow` rows survive) | runtime is argon2i m=4096 (#27), **4.0 ms per guess against 14** — and a **version bump does not fix it**: `redox_users 0.5.2` still depends on `rust-argon2 = "0.8"` and still calls `Config::default()` | one of: (a) fork `redox_users` as a 31st type-C repo with `[patch.crates-io]` in `eos-userutils` and `eos-orbutils` (CLAUDE.md §12 cost: two hosts, `pins --strict`); (b) an upstream MR to `redox_users` and a pin on the released version; (c) hash in the forks and bypass `set_passwd` — refused, three copies. Owner picks (§3.0 Q3). §5.6 area → risk analysis + rollback | M |
| `R-602a` | **Strength estimate + time-to-crack shown while typing** *(✅ **wired into `passwd` 2026-09-03** — pin `e839cfa`, proven end to end on aarch64: `install-smoke: PASS` with a 17-character password, and the **negative control** `EOS_SMOKE_PASSWORD=eos` → `install-smoke: FAIL — passwd refused this password (credential policy)` in 90 s. The floor applies where a secret is **chosen**, not where it is presented: `login` is deliberately untouched, because a length floor there locks out every account made before the floor existed. The library exists: `eos-userutils` `src/credpolicy/`, a `lib` target, **123** unit + 6 doc tests green. **Still not wired into the other four callers** — wiring changes what `passwd` accepts and is its own change with its own boot-smoke)* *(decided 2026-09-03: the policy library lives as a `lib` target in the `eos-userutils` fork — Q3)* (TUI `passwd`/first boot, `orblogin` greeter) | nothing; `read_passwd` returns the string, nobody scores it | a scoring library in the userutils fork (zxcvbn-style: dictionary, sequences, keyboard walks, repeats — not a regex checklist) and a time estimate **computed from the measured 15.3 ms/hash × cores**, so the number shown is this system's number, not a generic one | M |
| `R-602b` | **Blocklist of common passwords** *(floor **12** characters, PIN **6** digits, blocklist shipped with the library — Q4. The harness password `eos` (3 characters) must change in the same merge request that wires the floor, or `R-601c` goes red)* *(decided 2026-09-03: length floor **12** characters, PIN **6** digits; blocklist shipped with the library; the harness password `eos` changes in the same MR — Q4)* (`123456`, `qwerty`, `password`, keyboard rows, the hostname, the username) | nothing | a compressed list in the image under `/usr/share/eos/weak-passwords`, consulted by `passwd`, the installer and the greeter through **one** library so the three cannot disagree; refusal is fail-closed with the reason named | S |
| `R-602c` | **Inline guidance: what a good password looks like and why** *(decided 2026-09-03: same library, i18n keys not prose — Q3)* | nothing | one short text, one place (the shared library), rendered by TUI and GUI; says *length beats complexity*, *a phrase beats a word*, *never reuse*, and states the measured cost so the advice is arguable | S |
| `R-602d` | **PIN as an unlock factor** *(`TryCounter` implemented as pure logic — load, increment, reset, lock out after N with a growing delay; the caller sleeps, the library never does. Per-account file, root may delete it — Q5. PIN is **screen unlock only** — Q1)* *(decided 2026-09-03: PIN is **screen unlock only** — never `sudo`, `passwd` or FDE; the try counter is a per-account file that root may delete — Q1, Q5)* | no concept; no try counter in `login.rs:173-259` or `orblogin/main.rs:185-251`; `redox_users` sleeps a fixed **3 s** per failed verify (`lib.rs:518,526` `auth_delay`), per process — parallel sessions walk around it; the only cap anywhere is `sudo.rs:22` `MAX_ATTEMPTS = 3`, in-process, forgotten on the next invocation. Neither is a lockout | `redox_users`-compatible hash of the PIN (same argon2id), a **separate** credential slot so the password is never replaced, a per-account **try counter with exponential back-off** enforced by the login/greeter path, and a hard rule in the installer: a PIN cannot be set on an account whose disk is not encrypted with a real password | M |
| `R-602e` | **Negative controls for all of the above** *(decided 2026-09-03: agreed — Q4)* | the harness itself sets `PASSWORD = "eos"` (`install-smoke-drive.py:27`) — **three characters** — so any length floor turns `R-601`/`R-601c` red until the harness password changes **in the same MR** (`ci-install-smoke.sh` FDE path too) | mutation tests: a blocklisted password must be refused, a 3-character password must be refused, a PIN attempt counter must lock, the greeter must not accept a PIN over the network; each seen red once | S |
| `R-602f` | ✅ **done 2026-09-04 — one policy, both doors.** *(decided 2026-09-03: one library, five callers — Q3. **The gap was measured and turned out narrower than five:** only `passwd` and `orblogin` **set** a secret; `login.rs`, the sudo daemon and `eos-control`'s elevation **verify** one, and a floor applied at verification locks out every account made before it existed. The greeter's entire rule was `is_empty() || == "password"`, so after `R-602a` the same person got a real check at the console and almost none at the graphical door — the path most people take. **The obvious fix did not work:** a git dependency on `userutils` fails to resolve, dragging `redox-rt` (relibc, `redox_syscall ^0.9.2`) against orbutils' 0.9.0 lock. So `credpolicy` — which imports **only `std`** — became its own package `eos-credpolicy`, adding nothing to any caller's graph; `userutils` re-exports it under the old name, so `passwd` is untouched, and `credpolicy-hostcheck` is gone because a real package tests itself. Both `cook userutils` and `cook orbutils` successful; `orblogin` carries the policy strings; `boot-smoke` PASS. **The greeter judges BEFORE the confirmation prompt**, unlike `passwd`, which judges after — the very thing that hid `passwd`'s refusal from the harness for a whole run.)* ⚠️ **The gap is now MEASURED and NARROWER than this row assumed, and one half of it I created today.** Of the five paths, only **two set a secret**; the other three — `login.rs`, the sudo daemon, `eos-control`'s elevation — **verify** one, and a length floor applied at verification locks out every account made before the floor existed. So parity is needed between `passwd` and **`orblogin`**, not across five. And `orblogin` does set passwords: it has a first-boot `LoginMode::SetNew` flow whose whole rule is `password.is_empty() || password == "password"` (`orbutils/src/orblogin/main.rs:164`). Since `R-602a` gave `passwd` the policy, **the same person setting their first password gets a floor at the text console and none at the graphical one.** The obvious fix does not work and the reason is measured: a git dependency from `eos-orbutils` on `eos-userutils` fails to resolve — `userutils` pulls `redox-rt` from relibc, which needs `redox_syscall ^0.9.2`, while `orbutils` is locked to `0.9.0`. `credpolicy` itself depends on **nothing but `std`**, so the fix is to make it its own package — which means turning `eos-userutils` into a workspace, a structural change to the fork that provides `login`, `passwd`, `getty` and `su`, deliberately **not** started at the end of a long session and on top of an unresolved history question about that same repository)* — the same rules in the greeter and in `passwd` | five independent password paths with no shared policy: `passwd.rs`, `login.rs`, `orblogin` (`eos-orbutils`), the sudo daemon behind `/scheme/sudo` (used by `sudo`, `su`), and `eos-control`'s elevation (`src/elevate.rs:27`, password read from stdin in `power.rs`/`netcfg.rs`) | folds into `R-601d`; one library, two front-ends | S |

Dependencies: `R-602g` first — it is the cheapest row and the one that makes the others honest.
`R-602a`–`c` then need the userutils and orbutils forks and a rebuilt image; `R-602d` needs a
decision from the owner (§3.0 questions) and touches `login_schemes.toml` — a §5.6 area, so it
carries a risk analysis and a rollback plan. None of this is blocked on hardware.

---

## 7. Desktop shell and applications

### 7.1 What the shipping session actually is

The shipping desktop is **orbital + eos-orbutils with COSMIC applications as clients**.
`cosmic-comp` never runs: it sits in `recipes/wip/` behind *"TODO: performance issues, no keyboard
input"* (no `libinput` — Redox has no evdev/udev), and the only configuration naming it,
`config/wayland.toml`, is referenced by no target, script or CI job. Calling this "the COSMIC
desktop" was corrected across the documentation set in `R-D12`.

`cosmic-settings` is **unbuildable on the aarch64 host** (`fontconfig → host:gperf` 404, §4.2), so
`Settings → Update` (`R-708`) and `Settings → Drivers` (`R-806`) have nowhere to live except a
native control panel. That is `R-D01`, and it is why `R-D01` is a **foundation**, not a nicety.

### 7.2 Shell register — `R-Dxx`

| id | item | capability | state |
|---|---|---|---|
| `R-D01` | **Native E-OS Settings control panel** (orbital/orbclient, no libcosmic). Built and running (`U-071`, `eos-orbutils` `061dfd3`): an `eos-settings` binary that compiles for aarch64-redox, installs, ships `apps/15_eos-settings` plus an icon and launches against the live orbital, PID-verified. **Render-verified end to end** in QEMU: sidebar, **9 panels**, real System data, footer (`assets/screenshots/eos-settings-panel.png`). **Status disambiguated, because three places disagreed:** ✅ meant *present in the image*, 🟡 means *complete*. The panels exist; the panes that matter for the trust chain (`R-708`, `R-806`) have **no function** — corrected 2026-09-04: panel index 2 "Aktualizacje" *does* ship as a placeholder (`launcher/src/settings.rs:41-51,127-135`, head `5931fc1`: a note row *"w budowie (R-7xx)"* plus one `Źródło` row per `/etc/pkg.d` entry; pulled into every desktop image by `recipes/gui/orbutils/recipe.toml:16-17` and `config/desktop-minimal.toml:15`), so nobody mints "add an Update panel" a second time. Neither `R-D02`/`R-D03` live state exists. **One id, two binaries — open under decision #19:** this row and §16.1 say `eos-settings` (orbclient); §21 row 2 says `eos-control` (Slint on `eos-ui`, owns the `/scheme/sudo` shims `eos-power`/`eos-netcfg`, `R-D11`), and `eos-control` now ships in both arch configs (`config/aarch64/eos.toml:22`, `config/x86_64/eos.toml:24`), so §16.1's aarch64-build rationale no longer picks a winner. **🟡, in the sense of complete** `[P0·XL·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-D02` | **Functional system tray.** Icons and click-to-Settings done (`U-101`, `60c262d`): the `tray-{net,vol,set}` icons had never actually shipped — an invisible tray — so E-OS now ships three crimson glyphs and a click anywhere on the tray opens Settings, render-verified. **Remaining:** live state — the network indicator from netstack, a volume popup via `audiod`, which is **blocked by the absence of audio on the QEMU loop** (see `R-D07`) `[P1·M·🖥️]` · needs `R-D01` | **WORKS TODAY** | 🟡 |
| `R-D03` | **Notifications daemon and UI.** Minimal daemon done (`U-102`, `8ad7cd8`): `eos-notifyd` shows a crimson top-right toast for a `title\nbody` written to `/tmp/eos-notify`; render-verified. Enough to unblock `R-705`'s "updates available". **Remaining:** a real `notify:` scheme/socket transport instead of a polled file, a queue so one toast does not block the next, and richer UI (icons, actions) `[P1·M·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-D04` | **Screenshot utility** (`U-100`, `eos-orbital` `38226c7`). A standalone tool cannot capture the screen — orbital is the DRM master and the composited image lives only in its CPU shadow buffer — so the capture is **in the compositor**: Super-P writes `/home/user/screenshot-N.bmp` (uncompressed 32-bit BMP, no codec dependency, per-shot counter). Render-verified end to end: Super-P produced a valid 800×600 BMP of 1,920,054 B whose content is the real desktop `[P2·S·🖥️]` | **WORKS TODAY** | ✅ |
| `R-D05` | **Launcher type-to-search plus a local-time clock.** Clock (`U-098`, `94dcc91`): the bar reads local `YYYY-MM-DD HH:MM UTC±H` from `/etc/tz-offset` (ships 7200/UTC+2), render-verified `12:58 UTC+2` at host-UTC 10:58 — and this is exactly why `R-603d` needs a real timezone database rather than a baked constant. Search (`U-099`, `7b1268b`): the Start menu filters every app by name as you type, fed from orbital `TextInput` events, in a fixed-height window that never clips `[P2·S·🖥️]` | **WORKS TODAY** | ✅ |
| `R-D06` | **NetSurf builds from source as a PIE and renders.** *Downgraded 2026-09-02 (#28): the staged and shipped `netsurf-fb` on both architectures is the upstream `ET_EXEC` prebuilt again — the recipe builds PIE, the artefact is not that build; a gate on the artefact is `R-F30`.* The bundled browser died the instant it was clicked (data abort, ESR 0x92000047) because the shipped binary was upstream's non-PIE `ET_EXEC` prebuilt and aarch64-Redox only loads PIEs. Fixed across **three layers** (`U-103`, `U-104`): (1) the from-source build was blocked by a **host-toolchain 404** — `host:gperf` builds via `cookbook_redoxer`, whose `toolchain()` tried to download a host→host relibc toolchain Redox never publishes → `scripts/redoxer-host-stub.sh` pre-creates the stub; (2) a **CC wrapper** in the recipe forces `-fPIC` on every compile and `-pie` on the link, so `netsurf-fb` is a verified `DYN`/pie executable and, the recipe now differing from upstream, `--repo-binary` no longer re-downloads the prebuilt; (3) the PIE then crashed on first render — a **use-after-munmap of the 800×600×4 window buffer**: libnsfb caches `nsfb->ptr` while a `SDL_RESIZABLE` window makes orbclient's event pump `munmap`+remap that buffer on the resize event orbital sends on first map. Dropping `SDL_RESIZABLE` keeps the buffer put. Result, proven by boot and screendump: NetSurf renders `welcome.html` in full. Write-up: [`docs/architecture/netsurf-pie.md`](docs/architecture/netsurf-pie.md). Follow-up `R-D09` | **WORKS TODAY** | 🟡 |
| `R-D07` | **Volume mixer UI plus a verified cosmic-edit boot.** cosmic-edit (2026-07-23): launched from its desktop icon, COSMIC Text Editor renders in full in the E-OS theme and is interactive — typing paints text and the tab flips to the modified state. The one `Image … start failed: Aborted` line came from a stray VT-launch probe, not from cosmic-edit; orbital has no Linux-style VTs. Volume mixer (`U-110`, `eos-control` `a76d0587`): a Sound tab drives `audiod`'s master volume through the `audio:volume` scheme control, with a mute button; when no audio stack is present the tab honestly shows "Audio unavailable" rather than a dead slider. **Hardware-gated regardless:** a *live* volume change needs real HDA — on the QEMU loop `ihdad` binds the controller but times out on the codec RIRB response, so `audiod` exits and `audio:` never appears. That driver bug is tracked in [`docs/reference/known-issues.md`](docs/reference/known-issues.md) and belongs to a drivers-fork job `[P2·M·🖥️]` · needs `R-D01` | **WORKS TODAY** | ✅ |
| `R-D08` | **Launcher `.desktop` membership verified from the image.** On a live boot the launcher is populated from the **image's** `.desktop` entries, not the source tree: the Start menu groups apps under freedesktop Categories and the grid shows installer-gui, cosmic-edit, cosmic-files, cosmic-term, the CLI tools and the E-OS apps. That they appear *is* the proof their `.desktop` files are installed in the image. **Recorded 2026-09-04:** the launcher also carries the only file-association mechanism this desktop has — `accept=*.ext` lines in `/usr/share/ui/apps/*` manifests (`eos-orbutils` `launcher/src/package.rs:104` `accepts`, `:165` parser; `main.rs:902-911` `chooser_main` matches the glob and spawns the package for a file argument; `apps/60_viewer` ships `accept=*.bmp` and friends). There is no MIME database and no default-app registry; `PR-022` relies on it for `.iso`/`.img`/`.vhd`, and whether `cosmic-files`' Redox build reaches it through `open::that` (`open 5.4.3` runs `launcher <path>` on `target_os = "redox"`; `cosmic-files` @ `28546795` depends on `open 5.3.4`) is **[UNVERIFIED]** (§15). **Remaining, and it is the part that matters:** the full **live → greeter → installer-gui → install** flow has never been tested end to end. `R-601` proved the **TUI** path, not this one. Precondition of `R-601d` `[P1·L·🖥️]` | **WORKS TODAY** (membership) | 🟡 |
| `R-D09` | **NetSurf resizable window.** `R-D06` dropped `SDL_RESIZABLE` to dodge the use-after-munmap. Proper resize needs libnsfb's SDL surface to re-fetch `nsfb->ptr` after orbclient remaps on `EVENT_RESIZE` and to post an `SDL_VIDEORESIZE`; the right home is the SDL orbital driver / libnsfb, not the recipe `[P3·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-D10` | **NetSurf browses the network.** A `-object filter-dump` pcap settled it (2026-07-19) and **corrected an earlier wrong call**: virtio-netd binds the NIC, netstack runs, and the pcap shows **DHCP** (request→reply), **ARP**, **ICMP**, **DNS** (`A? example.com` → `104.20.23.154` in 23 ms), a full **TCP** handshake to an external host, **HTTP** `200 OK`, and a live **TLS** exchange on :443 — all bidirectional. NetSurf's *own* fetch is in the pcap, and it renders the live Example Domain page. *The earlier "packets don't flow out" diagnosis was a false negative:* the raw-IP probe used `http://9.9.9.9/`, and **9.9.9.9:80 is closed even from the host**, so the SYN correctly got no reply | **WORKS TODAY** | ✅ |
| `R-D11` | **Privileged power actions from the GUI** (`U-109`). `sys:kstop` is root-only and `eos-control` runs as the desktop user, whose password is **not** empty since first boot sets it — verified: a shell login as `user` with an empty password returns `Login incorrect`. Fixed with a dedicated **`eos-power`** shim that elevates the way `sudo` does internally — open `/scheme/sudo`, write the password, elevate the process fd (`call_wo` + `CallFlags::FD`), `setns`, then write `sys:kstop`. **The GUI never runs as root**; it spawns `eos-power` and pipes the password to its stdin. Verified end to end: arming *Shut down*, typing the password and confirming **powered the VM off — QEMU exited** | **WORKS TODAY** | ✅ |
| `R-D12` | **Stop calling the session "the COSMIC desktop"** (`U-127`). Corrected across README (tagline, badge, screenshot alt and caption, feature table, highlights, architecture diagram, spec table, quick start, components table), `EOS_BUILD_STATE.md`, seven documents, `config/x86_64/eos.toml`, `NOTICE`, `assets/eos-banner.svg`, the GitHub issue template and the roadmap. `config/wayland.toml` is marked UNUSED/EXPERIMENTAL in place and `cosmic-comp`'s absence is a recorded entry in known-issues. Occurrences that were **correct** — the COSMIC applications, `cosmic-theme`, upstream-Redox history, the vendored `docs/reference/upstream-redox-readme.md` — were deliberately left alone `[P1·S·🖥️]` | — | ✅ |
| `R-D13` | **i18n string catalogue plus a key-parity gate (pl/en).** **No i18n infrastructure exists anywhere in the shell** — `eos-control` has its strings hard-coded, and an earlier claim that an i18n gate existed was fabricated (`U-126`). Filed in the `R-Dxx` family, not `R-6xx`, because the gap is the whole shell, not just the installer. Precondition of M4 `[P2·M·🖥️]` | **NEW SUBSYSTEM** | 🔴 |
| `R-D15` | **Context-menu component with a user-selected style — Windows-style list, Linux-style list, or radial ("circle") — in `eos-ui`** *(owner requirement F, 2026-09-04)*. **Absence measured, not assumed:** `grep -rn -E 'PopupWindow|ContextMenuArea|MenuBar|show_popup' --include=*.slint --include=*.rs` over all eleven product clones → **0 hits**; `grep -n -i -E 'context.?menu|right.?click|radial' ROADMAP.md` → **0** before this row. The **input** primitive exists — `eos-ui/src/orbital.rs:154` already maps orbclient `btn.right` to `PointerEventButton::Right` — the **menu** primitive does not. **Why this is a component and not a style switch:** Slint 1.17.1 resolves the widget style once at compile time (`i-slint-compiler-1.17.1/typeloader.rs:937`; every product pins `with_style("fluent-dark")` in its `build.rs`), its menus exist only as list implementations (`widgets/{cosmic,cupertino,fluent,material,qt}/menu.slint`, `common/menus.slint` — no radial anywhere; `cargo search` for radial/pie/circular menu finds only a GTK4 widget and a ratatui crate), and `slint-build` has no `no_native_menu` setter (`with_include_paths` … `with_sdf_fonts` only), so the builtin `ContextMenuArea` cannot be switched per user at all. **The component:** one `PopupWindow` that owns its own anchor (Slint refuses `popup.x/y` bound from the enclosing component), a list body (flat/square vs rounded/padded by property) and a radial body of `Path` sectors with angle→sector hit-testing, opened on `PointerEventButton.right` or on `Key.Menu`; `menu-style` set at runtime by a new `eos_ui::prefs` module reading `~/.config/eos/ui.toml` (`dirs` 6 → `redox_users`, pure Rust) — **absent file = default style decided in code**, so nothing has to ship in `/home/user`; if a visible default file is wanted it goes to `/etc/skel/.config/eos/ui.toml` (copied into every account the wizard creates, `eos-installer/src/installer.rs:325-327`) **and** to the live user's home, never `/home/user` alone (`config/x86_64/eos.toml` `[[files]]` reach only the live medium). **Probed 2026-09-04** in a throwaway crate with `eos-ui`'s exact Slint features: `cargo check` host → exit 0; `cargo check --target x86_64-unknown-redox` → **Finished in 2 m 33 s, exit 0**; `cargo tree --edges normal --target x86_64-unknown-redox` → no `cc`, no winit/muda/accesskit in the Redox graph. *(Probe sits at `xbuild-probe/probe-F-context-menu` on the external disk; re-home under `/Volumes/EOS-Podman/xbuild/` and `cargo clean` before it is cited as evidence — du 19 GiB, content 2.81 GiB.)* **Keyboard path** (the only assistive path on Redox until `V2-STD07`, and it must be said so or the radial variant worsens `V2-STD06`): the FocusScope handles Escape/arrows/Return/digits and compiled for both targets; keyboard-**open** is one match arm in `eos-ui` `key_text` — `K_APP => Key::Menu` (orbclient 0.3.55 `event.rs:295`) — Shift+F10 is a follow-up, because neither modifiers nor F-keys are mapped today (`orbital.rs:59-84`); close-policy must be close-on-click-outside for core's Escape path (`i-slint-core window.rs:1143-1165`), otherwise the FocusScope closes it itself. **Honest asymmetry, in the `PR-020` shape:** *Redox* — `eos-ui`'s `Platform` keeps `supports_native_menu_bar()=false` / `show_native_popup_menu()=false`, so this component is the **only** menu and the switch is trivially honest; *Linux* — winit x11/wayland has no `muda` cfg, Slint-drawn, all three styles; *Windows* — `muda` is forced on (`PR-008`) but `show_native_popup_menu` is reached **only** through the builtin `ContextMenuArea` lowering (`passes/lower_menus.rs` → `Builtin.show_popup_menu`), a custom `PopupWindow` never calls it, so all three styles render on Windows too. What stays true on every target: the style applies to **E-OS windows and the E-OS shell only** (§13, §14.5). AccessKit on Windows/Linux is one winit feature (`accessibility`, off in every product today) — `cargo tree -e normal -F i-slint-backend-winit/accessibility` before promising it. **Not measured, and the first thing to prove in QEMU:** `eos-ui` hands back one `MinimalSoftwareWindow` for every adapter (`orbital.rs:43-48`), so every popup is a `ChildWindow` **clipped to the parent** (`i-slint-core window.rs:1834-1841`); upstream's `tests/popups.rs` exercises exactly this shape, but no E-OS product has ever painted a popup over orbital with `ReusedBuffer` — a radial near a window corner is cut off unless the component flips its anchor, and a top-level popup needs `WindowAdapterInternal::create_popup` with a second orbclient window (a second, container-only measurement). Licences: `dirs`/`dirs-sys`/`xdg`/`toml` MIT or Apache-2.0; `option-ext` 0.2.0 is **MPL-2.0** → NOTICE and `deny.toml` allowlist `[P2·M·🖥️]` · needs `R-D13` (every label through the catalogue) · feeds `PR-007`, `R-D17` | **BUILDABLE** | 🔴 |
| `R-D16` | **Removable-media and image mount manager.** Nothing mounts anything on the desktop today: §17.2.1 names "removable-media automount (`usbscsid` exists; nothing mounts a stick)" with no register row, and `grep -rn -i -E "scheme/disk|redoxfs |mount\(|unmount"` over `eos-orbutils`, `eos-control` and `eos-drive` finds no mount code — only `eos-installer` mounts (`installer.rs:406` `redoxfs::mount`, `:435` `unmount_path`), and `eos-control`'s Storage tab reads root `statvfs` (`sys.rs:332-345`). Redox has no mount table, no udev, no polkit, and `init` supervises nothing after start (`R-816`), so this row **is** the mount table and owns the lifecycle of the mounter processes it spawns. Pieces: a mounted-media table (sticks over `usbscsid`, images over `R-818`, a RedoxFS or `R-819` scheme per partition) in the Settings → Storage pane (`R-D01`); an `eos-mount` shim in the `eos-power`/`eos-netcfg` pattern (`R-D11`; `eos-control/src/elevate.rs:1-20`: `/scheme/sudo`, password on stdin, **the GUI never root**) for attach/mount/unmount/detach, because `disk:` schemes are root-only (§7.3); Eject = unmount + stop the mounter for a stick, START STOP UNIT on `R-815`'s channel for an optical drive (absent today); a tray indicator (`R-D02` "remaining: live state") and an `eos-notifyd` toast (`R-D03`) — **polled**, because there is no hot-plug bus (§7.3; `V2-S05` is a kernel change); a per-user policy that **re-attaches the last images at session start — after login, inside the user session, through the shim, prompting once** — and *not* an `init` service: `init` runs as root before any login, and a root oneshot parsing a user's image list is exactly what the shim pattern exists to avoid (`25_raid1d.service` assembles system-owned devices; the analogy does not transfer). Tells the file manager the `/scheme/<name>/` path — there is no `/media`. Absorbs the §17.2.1 gap and gives `EC-7` (offline update from a stick) its mounted, verified medium. `PR-022` is its first consumer `[P2·M·🖥️]` · needs `R-D01`; `R-818`/`R-819` for images | **NEW SUBSYSTEM** | 🔴 |
| `R-D17` | **Right-click surfaces in the shell, and the Settings → Wygląd chooser.** **Measured:** `grep -rn -E '\.right\b|btn\.right|MouseButton|right_click|context'` over `eos-orbutils/launcher/src` and `orbutils/src` → **0 hits**; every handler reads `button_event.left` only (`desktop.rs:296`, `main.rs:476/766/942`). Orbital does deliver `EventOption::Button{right}` to the window under the pointer (`eos-ui/orbital.rs:150-171` proves it on app windows) — the handlers are what is missing. **The shell cannot adopt `R-D15` directly:** it is orbclient, not Slint, and `eos-ui` owns exactly one window adapter per process while the launcher is several windows in one process (`main.rs:254-276`, plus the separate `desktop` binary) — a Slint launcher is 💡, blocked on *eos-ui supports one adapter per process*, a substrate that does not exist. So the shell gets an **orbclient twin**: `launcher/src/menu.rs` drawing the list/radial into a Borderless window (template: the Start-menu window, `R-D05`), reading the same `~/.config/eos/ui.toml` with `toml` + `serde` added to `launcher/Cargo.toml` (today: orbclient, orbfont, xdg — **no** toml, **no** serde; they are workspace deps of the `orbutils` crate only, so no new licence). **Surfaces:** desktop icons (`desktop.rs`), the bar, the tray (`R-D02`), Start-menu entries. A menu on the **bare** background belongs to whichever window owns the pixel — there is no compositor-level hook, and whether `eos-orbital` routes the right button to the `background` window is **unmeasured** (no local clone; `recipes/gui/orbital` holds only `recipe.toml`): instrument the fork's button dispatch with `eprintln!`, boot, read the serial log. **The setting:** a tenth panel **Wygląd** in `eos-settings` (`R-D01`; `settings.rs:41-50` has nine, none for appearance) with the three-way chooser and a **live preview drawn by the same `menu.rs`**, so the preview and the shell's real menu are one code path; it writes the TOML. `eos-control` may mirror the chooser later as a Slint pane previewing the `R-D15` component itself — a sub-line, **not** a second Settings owner: the comment at `config/x86_64/eos.toml:933` calling `eos-control` "the settings panel" contradicts §7.1, `R-708` and M7, which put Settings in `R-D01`, and is corrected in the same MR. No file-event bus on Redox: the value is read at process start (re-read on window focus is optional polish). Strings are Polish literals → `R-D13`. Licence: `eos-orbutils` is MIT per `README.md:31` + `LICENSE-MIT`, but `LICENSE-GPL` sits in the fork root with nothing saying what it covers and `orbutils/Cargo.toml:6` names a `LICENSE` file that does not exist — settle both in NOTICE/`deny.toml` before this row claims anything about licensing. On Windows/Linux none of this applies: the host shell's right-click is not ours (§13) `[P2·M·🖥️]` · needs `R-D15`, `R-D01`, `R-D13` | **BUILDABLE** | 🔴 |

### 7.3 `eos-guard` → a security suite — `V2-S`

**What `eos-guard` does today, measured in the binary:** a file-integrity monitor. It hashes
`/usr/bin` and `/etc` with blake3, keeps the baseline in SQLite, scans on demand and classifies
Ok/New/Modified/Removed, warns about setuid, and detects tampering with itself. Slint GUI.
**That is all** — one job, not a suite.

The key finding: **most "recon" and "blue team" tooling is pure user-space**, and E-OS has the
`tcp:`, `udp:`, `icmp:` and `file:` schemes plus `argon2` in the tree. But **three classes are
blocked on a missing primitive**, and that has to be said rather than promised around.

**Realistic now** (schemes verified to exist): port and network scanner (`tcp:` connect) · ping and
traceroute (`icmp:echo`, in `netutils`) · banner grabbing · WHOIS (`tcp:` :43) · DNS lookup and
subdomain enumeration (`udp:` :53) · password strength, generator and hashing (`argon2`) · YARA /
Sigma / log analyser / event-log parser · metadata extractor and hash calculator · malware-hash,
IOC and URL-reputation checkers (`tcp:`+TLS as an API client) · **file-integrity checking, which
already exists — it is `eos-guard`** · file recovery and memory-dump *analysis* from a supplied image.

**Realistic with work** (primitive exists, but root-only or unconfirmed): full traceroute (confirm
`icmp:` delivers Time-Exceeded) · SQLi/XSS/website scanners (an HTTP(S) client has to be written on
`tcp:`+TLS) · SYN/stealth scan (raw `ip:`, root-only since `U-144`) · file recovery on a **live**
disk (`disk:`/`nvme:`, root-only) · memory acquisition from a live process (`proc:` + root) ·
vulnerability/cloud/compliance/Docker-image scanners as remote-API clients · brute-force, rate
limiter, alerting, SIEM and threat-intel dashboards (application logic plus `eos-devd` for inventory).

**Blocked on a missing primitive — not to be promised until it exists:**

| tool | missing primitive |
|---|---|
| **Packet sniffer / pcap** | no promiscuous capture scheme, no BPF/tap |
| **USB activity tracker (live)** | no hot-plug/uevent event bus |
| **Docker security scanner (local)** | Redox has no OCI/container runtime |
| **On-access file scanner** (`PR-004b` on the hosts; `PR-020` on Redox stays on-demand) — 💡, no id | no file-event bus: RedoxFS emits no change events, `event:` is fd-readiness only, and the shipped inotify is a stub (`recipes/libs/libinotify-stub`, linked by `recipes/libs/glib` with `-Dfile_monitor_backend=inotify` — a file monitor that never fires). Whether the bus belongs in the `redoxfs` daemon or in the kernel is **[UNVERIFIED]** until those sources are read; no cost claimed. The same absence blocks any "live" mode for Guard, so one bus would serve both products |

| id | item | where | state |
|---|---|---|---|
| `V2-S01` | `tcp:`/`udp:`/`icmp:` library plus the first CLIs: port scan, DNS, ping, whois, banner | 🖥️ | 🔴 |
| `V2-S02` | file+CPU: hash calculator, metadata extractor, YARA matcher **as `PR-020`'s `lib` crate (one `boreal` matcher, not a second)**, Sigma matcher (a log-rule format, this row's own), log analyser | 🖥️ | 🔴 |
| `V2-S03` | HTTP(S) client → website/SQLi/XSS/certificate checkers, URL and IOC reputation | 🖥️ | 🔴 |
| `V2-S04` | "Personal Cybersecurity" dashboard tying the above together (Slint, like `eos-guard`) | 🖥️ | 🔴 |
| `V2-S05` | the primitives themselves: promiscuous capture and a hot-plug bus → sniffer, USB tracker (a kernel change) | ⚙️ | 🔴 |

> "Ransomware simulator (safe lab)" and "CSRF demo lab" are safe as educational applications and
> need no new primitive.

### 7.4 `eos-notes` → an encrypted notebook — `V2-NT`

**What `eos-notes` does today, measured:** text notes (title + body) in SQLite WAL, autosave, a list
panel, substring filtering, deletion. Slint GUI. **No** Markdown, **no** encryption, no tabs, tags,
links or attachments. The distance to the wish list is large and saying so is part of the plan.

**Several "notebook features" are actually system features already present** — they must be *wired*,
not written, and this changes the shape of the work:

| feature on the list | what the system already provides |
|---|---|
| Content encryption | **RedoxFS AES-XTS** (`R-502`) plus the hybrid signature `R-503` — the engine exists |
| Plugin sandboxing / "zero trust" | Redox's **capability + namespace model** — an OS foundation, not an app feature |
| Note integrity verification | **`eos-guard`** (blake3) — to be connected, not written |
| Ed25519 signing | `tools/eos-repo-sign` (ed25519 + ML-DSA-65) — the same crypto |
| Memory zeroization | the `zeroize` crate; practice across the tree |
| Process isolation, IPC-only | the microkernel architecture — already how it works |

All ten items are **🔴 planned**. The predecessor's table had *no status column at all*, so ten
identifiers existed with no recorded state; on the evidence in §7.4's first paragraph — no Markdown,
no encryption, no tags, no links, no attachments — none of them is started.

| id | item | why here | state |
|---|---|---|---|
| `V2-NT01` | **Markdown**: editing, live preview, source mode, code blocks, tables, lists, checklists | the core; without it everything else hangs in a vacuum | 🔴 |
| `V2-NT02` | **Per-note encryption** (AES-256-GCM / XChaCha20, key from Argon2id) | the most important property; the crypto is in the tree, only the integration is missing | 🔴 |
| `V2-NT03` | **Organisation**: folders, nested tags, properties, templates, daily notes | turns an editor into a knowledge system | 🔴 |
| `V2-NT04` | **`[[…]]` links, backlinks and a graph view** | the "second brain" model | 🔴 |
| `V2-NT05` | **Full-text search**, quick switcher, command palette | navigation that scales to thousands of notes | 🔴 |
| `V2-NT06` | **Bases** — table/card/list views over metadata | notes as a database | 🔴 |
| `V2-NT07` | **Canvas** — an infinite surface | visual brainstorming | 🔴 |
| `V2-NT08` | **Advanced security**: recovery seed (BIP39), auto-lock, decoy vault, steganography, HMAC, audit log | a layer above `V2-NT02`; **anti-screenshot and anti-screen-recording are impossible from the application** until Orbital exposes an API, and they are listed here as OS-dependent rather than promised | 🔴 |
| `V2-NT09` | **Encrypted attachments, export to PDF/HTML/MD, import from Notion/Evernote/CSV** | exchange with the outside world | 🔴 |
| `V2-NT10` | **Plugin system** (Rust SDK, namespace sandbox) plus end-to-end-encrypted sync | extensibility and zero-knowledge synchronisation | 🔴 |

---

### 7.5 Products — in the image, on Windows and Linux, and the four new ones — `PR-*`

Premise, owner's words (2026-09-02 and 2026-09-03): product information for *"Notes, Antivirus,
Browser"*; those products **also downloadable separately for Windows and Linux**; **new products** —
a spreadsheet, a presentation tool, a cloud drive (OneDrive/Mega/Drive-like) and an app store
(Microsoft-Store-like); every product **built into E-OS with an enable/disable switch at install**;
**E-OS is the primary platform** for all of them; new repositories where a product needs one; and the
question *"is the antivirus going to be `eos-guard`?"* answered.

#### 7.5.1 What the image holds today (read-only inventory, config TOML membership)

| product | in the image? | where it comes from | note |
|---|---|---|---|
| **Notes** — `eos-notes` | **yes** | type A, pinned in its recipe; `config/*/eos.toml` `[packages.eos-notes]` | a product |
| **Control panel** — `eos-control` | **yes** | type A, pinned | Overview / processes / network pane (`R-902`) / Security tab |
| **Browser** — NetSurf 3.11 (`netsurf-fb`) | **yes** | upstream recipe via `config/desktop.toml:21` | not an E-OS fork; the staged binary is the **upstream prebuilt** (`EXEC` at `0x400000`, no PIE — #28, `R-F30`) |
| **Terminal** — `cosmic-term` | **yes** | `desktop.toml:15` | — |
| **Editor / files** — `cosmic-edit`, `cosmic-files` | **yes** | `desktop.toml` | `cosmic-edit` is the recipe behind #26 |
| **Integrity monitor** — `eos-guard` | **yes**, as an app since 2026-09-03 (`PR-002` ✅) | type A, `recipes/gui/eos-guard` pinned `3bcde7d9` (since `e-os!133`, 2026-09-05; this row's first value `a984e4c3` never reached `main` — `!119` had already moved the pin to `f6397272` before the row landed); `[packages.eos-guard]` in `config/x86_64/eos.toml:46` and `config/aarch64/eos.toml:44`; `config/optional-apps.toml` `[eos-guard]` ("Nie jest to antywirus.") | blake3 baseline + permission audit; one engine shared with `eos-control`'s Security tab (`PR-004`); stays a separate product (Q16) |
| **System monitor** — `eos-sysmon` | **no**, as an app | type A, not an image package | same route: a tab in `eos-control` |
| **`eos-ui`** | n/a | type A library (`role = lib`), no recipe | the Slint-on-Orbital backend every product above uses |
| **Antivirus** | **no** — scheduled (Q16, Q17) | `PR-020` (on-demand, in the image + hosts) and `PR-004b` (on-access on the hosts); nothing in the tree, a host probe only; `recipes/wip/security/*` are not its source (§13) | §7.5.3 |

#### 7.5.2 Cross-platform: what was measured on 2026-09-03, not assumed

- **The three Slint products type-check on a non-Redox host.** Clean clones of `eos-ui`, `eos-notes`
  and `eos-control` at their `main` heads: `cargo check` on `aarch64-apple-darwin` — **rc 0, 0
  errors** each (30 s, 32 s, 23 s). `eos-ui` selects the Orbital platform only under
  `cfg(target_os = "redox")` (`lib.rs:101-110`) and documents the non-Redox branch as *"the app runs
  on Slint's own backend (useful for host-side development builds)"*; `eos-control` already carries a
  `cfg(not(target_os = "redox"))` dependency block (`libc`). The code was written to build elsewhere.
- **They do not yet *open a window* elsewhere.** All three pin `slint` with `default-features =
  false` and only `renderer-software` (`eos-notes/Cargo.toml:17`, `eos-control/Cargo.toml:35`,
  `eos-ui/Cargo.toml`): no `backend-winit`, so on macOS/Linux/Windows `slint::run` has no platform to
  start. That is a Cargo feature per crate plus one `BackendSelector` call, not a port — **S** — but
  it is unmeasured until run, so it is a row, not a claim. **[UNVERIFIED]:** whether Slint's winit
  backend still compiles on Windows and Linux at the pinned `slint 1.17`.
- **Both products pin `eos-ui` from the GitHub mirror**, not from the GitLab source of truth:
  `eos-notes/Cargo.toml:18` and `eos-control/Cargo.toml:36` say
  `git = "https://github.com/Gh0s777tt/eos-ui.git"`. `ADR-0001` and `S-17` (recipes repointed) did
  not reach the products' own manifests. Recorded as `PR-006`.
- **Zero tests.** `#[test]` count: `eos-ui` 0 (648 lines), `eos-notes` 0 (762), `eos-control` 0
  (4 976). Coverage automation for products (§11.3, `TQ-*`) therefore starts from a measured zero, and
  the first floor can only be "does not fall below what the first test suite reaches".
- **Not every product travels equally.** `eos-notes` has no platform-specific code at all — the best
  candidate. `eos-control` reads `/proc` on a host (`src/sys.rs:4-9`, 23 `cfg(target_os)` lines) and
  its capability inspector (`sys:iostat`) has no meaning off Redox: a **Linux** build is a developer
  aid, a **Windows** build would be a rewrite of `sys.rs` for a feature that cannot exist there — so it
  is not a product row. `eos-orbutils` is Orbital chrome and stays Redox-only by design.
- **A precedent exists.** `redox_installer_gui` already compiles for Linux *and* Redox through a
  `sys/` shim (`gui/src/sys.rs`: `cfg(linux)` / `cfg(redox)` / `compile_error!` elsewhere) — the
  pattern every product that must run off-Redox should copy.
- **One stale comment hides the answer.** `eos-notes/.gitlab-ci.yml:20-23` skips the host GUI build
  citing "Slint 1.1.1 + winit 0.28 … no longer compiles"; the crate pins Slint 1.17. The belief that
  the host build is broken is two major versions old and unmeasured (`PR-007` measures it).

#### 7.5.3 The antivirus answer

**Yes and no, and the distinction is the product.** `eos-guard` *is* the security product: a
file-integrity monitor (blake3 baseline in SQLite, Ok/New/Modified/Removed classification, setuid
warnings, self-tamper detection — §7.3) whose engine already lives in `eos-control`'s Security tab.
What it is **not** is an antivirus in the Windows sense: it has no on-access scan hook, no signature
engine, no quarantine, no update channel for signatures. On E-OS the honest equivalent of "antivirus"
is the package-bytes gate that exists (`V2-MS13`: blake3 enforced from the signed index) plus the
integrity baseline; the missing primitive for on-access scanning is a file-event bus, which Redox
does not have (§7.3 table: *no hot-plug/uevent event bus*). **Recommendation, as given 2026-09-03:** ship the product as
**E-OS Guard**, describe it as *integrity and permission monitoring*, and never print the word
"antivirus" on a page until `PR-004b` below exists.

**The owner answered this again on 2026-09-04 (Q16), and the second answer governs.** Guard stays
separate — that half of the recommendation was accepted — and **a separate antivirus is to be
built** as its own product, `PR-020`. So the paragraph above keeps its analysis and loses its
conclusion: the word will be printed, because the thing will exist. What does *not* change is the
platform asymmetry, which is a fact about the systems rather than a preference:

| target | on-demand scan | on-access scan |
|---|---|---|
| Redox (E-OS) | **measured 2026-09-04, both arches, in the cookbook**: `aho-corasick` + `memchr` + `blake3` + `walkdir` + `regex` — aarch64 **7.73 s / 8.01 s**, x86_64 **31.51 s**; **plus the engine, measured on the host the same day**: `boreal 1.2` graph of 36 crates checks for `x86_64-unknown-redox` (`PR-020`); the Redox **link and run** are on the not-measured list until the container is free | **no** — needs a file-event bus (§7.3 table row): RedoxFS emits no change events, `event:` is fd-readiness only, the shipped inotify is a stub (`recipes/libs/libinotify-stub`) |
| Linux | buildable today (`PR-008`; `boreal` ELF PIE 4 317 712 B measured) | `fanotify`, user-space — but a `FAN_CLASS_CONTENT` listener needs `CAP_SYS_ADMIN`, which `PR-008`'s `.tar.gz` cannot grant; 💡 until a privileged install path exists (`PR-004b`) |
| Windows | buildable today | needs a **signed kernel minifilter** — ⚙️/🔑, an operator and legal step, not a coding one |

**The engine candidate this document named does not survive measurement, and the correction is the
point of this paragraph.** `yara-x` (BSD-3, Rust) was named above as *the* candidate without asking
what it costs. Measured 2026-09-04 on a throwaway crate: `yara-x 1.20.0` resolves to **286
packages**, and `wasmtime 45.0.3` and `cranelift-codegen 0.132.3` are **normal dependencies, not
dev** — it compiles rules to WebAssembly and JITs them. That is a reasonable design on a host and an
impossible one on `*-unknown-redox`. So `yara-x` stays the candidate for the Linux and Windows
builds that `PR-008` now packages, and the Redox scanner needs a matcher small enough to
cross-compile — which is a smaller problem than it sounds, because Redox has no on-access path
anyway. ClamAV bindings remain refused: GPL-2 C in an AGPL tree.

**The counter-check is what makes the two rows above worth reading (§5.9 level 4).** A build that
succeeds proves nothing on its own — a toolchain that had silently fallen back to the host would
have compiled the scanner stack just as happily. So the same command was run on the crate that
*must* fail: `yara-x` on `aarch64-unknown-redox` gives `compile_error!("unsupported platform")`
twice, `cannot find function `sigaltstack` in crate `libc``, `SS_DISABLE`, and **exit 101**. Those
symbols are wasmtime's signal-based trap handling, so the compiler named the same cause the
dependency graph had implied. The instrument refuses for *platform* reasons, which is what licenses
reading its acceptance as a platform result.

**Both Redox arches are now measured, and closing that gap produced a better finding than the
gap did.** The first `x86_64-unknown-redox` attempt **failed**, and the failure was the probe's
fault rather than the platform's: `blake3` tried to assemble `blake3_sse2_x86-64_unix.S` with the
**host** `cc`, because a bare `cargo build --target …` inherits `PATH` and the cookbook's cross
toolchain was not on it. `rustup toolchain link` had supplied a correct `std`, so the build started
and looked entirely credible. With `prefix/x86_64-unknown-redox/gcc-install/bin` on `PATH` and `CC`
/ `AR` / `CC_<target>` / `CARGO_TARGET_<TARGET>_LINKER` set the way the cookbook sets them, the same
stack finishes in **31.51 s** — and `yara-x` still refuses on that arch with the same
`compile_error!("unsupported platform")`.

That false negative was **one export away** from being published as "blake3 does not build for
Redox". It is recorded as trap **P-17** in `CLAUDE.md` §8, because it is the `PR-008` lesson in a new
costume: *measure the command that runs in production, not the equivalent one you typed by hand.*

#### 7.5.4 The register

| id | item | today | to build | size |
|---|---|---|---|---|
| `PR-001` | **Product pages generated from the config**, not written by hand — for every `[packages.*]` entry the image ships, a page with what it is, where its source is, its type (A/B/C) and its pin | three hand-written lists that disagree (README, `docs/reference/packages.md`, `WS-*` product pages) | a generator over `config/*/eos.toml` + `repos.toml`; `WS-008` consumes it | S |
| `PR-002` | **`eos-guard` and `eos-sysmon` either ship or leave the product list** *(decided 2026-09-03: `eos-guard` ships as **E-OS Guard**, `eos-sysmon` stays archived — Q12)* | ✅ **done 2026-09-03**: `[packages.eos-guard]` in both configs; proven in the artefact, not the exit code — a mounted **copy** of each image (P-6) shows `/usr/bin/eos-guard` (aarch64 14 635 056 B, x86_64 15 670 816 B) and the launcher entry `40_eos-guard`; `boot-smoke` PASS on both. `eos-sysmon` stays archived: its whole surface is the `eos-control` Overview tab | — | S |
| `PR-015` | **The four new product repositories exist and build** *(created 2026-09-03, owner decision Q13)* — `eos-sheets`, `eos-slides`, `eos-drive`, `eos-store` on GitLab with GitHub mirrors, generated from one skeleton so they cannot drift apart; each pinned in `recipes/gui/<name>` and registered in `repos.toml`. **Not yet in any image**: they are skeletons, and shipping a window with a status line would be shipping a claim. `[packages.*]` entries land when each has a feature worth launching | ✅ repositories · 🔴 products | S |
| `PR-003` | **"Antivirus" on E-OS** *(decided 2026-09-03 — Q12; **reversed 2026-09-04 — Q16**)* — the owner has asked for a separate antivirus, so the second branch of this decision was taken: the word gets used because the thing gets built. The row stays as the *record of the decision*; the scanner is `PR-020` | no engine, no hook, no row | `PR-020` scheduled; until it ships, no page prints the word | S (decision) |
| `PR-004` | 🟡 **engine half done 2026-09-04, evening (the first version of this row said 2026-09-05, a wrong date corrected the same night) — `eos-guard!6` (`89721810`) + `eos-control!6`.** The engine lives once, in `crates/eos-fsintegrity` (walk, blake3, SQLite/WAL baseline + diff, `parse_roots`, `DEFAULT_SCAN_BUDGET`), a workspace **member** of `eos-guard` on the `eos-credpolicy` precedent: a git dependency finds a package by name among a repository's workspace members, so `eos-control` depends on it at a pinned revision with no third repository, mirror or pin. **The shape changed from the plan below:** the 2026-09-04 design panel (134 agents, its record is outside the tree) scored a separate `eos-fsintegrity` repository 8.0 and this in-repo member 7.83 against `lib` + `bin` on `eos-guard` 7.67 (a `[lib]` consumer drags `slint-build` into the graph: 243 crates vs 23); the repository split is an owner action 🔑 (new type-A repo, mirror, `repos.toml`, `CLAUDE.md` §11) and a path change later, not pre-empted. Two traps measured and closed in `eos-guard!6`: at a workspace root `cargo test` runs the root package only (1 test instead of 26 — CI says `--workspace`), and `packaging/release.sh` read `cargo metadata … packages[0]`, which is the engine. **Not touched, on purpose:** where the baseline lives — each product keeps its `paths.rs` with the same `…/eos-guard/baseline.db`; the shared-baseline question is the owner's. *Original entry:* **E-OS Guard as a standalone product** — `eos-guard` repo back in the image as an app (`PR-002`) *and* its engine kept in `eos-control`'s Security tab from one crate, not two copies | the engine exists twice (guard binary; `eos-control/src/security/`) | **second half done 2026-09-05 — `eos-guard!7` (`3bcde7d9`):** three trust-status lines under Guard's status line, product code in `src/sysstatus.rs` (the engine crate untouched): FDE from `/scheme/sys/env` ("aktywne" only when the bootloader left `REDOXFS_PASSWORD_ADDR`, live is a suffix), RAID-1 from `disk.raid1` in `/scheme` **and** `/tmp/raid1d.state` (both required; a planted file in sticky `/tmp` is "nieznane"), repository from `/etc/pkg/eos-repo-sign.pub.toml` + `/etc/pkg.d/*` + the `repo-state.toml` serial watermark (never says "podpisane": a watermark is pkg-lib's record, not a verification; no "expires" — no index carries it, S-11). Every I/O error other than ENOENT renders "nieznane — <path> (<errno>)". Today's images render *NIEAKTYWNE (obraz live…)* / *nie wykryto macierzy* / *brak skonfigurowanego źródła* — measured on the live and installed images first. **Still open:** the same lines in `eos-control`'s Security tab if decision #19 makes it Settings (lift `src/sysstatus.rs` into a workspace crate, one pin bump); `R-306` (W⊕X/ASLR/overflow-checks) has **no runtime source** — compile-time constants in the kernel (`memory.rs` `KERNEL_WX_USER`, `KERNEL_ASLR`), no `sys:` entry — so it is recorded here and not shown; the repository split if the owner wants it | M |
| `PR-004b` | **On-access half of the antivirus (`PR-020`)** — Linux `fanotify` helper 🐧, Windows signed minifilter ⚙️/🔑; quarantine directory; the rule bundle is `PR-020`'s, not a second one. *(Retitled 2026-09-04 from "Signature engine for Guard": per Q16 the antivirus is its own product, and Guard's repository confirms it never had any of this — `grep -rn 'yara\|quarantin\|antivirus\|malware\|fanotify\|minifilter' eos-guard-work/src` → 0 hits.)* **Engine: `yara-x` is not needed anywhere.** The 2026-09-04 measurement stands as the record of why it was dropped — 286 crates including `wasmtime 45.0.3` and `cranelift-codegen 0.132.3` as *normal* dependencies, `compile_error!("unsupported platform")` twice plus `sigaltstack`/`SS_DISABLE` missing in `libc` on `aarch64-unknown-redox`, exit 101; re-checked in `probe-A-antivirus-yarax`: `cargo tree -i wasmtime` → `wasmtime v45.0.3 └── yara-x v1.20.0` even with `default-features = false` — but `boreal` covers all three targets (`PR-020`), so no host-only engine exists. **Linux, measured on the host:** `nix 0.31.3` (MIT) feature `fanotify = []`; `[target.'cfg(target_os = "linux")'.dependencies] nix = { version = "0.31", features = ["fanotify"] }` with `Fanotify::init(InitFlags::FAN_CLASS_CONTENT, EventFFlags::O_RDONLY)` — `cargo check --target x86_64-unknown-linux-gnu` rc 0, `cargo zigbuild --release` → ELF PIE, stripped; `cargo tree -i libc` → `libc` only via `nix`, and the pair is **absent from the Redox tree**, so the Redox binary is the same on-demand scanner with no on-access module compiled in, not a crippled Linux binary. **Privilege, kernel-documented not host-measured:** `FAN_CLASS_CONTENT`/`FAN_CLASS_PRE_CONTENT` need `CAP_SYS_ADMIN` (`fanotify_init(2)`; the man page could not be opened on this Mac — the EPERM-unprivileged run is on the not-measured list). **Therefore the Linux half depends on a privileged install path `PR-008` does not give:** `PR-008` ships Linux as a `.tar.gz` (AppImage later), and an unprivileged unpack can never start a `FAN_CLASS_CONTENT` listener — a `.deb`/`.rpm` (or a documented root install) that places the helper with its unit/capabilities is a prerequisite line here, with the Slint GUI an unprivileged client over a local socket; **until that packaging exists the Linux half is 💡 (blocked on packaging), not 🔴**. **Windows:** a minifilter in C/C++ against the WDK, signed through the Microsoft hardware programme — ⚙️ (signing HSM/EV certificate) and 🔑 (the operator's legal identity), not Rust, not measurable here. **Redox:** no entry — no file-event bus (§7.3 table, 💡); on-demand only, honestly labelled (§14.5) | nothing | Linux: `nix`/`fanotify` helper + the privileged install path; Windows: the driver and its signature; both: quarantine directory and the on-access client in the `PR-020` GUI | L (Linux) / XL (Windows) |
| `PR-020` | **A separate antivirus product** *(owner decisions Q16 and Q17, 2026-09-04)* — its own repository and its own product page, **not** a mode of Guard, which stays what it is (`PR-004`); **in the image by default** and declinable at install (`PR-005`, `PR-018`); **installable on Linux and Windows** through `PR-008`. Working name `eos-av` until the owner names it (not asked). **Engine, measured 2026-09-04 on the host** (`/Volumes/Project itp/xbuild/probe-A-antivirus`, `CARGO_TARGET_DIR` on that volume — `EOS-Podman` was not mounted): `boreal = { version = "1.2", default-features = false, features = ["hash","object"] }` (MIT OR Apache-2.0, rust-version 1.85; `process` and `memmap` left off — `process` is the only feature pulling `libc`/`windows-sys`/`mach2`) + `walkdir 2` + `blake3 1` + `aho-corasick 1` + `memchr 2` + `regex 1`. `cargo check --target x86_64-unknown-redox` rc 0 (10.8 s cold, 0.96 s incremental); `x86_64-pc-windows-gnu` rc 0; `x86_64-unknown-linux-gnu` rc 0. `cargo tree --edges normal --target x86_64-unknown-redox --prefix none \| sort -u` → **36 crates**, none of `libc`/`windows`/`wasmtime`/`cranelift`/`cc`/`nix`/`mach2`/`memmap`. `cargo deny check licenses` with `eos-store`'s `deny.toml` → **licenses ok on all three targets**. Host run: an EICAR rule compiles and `Scanner::scan_mem` returns **exactly one** match (`assert_eq!(n, 1)`; note for the implementer: in boreal 1.2 `scan_mem` returns `Result<ScanResult, ScanError>`). Real links through cargo-zigbuild: Windows PE32+ (1 m 50 s), Linux ELF PIE 4 317 712 B (1 m 16 s). **Consequence for `PR-004b`: `yara-x` is not needed anywhere** — one engine, three targets. **Two corrections the crate manifest must carry:** (1) `default-features = false` on `blake3` does **not** drop the C/asm SIMD paths — the build-script output on both `x86_64-unknown-redox` and `x86_64-pc-windows-gnu` still emitted `blake3_{sse2,sse41,avx2,avx512}_ffi` and linked `blake3_sse2_sse41_avx2_assembly` + `blake3_avx512_assembly`, assembled by the host `cc` on the Redox check (ranlib warned `not a mach-o file`; `check` never links) and by cargo-zigbuild's `zig cc` wrapper on Windows; only `features = ["pure"]` (or `prefer_intrinsics`) makes the binary assembler-free — the same fix `eos-guard`'s `Cargo.toml` comment needs; (2) the scanner is written **without `std::os::unix`** so the `package-windows` job is a real gate on every MR (the trap `PR-008` documents for Guard). **Sub-item added 2026-09-04 by the archiver row `PR-021`: a library API on the scanner** — `scan(&mut impl Read) -> Verdict`, called by `eos-archive` on every entry stream before it writes a byte, so "virus scan inside archives before extraction" is this engine and not a second one; extraction is an explicit moment the archiver owns, so Redox gets there the protection the hosts get from on-access. **On-access is not this row:** `PR-004b`. **Redox threat model stays honest:** on-demand plus scheduled scans beside Guard's blake3 baseline, no "real-time protection" label (§14.5) | nothing in any repository; a host probe only (above); `recipes/wip/security/{clamav,yara-x,binsec}` are **not** its source (§13) | **repository** from the `PR-015` skeleton (`eos-ui`, AGPL-3.0-or-later, `deny.toml`, light-tier `.gitlab-ci.yml` with `package-windows` and `package-linux` as real jobs, a `#[test]` in the first commit), `lib` + `bin` like `PR-004` so `V2-S02`'s YARA matcher is the same crate, registered in `repos.toml` and CLAUDE.md §11 (check 7); **in the image:** `recipes/gui/eos-av` (custom template, `cookbook_cargo`) staging `/usr/bin/eos-av`, `/usr/share/ui/apps/40_eos-av` and `/usr/share/icons/apps/eos-av.png` into the real directory (`PR-017`), `[packages.eos-av]` in **both** `eos.toml`, a `config/optional-apps.toml` entry with that exact file list (check 24), a headless `--selftest` that scans EICAR and prints `EOS-AV-SELFTEST-OK` on exactly one match (mirrors `GUARD-SELFTEST-OK`, read by boot-smoke like `EOS-CONTROL-SELFTEST-OK`), `pins --strict` green; **hosts:** `PR-008`'s `packaging/release.sh --selftest`, signed checksums, `WS-005`; **rule format and bundle:** YARA syntax evaluated by `boreal`; on Redox a data-only pkgar `recipes/data/eos-av-rules` in the `ca-certificates` shape, listed in both `eos.toml`, installed by `pkg` over the pinned-key channel today and refreshed by `R-705`'s daemon later (**no rule auto-update on Redox before `R-705`**); on Linux/Windows a bundle archive published by `scripts/make-release.sh` (SHA256SUMS + minisign — `eos-guard`'s `packaging/release.sh:181-185` writes only a `.sha256` and must not be the publisher), verified in-app with `minisign-verify 0.2.5` (MIT, zero dependencies) against an embedded copy of `keys/eos-release.pub`; the hybrid ed25519+ML-DSA option is a **later step conditioned on** moving `verify()` out of `tools/eos-repo-sign/src/main.rs:161` into `lib.rs` (today `lib.rs` exports only `hex_encode`/`hex_decode`/`parse_kv`/`get`/`hybrid_ok`, and the crate is a standalone build-host tool) and cross-checking it on `x86_64-pc-windows-gnu` — **[UNVERIFIED]**; the shipped bundle carries E-OS-written rules only (§13 on third-party sets); scan-result toast via `R-D03`; **not measured, needs the container or other machines:** `cargo build --release --target x86_64-unknown-redox` with the cookbook's CC, the aarch64 build (target not installed on the host; blake3 NEON path untested), `redoxer exec` of the probe (proves `scan_mem` and `walkdir` under relibc, not just compile), the cooked recipe and `EOS-AV-SELFTEST-OK` in a boot-smoke serial log, `boreal/memmap` on relibc | L |
| `PR-021` | **Archiver — `eos-archive`** *(owner requirement D, 2026-09-04; a new type-A repo on the `PR-015` skeleton, E-OS-native, on Windows/Linux through `PR-008`'s packaging verbatim, switched at install by `PR-005`)* — what the WinRAR/WinZip feature list reduces to once measured: **7z read + write** (solid blocks and AES-256 with header encryption — `sevenz-rust2` 0.22.2 `writer.rs:282 push_archive_entries` writes one solid block, `:166 push_archive_entry` non-solid, `archive.rs:58 is_solid`; 7z comments are a `kComment 0x16` property the crate carries as a TODO at `archive.rs:33` — a small upstream patch, not a format limit), **ZIP** AES-128/192/256 (AE-2, `zip` 8 `aes-crypto`), ZIP64, comments (`zip` 8.6.0 `write.rs:1034 set_comment`, `:1046 set_raw_comment`), **ZIPX read** deflate64/lzma/xz/ppmd/bzip2/zstd but **write** deflate/bzip2/zstd/xz/ppmd only — the crate refuses the other two (`write.rs:2151` "Compressing Deflate64 is not supported", `:2198` "LZMA isn't supported for compression"), tar.gz/tar.xz/tar.bz2/tar.zst, **CAB read + write** (`cab` 0.6 `builder.rs` / `cabinet.rs`), **ARJ / LHA / ISO 9660 read only** (`unarj-rs` 0.2, `delharc` 0.8, `iso9660-rs` 1.0.2 incl. El Torito — never `cdfs` 0.2.3, which pulls `fuser` whose `build.rs` panics on pkg-config for the Redox target; *mounting* an ISO is the disc-image row, not this one), 7z `.001` byte-split volumes and a WinZip-style `.z01` set (`zip` `read.rs:143–162` parses the multi-disk EOCD, `write.rs` has no split writer — ours, APPNOTE-documented), **recovery record as a PAR2-class sidecar** on `reed-solomon-erasure` 6 (`par2-rs` 0.8.0 does **not** build for Redox in any feature set: `src/create/plan.rs:45 cannot find value _SC_PHYS_PAGES in crate libc`, and its default feature pulls `aws-lc-sys` + cmake), "adaptive compression" = a per-entry choice among store/deflate/zstd/LZMA2/brotli written into an open container that 7-Zip/WinZip open (`brotli` 9: 4 packages, `cargo check --target x86_64-unknown-redox` 11.14 s; `zstd-pure-rs` 0.1.2 + `ruzstd` 0.8.3: 3 packages, 5.77 s; `lzma-rust2` 0.16 `encoder` inside the core probe — all pure Rust, no `cc`), **scan-before-extract** through the library API recorded against `PR-020`, an "open with" manifest in `/usr/share/ui/apps/` with `accept=*.7z` … `accept=*.zst` (`launcher/src/main.rs:902–915 chooser_main` keeps every manifest whose glob matches; `cosmic-files` rev 28546795 built `--no-default-features` has its `desktop` feature off, so `mime_app.rs:317–318` leaves the MIME cache empty and every non-zip/tar/gz path — `.xz` and `.bz2` included — reaches `launcher` via `open` 5.4.1 `redox.rs`), a step-by-step wizard and a favourites list on `eos-ui`, one CLI binary from the same crate (`R-207`), SFX **opened** as an archive (EOCD search past the stub, no execution — creation is refused in §13), WebDAV as the only cloud target (`eos-drive` `PR-012` or any Nextcloud-class server: `reqwest_dav` 0.2.2 on `reqwest` 0.12 `rustls-tls` + the redox-os `ring` fork exactly as `pkg-lib` links it, 168 packages, `cc` only from `ring`; **`reqwest_dav` 0.3.x must not be used** — it resolves onto `reqwest` 0.13 + `aws-lc-sys` + cmake, 194 packages). **RAR is a separate cell, 🔑 until Q20**: extraction via `unrar-rs` 0.7 (`default-features = false`, `crypto-rust`; 72 packages, no `cc`, checks for Redox in 19.51 s) carries RARLAB's field-of-use restriction that "applies to anything that links this crate" (README:194–195) — non-free in the Debian/FSF sense, and `cargo info unrar_sys` reporting `MIT OR Apache-2.0` is false metadata cargo-deny would wave through; the clean-room `rars` 0.9.3 reads **and writes** RAR 1.3–7 incl. solid, volumes, AES, recovery records (43 packages, no `cc`, Redox check 24.33 s, `cargo deny --offline check licenses` ok) but its `COPYING` reads WTFPL while `Cargo.toml` says MIT OR Apache-2.0, and no court has tested a clean-room RAR writer. **Measured 2026-09-04 on the host only** — probe `pure-formats` (zip 8 + sevenz-rust2 0.22 + tar 0.4 + flate2 1 + cab 0.6 + iso9660-rs 1 + unarj-rs 0.2 + delharc 0.8 + reed-solomon-erasure 6 + lzma-rust2 0.16 + libbz2-rs-sys 0.2): `cargo generate-lockfile` → 131 packages, `cargo tree --edges normal,build -i cc` → nothing, `cargo check --target x86_64-unknown-redox --message-format short` → Finished 14.53 s; `cargo deny --offline check licenses` with the products' `deny.toml` **fails**: `bzip2-1.0.6` (libbz2-rs-sys) is not on the allow-list — an explicit allow with a reason, or no bzip2. **Not measured**: the C route (`zstd-sys`, `lzma-sys`, `bzip2-sys` — the host has no Redox C sysroot, `stdlib.h` not found) which this graph does not need; `aarch64-unknown-redox` (no std on the host); any link step; runtime on Orbital **[UNVERIFIED]** — and so is whether `cosmic-files`' own extract-here / extract-to / compress entries appear on screen at all (read from `src/menu.rs`, never seen in QEMU) | `cosmic-files` in the image (rev 28546795, `--no-default-features`): ZIP + tar.gz **create** with an AES-256 ZIP password, **extract** gzip/tar/zip, extract-here / extract-to / compress in its menu; its bzip2 and xz features are **off** in the E-OS build; `extrautils` CLI `tar`/`gzip`/`gunzip`/`unzip` (`config/minimal.toml`, recipe build-depends on `xz`); codec recipes `bzip2`, `libzip`, `lz4`, `xz`, `zstd`, `libarchive` non-wip — built by `config/x86_64/ci.toml`, **not** in the shipped image; every user-facing archiver recipe is `wip/` (`7-zip` "missing script for gnu make", `ouch` "compilation error", `unzrip` "make zstd work") | the repo; the format set above on pure-Rust crates; the split-volume writer and the PAR2 sidecar; the `PR-020` scan hook; the launcher manifest; packaging from `PR-008` (an Explorer context-menu COM DLL and Linux `.desktop` `Actions=` are host-only packaging items, unsigned on Windows — `PR-008`'s SmartScreen caveat); `deny.toml` allow for `bzip2-1.0.6` with a reason; the RAR cell after Q20 (if `rars`: read and write from one crate; if `unrar-rs`: read only, a `[[licenses.exceptions]]` entry, the restriction paragraph in `NOTICE`, and the crate permanently barred from a RAR writer); first evidence = the fixture set (test.7z solid+AES, test.part01.rar+test.rev, test.cab, test.iso, test.arj, test.lzh, test.zipx deflate64) extracted under `redoxer exec` and diffed with `blake3sum` | L (core) · S (RAR, after Q20) |
| `PR-021b` | **Scheduled, restorable backups** *(the "scheduled automatic backups" half of requirement D; gives `L-4` its register home — §0.2 says a time row may only reference a register id, and `L-4` referenced none)* — file-level archives on the `PR-021` engine (tar + zstd/xz + AES), a cron-expression schedule, and a restore that is **proven by restoring** (a backup whose restore never ran is a check that can only pass, §0.4); targets in order: local disk → `eos-drive`/WebDAV (`PR-012`) → the `CS-002` object store. The schedule half is measured on the host: `croner` 4 `chrono` + `chrono` 0.4 → 49 packages, no `cc`, `cargo check --target x86_64-unknown-redox` Finished 54.74 s. **No scheduler exists on E-OS**: `find recipes -maxdepth 4 -iname '*cron*'` → nothing, `recipes/wip/time/timer-rs` "not compiled or tested", `config/x86_64/eos.toml` has no cron/timer line; the only planned timer is `R-705`'s — the backup daemon shares it or runs as an init-started daemon in the `eos-power`/`eos-netcfg` pattern (§17.3.2). **Not promised**: backup-on-change (no file-event bus, §7.5.3) and point-in-time consistency of open files (RedoxFS exposes no snapshot API, `R-706`; VSS on Windows and LVM/btrfs snapshots on Linux would be host-only extras — the `PR-008` anti-pattern — and are not promised either). `borg`/`restic`/`rclone` are not candidates (`recipes/wip/backup`, `recipes/wip/tools/{restic,rclone}`: "missing script for pip" / "missing script for Go") | `tar` + `redoxfs-clone` by hand (audit `02 §3`); no tool, no schedule, no timer | a `backup` subcommand and pane in `PR-021`; a timer shared with `R-705`; a restore self-test in the first `#[test]`; WebDAV then `CS-002` targets as each exists | L |
| `PR-022` | **Disc images and virtual drives** *(owner requirement E, 2026-09-04; decision recorded in §3.0.7)* — one product, own repository from the `eos-notes` skeleton (`PR-015`), Slint on `eos-ui`, packaged for the three targets `PR-008` already packages. **Not the Daemon-Tools model:** no platform gets a driver installed by the application (`R-806` — drivers come only from the signed repository), and that is what shapes the per-platform asymmetry, in the `PR-020` style. **Redox:** a "virtual drive" is a userspace `disk.image*` scheme (`R-818`), the image's filesystem a separate read-only ISO 9660/UDF scheme (`R-819`), the mount/eject/tray half the mount manager `R-D16`; a mounted image appears under `/scheme/<name>/`, never as a drive letter or `/media`. **Windows:** ISO/VHD/VHDX attach through the OS's own Virtual Disk API — `windows-sys 0.61.2` with `Win32_Storage_Vhd` + `Win32_System_IO` exposes `OpenVirtualDisk`/`AttachVirtualDisk` (virtdisk.dll) and `cargo check --target x86_64-pc-windows-gnu` of the `winvhd` probe finishes in 8.02 s (measured 2026-09-04; the first attempt failed with E0425 until `Win32_System_IO` was added) — no driver from us; BIN/CUE, CHD, NRG, MDS get a drive letter on Windows **only** via a signed kernel driver (⚙️/🔑, the `PR-004b` asymmetry), so the Windows build converts them to ISO first. **Linux:** an unprivileged shell-out to `udisksctl loop-setup` / `udisksctl mount` (polkit, no root) with the kernel's own loop/ISO/UDF/NTFS/ext4; the `udisks2` crate is **LGPL-2.1** (registry `udisks2-0.3.1/Cargo.toml:36`), absent from every product `deny.toml` allowlist, so it is invoked, not linked; `loopdev-3 0.5.3` (MIT) zigbuilds on the `PR-008` path in 1 m 48 s (`probe-E-disc-images/check-log-zig.txt`) and is kept only as a root-only fallback. **Formats, by measurement** (`/Volumes/Project itp/xbuild/probe-E-disc-images/pure`, `cargo check` on `x86_64-unknown-redox` 57.62 s / `x86_64-unknown-linux-gnu` 30.02 s / `x86_64-pc-windows-gnu` 44.39 s; `cargo tree --edges normal` → the only C-adjacent leaf is `libc` via `getrandom`; no wasmtime, no signal handlers, no `compile_error!`): ISO 9660 + Joliet + Rock Ridge (`hadris-iso 2.3.0`), UDF 1.02 (`hadris-udf 2.3.0`), VHD fixed/dynamic/differencing and VHDX (`am-img-vhd`/`am-img-vhdx 0.3.4`, 17/14 `unsafe` — review items), BIN/CUE (`cue-rw 0.3.0` plus ~100 lines of 2352→2048 MODE1/MODE2 sector extraction of our own), CHD (`chd 0.3.4`, pure Rust, 0 `unsafe`) — the v1 set; NRG, CCD+IMG+SUB, MDF+MDS are **import by conversion** to ISO/BIN-CUE (`cargo search nrg`, `ccd`, `"mdf mds"` find no crate; documented footers around raw sectors); MDX refused (§13). `opticaldiscs 0.15.0` was measured and rejected: its default `chd` feature is `libchdman-rs 0.288.11`, whose `build.rs` **downloads a prebuilt C archive at build time** unless `LIBCHDMAN_FORCE_SOURCE` is set — a network fetch in a build script has no place in the offline signed cookbook — and its `nod 1.4.4` dependency with default features drags `bzip2-sys`/`liblzma-sys`/`zstd-sys` (host `cargo check` for Redox fails in `bzip2-sys` for want of a sysroot, which is a host verdict, not a platform one); `cargo zigbuild --target x86_64-pc-windows-gnu` of it did succeed (1 m 41 s, 4 789 760 B). **Licences:** `hadris-iso`/`hadris-udf`/`hadris-cd`/`hadris-fat` (MIT), `chd` (BSD-3-Clause), `isobemak` (MIT OR Apache-2.0) carry an SPDX field only — **no LICENSE file in the package**; fetch the upstream text before a shipping row cites them as compatible; `iso9660-rs`, `am-img-vhd(x)`, `cue-rw`, `windows-sys`, `loopdev-3`, `open` ship licence files. **Also in scope:** disc imaging of **data discs** to `.iso` — a block copy from the drive scheme to a file, gated on Redox by the `R-815` ATAPI proof, `\\.\CdRom0` / `/dev/sr0` elsewhere (no BIN/CUE or audio dumps: READ CD is a TODO at `disk_atapi.rs:81`); ISO creation from a folder (`hadris-cd 2.3.0` + `isobemak 0.4.3`; `cargo check` redox 27.09 s / linux 11.53 s / windows 11.75 s; 0 and 1 `unsafe`) carrying the sentence "E-OS cannot boot from an optical disc" (§14.4) — the `wip/` ISO tools (`xorriso`, `mkisofs-rs`, `libcdio`, `libisofs`, `k3b`) stay behind `CS-009` and are GPL-2.0+ where they are libburnia; writing the **verified** installer medium to a USB stick from inside E-OS — a raw write over `usbscsid` (`main.rs:159-163` has a real write path, Write16 in `cmds.rs:198-212`) to `/scheme/disk.usb-…-scsi` through the `R-D16` shim, hash-checked as in `R-614a`, the in-OS half of `R-F28` and of `installer-wizard.md:423` ("na pendrive jako cel", DO ZBUDOWANIA; removability is `R-604a` on `R-815`'s channel); sessions, history and favourites as per-user state; `accept=*.iso` (+ `img`/`vhd`/`vhdx`/`cue`/`chd`) lines in the launcher manifest — the association mechanism `R-D08` now records — end-to-end from `cosmic-files` **[UNVERIFIED]** (§15). Context-menu entries are cluster F's `R-D15`, cited, not re-minted. **Not promised:** copy-protection and media-type emulation, MDX, a drive cap, driver-installed virtual drives, Blu-ray/AACS (§13); burning, DVD boot, NTFS/ext4 inside a VHD on E-OS, live disc-inserted events, silent auto-mount at boot, UDF 2.x until measured (§14.5) | nothing: no image mounter, no ISO 9660/UDF/NTFS/ext4 scheme (`redoxfs` is the only mounter in the tree; `redox-fatfs` only in `config/*/ci.toml`, in no E-OS image), no mount manager (§17.2.1), `ahcid`'s ATAPI read path never run (`R-815`); five optical recipes in `recipes/wip/` with `#TODO` headers behind `CS-009` | repository; the Redox back-end `R-818` + `R-819` + `R-D16`; the Windows Virtual Disk back-end; the Linux `udisksctl` back-end; the container layer (BIN/CUE, CHD, VHD/VHDX) and the NRG/CCD/MDS converters; data-disc imaging after the `R-815` proof; ISO creation; the stick writer; manifests with `accept=` lines. **Measured for `x86_64-unknown-redox` only** — `aarch64-unknown-redox` is tier-3 with no host `rust-std`, so the primary arch (`R-811`) is settled in the container, and no probe was linked or run on Redox (§15) | L (Windows/Linux) / XL (Redox: three OS components first) |
| `PR-005` | **Enable/disable products at install time** — the wizard's package-selection screen writes the chosen `[packages.*]` set; the installer already takes a package list (`eos-installer` `src/config/package.rs` `PackageConfig`) | the installer *has* a package model; no screen chooses from it; `installer_tui.rs:17` lists "preconfigured packages" as a prompt to add | M3 wizard screen (§6.4) with a product list read from `PR-001`'s generator; unattended answer file (`R-616b`) carries the same set | M |
| `PR-006` | **Products pin `eos-ui` from GitLab, not the GitHub mirror** (`eos-notes/Cargo.toml:18`, `eos-control/Cargo.toml:36`) | mirror pinned | repoint, bump, `pins --strict`; add a `ci-integrity` check: no `github.com/Gh0s777tt` in any type-A `Cargo.toml` | S |
| `PR-007` | **Host window backend for the Slint products** — `backend-winit` feature per crate behind `cfg(not(target_os = "redox"))`, `BackendSelector` in `eos-ui::init` | `cargo check` clean on macOS; `run` has no platform | one feature line + one call per crate, **and the `R-D15` menu component behind the same `cfg`** — `eos_ui::prefs` is read in the same `init`, so a product gets the user's menu style on Redox, Linux and Windows from one bump of the `eos-ui` pin (every product pins one rev, e.g. `eos-control/Cargo.toml:37`); measure by launching Notes on Linux and macOS; Windows **[UNVERIFIED]** | S |
| `PR-008` | **Per-OS packaging and a download page** *(✅ **SHIPPED IN ALL SEVEN PRODUCT REPOSITORIES 2026-09-03**, proven by the CI job logs rather than by a local run: `eos-sheets` zip 10 435 145 B / tar.gz 7 665 915 B · `eos-slides` 10 435 227 / 7 666 041 · `eos-drive` 10 435 980 / 7 665 925 · `eos-store` 10 435 452 / 7 666 055 · `eos-notes` 11 786 760 / 9 716 432 · `eos-guard` Linux 9 759 997 B with Windows **deliberately `when: manual`** · `eos-control` Linux-only by design. **`eos-guard` has no Windows build on purpose:** its permission audit reads POSIX setuid/setgid/world-writable mode bits through `std::os::unix::fs::PermissionsExt`, which Windows does not have, and `#[cfg(unix)]`-ing the audit out would ship something that carries the Guard name and can never raise a finding — a check that can only pass (§5.4), sold as a security product. That is an owner decision, not a porting task. **`eos-notes` retired a stale claim in its own manifest:** it said *“Slint's host winit backend no longer compiles on a modern host rustc”* and that has not been true for some time — it now builds for both targets, `rusqlite`'s bundled SQLite C sources included. The **cross-build question is answered** and the `[UNVERIFIED]` below is retired. Windows: `cargo zigbuild --target x86_64-pc-windows-gnu` on the macOS runner produces `PE32+ executable (console) x86-64`, 22 818 304 B, in 1 m 23 s — **after** working around an upstream defect where `i-slint-backend-winit` 1.17.1 gates a struct field `#[cfg(muda)]` but its match arm only `#[cfg(target_os = "windows")]`, so the crate cannot compile for Windows with `default-features = false` at all (`known-issues.md`). Linux: the same tool produces `ELF 64-bit LSB pie executable, x86-64 ... stripped`, 17 001 800 B, in 3 m 08 s, once `i-slint-common/fontconfig-dlopen` moves fontconfig from link time to runtime. The obvious alternative was measured and rejected: rustc **segfaults under qemu-user** in an emulated amd64 container on this host. A `packaging/release.sh` with a `--selftest` of seven cases carries the artefact checks — and its first negative test was a false green, because corrupting the built binary made cargo relink it, so the assertion ran against a repaired file both times)* — `eos-notes` for Linux (`.tar.gz` + signed checksum, AppImage later), Windows (zip + signed checksum first, an installer later) and macOS (`.app` zip); `eos-control` for **Linux only**, as a developer build (§7.5.2); all signed with the release key (`R-F26`) and listed by `WS-005` behind the same developer-only toggle as the OS download | nothing; no runner executes GitHub workflows today (§11.3.1) | a `release-products` job on the `eos-heavy` runner (macOS host: the macOS and Linux-cross builds; Windows needs a Windows runner or `cargo-xwin` — **[UNVERIFIED]** for Slint); `cosign`/minisign as for images | M |
| `PR-009` | **Product test suites and coverage floors** — first tests in `eos-ui` (platform init), `eos-notes` (storage, Markdown), `eos-control` (security baseline, process list) | 0 / 0 / 0 tests | see `TQ-003`; a floor is set only after the first measurement | M |
| `PR-010` | **Spreadsheet — `eos-sheets`** (new type-A repo) — cells, formulas with a small expression engine, CSV/TSV import-export, Slint grid on `eos-ui`; no macros, no VBA-class scripting | nothing in the tree; `recipes/` has no spreadsheet (`sc-im`, `gnumeric`: 0 hits) | MVP: grid + 40 functions + CSV; file format: a documented TOML/JSON container, `.xlsx` **import** later via `calamine` (MIT) | L |
| `PR-011` | **Presentations — `eos-slides`** (new type-A repo) — slide list, text/image/shape boxes, a presenter view on a second Orbital window, export to PDF. **Pin note 2026-09-04** (measured while scoping `PR-021`): `printpdf` 0.12 with `default-features = false` checks clean for `x86_64-unknown-redox` (100 packages, no `cc`, 44.11 s); with default features it **fails** in `azul-core` 0.0.14 (`E0425 FontInstancePlatformOptions`) — pin it without `html`/`text_layout`. "Documents → PDF" batch conversion is refused in §13: the renderer this row does not promise cannot be promised by an archiver either | nothing; no `office` recipe | MVP on `eos-ui`; PDF export through `printpdf` (MIT, `default-features = false`); `.pptx` import **not** promised | L |
| `PR-012` | **Cloud drive — `eos-drive`** (new type-A repo; client + server) — server: a WebDAV endpoint in Rust over RedoxFS on the `CS-001` server edition, with per-user quota and server-side encryption from `CS-002`; client: a sync daemon + a folder in `cosmic-files`, conflict copies, and an `eos-control` pane; Windows/Linux clients from the same crate | nginx/openssh in the image; `rustls` + the redox-os `ring` fork already link on Redox through the installer's `reqwest` path and bundled SQLite builds in-app (`eos-notes` recipe) — the server-side stack exists in pieces; no sync client builds (`rclone` needs Go, `recipes/wip/tools/rclone`), no DB server is outside `wip/` (`CS-001`, `CS-008`; the website's dynamic half has the same dependency, §11.5) | **order:** `CS-001` → a TLS-terminating service proven on E-OS → server → client; the client on Windows/Linux can ship *first* against a Linux-hosted server if the owner accepts a non-E-OS host for the interim (§14.7) | XL (server on E-OS) / L (clients) |
| `PR-013` | **App store — `eos-store`** (new type-A repo; catalogue + client) — catalogue = a signed index of `pkgar` packages with metadata (name, description, screenshots, licence, permissions = scheme list) served by the same channel as updates (`R-703`); client = an `eos-control` pane or a standalone Slint app: browse, install, remove, update; **no accounts, no payments** in v1 | `pkg` + a signed index exist (`V2-MS13`–`15`); no metadata, no screenshots, no client UI; `cosmic-store` is deferred (`eos.toml:38`) | metadata schema in the index (`repo.toml` extension), a generator in `cookbook`, the pane; on Windows/Linux the "store" is the download page (`PR-008`), not a package manager | L |
| `PR-014` | **Browser** — E-OS ships NetSurf; a *downloadable* browser for Windows/Linux is **not** an E-OS product: NetSurf already has upstream builds for both, and a fork adds nothing but maintenance. The product row is `R-D06`/`R-F30` (build it from source as a PIE on E-OS) | upstream prebuilt | no separate repo; link to upstream downloads on the product page | S |

**Repositories created 2026-09-03** (Q13): `eos-sheets`, `eos-slides`, `eos-drive`, `eos-store` on GitLab (`e-os/`) with GitHub mirrors (`Gh0s777tt/`); registration in `repos.toml` and `CLAUDE.md` §11 follows with the first skeleton push (`pins --strict` must see a pinned recipe). Each starts from the `eos-notes` skeleton (`eos-ui`,
AGPL-3.0, `overflow-checks`, the `.gitlab-ci.yml` light tier, `deny.toml`, a `#[test]` in the first
commit) so `TQ-*` applies from day one; each gets a recipe under `recipes/gui/` and a
`[packages.*]` entry that `PR-005` can switch off.

**Order that costs least:** `PR-006` → `PR-007` → `PR-009` → `PR-001` → `PR-005` → `PR-008` (Notes and Control on Linux/Windows exist at this point) → `PR-004` → `PR-020` (reuses `PR-008`'s packaging and `PR-015`'s skeleton, shares nothing with `PR-013`) → `PR-021` (the archiver, whose scan-before-extract needs `PR-020`'s lib) → `PR-022` (disc images, after `R-818`/`R-819`/`R-D16`) → `PR-013` → `PR-010` → `PR-011` → `PR-012` (server last, because it waits for `CS-001`). `PR-002` is a decision and costs nothing; `PR-003` was one until Q16 reversed it — its cost is now `PR-020` (L) and `PR-004b` (band D).
Control on Linux/Windows exist at this point) → `PR-004` → `PR-013` → `PR-010` → `PR-011` → `PR-012`
(server last, because it waits for `CS-001`). `PR-002`/`PR-003` are decisions and cost nothing.

---

## 8. Drivers and hardware

### 8.1 Measured driver inventory

Measured **inside `base.pkgar` on both architectures**, not read off a wish list.

| category | drivers in the image | note |
|---|---|---|
| NVMe disk | `nvmed` | both arches; the root boots from NVMe in QEMU |
| SATA/AHCI disk | `ahcid`, `ided` | **x86_64 only** — on aarch64 the entries point at binaries that do not exist (`R-803`) |
| VirtIO disk | `virtio-blkd` | both arches, verified |
| USB storage | `usbscsid` | both arches; **E-OS enabled what upstream disables** |
| SD card (RPi) | `bcm2835-sdhcid` | **aarch64/Raspberry Pi only**, never bound on hardware |
| USB host | `xhcid`, `usbhubd`, `usbctl` | both arches |
| USB input | `usbhidd` | keyboard/mouse; both arches |
| PS/2 input | `ps2d` | **x86_64 only** (service correctly gated by architecture) |
| Intel network | `e1000d` (+ id `e1000e` 0x10D3) | the `e1000e` id is **x86_64 only** — see `R-907` |
| Realtek network | `rtl8168d`, `rtl8139d` | both arches; present, no QEMU model to test against |
| Intel 10G | `ixgbed` | both arches, untested |
| VirtIO network | `virtio-netd` | both arches |
| USB network (RNDIS) | `usbnetd` | both arches; an E-OS addition, pcap-verified |
| Display | `vesad` (framebuffer), `virtio-gpud` (2D) | both arches — **`virtio-gpud` IS in the image**, contrary to a frequent claim |
| Audio | `ihdad` (Intel HDA), `ac97d`/`sb16d` (x86_64) | `ihdad` — the codec RIRB timeout blocks audio in QEMU (`R-D07`) |
| RAID-1 | `raid1d` | **E-OS's own component**, not upstream; degraded mode, resync |

**Dead entries to clean up (`R-803`).** On **aarch64** the image carries `pcid.d/ac97d.toml`,
`vboxd.toml` and initfs `ahcid`/`ided` whose **binaries do not exist** for that architecture,
because the Makefile copies every `config.toml` regardless of architecture. Not a failure, but a
mess that forces guessing. The task: copy `pcid.d` conditionally per architecture.

### 8.2 Driver manager — `R-8xx`

A real PCI+USB bind pipeline exists (`hwd` → `pcid` → `pcid-spawner` matches static
`/usr/lib/pcid.d/*.toml`; `xhcid` matches `drivers.toml`), but nothing resembling a manager:
matching is a compiled-in catalogue across **three owners** (`initfs.toml` + `usr/lib/pcid.d/*` +
`xhcid/drivers.toml`), all drivers ship inside a monolithic `base.pkgar`, binding is one-shot at
boot, and platform/ACPI/DT devices are enumerated but never bound. The security thesis is sound but
**covers only hardware a driver exists for**.

> **Numbering warning:** [`docs/architecture/driver-manager.md:16`](docs/architecture/driver-manager.md)
> reserves `R-800`…`R-814` for **different** meanings. See [Annex B](#annex-b--identifier-collisions-and-decisions-d1d7).

| id | item | capability | state |
|---|---|---|---|
| `R-801` | **`eos-devd` device-inventory daemon** exposing `/scheme/devices` — unify `pcid` (`/scheme/pci`), `xhcid` (USB ports) and `hwd` platform enumeration into one readable lspci/lsusb-style inventory (vendor/device/class + bound driver + bound? flag). The read-side foundation, buildable in user space on aarch64 today: the PCI half is the loop `pcid-spawner/src/main.rs:34-60` already runs (`read_dir("/scheme/pci")`, `full_device_id`; bound? = `ENOLCK` at `:41-47`), the USB half is `std::fs` over `/scheme/usb.<hc>/port<n>/descriptors|state` (`xhcid/src/main.rs:150`, `xhci/scheme.rs:10-15`) — only the USB bound? flag is new work. Ships an **`lsdev` CLI** over the same inventory. **Inventory is scan-on-demand and at boot** — nothing emits a device event (measured 2026-09-04: `grep -rn -i 'rescan\|rebind\|hotplug\|uevent'` over `pcid` and `pcid-spawner` → 0; `xhcid` polls its own ports, `main.rs:102/116/145` `InterruptMethod::Polling`, `:166 hci.poll()`, and pushes to no bus), so a device plugged in after boot is not seen until `V2-S05`'s hot-plug bus (⚙️, §7.3); "like DriverBooster" does **not** include *live* here. Human-readable names come from `pci.ids`/`usb.ids` shipped as data and parsed at runtime — `recipes/dev/pciids` exists but is in **no** image config (`grep -n pciids config/x86_64/eos.toml config/x86_64/full.toml` → 0; `ci.toml` carries it commented); do not take `pci-ids 0.2.6` as-is, its `build.rs:52` `update_ids()` spawns `curl` against raw.githubusercontent.com on every build (`:298-303`) and overwrote the cargo-registry copy on this host (vendored `2025.07.11` → `2026.09.04` after one probe build) — unpinned, non-reproducible (`R-303`); `usb-ids 1.2026.6` has no network in its `build.rs`. Note that `hwd` spawns `acpid` only on the ACPI backend, not on the aarch64 DT path — see `R-811`. Host probe (`xbuild/probe-C-driver-updates`): `semver 1` + `toml 0.8` + `serde` + `pci-ids` + `usb-ids` → 30 packages, no `cc`, `cargo check --target x86_64-unknown-redox` Finished 33.75 s; **not measured** without the container: the `aarch64-unknown-redox` check and a real link with the cookbook toolchain (`P-17`) `[P0·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-802` | **Signed driver catalogue** (device-ID → driver package + version + arch), packaged as its own pkgar signed with the `R-503` hybrid key, fetched, verified and cached. Seed it from the existing three catalogues so day-one coverage equals shipped coverage `[P0·M·🖥️]` · needs `R-703` | **BUILDABLE** | 🔴 |
| `R-803` | **Harden the matcher against untrusted catalogue input.** The panic is fixed (`U-137`, `eos-base` `66e3070b`): `DriverConfig::match_function` parsed vendor keys with `i64::from_str_radix(..).unwrap() as u16`, which carried two bugs — the `unwrap` panicked `pcid` mid-scan, and since the matcher runs for every driver against every device **one bad entry broke all boot binding**; and the `as u16` cast silently truncated, so `0x11111000` matched vendor `0x1000`, letting an entry bind a device it never names. Now parsed straight into `u16` with out-of-range rejected, a `log::warn!` and a skip, so a bad entry costs only itself. Four unit tests; **the negative control matters** — against the old parser 3 of the 4 fail, two by panicking at `config.rs:50:77`. Gates: `cargo check` clean, `cargo test -p pcid --lib` 4/4, full image build, **boot-smoke PASS** (reaching login *is* the proof the matcher still binds `nvmed`). The `needs R-801` dependency was artificial and was dropped. **Remaining:** reject duplicate entries, validate binary presence (the dead aarch64 entries in §8.1, and the missing `Arch` column in the hardware matrix), and reject **unsigned** catalogues, which genuinely needs `R-802`/`R-703` `[P0·S·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-804` | **Split drivers out of `base.pkgar` into per-driver pkgar packages.** Every driver binary and its match toml ships inside `base.pkgar` today (`eos-base` `Makefile:92-95` copies `drivers/*/config.toml` into `/usr/lib/pcid.d`), so updating one driver replaces the core OS. Split into `drv-<name>` packages spanning the three catalogue owners and two roots (initfs vs rootfs), leaving `base` with only boot-critical initfs drivers. **Measured 2026-09-04, why this is the precondition of any "Outdated" verdict in `R-806`:** there is no per-driver version anywhere — `recipes/core/base/recipe.toml` has `[source]` git/branch/rev and no `[package] version`, `eos-base/Cargo.toml` is a bare `[workspace]`, so the cookbook's `guess_version` (`src/recipe.rs:488-533`) falls to the `"TODO"` default (`src/cook/package.rs:246`) and `repo_builder.rs:256-262` writes the blake3, not a version, into the index; `pkg-lib` `Package.version` is a free `String` with `skip_serializing_if = String::is_empty` (`package.rs:29-31`, fixtures all `"TODO"`). Each `drv-*` also declares the device class it binds and the schemes it registers — `driver-manager.md` §5.5's capability manifest, a named sub-scope here, not a row; enforcement is `M-1`/`R-1010`'s scheme policy and stops at the bus boundary (`R-F13`, no IOMMU) `[P1·L·🖥️]` · needs `R-802` | **BUILDABLE** | 🔴 |
| `R-805` | **`pcid` spawn-on-demand** so a just-installed driver binds without a reboot. `pcid-spawner` is one-shot at boot; add a control op reusing the existing `PCID_CLIENT_CHANNEL` fd-passing `[P1·M·🖥️]` · needs `R-801` | **BUILDABLE** | 🔴 |
| `R-806` | **Driver Manager GUI (Settings → Drivers)** listing Missing / Outdated / OK / No driver, installing **only** from the signed repository and reusing the update download/verify/apply pipeline (`R-708`'s check → verify → apply UI; `R-705`'s thin CLI gains `driver check` / `driver install` verbs). This pane **is** the owner's requirement C of 2026-09-04 ("update search like DriverBooster"): a Settings pane hosted by `R-D01`, not a product, and **E-OS-only** (§13). **What each verdict may mean, measured 2026-09-04:** *Missing* = enumerated, unbound (`ENOLCK` on `/scheme/pci`, `pcid-spawner/src/main.rs:41-47`) and the `R-802` catalogue names a driver → **Install** binds live via `R-805`, no reboot, for a device that was present at boot; *No driver* = `R-807`'s ledger; *Outdated* needs a per-driver package **and** a per-driver version to diff, and neither exists (`R-804` measures it; `pkg-lib` `outdated_packages` at `package.rs:381-382` is a publisher-side marker keyed by `SourceIdentifier`, not a version diff; `pkg-cli` `main.rs:187-220` has Install/Remove/Update/Search/Info/List and no `outdated`/`check`) — so *Outdated* is undefined until `R-804`, and a correctly signed **older** `drv-*` must be refused (`R-704`); the previous needs list omitted both. **Update of a bound driver = stage + system restart until `R-816`** (§14.4: `init` supervises nothing after start) and the pane must say so; storage and GPU drivers are never hot-replaced. Document the anti-scam property honestly: sole source is the signed repository over `R-703`'s verified manifest, every driver blake3 + ed25519 (+ ML-DSA) verified **at install** — never at load, since rootfs drivers exec from the unsigned root through `pcid-spawner` `main.rs:86` (§14.2, `V2-MS02`), so no Windows-style "driver signature enforced" badge — and scope honestly that **detection works even where no driver exists**. "OK" means *bound*, not *works* (`R-923`). Shell today: `eos-orbutils` `launcher/src/settings.rs:139` is the placeholder note "w budowie (R-8xx)"; `eos-control/src/gui.rs:157-431` has no Drivers tab and 0 hits for `scheme/pci` `[P1·M·🖥️]` · needs `R-801`, `R-802`, `R-804`, `R-704`, `R-703`, `R-D01`, `R-705` | **BUILDABLE** | 🔴 |
| `R-807` | **Persisted "device present, no driver" inventory**, so the manager can tell the user a Wi-Fi adapter or a touchpad exists but is unsupported — itself an anti-scam UX win, since `hwd` already names PNP0C0A battery and PNP0C50 I2C-HID with no driver (`drivers/hwd/src/backend/acpi.rs:109,115`). **Re-diffed against the `R-802` catalogue on every `R-705` scheduled check** — the only timer the system will have (`~/eos-forks/eos-base/init.d` holds one-shot `*.service`/`*.target` only, no cron or timer; `init` cannot supervise a separate service, §14.4) — raising an `R-D03` notification when a formerly no-driver device gains one. That hook is the whole of DriverBooster's "scan on schedule"; `update-system.md` §5 already designs Off / daily / weekly `[P2·S·🖥️]` · needs `R-801`, `R-802`, `R-705`, `R-D03` | **BUILDABLE** | 🔴 |
| `R-808` | **`hwd` platform-device binding (ACPI/DT):** map ACPI `_HID`/`_CID` and DT `compatible` strings to driver commands using the same match-table pattern as `pcid.d`, extending coverage beyond PCI+USB to SoC and laptop peripherals `[P2·L·⚙️]` · needs `R-801` | **BUILDABLE** | 🔴 |
| `R-809` | **Multi-segment ECAM/MCFG PCI enumeration.** `pcid` scans only bus 0, 0x80 and bridge-discovered buses (FIXME: *"Use full ACPI for enumerating the host bridges"*); handle multiple host bridges and PCIe segments `[P2·M·⚙️]` | **BUILDABLE** | 🔴 |
| `R-810` | **Driver A/B plus a boot-fail rollback watchdog** — keep the previous driver pkgar and auto-revert on a post-update boot failure, especially for storage and GPU `[P3·M·🖥️]` · needs `R-706`, `R-804` | **BUILDABLE** | 💡 |
| `R-811` | **Fix the `hwd` assumption that `acpid` is running.** `acpid` is spawned inside `AcpiBackend::new`, so it **never starts on the aarch64 DeviceTree backend** — the primary development target. The unified enumerator must not assume it `[P2·S·🖥️]` · needs `R-801` | **BUILDABLE** | 🔴 |
| `R-815` | **Administrative command channel to disks** — SMART, IDENTIFY, block size, secure erase. `installer-wizard.md` §15 names this as the only new work with no item and places it in `R-8xx` because it touches `nvmed`/`ahcid`, not the installer. Unblocks disk model and serial in `R-604a`, closes out `R-607a`, and carries secure erase for the Ghost profile. **`[UNVERIFIED]` whether the drivers expose any such channel today** — check `eos-base`: `drivers/storage/nvmed/src/**`, `drivers/storage/ahcid/src/**`; *partial answer 2026-09-04:* `grep -rn -i "eject|removable|test_unit_ready|StartStop" drivers/storage/` finds only the opcode enum entry `StartStopUnit = 0x1B` (`usbscsid/src/scsi/opcodes.rs:22`) and the RMB doc comment (`cmds.rs:34`) — never issued, never read. **Optical drives ride this channel, not a new number** *(requirement E, 2026-09-04)*. Read in `eos-base` (`eos-july` @ `816546df`): `ahcid/src/ahci/disk_atapi.rs` (148 lines) already dispatches `HbaPortType::SATAPI` (`ahci/mod.rs:64`) to IDENTIFY PACKET (`:47`), READ CAPACITY 0x25 and READ(10) 0x28, so a **read-only data-disc path exists on x86_64 SATA** (`V2-D01`: x86_64 only) and has **never been run**; `write` returns `EBADF` (`:145`, "TODO: Implement writing"), audio needs READ CD (`:81` TODO), `ided/src/main.rs:126` is `//TODO: probe ATAPI` (IDE optical absent), and `usbscsid` binds any class-8/subclass-6 device and only switches the mode-page layout for non-DirectAccess (`scsi/mod.rs:222`), so a USB DVD drive may read by accident — **[UNVERIFIED]**. Eject (START STOP UNIT), media-change polling (TEST UNIT READY / GET EVENT STATUS NOTIFICATION — there is no hot-plug bus, `V2-S05`) and the removable flag (what `R-604a`, `R-D16` and the stick writer in `PR-022` need) are this channel's work; ISO/UDF parsing is **not** — it stays in `R-819`'s process. **No burning.** The first proof is a QEMU run, 🖥️ not ⚙️: `-drive if=none,id=cd0,media=cdrom,file=probe.iso -device ide-cd,bus=ide.0,drive=cd0`, then `ls /scheme/disk.pci-*-ahci/` and `dd … bs=2048 count=16 | xxd` (§15); physical drives afterwards (Band E). This corrects §14.4's "absent from `recipes/`" in place — `recipes/` holds `recipe.toml` files, not driver source, so `installer.md:211`'s grep could never have found it. `R-815` is the first number outside the range `driver-manager.md` reserves (decision **D3**) **Cross-reference 2026-09-04**: this channel is the only honest form of "secure file wiping" — §13 refuses the overwrite kind (RedoxFS is copy-on-write, `R-706`; SSDs remap cells), and the tree holds no wiper at all (`recipes/wip/storage/wiper` wraps a disk-usage TUI); the archiver `PR-021` does not carry a wipe button and points here. `[P2·L·⚙️]` (ATAPI proof `[P1·S·🖥️]`) | **NEW SUBSYSTEM** (channel) / **BUILDABLE** `[UNVERIFIED]` (ATAPI data-disc read) | 🔴 |
| `R-816` | **Process supervisor / service lifecycle** — stop a service, replace its file, restart it, return to the previous version on failure. Precondition of the `service` package class (`ADR-0009` D6) and **the only route to a microkernel equivalent of live patching**. `init` knows exactly **two** service types — `oneshot` and `oneshot_async` — and supervises nothing after start. The nearest existing item, `R-805`, is about **binding devices**, not process lifecycle. `ADR-0009` D8 deliberately mints no number and defers to the register — i.e. here `[P2·L·🖥️]` | **NEW SUBSYSTEM** | 🔴 |
| `R-817` | **Offline signed driver bundle on the install medium and on removable media** — `drv-*` pkgars plus the `R-802` catalogue in a `/pkg` directory beside `id_ed25519.pub.toml`; DriverBooster's "offline driver updater" and §21 row 10, which had no row since the §3.0 gap list was rewritten (2026-09-03). The consumer exists today with no code change: `pkg-lib/src/repo_manager.rs:235-237` `update_remotes()` always tries `add_local("installer_key", …, <install_path>/pkg)`, `add_local` (`:276-290`) needs only the pubkey file beside the `pkgar_head`s (`RemotePath::is_local`, `:176`), and the installer takes the same path (`eos-installer/src/installer.rs:126-137`, `Library::new_local`). Missing is only the payload — `R-804` (drivers still inside `base.pkgar`) and `R-802` (catalogue); a live image has no `/pkg` at all (`installer_tui.rs:182-183`; `var/lib/packages` holds 65 `.pkgar_head`). **Caveat to carry:** the local path verifies with the classical ed25519 package key (`keys/eos-pkg-signing.pub.toml`), while ML-DSA hybrid verification lives in the repo-manifest path (`manifest_sig.rs`, `R-503`/`R-703`) — a bundle is classical-only until the catalogue signature is checked on the local path too; `R-704`'s downgrade refusal applies to a bundle exactly as to a download. If `EC-7` (offline update, "open scope" in §3.5) is ever minted as a row, this is its driver sub-scope, not a second mechanism. **Not measured:** a live image consuming `/pkg` from a second QEMU disk (`mkdir -p /pkg && cp -r /scheme/disk.1/pkg/* /pkg/ && pkg list`) — §15 `[P2·M·🖥️]` · needs `R-802`, `R-804`, `R-614b` | **BUILDABLE** | 🔴 |
| `R-818` | **Image-backed block scheme (`disk.image*`) — the Redox "virtual drive".** A file-backed `driver_block::Disk` (`eos-base` `eos-july` @ `816546df`, `drivers/storage/driver-block/src/lib.rs:72-80`: `block_size`/`size`/`read`/`write` — about 80 lines of our own) served through `DiskScheme::new` exactly as `lived` serves its RAM disk (`lived/src/main.rs`, 177 lines) and as the E-OS-owned `raid1d` runs as a service (`config/x86_64/eos.toml:764-772`). Partitions come free: `lib.rs:160-168` runs `partitionlib::get_partitions` (GPT `partition.rs:29` and MBR) over every `Disk` at wrap time, so an attached VHD/IMG shows `/scheme/disk.imageN/0p1…`. Feeds `R-819`, and RedoxFS partitions inside an image mount through `eos-redoxfs` (`mount.rs:170` opens any path) — **[UNVERIFIED]** in a booted image (§15). **Measured limit:** `DiskScheme::new` (`lib.rs:264-296`) takes its `BTreeMap<u32, T>` at construction and `grep -n "pub fn"` shows no add/remove after it, so runtime attach/detach is either one process per image (`disk.image0`, `disk.image1`, …; `lib.rs:271` asserts the `disk` prefix) or a small patch adding add/remove to `driver-block` — decided at implementation, not here. `driver-block` and `daemon` are unpublished workspace members (`cargo search driver-block` finds only `axdriver_block`), so the daemon is a git dependency on `eos-base` the way `eos-installer/Cargo.toml:77` pins `eos-redoxfs`, or lives in `eos-base` next to `lived`. **Root by kernel rule:** `eos-kernel` `src/scheme/mod.rs:313-323` refuses scheme creation to any `uid != 0`, capability or not — so attach/detach goes through the password-gated shim of `R-D16` (`R-D11` pattern) and the daemon ships as a signed pkgar like `raid1d`, which is how `R-806`'s anti-scam property holds: nothing is "installed as a driver" by an application. Any number of images per daemon — a "15 drives" cap is a Windows drive-letter artefact (§13). Container decoders (BIN/CUE, CHD, VHD/VHDX) sit in front of this scheme and belong to `PR-022`. Not measurable on the host: linking against the cookbook toolchain and the QEMU round-trip (§15) `[P2·L·🖥️]` · needs `R-D16` for the UI half | **NEW SUBSYSTEM** (user space; substrate read in `eos-base`, nothing new in the kernel) | 🔴 |
| `R-819` | **Read-only ISO 9660 (Joliet, Rock Ridge) and UDF filesystem schemes.** No filesystem scheme besides `redoxfs` exists in the tree (`grep -rli fatfs recipes/ config/` → only `config/*/ci.toml`), and §14.4 is right that *boot* needs none — but *mounting* an ISO is exactly a filesystem, so this is a new daemon in the shape `redoxfs` proves: `eos-redoxfs` `src/mount/redox/mod.rs:19-29` registers a scheme named after the mountpoint through `redox-scheme` (0.11.4, on crates.io) and serves it at `/scheme/<mountpoint>`. Parsers measured (`pure` probe, `cargo check --target x86_64-unknown-redox` 57.62 s): `hadris-iso 2.3.0` (MIT by SPDX field; Joliet, Rock Ridge, SUSP, El Torito; 20 `unsafe`; `rust-version 1.88`, met) preferred over `iso9660-rs 1.0.2` (`grep -rn unsafe` → 10 reinterpret-casts of disc bytes into `#[repr]` structs, `directory/record.rs:59,118`, `volume/mod.rs:52,63` and six more — a heavier review item for a parser of untrusted media, not a lighter one); `hadris-udf 2.3.0` reads UDF 1.02 mastered images; `udf-core 0.1.0` (Apache-2.0; metadata partitions, i.e. UDF 2.50+) and `oxideav-bluray 0.0.4` (MIT, with its `aacs` feature switched off) exist on crates.io and are **unmeasured**. `cdfs 0.2.3` is disqualified (normal dependency `fuser` → libfuse via pkg-config, `build.rs` panics on all three targets). Rules carried: `R-803`-style bounded parsing that skips a bad entry rather than panicking, `TQ-005` property-fuzz targets on both parsers, and a **separate process** so a hostile disc never parses inside `ahcid` (no IOMMU, `R-F13`). **Not "unprivileged":** the kernel allows scheme creation only to uid 0 (`eos-kernel` `src/scheme/mod.rs:321`), so this daemon is root like `redoxfs`; dropping uid after registration is an **[UNVERIFIED]** design option (whether a scheme survives `setuid` needs a booted image), and compartmentalisation is claimable only once `contain` (`R-1010`) is on. The mounted volume is `/scheme/<name>/…`, not a directory under `/media` — `R-D16` tells the file manager the name. Measured for `x86_64-unknown-redox` only; aarch64 needs the container `[P2·L·🖥️]` · needs `R-818` | **NEW SUBSYSTEM** (user space) | 🔴 |
| `R-820` | **Network time sync — `eos-timesyncd`.** The register named no time source at all (`grep -n -iE '\bNTP\b|\bRTC\b|time sync|trusted time' ROADMAP.md` → only `R-D05`'s clock and `R-F18`'s "wall clock"), yet `system-updates.md` §8.3 makes maintenance windows and the `expires` half of `V2-MS15` depend on one. **What exists:** `rtcd` ships in initfs (`eos-base/init.initfs.d/00_rtcd.service`, `00_runtime.target:8`) and sets the kernel clock from the CMOS RTC on x86 and from the bootloader's `BOOT_TIME` on aarch64 ACPI boots (`drivers/rtcd/src/main.rs:16-40`, `U-083`); on aarch64 DT boots the kernel reads PL031 itself (`eos-kernel/src/arch/aarch64/device/rtc.rs:6-25`). The clock-set path is `/scheme/sys/update_time_offset` → `time::START` (`eos-kernel/src/time.rs:31-35`), **root-only** (`src/scheme/sys/mod.rs:139-140`) — so `system-updates.md` §8.3's "no RTC sync" is stale: **what is missing is network sync and RTC write-back.** **To build:** a root `oneshot_async` service after `10_net.target` that queries SNTP over `std::net::UdpSocket` and writes the offset; `sntpc` 0.11.0 (MIT OR Apache-2.0) depends only on `cfg-if` and `cargo check --target x86_64-unknown-redox` → Finished. **NOT FEASIBLE TODAY, authenticated (NTS):** the wip recipe `recipes/wip/services/ntpd-rs/recipe.toml:1` is `#TODO not compiled or tested`, and `cargo add ntpd --no-default-features --features rustcrypto` fails on Redox in `clock-steering-0.2.1/src/unix.rs:172,204,232,268,289` (`libc::timex`, `libc::clock_settime`, `MOD_ESTERROR` absent from Redox libc) besides pulling tokio + mio + rustls. Plain SNTP yields *network-synced*, not *trusted*, time (§14.3). **Not measured without the container:** UDP 123 through slirp from QEMU, and the EPERM/root pair on `update_time_offset` (§15 row 25). Windows/Linux: host clocks are already synced, n/a `[P1·M·🖥️]` · needs `R-902` (network up) | **NEW SUBSYSTEM** (SNTP) · **NOT FEASIBLE TODAY** (NTS) | 🔴 |

### 8.3 Storage drivers and blocking buses

| id | item | what it gives | where | state |
|---|---|---|---|---|
| `V2-D01` | `ahcid`/`ided` **for aarch64**, or removal of the dead entries | an honest aarch64 image; SATA on ARM boards | 🖥️ | 🟡 |
| `V2-D02` | **NVMe: SMART/health, TRIM/discard, multi-queue** | endurance and performance on real SSDs; `nvmed` is minimal today | 🖥️ → ⚙️ validation | 🔴 |
| `V2-D03` | **Generic SDHCI/eMMC** (not only RPi) | SD and eMMC in x86 laptops and tablets | ⚙️ | 🔴 |
| `V2-D04` | **RAID 0/5/10 with parity** — extends `raid1d`, same work as `R-912` | a real array; two QEMU disks suffice to test | 🖥️ | 🔴 |
| `V2-D05` | **USB4 / Thunderbolt storage** — same work as `R-932` | external NVMe enclosures, PCIe hot-plug | ⚙️ | 🔴 |
| `V2-D06` | **UFS** (Universal Flash Storage) | storage in modern mobile devices. **Was absent from any roadmap** before v2 named it | ⚙️ | 🔴 |
| `V2-N01` | **I2C bus + I2C-HID** — same work as `R-916` | **laptop touchpads**, sensors, Type-C PD. **No I2C bus exists at all** | ⚙️ | 🔴 T3 blocker |
| `V2-N02` | **TPM 2.0 (TIS/CRB) + measured boot** — same work as `R-913`; the **fifth, still-empty trust layer** from [`docs/reference/keys-and-tokens.md`](docs/reference/keys-and-tokens.md) | measured boot, key sealing; `swtpm` in QEMU allows a **preliminary** build on the Mac | 🖥️ (swtpm) → ⚙️ (real PCRs) | 🔴 |
| `V2-N03` | **Signed bootloader / Secure Boot** — same work as `R-F27` | ✅ **done** (`U-206`–`U-210`): signing in the recipe; live ISO **and** the installed system boot under Secure Boot with the operator's key (`CN=E-OS Secure Boot`, valid to 2036), rejected with a foreign key. Next steps: §5.2 | 🖥️🔑 | ✅ |

### 8.4 Connectivity and honest hardware tiers — `R-9xx`

Wired IPv4 is the strongest subsystem: a smoltcp netstack over real e1000/rtl/virtio/ixgbe drivers,
with DHCP, DNS and automatic bring-up at boot. Everything else is tiered honestly.
**T2** = bounded driver work, buildable and verifiable soon. **T3** = multi-month real-hardware work
QEMU cannot emulate (Wi-Fi, Bluetooth, S3). **T4** = aspirational for a Redox downstream, gated on
absent substrates. **Two structural blockers cascade across the whole wish list:** there is no I2C
bus (killing sensors, I2C-HID and Type-C PD) and no GPU acceleration substrate (killing HDR, VRR,
DirectStorage, NPU and local AI).

| id | item | tier | state |
|---|---|---|---|
| `R-901` | **usbnetd RX — already fixed; the record was lost, not the fix.** This item had been written from a stale snapshot. RX=0 was the state at `1ed8267a8`; the receive path was fixed the **same day**: `U-056` found that `xhcid`'s `endpoints/<n>` numbers endpoints by a **global** counter across every interface of the configuration, and RNDIS puts its Communications control interface *before* CDC-Data, so the data bulk IN/OUT are global indices **2/3, not 1/2** — `usbnetd` used position+1 and therefore read the control interrupt endpoint and wrote the bulk-IN endpoint, hanging both. `U-057` then lifted the residual `xhcid` deadlock with `O_NONBLOCK` bulk-IN. Verified by pcap at the time: `DISCOVER → OFFER → REQUEST → ACK`, concurrently with `usb-storage`. The fix is in the shipped pin. **Also inverted:** this item accused `main.rs:17-19` of falsely claiming full duplex — that comment was correct and the docs were stale. **Residual:** the pcap has not been re-run against a current image (`U-130`) | — | ✅ |
| `R-902` | **Graphical network settings pane** (`U-112`, `U-113`, `eos-control` `5a0c6d3`): the Network tab shows interface, IP/netmask, gateway, DNS and link, and **applies a static IPv4 configuration** through a privileged **`eos-netcfg`** shim — password-gated, the GUI never running as root, like `eos-power`. The render-verification **caught a real gap**: the desktop user's session namespace has **no `netcfg:` scheme**, only `ip`/`tcp`/`udp` sockets, so the GUI reads `/etc/net/*` — fixed by having `eos-netcfg` also write `/etc/net/{ip,ip_subnet,ip_router,dns}`; re-verified on screen, applying `10.0.2.50` flipped the tile from `10.0.2.15`. Both remaining halves shipped in `U-132`: the persistent **DHCP/static toggle** and the **pre-install network pane** in the installer GUI, both put through the full gate (`make CI=1 … all` EXIT=0, boot-smoke PASS, `pins --strict` 26 OK / 0 drift). ⚠️ **Residual, stated rather than hidden:** the toggle's on-screen render **has not been screendumped**; the pane and its apply flow were, and the toggle's non-visual core is `--selftest`-proven inside a boot-smoked image, but a GUI render is only proven by screendump and that one is still owed | — | ✅ |
| `R-904a` | **Raw IP sockets removed from the unprivileged user namespace** (`U-144`). `config/base.toml` granted the user namespace `ip`, i.e. smoltcp's `RawSocket`: any unprivileged program could send arbitrary IP packets — spoofed sources, crafted headers — and step around any filter working above the raw layer. Building `R-904` first would have produced protection that is trivial to bypass, so this had to precede it. **Two halves, and one alone is worthless:** both `config/{aarch64,x86_64}/eos.toml` override `/etc/login_schemes.toml` without `ip`, **and** `eos-userutils` drops `ip` from the hard-coded `DEFAULT_SCHEMES` fallback used when that file is missing or unparseable — the config change alone was a defence one parse error silently undid. **`icmp` deliberately stays:** `ping` ships in netutils and opens `icmp:echo/<host>/ttl`, so removing it would cost ordinary users a working `ping` to close a far narrower hole. ICMP tunnelling remains possible and is `R-904`'s problem, not this item's | — | ✅ |
| `R-904` | **Host firewall / packet-filter layer.** The netstack exposes `ip`/`udp`/`tcp`/`raw` with **zero filtering** — a notable gap for a security-first daily driver, and audit finding `C-10`. There is **no netfilter-style hook point**, which is why `installer-profiles.md` classifies it as a NEW SUBSYSTEM `[P1·L·🖥️]` | T2 | 🔴 |
| `R-903` | **End-to-end IPv6.** The netstack is compiled `proto-ipv4` only; enable smoltcp `proto-ipv6`, wire netcfg addresses/routes plus SLAAC and DHCPv6, and add AAAA lookups in relibc — DNS is **A-record only** today, a second independent blocker beyond the netstack flag `[P2·M·🖥️]` | T2 | 🔴 |
| `R-905` | **netstack multi-adapter / multi-homing.** It detects every `network.*` adapter but binds only the first (explicit FIXME); a prerequisite for any future Wi-Fi coexisting with Ethernet `[P2·L·🖥️]` | T2 | 🔴 |
| `R-906` | **dhcpd lease renewal (T1/T2 timers).** `dhcpd` is one-shot with no renewal loop, so a long-running machine silently loses its lease `[P2·S·🖥️]` | T2 | 🔴 |
| `R-907` | **e1000e (8086:10d3) in the base `e1000d` catalogue.** The default q35 NIC is only in the x86_64 overlay, so a real Intel box outside that overlay binds no driver `[P2·S·🖥️]` | T2 | 🔴 |
| `R-910` | **Multi-gig wired NIC drivers** — RTL8125 (2.5GbE), Intel I225/I226, then Aquantia. Writable in-tree, but no QEMU model exists, so verification needs real silicon `[P2·M·⚙️]` | T2 | 🔴 |
| `R-911` | **USB Audio Class driver (`usbaudiod`)** — UAC1 output → input → UAC2; QEMU-verifiable via `-device usb-audio`. Hi-Res is a later T3 stretch; DSD/MQA/object audio are T4 `[P2·M·🖥️]` | T2 | 🔴 |
| `R-912` | **Software RAID 0/5/10** extending the `raid1d` family — RAID-0 trivial, RAID-5/6 parity moderate, **plus the already-scoped `R-501b` (resync/rebuild) and `R-501c` (root-on-RAID)**, which are folded in here rather than re-minted. Two QEMU disks suffice. Same work as `V2-D04` `[P2·M·🖥️]` · **blocked by `R-F04`** | T2 | 🔴 |
| `R-913` | **TPM 2.0 driver plus measured boot** — a TIS/CRB MMIO driver (QEMU-testable via `swtpm`) plus measured-boot PCR extension feeding the Secure Boot chain. Same work as `V2-N02`; **the fifth trust layer is still empty**. VBS/HVCI-class guarantees are T4 — a microkernel lacks that substrate. Also the boundary on binding FDE to hardware: until it exists, "the disk is encrypted" does not mean "this disk in this machine" `[P2·L·🖥️→⚙️]` | T2/T3 | 🔴 |
| `R-914` | **Hardware SHA acceleration** for pkgar signature verification, extending the existing ARMv8 crypto-extension FDE acceleration (`R-502`, scope parent `R-502b`) `[P3·M·🖥️]` | T2 | 🔴 |
| `R-916` | **I2C bus subsystem plus I2C-HID.** Redox has **no I2C bus driver at all** (`HARDWARE.md:45`, *"I2C devices aren't supported yet"*); this single gap blocks the entire sensor category, most laptop precision touchpads, and Type-C PD controllers. Foundational bus driver first, then I2C-HID. Same work as `V2-N01`; a precondition of `R-932` and `R-935` `[P3·L·⚙️]` | T3 blocker | 🔴 |
| `R-917` | **Colour management and multi-monitor.** A shared driver-graphics/KMS modeset abstraction already exists (connectors, properties, objects, DPMS); add software ICC v4 profile application, a correct sRGB pipeline, and multi-monitor on top. **The only display item that does not need the missing 3D acceleration layer** `[P3·L·⚙️]` | T2/T3 | 🔴 |
| `R-923` | **Verify present-but-unbound drivers on silicon** — `ihdgd` (Intel display/KMS modeset), `bcm2835-sdhcid`, `rtl8168d`, `ixgbed` ship but have never been bound on real hardware. **This is an honesty item:** "Present" in the hardware matrix today means *compiled*, not *works*; `ihdgd` in particular risks implying that real Intel GPU display works when only modeset code exists `[P2·M·⚙️]` | T2 | 🔴 |
| `R-918` | **LED-control API on the existing EC driver.** `acpid` ships a real ACPI-AML embedded-controller driver (`ec.rs`, EC_DATA 0x62 / EC_SC 0x66); add a privacy-indicator LED API (webcam/mic mute), which the EC transport does not yet expose `[P3·M·⚙️]` | T3 | 💡 |
| `R-920` | **Bluetooth LE stack.** No HCI/L2CAP/SDP/GATT today; build BLE via Rust-native `trouble` + `bt-hci` over a USB-HCI transport shim (≈6–12 months), then Classic BR/EDR for A2DP. **Cannot be developed or tested in QEMU.** BT6 Auracast / LE Audio are T4 `[P3·XL·⚙️]` | T3 | 💡 |
| `R-921` | **First Wi-Fi chipset — a research spike.** No 802.11 MAC, supplicant or firmware loader exists; pick FullMAC `brcmfmac` on RPi (which offloads the MAC) or ath9k SoftMAC via a ported FreeBSD `net80211` plus `wpa_supplicant`. Multi-month, real hardware only — **QEMU emulates zero Wi-Fi, so never version-promise it.** Wi-Fi 7 MLO and Wi-Fi 8 are T4 `[P3·XL·⚙️]` | T3 | 💡 |
| `R-922` | **ACPI S3 suspend plus battery/AC/thermal surfacing.** `acpid` today only powers off — no cpufreq/DVFS, no suspend, no battery or thermal reporting. A laptop that cannot sleep or report battery is not a credible portable daily driver. S0ix Modern Standby is T4 `[P3·L·⚙️]` | T3 | 💡 |
| `R-924` | **Broaden CPU-architecture reach** — verify a RISC-V desktop (Redox has the target, E-OS never validated it) and prove an HVF/KVM aarch64 path (Apple-Silicon development is TCG-only today, see `R-F23`) `[P3·L·🖥️]` | T3 | 💡 |
| `R-930` | **GPU 3D/compute acceleration substrate.** `driver-graphics` ships KMS-style modeset but no GEM, command submission, dma-fence or acceleration layer — `grep vulkan\|opengl\|GEM\|shader` returns **0**. Building this gates HDR, high-refresh VRR, DirectStorage, NPU and all local AI. No shortcut exists, and it is not realistically feasible for a downstream alone in the near term `[P3·XL·⚙️]` | T4 | 💡 |
| `R-931` | **Display quality: HDR / VRR / high refresh** — DisplayHDR, Dolby Vision, HDR10+, FreeSync/G-Sync, 120–540 Hz, 8K/10K. All gated on `R-930` `[P3·XL·⚙️]` | T4 | 💡 |
| `R-932` | **USB4 v2 / Thunderbolt 5 / USB-C PD 240 W** — no USB4/TB host-router driver, no PCIe tunnelling, no hot-plug, no Type-C PD stack; eGPU additionally needs 3D acceleration and I2C-PD. Same work as `V2-D05` `[P3·XL·⚙️]` · needs `R-930`, `R-916` | T4 | 💡 |
| `R-933` | **NPU / local-AI stack** — no NPU driver of any kind; local LLM, image generation, voice and translation are impossible before `R-930` `[P3·XL·⚙️]` | T4 | 💡 |
| `R-934` | **Cellular 5G/eSIM, NFC, UWB** — no QMI/MBIM modem stack, no CDC-ACM/usbserial, no SIM/eSIM, no NFC or UWB at any layer `[P3·XL·⚙️]` | T4 | 💡 |
| `R-935` | **Hardware biometrics** — fingerprint (ultrasonic, under-display), IR face, iris: no sensor drivers and no enrolment/matcher stack; most of it depends on the absent I2C substrate `[P3·XL·⚙️]` · needs `R-916` | T4 | 💡 |
| `R-936` | **Research tier 2026–2028** — Wi-Fi 8, Bluetooth 7, USB4 v3, PCIe 7, CXL 3.x, optical interconnects, neuromorphic, AR/VR/MR (OpenXR 1.1). Not addressable by a Redox downstream alone. Post-quantum crypto is the only wish-list item already partly delivered (`R-503`) `[P3·XL·⚙️]` | T4 | 💡 |

### 8.5 Cross-references kept, not re-minted

| id | what it is | why it has no row of its own |
|---|---|---|
| `R-401d` | Kernel contract: `irq_trigger` fans one INTx line out to **every** registered handle | closed kernel work from an earlier generation; cited as the deliberate design behind `R-F17` |
| `R-401f` | ACPI `_PRT` INTx routing (log: *128 entries*) | closed ACPI work; cited as already-delivered groundwork |
| `R-501b` | raid1d resync/rebuild | a named sub-scope **inside `R-912`**, decided in this merge rather than re-minted as `R-912a` |
| `R-501c` | root-on-RAID | as `R-501b` |
| `R-800`, `R-812`, `R-813`, `R-814` | **not register items** | the endpoints of the range `docs/architecture/driver-manager.md:16` reserves for itself; recorded only in Annex B and C.1 (`R-813` was listed there and omitted here until 2026-09-04) |

---

## 9. Security posture by audit finding

Derived directly from [`docs/audit/03-security-audit-2026-08-30.md`](docs/audit/03-security-audit-2026-08-30.md),
which is now **on `main`** and can be quoted from the tree rather than cited second-hand.
The audit's own severities are carried over unchanged, **including the two places where it argues a
finding down rather than up**. Scheduling for each row is in §3.1–§3.3.

### 9.1 Supply chain

| item | priority | finding | scheduled as |
|---|---|---|---|
| Pin the upstream package key; stop trusting a key fetched from the host that serves the packages | **High** | `C-1` | `S-9`, `V2-MS13` ✅ (the byte-level half) |
| `blake3` for `mpc`; an unpinned tarball becomes a hard error | **High** | `C-1b` | `S-7` ✅ |
| Verify `blake3` independently of `is_deps`; derive the published identifier from the computed hash | **High** | `C-1c` | `S-8` |
| Build a current `git`; stop shipping a 2017 binary | **High** | `C-8` | `S-16` |
| Bump `eos-pkgutils` for `rustls-webpki` / `ring` / `rand` | **High** | `C-3` | `S-12` |
| `osv-scanner` in CI and pre-push | Medium | `C-13` | `S-14` (partial) |
| SBOM per tag, committed | Medium | `C-14` | `S-20`, `V2-MS08` |
| Pin apt versions; make the build container reproducible | Medium | `C-17` | `S-15`, `R-303` |

### 9.2 Boot and update chain

| item | priority | finding | scheduled as |
|---|---|---|---|
| Boot verification fails **closed**; building without a key requires an explicit variable | **High** | `C-2` | `S-2` ✅ |
| Publish the x86_64 channel so an installed system can receive fixes | **High** | `C-4` | `S-10`, `EC-1`, `R-701` |
| Republish the aarch64 index carrying `serial`/`expires` | Medium | `C-12` | `S-11` |
| Atomic updates with rollback | **High** | `L-1` | `R-706`, `R-707` |

### 9.3 Runtime and privilege boundaries

| item | priority | finding | scheduled as |
|---|---|---|---|
| Application sandboxing — per-process scheme sets | **High** | `C-5` | `M-1`, `R-1010` |
| Persistent audit log | **High** | `C-9` | `M-2` |
| Packet filtering, or `sshd` off by default | **High** | `C-10` | `M-3`, `R-904` |
| Settle `debug`/`memory`/`irq`/`serio`/`sys` for unprivileged users | **High** | `C-21` | `M-6` |
| `linked_list_allocator` ≥ 0.10.2 — **debt, not a reachable exploit** (the audit argues this one *down*, and that reading is preserved) | Medium | `C-16` | `M-7` |

### 9.4 Process and governance

| item | priority | finding | scheduled as |
|---|---|---|---|
| Block direct pushes to `main` so the pipeline gate can apply | **High** | `C-6` | `S-1`, `R-F12` |
| **Restore CI capacity — the shared tier has been dark since 2026-08-28, intermittently; the `eos-heavy` tier failed nightly on a podman startup race until 2026-09-01, when it first went green** | **High** | `C-7` | **`R-009`** (§11) |
| Move signing off the build machine | Medium | `C-11` | `M-4`, `V2-MS12b` |
| Break-glass account or recovery procedure | **High** | `C-18` | `S-19`, `R-614c`, `EB-5` |
| Gitleaks allowlist entry with justification | Low | `C-19` | `S-4` ✅ |
| Enforce commit signing | Low | `C-20` | open, no item — see §15 |
| SAST | Medium | `C-15` | `M-5` |

### 9.5 Already delivered

| item | evidence |
|---|---|
| Verified boot chain with domain separation, failing closed on a missing signature | `U-212` (`V2-MS02`) |
| Hybrid ed25519 + ML-DSA-65 index signature, verified against the live published index | `U-198`, `U-224` (`R-503`) |
| blake3 enforced on installed package bytes on every path | `U-223` (`V2-MS13`, `V2-MS14`) |
| Rollback and freeze counters in the index | `U-223` (`V2-MS15`) |
| Index and package keys pinned in the image | `U-197`, `U-224` (`R-702`) |
| Secure Boot signing with SBAT stamped **before** the signature | `U-206`–`U-208`, `U-218` (`V2-MS01`, `V2-N03`) |
| Raw IP sockets removed from unprivileged users | `U-144` (`R-904a`) |
| Forced password on first boot, both login paths | `U-076`–`U-079` (`R-602`) |
| argon2id password hashing | verified `U-224` |
| Kernel `Iopl` requires root | `U-219` |

---

## 10. Correctness and regression register

Cheap, high-leverage fixes that gate the trustworthiness of the install and update path. **Closed
entries are kept in full**, because the root-cause write-ups and the retracted wrong conclusions are
the project's audit trail — a "clean" merge that drops them destroys the reason this register is
trusted.

| id | item | state |
|---|---|---|
| `R-F01` | **No plaintext-password leak in the shipping installer.** Verified at the pinned rev `05bf2eb`: only `Password: set/unset` state is printed. The leak was a **stale-clone artefact**; the real work became `R-F02` `[P0·S·🖥️]` | ✅ |
| `R-F02` | **Stale vendored `src/eos-installer` resynced or deleted, plus a provenance gate** (`U-187`). Checked, not assumed: `src/eos-installer` **no longer exists** — the vendored copy had been removed in the meantime, so half of "resync or delete" was already done. The missing half was the **gate**, and that is what was delivered: **check 11** in `ci-integrity.sh` reads fork names from `repos.toml` (28 entries) and rejects any commit that puts fork source into `src/`, `vendor/` or the repository root. Type-A repositories are exempt, because that is where they belong. **Seen failing:** a planted `src/eos-installer/main.rs` gives FAIL naming the directory; removing it returns PASS. Same class of defect as the snapshots in `U-186` — a copy that cannot be pinned and drifts silently from what actually reaches the image — except committed `[P1·M·🖥️]` | ✅ |
| `R-F03` | **pkgar-core `read_at` panic on a truncated segment** (`U-067`, `eos-pkgar` `cb8ae7b`). `read_at` used `copy_from_slice` after clamping `end` to `src.len()`, so a short data segment panicked — reachable via a truncated `.pkgar` whose signed header does not cover the data length. Restored `buf[..end-start]`, added `checked_add` on `offset+header_len` and a truncated-package regression test `[P0·S·🖥️]` | ✅ |
| `R-F04` | **Harden `raid1d` arithmetic and split-brain.** Safety fixes landed (`U-068`, `eos-base` `d4f193c9`): `checked_add` in `byte_off` and an N-way read fallback. `byte_off` used an unchecked add that could wrap and silently degrade a healthy mirror, and the `[primary, 1-primary]` fallback underflow-panicked when `member_count > 2`. **Remaining:** a `raid1d resolve` subcommand and repo-wide `clippy::arithmetic_side_effects`. **Blocks `R-912`/`V2-D04`** `[P1·M·🖥️]` | 🟡 |
| `R-F05` | **Numbering and copy-paste documentation drift.** **This is one of the four identifiers the two predecessors disagreed about** (⏳ against 🟡) — but only in glyph: both described the same substance in prose. Resolved as 🟡. Closed part: the **duplicate `U-039` is resolved** — the netsurf crash is recorded under `U-103`/`U-104` — so `U-039` unambiguously means the upstream-patch refresh. Also closed and worth recording because **one of the accusations was wrong**: the "copied aarch64-only comment in `eos.x86_64.toml`" was **not** a copy-paste error — both places refer to the **build host**, which really is an aarch64 machine. What *was* stale was different and was fixed: the comment claimed the configuration is *"built and boot-verified on the x86_64-linux rig, not on this aarch64 build host"*, whereas since `U-172` it is built **and run** on this host under TCG with `boot-smoke` reaching a login. That claim was the stated reason x86_64 was not exercised here, so its staleness had a real cost. **Still open:** the missing `U-038` gap, the going-forward `R-NNN`↔`U-NNN` mapping — now more urgent because the `V2-*` namespace was added — the `lived` null-namespace `expect()` message, the no-op `Transaction::remove` `io::sink` hash, and **decision D2**: the "ARCHIVAL NUMBERING" banner that Annex B requires in the two design documents has **never been added** — re-measured 2026-08-31, `grep -rl "ARCHIVAL NUMBERING\|NUMERACJA ARCHIWALNA" --include='*.md' .` finds the phrase only in **this file** and in `docs/adr/0009-system-update-mechanism.md`, both of which *describe* the banner rather than carry it, and neither `docs/architecture/update-system.md` nor `docs/architecture/driver-manager.md` has it. **The banner is Polish in the tree** (`NUMERACJA ARCHIWALNA`), so the English form quoted in Annex B D2 matches nothing today and is the text to be *added*, not a string to grep for `[P2·S·🖥️]` | 🟡 |
| `R-F06` | **Typed errors for the missing-pubkey unwraps** (`U-188`, `eos-pkgutils` `14505ecd`). Premise confirmed at the pinned revision: **four** occurrences of `repo.pubkey.unwrap()` in `pkg-lib/src/backend/pkgar_backend/mod.rs` (lines 173, 176, 204, 206) — two each in `install()` and `upgrade()`. The field is an `Option` and `None` is an ordinary reachable state, not an error, so installing from such a repository **crashed the package manager**: anyone who can put a keyless source into `/etc/pkg.d` stops all installation and updating — denial of service from a missing file. **The error variant already existed** (`Error::RepoNotLoaded`, *"Public key for {0:?} is not available"*, already returned by `sync_keys()`), so the fix says the same thing in the same words instead of inventing a second vocabulary. Four sites reduced to one `require_pubkey()`, which also makes it **testable** without standing up the whole backend. **Negative control, because a test never seen failing is not a test:** with `unwrap()` restored in a throwaway copy, `missing_pubkey_is_an_error_naming_the_remote` **panics at line 175** — demonstrating exactly that denial of service — while `present_pubkey_is_returned` still passes, so it is not an always-failing test. With the fix, both pass `[P2·S·🖥️]` | ✅ |
| `R-F07` | **Graphical session no longer blocked by audio.** The greeter's `20_orbital` dropped its `requires_weak 20_audiod.service`; `audiod` exits without signalling readiness on hardware with no audio and hung the whole desktop (`U-072`). Verified: `orbital` now starts (`/scheme/orbital` present) `[P0·S·🖥️]` | ✅ |
| `R-F08` | **Greeter auto-activated on boot, no more Super+F3** (`U-078`). Booting the aarch64 image lands directly on the crimson greeter, zero key presses. **Real root cause, found with an `inputd` serial trace:** the installer **concatenates** `[[files]]` entries with no de-duplication, and because `desktop.toml` includes **both** `desktop-minimal.toml` and `server.toml` — each pulling `minimal.toml` — `minimal.toml`'s `30_console` (which runs `inputd -A 2`) lands **last** on disk via the `server.toml` path and re-steals the foreground to the text console *after* `20_orbital` activates the greeter's VT3. Fix: `eos.toml`, merged dead last so it wins, pins `30_console` **without** `inputd -A 2` on both arches; the VT2 getty stays available via Super+F2. **This corrects the earlier hypothesis** that VT2 activation was a display-handoff artefact `[P1·S·🖥️]` | ✅ |
| `R-F09` | **vesad environment parsing without a panic.** `split_once('=').unwrap()` → `filter_map`, so a line in `/scheme/sys/env` with no `=` no longer panics; found while working on `R-F08` (`U-075`) `[P2·S·🖥️]` | ✅ |
| `R-F10` | **The bootloader unlocked a filesystem it was not built against** (`U-156`). `eos-bootloader@eos-rebased` declared `redoxfs = "0.8"` and resolved it from **crates.io** with **no `[patch.crates-io]`**, while the image's filesystem is built from the pinned fork carrying `--cfg aes_armv8`. So the code that prompts for the FDE password and unlocks the root at boot was a *different codebase* from the one that creates and manages that root: it happened to interoperate, and the first change to the KeySlot/header format on either side would make an encrypted disk unbootable with no gate to catch it. **Closed** by `eos-redoxfs@555359ef61` (import the `Vec` *type*, so the crate builds with `default-features = false` at all) and `eos-bootloader@b249982f29` (depend on the fork by `git+rev`, and unify `redox_syscall` on 0.9 so `syscall::Error` stops being two distinct types). `Cargo.lock` now records the git fork; verified from the bumped pins with `ci-boot-smoke.sh` PASS `[P0·M·🖥️]` | ✅ |
| `R-F11` | **The 13 unpinned/unhashed recipes that actually ship are pinned** (`U-145`). Of the **74** packages in `repo/x86_64-unknown-redox`, 10 had a `git =` source with no `rev` and 3 fetched a tarball with no `blake3`. All 13 are pinned: git revisions taken from the SBOM of the verified build — i.e. exactly what ships, cross-checked on `sdl1` whose SBOM value matches its fetched `source/` HEAD byte for byte — and the three tarball hashes computed from fresh downloads and then **validated by cookbook itself** (clearing caches forced `cook openssh/nano/file - successful`, which routes through the `blake3` comparison that bails on mismatch). `ca-certificates` — an unpinned TLS trust root — was among them. **Correction to this item's original wording:** it claimed a missing hash is only a WARNING. It is not; `fetch.rs` bails with *"Please add blake3 = …"*. The real defect is narrower and worse: that check sits inside `if !cached`, so **anything already cooked is never re-verified** — removing `source/` alone did not trigger it; only deleting `target/` plus `build/<arch>/<cfg>/repo.tag` did. **Remaining:** make the skip-when-cached path fail closed under `EOS_STRICT_FETCH=1` and set it in CI. **Not claimed:** a blake3 pin freezes an artefact so it cannot change under us — it does **not** authenticate it; upstream signature verification is a separate step `[P1·M·🖥️]` | 🟡 |
| `R-F12` | **Every CI gate is a notification, not a gate.** **One of the four contradictions between the predecessors** (⏳ against 🟡); resolved as 🟡 on the evidence. `only_allow_merge_if_pipeline_succeeds = false` on the GitLab project and there had been **0 merge requests** in project history; all 10,088 commits went straight to `main`, so `pin-check`, `integrity`, `rust-checks` and `secret-scan` run *after* the code is published and mirrored, and `docs-currency` — which triggered only on merge-request events — **had never executed once**. **Partly fixed (`U-189`):** `.gitlab-ci.yml:83` now carries the comment *"R-F12: this job used to trigger ONLY on merge_request_event"* and the job also runs on the default branch; the script already had the fallback `base="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-HEAD~1}"`, so nothing else needed changing. **This does NOT close the item and that is not glossed over:** the process decision (adopt merge requests for anything touching the trust chain, the build or a pin) and the project setting remain, and the latter needs a token — an operator action. On `main` the gate still runs **after** publication and mirroring; the move is from "never" to "too late", not to "in time". **Re-measured 2026-09-07, and three of this row's factual assertions are now stale — the thesis survives, its evidence does not.** `glab api projects/e-os%2Fe-os` reports `only_allow_merge_if_pipeline_succeeds` = **`true`**, not `false`; the project has **200 merge requests**, not 0; and `main` is a protected branch with `allow_force_push: false`, which Band E files separately as blocked on an operator's click. *"Both CI platforms are dead"* is also wrong as written: a **self-hosted macOS/arm64 runner** executes `local-gates` and `pages` on every push (`Runtime platform arch=arm64 os=darwin` in the job trace); only the shared-runner half dies with `ci_quota_exceeded`. **But the thesis holds, for a reason that is worse and is mine.** The setting was turned on and gates nothing, because the documented merge procedure lowers it, merges, and restores it — measured on three consecutive merge requests, each **merged 1.3 to 2.5 seconds after its pipeline record was created**, i.e. before the pipeline could run, with the pipeline's own status still `running` or already `failed`. So the remedy this row asks for **has been applied and is ineffective while merges are made that way**, and saying "the setting needs an operator" is no longer the obstacle. **Also unmeasured until now: `main` is intermittently red on the one gate that does run** — `local-gates` reports `19 PASS · 1 FAIL` with `cargo-deny` failing on `Recv failure: Connection reset by peer` fetching the RustSec advisory database, i.e. infrastructure rather than an advisory `[P1·XS·🔑]` | 🟡 |
| `R-F13` | **`docs/security/threat-model.md` promised driver isolation the hardware does not enforce** (`U-187`). Verified **to file and line**, not paraphrased: in `eos-base`, `drivers/acpid/src/acpi.rs:461` reads `//TODO (hangs on real hardware): Dmar::init(&this);` — the DMAR table is parsed but **never initialised**, for an upstream reason: it hung on real hardware. In `eos-kernel`, searching all of `src/` for `iommu`, `smmu` and `dmar` yields **zero files** — there is no IOMMU path in the kernel at all, on any architecture. The document now says outright that driver isolation is **partial**: complete at the **syscall** boundary, **none** at the **bus** boundary, because a driver programmes a bus-mastering device that without an IOMMU reads and writes **any** physical address, kernel memory included, entirely outside the kernel's knowledge. The honest formulation: user space bounds the **blast radius** and gives a restartable boundary, but **does not stop a hostile driver**. Real isolation needs SMMUv3 on aarch64 and VT-d/AMD-Vi on x86_64 — large work, tracked separately, not a documentation fix `[P1·XS→L·🖥️]` | ✅ |
| `R-F14` | **44 shell scripts, zero linting — gated** (`U-159`). `git grep -ci shellcheck` → **0** across 44 tracked `.sh` files that sign releases, publish repositories and can delete 37 GB of build cache. The class had already cost time: `scripts/check-ci-config.sh` used `declare -A` and `scripts/eos-check.sh` used `${ARCH^^}`, both bash-4 constructs on a host shipping `/bin/bash` 3.2. Closed with a `shell-lint` job (errors blocking, warnings advisory) plus `ci-integrity.sh` **check 5**, a blocking gate on bash-4-only syntax. The first run found **3 real errors** plus a `cd` without `\|\| exit` inside the integrity gate itself. Scope excludes inherited `build.sh`/`*_bootstrap.sh`/`recipes/wip/`, which held 141 of the 188 initial findings `[P1·S·🖥️]` | ✅ |
| `R-F15` | **`rust-checks` covered one of the two manifests that matter** (`U-159`). The job ran fmt/clippy/test/cargo-deny against a single `--manifest-path`; the vendored `redox_cookbook` at the repository root — the engine that builds every image — was never linted, never dependency-audited, and its unit tests never ran. Now the root manifest runs `cargo test` (its **9 unit tests** had never executed in CI) and `cargo-deny check advisories`. **That audit failed on its first run** — **RUSTSEC-2026-0204**, an invalid pointer dereference in `crossbeam-epoch 0.9.18` reached through `ignore`/`rayon-core` → `blake3` → `pkgar` — fixed by updating to 0.9.20. Licences and sources stay ungated: those are upstream's choices in a vendored tree `[P1·S·🖥️]` | ✅ |
| `R-F16` | **A second PCI storage controller silently stopped the boot** (`U-153`). Found by the `R-601` harness. **The defect was in the kernel's GIC distributor, not in any driver.** `GICD_ISENABLER`/`GICD_ICENABLER` are *write-one-to-set* / *write-one-to-clear*: a written 1 acts on that IRQ, a written 0 does nothing, and a read returns the current enable mask for the 32 IRQs in that block. `irq_disable()` did a read-modify-write — read the mask, OR in the target bit, write it back — which writes a 1 to **every enabled bit in the block**, disabling all of them. Two PCI devices on different INTx lines land on adjacent SPIs (3 and 4, both block 1), so masking the second device's line while servicing its interrupt also masked the **boot disk's** line, and nothing re-enabled it because that driver was not in an interrupt cycle. The root read never completed, `redoxfs` blocked, and the boot died in initfs with no panic. The same shape in `irq_enable()` was harmless — re-setting set bits is a no-op — which is why this only ever appeared as an unexplained hang. **Fixed in `eos-kernel@18dce5577d`:** write the single bit, no read, no merge — covering GICv2 and GICv3 alike. **Verified against the image built from the bumped pin:** `scripts/repro-intx-lines.sh` reports **10/10 boot**, `ci-boot-smoke.sh` PASS. **Three of my own published conclusions were wrong along the way and are corrected in the record:** the scope (`U-147`), the mechanism (`U-148`), and the claim that `redoxfs` cannot be instrumented (`U-151` — the real reason was a stale binary, not a dead channel). The `raid1d`-holds-the-target-disk theory `R-601` carried for months was tested and **disproved**. **x86_64 is *expected* to be unaffected** because MSI/MSI-X avoids this path — still **`[UNVERIFIED]`** `[P0·M·🖥️]` | ✅ |
| `R-F17` | **A driver aborted on a kernel return value that is by design** (`U-149`). Found in the *passing* half of the `R-F16` matrix. With both disks on GIC SPI 3 the boot reaches `switchroot` and then `nvmed` dies: `assertion failed: amount == core::mem::size_of::<usize>()` at `drivers/executor/src/lib.rs:191`. The kernel's irq scheme **deliberately** returns `Ok(0)` from `kwrite` when the acknowledged count is stale, while the driver asserted the write consumed `size_of::<usize>()` bytes. A stale ack is not an error on a shared line — `irq_trigger` fans one line out to **every** registered handle, which `R-401d` deliberately permits — so any two devices sharing an INTx line could abort a storage driver. **Fixed in `eos-base@7d5ca7e28e`:** `Ok(0)` is treated as *stale ack — a newer interrupt is already pending and will unmask*, and the `.unwrap()` is gone. Safe because `COUNTS` is bumped only by `irq_trigger`. **Verified with a before/after negative control** on two NVMe disks sharing SPI 3: before → login then panic at `lib.rs:191`; after → login, no panic, zero `irq ack` warnings. A **separate defect from `R-F16`** `[P0·S·🖥️]` | ✅ |
| `R-F18` | **Any two PCI devices sharing an INTx line cause an interrupt storm** (`U-180`, `eos-base` `816546df`). Discovered as "the disk on the xHCI line"; **that narrowing was wrong and cost time, because it sent the next person to `drivers/usb/xhcid`, the wrong file.** Located to the second in `U-154` by polling the serial log on wall clock: the boot runs normally to 23 s, then stops for **84 s** — and with `init`'s `log_debug` on, the gap sits inside one step: `rm -rf /tmp` takes **80 s** instead of 1 s. The victim is ordinary filesystem I/O on the boot disk. **Re-measured and reformulated in `U-179`** with four runs changing exactly **one** parameter, the PCI slot: (A) second disk alone on its line → highest counter **7,955**; (B) sharing with xHCI → `virq 37` = **16,829,830**; (C) xHCI moved to another line → the storm **moved with xHCI**; (D) two NVMe sharing a line with **xHCI separate and quiet** → **2,501,072**. **Run D is decisive: xHCI has nothing to do with it and the storm still occurs.** The cleanest comparison is A against D — same line, same `nvmed` driver, sharing the only variable added: **7,955 → 2,501,072, i.e. 314×**. **Mechanism, matching the kernel contract read in `src/scheme/irq.rs:441-467`:** `irq_trigger` bumps `COUNTS[irq]` and wakes **every** handle, and unmasking is done by **whichever** handle acknowledges with the current count — **there is no waiting for all of them**. On a level-triggered line the first driver unmasks while the second device is **still asserting**, so the interrupt returns immediately. **Root cause and fix, in `drivers/executor/src/lib.rs`, not in the kernel and not in `xhcid`:** the executor **acknowledged the interrupt before checking whether its own device had reported anything** — `poll_cqes` came *after* the acknowledgement. Since acknowledging **unmasks the line**, a driver released a level line for an interrupt that was never its own. **Fix:** always read (that consumes the event, without which the reactor spins), but **acknowledge only when your own device reported something**. **Measured on the same configuration:** `virq 37` **16,829,830 → 8**; the worst reproducer row **160 s → 16 s**; the whole 10-row matrix now fits in 16–33 s; boot-smoke PASS. **A kernel fix was written, tested and reverted — twice.** `U-157` wrote "unmask only when every handle has acked" and reverted it because it measured 111 s before and 111 s after — but it was measuring **boot time**, not **interrupt count**, an instrument that did not exist yet. With the counter in hand the same kernel change measures **14,044,113** against 16,829,830 — 17 % — and was rejected again. **A further correction (`U-171`):** the recommendation "clear `IMAN.IP` before acknowledging" had nothing to fix — `Xhci::received_irq()` already reads and clears it before the handle is acknowledged; that advice had been repeated without checking the code. **Residual risk, checked rather than assumed:** if the owning driver drained its queue on an earlier wake-up it will find nothing here, will not acknowledge, and will leave the line masked. Under block installation (~460 MB of continuous I/O) this did not occur; it is recorded so the next person does not rediscover it `[P1·M·🖥️]` | ✅ |
| `R-F19` | **The installer could not write the RedoxFS partition — `Operation not permitted`** (`U-170`). **Not a privilege problem:** root and `sudo` failed at the identical step, and an earlier note claiming otherwise was read off a run killed too early. **Root cause:** `unmount_path()` on Redox is `rmdir /scheme/<name>`, and that request never reaches the scheme manager — it is routed **into the redoxfs daemon**, hits `unlink_internal`, finds the root node has no parent and returns `EPERM`. **Measured on a live system with the instrument controlled first** — `rmdir /scheme/probe_does_not_exist` → *No such device*; `rmdir /scheme/file/no-such-thing` → *No such file or directory*; `rmdir /scheme/file` → *Operation not permitted*: three different errors, so the probe discriminates. Upstream says the same in commit `7f469db`. **Fixed in `eos-redoxfs` `58824d7`:** the daemon honours `rmdir` of its own scheme root as an unmount request — but **only from the process that owns the mount** (`ctx.pid`), because doing it for any caller would hand every uid-0 process a new way to unmount the live root. **A correction to `U-166`:** *"the install completes and only the unmount fails"* was an over-read — the probe printed after the callback returned regardless of `Ok`/`Err`. With the installer's bare `?` replaced by `res.and(...)`, the same run reported the real first failure: **`failed to read package files: No such file or directory`** — which is `R-F21`. **Status brought into line with the text (`U-182`):** the entry had said "resolved as originally described" while the marker still read ⏳ — the document contradicted itself. Closed, because `install-smoke` passes **end to end** (`U-176`, re-confirmed in `U-181` with the `R-F18` fix), and that is proof *in operation*: the shell prompt would not have returned after installation if `unmount_path()` had not worked and the mount thread had not finished in `join()`. The chain this item exposed — `R-F21` → `R-F22` → `R-F24` — is closed in full `[P0·M·🖥️]` | ✅ |
| `R-F20` | **Core recipes shipped as upstream prebuilt binaries** (`U-165`). Found in `U-163` because a source patch to the installer would not take effect. `/work/redox/.config` — **untracked and gitignored** — set `REPO_BINARY?=1` (the tree default is `0`), making cookbook's default rule `binary`, so `cook` **downloaded `…/pkg/<arch>/<recipe>.pkgar` from `static.redox-os.org`** instead of compiling the pinned source, and did so even after the local packages were deleted. **Audited by structure** (a compiled recipe has `target/<arch>/build`; a downloaded one has only `stage`): built — `base`, `bootloader`, `coreutils`, `ion`, `kernel`, `redoxfs`, `relibc`, `userutils`; downloaded — `extrautils`, `findutils`, `installer`, `netdb`, `netutils`, `pkgutils`, `uutils`. **Five of the seven declared an E-OS fork** and are tracked in `repos.toml`, so `pins --strict` was green while the shipped artefact came from elsewhere. **Answered in `U-164`:** three of them carry only a README commit (pure mirrors), but `eos-pkgutils@eos` carries `pkg-lib`'s **manifest-signature verification** — and **none of its four distinctive literals appeared in the 1.4 GB image**, with the search instrument controlled first. So `R-703`'s client half, which `docs/security/index.md` called *implemented*, was **not in the artefact**. **Fixed** by `scripts/eos-source-rules.sh`, which derives the list from the tree rather than restating it: 13 of 26 were unpinned, all 26 are now set to source. Verified on the artefact — the four `pkg-lib` literals go 0 → 1 in the image, the rebuild downloads nothing, boot-smoke PASSes. Still fragile: `cookbook.lock` stays generated and gitignored, so the script must be run on a fresh tree; it exits non-zero when the gap reopens `[P0·M·🖥️]` | ✅ |
| `R-F21` | **`installer_tui` read the package database from a path that no longer exists** (`U-171`, `eos-pkgutils` `cf36a01` + `eos-installer` `e409d32`). `package_files()` opened `<root>/pkg/id_ed25519.pub.toml` and listed `<root>/pkg/*.pkgar_head`, but `pkg-lib` had moved the database years earlier. **Measured on the live image:** `/pkg` does not exist at all, while **`/var/lib/packages` holds 65 `.pkgar_head` files** and `/etc/pkg/packages.toml` exists. Invisible until `U-170` stopped the unmount error masking the callback's result. The fix was **not** a path swap: `pkg-lib` exposes `PACKAGES_TOML_PATH` and `PACKAGES_HEAD_DIR`, and `package_files()` now reads through `PackageState::from_sysroot` — rewritten rather than repointed, because the key moved too: `pkg-lib` keeps one key **per remote repository** in `packages.toml`, not one file at a fixed address `[P0·M·🖥️]` | ✅ |
| `R-F22` | **`copy_file()` aborted the install on the first file the configuration layer had already written** (`U-171`). The configuration phase runs **before** copying and deliberately overwrites some package files — E-OS replaces `/etc/issue` with its own login banner, one of **65** `[[files]]` entries — while both branches of `copy_file` create with `create_new`/`symlink`. The first collision killed the whole run, **measured on file 12 of 13,679**. The configuration layer is personalisation and must win, so an existing target is now skipped. **This code had never executed before:** `package_files()` failed ahead of it (`R-F21`), and that failure was masked by `R-F19`. **Effect measured on the same harness and image:** `ENOENT` (0 files) → `File exists` (12 of 13,679) → `copy usr/bin/msggrep [661/13679]` with no error `[P0·S·🖥️]` | ✅ |
| `R-F23` | **E-OS is unstable under hardware virtualisation (`hvf`) on Apple Silicon.** `boot-smoke` **passes** under `-machine virt,accel=hvf -cpu host` (login in 10 s against 19 s under TCG — **measured**, and **~1.9×**, not the order of magnitude first written), but under sustained load the guest dies on `synchronous_exception_at_el0`. Two runs, **two different processes**: `/usr/bin/ptyd` at file 77 of 13,679 (`-smp 4`, `FAR_EL1 = 0x19`, `ELR_EL1 = 0x44FC6C`, `SPSR_EL1 = 0`) and `/usr/lib/drivers/virtio-netd` at file 19 of 13,679 (`-smp 1`). **One core does not help, so this is not a multi-core race** — the candidate is the CPU model difference (`-cpu host` is Apple M-series, not `cortex-a72`): a missing architectural feature, cache-coherency maintenance, or unaligned access handling. It matters practically: this is how E-OS would run on an Apple Silicon host and in many cloud environments. **The harness stays on TCG by default — correctness before speed**; `EOS_SMOKE_ACCEL=hvf` reproduces `[P1·M·🖥️]` | 🟡 |
| `R-F24` | **`try_fast_install()` never ran, even when booted from the live image** (`U-176`, `eos-installer` `c8d32ad`). The installer has a **block** copy path that reads the live system straight from memory, entered only when `DISK_LIVE_ADDR` and `DISK_LIVE_SIZE` are in the environment; without them it returns `Ok(false)` immediately (`installer.rs:765`). The variables are set by the **bootloader** on a live boot and read by `lived`. **Measured:** `redox-live.iso` starts with live mode **on by default** — the bootloader menu says *"Press l to **disable** live mode"*, unlike `harddrive.img` where it says "enable" — and **even so** the install took the file-by-file path. **Cause:** the variables live in the **kernel** environment, read through `/scheme/sys/env`, while the installer called `env::var()`, i.e. the **process** environment. Two different sources. **Measured in a single run, side by side:** `grep DISK_LIVE /scheme/sys/env` → `DISK_LIVE_ADDR=00000000e4e50000`, while `echo "$DISK_LIVE_ADDR"` → *Variable does not exist*. The installer now reads both, process environment first. **Effect:** file path **31 files/min, 0.101 MiB/s, ~6.8 h**; block path **1.3 MB/s, 460 MB, ~6 min**. **Methodological note kept:** pressing `l` **toggles**, it does not enable — on the ISO it *disables* live mode, and such a run could not even log in. The menu names the **available action**, not the current state; read it before sending a key `[P1·M·🖥️]` | ✅ |
| `R-F25` | **WITHDRAWN (`U-181`) — this was not a defect, it was my broken instrument.** The item claimed the guest was dying during block copying (at 80 %, 94 %, 99 %). **Nothing was dying.** Liveness was checked with `pgrep -c qemu-system-aarch64`, and `pgrep` **without `-f`** matches only the process name on macOS, truncated to 15 characters — `qemu-system-aar`. The pattern `qemu-system-aarch64` **could never match**, so every reading said "0 processes" regardless of the truth. `ps` showed **two live machines at 100 % CPU** with copying progressing (18→25 %, 86→90 %). The runs were not dying — they were **slow**, because they were competing for cores, and after each false reading I started another one, slowing them further. One of the "dead" runs finished **PASS**; the other stopped at 97 %, and the retained QEMU log says `terminating on signal 15 from pid 37386`, where 37386 is **the harness script itself** — a budget overrun, not a failure. **The lesson is exactly `CLAUDE.md` §5.4:** prove the instrument before believing a negative result. I wrote that rule and broke it, three times in a row | ❌ |
| `R-F26` | **The release-signing key was lost and has been rotated** (`U-205`). `keys/eos-release.pub` (minisign `DCEC85BA6057ED4A`) was committed, and `docs/getting-started/install.md` and `docs/security/hardening.md` **instructed users** to verify downloads with it — while the owner confirmed he did not hold the private half. **Nothing broke silently:** `scripts/make-release.sh` fails safe without `MINISIGN_SECRET_KEY`, and unsigned requires an explicit `EOS_ALLOW_UNSIGNED=1` (`U-120`) — **but the documentation promised a verification that could not be delivered for any new release.** Not a code defect: a gap between a promise and a capability. **Correction to the first version of this entry (`U-192`):** I wrote that the key ships in the image, counting two `grep` hits for `eos-release` in `config/*/eos.toml`. **Both referred to a comment about a different file** — `/usr/share/eos/eos-release`, the release identifier. Checked in the **running image**: `/usr/share/eos/` contains only `eos-release`; the minisign key is **not** in the image. That lowered the cost of rotation: the public key lives only in the repository, so replacing the file is enough and requires no rebuild and no re-imaging of clients. **Done:** the operator rotated it. The new key `8A627C8113176141` is in `keys/eos-release.pub`, the old `DCEC85BA6057ED4A` moved to `keys/wycofane/` — **retired, not deleted**, so what it signed can still be verified — and the private half lives outside the repository and is untracked. The integrity gate confirms no secret material in tracked files. The full signing round trip is the operator's to run, since the key is passphrase-protected `[P1·XS·🔑]` | ✅ |
| `R-F27` | **Secure Boot blocked installation on a typical PC.** **One of the four contradictions between the predecessors** — the old English roadmap carried ⏳ while v2 carried ✅ — and it is **stale by two milestones**; resolved as ✅ against the tree. The original finding: `recipes/core/bootloader/recipe.toml` built `bootloader.efi` and **nobody signed it**; `pesign`, `sbsign` and `shim` appeared nowhere in the repository. Every UEFI machine leaves the factory with Secure Boot on, so an unsigned `bootloader.efi` is **rejected by firmware** and the user must disable Secure Boot in the BIOS to boot the medium at all. That was the loudest obstacle to leaving QEMU, and it had never been a roadmap item — the roadmap listed drivers and test matrices, but not the boot chain. **Mechanism proven (`U-206`):** `scripts/eos-sign-bootloader.sh` signs with our own key and `scripts/eos-secureboot-proof.sh` proves it end to end under QEMU with real Secure Boot firmware (edk2) on throwaway keys, in three cases: our key + signed → boots ("E-OS Bootloader 1.0.0"); our key + unsigned → rejected; foreign key + our signature → rejected. Boot happens if and only if signed **and** trusted. **Integration closed and proven end to end (`U-207`, `U-208`):** signing moved into the recipe, at `cook` time, when the operator provides a key in `build/sb-signing/` (outside the repository), otherwise degrading gracefully to unsigned with an explicit message. **An earlier error, corrected:** I first signed the file produced by `--write-bootloader`, but the installer takes the ESP bootloader from `bootloader.pkgar` (`fetch_bootloaders`), so the ISO went out with an unsigned ESP and Access Denied under SB. Fixed at the source. Both media are now covered: live ISO **and** installed `harddrive.img` boot under Secure Boot with our key and give Access Denied with a foreign one. Deployment note: signing happens only on a fresh `cook`, so `scripts/eos-sb-setup-key.sh` invalidates the bootloader package to force re-signing on the next build. Verified in the tree today: `recipe.toml:110-130` calls `sbsign` then `sbverify`; `recipes/core/bootloader/sbat.csv` exists. Tracked onward as `V2-N03` ✅ `[P1·L·⚙️→🖥️]` | ✅ |
| `R-F28` | **`scripts/ventoy.sh` cannot produce an E-OS image.** The only USB-preparation script has hard-coded `ARCHS=(i686 x86_64)` and `CONFIGS=(demo desktop)`; `CONFIG_NAME=eos` never appears in it, and `i686` is rewritten to `i586`. A script that **cannot work** for this project is worse than no script, because it looks like a ready path. **Recommendation unchanged: consider deleting it rather than fixing it** — `dd` is the canonical route (`installer.md` §10 item 9) `[P2·S·🖥️]` | 🔴 |
| `R-F30` | **A gate on the shipped NetSurf artefact** (#28, minted 2026-09-03 — cited by `R-D06` and §3.0 since 2026-09-02 without a row). The recipe builds a PIE with the E-OS patches; the staged `netsurf-fb` on both architectures is upstream's `ET_EXEC` prebuilt at `0x400000` with a foreign `commit_identifier`. Gate: after `cook`, `readelf -h` on the staged binary must say `DYN`, and the binary must carry the E-OS patch marker; negative control = the current prebuilt goes red. Until green, `R-D06` stays 🟡 `[P1·S·🖥️]` | 🔴 |
| `R-F29` | **`scripts/eos-build.sh:72` runs the build through `tail -3` inside `bash -lc` without `set -o pipefail`.** *Newly minted in this merge; neither predecessor carried it as an item.* Line **59** sets `set -o pipefail` for the host-tools build; line **72**, which runs `make CI=1 ARCH=$ARCH CONFIG_NAME=eos all build/$ARCH/eos/$MEDIUM_NAME 2>&1 \| tail -3`, does not — so the build's exit status is `tail`'s. This is `CLAUDE.md` trap **P-3** live in the build script, and it is the same mechanism that let `cargo: command not found` scroll past under `set -e` (`U-224`). The bootloader recipe's own comment names the output half of this defect — *"`scripts/eos-build.sh` pipes make through `tail -3`, so the warning never reached the operator"* — while the exit-status half is still open. **Stated precisely, because the script is not defenceless:** line 72 has no `\|\|` guard, so a failed `make` returns `tail`'s zero; what catches the worst case is a *downstream* check comparing the mtimes of `harddrive.img` and the medium before and after, which refuses to export unchanged images when a Secure Boot key is present. That guard fires only when **both** images are untouched, so a `make` that fails **after** writing one of them still passes. Fix: add `set -o pipefail` on the container side of line 72, as line 59 already does. Negative control: break the make target and confirm the script exits non-zero `[P1·XS·🖥️]` | 🔴 |
| `R-F31` | **[refuted 2026-09-05 at the driver level — the raw path is correct; what is left is a `fatfs`-probe failure with no explanation]** The row said `nvmed` partition entries (`1pN`) *return a wrong sector on seek-then-read*. Measured again with the reader the row itself asked for (`dowody/rf31-seekread-2026-09-05/reader/`, `pread` vs `lseek`+`read`, 512 B at offsets 0, 512 and 6656 on an installed disk from the `!133` image, `disk.pci-0000-00-05.0-nvme/1p1`): **both calls return byte-identical data, and the data is right** — a full-sector FNV hash of each read equals the hash of the same offset in **the installed disk image** on the host (`xbuild/pr004-onimage/smoke-keep/install-smoke-images/target.img`: `8416d7bde6b52680`, `184fcdac50be81e5`, `b0e4cf72b4abc8e2`). Name that image: on today's *installer* image the third hash is `1bfd588956c4cd57`, because five bytes differ — the `CrtTimeTenth`/`CrtTime`/`WrtTime` fields of the `EFI` 8.3 entry — while the LFN entry itself is identical. The probe's multiplier is `0x1000000001b3`, which is the FNV-64 prime `0x100000001b3` **with one hex zero too many** (about sixteen times it, not exactly — 2^44 + 0x1b3 against 16 × prime = `0x100000001b30`); both sides must use the same constant to reproduce. The bytes the original probe called *mangled* — `41 45 00 46 00 49 00 00 00 ff ff 0f 00 2d ff ff` at partition offset 6656 — are a **valid VFAT long-name entry for `EFI`**: sequence byte `0x41`, attribute `0x0f` at offset 11, the characters `E`, `F`, `I` in UTF-16LE. A FAT root directory is supposed to look like that. **Control on a disk whose every request is logged:** the same reader against the file-backed `disk.image0` served by `imgd` (`R-818`, §15 row 30) shows `pread` and `lseek`+`read` agreeing and the offsets translating correctly — offset 0 → `read block=64`, 512 → `block=65`, 6656 → `block=77`, i.e. partition start 64 plus 0/1/13. **Also measured, and it explains why the original comparison was impossible:** the whole-disk node `1` cannot be opened while its partitions are in use — `open` → `errno 37 (ENOLCK)`, not the `EINVAL` the first row reported (that `EINVAL` came from `od`, i.e. the uutils layer, `R-F34`). **What the original probe actually saw, worked out from the log the row cites:** `verify-24` shows `fatfs` mounting the ESP correctly (`fat type: Fat12`, `volume id: 0x12345678`, `volume label: "NO NAME"`) and then printing the root directory as **sixteen identical entries** — `1174422849  AE F I  . ..` repeated, then `(16 entries)`. `1174422849` = `0x46004541` = the little-endian first four bytes at offset 6656 (`41 45 00 46`), and the name column is bytes 0..11 of that same LFN entry read as an 8.3 name; the probe prints `entry.len()`, i.e. bytes 28..32 of the entry. So the driver handed over a correct sector and the probe rendered one LFN slot sixteen times — not a wrong sector. **The reason is now known, one layer above the driver — `R-F38`:** the disk scheme silently rounded a read offset down to the block boundary, so each 32-byte directory entry the probe read at 6656+32k was served the same 32 bytes. Neither the driver nor the probe was at fault; `SchemeAsync::read` dropped the remainder of `offset / block_size`. Measured on the ESP of an installed disk: offsets 6660 and 6688 returned the bytes of 6656 with no error, and after the fix (`eos-base!5`, `e31fda3a`) they return `EINVAL`. The row's original instinct — *something below the probe returns the wrong bytes* — was right about the fact and wrong about the layer, and my first correction of it (blaming the probe, `!157`) was wrong in the other direction. Evidence: `dowody/rf31-seekread-2026-09-05/` (three guest runs, the reader) and the originals in `dowody/s15-qemu-2026-09-05/{rows-24-25-29-run3,verify-24}-serial.log` | 🔴 |
| `R-F32` | **[fixed 2026-09-05 — `eos-base!2` (`e8e1b9b5`), pin bumped in this repo; the row was narrower than the defect]** `driver-block`'s `DiskWrapper` never clamped a request that starts inside the device and reaches past its end — it checked only that the buffer length is a whole number of blocks and, for partitions, that the **start** block is in range. Two consequences, both measured. **(1) The medium end** (what the row was minted for, §15 row 27): with `probe.iso` on the ICH9 AHCI port, whole-device reads (`cp`, `cat`, `sha256sum`) stopped at 917 504 B of a 921 600 B disc with `[@ahcid::ahci::hba:451 ERROR] IS 40000000 … TFD 5041` (sense key 5, ILLEGAL REQUEST); reproduced without any ATAPI hardware on a file-backed disk whose driver logs every request (`imgd`, §15 row 30), where a 1024-byte read at the last block of a 1 MiB device arrived as `read block=2047 len=1024` and was refused. **(2) A partition-boundary leak, not in the original row:** a read that crosses a partition's end returned the **neighbouring partition's blocks**. On an installed disk, reading 2048 B at partition offset 1 047 552 of the ESP (`1p1`, LBA 2048–4095) returned `n=2048` whose second half begins `RedoxFS\0…` — the next partition's filesystem header — with the full-buffer hash equal to the disk image's bytes across the boundary. After the fix the same call returns `n=1024`, the ESP's own tail, and in-range reads are byte-identical (512 B and 1024 B answers unchanged). **Fix:** clamp `read` **and** `write` to what is addressable (`Disk::size()` in bytes, `Partition::size` in blocks) and return the short count; a start at or past the whole device's end returns `Ok(0)`, a start past a partition's end keeps `EOVERFLOW`. The write side matters more than a wrong answer: an unclamped write crossing a partition's end would land in the next partition. **Gate:** `cook base - successful` (`source_identifier = abc4e3f1…`, merged as `e8e1b9b5`), image rebuilt after clearing `repo.tag` and the image products (P-2/P-22: `make all` otherwise says *"Nothing to be done"*), `ci-install-smoke.sh` **PASS** — which exercises the boot path, since RedoxFS reads through this very wrapper — and the before/after table on disks installed from the two images. **The medium end, demonstrated fixed 2026-09-05 (this was missing when the row first said "fixed"):** with `imgd` rebuilt against the clamped `driver-block`, a 1024-byte read at block 2047 of a 2048-block device is handed to the disk as `read block=2047 len=512` and the caller gets `n=512` with the right content (`EFI PART`, the backup GPT header); before the clamp the same call arrived as `len=1024` and was refused (`errno 22`). The earlier "after" run on the file-backed disk showed the old behaviour only because `imgd` links its **own** copy of `driver-block` from the git dependency, not the image's — that log is kept as `filebacked-after-stale-imgd-serial.log`. **Follow-up, `eos-base!4` (`a685dbde`):** the first clamp made a **write** whose start is past the end answer `Ok(0)`, mirroring the read path — for a writer that is a silent zero-byte success and a `while written < len` caller would spin forever, so it now returns `EOVERFLOW`, matching the partition arm; `ci-install-smoke.sh` PASS on the image built from it. A write issued past the end on a live device was **not** measured: nothing in the image can seek-write. **Not re-measured:** the ATAPI disc itself (the fix is in the shared wrapper, above the driver; `disk_atapi.rs` `read()` advancing `sector += blk_len` for requests ≥ 64 blocks is still an unexamined suspect for other symptoms). Evidence: `dowody/rf32-clamp-2026-09-05/` and the originals in `dowody/s15-qemu-2026-09-05/{row-27-ide-cd-serial-run2,verify-27}-serial.log` | ✅ |
| `R-F33` | **`usbscsid` binds a USB optical drive but no block read ever returns, and the reported size is one block short** (minted 2026-09-05 from §15 row 28; the size half now has a cause and a proposed fix, the blocking half is untouched). QEMU `usb-storage,removable=on` with `probe.iso` on `qemu-xhci`: `xhcid` loads the subdriver, `usbscsid` reports `Inquiry version: 5` and `read_capacity10 … max_lba 449, block_len 2048`, the scheme `disk.usb-usb.pci-0000-00-02.0_xhci+2-scsi/0` appears with size **919 552** for a 921 600 B disc, and then `od -j 32768 -N 64`, `head -c 2048` and the `fatfs` probe all block indefinitely (813 s in one session, still `Running` after 8 min in another); `^C` does not recover the shell; no `usbscsid: READ IO ERROR` line ever appears, only one `xhcid: Lost event TRB type 32, completion code: 1`. **Size half — cause found 2026-09-05:** the scheme size is `block_count * block_size` and `ReadCapacity10ParamData::block_count()` returned `max_lba` **unchanged** (`usbscsid/src/scsi/cmds.rs:451-453`); SBC's READ CAPACITY (10) returns the address of the *last* logical block — hence the field's own name — so the count is that address plus one, and 449 blocks is exactly 450 minus one. Fix proposed in **`eos-base!3`** (`0688e2c0`, `u32::from_be(self.max_lba) as u64 + 1`, widened because `max_lba + 1` overflows `u32` at the `0xffff_ffff` "ask READ CAPACITY (16)" sentinel this driver does not implement); the mode-sense block descriptors' own `block_count()` are true counts and are untouched. **That MR is deliberately NOT merged and the pin is NOT bumped:** the change compiles (`cargo check -p usbscsid` clean), cooks (`source_identifier = 0688e2c0…`) and reaches the image (`/usr/lib/drivers/usbscsid` `cmp`-identical to the cooked binary), but **the number it produces has never been seen in a guest** — in two boots of this harness (`usb-storage` on the `qemu-xhci` that also carries `usb-kbd`) the driver announces itself (`USB SCSI driver spawned with scheme usb.pci-0000-00-02.0_xhci, port 2, protocol 80`) and then prints nothing at all: no `Inquiry version:`, no `read_capacity10`, and `/scheme/disk.usb-…-scsi` answers `No such device`. **The same happened on an image without the change**, so it is this topology, not the fix — and it puts the failure *earlier* than the original session, which is consistent with the blocking half. Next probe for the size half: reproduce the original session's device line (a dedicated controller, no `usb-kbd` on it) and read `ls -la` on the scheme; for the blocking half: instrument `usbscsid`'s read path or capture the xHCI TRB ring. Evidence: `dowody/rf33-usbscsid-2026-09-05/` (both bind attempts and the harness line) and the originals `dowody/s15-qemu-2026-09-05/{row-28-usb-cd-serial,verify-28-serial}.log` | 🔴 |
| `R-F34` | **`dd` in the image refuses to run before it touches a file, because it is dynamically linked — and `status=none` is the whole workaround** (minted 2026-09-05, cause proven the same day; the first version of this row named the right guard but the wrong reason for it — see below). `/usr/bin/dd` is a symlink to the multicall `coreutils` (`uutils coreutils 0.7.0`, recipe `core/uutils`, staged build's `source_identifier` = the pinned `1f7c81f5`), **an ELF PIE, dynamically linked, interpreter `/lib/ld64.so.1`, `NEEDED libc.so.6`**. It prints `dd: write error` and exits 1 for `of=FILE`, `> FILE` and `\| cat > FILE` alike, with every input tried — 11 copy jobs across five logged guest sessions, every one refused, plus a dedicated boot of nine `dd` invocations (one `--version` and eight copy jobs, seven of them refused). **Chain, each link measured:** (1) `dd.rs:1516-1519` is a *startup guard*, not an I/O path — `if uucore::signals::stderr_was_closed() && settings.status != Some(StatusLevel::None) { return Err(USimpleError::new(1, "write error")) }` — placed before the input and output are opened, which is why every variant fails identically and nothing is written (the `> FILE` variant does leave a 0-byte file — the shell creates it before `dd` runs) (it is the only site that can emit a **bare** `dd: write error`: the crate's other occurrence of that string is the Fluent message `dd-error-write-error` in `locales/en-US.ftl:123`, consumed at `dd.rs:830` through `map_err_context`, and uucore renders that as `dd: write error: <cause>`). (2) `stderr_was_closed()` reads a static filled by an `.init_array` constructor before `main`: `signals.rs:490-493` stores `fcntl(STDERR_FILENO, F_GETFD) == -1`. (3) **That `fcntl` fails only in a dynamically linked binary.** A probe whose constructor mirrors uucore's, built twice from one source and run in one boot: **dynamic PIE → `EARLY fcntl(2, F_GETFD) = -1, errno 9 (EBADF)`, `stderr_was_closed()` would be `true`**; **static → `= 0, errno 0`, would be `false`**; in both builds the same call from `main` returns 0, so a probe that only asks late (the first version of this one) reports the opposite of what `dd` sees. (4) `status=none` skips the guard: in the same boots `dd if=/dev/zero of=/tmp/d2.bin bs=512 count=1 status=none` writes 512 B, while the identical command without it leaves no file; control `head -c 512 /dev/zero > /tmp/h1.bin` → 512 B. **Consequence:** every §15 recipe and every Redox document that says `dd of=` works on this image once `status=none` is added; the write path itself is sound, and any *statically* linked build of the same uutils revision is unaffected. **Answered by `R-F37`:** the constructor runs before relibc's own `.init_array` entry, so the process is half-built — `fcntl` → `EBADF`, `open` → `ENOENT`, `getpid()` → `0`, while `write(2, …)` and `getenv` already work. Evidence: `dowody/rf34-dd-2026-09-05/` (`dd-variants-serial.log`, `fcntl-static-vs-dynamic-serial.log`, `fcntl-static-only-serial.log`, the probe source, both upstream sources at the pinned revision) and the original sightings in `dowody/s15-qemu-2026-09-05/{kit3,kit4,rows-24-25-29-run2,verify-29}-serial.log` and `row-27-ide-cd-serial-run2.log` | 🔴 |
| `R-F35` | **`/etc/group` is installed mode `0600`, so `id` fails for an unprivileged user** (minted 2026-09-05; `user`, uid 1000, is the only non-root account in `/etc/passwd`, and the root-owned `0600` mode implies the same for any other). On a disk installed from the image built on the `!133` branch (`eos-build.sh` 12:07–12:10, Guard pin `3bcde7d9`, i.e. the content of `!133` before its 12:29 merge) and booted in QEMU 11.0.2, `su user` then `id` prints `id: Permission denied (os error 13)` and exits 1, while `id -u` (1000), `id -un` (`user`), `id -g` (1000), `id -G` (`1000 1000`) and `whoami` all succeed — only the forms that resolve a **group** name fail, because they read `/etc/group`. Mechanism, read in the shipped source (`recipes/core/userutils` `fcc36614`, `src/bin/id.rs:154-158`): plain `id` builds **both** `AllUsers::basic(…)` (which reads `/etc/passwd`, 0644) **and** `AllGroups::new(…)` (which reads `/etc/group`, 0600) and `unwrap_or_exit(1)`s on either, while `id -un` and `whoami` take the user-only path — so a *user* name resolves fine. (`id user` is not a supported form of this `id` at all: `error: Found argument 'user' which wasn't expected`.), which `ls -la` shows as `-rw------- 1 root root 45` next to `/etc/passwd` `-rw-r--r--` and `/etc/shadow` `-rw-------`; `cat /etc/group` as the user is `Permission denied`, `cat /etc/passwd` works. **Cause proven by mutation in the same boot:** root `chmod 644 /etc/group` → the same `su user; id` prints `uid=1000(user) gid=1000(user)` and exits 0. Source: `recipes/core/installer/source/src/installer.rs:275-277` writes `/etc/group` with `.with_mod(0o0600, 0, 0)` (the same mode as `/etc/shadow` at `:258-260`, where it is right); the line is inherited from upstream Redox (`ee5a94d`, 2025-09-26) into the `eos-installer` fork (pinned `713ca48c`), not an E-OS hardening decision — on every other Unix `/etc/group` is world-readable and only the shadow files are not. Also seen earlier the same day on a **different installed disk** (`dowody/s15-qemu-2026-09-05/trust3-serial.log`, RedoxFS `a81e223b…`, the filesystem of `trust-installed-serial.log`) — the first version of this row called that log "the live image", which a sceptic refuted on 2026-09-05; the live image was never tested for this. Consequences: any unprivileged program that maps a gid to a name fails outright (rc 1 in every observed case; nothing was seen to answer wrongly); the `sudo` group (gid 1, member `user`, `config/base.toml:252`) cannot be read by that user. Not measured: which relibc call returns EPERM (no `strace`), and whether `ls -l` group names, `stat` or the GUI are affected; `groups(1)` is not in the image at all (`ion: command not found: groups`). Fix shape (owner 🔑, it loosens a mode): `0o0644` for `/etc/group` in `eos-installer`, `/etc/shadow` unchanged. Evidence: `dowody/rf35-id-eperm-2026-09-05/{run1,run2}/serial.log` + the two driver copies | 🔴 |
| `R-F36` | **[fixed 2026-09-05 — `eos-kernel!2` (`83fd2534`), pin bumped in this repo]** The kernel panicked on the shutdown path — `attempt to subtract with overflow` in `userspace_acpi_shutdown()` — in **6 of the 17 preserved pre-fix shutdown runs of 2026-09-05** (~35 %; the first sighting was 2 of 5 at 14:00, and a sceptic later counted every run on the pre-fix filesystem `55455aea…`), all on disks installed from the `!133`-branch image, QEMU 11.0.2: `KERNEL PANIC: panicked at src/arch/x86_shared/stop.rs:88:12` right after `Waiting one second for ACPI driver to run the shutdown sequence.`, backtrace `syscall_instruction → sys_write → SysScheme::kwriteoff → FILES::{closure#1} → panic_handler_inner`, faulting process `/usr/bin/shutdown`, `HALT` on CPU #1. Line 88 was `if current - initial > time::NANOS_PER_SEC`, both values from `time::monotonic(token)` in the one-second wait loop. **Why the clock steps backwards, read off the source:** `monotonic_absolute()` is `offset + hpet_or_pit()` (`arch/x86_shared/time.rs:12-13`) where `OFFSET` accumulates whole ticks and `hpet_or_pit()` counts nanoseconds *since the last timer interrupt*; the two reads are not atomic, so an interrupt landing between them pairs the old offset with the already-reset counter and the value drops by up to one tick. It trapped rather than wrapping because of an E-OS hardening choice — the release kernel sets `overflow-checks = true` (`Cargo.toml`) — and the abort killed `kstop()` **before** its own fallbacks, so on a machine whose ACPI driver is absent, slow or crashed nothing else would have run (both measured machines still powered off, because `acpid` had already written S5). **Fix:** `current.saturating_sub(initial)` — a backwards step counts as "no time has passed" and the loop waits out the real second. **Gate, run before the merge:** the patched kernel cooked (`cook kernel - successful`), the image rebuilt from it carries that exact binary (`/usr/lib/boot/kernel` `cmp`-identical to the cooked file, sha256 `e802020faea11040…`, 1 297 808 B), `ci-install-smoke.sh` **PASS**, and **five shutdown trials on fresh clones of the installed disk: `panic=0 overflow=0`, clean power-off every time** (`dowody/rf36-shutdown-2026-09-05/`), and three later runs on post-fix images are clean too — eight clean post-fix shutdowns against a 6-in-17 baseline. Eight clean runs alone would be ~3 % likely by chance at that rate (five alone, ~12 %) — what makes it a fix is that `saturating_sub` cannot underflow; the runs show nothing else broke. Not changed: the same pattern at `syscall/debug.rs:266` sits behind `feature = "syscall_debug"`, which the release build does not enable. **Reading the archived trials:** each `result.txt` ends `VERDICT: FAIL` — an artefact of reusing `serial-selftest.sh`, which looks for `GUARD-SELFTEST-OK` that these command sets never run; the lines that matter in them are `panic=0`, `overflow=0` and `poweroff: clean` | ✅ |
| `R-F37` | **In a dynamically linked binary, `.init_array` constructors run before relibc's own init entry, so the process is half-built: `fcntl` → `EBADF`, `open` → `ENOENT`, `getpid()` → `0`, while `write(2, …)` and `getenv` already work** (minted 2026-09-05; this is the layer under `R-F34`). relibc registers its own `.init_array` entry (`start.rs:82-84` → `init_array()` at `:107`, which sets up the allocator, stdio, `environ` and pthread) and says so in a comment: *"we cannot guarantee if init_array runs first or if relibc_start runs first"*. For a **dynamic** executable the loader walks `DT_INIT_ARRAY` in order (`ld_so/dso.rs:466`), so a constructor linked ahead of relibc's runs on an uninitialised process. Measured in the guest with a probe built from one source as a dynamic PIE (`dowody/rf34-dd-2026-09-05/ctor-capabilities-serial.log`, `fcntlprobe/main-ctor-capabilities.rs`): from the constructor `fcntl(2, F_GETFD)` = `-1` `errno 9 (EBADF)`, `open("/tmp/ctor-probe", O_CREAT\|O_WRONLY, 0644)` = `-1` `errno 2 (ENOENT)` **and no file is created**, `getpid()` = `0`; but `write(2, "X", 1)` = `1` (the byte reaches the console) and `getenv("HOME")` is non-null. The same `fcntl` from `main` returns `0`, and a **statically** linked build of the same source gets `0` already in the constructor — the A/B is in `fcntl-static-vs-dynamic-serial.log`. **Consequences:** any ported program that does real work in a constructor — Rust crates with `#[link_section = ".init_array"]`, C++ global constructors that open files, GNU-style `__attribute__((constructor))` — sees ENOENT/EBADF from a process that looks alive; `R-F34` (`dd` refusing every job) is exactly this, one layer up. **Blast radius, counted 2026-09-05** over every ELF in the cooked stages of this build tree (`readelf -S`, `.init_array` size / 8; the cooked subset, not the whole image): **157 dynamic** — that half is stable across re-runs — plus the static ones, whose count moves with whatever is being cooked while the census walks the stages: **39** when this was counted, 32 and then 43 on re-runs an hour later (a build container was cooking at the time), so treat the total as a snapshot, not a constant. Of the dynamic ones **145 carry exactly one entry — relibc's own — and 12 carry more**, i.e. a foreign constructor runs somewhere in their startup: `core/uutils/coreutils` (**68**), `wip/rs/uutils-procps/procps` (15), `dev/gcc13/*` (6–47 across **eight** binaries), `web/netsurf/netsurf-fb` (3), `tools/patchelf/patchelf` (2). Every static binary has two entries and is unaffected. In the image's own package chain (`config/x86_64/eos.toml` → `desktop.toml` → …) `uutils`, `uutils-procps`, `netsurf` and `patchelf` are shipped; `gcc13` is declared only in `x86_64/ci.toml`, `aarch64/ci.toml` and `x86_64/jeremy.toml` (and reaches `x86_64/full.toml` through its `include`; it is commented out in `i586/ci.toml:228` and `riscv64gc/ci.toml:229`). A foreign constructor is not by itself a failure — `R-F34` is the only case measured so far where one *acts* on what it captured — but any of these can read a half-built process. **Still not measured:** whether the order is fixed or link-order dependent, whether `ld.so` could run relibc's entry first, and what the other eleven constructors actually do. Nothing in the image was changed to test this | 🔴 |
| `R-F38` | **[fixed 2026-09-05 — `eos-base!5` (`e31fda3a`), pin bumped in this repo] The disk scheme silently rounded a read or write offset down to the block boundary, so a caller that seeked into a block was served the block's start — different data, no error.** `SchemeAsync::read`/`write` in `driver-block` computed `offset / block_size` and dropped the remainder (`lib.rs`, the `Handle::Disk` and `Handle::Partition` arms of both). Measured on an installed disk, `/scheme/disk.pci-0000-00-05.0-nvme/1p1` (the ESP), 512-byte reads compared byte-for-byte with the disk image on the host: offset 6656 (aligned) correct; **offset 6660 (+4) and 6688 (+32) returned the bytes of 6656** although the truth at those offsets hashes `27cde8d6957ba110` and is `EFI     ` (the 8.3 entry) respectively; offset 7168 (the next block) correct again. **This is the mechanism behind `R-F31`:** a `fatfs` probe reading a FAT root directory 32 bytes at a time got the same 32 bytes sixteen times, printed sixteen identical entries, and the whole thing was filed as "`nvmed` returns a wrong sector on seek-then-read" — the driver was innocent, the probe was innocent, and one layer above both was rounding the offset. **Fix:** an offset that is not on a block boundary now returns `EINVAL`, the same answer the buffer length has always got for not being a whole number of blocks; after the fix the same four reads give correct / `EINVAL` / `EINVAL` / correct. Rejecting is the conservative choice — a caller that appeared to work was reading the wrong bytes — but it **is** a behaviour change for anything that relied on the rounding. **Gate:** `cargo check -p driver-block` clean, `cook base - successful` (`source_identifier = 262a99f8…`), image rebuilt, `ci-install-smoke.sh` **PASS** (RedoxFS reads block-aligned, so the boot path is untouched), and the before/after table on disks installed from the two images. Evidence: `dowody/rf38-unaligned-offset-2026-09-05/` | ✅ |
| `R-F39` | **An adversarial audit of the storage stack found 25 confirmed places where a request is silently reshaped instead of honoured or refused — one of them in the clamp added the same day, fixed as `eos-base!6` (`3c2ce2e8`); four more (`R-F40`, `R-F41` the same night, `R-F42` and `R-F43` on 2026-09-06) were measured in a guest and two (`R-F44`: #22 and #19, one row) were measured against the pinned source and **fixed** in `eos-redoxfs!2` (`81de36dc`), three more (`R-F45`, #6; `R-F46`, #7; `R-F47`, #17 — **fixed** in `eos-base!9`) were measured in a guest, `R-F48` (#24, **fixed** in `eos-redoxfs!4`) against the library, and `R-F49` (#25), `R-F50` (#5) `R-F51` (#11, **fixed** in `eos-base!10`) `R-F52` (#8) `R-F53` (#3) and `R-F54` (#18, **fixed** in `eos-base!11`) in a guest and `R-F55` (#15), `R-F56` (#9), `R-F57` (#14) and `R-F58` (#16) against the pinned library `R-F61` (#23) and `R-F62` (#10) in a guest, each with a row of its own, so **3 of the 25 have no row of their own — #1, #12 and #13** — which is not the same as three being unfixed. **Thirteen of the 25 are fixed** — the eleven rows carrying ✅ (`R-F40`, `R-F42`, `R-F43`, `R-F44`, `R-F47`, `R-F48`, `R-F51`, `R-F54`, `R-F55`, `R-F58`, `R-F62`), of which `R-F44` covers two findings (#22 and #19), plus finding #1, fixed as `eos-base!6` and never given a row — so **twelve remain open**, and the rest are registered-but-open. Read the individual rows for status; this sentence has been wrong twice by counting rows where it meant findings, and once by going stale after a fix landed. Method (2026-09-05, `dowody/audit-silent-reshape-2026-09-05/`): five readers, one per layer — `driver-block`'s scheme, `partitionlib`, `nvmed`+`ahcid`, `usbscsid`/`ided`/`virtio-blkd`/`raid1d`/`lived`, and RedoxFS where it meets the block layer — each finding then attacked by an independent verifier whose default answer was REFUTED; **31 verified, 25 confirmed, 6 refused**. The archetype is `R-F38`. **Fixed:** the end-of-medium clamp computed `(available * block_size) as usize`, a byte count truncated modulo 2^32 on the tree's i586 target, so at offset 0 of a 4 GiB medium `max_len` became 0 — a false EOF for a reader and a spinning `while written < len` for a writer; E-OS ships only 64-bit, so no image was affected. **Open — the 3 with no row of their own, each triaged 2026-09-06 for whether it can be measured today and each found blocked, with the blocker named so nobody re-triages them:** *silent wrong count:* `usbscsid` turning xhcid's `bytes_transferred` into a CSW residue; *silent success:* `ahcid` swallowing three EIO paths into `size = 0`; and **finding #1**, the end-of-medium clamp — which is a different case from the other two: it was **fixed the same day** as `eos-base!6` (`3c2ce2e8`) on a source read alone and never measured, because it is latent only on a 32-bit target and E-OS ships nothing but 64-bit, so there is no image on which it can be reproduced at all. **Why each of the two remaining blocked findings is blocked, verified against the pinned source rather than assumed:** *`ahcid`'s three EIO paths (#12)* — its ATAPI sibling #10 is no longer here: it was measured in a guest and fixed, as `R-F62`, once the harness was shown to present an ATAPI disc. What still blocks #12 is that `ahcid` has no `[lib]` and no `src/lib.rs` (checked: `src/` holds only `main.rs` and `ahci/`), so nothing can depend on it; and the defect sits behind `Dma::zeroed`, which goes `alloc_and_map(…, &*VIRTTOPHYS_HANDLE)` → `memory_root_fd()` → `libredox::Fd::open("/scheme/memory/scheme-root")` (`common/src/dma.rs:137,183`, `common/src/lib.rs:41`), a path that does not exist on the container's Linux host, so a host probe panics before reaching the defective line. Stubbing `common` — which is what made `R-F58` reachable — does not work here: for `ided` the stubbed `Dma` is an opaque buffer the measurement never inspects, whereas `ahcid`'s state machine *is* `common::io::Mmio` plus `common::timeout::Timeout`, so a stubbed probe would measure the re-implementation, not the pinned code. *`usbscsid`'s CSW residue (#13)* — the wrong assignment is inside `BulkOnlyTransport::send_command`, and `BulkOnlyTransport` (`bot.rs:85-94`) holds concrete `&XhciClientHandle` and two `XhciEndpHandle`s with no trait and no generic, so there is no seam below the `Protocol` boundary that `R-F57`'s probe used; worse, the one host-callable function, `SendCommandStatus::bytes_transferred` (`mod.rs:34-36`), is **unchanged by the fix** — it returns 512 for `residue=3584, len=4096` both before and after, because the fix changes what `bot.rs` *stores* in `residue`, so no probe over that function can discriminate. **What each would actually need:** #12, a way to make IDENTIFY fail on a disk `ahcid` has bound — the device is no longer the obstacle (an ATAPI disc binds, and `R-F62` was measured through it), so what is missing is fault injection; #13, **not** a USB mass-storage path — that turned out to exist, once `-device qemu-xhci` is given an `id`; what blocks it is that `usbscsid` **stalls somewhere in the bulk-transfer path**, which is also the real reason `R-F33` has been blocked. **A claim of non-determinism made here has been withdrawn.** Instrumenting the driver (it has no logger and no `log::` call at all) was read as moving the stall point between three places. It did not: in both instrumented boots `ls` returned in 4.7 s with `Os { code: 19, … "No such device" }`, the guest printed `ALIVE` and shut down cleanly — **ENODEV, because `usbscsid` never reached scheme registration at all**, not a stall. The two behaviours split cleanly by image, not by timing: stock registers the scheme and then hangs on every access; instrumented never registers it. And the instrument is not neutral — three of its `eprintln!`s sit *inside* `BulkOnlyTransport::send_command`, between the CBW write, the data stage and the CSW read, writing to a 3-second-slowed serial console, so they are blocking I/O inserted into the very sequence under test. The instrumented runs bound how far stock `usbscsid` gets and nothing more. Not diagnosed: which side stalls (`dowody/harness-sata-and-usb-2026-09-06/`). And the AHCI half of #10/#12 is less blocked than stated: a plain `ide-hd` on q35's `ide.0` comes up as `SATA`, publishes `0` and a parsed `0p0`, and returns the medium's real bytes — an ATAPI *disc* is still what #10 needs, but the bus is live. The other findings of the 25 have rows of their own and are followed there, not here: `R-F40` (GPT CRC failure falling back to the protective MBR, fixed), `R-F41` (partition bounds never intersected with the device), `R-F42`/`R-F43` (truncate leaving bytes readable and leaking the record, fixed), `R-F44` (`DiskCache` counts, fixed), `R-F45` (`start_lba`/`size` copied without validation), `R-F46` (MBR extended containers), `R-F47` (`virtio-blkd` units, fixed), `R-F48` (`add_dir_entry` dropping entries, fixed), `R-F49` (`fpath` truncation), `R-F50` (GPT slot keys), `R-F51` (`nvmed` chunking, fixed), `R-F52` (the GPT entry stride), `R-F53` (the block-size gate), `R-F54` (`raid1d`'s `usable_bytes`, fixed), `R-F55` (the WRITE(16) byte order), `R-F56` (the zeroed GPT type GUID), `R-F57` (the ignored CSW status), `R-F58` (the LBA28 high bits), `R-F61` (the fmap padding), `R-F62` (the ATAPI chunk loop). **Twenty-two of the 25 have since been measured** — fifteen in a running guest (`R-F40`, `R-F41`, `R-F42`, `R-F43`, `R-F45`, `R-F46`, `R-F47`, `R-F49`, `R-F50`, `R-F51`, `R-F52`, `R-F53`, `R-F54`, `R-F61`, `R-F62`) and seven against the pinned source, where the claim was about what a function returns or drops (`R-F44` and `R-F48`, both fixed, and `R-F55`, `R-F56`, `R-F57`, `R-F58`); the remaining 3 have not been — the **two** blocked ones (#12 and #13) **and finding #1**, the end-of-medium clamp, which was fixed as `eos-base!6` on a source read alone and is latent only on a 32-bit target, so it cannot be measured on a 64-bit image at all, and each needs its own row and its own measurement before it is called a defect of E-OS rather than of the code as read; the report gives every one a file:line, a failing scenario and the command that would settle it | 🔴 |
| `R-F40` | **[fixed 2026-09-06 — `eos-base!7` (`2ad9af07`), pin bumped in this repo] A GPT whose header CRC fails is silently republished from the protective MBR as one whole-disk partition** (minted 2026-09-05 from the `R-F39` audit, then **measured in a guest**). `partitionlib::get_partitions` (`src/partition.rs:74-76`) discards every GPT parse error into `.or_else(\|_\| get_mbr_partitions(device))`, and `Entry::is_valid` (`src/mbr.rs:54-55`) never looks at `sys_id` — so the protective MBR entry (type `0xEE`, which exists only to stop legacy tools from touching a GPT disk) is taken for a real partition. Measured on a file-backed disk served by `imgd` (`R-818`) from a crafted image: `probe-badcrc.img` is the 1 MiB two-partition probe image with one byte of the disk GUID flipped in **both** the primary and the backup header, so the stored header CRC `39d757ef` no longer matches the computed `b95deb1b`. In the guest the daemon logs `read block=1` (the GPT header) followed by `read block=0` (the MBR), and `ls /scheme/disk.badcrc` shows **`0  0p0`** — one partition of **1 048 064 B**, i.e. the whole 1 048 576 B medium minus its first block, `start_lba = 1`, exactly the protective entry. The two real partitions are gone and nothing reports an error. Consequence: a disk whose partition table is damaged is presented as a single valid partition covering everything — a formatter, a filesystem probe or an installer sees a plausible disk instead of a broken table. **Fixed** in `eos-base!7` (`2ad9af07`), pin bumped in this repo: `Entry::is_valid` now refuses `sys_id` `0xEE` (protective) and `0x00` (an unused slot), with three unit tests — two of them fail on the old rule (*"the protective MBR entry was published as 1 partition(s)"*, *"a type-0 entry was published"*) while the third, an ordinary `0x83` plus an ESP `0xEF`, passes both before and after. Re-measured in a guest on the same crafted image, served by an `imgd` linking `driver-block` at the new revision: `ls /scheme/disk.badcrc` now shows **`0` alone** — the whole 1 048 576 B medium and **no partition** — where it showed `0  0p0` before. The daemon still logs `read block=1` then `read block=0`, so the fallback to MBR still happens; it now finds nothing publishable there. **Not measured:** whether a real GPT disk in the wild ever reaches this path (the crafted image is the only case run); what the installer does with a disk that now publishes no partitions at all; and whether the fallback should happen at all when a CRC fails, which is a separate question and still open. Evidence: `dowody/audit-measured-2026-09-05/{badcrc-and-oversize-serial.log,probe-badcrc.img}`, `dowody/protective-mbr-2026-09-06/` | ✅ |
| `R-F41` | **A partition's size and bounds are taken verbatim from the table and never intersected with the device, so the scheme publishes — and serves — space the medium does not have** (minted 2026-09-05 from the `R-F39` audit, then **measured in a guest**). `driver-block`'s `blocks_available` bounds a partition request by `part.size` alone (`lib.rs:199-212`) and `fsize`/`fstat` multiply the same field by the block size (`:711`, `:613-614`); nothing consults `disk.size()`. Measured with `imgd` on `probe-oversize.img` — the same 1 MiB probe image whose first GPT entry declares LBA 64..100000 with **both CRCs recomputed, so the table is entirely valid** — booted from an image carrying the day's clamp: `ls -la /scheme/disk.over` reports `0p0` as **51 167 744 B on a 1 048 576 B medium** (48× the disk), and reads inside the declared-but-absent region are forwarded to the driver as out-of-range blocks: partition offset 1 015 296 → `read block=2047`, the last real block, correct content; offsets 1 015 808, 1 016 320 and 2 097 152 → `read block=2048`, `2049` and `4160` on a disk that has blocks 0..2047, each refused by the daemon's own bounds check (`errno 22` reaching the caller). With a real driver instead of a probe the same requests are what `R-F32` was minted for — an I/O error from the device, or worse on hardware that does not range-check. The clamp added in `eos-base!2` bounds a partition request to `part.size`; it cannot help when `part.size` itself is a lie. **Fix shape (not implemented):** intersect `part.start_lba + part.size` with `disk.size() / block_size` when the table is parsed, or clamp again in `blocks_available`; either is a behaviour change for a disk whose table overstates it. Evidence: `dowody/audit-measured-2026-09-05/{oversize-reads-serial.log,badcrc-and-oversize-serial.log,probe-oversize.img}` | 🔴 |
| `R-F42` | **[fixed 2026-09-06 — `eos-redoxfs!3` (`e0295a5d`), pin bumped in this repo] A file truncated to zero and extended back hands the caller its original bytes, and a remount does not clear them — the inline half** (minted 2026-09-06 from the `R-F39` audit, finding #21, then **measured in a guest**). For a node small enough to keep `NodeFlags::INLINE_DATA` (under 3968 B) `truncate_node_inner` does nothing on the way down — the deallocation arm is guarded `} else if !node.data().has_inline_data() {` (`transaction.rs:1843`), so only `size` is set and the bytes stay in the node — and nothing on the way up either, because the grow loop breaks immediately whenever `old_size % record_level.bytes() == 0` (`:1826-1833`), which zero is; `read_node_inner`'s inline path (`:1712-1747`) is bounded only by `node_size` against the whole `inline_data()` slice, so it copies out whatever the node still holds. Measured on the shipped `harddrive.img` (`sha256 9a3f3102…`) booted headless (q35, OVMF, one NVMe `serial=eos`, `-display none`), root over the serial line, files in `/home/root` — the installed RedoxFS root, not `/tmp`, which is a RAM scheme (`P-36`). **(a)** 18 bytes `SECRET000000-SECRE` written and fsynced; `ftruncate(0)` → `size 0` and a read returns 0 bytes; `ftruncate(18)` → the read returns **the identical 18 bytes** (`5345435245543030303030302d5345435245`) where POSIX requires zeros. **(b)** The same node with a hole: 200 B written, `ftruncate(0)`, `lseek(100)`, one byte `Z` written → the file is 101 B and **all 101 bytes are non-zero**, i.e. the pre-truncate content is readable in the hole. **(c)** A second boot of the same disk image with a read-only probe returns the same bytes — they are in the node on the medium, not in `DiskCache`. **Bound, measured in the same guest:** a plain `O_TRUNC` rewrite is unaffected — after `File::create` + 10 bytes the file reads exactly those 10 bytes, and extending it back to 200 gives zeros past them, because the 10-byte write left `old_size = 10`, which is not record-aligned, so the zero-fill loop does run. The defect needs the extend, or the sparse write, to start from a record-aligned size — in practice zero. **Fixed** in `eos-redoxfs!3` (`e0295a5d`): the shrink path now zeroes the inline area past the new size, so the grow path's "a null record pointer reads as zeros" assumption is true again; a regression test ships with it and fails on the old code with *"inline: 18 of 18 bytes survived the truncate"*. Re-measured in a guest on the image built at the new pin: all three cases — inline, record-backed and the hole — read back **all zeros**, the hole file's only non-zero byte being the `Z` written at offset 100; the image (`harddrive.img`, `sha256 999ad12d…`) boots to a shell in 32 s and powers off cleanly. **Not measured:** whether any shipped E-OS component leaves such a hole; whether the FUSE mount (`mount/fuse.rs:203`) behaves the same; and the fix does not repair a filesystem that already carries the stale bytes. `R-F43` is the record-backed twin and shares this row's grow-path half. Evidence: `dowody/redoxfs-truncate-2026-09-06/`, `dowody/redoxfs-truncate-fixed-2026-09-06/` | ✅ |
| `R-F43` | **[fixed 2026-09-06 — `eos-redoxfs!3` (`e0295a5d`), pin bumped in this repo] The same resurrection for a file too large to stay inline, by a different route: `truncate` never deallocates the last partial record — and the record is leaked when the file is deleted** (minted 2026-09-06 from the `R-F39` audit, finding #20, then **measured in a guest**). `truncate_node_inner`'s deallocation range (`transaction.rs:1845-1849`) is `size.div_ceil(record_level.bytes())..old_size / record_level.bytes()` — `div_ceil` on the lower bound but **floor division on the exclusive upper bound** — so for any record-backed file whose size is not a whole multiple of the 128 KiB record the last record's `BlockPtr` is neither cleared nor freed; for every file under 128 KiB that is the whole file, and truncating to zero gives the empty range `0..0`. With the grow-path half described in `R-F42`, the record comes straight back. **(a)** Measured on the same image and harness as `R-F42`: 10000 bytes written and fsynced — past the 3968-byte inline area (`size_of::<NodeLevelData>()`, 248 `BlockPtr`s), so the node is record-backed — `ftruncate(0)` → `size 0` and a read returns nothing; `ftruncate(10000)` → **all 10000 bytes come back identical**, and a second boot of the same disk returns them again, so they are on the medium. **(b) The space half** (`release_node` calls `truncate_node_inner(0)` before `remove_tree`/`deallocate`, `transaction.rs:1339-1345`, so an unlinked sub-record file takes its record with it): three cycles of *create 200 × 10000 B, delete all 200* inside one boot, with nothing else running, and `df` between them — free space **881272 → 880320 → 879592 → 878644 KiB**, i.e. **−952, −728 and −948 KiB per cycle** that the same boot never returns; the mean 876 KiB over 200 files is 4.4 KiB per file, about the one 4096-byte block an un-deallocated compressed record would be. A remount returns part of it and not the rest (`run3` ended at 881280 KiB, the next boot read 881640, the pre-cycle baseline was 882112). **(c) The allocator, not `df`:** on a `DiskSparse` image, 64 files of 10000 bytes created and deleted sixteen times over — 1024 files, one `ALLOC_GC_THRESHOLD`, so the collector has run — leave **1025 of 65269 blocks permanently gone**, one 4 KiB block per file. **Fixed** in `eos-redoxfs!3` (`e0295a5d`): the deallocation range's exclusive upper bound rounds up (`old_size.div_ceil(rl)`), so the last partial record is freed; after it the same 1024-file run returns free space to **exactly** its starting value, `+0`. A regression test ships with it and fails on the old code with *"1024 blocks did not come back after 1024 files with content were unlinked"*. Re-measured in a guest at the new pin: the 10000-byte case reads back all zeros, on the same boot as `R-F42`'s. **Not measured:** whether a file spanning several records loses only the last one, as the range says it should; and the fix does not free what an earlier truncate already leaked. Evidence: `dowody/redoxfs-truncate-2026-09-06/`, `dowody/redoxfs-truncate-fixed-2026-09-06/` | ✅ |
| `R-F44` | **[fixed 2026-09-06 — `eos-redoxfs!2` (`81de36dc`), pin bumped in this repo] `DiskCache` reported every transfer as complete, so RedoxFS's own short-transfer guards could not fire and one clamped write silently corrupted a record** (minted 2026-09-06 from the `R-F39` audit, findings #22 and #19 — the same defect in two adjacent functions, so one row). `read_at` dropped the `usize` from `self.inner.read_at` and rebuilt the count from the caller's buffer (`disk/cache.rs:66`, returned at `:82`); `write_at` did the same (`:89`, `:104`). `bin/mount.rs:170` wraps the only disk of the mount stack in `DiskCache`, so `Transaction::sync`'s two `count != …` checks (`:280`, `:307`), `read_block`'s (`:345`) and `FileSystem::open` — which discards the count outright at `:65` and `:75` — were all unreachable. **Measured against the pinned source, on the host, not in a guest**: with a `Disk` that transfers one block of a three-block read and accepts one block less than asked, `read_at` returned `Ok(12288)` for 4096 bytes transferred **and cached the unfilled tail**, so a second read of the same blocks returned that half-real copy without touching the disk (`inner_calls` stayed 1); `write_at` returned `Ok(12288)` for 8192 accepted. **The consequence, on a real `FileSystem<DiskCache<…>>`:** a 16 MiB image, 6 MiB of incompressible data in 128 KiB records, **exactly one** write shortened by one 4096-byte block — the shape `driver-block`'s end-of-device clamp (`R-F32`, `eos-base!2`) produces for the single request that straddles a partition end — everything else passed through: `write_node` returned `Ok` for all 6 291 456 bytes, nothing reported an error, the generation header was committed, and reopening the same image without the cache — what a remount sees — gave **1 of 48 records as `EIO`** and a whole-file read that failed. **After the fix** the transaction fails at once with `EIO`, nothing is committed (3831 of 3833 blocks still free) and the reopened image is clean, 0 of 48. **Control both ways:** with the clamp disabled the same run writes and reads back all 6 291 456 bytes, 0 wrong — the harness is not what produces the failure. The fix returns the count the disk gave back, caches only whole blocks it actually transferred, drops a block a write stopped inside, and clamps both counts to `buffer.len()` so a broken disk cannot index past the caller's buffer. `cargo test --features std`: **39/39** library tests pass, identical to the pinned revision; the 6 `tests/tests.rs` cases needing a FUSE mount fail the same way before and after (no `/dev/fuse` in the build container), so they are evidence of nothing. **In a guest:** the image rebuilt at this pin (`harddrive.img`, `sha256 90d8c1e5…`) boots to a root shell in **24 s**, writes and reads files on its RedoxFS root, reports `df` normally and powers off cleanly with `shutdown`; the truncate behaviour of `R-F42`/`R-F43` is unchanged on it — the control that says only the intended thing changed. **Not measured:** any real E-OS disk that short-counts (the clamp that produces one is `R-F32`'s, at a partition end), and the aarch64 image. Evidence: `dowody/diskcache-counts-2026-09-06/` | ✅ |
| `R-F45` | **A partition whose entry overstates its extent serves its neighbour's blocks under its own name, byte for byte, with a full-length success** (minted 2026-09-06 from the `R-F39` audit, finding #6, then **measured in a guest**). `partitionlib` copies `start_lba`/`size` out of a GPT or MBR table with no validation against the device, `last_usable`, or the neighbouring entries (`partition.rs:41,44`; MBR twin at `:64-65`), and `driver-block` bounds a partition request by `part.size` alone while `abs_block` is `part.start_lba + block` (`lib.rs:199-212`, `:220-234`) — so the arithmetic is faithful to a table that is wrong. Measured with `imgd` (`R-818`) on `probe-overlap.img`, 1 MiB, **both GPT CRCs recomputed so the table parses as entirely valid**, whose two entries overlap: entry 0 `OVERLAP-P1` LBA 64..800 (737 blocks) and entry 1 `OVERLAP-P2` LBA 500..900. Every sector from 64 to 900 names its true owner (`P1-ABS-LBA-0499`, `P2-ABS-LBA-0500`, …). `ls -la /scheme/disk.ov` publishes `0p0` as **377 344 B** — exactly the 737 blocks the overstated entry declares — and `0p1` as 205 312 B. Reading `0p0` with `seekread` (full-sector FNV-1a, so a matching prefix cannot hide a difference further in): block 435 → `P1-ABS-LBA-0499` `fnv=055c90a668baefa5`, block 436 → **`P2-ABS-LBA-0500` `fnv=9110e07cf5d98425`**, block 437 → **`P2-ABS-LBA-0501` `fnv=fea98620da1e92e5`** — and reading `0p1` at offsets 0 and 512 returns **the same two hashes**. `pread` and `lseek+read` agree; every read is a full-length `Ok(512)` with no error. So one partition's node hands out another partition's filesystem, and an `fstat`-sized copy of `0p0` would walk 264 blocks into the neighbour. **Fix shape (not implemented):** intersect each entry with the device and with its neighbours when the table is parsed, and refuse or clamp the ones that overlap — the same behaviour change `R-F41` is waiting on, and the same reason it waits: it changes what a disk with a bad table publishes. **Not measured:** only reads were run; a write past block 436 goes through the same `abs_block` and would land on `0p1`, but that was not tried. Nor was the MBR twin, nor a table produced by a real tool — this overlap was crafted. Evidence: `dowody/partition-overlap-2026-09-06/` | 🔴 |
| `R-F46` | **An MBR extended container is published as an ordinary partition, its logical partitions are never enumerated, and block 0 of that node is the EBR** (minted 2026-09-06 from the `R-F39` audit, finding #7, then **measured in a guest**). `Entry::is_valid` (`mbr.rs`) refuses type `0xEE` and `0x00` since `eos-base!7` (`R-F40`) but **deliberately does not look at `0x05`/`0x0F`/`0x85`**, and nothing in `partitionlib` walks an EBR chain — so a container is published like any other entry and what it contains is invisible. Measured on `probe-extended.img`, an ordinary 4 MiB DOS disk (three primaries, one `0x0F` LBA-addressed container, two logical partitions chained through two EBRs), every sector marked with what it really is. **Control:** `sfdisk` (util-linux) reads **six** entries — the three primaries, the container, and the logicals at LBA 4159 and 5183. **E-OS, served by `imgd` (`R-818`):** `ls /scheme/disk.ext` → **`0  0p0  0p1  0p2  0p3`**, four partitions, with `0p3` at **2 097 152 B** — the container itself. `0p0` block 0 reads `PRIMARY-1-LBA-02…` (`fnv=1c790fc6d3e8ec7d`), but **`0p3` block 0 reads `INSIDE-EXTENDED-…` (`fnv=3ab491eeb7e79abb`) — the EBR sector**, whose partition entries at byte 446 are exactly what `sfdisk` followed; `0p3` at offset 32 256 (block 63) reads `LOGICAL-1-DATA-…`, so the logical's bytes exist but only *through* the container; and `/scheme/disk.ext/0p4` fails to open with `errno=2`. **Two of the five filesystems on the disk have no node at all**, and a filesystem probe that opens `0p3` reads a partition table where it expects a superblock. **Fix shape (not implemented):** either exclude container types from the published list — small and safe, but it removes a node a working DOS disk shows today — or walk the EBR chain and publish the logicals, which is a feature, not a repair. Both change what a healthy disk publishes, so the choice is the owner's. **Not measured:** the write that would destroy the EBR; a real DOS-partitioned medium (this one was crafted, though `sfdisk` agrees with the intent); and the finding's second scenario, a 'superfloppy' whose boot sector ends in `0x55AA` being taken for a partition table. Evidence: `dowody/extended-partitions-2026-09-06/` | 🔴 |
| `R-F47` | **[fixed 2026-09-06 — `eos-base!9` (`fc8dc3f3`), pin bumped in this repo] `virtio-blkd` used the device's logical block size as the unit for `capacity` and for the request's `sector`, so a 4 Kn virtio disk was reported at eight times its size and the driver aborted on its first read** (minted 2026-09-06 from the `R-F39` audit, finding #17, then **measured in a guest**). The virtio-blk configuration space counts `capacity` in fixed 512-byte sectors and every `virtio_blk_req.sector` in the same unit (virtio 1.2, §5.2.4 and §5.2.6); `blk_size` is the device's logical block size, and `VIRTIO_BLK_F_BLK_SIZE` is never even acked (the transport acks only `VIRTIO_F_VERSION_1`). `scheme.rs:92-94` returned `capacity() * block_size()` as the medium's size and `:18-23`/`:46-52` passed the block number out as `sector` unscaled. **Measured** on a 4 MiB image whose every 512-byte sector is stamped with its LBA, on `virtio-blk-pci`, same PCI slot each time: **(a)** with `logical_block_size=4096` the driver logs `disk size: 8192 sectors and block size of 4096 bytes` — so `size()` computes **33 554 432 B for a 4 194 304 B disk** — then **panics** at `scheme.rs:40` (`assert_eq!(*status, 0)`, the device refusing the request), `Abort`, the kernel logs `UNHANDLED EXCEPTION … NAME /scheme/initfs/lib/drivers/virti`, and **the boot never reaches a login prompt**; **(b)** the control, the same image and slot at QEMU's default 512, comes up as `disk.pci-0000-00-09.0_virtio_blk` and reads correctly (offset 0 → LBA 0, 512 → LBA 1, 4096 → LBA 8), which is why every E-OS run with `qemu.mk`/`qemu-driver-check.sh` has been blind to this. **The first fix was refuted by the guest:** reporting 512 as the block size so that block numbers would already be sector numbers still panicked, because a host **enforces its logical block size on the request length** — 512-byte requests to a 4096-byte-logical device are refused however the sector is computed. **The fix that works** keeps the units apart: `block_size()` stays `blk_size` (never below 512), `size()` is `capacity * 512`, and the block number is scaled on the way out, `sector = block * (blk_size / 512)`. After it, on the same configuration: **0 panics**, `ls -la` reports `0` as **4 194 304 B**, 4096-byte reads land at offset 0 → LBA 0, 4096 → **LBA 8**, 8192 → **LBA 16**, 4 190 208 → **LBA 8184**, and a 512-byte read returns `errno 22` — `driver_block::read` refusing a length that is not a whole block, which is the honest answer. On a 512-byte device `sectors_per_block()` is 1 and nothing changes. **Not measured:** `logical_block_size` and `physical_block_size` were set together, not separated; a `blk_size` that is not a multiple of 512 was not tried; there is no unit test, because `BlockDeviceConfig` reads the device's mapped configuration space and cannot be built away from a real device. Evidence: `dowody/virtio-blk-units-2026-09-06/` | ✅ |
| `R-F48` | **[fixed 2026-09-06 — `eos-redoxfs!4` (`e529d63d`), pin bumped in this repo] A directory whose leaf splits loses the entries that do not fit, silently, while `create_node` reports success** (minted 2026-09-06 from the `R-F39` audit, finding #24, then **measured against the library**). `add_dir_entry` (`htree.rs:340-353`) splits a full `DirList` by entry **count** and fills both halves with `DirList::append`, discarding the `bool` it returns; a `DirList` holds a fixed 4092 bytes of variable-length entries, so a half that does not fit loses the overflow while the function still returns `Ok(Some(..))` — the node is created and linked, `readdir` never lists the name again, and the pre-existing entries in the same leaf go with it. Measured with the `#[cfg(test)]` `HTreeHash::from_name`, which reads the number after `__`, so names like `entry0001__100` collide by construction: **before**, all **400** `create_node` calls returned `Ok` and **185 of those 400 names were then unreachable**; **after**, `create_node` stops at **215** names with `ENOSPC` and **0 of the 215** are unreachable. The discarded `bool` was the whole mechanism — with it honoured, everything the filesystem accepted stays findable. 215 is the structural limit (entries sharing an `HTreeHash` must live in one leaf for lookup to find them, and a leaf is 4092 bytes); `ENOSPC` is how a caller should hear about it. The fix also builds both halves **before** replacing anything, so a failure leaves the caller's `dir_list` as it was — the previous shape would have committed the first half and lost the second. A regression test ships with it and fails on the old code with *"185 of the 400 names create_node accepted are unreachable"*; `cargo test --features std` is **42/42**. **In a guest** the collision case is out of reach (the shipped hasher is a 32-bit seahash, so it needs colliding hashes), but the image built at the new pin answers the regression question: 600 files in one directory, `created=600 of 600`, `listed=600`, `unopenable=0`, and the `R-F42`/`R-F43` probe still reports `zeros (POSIX)` on all three cases. **Not measured:** the collision case in a guest, and what `rename_node` does on the same shape — the audit names it as the worse victim, since it unlinks the old name after linking the new one. Evidence: `dowody/dir-split-2026-09-06/` | ✅ |
| `R-F49` | **`fpath` hands back a truncated path with a success code, and the truncation can name a different, existing object — but this is the whole tree's contract, not one scheme's bug** (minted 2026-09-06 from the `R-F39` audit, finding #25, then **measured in a guest**). RedoxFS's `fpath` (`mount/redox/scheme.rs:682-709`) copies only `buf.len()` bytes and returns `Ok(i)` with no length precheck and no `ENAMETOOLONG`. Measured with a probe using the raw `libredox::call::fpath` ABI on a file whose scheme path is 161 bytes: with a **4096-byte** buffer it returns `Ok(161)` and the true path; with a **145-byte** buffer — chosen at runtime as the offset of the last `/`, so the truncation is a *valid path*, not a mangled string — it returns **`Ok(145)`** and `/scheme/file/home/root/fp/…/directory-number-05`, which **opens, `is_dir=true`**; with a buffer of exactly 161 it returns `Ok(161)` and the exact path (the control that says the probe is not simply always truncating). A caller that reopens or compares the result operates on the parent directory instead of the file, told nothing. The only signal is `i == buf.len()`, indistinguishable from an exact fit. **What the measurement then showed about the fix:** `ENAMETOOLONG` appears **0 times** in the whole of `eos-base`'s Rust sources and **0 times** in redoxfs (relibc uses it 9 times, on its own side), **25 files** in `eos-base` implement `fn fpath`, and the two read in full — `bootstrap/src/initfs.rs:300-313` and the shared `scheme-utils::FpathWriter::push_str` (`:106-110`, used by `driver-graphics` among others) — truncate identically, `min(len, buf.len() - written)` then `Ok(written)`. So "truncate and return what fit" is the contract every scheme implements; changing RedoxFS alone would make it the odd one out, and changing the contract is a platform decision, like `R-F41`, `R-F45` and `R-F46`. **Fix shape (not implemented):** give `scheme-utils` an overflow flag and let `FpathWriter::with` return `ENAMETOOLONG`, then move the hand-rolled implementations onto it — one change, 25 call sites, and a new error that callers have never seen from these schemes. **Not measured:** 23 of the 25 implementations were not read, and the finding's second half — a resource path grown past 4096 bytes by repeated dirfd-relative `SYS_OPENAT`, which would make even a `PATH_MAX` caller truncate — was not tried. Evidence: `dowody/fpath-truncation-2026-09-06/` | 🔴 |
| `R-F50` | **Deleting one partition silently renames the ones after it, so a path that meant swap yesterday means the root filesystem today** (minted 2026-09-06 from the `R-F39` audit, finding #5, then **measured in a guest**). `gpt::partition::file_read_partitions` returns a **sparse `BTreeMap` keyed by GPT slot**; `partitionlib/src/partition.rs:39` (`.map(\|(_, part)\| Partition {`) throws the key away and collects the survivors into a dense `Vec`, and `driver-block` names them `{nsid}p{index}` by that Vec index (`lib.rs:524-525`, resolved at `:549-550`). Measured on two 1 MiB images identical byte for byte **except GPT entry 1**, both with all CRCs recomputed so both tables are entirely valid, every sector stamped with its owner: `probe-slots-all.img` has slots 1/2/3 = `SLOT1-ESP` 100..199, `SLOT2-SWAP` 300..399, `SLOT3-ROOT` 500..599; `probe-slots-gap.img` has slot 2 zeroed, which is what `sgdisk -d 2` leaves behind. Served by `imgd` (`R-818`) and read with `seekread`: on the full disk `0p0`→`SLOT1-ESP` (`fnv=e6ffef3caa801007`), `0p1`→`SLOT2-SWAP` (`fnv=2f793a52e5f72932`), `0p2`→`SLOT3-ROOT` (`fnv=a948aa13f6a462a8`); on the disk with the gap, `0p0`→`SLOT1-ESP` unchanged, **`0p1`→`SLOT3-ROOT` with `fnv=a948aa13f6a462a8` — the identical hash `0p2` had on the other disk** — and `0p2` fails to open with `errno=2`. So an fstab entry, a script, or a `mkswap` written when `0p1` meant swap now addresses the root filesystem: no `ENOENT`, no error, a plausible size. The `ENOENT` on `0p2` is the loud case; `0p1` is the silent one. The names are also already off by one against `sgdisk -p`/`lsblk` even on the undamaged disk — GPT slot 1 is `0p0`. **Fix shape (not implemented):** key the exposed name on the GPT slot, so slot 3 stays `p3` and a freed slot 2 returns `ENOENT` — which renames every partition on every **healthy** disk and breaks any path written against today's numbering, so it is the owner's call, like `R-F41`, `R-F45`, `R-F46` and `R-F49`. **Not measured:** only reads; a write to `0p1` on the second disk would land on root, but that was not run; and the MBR twin (`mbr.rs:50` collecting into the same dense `Vec`) was not measured here — `R-F46` measured a different consequence of the same collect. Evidence: `dowody/gpt-slot-keys-2026-09-06/` | 🔴 |
| `R-F51` | **[fixed 2026-09-06 — `eos-base!10` (`ee1b555d`), pin bumped in this repo] `nvmed` chunked every transfer by a fixed 8192 bytes instead of by whole blocks, so on a namespace with a larger LBA each 8 KiB of the caller's buffer came from the start of a different block — including blocks never asked for** (minted 2026-09-06 from the `R-F39` audit, finding #11, then **measured in a guest**). `namespace_read` (`nvmed/src/nvme/mod.rs:497-511`) and `namespace_write` (`:525-539`) split the buffer with `buf.chunks_mut(/* TODO: buf len */ 8192)`, compute `blocks` by rounding the chunk up to a block, and advance the LBA by that many. Measured on a QEMU NVMe namespace with `logical_block_size=16384` and an image whose every 512-byte sector carries its own absolute byte offset: **before**, one 32 768-byte read at offset 0 returned `Ok(32768)` whose four 8 KiB slices held `OFF-0000000`, **`OFF-0016384`** (the start of LBA 1, not the tail of LBA 0), **`OFF-0032768`** and **`OFF-0049152`** — LBAs 2 and 3, never requested — and even the smallest legal request, one 16 384-byte block, put `OFF-0016384` where `OFF-0008192` belonged. **After** the fix the same two reads return `OFF-0000000 / OFF-0008192 / OFF-0016384 / OFF-0024576` and `OFF-0000000 / OFF-0008192`. The fix makes the chunk a whole number of blocks aimed at the same 8192 bytes, so a namespace whose block divides it — 512, 4096, 8192 — issues exactly the commands it did before, which is why the guest still boots from its own 512-byte NVMe in every run; a block larger than the 2 MiB bounce buffer now returns `EINVAL` instead of copying a prefix and reporting success. 8192 was never a device limit: `ThreadCtxt::buffer` is 2 MiB and its PRP list covers all of it — the number was the `/* TODO */` the audit pointed at. Re-measured on a build of the merge commit (`harddrive.img` `sha256 69ff2c64…`): identical output. **Not measured:** the write path — same arithmetic, and there each command would also carry stale bounce-buffer bytes into blocks the caller never addressed — and no block size between 8192 and 2 MiB other than 16384. Evidence: `dowody/nvme-chunking-2026-09-06/` | ✅ |
| `R-F52` | **A GPT that passes every integrity check is parsed at the wrong stride: partitions vanish, and phantoms appear that are windows onto the protective MBR** (minted 2026-09-06 from the `R-F39` audit, finding #8, then **measured against the pinned `partitionlib` and in a guest**). The entry array is walked at a hardcoded 128 bytes per entry — `gpt-3.x`'s `partition.rs` reads `[u8; 56]` + `[u8; 72]` per iteration, `num_parts` times — while the array CRC is verified over `num_parts * part_size` taken from the header; `file_read_header` checks the signature and the header CRC and never bounds-checks `part_size` or `num_parts`, and `partitionlib/src/partition.rs:33-35` passes the header through untouched. Measured on three 4 MiB images, each with **both CRCs valid**: with the ordinary `part_size = 128` the library returns 2 partitions, `ALPHA` and `BRAVO`; with **`part_size = 256`** and `BRAVO` at table index 64 it returns **1** — `BRAVO` is simply gone; with **`part_size = 192`** it returns **3** — `ALPHA`, then two phantoms with `start_lba = 0`, `size = 1` and an all-zero GUID, while `BRAVO` never appears at all. Served to a guest by `imgd` (`R-818`), E-OS publishes exactly that: `disk.s192` shows `0p0` at 1 048 576 B (`ALPHA`, right) plus **`0p1` and `0p2` at 512 B each**, and `disk.s256` shows `0p0` alone. **The phantom is not harmless:** reading `0p1` returns a full-sector FNV-1a of **`b1850adae5fc5987`**, byte-identical to the image's **LBA 0 — the protective MBR**, and **that hash is unique in the image**: of its 8192 sectors, only sector 0 carries it. (`0p0` reads `aef344b97d054b25`, which is LBA 2048 — but that value is simply the FNV of 512 zero bytes and 8187 of the 8192 sectors share it, so it locates nothing and is not evidence of anything; the identification rests on the `0p1` hash alone.) A write to `0p1` block 0 lands on the partition table itself, and the caller believes it is writing to a partition. **Fix shape (not implemented):** either honour the header's `part_size` when walking the array — that is inside the vendored `gpt` crate, not E-OS's own code — or have `partitionlib` refuse a header whose `part_size` is not 128 with an explicit error instead of mis-parsing it silently. Both change what a healthy but unusual disk publishes (the UEFI spec permits any multiple of 128), so the choice is the owner's, as with `R-F41`, `R-F45`, `R-F46`, `R-F49` and `R-F50`. **Not measured:** only reads — no write to a phantom was attempted — and no real tool was found that writes a `part_size` other than 128, so this is a legal table parsed wrongly, not a corrupted one. Evidence: `dowody/gpt-entry-stride-2026-09-06/` | 🔴 |
| `R-F53` | **A disk whose block size is neither 512 nor 4096 is reported as having no partition table at all — the same medium, byte for byte, publishes its partition at 512 and nothing at 2048** (minted 2026-09-06 from the `R-F39` audit, finding #3, then **measured in a guest**). `DiskWrapper::pt` (`driver-block/src/lib.rs:107-111`) matches the block size against exactly two values and takes `_ => return None`; the function returns `Option`, and its consumers read `None` as "there is no table" — `:533` `if disk.pt.is_none() { continue; }` and `:560` `.ok_or(Error::new(ENOENT))?`. Nothing distinguishes "unsupported block size" from "unpartitioned medium", and nothing is logged. **Measured on one boot with one image attached twice:** `probe-mbr.img` is 4 MiB with an ordinary MBR — one bootable `0x83` entry at LBA 512, 512 sectors — given to `virtio-blk-pci` at `addr=0x9` (512-byte blocks) and at `addr=0xa` with `logical_block_size=2048`, both confirmed by the driver's own line (`disk size: 8192 sectors and block size of 512 bytes` / `… of 2048 bytes`). The 512 disk publishes `0` and **`0p0` at 262 144 B**, exactly the 512 × 512 the table declares; the 2048 disk publishes **`0` alone — no partition**. The medium is perfectly readable either way: a 2048-byte read of the 2048 disk returns the same MBR bytes the 512 disk shows (`eb3c90452d4f5320…`), while a 512-byte read of it returns **`errno 22`** — `driver-block` refusing a length that is not a whole block, which is itself proof the 2048 reached it. So the table is not damaged and not unreadable; it is never parsed. **What this means for real media, read and not measured:** `ahcid`'s ATAPI `block_size()` (`disk_atapi.rs:72-74`) returns the `blk_size` it took from the device's own READ CAPACITY (`:55`), and optical media report 2048 — so a CD or DVD, including an isohybrid image carrying a real MBR, would hit this gate; `usbscsid` passes the SCSI logical block length through the same way. **I tried to measure that and did not get there:** an `ide-cd` on q35's `ide.0` never came up as an ATAPI disk — `ahcid` logged `pci-0000-00-1f.2_ahci-0: Unknown(4294967295)`, published no scheme, and both names I guessed returned `ENODEV`. **Corrected 2026-09-07, then corrected again the same night after review.** ATAPI does bind: `ahcid` reports `pci-0000-00-1f.2_ahci-1: SATAPI` and identifies `QEMU DVD-ROM`. But the first correction got the reason and the consequence wrong on three counts, and `R-F62` — added half an hour later in this same table — refutes all three. *(a) The bus:* the first correction said moving the CD to `ide.1` was what enabled it. `R-F62` bound and read a disc on **`ide.0`, alone**, so `ide.0` was never the obstacle. *(b) The blocker:* it said the guest "does not finish first boot with the disc attached". It does — `R-F62` reached a shell in 24 s with a disc attached and ran seven commands against it. What actually happened in the two failing runs is visible on line 3 of both logs: `BdsDxe: loading Boot0001 "UEFI QEMU DVD-ROM QM00003"` — **the 1.4 GB medium was the live ISO and UEFI booted it**, so the harness was driving a different system and desynced at its login prompt. A non-bootable 8 MiB disc leaves UEFI falling through to `Boot0002 … NVMe`, and the guest boots normally. *(c) The lead:* it filed `Size: 0 MB` as a lead toward finding #12; `R-F62` retracts that — ATAPI reports zero sectors in IDENTIFY PACKET and capacity comes from READ CAPACITY, which the scheme evidently used, publishing the true 8388608. **The ATAPI path is measured and the finding it blocked is closed: see `R-F62`** (`dowody/atapi-128k-read-kills-ahcid-2026-09-07/`, and the superseded first attempt at `dowody/atapi-binds-but-boot-stalls-2026-09-07/`). **Fix shape (not implemented):** run the MBR path for any block size a medium can legally report and keep the GPT path for the two the `gpt` crate's `LogicalBlockSize` offers — which needs an MBR-only entry point in `partitionlib`, since `get_partitions` takes a `LogicalBlockSize` and that enum has only `Lb512` and `Lb4096`; at minimum, say `None` for a reason instead of silently. Note `block_read`'s buffer is a fixed `[u8; 4096]` (`lib.rs:49-50`), so a block size above 4096 must still be refused, and refused loudly. **Not measured:** the ATAPI path; any write; and no claim that an E-OS image is currently shipped on 2048-byte media. Evidence: `dowody/block-size-gate-2026-09-06/` | 🔴 |
| `R-F54` | **`raid1d` publishes the array at whatever `usable_bytes` its superblock claims, so an overstatement makes each member's own RAID superblock addressable as array data** (minted 2026-09-06 from the `R-F39` audit, finding #18, then **measured in a guest** and **fixed** in `eos-base!11` (`2063f464`)). `read_superblock` (`drivers/storage/raid1d/src/main.rs:99-109`) returns `(Superblock, size)` — the member's real length is in the caller's hand — and every caller drops it: `from_bytes` (`:84-86`) checks `usable_bytes` only for non-zero and block-multiple, and `assemble` propagates `members[src_i].sb.usable_bytes` (`:477`, `:512`, `:571`) without ever comparing it with `Member::dev_size`. The superblock lives in the member's own last 4 KiB (`sb_offset(dev_size)`), so an overstatement lands exactly on the metadata rather than past the end of the disk, where the read would have failed loudly. **Measured on one boot with two crafted 16 MiB members** given to `virtio-blk-pci` at `addr=0x9` and `addr=0xa`, each 512-byte sector carrying its own absolute offset, superblocks claiming `usable_bytes = 16777216` — 4096 more than `cmd_create` writes. **Before** (image pinned at `ee1b555d`): `raid1d: assembled array 101112131415161718191a1b1c1d1e1f (16 MiB, 2 active member(s), primary /scheme/disk.pci-0000-00-09.0_virtio_blk/0)`, `ls -la /scheme/disk.raid1` reports `0   16777216`, and a `pread` at byte `16773120` returns **`n=512`, `454f5352414944310200000010111213` = `EOSRAID1........`** — the array serving its own superblock as file data. **After** (`1b64db73`): the daemon prints `raid1d: superblock claims 16777216 usable bytes but the members hold 16773120; using the smaller`, assembles the same UUID as `(15 MiB, 2 active member(s), …)`, `ls -la` reports `0   16773120`, and the same `pread` returns **`n=0`** — past the end, which it now is; a second offset at `16776704` likewise. **The control is in both runs:** a `pread` at byte 0 returns `RAID-MEMBER0-OFF` before and after, unchanged, so the clamp did not simply break the array. **Fix:** bound `usable` by the smallest `sb_offset(dev_size)` across the members, rounded down to a whole block so the offset arithmetic downstream keeps its invariant; for an array `cmd_create` made that is exactly the value already stored, so a healthy array is untouched — verified two ways: the clamp's expression is textually the same one `cmd_create` uses to write the value (`:295` vs `:492`), and a brute force over 600 045 healthy member pairs and 160 297 honest superblocks across every legal `block_size` (512…65536) shrank none. The mismatch is logged rather than corrected in silence. **Two things this fix did NOT do, both found by an adversarial reviewer after it was merged and both stated wrongly in `eos-base!11`'s commit message, which claimed the opposite — both since MEASURED and FIXED the same day**, pin `1b64db73` → `e218511c`, evidence `dowody/raid1d-clamp-followups-2026-09-06/`. **(a) It did not repair the lying superblock.** `usable_bytes` was assigned in exactly one place (`:538`), inside `for i in rebuild`; the unconditional generation bump at `:581-590` wrote each active member's `m.sb` back with the inflated value still in it. In the measured run `rebuild` is empty — both members share a generation and neither is split-brain — so `16777216` came back to both disks on every assembly and the warning fired forever. **Red, two boots of the `1b64db73` image with the same crafted members:** generation 1 → 2 → 3 and `last_full_sync` with it, so the superblock demonstrably *was* rewritten both times, `usable_bytes` still `16777216` after each, warning printed on both. **Green (`eos-base!13`, `88fa8e8b`, merge `e218511c`):** boot 1 adds `raid1d: repairing the geometry recorded on every member: 16777216 -> 16773120 usable bytes`, both members come away recording `16773120`, and boot 2 prints no warning at all while the generation still advances — repaired once instead of re-diagnosed forever. The `R-F54` result itself is the control and is unchanged: `pread` at 0 → `RAID-MEMBER0-OFF`, at 16772608 → `n=512`, at 16773120 and 16776704 → `n=0`. **(b) `capacity` was computed over every discovered member before any was excluded** (`:492` vs the `active = false` assignments at `:546` and `:558`), and `:538` wrote the clamped value into the rebuilt member's superblock; because the bound is a `min`, the size ratcheted down and never recovered. **Both halves measured on the `1b64db73` image.** *An excluded member still bounded the array:* a 16 MiB member whose stale 12 MiB peer failed its rebuild (`rebuild FAILED … I/O error (os error 5) — staying degraded`) published `12578816` while `running DEGRADED (1 of 2 member(s) active)` on the 16 MiB disk alone, and `pread` at 12578816 and 16772608 answered `n=0` — 4 MiB of the surviving member unreachable, bounded by a disk that is not in the array. *A rebuild persisted the clamp:* a 16 MiB **stale** member rebuilt from a 12 MiB peer came away with `usable_bytes = 12578816` on its own superblock, and the next boot — both members 16 MiB again — published 11 MiB **with no warning at all**, silently 4 MiB short and permanently so. **Green (`eos-base!12`, `6d4e063e`, merge `65f7bdcc`):** the published size is measured after the rebuilds over the active members only (first case: `(15 MiB, 1 active member(s))`, `ls -la` `16773120`, both offsets `n=512`, and 16773120 still `n=0` so the clamp is untouched), and the rebuild writes the array's agreed geometry rather than the clamped value (second case: the member's superblock still records `16773120`, the boot is still clamped and still logged, and the next boot is back to 15 MiB). Every green was measured twice — on the pre-merge testpin `95a77332` and again on the pinned `e218511c`, whose trees are identical. **The gate:** the arithmetic behind both decisions moved to `drivers/storage/raid1d/src/geometry.rs`, a module with no Redox dependencies so it runs on the build host (`cargo test -p raid1d` cannot — `libredox` does not build for darwin, measured); every gate in it was **shown red** against the pre-fix expressions, in two variants, before it was shown green, and `R-F54`'s invariant is re-checked there over **802 816 healthy member pairs and 3 556 864 honest superblocks** across every legal `block_size` — none shrank, none would be rewritten. **Why it matters:** a filesystem's backup superblock, a backup GPT header or `mkfs` zeroing the tail all write at the top of the medium — onto the RAID metadata — and the audit reads that path as answering `Ok(buffer.len())`. **Still not measured:** the write path — a filesystem actually writing over the RAID metadata, the destruction itself, as opposed to the read that exposed it; and a member *deliberately* replaced by a smaller disk, which the fix treats exactly like a member that mis-reports its size — clamp the boot, log it, write nothing — because `raid1d` cannot tell them apart, and whether that is the right policy for a deliberate replacement nobody has decided. **Two findings the follow-up work turned up on the way, neither looked for, both registered rather than left in a scrollback:** `R-F59` (`virtio-blkd` panics on a device write error instead of returning `EIO`, which is why the failing member in those runs is attached as NVMe) and `R-F60` (`last_full_sync` advanced after a resync that covered only part of the array — older than `R-F54`, hidden until (b) stopped shrinking the array to match). Evidence: `dowody/raid1d-usable-bytes-2026-09-06/` and `dowody/raid1d-clamp-followups-2026-09-06/` | ✅ |
| `R-F55` | **`usbscsid` builds every WRITE(16) command descriptor with the LBA and the transfer length in host byte order, in fields SCSI defines as big-endian — a one-block write at LBA 1 leaves the host as a request for 16 777 216 blocks at LBA 72 057 594 037 927 936** (minted 2026-09-06 from the `R-F39` audit, finding #15, then **measured against the pinned source**). `Read16::new` (`drivers/storage/usbscsid/src/scsi/cmds.rs:181-194`) converts both multi-byte fields — `lba: u64::to_be(lba)`, `transfer_len: u32::to_be(transfer_len)` — and `Inquiry::new` (`:18-26`) does the same for its `alloc_len`. `Write16::new` (`:209-220`) stores both raw, twenty lines away from its sibling, under a struct field annotated `pub lba: u64, // big endian`. The struct's in-memory image **is** the wire CDB: `scsi/mod.rs:187-189` reinterprets the driver's `command_buffer: [u8; 16]` as the struct, `:287-288` assigns the constructor's result into it, and `:295` hands `&self.command_buffer[..16]` to `protocol.send_command`. Nothing between the constructor and the wire touches those bytes. **Measured at library level, on the host, by compiling the pinned `cmds.rs` and `opcodes.rs` verbatim** (`include!`, not copied) and decoding the emitted bytes the way a target would — LBA at CDB bytes 2..10 big-endian, transfer length at 10..14: for `lba=1, transfer_len=1` the CDB is `8a000100000000000000010000000000`, which a target reads as **`lba=0x0100000000000000 len=0x01000000`**; for `lba=0x123456789abcdef0, transfer_len=0x40` it is `8a00f0debc9a78563412400000000000`, read as **`lba=0xf0debc9a78563412 len=0x40000000`**. **Two controls in the same run, both correct:** `READ16` built from identical arguments (`8800…` → `lba=1 len=1`) and `INQUIRY` with `alloc_len=0x0024` (→ `0x0024`). **It ships:** `usbscsid` appears in neither `config/` nor `recipes/` by name — it arrives through the `base` recipe's driver set — but the x86_64 image carries it, and carries the driver's own error string from `scsi/mod.rs:284`, *"number of blocks to write couldn't fit inside a u32"* — an `Err(ScsiError::Overflow(…))`, not a panic — exactly once. A grep of the configuration alone would have said "not shipped". **Fixed — `eos-base!14` (`fbfe4e6f`, merged as `8c0ff425`):** `lba: u64::to_be(lba), transfer_len: u32::to_be(transfer_len)`, the two lines its sibling already has. Measured after: the WRITE(16) descriptor becomes byte-identical to the READ(16) one apart from the opcode, and the target reads `lba=1 len=1`; both controls unchanged. **Verified as far as this project can verify it:** the image was built from a branch carrying both this and `eos-base!15`, boots to a shell in 24 s with no driver error, and carries the driver's own strings; but neither the defect nor the fix can be exercised in a guest — a guest cannot confirm it — see the correction below, and `dowody/harness-sata-and-usb-2026-09-06/` — so the library-level before/after is the measurement. **Not measured:** what a real device does with such a CDB — the plausible answer is CHECK CONDITION, i.e. every USB write fails loudly rather than corrupting anything, but a device that clamps is the silent case. **Correction, and then a correction of the correction.** The harness *does* have a USB mass-storage path; the claim that it did not was already false on 2026-09-05, whose own evidence (`dowody/s15-qemu-2026-09-05/row-28-usb-cd/`, `dowody/rf33-usbscsid-2026-09-05/`) attaches `-device qemu-xhci` with **no `id`** and `-device usb-storage` with **no `bus=`**, binds (`Loading subdriver "SCSI over USB" … class 8.6`, `usbscsid: SCSI initialized`) and then blocks forever on every read. A later note here claimed the missing `id` was the reason USB had never worked; **it was not** — QEMU auto-assigns the bus when `bus=` is omitted, and the `id` only repaired a `bus=xhci.0` hard-coded into a harness script written that same evening. What is real, and unchanged since 2026-09-05, is that `usbscsid` binds, prints `SCSI initialized`, and then never answers: `ls` on its scheme timed out after 454 s with `^C` not recovering the prompt, and a direct `pread` on a named path hung too. That, not the absence of a device, is what has been blocking `R-F33`; nor whether E-OS writes to USB storage anywhere today. **A false positive of my own, recorded so it is not repeated:** a first pass grepped for `to_be` and flagged `ModeSense10::new` as a second offender because it uses `u16::from_be`. That is not a defect — `to_be` and `from_be` are the same involution, so the bytes are identical on every platform. `Write16` is the only constructor in the file that omits the conversion. Evidence: `dowody/write16-byte-swaps-2026-09-06/` | ✅ |
| `R-F56` | **A GPT entry whose partition type GUID is zero — the way the spec says an entry is marked unused — is published as a real partition, identical in every field to a used one** (minted 2026-09-06 from the `R-F39` audit, finding #9, then **measured against the pinned library**). UEFI 2.10 §5.3.3 defines an entry with a zero `PartitionTypeGUID` as unused; `partitionlib`'s `get_gpt_partitions` (`drivers/storage/partitionlib/src/partition.rs:37-46`) maps the entry array to its own `Partition` type without ever asking whether the entry is used. This is **not** `R-F52`, which is the entry-*stride* defect at `:33-35` (#8) and already has a row. **Measured on `partitionlib`'s own test image** (`resources/disk.img`, 512 KiB, 512-byte sectors, one used entry named `bug`), calling the real entry point `get_partitions(Cursor::new(img), Lb512)` against the pinned crate, in three variants that differ only in the entry array, the **two mutated ones** with both CRCs repaired so the table still validates (the baseline is untouched and its shipped CRCs already verify: `0x8afb3df7` and `0xd6249f34`): **baseline** (untouched) gives `kind=Gpt count=1`, `start_lba=34 size=957 name="bug" uuid=b665fba9-…`; **subject** (zero *only* the 16-byte type GUID at `img[1024..1040]`) gives **`kind=Gpt count=1` with the very same start, size, name and unique GUID**; **negative control** (zero the whole 128-byte entry) gives **`kind=Gpt count=0`**. `kind=Gpt` in all three is what makes the result mean anything — a wrong CRC would send `get_partitions` (`:74-76`) down the MBR fallback, whose protective entry the pinned `mbr.rs` correctly rejects, giving `kind=Mbr count=0`, a false "fixed" reading. **The control is the interesting half:** subject and control differ only in bytes 16..128 of the entry, fields the spec calls irrelevant once the type GUID is zero, yet one yields a partition and the other none — so the check that exists is the `gpt` crate's all-zero skip (`gpt-3.1.0/src/partition.rs:291`), and `partitionlib` inherits only that: it drops entries that are entirely blank and keeps entries that are merely marked unused. **What it would mean on real media:** a tool that releases a partition the spec-sanctioned way, by zeroing its type GUID, leaves E-OS still publishing it, so reads and writes go to a range its owner has released and may have reassigned. **Fix shape (not implemented):** filter on `is_used()` before the map — a one-line change whose blast radius is every disk whose table has released entries, so it is a behaviour decision, not a typo. **Not measured:** no guest run, so no claim about what the scheme layer or the installer does with the extra node; and no claim that any tool E-OS ships zeroes a type GUID this way. Evidence: `dowody/gpt-zero-type-guid-2026-09-06/` | 🔴 |
| `R-F57` | **A SCSI command the device answered "failed" is reported to the caller as a complete transfer — a failed read hands back the previous read's bytes with a full count, and a failed write is called a success while the medium receives nothing** (minted 2026-09-06 from the `R-F39` audit, finding #14, then **measured against the pinned source**). `Scsi::read` (`drivers/storage/usbscsid/src/scsi/mod.rs:273-278`) and `Scsi::write` (`:292-298`) both end with `Ok(status.bytes_transferred(bytes_to_read as u32))` and never inspect `status.kind`, which carries the CSW outcome; a device answering CHECK CONDITION produces `kind = Failed`, and that value is discarded. **Measured at library level** by compiling the pinned `scsi/{mod,cmds,opcodes}.rs` and `protocol/{mod,bot}.rs` **verbatim** (`include!`, nothing copied or edited) against the real `xhcid_interface`, and substituting a fake transport implementing the driver's own `Protocol` trait — `usbscsid` is a binary-only crate with no `[lib]`, which is why the files are included rather than depended on. The fake answers INQUIRY, MODE SENSE(10) and READ CAPACITY(10) so the real `Scsi::new` runs to completion (block size 512, 65 535 blocks), then serves READ(16)/WRITE(16) either moving the bytes and returning `Success`, or moving nothing and returning `Failed`; `residue: None` is not an invention — `bot.rs:295` yields `None` when the device reports `dCSWDataResidue == 0`. **Result** (the `Ok` comes from `kind` being discarded; the *magnitude* 4096 additionally requires the CSW residue to be zero — with `residue = 4096` the driver would return `Ok(0)`, still a swallowed failure but not a claimed complete transfer): `READ ctrl (kind=Success, 4096 bytes of 0xAA): result=Ok(4096) buf[0]=0xaa buf[4095]=0xaa` / **`READ fail (kind=Failed, 0 bytes moved): result=Ok(4096) buf[0]=0xaa buf[4095]=0xaa`** — the caller is told 4096 bytes arrived and the buffer still holds the *previous* read; `WRITE ctrl (kind=Success): result=Ok(4096) medium_len=4096` / **`WRITE fail (kind=Failed): result=Ok(4096) medium_len=0`** — the caller is told 4096 bytes were written and the medium got none. **The two `Success` rows are the negative control and are correct in both directions**, so the probe separates the cases rather than always failing. This is the archetype of `R-F39`'s "silent success" class: the error exists, the device reported it, and the layer above is told everything is fine — and a read that returns stale buffer contents with a full count is indistinguishable from a real read by any caller. **Fix shape (not implemented):** map `kind` to an error before the `Ok`, which means deciding what each CSW status becomes — a driver-behaviour decision, and the fork was busy. **Not measured:** no real device and no guest — the harness *does* attach a USB mass-storage device (see `dowody/harness-sata-and-usb-2026-09-06/`), but `usbscsid` hangs on the first access to the scheme it publishes, so what is measured here is the driver's own logic at the `Protocol` boundary; whether E-OS reads or writes USB storage anywhere today; and finding #13, the adjacent residue arithmetic, which was deliberately held at `None` throughout so it could not confound this result. *Aside, not a defect:* the `Debug` line `ReadCapacity10ParamData { max_lba: 4294901760, block_len: 131072 }` prints the struct's raw big-endian fields; the driver converts them where it uses them, which is why the same run reports `block_size=512 block_count=65535`. Evidence: `dowody/scsi-status-ignored-2026-09-06/` | 🔴 |
| `R-F58` | **`ided` never writes LBA bits 27:24, so on a disk without LBA48 every block above 8 GiB silently aliases into the first 8 GiB — and a write to the first block past the boundary lands on block 0, the partition table** (minted 2026-09-06 from the `R-F39` audit, finding #16, then **measured against the pinned source**). ATA LBA28 carries address bits 27:24 in the low nibble of the device/head register. `ide.rs` writes that register — in the read path at `:226-228` and byte-identically in the write path at `:370-372` — as `chan.device_select.write(0xE0 | (self.dev << 4));`, directly under its own `//TODO: upper part of LBA 28`, so bits 3:0 are always zero while the three `lba_*` ports carry only bits 23:0. **The range is reachable because the driver puts it there:** `main.rs:185-190` falls back to `lba_bits = 28` whenever IDENTIFY words 100..103 are zero, reading the sector count from words 60/61 instead — up to 2²⁸−1 sectors, **128 GiB** — and `:203` publishes `size = sectors * 512`. The driver therefore advertises up to 128 GiB while addressing only the first 8 GiB. **Measured at library level** by compiling the pinned `ide.rs` **verbatim** (`#[path = …] mod ide;`, nothing edited) and substituting only its dependencies: a `common` whose `Pio::write` records `(port, value, width)` instead of executing `out` — no `asm!` anywhere — plus signature-identical `driver-block` and `redox_syscall` stubs; the harness then rebuilds the address the way an ATA device would and compares it with the block requested. **Result:** `LBA28 read block 0x0100_0000` → `device_select=0xe0`, **controller latches `0x0000_0000`**; `LBA28 read 0x0A00_0007` → latches `0x0000_0007`; **`LBA28 write 0x0100_0000` → latches `0x0000_0000`**; `LBA28 read 0x0FFF_FFFF` — the largest address the LBA28 fallback will publish — → latches `0x00FF_FFFF`. **Four negative controls, all passing:** LBA28 read *and* write at `0x00FF_FFFF`, the last block below the boundary, and LBA48 at `0x0100_0000` and `0x1234_5678_9A`, the latter recovered exactly, which is also what proves the harness's address reconstruction correct. **The sharpest consequence** is the write: a filesystem writing at the 8 GiB mark overwrites the protective MBR and the boot sector, and the driver reports success — the same shape as `R-F38`. **Fixed — `eos-base!15` (`fix/ided-lba28-high-bits`, merged as `d439c9b6`):** `0xE0 | (self.dev << 4) | ((block >> 24) as u8 & 0x0F)` on the LBA28 path only (`b6ed859a`; the `//TODO` says as much), plus a second commit (`25873676`) closing the residual defect an adversarial reviewer found — a block **at or above** 2²⁸ has no room in these registers at all, and was still truncated silently: `read`/`write` now refuse the whole range before any I/O with `EIO` (measured: `result=Err(errno 5)` and an **empty port trace**, where the pinned code returned `Ok(512)` having latched block 0), and `main.rs` clamps the LBA28 sector count so the driver stops publishing capacity it cannot reach. Over twelve rows: pinned **7 aliased / 0 refused**, patched **0 wrong / 2 refused / 10 OK**, four negative controls unchanged. `cook base - successful`, and the guard's message appears twice in the built `ided` — once per path. **Verified as far as this project can verify it:** the image built from both fixes carries `past the LBA28 limit` **twice** — once per path — plus the clamp's console message, boots to a shell in 24 s and reads `/etc/hostname` off RedoxFS with no driver error; but q35 has no legacy IDE, so the defect itself cannot be exercised in a guest and the library-level before/after remains the measurement. **Not measured:** no real IDE disk and no guest — q35 has no legacy IDE, which is what defeated the earlier attempt recorded under `R-F53`; what is measured is the sequence of port writes the driver emits, not a device's reaction; whether any machine E-OS runs on presents an LBA28 disk above 8 GiB (LBA48 arrived around 2002, so such a disk is old — but the driver's own fallback is what makes the range reachable); and the DMA path was not exercised — but the whole address-setup sequence (device select, sector count, `lba_0/1/2`) is **common to DMA and PIO**, only the command byte differing, so a PIO-only probe does cover the DMA path's addressing. **It ships, and the naive check is a trap in both directions:** `ided` is declared as a package in neither `config/` nor `recipes/` — it arrives through the `base` recipe's driver set — and a plain `grep -r ided recipes/` is no help either, since its only two hits are substrings inside unrelated `wip` files. In the other direction `LC_ALL=C grep -ac ided harddrive.img` answers **1100**, because of *provided*, *divided* and *decided*. Unique strings settle it: `ided: failed to get I/O privilege`, `ided: failed to enter null namespace` and the driver's own trace format `IDE read chan` each appear **exactly once** in the x86_64 image, while the source comment `upper part of LBA 28` correctly appears **zero** times — a comment cannot reach a binary, which is itself a check that the greps are measuring the right thing. Evidence: `dowody/ide-lba28-high-bits-2026-09-06/` | ✅ |
| `R-F59` | **`virtio-blkd` turns any device-reported I/O error into a panic, so one bad sector kills the driver and every disk it serves instead of returning `EIO`** (minted 2026-09-06 while measuring `R-F54(b)`, then **measured in a guest**). The private helper trait `BlkExtension` (`drivers/storage/virtio-blkd/src/scheme.rs:11-14`) declares `read`/`write` as returning a bare `usize`, and both implementations end with `assert_eq!(*status, 0)` — read at `:40`, write at `:70` — over the virtio status byte, whose non-zero values are exactly `VIRTIO_BLK_S_IOERR` (1) and `VIRTIO_BLK_S_UNSUPP` (2). The error is representable one level up: the `Disk` impl at `:115` and `:120` returns `syscall::Result<usize>`, and `driver-block`'s trait (`drivers/storage/driver-block/src/lib.rs:78-79`) is declared that way for this reason. It is thrown away before it gets there. **Measured 2026-09-06** on the image pinned at `1b64db73`, attaching a RAID member as a `virtio-blk-pci` drive with `readonly=on` (QEMU then answers every write with `VIRTIO_BLK_S_IOERR`) and letting `raid1d` try to rebuild onto it: `thread 'main' (1) panicked at drivers/storage/virtio-blkd/src/scheme.rs:70:9 / assertion \`left == right\` failed / left: 1 / right: 0`, then `[ERROR virtio-blkd@src/header/stdlib/mod.rs:121] Abort` and `Invalid opcode fault`. The daemon dies, the array is never assembled, and `raid1d status` afterwards reports `no RAID members found`. **Why it matters:** `raid1d` has a whole degraded path built on `EIO` — exclude the member, run on the survivors, say so loudly — and it never gets the chance, because the driver underneath aborts first; the same is true of any other consumer that handles a failed read. A read error is the more common case in practice and takes the identical path at `:40`. **Fix shape (not implemented):** make `BlkExtension::{read,write}` return `syscall::Result<usize>` and map a non-zero status to `Error::new(EIO)`; the two call sites at `:115`/`:120` already return that type. **Not measured:** whether a real device (as opposed to QEMU's read-only flag) reaches the same status byte on a genuine medium error; the read path, which is read from the code and has the same assert; and whether any other E-OS driver has the same shape. **Discovered as instrument trouble, not by looking:** this is why the `R-F54(b)` runs attach the failing member as NVMe — `nvmed` returns `Err(EIO)` (`drivers/storage/nvmed/src/nvme/mod.rs:477-482`) and survives. Evidence: `dowody/raid1d-clamp-followups-2026-09-06/` (README, "The harness") | 🔴 |
| `R-F60` | **`raid1d` advances `last_full_sync` — its marker for "every member was present and in sync at this generation" — after a resync that copied only part of the array** (minted 2026-09-06 while measuring `R-F54(b)`, then **observed in a guest**). `complete` (`drivers/storage/raid1d/src/main.rs`) asks only whether every member of the array is present and active; it does not ask whether the rebuild that just ran actually covered the array's geometry. `resync_copy` copies the bound it was given, and when a peer reports less than the array's recorded `usable_bytes` that bound is short. The generation bump then sets `last_full_sync = new_gen` on both members, which is the value the split-brain check later trusts to tell "in sync at generation N" from "two members that each advanced while the other was absent". **Observed 2026-09-06** on the merged pin `e218511c`, in the `R-F54(b)` second fixture: a 16 MiB stale member rebuilt from a 12 MiB peer, the copy bounded at 12578816. On the following boot, with both members 16 MiB again, `pread` below 12578816 returns `RAID-MEMBER1-OFF` (what the rebuild copied) and above it `RAID-MEMBER0-OFF` (never mirrored) — the two members differ over 4 MiB of an array whose superblocks both record a clean full sync at that generation. **This is older than `R-F54`** — `resync_copy` has always copied only `usable` bytes — and it was invisible until `eos-base!12` stopped shrinking the array to match, which is the only reason it is being written down now rather than found later by a filesystem. **Fix shape (not implemented):** a resync that could not cover `usable_bytes` is not a full sync — do not advance `last_full_sync`, and say so in the log; the array can still assemble and run. **Not measured:** whether the divergence is reachable without a member that mis-reports its size (a genuinely truncated read from a peer would do it too, but that path is not exercised here); and what a split-brain resolution does with a `last_full_sync` it should not trust — the interesting failure, and the reason this is not merely cosmetic. Evidence: `dowody/raid1d-clamp-followups-2026-09-06/b2-pin/boot2/` | 🔴 |
| `R-F61` | **Once any process has mmapped a file, every later read of that file returns page padding as content with a full count — `read(fd, buf, 4096)` on the shipped 3-byte `/etc/hostname` returns 4096 while `fstat` still says 3** (minted 2026-09-06 from the `R-F39` audit, finding #23, **measured in a guest** after a first attempt failed). `FileResource::read` (`redoxfs/src/mount/redox/resource.rs:496-541`, the fast-path block at `:521-530`) takes an fmap fast path that memcpys `buf.len()` bytes out of the page-rounded mapping and returns `Ok(buf.len())`; neither `node.data().size()` nor `tx.read_node` appears anywhere in that block. **The first probe did not reach it, and the reason is the instructive half:** it created and wrote the file it later mapped, and `FileResource::write` does `fmap_info.version += 1` (`:560-562`) while `Fmap::new` registers every new range with a hardcoded `version: 0` (`:386`) — so the range was stale from birth and the guard at `:513` sent every read down the slow path. That was diagnosed by an adversarial reviewer reading the source already in hand, after the first write-up had left two hypotheses open, **both of which were wrong**: `fmaps` *is* per-scheme, keyed by node id and never removed on close, and the version guard *is* satisfiable. **Two routes past it, both read from the source and both run in one boot. Route A** — a file this boot never wrote through the `file:` scheme, so both versions stay 0: `/etc/hostname`, 3 bytes, gives `read_n=3 stat_size=3` before any mapping and **`read_n=4096 stat_size=3 nonzero_prefix=3 trailing_nuls=4093`** after. **Route B** — map the same offset and length twice, because `ranges.remove_and_unused` returns the existing entry and `:653` re-synchronises `fmap.version = fmap_info.version` unconditionally: a 10-byte file reads `10` before any mapping, still `10` after the first `mmap` (registered stale), and **`4096` after the second**. Route B is the sharper demonstration — same file, same process, one extra `mmap` between the two readings and nothing else. **How far the poisoning reaches — stated more carefully after review.** In the source the fast path is keyed purely on node id in a scheme-global map, with no per-client or per-handle check, so any requester hits it; and the entry outlives both `munmap` (`funmap` re-inserts the range) and `close` (`on_close`, `scheme.rs:996-1016`, only decrements `open_fds` and never removes the entry). **But the run does not measure cross-process:** the probe is a single process, and what it demonstrates is that a *different file descriptor* in that process sees the padded read. Nor is it truly "for the daemon's life" — the next write through the scheme bumps `fmap_info.version` and ends it. A second process reading the file route A mapped would close the gap in one boot. A read-until-zero loop, a config parser or a shell `$(cat …)` gets the padded answer and cannot tell it from a genuine 4096-byte file. **Fix shape (not implemented):** clamp the fast path's count to the node size, which the block never consults — the slow path's `tx.read_node` already returns the short count, so the two paths currently disagree about the same file. **Not measured:** the write path; whether anything E-OS ships actually mmaps a short configuration file (the defect is in what RedoxFS serves, not in a demonstrated victim); and Route A rests on `/etc/hostname` being unwritten earlier in the boot. **The control row is not the safeguard for that, contrary to what an earlier version of this row said:** it runs before any mapping exists, when `fmap_info.base` is still `null_mut()` (`:432`), so the guard at `:507` short-circuits and the version is never consulted — the control is blind to a version mismatch by construction. What actually evidences the assumption is the *after-mmap* row itself: had the version been stale, that read would have returned `3` as well, and it returned `4096`. Evidence: `dowody/redoxfs-fmap-padding-2026-09-06/`, with the failed first attempt kept at `dowody/fmap-fastpath-not-reproduced-2026-09-06/` | 🔴 |
| `R-F62` | **A single 128 KiB read from an ATAPI disc kills `ahcid` — the driver panics on a subtraction overflow and every AHCI device on the machine goes with it** (minted 2026-09-07 from the `R-F39` audit, finding #10, then **measured in a guest**). **The audit's *silent wrong data* label is right for large reads and wrong for small ones, and my first version of this row rejected it flat — corrected here after review.** Because `sector` advances by 2048 per pass, the loop escapes without underflow exactly when `sectors >= 2048` and `sectors mod 2048 < 64`: **a 4 194 304-byte read returns `Ok(4194304)` having copied only 131 072 bytes**, leaving 4 MiB of the caller's buffer untouched under a full-length success; a 4 196 352-byte read returns `Ok(4196352)` and issues its tail `READ10` at sector 2048 instead of 64, so the bytes it does write come from the wrong place on the medium; 8 388 608 returns `Ok(8388608)` having copied 262 144. Sizes in between — 131 072 through 4 194 303, and 4 325 376 — panic instead. Only the panic band was measured; the large-read band is derived from the arithmetic and is not observed here. `disk_atapi.rs:82-118`: `sector` counts **sectors** in every other use — `read10_cmd(block + sector, …)` and `buffer.offset(sector * blk_len)` — but the loop ends with `sector += blk_len` (`:117`), adding the **block size** rather than the number of blocks just transferred. With `blk_len = 2048` on optical media, `buf_len = (256 * 512) / blk_len = 64` sectors, so after one pass `sector` is 2048 where it should be 64. The loop is entered only when `sectors >= buf_len`, i.e. when the caller asks for **at least 131 072 bytes**; on the second evaluation of `:97`, `sectors - sector` is `64 - 2048` on `u32`, and the driver is built with overflow checks on. **Measured on an 8 MiB medium of 2048-byte sectors, each stamped with its own absolute offset, attached as `ide-cd` on `ide.0` with no other disk.** *Control, 65 536 bytes (32 sectors, below the threshold):* `n=65536`, `ascii=CD-OFF-000000000` — correct count, correct bytes, loop never entered. *Subject, 131 072 bytes (exactly the threshold):* **`thread 'main' (1) panicked at drivers/storage/ahcid/src/ahci/disk_atapi.rs:97:15: attempt to subtract with overflow` → `[ERROR ahcid…] Abort` → `Invalid opcode fault`.** The guest never reaches the next command; the client is left blocked on a scheme whose server is gone. **Nothing brings `ahcid` back.** It is spawned by `pcid-spawner`, a `type = "oneshot"` service that enumerates `/scheme/pci` once and exits; `daemon::Daemon::spawn` waits for a readiness byte and drops the `Child`; `init`'s final loop is a bare `waitpid` reaper and `ServiceType` has exactly four variants — `Notify`, `Scheme`, `Oneshot`, `OneshotAsync` — **with no restart among them**; and `grep -rn respawn` over the whole of `eos-base` returns **nothing**. So the AHCI storage stack stays down until reboot, and on a machine whose root sits on an AHCI port that includes the block scheme under the mounted root (`init.initfs.d/50_rootfs.service` runs `redoxfs … $REDOXFS_BLOCK` after `40_drivers.target`). This was checked after the row already had its severity *softened* — the correction ran the wrong way, and the right answer is that the blast radius was understated. **Blast radius, corrected after review:** `ahcid` is one process **per AHCI controller** (`main.rs:16` `pci_daemon`, one per PCI function; `:47` `format!("disk.{}", name)`), serving every port of that controller from a single `DiskScheme`, so the panic takes down every SATA disk **on that controller** — not the whole machine, and a second controller is unaffected. **It was not demonstrated:** this run's boot disk was NVMe and the disc was the controller's only device (`ahci-1`…`ahci-5` all `None`), so the collateral damage is a reading of `main.rs`, not a measurement. 128 KiB is the natural size for reading an ISO9660 directory extent. **The rest of the path is sound:** the same medium reads correctly at 2 KiB granularity at offsets 0, 2048 and 131072, and the scheme publishes the true size 8388608. **Retracted here:** an earlier note filed `ahcid`'s `Size: 0 MB` identify line as a lead toward finding #12 — that is a **false lead**, since ATAPI devices report zero sectors in IDENTIFY PACKET and capacity comes from READ CAPACITY, which the scheme evidently used. **Fixed — `eos-base!16` (`e402be5a`, merged as `f052057f`):** `sector += buf_len`, the number of blocks just transferred; the tail branch at `:119` was already correct and is untouched. **Measured after, on the same medium and harness:** the 64 KiB control is byte-identical to before (`fnv=b0fccec4319c4265`), so the working path is undisturbed; the 128 KiB read at offset 0 now returns `n=131072` with `ascii=CD-OFF-000000000` and **no panic**; the same read at offset 131072 returns a **different** digest with `ascii=CD-OFF-0000131072`, so the probe discriminates; a repeat at offset 0 gives the same digest, so it is stable; and the guest reaches `SUBJECT-DONE` and `ALIVE`, where before `ahcid` had aborted. **Not measured:** a real optical drive; the write path (`DiskATAPI::write` returns `EBADF` unconditionally at `:145`); whether anything E-OS ships issues such a read today; and whether a real caller issues such a read. **Settled rather than left open:** the increment does **not** reach the SATA path — `DiskATA::read` is `loop { match self.request(block, BufferKind::Read(buffer))? { Some(count) => return Ok(count), None => yield_now() } }`, with no chunking loop and no subtraction at all. Evidence: `dowody/atapi-128k-read-kills-ahcid-2026-09-07/` | ✅ |

---

## 11. Platform, process and release

### 11.1 CI and release-integrity recovery — `R-0xx`

*Historical context: GitHub Actions was disabled account-wide (HTTP 422, 0 completed runs), which
at audit time (2026-07-13) made every advertised pipeline inert. **That framing was superseded**
in 2026-07-23: integrity moved to **GitLab CI** — light gates (`secret-scan`, `integrity`,
`pin-check`, `docs-currency`, `rust-checks`) on shared runners, plus the heavy `build-image` and
boot-smoke on the self-hosted `eos-heavy` runner ([`docs/operations/ci.md`](docs/operations/ci.md)).
**And that framing has now been superseded in turn — see `R-009`.** The items below keep their final
statuses as the record of that recovery.*

| id | item | state |
|---|---|---|
| `R-001` | **Reality-ledger / verification-matrix document**, so "done" stops drifting from what boots. The document exists at [`docs/archive/reality-ledger.md`](docs/archive/reality-ledger.md) (generated 2026-07-13, reconciliation note 2026-07-23) and is listed in `docs/SUMMARY.md`. Its function is now largely served by [`docs/audit/`](docs/audit/) — see Annex C `[P0·S·🖥️]` | ✅ |
| `R-002` | **Local `make release` with real checksums** (`U-069`): `scripts/make-release.sh` builds the release and regenerates `release/SHA256SUMS` **over the actual retained artefact**, then minisigns locally so the install documentation's verify/dd steps work. The state it replaced: a `SHA256SUMS` dated Jul-5 listing a phantom `eos-0.1.0-<arch>.img` while builds produced `build/<arch>/eos/harddrive.img` at 1400 MiB `[P0·M·🖥️]` | ✅ |
| `R-003` | **Correct the doc↔reality claims that dead Actions had made false** (`U-069`): `install.md` and README no longer advertise a phantom download or inactive scanning; the `R-303` CI-build prose and the `R-1004` "live Pages site" claim were downgraded, and CodeQL/gitleaks/cargo-audit/release-signing were marked Actions-blocked `[P0·S·🖥️]` · needed `R-002` | ✅ |
| `R-004` | **Non-Actions CI**: GitLab light gates live since `U-070`; the heavy `build-image` plus boot-smoke runs on the registered self-hosted **`eos-heavy`** runner and passed even with shared minutes exhausted (`U-092`). *Operational note (2026-08-14): the `eosbuild` container on that runner is missing and must be recreated before heavy jobs go green again (`U-114`)* `[P1·L·🐧]` · needed `R-002` | ✅ |
| `R-005` | **Local scheduled security scans plus git hooks** (`U-070`): `.gitlab-ci.yml` gitleaks + integrity, `scripts/local-scan.sh`, `scripts/hooks/pre-push`, and a grep gate that fails on `println!.*password` / `TODO: Remove this debug` `[P1·S·🖥️]` | ✅ |
| `R-006` | **GitLab mirror configured and verified** — and the roles have since **inverted**: `gitlab.com/e-os` is the source of truth (development and CI) and GitHub `Gh0s777tt/*` is the read-only mirror (`ADR-0001`). Verified 2026-08-14: all 30 `repos.toml` repositories have identical branches and tags on both hosts. *Forks have no automatic mirroring — pushing one takes **two** commands* `[P2·S·🖥️]` | ✅ |
| `R-007` | **Unpushed `main` pushed; moot Dependabot branches pruned.** The three `github_actions/*` PRs targeted a deleted workflow and were closed 2026-08-14; `cargo/*` bumps stay open pending a build-container-verified update round `[P2·S·🖥️]` | ✅ |
| `R-008` | **First non-Actions signed pkgar publish** (`U-209`). The operator ran `publish-repo-pages.sh aarch64-unknown-redox`, which signed `repo.toml` hybridly (ed25519 64 B + ML-DSA-65 3309 B) and published **78 packages, 893 MB** to GitHub Pages. Verified live: `repo.toml`, `repo.toml.sig` and `eos-repo-sign.pub.toml` all return HTTP 200. This unblocked `R-701` and made a **live** check of the client-side closing verification possible (`R-703`). **x86_64 not yet published** `[P0·M·🖥️🔑]` · needed `R-002`, `R-701` | ✅ |
| `R-009` | **Restore CI capacity — the shared tier is unreliable, and the tier that does run is the developer's own Mac.** *Newly minted in this merge.* Neither predecessor gave this a number: the old `ROADMAP.md` carried it as an unnumbered row (`C-7`) inside the security roadmap, and v2 mentioned it only through `R-F12`. **Measured, three times, not opined:** GitLab pipelines abort in ~0 s on `ci_quota_exceeded` and have since 2026-08-28; **GitHub Actions produces no runs at all** for this repository — on 2026-08-30 a minimal `on: push` workflow on a fresh branch produced **no** run, neither queued nor red; and `C-6` establishes that every commit in history went straight to `main`, so even a working pipeline would check code **after** publication and mirroring. A local `scripts/verify.sh` run is today the only gate known to execute. **Downstream of this item:** `V2-MS04`, `R-601a`, `R-601b`, `S-14`, `R-F12`, and every "in CI" clause in this document. **Note on documentation drift found while writing this row:** `CLAUDE.md` §13.1 says the Actions canary measurement stays reproducible in `.github/workflows/_canary.yml`; **that file is not in the tree** (`ls .github/workflows/` → `ci.yml`, `docs.yml`, `lint.yml`, `release.yml`, `sbom.yml`, `scorecard.yml`, `security.yml`, `stale.yml`). The claim needs restoring or removing `[P0·M·🔑]` | 🔴 |

### 11.2 Release, repository and stability — `R-2xx`, `R-3xx`, `R-4xx`, `R-10xx`

| id | item | state |
|---|---|---|
| `R-201` | Full documentation site, green CI and repository hardening for the v0.2.0 "Identity" milestone. The site and hardening exist; "green CI" is blocked on `R-009` | 🟡 |
| `R-207` | A usable out-of-the-box toolset after a fresh install. **Named 2026-09-04**: the archiver CLI from `PR-021` (one binary from the product crate — every `wip/` archiver recipe fails to build: `7-zip` "missing script for gnu make", `ouch` "compilation error") and `ncdu` 1.22, which `config/x86_64/ci.toml:161` already builds and no shipped config lists — a one-line `[packages.ncdu]` away | 🟡 |
| `R-303` | **Reproducible release pipeline** tag → image → release. The pipeline exists; **byte-for-byte reproducibility is unproven**. `.config` and `cookbook.lock` are now **tracked** (`U-168`, `U-169`), so the main obstacle is gone, but **nobody has run the comparison**. Until someone does, it is not a fact. Same work as `V2-MS07`; five measured obstacles remain, from unpinned apt (`S-15`) to embedded timestamps | 🟡 |
| `R-402` | Extended hardware and driver coverage for the v0.4.0 "Reach" milestone | 🔴 |
| `R-403` | Test matrix on real hardware — the umbrella over `R-607b` and `R-923` | 💡 |
| `R-1002` | **LTS branch plus stability policy.** The `lts/0.1` branch exists (verified: `remotes/github/lts/0.1`) and the policy exists; **what is open is the ABI commitment at 1.0**. *This was one of the five contradictions resolved during the previous merge: v2 had it 🔴 while the branch and policy already existed* | 🟡 |
| `R-1003` | **Package repository as a product.** *Its "remaining" list used to name three things that were already done elsewhere in the same file.* Rewritten honestly: first publish ✅ (`R-008`), `50_eos` wired on aarch64 ✅, key generated ✅. **What actually remains: the x86_64 publish and an application ecosystem** — 65 packages against tens of thousands | 🟡 |
| `R-1010` | **Enable the `contain` package** — Qubes-style compartmentalisation. `recipes/core/contain` **exists in the tree and is switched off**; `Namespace::fork()` is unprivileged and can only **narrow**. *Newly minted as a register row in this merge.* v2 §12.7 stated outright that the register did not contain this item **while `EP-2` and `M4` depended on it** and `CLAUDE.md:593` cited it as `R-1010`; `docs/adr/0011-installer-wizard-architecture.md` and `docs/architecture/installer-profiles.md` cite it too. Shipping a milestone that depends on a non-existent identifier is not acceptable, so it is a row: enable `contain` and define per-application policy. Audit finding `C-5`; the precondition of sandboxed profile import (M4) and the substrate `M-1` builds on `[P1·L·🖥️]` | 🔴 |
| `R-1004` | Legacy "live Pages site" claim, quoted only inside `R-003`'s body as prose that had to be downgraded. **Retired — not an item.** See [Annex C](#annex-c--retired-documents-and-retired-identifiers) | ❌ |

### 11.3 Testing, coverage and gates — the standing state, and the automation to add — `TQ-*`

Not a new item; the standing context every row above is measured against — followed, since
2026-09-03, by the register of what the owner asked to be **automatic**: the state of test coverage
and of *security* coverage, checked on every change rather than on request.

#### 11.3.1 Standing state (re-measured 2026-09-03)

- **`scripts/verify.sh`** is the one command run before every commit: format → lint → typecheck →
  build → test → project gates → security scans, exiting non-zero on any failure. It **calls** the
  same commands the pipelines do rather than restating their rules. **On `main` today: 16 stages,
  16 PASS, 0 FAIL, 0 SKIPPED.** `CLAUDE.md` §9 still called this script "PENDING" under the name
  `eos-verify.sh`; corrected in the same change as this section.
- **A missing tool is `SKIPPED` *and* a non-zero exit** (`U-140`); the deliberate escape is
  `--allow-missing`, and then the summary names what was **not** measured.
- **`exit 1` ≠ `exit 2`.** 1 = the gate **found a defect**; 2 = the gate **could not run** (`U-177`).
- **`ci-integrity.sh` has checks 0…15** (15 = `eos-check-no-caches.py`, 2026-09-01), plus three
  added 2026-09-03: **16** `scripts/eos-check-roadmap.py` (in-document anchors, duplicate heading
  numbers, one status per identifier, ✅ only with an evidence token in the row — it found two rows
  on its first run, `R-301` and `R-502b`, fixed in the same change), **17**
  `scripts/eos-check-assets.sh` (byte-identical assets under two paths, the 5 MB limit, orphan
  images — first run: 1 duplicate pair, 26 orphans, §11.7) and **18** `scripts/eos-check-summary.py`
  (every tracked docs page listed in `SUMMARY.md`, every listed page exists — first run: 14 unlisted
  pages). All three carry a negative self-test (`--selftest`, `EOS_ASSETS_SELFTEST=1`).
- **Coverage** is measured on every `verify.sh` run: `tools/eos-repo-sign` is **gated** at
  `--fail-under-lines 38` (measured 41.06 %); the vendored `redox_cookbook` is reported without a
  threshold — gating coverage on code we do not maintain is re-litigating someone else's tree. The
  same two legs run in `.gitlab-ci.yml` `coverage` and in `.github/workflows/ci.yml` `coverage`
  (matrix: `eos-repo-sign` gate=true min 38; `redox-cookbook` gate=false).
- **What is NOT measured anywhere today:** the product crates (`eos-ui`, `eos-notes`, `eos-control`,
  `eos-guard`, `eos-sysmon` — 0 `#[test]` in the three measured, §7.5.2), the forks of type C
  (`eos-installer`, `eos-pkgutils`, `eos-userutils`…) beyond what upstream's own tests do, and
  **any security-coverage number at all**: nothing counts `unsafe` blocks, nothing checks that a
  parser has a fuzz target, nothing tracks which crates run `cargo-deny`/`osv-scanner`.
- **Runners — measured, not assumed (2026-09-03).** GitLab shared minutes are exhausted
  intermittently (`R-009`, §3.0): the newest `main` pipeline (2026-09-02T21:08) had all 10 light-tier
  jobs fail on `ci_quota_exceeded`. The GitHub mirror's workflows **do not execute either**:
  `gh api …/actions/workflows/security.yml/runs` → `total_count: 0`, `lint.yml` 0, `ci.yml` last run
  2026-06-15 — the 294 "runs" on the repository are Dependabot's, not ours. An earlier draft of
  this section said the GitHub workflows run; that was wrong and is corrected here. **The only
  runner that has executed a job since 2026-09-01 is the self-hosted `eos-heavy` Mac** (online,
  concurrency 1; `build-image` passed 2026-09-01 19:14 UTC). New automation therefore lands **in
  `verify.sh` first** (always runs) and **as an `eos-heavy` job second** (`TQ-011`), with the
  shared-runner and GitHub copies kept as the identical third — they judge nothing today.
- **Known flake, measured:** `cook::cook_build::tests::file_system_loop_no_infinite_loop` (#20) —
  thread-order dependent; the `test` stage serialises the vendored suite; not fixed by that.
- **Tools on this host (2026-09-03):** `cargo-llvm-cov`, `cargo-deny`, `semgrep`, `gitleaks`,
  `osv-scanner`, `shellcheck`, `yamllint` present; `cargo-audit`, `cargo-geiger`, `cargo-mutants`,
  `cargo-fuzz`, `cargo-nextest`, `pyflakes` **absent** — every row below that needs one says so.

#### 11.3.2 What "security coverage" means here, so it can be a number

A coverage percentage says which lines a test executed. It says nothing about whether the
*dangerous* lines were tested, or whether the crate's dependencies are known-bad. Five proxies,
each computable from the tree with tools on this host or one `cargo install` away, each with a
floor that can go red:

| proxy | what it counts | tool | floor to start |
|---|---|---|---|
| **SC-1 unsafe hygiene** | `unsafe` blocks/fns in own code with a `// SAFETY:` comment on the preceding line ÷ all `unsafe` | `grep` (script), later `cargo-geiger` | 100 % of *new* unsafe; measured baseline for old |
| **SC-2 parser fuzzing** | files matching `parse|decode|deserialize|from_bytes|from_str` in own crates that have a `fuzz/fuzz_targets/*` target | `cargo-fuzz` (absent) | baseline; then "no new parser without a target" |
| **SC-3 dependency policy** | own crates with `deny.toml` **and** an executed `cargo-deny check` **and** `osv-scanner` in `verify.sh`/CI ÷ all own crates | `cargo-deny`, `osv-scanner` (present) | 100 % — a crate outside the scan is a crate nobody watches |
| **SC-4 negative tests on inputs** | externally facing inputs (CLI args, env vars, files read, sockets) with at least one test that feeds a hostile value ÷ all such inputs, per crate; a manifest lists them | a `tests/inputs.toml` per crate + a script that checks each named input has a test | baseline; new inputs 100 % |
| **SC-5 mutation score on trust code** | killed mutants ÷ mutants in `tools/eos-repo-sign::verify()`, `eos-bootloader` manifest verification, `eos-installer` crypto paths | `cargo-mutants` (absent) | measured once, then "does not fall" |

Line coverage stays the sixth number (**SC-0**), per crate, with the floor policy already in force.

#### 11.3.3 The register

| id | item | today | to build | size |
|---|---|---|---|---|
| `TQ-001` | **One coverage report for every own crate, published where a reader looks** *(✅ **done 2026-09-03** — `scripts/eos-coverage-report.sh` + `coverage-floors.toml`, stage `coverage-report` in `verify.sh` (18 stages now), page `coverage.md` under `docs/reference/`. Measured 41.06 % lines gated at 38, cookbook 6.26 % advisory. **A defect was found in the gate itself before it landed:** it read the text table's first `%` column, which is *regions* (38.12 %), against a *lines* floor — passing by 0.03 of a point on the wrong number; it now reads the JSON, where every number has a name)* — `scripts/eos-coverage-report.sh` runs `cargo llvm-cov --summary-only` over `tools/eos-repo-sign` and every type-A product checkout it can reach, writes a page `coverage.md` under `docs/reference/` (a table: crate · lines % · floor · date · commit) and fails if any gated crate is under its floor | one crate gated, one advisory; number visible only in a log | the script, the generated page, a `verify.sh` stage `coverage-report`, the `local-gates` job (`TQ-011`) uploading the page as an artifact | M |
| `TQ-002` | **Security-coverage report** *(✅ **done 2026-09-03** — `scripts/eos-security-coverage.py` + `security-coverage.toml`, stage `sec-coverage`, page `security-coverage.md`. SC-1 100 % (0 of 0), SC-3 100 % (1 of 1), SC-2/SC-5 SKIPPED with the tool named. **Second defect caught before landing:** `SC-4` with zero declared inputs reported 100 % and satisfied a floor of 50 — a vacuous truth satisfies any threshold, exactly the gate-that-cannot-fail shape; an unmeasurable proxy is now SKIPPED, never a pass)* — `scripts/eos-security-coverage.py` computes SC-1, SC-3, SC-4 from the tree today (no new tool), SC-2 and SC-5 when their tools are present (`SKIPPED` + exit 2 otherwise, never silently 0 %), writes a page `security-coverage.md` under `docs/reference/`, fails when a floor is crossed | nothing | the script with a `--selftest` that plants an `unsafe` without `SAFETY:` and expects red; floors in a `security-coverage.toml`; stage in `verify.sh`; runs inside `local-gates` | M |
| `TQ-003` | **First test suites and floors in the product crates** — `eos-ui` (platform init, font registration), `eos-notes` (SQLite storage round-trip, Markdown), `eos-control` (blake3 baseline diff, process list parsing, network pane model); `--fail-under-lines` set to the *first measured value minus nothing* so the gate catches regression from day one | 0 / 0 / 0 tests | tests, `cargo llvm-cov` in each repo's CI, the crate rows in `TQ-001` | M |
| `TQ-004` | **`cargo-audit` and `cargo-geiger` installed and wired** — audit duplicates `osv-scanner` on the advisory database but runs offline from `Cargo.lock`; geiger gives SC-1 without the grep approximation | both absent | `cargo install --locked`, pins in `verify.sh` `have` checks with the install hint; the `eos-heavy` host gets the same installs | S |
| `TQ-005` | ✅ **first targets done 2026-09-04 — and `SC-2` was counting the wrong things in BOTH directions.** Two targets for `tools/eos-repo-sign`: `hex_decode` (**4 006 970 runs in 21 s**, no crash) and `parse_kv` (**1 063 806 runs in 26 s**, no crash). They assert **properties**, not sensible output: a hex decode either fails or yields exactly half as many bytes as characters **and** re-encodes to the same value, and a parsed document never turns a comment or a `[section = x]` header into a field — the forged-header case being the one that decides what a signature covers. **The parsing surface moved behind a library target**, because a fuzzer cannot link against a binary crate; the functions were *moved*, not copied, so the hostile-input tests keep attacking the code that ships. **`SC-2`'s own bugs:** its target glob only matched at the repository **root**, so targets inside a crate counted as zero, and it counted the fuzz targets **themselves** as parser files — a target made the denominator worse as fast as it improved the numerator, which is a metric that punishes the fix. Now counted per **crate**, floor **100.0**, proven able to fail: hide the targets → 0 %, RED, exit 1. **Second parser covered 2026-09-04:** `Repository::from_toml` in `eos-pkgutils` — the index a device fetches from a mirror — **2 146 750 runs, no crash**, and the run found `PR-019`. **The corpus turned out to be the whole game:** with one realistic seed a deliberately planted bug (letting `/` through `PackageName::new`) survived **1 840 305 runs undetected**; with four shape-aware seeds it was caught. libFuzzer's byte mutations almost never produce valid TOML carrying a quoted key with a specific character in it. Original entry: **Fuzz targets for the trust parsers** — `tools/eos-repo-sign` (index parsing, signature envelope), `eos-pkgutils` (`repo.toml`, pkgar header), `eos-bootloader` (manifest) — `cargo-fuzz`, 60 s per target in CI, corpus committed | none | `cargo-fuzz` install, `fuzz/` per crate, a scheduled `eos-heavy` job (fuzzing on every push burns hours for nothing) | M |
| `TQ-006` | ✅ **done 2026-09-04 — and the critic was right.** `cargo-mutants` on `tools/eos-repo-sign` found **`replace && with || in verify` MISSED**: `ed_ok && pq_ok` is the entire guarantee of a hybrid signature — both algorithms must verify, so a break of either alone is not enough — and **nothing in the suite could tell it from `||`**. The line was **covered** (41.06 %) and **not checked**. Killed by extracting `hybrid_ok()` and testing all four rows of its truth table; three of the four are exactly what `&&` gives and `||` does not. Score **52.2 % → 60.4 %** (24/46 → 29/48), gated by `scripts/eos-mutation-score.sh` at a floor of 58 with a `--selftest` of 8 cases. **`SC-5` in the security-coverage report stops being SKIPPED** and reads 60.4 %. Two of my own measurements were wrong on the way and are kept visible: `-j 4` gave 14, 18 and 21 missed on the same tree (timeouts count as missed, so the score moved with machine load — the gate pins `-j 1`), and a `mutants.toml` exclusion I wrote **filtered nothing**, which the numbers proved by not changing. One survivor is **unkillable and named as such**: `| → ^` in `hex_decode` is an equivalent mutant, since the two nibbles occupy disjoint bits. Next: `eos-bootloader` | absent | install, a `mutants.toml` excluding I/O, a nightly `eos-heavy` job, the number in `TQ-002`'s page | M |
| `TQ-007` | ✅ **first manifest done 2026-09-04** — `tools/eos-repo-sign/tests/inputs.toml` declares **four** inputs (public-key file, signature file, hex field, key/value document), each naming the test that feeds it hostile values. All four are parsed **before any signature has been checked** — unavoidable, and exactly why that is the surface worth attacking. The tests assert a **refusal**, not a panic and not a silent zero: odd-length hex, out-of-alphabet nibbles, an embedded NUL, full-width Unicode digits, a repeated key, a 100 000-character value, and a forged `[ed25519 = ...]` section header that must not become a field. **`SC-4`'s floor rose 0.0 → 100.0** in the same change, which is the only honest floor for a rule of the form *every X has a Y*: declaring an input is admitting it needs a test, so the next one added without one turns the proxy red the moment it is declared. Proven able to fail: a fifth input with no `negative_test` → 80 %, RED, exit 1. Remaining crates still to declare theirs. Original entry: **Negative-input manifest per crate** (`tests/inputs.toml`: every CLI flag, env var, file format, socket the crate reads, and the test that feeds it garbage) — the SC-4 source of truth; `eos-security-coverage.py` refuses an input with no test | nothing | the manifest format, the first three manifests (`eos-repo-sign`, `eos-installer`, `eos-control`), the check | M |
| `TQ-008` | **Lints that are security policy, enforced as errors** — `unsafe_op_in_unsafe_fn`, `missing_docs` (`API-003`), `clippy::undocumented_unsafe_blocks` (this *is* SC-1 at compile time), `clippy::unwrap_used` in trust code | `eos-ui` has `warn(missing_docs)`; nothing else | `[lints]` tables in each own `Cargo.toml`, `-D` in CI; measured before/after count of warnings | S per crate |
| `TQ-009` | **Script tests as a suite, not folklore** — every own script's negative test collected in `scripts/tests/run.sh` (today they live in MR descriptions and in `ci-integrity.sh` comments); `verify.sh` runs the suite | 2 self-tests (`eos-check-roadmap.py`, `eos-check-assets.sh`) plus ad-hoc | the harness (one function per script: setup → run → expect exit N → expect a line), the first ten scripts, the stage | M |
| `TQ-010` | **The two numbers on the README badge row and in the roadmap page** — line coverage of gated crates and the security-coverage summary, generated, never typed | typed numbers (38 %, 41.06 % — in this section and in `CLAUDE.md` §5.10; `README.md` carries none) | `TQ-001`/`TQ-002` outputs consumed by `README.md` through the marker-value gate pattern (`R-F05`) | S |

| `TQ-011` | **A `local-gates` job on the `eos-heavy` runner** — `bash scripts/verify.sh` on every merge request and on `main`, `needs: []`, `tags: [eos-heavy]`, its summary published as an artifact; the runner has every tool `verify.sh` names | the 16 stages run only on the developer's machine; every shared-runner and GitHub job fails on quota or never starts | the job (added 2026-09-03 in the same change as this row; first pipeline is its proof), then the merge rule "the `local-gates` job is green" replaces "all jobs failed on quota" in §3.0 | S |
| `TQ-012` | **Semgrep rules for this project's own invariants** — the blocking tier scans 11 of 71 files (Python only) with 0 ERROR rules for Rust or bash; add `.semgrep/eos.yml` (bash: `\|\| true` on a gate line, unquoted `$@`; Rust: `Command::new("sh")`, `.unwrap()` on decode results in trust code, `temp_dir` outside `cfg(test)`) and pass `--config=.semgrep/` | 19 rules / 11 files at ERROR; the two Rust INFO findings never reach the gate | the rule file with a planted-violation self-test, `verify.sh` stage `semgrep` widened | S |
| `TQ-013` | **The network-only invariant gates moved to the runner that works** — `mirror-drift` and `rebase-check` need git + python3 + network, all present on the `eos-heavy` Mac; today both fail on quota in every scheduled pipeline | 8 of 17 GitLab jobs cannot gate (allow_failure, manual, dormant, schedule-only); the two that guard fork drift have not run green since 2026-09-01 | `tags: [eos-heavy]`, `needs: []` on both; `rebase-check` keeps `allow_failure` | S |

**Order that costs least:** `TQ-011` (one job; done in this change) → `TQ-004` (installs) → `TQ-008`
(lints, each a one-line change with a measured warning count) → `TQ-013` → `TQ-012` → `TQ-001` →
`TQ-002` → `TQ-003` → `TQ-009` → `TQ-007` → `TQ-005` → `TQ-006` → `TQ-010`. The first five are a
week; `TQ-005`/`TQ-006` need a scheduled runner and are the only rows that cost minutes.

---

### 11.4 Everything on E-OS: the server edition and the cloud platform — `CS-*`

**Name (owner, 2026-09-03, Q9): E-Cloud.** The `CS-*` identifiers stay; the product is called E-Cloud from here on.

Premise, owner's words (2026-09-02): *"I would like everything to be on Redox and E-OS — where it
can be."* The register below takes that literally: E-OS is the **host**, not a guest managed by
someone else's hypervisor. Where that is not possible today, the row says what has to exist first
and does not pretend.

**What the kernel has.** Measured 2026-09-02 on the `eos-kernel` fork: the only references to
virtualisation are `cpu.rs:131` printing the CPUID `vmx` flag, ACPI GTDT timer fields, and
`hvc #0` in `stop.rs` — a call into the **firmware's** PSCI to halt or reboot. No VMCS, no VMCB,
no `vmlaunch`, no `vmrun`. **Redox has no hypervisor.** That single fact orders everything below.

**What exists as a recipe.** In the image and building today: `nginx`, `openssh`, `curl`. Present
only under `recipes/wip/` — a recipe exists but is excluded from every image and its build state is
**unknown**: `postgresql16`, `sqlite3`, `mariadb`, `mysql-server`, `redis`, `postfix`, `opensmtpd`,
`wireguard-rs`, `haproxy`, `caddy`, `docker`, `podman`, `nomad`, and `qemu` (a TCG-only port from
`jackpot51/qemu`, with `#TODO: verify if the crash was fixed` as its first line). Absent entirely:
`dovecot`, `exim`, `containerd`, `kubernetes`, `k3s`, `etcd`.

**Three tiers, in the order they can be delivered.**

*Tier 1 — a server edition that runs on E-OS now.* Everything here is user-space Rust or already a
recipe; the gap is a config, a hardening pass and proof.

| id | item | today | to build | size |
|---|---|---|---|---|
| `CS-001` | **An E-OS server edition** — headless: no Orbital, serial + ssh login, `nginx`, RAID-1, FDE, the first-boot password rules of §6.6 | upstream ships `config/server.toml` (includes `minimal.toml`; `bash`, `bottom`, `curl`, `git`, `installer`, `kibi`, `redoxfs`; `contain` commented out *"needs to update dependencies"*) and `config/x86_64/server-demo.toml`; the desktop image already pulls `server.toml`'s package set through `desktop.toml:3` — but CI and `eos-build.sh` build **only** `CONFIG_NAME=eos`, so no headless image has ever been built or booted here | an `eos-server.toml` layered on it with the E-OS trust chain, the §6.6 password rules, **managed SSH host keys** (`R-606`: openssh ships, keys are unmanaged) and a stated answer on packet filtering (`R-904` is a new subsystem — a server edition without a firewall must say so); the CI and smoke rows are `CS-010` | M |
| `CS-009` | **A "the `wip/` recipe builds" gate** *(decided 2026-09-03: agreed: the gate may answer "does not build" — Q10)* — the first step of every Tier 1 row | 15 recipes named above, build state **unknown**; `wip/vm/qemu` opens with `#TODO: verify if the crash was fixed` | one `cook-wip` job per recipe with a PASS/FAIL table in `docs/reference/packages.md`; the honest outcome may be "does not build", which then rewrites the "to build" column of `CS-003`/`CS-006`/`CS-008` | S |
| `CS-010` | **Headless boot-smoke and install-smoke for the server edition** | `server.toml` never built here; the harness knows only `eos login:` | a `CONFIG_NAME` axis in `.gitlab-ci.yml:449-452` and `eos-build.sh`, an `ssh` banner instead of the greeter as the PASS condition, `login_schemes.toml` without `orbital` | M |
| `CS-002` | **Object storage and backups** — an S3-compatible API in Rust over RedoxFS, versioning, server-side encryption with the repo-sign key hierarchy | nothing | a new type-A crate; the API surface is well specified upstream (S3), the storage engine is RedoxFS | L |
| `CS-003` | **Managed SQL** — first `sqlite3` as a service (recipe exists in `wip/`), then `postgresql16` | both in `wip/`, unbuilt | prove the recipes build and survive `cargo test`-equivalent load; supervision, backup to `CS-002` | L |
| `CS-004` | **Identity, RBAC and policies** — one IAM model for the console, the API and the OS accounts | `login_schemes.toml` is a per-user scheme allowlist — the kernel-side half already exists | a policy language, a token service, audit log (`C-9`, planned) | L |
| `CS-005` | **Monitoring, logs, alerts** — `eos-sysmon` grown into a node agent; central log store; alert rules | `eos-sysmon` (type A) exists as a desktop monitor | agent mode, a wire format, a store, an alert path (mail via `CS-008`) | M |
| `CS-006` | **Networking: VPN and load balancing** — `wireguard-rs` and `haproxy` are in `wip/` | recipes exist, unbuilt | prove them, then a control API; a **Rust** L4 balancer is a type-A candidate if `haproxy` will not port | L |
| `CS-007` | **Usage metering and billing** — per-resource counters, invoices | nothing | needs `CS-004` and `CS-005` first; the numbers must be the same ones monitoring shows | M |
| `CS-008` | **Mail** — `opensmtpd`/`postfix` are in `wip/`; there is **no** IMAP server anywhere (`dovecot` absent) | recipes for the MTA only | port one MTA, write or port an IMAP server; this is also what the website's built-in mail (`WS-*`) needs | L |

*Tier 2 — isolation without a hypervisor.* Redox's own primitive is the scheme namespace:
`Namespace::fork()` is unprivileged and can only **narrow** (`R-1010`, the `contain` package).
That is the honest basis for "containers on E-OS" — and it is not Docker.

| id | item | today | to build | size |
|---|---|---|---|---|
| `CS-101` | **E-OS containers** — a process tree with a narrowed scheme set, its own root, resource caps | `recipes/core/contain/recipe.toml` is a 5-line **unpinned** stub with no `source/` or `target/` fetched anywhere in the tree; what does exist is the session side — `config/desktop-contain.toml` (`pass_schemes`, `sandbox_schemes`, `getty --contain`) and `-C/--contain` support in the `eos-userutils` fork's `getty.rs`; `R-1010` | an image format (pkgar-based), a runtime, a CLI; this is the real "serverless" substrate too (`CS-103`) | XL |
| `CS-102` | **An orchestrator in Rust** — scheduling `CS-101` containers across `CS-001` nodes, health, restarts, rolling updates | nothing; `nomad` is in `wip/` unbuilt, `kubernetes`/`etcd` absent | do **not** call it Kubernetes: it will not run Kubernetes workloads. A native scheduler with a compatible-enough API is a later, separate question | XL |
| `CS-103` | **Functions** (run code without a server) | nothing | thin layer over `CS-101` with a trigger model | M |

*Tier 3 — virtual machines, Windows and Linux guests, on E-OS as the host.* Blocked on the kernel.

| id | item | today | to build | size |
|---|---|---|---|---|
| `CS-201` | **A hypervisor in the Redox kernel** *(RFC drafted 2026-09-03 as `docs/rfc/0001-hypervisor-in-redox.md` — **draft, not submitted**; measured against `redox-os/kernel` `f4d59db5`. Sending it upstream is the owner's action, not tooling's — Q11)* *(decided 2026-09-03: **RFC to Redox upstream first**, drafted as `rfc/0001-hypervisor-in-redox.md` under `docs/` in the next change; not posted by tooling — Q11)* — VMX and SVM on x86_64, EL2 on aarch64, an EPT/NPT-backed memory model, VM exits routed to a user-space VMM | **nothing** (measured above) | kernel work of a kind this project has never done; §5.6 area, upstream-facing; must be designed with Redox upstream or it becomes an unrebaseable fork | XL |
| `CS-202` | **A user-space VMM in Rust** (virtio devices, a guest console) | nothing | after `CS-201`; a `firecracker`/`crosvm`-shaped crate | XL |
| `CS-203` | **Linux and Windows guests** | not possible on E-OS today | after `CS-202`; Windows additionally needs UEFI + TPM emulation and licensing the owner must resolve | XL |
| `CS-204` | **Interim: TCG emulation** — `recipes/wip/vm/qemu` ported without acceleration | unbuilt, `#TODO` crash | the only way to run a guest on E-OS before `CS-201`; **slow by construction**, useful for CI-style workloads, not for a product | L |
| `CS-205` | **Big data, AI/ML services** | nothing; no GPU driver, no BLAS in the image | after `CS-101`/`CS-201`; a GPU driver is its own programme (§8) | XL |

**Reading the tiers.** Tier 1 is buildable now and is what "server edition" means in 2026. Tier 2
is real work on Redox's own primitives and is worth more than porting Docker. Tier 3 starts with a
kernel hypervisor that does not exist, and everything the owner listed under VMs, Windows/Linux
servers, Kubernetes, BigQuery-class analytics and AI sits behind it. `§14.7` says what this
document therefore refuses to promise.

---

### 11.5 The project website — `WS-*`

Premise, owner's words (2026-09-02): a Microsoft-style portal — multilingual with nothing
hardcoded, a current toolchain, accounts (register, log in, delete), built-in e-mail, search,
support with tickets / mail / AI chat / FAQ, a live changelog, a developer section, legal pages
(contact, privacy, terms, trademarks), product pages, gated downloads with a switch, accessibility,
a privacy-and-security section, About, and API information & settings. Hosted **on E-OS where it
can be** (§11.4, `CS-001`).

**What exists** (inventory 2026-09-02, read-only, `main` `e34a5188e`): an mdBook documentation site
— `book.toml`, `docs/SUMMARY.md` (install, FAQ, known issues, security, ADRs), a GitLab `pages` job
publishing to `https://e-os.gitlab.io/e-os/`, a GitHub Actions `docs.yml` building the same book
plus rustdoc to GitHub Pages, and a `docs-pdf` job producing `eos-docs.pdf`. `SECURITY.md` states
the disclosure process. The last successful publish date of either site is **[UNVERIFIED]**: every
GitLab job has failed on quota since 2026-08-28, and the GitHub side was not confirmed.

**What does not exist** — searched `package.json`, `*.tsx|vue|svelte`, `next|astro|nuxt|vite.config*`,
`locales/`, `*.po|pot|ftl|mo|xliff`, `PRIVACY*|TERMS*|EULA*|TRADEMARK*|ACCESSIBILITY*`, `Dockerfile`/
compose for a web service, across the repository: no frontend, no backend, no i18n infrastructure,
no privacy policy, no terms, no accessibility statement, no accounts, no mail, no tickets, no search
beyond mdBook's built-in. Adversarial re-check (2026-09-02) narrowed three of the first pass's
"missing" claims, and they are stated here as found: a root `NOTICE` (copyright, AGPL-3.0, Redox/MIT
provenance, a **trademark reservation** for the E-OS name at `:33-35`) exists, so what is missing is a
standalone trademark *policy*, not any trademark statement; a **support policy** exists twice —
`SECURITY.md:29-52` (response commitments 72h/7d/30d/90d, supported versions) and
`docs/reference/stability.md:37-45` (support lines: rolling / `lts/0.1` / checkpoint); and a public
**download surface** exists without any gate — the signed package index on GitHub Pages
(`gh0s777tt.github.io/eos-pkg-aarch64`, live, HTTP 200; x86_64 404) and the nightly images as
1-week CI job artefacts (`.gitlab-ci.yml:517-522`, `:635-640`).

**Two halves, because they have different homes.** The *static* half (content, changelog, docs,
legal pages, product pages, download page) can be built now and served by `nginx` on `CS-001`.
The *dynamic* half (accounts, mail, tickets, AI chat, API settings) is a set of services with a
database and secrets; it cannot live in this orchestration repository and cannot run on static
Pages. On E-OS it needs `CS-003` (a database) and `CS-008` (mail) first — which is why it is
sequenced after Tier 1, not alongside the static half.

| id | item | today | to build | needs | size |
|---|---|---|---|---|---|
| `WS-001` | **Separate repository `eos-website`** *(✅ **done 2026-09-03**, and **deployed the same day** — the site had been sitting at **zero Pages deployments** because its jobs asked for `tags: [eos-heavy]` and the runner was a *project* runner bound to `e-os/e-os` alone: every job sat at `stuck_pending_no_matching_runners`, which is a stuck pipeline rather than a red one and therefore looks like nothing. After enabling the runner for the project the whole pipeline went green in one run — `i18n`, `changelog`, `contrast`, `pipeline`, `gates-negative`, `pages` — and Pages recorded its first deployment at **2026-09-03 11:14:52 UTC**, **27 pages**, both locales, all seven products listed, the downloads gate rendered. Pages access stays **private**: the owner said the site is hosted "locally for now, on a server later", so making it world-readable is their switch to flip, not mine.)* — `e-os/eos-website` created and pushed with a GitHub mirror: Astro, static, twelve pages in `pl` and `en`, every string from message catalogues, gates that can go red (`check-i18n`, `check-contrast`, `check-changelog`, `check-built`, `check-ci`) plus `negative-tests.sh`, which breaks each of them on purpose in a throwaway copy and asserts both the exit code and the message)* *(decided 2026-09-03: repository `e-os/eos-website` + mirror created 2026-09-03 — Q6, Q13)* (type A) with its own CI, lockfile-pinned toolchain, the same secret/supply-chain gates as here | nothing | the repository, a `verify.sh` for it, an entry in `repos.toml` | — | S |
| `WS-002` | **i18n as the first commit, not the last** — every string in message catalogues, locale negotiation, RTL-ready layout, Polish and English as the first two locales | mdBook is single-language; docs are mixed PL/EN with no switch | a catalogue format and the build step that fails on an untranslated key | `WS-001` | M |
| `WS-003` | **Static site: home, About, products, developers, changelog, downloads, legal** *(the roadmap page half **done 2026-09-03**: `docs/roadmap/index.html` ships inside the mdBook tree, so the existing `pages` job publishes it at `/roadmap/` with no CI change. It is a **view**, not a second plan — the eight milestone tiles show the marks from §3.4 and check 19 (`eos-check-roadmap-page.py`) compares them at every `ci-integrity` run. The mark is read out of the tile's **visible text**, because §5.4 says a gate on presence is not a gate: a hidden attribute can stay right while the tile a person reads goes wrong. Four controls measured, not assumed — flip the mark in the plan → red naming M1; flip it on the page → red naming M2; cite `R-607z` → red naming the identifier; hide `ROADMAP.md` → **exit 2**, the instrument code, not exit 1)* | mdBook covers docs only | the remaining pages generated from this repository's `CHANGELOG.md` and `README.md` the same way, so the site cannot drift from them (the drift this file documents in §1.4 is the reason) | `WS-002` | M |
| `WS-004` | **Legal pages that exist as documents first** — privacy policy, terms, trademark policy for the "E-OS" name, accessibility statement | `NOTICE` reserves the trademark and states provenance; `SECURITY.md` and `stability.md` are the support policy; privacy, terms and accessibility do not exist | the owner writes or commissions them; the site renders them; not a coding task | owner | S |
| `WS-005` | **Downloads with a real gate** *(the hosting half **done 2026-09-03**: the `pages` job moved to the `eos-heavy` runner and lost its `allow_failure`. Measured before the move — Pages had exactly one deployment, **2026-09-01 16:31 UTC**, and nothing since: every later run died in ~0 s on `ci_quota_exceeded` while `allow_failure: true` kept that out of the pipeline badge, so the published site froze two days behind `main` and looked fine. The job now asserts its own artefact — `mdbook build` **exits 0 on an empty book** (measured), so `test -s public/roadmap/index.html` is what stands between a green badge and a published empty site. The gate half is untouched and still needs `CS-004`.)* (decided 2026-09-03: hosted on GitLab Pages for now, the `pages` job on the `eos-heavy` runner; the static host cannot enforce the gate server-side, so artefact links are simply not published until the flag flips — Q7)* — "developers only" until the owner flips it | ungated and public already: the package index on GitHub Pages (aarch64 live) and nightly images as CI artefacts; a GitHub Release object exists for `v0.1.0` only | the switch must be **server-side** (`CS-004` identity): a client-side toggle on a static host is decoration, not access control | `CS-001`, `CS-004` | M |
| `WS-006` | **Search** across docs, changelog, products, support | mdBook's built-in only | a static index for the static half; a service for tickets/FAQ later | `WS-003` | S |
| `WS-007` | **Accessibility** — keyboard, contrast, screen-reader landmarks, reduced motion, a published statement | nothing | built into `WS-002`'s layout system; audited with a real screen reader, not a linter alone | `WS-002` | M |
| `WS-008` | **Accounts** — register, log in, delete, with the same credential rules as the OS (§6.6) | nothing | a service on `CS-001` with `CS-003`; passwords argon2id at the §6.6 parameters; deletion that actually deletes | `CS-003`, `CS-004` | L |
| `WS-009` | **Support: FAQ, tickets, e-mail** *(✅ **done 2026-09-03** (the ticket half — Q8) — `e-os/eos-support` created and pushed: issue templates, a label set with an idempotent `glab` applier, and the prefilled new-issue URL scheme the support page builds client-side. A static host has no backend and the page says so instead of implying one. Mail and accounts stay open (`WS-008`, `CS-008`))* *(decided 2026-09-03: tickets exist **now** as issues in `e-os/eos-support` (created 2026-09-03), opened from a prefilled new-issue link on the support page; no backend needed on Pages — Q8)* | `SECURITY.md` disclosure only | FAQ is static (`WS-003`); tickets and mail need `WS-008` and `CS-008` | `WS-008`, `CS-008` | L |
| `WS-010` | **AI chat in support** *(design only, as decided — the design page `ai-chat-design.md` in the `eos-website` repository: an own model, what fits a CPU-only Rust host, retrieval over the docs, the guardrails, and what is not possible today — Q8)* *(decided 2026-09-03: an **own model**, design only for now (the design page `ai-chat-design.md` under the website repository's `docs/`); nothing external — Q8)* | nothing | on E-OS this needs a model runtime the platform does not have (`CS-205`); an external API contradicts the premise — **owner's decision, §3.0 Q4** | decision | L |
| `WS-011` | **Built-in e-mail for users** | nothing; no IMAP server exists on Redox | `CS-008` is the whole cost; the site only fronts it | `CS-008` | L |
| `WS-012` | **API information & settings** — keys, quotas, docs | nothing | renders `API-*` documentation; settings need `WS-008` | `API-001`, `WS-008` | M |

"Microsoft-style" is read as: a product-organised information architecture with a persistent
global navigation, a support hub and a developer hub — not as a visual clone, which would also be a
trademark problem `WS-004` exists to avoid.

---

### 11.6 A documented system API — `API-*`

Premise, owner's words (2026-09-02): *"a full API for the system, described in detail."*

**What "the system API" is here.** E-OS is a Redox downstream, so its programming surface is
inherited: the kernel scheme namespace (`/scheme/*`), the syscall ABI, `relibc` / `libredox`, and
`orbclient` for the desktop. On top of that sit E-OS's own crates (type A): `eos-ui` (a library),
`eos-control`, `eos-notes`, `eos-guard`, `eos-sysmon`, and `tools/eos-repo-sign` in this repository
(the only *tracked* first-party crate here; an untracked host build of `eos-control` sits under
`build/hostbuild-eos-control/`, and the `.sig` format `eos-repo-sign` writes is *named* in
`docs/adr/0004-hybrid-manifest-signature.md:37-38` as "flat hex text" — its fields and `version = 1`
semantics exist only in `main.rs:193-202` and the reader `manifest_sig.rs`, which is itself an `API-*` gap).

**What exists** (inventory 2026-09-02): `docs/reference/stability.md` — the only policy document,
which says in so many words that `0.x` carries **no stability guarantees** and that the syscall /
scheme ABI is *"inherited from upstream Redox, still evolving"*; a CI `rustdoc` job that documents
**only** `tools/eos-repo-sign`, and even that as a crate front page with no public items; one
developer guide, `docs/guides/creating-an-eos-app.md` (122 lines); and a partial, reconnaissance-
grade description of the `netcfg:` scheme. Adversarial re-check (2026-09-02) added two things the
first pass missed, and they change what "to build" means: `eos-ui` at its pinned rev already carries
`#![warn(missing_docs)]` (`lib.rs:19`), crate-level `//!` docs with a doctest, and every public item
documented — so the library's *source* is documented; what does not exist is a **published** rustdoc
for it or for the four applications. And the MR template (`.gitlab/merge_request_templates/Default.md:19`)
already requires `///` on new public items, with an advisory `docs-currency` job checking it —
while `.gitlab-ci.yml:112` points at "CLAUDE.md §3" for the hard rule, which is not there (fixed in
the same change as this section). **What does not exist**: any reference page for schemes, syscalls
or the ABI; an enumeration of the `sys:` scheme's nodes (`uname`, `cpu`, `stat`, `iostat`, `context`,
`irq`, `log`, …); published rustdoc for any type-A crate; tracked sources for the type-A crates (they
are fetched at build time; an untracked host build of `eos-control` sits under `build/`); a
versioning or stability statement for E-OS's own interfaces (`eos-ui`, `eos-control`'s panes,
`eos-guard`'s reports).

A promise of a "full, detailed API" is therefore two different promises, and only one of them is
this project's to make: E-OS can **document** the inherited surface it ships, but it can only
**stabilise** its own. `stability.md` already ties the 1.0 promise to upstream stabilisation; this
register keeps that line.

| id | item | today | to build | size |
|---|---|---|---|---|
| `API-001` | **Scheme reference** — every scheme the image mounts, its nodes, the operations each accepts, with the E-OS allowlist (`login_schemes.toml`) cross-referenced so a reader sees what an unprivileged user can reach | `netcfg:` sketched (`docs/architecture/eos-control-network.md:23-36`); the kernel tree shows what the page must cover: `src/scheme/{acpi,debug,dtb,event,irq,memory,pipe,proc,serio,sys,time,user}` and `sys/` nodes `block context cpu exe fdstat iostat irq log stat syscall uname`, plus `env` and `kstop` registered inline in `sys/mod.rs:81,97` — none of it documented | generated from a running image (`ls /scheme`, per-scheme probing) into a page `schemes.md` under `docs/reference/`, with a CI check that the page and the image agree | M |
| `API-002` | **Syscall / ABI reference for the shipped kernel revision** — pinned to the `eos-kernel` rev in `repos.toml`, regenerated on every bump | nothing | rustdoc of the kernel's `syscall` crate published as an artefact, plus a hand-written map from syscall to scheme operation | M |
| `API-003` | **rustdoc for every type-A crate**, published, with `#![deny(missing_docs)]` on public items | `eos-ui` is documented at source with `warn(missing_docs)`; nothing is published — the GitLab `rustdoc` and `pages` jobs carry `allow_failure: true` and have not run since 2026-08-28 (`R-009`), and `docs.yml` publishes an artefact, not Pages; the four apps have no such lint; `eos-repo-sign`'s rustdoc has no public items | fetch the type-A sources in CI (they are pinned), build docs, fail on undocumented public items | M |
| `API-004` | **A stability contract for E-OS's own interfaces** — which crates and panes are public, what semver means for them, what `0.x` promises (nothing) and what 1.0 will | `stability.md` covers the inherited surface only | a section in `stability.md` and a CI gate that a public item cannot disappear in a MINOR without a deprecation | S |
| `API-005` | **`libredox` / `relibc` coverage statement** — which POSIX.1-2024 interfaces are present, measured, not claimed | `V2-STD01` measured 4267/5650 | render that measurement as the reference page it already is | S |
| `API-006` | **Developer hub on the website** | the one guide | `WS-012` renders `API-001`…`API-005`; nothing new is written twice | S |

**What this does not promise.** A stable syscall ABI before upstream Redox stabilises it; a
"complete" list of anything that is not generated from the image — a hand-written list drifts,
and §1.4 shows what drift costs here.

---

### 11.7 Repository hygiene — what left the tree, what waits for the owner, what keeps it clean — `RH-*`

Premise, owner's words (2026-09-03): *remove unnecessary things from the repository and never add
them back; keep order; files that are not needed in the repository can be kept locally.* This
section is the ledger of that work, because a deletion without a record is the one change nobody
can audit afterwards.

#### 11.7.1 Removed on 2026-09-03 (no approval needed — `CLAUDE.md` §21.4, or explicitly asked for)

| what | count / size | why | how it stays gone |
|---|---|---|---|
| AppleDouble sidecars `._*` in the working tree | **28 025 files → 0** | exFAT + Finder write one beside every file touched; none was tracked; they broke `cargo llvm-cov` (`verify.sh` comment) and made `git count-objects` print 308 "garbage" warnings | `.gitignore:50,74` already has `._*`; `dot_clean -m .` or `find . -name '._*' -delete` in `docs/operations/maintenance.md`; the tree lives on exFAT, so they **will** return — `RH-004` |
| `._*` inside `.git/objects` | 308 → 0 | same origin; harmless to git, noisy to every tool | as above |
| `.DS_Store` | 5 → 0 | Finder metadata | `.gitignore:47,73` |
| `ROADMAP-v2.md` | 1 779 B (a 26-line redirect stub) | the owner asked for **one** roadmap file; every citation it served now resolves through Annex C.2 | Annex C.2 keeps the naming history and `git show 87e8194b1:ROADMAP-v2.md` |
| `docs/archive/plan.md`, `hardware-plan.md`, `roadmap-connectivity.md`, `hardware-capabilities-roadmap.md`, `acpi-off-removal-plan.md`, `feature-proposals.md` | 6 files, 51 253 B | merged **in full** into §17–§21 of this file; every citation rewritten to the new section (config comments, profiles, ADR-0011, `installer*.md`, `SUMMARY.md`, `HARDWARE.md`) | the doc-paths gate (check 14) refuses a stale path; `RH-002` |
| `assets/screenshots/eos-aarch64-greeter-rebased-july.png` | 73 300 B | byte-identical to `eos-aarch64-live-iso-greeter.png`, which four documents cite; this copy none | check 17 (`eos-check-assets.sh`) refuses duplicates |
| 18 uncited screenshots under `assets/screenshots/` | 1 331 000 B | 0 references each (check 17); the owner's decision Q15 | copies in `~/eos-artifacts/repo-archive-2026-09-03/screenshots/`; check 17 fails closed on orphans from now on |
| `docs/archive/readme-snapshot-archive.md`, `docs/archive/eos-pkg-aarch64-readme-pre-publication.md`, `docs/audit/05-restructure-analysis-2026-08-30.md` | 19 096 B | 0 references; Q15 | archived locally; named in `eos-check-doc-paths.py` ALLOW with a retire condition |
| `patches/` (3 files) | 8 609 B | reference copies of patches that live in the forks; Q15 | archived locally |
| `scripts/probe-scheme-rmdir.sh`, `.py` | 6 823 B | one-off `R-F19` probes, 0 references; the fix is recorded (`U-170`); Q15 | archived locally |
| `EOS_BUILD_STATE.md` → `docs/archive/EOS_BUILD_STATE.md` | moved | a 2026-06-06 checkpoint cited as the toolchain-pin record by two getting-started pages; Annex C.2 said "archive" | both citations repointed |
| `audyt-pelny.md` — the owner's prompt library, untracked under the former `docs/prompts/` | moved out | Q14 | the owner's local `eos-artifacts/prompts/` |
| 11.5 GiB reclaimed on the **internal** disk (my own scratch clones and `target/` dirs) | 11.5 GiB | §21.1 measured first: internal 96 % full with **513 MiB** free, external 32 % — the build's last step had died on it. Three clones held local changes; their diffs were saved as patches to the owner's archive **before** deletion (§21.5) | every deleted directory is recreated by `git clone` or `cargo build` |
| `.gitignore` guard after the `keys/` negation | 3 lines added | measured: `git check-ignore -v --no-index keys/._eos-release.pub` → **not ignored** (`.gitignore:95 !keys/**/*.pub` re-admitted it — the `U-196` regression the file's own comment warns about); after: ignored by the new `**/._*` | the guard sits after every negation; the same command is the negative test |

#### 11.7.2 Still listed (the owner answered Q15 on 2026-09-03; what remains here is kept on purpose)

| candidate | size | references | proposal |
|---|---|---|---|
| `docs/architecture/overview.md` | 3 900 B | 12 | **kept**: the book's internals chapter; `ARCHITECTURE.md` is the declared entry point (`RH-008`) |
| upstream Redox helper scripts nobody references: `find-recipe.sh`, `print-recipe.sh`, `recipe-match.sh` (0 refs), `backtrace.sh`, `dual-boot.sh`, `network-boot.sh`, `include-recipes.sh`, `changelog.sh` (upstream form, `ADR-0003`) | 8 files | 0–2 | **keep** — they are upstream's tree shape and cost nothing; `shellcheck -S warning` treats them as advisory. Deleting them is a divergence from upstream form, not a clean-up |
| `bin/*-llvm-config`, `bin/*-pkg-config` | 7 files, 4.4 KB | used by the cookbook build | keep |
| `sbom/eos-0.1.0-*.cdx.json` | 64 890 B | `V2-MS08` names them as "quietly ageing" | regenerate per tag (`S-20`), then these two become the 0.1.0 record — keep |
| `docs/img/` twins of 16 `assets/screenshots/` files | 758 074 B vs 1 288 981 B | `docs/img/README.md` says they are "~20× smaller" derived copies; measured ratio **0.16–2.64×**, and `eos-bootloader.png` in `docs/img` is 6.2× *larger* with different dimensions | one source of truth: keep `docs/img` (what the book renders), fix the README claim, retire the 15 `assets/` twins nothing cites by that path — owner's call, because the "originals" are the higher-resolution evidence |

#### 11.7.3 The register

| id | item | today | to build | size |
|---|---|---|---|---|
| `RH-001` | **One roadmap file** — `ROADMAP.md` is the only plan; §17–§21 hold what the six archived plans held; `ROADMAP-v2.md` is gone | done 2026-09-03 | — | ✅ |
| `RH-002` | **Citations follow the merge** — every `docs/archive/<plan>.md §N` mention rewritten to `ROADMAP.md §17–21`; check 14 green | done 2026-09-03 | — | ✅ |
| `RH-003` | **Orphan assets decided** *(decided 2026-09-03: done: 18 uncited screenshots archived locally and removed, the seven brand sources cited from `docs/guides/screenshots.md`, check 17 fails closed — Q15)* — the 25 files in §11.7.2 row 1 either cited or moved out | 25 orphans, warn-only in check 17 | the owner's list; then `--warn-orphans` is removed from `ci-integrity.sh` and the rule fails closed | S |
| `RH-004` | **The tree leaves exFAT** — every session starts with thousands of `._*` files, `cargo llvm-cov` needs a workaround, `git` prints garbage warnings; an APFS volume or a case-sensitive disk image for the checkout ends the class | exFAT (`/Volumes/Project itp`) | the operator's move (🔑); `docs/operations/maintenance.md` gets the recipe; `P-10`/`P-14` traps shrink | S (operator) |
| `RH-005` | **`git add -A` refused by a hook** — check 15 caught two `.pyc` on 2026-09-01 *after* the fact; a `pre-commit` command in `lefthook.yml` that refuses a staged file matching the cache/sidecar/artefact classes stops it *before* | check 15 only in CI/verify | one lefthook command, negative test: stage a `.pyc`, commit refused | S |
| `RH-006` | **No hook is installed on the development host, and two hook managers compete for the slot** *(✅ **done 2026-09-03**: `brew install lefthook pre-commit` + `lefthook install` — `.git/hooks` now holds `commit-msg pre-commit pre-push`, and `lefthook.yml` gained the `hygiene` command its own `.pre-commit-config.yaml` header prescribes, so those ten hooks run somewhere at last. Proven to REFUSE, not merely to exist: a staged `glpat-<20 chars>` gives `leaks found: 1`, `git commit` exits **1**, and the branch tip does not move. **The first attempt at that proof was itself a trap** — it used the AWS documentation example key, which `gitleaks`' own rules allowlist, so the run said `no leaks found` and the commit sailed through, looking exactly like a broken hook (§5.9 level 2: a mutation that misses is indistinguishable from a gate that does not work). New `verify.sh` stage `hooks` (19 stages now) fails when THIS working copy has no lefthook hook, or has a foreign one; on CI it reports the invariant as inapplicable rather than pretending to measure it. Four controls measured: hook hidden → FAIL naming the file; foreign hook → FAIL naming the race; `CI=true` → PASS as inapplicable; restored → PASS.)* Measured 2026-09-03: `.git/hooks` holds only the `*.sample` files and `core.hooksPath` is unset — so neither `lefthook.yml`'s fail-closed gitleaks pre-commit nor `scripts/hooks/pre-push` (the secret scan §1.4 fixed) runs on this machine; both protect only a clone that installed them. `.pre-commit-config.yaml` (10 local hooks, 30 KB) says in its own header it must be *invoked by* lefthook, and is not | 0 hooks installed; two managers, no wiring | `lefthook install` + the `hygiene: pre-commit run` line the header prescribes, recorded in `maintenance.md`; a `verify.sh` stage `hooks` that fails when `.git/hooks/pre-commit` is not lefthook's (negative test: remove it → red) | S |
| `RH-007` | **`docs/SUMMARY.md` mirrors the tree** — a gate that every `docs/**/*.md` (outside `archive/`, `audit/`, `prompts/`, `img/`) is in `SUMMARY.md` and every `SUMMARY.md` link resolves; `mdbook` is not on this host, so the gate is a script | measured 2026-09-03: **14 pages absent** — `ADR-0007`…`0011`, the four installer/update specifications, `compatibility.md`, `semver-decisions`, `third-party-licenses.md`, `github-configuration.md`, `incident-response.md`; 0 dead links | `scripts/eos-check-summary.py`, check 18 (added 2026-09-03), the 14 entries added | S |
| `RH-008` | **`overview.md` into `ARCHITECTURE.md`** *(decided 2026-09-03: done as a statement, not a merge: `ARCHITECTURE.md` names itself the entry point and `docs/architecture/overview.md` the internals chapter; mdBook cannot list a page outside `docs/`, so a physical merge would drop the internals from the book)* | two entry points | one document, twelve links rewritten | S |
| `RH-009` | **`docs/prompts/`** *(decided 2026-09-03: done: moved out of the tree to the owner's local `~/eos-artifacts/prompts/` — Q14)* — the owner's untracked prompt library sits in the tree; either tracked (with `docs/SUMMARY.md` exclusion and a README saying what it is) or moved out; today every `git status` shows it | untracked | the owner's decision (§3.0 Q14) | S |
| `RH-018` | ✅ **fixed 2026-09-04 (`eos-sheets`!3+!4, `eos-slides`!3+!4, `eos-drive`!3+!4, `eos-store`!3), and the row was half wrong.** It said seven repositories had "CI files and no CI". Measured: `checks-heavy` **does run** in six of seven — 6 tests and 70.29 % line coverage in `eos-sheets`, in 20 s, fast because `target` is cached on the external volume rather than because it skipped anything. **The real defect was next door: `host-gui` was not being skipped — it was running and failing**, `cargo: command not found`, exit 127, on every pipeline it was ever part of, invisible because the pipeline was already red from `ci_quota_exceeded`. Cause: the PATH rule for this runner was written **twice** (`.package`, `checks-heavy`) and applied to `host-gui` zero times; the build-tree redirect (`EOS_XBUILD`) likewise. Both now live once, in `.host-toolchain`, reached by `!reference`. **`host-gui` passed for the first time in all four repositories**: 3m39s / 2m47s / 2m41s / 2m15s. The remaining half, `eos-ui`, got the same treatment in `eos-ui!2` (`71e98d2b`, merged 2026-09-04 16:24 UTC): `checks-heavy` on `eos-heavy` passed on `main` in 18 s with `EOS-UI-TESTS: 1` (pipeline 2821052541, job 16313707728); the shared-runner jobs died on `ci_quota_exceeded` as everywhere else. Until then this row said "`eos-ui` still has no `eos-heavy` job at all" | done 2026-09-04 | — | `RH-017` | M |
| `RH-019` | **The product repositories' GitHub mirrors are not mirrors — they are copies somebody has to remember to push.** Measured 2026-09-03 right after the `PR-008` merge requests landed: `glab api projects/.../remote_mirrors` returns **`(none configured)`** for every product repository, while the orchestration repository has one enabled and updating (`update_status: finished`). The merged products were all **behind** their GitHub copies until pushed by hand; the unmerged ones only looked in sync because nothing had changed. `ADR-0001` says GitHub is a read-only mirror, and a mirror that updates when someone remembers is a fork with a misleading name — the same type confusion `CLAUDE.md` §12 calls the most expensive mistake in this ecosystem | 0 of 9 product/library repositories have push mirroring; drift is invisible until someone compares two `git ls-remote` outputs | configure push mirroring per repository — **operator task, not a tool task**: it needs a GitHub PAT in the mirror URL, and §19 is explicit that a token never goes to a tool that logs. Until then, `scripts/eos-mirror-drift.sh` should cover the product repositories too, so drift is at least *reported* rather than discovered | owner (PAT) | S |
| `PR-018` | ✅ **done 2026-09-03 — a person can decline applications at install time**, which is the half of the owner's request `PR-016` did not cover. Asked **next to the password prompt, before the disk is touched**: everything after that point writes, and a question asked after the erase cannot change the outcome without a second pass. It is a **removal, not a selection**, because the fast path is a filesystem clone (`try_fast_install`) that chooses no packages — which is also why the manifest carries an exact file list rather than a package name. **Both paths honour the same answer**; the slow path removes while still mounted, since `package_files` walks the package database and knows nothing of the choice, and a toggle working only on the fast path would silently stop working on older hardware. **Three defaults so silence is safe:** an empty answer, end of input, and an absent or unreadable manifest all keep everything. Proven in the installed disk, not the log: declining #1 left `eos-drive` with **binary, icon and launcher entry all absent** and the other five with **all three each**, and the system still reached `install-smoke: PASS`. The installer said `leaving out: eos-drive` / `3 file(s) removed, 0 already absent`. Control run with an empty answer: PASS, everything intact | fork `eos-installer` `713ca48`, 8 new tests (11 total) | — | `PR-016`, `PR-017` | M |
| `PR-019` | ✅ **fixed 2026-09-04, same day it was found.** **`PackageName::new` accepted a bare `.`** — found 2026-09-04 by the new index fuzzer. The rule is *at most one dot*, written for the `name.target` form, and a lone `.` is its degenerate case. Measured directly: `"."` **ACCEPTED**, `".."` rejected, `"a.b"` ACCEPTED, `"a.b.c"` rejected, `""` / `"a/b"` / `"a\0b"` / `"a:b"` all rejected. **Not a traversal** — `..` is the dangerous form and it is refused — but a name that can never match a real package, and `repo_manager.rs` pastes it into `format!("{}/{}", remote.path, file)`, so it forms URLs like `<repo>/.` | one degenerate name accepted; no exploit path found | a name made entirely of dots is now refused. The test pins **both** directions — `.` `..` `...` `....` rejected, `foo` `foo.bar` `a.b` still accepted, `foo.bar.baz` still rejected — because without the second half it would pass just as well with the dot handling deleted. Mutation control: remove the three new lines and exactly `package_name_rejects_names_made_only_of_dots` fails. 24 tests green, 1 165 366 fuzz runs clean, `cook pkgutils` successful. **Still not asserted in the fuzz target**: a target that fires on behaviour the code intends teaches people to ignore fuzz crashes | `TQ-005` | S |
| `PR-017` | ✅ **done 2026-09-03.** **Every application icon was missing from the image, ours and upstream's alike** — found 2026-09-03 while checking that the optional-app manifest tells the truth. Each product recipe installs `${COOKBOOK_STAGE}/usr/share/ui/icons/apps/<app>.png`, the staged output has it, and the image does **not**: `find / -name 'eos-*.png'` in a mounted copy returns **nothing**. The cause is a path that resolves somewhere else — `/usr/share/ui/icons` is a **symlink to `/usr/share/icons`**, which holds 26 PNGs **directly** and has **no `apps/` subdirectory at all**. So `/usr/share/ui/icons/apps/eos-sheets.png` names a directory that does not exist. **This is not an E-OS regression:** upstream launcher entries point at the same place — `00_netsurf` says `icon=/usr/share/ui/icons/apps/internet-web-browser.png`, and that file is absent too while `/usr/share/icons/internet-web-browser.png` is present. Six E-OS applications and the upstream ones have launcher entries whose icon path resolves to nothing | 14 launcher entries, **0** icons; nobody noticed because a missing icon degrades to a placeholder rather than an error | **fixed by staging into the real directory.** The cause was not a wrong convention but a **symlink a package may not write through**: the icon was in the `.pkgar` and staged correctly, and the extractor — rightly — refused to follow `usr/share/ui/icons` into `/usr/share/icons`. Because nothing had ever created the real `apps/` directory, **every** package writing there failed the same way, which is why fixing our seven recipes made the **upstream** icons appear too. The fourteenth entry needed one more line: `orbutils` ships `eos-icons/eos-settings.png` and its own launcher entry, and never installed the icon. Measured after: **14 of 14 launcher entries resolve, 18 of 18 manifest files present**, `boot-smoke: PASS`. Runtime paths unchanged — reading through a symlink was never the problem | `PR-016` | M |
| `PR-016` | ✅ **done 2026-09-03.** **Four of the seven products were in no image at all** — `eos-sheets`, `eos-slides`, `eos-drive`, `eos-store` had repositories, recipes, per-OS packaging and CI, and appeared in **neither** image config. Found by a rebuild, not by reading the config: after clearing all seven product recipe trees only three came back with a `source/`. **Whether they compile for Redox was measured before the config lines were written** — all four `cook … - successful` — because *add a package name* and *port a Slint GUI application* are very different amounts of work and a config file cannot tell you which one you are doing. Now shipped in both configs; proven **in the image**, on a mounted **copy** (P-6): `/usr/bin/eos-sheets|slides|drive|store` present with **distinct** SHA-256s and each carrying its own selftest marker, plus launcher entries `30_eos-sheets`, `30_eos-slides`, `30_eos-drive`, `30_eos-store`. The four are byte-identical **in size** (8 787 768) because they are one scaffold; the checksums are what proved that is similarity rather than a duplicated binary. `boot-smoke: PASS`. Original entry: **Four of the seven products are in no image at all** — measured 2026-09-03 while bumping their pins: `eos-sheets`, `eos-slides`, `eos-drive` and `eos-store` have repositories, recipes, per-OS packaging and (since `RH-018`) working CI, and appear in **neither** `config/aarch64/eos.toml` nor `config/x86_64/eos.toml`. The build proves it rather than the config alone: after clearing all seven recipe trees and rebuilding, only `eos-guard`, `eos-notes` and `eos-control` have a `source/` at all — the other four were never fetched, because nothing pulls them into the package closure. Their pins are therefore **bumped but unexercised**: no build has ever compiled them for Redox | 4 products shipped nowhere, against the owner's request that these be *built into the system with the ability to enable or disable them at install* | add `[packages.eos-sheets]` and the other three to both configs, then **measure** — these are Slint GUI applications built only for host targets so far, and whether they compile for `*-unknown-redox` is unknown until a build says so. Expect that to be the real work, not the config line | `PR-008` | M |
| `RH-020` | ✅ **done 2026-09-04.** **The gate buffered its whole output into a file and printed it only at the end**, so a job that died left **nothing** in the trace. Found the hard way: the runner lost DNS mid-run, three security stages failed with `Could not resolve host: github.com`, and the job then sat marked *running* for **34 more minutes** before GitLab failed it as `no_updates_running` — with the trace holding nothing after the `bash scripts/verify.sh` line. The stage table survived only in the runner's working directory, and reading it there is what corrected a diagnosis I had already stated: I blamed the new `mutants` stage for a 39-minute gate, and `mutants` had taken **68 s**. The retried job, network restored, finished in **189 s** with every stage green. Two harms, one cause: a dead job leaves no diagnostic where a reader looks first, and GitLab kills jobs that emit no trace output — which makes a slow healthy run indistinguishable from a hung one, and then makes it one | trace empty on failure; 39-minute zombie job | `tee` instead of `>`, with `${PIPESTATUS[0]}` so the status is `verify.sh`'s and not `tee`'s (P-3, in the one place where taking the wrong end of the pipe reports every failure as a pass) | — | S |
| `RH-017` | **Two pipelines per push, both doing the same work** *(**fixed on the second attempt, 2026-09-03 — and both of my earlier claims about it were wrong.** The first rule was GitLab's own documented template, `$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUEST_IID → when: never`, and it deduplicated **nothing**: measured twice with the rule already merged, on a branch that already had an open merge request, both `2817226692` (push, 3 jobs — so the guard let it run) and `2817226740` (merge_request_event) were created. `$CI_OPEN_MERGE_REQUEST_IID` is simply not populated in those branch pipelines here. My **second** claim — "it works after the merge request exists" — was disproved by the very push that carried it. The rule now says what it means: **branch pipelines run only on the default branch**, everything else gets its merge-request pipeline and nothing else. Stated trade: a branch pushed **without** a merge request gets no pipeline at all, which in this project is the normal path anyway (§5.7). **Confirmed by measurement, after the run and not before it:** the push carrying the new rule produced exactly one pipeline — `2817238547 merge_request_event`, with no `push` sibling, against two for each of the three pushes before it)*; the seven product repositories still need the same three lines)* — measured: a push to a branch with an open merge request creates a `push` pipeline **and** a `merge_request_event` pipeline, and both run the same jobs. On shared runners that is invisible, because they fail on quota either way. It stops being invisible the moment a job does real work: in the product repositories the same ~20-minute cross build ran **twice per push** on a runner with `concurrent = 1`, so the duplicate did not merely waste time — it delayed every other job behind it, including the 2-minute `local-gates` that the merge gate depends on | both pipelines run; `glab api .../pipelines` shows the pair for every push | the standard `workflow:` guard, whose middle rule (`$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUEST_IID` → `when: never`) is the mechanism; without it the last rule matches everything and nothing is deduplicated. To do in each product repository **after** its `PR-008` merge request lands, so a new pipeline does not restart a queued cross build | — | S |
| `RH-010` | ✅ **done 2026-09-03.** **`CLAUDE.md` numbering and its dangling self-citations.** Measured with the new gate rather than by eye: **14** citations pointed at sections that do not exist in the contract (`§4.1`, `§4.2` ×3, `§4.3` ×2, `§4.5`, `§10.1`, `§10.2`, `§10.3` ×2, `§1.6` ×2, `§11.3`) — all survivors of an older numbering — and `## 19. TODO` sat physically **after** `## 21`. Four more citations were fine and only looked broken: they are cross-document references to `ROADMAP`, which the gate now recognises as legitimate when they are qualified. Three `§2 reguła 4` citations resolved but pointed at a section with no numbered rules, so they were repointed at `§18 pkt 6`, the rule they actually mean; that class is invisible to the gate and was fixed by reading. Every dangling citation now points at the section that carries the rule **today**, §19 sits between §18 and §20, and `scripts/eos-check-claude-refs.py` (integrity check 21) keeps it that way with three rules and a five-case `--selftest`. Original entry: **`CLAUDE.md` numbering and its 43 dangling self-citations.** Sections run §18 → §20 → §21 → §19 (`## 19. TODO` sits at line 951) and there is a `### 21.2b`; 16 lines inside the file and 27 outside (`verify.sh:38,151,307`, `ci-integrity.sh:17`, `setup-github-security.sh`, `release.yml`…) cite sub-sections that do not exist (§1.6, §4.1–4.5, §10.1–10.3, "§2 reguła 4") | measured 2026-09-03 | a one-time old→new map (§4.1→§5.4, §4.2→§20.6, §4.3→§18.3, §4.5→§18.6, §10.1/§10.3→§5.7, §10.2→§4, §1.6→§19), `§19 TODO` → `§22`, all 43 rewritten, and a 0.05 s check that every `CLAUDE.md §N.M` in the tree matches a heading | M |
| `RH-011` | ✅ **done 2026-09-03.** **Three Definition-of-Done lists that disagree** — measured: `CLAUDE.md` §6 with **18** items, `CONTRIBUTING.md` with a different **14**, the merge-request template with **8** while its header claimed it *was* "the Definition of Done from CLAUDE.md" and its verification heading cited "the three gates", a concept the contract has never contained. §6 is now declared the one list; the other two say what they actually are (the **commands** to run; the **shape** of a description) and point at it. Gate: `eos-check-dod-refs.py`, integrity check 23. It deliberately does **not** diff item text — the contract is Polish and `CONTRIBUTING.md` is English, so a textual diff would be noise, and a gate that cries wolf gets routed around. **The gate needed fixing twice, and the second version is the lesson:** the first rule only fired on documents carrying a literal *Definition of Done* heading, and `CONTRIBUTING.md` files its checklist under *Pull / merge request checklist* — so deleting its anchor **passed green**. A rule keyed on a heading checks the heading, not the thing (§5.4). The anchor requirement is unconditional now and that case is a selftest case. Original entry: **Three Definition-of-Done lists that disagree** — `CLAUDE.md` §6 (17 items), `CONTRIBUTING.md:92-116` (14), the MR template (8, and it cites "the three gates" that `CLAUDE.md` never defines; `scripts/eos-check.sh:3` too) | measured 2026-09-03 | §6 stays the single list; the template and CONTRIBUTING become a link plus the `verify.sh` output slot; "three gates" is either defined in §5.2 or deleted | S |
| `RH-012` | **The same paragraph copied across files, each copy with its own date** — the CI-quota status in ≥ 9 files, the repository-type list in 6 (and `docs/architecture/forks.md` contradicts `repos.toml` on `eos-orbital`), the build/boot quick start in 6, the gate list in 8, the FDE description in 4 | measured 2026-09-03 | one home per paragraph, the others link; where a copy must exist (README), the marker-value gate pattern (`R-F05`) keeps it in step | M |
| `RH-013` | **Shared shell helpers instead of pasted ones** — `cleanup()` ×3 byte-identical, `fail()` ×3, `step()` ×2, `mon()` ×2, `_parse()` ×2 already diverging, the QEMU/firmware discovery block ×8 with drift (different `FW_VARS` names, quoting) | measured 2026-09-03 | `scripts/lib/{qemu-host.sh,report.sh,toml.sh}` sourced by the harnesses; a `ci-integrity` line that refuses a second definition of `cleanup()`/`fail()` outside `scripts/lib/` | M |
| `RH-014` | ✅ **done 2026-09-03.** The lint scope was the literal glob `scripts/*.sh`, so **14 tracked shell files were linted by nothing** — `scripts/hooks/pre-push` (the secret-scan hook), the three `examples/*.sh` a reader is invited to run, `upstream/prepare-mrs.sh` (which deletes directories), and nine vendored upstream files. Measured on the five **E-OS-owned** ones: **0 errors, 1 warning** — and that warning was `SC2115` on `rm -rf "$WORKDIR/$repo"`, where an empty `$repo` deletes the whole work directory. Fixed to `"${WORKDIR:?}/${repo:?}"`. The scope is now **computed** from `git ls-files` rather than written down, so a new script is linted the day it lands (60 files). The nine vendored files (`build.sh`, `native_bootstrap.sh`, `podman_bootstrap.sh`, `podman/rustinstall.sh`, five `bin/*-pkg-config`) carry 15 `SC2068` errors between them and are excluded **by name, with the reason**: ADR-0003 says vendored code keeps upstream form, and "fixing" them buys style at the price of a divergence carried through every future sync. `recipes/**` and `src/**` are excluded too — cookbook fragments are *sourced*, carry no shebang by design, and yielded 4 `SC2148` errors that say nothing about the tree. Original entry: **Scripts outside every lint** — the lint scope is `scripts/*.sh` everywhere, so `scripts/hooks/pre-push`, `bin/*` (five byte-identical `pkg-config` wrappers, two Python `llvm-config`) and the 12 `*.py` files are checked by nothing; no Python linter runs anywhere (`pyflakes`/`ruff` absent) | measured 2026-09-03 | widen the `shell-lint` stage to hooks and `bin/`; add `ruff` (or `pyflakes`) as a `verify.sh` stage with the install hint; 24 of 73 script files are named in no document — list them in `docs/operations/ci.md` | S |
| `RH-015` | **29 hard-coded `/opt/homebrew` paths in 8 harness scripts**, 3 overridable by env — a second Mac with MacPorts, or a Linux host, cannot run the proofs | measured 2026-09-03 | one `scripts/lib/qemu-host.sh` that resolves `qemu-system-*` and the edk2 firmware from `command -v` and `EOS_QEMU_SHARE`, with the Homebrew path as the fallback (folds into `RH-013`) | S |
| `RH-016` | ✅ **done 2026-09-03, and the original number was wrong in a way worth keeping visible.** This entry said *"16 of 60 shell files set nothing, 36 lack `-e`"*. Re-measured with the **whole file** scanned instead of a 25-line window — the first attempt used a window and reported `verify.sh` **itself** as setting nothing, which is false — and split by authorship: **E-OS-owned: 15 with `set -euo pipefail`, 15 with `set -uo pipefail`, ZERO with nothing.** Every file in the alarming count was a **vendored cookbook helper**. Acting on the original number would have meant editing upstream files and carrying that divergence through every sync (ADR-0003) — a fix worse than the defect. The gate (`eos-check-shell-strict.sh`, integrity check 22) therefore requires `-u` **and** `pipefail` and deliberately **does not require `-e`**: fifteen owned scripts omit it because they are gates and harnesses that *inspect* exit codes (`ci-integrity.sh` collects failures rather than dying on the first), so demanding `-e` would break exactly the scripts whose job is to keep going and report. Original entry: **`set -euo pipefail` is the contract (`CLAUDE.md` §4) and 16 of 60 shell files set nothing, 36 lack `-e`** — the harnesses are `set -uo pipefail` on purpose (they inspect statuses); the rest are not on purpose | measured 2026-09-03 | a `ci-integrity` line: every E-OS-owned `scripts/*.sh` starts with a `set -` line, and a comment names the reason when `-e` is omitted; upstream helpers exempt (`ADR-0003`) | S |

---

## 12. Standards and compliance

The full standards list was analysed. The result is asymmetric and that has to be said plainly:
**a few items have an excellent value-to-effort ratio, one is a legal obligation, and most
certifications are, for a project this size, a trap costing years and hundreds of thousands of
dollars.** Putting them all on a roadmap as goals would be dishonest.


### 12.1 Worth doing — best value for effort

| id | standard | what it gives E-OS | effort | state |
|---|---|---|---|---|
| `V2-STD01` | **POSIX (ISO/IEC 9945)** — measure `relibc` with the `os-test` suite | ✅ **measured, full run** (`U-222`): **4267/5650 = 75.5 %** against POSIX.1-2024; excluding the 207 `udp` tests that fail for want of a NIC in the image, **78.4 %**. Best: `stdio` 100 %, `io` 94 %, `include` 83 %. Worst: **`pty` 0/29** (terminals unimplemented — `TODO: ioctl TIOCSCTTY`), `namespace` 18 %, `basic/complex` 0/66. **933 of 1382 failures are missing headers**, not wrong behaviour. Found **3 hangs not on the upstream list** — without fixing them the suite does not finish at all | — | ✅ |
| `V2-STD02` | **`unsafe` audit + Miri + parser fuzzing** | E-OS's posture is already **better than upstream** (`overflow-checks=true`, `panic=abort`, ASLR mmap, W^X at syscall); what is missing is an inventory of `unsafe` blocks with their invariants, and UB tests. *Note the deliberate limits recorded in `CLAUDE.md` §19: Miri is skipped because E-OS's own Rust has **zero** `unsafe` blocks (check 4 enforces it) and running it over the vendored tree would mean maintaining a divergence (`ADR-0003`); `cargo-fuzz` is skipped **here** because the parsers worth fuzzing — `pkgar`, RedoxFS, `redox_installer` — live in **forks**, so their place is the fork's CI* | S–M | 🔴 |
| `V2-STD03` | **NIST SP 800-53 Rel. 5.2.0** as a *design checklist*, not a certification | the new 5.2.0 controls (`SI-07(12)` update integrity, `SA-24`, `SA-15(13)` provenance) map **one to one** onto `R-701`/`R-702`/`R-703`, which we are doing anyway | S — a mapping page | 🔴 |
| `V2-STD04` | **NIAP PP_OS v4.3** as a self-assessment, not a certification | what US public procurement actually asks for, and a readable requirement list that can be ticked off **today**. E-OS probably already meets half the `FPT` family | S–M | 🔴 |
| `V2-STD05` | **Timing determinism — a first measurement** | measured upstream: of 196 Open POSIX TPS programs **46 build and 150 do not**; every `sched_setscheduler` test fails to compile. E-OS has **not one** latency measurement | M | 🔴 |

### 12.2 The one legal obligation on the list

| id | standard | what it means | effort | state |
|---|---|---|---|---|
| `V2-STD06` | **European Accessibility Act — Directive (EU) 2019/882** | **in force since 28 June 2025** and it names **operating systems explicitly** (Art. 2(1)(a)); Art. 3(38) covers standalone software too. It binds when E-OS is made available on the EU market *"in the course of a commercial activity"* — **being free of charge does not exempt**; commercial character decides | XL (a programme, not a feature) | 🔴 |
| `V2-STD07` | **Accessibility API (AccessKit)** — the precondition for everything above | the Slint/Orbital desktop has **no** accessibility API at all. Without one, EAA Annex I §2(n) (*"interface for assistive technologies"*) is unsatisfiable and `EN 301 549` §11.5.2 unreachable. **AccessKit is natively Rust and Slint supports it** — this is a real path | XL (6–18 months) | 🔴 |
| `V2-STD08` | **EN 301 549 / WCAG 2.2 AA** as the engineering specification | this is the document that says **concretely what to build**; building to 2.2 AA covers EAA, Section 508 and US Title II at once, with no rework | M–L | 🔴 |

> **Honestly:** a purely non-commercial AGPL release probably falls outside the EAA. But the moment
> any form of commercialisation appears, that obligation is **already active**, not future. Better
> to know now than after the first invoice.

### 12.3 Architecturally already there — document it, do not build it

| standard | why E-OS is already close | what is missing |
|---|---|---|
| **SELinux/AppArmor-class protection** | E-OS has a **better substrate** than an LSM bolted onto a monolith: everything is a scheme; drivers, filesystem, network and display are user space; a permission *is* the set of reachable schemes. `raw` is already gated to root (`U-144`, `R-904a`) | no policy language, no denial auditing, no domain transition on `exec` |
| **"Zero-Trust Kernel"** | satisfied **at the syscall boundary** (microkernel, user-space drivers, no ambient authority) | **this is not a standard.** There is no NIST or ISO document on a "zero-trust kernel". Cite SP 800-207 as the source of the principle and say plainly that applying it to a kernel is **our own framing**. The real gap is the **absent IOMMU/SMMU** — a user-space driver can still DMA anywhere (`R-F13`) |
| **Secure Boot & TPM 2.0** | Secure Boot ✅ proven with a negative control — better than most projects at this stage | TPM 2.0 does not exist (`R-913`/`V2-N02`); until it does, "the disk is encrypted" does not mean "this disk in this machine" |
| **UEFI** | the bootloader is a correct `PE32+` for `${ARCH}-unknown-uefi`, boots through OVMF/EDK2 on both architectures, and §5.1.1 adds three measured PE attributes | no UEFI SCT tests, no `EFI_MEMORY_ATTRIBUTE_PROTOCOL` |
| **ACPI** | real, non-trivial work: `R-401f` delivered `_PRT` INTx routing (log: *128 entries*), aarch64 boots under ACPI **and** device tree, and `acpid` has a working AML interpreter for the EC | no S3, no `_PSR`/battery/thermal zones (`R-922`), no multi-segment ECAM (`R-809`) |

### 12.4 Deliberate refusals, with reasons so they stop coming back

| standard | reason for refusal |
|---|---|
| **Common Criteria / EAL** | USD 175–750 k and 7–24 months for EAL4. E-OS has a zero evidence package (ADV/AGD/ALC/ATE/AVA). **PP_OS as a self-assessment** (`V2-STD04`) gives 80 % of the value for 1 % of the cost |
| **FIPS 140-3** | **two of our algorithms are not approved**: BLAKE3 has no FIPS status at all, and Argon2 is not an approved password KDF (SP 800-132 wants PBKDF2). Certifying would mean swapping the crypto core for a **worse** one |
| **ISO/IEC 27001** | certifies an **organisation**, not software: management review, independent internal audit, defined roles. That machinery is meaningless for a one-person project |
| **DO-178C, IEC 61508, IEC 62304, ISO 26262** | all certify a **component in a product context**, not an operating system. The certifiable artefact would be the microkernel alone (seL4 scale: 3–5+ person-years), without the compositor or the package manager. Concrete blockers on top: no priority scheduling and **zero latency measurements**, so "freedom from interference" in the time dimension cannot even be *argued* |
| **Ferrocene** | the only directly Rust-related entry, so precision matters: **no `*-unknown-redox` target is qualified**, the qualified host is x86-64 Linux/glibc only, and only the **`core`** library is certified — `alloc`, `std` and `test` are not. E-OS uses `alloc` and `std` everywhere |
| **LSB** | a **dead** standard: last release 5.0 in 2015, dropped by Debian in 2015 and Ubuntu after it; the former maintainer wrote in 2023 that the project is essentially abandoned |
| **ADA Title III** | there is no technical standard under Title III for software, and an operating system is not a "place of public accommodation". The entry exists purely as a **scope control**, so that "ADA compliance" never becomes the justification for work the statute does not require |
| **ISO 21434 / UNECE R155** | out of scope (desktop), but worth noting strategically: automotive and industrial are the **only** market where a Rust microkernel with a small TCB has a natural advantage |
| **Vulkan / DirectX / DDI** | Vulkan conformance is an adoption programme costing **USD 30,000**, on top of a stack that does not exist. `R-930` states it precisely: `grep vulkan\|opengl\|GEM\|shader` = 0; a KMS/DRM equivalent has to exist first |
| **OCI (containers)** | the `runtime-spec` is **Linux by definition** — its isolation primitives *are* namespaces and cgroups. But note: E-OS has a **better-fitting primitive that is simply switched off** — `recipes/core/contain`. The goal is not OCI conformance; it is enabling and documenting our own isolation (`R-1010`) |

### 12.5 What the system already has, so the work is wiring rather than writing

- **Disk encryption** — RedoxFS AES-XTS (`R-502`), with ARMv8 Crypto acceleration.
- **Signing and integrity** — `eos-repo-sign` (ed25519 + ML-DSA-65, `R-503`), `eos-guard` (blake3).
- **Isolation** — the capability model, a namespace per process, IPC-only, no `sudo:` without the
  capability. Measured in `U-161`: `sudo` and root fail identically, because access depends on
  capabilities and not on UID.
- **User-space networking** — `smoltcp`, with `tcp:`/`udp:`/`icmp:` schemes as the foundation for
  recon tooling (§7.3).
- **Memory safety** — the whole stack in Rust; `zeroize` for keys.

---

## 13. Dropped and refused

Two lists that do not overlap at all, and both must survive: **features** refused here, and
**standards** refused in §12.4.

| item | reason |
|---|---|
| Antivirus / malware scanner — **refusal superseded 2026-09-04 (Q16, Q17): the product is `PR-020`, on-access `PR-004b`.** What stays refused: ClamAV / `libclamav` bindings (GPL-2 C in an AGPL tree); on-access scanning **on Redox** until a file-event bus exists (§7.3); the antivirus as a *replacement* for Guard's blake3 baseline (`PR-004`) — it is built beside it | The 2026-08-30 reason (audit `02 §3`: no third-party binary ecosystem on Redox, so the integrity monitor is the real defence) is still true of Redox and now lives in §14.5 as a non-promise about what the Redox build protects against — not here as a refusal of the product. The engine is measured, not assumed (`PR-020`: `boreal`, 36 crates, `deny.toml` green) |
| SELinux/AppArmor-style MAC | Architecturally wrong for a microkernel. The scheme allowlist is the native equivalent; the effort belongs in per-process scopes (`M-1`, `R-1010`), not in porting an LSM. Audit `02 §4`, and see §12.3 |
| `orbterm` in the desktop image | Superseded by `cosmic-term`. Explicitly excluded in `config/desktop.toml:26` (`orbterm = "ignore"`) |
| `eos-sysmon` as a separately shipped application | Consolidated into `eos-control` (`U-095`); the repository remains as history. **`eos-guard` left this row on 2026-09-03:** it ships as E-OS Guard (`PR-002` ✅ — `[packages.eos-guard]` in both configs, `/usr/bin/eos-guard` and launcher `40_eos-guard` proven in a mounted copy of each image) and stays a separate product by Q16; its engine is the basis of §7.3 and of `eos-control`'s Security tab (`PR-004`) |
| Global `REPO_BINARY=0` | Would compile third-party ports for hours with no security gain. See `ADR-0002`. **Revisit for `git` specifically** (`S-16`) |
| DAST | Not meaningful for an operating system image |
| A separate rescue medium | A second artefact means a second checksum, a second signature and a second thing that goes stale. Rescue is content of *this* medium — `R-614` (`installer.md` §10 item 7) |
| A network installer | Refused, not deferred: no Wi-Fi exists, and the installer would need a touchpad (no I2C) and a screen reader (needs working audio). §14 |
| Rollback by filesystem snapshot | Not refused because it is worse — refused because **there is nothing to build it on**. RedoxFS is internally copy-on-write but exposes no snapshot API, and `clone.rs` clones a file tree, not a point in time |
| `cosign` for artefact signing | The task could be written, but **a human generates the signing key** (`CLAUDE.md` §5.7) and a tool that logs must not touch it. Operator work, not automation. Today: minisign |
| `cargo-audit` in CI | Redundant against `cargo-deny check advisories`; kept locally in `local-scan.sh` |
| Any `recipes/wip/security/` scanner as a source for `PR-020` — `clamav` (GPL-2 C, unpinned 1.5.0 tarball), `yara-x` (wasmtime JIT, measured `compile_error!` on `aarch64-unknown-redox`, `git =` with no `rev`), `binsec` (libyara via `yara-sys`, "crate error" in its own TODO), and `lmd`, `chkrootkit`, `aide`, `samhain`, `ossec-hids`, `wazuh`, `maltrail` (Linux-bound C/GPL HIDS) | `PR-020` is a Rust product on the pure-Rust `boreal` engine; nothing under `wip/` is its source. Every one of these carries `#TODO not compiled or tested`, none is pinned, and they sit outside the 74 packages `R-F11` pinned because they are upstream cookbook sweeps with no E-OS decision behind them. `CS-009`'s wip gate covers the Tier-1 server list, not this directory — this line, cited from `PR-020`, is the only guard, and check 19 does not read it |
| Third-party YARA rule sets under non-commercial or detection-rule-licence terms (CC-BY-NC, DRL) inside the shipped `PR-020` bundle | Non-commercial terms cannot ride a product the project distributes and signs; DRL-class sets carry attribution and redistribution conditions the bundle format has no field for. The shipped bundle is E-OS-written rules only. Whether any permissively licensed third-party set may be added later is an owner question that has not been asked (a Q18 candidate), not a default |
| Driver updater for Windows / Linux (a host edition of `R-806`, as `PR-008` packages products and `PR-020` ships on both) | Refused, not deferred. A host build can *list* devices — measured 2026-09-04 in `xbuild/probe-c-driver-updates-host`: `windows 0.62.2` (`Win32_Devices_DeviceAndDriverInstallation`, `Win32_Devices_Properties`), `udev 0.9.3` (libudev), `fwupd-dbus 0.3.0` (libdbus) all resolve — but it cannot honestly *update*: neither host has an E-OS-signed driver source, so it would fetch WHQL/vendor packages from vendor and third-party sites, i.e. become the "malicious driver updater" class `docs/architecture/driver-manager.md` §4.4 exists to eliminate, and the single-signed-source property that justifies `R-806` does not survive the port. Windows Update and `fwupd`/LVFS already fill the role. Same honesty precedent as `eos-guard`'s missing Windows build ("a check that can only pass", `PR-008`). The E-OS Driver Manager is Settings → Drivers, `R-806`, not a product; no `PR-*` and no `R-D*` is minted for it |
| Firmware, BIOS, UEFI-capsule and CPU-microcode updates (bundled by DriverBooster-class tools) | No substrate: `grep -rn -i microcode ~/eos-forks/eos-kernel/src` → one comment (`src/arch/x86_shared/gdt.rs:199`), no loader; `UpdateCapsule|update_capsule` → 0 hits across `~/eos-forks`; `microcode|capsule|fwupd|lvfs|firmware update|bios update` → 0 relevant hits in `recipes`, `config`, `docs`, `ROADMAP.md`; `recipes/core/bootloader` builds `eos-bootloader` with no capsule path. Both are kernel + bootloader work (a runtime-services call path, an early-boot MSR write) that only real hardware can verify — ⚙️, NEW SUBSYSTEM. No `R-8xx` number is minted; §14.5 records the non-promise so "like DriverBooster" cannot be read to include it |
| A "proprietary adaptive compression algorithm" or an E-OS-own archive format | The owner's wording is WinRAR marketing copy. A novel algorithm is a research programme with no acceptance test, and a format nobody else opens is a lock-in, not a feature. What ships instead is measured (`PR-021`): per-entry choice among store/deflate/zstd/LZMA2/brotli written into 7z, ZIP or tar.zst, all pure Rust, all checking for `x86_64-unknown-redox` — and the result opens in 7-Zip and WinZip. Nothing here is proprietary and nothing will be |
| SFX (self-extracting archive) creation | An SFX is an unsigned executable wrapped around data, distributed outside the signed `pkgar` channel that §14.3 treats as the only trusted software path; on Windows it is the dropper shape `PR-020` quarantines, so one suite would create what its other half flags; no Redox SFX stub exists and writing one means shipping an unsigned executable format on purpose. **Opening** an SFX as an archive stays in `PR-021` (read past the PE/ELF stub, never execute). Not "the system refuses to run it" — Redox runs any readable ELF; the refusal is a product decision, not an OS property |
| Auto-install of installers found inside archives | On E-OS there is no installer format to run (no `.exe`/`.msi`/`.deb` ecosystem) and packages install only through the signed index (§14.3, `V2-MS13`, `PR-013`: on Windows/Linux the "store" is a download page, not a package manager); on Windows/Linux executing an installer found in a downloaded archive is the exact class `PR-020` exists to catch. A security downstream does not ship the attack it sells protection from |
| Overwrite-based "secure file wiping" | Physics and the filesystem, not effort: RedoxFS is copy-on-write (`R-706`) — overwriting in place allocates new blocks and leaves the old ones — and SSD wear-levelling remaps cells on every target (`installer-wizard.md`: "Nadpisywanie i tak nie wystarcza na SSD/NVMe"). A **Wipe** button would be a control that can only pass (§0.4); NTFS/ext4 journaling makes the Windows/Linux builds no better. The tree holds **no** wiper: `recipes/wip/storage/wiper` is "not compiled or tested" and upstream `ikebastuz/wiper` is a disk-usage TUI ("Disk analyser and cleanup tool"), settling the wizard's `[NIEZWERYFIKOWANE]`. The honest forms already have rows: device secure erase = `R-815` (NEW SUBSYSTEM, ⚙️) and FDE key destruction (`R-502`, RedoxFS AES-XTS — `R-305` is a retired pre-history id, §20.2) |
| "System optimisation" bundle — disk cleaner, Windows registry optimiser, driver updater | There is no registry on E-OS or Linux: a registry optimiser would exist only on the secondary platform and never raise a finding on the primary one — the `PR-008` anti-pattern — and on Windows registry cleaners are documented snake oil. The driver updater is `R-806`, whose whole design is **one signed source**; an archiver carrying a DriverBooster-style updater would be a second, unsigned driver path. Disk usage is real but not archiver scope: `ncdu` 1.22 (`recipes/tui/ncdu`) is already built by `config/x86_64/ci.toml:161` and absent from the shipped image — shipping it is a one-line config change under `R-207`, and a pane belongs in `eos-control` |
| Batch conversion "documents → PDF" (and a generic PDF/image toolbox) inside the archiver | Needs an Office-format renderer that `PR-010`/`PR-011` explicitly do not promise (`.pptx` import not promised; `.xlsx` import later via `calamine`); promising it here would reverse two scoped rows by the back door. RAW→JPG is measured buildable (`image` 0.25 + `rawloader` 0.37: 51 packages, no `cc`, Redox check 1 m 40 s) but `rawloader` is LGPL-2.1 — absent from the products' `deny.toml` allow-list and a static-linking question before any row — and it is not archiver scope; left unminted until the owner asks for a media-tools product |
| Copy-protection emulation (SafeDisc, SecuROM, LaserLock, …) and CD/DVD/BD media-type emulation | Their only consumer is the DRM check of a Windows game, and E-OS runs no games (§17.2.2, §17.5). On Windows it means a kernel driver (⚙️/🔑 — Microsoft itself dropped `secdrv.sys` in Windows 10) and is circumvention; on Linux and Redox there is nothing to emulate for. Once sectors are readable no consumer on any target distinguishes CD from DVD from BD. Refused, not deferred — the Windows build of `PR-022` does not get it either |
| MDX as a first-class image format | Daemon Tools' proprietary, obfuscated container: the only crate claiming it (`opticaldiscs 0.15.0`, `mdx` feature) needs `aes` + `pbkdf2` + `ripemd` to open one, which says what kind of format it is. `PR-022` reads ISO, BIN/CUE, CHD, VHD/VHDX and converts NRG/CCD/MDS; MDX stays out |
| A virtual-drive count ("up to 15 drives") as a specification | A Windows drive-letter artefact. A `DiskScheme` keys disks by `u32` (`driver-block/src/lib.rs:267`), so a cap is neither a feature nor a limit; `R-818` hosts any number |
| Virtual drives via an application-installed driver (the SPTD model) | `R-806`: drivers come only from the signed repository as per-driver `pkgar`, never from an installer. On Redox a virtual drive is a userspace scheme in a signed package (`R-818`), on Windows the OS's own Virtual Disk API, on Linux `udisks`. No product of ours installs a driver on any platform, and a feature that needs one (a Windows drive letter for BIN/CUE or CHD) converts to ISO instead |
| Blu-ray video (AACS / BD+) reading or imaging | DRM circumvention — `oxideav-aacs 0.1.3` exists on crates.io and is refused for that reason, not for lack of code. BD-ROM data discs without AACS are ordinary UDF and fall under `R-819` once a UDF 2.5 reader is measured |
| Restyling the context menus of upstream applications (`cosmic-files`, `cosmic-edit`, `cosmic-term`, NetSurf) and hooking the host shell's right-click on Windows/Linux (Explorer, GTK/Qt file managers) | Their menus are their toolkit's, not ours: `config/desktop.toml:12-15` ships cosmic-edit/-files/-term from upstream `pop-os` at a pinned rev (`recipes/cosmic/cosmic-files/recipe.toml`, rev `28546795`), and `repos.toml` holds **no** libcosmic or cosmic-files fork at any type (only `eos-orbital`, `eos-orbutils`, `eos-liborbital`) — a radial menu would need a rewrite of iced overlay code even inside a fork (Q23). On a host, a global right-click hook is an Explorer shell extension or a GTK/Qt module injected into other people's processes — the shape of the malware Guard exists to catch, and not something an E-OS build should install. Refused, not deferred: the style is a property of E-OS windows and the E-OS shell (`R-D15`, `R-D17`); it comes back only if a file manager becomes an E-OS product |

---

## 14. What this plan deliberately does NOT promise

This list is **part of the plan, not a footnote to it.** Both predecessors independently discovered
that the refusals and the anti-promises are the most re-read part of a roadmap, and both buried
them. They are here, next to §13 and §15, so the document's honesty is checkable in one pass.

### 14.1 About hardware and the state of proof

- **Nothing here has ever run on physical hardware.** Everything above is a projection from code and
  upstream data until the first metal run (`R-607b`, task 11 of M1) turns it into a measurement.
- **`R-601` is proven only under QEMU/TCG.** On real firmware (`R-607`) it is not.
- **QEMU will settle nothing in M1.** `installer.md` §9.3 lists nine things emulation cannot show,
  including the most common failure in practice — *"the firmware does not see the medium"*.
  **Ten hardware-matrix rows are ten separate measurements, not one box to tick.**
- **GPU 3D, HDR, USB4 and graphics acceleration** remain hardware-dependent and outside the QEMU
  path. Anything in T4 (`R-930`…`R-936`) must **never be version-promised**.
- **E-OS is unstable under `hvf` on Apple Silicon** (`R-F23`), which is exactly how it would run on
  an Apple Silicon host and in many cloud environments.

### 14.2 About the boot chain

- **Secure Boot is done, but with our own key.** On a foreign x86_64 machine it still costs the
  owner **one step** — enrolling the certificate in firmware. "Works immediately on any PC" needs a
  Microsoft signature, which §5.1.3 shows is blocked today by non-technical matters, not by code.
- **`V2-MS02` verifies the kernel and initfs, and that is NOT "a verified boot chain".** `initfs`
  carries **only disk drivers**; `xhcid`, `e1000d`, `usbhidd`, `usbscsid`, `ihdad`, `rtl8168d` and
  about ten others load from the **unsigned** root after it is mounted, through `pcid` — and without
  an IOMMU a swapped driver gets DMA, i.e. the same effect through a different file.
- **On BIOS this is not a trust anchor at all**, only tamper evidence: stage1/2/3 are raw sectors
  that nothing authenticates. Whoever can write the kernel can replace the verifier. **The installer
  must say this on the screen**, not in the documentation.
- **In live mode the whole disk image is read into RAM unverified** before the kernel is read from
  it. `V2-MS02` verifies **after** that point. Closing that gap is a NEW SUBSYSTEM in the bootloader
  and is **not** promised here.
- **There is no measured boot and no TPM** (`R-913`/`V2-N02`). FDE is RedoxFS **AES-XTS-128** with a
  key derived from a passphrase — **with no third-party cryptographic audit** and **no binding to
  TPM or Secure Boot** — so the passphrase is the only secret, the bootloader is unencrypted, and an
  attack on the password prompt itself stays in the model.

### 14.3 About the package channel

- **Package signatures protect content — since `U-223`.** blake3 hashes from the signed manifest are
  enforced on the bytes that actually install (`V2-MS13`), on **every** path because `install` now
  fetches and verifies the manifest too (`V2-MS14`), and the index carries a counter and an expiry,
  so a correctly signed **old** index is rejected (`V2-MS15`). Attack closed: whoever takes over the
  package host can no longer reproduce "manifest OK, package OK" by substituting their own key and
  re-signing the packages.
- **What that does not cover, said plainly:** the anti-rollback marker sits in an **ordinary file**
  next to the pinned key, so **root on the machine can delete it**. This is protection against a
  network attacker, not a local one.
- **A source with no remotes is deliberately exempt** from index enforcement: during image
  construction `redox_installer` already has the pinned key while `repo.toml.sig` does not yet
  exist, and without that exemption **every build would fail**.
- **There is no per-package anti-rollback before `R-704`.** The **index** is protected
  (`V2-MS15` ✅); the **package** is not — a correctly signed **older** pkgar still installs.
- **The trust chain does not reach past the build machine.** The package-signing key generates
  itself, is stored in **plaintext**, and both copies live on **one computer** (`V2-MS12b` 🟡,
  finding `C-11`).
- **There is nothing to freeze or roll back on x86_64 yet.** `gh0s777tt.github.io/eos-pkg-x86_64`
  serves only a README today (Pages enabled, every path 404s), and the local repository copy was
  lost during the `U-214` clean-up — so `V2-MS15`'s protection starts working with the first real
  release there.
- **Byte reproducibility of the release or the medium is not promised** — `R-303`/`V2-MS07` are
  open, and without them "this is the same image" is an assertion, not a measurement.
- **SNTP gives network-synced time, not trusted time.** `R-817` is plain SNTP (unauthenticated); NTS is **NOT FEASIBLE TODAY** (`ntpd-rs` needs `libc::timex`/`clock_settime`, absent from Redox libc). An attacker who spoofs the NTP reply can move the clock back and defeat the `expires` half of `V2-MS15` — the **serial ratchet remains the only anti-freeze control**, and it protects against a network attacker, not root.
- **No staged rollouts before `R-606`.** Every install is hostnamed `eos` with no `machine-id`, and `machine-uid` 0.6.0 does not build for Redox (no `target_os` arm), so `rollout_percent` bucketing (`R-704`, `R-705`) has nothing to bucket on. When it lands it is client-side and telemetry-free by construction — which also means the publisher **cannot know who took a wave**; the only brake is `rollout_percent = 0` plus a serial bump, and `eos-update rollback` for those who already applied.

### 14.4 About the installer, the wizard and updates

- **Nothing in the §6 programme is implemented** beyond the items explicitly marked ✅, which
  predate it. Until M1 has one filled-in matrix row, **EP-1 is a design, not a system**.
- **No LUKS2, dm-crypt, LVM, btrfs, ZFS, XFS, ostree, systemd-sysupdate, systemd-boot, GRUB2,
  shim+MOK, TPM2, FIDO2 or kernel live-patching.** None of these parts exists on Redox and none is
  quietly substituted with something else. With capability markers, because a list without them
  settles nothing: LUKS2 / dm-crypt / LVM / btrfs / ZFS / XFS / ostree / systemd-sysupdate /
  systemd-boot / GRUB2 / shim+MOK — **NOT FEASIBLE TODAY** (they depend on a Linux ecosystem that is
  not here); TPM2 — **NEW SUBSYSTEM**; FIDO2 — **NEW SUBSYSTEM** (needs a USB HID stack and CTAP2);
  live kernel patching — **NOT FEASIBLE TODAY** (no `ftrace`, no loadable modules, no runtime symbol
  relocation).
- **No service or driver restart after an update.** `init` knows exactly two service types
  (`oneshot`, `oneshot_async`) and supervises nothing after start, so the `service` package class of
  `ADR-0009` D6 is **disabled** until `R-816` exists. Until then everything outside class `app` goes
  the **system-restart** route — and the UI must say so rather than hide it behind "seamlessly".
- **A Linux `cryptsetup` will not open an E-OS encrypted disk** — and that belongs on the wizard
  screen, not discovered during a data-recovery attempt.
- **No snapshots and no rollback by snapshot** (see §13).
- **No A/B slots on a machine installed today.** The installer creates three partitions and gives
  the whole tail of the disk to one RedoxFS, so `R-710b` needs `R-609`, not just `R-707`.
- **No DVD boot — but the hybrid image is NOT work to be done.** An earlier version of this point
  said a hybrid ISO was *"BUILDABLE on the host with `xorriso`"* and that *"the system has no ISO9660
  driver, so a disc would start the bootloader and find no root"*. **Both sentences are false** and
  repeated an error that `installer.md` §1.2 item 13 and §2.2 retracted after measuring. The
  measured state, by signature, split by capability:
  - MBR + GPT + ISO 9660 + El Torito in one file — **WORKS TODAY** (offset 0 x86 code, 512
    `EFI PART`, 0x8001 `CD001`, 0x8801 `EL TORITO SPECIFICATION`; both images; `file` reports
    *ISO 9660 CD-ROM filesystem data (DOS/MBR boot sector) 'Redox OS' (bootable)*). The requested
    "hybrid ISO for USB and DVD" is **already satisfied at the format level** and must not be
    written down as work.
  - The El Torito entry for the **EFI** platform points at empty bytes — **BUILDABLE** (`R-611d`).
    An entry pointing at zeros is a control pretending to be a capability.
  - An optical-drive driver — **corrected 2026-09-04:** an earlier version said *"NEW SUBSYSTEM, absent from `recipes/`"*, and the grep behind it (`installer.md:211`) searched `recipes/` and `config/`, which hold `recipe.toml` files, not driver source, so it could never have found one. Read in `eos-base` (`eos-july` @ `816546df`): `ahcid/src/ahci/disk_atapi.rs` carries a **read-only ATAPI data-disc path** (IDENTIFY PACKET, READ CAPACITY, READ(10)) on x86_64 SATA — **BUILDABLE**, `[UNVERIFIED]`, never run; eject, media change, audio, IDE (`ided/src/main.rs:126` `//TODO: probe ATAPI`), aarch64 (`V2-D01`), USB (`usbscsid` binds by accident, unproven) and writing are absent. Tracked on `R-815`; first proof in QEMU (§15).
  - End-to-end DVD boot — **NOT FEASIBLE TODAY**: the EFI El Torito entry is empty (`R-611d`) and the bootloader reads raw blocks itself, so an in-system ATAPI path (`R-815`) does not help it; no driver in `ahcid` makes a disc boot.

  **The argument "without an ISO9660 driver the disc will not find the root" rested on a false
  premise:** the ISO 9660 on this medium is a **42 KiB decoy** (21 sectors of 2048 B) and the root —
  RedoxFS — is in the **third GPT partition**. The bootloader and `lived` read raw blocks, not an
  ISO directory; the root is in ISO 9660 on **no** medium, including the USB stick, and that does
  not matter. What blocks a disc is the missing drive driver, not a missing filesystem.
- **No `fsck`.** `R-615` is a NEW SUBSYSTEM. Until it exists, the only answer to filesystem
  corruption after a power cut is reinstalling — and the user has to be told that.
- **No swap.** It appears in neither the configurations nor the documentation.
  **`[UNVERIFIED]` whether the Redox kernel pages at all** — check the memory subsystem in
  `eos-kernel`. If it does, the partition-layout decision needs revisiting.
- **No disk model, serial number or SMART before `R-815`.** `disk_paths()` returns **path and size**
  and nothing more, and on Linux it is an **empty function**. The requested disk-selection screen
  exists today at about one quarter.
- **No touchpad, screen reader or Wi-Fi in the installer.** A touchpad needs an I2C bus, of which
  there is **none** (`R-916`/`V2-N01`); a screen reader needs working audio; Wi-Fi does not exist —
  so **a network installer is refused, not deferred**.
- **No sandbox for profile import.** `contain` exists and is **switched off** (`R-1010`, finding
  `C-5`). Until it is on, profile import has no isolation and the trust model rests on human review.
- **No persistent audit log.** `R-612c` gives an **installation** journal on the ESP and `R-706` an
  **update** journal; a system audit log does not exist (finding `C-9`) and §6 does not deliver one.
- **No firewall on the medium or in profiles — NEW SUBSYSTEM.** `R-904` / `C-10`: the netstack
  exposes `ip`/`udp`/`tcp`/`raw` with **zero filtering** and there is no netfilter-style hook point.
  The `net.firewall` feature exists in the schema **so that the gap is visible in the inventory**,
  not to pretend it is there.
- **No Ghost profile as requested.** Tor and VPN are NEW SUBSYSTEMS; amnesic mode and "system-wide
  anonymity" are NOT FEASIBLE TODAY; a hidden volume is **advised against as an illusion**; and
  secure erase by device command waits on `R-815`.
- **No "relaxed mitigations" in the Gamer profile.** There is no measurement, and
  **`[UNVERIFIED]` whether `eos-kernel` has any speculative mitigations at all** — without that the
  switch has no referent. Check: `grep -riE "kpti|retpoline|ibrs|ibpb|spec_ctrl|mds|l1tf"` in
  `eos-kernel`.
- **No unattended apply and no automatic restart — "like Windows Update" does not mean that here** (decision #18). The default is: download automatically, apply with consent, restart only when the user says so. Reasons are mechanical, not ideological: an FDE machine stops at the bootloader passphrase prompt on every boot (`ADR-0009` §5.1), so a night-time "automatic update" ends as a prompt with nobody there; and `sys:kstop` is root-only (`eos-kernel/src/scheme/sys/mod.rs:139-140`), reached from the GUI only through the password-gated `R-D11` shim. A `critical` package bypasses the deferral window, never verification, never the restart consent.
- **Scheduled installs are relative to boot, not to the wall clock, until `R-820` exists.** There is no cron, no timer unit and no network time source; `rtcd` reads the RTC at boot (`U-083`) and nothing corrects it afterwards, so "install at 02:00" would run at whatever the RTC says. `R-705` schedules "N minutes after boot, every N hours of uptime"; a maintenance window is 💡 on `R-820`.
- **"Enterprise policy" on E-OS is a convention, not an enforcement.** There is no MAC (`R-1010` off, finding `C-5`): root edits `/etc/eos-update.toml`, switches channels in `/etc/pkg.d` and deletes the anti-rollback watermark. The pane confirms; it cannot forbid.

### 14.5 About security tooling, applications and standards

- **Four classes of security tool are blocked on a missing OS primitive** — packet sniffer, live USB tracker, local container scanner, and **on-access file scanning** (§7.3). They need a change to the system, not just a new application; for on-access scanning the change is a file-event bus that RedoxFS does not emit and the shipped inotify only stubs.
  USB tracker, local container scanner (§7.3). They need a change to the system, not just a new
  application.
- **The desktop has no accessibility API.** Until `V2-STD07` exists, conformance with the EAA and
  EN 301 549 is **unreachable**, not "partial".
- **Anti-screenshot and anti-screen-recording in `eos-notes` are impossible from the application**
  until Orbital exposes an API (`V2-NT08`).
- **No certification from §12 is promised.** §12.1 is measurements and self-assessments, not
  certificates; §12.4 is a list of deliberate refusals with reasons.
- **Driver isolation is partial** (`R-F13`): complete at the syscall boundary, **none** at the bus
  boundary, because there is no IOMMU. User space bounds the blast radius; it does not stop a
  hostile driver.
- **The antivirus (`PR-020`) on Redox is on-demand and scheduled scanning beside Guard's integrity baseline — it does not promise real-time protection, and it does not claim a threat model built on third-party binaries**, because every package on Redox arrives through the PQ-hybrid-signed pkgar index (`R-503`, `R-703`) and there is no third-party binary ecosystem to scan. Calling a walkdir-plus-blake3 poll "real-time" would be the §5.4 check that can only pass. On Linux, on-access needs a `CAP_SYS_ADMIN` helper that `PR-008`'s `.tar.gz` cannot install (💡 until packaged, `PR-004b`); on Windows it needs a kernel minifilter signed through Microsoft's programme — ⚙️/🔑, an operator and legal step, not code. Rule updates on Redox ride the package channel and do not auto-refresh before `R-705`.
- **On Windows and Linux there is no E-OS updater and none is planned** (requirement B is an operating-system function; on a host OS it is Windows Update or the distribution's package manager). Measured 2026-09-04: `grep -rn -iE 'self.?update|check for update'` over the seven product clones → 0 hits; no product carries self-update code and `PR-008` ships zips/tarballs with no updater. The most a product on a host may do is a "newer version available" check against the signed index or the `PR-008` download page — 💡 under `PR-008`/`PR-013`, never an `R-7xx` row. "Like Windows Update" on E-OS itself promises no unattended install, no automatic restart, no active hours, no wall-clock scheduling (`R-820`), no staged rollouts (`R-606`) and no driver updates (`R-806`/`R-810`).
- **The Driver Manager (`R-806`) is E-OS-only and scan-on-demand.** It exists because E-OS has exactly one driver source, the signed repository; on Windows or Linux it would have to fetch from vendor sites and become the "driver updater" scam class `docs/architecture/driver-manager.md` §4.4 removes, so no host edition is built (§13). And nothing on E-OS emits a device event — `pcid` binds once at boot, `xhcid` polls its own ports and pushes to no bus (measured 2026-09-04, `main.rs:102/116/145`) — so "plug it in and we offer the driver" waits on `V2-S05` (⚙️); until then the pane scans when opened, at boot, and on `R-705`'s schedule.
- **"Signed driver" means verified at install, never at load.** A driver is blake3 + ed25519 (+ ML-DSA) checked when its pkgar is extracted; at boot `pcid-spawner` execs it from the unsigned root (§14.2, `V2-MS02`). No Windows-style "driver signature enforcement" badge is promised, and without an IOMMU (`R-F13`) a signed-but-hostile driver is not stopped.
- **"Outdated" has no meaning until `R-804`.** Every driver lives inside `base.pkgar` with no per-driver version (the cookbook writes `"TODO"`), so today the only honest "update" is the whole base over `R-707`'s apply-on-reboot path; and updating a bound driver stays a system restart until `R-816` exists (§14.4). The pane will say "restart required", not "seamless".
- **No firmware, BIOS, UEFI-capsule or CPU-microcode updates.** No `UpdateCapsule` path from the OS, no microcode loader in the kernel, no signed firmware channel (0 hits in `eos-kernel`, `recipes`, `config`, `docs`); ⚙️ and NEW SUBSYSTEM, and not a driver-manager feature.
- **An offline driver bundle (`R-817`) verifies classically only.** The local `/pkg` path checks the ed25519 package key; the ML-DSA hybrid signature is checked only on the repo-manifest path until the catalogue signature is verified locally too.
- **The archiver (`PR-021`) is compile-measured, not run.** Every format crate checks for `x86_64-unknown-redox` on the host with no `cc` in the graph; nobody has yet opened a 7z, RAR, CAB or ISO on Orbital, `aarch64-unknown-redox` was not built (no std on the host), and the C codec route (`zstd-sys`, `lzma-sys`, `bzip2-sys`) is unmeasured for Redox and deliberately unused. Even `cosmic-files`' own extract-here / extract-to / compress entries were read from `src/menu.rs` at rev 28546795, never seen in QEMU.
- **Recovery records are PAR2-class, not WinRAR-compatible.** A `.par2`-style sidecar on `reed-solomon-erasure` repairs our archives; WinRAR's embedded recovery record and `.rev` volumes are written only if the owner chooses `rars` under Q20. `par2-rs` itself does not build for Redox (`_SC_PHYS_PAGES` missing from Redox libc), so the container is ours.
- **ZIPX is a subset:** deflate64 and LZMA(1) entries are opened, never created — `zip` 8.6.0 refuses to write them (`write.rs:2151`, `:2198`). xz, ppmd, bzip2 and zstd are written. 7z comments wait on a `sevenz-rust2` TODO (`archive.rs:33`), not on the format.
- **No drag-and-drop into an archiver window on E-OS.** `orbclient` 0.4.3 carries the event slot (`EVENT_DROP`, `DragAction`, a `dnd` window handle) but the shipped compositor `eos-orbital` 38226c74 never emits it — its only drag code moves and resizes windows (`scheme.rs:36, 356–375`). The buildable path today is copy in `cosmic-files`, paste in the archiver over the compositor clipboard (`scheme.rs:569–612`, a single unsynchronised byte buffer flagged TODO upstream). A compositor DnD path is shell work next to cluster F's context-menu row (`R-D15`), not archiver work.
- **Right-click entries inside `cosmic-files` need a patch to upstream `pop-os/cosmic-files`** (the recipe pins upstream, not an E-OS fork); the menu style is `R-D15`. The archiver's own integration is one launcher manifest — easier than Windows, where an Explorer context menu is an unsigned COM DLL behind SmartScreen and stays a host-only packaging item.
- **Vendor clouds (Google Drive, Dropbox, OneDrive, Box) are 🔑, not scheduled** (Q21): registered developer applications, secrets in custody and consent-screen reviews are operator actions, and the OAuth loopback redirect has never been shown to work in NetSurf. WebDAV — `eos-drive` and Nextcloud-class servers — is the cloud target that exists.
- **"AES for e-mail attachments" reduces to "encrypt the file".** There is no mail client on E-OS (§14.7, `CS-008`); on Windows/Linux attaching the encrypted archive in whatever mailer the user has is the user's action, not a feature.
- **RAR is a licence decision, not a technical fact** (Q20): the only RAR engines are a non-free field-of-use-restricted decoder and a clean-room writer with contradictory licence texts. Until the owner answers, `PR-021` ships without RAR, and no page prints "RAR".
- **Backups (`PR-021b`) are scheduled, not continuous, and not point-in-time**: no file-event bus (§7.5.3) and no RedoxFS snapshot API (`R-706`); VSS and LVM/btrfs snapshots on the secondary platforms are not promised either.
- **Secure wiping is not promised anywhere** — see §13; the honest form is `R-815`'s device secure erase and FDE key destruction, both outside the archiver.
- **No DVD boot and no burning of optical media.** The boot half is §14.4; the burn half is new: `ahcid`'s ATAPI `write` returns `EBADF` (`disk_atapi.rs:145`, "TODO: Implement writing"), `libburn`/`libisoburn` sit in `recipes/wip/` with `#TODO compilation error` behind `CS-009`, and the one disc worth burning — the E-OS medium — is a disc E-OS itself cannot boot, while a second bootable artefact is refused (§13, `R-611a`). `PR-022` creates ISO files and writes the verified medium to a USB stick; it burns nothing, on any of the three targets.
- **A mounted VHD or IMG shows its partitions on E-OS, not necessarily its files.** `partitionlib` lists them (`R-818`), but only RedoxFS (and FAT, once `redox-fatfs` or `hadris-fat` ships in an image) can be mounted; NTFS and ext4 inside a Windows or Linux VHD stay unreadable on E-OS (`R-609d`). The Windows and Linux builds of `PR-022` can browse such a VHD through their own kernels — an asymmetry the product page says out loud.
- **Disc imaging covers data discs only, after the `R-815` ATAPI proof.** No BIN/CUE or subchannel dumps and no audio CDs (READ CD is a TODO at `disk_atapi.rs:81`); no DVD-Video or Blu-ray imaging (AACS is refused in §13; UDF 2.x is unmeasured).
- **UDF 1.02 in v1; UDF 2.x is not promised until measured.** `hadris-udf 2.3.0` reads UDF 1.02 mastered images; `udf-core 0.1.0` (Apache-2.0, UDF 2.50+ metadata partitions) and `oxideav-bluray 0.0.4` (MIT, `aacs` off) exist on crates.io and were not checked for Redox. The row says "unmeasured", not "impossible".
- **No live "disc inserted" or "stick plugged in" events.** There is no hot-plug/uevent bus (§7.3; `V2-S05` is a kernel change), so `R-D16`'s tray and toasts poll — a disc appears after a poll interval, not on insertion.
- **No silent auto-mount at boot.** `init` runs as root before any login and supervises nothing (`R-816`); a root service parsing a user's image list would bypass the password-gated shim every other privileged action uses (`R-D11`). `R-D16` re-attaches the last images after login, inside the session, prompting once. Silent boot-time mounting is 💡 blocked on `R-816` and on an authorisation channel that is not a password — it is not part of the 🔴 row.
- **The ISO/UDF daemon is not an unprivileged process.** The kernel allows scheme creation only to uid 0 (`eos-kernel` `src/scheme/mod.rs:321`), so `R-819` is root like `redoxfs`; what bounds a hostile disc is a separate process without MMIO/DMA, bounded parsing (`R-803`) and fuzzing (`TQ-005`) — not compartmentalisation, which waits on `contain` (`R-1010`).
- **Every Redox measurement in this cluster is `cargo check` for `x86_64-unknown-redox` on the host.** Nothing was linked with the cookbook toolchain, nothing ran in QEMU, and `aarch64-unknown-redox` — the primary development architecture (`R-811`) — could not be measured outside the container (§15 rows 27–34).
- **The context-menu style is a property of E-OS's own windows and the E-OS shell, not of every application on screen.** `R-D15`/`R-D17` cover the Slint products and `eos-orbutils`; `cosmic-files`, `cosmic-edit`, `cosmic-term` and NetSurf keep their own toolkit's menus (§13), and on Windows/Linux the host's right-click (Explorer, GTK/Qt) is untouched by construction. On Redox the keyboard (`Key.Menu`, arrows, digits, Escape) is the **only** assistive path to a menu until `V2-STD07` exists; AccessKit exposure is a host-build feature, not a Redox one. Whether a Slint popup renders and takes input over orbital at all has not been measured in QEMU — it is the first proof `R-D15` owes.

### 14.6 About this project's own process

- **Every gate in this project still runs on the developer's machine** (`R-009`). The `eos-heavy`
  runner *is* that Mac, so a green `build-image` does not close this — it moves the schedule, not
  the trust boundary. What did change on 2026-09-01: the heavy tier now executes. `build-image`
  succeeded in 1299 s, running esp-cert with its negative control, boot-smoke on both images, and
  install-smoke through to a login prompt on the installed disk.
  The shared light tier remains unreliable — GitLab aborts in ~0 s on `ci_quota_exceeded` whenever
  the monthly minutes are gone, and GitHub Actions produces no runs at all. So "in CI" clauses in
  this document split in two: those about the image build, boot-smoke and install-smoke describe an
  **executed** check; the rest remain statements about a **file** until `R-009` closes.
- **A `blake3` pin freezes an artefact; it does not authenticate it** (`R-F11`). Upstream signature
  verification is a separate, unstarted step.
- **`pins --strict` proves the pin matches the remote tip; it does not prove the image was built
  from it** — that took `eos-source-rules.sh` (`R-F20`), and `cookbook.lock` is still generated and
  gitignored.

---

### 14.7 About "everything on E-OS": the server edition, the cloud platform and the website

Written 2026-09-02 from the owner's premise *"everything on Redox and E-OS — where it can be"*.
The refusals below are what makes the `CS-*` and `WS-*` registers honest.

- **No virtual machines on an E-OS host until there is a hypervisor in the kernel.** Measured
  on the `eos-kernel` fork: the only virtualisation references are a CPUID flag being printed,
  ACPI timer fields, and `hvc #0` calling the firmware's PSCI to halt. There is no VMCS, no
  VMCB, no `vmlaunch`, no `vmrun`. `CS-201` is a kernel programme, not a feature; nothing in
  Tier 3 (`CS-201`–`CS-205`) has a date, and this document will not invent one.
- **"Windows and Linux servers" means guests, and guests need `CS-201` first.** Windows
  additionally needs UEFI and TPM emulation in the VMM and a licensing answer only the owner can
  give. Until then the honest interim is TCG emulation (`CS-204`) — slow by construction.
- **"Kubernetes" will not be Kubernetes.** `kubernetes`, `k3s`, `containerd` and `etcd` have no
  recipe at all; `nomad` and `docker` sit in `wip/` unbuilt. What can be built on Redox's own
  primitive (`Namespace::fork()`, `R-1010`) is an E-OS container runtime and a Rust orchestrator
  (`CS-101`, `CS-102`). It will not run Kubernetes manifests, and it will not be called
  Kubernetes here.
- **No AI/ML or big-data services before there is a GPU driver and a compute stack.** There is
  neither. `CS-205` stays behind §8 and Tier 2/3.
- **A `wip/` recipe is not a port.** `postgresql16`, `sqlite3`, `redis`, `postfix`, `opensmtpd`,
  `haproxy`, `caddy`, `wireguard-rs`, `qemu` exist as recipe files excluded from every image; their
  build state is **unknown** until someone builds them. Rows that depend on them say "prove the
  recipe" as the first step, and the first step is where the surprises live.
- **Built-in e-mail needs an IMAP server that does not exist on Redox.** `dovecot` and `exim` have
  no recipe; only two MTAs sit in `wip/`. `CS-008` and the website's mail (`WS-*`) are behind that.
- **The website's accounts, tickets, AI chat and mail cannot live in this repository or on static
  Pages.** They are services with a database and secrets. "On E-OS" means a `CS-001` server
  edition hosting them — which is the right target and is also why the website's dynamic half
  is sequenced after Tier 1, not before it.
- **A PIN is not a shorter password.** At the shipped argon2id cost (15.3 ms/hash) a 4-digit PIN
  falls to an offline search in 153 s on one core. `R-602d` therefore admits a PIN only as an
  online unlock factor with a try counter, never as the disk-encryption secret, and never on an
  unencrypted disk. Anyone asking for "PIN instead of password" for FDE is asking for something
  this document refuses.
- **"Latest stack" is a moving target and will be pinned, not promised.** Version numbers for the
  website's toolchain are chosen at implementation time from lockfiles, with the same
  supply-chain gates (`S-7`, `EOS_STRICT_FETCH`) this repository already applies to compilers.

---

## 15. What has not been verified, and the command to verify it

Written in the same breath as the rest, per `CLAUDE.md` §5.3. Items marked **[stale]** were true
when first written and are no longer; they are corrected here rather than deleted, because the
correction is itself information.

| # | not verified | how to settle it |
|---|---|---|
| 1 | **Fork code was not read.** `recipes/core/installer/` contains **only `recipe.toml`** — confirmed again this session by `ls`. Every claim about `installer.rs`, `disk_wrapper.rs`, `key.rs`, `header.rs`, `clone.rs` and `transaction.rs` comes from the specifications and the brief, **not from reading in this tree**. This is what makes `R-607a` and `R-612a` **`[UNVERIFIED in-tree]`**: they are ✅ on the strength of the merged MRs and the bumped pins | `scripts/eos-sync-buildtree.sh --apply`, then read `recipes/*/source`: `disk_wrapper.rs:28`, `installer.rs:604`, `installer.rs:565-660`, `installer.rs:765` |
| 2 | **[stale] The security audit was cited second-hand.** `docs/audit/03-security-audit-2026-08-30.md` was said to live on branch `fix/p0-audit-findings`. **It is on `main` now** — `docs/audit/` holds `00`…`05`, `98`, `99` plus two older audits. Findings `C-4`, `C-5`, `C-9`, `C-10`, `C-11`, `C-12`, `C-18` can and should be quoted from the tree | `sed -n '1,200p' docs/audit/03-security-audit-2026-08-30.md` |
| 3 | **[stale, corrected] `ADR-0007`–`ADR-0011` exist.** An earlier version stated `docs/adr/` ended at `ADR-0006` and that 0007–0011 were merely reserved. Both sentences were false, and the content mapping was wrong for two of them: `ADR-0008` is the **partition layout**, not transaction ordering, and `ADR-0010` is the **encryption stack**, not the profile model. Verified this session: eleven ADRs plus a template and a README. **Still unknown:** the ADRs were not read in full — only headers, Scope, and the `D*` sections cited here | `ls docs/adr/`; read `ADR-0007`…`ADR-0011` in full before approving §6 |
| 4 | **Whether `R-812`–`R-814` have individual content** in `docs/architecture/driver-manager.md`. The document lists them collectively (*"R-811…R-814 — Real-HW coverage"*), so the reservation is range-wide. `R-815` is safe under either reading, but whether that range survives at all should be settled at approval | read `docs/architecture/driver-manager.md` around the range declaration at `:16` and the real-HW section |
| 5 | **No task cost was measured.** The `S/M/L/XL` sizes come from the four specifications and the predecessor roadmap, and were estimated where neither had one. **None of them is a measurement.** | — |
| 6 | **`/etc/shadow` after the first-boot enrolment was never read.** #27 is derived from `Config::default()` in `redox_users 0.4.6` and the crate's own tests, not from a hash on a booted disk. | after `ci-install-smoke.sh`, mount the target image's RedoxFS (a **copy**, P-6) and `grep '^root;' etc/shadow` — expect `$argon2i$v=19$m=4096,t=3` today, `$argon2id$…m=19456` after `R-602g` |
| 7 | **The last successful docs-site publish is unknown** on either host. | GitLab: `glab api projects/e-os%2Fe-os/jobs?scope=success` filtered on `pages`; GitHub: the `github-pages` environment's deployments list |
| 8 | **`relibc`'s `crypt(3)` argon2 parameters** (`src/header/crypt/argon2.rs`, RustCrypto `argon2 0.5.3`) were not measured. | read the `Params` it constructs, then the same 20-hash bench as `/tmp/a2b` |
| 9 | **[stale, corrected] The check number.** An earlier version said `ci-integrity.sh` had checks 0…11 and that the new numbering gate would be **check 12**. **Check 12 already exists** — the tarball-blake3 gate at `ci-integrity.sh:339` calling `scripts/eos-check-tar-pins.py`. The numbering gate of decision D5 is **check 13**. Renumber before anyone implements it | `grep -n '^# [0-9])\|── [0-9]*\.' scripts/ci-integrity.sh` |
| 10 | **None of the proposed negative controls has been run.** The "proof it is done — and how it fails" column in §6.3 describes the **intended** shape of each test. Per `CLAUDE.md` §5.4 none of them is a test until someone has seen it fail without the fix and pass with it | run each listed control on a branch, record the output in the MR |
| 11 | **Measurements taken on a built tree are not reproducible today.** Artefact sizes, hybrid-image signatures and the contents of `build/fstools/bin/` come from a session in which the build tree existed. In a clean tree `build/` holds only `container.tag`, `hostbuild-eos-control` and `id_ed25519.pub.toml` | `make CI=1 ARCH=x86_64 CONFIG_NAME=eos live` and `make fstools`, then repeat the offset measurements and the binary listing |
| 12 | **Bootloader code was not read.** Classifying the boot-attempt counter (`R-707`, M7) as a NEW SUBSYSTEM rests on `ADR-0009` saying the bootloader has no write path — not on reading it. `recipes/core/bootloader/` in this tree is `recipe.toml` + `sbat.csv`, confirmed | in `eos-bootloader`, look for any write path to the ESP or to RedoxFS |
| 13 | **`R-F16`'s x86_64 expectation.** x86_64 is *expected* to be unaffected by the GIC defect because MSI/MSI-X avoids that path entirely — **never verified**; no x86_64 image has been built and booted for that purpose on this host | build the x86_64 image and run the INTx reproducer against it |
| 14 | **`R-902`'s DHCP/static toggle has never been screendumped.** The pane and its apply flow were; the toggle's non-visual core is `--selftest`-proven inside a boot-smoked image. A GUI render is only proven by screendump | boot the image, open eos-control → Network, toggle, `screendump` |
| 15 | **`R-901`'s pcap has not been re-run** against a current image; the proof is from the original fix | re-run the `-object filter-dump` capture on the current aarch64 image |
| 16 | **Whether the Redox kernel pages at all** (swap, §14.4) | inspect the memory subsystem in `eos-kernel` |
| 17 | **Whether `eos-kernel` has any speculative-execution mitigations** (§14.4) | `grep -riE "kpti\|retpoline\|ibrs\|ibpb\|spec_ctrl\|mds\|l1tf"` in `eos-kernel` |
| 18 | **Whether `nvmed`/`ahcid` expose any administrative command channel** (`R-815`) — *partly answered 2026-09-04:* `ahcid` has an ATAPI read path (`disk_atapi.rs`), no eject/removable/media-change command anywhere in `drivers/storage/` (only the `StartStopUnit` opcode enum entry); `nvmed` not re-read | read `drivers/storage/nvmed/src/**` in `eos-base`; the ATAPI half is rows 27–28 below |
| 19 | **Whether keyboard layouts exist anywhere** (`R-603d`) | check `eos-orbital` and `eos-orbdata` |
| 20 | **Whether `fsync` is durable on RedoxFS** (`R-706`, `R-612c`) | write a power-cut test against the journal format before committing to it |
| 21 | **Two items have no register row and are named here so they are not lost:** the KDF audit for AES-XTS (`EA-2`) and the honest first-run security-posture screen (`EB-4`). Offline update from removable media (`EC-7`) **was folded into `R-705`** on 2026-09-04. Also **`C-20` (enforce commit signing)** has no roadmap item | decide at approval: mint rows or fold each into `R-603b` / `S-1` |
| 22 | **`.github/workflows/_canary.yml` is missing** although `CLAUDE.md` §13.1 cites it as the reproducible Actions measurement | restore the file or correct `CLAUDE.md` |
| 23 | **`R-201`, `R-207`, `R-402`, `R-403` carry no in-tree evidence** in either predecessor beyond a one-line description. They are carried forward at their inherited status and should be re-scoped or retired at the next review | define an acceptance criterion for each, or move to Annex C |
| 24 | **[measured 2026-09-05 — partly] Root can open the ESP block device and `fatfs` lists `EFI/BOOT/BOOTX64.EFI` from its bytes** (`R-707`, ADR-0009 D7) — **but a seek-then-read through the `1p1` partition entry returns a mangled sector, and the marker-write/external re-read and the bootloader grep were not done.** Fresh `cp -c` clones of `eos-0.2.0-x86_64-installer.img` (sha256 `6c7c0c6f…d00fe8`) under QEMU 11.0.2 TCG (q35, OVMF, one NVMe `serial=eos`, e1000 slirp), root via the first-boot password flow, four guest sessions (measurer runs 1–3 + sceptic `verify-24`). With one NVMe the boot disk is `/scheme/disk.pci-0000-00-04.0-nvme` (the kit's `05.0` path → `No such device`; in the two-NVMe prepare layout 05.0 was the probe disk). `nvmed` lists the GPT partitions: `ls` → `1 1p0 1p1 1p2`, `ls -l` sizes 1468006400 / 1031168 / 1048576 / 1464860672 — an exact match of a host-side GPT parse of the clone (BIOS 34..2047, EFI 2048..4095, REDOX 4096..2865151). The `s15probe` (fatfs 0.3.6 + fscommon 0.1.1, read-only `File::open`) opens `…/1` (len 1468006400) and `…/1p1` (len 1048576) without error; `1` is not a FAT volume (`invalid bytes_per_sector value in BPB (not power of two)` — protective MBR, type 0xEE). Read **sequentially** the ESP is correct through both devices: `tail -c +1048577 …/1 \| head -c 1048576 > esp3.img` (run 2) and `head -c 1048576 …/1p1 > p1seq.img` (verify-24, exit 0) each give a 1 048 576-byte file that fatfs lists as FAT12, volume id `0x12345678`, label `NO NAME`, `/: EFI <DIR>`, `EFI/BOOT/: ., .., BOOTX64.EFI 232504` → `S15-ESP-OK`; `od -j 6656` on `p1seq.img` shows the real root-directory bytes `41 45 00 46 00 49 00 00 00 ff ff 0f 00 2d ff ff …`, identical to the host clone. Pointed **directly at `1p1`** (run 3, reproduced identically in verify-24) the same probe parses the boot sector correctly (FAT12, `0x12345678`, `NO NAME`) but its seek-then-read of the root-directory sector (partition offset 6656) returns a mangled 512-byte sector — 16 identical 32-byte slots whose first 11 bytes are the LFN bytes of the `EFI` entry (printed as name `AE\0F\0I\0\0.` + U+FFFD), size field 1174422849 = bytes `41 45 00 46` — so `open_dir(EFI/BOOT)` fails with `No such file or directory` → `S15-ESP-FAIL` (the probe still exits 0; only the marker line signals it). Small/unaligned reads fail outright: `od -N 64 [-j N]` on `1p1` and on `1` → `od: I/O: Invalid argument (os error 22)`, so a positional-read comparison between `1` and `1p1` could not be measured and the faulty component (`nvmed`, the partition layer, or relibc `lseek`/`read`) is not isolated — a defect in seek+read access to `nvmed` partition entries to file before any ESP-writing feature relies on `1pN` paths; sequential access is the known-good workaround. Tool caveats: `dd` cannot write on this image (`dd: write error`, exit 1, no/0-byte output even from `/dev/zero`), so extraction used `tail`/`head`; `tail` aborted with `Invalid opcode fault` (kernel `UNHANDLED EXCEPTION … /usr/bin/tail`, exit 1) after the complete 1 MiB had been written — cause not measured; run 3's 300 s budget expired during the `1p1` probe, its last 8 commands were sent without capture (could not measure). **Not done:** no write to the ESP, no marker and external re-read after a clean shutdown, no `eos-bootloader` source grep — those two asks stay open. Logs: `~/eos-artifacts/dowody/s15-qemu-2026-09-05/rows-24-25-29-serial.log`, `-run2-serial.log`, `-run3-serial.log`, `verify-24-serial.log` (+ `-commands.txt`, `-driver.out`, `-run-qemu.sh`); note `SHA256SUMS` there lists `guestrun.py` as `bc743cd0…` while the file hashes `21b1db82…`. *Was:* **Whether root in the running image can open the ESP partition and `fatfs` can list it** (`R-707`, ADR-0009 D7). Host `cargo check` of `fatfs` 0.3.6 for `x86_64-unknown-redox` passed; the installer does the same from user space — but a 20-line probe in QEMU was **not run** (container reserved), and the bootloader's side of the flag/counter is still row 12 (`eos-bootloader` `eos-rebased` `d421744` is not cloned on this host) | in QEMU as root: `ls /scheme/disk.*/`, then a `fatfs` probe opening the ESP block path and printing `EFI/BOOT/`; write a marker, re-read the ESP externally after a clean shutdown; `grep -rn -iE 'write\|create\|counter\|pending\|BOOT_TIME' eos-bootloader/src` |
| 25 | **[measured 2026-09-05] The time-sync path end to end** (`R-820`, `R-705`): **(a) `sys:update_time_offset` refuses `user` with `EPERM` and takes root's write immediately; (b) SNTP over UDP 123 reaches the internet through slirp; (c) the image's `curl` does HTTP Range (`206`) against the Redox mirror — the E-OS repo URL on GitLab is a `404`.** Fresh `cp -c` clones of `eos-0.2.0-x86_64-installer.img` (`6c7c0c6f…`) under QEMU TCG (q35, `-smp 4 -m 2048`, NVMe boot disk, `-device e1000,netdev=n0 -netdev user,id=n0`), three measurer boots + one sceptic boot (`verify-25`). (a) As root `printf '\0%.0s' {1...16} > /scheme/sys/update_time_offset` (16 bytes per `wc -c`; ion's `{1..16}` is exclusive) prints nothing, `echo $?` → 0, and `date` jumps from the wall clock to uptime: `Sat Sep 5 05:54:15 UTC 2026` → `Thu Jan 1 00:10:10 UTC 1970` (run 1; `06:16:30` → `00:11:42 1970` run 2; `06:44:31` → `00:01:44 1970` verify) — the clock change is the evidence, since ion prints `$?`=0 even after a **failed** redirection. As `user` (uid 1000 per `/etc/passwd`, reached by interactive `su user`, which asks no password and gives `user:~$`) the same line fails: `ion: pipeline execution error: failed to redirect stdout to file '/scheme/sys/update_time_offset': Operation not permitted (os error 1)`; from `sh /tmp/tofs.sh`: `line 4: /scheme/sys/update_time_offset: Operation not permitted`, script `$?` = 1 (that POSIX `sh` does not expand `{1...16}`, `wc` printed 1; the EPERM comes from `open()` regardless). The row's `sudo`/`su -c` form is unusable here: `sudo -u user …` → `sudo: failed to execute -u: No such file or directory (os error 2)`, `su user -c …` → `USAGE: su [LOGIN]`; `exit` from the user shell returns to root after a harmless `[src/procmgr.rs:1703 ERROR] failed to send SIGCHLD to parent … Operation not permitted`. `ls -l /scheme/sys/update_time_offset` says `Is a directory` (os error 21). (b) `/etc/net/{dns,ip,ip_router,ip_subnet}` = `9.9.9.9` / `10.0.2.15` / `10.0.2.2` / `255.255.255.0` are **static image files** (`config/base.toml` "Default net configuration (optimized for QEMU)", mtime = image build); the live netstack reads `/scheme/netcfg/ifaces/eth0/addr/list` = `10.0.2.15/24` and `/scheme/netcfg/resolv/nameserver` = `10.0.2.3` (slirp's DNS); whether `dhcpd` ran was not measured (no dhcpd line in any boot log, none in `ps`; `dhcpd` exists in `/usr/bin`). `ping -c 1 10.0.2.2` → 2.687 ms (`which ping` → `/usr/bin/ping`, 686168 B). UDP 123 passes: the `sntpc` probe got a stratum-1 reply from 216.239.35.0 (`S15-SNTP-OK unix_seconds=1788587355`, roundtrip 203 ms), a hand-rolled 48-byte packet got a 48-byte stratum-1 reply (rtt 518 ms, guest clock 2 s behind), and `pool.ntp.org` resolved and answered (`unix_seconds=1788587365`, stratum 2, run 1; `1788590667`, stratum 1, verify) — which resolver the probe used was not determined. `/usr/bin` (309 entries) has `eos-netcfg`, `netstack`, `netsurf-fb`, `dhcpd`, `ping`; nothing matching `ntp`. (c) `curl -sS -r 0-1023 https://static.redox-os.org/pkg/x86_64-unknown-redox/repo.toml -o /tmp/r1.bin -w '%{http_code}\n'` → `206` (runs 1 and verify; `code=206` run 2), curl exit 0, `/tmp/r1.bin` 1024 bytes; the `-D` dump shows `HTTP/2 206`, `content-length: 1024`, `content-range: bytes 0-1023/36924` — TLS, DNS and Range work. `https://gitlab.com/e-os/eos-pkg-x86_64/-/raw/main/repo.toml` → `404` (`HTTP/2 404`, text/html, 2679-byte body, exit 0, same with `-L`): TLS/DNS to gitlab.com work but the URL does not exist or the project is private, so Range on that endpoint could not be judged. Tooling defects met on the way: Redox `grep` rejects `-E` (`Invalid parameter '-E'`) and multiple `-e`; `ls /usr/bin \| grep -iE …` killed `ls` with a page fault (`UNHANDLED EXCEPTION … NAME /usr/bin/ls`); `tail -c … \| head -c …` aborts with `Invalid opcode fault`; `dd of=`/`dd > file` → `dd: write error`. Harness: run 1's user-shell part was typed blind (root-only prompt regex); run 2 used a driver copy whose only change is `PROMPT_END` also accepting `user:…$ ` (diff verified); the root write was always done after the network tests. Logs: `~/eos-artifacts/dowody/s15-qemu-2026-09-05/rows-24-25-29-serial.log`, `-run2-serial.log`, `verify-25-serial.log` (+ `-commands.txt`, `-driver.out`, `-run-qemu.sh`). *Was:* **The time-sync path end to end** (`R-820`, `R-705` maintenance windows): (a) that a write to `/scheme/sys/update_time_offset` fails with `EPERM` as a user and succeeds as root — read from `sys/mod.rs:139-140`, not executed; (b) that SNTP over UDP 123 reaches the internet through QEMU's slirp — the netstack's UDP path was never exercised for this; (c) whether `curl` in the image supports range/resume (`R-710a`, `system-updates.md` §11 item 6) | as user then via `sudo`: `printf '\0%.0s' {1..16} > /scheme/sys/update_time_offset; echo $?`; an `sntpc` probe against `pool.ntp.org`; `curl -sS -r 0-1023 <repo>/repo.toml -o /dev/null -w '%{http_code}\n'` |
| 26 | **The negative control for the local-mirror source** (`R-705`, ex-`EC-7`): read in the fork, a source with no remotes skips index enforcement (`pkgar_backend/mod.rs:160-170`, the `V2-MS14` build-time exemption), so a naive "point `pkg` at the USB stick" would silently drop `repo.toml.sig` + serial checks. That it is *wrongly accepted* today was **not demonstrated** in a running image | a signed repo on a second QEMU disk, added via `add_local`, `pkg update` with a tampered `repo.toml` — assert it is accepted (the bug) before, refused after `R-705` lands |
| 27 | **[measured 2026-09-05] `ahcid`'s ATAPI path binds and reads a data disc bit-exactly — `CD001` at 0x8001** (`R-815`, `PR-022`) — **but a read that crosses the end of the medium gets `I/O error` instead of a short read, and `dd` in the image cannot write, so the row's `dd \| xxd` form was replaced by `cp` + `xxd`.** Fresh APFS clones of `eos-0.2.0-x86_64-installer.img` (RedoxFS UUID `a4609fa6-…`, 1397 MiB), QEMU 11.0.2 TCG, q35/UEFI, `-smp 4 -m 2048`, `probe.iso` (921600 B = 450 × 2048, sha256 `88b4bad7…`) attached as `-drive if=none,id=cd0,media=cdrom,file=probe.iso -device ide-cd,bus=ide.0,drive=cd0` = port 0 of the ICH9 AHCI at `00:1f.2`; measurer runs 1–2 (25 s / 29 s to shell, 32/32 and 35/35 commands) + sceptic `verify-27` (25/25). Binding: pcid `PCI 0000:00:1f.2 8086:2922 01.06.01.02 1 SATA AHCI`, `pcid-spawner` spawns `ahcid`, `pci-0000-00-1f.2_ahci-0: SATAPI`, `Serial: QM00001 … Model: QEMU DVD-ROM`, ports 1–5 `None`; scheme `disk.pci-0000-00-1f.2_ahci` (underscore, `ahcid/src/main.rs` `name.push_str("_ahci")` — the hyphen spelling gives `No such device`, code 19) with one entry `0`; `stat` → size 921600, Blocks 450, IO Block 2048, mode 0000 — READ CAPACITY honoured. Reading: `head -c 2048 …/0 > blk0.bin` → 2048 B, exit 0, sha256 `e5a00aa9…` = host's first 2048 B; `cp …/0 cp.bin` → 917504 B (448 blocks) with sha256 `5aa0961a…e42e67` = host `head -c 917504 probe.iso` (recomputed by the sceptic); `xxd -s 32768 -l 64 cp.bin` → `0143 4430 3031` = `CD001` at 0x8001 (PVD): READ(10) data is bit-exact for blocks 0–447. Every whole-device read (`cp`, `sha256sum`, `cat`) ends with `[@ahcid::ahci::hba:451 ERROR] IS 40000000 IE 17 CMD 3000006 TFD 5041` (error register 0x50 = sense key 5, ILLEGAL REQUEST) followed by `I/O error`, exit 1, stopping at 917504 = 112 × 8 KiB: the reader's 8 KiB request at block 448 crosses the 450-block end and `driver-block/src/lib.rs` `read()` passes it through unclamped (only `buf.len() % block_size != 0 → EINVAL`). Blocks 448–449 ARE readable when the request ends exactly at the medium end: `tail -c 4096 …/0` → exit 0, 4096 B, sha256 `ad7facb2…` = host's last 4096 B (all zeros — a weak content check), no `ahcid` error. Non-2048-multiple reads fail: `xxd -l 64 …/0` → `Invalid argument`, exit 2; `s15probe`/fatfs (512-byte boot sector) → `Invalid argument (os error 22)`. `ahcid` stayed alive throughout (`ls` lists `0` after every error, all three runs). `dd` (uutils coreutils 0.7.0) prints `dd: write error` (exit 1, no output file, nothing written to a pipe) for **every** input tried: the ATAPI device, the real NVMe boot disk `/scheme/disk.pci-0000-00-04.0-nvme/1` (verify-27; the measurer's run-2 "control" and the kits' `dd` used the nonexistent `05.0-nvme`/`06.0-nvme` schemes and showed nothing), a regular file `/home/root/blk0.bin`, and `/nonexistent`. Source-level, not measured: `disk_atapi.rs` `read()` advances `sector += blk_len` (2048) instead of `+= buf_len` (64) for requests ≥ 64 blocks. Other notes: `ls /scheme/` not run (kit rule: listing `/scheme` hangs the shell; the scheme name came from the `ahcid` source and was confirmed by the guest); `od` on an empty pipe died with `UNHANDLED EXCEPTION … PID 110, NAME /usr/bin/od` (GUARD PAGE), unrelated to `ahcid`; with `-drive media=cdrom` present QEMU adds no default empty DVD (kit3/kit4 without it: port 2 `QM00005` failing probe with `TFD 2041`, `2: I/O error`). Logs: `~/eos-artifacts/dowody/s15-qemu-2026-09-05/row-27-ide-cd-serial.log`, `row-27-ide-cd-serial-run2.log`, `verify-27-serial.log` (+ `-commands.txt`, `-run.out`, `-run-qemu.sh`, `*.clean.txt`). *Was:* **Whether `ahcid`'s ATAPI path reads a data disc at all** (`R-815`, `PR-022`) — the code exists, no run has ever exercised it | `qemu-system-x86_64 -M q35 -m 2G -drive file=eos-x86_64-harddrive.img,format=raw -drive if=none,id=cd0,media=cdrom,file=probe.iso -device ide-cd,bus=ide.0,drive=cd0 -serial stdio`; inside: `ls /scheme/disk.pci-*-ahci/` and `dd if=/scheme/disk.pci-*-ahci/<n> bs=2048 count=16 \| xxd \| head` — expect `CD001` at 0x8001 |
| 28 | **[measured 2026-09-05 — partly] `usbscsid` binds to and identifies a USB optical drive (INQUIRY and READ CAPACITY(10) answered, disk registered with an off-by-one size), but every block-aligned read of it blocked without returning and could not be interrupted** (`R-815`) — **whether the SCSI READ was ever issued, and whether the stall is in `usbscsid` or wider, was not separated.** Fresh APFS clones of `eos-0.2.0-x86_64-installer.img` (`6c7c0c6f…d00fe8`; the guest banner calls itself `E-OS 0.1.0 "Genesis"`), live boot, UEFI, `-smp 4 -m 2048`, TCG, `probe.iso` (921600 B, ISO 9660, `CD001` at 0x8001, 450 × 2048-byte blocks) as `-device usb-storage,drive=usbcd,removable=on` on `qemu-xhci`; two measurer boots + a third sceptic boot (`verify-28`, stopped after the bind lines, 25 s to shell). BIND: yes — `xhcid`: `Loading subdriver "SCSI over USB" for port 2 iface 0 alternate 0 class 8.6 proto 80`, `Device on port 2 was attached`; `usbscsid` (present in `/usr/lib/drivers/`): `USB SCSI driver spawned with scheme `usb.pci-0000-00-02.0_xhci`, port 2, protocol 80`, `Inquiry version: 5`, `read_capacity10 result: ReadCapacity10ParamData { max_lba: 3238068224, block_len: 524288 }` (raw big-endian fields = last LBA 449, block length 2048), `usbscsid: SCSI initialized`; `ls -l /scheme/disk.usb-usb.pci-0000-00-02.0_xhci+2-scsi/` → `---------- 0 root root 919552 Jan 1 1970 0` every time it ran in the foreground (919552 = 449 × 2048, one block short: `ReadCapacity10ParamData::block_count()` returns the last-LBA field, `cmds.rs:452-454`). READ: no data was ever obtained. Boot 1: `od -A x -t x1z -N 64 -j 32768 …/0` produced no output for 813.7 s, after which the driver's `^C` did not recover the shell. Boot 2: `head -c 2048 …/0 \| xxd \| head -4 &` (job `[0] 91`, started after `date` = 06:23:27) was still listed `Running` by `jobs` at 06:31:48 with no output, and the later background jobs — `ls -l` of the USB scheme (100), a 34816-byte read (105), `s15probe esp …/0` (114), a 919552-byte read (119) — were all still `Running` then; whether they were queued behind `usbscsid` or stalled for another reason was not separated by a control (ion's background pipelines are themselves broken: `tail: cannot fstat 'standard input': Bad file descriptor`). Sub-block requests never reached the device: `xxd -l 64` and `xxd -s 32768 -l 64` on the USB disk → `Invalid argument`, exit 2 (`driver-block/src/lib.rs:200-201` rejects lengths that are not block multiples). Two user-space page faults were logged (boot 1: `UNHANDLED EXCEPTION, CPU #0, PID 94, NAME /usr/bin/dd` around `dd if=…/0 bs=2048 skip=16 count=1 \| xxd -l 64`; boot 2: `PID 83, NAME /usr/bin/head` around `head -c 64 …/0 \| xxd &`, whose job was reported `ion: ([0] 82) exited with 1`) — consistent with the readers crashing, but the serial ordering (dump interleaved with the echo of the still-incomplete command line) does not prove which process. No `usbscsid: READ IO ERROR` line ever appeared; the only `xhcid` diagnostic was `Lost event TRB type 32, completion code: 1` at 06:15:33 in boot 2, ~22 s after `xhcid` started and before any read. The command the driver would send is READ(16) per source (`scsi/mod.rs:267-268`), but no evidence shows whether it was issued. `dd` is not an instrument in this image (uutils dd 0.7.0 prints `dd: write error`, exit 1, even for a 3-byte text file and `if=/nonexistent`); the row's literal `ls /scheme/` / `ls /scheme/disk.usb-*-scsi/` were not run (the kit records that listing or globbing `/scheme` hangs the shell); no QEMU-monitor output was filed. Logs: `~/eos-artifacts/dowody/s15-qemu-2026-09-05/row-28-usb-cd-serial.log` (all phases concatenated with `#####` headers), `row-28-usb-cd-commands.txt`, per-phase logs/launchers/drivers under `row-28-usb-cd/`, `verify-28-serial.log` (+ `verify-28/`). *Was:* **Whether `usbscsid` binds and reads a USB optical drive** (`R-815`) — `scsi/mod.rs:222` only changes the mode-page layout for non-DirectAccess | QEMU `-device qemu-xhci -device usb-storage,drive=usbcd,removable=on -drive if=none,id=usbcd,media=cdrom,file=probe.iso`; then `ls /scheme/disk.usb-*-scsi/` |
| 29 | **[measured 2026-09-05] `redoxfs` mounts from a plain file path on Redox — YES** (`R-818`): **mkfs, mount, write and read-back on a 32 MiB regular file all work; the row's literal `dd` recipe cannot run on this image for two reasons unrelated to `redoxfs`.** Fresh `cp -c` clones of `eos-0.2.0-x86_64-installer.img` (`6c7c0c6f…0fe8`), QEMU TCG (q35, `-smp 4 -m 2048`, NVMe, e1000 slirp), default live boot (`Press l to disable live mode`, `Switching to live disk`), `ls /scheme/disk.live/` → `0`; measurer run 2 + sceptic `verify-29` (37/37 commands returned, 0 timeouts, identical outcome). (1) `dd` (`/usr/bin/dd`, `dd (uutils coreutils) 0.7.0`) fails on every output form tried — `of=FILE`, `> FILE`, `\| cat > FILE` — with `dd: write error`, exit 1 (the pipeline form reports `cat`'s 0), leaving no file or a 0-byte file; 12 invocations across four boots, inputs `/dev/zero`, the NVMe disk and `/scheme/disk.live/0`. (2) `/scheme/disk.live/0` cannot be opened for reading while the live root runs: `head -c 16777216 /scheme/disk.live/0 > /home/user/live.img` → `head: cannot open '/scheme/disk.live/0' for reading: No record locks available`, exit 1, 0-byte file; `ls -l` → `Os { code: 37 … "No record locks available" }` (ENOLCK is what was measured; that the root `redoxfs` daemon, PID 20 `/scheme/initfs/bin/redoxfs`, holds the lock is an interpretation). `redoxfs /home/user/live.img imgtest` on that 0-byte file → `ERROR redoxfs] failed to open filesystem /home/user/live.img: No such file or directory` / `not able to mount path …`, exit 1; `ls /scheme/imgtest` → `No such device`, exit 2. The answer: `head -c 33554432 /dev/zero > /tmp/t.img` (exit 0; regular file, 33554432 B; `/dev/zero` → `/scheme/zero`) → `redoxfs-mkfs /tmp/t.img` → `created filesystem on /tmp/t.img, reserved 0 blocks, size 33 MB, uuid 579c93be-…` (`361fe7f5-…` in verify), exit 0 → `redoxfs /tmp/t.img imgtest2` → no output, exit 0, prompt back in ~5 s, `ps` shows a second `/usr/bin/redoxfs` (PID 86) running → `ls /scheme/imgtest2` → empty, exit 0 (on an unmounted name the same `ls` says `No such device`) → `echo hi > /scheme/imgtest2/x` → 0 → `cat /scheme/imgtest2/x` → `hi`; `ls -l /scheme/imgtest2/` → `-rw-r--r-- 1 root root 3 … x`. Bonus (verify only): a 16 MiB `head -c` truncation of that image mounts too (`redoxfs /tmp/t16.img imgtest3` → exit 0, `ls /scheme/imgtest3` → `x`), i.e. the shape of the row's recipe works once its input is a readable file. Not exercised: the literal 16 MiB copy of the live disk (needs a host-side copy or a boot with live mode off). Any §15 recipe that says `dd of=` must be rewritten with `head -c`/shell redirection on this image; the mounts were left running inside the throwaway guests. Logs: `~/eos-artifacts/dowody/s15-qemu-2026-09-05/rows-24-25-29-run2-serial.log`, `verify-29-serial.log` (+ `verify-29-extract.txt`, `-commands.txt`, `-driver.out`). *Was:* **Whether `redoxfs` mounts from a plain file path on Redox** (`R-818`; `mount.rs:170` `DiskFile::open(path)` suggests yes) | in a booted E-OS: `dd if=/scheme/disk.live/0 of=/home/user/live.img bs=4096 count=4096 && redoxfs /home/user/live.img imgtest && ls /scheme/imgtest` |
| 30 | **[measured 2026-09-05 — settled] A file-backed `driver_block::Disk` daemon written OUTSIDE `eos-base` links, runs, serves the file's partitions and takes block-aligned reads *and* writes; `DiskScheme` needs no patch for that, but it has no add/remove API at all** (`R-818`). The probe `imgd` (142 lines, `dowody/s15-row30-2026-09-05/crate/`) depends on `driver-block` **by package name from the eos-base git repository** (a workspace member, the `eos-credpolicy` pattern) and cross-builds with the cookbook toolchain in 11 s: `cookbook_redoxer env cargo build --release --target x86_64-unknown-redox` → static ELF x86-64, **591 744 B without the read/write tracing (used in run 8) and 591 736 B with it (runs 10–12, the shipped artefact)**. `Cargo.lock` resolves `daemon`, `driver-block`, `executor`, `partitionlib` and `scheme-utils` from the eos-base checkout `816546df`; `redox-scheme` 0.11.4 and `gpt` 3.1.0 come from crates.io (the latter through `partitionlib`). **Trap:** `daemon::Daemon::new` refuses a manual start — `Daemons can't be started manually. Add a service config to make init start this daemon instead.` (verified in the upstream source at the pinned revision, `daemon/src/lib.rs:16` in `get_fd`, reached from `get_fd("INIT_NOTIFY")`; the guest run that printed it is **not** among the logs shipped here). The E-OS patch turns an *invalid* fd into `None`, so `INIT_NOTIFY=99` also gets past it — but `DiskScheme::new` takes `Option<Daemon>`, so a shell-started probe passes `None` and simply never signals readiness. In the guest (installed disk from `e-os!133`, **four boots, one command set each: `runs/run{8,10,11,12}`**, files fetched over slirp inside the same boot — P-36): `imgd /tmp/probe.img &` → `imgd: serving /tmp/probe.img (1048576 B, 512 B blocks) as disk.image0`, and in the traced builds the daemon's own `read` is called at once for **blocks 1..33** — `partitionlib` reading the GPT header (LBA 1) and all 32 blocks of entries (LBA 2–33), exactly what the image's header declares. `ls /scheme/disk.image0` → **`0  0p0  0p1`**, `ls -la` sizes `1048576 / 114688 / 114688` = the whole file and the two GPT partitions of the probe image, so **the row's expectation `0p1…` is wrong in one detail: partitions are numbered from zero** (`0p0` is the first); the real NVMe disk shows the same shape (`1 1p0 1p1 1p2`, measured in `dowody/s15-qemu-2026-09-05/`, not here). Content proves the offsets are applied: `head -c 512 …/0p0` → `imgd: read block=64 len=512` (LBA 64 = partition 1), bytes `ROW30-P1-DATA-…`; `head -c 1024 …/0p1` → `read block=288 len=1024` (LBA 288 = partition 2), `ROW30-P2-DATA-…`. **Writes work when aligned:** `cat /tmp/blk.bin > /scheme/disk.image0/0p0` with a 512-byte file → `imgd: write block=64 len=512`, and reading `0p0` back returns `ROW30-P2-DATA-…`, the block that was written (run 12). **Sub-block I/O fails:** `-c 42` on `0p0` and `0p1`, `-c 32` and `-c 16` on `0p1`, `-c 8` on `0` and a 15-byte `echo >` all end in `Invalid argument (os error 22)`; sizes 512 and 1024 always succeed. What the logs prove is that `FileDisk::read`/`write` is **never entered** for the failing sizes (the probe logs both before validating anything), so the refusal happens above the disk — **which layer refuses (the scheme handler, `redox-scheme`, or relibc under `head`) is not proven here**, and `head` blames its own stdout write (`head: error writing 'standard output': Invalid argument`). **Add/remove:** `impl<T: Disk> DiskScheme<T>` exposes only `new`, `event_handle` and `tick` (plus `on_close`), and the disk map is moved in at construction — there is no public way to add or remove a disk afterwards, so hot-plug does need a patch; nothing here proves what that patch should look like. Note for anyone re-reading the logs: every run ends `VERDICT: FAIL` because the harness is `serial-selftest.sh` reused unchanged and it looks for `GUARD-SELFTEST-OK`, which these command sets never run. Logs, the crate and the built binary: `dowody/s15-row30-2026-09-05/` | in the container: build a ~60-line daemon with git dependencies `driver-block` + `daemon` on `eos-base` for `x86_64-unknown-redox`; in QEMU attach an IMG, `ls /scheme/disk.image0/`, expect `0p1…` from `partitionlib` |
| 31 | **[measured 2026-09-04, evening] The pure-Rust image crates link on both Redox arches** (`R-819`, `PR-022`): the `probe-pure` crate (hadris-iso/udf/fat 2.3, iso9660-rs 1.0.2, am-img-vhd/vhdx 0.3.4, chd 0.3.4, cue-rw 0.3.0, qcow2-core 0.3.4, vmdk-core 0.8.4) built in the build container with the cookbook toolchain through `cookbook_redoxer env` (`CC=x86_64-unknown-redox-gcc` / `aarch64-unknown-redox-gcc`, `CLAUDE.md` P-17): `cargo build --release --target x86_64-unknown-redox` → Finished 20.99 s → `ELF 64-bit LSB executable, x86-64, statically linked`, 400 528 B; `aarch64-unknown-redox` → Finished 8.49 s → `ELF … ARM aarch64, statically linked`, 499 408 B. Logs: `~/eos-artifacts/dowody/s15-2026-09-04/s15.log`. *Was:* only `cargo check` for `x86_64-unknown-redox` on the host; `aarch64-unknown-redox` has no host `rust-std` | in the container: `cp -r probe-E-disc-images/pure` and `cargo build --release --target x86_64-unknown-redox && cargo build --release --target aarch64-unknown-redox` |
| 32 | **[measured 2026-09-04/05 — settled] The CHD decompressors of `opticaldiscs` do build with the cookbook toolchain, but not from the crates.io package.** `opticaldiscs` 0.15.0 exposes `chd = ["dep:libchdman-rs"]` (on by default; the first probe had it off through `default-features = false`, so it measured only the `zstd-sys`/`liblzma-sys` C in the graph). `libchdman-rs` 0.288.11 as published on crates.io cannot be built for either Redox target: its tarball ships no C/C++ (`build.rs:54` panics "requires MAME's vendored C++ source … NOT shipped in the crates.io package") and its `prebuilt` archives exist only for linux-gnu/apple/windows-msvc; on this aarch64 host the x86_64 attempt dies even earlier because `cookbook_redoxer env` exports an unprefixed `CC=x86_64-unknown-redox-gcc` that also reaches the host build-dependency `ring` (`prebuilt → ureq → rustls`; "file in wrong format") — `HOST_CC=cc HOST_CXX=c++ HOST_AR=ar` is needed. With the git tag `v0.288.11` (sparse checkout of the MAME submodule dirs `build.rs` uses, 48 MB) substituted through `[patch.crates-io]` and `LIBCHDMAN_FORCE_SOURCE=1`, the LZMA SDK, zlib, utf8proc, zstd, libFLAC and MAME's `chd`/`cdrom`/`huffman` C++20 compile with `x86_64-unknown-redox-gcc/g++ 13.2.0` and link statically into a Redox x86_64 binary referencing `open_chd`: 3 930 432 B (3 418 696 stripped) vs 400 536 B without CHD, 936 chd/FLAC/ZSTD/Lzma symbols, 25 s. `aarch64-unknown-redox` fails on exactly one upstream portability bug — `lzma/C/CpuArch.c` includes Linux-only `<asm/hwcap.h>` on non-Apple/non-Windows ARM (relibc has `sys/auxv.h`, no `asm/hwcap.h`); with a two-line guard (`USE_HWCAP` only under `__linux__`) it links too: 3 933 720 B, 852 symbols, 14 s. **Runtime on Redox not measured** (cross-built and inspected with `readelf`/`nm` only). Logs: `~/eos-artifacts/dowody/s15-2026-09-04/p-optical-chd-*`. Irrelevant to v1, which avoids the crate. *Was:* partly — zstd/lzma only
| 33 | **[measured 2026-09-04, evening; re-measured 2026-09-05] Six of the seven `wip/` optical recipes do not build; `libcdio` does, once `libiconv` is declared** (`CS-009`), each cooked with `make r.<recipe>` for x86_64 in the build container, 15-minute cap: `xorriso`, `libisofs`, `libburn`, `libisoburn` — `configure: error: config.sub x86_64-unknown-redox failed` (an autoconf `config.sub` that does not know the Redox triple; fails in seconds); `mkisofs-rs` — `error[E0635]: unknown feature proc_macro_span_shrink` in `proc-macro2 v1.0.46` (a 2022 lock file against the current nightly); **`cargo update -p proc-macro2` in the recipe script was measured 2026-09-05 and does not help** — a recipe script runs with the cookbook root as its working directory, so the update rewrote `/work/redox/Cargo.lock` (`proc-macro2 1.0.103 → 1.0.107`, restored afterwards) while `cookbook_cargo` still compiled `proc-macro2 v1.0.46` from the recipe's own `source/Cargo.lock`: `error[E0635]` unchanged, `cook mkisofs-rs - failed`, rc=2 (`CLAUDE.md` P-34). Next probe: update the lock the build actually reads — `cargo update --manifest-path "${COOKBOOK_SOURCE}/Cargo.toml" -p proc-macro2` — or ship a patched `Cargo.lock` as a recipe patch; `libcdio` 2.3.0 — `configure` passes but its iconv probe fails (`checking for iconv... no`; `build/config.log:2143`/`:2242` `fatal error: iconv.h: No such file or directory`, also with `-liconv`), so `config.h` has `#undef HAVE_ICONV` and the build stops at `lib/driver/utf8.c:392:3: #error "The iconv library is needed to build drivers, but it is not detected"` — a missing dependency, not a porting bug: `recipes/libs/libiconv` (1.17, `01_redox.patch`) exists in the tree and the `wip` recipe (`#TODO not compiled or tested`, `template = "configure"`) declared no `[build] dependencies`. **Measured 2026-09-05: adding `dependencies = ["libiconv"]` makes it build.** From a removed `target/`, `make r.libcdio` for x86_64 ends `cook libcdio - successful` (rc=0, 13:51:38–14:01 CEST), `build/config.h` gets `#define HAVE_ICONV 1`, and `stage/` carries six Redox ELF binaries — `cd-drive` 160 984 B, `cd-info` 174 144 B, `cd-read` 165 912 B, `iso-info` 173 272 B, `iso-read` 169 176 B, `mmc-tool` 165 848 B (`ELF 64-bit LSB executable, x86-64, dynamically linked, interpreter /lib/ld64.so.1, stripped` — the first version of this row wrote the interpreter without its `.1` and put the headers in the wrong directory; a sceptic corrected both on 2026-09-05) — plus five archives in `stage/usr/lib` (`libcdio.a` 274 684 B, `libiso9660.a`, `libudf.a`, `libcdio++.a`, `libiso9660++.a`) with `pkgconfig/`'s five `.pc` files, and the headers in `stage/usr/include/{cdio,cdio++}` (33 entries under `cdio/`); `target/` 31 MiB. The dependency now sits in the recipe. **Not** tested on hardware or in a guest, and `k3b`'s inherited failure was not re-measured. Log: `~/eos-artifacts/dowody/s15-row33-2026-09-05/libcdio.log`. Full log `~/eos-artifacts/dowody/s15-2026-09-04/libcdio-full.log` (411 lines; an incremental 4 s run on the 20:28 `build/` dir — a clean rebuild was not done, the first run's "~10 min" and this 4 s are two different runs); `k3b` — its dependency `libcdio-paranoia` stops at `configure: error: Required libcdio library not found`, i.e. it inherits the `libcdio` failure. Logs: `~/eos-artifacts/dowody/s15-2026-09-04/s15.log`, `s15b.log`. *Was:* never cooked | in the container: `for r in …; do ./target/release/cook wip/$r; done` — the honest outcome may be "does not build" |
| 34 | **[measured 2026-09-05] `launcher <plik>` **trafia** we wpis `accept=`; `cosmic-files` **nie woła launchera** — podwójne kliknięcie nie zostało wykonane** (`R-D08`, `PR-022`). Część (a), na klonie dysku zainstalowanego z obrazu gałęzi `!133`, QEMU 11.0.2, powłoka roota na serialu: przy `/usr/share/ui/apps/70_probe` = `name=probe` + `binary=/usr/bin/ion` + `accept=*.iso` i pliku `/home/user/x.iso` będącym skryptem iona, `launcher /home/user/x.iso` kończy się rc 0, a `cat /tmp/launcher-probe` zwraca `LAUNCHER-REACHED-70-PROBE` — dopasowanie wzorca i uruchomienie binarki wpisu z tą ścieżką są udowodnione końcowym markerem, nie wnioskowaniem. Kontrola negatywna: `launcher /home/user/x.txt` (żaden wpis nie pasuje) też kończy się **rc 0** i nie pisze nic poza ostrzeżeniami `cosmic_text`/`fontdb` — `error!("no application found for '{}'")` z `main.rs:983` **nie dociera na konsolę**, więc brak skojarzenia jest cichy. Dopasowanie jest prymitywne: `main.rs:907-909` przyjmuje tylko `*sufiks` i `prefiks*`, nic więcej. Część (b), na binarce z obrazu (`stage/usr/bin/cosmic-files`, 30 281 728 B, `strings`): **zero** wystąpień `usr/bin/launcher` i `xdg-open`, są za to `open-5.4.3` (z jego komunikatem `no launcher worked, at least one error`), `mime_guess-2.0.5`, `shared-mime-info` i własne akcje `OpenWith*` — czyli otwieranie pliku idzie skrzynką `open`, która na Redoksie nie ma czego wywołać, a nie orbitalowego `/usr/bin/launcher`. Kontrola metody: w binarce `launcher` `strings` znajduje `no application found for '` (1 trafienie), więc taki napis by się pokazał; **w gościu** `grep` na tej samej binarce daje 0 — narzędzie obrazu nie nadaje się do tego testu i pierwsza sonda była bezwartościowa. **Czego nie zmierzono:** samego podwójnego kliknięcia — emulowany wskaźnik jest zawodny (`CLAUDE.md` P-33: mysz PS/2 nigdy nie ruszyła kursora, `usb-tablet` 1 raz na 3), a `20_cosmic-files` deklaruje `binary=/bin/cosmic-files`. Dowody: `~/eos-artifacts/dowody/s15-row34-2026-09-05/` | w uruchomionym pulpicie: `printf 'name=probe\nbinary=/usr/bin/echo\naccept=*.iso\n' > /usr/share/ui/apps/70_probe && touch /home/user/x.iso && launcher /home/user/x.iso`, potem podwójny klik w `x.iso` w `cosmic-files` |

---

## 16. Vision and positioning

E-OS is a **Redox distribution with a real chain of trust**. That is the whole claim, and it is
deliberately narrower than the projects it gets compared to. It is a distribution of a Rust
microkernel operating system, **not a system written from scratch**, and it must never be presented
as one.

What the claim means concretely, and what the audit says about each:

- **A boot chain that refuses unsigned code** — done, with domain separation. Keep it fail-closed.
- **A package channel nobody can quietly replace** — the cryptography is done and better than most
  (hybrid post-quantum, and since `U-223` enforced on the installed bytes). What is missing is that
  it is switched on everywhere: x86_64 has no active channel at all.
- **A microkernel where a driver fault is not a kernel fault** — inherited from Redox and real:
  16 drivers run as ordinary processes. **With the honest boundary from `R-F13`:** that is isolation
  at the syscall layer, not at the bus layer, because there is no IOMMU.
- **Honest documentation** — the audit found this project's own README claiming a key did not exist
  when it did, and claiming two applications shipped when they did not. The remedy is a gate that
  checks a marker's *value*, not its presence.

**Where E-OS is genuinely ahead:** a Rust microkernel with isolated drivers, and a post-quantum
signed package index. No comparable project has either.

**Where it is behind, and should say so:** no application isolation, no atomic updates, no published
update channel on x86_64, no CI that executes, and an ecosystem of 65 packages against tens of
thousands.

**E-OS should not position itself against Tails, Qubes or GrapheneOS.** They do something else, and
comparing is unfair to the reader. The honest comparison is with upstream Redox, and there E-OS is
meaningfully ahead on trust.

### 16.1 Two critical paths

- **Foundation A — signed delivery that survives dead CI:** `R-002` (local `make release` with real
  checksums) → `R-701` (E-OS key, first non-Actions publish, wire and repoint `/etc/pkg.d`) →
  `R-702` (pin the public key, kill TOFU) → `R-703` (client-verified signed manifest). **Both** the
  update system and the driver manager pull from this backend; `R-503`'s post-quantum signatures are
  inert until `R-703` connects them at the client.
- **Foundation B — the Settings shell:** `R-D01`, a native orbital/orbclient control panel with no
  libcosmic/fontconfig/gperf dependency — so it builds on the aarch64 host and dodges both the
  host-toolchain 404 and dead CI — is the **only** place `Settings → Update` (`R-708`) and
  `Settings → Drivers` (`R-806`) can live. `cosmic-settings` is a dead end on the primary
  development architecture.

Running in parallel and independent of both: `R-601` (install harness) → `R-602` (OOBE) closed the
daily-driver install claim and retired the live default-credentials exposure; `R-801` (the `eos-devd`
read side) can start immediately on aarch64. Cheap trust-gating fixes go first regardless, because
they are outright violations sitting in the exact code the flagship subsystems reuse.

**The hard gating truth:** x86_64 parity and 100 % of real-hardware validation are blocked on
physical machines and cannot be closed from the Apple-Silicon host. The roadmap therefore has **two
physically separate critical paths, and the metal one is the longer pole.**

> **Who this is for and in what order:** [§17](#17-who-e-os-is-for-what-security-model-it-builds-and-the-order-of-work)
> (merged from `docs/archive/plan.md`, `U-142`) — the three editions (desktop / gaming / server),
> which Qubes and Tails patterns map onto the scheme model and which cannot without an IOMMU, and
> the ten-step ordering where the order *is* the security control. §1–§16 are the item list; §17 is
> the argument.

---

## 17. Who E-OS is for, what security model it builds, and the order of work

*Merged 2026-09-03 from `docs/archive/plan.md` (written 2026-08-22, `U-142`, from the audit in
`U-141`). The text is carried, not summarised, because §16 cites it as the argument behind the
item list. Where the state has moved since 2026-08-22, a dated status note points at the register
row that now holds the status; the original claim is left readable so the correction is visible.
Old citations of the form `docs/archive/plan.md §N` map to `§17.N` of this file.*

`ROADMAP.md` lists *items*. This section answers the three questions the item list cannot: **who is
E-OS for**, **what security model is actually being built**, and **in what order**, because for
several of these the order *is* the control.

### 17.1 Where the project actually stands

E-OS is a hardened Redox downstream with a **real, verified desktop on aarch64 under QEMU** — not a
prototype, and not something anyone has booted on metal. The hardening is in the code, not just the
prose: `overflow-checks` across kernel/relibc/base, mmap ASLR with guard bands, W⊕X at the syscall
boundary, AES-XTS FDE with ARMv8 crypto extensions, and scheme namespaces as a working unprivileged
confinement primitive.

Three things were missing on 2026-08-22, and they are not features:

1. **The trust chain is open at both ends.** No `keys/eos-repo-sign.pub.toml` existed, and every
   shipped image carried `/etc/pkg.d/50_redox → https://static.redox-os.org/pkg`
   (`config/base.toml:120-121`) — so `pkg install` fetched upstream binaries built without E-OS
   flags, over a TOFU-keyed channel. *Status 2026-09-03: the key exists and is pinned in the image
   (`R-702`, `U-224`); the upstream channel is gated by `ci-integrity.sh` check 9 (`R-701a`); the
   x86_64 channel is still not published (`R-701`, `S-10`, `EC-1`).*
2. **Nothing gated `main`.** `only_allow_merge_if_pipeline_succeeds = false`, **0 merge requests**
   across 10 088 commits. *Status 2026-09-03: every change since 2026-08-31 lands by merge request
   (!52–!78); the pipeline gate is on, and is lowered only for merges made after confirming every
   job failed on `ci_quota_exceeded` and none evaluated the code (§3.0). `S-1` records the branch
   protection that is still the operator's.*
3. **Zero real hardware.** Every boot claim is QEMU. *Unchanged: `R-607b`, §18.0.*

### 17.2 Three editions, one base

The same base, three package sets and three defaults. Not three forks.

#### 17.2.1 Desktop (the current product)

Closest to shipping. What an ordinary user will miss on day one, none of which had a roadmap item
on 2026-08-22: **removable-media automount** (`usbscsid` exists; nothing mounts a stick — `R-D16` since 2026-09-04),
**printing**, **accessibility and UI scaling**, **screen brightness**, **backup/restore and a
recovery path**, **a trash/undelete**, and **an i18n string catalogue** — the UI shipped hard-coded
Polish strings (`eos-control settings.rs`) while the docs are English. *Status 2026-09-03: i18n is
`R-D13`; backup is `PR-021b` (`L-4`'s register home since 2026-09-04); automount is `R-D16`; the rest still have no register row — the §3.0 list that named them as gaps was rewritten 2026-09-03, and §21 is now the only record of un-rowed proposals.*

> There is **no i18n gate in `CLAUDE.md`**. An earlier version of `docs/archive/reality-ledger.md`
> claimed there was; it was fabricated (see `U-126`). i18n is work to *schedule*, not a rule being
> violated.

#### 17.2.2 Gaming (honest position: not yet possible)

**E-OS does not run games, and the roadmap says so out loud.** The blocker is not 3D alone — it is
a chain, and every link is missing:

| Link | State |
|---|---|
| Linux ABI compatibility, or native ports | none, and no item |
| GPU acceleration (GEM/dma-fence class layer) | none — `R-930` documents the absence |
| Gamepad input | none beyond USB HID — `usbhidd` covers keyboard/mouse and the Xbox 360 vendor class (§19.1) |
| Low-latency audio | `ihdad` times out on the codec RIRB response and `audiod` exits |

Two design decisions worth taking **now**, while they are cheap: treat executable memory as a
capability (a JIT needs it; a text editor must not have it), and treat GPU passthrough as gated on
IOMMU rather than something to bolt on later. *The "gamers" server edition in the owner's cloud
request (§11.4) inherits this chain unchanged: a game *server* needs none of the four links; a game
*client* needs all of them.*

#### 17.2.3 Server (did not exist — and the placeholder is dangerous)

On 2026-08-22 there was **no server edition**: no `config/*/eos-server.toml`, no roadmap item, no
headless boot-smoke. What sits next to `eos.toml` is `config/x86_64/server-demo.toml` with
`PermitRootLogin yes`, `PasswordAuthentication yes` and `PermitEmptyPasswords yes` — one syllable
away from the real config. Worse, `config/desktop.toml:3` does `include = [..., "server.toml"]`, so
the desktop image pulls the server package set. *Status 2026-09-03: the edition is now `CS-001`,
the headless smoke `CS-010` (§11.4); the `server-demo.toml` hazard is unchanged.*

Three things a server edition needs that the desktop does not:

- **Unattended install.** `R-602`'s OOBE forces `passwd` before a shell on *every* path — correct
  for a desktop, fatal for a server that must boot without a human at the console. The rule to add:
  an account seeded with a public key and a locked password **satisfies** R-602 (`R-616b`,
  `docs/architecture/installer-profiles.md` feature `user.authorized-key`).
- **A firewall.** `R-904` is `P1` for the desktop; for a server it is `P0`.
- **Its own boot-smoke** asserting a headless console and `sshd`, not a greeter (`CS-010`).

### 17.3 Compartmentalisation: what transfers from Qubes and Tails, and what does not

The scheme model reproduces most of Qubes' **visibility** model without a hypervisor. It does
**not** reproduce its **hardware** isolation. That distinction has to be written down before anyone
puts "Qubes-like" in a README.

#### 17.3.1 The asset already in the tree

`recipes/core/contain` exists and `config/desktop-contain.toml` is a complete sandboxed session:
`contain_orblogin`, `getty --contain`, and an `/etc/contain.toml` that passes a narrow scheme set
(`rand null tcp udp thisproc pty orbital display.vesa`), **brokers** the file scheme
(`sandbox_schemes = ["file"]` — mediated, not handed over) and allowlists paths via
`files`/`rofiles`/`dirs`/`rodirs`.

It is **disabled**: `config/server.toml:14` reads `#contain = {} # needs to update dependencies`,
the recipe has no `rev`, and no `contain.pkgar` is in the built repo. This is the single largest
unused asset the audit found — a working AppVM-equivalent, switched off. *Register row: `R-1010`;
the cloud plan's Tier 2 (`CS-101`) is the same primitive, hardened and given a lifecycle.*

#### 17.3.2 The mapping

| Qubes / Tails pattern | Equivalent here | Blocker |
|---|---|---|
| **AppVM compartment** | `contain` — already built, see above | Package disabled, recipe unpinned (`R-1010`) |
| **Per-application namespace** | `Namespace::fork()` + `NsDup::IssueRegister` — kernel side complete and unprivileged | The namespace is set **once per session** in `login.rs`, so every app inherits the shell's set; a per-launch policy is `M-1` |
| **qrexec / split-GPG** | Already done twice: `eos-power`, `eos-netcfg` — a narrow named channel with policy instead of ambient authority. Generalise into an `eos-broker` convention | Clipboard and file-open brokers do not exist |
| **Network qube** | `netstack` is *already* a separate user-space process. A second instance on another interface, bound under `tcp`/`udp` in a narrower namespace, gives "this app only goes through that link" | Nothing spawns a second instance; no per-namespace binding today |
| **Driver domains** | Drivers are separate processes — but without an IOMMU this is logical isolation, not hardware isolation | `Dmar::init` is commented out; no `iommu`/`smmu` path in the kernel (`R-F13`, `CS-201`) |
| **USB qube** | **Not reachable** — it depends on handing a controller to a VM behind an IOMMU. Do **not** fake it. The achievable version gates *trust*, not isolation: `eos-devd` asks before binding a driver to a new device | `R-801`, `R-805` |
| **dom0 has no network** | Structurally satisfied — the microkernel + `initnsmgr` + bootloader contain no network code and nowhere to run a browser. Name this as a microkernel advantage rather than a Qubes feature | — |
| **Tails: amnesia** | **Already built**, as a side effect of the live image — the bootloader copies ~1.4 GB into RAM, verified on both arches (`U-133`). What is missing is making it a *product*: a menu entry and a guarantee that nothing touches the disk | `installer-profiles.md` feature `sys.amnesia`; `R-614a` |
| **Tails: MAC randomisation** | `ifaces/<if>/mac` is writable with validation, and the privileged `eos-netcfg` shim already exists and is screen-verified | Needs a `randomize-mac` subcommand and a toggle in the network pane |
| **Tails: persistent volume** | A second RedoxFS under a **separate scheme name** (`file.persist`) — in Tails persistence is bind-mounts in a global namespace; here it is a capability an app either has or lacks | Not started; depends on `R-1010` |
| **Tails: Tor by default** | — | **Do not promise this.** No tor port, no firewall, `ip` in the user namespace. Without all three it is a guarantee the system cannot keep, and the failure is silent (`installer-profiles.md` feature `net.tor`: *unrealistic today*) |

#### 17.3.3 The honest limit

Everything above is isolation **between processes of the same user**, enforced by the kernel's
scheme namespaces. It is *not* protection against a malicious driver reprogramming DMA, and it is
not a hypervisor boundary. Until there is an IOMMU, that sentence belongs in
`docs/security/threat-model.md` verbatim.

### 17.4 Order of work — and why this order

Several of these are only correct in sequence. Where that is true, the reason is stated. The
*Status* column was added on 2026-09-03 from the register; the ordering argument is unchanged.

| # | Step | Why here | Status 2026-09-03 |
|---|---|---|---|
| 1 | Turn on **"pipelines must succeed"** and move work onto merge requests | Until something blocks `main`, every gate added below is a notification after the fact. It also wakes `docs-currency`, which only runs on merge requests | done in practice (all work is MRs; gate on); branch protection `S-1` still the operator's |
| 2 | **Delete `50_redox`** from the E-OS image config (`R-701a`) | Two lines, pure subtraction, independent of the key. Removes the one channel by which a shipped image undermines its own hardening | `R-701a` — see §5.3 |
| 3 | **Keygen → sign and publish indexes (`R-008`) → pin in configs (`R-702`) → enforce (`R-703`)** | Only this order is safe. Pinning flips `pkg-lib` to fail-closed, so every already-published index must carry the new signature first | `R-008` ✅, `R-702` ✅, `R-703` — see §5.3 |
| 4 | **Pins + `blake3` for the recipes that actually ship** (`R-F11`) | Right after (3), because a signature over content fetched without an integrity check is a signature over nothing | `R-F11`, check 12 of `ci-integrity.sh` (`eos-check-tar-pins.py`) |
| 5 | **Remove `ip`/`icmp` from `user_schemes.user`** (`config/base.toml:44-48`) | One line, boot-verifiable, and it must precede `R-904`: a firewall built while raw sockets sit in the user namespace is a wall with a door in it | done (`U-144`: raw `ip:` is root-only) |
| 6 | **`R-601` — install-to-second-disk harness** | First purely functional step. The only missing proof of the "daily driver" claim, and doable entirely on the current Mac | ✅ `U-176`; x86_64 `R-601c` ✅ 2026-09-02 |
| 7 | **Fork push-mirrors** (`eos-setup-mirrors.sh --apply`, excluding `role = "pkg"`) | Now, because pin bumps start flowing and manual double-pushes silently build stale code | `M-9` (mirror-head parity) still open; `eos-mirror-drift.sh` fails closed since 2026-09-02 |
| 8 | **`shellcheck` + `cargo-deny`/`cargo test` on the root manifest** (`R-F14`, `R-F15`) | After (1) so gates actually block, and after (6) so the first shellcheck run over 44 scripts lands with a baseline | `verify.sh` stages `shell-lint`, `cargo-deny`, `test` — §11.3 |
| 9 | **Rewrite the security documents that overstate** | Here, because after eight steps most of those sentences need rewriting anyway — one pass instead of two. `U-141` already did the worst of it | `V2-MS03` ✅; #27/#28 corrections 2026-09-02 |
| 10 | **Enable `contain` and add per-application namespace policy** | The compartmentalisation work only means something once (2)–(5) closed the paths around it. Starting here would be building a wall before the doors | `R-1010`, `M-1` — open |

### 17.5 What we deliberately do not promise

Writing these down is part of the plan, because the failure mode of a security project is a promise
it cannot keep.

- **Not "Qubes-like".** No hypervisor, no IOMMU, no driver domains in the hardware sense.
- **Not "Tor by default".** See §17.3.2.
- **Not a gaming platform**, until the chain in §17.2.2 exists.
- **Not validated on hardware.** Every boot claim in this repo is QEMU until someone boots the live
  USB on the x86 rig and records what happened — including the parts that fail (§18.0).

---

## 18. The road from QEMU to a physical computer

*Merged 2026-09-03 from `docs/archive/hardware-plan.md` (Polish, `U-201`: 143 claims checked
against the tree, of which 32 from the earlier summary were false). Translated, not summarised.
Old citations `docs/archive/hardware-plan.md ETAP N` / `§0.5` map to `§18.N` / `§18.0.5`.*

One question: **what to do, in what order, so that E-OS can be installed on a physical computer and
developed further.** Every item has three parts: **what to do**, **what it gives**, and **what to
reuse instead of writing from scratch**.

### The ordering principle

> **Measure on metal first, then plan.**

Nothing in this repository has ever run on physical hardware — every verification is QEMU
(`scripts/ci-boot-smoke.sh`, `repro-intx-lines.sh`, `ci-install-smoke.sh`). **The first boot on a
real computer will give more information than a month of planning**, because it turns forecasts
into measurements. That is why stage 0 comes before everything else, although it looks modest.

### 18.0 Stage 0 — first boot on metal · one evening · **do this first** (`R-607b`)

**18.0.1 Build the x86_64 image**

```
make CI=1 ARCH=x86_64 CONFIG_NAME=eos all
```

`make CI=1 all` alone builds **aarch64** — the architecture has to be given explicitly. x86_64 is
built and passes `boot-smoke` under emulation (`U-172`, and `R-601c` since 2026-09-02), **never on
hardware**.

**18.0.2 Write it to a USB stick.** `scripts/ventoy.sh` **does not work** — it hard-codes
`CONFIGS=(demo desktop)` and does not know `eos` (`R-F28`). Until fixed: plain `dd` of
`redox-live.iso`.

**18.0.3 Secure Boot: enrol our certificate or switch it off** — choose one. The claim that nobody
signs the bootloader is stale: `recipes/core/bootloader/recipe.toml:52-65` signs **both** bootloaders
(`bootloader.efi` and `bootloader-live.efi`) at `cook` time when the operator provides a key
(`scripts/eos-sb-setup-key.sh`). Proven on both media with the operator's key (`U-210`), with a
negative control: a foreign key → `Access Denied`. Two correct paths:

- **enrol the E-OS certificate** in firmware (`db`/MOK) — install with Secure Boot on;
- **or switch Secure Boot off** — faster if only testing.

Automatic installation *without* either step would need a Microsoft-signed shim; why that is not
done today is [`ADR-0006`](docs/adr/0006-path-to-microsoft-verification.md).

**18.0.4 Choose a desktop computer, not a laptop.** This sidesteps the largest gap: **there is no
I2C driver**, so no I2C-HID, so **no modern touchpad works** (`R-916`). USB keyboard and mouse work
through `xhcid`.

**18.0.5 Record where it stopped.** This is the real product of the stage. The sequence of symptoms
says what is missing — the form `installer.md` §9.3 and §3.4 refer to:

| how far it got | conclusion |
|---|---|
| firmware does not see the medium | Secure Boot on, or a bad write of the medium |
| bootloader starts, no picture | `vesad` did not get a framebuffer from UEFI GOP |
| picture, then "no root filesystem" | no disk driver (NVMe/AHCI) for this controller |
| login prompt, no keyboard | `xhcid` did not bind the USB controller |
| desktop, no network | no driver for this NIC (only `e1000d` on x86_64 — §19.2) |

### 18.1 Stage 1 — the boot chain · large · unlocks "install without touching the BIOS"

**18.1.1 Signed bootloader (`R-F27`).** Sign `bootloader.efi` with our own key enrolled through
MOK (the user runs `mokutil`), or through a Microsoft-signed `shim` (their review process). Gives:
installation without entering the BIOS. **Without it E-OS stays a system for someone who can and
will disable Secure Boot.** Reuse: Fedora's/Debian's `shim` as the pattern; the signing key is
**none** of the existing ones — [`keys-and-tokens.md`](docs/reference/keys-and-tokens.md) §6a,
layer 5 does not exist. Register: `V2-MS10`, `V2-MS11`, `L-5`.

**18.1.2 Fix `ventoy.sh` (`R-F28`)** · small. Gives a repeatable USB medium instead of manual `dd`.

### 18.2 Stage 2 — basic hardware · nothing to render without it

**18.2.1 Disk — check, do not write.** `nvmed`, `ahcid` and `virtio-blkd` **are in the image**. But
`R-803` itself warns that some entries point at **absent binaries** — so the first task is to
*check*, not to write a new driver.

**18.2.2 Network — a real gap.** There is **only `e1000d`** wired into the x86_64 config. A typical
PC has Realtek or a newer Intel. Without network there are no packages, updates or browser. Reuse:
`R-910` names RTL8125 and Intel I225/I226 as the first targets; §19.2 lists the drivers already in
the tree (`rtl8168d`, `rtl8139d`, `ixgbed`) that are present but not all wired in.

**18.2.3 Input — works, but not on a laptop.** `xhcid` + `usbhidd` handle USB keyboard and mouse.
**I2C-HID does not exist** and this is not "untested" — the whole I2C bus is missing (`R-916`).

### 18.3 Stage 3 — installing next to an existing system

**State:** the installer **wipes the whole disk**. Installation beside Windows or Linux **does not
exist**. `scripts/dual-boot.sh` exists, but it is upstream's, needs a Linux host and **was never
tested by E-OS**. Gives: using E-OS on the only computer one has — the difference between "a
curiosity on spare hardware" and "a system one lives with". Register: `R-609`, M8 in §3.4.

### 18.4 Stage 4 — driver infrastructure (`R-801`…`R-807`)

**Why only now:** this is the foundation for *managing* drivers, not for their *existence*. On bare
metal you need disk and network first; a driver catalogue without drivers gives nothing.

| item | what to do | what it gives |
|---|---|---|
| `R-801` | `eos-devd` — device inventory (`/scheme/devices`) | knowing **what** is in the computer before guessing a driver |
| `R-802` | signed catalogue ID → package | a driver is not code from the internet |
| `R-804` | `pkgar` packages per driver | driver update without rebuilding the image |
| `R-805` | `pcid` spawn-on-demand | binding without a reboot |
| `R-807` | the "device present, no driver" list | **this** says what to write next — instead of guessing |

### 18.5 Stage 5 — graphics · the furthest, contrary to appearances

**Correcting the starting point.** A common error in summaries: "E-OS has no GPU driver at all".
**`virtio-gpud` IS in the image** — in the initfs of both architectures, with an entry in
`/lib/pcid.d/initfs.toml` (verified, `U-201`). The starting point is better than it looks.

**18.5.1 What works today.** `vesad` (firmware framebuffer) + Orbital (software compositor) +
software rendering. **Slint, Iced, egui and winit already work.** The lack of a GPU **does not
block** interface development.

**18.5.2 The order, if GPU work is taken up.**

1. **VirtIO GPU 2D** — already present; use it before writing anything new.
2. **VirtIO GPU 3D through virglrenderer** — acceleration **testable in QEMU**, without a physical GPU.
3. **Intel modesetting** — upstream Redox has started (Kaby Lake, Tiger Lake), Intel's documentation
   is public, the iGPU is the most common, and **it needs no closed firmware**.
4. **AMD through `linux-kpi`** — Red Bear OS showed `amdgpu` compiles.

**What not to start with:** NVIDIA (closed GSP firmware, Nova only a skeleton) and full 3D
acceleration at once. Register: `R-930`, `L-6`.

### 18.6 What to reuse instead of writing from scratch

| source | what is taken from it |
|---|---|
| upstream Redox | Intel modesetting, `virtio-gpud`, the base drivers |
| Red Bear OS | `linux-kpi`, `redox-drm`, `firmware-loader` — proof that `amdgpu` can be compiled |
| Mesa3D | LLVMpipe (present), Lavapipe, a backend to write |
| Linux DRM documentation | the UMD/KMD model as the architectural pattern |
| `HARDWARE.md` | **upstream data, not ours** — failure distribution: touchpad, USB, network |

### 18.7 What this stage plan deliberately does NOT promise

**Secure Boot stays a manual switch-off** until `R-F27` is done. **No measurement in this repository
comes from hardware** — everything above is a forecast based on code and on upstream data, and
stage 0 exists precisely to replace it with facts.

---

## 19. Connectivity: USB, wired LAN, Bluetooth

*Merged 2026-09-03 from `docs/archive/roadmap-connectivity.md`, grounded in the `eos-base` driver
tree (`drivers/`, `netstack/`). Carried in full; `R-920` cites the B0–B5 phasing below and
`docs/architecture/xhcid-nonblocking-transfers.md` cites §19.1. Everything marked
"QEMU-verifiable" can be developed and boot-tested in the headless harness; items marked 🔬 need
**real hardware** (QEMU emulates no Wi-Fi and effectively no Bluetooth), so they are development
plans, not things the dev loop can prove.*

### 19.1 USB

USB in E-OS is **xHCI-based** (`drivers/usb/xhcid`), so **all USB versions are covered at the
controller level** — xHCI is backward-compatible and `xhcid` handles Low/Full/High speed
(USB 1.1/2.0) and SuperSpeed / SuperSpeed+ (USB 3.0–3.2). Support is added **per device class** by
writing a class driver and registering it in `drivers/usb/xhcid/drivers.toml` (class/subclass/
protocol → driver command). `usbhubd` handles hubs, so hub topology works.

| Device class | Code | Driver | Status | Testable in QEMU |
|---|---|---|---|---|
| **HID** — keyboards, mice, gamepads | 3 | `usbhidd` | ✅ done | ✅ (`usb-kbd`, `usb-mouse`, `usb-tablet`) |
| Xbox 360 controller (vendor HID) | 0xFF/93 | `usbhidd` | ✅ done | ⚠️ (needs a passthrough pad) |
| **Hubs** — multi-device topology | 9 | `usbhubd` | ✅ done | ✅ (`usb-hub`) |
| **Mass storage** — flash drives, USB HDD | 8/6 | `usbscsid` | ✅ done — re-enabled and fixed; the "XHCI errors" were a `daemon`-crate `INIT_NOTIFY` bug, not SCSI/xHCI (`U-054`) | ✅ (`usb-storage`) |
| **Audio** — headsets, speakers, mics | 1 | *(none — `usbaudiod` to write)* | ⏳ planned | ✅ (`usb-audio`) |
| **Printer** | 7 | *(none — `usbprinterd` to write)* | ⏳ planned | 🟡 (no native model; raw test) |
| **CDC-ACM** — USB serial / modems | 2/2 | *(none — `usbserial` to write)* | ⏳ planned | ✅ (`usb-serial`) |
| **RNDIS / CDC-ECM** — USB-Ethernet | 2/2, 10 | `usbnetd` | ✅ full duplex — enumerate + handshake + MAC + `network.*` scheme, TX and RX verified (`U-056`, `U-057`) | ✅ (`usb-net`) |
| **UVC** — webcams | 14 | *(none)* | 🔬 later | 🟡 |

**USB work plan (priority order).**

1. **Re-enable mass storage (`usbscsid`).** ✅ done (`U-054`); the daemon fix also unblocks every
   future xHCI subdriver (audio/printer/CDC).
2. **`usbserial` (CDC-ACM).** The *simplest* new class driver (two bulk endpoints, a control
   interface) — a good first "new class" and immediately useful (serial consoles, Arduino, modems).
3. **`usbnetd` (CDC-ECM/RNDIS).** ✅ done (`U-056`/`U-057`).
4. **`usbaudiod` (USB Audio Class 1.0, then 2.0).** The largest — isochronous endpoints,
   format/rate negotiation, feedback endpoints — and it must plug into the audio scheme alongside
   `ac97d`/`ihdad`/`sb16d`. UAC1 output first, then input, then UAC2.
5. **`usbprinterd` (Printer class).** Bulk-out (+ optional bulk-in status). Raw printing first; a
   spooler/driver ecosystem is a separate, larger effort (§17.2.1 lists printing as a desktop gap).

**Effort:** CDC-ACM ≈ 1–2 weeks · USB audio ≈ 4–8 weeks · printer ≈ 2–3 weeks (raw). Each is an
isolated driver plus a `drivers.toml` line, so they ship incrementally.

### 19.2 Wired LAN — the strongest subsystem

`netstack` (smoltcp: IP/ICMP/TCP/UDP plus a router and `netcfg`) rides on these PCI NIC drivers,
each auto-spawned by `pcid` from its `config.toml` PCI-ID match:

| NIC driver | Covers | Status |
|---|---|---|
| `virtio-netd` | virtio-net (VMs) | ✅ boot-verified in E-OS |
| `e1000d` | Intel 8254x/PRO/1000 | ✅ present; QEMU-verified 2026-07 (`-device e1000`, `pcid` auto-spawns, login reached, 0 exceptions) |
| `rtl8168d` | Realtek RTL8168/8111 (common desktop GbE) | ✅ present in the tree; **not verified in E-OS** |
| `rtl8139d` | Realtek RTL8139 (legacy) | ✅ present; QEMU-verifiable (`-device rtl8139`) |
| `ixgbed` | Intel 82599 10GbE | ✅ present; unverified |

**LAN work plan (all QEMU-verifiable).** 1. verify the driver set beyond virtio — ✅ done for
`e1000`; 2. **IPv6** — smoltcp supports it; wire it through `netstack`'s `ip`/`tcp`/`udp` schemes
and `netcfg` (no register row yet — the §3.0 gap list was rewritten 2026-09-03; this sentence is the record); 3. more NIC coverage — RTL8125 (2.5GbE), Intel
I225/I226, Aquantia (`R-910`), DHCPv6/SLAAC; 4. throughput — checksum offload, larger rings,
zero-copy in the smoltcp glue; 5. bridging/VLAN in the `router` module for appliance use
(`CS-004` depends on this).

### 19.3 Bluetooth — 🔬 a full stack, needs real hardware

**E-OS/Redox has *no* Bluetooth today** — no HCI, no L2CAP, no profiles. This is a ground-up
subsystem. USB BT dongles expose a standard **HCI-over-USB** interface (class 0xE0), the natural
entry point, reusing `xhcid`.

**Layered architecture (bottom-up).**

1. **HCI transport (`bthci`)** — USB (class 0xE0: commands/events/ACL endpoints) first; UART-HCI
   later. *Milestone: reset the adapter, read its BD_ADDR, start/stop inquiry.*
2. **HCI host + L2CAP (`btd`)** — connection management plus the multiplexing layer every profile
   rides on. *Milestone: an ACL link and an L2CAP channel to a peer.*
3. **SDP** — service discovery.
4. **Pairing / security** — SSP, link keys, encryption; a key store reusing E-OS's argon2/crypto.
5. **Profiles**, each a daemon over L2CAP/RFCOMM: RFCOMM+SPP (simplest); HID (HOGP) → the existing
   `inputd`; A2DP (SBC, then AAC/aptX) → the audio scheme; HFP.
6. **BLE** — LE link layer + ATT/GATT + GAP. Large; can follow classic. `R-920` chooses the
   Rust-native `trouble` + `bt-hci` crates for this layer.

| Phase | Deliverable | Rough effort | Hardware |
|---|---|---|---|
| B0 | `bthci` USB transport: reset + BD_ADDR + inquiry | 2–4 weeks | USB BT dongle |
| B1 | `btd`: ACL + L2CAP + SDP | 1–2 months | dongle + a peer |
| B2 | Pairing/SSP + link-key store | 3–4 weeks | dongle + peer |
| B3 | RFCOMM/SPP + HID (HOGP) → `inputd` | 1–2 months | BT keyboard/mouse |
| B4 | A2DP (SBC) → audio scheme | 2–3 months | BT headphones |
| B5 | BLE: LL + ATT/GATT + GAP | 2–4 months | LE peripheral |

**Total to "BT headphones and a BT keyboard work":** roughly **6–12 months** of focused work, all
needing hardware. A genuine subsystem, not a driver — best pursued upstream in Redox too.

> **Ordering note (2026-09-03).** The register row `R-920` chose **BLE first** (the Rust-native
> `trouble` + `bt-hci` crates over a USB-HCI shim) — the reverse of the classic-first B0–B5 above.
> Both orderings are kept on purpose: B0–B5 is the path to headphones and keyboards, `R-920` is the
> path to modern peripherals with the least new code. Annex C.2 used to say `R-920` "cites B0–B5";
> it does not, and that sentence was corrected when this section was merged.

**Items in this section that still have no register row** (kept visible here rather than minted
blind — §0.3 namespaces are the owner's): `usbserial`/CDC-ACM as a deliverable (named only as an
absence in `R-934`), `usbprinterd`, UVC webcams, NIC throughput (checksum offload, larger rings,
zero-copy), bridging/VLAN in `router`. The rows that exist: `usbaudiod` → `R-911`, IPv6 → `R-903`,
multi-gig NICs → `R-910`, Bluetooth → `R-920`, Wi-Fi → `R-921`.

### 19.4 Summary — now versus later

- **Now, QEMU-verifiable:** wired LAN across several NIC families, USB HID, USB hubs, all USB
  speeds, USB mass storage, USB-Ethernet; writing CDC-ACM / USB-audio / printer class drivers
  incrementally; IPv6.
- **Later, needs real hardware:** **Wi-Fi** (`R-921`, `L-2` — 802.11 MAC + supplicant + per-chip
  firmware) and the full **Bluetooth** stack above (`R-920`, `L-6`). Both are gated on hardware, not
  on E-OS design.

---

## 20. Delivered capability plans, kept for their scope — `R-50x` and the ACPI-off removal

*Merged 2026-09-03 from `docs/archive/hardware-capabilities-roadmap.md` (recreated 2026-07-12 after
the original notes were lost) and `docs/archive/acpi-off-removal-plan.md`. All four items are
**delivered**; what is carried is the scope and the non-goals, because the non-goals are where the
open work hides. `HARDWARE.md` pointed at the first file; it now points here.*

### 20.1 `R-501` — RAID-1 mirror daemon (`raid1d`) — ✅ delivered (`U-042`)

**Why first:** pure userspace, exercises the scheme/daemon machinery, immediately useful (mirrored
root/data on two disks), and it unlocks degraded-boot stories that fit the resilience branding.

**Scope delivered:** a userspace block-scheme daemon over two disk schemes exposing one mirrored
logical device; a per-member superblock (last 4 KiB: magic, array UUID, member index, generation
counter) so members are identified positively; writes to both members (fail only if **both** fail),
reads from the primary with fallback; **degraded mode** served and loudly logged; a `create`/`status`
helper; QEMU proof: two NVMe disks → `create` → RedoxFS on the mirror → write → boot with **one**
disk → data readable, degraded warning in the log. Hardening followed in `R-F04` (`U-068`).

**Non-goals then, open scope now:** resync/rebuild after re-adding a member, RAID-0/5/6, hotplug,
write-intent bitmaps, more than two members, root-on-RAID (needs the installer) — all folded into
`R-912` (§8.4) as named sub-scopes; not re-minted as `R-501b`/`R-501c` (Annex C.1).

### 20.2 `R-502` — aarch64 crypto-extension acceleration for FDE — ✅ delivered (`U-043`/`U-044`)

The FDE path (`R-305`, RedoxFS AES-XTS) was pure software; ARMv8 Crypto Extensions are present on
QEMU's `cortex-a72`/`a53`/`max` (confirmed once the kernel ISAR decode bug `U-043` was fixed) and on
every realistic target, and the change lives in the userspace `redoxfs` daemon. Delivered: the `aes`
crate's ARMv8 backend, runtime-detected with software fallback, wired into the FDE path; before/after
numbers in `docs/guides/encryption.md`; FDE boot re-verified. **Non-goals:** kernel-side crypto, SHA
acceleration for pkgar (`R-502b`, kept as a cross-reference), x86 AES-NI (handled by the crates).

### 20.3 `R-503` — post-quantum hybrid package signing — ✅ delivered (`U-045`)

Repo signing is ed25519 **and** ML-DSA-65; verification checks both on install; classical-only
verifiers keep working. The migration plan (key custody, rollout stages, fallback) is in
`docs/security/index.md`; the design is `ADR-0004`. **Non-goals:** PQ TLS/ssh (upstream-dependent),
a PQ FDE-KDF (the KDF is not the quantum-exposed part), replacing ed25519 outright. *The signatures
are inert at the client until `R-703` connects them (§16.1).*

### 20.4 Horizon items from that plan, and where they went

| item | register home now |
|---|---|
| NVMe SMART/health surfacing (`eos doctor` integration) | `V2-D02`; the "doctor" itself is §21 proposal 9 — no row yet |
| TRIM/discard pass-through end to end (`nvmed` → RedoxFS) | `V2-D02` |
| virtio-gpu path for QEMU (replaces ramfb; resolution switching, speed) | `virtio-gpud` is in the initfs (§18.5); the *desktop* on it is open under `R-930` |
| Multi-queue NVMe / I/O parallelism in the storage daemons | `V2-D02` |

### 20.5 The aarch64 `-machine virt,acpi=off` requirement — ✅ removed (`R-401f`, `U-019`)

**Was:** aarch64 booted only with `-machine virt,acpi=off`, forcing a device-tree boot, the only
path on which `pcid` got the PCIe `interrupt-map` it needs to route legacy INTx; under ACPI
`pcie.interrupt_map` was empty, `nvmed` never received its IRQ and the boot hung. Root cause in
`drivers/pcid/src/main.rs` `enable_function()` and `cfg_access/mod.rs` `Mcfg::with`.

**Shipped approach (simpler than planned):** no kernel or `acpid` change was needed. The kernel
already brought up the GIC from the ACPI MADT and exposes `irq:phandle-0`; `acpid` already serves the
AML namespace; `pcid` reads the static `\_SB.PCIx._PRT` plus each link device's `_CRS` from
`acpi:/symbols` and routes INTx to the matching GIC SPI (upstream patches
`upstream/base/0002…0003`).

**Deliberately not done — the general case.** Real firmware may express `_PRT` through link
devices (`\_SB.LNKx`, `_CRS`/`_SRS`) rather than static GSIs; resolving those is a deep AML
subsystem touching kernel + `acpid` + `pcid`, with real regression risk to the working boot, and it
is verifiable only through slow no-ACPI TCG boots. Real aarch64 hardware boots from device-tree, so
the value is low. **Recommendation kept:** take it up as its own focused effort only if ACPI-boot
support becomes a requirement, and upstream the `_PRT` work into `redox-os/acpid` and
`redox-os/drivers` rather than carrying it downstream.

---

## 21. The fourteen feature proposals of 2026-07-13, and what became of each

*Merged 2026-09-03 from `docs/archive/feature-proposals.md` (Polish, roadmap audit of 2026-07-13:
fourteen features chosen for a secure, telemetry-free Crimson desktop, each built on something
already in the tree — `raid1d`, RedoxFS AES-XTS, hybrid signatures, scheme namespaces). The
proposals are carried as a table so that the ones that never got a register row stop being
invisible. Old citations `feature-proposals.md #N` map to row N below. `docs/architecture/system-updates.md`
§4 and `docs/archive/reality-ledger.md` cite this list.*

| # | proposal (what it does) | why it fits E-OS | effort then | fate on 2026-09-03 |
|---|---|---|---|---|
| 1 | **`eos-devd`** — one device inventory (`/scheme/devices`) unifying `pcid` (`/scheme/pci`), USB ports from `xhcid` and platform/ACPI/DT enumeration from `hwd` | the read side of the Driver Manager and of the Security dashboard at once; `hwd` already recognises `PNP0C0A` (battery) and `PNP0C50` (I2C-HID) by name | M | **`R-801`** — open; §18.4 puts it after disk and network on metal |
| 2 | **Native `E-OS Settings`** (orbital/orbclient, no libcosmic) — panel host for Update, Drivers, Display, Network, Audio, Users, Date & Time, Security | the flagship Update and Driver panes had nowhere to live; libcosmic's fontconfig→host-toolchain chain did not build on aarch64 | L | **✅ `R-D01`** (`U-071`) — **which binary is open under decision #19**: `eos-settings` (orbutils, the 9-panel orbclient shell with a placeholder "Aktualizacje" panel) or `eos-control` (Slint on Orbital via `eos-ui`, Network pane `R-902` ✅, owns the `R-D11` shims); Update pane `R-708` and Drivers pane `R-806` open |
| 3 | **Security dashboard** (Settings → Security): FDE active, W⊕X/ASLR/overflow-checks (`R-306`), RAID-1 state, signed-repo status | a verified security foundation the user never sees; the dashboard turns an audit into a screen | M | **partly ✅** — `eos-control`'s Security tab carries `eos-guard`'s blake3 baseline and permission audit (§7.5); the FDE / RAID-1 / signed-repo lines are shown since 2026-09-05 in **`eos-guard`'s window** (`eos-guard!7`, **`PR-004`** below), not in the Security tab — which binary is "Settings" is decision #19; `R-306` has no runtime source (compile-time kernel constants, no `sys:` entry) and is not shown |
| 4 | **Signed-driver trust verifier** — every driver shows source = signed E-OS repo only, blake3+ed25519 (+ML-DSA advisory) verification, update state; plus hardening of the catalogue parser, whose `i64::from_str_radix(...).unwrap()` in `match_function` **panicked `pcid-spawner`** on a hostile entry | erases the Windows-era "hunt for a driver / fake installer" attack class | M | parser hardening **✅ `R-803`** (`U-137`, `eos-base` `66e3070b`); the UI half is **`R-806`**, open |
| 5 | **Application capability/permission manager** — list which schemes (`/scheme/*` = capabilities) an app may open, revoke them | schemes-as-capabilities is the microkernel's native advantage; a telemetry-free desktop should show it | L | **`R-1010` / `M-1`** — open; the kernel side (`Namespace::fork()`) exists, the per-launch policy does not (§17.3.2) |
| 6 | **Enforce credentials in the wizard** — OOBE forces the password change, retires default `root/password`, generates `machine-id` and SSH host keys | every built image booted as `user` (no password) + `root/password` | S–M | **✅ `R-602`** (`U-076`–`U-079`) for the password on every login path; `machine-id` and host keys are **`R-606`**, open; the *quality* of the password is the new `R-602a`…`g` (§6.6) |
| 7 | **Snapshot + rollback** before every `pkg update`/apply; `eos-update rollback` | `transaction.commit()` mutates the live FS by a rename loop **without a durable journal** — a power loss leaves a half-applied state | L → XL (A/B slots) | **`R-706`**, `L-1`, `EC-4`, M6 in §3.4 — open |
| 8 | **Recovery / rescue mode** — a second bootloader entry with `pkg`, an FDE verifier, `raid1d` assemble/rebuild and apply-on-reboot for a failed update | kernel/base/relibc updates replace the live system in place; a bad kernel can brick a real installation | L | **`R-614`/`R-614a`** (the *medium* as the rescue system; a separate rescue medium was refused) and **`R-707`** (kernel fallback) — open |
| 9 | **`eos health` / "doctor"** — one command and a Settings tile: FDE sanity, `raid1d` consistency (**per-block scrub** — `raid1d` has no per-block checksums), stale `pcid.d` entries (`ac97d.toml`/`vboxd.toml` pointing at absent binaries) | local diagnostics without telemetry | M | **no register row** — the §3.0 list that named it as a gap was rewritten 2026-09-03 and this table is now its only record; the stale-entry half is `R-803`'s remaining "validate binary presence", the scrub half is inside `R-912`. On E-OS "fix no network" reduces to *is a driver bound to this PCI function* (`ENOLCK` on `/scheme/pci`) plus `R-807`'s ledger — meaningful only after `R-801` |
| 10 | **Offline driver bundle on the install medium** — a signed `pkgar` catalogue plus drivers generated from `/usr/lib/pcid.d/*.toml` and `xhcid/drivers.toml` | the installer already pins the key (`installer_key`, `pubkey: Some`), so the bundle verifies natively; bypasses dead CI | M | **`R-804`** (split drivers out of `base.pkgar`) is the precondition, open; the bundle is **`R-817`** (minted 2026-09-04 — `pkg-lib` `add_local` already consumes a `/pkg` directory, only the payload is missing) |
| 11 | **Signed hardware→driver catalogue** — a versioned `device-ID → package+version+arch` map as its own `pkgar`, signed with the `R-503` hybrid key, fetched/verified/cached | the missing source of truth for the Driver Manager; must reconcile **three** catalogues (`initfs.toml`, `usr/lib/pcid.d/*`, `xhcid/drivers.toml`) | M (+L for `drv-*` split) | **`R-802`** + **`R-804`** — open |
| 12 | **Reproducible-build verifier for the user** — recompute the image's sums locally and compare with the signed manifest, without trusting the server | `release/SHA256SUMS` pointed at a non-existent `eos-0.1.0-<arch>.img` | S | **✅ `R-002`** (`U-069`, real checksums from a local `make release`); byte reproducibility itself is **`R-303`/`V2-MS07`**, unproven |
| 13 | **Local crash reporter** — catches panics/data aborts (e.g. the `netsurf` ET_EXEC abort, ESR `0x92000047`), stores them locally with context, shows them in Settings | a telemetry-free desktop cannot "phone home" but still needs diagnostics | M | **no register row** — the §3.0 list that named it as a gap was rewritten 2026-09-03 and this table is now its only record; needs a panic hook in relibc/kernel |
| 14 | **Functional system tray + host-firewall UI** — turn three **decorative** PNGs (net/vol/settings, no handlers) into live controls; and put a UI on a firewall, since the netstack exposed a raw `raw` scheme with no filtering | icons that look clickable and do nothing break the daily-driver impression | M (tray) + L (firewall) | tray **✅ `R-D02`** (`U-101`); volume **`R-D07`**; firewall **`R-904`**, `M-3` — open; raw `ip:` became root-only (`U-144`) |

**Implementation order proposed then (hard dependencies), kept because it still holds:**

1. **#1 `eos-devd`** and **#2 the Settings shell** — the foundation; without them Driver/Update/
   Security/Permissions have nowhere to live. *#2 is done; #1 is not.*
2. **#6 credentials** and **#4 parser hardening** — live critical holes, cheap, in parallel. *Both done.*
3. **#11 catalogue + `drv-*` split → #10 offline bundle → #4 trust UI** (Driver Manager complete).
4. **#7 snapshot/rollback + #8 recovery** — harden the update system for real disks.
5. **#3 dashboard, #9 doctor, #13 crash reporter, #14 tray/firewall** — the layer that makes the
   whole thing visible, auditable Crimson value.

**QEMU realism then:** 12 of 14 fully doable on aarch64/TCG; revoking capabilities (#5) and the real
driver bind (#4) need kernel work or hardware respectively. Unchanged.

---

## Annex A — full identifier index

**This index carries no status.** Status lives in the register (§5–§12) and nowhere else; that is
the rule that prevents the class of contradiction this merge had to resolve. The index exists for
one purpose: to **prove that no identifier was lost**, and to be regenerable mechanically from the
register at the next review rather than maintained by hand.

**Census.** 175 `R-*` register rows · 3 `R-*` identifiers retired by renumbering (Annex C) ·
48 `V2-*` rows · 62 scheduling rows (`S-*`, `M-*`, `L-*`, `M1`–`M8`, `EA-*`, `EB-*`, `EC-*`) ·
5 non-item tokens recorded in Annex B.

### A.1 `R-*` — register

| family | identifiers | section |
|---|---|---|
| `R-0xx` CI and release-integrity recovery | `R-001` `R-002` `R-003` `R-004` `R-005` `R-006` `R-007` `R-008` `R-009` | §11.1 |
| `R-2xx` / `R-4xx` milestones | `R-201` `R-207` `R-402` `R-403` | §11.2 |
| `R-3xx` release pipeline | `R-301` (§5.4) · `R-303` (§11.2) | §5.4, §11.2 |
| `R-4xx` kernel/ACPI cross-references | `R-401d` `R-401f` | §8.5 |
| `R-5xx` crypto and storage scopes | `R-501b` `R-501c` (§8.5) · `R-502` `R-502b` `R-503` (§5.4) | §5.4, §8.5 |
| `R-6xx` installer, wizard, medium | `R-601` `R-601a` `R-601b` `R-601c` `R-601d` `R-601e` `R-602` `R-603` `R-603a` `R-603b` `R-603c` `R-603d` `R-603e` `R-604` `R-604a` `R-604b` `R-604c` `R-604d` `R-605` `R-606` `R-607` `R-607a` `R-607b` `R-608` `R-608a` `R-609` `R-609d` `R-610` `R-611` `R-611a` `R-611b` `R-611c` `R-611d` `R-611e` `R-612` `R-612a` `R-612b` `R-612c` `R-612d` `R-613` `R-614` `R-614a` `R-614b` `R-614c` `R-615` `R-616` `R-616a` `R-616b` `R-616c` `R-602a` `R-602b` `R-602c` `R-602d` `R-602e` `R-602f` `R-602g` | §6.2 |
| `R-7xx` update system | `R-701` `R-701a` `R-702` `R-703` `R-704` `R-705` `R-706` `R-707` `R-708` `R-709` `R-710` `R-710a` `R-710b` `R-711` `R-712` | §5.3 |
| `R-8xx` driver manager and services | `R-801` `R-802` `R-803` `R-804` `R-805` `R-806` `R-807` `R-808` `R-809` `R-810` `R-811` `R-815` `R-816` `R-817` `R-818` `R-819` `R-820` · non-items `R-800` `R-812` `R-813` `R-814` | §8.2, §8.5 |
| `R-9xx` connectivity and hardware tiers | `R-901` `R-902` `R-903` `R-904` `R-904a` `R-905` `R-906` `R-907` `R-910` `R-911` `R-912` `R-913` `R-914` `R-916` `R-917` `R-918` `R-920` `R-921` `R-922` `R-923` `R-924` `R-930` `R-931` `R-932` `R-933` `R-934` `R-935` `R-936` | §8.4 |
| `R-10xx` platform and product | `R-1002` `R-1003` `R-1010` · retired `R-1004` | §11.2, Annex C |
| `R-Fxx` correctness and regression | `R-F01` … `R-F62` (all 62, none omitted; `R-F30`–`R-F62` minted 2026-09-03/07) | §10 |
| `R-Dxx` desktop shell | `R-D01` `R-D02` `R-D03` `R-D04` `R-D05` `R-D06` `R-D07` `R-D08` `R-D09` `R-D10` `R-D11` `R-D12` `R-D13` `R-D15` `R-D16` `R-D17` (`R-D14` was never minted) | §7.2 |
| **retired by renumbering** | `R-609a` → `R-616a` · `R-609b` → `R-616b` · `R-609c` → `R-616c` | Annex C |

### A.2 `V2-*`

| family | identifiers | section |
|---|---|---|
| Secure Boot / shim-review track | `V2-MS01` `V2-MS02` `V2-MS03` `V2-MS04` `V2-MS05` `V2-MS06` `V2-MS07` `V2-MS08` `V2-MS09` `V2-MS10` `V2-MS11` `V2-MS12a` `V2-MS12b` `V2-MS13` `V2-MS14` `V2-MS15` | §5.2 |
| Storage drivers | `V2-D01` `V2-D02` `V2-D03` `V2-D04` `V2-D05` `V2-D06` | §8.3 |
| Blocking buses | `V2-N01` `V2-N02` `V2-N03` | §8.3 |
| `eos-guard` → security suite | `V2-S01` `V2-S02` `V2-S03` `V2-S04` `V2-S05` | §7.3 |
| `eos-notes` → encrypted notebook | `V2-NT01` … `V2-NT10` (all ten, each now carrying a status) | §7.4 |
| Standards | `V2-STD01` `V2-STD02` `V2-STD03` `V2-STD04` `V2-STD05` `V2-STD06` `V2-STD07` `V2-STD08` | §12 |
| **retired by splitting** | `V2-MS12` → `V2-MS12a` (guard) + `V2-MS12b` (custody) | Annex C |

### A.3 Scheduling identifiers

| series | identifiers | section |
|---|---|---|
| Short term | `S-1` … `S-20` | §3.1 |
| Mid term | `M-1` … `M-9` | §3.2 |
| Long term | `L-1` … `L-7` | §3.3 |
| Installer programme milestones | `M1` … `M8` — **note the hyphen distinguishes these from `M-1`…`M-9`** | §3.4 |
| Epic backlog | `EA-1` … `EA-6` · `EB-1` … `EB-5` · `EC-1` … `EC-7` | §3.5 |
| **retired by renaming** | `A-1`…`A-6` → `EA-*` · `B-1`…`B-5` → `EB-*` · `C-1`…`C-7` → `EC-*` | Annex C |

### A.4 Identifiers owned by other documents

| token | owner | note |
|---|---|---|
| `C-1` … `C-21`, `G-1` … `G-19`, `A §…` | [`docs/audit/`](docs/audit/) | audit findings; referenced throughout §3 and §9 |
| `U-NNN` | [`CHANGELOG.md`](CHANGELOG.md) | the evidence keys this document cites |
| `ADR-0001` … `ADR-0011` | [`docs/adr/`](docs/adr/) | architecture decisions |
| `R-800` … `R-814` | [`docs/architecture/driver-manager.md:16`](docs/architecture/driver-manager.md) | a reserved range with **different** meanings — Annex B |
| `R-701` … `R-708` | [`docs/architecture/update-system.md`](docs/architecture/update-system.md) §7 | the same numbers with **different** meanings — Annex B |
| `R-0xx`, `R-10x`, `R-70x`, `R-80x`, `R-9xx`, `R-Dxx`, `R-Fxx`, `R-NNN` | — | family placeholders in headings, **not identifiers** |

---

### A.5 Registers added 2026-09-02 and 2026-09-03

| family | identifiers | section |
|---|---|---|
| `CS-*` everything on E-OS: server edition and cloud | `CS-001` … `CS-010` (tier 1) · `CS-101` `CS-102` `CS-103` (tier 2) · `CS-201` … `CS-205` (tier 3) | §11.4 |
| `WS-*` project website | `WS-001` … `WS-012` | §11.5 |
| `API-*` documented system API | `API-001` … `API-006` | §11.6 |
| `PR-*` products: in the image, on Windows/Linux, the new ones | `PR-001` … `PR-022` (incl. `PR-004b`, `PR-021b`; `PR-015` … `PR-020` added 2026-09-03/04, `PR-021`/`PR-021b`/`PR-022` on 2026-09-04) | §7.5 |
| `TQ-*` test and security-coverage automation | `TQ-001` … `TQ-010`; proxies `SC-0` … `SC-5` are measures, not items | §11.3 |
| `RH-*` repository hygiene | `RH-001` … `RH-009` | §11.7 |

## Annex B — identifier collisions and decisions D1–D7

### B.1 `R-70x` — the register versus `docs/architecture/update-system.md`

Measured this session at `docs/architecture/update-system.md:172-179` against §5.3 of this file:

| id | `update-system.md` §7 | this register (§5.3) |
|---|---|---|
| `R-701` | wire `eos-repo-sign` into `publish-repo-pages.sh` | run an E-OS-owned update source |
| `R-702` | `verify_manifest()` in `pkg-lib`, end TOFU | **pin the repo key**, end TOFU |
| `R-703` | `eos-updated` service + `/scheme/eos-update`, journalled staging | **client-side signed-manifest verification** |
| `R-704` | **rollback** by generation (snapshot of replaced files) | **anti-rollback** / freshness + hash pinning |
| `R-705` | Settings → Update pane | `eos-update` daemon + CLI |
| `R-706` | scheduling, auto-apply policies, channel selection | **transactional staging + one-step rollback** |
| `R-708` | **A/B slots + deltas** | Settings → Update pane |

The only number that means the same thing in both documents is `R-707` (base/kernel applied on
reboot with a fallback). The other six do not. **`R-704` means "rollback" in one and "protection
against rollback" in the other — near-opposite meanings, so every sentence in the project containing
`R-704` is currently ambiguous.**

### B.2 `R-80x` — the register versus `docs/architecture/driver-manager.md`

`docs/architecture/driver-manager.md:16` states verbatim: *"**Scope codes:** R-800 … R-814 (this
document defines the range)"* — **fifteen numbers reserved** which the register uses for other work:

| id | `driver-manager.md` | this register (§8.2) |
|---|---|---|
| `R-801` | signed driver catalogue | `eos-devd` inventory daemon |
| `R-802` | hardening the matcher | signed driver catalogue |
| `R-803` | `pcid` binding on demand | hardening the matcher + dead `pcid.d` entries |
| `R-806` | packaging a driver as pkgar | Driver Manager GUI |
| `R-809` | Settings + Drivers pane | multi-segment PCI enumeration (ECAM) |

**The drift is not a uniform shift, which is worse than if it were, because no single operation
fixes it:** `R-801`→`R-802` and `R-802`→`R-803` are off by one, but `R-803`→**`R-805`**,
`R-806`→**`R-804`**, `R-809`→**`R-806`**. `R-811`…`R-814` are reserved collectively there for
real-hardware verification, while this register uses only `R-811`, for something else entirely.

### B.3 `A-*`/`B-*`/`C-*` versus the audit's `C-*`

Named for the first time in this merge. In the predecessor epic tables `C-1` meant *"publish the
x86_64 repository"*; in `docs/audit/03-security-audit-2026-08-30.md` `C-1` means *"pin the upstream
package key"*, and both documents are live and cross-referenced. **Resolved by renaming** the epic
namespace to `EA-*`/`EB-*`/`EC-*` (§3.5); the audit keeps `C-*`, because it is the older and more
widely cited namespace and its identifiers appear in `S-*`, `M-*` and `L-*` traces throughout §3.

### B.4 Decisions

**D1 — the numbering in this register wins.** Not arbitrary: this is the project register that
`CLAUDE.md` §2 points at, and the only place where an item's state is maintained. The two design
documents are descriptions of subsystems, not a register.

**D2 — the older documents are NOT renumbered.** Rewriting identifiers in
`docs/architecture/update-system.md` and `docs/architecture/driver-manager.md` would break
cross-references from `CHANGELOG.md` and other documents, and `CLAUDE.md` §2 rule 4 requires a
correction to be **visible**, not silent. Instead both gain a header block:

```
> **ARCHIVAL NUMBERING — does not apply.** The `R-*` identifiers in this file mean something
> different from `ROADMAP.md`, which is the project register (Annex B). Correspondence table below.
> The current design of this layer: docs/architecture/system-updates.md
```

plus the correspondence tables from B.1/B.2. Cost: two headers. Gain: no sentence in the project is
unreadable. **Status: adopted but NOT implemented.** Verified this session — `grep -rl "ARCHIVAL
NUMBERING\|NUMERACJA ARCHIWALNA" --include='*.md' .` finds the phrase only in this file and in
`docs/adr/0009-system-update-mechanism.md` — both of which *describe* the banner rather than carry
it. **The banner was never added.** (Re-measured 2026-08-31, after `ROADMAP-v2.md` was reduced to a
redirect stub; the earlier reading named `ROADMAP-v2.md` in place of this file, for the same reason.) Tracked as open scope
under `R-F05`.

**D3 — free ranges after this decision.** The freedom of each newly minted number was verified with
`grep -rl` before minting. That measurement is no longer literally repeatable, because those numbers
now live in this file, in four specifications and in `ADR-0007`–`ADR-0011`. The repeatable form,
which is the one that applies at approval:

```
grep -rl '<ID>' --include='*.md' .
```

must return **only** `ROADMAP.md`, `docs/architecture/*.md` and `docs/adr/00{07..11}-*.md`. A hit in
`docs/architecture/update-system.md` or `docs/architecture/driver-manager.md` means the number was
occupied after all.

| family | occupied in the register | occupied elsewhere | first safe free number |
|---|---|---|---|
| `R-0xx` | `R-001`…`R-008` | — | **`R-009`** — minted here for CI capacity |
| `R-6xx` | `R-601`…`R-616c` | — | `R-617` |
| `R-7xx` | `R-701`…`R-712` + `R-701a` | `update-system.md` §7 uses `R-701`…`R-708` for other work | **none minted** — see D4 |
| `R-8xx` | `R-801`…`R-811`, `R-815`…`R-820` | `driver-manager.md:16` reserves `R-800`…`R-814` range-wide | **`R-821`** — `R-817` (offline driver bundle), `R-818` (image-backed block scheme), `R-819` (ISO 9660/UDF schemes) and `R-820` (`eos-timesyncd`) minted 2026-09-04; `R-818` was deliberately **not** used for hot-plug detection, which is a consumer of `V2-S05`, not a subsystem |
| `R-Dxx` | `R-D01`…`R-D13`, `R-D15`…`R-D17` | — | `R-D18` (`R-D14` skipped on 2026-09-04: three rows were minted the same day and the brief that named the free number was already stale) |
| `R-Fxx` | `R-F01`…`R-F62` | — | `R-F63` |

**D4 — not one new number is created in the `R-7xx` family.** All the work in `system-updates.md`
attaches to the existing `R-704`…`R-712`, and the only "new" identifiers are the **split of `R-710`
into `R-710a`/`R-710b`**, which `system-updates.md` §1.5 proposes and which adds no third meaning:
`R-710` already means *"A/B root slots + differential updates"*, and the split only separates the two
halves, because they have **different dependencies** — deltas do not need `R-707`, slots do. Adopted
as binding.

**D5 — the gate that must be able to fail.** `scripts/ci-integrity.sh` gains a check requiring every
file under `docs/` that uses `R-[0-9]{3}` identifiers **in a sense other than the register's** to
carry the D2 header. Mechanisable minimum: `grep -q 'ARCHIVAL NUMBERING'` in
`docs/architecture/update-system.md` **and** `docs/architecture/driver-manager.md`, otherwise the
check fails naming the file. **How that check fails:** remove the header from one file → red with
its name; remove `grep` from `PATH` → `FAIL (instrument):`, never "broken invariant" (`CLAUDE.md`
§13, the `U-177` pattern). **Corrected again 2026-08-31: it is check 14, not 13** — check 13 was taken by the empty-array gate. An earlier
version asserted `ci-integrity.sh` holds checks 0…11 and that this becomes check 12. **Check 12
already exists** — the tarball-blake3 gate at `ci-integrity.sh:339` calling
`scripts/eos-check-tar-pins.py`. Renumber before anyone implements D5.

**D6 — ADRs behind these decisions.** `ADR-0007`…`ADR-0011` **exist** (verified `ls docs/adr/`) and
are **not** what an earlier version of this table assigned to them:

| number | file and actual decision |
|---|---|
| `ADR-0007` | `0007-bootloader-and-install-medium.md` — bootloader of the installation medium and of the installed system |
| `ADR-0008` | `0008-filesystem-and-partition-layout.md` — root filesystem and **partition layout** (ESP, root, `/home`, swap, A/B reserve) |
| `ADR-0009` | `0009-system-update-mechanism.md` — journalled transaction now, A/B slots later |
| `ADR-0010` | `0010-encryption-stack.md` — **disk encryption stack** (AES-XTS-128, Argon2id, 64 key slots) |
| `ADR-0011` | `0011-installer-wizard-architecture.md` — one engine, one core, two front-ends |

**Two decisions the milestones rest on have NO ADR** — a gap, not a recording oversight:

| decision with no ADR | where it currently lives | which milestone rests on it |
|---|---|---|
| Installation transaction ordering: **root and verification before the ESP** | `installer.md` §6.2 (five phases) | **M2**, and partly `R-612a` already in M1 |
| Profiles and features as an **extension** of the existing TOML, not a second system | `installer-profiles.md` §1.1 + §1.3 ("Rejected alternatives") | **M4** |

Until they exist, the milestone dependency is **on the specification section**, not on an ADR
number. If they are given ADRs at approval (`ADR-0012`, `ADR-0013` are the first free), **correct
this table, not the milestones**: the dependency is on the decision, not on the number.

**D7 — `R-609a`/`R-609b`/`R-609c` are renumbered to `R-616a`/`R-616b`/`R-616c`. Decided here, not
deferred.** v2 left this open while writing *"do not leave this undecided"*. The problem: `R-609`
means *"manual partitioning / install alongside"* in the register, but a profile validator, an
answer file and Gamer/Business/Ghost profiles **are not partitioning** — hanging them off `R-609`
gives that number a third meaning, which is the exact defect B.1 and B.2 exist to fix. `R-616` was
verified free and becomes the parent, *"profile model and unattended installation"*. **Only
`R-609d`** (S4 partitioning modes) genuinely belongs to `R-609`, and it stays.
**Open follow-up, owned and not silently dropped:** `docs/architecture/installer-profiles.md` §9 and
`docs/architecture/installer-wizard.md` §15 already cite the old numbers and must be corrected in the
same movement — tracked under `R-F05`.

**`R-1010` — minted as a register row, not left as a dangling citation.** v2 §12.7 recorded that the
register did not contain this item while `EP-2` and `M4` depended on it, and `CLAUDE.md:593`,
`docs/adr/0011-installer-wizard-architecture.md` and `docs/architecture/installer-profiles.md` all
cite it. Shipping a milestone that depends on a non-existent identifier is not acceptable, and
renaming it to "plan step 10" would have broken three documents. It is now §11.2.

**`V2-MS12` — split into `V2-MS12a` and `V2-MS12b`.** One number wore two scopes with two different
statuses: the guard (delivered, `U-213`) and the key custody (open, `[P2]`). That is why the
Delivered table said ✅ while the milestone table said 🟡 about "the same" identifier. Split, so each
half has one status.

---

## Annex C — retired documents and retired identifiers

### C.1 Retired identifiers

Nothing is lost; everything here says where it went and why.

| identifier | disposition | reason |
|---|---|---|
| `R-609a` | → **`R-616a`** | decision D7: a profile validator is not partitioning |
| `R-609b` | → **`R-616b`** | decision D7 |
| `R-609c` | → **`R-616c`** | decision D7 |
| `R-1004` | **retired, not an item** | a legacy "live Pages site" claim quoted only inside `R-003`'s body as prose that had to be downgraded. It never had a scope of its own; `R-1003` covers the repository as a product |
| `R-616` (as "declared free") | **now in use** | v2 declared it the first free number in the `R-6xx` family; D7 uses it |
| `V2-MS12` | → **`V2-MS12a`** + **`V2-MS12b`** | one number, two scopes, two statuses (Annex B) |
| `A-1`…`A-6` | → **`EA-1`…`EA-6`** | namespace collision with the audit's `C-*` (Annex B.3) |
| `B-1`…`B-5` | → **`EB-1`…`EB-5`** | as above |
| `C-1`…`C-7` (epic) | → **`EC-1`…`EC-7`** | as above; the audit keeps `C-*` |
| `R-800`, `R-812`, `R-813`, `R-814` | **not register items** | the endpoints of the range `docs/architecture/driver-manager.md:16` reserves; recorded in Annex B only |
| `R-501b`, `R-501c` | **folded into `R-912`** as named sub-scopes | earlier-generation identifiers; re-minting them as `R-912a`/`R-912b` would create two names for one piece of work (§8.5) |
| `R-401d`, `R-401f`, `R-301`, `R-502`, `R-502b`, `R-503` | **kept as delivered cross-references** | closed work from earlier generations, cited by live items; §5.4 and §8.5 |
| `R-10x`, `R-70x`, `R-80x`, `R-0xx`, `R-9xx`, `R-Dxx`, `R-Fxx`, `R-NNN` | **not identifiers** | family placeholders that appear in headings |

### C.2 Retired documents

Listed for approval before any removal. **Removed on 2026-09-03 at the owner's request** ("one detailed file as plan and roadmap, not several"): `ROADMAP-v2.md` and the six archived plans merged into §17–§21. The rest of the table still waits.

| document | measured size | proposal | reason |
|---|---|---|---|
| `ROADMAP-v2.md` | **122,262 bytes**, now a **26-line redirect stub** | **merged into this file 2026-08-31; stub removed 2026-09-03** (`git show 87e8194b1:ROADMAP-v2.md` for the last full text) | Its content is carried here in English: the shim-review audit (§5.1), the driver inventory (§8.1), the three-host split (§4), `eos-guard` and `eos-notes` (§7.3, §7.4), the standards analysis (§12), the anti-promises (§14) and the whole §12 installer programme (§3.4, §6). **The predecessor's own row for this file was wrong twice** — it recorded the size as 57 kB and proposed archiving the file whose §12 the project was actively working from. Both errors are corrected here rather than repeated. **The full text was not deleted** — it is in git at `87e8194b1`, and every reference to it in the tree now points here, except the dated records in `docs/audit/` and the `U-203`/`U-204`/`U-211`/`U-227` entries in `CHANGELOG.md`, which describe commits that really did act on that file — `U-227` being this merge itself. Verified 2026-08-31: `grep -rl ROADMAP-v2` over tracked Markdown returns exactly `CHANGELOG.md`, `ROADMAP.md`, `ROADMAP-v2.md` and four files in `docs/audit/` |
| `docs/architecture/overview.md` | 3.9 kB | **merge into `ARCHITECTURE.md`** | Two architecture documents with overlapping scope, mutually cross-linked, with no statement of which is the entry point. Audit `00 §6.4` |
| `EOS_BUILD_STATE.md` | 3.3 kB | **archived 2026-09-03** → `docs/archive/EOS_BUILD_STATE.md` | A checkpoint record from 2026-06-06, superseded by the audit reports; two citations repointed |
| `docs/archive/readme-snapshot-archive.md`, `docs/archive/eos-pkg-aarch64-readme-pre-publication.md`, `docs/audit/05-restructure-analysis-2026-08-30.md`, `patches/`, `scripts/probe-scheme-rmdir.*` | 34.5 kB | **removed 2026-09-03** (owner, Q15) | 0 references each; copies under the owner's `~/eos-artifacts/repo-archive-2026-09-03/` |
| `docs/archive/plan.md`, `docs/archive/hardware-plan.md` | 11 924 B, 8 476 B | **merged in full → §17, §18; removed 2026-09-03** | §16 now cites §17; the symptom form is §18.0.5; every `plan.md §N` citation in `config/`, `docs/architecture/`, the profiles and `ADR-0011` was rewritten to `ROADMAP.md §17.N` |
| `docs/archive/roadmap-connectivity.md` | 9 156 B | **merged in full → §19; removed 2026-09-03** | `R-920`'s B0–B5 ordering is §19.3 |
| `docs/archive/hardware-capabilities-roadmap.md`, `docs/archive/acpi-off-removal-plan.md` | 4 288 B, 4 839 B | **merged (scope and non-goals) → §20; removed 2026-09-03** | all four items delivered; `HARDWARE.md` repointed |
| `docs/archive/feature-proposals.md` | 12 570 B | **merged as a fate table → §21; removed 2026-09-03** | `system-updates.md` §4 repointed |
| `docs/archive/reality-ledger.md` | — | **review** | Superseded in function by `docs/audit/`, but `R-001` and `R-003` both cite it as the record of the CI recovery |

> **Naming history, so the loop is legible.** `ROADMAP.md` v1 was archived into `ROADMAP-v2.md` on
> 2026-08-29 (`U-211`). `ROADMAP.md` was then rebuilt and acquired content v2 never had, while its
> header still described it as an archive — so each file claimed the other was retired. **This
> rebuild ends that:** `ROADMAP.md` is the single live roadmap, under its conventional name, and
> `ROADMAP-v2.md` is a redirect stub pointing at it. There is one roadmap, and one status per
> identifier.

---

*Every claim in this document was either read out of the tree at `main` = `821b30fd6` on
2026-08-31 (§17–§21 and the 2026-09-03 registers: at `f9e431b11`), cited to a commit or a `U-NNN` changelog entry, or marked `[UNVERIFIED]` with the
command that would settle it. Where the two predecessor documents disagreed, the disagreement is
written down with its evidence rather than resolved silently — §5.3 (`R-702`), §10 (`R-F05`,
`R-F12`, `R-F27`), §7.2 (`R-D01`), §11.2 (`R-1002`, `R-1003`), §5.2 (`V2-MS12`).*
