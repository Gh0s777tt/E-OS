# E-OS Roadmap

**Last reviewed:** 2026-08-31 · **Owner:** Gh0s777tt · **Status:** current · **Language:** English
**Tree state:** branch `main` = `821b30fd6`. All 14 merge requests merged, none open.
`scripts/verify.sh` on `main`: 16 stages, 16 PASS, 0 FAIL, 0 SKIPPED.
`scripts/eos-repos.sh pins --strict`: 26 OK, 0 drift.

> **This file replaces both predecessors: the time-ordered `ROADMAP.md` and the subject-ordered,
> Polish-language `ROADMAP-v2.md`.** Each of those two documents declared the *other* retired —
> a loop that made both unciteable. The loop is closed here: this is the single roadmap and the
> single place where the status of an identifier is maintained. Its Polish substance is
> **translated** into this file, not summarised. As of 2026-08-31 `ROADMAP-v2.md` is a short
> redirect stub pointing here — kept in the tree rather than deleted, because removing a document
> is the owner's decision ([Annex C](#annex-c--retired-documents-and-retired-identifiers)); its
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
- [3. Now, next, later](#3-now-next-later) — starts with [3.0 What is left, in one place](#30-what-is-left-in-one-place)
- [4. Where work can happen](#4-where-work-can-happen)

**The subject register — the single source of status**
- [5. Trust chain: boot, package channel, keys](#5-trust-chain-boot-package-channel-keys)
- [6. Installer, wizard and updates](#6-installer-wizard-and-updates)
- [7. Desktop shell and applications](#7-desktop-shell-and-applications)
- [8. Drivers and hardware](#8-drivers-and-hardware)
- [9. Security posture by audit finding](#9-security-posture-by-audit-finding)
- [10. Correctness and regression register](#10-correctness-and-regression-register)
- [11. Platform, process and release](#11-platform-process-and-release)
- [12. Standards and compliance](#12-standards-and-compliance)

**What we do not claim**
- [13. Dropped and refused](#13-dropped-and-refused)
- [14. What this plan deliberately does NOT promise](#14-what-this-plan-deliberately-does-not-promise)
- [15. What has not been verified, and the command to verify it](#15-what-has-not-been-verified-and-the-command-to-verify-it)
- [16. Vision and positioning](#16-vision-and-positioning)

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

Five namespaces are live in this project. Two of them collide with documents outside the register,
and one collides with the audit. **A reader who meets `R-704` or `R-802` without knowing this will
misread it**, so this is a reading instruction, not a footnote.

| namespace | what it numbers | where it is defined |
|---|---|---|
| `R-*` | the work register — features, subsystems, defects | this file (§5–§12) |
| `V2-*` | Secure Boot milestones, storage drivers, buses, security suite, notebook, standards | this file (§5.2, §7.3, §7.4, §8.3, §12) |
| `S-*` / `M-*` / `L-*` | scheduling rows on the time axis, traced to audit findings | this file (§3.1–§3.3) |
| `EA-*` / `EB-*` / `EC-*` | installer / wizard / live-update epic backlog (**renamed this merge**) | this file (§3.5) |
| `C-*` / `G-*` / `A §…` | audit findings | [`docs/audit/`](docs/audit/) |

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
| NetSurf built from source as PIE | `U-103`, `U-105` |
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

### 3.0 What is left, in one place

The registers below are the source of truth for status; this list exists so the question
"what is actually left?" has one honest answer that fits on a screen. Written 2026-09-02.

**Blocked on something other than work**

- **`R-607b` — first run on real hardware.** One PC, the symptom form filled in, the result
  recorded as the first metal evidence. It is the only open row in M1 and it cannot be closed
  from QEMU. Everything upstream of it is done.
- **Releases, signed tags, cosign attestation, docs-site publication.** Gated on a working CI
  and on a signing key the owner holds. Generating that key is deliberately a human action and
  is not automated: a signing key must never pass through tooling that logs.
- **Shared-runner CI quota.** Every GitLab job has failed in 0 s with `ci_quota_exceeded` since
  2026-08-28. Nothing in the pipeline has been *evaluated* since then; each merge today was made
  after confirming all six jobs failed for quota and none had judged the code.

**Open defects with evidence, ready to be worked**

- **#26 — the x86_64 image does not assemble after a `cosmic-edit` re-cook.** `libonig` and
  `libxkbcommon` have no recipe in this tree; the freshly generated `auto_deps.toml` requires
  both. Not proven from a pristine tree, and said so in the issue.
- **#25 — the installer's disk-password prompts are not flushed**, so a headless serial install
  looks hung exactly where it asks about encryption. Fix is open as `eos-installer` !6,
  compile- and package-verified, not yet exercised on a booted image (blocked by #26).

**Named gaps, not yet defects**

- **`R-601e` — the harness still lacks three cases**: interruption in phase 1/3 (the only test of
  the M2 transaction), BIOS boot, and choosing the *wrong real disk* — `R-604a` tests a name that
  matches **no** disk (`install-smoke-drive.py:390` sends `offered[0] + "-not-a-real-disk"`),
  which is a different thing. FDE is now covered.
- **`R-601d` — GUI ↔ TUI parity gate.** Both front-ends must cover the same state set; the
  graphical path has never been exercised end to end.
- **`tools/eos-repo-sign::verify()` has no test.** It is the single place where trust in the
  E-OS package repository is decided. Named by the audit's completeness critic, round 2.
- **`S-8`, `S-11`…`S-16`, `S-18`…`S-20`** in §3.1 remain as recorded on 2026-08-31; today's audit
  did not re-verify them, and they are not restated here as if it had.

**What today's work does NOT change**

No feature was added, no kernel code touched, and the contents of the images are the same. What
changed is whether the gates around them can fail — see [§1.4](#14-gate-quality-audit-2026-09-02).

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
| S-9 | **Pin the upstream package key** → [`R-701a`](#53-package-channel-and-update-trust--r-7xx), [`V2-MS13`](#52-secure-boot-milestones--v2-ms) | open | **High** | Gh0s777tt | 4 h | `C-1`, `G-2` |
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
| M-8 | **`V2-MS04`, `V2-MS06`, `V2-MS07`, `V2-MS08`, `V2-MS09`** — remaining shim-review preparation. *Listed individually here on purpose:* the old range notation "`V2-MS06`–`V2-MS09`" left `V2-MS07` and `V2-MS08` with no owner and no horizon | Medium | Gh0s777tt | — | `ADR-0006` |
| M-9 | **Mirror-head parity check** — nothing compares GitLab and GitHub heads; one live divergence already exists (`eos-pkg-aarch64`, disjoint histories) | Medium | Gh0s777tt | 4 h | audit `00 §5.2` |

### 3.3 Long term (6–12+ months) — `L-1`…`L-7`

| # | Item | Priority | Owner | Traces to |
|---|---|---|---|---|
| L-1 | **Atomic updates with rollback** — the single largest gap against Silverblue, NixOS and GrapheneOS → [`R-706`](#53-package-channel-and-update-trust--r-7xx), [`R-707`](#53-package-channel-and-update-trust--r-7xx) | **High** | Gh0s777tt | audit `04 §4` |
| L-2 | **Wi-Fi** — no wireless driver ships → [`R-921`](#84-connectivity-and-honest-hardware-tiers--r-9xx) | **High** | Gh0s777tt ⚙️ | audit `02 §6` |
| L-3 | **Reproducible builds** — five measured obstacles, from unpinned apt to embedded timestamps → [`R-303`](#11-platform-process-and-release), [`V2-MS07`](#52-secure-boot-milestones--v2-ms) | Medium | Gh0s777tt | `A §2.1` |
| L-4 | **Backup tooling** | Medium | — | audit `02 §3` |
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
the symptom form is in [`docs/archive/hardware-plan.md`](docs/archive/hardware-plan.md) §0.5.

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
| EC-7 | Offline update from removable media, signature-verified | Low | `R-614b` (adjacent); no register row — **open scope** |

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
| Three documents contradicted the code | `docs/security/threat-model.md`, `docs/security/hardening.md` and `docs/archive/hardware-plan.md` still claimed nothing signs the bootloader. A reviewer reads the security documents, and a contradiction with the code is a maturity warning. **Since fixed as `V2-MS03`** (`U-211`, `U-216`) | XS |

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
| `R-701` | **Wire a working, E-OS-owned update source.** Publish done (`R-008`/`U-209`), `50_eos` **active on aarch64** with the pinned key measured in the running image (`U-210`: `cat /etc/pkg.d/50_eos` → the URL; `/etc/pkg/eos-repo-sign.pub.toml` present). `pkg update` **reaches the TCP layer** — DNS resolves and it connects to github.io — but a **complete `repo.toml` fetch and signature verification was never captured**: aarch64 under TCG plus TLS to github.io is too slow and unstable in the probe harness. **x86_64 remains unpublished and its `50_eos` is commented out** (`config/x86_64/eos.toml:767`), which is audit finding `C-4`. Ordering corrected in `U-134`: this used to depend only on `R-002`, which would have let it land *before* the key was pinned — strictly worse than the inert state it replaced `[P0·S·🖥️🔑]` | **WORKS TODAY** (aarch64) · **BUILDABLE** (x86_64) | 🟡 |
| `R-702` | **Pin the repo public key; kill TOFU.** ✅ — **and this is one of the four places the two predecessor documents disagreed.** The old `ROADMAP.md` carried 🚧 in its `R-7xx` section while its own Delivered table already carried "✅ `U-224`"; it contradicted itself. Resolved in favour of ✅ on the evidence: `keys/eos-repo-sign.pub.toml` exists, `config/aarch64/eos.toml:818` and `config/x86_64/eos.toml:849` both install it at `/etc/pkg/eos-repo-sign.pub.toml`, measured in the running system at **4075 B**, byte-identical to the repository file, and the `no pinned repo-manifest key` warning is gone from the log. The key pair was **verified with a test signature** (`U-224`): ed25519 and ML-DSA-65 both pass against the public half, and after flipping one byte both refuse with exit code 1. **What ✅ does not mean, and this residual must survive:** *pinned*, not *enforced end to end*. The closing proof — a live fetch that a wrong key rejects — was never captured, because no remote source was configured when the measurement was taken. That proof belongs to `R-703` `[P0·M·🖥️]` | **WORKS TODAY** | ✅ |
| `R-703` | **Client-side signed-manifest verification.** Publisher half done: `publish-repo-pages.sh`/`publish-repo.sh` emit `repo.toml.sig` via `eos-repo-sign`, and an unsigned publish hard-fails since `U-120`. Client half also done, and this entry claimed otherwise until `U-134`: `pkg-lib` fetches and verifies `repo.toml.sig` — `verify_repo_manifest` → `manifest_sig::verify_manifest_ed25519` — with tamper, wrong-key and malformed-signature tests, at the pinned `eos-pkgutils`. **Remaining:** a captured live end-to-end fetch+verify (see `R-701`), and promoting ML-DSA-65 from advisory to required per `R-503` `[P0·S·🖥️]` | **WORKS TODAY**, unproven live | 🟡 |
| `R-704` | **Anti-rollback / freshness + hash pinning.** The **index** is protected (`V2-MS15` ✅ — `serial`, `expires`); the **package** is not: a correctly signed **older** pkgar still installs. Add a per-package monotonic serial, reject downgrades, pin each downloaded package hash to the manifest hash `[P1·M·🖥️]` · needs `R-703` | **BUILDABLE** | 🔴 |
| `R-705` | **`eos-update` daemon plus a thin CLI** — check → resolve → verify → download → stage → apply, with a scheduling timer, desktop "updates available" notification, a persisted journal and privilege re-exec `[P1·L·🖥️]` · needs `R-703`, `R-D03` | **BUILDABLE** | 🔴 |
| `R-706` | **Staged transactional apply plus one-step rollback.** `transaction.commit()` mutates the live filesystem through an in-memory rename loop with no persisted journal, so a crash mid-loop half-applies with no recovery. Download and verify into staging, snapshot replaced files and `package.toml`, commit under a journal, expose `eos-update rollback`. **Shares its journal format with `R-612c`** — one semantics of resumption, not two. **Rollback by snapshot is impossible and is not the plan:** RedoxFS is internally copy-on-write but exposes **no snapshot API**, and `clone.rs` clones a file tree, not a point in time `[P1·XL·🖥️]` · needs `R-705` | **BUILDABLE**; `fsync` durability on RedoxFS `[UNVERIFIED]` | 🔴 |
| `R-707` | **Base/kernel apply-on-reboot with boot fallback.** Kernel, base and relibc are upgraded by live in-place file replacement — a bad kernel or a power cut can brick a real disk. Stage into `pending/`, flag the bootloader, verify on next boot, auto-revert after N failed boots, keep `kernel`+`kernel.sig` atomic. The **boot-attempt counter is a NEW SUBSYSTEM**: it needs a write path from the bootloader, and whether one exists is `[UNVERIFIED]` `[P2·XL·⚙️]` · needs `R-706` | **BUILDABLE** + **NEW SUBSYSTEM** (counter) | 🔴 |
| `R-708` | **"Settings → Update" pane** in the E-OS Settings shell: check/download/verify/apply with progress, changelog, history and rollback; refuses to apply unless manifest signature, per-package ed25519 and anti-rollback all pass; writes an audit log `[P1·L·🖥️]` · needs `R-705`, `R-D01` | **BUILDABLE** (shell ✅) | 🔴 |
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
| `R-502b` | **Hardware SHA acceleration** — parent scope of `R-914`; kept as a cross-reference, not re-minted | ✅ (scope), `R-914` open |
| `R-301` | **Signed release checksums for `harddrive.img`.** Closed in an earlier roadmap generation. Kept here because `R-611` cites it to prove it is not a duplicate: `R-301` covers the **pre-installed image**, `R-611` covers the **installation medium** — two different files | ✅ |
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
| `R-601e` | Missing harness cases: FDE (the harness sends an empty password today), interruption in phase 1/3, two disks with the wrong one chosen, a 4Kn disk, BIOS boot. **The interruption case is the only test of the M2 transaction** `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-602` | **First-boot OOBE wizard.** Password enforcement is **done and verified on every login path**. Text/getty and serial (`U-076`, `U-077`): a shared `force_first_boot_passwd` helper forces `passwd` before the shell for the passwordless `user` **and** any account still on the shipped default, order-independent so it catches `root/password`. Graphical greeter (`U-079`): `orblogin` — the default path since `R-F08` — no longer lets a default-credential account reach the desktop; it switches in-window to New password → Confirm, `set_passwd`+`save` (`Config::writeable(true)`, else EBADF), then starts the session. The live P0 default-credentials exposure is closed on both paths. **Remaining: per-machine identity** (hostname, locale, keymap, machine-id, SSH host keys) → `R-606` `[P0·L·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-603` | **Enrich the installer front-ends: account, hostname, locale.** Both GUI and TUI clone `base.toml` defaults and create no accounts (`installer_tui` TODO#3 unimplemented). Collect username+password, hostname, timezone, locale and keyboard, and feed `config.users`/`hostname` instead of the baked defaults `[P1·L·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603a` | **Move disk-selection logic out of the front-end into the library.** `installer_tui` has its own `disk_paths()` and `choose_disk()`, so GUI and TUI can diverge — a measured debt, not a hypothesis. The engine-with-two-front-ends shape already **exists** (`src/lib.rs` + `src/bin/installer.rs` + `src/bin/installer_tui.rs`, with the GUI a separate crate depending on `redox_installer` by path) `[P1·L·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603b` | Wizard state machine S0–S10: transition rules, point of no return, validation, and an S8 diff-and-risk screen `[P1·L·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603c` | Profile and feature data model in TOML: `serde` types plus a resolver (`installer-profiles.md` §3). **Inheritance with locks:** the `include = [...]` mechanism **exists** (`config/x86_64/eos.toml:7` → `["../desktop.toml"]`, and `config/desktop.toml:3` → `["desktop-minimal.toml", "server.toml"]`, so the chain is already two levels deep) but it merges *files*, not *decisions*, and has no locks `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-603d` | Account, hostname, timezone and keyboard layout collected by **both** front-ends and fed to `config.users`/`hostname`. A timezone **database is a NEW SUBSYSTEM** — today `/etc/tz-offset` is a constant number. Keyboard layouts `[UNVERIFIED]`: check `eos-orbital`, `eos-orbdata` `[P1·L·🖥️]` | **BUILDABLE** + **NEW SUBSYSTEM** (tz db) | 🔴 |
| `R-603e` | On-device verification of the **profile** signature. Needs `R-711`: without a keyring a profile signature is irrevocable `[P2·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-604` | **Destructive-action guardrails.** Whole-disk erase hides behind a bare numeric menu with no disk identification. Parent of `R-604a`–`R-604d` `[P1·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-604a` | Disk picker shows **device path, size, interface type and removability**; erase is confirmed by **retyping the device path**, not by picking a number. Negative control: two disks in QEMU, type the wrong name → refusal, zero writes. Today the harness expects the literal `Select a drive from 1 to`, and **the number in that menu changes between runs** if PCI enumeration order changes `[P0·M·🖥️]` | **BUILDABLE** | 🔴 ✅ **done 2026-09-01** (#9): the screen ran on Redox for the first time and refused a name matching no disk. Both halves of the negative control are now MEASURED, not inferred — the driver stats the target either side of the refusal and requires zero allocated blocks. Pinned at `eos-installer 2aae3ace0bbf`; `pin-allowlist.txt` is empty again. |
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
| `R-D01` | **Native E-OS Settings control panel** (orbital/orbclient, no libcosmic). Built and running (`U-071`, `eos-orbutils` `061dfd3`): an `eos-settings` binary that compiles for aarch64-redox, installs, ships `apps/15_eos-settings` plus an icon and launches against the live orbital, PID-verified. **Render-verified end to end** in QEMU: sidebar, **9 panels**, real System data, footer (`assets/screenshots/eos-settings-panel.png`). **Status disambiguated, because three places disagreed:** ✅ meant *present in the image*, 🟡 means *complete*. The panels exist; the panes that matter for the trust chain (`R-708`, `R-806`) do not, and neither do `R-D02`/`R-D03` live state. **🟡, in the sense of complete** `[P0·XL·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-D02` | **Functional system tray.** Icons and click-to-Settings done (`U-101`, `60c262d`): the `tray-{net,vol,set}` icons had never actually shipped — an invisible tray — so E-OS now ships three crimson glyphs and a click anywhere on the tray opens Settings, render-verified. **Remaining:** live state — the network indicator from netstack, a volume popup via `audiod`, which is **blocked by the absence of audio on the QEMU loop** (see `R-D07`) `[P1·M·🖥️]` · needs `R-D01` | **WORKS TODAY** | 🟡 |
| `R-D03` | **Notifications daemon and UI.** Minimal daemon done (`U-102`, `8ad7cd8`): `eos-notifyd` shows a crimson top-right toast for a `title\nbody` written to `/tmp/eos-notify`; render-verified. Enough to unblock `R-705`'s "updates available". **Remaining:** a real `notify:` scheme/socket transport instead of a polled file, a queue so one toast does not block the next, and richer UI (icons, actions) `[P1·M·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-D04` | **Screenshot utility** (`U-100`, `eos-orbital` `38226c7`). A standalone tool cannot capture the screen — orbital is the DRM master and the composited image lives only in its CPU shadow buffer — so the capture is **in the compositor**: Super-P writes `/home/user/screenshot-N.bmp` (uncompressed 32-bit BMP, no codec dependency, per-shot counter). Render-verified end to end: Super-P produced a valid 800×600 BMP of 1,920,054 B whose content is the real desktop `[P2·S·🖥️]` | **WORKS TODAY** | ✅ |
| `R-D05` | **Launcher type-to-search plus a local-time clock.** Clock (`U-098`, `94dcc91`): the bar reads local `YYYY-MM-DD HH:MM UTC±H` from `/etc/tz-offset` (ships 7200/UTC+2), render-verified `12:58 UTC+2` at host-UTC 10:58 — and this is exactly why `R-603d` needs a real timezone database rather than a baked constant. Search (`U-099`, `7b1268b`): the Start menu filters every app by name as you type, fed from orbital `TextInput` events, in a fixed-height window that never clips `[P2·S·🖥️]` | **WORKS TODAY** | ✅ |
| `R-D06` | **NetSurf builds from source as a PIE and renders.** The bundled browser died the instant it was clicked (data abort, ESR 0x92000047) because the shipped binary was upstream's non-PIE `ET_EXEC` prebuilt and aarch64-Redox only loads PIEs. Fixed across **three layers** (`U-103`, `U-104`): (1) the from-source build was blocked by a **host-toolchain 404** — `host:gperf` builds via `cookbook_redoxer`, whose `toolchain()` tried to download a host→host relibc toolchain Redox never publishes → `scripts/redoxer-host-stub.sh` pre-creates the stub; (2) a **CC wrapper** in the recipe forces `-fPIC` on every compile and `-pie` on the link, so `netsurf-fb` is a verified `DYN`/pie executable and, the recipe now differing from upstream, `--repo-binary` no longer re-downloads the prebuilt; (3) the PIE then crashed on first render — a **use-after-munmap of the 800×600×4 window buffer**: libnsfb caches `nsfb->ptr` while a `SDL_RESIZABLE` window makes orbclient's event pump `munmap`+remap that buffer on the resize event orbital sends on first map. Dropping `SDL_RESIZABLE` keeps the buffer put. Result, proven by boot and screendump: NetSurf renders `welcome.html` in full. Write-up: [`docs/architecture/netsurf-pie.md`](docs/architecture/netsurf-pie.md). Follow-up `R-D09` | **WORKS TODAY** | ✅ |
| `R-D07` | **Volume mixer UI plus a verified cosmic-edit boot.** cosmic-edit (2026-07-23): launched from its desktop icon, COSMIC Text Editor renders in full in the E-OS theme and is interactive — typing paints text and the tab flips to the modified state. The one `Image … start failed: Aborted` line came from a stray VT-launch probe, not from cosmic-edit; orbital has no Linux-style VTs. Volume mixer (`U-110`, `eos-control` `a76d0587`): a Sound tab drives `audiod`'s master volume through the `audio:volume` scheme control, with a mute button; when no audio stack is present the tab honestly shows "Audio unavailable" rather than a dead slider. **Hardware-gated regardless:** a *live* volume change needs real HDA — on the QEMU loop `ihdad` binds the controller but times out on the codec RIRB response, so `audiod` exits and `audio:` never appears. That driver bug is tracked in [`docs/reference/known-issues.md`](docs/reference/known-issues.md) and belongs to a drivers-fork job `[P2·M·🖥️]` · needs `R-D01` | **WORKS TODAY** | ✅ |
| `R-D08` | **Launcher `.desktop` membership verified from the image.** On a live boot the launcher is populated from the **image's** `.desktop` entries, not the source tree: the Start menu groups apps under freedesktop Categories and the grid shows installer-gui, cosmic-edit, cosmic-files, cosmic-term, the CLI tools and the E-OS apps. That they appear *is* the proof their `.desktop` files are installed in the image. **Remaining, and it is the part that matters:** the full **live → greeter → installer-gui → install** flow has never been tested end to end. `R-601` proved the **TUI** path, not this one. Precondition of `R-601d` `[P1·L·🖥️]` | **WORKS TODAY** (membership) | 🟡 |
| `R-D09` | **NetSurf resizable window.** `R-D06` dropped `SDL_RESIZABLE` to dodge the use-after-munmap. Proper resize needs libnsfb's SDL surface to re-fetch `nsfb->ptr` after orbclient remaps on `EVENT_RESIZE` and to post an `SDL_VIDEORESIZE`; the right home is the SDL orbital driver / libnsfb, not the recipe `[P3·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-D10` | **NetSurf browses the network.** A `-object filter-dump` pcap settled it (2026-07-19) and **corrected an earlier wrong call**: virtio-netd binds the NIC, netstack runs, and the pcap shows **DHCP** (request→reply), **ARP**, **ICMP**, **DNS** (`A? example.com` → `104.20.23.154` in 23 ms), a full **TCP** handshake to an external host, **HTTP** `200 OK`, and a live **TLS** exchange on :443 — all bidirectional. NetSurf's *own* fetch is in the pcap, and it renders the live Example Domain page. *The earlier "packets don't flow out" diagnosis was a false negative:* the raw-IP probe used `http://9.9.9.9/`, and **9.9.9.9:80 is closed even from the host**, so the SYN correctly got no reply | **WORKS TODAY** | ✅ |
| `R-D11` | **Privileged power actions from the GUI** (`U-109`). `sys:kstop` is root-only and `eos-control` runs as the desktop user, whose password is **not** empty since first boot sets it — verified: a shell login as `user` with an empty password returns `Login incorrect`. Fixed with a dedicated **`eos-power`** shim that elevates the way `sudo` does internally — open `/scheme/sudo`, write the password, elevate the process fd (`call_wo` + `CallFlags::FD`), `setns`, then write `sys:kstop`. **The GUI never runs as root**; it spawns `eos-power` and pipes the password to its stdin. Verified end to end: arming *Shut down*, typing the password and confirming **powered the VM off — QEMU exited** | **WORKS TODAY** | ✅ |
| `R-D12` | **Stop calling the session "the COSMIC desktop"** (`U-127`). Corrected across README (tagline, badge, screenshot alt and caption, feature table, highlights, architecture diagram, spec table, quick start, components table), `EOS_BUILD_STATE.md`, seven documents, `config/x86_64/eos.toml`, `NOTICE`, `assets/eos-banner.svg`, the GitHub issue template and the roadmap. `config/wayland.toml` is marked UNUSED/EXPERIMENTAL in place and `cosmic-comp`'s absence is a recorded entry in known-issues. Occurrences that were **correct** — the COSMIC applications, `cosmic-theme`, upstream-Redox history, the vendored `docs/reference/upstream-redox-readme.md` — were deliberately left alone `[P1·S·🖥️]` | — | ✅ |
| `R-D13` | **i18n string catalogue plus a key-parity gate (pl/en).** **No i18n infrastructure exists anywhere in the shell** — `eos-control` has its strings hard-coded, and an earlier claim that an i18n gate existed was fabricated (`U-126`). Filed in the `R-Dxx` family, not `R-6xx`, because the gap is the whole shell, not just the installer. Precondition of M4 `[P2·M·🖥️]` | **NEW SUBSYSTEM** | 🔴 |

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

| id | item | where | state |
|---|---|---|---|
| `V2-S01` | `tcp:`/`udp:`/`icmp:` library plus the first CLIs: port scan, DNS, ping, whois, banner | 🖥️ | 🔴 |
| `V2-S02` | file+CPU: hash calculator, metadata extractor, YARA/Sigma matcher, log analyser | 🖥️ | 🔴 |
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
| `R-801` | **`eos-devd` device-inventory daemon** exposing `/scheme/devices` — unify `pcid` (`/scheme/pci`), `xhcid` (USB ports) and `hwd` platform enumeration into one readable lspci/lsusb-style inventory (vendor/device/class + bound driver + bound? flag). The read-side foundation, buildable in user space on aarch64 today. Note that `hwd` spawns `acpid` only on the ACPI backend, not on the aarch64 DT path — see `R-811` `[P0·M·🖥️]` | **BUILDABLE** | 🔴 |
| `R-802` | **Signed driver catalogue** (device-ID → driver package + version + arch), packaged as its own pkgar signed with the `R-503` hybrid key, fetched, verified and cached. Seed it from the existing three catalogues so day-one coverage equals shipped coverage `[P0·M·🖥️]` · needs `R-703` | **BUILDABLE** | 🔴 |
| `R-803` | **Harden the matcher against untrusted catalogue input.** The panic is fixed (`U-137`, `eos-base` `66e3070b`): `DriverConfig::match_function` parsed vendor keys with `i64::from_str_radix(..).unwrap() as u16`, which carried two bugs — the `unwrap` panicked `pcid` mid-scan, and since the matcher runs for every driver against every device **one bad entry broke all boot binding**; and the `as u16` cast silently truncated, so `0x11111000` matched vendor `0x1000`, letting an entry bind a device it never names. Now parsed straight into `u16` with out-of-range rejected, a `log::warn!` and a skip, so a bad entry costs only itself. Four unit tests; **the negative control matters** — against the old parser 3 of the 4 fail, two by panicking at `config.rs:50:77`. Gates: `cargo check` clean, `cargo test -p pcid --lib` 4/4, full image build, **boot-smoke PASS** (reaching login *is* the proof the matcher still binds `nvmed`). The `needs R-801` dependency was artificial and was dropped. **Remaining:** reject duplicate entries, validate binary presence (the dead aarch64 entries in §8.1, and the missing `Arch` column in the hardware matrix), and reject **unsigned** catalogues, which genuinely needs `R-802`/`R-703` `[P0·S·🖥️]` | **WORKS TODAY** | 🟡 |
| `R-804` | **Split drivers out of `base.pkgar` into per-driver pkgar packages.** Every driver binary and its match toml ships inside `base.pkgar` today, so updating one driver replaces the core OS. Split into `drv-<name>` packages spanning the three catalogue owners and two roots (initfs vs rootfs), leaving `base` with only boot-critical initfs drivers `[P1·L·🖥️]` · needs `R-802` | **BUILDABLE** | 🔴 |
| `R-805` | **`pcid` spawn-on-demand** so a just-installed driver binds without a reboot. `pcid-spawner` is one-shot at boot; add a control op reusing the existing `PCID_CLIENT_CHANNEL` fd-passing `[P1·M·🖥️]` · needs `R-801` | **BUILDABLE** | 🔴 |
| `R-806` | **Driver Manager GUI (Settings → Drivers)** listing Missing/Outdated/OK, installing **only** from the signed repository and reusing the update download/verify/apply pipeline. Document the anti-scam property — sole source is the signed repository, every driver blake3 + ed25519 (+ ML-DSA) verified — and scope honestly that **detection works even where no driver exists** `[P1·M·🖥️]` · needs `R-801`, `R-802`, `R-D01`, `R-705` | **BUILDABLE** | 🔴 |
| `R-807` | **Persisted "device present, no driver" inventory**, so the manager can tell the user a Wi-Fi adapter or a touchpad exists but is unsupported — itself an anti-scam UX win, since `hwd` already names PNP0C0A battery and PNP0C50 I2C-HID with no driver `[P2·S·🖥️]` · needs `R-801` | **BUILDABLE** | 🔴 |
| `R-808` | **`hwd` platform-device binding (ACPI/DT):** map ACPI `_HID`/`_CID` and DT `compatible` strings to driver commands using the same match-table pattern as `pcid.d`, extending coverage beyond PCI+USB to SoC and laptop peripherals `[P2·L·⚙️]` · needs `R-801` | **BUILDABLE** | 🔴 |
| `R-809` | **Multi-segment ECAM/MCFG PCI enumeration.** `pcid` scans only bus 0, 0x80 and bridge-discovered buses (FIXME: *"Use full ACPI for enumerating the host bridges"*); handle multiple host bridges and PCIe segments `[P2·M·⚙️]` | **BUILDABLE** | 🔴 |
| `R-810` | **Driver A/B plus a boot-fail rollback watchdog** — keep the previous driver pkgar and auto-revert on a post-update boot failure, especially for storage and GPU `[P3·M·🖥️]` · needs `R-706`, `R-804` | **BUILDABLE** | 💡 |
| `R-811` | **Fix the `hwd` assumption that `acpid` is running.** `acpid` is spawned inside `AcpiBackend::new`, so it **never starts on the aarch64 DeviceTree backend** — the primary development target. The unified enumerator must not assume it `[P2·S·🖥️]` · needs `R-801` | **BUILDABLE** | 🔴 |
| `R-815` | **Administrative command channel to disks** — SMART, IDENTIFY, block size, secure erase. `installer-wizard.md` §15 names this as the only new work with no item and places it in `R-8xx` because it touches `nvmed`/`ahcid`, not the installer. Unblocks disk model and serial in `R-604a`, closes out `R-607a`, and carries secure erase for the Ghost profile. **`[UNVERIFIED]` whether the drivers expose any such channel today** — check `eos-base`: `drivers/storage/nvmed/src/**`, `drivers/storage/ahcid/src/**`. `R-815` is the first number outside the range `driver-manager.md` reserves (decision **D3**) `[P2·L·⚙️]` | **NEW SUBSYSTEM** | 🔴 |
| `R-816` | **Process supervisor / service lifecycle** — stop a service, replace its file, restart it, return to the previous version on failure. Precondition of the `service` package class (`ADR-0009` D6) and **the only route to a microkernel equivalent of live patching**. `init` knows exactly **two** service types — `oneshot` and `oneshot_async` — and supervises nothing after start. The nearest existing item, `R-805`, is about **binding devices**, not process lifecycle. `ADR-0009` D8 deliberately mints no number and defers to the register — i.e. here `[P2·L·🖥️]` | **NEW SUBSYSTEM** | 🔴 |

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
| `R-800`, `R-812`, `R-814` | **not register items** | the endpoints of the range `docs/architecture/driver-manager.md:16` reserves for itself; recorded only in Annex B |

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
| `R-F12` | **Every CI gate is a notification, not a gate.** **One of the four contradictions between the predecessors** (⏳ against 🟡); resolved as 🟡 on the evidence. `only_allow_merge_if_pipeline_succeeds = false` on the GitLab project and there had been **0 merge requests** in project history; all 10,088 commits went straight to `main`, so `pin-check`, `integrity`, `rust-checks` and `secret-scan` run *after* the code is published and mirrored, and `docs-currency` — which triggered only on merge-request events — **had never executed once**. **Partly fixed (`U-189`):** `.gitlab-ci.yml:83` now carries the comment *"R-F12: this job used to trigger ONLY on merge_request_event"* and the job also runs on the default branch; the script already had the fallback `base="${CI_MERGE_REQUEST_DIFF_BASE_SHA:-HEAD~1}"`, so nothing else needed changing. **This does NOT close the item and that is not glossed over:** the process decision (adopt merge requests for anything touching the trust chain, the build or a pin) and the project setting remain, and the latter needs a token — an operator action. On `main` the gate still runs **after** publication and mirroring; the move is from "never" to "too late", not to "in time". **And the harder fact neither predecessor stated: both CI platforms are dead** (`R-009`), so the job's rules are academic today `[P1·XS·🔑]` | 🟡 |
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
| `R-F29` | **`scripts/eos-build.sh:72` runs the build through `tail -3` inside `bash -lc` without `set -o pipefail`.** *Newly minted in this merge; neither predecessor carried it as an item.* Line **59** sets `set -o pipefail` for the host-tools build; line **72**, which runs `make CI=1 ARCH=$ARCH CONFIG_NAME=eos all build/$ARCH/eos/$MEDIUM_NAME 2>&1 \| tail -3`, does not — so the build's exit status is `tail`'s. This is `CLAUDE.md` trap **P-3** live in the build script, and it is the same mechanism that let `cargo: command not found` scroll past under `set -e` (`U-224`). The bootloader recipe's own comment names the output half of this defect — *"`scripts/eos-build.sh` pipes make through `tail -3`, so the warning never reached the operator"* — while the exit-status half is still open. **Stated precisely, because the script is not defenceless:** line 72 has no `\|\|` guard, so a failed `make` returns `tail`'s zero; what catches the worst case is a *downstream* check comparing the mtimes of `harddrive.img` and the medium before and after, which refuses to export unchanged images when a Secure Boot key is present. That guard fires only when **both** images are untouched, so a `make` that fails **after** writing one of them still passes. Fix: add `set -o pipefail` on the container side of line 72, as line 59 already does. Negative control: break the make target and confirm the script exits non-zero `[P1·XS·🖥️]` | 🔴 |

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
| `R-207` | A usable out-of-the-box toolset after a fresh install | 🟡 |
| `R-303` | **Reproducible release pipeline** tag → image → release. The pipeline exists; **byte-for-byte reproducibility is unproven**. `.config` and `cookbook.lock` are now **tracked** (`U-168`, `U-169`), so the main obstacle is gone, but **nobody has run the comparison**. Until someone does, it is not a fact. Same work as `V2-MS07`; five measured obstacles remain, from unpinned apt (`S-15`) to embedded timestamps | 🟡 |
| `R-402` | Extended hardware and driver coverage for the v0.4.0 "Reach" milestone | 🔴 |
| `R-403` | Test matrix on real hardware — the umbrella over `R-607b` and `R-923` | 💡 |
| `R-1002` | **LTS branch plus stability policy.** The `lts/0.1` branch exists (verified: `remotes/github/lts/0.1`) and the policy exists; **what is open is the ABI commitment at 1.0**. *This was one of the five contradictions resolved during the previous merge: v2 had it 🔴 while the branch and policy already existed* | 🟡 |
| `R-1003` | **Package repository as a product.** *Its "remaining" list used to name three things that were already done elsewhere in the same file.* Rewritten honestly: first publish ✅ (`R-008`), `50_eos` wired on aarch64 ✅, key generated ✅. **What actually remains: the x86_64 publish and an application ecosystem** — 65 packages against tens of thousands | 🟡 |
| `R-1010` | **Enable the `contain` package** — Qubes-style compartmentalisation. `recipes/core/contain` **exists in the tree and is switched off**; `Namespace::fork()` is unprivileged and can only **narrow**. *Newly minted as a register row in this merge.* v2 §12.7 stated outright that the register did not contain this item **while `EP-2` and `M4` depended on it** and `CLAUDE.md:593` cited it as `R-1010`; `docs/adr/0011-installer-wizard-architecture.md` and `docs/architecture/installer-profiles.md` cite it too. Shipping a milestone that depends on a non-existent identifier is not acceptable, so it is a row: enable `contain` and define per-application policy. Audit finding `C-5`; the precondition of sandboxed profile import (M4) and the substrate `M-1` builds on `[P1·L·🖥️]` | 🔴 |
| `R-1004` | Legacy "live Pages site" claim, quoted only inside `R-003`'s body as prose that had to be downgraded. **Retired — not an item.** See [Annex C](#annex-c--retired-documents-and-retired-identifiers) | ❌ |

### 11.3 Testing, coverage and gates — the standing state

Not a new item; the standing context every row above is measured against.

- **`scripts/verify.sh`** is the one command run before every commit: format → lint → typecheck →
  build → test → project gates → security scans, exiting non-zero on any failure. It **calls** the
  same commands the pipelines do rather than restating their rules — a second copy of a rule is a
  copy that drifts. **On `main` today: 16 stages, 16 PASS, 0 FAIL, 0 SKIPPED.**
- **A missing tool is `SKIPPED` *and* a non-zero exit**, because `gitleaks || true` once passed a
  planted key while printing green (`U-140`): an absent scanner gives the same result as a disabled
  one. The deliberate escape is `--allow-missing`, and then the summary names what was **not**
  measured.
- **`exit 1` ≠ `exit 2`.** 1 = the gate **found a defect**, fix the tree. 2 = the gate **could not
  run**, fix the toolbox. The same split as `FAIL (instrument):` in `ci-integrity.sh` (`U-177`).
- **`ci-integrity.sh` has checks 0…13** — banner `0.` (the instrument probe) through `11.`, plus
  check **12**, the tarball-blake3 gate (`scripts/eos-check-tar-pins.py`), plus check **13**, added
  2026-08-31: `scripts/eos-check-unbound-arrays.py`, which refuses an empty array expanded under
  `set -u`. Check 5 could not see that class — it greps for bash-4-only *syntax*, and this parses in
  bash 3.2 and dies at run time on one branch. Measured: `ci-install-smoke.sh` died with
  `VIDEO_ARGS[@]: unbound variable` while this gate printed `ok` and exited 0 in the same tree. It
  found one further instance nobody had planted, in `scripts/rx-proof-harness.sh:193`.
  **The numbering gate that decision D5 requires is therefore check 14, not 13** — see Annex B. *Re-measured 2026-08-31, correcting the wording inherited from the
  predecessors: `CLAUDE.md` **has no §0**, and its §3 (line 75) already says "twelve checks", which
  is current. The single stale place is **§13** (line 443), which still says "8 invariant checks" —
  four behind the gate, and therefore also contradicting §3 of its own document. (`CLAUDE.md` is
  Polish; grep it for `kontroli` to see both lines.) A defect against `CLAUDE.md` §5.8, to be fixed
  there rather than here.*
- **Coverage** is measured on every `verify.sh` run, not quarterly: `tools/eos-repo-sign` is
  **gated** at `--fail-under-lines 38` (measured 41.06 %); the vendored `redox_cookbook` is reported
  without a threshold. The asymmetry is deliberate — gating coverage on code we do not maintain is
  re-litigating someone else's tree.
- **Known flake, measured rather than inferred:** `cook::cook_build::tests::file_system_loop_no_infinite_loop`
  fails at `src/config.rs:209` with `Configuration is not initialized` — it reads global state that
  a **different** test in the same binary initialises, so the result depends on thread order. The
  odds **rise with CPU load**: 2 failures in 18 default parallel runs on an idle machine, 5 in 6
  when other work competed for the processor, 0 in 3 with `--test-threads=1`. A loaded shared CI
  runner is therefore this test's **worst** case. Not fixed by pinning threads in the gate: local
  green bought by diverging from CI is still a red pipeline.

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
| Antivirus / malware scanner | No third-party binary ecosystem to scan. File-integrity monitoring in `eos-control` addresses the actual risk; a signature scanner would be theatre. Audit `02 §3` |
| SELinux/AppArmor-style MAC | Architecturally wrong for a microkernel. The scheme allowlist is the native equivalent; the effort belongs in per-process scopes (`M-1`, `R-1010`), not in porting an LSM. Audit `02 §4`, and see §12.3 |
| `orbterm` in the desktop image | Superseded by `cosmic-term`. Explicitly excluded in `config/desktop.toml:26` (`orbterm = "ignore"`) |
| `eos-guard` and `eos-sysmon` as separately shipped applications | Consolidated into `eos-control` (`U-095`). The repositories remain as history, and `eos-guard`'s **engine** is still the basis of §7.3 |
| Global `REPO_BINARY=0` | Would compile third-party ports for hours with no security gain. See `ADR-0002`. **Revisit for `git` specifically** (`S-16`) |
| DAST | Not meaningful for an operating system image |
| A separate rescue medium | A second artefact means a second checksum, a second signature and a second thing that goes stale. Rescue is content of *this* medium — `R-614` (`installer.md` §10 item 7) |
| A network installer | Refused, not deferred: no Wi-Fi exists, and the installer would need a touchpad (no I2C) and a screen reader (needs working audio). §14 |
| Rollback by filesystem snapshot | Not refused because it is worse — refused because **there is nothing to build it on**. RedoxFS is internally copy-on-write but exposes no snapshot API, and `clone.rs` clones a file tree, not a point in time |
| `cosign` for artefact signing | The task could be written, but **a human generates the signing key** (`CLAUDE.md` §5.7) and a tool that logs must not touch it. Operator work, not automation. Today: minisign |
| `cargo-audit` in CI | Redundant against `cargo-deny check advisories`; kept locally in `local-scan.sh` |

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
  - An optical-drive driver (ATAPI / SCSI MMC) — **NEW SUBSYSTEM**, absent from `recipes/`.
  - End-to-end DVD boot — **NOT FEASIBLE TODAY**, needing both of the above.

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

### 14.5 About security tooling, applications and standards

- **Three classes of security tool are blocked on a missing OS primitive** — packet sniffer, live
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
| 6 | **[stale, corrected] The check number.** An earlier version said `ci-integrity.sh` had checks 0…11 and that the new numbering gate would be **check 12**. **Check 12 already exists** — the tarball-blake3 gate at `ci-integrity.sh:339` calling `scripts/eos-check-tar-pins.py`. The numbering gate of decision D5 is **check 13**. Renumber before anyone implements it | `grep -n '^# [0-9])\|── [0-9]*\.' scripts/ci-integrity.sh` |
| 7 | **None of the proposed negative controls has been run.** The "proof it is done — and how it fails" column in §6.3 describes the **intended** shape of each test. Per `CLAUDE.md` §5.4 none of them is a test until someone has seen it fail without the fix and pass with it | run each listed control on a branch, record the output in the MR |
| 8 | **Measurements taken on a built tree are not reproducible today.** Artefact sizes, hybrid-image signatures and the contents of `build/fstools/bin/` come from a session in which the build tree existed. In a clean tree `build/` holds only `container.tag`, `hostbuild-eos-control` and `id_ed25519.pub.toml` | `make CI=1 ARCH=x86_64 CONFIG_NAME=eos live` and `make fstools`, then repeat the offset measurements and the binary listing |
| 9 | **Bootloader code was not read.** Classifying the boot-attempt counter (`R-707`, M7) as a NEW SUBSYSTEM rests on `ADR-0009` saying the bootloader has no write path — not on reading it. `recipes/core/bootloader/` in this tree is `recipe.toml` + `sbat.csv`, confirmed | in `eos-bootloader`, look for any write path to the ESP or to RedoxFS |
| 10 | **`R-F16`'s x86_64 expectation.** x86_64 is *expected* to be unaffected by the GIC defect because MSI/MSI-X avoids that path entirely — **never verified**; no x86_64 image has been built and booted for that purpose on this host | build the x86_64 image and run the INTx reproducer against it |
| 11 | **`R-902`'s DHCP/static toggle has never been screendumped.** The pane and its apply flow were; the toggle's non-visual core is `--selftest`-proven inside a boot-smoked image. A GUI render is only proven by screendump | boot the image, open eos-control → Network, toggle, `screendump` |
| 12 | **`R-901`'s pcap has not been re-run** against a current image; the proof is from the original fix | re-run the `-object filter-dump` capture on the current aarch64 image |
| 13 | **Whether the Redox kernel pages at all** (swap, §14.4) | inspect the memory subsystem in `eos-kernel` |
| 14 | **Whether `eos-kernel` has any speculative-execution mitigations** (§14.4) | `grep -riE "kpti\|retpoline\|ibrs\|ibpb\|spec_ctrl\|mds\|l1tf"` in `eos-kernel` |
| 15 | **Whether `nvmed`/`ahcid` expose any administrative command channel** (`R-815`) | read `drivers/storage/nvmed/src/**` and `drivers/storage/ahcid/src/**` in `eos-base` |
| 16 | **Whether keyboard layouts exist anywhere** (`R-603d`) | check `eos-orbital` and `eos-orbdata` |
| 17 | **Whether `fsync` is durable on RedoxFS** (`R-706`, `R-612c`) | write a power-cut test against the journal format before committing to it |
| 18 | **Three items have no register row and are named here so they are not lost:** the KDF audit for AES-XTS (`EA-2`), the honest first-run security-posture screen (`EB-4`), and offline update from removable media (`EC-7`). Also **`C-20` (enforce commit signing)** has no roadmap item | decide at approval: mint rows or fold each into `R-603b` / `R-614b` / `S-1` |
| 19 | **`.github/workflows/_canary.yml` is missing** although `CLAUDE.md` §13.1 cites it as the reproducible Actions measurement | restore the file or correct `CLAUDE.md` |
| 20 | **`R-201`, `R-207`, `R-402`, `R-403` carry no in-tree evidence** in either predecessor beyond a one-line description. They are carried forward at their inherited status and should be re-scoped or retired at the next review | define an acceptance criterion for each, or move to Annex C |

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

> **Who this is for and in what order:** see [`docs/archive/plan.md`](docs/archive/plan.md)
> (`U-142`) — the three editions (desktop / gaming / server), which Qubes and Tails patterns map
> onto the scheme model and which cannot without an IOMMU, and the ten-step ordering where the order
> *is* the security control. This file stays the item list; that file is the argument.

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
| `R-6xx` installer, wizard, medium | `R-601` `R-601a` `R-601b` `R-601c` `R-601d` `R-601e` `R-602` `R-603` `R-603a` `R-603b` `R-603c` `R-603d` `R-603e` `R-604` `R-604a` `R-604b` `R-604c` `R-604d` `R-605` `R-606` `R-607` `R-607a` `R-607b` `R-608` `R-608a` `R-609` `R-609d` `R-610` `R-611` `R-611a` `R-611b` `R-611c` `R-611d` `R-611e` `R-612` `R-612a` `R-612b` `R-612c` `R-612d` `R-613` `R-614` `R-614a` `R-614b` `R-614c` `R-615` `R-616` `R-616a` `R-616b` `R-616c` | §6.2 |
| `R-7xx` update system | `R-701` `R-701a` `R-702` `R-703` `R-704` `R-705` `R-706` `R-707` `R-708` `R-709` `R-710` `R-710a` `R-710b` `R-711` `R-712` | §5.3 |
| `R-8xx` driver manager and services | `R-801` `R-802` `R-803` `R-804` `R-805` `R-806` `R-807` `R-808` `R-809` `R-810` `R-811` `R-815` `R-816` · non-items `R-800` `R-812` `R-814` | §8.2, §8.5 |
| `R-9xx` connectivity and hardware tiers | `R-901` `R-902` `R-903` `R-904` `R-904a` `R-905` `R-906` `R-907` `R-910` `R-911` `R-912` `R-913` `R-914` `R-916` `R-917` `R-918` `R-920` `R-921` `R-922` `R-923` `R-924` `R-930` `R-931` `R-932` `R-933` `R-934` `R-935` `R-936` | §8.4 |
| `R-10xx` platform and product | `R-1002` `R-1003` `R-1010` · retired `R-1004` | §11.2, Annex C |
| `R-Fxx` correctness and regression | `R-F01` … `R-F29` (all 29, none omitted) | §10 |
| `R-Dxx` desktop shell | `R-D01` `R-D02` `R-D03` `R-D04` `R-D05` `R-D06` `R-D07` `R-D08` `R-D09` `R-D10` `R-D11` `R-D12` `R-D13` | §7.2 |
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
| `R-8xx` | `R-801`…`R-811`, `R-815`, `R-816` | `driver-manager.md:16` reserves `R-800`…`R-814` range-wide | **`R-815`** — first number outside someone else's declared range |
| `R-Dxx` | `R-D01`…`R-D13` | — | `R-D14` |
| `R-Fxx` | `R-F01`…`R-F29` | — | `R-F30` |

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

Listed for approval before any removal — **nothing has been deleted.**

| document | measured size | proposal | reason |
|---|---|---|---|
| `ROADMAP-v2.md` | **122,262 bytes**, now a **26-line redirect stub** | **merged into this file 2026-08-31; stub kept in the tree, deletion still needs the owner** | Its content is carried here in English: the shim-review audit (§5.1), the driver inventory (§8.1), the three-host split (§4), `eos-guard` and `eos-notes` (§7.3, §7.4), the standards analysis (§12), the anti-promises (§14) and the whole §12 installer programme (§3.4, §6). **The predecessor's own row for this file was wrong twice** — it recorded the size as 57 kB and proposed archiving the file whose §12 the project was actively working from. Both errors are corrected here rather than repeated. **The full text was not deleted** — it is in git at `87e8194b1`, and every reference to it in the tree now points here, except the dated records in `docs/audit/` and the `U-203`/`U-204`/`U-211`/`U-227` entries in `CHANGELOG.md`, which describe commits that really did act on that file — `U-227` being this merge itself. Verified 2026-08-31: `grep -rl ROADMAP-v2` over tracked Markdown returns exactly `CHANGELOG.md`, `ROADMAP.md`, `ROADMAP-v2.md` and four files in `docs/audit/` |
| `docs/architecture/overview.md` | 3.9 kB | **merge into `ARCHITECTURE.md`** | Two architecture documents with overlapping scope, mutually cross-linked, with no statement of which is the entry point. Audit `00 §6.4` |
| `EOS_BUILD_STATE.md` | 3.3 kB | **archive** | A checkpoint record from 2026-06-06, superseded by the audit reports |
| `docs/archive/plan.md`, `docs/archive/hardware-plan.md` | — | **review, do not archive yet** | `plan.md` is still cited by §16 as the argument behind the item list, and `hardware-plan.md` §0.5 holds the symptom form M1 task 11 depends on |
| `docs/archive/roadmap-connectivity.md` | — | **review** | Predates this document's networking items; `R-920` still cites its B0–B5 ordering |
| `docs/archive/reality-ledger.md` | — | **review** | Superseded in function by `docs/audit/`, but `R-001` and `R-003` both cite it as the record of the CI recovery |

> **Naming history, so the loop is legible.** `ROADMAP.md` v1 was archived into `ROADMAP-v2.md` on
> 2026-08-29 (`U-211`). `ROADMAP.md` was then rebuilt and acquired content v2 never had, while its
> header still described it as an archive — so each file claimed the other was retired. **This
> rebuild ends that:** `ROADMAP.md` is the single live roadmap, under its conventional name, and
> `ROADMAP-v2.md` is a redirect stub pointing at it. There is one roadmap, and one status per
> identifier.

---

*Every claim in this document was either read out of the tree at `main` = `821b30fd6` on
2026-08-31, cited to a commit or a `U-NNN` changelog entry, or marked `[UNVERIFIED]` with the
command that would settle it. Where the two predecessor documents disagreed, the disagreement is
written down with its evidence rather than resolved silently — §5.3 (`R-702`), §10 (`R-F05`,
`R-F12`, `R-F27`), §7.2 (`R-D01`), §11.2 (`R-1002`, `R-1003`), §5.2 (`V2-MS12`).*
