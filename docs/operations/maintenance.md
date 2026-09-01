---
title: Maintenance & operations
status: current
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Maintenance & operations

This is the operator's guide to the E-OS repositories: what the professional-standard
overhaul changed, what now happens **automatically**, and what needs **your decision**.

## Hosting model (the one thing to remember)

**GitLab is the source of truth; GitHub is a read-only mirror.**

- Push to **`gitlab.com/e-os`**. A native GitLab **push mirror** replays it to GitHub.
- **Never** dual-push (a manual GitHub push races the mirror and fails it).
- ⚠️ **The mirror replays pushes, not deletions.** Deleting a branch on GitLab leaves it
  standing on GitHub — measured 2026-08-22 (`U-139`): all nine branches were still there
  45 s after the GitLab delete and had to be removed with an explicit
  `git push github --delete`. This is the one case where touching GitHub by hand is
  correct, because there is no push for the mirror to race.
- All CI runs on GitLab (GitHub Actions is disabled account-wide).
- The **30** repos live in the GitLab group **`e-os`** (all public) and mirror to
  `github.com/Gh0s777tt`. [`repos.toml`](https://github.com/Gh0s777tt/E-OS/blob/main/repos.toml) is the single source of truth
  for the list; drive everything with [`scripts/eos-repos.sh`](https://github.com/Gh0s777tt/E-OS/blob/main/scripts/eos-repos.sh).
- **Sync state, re-measured 2026-08-22 (`U-139`):** all **30/30** repositories report the
  same SHA on both hosts for their pinned branch — zero drift. Checked with
  `git ls-remote` against both URLs rather than trusting the mirror's status page.

## What was done

| Stage | Result |
|-------|--------|
| **Inventory & sync** | `repos.toml` manifest + `eos-repos.sh` (clone/update/status/pins/mirrors). Verified 25/25 repos in sync, **0 pin drift**. |
| **Model inversion** | Retired the launchd GitHub→GitLab job; GitLab→GitHub push mirror on E-OS (24 forks pending your PAT). Group `e-os` created, all 25 repos transferred, all public. |
| **100% audit** | 3 adversarially-verified workflows → **52 findings** (0 critical, 4 high) in [`docs/audit/AUDIT-2026-07-13.md`](../audit/AUDIT-2026-07-13.md). Upstream drift healthy (0–7 commits). |
| **Package trust chain** | Publisher signs `repo.toml` (hybrid ed25519+ML-DSA, `eos-repo-sign`); the `pkg` client verifies it against a pinned key (R-703, unit-tested). |
| **READMEs** | Main README audited + hosting note; consistent README on all 24 related repos. |
| **Docs** | mdBook completed, live at **<https://e-os.gitlab.io/e-os/>** (GitLab Pages), `ecosystem.md` generated from `repos.toml`, Mermaid diagrams. |
| **CI/CD** | Two-tier GitLab CI (light on shared runners, heavy on self-hosted), cargo-deny, Renovate, semantic-release, lefthook hooks. Pipeline **green**. |

### Notable fixes shipped

- `gitleaks` now scans full history (`GIT_DEPTH: 0`); `local-scan.sh` no longer swallows
  `cargo-audit` failures; `verify_strict` + panic-safe hex in `eos-repo-sign`.
- **`raid1d`** validates an untrusted disk superblock (was a div-by-zero DoS, K-01).
- Removed 7 dead GitHub workflows + the dead Dependabot ecosystem; added shared
  `rustfmt.toml` / `clippy.toml` / `.editorconfig`; stopped shipping a stale `SHA256SUMS`.

## What happens automatically

On every **merge request / push to `main`** (GitLab shared runners):

- `secret-scan` (gitleaks, full history), `integrity`, `pin-check` (recipe pins vs forks),
  `rust-checks` (fmt + clippy + test + cargo-deny), `docs-currency` (MR).
- On `main`: `pages` republishes the docs site.

On a schedule (once you enable it): **Renovate** opens dependency-bump MRs (patches
auto-merge when green). On tags/schedules on your **self-hosted** runner: `build-image`.

Locally, if you `lefthook install`: fmt/gitleaks on commit, clippy/integrity on push,
Conventional-Commits enforcement on the message.

## What needs your decision / one-time action

These are gated on your credentials or settings — nothing here runs until you do it.
Full click-by-click is in [`docs/operations/ci.md`](ci.md).

| Action | Why | Where |
|--------|-----|-------|
| ~~**`eos-repo-sign keygen`**~~ — **done**: `keys/eos-repo-sign.pub.toml` is committed and pinned; the secret is held off-repo | Make the package-manifest signing chain live (C.1/C.2) | local + `keys/` |
| **Run `scripts/eos-setup-mirrors.sh --apply`** with a GitHub PAT in `$GITHUB_MIRROR_PAT` | Mirror the 24 forks GitLab→GitHub (E-OS already mirrors) | local |
| Set masked/protected CI var **`GITLAB_TOKEN`** (api) | Enable semantic-release (tags + GitLab Releases) | GitLab → Settings → CI/CD → Variables |
| Set **`RENOVATE_TOKEN`** (api) + a nightly **pipeline schedule** | Enable Renovate dependency updates | GitLab → Settings → CI/CD |
| ~~Register a runner tagged **`eos-heavy`**~~ — **done**: `eos-heavy (mac podman)`, id 54369740, shell executor, online; ran `build-image` and `docs-pdf` on 2026-09-01. What remains is a **native x86_64** heavy runner | Run the full OS image build + QEMU smoke test | GitLab → Settings → CI/CD → Runners |
| **Protect `main`** (MR-only, green pipeline required, ≥1 approval) | Enforce review + CI gate | GitLab → Settings → Repository |
| GitHub mirror hygiene (issues off / note dev-on-GitLab; enable secret-scanning + Dependabot alerts) | Keep contributions on GitLab | GitHub → Settings |

## Routine tasks

- **Bump a fork pin:** commit the fork change, push to GitLab, update `rev=` in the
  recipe. `scripts/eos-repos.sh pins` (and CI `pin-check`) must stay clean.
- **Add a repo:** add it to `repos.toml` (the source of truth), then set up its mirror.
- **Cut a release:** merge Conventional-Commit MRs; semantic-release tags + publishes.
  Build artifacts + checksums come from `scripts/make-release.sh` (signed with your
  minisign key) and the `build-image` job.
- **Docs:** edit `docs/*.md`; the MR `docs-currency` check nudges you if code changed
  without docs. `pages` redeploys on merge.

## Known open work (tracked, not yet done)

From the audit and the security track — see the [audit report](../audit/AUDIT-2026-07-13.md)
and [`ROADMAP.md`](https://github.com/Gh0s777tt/E-OS/blob/main/ROADMAP.md):

- **C.2 deployment** — pin the `eos-pkgutils` R-703 branch + bake the pinned key (needs your keygen).
- **Entropy (K-02/06/08)** — emulated aarch64 RNG is weak under emulation; harden `randd`/kernel.
- **Doc consistency (M-12/13/14/16)** — CHANGELOG fragment, SECURITY.md/ROADMAP claims vs reality, `HARDWARE.md`.
- **Fork nits** — `xhcid` byte-count, `pcid` `_PRT` parsing, `redoxfs` `from_utf8_unchecked`, etc.
- **Fork pin bumps** — done: `eos-base` is pinned at `816546df2a` and `eos-pkgutils` at `ec08f22aa6` in `repos.toml`, and the `pin-check` gate holds them there (25 OK, 0 non-allowlisted drift, measured 2026-09-01).
