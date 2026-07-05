# 📦 E-OS Package Repository

E-OS is built with the Redox **cookbook**: every recipe is compiled into a
**signed `.pkgar` package**, and the build assembles a package repository you can
host and install from.

---

## What the build produces

After `make CI=1 CONFIG_NAME=eos all`, the repo lives in `repo/<target>/`:

```
repo/x86_64-unknown-redox/
├── repo.toml          # index: build_id + [packages] name -> blake3 hash
├── base.pkgar         # one signed package per recipe (~58 packages)
├── cosmic-term.pkgar
├── userutils.pkgar    # (the E-OS-forked, branded build)
└── …                  # ~463 MB total per architecture
```

- **`repo.toml`** is the index clients read to resolve and verify packages.
- Each **`.pkgar`** is content-addressed (blake3) and **ed25519-signed**; the
  matching public key is `id_ed25519.pub.toml` (`pkey = …`). Clients verify the
  signature before installing.

> Provenance flows through: the E-OS source forks (`userutils`, `orbdata`,
> `bootloader`) are cooked locally and packaged here, so the repo carries the
> branded builds — cross-referenced in the [SBOM](../sbom/) (`source_git_ref`).

## Hosting an E-OS repository

A package repo is just **static files over HTTPS** — the layout upstream uses is
`…/pkg/<target>/<pkg>.pkgar` plus `…/pkg/id_ed25519.pub.toml`. To publish E-OS's:

1. Generate (once) and keep **off-repo** an E-OS package-signing ed25519 key, and
   build with it so packages are signed under an E-OS identity (analogous to the
   [release signing key](../keys/README.md)).
2. Serve `repo/<target>/` (the `.pkgar` files + `repo.toml`) and the public
   `id_ed25519.pub.toml` from any static host / object store / CDN, or attach a
   tarball to a GitHub release with [`scripts/publish-repo.sh`](../scripts/publish-repo.sh).

Because the repo is ~0.5 GB/arch it is **not** committed to git — host it as
release assets or on a CDN.

### The official E-OS hosting path (R-1003)

E-OS hosts its repo on **GitHub Pages**, one repository per architecture (the
`pkg` client requires the nested `<base>/<target>/<pkg>.pkgar` layout, which
flat release assets cannot serve):

| Arch | Hosting repo | Stable repo URL |
|---|---|---|
| x86_64 | [`eos-pkg-x86_64`](https://github.com/Gh0s777tt/eos-pkg-x86_64) | `https://gh0s777tt.github.io/eos-pkg-x86_64/pkg` |
| aarch64 | [`eos-pkg-aarch64`](https://github.com/Gh0s777tt/eos-pkg-aarch64) | `https://gh0s777tt.github.io/eos-pkg-aarch64/pkg` |

Publish after a build with
[`scripts/publish-repo-pages.sh`](../scripts/publish-repo-pages.sh)`
[TARGET]` — it stages `pkg/<target>/` + the public key, verifies no package
exceeds GitHub's 100 MB blob limit, and **force-pushes a single orphan commit**
to the hosting repo's `main` (history is discarded each publish, so the hosting
repo never grows). Once the repo is populated and stable, add a
`/etc/pkg.d/50_eos` entry to `config/*/eos.toml` pointing clients at the URL
above (deliberately *not* pre-added — a dead repo URL would degrade `pkg` on
shipped images).

## Consuming packages

- **At build time** — point the build's binary-package source at your repo URL so
  `REPO_BINARY=1` builds pull your hosted `.pkgar` files (the same path upstream
  uses for `static.redox-os.org/pkg/<target>/…`).
- **On a running system** — use the `pkg` / `pkgar` tools to install/verify
  packages from the configured repo.

## Status

The repo is **produced and signed** for x86_64 + aarch64 every build. **Public
hosting infrastructure is live**: the `eos-pkg-<arch>` Pages repos exist with
Pages enabled, and `scripts/publish-repo-pages.sh` publishes to them. Remaining
for `R-1003`: run the first publish from a build rig, then wire
`/etc/pkg.d/50_eos` into the image configs and generate an E-OS-owned package
signing key (kept off-repo).
