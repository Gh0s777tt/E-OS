# Roadmap

**Last reviewed:** 2026-08-30 · **Owner:** Gh0s777tt · **Status:** current

Every item on this roadmap traces to something checkable: an audit finding, an ADR, a milestone
identifier, or a measurement recorded in [`CHANGELOG.md`](CHANGELOG.md). There are no wishlist
entries. Where an item exists only because an audit found a defect, the finding id is given and it
can be read in [`docs/audit/`](docs/audit/).

**Status:** ✅ done · 🚧 in progress · 📋 planned · ❌ dropped
**Priority:** High / Medium / Low

> This file replaces both the archived v1 roadmap and `ROADMAP-v2.md`. See
> [Retired documents](#retired-documents) at the end.

---

## Contents

- [Delivered](#delivered)
- [Short term (1–3 months)](#short-term-13-months)
- [Mid term (3–6 months)](#mid-term-36-months)
- [Long term (6–12+ months)](#long-term-612-months)
- [Security roadmap](#security-roadmap)
- [Epic: installer, installation wizard and live updates](#epic-installer-installation-wizard-and-live-updates)
- [Dropped](#dropped)
- [Vision](#vision)
- [Retired documents](#retired-documents)

---

## Delivered

### v0.1.0 — "Genesis" (2026-06-07)

| Item | Status | Evidence |
|---|---|---|
| E-OS identity, branding, security and automation baseline | ✅ | `cad6d4895` |
| Build configuration and OS-level rebrand | ✅ | `0d14ebc12` |
| Red/black bootloader theme, greeter and wallpaper, built from source | ✅ | `897fa66d6`, `5dc7e14e9` |
| Console login branded `eos login:` | ✅ | `919a84809` |
| aarch64 desktop configuration | ✅ | `82af7a440` |
| Recipes repointed at E-OS source forks | ✅ | `4a09cf7c3` |
| CycloneDX SBOM, checksums, release pipeline | ✅ | `f17427863` |
| minisign-signed release checksums + public key | ✅ | `630d98e40` |
| Threat model, hardening and disk-encryption guides | ✅ | `5f61baeef` |
| mdBook documentation site | ✅ | `60d938127` |
| `time` bumped for CVE-2026-25727 | ✅ | `0d90e5c71` |

### v0.2.0 (2026-08-22)

233 commits; 82 recorded changelog entries. Highlights, each traceable:

| Item | Status | Evidence |
|---|---|---|
| **eos-notes** — first E-OS application (Slint + SQLite/WAL) | ✅ | `U-086` |
| **eos-ui** — shared Slint-on-Orbital backend | ✅ | `U-088` |
| **eos-guard** — filesystem integrity monitor | ✅ | `U-089` |
| **eos-sysmon** — system monitor | ✅ | `U-094` |
| **eos-control** — unified control centre; supersedes guard + sysmon as shipped apps | ✅ | `U-095` |
| Control centre panes: processes, storage, network, power, sound | ✅ | `U-096`–`U-113` |
| Desktop: launcher search, clock, status tray, notifications, screenshot | ✅ | `U-098`–`U-102` |
| NetSurf built from source as PIE | ✅ | `U-103`, `U-105` |
| Graphical and text OOBE forcing a password on first boot | ✅ | `U-076`, `U-077`, `U-079` |
| Secure Boot: bootloader signed, live ISO and installed system proven | ✅ | `U-206`–`U-208` |
| Supply chain: every fetched build binary SHA256-pinned | ✅ | `U-118` |
| Unsigned publish requires an explicit opt-in | ✅ | `U-120` |
| Upstream package source no longer shipped active | ✅ | `U-143` |
| Raw IP sockets removed from unprivileged users | ✅ | `U-144` |
| Repo type enforced from the manifest; first x86_64 build and boot | ✅ | `U-169` |
| Install proven end to end: partition → install → reboot → login | ✅ | `U-176` |
| First signed repository, verified both ways | ✅ | `U-198` |

### Since v0.2.0 — unreleased

| Item | Status | Evidence |
|---|---|---|
| `V2-MS01` SBAT stamped into both UEFI bootloaders before signing | ✅ | `U-218` |
| `V2-MS02` bootloader verifies kernel and initfs by signature | ✅ | `U-212` |
| `V2-MS05` hermetic Secure Boot signing | ✅ | `U-218` |
| `V2-MS12` package-key guard; false premise corrected | ✅ | `U-213` |
| `V2-MS13` blake3 from the signed index enforced on installed bytes | ✅ | `U-223` |
| `V2-MS14` `pkg install` authenticates the index too | ✅ | `U-223` |
| `V2-MS15` rollback and freeze protection (`serial`, `expires`) | ✅ | `U-223` |
| `R-702` repo-signing key pinned in the image, pair verified | ✅ | `U-224` |
| Kernel `Iopl` privilege fix — raw port I/O requires root | ✅ | `U-219` |
| POSIX.1-2024 measured: 4267/5650 | ✅ | `U-220`–`U-222` |
| Full audit: inventory, code, features, security, gaps | ✅ | `U-224`, [`docs/audit/`](docs/audit/) |

---

## Short term (1–3 months)

Ordered by cost-to-value. The first block is roughly three and a half hours of work in total and
closes six findings, two of them HIGH.

| # | Item | Status | Priority | Owner | Effort | Traces to |
|---|---|---|---|---|---|---|
| S-1 | **Block direct pushes to `main`** — `only_allow_merge_if_pipeline_succeeds` is already enabled and is bypassed by every commit going straight to `main` (0 merge requests in project history) | 📋 | **High** | operator | 15 min | audit `C-6`, `G-5` |
| S-2 | **Make an unverified boot build explicit** — require `EOS_ALLOW_UNVERIFIED_BOOT=1`; today a missing boot key silently yields a bootloader that verifies nothing, and `eos-build.sh` pipes the warning through `tail -3` | 📋 | **High** | Gh0s777tt | 30 min | audit `C-2`, `G-4` |
| S-3 | **Fix the `repo` TUI panic** — `repo.rs:1945` stores `Some(empty)`; `repo.rs:1700` indexes it. A log search with no match kills the TUI mid-build | 📋 | **High** | Gh0s777tt | 15 min | audit `A §5.3` |
| S-4 | **Allowlist `keys/eos-pkg-signing.pub.toml` in `.gitleaks.toml`** with a written justification — it is a 32-byte public key; the gate will fail on it the moment CI minutes return | 📋 | **High** | Gh0s777tt | 15 min | audit `C-19` |
| S-5 | **Give `$(FSTOOLS_TAG)` source prerequisites** — `make` never rebuilds the host tools, so a build can run against a stale `repo_builder` and emit an index missing a field the source already writes | 📋 | **High** | Gh0s777tt | 1 h | audit `C`, `A §5.1`, `G-15` |
| S-6 | **Point the README bootstrap at the in-repo script** — the documented first command is `curl … \| bash` from a moving branch of a third-party server | 📋 | **High** | Gh0s777tt | 15 min | audit `A §2.3` |
| S-7 | **Pin `blake3` for `mpc`** and make an unpinned tarball a hard error — the only unpinned recipe of 19 GNU sources, and it is a `gcc13` dependency; `config.rs` silently rewrites the URL to a university mirror | 📋 | **High** | Gh0s777tt | 1 h | audit `C-1b`, `A §5.4b` |
| S-8 | **Verify `blake3` regardless of `is_deps`** — dependency recipes skip the check, yet the declared hash is published as the source identifier | 📋 | **High** | Gh0s777tt | 3 h | audit `C-1c`, `A §5.4c` |
| S-9 | **Pin the upstream package key** instead of trusting the copy fetched from the host that serves the packages | 📋 | **High** | Gh0s777tt | 4 h | audit `C-1`, `G-2` |
| S-10 | **Publish the x86_64 package repository** and enable `/etc/pkg.d/50_eos` — an installed x86_64 system currently has no update path at all | 📋 | **High** | operator | 1 d | audit `C-4`, `G-1` |
| S-11 | **Republish the aarch64 index with `serial`/`expires`** — the live index predates `V2-MS15` and has no rollback protection | 📋 | Medium | operator | 1 d | audit `C-12` |
| S-12 | **Bump `eos-pkgutils`** for `rustls-webpki`, `ring`, `rand` — `rustls-webpki 0.103.4` with six advisories ships inside `/usr/bin/pkg` | 📋 | **High** | Gh0s777tt | 2 h | audit `C-3`, `G-13` |
| S-13 | **Tests for `repo_builder.rs` and `cook/package.rs`** — the code that writes the signed index and signs packages has none | 📋 | **High** | Gh0s777tt | 2 d | audit `G-9` |
| S-14 | **`osv-scanner` in CI and in `lefthook`** — Dependabot reports 0 while an independent scanner finds 2 in the same lockfile | 📋 | Medium | Gh0s777tt | 1 h | audit `C-13` |
| S-15 | **Pin apt versions in the container files** — three `DL3008`; the build environment is not reproducible | 📋 | Medium | Gh0s777tt | 2 h | audit `C-17`, `G-16` |
| S-16 | **Build a current `git`** — the image ships `git 2.13.1` (2017) as a fetched upstream binary | 📋 | **High** | Gh0s777tt | 4 h | audit `C-8`, `G-8` |
| S-17 | **Repoint 22 recipes from the GitHub mirror to `gitlab.com/e-os`** — the build resolves sources against the mirror, not the declared source of truth | 📋 | Medium | Gh0s777tt | 2 h | audit `G-10`, `ADR-0001` |
| S-18 | **One source of product version** — the image reports `0.1.0` while the signed tag is `v0.2.0` | 📋 | Medium | Gh0s777tt | 1 h | audit `G-17` |
| S-19 | **Second maintainer or a written recovery procedure** — a single-person project with no break-glass path | 📋 | **High** | operator | 1 d | audit `C-18`, `G-12` |
| S-20 | **SBOM generated and committed per tag** — `sbom/` covers 0.1.0 only; the CI artefact expires after 30 days | 📋 | Medium | Gh0s777tt | 2 h | audit `C-14` |

## Mid term (3–6 months)

| # | Item | Status | Priority | Owner | Effort | Traces to |
|---|---|---|---|---|---|---|
| M-1 | **Application sandboxing** — per-process scheme sets, starting with NetSurf. Today the browser holds the same 25 schemes as the shell, including `file`, `proc` and `sudo` | 📋 | **High** | Gh0s777tt | 1–2 weeks | audit `C-5`, `G-3` |
| M-2 | **Persistent audit log** — a logging daemon with rotation; there is nothing to read after an incident | 📋 | **High** | Gh0s777tt | 1 week | audit `C-9`, `G-6` |
| M-3 | **Packet filtering**, or an explicit decision to disable `sshd` by default | 📋 | **High** | Gh0s777tt | 2 weeks | audit `C-10`, `G-7` |
| M-4 | **Separate signing from the build machine** — four private keys currently live on the host that is also the CI "heavy" runner | 📋 | Medium | operator | 1 week | audit `C-11`, `G-11` |
| M-5 | **SAST in CI** (`semgrep`) — there is none today; clippy is a linter, not a SAST | 📋 | Medium | Gh0s777tt | 4 h | audit `C-15`, `G-19` |
| M-6 | **Resolve the semantics of `debug`, `memory`, `irq`, `serio`, `sys` for unprivileged users** and drop whatever is unnecessary | 📋 | **High** | Gh0s777tt | 2 d | audit `C-21` |
| M-7 | **`linked_list_allocator` ≥ 0.10.2** — `RUSTSEC-2022-0063`; none of its three paths is reachable in this usage, so this is debt, not an exploit | 📋 | Medium | Gh0s777tt | 2 h | audit `C-16` |
| M-8 | **`V2-MS04`, `V2-MS06`–`V2-MS09`** — remaining shim-review preparation items | 📋 | Medium | Gh0s777tt | — | `ADR-0006` |
| M-9 | **Mirror-head parity check** — nothing compares GitLab and GitHub heads; one live divergence already exists (`eos-pkg-aarch64`, disjoint histories) | 📋 | Medium | Gh0s777tt | 4 h | audit `00 §5.2` |

## Long term (6–12+ months)

| # | Item | Status | Priority | Owner | Traces to |
|---|---|---|---|---|---|
| L-1 | **Atomic updates with rollback** — the single largest gap against Silverblue, NixOS and GrapheneOS | 📋 | **High** | Gh0s777tt | audit `04 §4` |
| L-2 | **Wi-Fi** — no wireless driver ships; a desktop system notices immediately | 📋 | **High** | Gh0s777tt | audit `02 §6` |
| L-3 | **Reproducible builds** — five measured obstacles, from unpinned apt to embedded timestamps | 📋 | Medium | Gh0s777tt | audit `A §2.1` |
| L-4 | **Backup tooling** | 📋 | Medium | — | audit `02 §3` |
| L-5 | **`V2-MS10`/`V2-MS11`** — legal entity, EV certificate, shim chainload. Non-technical blockers first | 📋 | Low | operator | `ADR-0006` |
| L-6 | **Bluetooth, NVMe, non-Intel GPU drivers** | 📋 | Medium | — | audit `02 §6` |
| L-7 | **OpenSSF Scorecard registration** | 📋 | Low | operator | audit `C` checklist |

---

## Security roadmap

Derived directly from [`docs/audit/03-security-audit-2026-08-30.md`](docs/audit/03-security-audit-2026-08-30.md).
The audit's own severities are carried over unchanged, including the two places where it argues a
finding **down** rather than up.

### Supply chain

| Item | Status | Priority | Finding |
|---|---|---|---|
| Pin the upstream package key; stop trusting a key fetched from the host that serves the packages | 📋 | **High** | `C-1` |
| `blake3` for `mpc`; unpinned tarball becomes a hard error | 📋 | **High** | `C-1b` |
| Verify `blake3` independently of `is_deps`; derive the published identifier from the computed hash | 📋 | **High** | `C-1c` |
| Build a current `git`; stop shipping a 2017 binary | 📋 | **High** | `C-8` |
| Bump `eos-pkgutils` for `rustls-webpki` / `ring` / `rand` | 📋 | **High** | `C-3` |
| `osv-scanner` in CI and pre-push | 📋 | Medium | `C-13` |
| SBOM per tag, committed | 📋 | Medium | `C-14` |
| Pin apt versions; make the build container reproducible | 📋 | Medium | `C-17` |

### Boot and update chain

| Item | Status | Priority | Finding |
|---|---|---|---|
| Boot verification fails **closed**; building without a key requires an explicit variable | 📋 | **High** | `C-2` |
| Publish the x86_64 channel so an installed system can receive fixes | 📋 | **High** | `C-4` |
| Republish the aarch64 index carrying `serial`/`expires` | 📋 | Medium | `C-12` |
| Atomic updates with rollback | 📋 | **High** | `L-1` |

### Runtime and privilege boundaries

| Item | Status | Priority | Finding |
|---|---|---|---|
| Application sandboxing — per-process scheme sets | 📋 | **High** | `C-5` |
| Persistent audit log | 📋 | **High** | `C-9` |
| Packet filtering, or `sshd` off by default | 📋 | **High** | `C-10` |
| Settle `debug`/`memory`/`irq`/`serio`/`sys` for unprivileged users | 📋 | **High** | `C-21` |
| `linked_list_allocator` ≥ 0.10.2 — debt, **not** a reachable exploit | 📋 | Medium | `C-16` |

### Process and governance

| Item | Status | Priority | Finding |
|---|---|---|---|
| Block direct pushes to `main` so the existing pipeline gate applies | 📋 | **High** | `C-6` |
| Restore CI capacity — every gate has been dark since 2026-08-28 | 📋 | **High** | `C-7` |
| Move signing off the build machine | 📋 | Medium | `C-11` |
| Break-glass account or recovery procedure | 📋 | **High** | `C-18` |
| Gitleaks allowlist entry with justification | 📋 | Low | `C-19` |
| Enforce commit signing | 📋 | Low | `C-20` |
| SAST | 📋 | Medium | `C-15` |

### Already delivered

| Item | Status | Evidence |
|---|---|---|
| Verified boot chain with domain separation, fail-closed on a missing signature | ✅ | `U-212` |
| Hybrid ed25519 + ML-DSA-65 index signature, verified against the live published index | ✅ | `U-198`, `U-224` |
| blake3 enforced on installed package bytes on every path | ✅ | `U-223` |
| Rollback and freeze counters in the index | ✅ | `U-223` |
| Index and package keys pinned in the image | ✅ | `U-197`, `U-224` |
| Secure Boot signing with SBAT stamped before signature | ✅ | `U-206`–`U-208`, `U-218` |
| Raw IP sockets removed from unprivileged users | ✅ | `U-144` |
| Forced password on first boot, both login paths | ✅ | `U-076`–`U-079` |
| argon2id password hashing | ✅ | verified `U-224` |
| Kernel `Iopl` requires root | ✅ | `U-219` |

---

## Epic: installer, installation wizard and live updates

Three linked epics. Dependencies are stated because the order is the constraint: the update
mechanism is useless without a published channel, and a wizard that offers encryption is only
meaningful if the installer can actually apply it.

> The referenced "PROMPT 5" specification was not available when this roadmap was written. These
> epics were therefore derived from the shipped installer, the audit findings and the existing
> milestone registry. **They should be reconciled against that specification before work starts.**

### Epic A — OS installer

**Today:** `redox_installer`, `redox_installer_tui` and `redox_installer_gui` ship in the image; a
full partition → install → reboot → login cycle is proven (`U-176`); AES-XTS is offered at install.

| # | Sub-task | Status | Priority | Depends on |
|---|---|---|---|---|
| A-1 | Full-disk encryption **on by default**, with an explicit opt-out | 📋 | High | — |
| A-2 | Verify the KDF used to derive the AES-XTS key from the passphrase — currently unaudited | 📋 | **High** | — |
| A-3 | Post-install integrity check: confirm the installed system's kernel and initfs verify against the pinned boot key before first reboot | 📋 | High | `V2-MS02` ✅ |
| A-4 | Install-time selection of the package channel, defaulting to the signed E-OS repository | 📋 | High | Epic C-1 |
| A-5 | Unattended install from an answer file, for CI and fleet use | 📋 | Low | A-1 |
| A-6 | Installer refuses to proceed when the image's own signature chain cannot be verified | 📋 | Medium | A-3 |

### Epic B — Installation wizard (first-run experience)

**Today:** the graphical greeter and the text login both force a password on first boot
(`U-076`–`U-079`); `eos-welcome` prints a quick-start.

| # | Sub-task | Status | Priority | Depends on |
|---|---|---|---|---|
| B-1 | Timezone and locale selection at first run — today `/etc/tz-offset` is baked at build time | 📋 | Medium | — |
| B-2 | Network configuration in the wizard, reusing the `eos-control` network pane | 📋 | Medium | — |
| B-3 | Offer to enable the package channel and show which key will be trusted | 📋 | High | Epic C-1 |
| B-4 | Present the security posture honestly at first run: what is verified, what is not | 📋 | Medium | audit `03` |
| B-5 | Optional creation of a second administrative account — mitigates the break-glass gap on the device side | 📋 | Low | — |

### Epic C — Live system updates

**Today:** the mechanism is complete and **switched off**. `pkg` enforces the signed index, blake3
on bytes, rollback and freeze counters — and both entries in `/etc/pkg.d/` are commented out, so an
installed x86_64 system cannot update at all.

| # | Sub-task | Status | Priority | Depends on |
|---|---|---|---|---|
| C-1 | **Publish the x86_64 repository and enable `50_eos`** | 📋 | **High** | S-10 |
| C-2 | Republish aarch64 with `serial`/`expires` | 📋 | Medium | S-11 |
| C-3 | Scheduled update check with a user-visible notification, via `eos-notifyd` | 📋 | Medium | C-1 |
| C-4 | **Atomic apply with rollback** — currently `pkg` mutates the live system in place | 📋 | **High** | C-1, L-1 |
| C-5 | Staged download and verification before any file is replaced | 📋 | High | C-4 |
| C-6 | Update path for the bootloader and kernel that preserves the signature chain | 📋 | **High** | `V2-MS02` ✅, C-4 |
| C-7 | Offline update from removable media, signature-verified | 📋 | Low | C-5 |

**Critical path:** `C-1 → C-4 → C-6`. Nothing else in Epic C matters until a channel exists.

---

## Dropped

| Item | Status | Reason |
|---|---|---|
| Antivirus / malware scanner | ❌ | No third-party binary ecosystem to scan. File-integrity monitoring in `eos-control` addresses the actual risk; a signature scanner would be theatre. Audit `02 §3` |
| SELinux/AppArmor-style MAC | ❌ | Architecturally wrong for a microkernel. The scheme allowlist is the native equivalent; effort belongs in per-process scopes (`M-1`), not in porting an LSM. Audit `02 §4` |
| `orbterm` in the desktop image | ❌ | Superseded by `cosmic-term`. Explicitly excluded in `config/desktop.toml:26` |
| `eos-guard` and `eos-sysmon` as separate shipped applications | ❌ | Consolidated into `eos-control` (`U-095`). The repositories remain as history |
| Global `REPO_BINARY=0` | ❌ | Would compile third-party ports for hours with no security gain. See `ADR-0002`. **Revisit for `git` specifically** (`S-16`) |
| DAST | ❌ | Not meaningful for an operating system image |

---

## Vision

E-OS is a **Redox distribution with a real chain of trust**. That is the whole claim, and it is
deliberately narrower than the projects it gets compared to.

What that means concretely, and what the audit says about each:

- **A boot chain that refuses unsigned code** — done, with domain separation. Keep it fail-closed.
- **A package channel nobody can quietly replace** — the cryptography is done and better than most
  (hybrid post-quantum). What is missing is that it is switched on.
- **A microkernel where a driver fault is not a kernel fault** — inherited from Redox and real:
  16 drivers run as ordinary processes.
- **Honest documentation** — the audit found this project's own README claiming a key did not exist
  when it did, and claiming two applications shipped when they did not. The remedy is a gate that
  checks a marker's *value*, not its presence.

Where E-OS is genuinely ahead: a Rust microkernel with isolated drivers, and a post-quantum signed
package index. No comparable project has either.

Where it is behind, and should say so: no application isolation, no atomic updates, no published
update channel on x86_64, and an ecosystem of 65 packages against tens of thousands. E-OS should
not position itself against Tails, Qubes or GrapheneOS — it does not do what they do. The honest
comparison is with upstream Redox, and there it is meaningfully ahead on trust.

---

## Retired documents

Listed for approval before removal — **nothing has been deleted**.

| Document | Size | Proposal | Reason |
|---|---|---|---|
| `ROADMAP-v2.md` | 57 kB | **merge into this file, then archive** | Its content is carried here: `V2-MS*` milestones appear under Delivered and Mid term, the `R-*` registry items that remain open appear as traced entries. Keeping two roadmaps is what created the divergence the audit found |
| `docs/architecture/overview.md` | 3.9 kB | **merge into `ARCHITECTURE.md`** | Two architecture documents with overlapping scope, mutually cross-linked but with no statement of which is the entry point. Audit `00 §6.4` |
| `EOS_BUILD_STATE.md` | 3.3 kB | **archive** | A checkpoint record from 2026-06-06, superseded by the audit reports |
| `docs/archive/plan.md`, `docs/archive/hardware-plan.md` | — | **review** | Overlap with this roadmap; may contain hardware detail worth keeping |
| `docs/archive/roadmap-connectivity.md` | — | **review** | Predates this roadmap's networking items |
| `docs/archive/reality-ledger.md` | — | **review** | Superseded in function by `docs/audit/` |

> `ROADMAP.md` v1 was already archived into `ROADMAP-v2.md` on 2026-08-29 (`U-211`). This rebuild
> reverses that naming: `ROADMAP.md` is the live roadmap again, under its conventional name.
