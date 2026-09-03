# Summary

[Introduction](getting-started/index.md)
[Ecosystem components](architecture/ecosystem.md)

# Using E-OS

- [A visual tour (screenshots)](guides/screenshots.md)
- [Install](getting-started/install.md)
- [Packages](reference/packages.md)
- [Forks & vendored components](architecture/forks.md)
- [Architecture](architecture/overview.md)
  - [Diagrams](architecture/README.md)
    - [Repository topology](architecture/repository-topology.md)
    - [Build path](architecture/build-path.md)
- [Hardware support](reference/hardware-matrix.md)
- [Hardware bring-up (aarch64)](guides/hardware-bringup.md)
- [Compatibility](reference/compatibility.md)
- [Known issues](reference/known-issues.md)
- [FAQ](getting-started/faq.md)

# Building

- [Build from source](getting-started/building.md)
- [Troubleshooting](getting-started/build-troubleshooting.md)
- [Creating an E-OS app](guides/creating-an-eos-app.md)
- [CI/CD & automation](operations/ci.md)
- [Tokeny — wszystko za jednym posiedzeniem](reference/keys-and-tokens.md)
- [Maintenance & operations](operations/maintenance.md)

# Stability

- [Stability policy](reference/stability.md)
- [Test coverage (generated)](reference/coverage.md)
- [Security coverage (generated)](reference/security-coverage.md)
- [Semantic-versioning decisions (2026-08-30)](reference/semver-decisions-2026-08-30.md)
- [Third-party licences](reference/third-party-licenses.md)

# Security

- [Security guide](security/index.md)
- [Threat model](security/threat-model.md)
- [Hardening guide](security/hardening.md)
- [Incident response](security/incident-response.md)
- [GitHub configuration](security/github-configuration.md)
- [Disk encryption](guides/encryption.md)
- [Decision records (ADR)](adr/README.md)
  - [Template](adr/0000-template.md)
  - [ADR-0001 GitLab as source of truth](adr/0001-gitlab-as-source-of-truth.md)
  - [ADR-0002 Build forks from source](adr/0002-build-from-forks-not-upstream-binaries.md)
  - [ADR-0003 Vendored code stays upstream-shaped](adr/0003-vendored-code-keeps-upstream-form.md)
  - [ADR-0004 Hybrid manifest signature](adr/0004-hybrid-manifest-signature.md)
  - [ADR-0005 Secure Boot bez Microsoftu](adr/0005-secure-boot-without-microsoft.md)
  - [ADR-0006 Ścieżka do weryfikacji Microsoftu](adr/0006-path-to-microsoft-verification.md)
  - [ADR-0007 Bootloader and install medium](adr/0007-bootloader-and-install-medium.md)
  - [ADR-0008 Filesystem and partition layout](adr/0008-filesystem-and-partition-layout.md)
  - [ADR-0009 System update mechanism](adr/0009-system-update-mechanism.md)
  - [ADR-0010 Encryption stack](adr/0010-encryption-stack.md)
  - [ADR-0011 Installer wizard architecture](adr/0011-installer-wizard-architecture.md)
- [RFC-0001 A hypervisor interface in the Redox kernel (draft, not submitted)](rfc/0001-hypervisor-in-redox.md)

# Design & specifications

- [Desktop environment — Crimson](architecture/desktop-environment.md)
- [Installer](architecture/installer.md)
- [Installer wizard](architecture/installer-wizard.md)
- [Installer profiles](architecture/installer-profiles.md)
- [System updates](architecture/system-updates.md)
- [Update system](architecture/update-system.md)
- [Driver manager](architecture/driver-manager.md)
- [xhcid non-blocking transfers](architecture/xhcid-nonblocking-transfers.md)
- [NetSurf: PIE + host-toolchain (R-D06)](architecture/netsurf-pie.md)
- [eos-power: privileged reboot/shutdown (R-D11)](architecture/eos-power.md)
- [eos-control: Network settings pane (R-902)](architecture/eos-control-network.md)

# Roadmap & status

- [Reality ledger — done vs claimed](archive/reality-ledger.md)
- [Upstream reuse analysis](archive/upstream-reuse-analysis.md)

# Audits

- [Audit 2026-07-13 (23-agent grounded audit)](audit/AUDIT-2026-07-13.md)
- [Audit 2026-08-14 (ecosystem, docs, secrets, supply chain)](audit/AUDIT-2026-08-14.md)

# Upstream (Redox OS)

- [Redox README](reference/upstream-redox-readme.md)
- [Redox contributing](reference/upstream-redox-contributing.md)
