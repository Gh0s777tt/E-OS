# 🔐 Contributor Security Guide

This is the **practical** security guide for working *on* E-OS. To **report** a
vulnerability, see [`../SECURITY.md`](../SECURITY.md).

## Golden rules

1. **Never commit secrets.** No tokens, keys, passwords, `.pkgar` signing keys.
   CI runs **gitleaks** and GitHub **push protection** will block you.
2. **Sign your commits** (`git commit -S`). See below.
3. **Review dependencies.** Dependabot PRs are not auto-merged blindly.
4. **Least privilege** in code — request only the scheme handles you need.

## Signing commits

```bash
# one-time
git config --global user.signingkey <YOUR_KEY_ID>
git config --global commit.gpgsign true
# or SSH signing
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

Signed commits get the **Verified** badge and are encouraged for all merges.

## If a secret leaks

1. **Revoke it immediately** at the provider (GitHub/GitLab/etc.).
2. Tell a maintainer (see `SECURITY.md`).
3. Do **not** try to rewrite history alone — coordinate; the secret is already
   compromised the moment it's pushed.

> 🧠 Note: GitHub/GitLab **secret scanning auto-revokes** many token types the
> instant they appear in a push or are pasted publicly. Treat any exposed token
> as dead and rotate it.

## Repository protections (maintainers)

Re-measured 2026-08-22 (`U-141`) against the live settings and the tree, because the
previous version of this table named two workflow files that **do not exist** and claimed
a required review that has never been enforced. Status here means *verified today*, not
*intended*.

| Control | Where | Status |
|---------|-------|--------|
| Secret scanning + push protection | GitHub repo settings | ✅ **on** — `secret_scanning` and `secret_scanning_push_protection` both `enabled` |
| gitleaks — pre-commit | `lefthook.yml` | ✅ **on, fails closed** since `U-140` (it previously ended in `\|\| true` and blocked nothing) |
| gitleaks — CI | `.gitlab-ci.yml` → `secret-scan` | ✅ **on**, full history (`GIT_DEPTH: 0`) |
| Dependabot | `.github/dependabot.yml` | ✅ **on** — cargo only; the `github-actions` ecosystem was dropped deliberately |
| Dependabot security updates | GitHub repo settings | ✅ **on** |
| `cargo-deny` (advisories/licenses/sources) | `.gitlab-ci.yml` → `rust-checks` | ⚠️ **on, but one crate** — `tools/eos-repo-sign` only; the vendored `redox_cookbook` engine is not covered |
| Force-push / branch deletion blocked | GitHub `main` | ✅ **on** |
| Protected branch | GitLab `main` | ✅ **on** — push and merge restricted to Maintainers |
| CodeQL code scanning | — | ❌ **off**. `.github/workflows/` no longer exists (Actions are disabled account-wide). The results GitHub still shows are from the last run before that and are **stale** — do not read them as current. |
| Required review before merge | — | ❌ **not enforced** on either host |
| CODEOWNERS review | `.github/CODEOWNERS` | ⚠️ **file present, unenforced** — with no required review it is advisory |
| Pipeline must pass before merge | GitLab project setting | ❌ **off** — `only_allow_merge_if_pipeline_succeeds = false`, and there have been **0 merge requests** in project history, so every gate is a notification *after* the push, not a gate. `docs-currency` (MR-only) has never executed. |
| Signed commits / tags | git + GitLab | ✅ **on (re-measured `U-152`)** — SSH signing, `commit.gpgsign`/`tag.gpgsign` both true, `allowed_signers` set; every commit since `1d3c62ea6` verifies `G`, and GitLab's signature API reports `verified`. `v0.2.0` is the first **annotated, signed** tag — the older two are *lightweight* and could never have held a signature. ⚠️ **GitHub mirror unconfirmed**: the `gh` token lacks `admin:ssh_signing_key`, so whether the key is registered there as a *signing* key is unknown; if not, mirrored commits read *Unverified*. |

**What this table says in one line:** secrets are genuinely well covered end to end;
*review and merge gating are not covered at all*, and code scanning is off despite
GitHub still displaying old results.

## Threat model (summary)

E-OS's microkernel design shrinks the trusted computing base: a compromised
driver is a compromised **process**, not the kernel. The scheme model enables
capability-style confinement. Hardening the *distribution* (signed images, SBOM,
reproducible builds) is tracked under roadmap **v0.3.0 "Fortify"**.

## Why AGPL-3.0

Strong copyleft is an anti-appropriation control: anyone who ships or **serves** a
modified E-OS must release their source. It keeps the security benefits of the
code in the open. Inherited Redox code stays MIT; see [`../NOTICE`](../NOTICE).

## Post-quantum package signing (R-503) — migration plan

The package repo's `repo.toml` lists every package's blake3 hash, so a signature
over it authenticates the whole repository (see `docs/packages.md`). Today's
trust anchor is **ed25519** (pkgar). A store-now-decrypt-later adversary can
harvest signed artifacts and forge them once a cryptographically relevant
quantum computer exists, so E-OS is moving the repo signature to a **hybrid**:
classical **ed25519** *and* post-quantum **ML-DSA-65** (FIPS 204). The hybrid is
strictly stronger — a forgery needs to break **both** — and never weaker than
today's ed25519.

### Prototype (shipped)

`tools/eos-repo-sign` (a build-host tool, not shipped to Redox) implements the
scheme end-to-end:

```sh
eos-repo-sign keygen  signing.key signing.pub          # ed25519 + ML-DSA-65 keypairs
eos-repo-sign sign    signing.key repo.toml            # -> repo.toml.sig (both sigs)
eos-repo-sign verify  signing.pub repo.toml            # both must pass
eos-repo-sign verify  signing.pub repo.toml --classical-only   # ed25519 only
```

Verified against the real `repo/aarch64-unknown-redox/repo.toml`: hybrid verify
passes, `--classical-only` passes (a pre-migration verifier keeps working), and a
single flipped byte fails **both** algorithms. Sizes: ed25519 pubkey 32 B / sig
64 B; ML-DSA-65 pubkey 1952 B / sig 3309 B. The `.sig` is flat, hex-encoded,
auditable text.

### Rollout stages

1. **Dual-publish (compatible).** The repo publisher writes `repo.toml.sig`
   alongside the existing pkgar ed25519 signatures. Old clients ignore it; new
   clients verify ed25519 from it and treat ML-DSA as advisory.
   > ⚠️ **Correction (`U-164`): the client half is implemented in the fork but is NOT in the shipped
   > image.** `pkg-lib` comes from `recipes/core/pkgutils`, which `REPO_BINARY=1` makes cookbook download
   > as an upstream prebuilt package (`R-F20`), so none of the signature-verification code ships. Verified
   > by searching the 1.4 GB image for four distinctive literals from that code: zero hits, with the
   > search instrument controlled against strings that are present.
   >
   > **Status: both ends built, no key between them.** Publisher-side is **live**
   > — `publish-repo-pages.sh` and `publish-repo.sh` sign, and since `U-120`
   > refuse to publish unsigned unless `EOS_ALLOW_UNSIGNED=1`. Client-side is
   > **also implemented**: `pkg-lib`'s `verify_repo_manifest` loads the pinned key
   > and calls `manifest_sig::verify_manifest_ed25519` (tamper/wrong-key tests
   > included). The stage is not complete only because **no key is pinned**
   > (`R-702`): with none the client warns and continues, with one a missing or
   > invalid signature is fatal. Generate `keys/eos-repo-sign.pub.toml` and bake
   > it in, and stage 1 closes without further code.
2. **Dual-require (new clients).** Updated clients require **both** ed25519 and
   ML-DSA-65 to pass. Images still boot because pkgar's per-package ed25519
   verification is unchanged; the hybrid guards the *manifest*.
3. **PQ-primary.** Once all supported clients enforce the hybrid, ML-DSA-65
   becomes mandatory and ed25519 is retained only for defense-in-depth.

### Key custody

- The **secret** file (ed25519 seed + ML-DSA-65 seed, 32 B each) lives **off-repo**,
  in the same custody as the existing minisign release key (`keys/README.md`) —
  ideally an HSM or hardware token once tooling supports it.
- The **public** file ships with the repo and is pinned into `/etc/pkg.d` on the
  image (alongside the R-1003 repo-hosting work).
- Rotation: publish a new `signing.pub`, re-sign, and ship the new public key in
  an image update signed by the *old* key — the standard signed-key-rotation
  chain.

### Non-goals (this phase)

PQ TLS/SSH (upstream-dependent), PQ for the FDE key-derivation (Argon2 is not the
quantum-exposed part), and replacing ed25519 outright. Crate: RustCrypto
`ml-dsa` 0.1 (FIPS 204); revisit when it reaches 1.0 and when a FIPS-validated
build is available.
