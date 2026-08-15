# E-OS signing keys & trust anchors

E-OS has **two** independent signing layers; the public keys live here, every
secret key is **user-held and kept off-repo**.

## 1. Release checksums — minisign

Release checksums (`SHA256SUMS`) are signed with
[minisign](https://jedisct1.github.io/minisign/).

**Public key:** [`eos-release.pub`](eos-release.pub)
(`RWRK7VdguoXs3DzsgMNdzZg1tpSCIrl6WtFw+QvbSJtauj4OvkiuFM4V`)

`SHA256SUMS` + `SHA256SUMS.minisig` are **release assets** — produced per-release
by `scripts/make-release.sh` over the actual built images and attached to the
tag. They are **not** committed to the repo tree (a committed copy goes stale and
references images that were never shipped). Download them from the release, then:

```sh
minisign -Vm SHA256SUMS -p eos-release.pub   # checks SHA256SUMS.minisig
sha256sum -c SHA256SUMS                        # then check the images
```

Produce + sign locally:

```sh
VERSION=0.1.0 MINISIGN_SECRET_KEY=/path/off-repo/eos-release.key \
  scripts/make-release.sh
```

## 2. Package-repo manifest — hybrid ed25519 + ML-DSA-65 (R-503 / R-703)

The package repository's `repo.toml` lists every package's blake3 hash, so a
signature over it authenticates the whole repo. E-OS signs it with a **hybrid**
ed25519 + ML-DSA-65 (post-quantum, FIPS 204) signature via `tools/eos-repo-sign`.

**Trust anchor (R-702) — NOT YET IN PLACE.** The *design* is that the hybrid public
key is pinned **in the image**, so clients verify `repo.toml.sig` against the pinned
key rather than one fetched from the repo host. Neither half exists today:
`eos-repo-sign.pub.toml` has never been generated or committed (this directory holds
only `eos-release.pub`, the minisign release key), and no client-side
`verify_manifest()` is implemented (`R-703`). The publisher already signs, so the
missing anchor is the *only* reason that signature is inert. The steps below create
the key; pinning it into the image is `R-702`.

One-time key setup (secret stays off-repo — e.g. a password manager or a masked
GitLab CI *file* variable):

```sh
cargo build --release --manifest-path tools/eos-repo-sign/Cargo.toml
tools/eos-repo-sign/target/release/eos-repo-sign keygen \
    /path/off-repo/eos-repo-sign.secret.toml  keys/eos-repo-sign.pub.toml
git add keys/eos-repo-sign.pub.toml            # PUBLIC key only
```

Publishing a repo then signs the manifest automatically:

```sh
EOS_REPO_SIGN_KEY=/path/off-repo/eos-repo-sign.secret.toml \
  scripts/publish-repo-pages.sh x86_64-unknown-redox   # emits repo.toml.sig
```

Verify a downloaded manifest:

```sh
eos-repo-sign verify keys/eos-repo-sign.pub.toml repo.toml   # checks repo.toml.sig
```

## CI signing

CI-side signing (`.github/workflows/release.yml`) is **inert** — GitHub Actions is
disabled account-wide (see `ROADMAP.md`, R-004). Signing runs locally via the
scripts above until the release + signing jobs move to GitLab CI (with the secret
supplied as a masked/protected CI *file* variable). Rotate to a password-protected
key for production releases.
