---
title: Build & boot troubleshooting
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🔧 Build & boot troubleshooting

Practical fixes for issues hit while building and testing E-OS in the containerised
(Podman) WSL2 environment described in [EOS_BUILD_STATE.md](../archive/EOS_BUILD_STATE.md).

## Apple-Silicon macOS + Podman: the build dies at the first `cargo build` (`Input/output error (os error 5)`)

**Symptom** — on an Apple-Silicon Mac driving `podman machine` (applehv), `make … all`
gets through the container image **and** the prefix toolchain, then dies at the first
host-side `cargo build` (e.g. `build/fstools.tag`):

```
error: failed to read `/mnt/redox/Cargo.toml`
  Input/output error (os error 5)
make: *** [mk/fstools.mk:47: build/fstools.tag] Error 101
```

**Cause — the Podman `virtiofs` bind mount can't serve cargo/rustc's file access.**
The repo is bind-mounted into the build container (`--volume $ROOT:/mnt/redox`). On
podman-machine (macOS) that mount is **virtiofs**, and it does **not** reliably serve
the memory-mapped / metadata-heavy reads cargo and rustc use. A plain read of a file
works while a *cargo* read of the **same** file fails with `EIO` — proving it's the
access pattern, not the file:

```
$ podman run … redox-base bash -c 'cat /mnt/redox/Cargo.toml >/dev/null && echo OK'
OK                                     # plain read — fine
$ podman run … redox-base bash -c 'cd /mnt/redox && cargo metadata …'
… Input/output error (os error 5)      # cargo/mmap read — fails
```

This is why a local from-scratch build has **never** worked from a macOS checkout (the
recipe `target/` trees stay empty) — every `cargo`/`rustc` step would hit it. It is
**not** an E-OS bug; it's a podman-macOS virtiofs limitation.

**What *does* work on macOS.** The container build itself, the space-in-path fix
(`U-111`, `mk/podman.mk`), and downloading the prefix toolchain all work — they don't
drive cargo over the bind mount. (Extracting the prefix tarballs *inside* the container
also fails, on a related virtiofs symlink bug: tar writes a 0-byte `0400` file where a
symlink should be. Work around it by extracting the already-downloaded
`prefix/<target>/{clang,rust}-install.tar.gz` on the **host** with the native `tar`
before re-running `make`.)

**Fixes / where to actually build.**
- **Build on Linux** — the CI heavy `build-image` job (self-hosted `eos-heavy`), or any
  Linux host, has no virtiofs and builds fine. This is the supported path: treat CI as
  the authoritative image build + boot-smoke gate.
- **Build inside the VM's native filesystem** — put the whole build tree in a Podman
  *named volume* (ext4 in the VM, not a virtiofs bind mount) and drive `make` from
  *inside* a container. Bypasses virtiofs entirely. **Verified end-to-end on
  2026-07-24** (a full aarch64/eos image cooked + boot-smoke PASS, incl. `U-112`). The
  working layout uses two volumes: **`eos-work`** mounted at `/work` (so the checkout is
  `/work/redox`, matching the sysroot paths baked into the cook — mount it at the *same*
  point every time) and **`eos-root`** at `/root` (the build HOME with `.cargo`/`.rustup`).

  ```sh
  # one long-lived container (fuse + SYS_ADMIN needed: the image assembly mounts redoxfs)
  podman run -d --name ec-build --cap-add SYS_ADMIN --device /dev/fuse --network=host \
      -v eos-work:/work -v eos-root:/root -w /work/redox redox-base sleep infinity
  # drive the full build INSIDE it — PODMAN_BUILD=0 (already in a container) and CI=1 are
  # both mandatory (see the CI=1 gotcha below)
  podman exec ec-build bash -lc 'cd /work/redox && export PATH=/root/.cargo/bin:$PATH && \
      make PODMAN_BUILD=0 CI=1 CONFIG_NAME=eos ARCH=aarch64 COOKBOOK_MAKE_JOBS=6 all'
  # copy the image out and boot-smoke it on the host (homebrew qemu + edk2 firmware)
  podman cp ec-build:/work/redox/build/aarch64/eos/harddrive.img /tmp/eos.img
  scripts/ci-boot-smoke.sh /tmp/eos.img 420
  ```

  **`CI=1` is mandatory** — without it `repo cook` panics immediately with
  `Result::unwrap() … Os { code: 25, … "Inappropriate ioctl for device" }` because a
  `podman exec` has **no TTY** and the cook's progress-TUI does a terminal ioctl (the
  `R-103` headless panic). To rebuild one recipe at a new pin, edit its
  `recipes/*/recipe.toml` `rev`, then `make c.<recipe>`, `rm build/<arch>/eos/repo.tag
  build/<arch>/eos/harddrive.img`, and re-run the `make … all` above (removing `repo.tag`
  is what forces the repo re-assembly to notice the cleaned recipe). Editing the tree on
  the host means re-syncing into the volume each iteration — the ergonomic cost of losing
  the live bind mount. Cold bootstrap (populating the volumes with a checkout + the
  `prefix/` toolchain + a first from-scratch cook) is the involved part; once warm,
  incremental full builds are minutes.
- Use a macOS checkout for editing, git, the host `cargo … --no-default-features`
  self-tests, and QEMU render-verify of **already-built** images — not for `make all`.

## `make CONFIG_NAME=eos all` fails: "Package … not found" (e.g. `ncursesw`)

**Symptom** — during the `installer` step:

```
installer: failed to install: Package PackageName("ncursesw") not found
  repo - marking ncursesw as outdated: Package "ncursesw" is missing one or more dependencies
  repo - marking terminfo as outdated:
  source of terminfo is not identifiable: Reading file failed at
    recipes/data/terminfo/target/<target>/source_info.toml: No such file (os error 2)
```

**Cause.** `ncursesw` depends on `terminfo` (see
`recipes/libs/ncursesw/recipe.toml` → `dependencies = ["terminfo"]`). Under
`REPO_BINARY=1`, packages are pulled prebuilt from `static.redox-os.org` and their
source is never fetched, so `terminfo` has no `source_info.toml`. The repo resolver
then can't determine `terminfo`'s freshness, marks it — and its dependent
`ncursesw` — *outdated*, and never publishes them to the local repo, so the
installer can't find `ncursesw`. This is a cookbook dependency-resolution quirk,
**not** an E-OS config problem. The same can hit `readline`, `libxcb`,
`xkeyboard-config`.

**Fix.** Cook the affected recipes from source once, then build:

```sh
make CI=1 r.terminfo r.ncursesw r.readline r.libxcb r.xkeyboard-config
make CI=1 CONFIG_NAME=eos all
```

They download cleanly from `static.redox-os.org`; cooking them explicitly publishes
them to the local repo with a valid state. For aarch64, prefix the cook with
`ARCH=aarch64`.

## Fresh clone + `REPO_BINARY=1` silently ships UPSTREAM binaries for the pinned forks

**Symptom** — the build succeeds, but the image is unbranded and unfixed:
`strings harddrive.img | grep -c 'eos login:'` → **0**, `'E-OS Bootloader'` → **0**,
`'redox login:'` → **>0**. `repo/<target>/kernel.toml` shows an upstream
`source_identifier`, not the fork pin. On aarch64 such an image may not even
boot (no R-401b/c/d/e/f), and on both arches it lacks the R-402a relibc TLS fix.

**Cause.** Under `REPO_BINARY=1`, `repo cook --repo-binary` decides per-recipe
between "fetch prebuilt binary" and "build from source" by comparing the local
`source_info.toml` with the packaged state. **On a fresh clone the pinned-source
recipes have never been fetched**, so there is nothing to compare — the resolver
silently takes the upstream binary from `static.redox-os.org`, ignoring the
recipe's `git`/`rev` pin. (`make f.<pkg>` does *not* help as-is: with
`--repo-binary` it reports `fetch <pkg> - cached` without fetching source.)
Development rigs never see this because their sources are already fetched.

**Fix.** Force the six fork recipes from source before assembling the image —
either with the purpose-built `scr.%` targets (sets the recipe rule to *source*,
cleans, rebuilds; used by `.github/workflows/build.yml`):

```sh
make CI=1 CONFIG_NAME=eos scr.kernel scr.base scr.relibc \
     scr.bootloader scr.userutils scr.orbdata
make CI=1 CONFIG_NAME=eos all
```

or equivalently by bypassing the binary fast-path for just those recipes:

```sh
make CI=1 REPO_BINARY=0 f.kernel f.base f.relibc f.userutils f.bootloader f.orbdata
make CI=1 REPO_BINARY=0 r.kernel r.base r.relibc r.userutils r.bootloader r.orbdata
make CI=1 CONFIG_NAME=eos all
```

**Verify** after the build that each fork was packaged from its pin — compare
`source_identifier` in `repo/<target>/<pkg>.toml` against
`git -C recipes/<group>/<pkg>/source rev-parse HEAD`, and check the image:
`strings harddrive.img | grep -c 'eos login:'` ≥ 1. For aarch64, prefix the
makes with `ARCH=aarch64`.

## Booting & smoke-testing under QEMU

- **x86_64** runs under KVM (fast). Boot the *built* image directly — don't use
  `make qemu`, which first rebuilds the image:

  ```sh
  scripts/qemu-driver-check.sh x86_64     # boots headless + lists drivers that bind
  ```

- **aarch64** has **no KVM** on an x86_64 host, so it runs under TCG (software,
  slow). `-cpu max` is too slow to reach login in a sane window — use
  **`-cpu cortex-a72`** (also a faithful non-FEAT_RNG proxy for the R-401b RNG
  work). Expect roughly 9 minutes to `eos login:`:

  ```sh
  scripts/qemu-driver-check.sh aarch64
  ```

`/dev/kvm` must be available for x86_64; firmware is OVMF
(`/usr/share/ovmf/OVMF.fd`) for x86_64 and AAVMF
(`/usr/share/AAVMF/AAVMF_CODE.fd`) for aarch64.

See [hardware-matrix.md](../reference/hardware-matrix.md) for the verified driver coverage these
boots produce.
