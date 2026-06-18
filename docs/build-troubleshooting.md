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
