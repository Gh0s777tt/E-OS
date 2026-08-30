# 🔐 Security Policy

E-OS takes security seriously — it's an operating system. Thank you for helping
keep it and its users safe.

## 📦 Supported versions

| Version | Supported |
|---------|:---------:|
| `0.1.x` (Genesis) | ✅ |
| `main` (rolling) | ✅ latest fixes |
| `lts/0.1` (LTS line) | ✅ extended-support backports |
| `eos-base` (checkpoint) | ✅ |
| Legacy 2019 mirror (`master`, `0.4.1`) | ❌ archived, unsupported |

Because E-OS is **pre-1.0 (alpha)**, `main` carries the latest security fixes; the
**`lts/0.1`** branch tracks the 0.1 “Genesis” line and receives security
**backports** for an extended window, so a deployment can pin to a stable line
instead of rolling `main`.

## 🚨 Reporting a vulnerability

**Please do _not_ open a public issue, PR, or discussion for security bugs.**

Report privately via one of:

1. **GitHub Security Advisories** — *Security → Report a vulnerability*
   (preferred): <https://github.com/Gh0s777tt/E-OS/security/advisories/new>
2. **Email** the maintainer: `dzierzawskii98.dam@gmail.com`
   (subject prefix `[E-OS SECURITY]`; PGP key on request).

Please include: affected component/commit, impact, reproduction steps, and any
PoC. We aim to:

| Stage | Target |
|-------|--------|
| Acknowledge report | ≤ 72 h |
| Initial assessment | ≤ 7 days |
| Fix / mitigation plan | ≤ 30 days (severity-dependent) |
| Coordinated disclosure | by mutual agreement |

We support **coordinated disclosure** and will credit reporters (opt-in).

## 🎯 Scope

**In scope:** the E-OS kernel, relibc, RedoxFS, drivers, build/cookbook tooling,
release artifacts, and this repository's CI/CD.

**Upstream:** vulnerabilities inherited from **Redox OS** or third-party crates
should also be reported to the relevant upstream. We will help coordinate.

**Out of scope:** issues only affecting the archived 2019 mirror; volumetric DoS;
social engineering; findings without a security impact.

## 🧭 Threat model, hardening & encryption

E-OS's OS-level security posture is documented in:

- **[Threat model](docs/threat-model.md)** — assets, trust boundaries, adversaries,
  and the mitigations the microkernel + capability-scheme design provides (with
  honest non-goals for a pre-1.0 system).
- **[Hardening guide](docs/hardening.md)** — a practical, impact-ordered checklist
  (change default credentials, encrypt the disk, minimize packages, verify downloads).
- **[Disk encryption](docs/encryption.md)** — RedoxFS **AES-XTS-128** full-disk
  encryption: installing, building and booting an encrypted E-OS root.

## 🛡️ How we harden this repository

CI is defined in **two** places, and neither is currently doing its job unaided.
**GitLab** (`.gitlab-ci.yml`) is the authoritative pipeline, but every job there has
failed in ~0 s with `ci_quota_exceeded` since 2026-08-28. **GitHub Actions**
(`.github/workflows/`) was added as the remediation — a public repository has no minute
cap — but Actions do not execute on this account today: a minimal `on: push` workflow
pushed straight to github.com produces no run at all. Turning that back on is step 0 of
[docs/security/github-configuration.md](docs/security/github-configuration.md).
Until one of the two is running, treat every gate below as *written, not enforced*.

- 🔑 **gitleaks** scans the **whole history** on GitLab CI (`secret-scan`), and
  **cargo-deny** checks RustSec advisories / licenses / sources on every merge
  request. GitHub secret-scanning alerts may be enabled as a mirror-side notice.
- 🤖 **Renovate** (GitLab, replaced Dependabot) keeps dependencies patched;
  optional GitLab SAST/Dependency-Scanning templates (see [docs/ci.md](docs/ci.md)).
- 👮 **Branch protection** on the default branch; **CODEOWNERS** review required.
- ✍️ **Signed commits** encouraged. Releases publish **SHA256SUMS** + a CycloneDX
  **SBOM**; the checksums are **minisign-signed** by `scripts/make-release.sh` (the
  key is user-held, off-repo). The package `repo.toml` manifest is **signed at
  publish time** with a hybrid **ed25519 + ML-DSA-65** signature
  (`tools/eos-repo-sign`; since `U-120` an unsigned publish is a hard failure
  unless `EOS_ALLOW_UNSIGNED=1` is given explicitly).
  ⚠️ **The client half is built but has no trust anchor.** `pkg-lib` *does*
  verify the manifest — `manifest_sig::verify_manifest_ed25519`, called from
  `verify_repo_manifest`, with tamper / wrong-key / malformed-signature tests
  (`eos-pkgutils@14505ecd`, the pinned rev). It is inert for exactly one reason:
  **no public key is pinned in any image**, because `keys/eos-repo-sign.pub.toml`
  has never been generated. With no key the client prints a loud warning and
  proceeds (per-package pkgar ed25519 stays enforced); **the moment a key is
  pinned, a missing or invalid `repo.toml.sig` becomes a hard error.** So until
  `R-702` bakes the key in, treat the *index* as unauthenticated on the client —
  but the missing piece is one file, not a subsystem.
- ⚖️ **AGPL-3.0** — modifications, including networked use, must be shared.

> **Zaktualizowane (`U-201`).** Klucz podpisujący repozytorium **istnieje od `U-196`**: połowa publiczna to `keys/eos-repo-sign.pub.toml`, przypięta w `config/{aarch64,x86_64}/eos.toml` i **zmierzona w działającym obrazie** pod `/etc/pkg/eos-repo-sign.pub.toml` (4075 B, bajt w bajt, `U-197`). Sekret jest poza repozytorium, na dysku wewnętrznym, z trybem `0600`. Zdanie powyżej opisuje stan sprzed tej zmiany.


See [docs/security.md](docs/security.md) for the contributor security guide.
