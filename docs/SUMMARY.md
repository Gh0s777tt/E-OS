# Summary

[Introduction](getting-started.md)
[Ecosystem components](ecosystem.md)

# Using E-OS

- [A visual tour (screenshots)](screenshots.md)
- [Install](install.md)
- [Packages](packages.md)
- [Forks & vendored components](forks.md)
- [Architecture](architecture.md)
  - [Diagrams](architecture/README.md)
    - [Repository topology](architecture/topologia-repozytoriow.md)
    - [Build path](architecture/sciezka-budowania.md)
- [Hardware support](hardware-matrix.md)
- [Hardware bring-up (aarch64)](hardware-bringup.md)
- [Known issues](known-issues.md)
- [FAQ](faq.md)

# Building

- [Build from source](building.md)
- [Troubleshooting](build-troubleshooting.md)
- [Creating an E-OS app](creating-an-eos-app.md)
- [CI/CD & automation](ci.md)
- [Tokeny — wszystko za jednym posiedzeniem](tokeny.md)
- [Maintenance & operations](MAINTENANCE.md)

# Stability

- [Stability policy](stability.md)

# Security

- [Security guide](security.md)
- [Threat model](threat-model.md)
- [Decision records (ADR)](adr/README.md)
  - [Template](adr/0000-szablon.md)
  - [ADR-0001 GitLab as source of truth](adr/0001-gitlab-jako-zrodlo-prawdy.md)
  - [ADR-0002 Build forks from source](adr/0002-budowanie-z-forkow-nie-z-binarek-upstreamu.md)
  - [ADR-0003 Vendored code stays upstream-shaped](adr/0003-vendorowany-kod-zostaje-na-formie-upstreamu.md)
  - [ADR-0004 Hybrid manifest signature](adr/0004-hybrydowy-podpis-manifestu.md)
- [Hardening guide](hardening.md)
- [Disk encryption](encryption.md)

# Design & proposals

- [Desktop environment — Crimson](design-desktop-environment.md)
- [xhcid non-blocking transfers](design-xhcid-nonblocking-transfers.md)
- [NetSurf: PIE + host-toolchain (R-D06)](design-netsurf-pie.md)
- [eos-power: privileged reboot/shutdown (R-D11)](design-eos-power.md)
- [eos-control: Network settings pane (R-902)](design-eos-control-network.md)
- [Update system](update-system-design.md)
- [Driver manager](driver-manager-design.md)
- [Feature proposals](feature-proposals.md)
- [ACPI-off removal plan](acpi-off-removal-plan.md)

# Roadmap & status

- [The plan — editions, compartmentalisation, order](plan.md)

- [Hardware capabilities roadmap](hardware-capabilities-roadmap.md)
- [Connectivity roadmap](roadmap-connectivity.md)
- [Reality ledger — done vs claimed](reality-ledger.md)
- [Upstream reuse analysis](upstream-reuse-analysis.md)

# Audits

- [Audit 2026-07-13 (23-agent grounded audit)](audit/AUDIT-2026-07-13.md)
- [Audit 2026-08-14 (ecosystem, docs, secrets, supply chain)](audit/AUDIT-2026-08-14.md)

# Upstream (Redox OS)

- [Redox README](REDOX-README.md)
- [Redox contributing](REDOX-CONTRIBUTING.md)
