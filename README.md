<!-- SYNC: v0.2.0 · Unreleased U-230 · 2026-09-12 — keep this file in step with CHANGELOG.md and ROADMAP.md.
     NOTE: ci-integrity.sh check 3 verifies that this marker EXISTS, not that its value is current.
     Keeping it accurate is a human obligation until that gate is tightened (see ROADMAP, P0). -->

`[en]` · [`[pl]`](README.pl.md)

# E-OS

A hardened downstream distribution of [Redox OS](https://www.redox-os.org) — a Unix-like operating
system with a microkernel written in Rust, packaged with a verified boot chain, a post-quantum
signed package index, and a curated desktop.

[![pipeline](https://gitlab.com/e-os/e-os/badges/main/pipeline.svg)](https://gitlab.com/e-os/e-os/-/pipelines)
[![coverage](https://gitlab.com/e-os/e-os/badges/main/coverage.svg)](https://gitlab.com/e-os/e-os/-/pipelines)
[![tag](https://img.shields.io/github/v/tag/Gh0s777tt/E-OS)](https://github.com/Gh0s777tt/E-OS/tags)
[![license](https://img.shields.io/badge/license-AGPL--3.0--or--later-blue)](LICENSE)

```
─── state ─────────────────────────────────── measured 2026-09-12 ───
  register     done  91   partial  26   planned 137   idea 18
               ████████░░░░░░░░░░░░░░░░  33.2% of 274 tracked rows
  gate         scripts/verify.sh   20 stages   20 PASS   0 FAIL
  tests        31 functions · 16 on E-OS-owned code · 661 lines
  mutation     60.0%  (floor 58)      coverage  55.2%  (floor 38)
  pins         ok=30  drift=0  non-allowlisted=0  split-pin=0
  packages     aarch64  78 published        x86_64  none yet  (C-4)
  release      v0.2.0 tagged · no Release object on either host
────────────────────────────────────────────────────────────────────
```

> **On the badges.** The pipeline badge reads **failed** and coverage reads **unknown**. Both are
> accurate, and neither is a code signal: the shared-runner quota exhausts intermittently, so 9 of the
> 10 jobs in a merge-request pipeline abort in ~0 s with `ci_quota_exceeded` — never assigned a runner,
> never started. The self-hosted `eos-heavy` tier spends no shared minutes and is unaffected; it is
> what runs `local-gates`, and `local-gates` is what every merge waits for. An OpenSSF Scorecard badge
> is deliberately absent (the project is not registered, the badge would render `invalid repo path`),
> and a release badge is absent because tags exist while Release objects do not.

---

## Table of contents

- [What this repository is](#what-this-repository-is) · [The repository graph](#the-repository-graph)
- [Features](#features) — [Shipped](#shipped) · [Planned](#planned) · [Deliberately absent](#deliberately-absent)
- [Quick start](#quick-start) — [Do the gates work?](#do-the-gates-work)
- [Usage](#usage)
- [Requirements and supported platforms](#requirements-and-supported-platforms) — [Build host](#build-host) · [Build targets](#build-targets) · [Runtime hardware](#runtime-hardware)
- [Documentation](#documentation) · [Project documents](#project-documents)
- [Architecture](#architecture) · [Security](#security) — [Threat model in brief](#threat-model-in-brief)
- [License, authors, acknowledgements](#license-authors-acknowledgements)

---

## What this repository is

This repository is the **orchestrator** of the E-OS ecosystem. It contains no operating-system
source code of its own. What it holds is:

| Directory | Contents |
|---|---|
| `recipes/` | build recipes — which upstream or forked source becomes which package |
| `config/` | image definitions per architecture and variant (`eos.toml`, `desktop.toml`, …) |
| `src/` | the vendored upstream `redox_cookbook` build engine (binaries `repo`, `repo_builder`, `cookbook_redoxer`) |
| `tools/eos-repo-sign` | E-OS-authored: hybrid ed25519 + ML-DSA-65 signing of the package index |
| `scripts/` | build, signing, publication and verification automation — 75 tracked scripts |
| `mk/`, `Makefile` | the GNU Make build system |
| `podman/` | container definitions for the hermetic build environment |
| `docs/` | the documentation set, including audit reports |

The operating system itself lives in **36 sibling repositories**, pinned by revision in
[`repos.toml`](repos.toml). Nothing is fetched by a floating branch: every pinned revision is
verified against the published branch head by `scripts/eos-repos.sh pins --strict`.

### The repository graph

```mermaid
graph TD
  EOS["<b>E-OS</b><br/>orchestrator · recipes · config<br/>cookbook · eos-repo-sign"]

  subgraph CORE["Boot and core — forks with E-OS patches"]
    K[eos-kernel]:::c
    B[eos-base]:::c
    BL[eos-bootloader]:::c
    R[eos-relibc]:::c
    FS[eos-redoxfs]:::c
    UU[eos-userutils]:::c
    IN[eos-installer]:::c
  end

  subgraph PKG["Package chain"]
    PU[eos-pkgutils]:::c
    PA[eos-pkgar]:::c
    PX[(eos-pkg-x86_64)]:::d
    PAA[(eos-pkg-aarch64)]:::d
  end

  subgraph GUI["Graphical stack"]
    OB[eos-orbital]:::c
    OU[eos-orbutils]:::c
    OD[eos-orbdata]:::c
    OC[eos-orbclient]:::b
    OT[eos-orbterm]:::b
    LO[eos-liborbital]:::b
  end

  subgraph APPS["First-party applications (eos-guard, eos-sysmon: repositories, not shipped as apps — PR-002)"]
    UI[eos-ui]:::a
    CTL[eos-control]:::a
    NTS[eos-notes]:::a
    GRD[eos-guard]:::a
    SYS[eos-sysmon]:::a
  end

  subgraph MIRR["Read-only vendored mirrors"]
    M["eos-coreutils · eos-extrautils · eos-ion<br/>eos-netdb · eos-netutils · eos-redox-fatfs<br/>eos-redoxer"]:::b
  end

  EOS -->|pins + builds from source| CORE
  EOS -->|pins + builds from source| PKG
  EOS -->|pins| GUI
  EOS -->|pins| APPS
  EOS -->|pins| MIRR
  EOS -.->|publishes signed index| PX
  EOS -.->|publishes signed index| PAA
  CTL --> UI
  NTS --> UI
  GRD --> UI
  SYS --> UI

  classDef a fill:#8b0000,stroke:#e50914,color:#fff
  classDef b fill:#2b2b2b,stroke:#777,color:#ddd
  classDef c fill:#4a1010,stroke:#c0392b,color:#fff
  classDef d fill:#1a1a1a,stroke:#555,color:#aaa
```

**Repository types**, enforced by `scripts/eos-mirror-drift.sh` and `ci-integrity.sh`:

```
  A  E-OS-authored components ............................. 12
  B  read-only vendored mirrors — never hand-edited ....... 10
  C  forks carrying E-OS patches, kept rebasable .......... 13
  D  published package artefacts ...........................2
                                                          ----
     blocks in repos.toml .................................37   (36 siblings + this repository)
```

---

## Features

Everything in the **Shipped** table was verified on 2026-08-30 by mounting the built image
(`eos-x86_64-harddrive.img`) and reading its contents — not from documentation. Method and evidence:
[`docs/audit/02-feature-inventory-2026-08-30.md`](docs/audit/02-feature-inventory-2026-08-30.md).

### Shipped

| Area | What is in the image |
|---|---|
| **Verified boot chain** | The bootloader authenticates the kernel and initfs with ed25519 over `SHA-512(role ‖ len_le ‖ data)` **before** the magic-byte check and before any byte is used. A missing signature or a zero key refuses to boot. Domain separation means a signed initfs cannot verify as a kernel. |
| **Post-quantum signed package index** | `repo.toml` is signed with a **hybrid ed25519 + ML-DSA-65 (FIPS 204)** signature. Verified against the live published aarch64 index (78 packages): both halves pass; a single flipped byte makes both refuse. |
| **Pinned trust anchors in the image** | `/etc/pkg/eos-repo-sign.pub.toml` (index key) and `/etc/pkg/packages.toml` → `[pubkeys.local]` (package key), byte-identical to the committed public halves. |
| **Package bytes enforced against the signed index** | blake3 from the authenticated manifest is checked against the bytes about to be extracted, on every install path including `pkg install`. Rollback and freeze protection via `serial` and `expires`. |
| **Secure Boot** | Both UEFI bootloaders carry SBAT and are Authenticode-signed; SBAT is stamped **before** signing, because Authenticode covers the whole file. |
| **Desktop** | The Crimson desktop on the `orbital` display server: greeter, launcher, taskbar, tray, notifications, screenshot tool, animated wallpaper, launcher search. |
| **Applications** | `cosmic-edit`, `cosmic-files`, `cosmic-term`, NetSurf 3.11 — **shipped as the upstream prebuilt, not PIE** ([#28](https://gitlab.com/e-os/e-os/-/issues/28), measured 2026-09-02: `readelf` Type `EXEC` at `0x400000`, no `about:welcome` patch, foreign `commit_identifier`); the recipe builds it from source as PIE, the artefact in the image is not that build. Plus **eos-notes** (Slint + SQLite WAL) and **eos-control** — system overview, processes and capabilities, security, storage, power, sound, and a live network pane that reads the running `netcfg:` stack and applies static IPv4 through a privileged `eos-netcfg` shim, never running the GUI as root. |
| **Shells and tooling** | `ion` (default), `bash`, `nushell`; `vim`, `nano`, `kibi`, `ripgrep`, `git`, `curl`, `wget`, OpenSSH 9.8, OpenSSL 3.5.3. |
| **Full-disk encryption** | RedoxFS AES-XTS, offered by the installer. Hardware-accelerated on aarch64 via ARMv8 Crypto Extensions, software path on x86_64, gated by a kernel-exported CPU-feature channel. |
| **Forced first-boot password** | Both the text login and the graphical greeter refuse to proceed while the account has no password. |
| **Per-user kernel-scheme allowlist** | `/etc/login_schemes.toml` grants `root` everything and the unprivileged user an explicit 25-scheme list. Raw IP sockets (`ip`) are **removed** from that list. |
| **User-space drivers** | 16 drivers as ordinary processes — a driver fault does not take down the kernel. Includes a Rust **USB RNDIS** network driver (`usbnetd`, full duplex, a complete DHCP handshake pcap-verified) and USB mass storage. |
| **RAID-1** | `raid1d`: write-both / read-fallback, degraded boot, resync of a re-added member, split-brain safety. |
| **Filesystem integrity and system monitoring** | Shipped as tabs inside **eos-control**, not as separate apps. `recipes/gui/eos-guard` and `recipes/gui/eos-sysmon` exist but neither is packaged into the image (`U-095` consolidated both into the control center). A booted E-OS has the functionality and not two extra binaries. |
| **Password hashing** | Two paths, measured 2026-09-02 ([#27](https://gitlab.com/e-os/e-os/-/issues/27)): passwords hashed **at image-build time** use argon2id (`m=19456, t=2, p=1`, `rust-argon2 3.0.0`); passwords set **in the running system** — `passwd`, first-boot enrolment, the `orblogin` greeter — go through `redox_users 0.4.6` → `rust-argon2 0.8.3`, whose default is **argon2i, `m=4096, t=3`**: 4.0 ms per guess against 14.1 ms, on one core. This row used to state only the stronger of the two. |

### Planned

| Item | Status | Tracked as |
|---|---|---|
| Published x86_64 package channel | 🟡 in progress | [ROADMAP](ROADMAP.md) · audit `C-4` · `R-701` |
| Application sandboxing (per-process scheme sets) | 🔴 planned | [ROADMAP](ROADMAP.md) · audit `C-5` |
| Persistent audit log | 🔴 planned | [ROADMAP](ROADMAP.md) · audit `C-9` |
| Packet filtering / firewall | 🔴 planned | [ROADMAP](ROADMAP.md) · audit `C-10` |
| Wi-Fi | 🔴 planned | [ROADMAP](ROADMAP.md) |
| Microsoft-signed shim path | 🔴 planned | [`docs/adr/0006-path-to-microsoft-verification.md`](docs/adr/0006-path-to-microsoft-verification.md) |

Status glyphs follow [`ROADMAP.md` §0.1](ROADMAP.md): ✅ done · 🟡 partial · 🔴 planned · 💡 idea.

### Deliberately absent

No antivirus, no VPN/Tor, no backup tool, no SELinux/AppArmor. The access-control model is the
per-user scheme allowlist above; file integrity monitoring lives inside `eos-control`.

Two of those four are **choices** and two are **gaps**, and earlier wording blurred them (caught by the
adversarial pass of the 2026-09-02 inventory): antivirus and MAC are refused with reasons
(`ROADMAP.md` §13; the antivirus answer in full is [§7.5.3](ROADMAP.md#753-the-antivirus-answer) — the
security product is **E-OS Guard**, integrity and permission monitoring, and the word "antivirus" is
not used until an on-access engine exists). Backup tooling and VPN/Tor are gaps the roadmap tracks as
`L-4` / `CS-002` (backup) and `R-616c` / `CS-006` (VPN, Tor as new subsystems). The inventory behind
this paragraph is [`docs/audit/02-feature-inventory-2026-08-30.md`](docs/audit/02-feature-inventory-2026-08-30.md) §3.

**Products beyond E-OS.** The Slint applications (`eos-notes`, `eos-control`, `eos-ui`) type-check on a
non-Redox host today (`cargo check` clean on macOS, measured 2026-09-03) but have no host window
backend yet; Windows and Linux builds, the four new products (spreadsheet, presentations, cloud drive,
app store) and the install-time on/off switch are `PR-*` rows in
[`ROADMAP.md` §7.5](ROADMAP.md#75-products--in-the-image-on-windows-and-linux-and-the-four-new-ones--pr-).

---

## Quick start

Every command below was executed on the reference host (Apple Silicon macOS + podman) and its real
output is shown.

```console
$ git clone https://gitlab.com/e-os/e-os.git && cd e-os
```

**Build an x86_64 image.** Use the script, not bare `make`: this project directory lives on exFAT,
which podman cannot bind-mount, so the build runs inside a podman volume. `make all` from the project
directory does not work here.

```console
$ bash scripts/eos-build.sh x86_64
==> export image + live ISO
    ~/eos-artifacts/eos-x86_64-harddrive.img          (1400 MiB)
    ~/eos-artifacts/eos-0.2.0-x86_64-installer.img    (1400 MiB)
Done.
```

The second file is the **installation medium** — the one you write to a USB stick. It used to be called
`eos-x86_64-live.iso`; `R-611a` renamed it to `eos-<version>-<arch>-installer.img`, and the name comes
from `make print-installer-medium` rather than being spelled out in each caller. Both are raw GPT images.

**Boot the image headlessly and assert it reaches userspace:**

```console
$ bash scripts/ci-boot-smoke.sh ~/eos-artifacts/eos-x86_64-harddrive.img 300 --arch x86_64
boot-smoke: x86_64, qemu pid 13690, up to 300s to reach login (TCG: 19s measured)…
boot-smoke: PASS — reached userspace login
```

Both architectures reach a login prompt (measured 2026-09-01). aarch64 was broken for part of August
and is fixed: the bootloader is now built without LTO on that target, because LTO merged callee stack
frames into their caller and the kernel-load path overran the firmware's ~124 KiB DXE stack.

**Install onto a second disk and boot the result** — the stronger claim, because booting a pre-built
image proves nothing about installing:

```console
$ bash scripts/ci-install-smoke.sh ~/eos-artifacts/eos-0.2.0-aarch64-installer.img 2400 --arch aarch64
install-smoke:   saw the installer refusing a name that matches no disk
install-smoke:   the target disk is byte-for-byte untouched by the refusal (0 blocks)
install-smoke: PASS — installed to a second disk and booted it to a login prompt
```

This passes on **aarch64** and, since 2026-09-02, on **x86_64** as well
([#6](https://gitlab.com/e-os/e-os/-/issues/6), [#24](https://gitlab.com/e-os/e-os/-/issues/24)).
Two separate causes had to go. The `getty` terminal-size probe was swallowing typed input — not, as
first supposed, a stray newline left in `login`. That alone still left the x86_64 run **intermittent**,
passing 2 runs out of 7, because a *second* getty on the same serial console answered the next line
typed with "Login incorrect"; with one getty per console it passes 5 of 5. Both causes were confirmed
the same way: put them back, and the harness fails again.

`EOS_SMOKE_FDE=1` runs the same harness against an **encrypted** install. Stage 2 then proves the
encryption in three steps, each of which can fail on its own: the bootloader must ask for the disk
password, a deliberately wrong password must not unlock the disk, and only then may the right one reach
`eos login:`. `EOS_SMOKE_FDE_NEGATIVE=1` is the negative control — it installs *without* encryption
while still running stage 2 in FDE mode, so the first step has to fail, and be seen to fail for the
right reason.

### Do the gates work?

On 2026-09-02 two multi-agent rounds read every gate in the repository — every script,
`.gitlab-ci.yml`, the GitHub Actions workflows, the git hooks, and `Makefile` with `mk/*.mk` — and
asked one question of each: *can this check fail?* 34 defects were confirmed and fixed, among them a
secret scan that failed **open** when `gitleaks` was absent, a release pipeline that signed without
ever verifying what it signed, and a Secure Boot check that reported success having examined no files.
Each fix carries a measurement in both directions; the register is
[`ROADMAP.md` §1.4](ROADMAP.md#14-gate-quality-audit-2026-09-02).

Three gates were added on 2026-09-03, each with a negative self-test, and each found something on its
first run: `eos-check-roadmap.py` (two ✅ rows with no evidence), `eos-check-assets.sh` (one
byte-identical screenshot under two names, 26 images no document cites) and `eos-check-summary.py`
(fourteen documentation pages that were never listed in the book). The hygiene ledger is
[`ROADMAP.md` §11.7](ROADMAP.md#117-repository-hygiene--what-left-the-tree-what-waits-for-the-owner-what-keeps-it-clean--rh-);
the rule that every kind of change has a named check is `CLAUDE.md` §5.11.

---

## Usage

**Verify every pinned revision against the published branch head:**

```console
$ bash scripts/eos-repos.sh pins --strict
eos-liborbital   | master       | 76ba2e79ac  | 76ba2e79ac  | OK(tip)
eos-redox-fatfs  | master       | 26caa09089  | 26caa09089  | OK(tip)
eos-redoxer      | master       | 974c1482c2  | 974c1482c2  | OK(tip)
---- pins ok=30 drift=0 (non-allowlisted=0) split-pin=0 ----
```

**Run the repository integrity gate** — the same checks CI runs. It prints 24 `ok:` lines and a
verdict; the excerpt below is **abridged**:

```console
$ bash scripts/ci-integrity.sh
  ok: README SYNC marker present
  ok: every unsafe in E-OS-owned Rust is justified
  ok: CRLF-pinned files keep their line endings
  ok: no image ships an active unauthenticated package source
  ok: no repo-signing secret material in tracked files
  ok: no fork source vendored into this repo
  …18 further ok: lines, 14 advisories…
integrity: PASS
```

**Run the whole local gate chain** — this is what every merge waits for:

```console
$ bash scripts/verify.sh
  total: 20 stages — 20 PASS · 0 FAIL · 0 SKIPPED (could not run) · 0 SKIPPED (--fast)
verify: PASS
```

**Sign and verify a repository index:**

```console
$ tools/eos-repo-sign/target/release/eos-repo-sign sign  <secret.toml> repo.toml
$ tools/eos-repo-sign/target/release/eos-repo-sign verify keys/eos-repo-sign.pub.toml repo.toml
ed25519 (classical):  OK
ml-dsa-65 (PQ):       OK
VERIFIED: repo.toml
```

Exit status is `0` on success and `1` on failure; a single flipped byte makes both algorithms report
`FAIL`.

---

## Requirements and supported platforms

### Build host

| | |
|---|---|
| **Operating system** | macOS (Apple Silicon, the reference host) or Linux |
| **Container runtime** | podman — the build is hermetic and runs inside `localhost/redox-base:latest` |
| **Toolchain** | Rust nightly pinned by [`rust-toolchain.toml`](rust-toolchain.toml); installed inside the container |
| **QEMU** | `qemu-system-x86_64` / `qemu-system-aarch64`, for boot-smoke and local runs |
| **Disk** | ~90 GB free. A full build tree with caches measures ~70 GB |
| **Filesystem caveat** | if the checkout is on exFAT, podman cannot bind-mount it; `scripts/eos-build.sh` handles this by building inside a podman volume |

### Build targets

| Target | Status |
|---|---|
| `x86_64-unknown-redox` | supported — image and installer medium, boot-verified under QEMU |
| `aarch64-unknown-redox` | supported — additionally the only architecture with a **published** package channel (78 packages) |
| `i586`, `riscv64gc` | inherited upstream configuration, **not built by E-OS** |

### Runtime hardware

Verified under QEMU. Hardware coverage is described in [`HARDWARE.md`](HARDWARE.md); the image carries
16 user-space drivers:

```
  ac97d      e1000d     ihdad      ihdgd      ixgbed     rtl8139d
  rtl8168d   sb16d      usbctl     usbhidd    usbhubd    usbnetd
  usbscsid   vboxd      virtio-netd           xhcid
```

**No Wi-Fi, Bluetooth, NVMe or non-Intel GPU driver ships today.**

---

## Documentation

The full documentation set lives in [`docs/`](docs/) and is published as an mdBook at
<https://e-os.gitlab.io/e-os/>.

| Area | Entry point |
|---|---|
| Getting started | [`docs/getting-started/index.md`](docs/getting-started/index.md) |
| Building | [`docs/getting-started/building.md`](docs/getting-started/building.md) · [`docs/getting-started/build-troubleshooting.md`](docs/getting-started/build-troubleshooting.md) |
| Installing | [`docs/getting-started/install.md`](docs/getting-started/install.md) |
| Architecture | [`docs/architecture/`](docs/architecture/) |
| Security | [`docs/security/index.md`](docs/security/index.md) · [`docs/security/hardening.md`](docs/security/hardening.md) · [`docs/security/threat-model.md`](docs/security/threat-model.md) |
| Packages | [`docs/reference/packages.md`](docs/reference/packages.md) |
| Decision records | [`docs/adr/`](docs/adr/) |
| Audit reports | [`docs/audit/`](docs/audit/) |

> The GitHub Pages copy of the documentation site is **not maintained** and currently returns 404.
> GitLab Pages is canonical.

## Project documents

| Document | Purpose |
|---|---|
| [`ROADMAP.md`](ROADMAP.md) | **the single plan** — delivered work, every open item ordered from the quickest to the heaviest (§3.0), the subject registers, and the six plans merged from `docs/archive/` (§17–§21) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | environment, branch strategy, commit format, PR checklist, release process |
| [`SECURITY.md`](SECURITY.md) | supported versions, private reporting, disclosure policy, scope |
| [`CHANGELOG.md`](CHANGELOG.md) | Keep a Changelog history grouped by release |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | components, boot flow, update flow, trust boundaries |
| [`CLAUDE.md`](CLAUDE.md) | working agreement and the mandatory verification protocol |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Contributor Covenant 2.1 |
| [`NOTICE`](NOTICE) · [`TRADEMARK.md`](TRADEMARK.md) | attribution and upstream trademark policy |

---

## Architecture

E-OS is a Redox downstream: a Rust microkernel with drivers, filesystems, the RAID layer and the
network stack running in **user space** as ordinary processes. Resources are addressed as **schemes** —
URL-like namespaces — and access is granted per user by an explicit allowlist.

```mermaid
graph LR
  FW[UEFI firmware] -->|Authenticode + SBAT| BL[bootloader.efi]
  BL -->|ed25519 over SHA-512<br/>role ‖ len ‖ data| K[kernel]
  BL -->|same, distinct role tag| IF[initfs]
  K --> DRV[user-space drivers]
  K --> FSD[redoxfs]
  DRV --> ORB[orbital display server]
  FSD --> ORB
  ORB --> APP[applications]
  style BL fill:#4a1010,stroke:#c0392b,color:#fff
  style K fill:#8b0000,stroke:#e50914,color:#fff
```

Full description, including the update and data flows: [`ARCHITECTURE.md`](ARCHITECTURE.md).

---

## Security

Report vulnerabilities privately — see [`SECURITY.md`](SECURITY.md) for the channels, the supported
version table, and the disclosure policy. **Please do not open a public issue for a security bug.**

### Threat model in brief

| Adversary | Position |
|---|---|
| Network attacker between device and repository | **Addressed** — hybrid signature, image-pinned key, blake3 enforced on package bytes, rollback/freeze counters |
| Whoever controls `static.redox-os.org` | **Partly addressed** — 30 of 65 packages are still prebuilt upstream binaries, but their signing key is now pinned in-tree (`keys/upstream-redox-pkg.pub.toml`) and written over whatever the sync fetches, so the key no longer comes from the serving host |
| Local unprivileged user | **Partly addressed** — no raw IP sockets; but the boundary is per-account, and there is no application sandbox |
| Device theft | **Addressed if enabled** — AES-XTS full-disk encryption is offered at install, not default |
| Build-machine compromise | **Not addressed** — signing keys live on the build host |

The complete model, with evidence for each row, is in
[`docs/audit/03-security-audit-2026-08-30.md`](docs/audit/03-security-audit-2026-08-30.md) §1.

---

## License, authors, acknowledgements

**License:** [AGPL-3.0-or-later](LICENSE). Files inherited from Redox OS remain under **MIT** — see
[`NOTICE`](NOTICE) and [`docs/reference/third-party-licenses.md`](docs/reference/third-party-licenses.md).

**Authors:** Damian (`Gh0s777tt`) and the E-OS contributors.

**Acknowledgements.** E-OS is a downstream distribution and does not claim to be a from-scratch
operating system. It stands on **Redox OS**, created by Jeremy Soller and the Redox community, and on
the Rust ecosystem. Upstream trademark policy is reproduced in [`TRADEMARK.md`](TRADEMARK.md). The
desktop applications `cosmic-edit`, `cosmic-files` and `cosmic-term` come from System76's COSMIC
project; the browser is **NetSurf**.

**Source of truth:** <https://gitlab.com/e-os/e-os>. The GitHub repository is a read-only mirror.
