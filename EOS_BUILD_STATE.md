# E-OS — verified build-state checkpoint

This branch (`eos-base`) records a **verified-bootable base** of E-OS, built on top of
modern upstream Redox OS. It is the clean starting point for E-OS development
(rebranding + custom features). Created 2026-06-06.

## Exact base

| Item | Value |
|------|-------|
| Upstream meta-repo | `gitlab.redox-os.org/redox-os/redox` |
| Base commit | `84d78137a1ba1c0e10994d59a577a2739d465baa` (`0.9.0-6174-g84d78137`, master, 2026-06-06) |
| Rust toolchain | `nightly-2026-05-24` (pinned by `rust-toolchain.toml`) |
| Target arch | `x86_64-unknown-redox` |
| Config | `CONFIG_NAME=desktop` → `config/desktop.toml` (full COSMIC desktop) |
| Package source | `REPO_BINARY=1` (prebuilt `.pkgar` from `static.redox-os.org`) |
| Container build | `PODMAN_BUILD=1` (rootless podman 5.7, crun) |

## Build environment

- Windows 11 host + WSL2 **Ubuntu 26.04**, dedicated build user (passwordless sudo), systemd on.
- Build tree on WSL ext4 at `~/eos/redox` (NOT `/mnt/c`, for speed).
- Rootless **podman 5.7.0** (overlay/crun); `unqualified-search-registries=["docker.io"]`.
- **QEMU 10.2.1** with KVM (`/dev/kvm`; user must be in the `kvm` group).

## How it was built

```sh
cd ~/eos/redox
. "$HOME/.cargo/env"
make CI=1 all            # CI=1 is REQUIRED for headless/background builds — see note below
```

**Critical note — `CI=1`:** the cookbook `repo` tool (`src/bin/repo.rs`) renders a ratatui
TUI during `cook`. Run headless (stdout not a TTY → terminal size 0) it panics
`slice index starts at 1 but ends at 0` at `repo.rs:1693` (`panel_height == 0`).
Setting `CI` to any non-empty value disables the TUI (`config.rs`: `tui = !(CI set & non-empty)`),
giving plain-text output that builds correctly. Always build with `CI=1` when detached.

## Output & verification

- Image: `build/x86_64/desktop/harddrive.img` — **681 MB**, RedoxFS **647 MiB**.
- Boot-tested under QEMU/KVM (`make qemu gpu=no kvm=yes`): UEFI(OVMF) →
  `Redox OS Bootloader 1.0.0` → RedoxFS mount → kernel → init switchroot →
  drivers (`nvmed`, `ahcid`, `xhcid`, `ihdad`, `e1000d`) → **`redox login:`**.
- Logins: `user` (no password), `root` / `password`.
- Headless serial shows `orbital: failed to open display` — expected with `gpu=no`
  (no GPU); the COSMIC GUI needs a real display (`make qemu` default, or WSLg).

## Reproduce

```sh
git clone https://gitlab.redox-os.org/redox-os/redox.git
cd redox && git checkout 84d78137a1ba1c0e10994d59a577a2739d465baa
# ensure .config has PODMAN_BUILD?=1 and REPO_BINARY?=1
make CI=1 all && make qemu      # qemu (with display) boots the COSMIC desktop
```

## Relationship to the 2019 mirror

The original E-OS repos held a verbatim **2019 Redox ~0.5.0 mirror** whose history has
**diverged** from current upstream master (the build system was rewritten:
xargo→podman, new `base` repo, COSMIC, RedoxFS rewrite). That content is preserved on the
existing `master` (GitLab) / `0.4.1` (GitHub) branches and tags `0.0.1`–`0.5.0`.
E-OS development proceeds from this `eos-base`, not by merging 7 years of history.
