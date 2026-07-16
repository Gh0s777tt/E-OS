# CI/CD & automation

E-OS runs **all CI on GitLab** (`gitlab.com/e-os`). GitHub Actions is disabled
account-wide, so GitHub is only a read-only mirror. The pipeline is defined in
[`.gitlab-ci.yml`](https://github.com/Gh0s777tt/E-OS/blob/main/.gitlab-ci.yml).

## Two tiers

To fit the free-tier budget (~400 shared-runner minutes/month), CI is split:

| Tier | Where | When | Jobs |
|------|-------|------|------|
| **Light** | GitLab shared runners | every MR + `main` | `secret-scan` (gitleaks, full history), `integrity`, `pin-check`, `docs-currency` (MR), `rust-checks` (fmt + clippy + test + cargo-deny), `pages` |
| **Heavy** | your **self-hosted** runner (tag `eos-heavy`) | tags + schedules | `build-image` — full `make CI=1 all` (x86_64 + aarch64), hours |

The heavy image build **never** runs on shared runners (it would blow the minute
budget and time out). It only picks up on a runner you register.

## What is automatic

- **Secrets** — `gitleaks` scans the whole history (`GIT_DEPTH: 0`) on every push.
- **Supply chain** — `cargo-deny` checks RustSec advisories, licenses, banned/duplicate
  crates and crate sources ([`deny.toml`](https://github.com/Gh0s777tt/E-OS/blob/main/deny.toml)).
- **Format / lint / test** — `cargo fmt --check`, `cargo clippy -D warnings`, `cargo test`
  on the E-OS host tooling, against the shared [`rustfmt.toml`](https://github.com/Gh0s777tt/E-OS/blob/main/rustfmt.toml) / [`clippy.toml`](https://github.com/Gh0s777tt/E-OS/blob/main/clippy.toml).
- **Pins** — `pin-check` fails if any recipe pin drifts from its fork tip (`repos.toml`).
- **Docs** — `pages` publishes the mdBook to <https://e-os.gitlab.io/e-os/>; `docs-currency`
  fails an MR that changes code without touching docs (opt-out: put `docs: n/a` in the MR).

## What you must set up (one-time, in the GitLab UI)

### 1. Self-hosted heavy runner (`build-image`)

The full OS build needs Podman + the cookbook toolchain, so run it on your own machine
(or a server), not a shared runner:

1. **Project → Settings → CI/CD → Runners → New project runner.**
2. Tags: **`eos-heavy`**. Untick *"Run untagged jobs"*.
3. Follow the shown `gitlab-runner register` command; pick the **docker** (or **shell**)
   executor. For docker, use a privileged image with Podman, or the shell executor on a
   host that already has the E-OS build container.
4. To build nightly: **Settings → CI/CD → Pipeline schedules → New schedule** (e.g. `0 3 * * *`).

### 2. Releases — `semantic-release` (dormant until enabled)

The `semantic-release` job derives the version from Conventional Commits, tags it and
cuts a GitLab Release (it does **not** rewrite the manual `CHANGELOG.md`). Enable it:

1. Create a GitLab **Project Access Token** (or PAT) with scope **`api`**.
2. **Settings → CI/CD → Variables → Add variable**: key `GITLAB_TOKEN`, value the token,
   **Masked** + **Protected**.

The job then runs on `main` and skips itself until the variable exists.

### 3. Dependency updates — Renovate (replaces Dependabot)

Dependabot's `github-actions` ecosystem was dropped (dead pipeline); Renovate on GitLab
replaces it. Config is in [`renovate.json`](https://github.com/Gh0s777tt/E-OS/blob/main/renovate.json):

1. Create a GitLab PAT with scope **`api`**; add it as a masked variable `RENOVATE_TOKEN`.
2. **Settings → CI/CD → Pipeline schedules → New schedule** (e.g. nightly). The `renovate`
   job runs only on schedules when `RENOVATE_TOKEN` is set, and opens MRs for bumps
   (patch updates auto-merge once CI is green).

### 4. Protect `main`

**Settings → Repository → Protected branches → `main`:**
- Allowed to merge: *Maintainers*; Allowed to push: *No one* (merge only via MR).
- **Settings → Merge requests:** require *"Pipelines must succeed"* and at least one approval.

### 5. GitHub mirror hygiene

The GitHub repo is a read-only mirror. To stop contributions landing there:
- **GitHub → Settings → General:** the README already states development is on GitLab.
  Optionally disable Issues, or add a `.github/` note pointing to GitLab.
- **GitHub → Settings → Code security:** you can still enable **secret scanning** and
  **Dependabot alerts** — these are notifications only and do not need Actions.

## Optional: GitLab security templates

For deeper scanning you can include GitLab's managed templates (they add jobs, so watch
the minute budget):

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
```

## Local hooks

Install [lefthook](https://github.com/evilmartians/lefthook) once (`brew install lefthook`,
then `lefthook install`). It mirrors the light tier locally: `rustfmt`/`gitleaks` on
commit, `clippy`/integrity on push, and Conventional-Commits enforcement on the message
([`lefthook.yml`](https://github.com/Gh0s777tt/E-OS/blob/main/lefthook.yml)).
