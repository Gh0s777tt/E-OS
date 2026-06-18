# 🔧 Building E-OS — internals & troubleshooting

## Build model

E-OS uses the Redox build system: a top-level `Makefile` that drives the
**cookbook** (`repo cook`) inside a **rootless Podman** container.

| Variable | Default | Meaning |
|----------|---------|---------|
| `ARCH` | `x86_64` | Target architecture |
| `CONFIG_NAME` | `desktop` | Filesystem config (`config/desktop.toml`, COSMIC) |
| `PODMAN_BUILD` | `1` | Build inside a container |
| `REPO_BINARY` | `1` | Use prebuilt `pkgar` packages (fast); `0` builds from source |
| `CI` | *(unset)* | **Set to `1` to disable the TUI** (required when headless) |

```bash
make CI=1 all      # toolchain (cached) → cook packages → assemble image
make CI=1 r.RECIPE # rebuild a single recipe
make image         # reassemble harddrive.img from staged packages
make clean         # remove build artifacts
```

Output: `build/x86_64/desktop/harddrive.img`.

## ⚠️ The `CI=1` rule (important)

When building non-interactively (CI, background jobs, piping output to a file),
**always pass `CI=1`**:

```bash
make CI=1 all
```

**Why:** the cookbook `repo` tool renders a `ratatui` TUI during `cook`. With no
real terminal, the reported terminal size is `0`, so an internal `panel_height`
becomes `0` and the renderer panics:

```
thread 'main' panicked at src/bin/repo.rs:1693:
slice index starts at 1 but ends at 0
```

`CI` (any non-empty value) sets `cook.tui = false`
(`config.rs`: `tui = !(CI set & non-empty)`), giving plain-text logs that build
correctly. This is the single most common first-build failure.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `repo.rs:1693 slice index … ends at 0` | TUI with no terminal | `make CI=1 all` |
| `Could not access KVM kernel module` | not in `kvm` group | `sudo usermod -aG kvm "$USER"` + new shell |
| `make qemu` shows `orbital: failed to open display` | ran with `gpu=no` (no GPU) | use `make qemu` (with display) for the GUI |
| Out of memory / OOM-killed | parallel Rust builds | lower jobs: `make CI=1 all -j2`; add swap |
| Very slow build | tree on `/mnt/c` | move to WSL ext4 (`~/...`) |
| Registry prompt during pull | unqualified image name | set `unqualified-search-registries=["docker.io"]` in `~/.config/containers/registries.conf` |
| Stale package after edit | cached recipe | `make CI=1 r.RECIPE && make image` |

## Reproducible base

The exact verified base (commit, toolchain, config, byte sizes, boot log) is
pinned in **[`../EOS_BUILD_STATE.md`](../EOS_BUILD_STATE.md)**. To reproduce a
known-good build, check out tag `eos-base-2026-06-06`.

## Headless boot test

```bash
make qemu gpu=no kvm=yes      # serial console; Ctrl-A X to quit QEMU
```

A healthy boot shows: `Redox OS Bootloader` → `RedoxFS … MiB` → kernel →
`init: switchroot` → driver spawns → `login:`.

## Troubleshooting

Hit a build error (e.g. `Package "ncursesw" not found`) or want to smoke-test the
image under QEMU? See **[build-troubleshooting.md](build-troubleshooting.md)**.
