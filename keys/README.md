# E-OS release signing

E-OS release checksums (`release/SHA256SUMS`) are signed with
[minisign](https://jedisct1.github.io/minisign/).

**Public key:** [`eos-release.pub`](eos-release.pub)
(`RWRK7VdguoXs3DzsgMNdzZg1tpSCIrl6WtFw+QvbSJtauj4OvkiuFM4V`)

## Verify a release

```sh
minisign -Vm SHA256SUMS -p eos-release.pub   # checks SHA256SUMS.minisig
sha256sum -c SHA256SUMS                        # then check the images
```

## Enable CI signing

The release workflow (`.github/workflows/release.yml`) re-signs `SHA256SUMS` on
each `v*` tag **when** the GitHub Actions secret `MINISIGN_SECRET_KEY` is set to
the minisign secret key (kept **off-repo**). Rotate to a properly password-protected
key for production releases.
