---
title: Security policy
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Security policy

## Reporting a vulnerability

**Do not open a public issue for a security bug.**

Two private channels, both real and monitored:

1. **GitHub Security Advisories** — <https://github.com/Gh0s777tt/E-OS/security/advisories/new>
   (*Security → Report a vulnerability*). Preferred: it gives a private thread and a CVE path.
2. **Email** — `dzierzawskii98.dam@gmail.com`

> **PGP.** No PGP key is published for this project today. Do not encrypt to a key you find
> elsewhere claiming to be ours. Publishing one is on the roadmap; until then, use GitHub Security
> Advisories, which is end-to-end private without needing one.

### What to include

The affected component and version, what an attacker gains, and the smallest reproduction you have.
A boot-log excerpt or a `pkg` transcript is more useful than a description.

## Response commitments

Stated as targets, not as a contract — this is a **single-maintainer project** and that is relevant
information for anyone deciding how to disclose.

| Stage | Target |
|---|---|
| Acknowledgement of receipt | 72 hours |
| Initial assessment with a severity | 7 days |
| Fix or documented mitigation, CRITICAL/HIGH | 30 days |
| Fix or documented mitigation, MEDIUM/LOW | 90 days |
| Public disclosure | coordinated, by default 90 days after the report or on fix release, whichever is first |

If a deadline will be missed you will be told before it passes, with the reason.

## Supported versions

| Version | Status | Security fixes |
|---|---|---|
| `main` (unreleased) | active development | yes |
| `v0.2.0` | current tag, 2026-08-22 | yes |
| `lts/0.1` | long-term branch | yes, until superseded |
| `v0.1.0` | superseded | no |
| pre-`v0.1.0` | inherited Redox history | no — report upstream |

**A caveat that must be stated plainly:** the x86_64 image currently ships with **no active package
source** — both entries in `/etc/pkg.d/` are commented out. A fix released today cannot reach an
installed x86_64 system through the update mechanism. Tracked as `C-4`; see
[`ROADMAP.md`](ROADMAP.md) `S-10`.

## Scope

### In scope

- The E-OS kernel, bootloader, `relibc`, `redoxfs` and the drivers, as shipped in E-OS images
- The package chain: `pkg`, `pkgar`, index signing and verification, key pinning
- The boot chain: Secure Boot signing, SBAT, kernel and initfs verification
- The E-OS applications: `eos-control`, `eos-notes`, `eos-ui`, `eos-netcfg`, `eos-power`, `eos-notifyd`
- The build and publication tooling in this repository
- Privilege boundaries, including `/etc/login_schemes.toml`

### Out of scope

- **Upstream Redox defects** that E-OS merely inherits — report them to
  <https://gitlab.redox-os.org/redox-os>. If E-OS's configuration makes an upstream bug reachable
  when it otherwise would not be, that **is** in scope.
- **Third-party ports** (NetSurf, OpenSSL, `git`, `vim`, the COSMIC applications) — report upstream.
  Their presence in an outdated version in our image **is** in scope: see `C-8`, `git 2.13.1`.
- Findings that require physical access plus an unlocked, unencrypted disk, when full-disk
  encryption was available and not enabled.
- Denial of service by resource exhaustion from an already-privileged local account.
- Missing features that are documented as absent — no firewall, no sandbox, no audit log. These are
  **known gaps with roadmap entries**, not vulnerabilities. Reporting them is welcome as a design
  discussion, not as an advisory.

CI is defined in **two** places, and the shared half is unreliable.
**GitLab** (`.gitlab-ci.yml`) is the authoritative pipeline. Its **shared-runner** jobs fail in
~0 s with `ci_quota_exceeded` whenever the monthly minutes are gone — from 2026-08-28 to the
2026-09-01 reset, green for a day, then gone again. Its **self-hosted** jobs (`tags: [eos-heavy]`,
`needs: []`) spend no shared minutes and are not covered by that: on 2026-09-01 `build-image`
succeeded in 1299 s and `docs-pdf` in 50 s. **GitHub Actions**
(`.github/workflows/`) was added as the remediation — a public repository has no minute
cap — but Actions do not execute on this account today: a minimal `on: push` workflow
pushed straight to github.com produces no run at all. Turning that back on is step 0 of
[docs/security/github-configuration.md](docs/security/github-configuration.md).
Read the gates below accordingly: the ones the `eos-heavy` tier runs (image build, boot-smoke,
install-smoke) are **enforced**; the rest are *written, not enforced* whenever the shared
quota is out — which is most of the time. Check the quota before relying on a green pipeline.

## Known gaps

Published deliberately. A security policy that hides the gaps is worth less than none.

| Gap | Finding | Status |
|---|---|---|
| 30 of 65 image packages are upstream binaries whose signing key is fetched from the serving host | `C-1` | open |
| `mpc`, a compiler dependency, is fetched with no hash from a substituted mirror | `C-1b` | open |
| Boot verification is fail-open at build time when no key is present | `C-2` | open |
| `rustls-webpki 0.103.4` with six advisories ships inside `pkg` | `C-3` | open |
| No active update channel on x86_64 | `C-4` | open |
| No application sandbox — the browser holds the same schemes as the shell | `C-5` | open |
| No persistent audit log | `C-9` | open |
| No packet filtering, with `sshd` present | `C-10` | open |

Full evidence: [`docs/audit/03-security-audit-2026-08-30.md`](docs/audit/03-security-audit-2026-08-30.md).

## Hall of fame

No externally reported vulnerabilities to date. Researchers who report a valid issue will be
credited here by the name they choose, or anonymously on request. Credit is given for
**valid reports**, including ones we decide not to fix — the report is the contribution.

## Cryptography in use

| Purpose | Algorithm |
|---|---|
| Password hashing | argon2id (`m=19456, t=2, p=1`) |
| Package index signature | ed25519 **and** ML-DSA-65 (FIPS 204), hybrid |
| Per-package signature | ed25519 (pkgar) |
| Boot verification | ed25519 over SHA-512(role ‖ len_le ‖ data) |
| Release checksums | minisign |
| Full-disk encryption | AES-XTS |
| Content integrity | blake3 |

No MD5, SHA-1, RC4 or DES is used in any security role.
