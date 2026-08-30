---
title: Getting Started with E-OS
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🚀 Getting Started with E-OS

Welcome! This guide takes you from zero to a booting E-OS desktop.

> **TL;DR:** install WSL2/Ubuntu → run `podman_bootstrap.sh` → `make CI=1 all` →
> `make qemu`.

## 1. Prerequisites

| Requirement | Notes |
|-------------|-------|
| OS | Linux, or **Windows 11 + WSL2 (Ubuntu)** |
| CPU / RAM | 4+ cores, **8 GB+** RAM (16 GB recommended) |
| Disk | **30 GB+** free (the build tree + image are large) |
| Virtualization | **KVM** for fast `make qemu` (nested virt on in WSL2) |
| Tools | `git`, `curl`, rootless **Podman**, **QEMU** (installed by bootstrap) |

> 💡 On Windows, keep the build tree on the **WSL ext4** filesystem
> (`~/eos/...`), **not** under `/mnt/c` — it is dramatically faster.

## 2. Get the source

```bash
git clone https://github.com/Gh0s777tt/E-OS.git eos
cd eos
```

## 3. Bootstrap the toolchain

```bash
curl -sf https://gitlab.redox-os.org/redox-os/redox/-/raw/master/podman_bootstrap.sh -o podman_bootstrap.sh
bash -e podman_bootstrap.sh      # choose: QEMU "full", runtime "crun"
source ~/.cargo/env
```

This installs Rust, the cross-toolchain, Podman and QEMU. The build itself runs
**inside a container** (`PODMAN_BUILD=1`), so your host stays clean.

## 4. Build

```bash
make CI=1 all
```

- **`CI=1` is required** for non-interactive builds (it disables the cookbook TUI
  that otherwise panics — see [building.md](building.md)).
- First build is long (downloads prebuilt `pkgar` packages and assembles the
  RedoxFS image). Output: `build/x86_64/desktop/harddrive.img`.

## 5. Run

```bash
make qemu              # full Crimson desktop (GUI; needs a display / WSLg)
make qemu gpu=no       # text/serial console (no GPU)
```

**Default logins:** `user` (no password) · `root` / `password`.

If `make qemu` fails with `Could not access KVM`, add yourself to the `kvm`
group: `sudo usermod -aG kvm "$USER"` (then restart the shell).

## 6. Develop a single package

```bash
make r.RECIPE          # rebuild one recipe, e.g.  make r.cosmic-term
make image             # reassemble the image
```

## Next steps

- 🧱 Understand the design → **[architecture.md](../architecture/overview.md)**
- 🔧 Build internals & troubleshooting → **[building.md](building.md)**
- 🔐 Contributor security → **[security.md](../security/index.md)**
- ❓ Questions → **[faq.md](faq.md)**
- 🗺️ What's next → **[../ROADMAP.md](../../ROADMAP.md)**
