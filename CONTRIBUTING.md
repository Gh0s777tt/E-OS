---
title: Contributing
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Contributing to E-OS

Read [`CLAUDE.md`](CLAUDE.md) first. It is the working contract; this file is the practical path
through it.

> **Honest note on process maturity.** This project has had **zero merge requests** in its entire
> history — every commit so far went straight to `main`. The workflow below is what the project is
> moving to, not a description of what has happened. Blocking direct pushes to `main` is the first
> item on the roadmap (`S-1`) precisely because the pipeline gate is already configured and
> currently bypassed.

## Development environment

| Requirement | Notes |
|---|---|
| macOS (Apple Silicon) or Linux | the reference host is Apple Silicon macOS |
| podman | the build is hermetic; nothing is installed on the host toolchain |
| QEMU | `qemu-system-x86_64` / `qemu-system-aarch64` for boot smoke tests |
| ~90 GB free disk | a full build tree with caches measures ~70 GB |
| `shellcheck`, `gitleaks`, `osv-scanner`, `hadolint` | local gates; CI runs the same |

```bash
git clone https://gitlab.com/e-os/e-os.git && cd e-os
brew install lefthook && lefthook install     # local gates before every push
bash scripts/eos-build.sh x86_64
bash scripts/ci-boot-smoke.sh ~/eos-artifacts/eos-x86_64-harddrive.img 300 --arch x86_64
```

**Do not use `make all` from the project directory** if your checkout is on exFAT — podman cannot
bind-mount it. `scripts/eos-build.sh` exists for exactly this reason.

## Where to make a change

E-OS spans 30 repositories with **enforced types**. Getting the type wrong is the most expensive
mistake available here.

| You want to change | Go to |
|---|---|
| what goes into an image | `config/*/eos.toml` in this repository |
| how a package is built | `recipes/` in this repository |
| kernel, bootloader, libc, filesystem | the corresponding `eos-*` fork (type C) |
| an E-OS application | `eos-control`, `eos-notes`, `eos-ui` (type A) |
| upstream Redox code | **upstream**, then sync — never edit a type-B mirror by hand |

The full type table is [`CLAUDE.md` §11](CLAUDE.md), generated from `repos.toml` and checked by CI.

## Branch strategy

| Branch | Purpose |
|---|---|
| `main` | integration; protected; **no direct pushes** |
| `feat/<topic>`, `fix/<topic>`, `docs/<topic>`, `chore/<phase>-<topic>` | work branches |
| `lts/0.1` | long-term support line |
| `archive/*` | historical, never merged |

**No force-push, anywhere.** Not on your own branch either — it destroys the review record.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/). The scope is an area, not a filename.

```
feat(pkg): enforce the signed index on package bytes
fix(boot): refuse to boot when the signature is absent
docs(readme): rebuild from verified facts
```

The body explains **why** and **what was measured** — not what the diff already shows. A commit
body that restates the diff is wasted; one that records the measurement that justified the change
is the most valuable artefact in the repository.

### Sign-off and signing

- **DCO sign-off** — every commit carries `Signed-off-by:`, added with `git commit -s`. This is your
  statement that you have the right to submit the work under the project licence.
- **Commit signing** — commits are signed (`commit.gpgsign true`, `gpg.format ssh`). Signing is not
  yet enforced by a server-side rule (`C-20`), so please self-enforce.

## Pull / merge request checklist

Copy this into the MR description and fill it in. **Paste real command output, not summaries.**

```markdown
## What changed and why

## Verification (real output, not a description)
- [ ] `bash scripts/eos-build.sh <arch>` → ends with `Done.`
- [ ] `cargo test --release` (in container) → <paste result line>
- [ ] `cd tools/eos-repo-sign && cargo test` → <paste result line>
- [ ] `bash scripts/ci-integrity.sh` → `integrity: PASS`
- [ ] `shellcheck -f gcc $(git ls-files 'scripts/*.sh')` → no errors
- [ ] `osv-scanner scan source --lockfile Cargo.lock` → no new findings
- [ ] Artefact verified, not just the exit code (CLAUDE.md §5.3): <how>

## Tests
- [ ] New or updated tests accompany this change
- [ ] A negative test exists for every check added (CLAUDE.md §5.4)
- [ ] If no test was possible: why, and who approved it

## Documentation
- [ ] README / CHANGELOG / ROADMAP / ARCHITECTURE updated in THIS MR
- [ ] CHANGELOG entry references the commit

## For boot / crypto / update / privilege changes (CLAUDE.md §5.6)
- [ ] Written risk analysis: what happens if this fails, and who notices
- [ ] Rollback plan: the actual commands
```

## Review expectations

- **One logical change per MR.** Unrelated fixes get their own MR, however small.
- A reviewer may ask for the **measurement**, not just the reasoning. "It should work" is not an
  answer the project accepts — see `CLAUDE.md` §5.3 for why that rule exists.
- Generated files (`Cargo.lock`, `cookbook.lock`, `sbom/*`, `docs/licenses/THIRD_PARTY.md`) must be
  **regenerated**, never hand-edited. A hand-edited lockfile will be sent back.

## Test requirements

Every change carries tests. Where a test genuinely cannot be written — cross-compiled Redox targets
do not run on the build host — say so explicitly and get agreement **before** submitting.

Current reality, so you know what you are joining: `redox_cookbook` has 9 tests, all in upstream
code; `tools/eos-repo-sign` has 9; the `eos-pkgutils` fork has 33. `repo_builder.rs` and
`cook/package.rs` — the code that writes the signed index and signs packages — have **none**. Fixing
that is roadmap item `S-13` and contributions are welcome.

## Release process

1. Ensure `CHANGELOG.md` `[Unreleased]` is complete and every entry names its commit.
2. Move `[Unreleased]` to a new version heading with the date.
3. Tag **annotated and signed**: `git tag -s vX.Y.Z -m "E-OS vX.Y.Z"`.
4. Build and boot-smoke both architectures.
5. `scripts/make-release.sh` — refuses to assemble a release without `MINISIGN_SECRET_KEY`;
   unsigned requires an explicit `EOS_ALLOW_UNSIGNED=1`.
6. Publish the package repository and verify the index signature from a clean checkout.
7. Regenerate and commit the SBOM for the tag.
8. Create the release object. *Note: `v0.2.0` is tagged and signed but has no release object —
   step 8 was missed and is roadmap item `S-20`'s neighbour.*

## Code of conduct

[`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) applies to every space this project uses.

## Security issues

**Never** in a public issue or MR. [`SECURITY.md`](SECURITY.md).
