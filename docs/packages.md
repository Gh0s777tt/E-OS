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

## Consuming packages

- **At build time** — point the build's binary-package source at your repo URL so
  `REPO_BINARY=1` builds pull your hosted `.pkgar` files (the same path upstream
  uses for `static.redox-os.org/pkg/<target>/…`).
- **On a running system** — use the `pkg` / `pkgar` tools to install/verify
  packages from the configured repo.

## Status

The repo is **produced and signed** for x86_64 + aarch64 every build, and
documented here. **Public hosting** (a stable E-OS repo URL + an E-OS-owned
signing key) is the remaining infrastructure step — see ROADMAP `R-1003`.
