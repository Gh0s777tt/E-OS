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

CI runs on **GitLab** (GitHub Actions is disabled account-wide, so it is *not* used).

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
  ⚠️ **The client half does not exist yet.** No E-OS public key is pinned in any
  image — `keys/eos-repo-sign.pub.toml` has never been generated or committed —
  and `pkg-lib` has no `verify_manifest()`, so **nothing on a running system
  checks that signature**. Until `R-702` (pin the key) and `R-703` (verify it)
  ship, treat the package channel as **unauthenticated on the client**.
- ⚖️ **AGPL-3.0** — modifications, including networked use, must be shared.

See [docs/security.md](docs/security.md) for the contributor security guide.
