---
title: CI/CD & automation
status: current
last-reviewed: 2026-09-01
owner: Gh0s777tt
---

# CI/CD & automation

E-OS defines CI in two places. **GitLab** (`gitlab.com/e-os`,
[`.gitlab-ci.yml`](https://github.com/Gh0s777tt/E-OS/blob/main/.gitlab-ci.yml)) is the
source of truth and the pipeline that gates merge requests. **GitHub Actions**
(`.github/workflows/`) runs on the read-only mirror and exists because the GitLab
pipeline stopped measuring anything on 2026-08-28: every job fails in ~0 s with
`ci_quota_exceeded` (audit finding C-7). A public repository has no Actions minute cap,
which is the whole reason the second pipeline is a remediation rather than a duplicate.

**Neither runs right now.** GitLab is out of minutes, and Actions do not execute on this
account: a minimal `on: push` workflow with no branch filter, pushed directly to
github.com on a fresh branch, produced no workflow run at all — not queued, not failed.
Real workflows last ran here on 2026-06-16. See
[docs/security/github-configuration.md](../security/github-configuration.md) §2.

## Two tiers

To fit the free-tier budget (~400 shared-runner minutes/month), CI is split:

| Tier | Where | When | Jobs |
|------|-------|------|------|
| **Light** | GitLab shared runners | every MR + `main` | `secret-scan` (gitleaks, full history), `integrity`, `pin-check`, `docs-currency` (MR), `rust-checks` (fmt + clippy + test + cargo-deny), `pages` |
| **Heavy** | your **self-hosted** runner (tag `eos-heavy`) | tags + schedules | `build-image` — `make CI=1 all` for **aarch64** in the podman container + headless **boot-smoke**; `build-image-x86_64` is **manual**, and boot-smokes too since `U-133` |

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
  fails an MR that changes code without touching docs (opt-out: put `docs: n/a` in the MR) and
  advises on new public items lacking a doc-comment. `docs-pdf` (self-hosted `eos-heavy`, tags +
  schedules, `allow_failure`) renders the whole manual to a downloadable `eos-docs.pdf` via
  [`scripts/docs-pdf.sh`](https://github.com/Gh0s777tt/E-OS/blob/main/scripts/docs-pdf.sh)
  (mdBook `print.html` → headless Chromium — no fragile PDF plugin). Generate it locally the same way:
  `scripts/docs-pdf.sh`.

## CI minutes (free tier)

The `e-os` namespace is on the **free tier (~400 shared-runner minutes/month)**.
The light tier (secret-scan, integrity, pin-check, rust-checks, pages) runs on
GitLab.com **shared** runners and spends those minutes; the fork pipelines
(especially kernel/relibc multi-arch `redoxer` builds) are the expensive part.
When the budget is exhausted every shared-runner job fails immediately with
`ci_quota_exceeded` (pages surfaces it first as `stuck_pending_no_matching_runners`).

The heavy `build-image` job runs on the **self-hosted `eos-heavy`** runner, which
consumes **no** shared minutes — so it carries `needs: []` to run independently of
the light tier. That way the only job that actually boots the OS still verifies a
commit even when the shared budget is spent (it would otherwise be skipped by the
failed earlier stages). Options when you hit the cap: wait for the monthly reset,
buy additional compute minutes, or register a second self-hosted runner for the
light tier too.

## Fork pipelines

Every pinned fork (see `repos.toml`) also runs CI in the `e-os` namespace. Upstream
`.gitlab-ci.yml` workflow rules gate pipelines to `$CI_PROJECT_NAMESPACE == "redox-os"`
(or to a branch name the fork doesn't develop on), so out of the box fork pipelines were
silently dead. The nine forks that carried such guards — kernel, relibc, base, redoxfs,
pkgutils, orbclient, orbital, orbutils, liborbital — add a namespace-only rule for `e-os`
ahead of the upstream arms (`U-084`); branch names vary across forks
(`eos-july`/`eos`/`master`), so the rule must not depend on them.

Two caveats, by design:

- **QEMU jobs are best-effort** — `redoxer exec`/`redoxer test` jobs are `allow_failure`:
  gitlab.com shared runners have no KVM, so TCG runs are slow and can time out. Real boot
  coverage is the meta `build-image` heavy job's boot-smoke, not fork CI.
- **Minute budget** — fork pipelines run on shared runners and count against the namespace
  budget; kernel/relibc pushes are the expensive ones (multi-arch `redoxer env make`, and
  relibc's `before_script` builds cbindgen in every job). Push to fork branches deliberately.

When rebasing a fork onto upstream, re-apply the namespace rule if the upstream file
overwrites it — `git log --oneline -- .gitlab-ci.yml` in the fork shows the
`ci: run pipelines in the e-os namespace` commit to cherry-pick.

## What you must set up (one-time, in the GitLab UI)

### 1. Self-hosted heavy runner (`build-image`)

The full OS build needs Podman + the cookbook toolchain, so it runs on your own machine
via a **shell executor**, and the build itself happens **inside** the persistent podman
container `eosbuild`, whose `/work/redox` tree carries the Rust toolchain + relibc +
prefix caches — so builds are incremental, minutes not hours. That tree lives in a named
volume, not in the container ([see below](#where-the-build-state-actually-lives--two-named-volumes)).
The job:

1. brings the podman machine (`eos-build`) + container (`eosbuild`) up (idempotent);
2. syncs the pipeline's commit into `/work/redox` with `git archive HEAD | tar -x`
   (overwrites tracked sources, keeps the untracked `build/` + `prefix/` caches);
3. runs `make CI=1 ARCH=aarch64 CONFIG_NAME=eos all` in the container;
4. copies `harddrive.img` out and **boot-smokes** it headlessly with
   [`scripts/ci-boot-smoke.sh`](https://github.com/Gh0s777tt/E-OS/blob/main/scripts/ci-boot-smoke.sh)
   (QEMU `virt`/`cortex-a72`, same invocation as `out/rf08_boot.sh`; asserts the boot
   reaches the login prompt).

`build-image-x86_64` cross-compiles in the same container and is **manual + non-blocking**;
trigger it from the pipeline UI. It **now boot-smokes too** (`U-133`): the long-standing
assumption that an x86_64 boot under TCG on Apple Silicon is too slow to gate on was
measured and is wrong — it reaches `eos login:` in ~16 s, the same order as the aarch64
job. `scripts/ci-boot-smoke.sh` takes `--arch aarch64|x86_64` (default `aarch64`, so the
aarch64 call site is unchanged) and works on both `harddrive.img` and the `redox-live.iso`
from `make live` — both are raw GPT images. A native x86_64 runner is still worth having
for speed and for real-hardware coverage, but it is no longer a prerequisite for gating.

**Guest RAM is `EOS_SMOKE_MEM`** (MiB, default `2048`), matching `ci-install-smoke.sh`,
which already read it. It was hard-coded until 2026-09-01, which made a whole class of
fault invisible to the harness: issue #15 is aarch64 asking for a fixed address at 5 GiB,
and only a RAM sweep shows that the address does not move with memory size. A dial that
cannot be turned without editing the script does not get turned.

```sh
EOS_SMOKE_MEM=6144 bash scripts/ci-boot-smoke.sh <image> 150 --arch aarch64
```

Note what this does **not** do: more RAM gets aarch64 past the allocation and into a
different, deterministic failure (same `ESR 0x9600000B`, same `0x140027FB0`, measured
twice on 2026-09-01). It is a diagnostic dial, not a workaround.

**Register the runner** (this project, id `82957024`; done once — the current runner is
already online). On macOS with Homebrew:

```sh
# 1. create a project runner, tag eos-heavy, no untagged jobs (needs a GitLab session)
glab api --method POST user/runners \
  -f runner_type=project_type -f project_id=82957024 \
  -f tag_list=eos-heavy -f run_untagged=false -f "description=eos-heavy (mac podman)"
# -> returns { "id": …, "token": "glrt-…" }

# 2. register the runner on this machine (shell executor)
gitlab-runner register --non-interactive --url "https://gitlab.com/" \
  --token "glrt-…" --executor shell --shell bash --description "eos-heavy (mac podman)"

# 3. run it as a login-session service (so it inherits your podman machine)
brew services start gitlab-runner
```

The shell executor runs as your login user, so it shares your `podman` machine and the
`eosbuild` container. The job prepends `/opt/homebrew/bin` to `PATH` so `podman`, `qemu`
and `git` resolve under the service's minimal environment.

#### Where the build state actually lives — two named volumes

This is the single most important fact about the heavy runner, and getting it wrong is
what turned the U-114 outage into a three-week freeze. The caches are **not** in the
container's writable layer; they are in two persistent podman **named volumes**:

| Volume | Mounted at | Holds | Size (2026-08-15) |
|---|---|---|---|
| `eos-work` | `/work` | the tree at `/work/redox` — sources, `build/`, `prefix/` for both arches | 28 GB |
| `eos-root` | `/root` | the SHA256-pinned host toolchain and the `~/.cargo` registry caches | 8.7 GB |

`podman rm` does **not** touch named volumes (only `podman rm -v` would). So a container
that "disappears" costs you the container, never the ~37 GB of incremental state — a
rebuilt container that re-mounts these volumes is warm immediately (`cargo check`
in seconds). The failure mode to fear is the opposite one: creating a *replacement*
container **without** `--volume eos-work:/work --volume eos-root:/root`. It looks
identical, execs fine, and silently orphans every cache, turning the next build into a
from-scratch multi-hour run for no visible reason.

**If `eosbuild` disappears** (heavy jobs fail with *"no container with name or ID
\"eosbuild\" found"* — typically after the podman machine was recreated), rebuild it
with one idempotent command on the runner host:

```sh
scripts/eos-container-setup.sh          # creates machine/image/container as needed
```

It builds the `redox-base` image from `podman/redox-base-containerfile`, creates the
persistent container with the same flags `mk/podman.mk` uses (`SYS_ADMIN` + `/dev/fuse`
for RedoxFS assembly, `--network=host`), re-mounts the two volumes above, installs the
SHA256-pinned host toolchain via `podman/rustinstall.sh` **only if `eos-root` doesn't
already carry it**, and seeds `/work/redox`. The tree deliberately never comes from a
host bind mount — macOS virtiofs cannot serve cargo's mmap reads, see
[build-troubleshooting.md](../getting-started/build-troubleshooting.md).

Two flags, and the difference between them matters:

- `--recreate` rebuilds the **container only** and keeps both volumes. Cheap and safe
  (~11 s measured), and the correct response to any "container is broken/missing/has the
  wrong flags" situation.
- `--wipe-caches` additionally deletes `eos-work` and `eos-root`. **The next build takes
  hours.** Reach for it only when you actually want a from-scratch rebuild.

Before trusting a recovered container, run gate 1 — it distinguishes "warm" from
"silently orphaned" in one second:

```sh
scripts/eos-check.sh /work/redox/recipes/core/base/source -p virtio-core
```

A warm tree finishes in well under a second; a cold one starts compiling the world.
The script also verifies `/dev/fuse` is present in the container — a container missing
it execs and compiles fine but **cannot assemble the RedoxFS image**, which surfaces
much later as a confusing `make … all` failure.

If macOS blocks the VM helpers on first start, approve `vfkit`/`krunkit`/`gvproxy`
under **System Settings → Privacy & Security** and re-run.

#### Runner-host storage: the podman machine lives on an external volume

On the current `eos-heavy` mac the podman machine image is **not** on the internal disk.
`~/.local/share/containers` is a symlink to `/Volumes/EOS-Podman/containers`, which is an
**APFS sparsebundle** stored on the external drive (`/Volumes/Project itp/Podman/`).

*Why:* the machine image is 80 GiB nominal / ~39 GiB real and the internal disk had 42 GiB
free — the heavy runner would have wedged the host within one or two full builds. The
external drive is **exFAT**, which has neither sparse files nor POSIX permissions, so a raw
VM image cannot sit on it directly (an 80 GiB sparse file would materialise in full). An
APFS sparsebundle solves both: exFAT only ever sees ordinary 64 MB band files, while the
mounted volume is real APFS.

*The consequence you must remember:* **the sparsebundle has to be mounted before
`podman machine start`**, or podman finds a dangling symlink and every heavy job fails.
A LaunchAgent (`com.ghostt77.container-volumes`, script `~/bin/mount-container-volumes.sh`)
mounts it at login; after re-attaching the drive by hand, run that script. Never unplug the
drive without ejecting while a build is running.

To build nightly: **Settings → CI/CD → Pipeline schedules → New schedule** (e.g. `0 3 * * *`,
target `main`). No schedule variable is needed — `build-image` runs on any schedule whose
`SCHEDULE_TASK` isn't `renovate`, so the heavy build and the Renovate schedule (below) never
cross-trigger.

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
   (A stale/rotated token here makes `renovate` fail with *"Authentication failure"* — the
   job is `allow_failure: true` so it can't block the pipeline, but fix the token to make
   it useful.)
2. **Settings → CI/CD → Pipeline schedules → New schedule** (e.g. nightly) and add a
   schedule **variable** `SCHEDULE_TASK` = `renovate`. The `renovate` job runs only on a
   schedule whose `SCHEDULE_TASK` is `renovate` and only when `RENOVATE_TOKEN` is set, and
   opens MRs for bumps (patch updates auto-merge once CI is green).

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
