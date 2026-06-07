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

- 🔑 **Secret scanning + push protection** and **gitleaks** in CI — credentials
  never land in history.
- 🤖 **Dependabot** (dependencies) and **CodeQL** (code scanning).
- 👮 **Branch protection** on the default branch; **CODEOWNERS** review required.
- ✍️ **Signed commits** encouraged; releases publish **SHA256SUMS** + a CycloneDX
  **SBOM**, with the checksums **minisign-signed** in CI when a key is configured
  (see ROADMAP `R-301`/`R-302`).
- ⚖️ **AGPL-3.0** — modifications, including networked use, must be shared.

See [docs/security.md](docs/security.md) for the contributor security guide.
