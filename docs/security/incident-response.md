# Incident response

This is the playbook for the five incidents that can actually happen to E-OS: a leaked
secret, a compromised dependency, a compromised maintainer account, a malicious
contribution, and a compromised signing key. It is written for **one person**, because
that is who there is (`C-18`) — there is no security team to escalate to, no second
maintainer to page, and no on-call rotation. Every step below is something the maintainer
does personally, in an order chosen so that the irreversible things happen last.

To **report** a vulnerability, see [`../../SECURITY.md`](../../SECURITY.md). That document
is the promise made to reporters; this one is what happens after the promise is triggered.
For day-to-day contributor hygiene see [`../security.md`](index.md); for the token
inventory and the five-layer key map see [`../reference/keys-and-tokens.md`](../reference/keys-and-tokens.md).

## Why this file is not a generic template

Three facts about *this* project decide almost every step, and a template that did not
know them would give the wrong advice:

1. **The build machine is the CI runner and it holds every private key** (`C-11`). The
   `eos-heavy` GitLab runner is a **shell executor running as the maintainer's login
   user** on their Mac (`docs/operations/ci.md` §"Register the runner"), sharing that user's `podman`
   machine and the `eosbuild` container. The six private keys in the inventory below live
   on that same machine. So "code merged to `main`" and "code executing next to the
   signing keys" are separated by one scheduled or tagged pipeline, and nothing else.
2. **CI is not watching right now.** Every GitLab job has failed in ~0 s with
   `ci_quota_exceeded` since 2026-08-28 (`C-7`), which includes `secret-scan` (gitleaks
   over the full history) and `pin-check`. Detection today rests on the *local* pre-commit
   hook and GitHub's push protection, not on a pipeline. Do not plan a response around a
   gate that is currently dead.
3. **One key cannot be rotated, only re-imaged around.** The repo-manifest public key is
   pinned **inside the image**. A client that has it cannot be told about a replacement
   over the package channel, because the client authenticates that channel with the key
   you are trying to replace. `keys/README.md` says this in one sentence: losing it means
   re-imaging every client that pinned the public half.

## 0. Contacts

There is one responder. Listing "roles" separately would be theatre, so the table lists
**channels** instead — the places an incident arrives from or has to be answered into.

| Channel | Address | Used for |
|---|---|---|
| Maintainer / sole responder | `@Gh0s777tt` — `dzierzawskii98.dam@gmail.com` | everything below |
| Private vulnerability intake (preferred) | GitHub Security Advisories on the mirror: *Security → Report a vulnerability* | reports from outside |
| Private vulnerability intake (email) | same address, subject prefix `[E-OS SECURITY]` | reports from outside |
| Source of truth | `gitlab.com/e-os/e-os` (project id `82957024`) | containment, force-push, protections |
| Push-mirror | `github.com/Gh0s777tt/E-OS`; 29 sibling repos also exist on GitHub (`repos.toml`) but only this one is push-mirrored today (`U-158`) | advisories, Pages docs, package hosting |
| Upstream | Redox OS, via the Redox project's own reporting channel | inherited vulnerabilities |
| Account recovery | GitHub Support, GitLab Support | account takeover only |

Deliberately **not** listed: a Redox OS security email address. `SECURITY.md` commits to
helping coordinate an inherited vulnerability upstream, and guessing an address here would
turn that commitment into a wrong address in a crisis. Look it up on the upstream project
at the time, and record what you used in the incident note.

Two quirks worth knowing before you need them:

- **Advisories live on the mirror.** `SECURITY.md` sends reporters to GitHub Security
  Advisories, but GitHub is a read-only push-mirror and GitLab is the source of truth. A
  reporter's private fork/advisory workflow therefore exists on the side of the project
  where code is never merged. That is the correct trade — GitLab's equivalent needs a paid
  tier — but it means a GitHub account compromise takes the *reporting* channel with it.
- **The published security contact is also the account recovery address.** One mailbox is
  the intake for reports and the reset path for both hosts. That is why §4 starts with
  email and not with the code host.

## 1. What an attacker gets — asset inventory

Containment decisions come from this table, so keep it accurate. Everything here was read
out of the tree; where a claim is a *requirement* rather than something the tree proves,
it says so.

### 1.1 Signing keys

| # | Key | Public half | Private half | Rotatable? |
|---|---|---|---|---|
| 1 | Commit/tag signing | `allowed_signers`, git config (`gpg.format = ssh`) | `~/.ssh/` on the build Mac | Yes — cheap |
| 2 | Per-package pkgar ed25519 | `keys/eos-pkg-signing.pub.toml` in this repo. **Not pinned on the client** — see the note below | `build/id_ed25519.toml` inside the `eos-work` podman volume; verified byte-identical copy at `~/.eos-keys/eos-pkg-signing.secret.toml` (`U-216`) | Yes — expensive, see §6.2 |
| 3 | Repo-manifest hybrid ed25519 + ML-DSA-65 | `keys/eos-repo-sign.pub.toml` (4075 B), pinned **inline** into `config/{aarch64,x86_64}/eos.toml` and shipped at `/etc/pkg/eos-repo-sign.pub.toml` | operator store, off-repo, off the project volume | **No** — see §6.3 |
| 4 | Release checksums (minisign) | `keys/eos-release.pub`, fingerprint `8A627C8113176141` | `~/klucze-eos/eos-release.key` (path is the operator's choice) | Yes — cheapest of all, done once already |
| 5 | Secure Boot MOK (`CN=E-OS Secure Boot`, `-days 3650` — so ~2036) | enrolled in each user's firmware | `build/sb-signing/mok.key` in `eos-work` during a signing build; operator copy via `EOS_SB_KEY` | Yes — needs user re-enrolment |
| 6 | Boot verification (kernel + initfs) | `boot.pub.bin` compiled into the bootloader | `build/boot-signing/` in `eos-work`; operator copy via `EOS_BOOT_KEY` | Yes — needs an image rebuild |

**Layer 2 is not a trust anchor, and mistaking it for one is a documented error.** It is
tempting to read `keys/eos-pkg-signing.pub.toml` as something clients pin; `ROADMAP.md`
said exactly that and `U-213` disproved it by reading the code: `pkg-lib`'s
`sync_keys_internal` **downloads** `id_ed25519.pub.toml` from the same host that serves the
packages on every cache miss, and `/etc/pkg/packages.toml` `[pubkeys.local]` is where the
client *caches* what it fetched — not a pin placed by the image. Nothing in
`config/{aarch64,x86_64}/eos.toml` carries that key. Consequence for containment: whoever
holds the package host can substitute their own layer-2 public half and re-sign every
package, so a layer-2 rotation neither repairs a host takeover nor requires an image
rebuild. What actually stops that attack is layer 3 plus the manifest hash — §1.3.

`C-11` counts **four** private keys on the build machine. This table lists six, because it
also counts the SSH signing key and the boot-verification key, which are on that machine
for exactly the same reason and are compromised by exactly the same event. If the Mac is
the incident, treat all six as lost — the difference between four and six changes the
cleanup, not the containment.

**The backup is inside the blast radius.** `V2-MS12` records that the layer-2 backup exists
and is byte-verified, on a *different volume* — but both copies are on the same computer,
and a third copy off that machine is still an open item. The layer-3 secret sits on the
internal disk with mode `0600`. A machine compromise takes original and backup together.
The off-machine copy is the single cheapest thing on this page and it is not done.

### 1.2 Tokens

Four, from [`../reference/keys-and-tokens.md`](../reference/keys-and-tokens.md). Two of them may be the same value.

| Token | Stored in | Blast radius if leaked |
|---|---|---|
| `GITHUB_MIRROR_PAT` | maintainer's shell, **and embedded in the target URL of every GitLab push mirror** | push to every mirrored GitHub repo — today that is this repo alone; see the revocation trap in §3.3 |
| `EOS_GH_TOKEN` | maintainer's shell | `sync-forks.sh --push` against the GitHub forks |
| `GITLAB_TOKEN` | GitLab CI/CD variable (masked, protected) | `api` scope on the source of truth — tags, releases |
| `RENOVATE_TOKEN` | GitLab CI/CD variable (masked, protected) | `api` scope as the dependency bot |

`GITLAB_TOKEN` and `RENOVATE_TOKEN` are deliberately separate so that revoking one does not
break the other, and so that compromising the bot does not hand over releases. Keep them
separate when you re-issue.

### 1.3 What an attacker can and cannot forge today

Useful to know **before** the panic, because half of an incident is deciding what did *not*
happen:

- **Cannot forge the package index.** The hybrid key's public half is pinned in both images
  and the values in `config/x86_64` and `config/aarch64` match `keys/eos-repo-sign.pub.toml`
  character for character (`U-224`, verified with a test signature that also *fails* after
  a single flipped byte). The client fails closed rather than warning and continuing.
- **Cannot substitute package bytes.** Since `U-223`, `install()` and `upgrade()` compare
  the pkgar header hash of the bytes they are about to unpack against the entry in the
  manifest that `verify_repo_manifest()` just verified — and `install` now pulls the index
  at all, which it previously did not. `ManifestHashMismatch`, `PackageNotInManifest`,
  `RepoManifestRollback` and `RepoManifestExpired` are all present in the shipped `pkg`.
  **This is the control that covers the unpinned layer-2 key.** Before `U-223` the two
  blake3 comparisons in `pkg-lib` were both *"do I need to update?"* logic, so a host
  takeover that served its own `id_ed25519.pub.toml` and re-signed every package produced
  "manifest OK, package OK" and installed arbitrary code (`U-213`). Do not treat layer 2 as
  the thing standing in the way; it is layer 3 plus this hash.
- **Can serve a stale index, up to a point.** `serial` is an anti-rollback ratchet and
  `expires` guards against freezing; neither replaces the other. But `expires` is absent
  from a local build, and the anti-rollback marker is an ordinary file next to the pinned
  key — **local root can delete it**. This is protection against a network attacker, not
  against one already on the machine.
- **Can deny service.** Taking the package host offline is not defended against and does
  not need to be.

## 2. The clock

Timings are the maintainer's, not a vendor SLA. They start **when you find out**, which is
the honest part: a single maintainer asleep is an eight-hour gap, and the only thing that
closes it is a client that fails closed, not a human who answers faster.

| Window | What must have happened |
|---|---|
| **T+0 → T+15 min** | **Contain.** Revoke, disconnect, take offline. Do not diagnose first — diagnosis is unbounded, revocation is one click, and a wrongly revoked token costs an afternoon while a wrongly delayed one costs the trust chain. |
| **T+15 min → T+1 h** | **Scope.** What did the credential reach, what was signed with the key, what is already mirrored. Write the timeline down as you go; you will not remember it at T+24 h. |
| **T+1 h → T+24 h** | **Rotate and rebuild.** New keys, new tokens, re-signed artefacts, images rebuilt if a pinned value changed. |
| **T+24 h → T+72 h** | **Notify.** 72 h is not arbitrary: `SECURITY.md` already promises reporters acknowledgement within 72 h, so users get told on no worse a clock than reporters do. |
| **T+72 h → T+7 d** | **Fix the class.** `SECURITY.md` promises an initial assessment in 7 days. Spend this window on the reason it was possible, not on the instance. |
| **≤ 30 d** | **Write it up** as a `U-NNN` CHANGELOG entry, with what was measured and what is still open. `SECURITY.md` promises a fix/mitigation plan in 30 days. |

## 3. Playbook — leaked secret

**Scope:** a token, password, or private key that reached somewhere it should not — a
commit, a paste, a screenshot, a session transcript, a log.

`docs/reference/keys-and-tokens.md` §0 states the rule this playbook exists to enforce: a secret that passes
through assistant tool calls is in the session transcript and must be treated as disclosed
**even if nobody read it**. "Probably not copied" is not a property you can build a supply
chain on.

### 3.1 Contain (T+0)

1. **Revoke at the provider first.** GitHub: *Settings → Developer settings → Tokens
   (classic) → Revoke*. GitLab: *Settings → Access tokens → Revoke*, **and separately**
   delete the value in *Settings → CI/CD → Variables* — revoking the token does not remove
   the variable, and a stale variable makes the next failure look like a bot outage rather
   than a revocation.
2. **Do not start with a history rewrite.** `docs/security/index.md` is right that the secret is
   compromised the moment it is pushed. Rewriting is also structurally hard here: `main` is
   protected on GitLab (push restricted to Maintainers) and force-push is blocked on the
   GitHub mirror, so a rewrite means lifting protections on the source of truth *and* on
   every affected mirror, and anyone who already cloned still has the secret. Rotate first;
   rewrite later, deliberately, if at all.

### 3.2 Scope (T+15 min)

- Which of the four tokens was it, and was it the *shared* GitHub PAT? If
  `GITHUB_MIRROR_PAT` and `EOS_GH_TOKEN` were issued as one value (which `docs/reference/keys-and-tokens.md`
  explicitly allows), one leak is two blast radii.
- Was it key **material** rather than a token? Then this is §6, not §3.
- How far back? `secret-scan` runs with `GIT_DEPTH: 0` precisely so gitleaks sees the whole
  history — but it has not run since 2026-08-28 (`C-7`). Run it locally instead:

  ```sh
  gitleaks detect --source . --no-banner --redact -v
  bash scripts/ci-integrity.sh     # check 10: secret material in tracked files
  ```

  Check 10 exists for this exact moment, and its failure text is already the instruction:
  *"repo-signing SECRET material in tracked files — treat the key as compromised and
  rotate:"*, followed by the files. It matches on the **shape** of the secret — a
  line-initial `[secret_keys]` **and** a 32+ hex-character assignment, both required — not on
  a filename, so renaming the file does not evade it.

### 3.3 The revocation trap you will hit (`GITHUB_MIRROR_PAT`)

A GitLab push mirror is a `remote_mirrors` object with the PAT embedded in the target URL —
that is how `scripts/eos-setup-mirrors.sh` writes them, and it is the only place the
credential is assembled. Scale matters when you plan the cleanup: today **one** mirror exists,
on the meta repo, because `--apply` has never been run for the forks (`U-158`, still open in
`docs/operations/maintenance.md`). Two consequences, and the second one grows with that count:

- **Revoking the PAT stops mirroring silently.** GitLab keeps the mirror object; it just
  stops succeeding. GitHub does not go stale loudly — it goes stale quietly, which looks
  identical to "nothing changed lately".
- **Re-running the setup script does not fix it.** The script skips any repo that already
  has a GitHub mirror (`github mirror already present — skip`). After revoking you must
  **delete** the stale mirror objects before the script will create new ones with the new
  token. Then verify, with the dry run, which needs no credential at all:

  ```sh
  scripts/eos-setup-mirrors.sh            # DRY RUN — lists what is missing
  scripts/eos-repos.sh status | tail -5   # addresses, never secrets
  ```

  `role = "pkg"` repos are skipped by design: a push-mirror would overwrite published
  package content (`U-158`). Do not "fix" that skip while cleaning up.

### 3.4 Re-issue

New tokens, 90-day expiry, minimum scope (`repo` for GitHub, `api` for GitLab), entered in
the provider UI or read into the shell without touching shell history:

```sh
read -rs -p "GitHub PAT: " TOK && export GITHUB_MIRROR_PAT="$TOK" EOS_GH_TOKEN="$TOK" && unset TOK
```

Confirm the **effect**, not the value: mirrors present again, `semantic-release` no longer
skipping, Renovate no longer reporting *"Authentication failure"* (a known symptom of a
stale token, not a bot failure).

## 4. Playbook — compromised maintainer account

**Order matters, and it is not the obvious one.** Start with the mailbox.

### 4.1 Email (T+0)

`dzierzawskii98.dam@gmail.com` is simultaneously the published security contact in
`SECURITY.md` and the recovery address for both code hosts. Whoever holds it can reset the
other two and read every incoming vulnerability report. Change the password, revoke active
sessions and app passwords, re-check the recovery phone/address and the forwarding and
filter rules — a forwarding rule left behind survives a password change and is the quietest
possible persistence.

### 4.2 GitLab — the source of truth (T+15 min)

A GitLab takeover is the worst case, because it reaches everything at once: the account owns
all **30** repositories in `repos.toml` directly — including the 26 forks whose `rev=` pins
this repo builds from — the push mirror carries a tampered `main` onward to the GitHub copy
of this repo, and the `eos-heavy` runner will execute a scheduled or tagged pipeline **as the
maintainer's login user, on the machine holding all six keys**. Containment:

1. Rotate the account password, revoke all sessions, re-enrol 2FA.
2. Revoke every personal and project access token (`GITLAB_TOKEN`, `RENOVATE_TOKEN` at
   minimum) and clear the CI/CD variables.
3. **Pause or unregister the `eos-heavy` runner** before anything else runs on it:

   ```sh
   brew services stop gitlab-runner    # on the runner host
   ```

   This is the step that decides whether an account incident becomes a key incident.
4. Delete the remote mirrors, so a tampered `main` cannot be pushed onward while you are
   still establishing what happened.
5. Verify `main` against your own local clone. Every commit since `1d3c62ea6` verifies `G`
   under SSH signing and GitLab's signature API reports `verified` (`U-152`) — so an
   attacker who pushes without the signing key leaves an unsigned commit, which is
   detectable. An attacker who has the Mac has the signing key too, and this check tells
   you nothing; that is precisely the `C-11` coupling.

### 4.3 GitHub — the mirror, which is not only a mirror (T+15 min)

It is tempting to treat the mirror as disposable because GitLab overwrites it. Do not: the
GitHub account also carries

- **the package host** — `config/aarch64/eos.toml` ships an **active** package source
  pointing at `https://gh0s777tt.github.io/eos-pkg-aarch64/pkg`. (The x86_64 config ships
  the same file with the URL commented out.) A GitHub account takeover is therefore a
  **package-host takeover** for aarch64 installs. What holds the line is §1.3: the attacker
  cannot forge `repo.toml.sig` without the layer-3 secret, and since `U-223` the client
  enforces the manifest's blake3 over the bytes it unpacks. Serving a stale signed index or
  nothing at all is the remaining move.
- **the vulnerability intake** — Security Advisories, per `SECURITY.md`.
- **the docs site** and any published release assets.

Rotate credentials, revoke tokens and OAuth apps, re-enrol 2FA, then check *Settings →
Deploy keys* and *Webhooks* on the affected repos. Force-push is blocked on `main`, which
limits history damage but not Pages content.

### 4.4 Recovery when you are locked out (`C-18`)

There is no second maintainer, so "break glass" cannot mean "ask someone else". It means
**pre-staged material**, and it is the one part of this document that is a requirement
rather than a description of the tree:

- 2FA recovery codes for GitHub and GitLab, printed, stored off the build machine.
- A copy of the layer-2, layer-3 and layer-4 private keys on encrypted media **not in the
  same building as the Mac** — the layer-2 backup is currently on the same computer as the
  original (`V2-MS12`), and the layer-2 secret is stored as **plaintext** (`skey` is 128 hex
  characters, i.e. 64 raw bytes; `docs/reference/keys-and-tokens.md` §6a corrects an earlier claim that the
  cookbook encrypted it), so the medium must be encrypted.
- The list of what is pinned where, which is §1.1 of this file.

If those do not exist, the honest recovery path is provider support with proof of
ownership, and an acceptance that the project is frozen until it completes. Read §6.3
before assuming a frozen project is the worst outcome — it is not.

## 5. Playbook — malicious contribution and compromised dependency

These are one playbook because in this project they are one path. The mechanism that
delivers hostile code is not a pull request; it is a **pin bump**.

### 5.1 Malicious PR / MR

GitHub PRs are not the merge path — commits reach `main` by push on GitLab and the mirror
never merges anything. And GitHub Actions **does not execute for this repository**: a
minimal `on: push` workflow pushed directly to github.com on a fresh branch produced no
workflow run at all, not even a queued one. So today an untrusted PR cannot run workflow
code on this project.

That is containment by accident, and it expires the moment Actions is re-enabled. What will
hold the line then is already written into `.github/workflows/`: `permissions: contents:
read` at the top level with per-job escalation, every third-party action pinned to a 40-char
commit SHA, no `pull_request_target` with a checkout of untrusted code, no `${{ github.* }}`
interpolated into a `run:` block, and `step-security/harden-runner` with egress auditing as
each job's first step. Treat any PR that edits a workflow file as hostile until read line by
line — that is the change that turns a fork PR into code execution.

The real review gap is `C-6`: the gate is configured but bypassed — **every commit went
straight to `main`**, and there is **no required review on either host**. `CODEOWNERS` exists
and is inert by construction, and its own header says why: every owner is the same handle,
GitHub will not let an author approve their own PR, so `require_code_owner_review: true`
would make every PR unmergeable except by an admin bypass. Hence
`required_approving_review_count: 0`. So "reject the malicious PR" is not the control;
"notice the malicious commit" is, and the only thing doing that today is the maintainer
reading their own diff.

If hostile code did land:

1. Revert on GitLab; let the mirror carry the revert.
2. **Assume it ran.** If any tagged or scheduled pipeline fired after the merge, it ran on
   `eos-heavy` as the maintainer's login user, next to six private keys — go to §6 and treat
   every key as compromised. Do not reason your way out of this; the pipeline either ran or
   it did not, and the answer is in the GitLab job list.
3. Recreate the build container before trusting another build:
   `scripts/eos-container-setup.sh --recreate` (container only, ~11 s, keeps both volumes).
   Reach for `--wipe-caches` only if you believe the 37 GB of cached build state itself was
   touched — the next build then takes hours.

### 5.2 Compromised dependency

Two manifests, deliberately different strictness, and the asymmetry is load-bearing here:

- `tools/eos-repo-sign/Cargo.toml` — E-OS-owned. Full `cargo-deny check` (advisories,
  licences, bans, sources), blocking.
- `Cargo.toml` at the root — the vendored `redox_cookbook` that builds every image.
  `cargo-deny check advisories` **only**: licences and sources are upstream's choices, and
  gating them would re-litigate a vendored tree rather than protect this one.

The precedent is in the tree and worth reading before you decide how seriously to take an
advisory: the first `cargo-deny` run over the root manifest (`U-159`) failed immediately on
**RUSTSEC-2026-0204**, an invalid pointer dereference in `crossbeam-epoch 0.9.18` reached
through `ignore` / `rayon-core` → `blake3` → `pkgar`. That is a dependency of the code that
hashes and verifies packages. It was fixed with `cargo update -p crossbeam-epoch` to 0.9.20.

Response:

1. Confirm reachability before rotating anything. `cargo deny check advisories` names the
   path; a crate present in the lockfile but not on any executed path is a different
   incident from one under `blake3`.
2. Update and re-run both manifests. `cargo-deny` is itself a gate, so its release asset is
   SHA256-pinned (0.20.2, `9f12ed4c…`) — download, verify, extract, never pipe a tarball
   into `tar`. If you bump it, bump the hash in the same commit.
3. Know that `C-13` is real: Dependabot reports 0 while `osv-scanner` finds live
   advisories. A green Dependabot is not evidence.
4. Renovate is `allow_failure: true` and fires only on its own schedule
   (`SCHEDULE_TASK=renovate`). A dependency bot must never block the OS pipeline — but that
   also means a silent Renovate is indistinguishable from a working one. Check it manually
   during an incident.

**The bigger dependency surface is not crates.** It is the 26 recipe pins across the 30
repositories in `repos.toml`. A hostile commit at a fork tip enters E-OS the moment someone
bumps `rev=`. The gate is `scripts/eos-repos.sh pins --strict` (`pin-check`) — which has
been dead since 2026-08-28 (`C-7`). Run it by hand before any pin bump:

```sh
bash scripts/eos-repos.sh pins --strict
bash scripts/ci-integrity.sh          # check 6: every forked recipe builds from its fork
```

## 6. Playbook — compromised signing key

Read §1.1 first, then find the layer. **The layers are independent and none substitutes for
another** — rotating the wrong one costs a republish and fixes nothing.

Common first step, all layers: stop the runner (`brew services stop gitlab-runner`) and stop
publishing. A signing pipeline that keeps running during a key incident produces artefacts
you will have to invalidate twice.

### 6.1 Layer 1 — commit/tag signing (SSH)

Cheapest. Issue a new key, update `allowed_signers` and the host-side signing key, and
**keep the old public key in `allowed_signers`** so historical commits still verify — the
same reasoning that put the retired minisign key in `keys/wycofane/` rather than deleting
it. Note in the incident record which commit is the first one signed by the new key; that
boundary is what a future reader needs.

### 6.2 Layer 2 — per-package pkgar key

**What breaks:** `pkgar` has no keyring and no revocation list (`R-711`). There is no way to
tell a client "the old key is bad". Rotation means **re-signing and republishing every
package**, and every artefact signed by the old key stays as trustworthy as the attacker
made it.

**Measured cost:** at `U-213` the republish was **642 MB** and invalidated **78** published
artefacts. The index measured at `U-224` carries **85** packages, so budget upward.

**What protects you during rotation:** `src/cook/package.rs` refuses to silently mint a new
key when `keys/eos-pkg-signing.pub.toml` records one — a build fails loudly instead of
producing packages under an unannounced key. The check compares the key read from the
**finished `.pkgar` header** (bytes `[64..96)`), not the committed public half, because the
secret is what signs; an earlier version of that gate compared the public halves and would
have let a swapped `.pub.toml` through in silence. Do not "simplify" it back.

**Steps:** generate the new key on the host, record the new public half in
`keys/eos-pkg-signing.pub.toml`, rebuild, republish every package, and back up the new
secret **before** the first build that uses it — `build/` is wiped routinely and the loss is
silent. There is **no image pin to update**: clients fetch the layer-2 public half from the
package host and cache it in `/etc/pkg/packages.toml` `[pubkeys.local]` (§1.1), so the new
key reaches them with the republish. That is also why this rotation is hygiene rather than
containment — if the incident is a package-host takeover, rotating layer 2 changes nothing
the attacker cannot redo, and `U-213` says so in as many words.

### 6.3 Layer 3 — repo-manifest key (the one that does not rotate)

**Read this before deciding anything else.** The public half is pinned *in the image* at
`/etc/pkg/eos-repo-sign.pub.toml`. A client that has it verifies the package index against
it and, since the pin exists, treats a missing or invalid `repo.toml.sig` as a **hard
error** rather than a warning. That is the property you wanted — and it is exactly why you
cannot push a replacement key: the only channel to the client is the one the old key
authenticates.

`keys/README.md` states the consequence without softening it: **losing this key means
re-imaging every client that pinned the public half.** `eos-repo-sign keygen` deliberately
refuses to overwrite an existing file, so the key cannot be "regenerated in place" either.

Response:

1. **Do not generate a replacement first.** Establish whether the secret was actually
   reachable. It lives off-repo, off the project volume (the project directory is exFAT
   mounted `noowners`, where `chmod` is inert and `0600` is not honoured — which is why the
   key is not there). If the incident is confined to the repository or to a token, layer 3
   may be untouched.
2. If it was reachable, **it was compromised**. Generate a new pair, pin it with
   `scripts/eos-pin-repo-key.sh` (which edits `config/{aarch64,x86_64}/eos.toml`, is
   idempotent, and **refuses a secret key file** — a config is world-readable in every
   shipped image), then `scripts/eos-sync-buildtree.sh --apply` and rebuild. Skipping the
   sync has already once produced a correctly-pinned key that never reached the image,
   without a single error (`U-185`).
3. **Tell users to reinstall, in plain words.** Template in §7.4. There is no
   over-the-air path and pretending otherwise is worse than the bad news.
4. Prove the result rather than assuming it: on a booted image, `/etc/pkg/` contains
   `eos-repo-sign.pub.toml` at the same byte size as the file in `keys/`, and boot shows no
   `no pinned repo-manifest key … NOT signature-verified` warning.

**How much this would cost today.** The first signed publish (`R-008`) **has happened**: at
`U-209` the operator published aarch64 — `repo.toml` hybrid-signed (ed25519 64 B +
ML-DSA-65 3309 B), 78 packages, verified live with HTTP 200 at
`https://gh0s777tt.github.io/eos-pkg-aarch64/`. So there is a real signed channel this key
authenticates, and `config/aarch64/eos.toml` points installs at it. x86_64 is not published
(at `U-223` that host still served only a README), so the aarch64 images are the exposure.
What is still unmeasured is the installed base — nothing in this tree counts machines that
pinned the anchor, and until something does, "small" is an assumption, not a finding. Rehearse
§6.3 while the number is plausibly small rather than after it stops being.

### 6.4 Layer 4 — minisign release key

The cheap one, and there is a worked example: it was rotated at `U-205` from fingerprint
`DCEC85BA6057ED4A` to `8A627C8113176141`, and the retired public key was **moved** to
`keys/wycofane/eos-release-DCEC85BA6057ED4A.pub` rather than deleted, so signatures made
before the rotation can still be checked. Repeat that shape.

It is cheap for one measured reason: the key is **not in the image**. An earlier version of
`docs/reference/keys-and-tokens.md` claimed it was, on the strength of two `grep` hits that both turned out to
concern `/usr/share/eos/eos-release`, the release *identifier*. A probe of a running image
found no minisign key (`U-192`). So rotation needs **no image rebuild and no client
re-imaging**.

What it does cost: every `SHA256SUMS` signed with the old key stops verifying under the new
one, and `docs/getting-started/install.md` and `docs/security/hardening.md` instruct users to verify downloads with
the committed key — so those instructions change in the same commit as the key, or the
documentation starts promising a check that cannot pass. `SHA256SUMS` also covers the
CycloneDX SBOM (`scripts/make-release.sh` folds it into the same signed file), so re-signing
a release re-covers its bill of materials.

```sh
mkdir -p keys/wycofane
git mv keys/eos-release.pub keys/wycofane/eos-release-8A627C8113176141.pub
minisign -G -p keys/eos-release.pub -s ~/klucze-eos/eos-release.key
chmod 600 ~/klucze-eos/eos-release.key
VERSION=<version> MINISIGN_SECRET_KEY=~/klucze-eos/eos-release.key scripts/make-release.sh
```

`scripts/make-release.sh` fails closed without a key: an unsigned release needs an explicit
`EOS_ALLOW_UNSIGNED=1` (`U-120`). Do not set it during an incident.

### 6.5 Layers 5 and 6 — Secure Boot MOK and boot verification

The MOK certificate (`CN=E-OS Secure Boot`, generated `-days 3650` per
`scripts/eos-sb-setup-key.sh`, so valid to roughly 2036) is enrolled in each user's
firmware, so a new certificate requires each user to enrol it — a manual, physical step
E-OS cannot perform for them. What E-OS *does* have is its own version-revocation path: the
UEFI binaries carry an SBAT section (`eos-bootloader,1,E-OS,eos-bootloader,0.1.0`), so a
compromised bootloader version can be revoked without waiting for a DBX entry that only
Microsoft can publish. Bump the SBAT generation as part of the response.

Both keys are placed by helper scripts that **invalidate the affected packages** so the next
build actually re-cooks and re-signs them (`scripts/eos-sb-setup-key.sh`,
`scripts/eos-boot-setup-key.sh`). This matters more than it sounds: a cached bootloader
package is not re-cooked, and a rebuilt image then ships the *previous*, old-key payload
while looking entirely successful — that is how a rebuilt install once booted to *Access
Denied* under Secure Boot (`U-208`). Verify the signature on the artefact, not the exit code
of the build.

## 7. Communication templates

These are meant to be sent as written, with the bracketed facts filled in. Nothing else in
them is a placeholder. Keep the honesty level: this project's own audit documents correct
their previous claims out loud, and a security notice that hedges will be trusted less than
one that does not.

### 7.1 Acknowledging a vulnerability report (within 72 h)

> Subject: Re: [E-OS SECURITY] <reporter's subject>
>
> Thank you for the report, and for sending it privately.
>
> I have received it and I am treating it as <critical / high / medium / low>. E-OS is a
> single-maintainer project, so I am the only person handling this; that means there is no
> delay from coordination, and also that I will not have an answer at every hour of the day.
>
> Next steps and the dates I am holding myself to:
> - Initial assessment, including whether I can reproduce it: by <date, ≤ 7 days from today>.
> - A fix or a mitigation plan: by <date, ≤ 30 days from today>, sooner if it is exploitable
>   remotely or affects the signing chain.
> - Disclosure timing: your call as much as mine. I support coordinated disclosure and will
>   credit you by <name / handle / "not at all", per your preference>.
>
> If any of that slips, I will tell you it slipped rather than going quiet.
>
> One question so I scope this correctly: <the single most useful question — affected commit,
> architecture, whether the package channel is involved>.
>
> — <maintainer>, E-OS

### 7.2 Leaked credential — internal record

Not sent anywhere; written into the incident file at T+15 min so the timeline exists before
memory rewrites it.

> Incident: leaked credential
> Detected: <timestamp, timezone> via <push protection / gitleaks pre-commit / manual review /
>   third-party report>
> Credential: <GITHUB_MIRROR_PAT / EOS_GH_TOKEN / GITLAB_TOKEN / RENOVATE_TOKEN / other>
> Exposure window: <first exposure> → <revocation>, i.e. <duration>
> Exposure surface: <public commit on main / mirrored to GitHub / assistant session transcript /
>   screenshot / log>
> Revoked at: <timestamp> — provider confirmed: <yes/no>
> Shared value? <yes — same PAT also used as X / no>
> Evidence of use: <checked GitLab audit events and GitHub security log; found none / found ...>
> Mirrors: <deleted and recreated / untouched — with reason>
> Re-issued at: <timestamp>, scope <repo / api>, expiry <date>
> Still open: <e.g. history rewrite deliberately not performed, because ...>

### 7.3 Public notice — compromised release signing key (layer 4)

Post as a GitHub Security Advisory, and repeat it verbatim on the release page.

> **E-OS release signing key rotated after compromise — verify downloads with the new key**
>
> **What happened.** The minisign private key used to sign `SHA256SUMS` for E-OS releases was
> exposed on <date>. I am treating it as compromised. It has been replaced; the old public
> key `<old fingerprint>` is retired and kept at `keys/wycofane/` so signatures made before
> the rotation can still be checked.
>
> **What this means for you.** A `SHA256SUMS.minisig` signed with the old key can no longer
> be taken as proof that a download came from this project — anyone holding the exposed key
> could have produced one. This affects release <version(s)>.
>
> **What it does not mean.** The signing key is not in the E-OS image and never was, so no
> installed system trusts it and nothing needs reinstalling because of this. The package
> repository uses a different key entirely and is unaffected.
>
> **What to do.**
> 1. Fetch the new public key from `keys/eos-release.pub` in the repository (fingerprint
>    `<new fingerprint>`).
> 2. Re-download `SHA256SUMS` and `SHA256SUMS.minisig` for your release — they have been
>    re-signed.
> 3. Verify, then check the images:
>    ```
>    minisign -Vm SHA256SUMS -p eos-release.pub
>    sha256sum -c SHA256SUMS
>    ```
> 4. If a download fails to verify, do not run it. Report it at the address in `SECURITY.md`.
>
> **Timeline.** Exposure <date/time>. Detected <date/time>. Key rotated <date/time>. Releases
> re-signed <date/time>. This notice <date/time>.
>
> **Why it was possible, and what changed.** <one honest paragraph — no vague "we have taken
> steps"; name the cause and the specific change.>

### 7.4 Public notice — compromised repo-manifest key (layer 3)

The one with genuinely bad news. Do not soften it.

> **E-OS package-repository signing key compromised — installed systems must be reinstalled**
>
> **What happened.** The private key that signs the E-OS package index (`repo.toml`) was
> compromised on <date>. That key's public half is pinned inside every E-OS image, at
> `/etc/pkg/eos-repo-sign.pub.toml`. Your installed system trusts it, and there is no way for
> me to replace it remotely: the only channel to your machine is the package channel, and
> your machine authenticates that channel with the key I would need to replace.
>
> **What this means.** Until you reinstall, an attacker holding that key could sign a package
> index your system would accept as genuine. Per-package signatures and the content hashes in
> the index are checked, but they are checked against an index that key can forge.
>
> **What to do.**
> 1. Stop installing and upgrading packages on affected systems now: `pkg` operations are the
>    exposed path.
> 2. Reinstall from an image built after <build date / commit>, which pins the new key. Verify
>    the download against `SHA256SUMS` and its minisign signature first — that key is separate
>    and is not affected.
> 3. After reinstalling, confirm the new anchor is in place: `/etc/pkg/eos-repo-sign.pub.toml`
>    should be present, and boot should show no "not signature-verified" warning.
>
> **Affected:** images built between <date> and <date> — check with
> `sha256sum /etc/pkg/eos-repo-sign.pub.toml` and compare against <value published here>.
>
> **Why reinstalling is the only option.** This is a documented property of the design, not a
> surprise: pinning the key in the image is what makes a forged or missing index a hard
> failure instead of a warning, and the cost of that guarantee is that the anchor can only be
> replaced by replacing the image. That trade is written down in `keys/README.md`.
>
> **Timeline and cause.** <dates> — <honest cause>.

### 7.5 Public notice — maintainer account compromise

> **E-OS maintainer account compromised on <host> — what to distrust**
>
> **What happened.** My <GitLab / GitHub> account was compromised between <date/time> and
> <date/time>. During that window an attacker could <push to the source of truth / alter the
> mirror / alter the published package host / read private vulnerability reports>.
>
> **What to distrust.** Anything obtained from <host> in that window: <clones, release assets,
> package downloads, docs>. Specifically: <list the concrete artefacts>.
>
> **How to check what you have.** Every commit on `main` since `1d3c62ea6` is SSH-signed, so
> `git log --show-signature` against the project's `allowed_signers` will show an unsigned or
> differently-signed commit if one was introduced. (On the GitHub mirror commits may read
> *Unverified* for an unrelated reason — the signing key's registration there is unconfirmed
> — so check locally, not by the badge.) Release images are covered by `SHA256SUMS` and its
> minisign signature: verify against `keys/eos-release.pub`, fingerprint `<fingerprint>`.
>
> **Current status.** Account recovered <date/time>. Tokens revoked and re-issued. The CI
> runner was stopped at <time> and <did / did not> execute anything during the window.
> Signing keys <are / are not> believed affected — <one sentence of reasoning>.
>
> **If you reported a vulnerability privately to this project between <dates>,** assume the
> report was readable by the attacker and treat your own disclosure timeline accordingly. I am
> sorry, and I will contact you individually.

### 7.6 Notifying upstream (inherited vulnerability)

> Subject: [SECURITY] <component> — <one-line impact>
>
> Hello,
>
> I maintain E-OS, a hardened downstream distribution of Redox OS. I have found what I
> believe is a security issue in <component> that originates upstream rather than in our
> changes, so you should have it first.
>
> Affected: <upstream path / file / function>, present at <upstream revision>.
> Impact: <what an attacker gains, concretely>.
> Reproduction: <steps, or the attached PoC>.
> Our exposure: E-OS pins <fork> at <rev>, which contains the same code.
>
> I have not disclosed this publicly and I am not planning to until you have had a chance to
> respond. If you would prefer a different channel for this, tell me and I will use it.
>
> — <maintainer>, E-OS

## 8. Closing an incident

An incident is closed when all four of these are true, not when the alarm stops:

1. The credential or key is revoked **and** its replacement is in use and verified by
   effect — mirrors re-created, a signature checked against the new public half, an image
   probed for the new pin.
2. `bash scripts/ci-integrity.sh` reports `integrity: PASS`, and you ran it rather than
   assuming the pipeline did — it has not run in CI since 2026-08-28 (`C-7`).
3. The timeline from §7.2 is written down, including the parts that reflect badly on the
   process.
4. A `U-NNN` entry lands in `CHANGELOG.md` saying what was measured, what changed, and what
   is still open. This project's changelog corrects its own earlier claims when they turn
   out to be wrong (`U-213`, `U-224`); an incident entry that only lists successes is not in
   that tradition and is not worth writing.

## 9. What this playbook does not cover

Stated plainly, because a playbook that implies more coverage than it has is worse than a
short one:

- **Detection.** Nothing here monitors. `secret-scan` and `pin-check` are dead (`C-7`), the
  GitHub workflows in this repository do not execute (Actions produce no runs for this
  repository at all), and so no SAST result exists (`C-15`) even though CodeQL and semgrep
  are now configured in `.github/workflows/security.yml` — configured is not running, and
  `C-15` stays open until a run produces a finding. Every playbook above begins at
  "you found out", and how you find out is unsolved.
- **An attacker already local on the build machine.** The anti-rollback marker is a plain
  file that local root can delete; the signing keys are files that local root can read.
  Secure Boot does not answer this either, and it is worth being exact about why, because
  Secure Boot *does* work here (§6.5, proven end-to-end with a negative control at `U-207`
  and `U-208`): it proves the boot chain was signed, not that the running system is
  unmodified. The layer that would say that is **measured boot / TPM 2.0**, which does not
  exist — `R-913`, roadmapped as `V2-N02` and not started. `docs/reference/keys-and-tokens.md` §6a calls this
  "layer 5"; §1.1 of this file numbers the *keys*, where 5 is the Secure Boot MOK. Two
  different numbering schemes, one of them about a layer that has no key because it does not
  exist yet.
- **Legal, regulatory or user-notification obligations.** Out of scope; if E-OS ever
  acquires users whose jurisdiction imposes them, this section stops being adequate.
- **A second responder.** `C-18` is not a gap this document can close. It can only make the
  gap explicit and pre-stage what one person needs to act alone.
