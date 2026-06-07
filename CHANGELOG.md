# 📓 Changelog

All notable changes to **E-OS** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Legend:** `Added` · `Changed` · `Deprecated` · `Removed` · `Fixed` · `Security`
> Each release is numbered (`SemVer`) and code-named. Entries are intentionally
> verbose — every line should tell you *what* changed and *why*.

---

## [Unreleased]

### Added
- `[U-001]` Project automation: GitHub Actions CI, **CodeQL** code scanning,
  **gitleaks** secret scanning and **Dependabot** dependency updates.
- `[U-002]` `CODEOWNERS`, issue/PR templates, `FUNDING.yml`.
- `[U-004]` **Custom build config** `config/x86_64/eos.toml` — the E-OS desktop
  variant (`make CI=1 CONFIG_NAME=eos all`).
- `[U-005]` **OS-level rebranding** via `postinstall` file overrides:
  `/etc/os-release`, `/etc/issue` login banner, hostname and `/etc/motd` → E-OS.
- `[U-006]` First desktop screenshot — `assets/screenshots/eos-cosmic-desktop.png`
  (COSMIC running on E-OS under QEMU/KVM).
- `[U-007]` **Red/black E-OS bootloader** — `"E-OS Bootloader"` banner + red-on-black
  theme (selection black-on-red), built from source. Change set:
  `patches/bootloader-eos-red-black.patch`; screenshot `assets/screenshots/eos-bootloader.png`.

### Changed
- `[U-003]` Documentation expanded under `docs/` (architecture, building, security, FAQ).

### Planned
- See **[ROADMAP.md](ROADMAP.md)** for what's coming in `v0.2.0` and beyond.

---

## [0.1.0] — "Genesis" — 2026-06-06

> 🎉 **First verified-bootable E-OS base.** E-OS is re-founded on **modern upstream
> Redox OS** (the 2019 mirror is archived) and boots end-to-end under QEMU/KVM.

### Added
- `[0.1.0-001]` **Modern Redox base.** Re-based onto upstream Redox build system
  commit `84d78137` (`0.9.0-6174`), Rust toolchain `nightly-2026-05-24`, full
  **COSMIC desktop** config (`config/desktop.toml`).
- `[0.1.0-002]` **Reproducible build environment**: WSL2 Ubuntu + rootless
  **Podman 5.7** (crun), **QEMU 10.2.1** with KVM. Documented in
  [`EOS_BUILD_STATE.md`](EOS_BUILD_STATE.md).
- `[0.1.0-003]` **Verified boot.** `build/x86_64/desktop/harddrive.img` (681 MB,
  RedoxFS 647 MiB) boots: UEFI → bootloader → kernel → init → drivers
  (`nvmed`, `ahcid`, `xhcid`, `ihdad`, `e1000d`) → `login:` prompt.
- `[0.1.0-004]` **E-OS brand & repo identity** — Netflix-red/black README,
  documentation set, changelog, roadmap, branding assets.

### Changed
- `[0.1.0-005]` **License → AGPL-3.0.** E-OS as a whole is now strong-copyleft
  (anti-appropriation). Inherited Redox components remain **MIT**; original
  notices preserved in `licenses/Redox-OS-MIT.txt` and [`NOTICE`](NOTICE).
- `[0.1.0-006]` Original Redox `README` preserved at `docs/REDOX-README.md`.

### Fixed
- `[0.1.0-007]` **Headless build crash.** `repo cook` panicked
  `slice index starts at 1 but ends at 0` (`src/bin/repo.rs:1693`) when its TUI
  ran without a real terminal (`panel_height == 0`). **Resolution:** build with
  **`CI=1`** to disable the TUI (`config.rs`: `tui = !(CI set & non-empty)`).
- `[0.1.0-008]` **KVM permissions** for `make qemu` — user added to the `kvm`
  group (`/dev/kvm` is `root:kvm 0660`).

### Security
- `[0.1.0-009]` Strong-copyleft licensing (AGPL-3.0) adopted as a deliberate
  anti-appropriation measure for the distribution.

### Provenance
- Verified base saved on both remotes as branch **`eos-base`** + tag
  **`eos-base-2026-06-06`** (commit `60ba2d1e`). The 2019 Redox mirror is
  retained on the legacy `master` (GitLab) / `0.4.1` (GitHub) branches.

---

[Unreleased]: https://github.com/Gh0s777tt/E-OS/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Gh0s777tt/E-OS/releases/tag/v0.1.0
