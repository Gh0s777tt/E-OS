# 🔧 Build & boot troubleshooting

Practical fixes for issues hit while building and testing E-OS in the containerised
(Podman) WSL2 environment described in [EOS_BUILD_STATE.md](../EOS_BUILD_STATE.md).

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

See [hardware-matrix.md](hardware-matrix.md) for the verified driver coverage these
boots produce.
