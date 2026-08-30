# eos-repo-sign — hybrid classical + post-quantum repo signing (R-503)

**What:** a standalone host tool that signs and verifies the package repo's
`repo.toml` with a **hybrid ed25519 + ML-DSA-65 (FIPS 204)** signature. Since
`repo.toml` lists every package's blake3 hash, one signature over it
authenticates the whole repository.

**Why it exists:** today the repo's trust anchor is ed25519 only (pkgar). This
tool prototypes the migration path to post-quantum signatures *without breaking
classical verifiers* — a hybrid `.sig` carries both signatures, verifiers that
only know ed25519 keep working (`--classical-only`), and a future
quantum-capable adversary still can't forge the ML-DSA half. The R-503 PQ story
becomes real (not security theater) once `R-703` wires client-side manifest
verification to this format — see `ROADMAP.md`.

## Usage

```bash
cargo run --release -- keygen secret.toml public.toml   # generate both keypairs
cargo run --release -- sign   secret.toml repo.toml     # writes repo.toml.sig
cargo run --release -- verify public.toml repo.toml     # verify hybrid
cargo run --release -- verify public.toml repo.toml --classical-only
```

Keys and signatures are hex in flat TOML-ish text — trivially auditable, no
extra parsing dependencies.

## Key handling (read before running `keygen`)

- Keep the **secret** key *outside* the repo tree (e.g.
  `~/keys/eos-release-secret.toml`); only the public half belongs in-repo
  (`keys/`). `*.key` is gitignored as a safety net, but don't rely on it.
- `keygen` refuses to overwrite an existing key file (move it away first if you
  really mean to rotate — silent rotation would strand every client pinning the
  old public key) and creates the secret file `0600` (owner-only) on Unix from
  the first byte (U-119; regression-tested).
- The publish flow that consumes this tool is `scripts/publish-repo-pages.sh`
  (set `EOS_REPO_SIGN_KEY`); operational details live in
  [docs/operations/maintenance.md](../../docs/operations/maintenance.md).

## Build notes

This crate is a **deliberately standalone workspace** (its own `Cargo.toml` +
lockfile) so host tooling never entangles the OS build graph. Standard checks:
`cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`.
