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

**Trust anchor (R-702) — THE ONE MISSING PIECE.** The hybrid public key is meant to
be pinned **in the image**, so clients verify `repo.toml.sig` against it rather than
one fetched from the repo host. Everything around it already exists: the publisher
signs, and `pkg-lib` verifies (`manifest_sig::verify_manifest_ed25519`, reached via
`verify_repo_manifest`, at the pinned `eos-pkgutils@14505ecd`). What does **not**
exist is `eos-repo-sign.pub.toml` — this directory holds only `eos-release.pub`, the
minisign *release* key, which is a different key for a different job. Without it the
client warns and proceeds; with it, an unsigned or tampered index is a hard failure.
Generating and committing it is therefore the highest-leverage single action in the
whole trust chain. The steps below create it **and install it**.

One-time key setup (secret stays off-repo — e.g. a password manager or a masked
GitLab CI *file* variable):

```sh
cargo build --release --manifest-path tools/eos-repo-sign/Cargo.toml
tools/eos-repo-sign/target/release/eos-repo-sign keygen \
    /path/off-repo/eos-repo-sign.secret.toml  keys/eos-repo-sign.pub.toml
git add keys/eos-repo-sign.pub.toml            # PUBLIC key only
scripts/eos-pin-repo-key.sh                    # install it into the image configs
```

The second command is not book-keeping. `pkg-lib` reads the pinned key from
`/etc/pkg/eos-repo-sign.pub.toml` **inside the image** (`REPO_SIGN_PUBKEY_PATH` in
`pkg-lib/src/lib.rs`), and nothing else puts it there — a key sitting in `keys/` alone
changes nothing at runtime. The script embeds the public half into
`config/{aarch64,x86_64}/eos.toml` (the installer's `[[files]]` has no `from`/`source`
field, so content must be inline), is idempotent, and **refuses a secret key file**:
`keygen` marks the secret half with `[secret_keys]`/`ml_dsa_65_seed`, and a config is
world-readable in every shipped image. Rebuild afterwards, or the key still is not in
the image.

Publishing a repo then signs the manifest automatically:

```sh
EOS_REPO_SIGN_KEY=/path/off-repo/eos-repo-sign.secret.toml \
  scripts/publish-repo-pages.sh x86_64-unknown-redox   # emits repo.toml.sig
```

Verify a downloaded manifest:

```sh
eos-repo-sign verify keys/eos-repo-sign.pub.toml repo.toml   # checks repo.toml.sig
```

## 3. Upstream package key — pinned, not downloaded (C-1)

`keys/upstream-redox-pkg.pub.toml` is upstream Redox's package-signing key, and it is the only
trust anchor for the prebuilt packages we do not build ourselves. It is **not ours** — we hold no
private half and cannot rotate it. It is here so that nobody has to take it from the network.

**The problem it fixes.** `RepoManager::sync_keys()` downloads that key from
`https://static.redox-os.org/pkg` and caches it in `build/remotes/`. That is the same host that
serves the packages, and nothing compared the key against anything: trust on first use, decided by
whoever answered the request. `cook::cook_build` then hands exactly that cached file to
`pkgar::extract`, so it is the whole cryptographic gate on **30 of the 65 packages** in a shipped
image. Whoever controlled the host supplied both the packages and the key that "verified" them.
`cook::fetch_repo::pin_upstream_key` now writes this file from the pin on every run, before any
package is opened, and sets the key on the remote so no download is attempted.

**How the value was established, and what that is worth.** A pin cannot prove a key was ever the
right one — it can only stop it changing without anyone noticing. Before committing it, the value
was taken from four independent witnesses and all four were byte-identical:

| Witness | Date observed | Value |
|---|---|---|
| `https://static.redox-os.org/pkg/pub.toml`, live | 2026-08-30 | `578b09da…59677e` |
| This tree's pre-existing `build/remotes/` cache | earlier build | `578b09da…59677e` |
| archive.org snapshot | 2023 | `578b09da…59677e` |
| archive.org snapshot | 2024 | `578b09da…59677e` |

Two of those witnesses are years apart and outside upstream's control at the time we read them,
which is what makes this more than "whatever the host said today". It is still evidence, not
proof: if the key was already wrong in 2023, every witness is wrong together. Say so plainly
rather than describing the pin as verification.

**If upstream rotates the key.** The build stops, loudly — extraction fails because the packages
are signed with a key that is not the pinned one. That is the intended behaviour and it must not
be worked around by deleting the pin. Instead:

1. Confirm the new value from more than one source that upstream does not solely control (their
   announcement, the live host, an archived snapshot taken after the rotation).
2. Update `keys/upstream-redox-pkg.pub.toml` **in its own commit**, with the witnesses recorded in
   the commit message and the table above updated.
3. Do not batch that commit with anything else. A key change should be reviewable on its own.

**What guards it.** `cook::fetch_repo`'s tests cover the three ways this silently stops working: a
poisoned cache surviving the run, a remote left without a key so `sync_keys()` fetches one anyway,
and the written path drifting away from the path `cook_build` reads. The last one matters most —
change the host in `REMOTE_PKG_SOURCE` without updating `REMOTE_PKG_PUBKEY_CACHE` and the pin
would land beside the file that is actually used, restoring the old behaviour with no visible sign.

## CI signing

CI-side signing (`.github/workflows/release.yml`) is **inert** — GitHub Actions is
disabled account-wide (see `ROADMAP.md`, R-004). Signing runs locally via the
scripts above until the release + signing jobs move to GitLab CI (with the secret
supplied as a masked/protected CI *file* variable). Rotate to a password-protected
key for production releases.

## Jedno polecenie (`U-184`)

```bash
scripts/eos-key-bootstrap.sh
```

Generuje parę hybrydową (ed25519 + ML-DSA-65), sprawdza, że sekret ma tryb `0600` i jest
ignorowany przez gita, przypina połowę **publiczną** do `config/{aarch64,x86_64}/eos.toml`
pod `/etc/pkg/eos-repo-sign.pub.toml`, i uruchamia bramki. Nie drukuje materiału klucza.

**Dlaczego uruchamiasz to Ty, a nie asystent.** Klucz podpisujący jest korzeniem zaufania dla
każdego pakietu, jaki E-OS kiedykolwiek wyda, a cała jego wartość polega na tym, że posiada go
**dokładnie jedna strona**. Wszystko, co robi asystent, przechodzi przez wywołania narzędzi
zapisywane w transkrypcie sesji — klucz wytworzony w ten sposób nigdy nie dałby się już
zaświadczyć jako nieskopiowany, a „prawdopodobnie nieskopiowany" nie jest własnością, na
której buduje się łańcuch dostaw.

**Dlaczego nie w kontenerze budującym.** Toolchain Rusta żyje w wolumenie `eos-root`
(`/root/.cargo/bin`), więc technicznie dałoby się tam wygenerować klucz. Skrypt **odmawia**:
klucz zapisany z współdzielonej maszyny wirtualnej przez virtiofs to klucz, którego trybu
`0600` nikt nie gwarantuje, którego czasem życia nie kontrolujesz i którego pochodzenia nie
poświadczysz. Dla tego jednego pliku warto nalegać na host — skrypt powie dokładnie, czego
brakuje (zwykle `rustup default stable`).

**Kopia zapasowa jest natychmiastowa i nie ma odzyskiwania.** `eos-repo-sign keygen` celowo
odmawia nadpisania istniejącego pliku, więc klucza nie da się „wygenerować ponownie w
miejscu"; jego utrata oznacza ponowne obrazowanie każdego klienta, który przypiął połowę
publiczną.
