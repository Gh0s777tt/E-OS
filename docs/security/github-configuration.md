# GitHub configuration — the settings that no file in this repo can carry

Everything here lives in GitHub's database, not in the tree. A workflow file can be
reviewed in a merge request; "secret scanning is on" cannot. This page is the record of
what that state is supposed to be, why, and how to prove it from a terminal.

Every step is given twice: a click path for the browser, and a `gh api` call. The
scripted half is implemented in
[`scripts/setup-github-security.sh`](../../scripts/setup-github-security.sh) — start with
`scripts/setup-github-security.sh --dry-run`, which changes nothing and prints the
current value of every setting it would touch.

- **Repository:** `Gh0s777tt/E-OS` (public, personal account — not an organisation)
- **Source of truth:** `gitlab.com/e-os/e-os` (project id `82957024`)
- **Default branch:** `main`

---

## 0. Read this first — GitHub is a push-mirror, so most of this protects nothing here

`gitlab.com/e-os/e-os` is the source of truth and `github.com/Gh0s777tt/E-OS` is a
push-mirror of every branch (ADR-0001; `README.md` says so at the top of the page). Code
does not arrive at GitHub through a pull request. It arrives because GitLab pushed it,
after it was already merged, already published, already mirrored to thirty other
repositories.

Three consequences, and the second one is the reason this section is first.

### 0.1 A branch rule on the mirror gates nothing

There is no pull request to block. By the time a commit reaches `main` on GitHub the
decision has been made somewhere else. A GitHub ruleset requiring review here is a rule
that is evaluated after the event it claims to control, on a copy of it.

`.github/CODEOWNERS` is in this repository and lists `@Gh0s777tt` for every path. It has
never caused a review, because a CODEOWNERS file only does anything on a pull request and
there have been none. `README.md` already states this plainly: *"`CODEOWNERS` exists but
is advisory"*.

### 0.2 A branch rule on the mirror can *break* mirroring

This is the part that costs you something. GitLab's push mirror authenticates as one
account and pushes directly to `refs/heads/*`. A GitHub rule that rejects a direct push
rejects **the mirror**, and the failure surfaces on GitLab as a red mirror status that
nobody is watching, hours or days after the mirror silently stopped.

| Rule | What it does to the mirror push |
|---|---|
| Require a pull request before merging | Rejects it. Every push. The mirror is a direct push by definition. |
| Require status checks to pass | Rejects a push whose head commit carries no passing check run — i.e. the moment GitLab pushes faster than Actions can start. |
| Require signed commits | Rejects every commit GitHub reads as *Unverified*. **This is today's state, not a hypothetical** — see 0.3. |
| Restrict creations | Rejects the first push of any new branch. The mirror mirrors *every* branch. |
| Require linear history | Rejects a push introducing a merge commit, which is a GitLab-side merge-method decision, not a GitHub one. |
| Block force pushes | Rejects a mirror push only if the GitLab mirror is set to overwrite diverged branches. Harmless otherwise — and worth having, see 3.6. |
| Restrict deletions | Blocks branch deletions from propagating. Harmless; the mirror keeps a stale branch instead of losing history. |

### 0.3 The signed-commits trap, concretely

`CLAUDE.md` §10.1 records the measured state: commits **are** SSH-signed, GitLab's API
reports them `verified`, and **GitHub is unconfirmed** because the signing key has never
been registered on the GitHub account as a *signing* key (the `gh` token in use lacked
the `admin:ssh_signing_key` scope). GitHub cannot verify a signature made with a key it
does not know about, so it renders those commits *Unverified*.

Turning on "require signed commits" on the mirror today would therefore reject **every**
mirror push — not because the commits are unsigned, but because the mirror was never told
which key signs them. Fix the key registration first (§3.4), confirm on the GitHub UI that
recent commits read *Verified*, and only then consider the rule.

### 0.4 Bypass actors make the rule vacuous anyway

The obvious repair for 0.2 is to add the mirroring identity to the ruleset's bypass list.
On this repository the mirroring identity *is* the maintainer's account, which is also the
only account with write access. A ruleset that exempts the only actor who could violate it
is a decoration. This project has a name for that: **a check that can only pass is not a
check.**

### 0.5 So where does each control actually live?

| Control | Real gate (GitLab) | On the mirror |
|---|---|---|
| No direct pushes to `main` | Settings → Repository → Protected branches: *Allowed to push* = **No one**, *Allowed to merge* = **Maintainers** (`docs/ci.md` §4) | Ruleset in evaluate mode, or off |
| Review before merge | Settings → Merge requests → approvals required | Advisory only — no PRs exist |
| CODEOWNERS review | GitLab Code Owners *approval* is a Premium feature; there is no `.gitlab/CODEOWNERS` in this repo at all | `.github/CODEOWNERS` — advisory |
| CI must pass before merge | Settings → Merge requests → **Pipelines must succeed** (`only_allow_merge_if_pipeline_succeeds`) — currently **off**, that is finding C-6 / `R-F12` | Required status checks — evaluate only |
| Linear history | Settings → Merge requests → merge method *Fast-forward* or *Semi-linear* | Rule can reject the mirror |
| No force-push | Protected branch: *Allowed to force push* off | Safe to enable (see 3.6) |
| Signed commits | Server-side rejection of unsigned commits is a GitLab Premium push rule; on Free the enforcement is local — `commit.gpgsign = true` plus the `lefthook` hooks | Blocked on §3.4 first |
| Secret detection | `secret-scan` job, gitleaks over full history (`GIT_DEPTH: 0`) | **Genuinely useful here** — §4 |
| Dependency alerts | Renovate + `cargo-deny` in `rust-checks` | **Genuinely useful here** — §5 |
| Private vuln reports | — | **Only here.** `SECURITY.md` already points reporters at GitHub — §6 |

The last three rows are the point of this document. Detection and reporting work fine on
a copy of the tree; *enforcement* does not. Spend the effort where it lands.

---

## 1. Prerequisites

```sh
gh auth status            # must be authenticated as the repository owner
gh --version              # 2.96.0 was used to write this page
jq --version              # the script parses API responses with jq
```

Token permissions needed by the scripted steps:

| Kind | Grant |
|---|---|
| Classic PAT | `repo` — measured sufficient for every read and write on this page, webhook inventory included. Add `admin:repo_hook` only if the hook listing is refused. |
| Fine-grained PAT | *Administration*: read+write, *Metadata*: read, *Webhooks*: read |

Two things this document will not tell you to do:

- **Do not park an admin PAT in Actions secrets.** `.github/workflows/scorecard.yml`
  already refuses one for exactly this reason, and says why in its header: a long-lived
  admin token stored to raise a score is a worse trade than the score.
- **Do not run the script with a token you cannot rotate.** Everything below is a one-time
  administrative action from a workstation, not something CI should hold credentials for.

### 1.1 Measured state, 2026-08-30

Read off the live repository with `scripts/setup-github-security.sh --dry-run`. Recorded
so that the sections below are corrections to a known state rather than instructions
issued into the dark — and so the next reader can tell what has moved.

| Setting | Measured | Section |
|---|---|---|
| Actions | **enabled**, `allowed_actions: all` | §2, §7 |
| Actions allowlist | none — every action on GitHub is permitted | §7 |
| Default workflow token | **`write`**, and Actions **may approve pull requests** | §7.1 |
| Secret scanning | enabled | §4 |
| Push protection | enabled | §4 |
| Dependabot alerts | enabled | §5 |
| Dependabot security updates | enabled | §5 |
| Private vulnerability reporting | **off** | §6 |
| Environments | one — `github-pages`; **`prod` returns 404** although `release.yml` declares it | §7.2 |
| Rulesets | none | §3 |
| Deploy keys | none | §12.2 |
| Collaborators | one — `Gh0s777tt` (`admin`) | §13 |
| Webhooks | one, active, to `webhook.zenhub.com` | §12.2 |
| Actions secrets | one — `MINISIGN_SECRET_KEY` | §11 |
| `sha_pinning_required` | `false` (field present in the `actions/permissions` response) | not addressed below — see note |

Five of those rows are the work: no allowlist, a write-scoped default token that can
approve pull requests, private vulnerability reporting off, an environment a workflow gates
on that does not exist, and a release-signing secret sitting on a mirror that cuts no
releases.

The last row is recorded because it was in the response, not because this page has an
opinion on it: `sha_pinning_required` would enforce at the repository what every workflow in
this suite already does by hand. It has **not** been tested — whether it is writable on a
personal account, and what it does to a `uses:` that carries a sub-path, are both unknown
here. Do not turn it on from a document that has not measured it.

The last row of the "measured" column is also the answer to a question this document
opened with: `Gh0s777tt` is the only account with access to the repository. That is not a
finding this page can close — it is §13.

---

## 2. Step 0 — Actions, and the files that still say it is off

The workflow suite in `.github/workflows/` is the remediation for **C-7**: every GitLab
gate has been failing in 0 s with `ci_quota_exceeded` since 2026-08-28, and Actions on a
public repository has no minute cap. That only works if Actions is on.

Measured today, it already is: `enabled: true`, `allowed_actions: all`. So the switch is
not the work — the allowlist in §7 is, and so is the documentation.

> **Corrected in place, and the correction is the point.** The first revision of this
> section listed exactly four files and named `docs/ci.md`, `.github/dependabot.yml` and
> `SECURITY.md` among them. All three had **already been fixed** by the time that revision
> was written; the real list is ten files and none of those three is on it. So the section
> whose job was to catch a stale claim was itself the stale claim, in both directions at
> once — three innocent files accused, nine of the ten guilty ones missed. Only
> `README.md` was both named and correct.
> `.github/workflows/security.yml:27-29` had spotted it first and says so in its header.
> Recorded rather than silently rewritten, per `CLAUDE.md` §2 rule 4.

**Already corrected — do not "fix" these again:**

| File | What it says now |
|---|---|
| `.github/dependabot.yml` | its header records that the `github-actions` ecosystem came *back* because `.github/workflows/` exists again (§5) |
| `SECURITY.md` | the measured claim — GitLab out of quota, and "Actions do not execute on this account today" — not the account-policy one |
| `docs/ci.md` | `.github/workflows/` "runs on the read-only mirror"; both pipelines are described, both as currently not running |

**Still asserting it** — `grep -rn 'account-wide'` over tracked files, 2026-08-30, with the
deliberately historical records (`CHANGELOG.md`, `docs/audit/`) excluded:

| File:line | |
|---|---|
| `.gitlab-ci.yml:2` | *"GitHub Actions is disabled account-wide (ROADMAP R-004)"* — this one is quoted by two workflow headers, so it propagates |
| `README.md:47` | *"(GitHub Actions is off account-wide)"*, in the header badge line |
| `ROADMAP.md:92` | *"GitHub Actions is disabled, so the old `release.yml` never ran"* |
| `docs/MAINTENANCE.md:17` | *"All CI runs on GitLab (GitHub Actions is disabled account-wide)"* |
| `docs/ecosystem.md:96` | same, plus *"GitHub is a visibility mirror only"* |
| `docs/install.md:8` | *"GitHub Actions is disabled on the account (see ROADMAP R-004)"*, inside the copy-pasteable install block |
| `docs/security.md:55` | *"`.github/workflows/` no longer exists (Actions are disabled account-wide)"* — **wrong twice**: the directory exists and holds nine files |
| `docs/reality-ledger.md:3`, `:101` | the ledger's own framing premise |
| `docs/update-system-design.md:145` | *"so R-1003 … and tag-signing are dead"* |
| `keys/README.md:85` | *"disabled account-wide (see `ROADMAP.md`, R-004)"* |

Two workflow headers (`scorecard.yml:15`, `security.yml:26`) cite `.github/dependabot.yml`
as still carrying the claim. It no longer does; those citations need the same pass.

Leaving these uncorrected is how a document starts lying — and they have already been
wrong for some time, which is worse than being about to become wrong. Correct them in the
same change as the allowlist. Note what *stays* true and must not be over-corrected:
Actions is **enabled** and **has still never produced a run on this repository**
(`_canary.yml` is the standing measurement). "Enabled" and "works" are different claims.

**Account level** (<https://github.com/settings/actions> → *Policies*). Nothing to do
here today: the repository-level query above answers `enabled: true`, and a repository
cannot enable what the account forbids, so the account policy already permits it. Check
this page first if Actions is ever refused at the repository level.

**Repository level** — this is what narrows `all` to `selected`:

Settings → Actions → General → *Actions permissions* → **Allow `Gh0s777tt/E-OS`, and
select non-`Gh0s777tt` actions and reusable workflows** (the allowlist in §7).

```sh
gh api --method PUT repos/Gh0s777tt/E-OS/actions/permissions \
  -f enabled=true -f allowed_actions=selected
gh api repos/Gh0s777tt/E-OS/actions/permissions          # verify
```

---

## 3. Branch protection and rulesets

Read §0 before doing anything in this section. The default position for this repository is
**skip** — the script will not create an enforcing ruleset unless you ask it to by name:

```sh
scripts/setup-github-security.sh --branch-ruleset skip      # default
scripts/setup-github-security.sh --branch-ruleset evaluate  # record violations, reject nothing
scripts/setup-github-security.sh --branch-ruleset active    # ENFORCE — read 0.2 first
```

Evaluate ("dry run") mode is an organisation feature on GitHub Team and Enterprise Cloud
plans. On a personal account the API will refuse it. The script reports that refusal as a
plan limitation and stops — it does **not** quietly fall back to `active`, because falling
back to `active` is the thing that breaks the mirror.

### 3.1 Click path

Settings → Rules → Rulesets → **New ruleset → New branch ruleset**

- Name: `eos-main`
- Enforcement status: **Evaluate** if offered, otherwise leave **Disabled** until §0.2 has
  an answer for your mirror configuration
- Target branches → **Include default branch**
- Rules: tick the ones you have decided on from the table below

### 3.2 Scripted

```sh
REPO=Gh0s777tt/E-OS
gh api --method POST "repos/$REPO/rulesets" --input - <<'JSON'
{
  "name": "eos-main",
  "target": "branch",
  "enforcement": "evaluate",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["squash", "rebase"]
      } },
    { "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [ { "context": "REPLACE-ME" } ]
      } }
  ]
}
JSON
```

Updating an existing ruleset is `PUT repos/$REPO/rulesets/{id}`; find the id with
`gh api "repos/$REPO/rulesets" --jq '.[] | "\(.id) \(.name)"'`. The script does this
lookup itself, which is what makes it idempotent — re-running it updates the ruleset in
place instead of creating `eos-main (2)`.

### 3.3 Required approvals — why "2" is not available here, and what to set instead

The target posture is two approving reviews plus a CODEOWNERS review. Neither is reachable
on this project, and the reason is not laziness:

- GitHub does not let the author of a pull request approve it.
- This project has **one** maintainer. One maintainer can produce zero approvals on their
  own work.
- Therefore any `required_approving_review_count` ≥ 1 makes every pull request unmergeable
  except by an administrator bypassing the rule — which is 0.4 again, with extra steps.
- `require_code_owner_review: true` has the same shape: `.github/CODEOWNERS` names
  `@Gh0s777tt` for `*`, so it demands an approval from the person who wrote the change.

GitLab is not a way out: it has the same author-cannot-approve behaviour (*Prevent
approval by author*), and Code Owner **approval** is Premium-only there.

**Honest interim setting**, which is what the script writes by default:

| Parameter | Interim | Target, once a second maintainer exists |
|---|---|---|
| `required_approving_review_count` | `0` | `2` |
| `require_code_owner_review` | `false` | `true` |
| `require_last_push_approval` | `false` | `true` |
| `dismiss_stale_reviews_on_push` | `true` | `true` |
| `required_review_thread_resolution` | `true` | `true` |

The two rows that stay `true` are the ones a single maintainer can actually honour: a
review comment must be resolved before merge, and a push after review invalidates it. They
are worth having even with zero required approvers, because they gate the *conversation*
rather than counting *people*.

`--approvals N` on the script sets the count and derives `require_code_owner_review` from
it (`N >= 1`), so the day the count goes up, CODEOWNERS starts being real in the same
command.

**This is finding C-18.** "No second maintainer" and "review cannot be enforced" are not
two problems; they are one problem seen from two angles. The exit criterion for both is in
§13. Until then, review on this project is a checklist
(`.github/PULL_REQUEST_TEMPLATE.md`) and the CI gates — not a human count, and the
documents should not claim otherwise.

### 3.4 Signed commits

Do **not** enable this rule yet. Sequence:

1. Register the SSH signing key on the GitHub account as a **signing** key (not an
   authentication key): <https://github.com/settings/keys> → *New SSH key* → key type
   **Signing Key**. Key generation is a human action and is deliberately not automated
   (`CLAUDE.md` §5, §10.1) — the script does not touch keys.
   Via CLI this needs an extra scope: `gh auth refresh -s admin:ssh_signing_key`.
2. Confirm: open a recent commit on `github.com/Gh0s777tt/E-OS` and check it reads
   *Verified*, or `gh api repos/Gh0s777tt/E-OS/commits/main --jq .commit.verification`.
3. Only then add `{ "type": "required_signatures" }` to the ruleset.
4. Update `README.md`, which currently carries the honest caveat *"Not yet confirmed on
   the GitHub mirror"*. That caveat becomes wrong the moment step 2 passes.

This closes the mirror half of **C-20**. The GitLab half — server-side rejection of an
unsigned commit — is a Premium push rule and stays unavailable; local enforcement via
`commit.gpgsign = true` and the `lefthook` hooks is what this project actually has.

### 3.5 Required status checks — read the names off a real run, do not type them

A required check whose name does not match any real check run is worse than no rule: it
blocks forever and teaches people to use the bypass. Get the names from the API:

```sh
gh api repos/Gh0s777tt/E-OS/commits/main/check-runs --jq '.check_runs[].name' | sort -u
```

The check-run name is the job's `name:` if it has one, otherwise the job id. There are
**nine** workflow files in `.github/workflows/` as of 2026-08-30 — `_canary.yml`, `ci.yml`,
`docs.yml`, `lint.yml`, `release.yml`, `sbom.yml`, `scorecard.yml`, `security.yml`,
`stale.yml` — carrying well over that many jobs between them, so reading the names off a
file by hand is already impractical and about to get worse.

Two things follow, and the second one is the one that bites:

- `_canary.yml`'s job is `canary` (no `name:`, so the check run is `canary` too). It is a
  temporary branch canary that exists only to prove a runner was reached, and it must
  **never** be a required check. The script filters it out of the discovered set by name.
- The command above returns **nothing today**, because Actions has never produced a run on
  this repository (`docs/ci.md`; `_canary.yml` is the standing measurement of that). So
  there are no real check-run names to require yet, and the script leaves the
  required-status-checks rule out rather than inventing one — see the `--checks` flag. Any
  name you add by hand before the first green run is a guess, and a wrong guess here blocks
  the branch forever.

`strict_required_status_checks_policy: true` is the "branch must be up to date before
merging" setting. Keep it on: it is the difference between "these checks passed" and
"these checks passed against the code that will be on `main` after the merge". It costs a
re-run on every merge, which on a repository with this much CI is the cheapest thing in
the file.

### 3.6 Force-push and deletion

These two are the only branch rules that are unambiguously worth enabling on the mirror:

```json
{ "type": "non_fast_forward" }
{ "type": "deletion" }
```

`README.md` already claims force-push and deletion are blocked on GitHub; this is the
setting that makes that claim true, and the verification in §14 is how you keep it true.

One caveat, and it decides whether `non_fast_forward` is safe for you: check GitLab →
Settings → Repository → *Mirroring repositories*. If the push mirror is configured to
overwrite diverged branches, it force-pushes, and this rule will reject it. If it is not,
the mirror pushes fast-forward only and the rule is free. Look — do not assume.

---

## 4. Secret scanning and push protection

Free on public repositories, and unlike everything in §3 it does real work on a mirror:
it scans the copy, and push protection rejects a push that carries a detectable
credential.

**Already on** as of 2026-08-30, both of them. This section is here so that stays true —
the read-back in §14 is the part that matters now.

Settings → **Code security** → *Secret scanning* → Enable; then *Push protection* →
Enable.

```sh
REPO=Gh0s777tt/E-OS
gh api --method PATCH "repos/$REPO" --input - <<'JSON'
{ "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
} }
JSON
gh api "repos/$REPO" --jq .security_and_analysis     # verify
```

Two extras worth enabling if the API accepts them on this plan — the script tries them
separately so a refusal does not fail the whole run:
`secret_scanning_non_provider_patterns` (private keys, connection strings — the shapes
that are not one vendor's token format) and `secret_scanning_validity_checks` (asks the
provider whether a found token is still live).

**Push protection can reject a mirror push.** That is the one rejection in this entire
document you should want. The recovery is *not* to bypass it on GitHub: it is to purge the
secret on GitLab, rotate the credential, and let the corrected history mirror. Treat any
push-protection block as an incident, not as an obstacle.

This does not replace the `secret-scan` job in `.gitlab-ci.yml`. That one scans the whole
history with gitleaks against `.gitleaks.toml` and its justified allowlist, and it runs
before the code is public. GitHub's scanner runs after. Both, or neither is worth much.

---

## 5. Dependabot alerts and security updates

**Both already on** as of 2026-08-30 — which is exactly why the warning at the end of this
section is the important part of it.

Settings → **Code security** → *Dependabot alerts* → Enable; then *Dependabot security
updates* → Enable.

```sh
REPO=Gh0s777tt/E-OS
gh api --method PUT "repos/$REPO/vulnerability-alerts"      # 204 on success
gh api "repos/$REPO/vulnerability-alerts"                   # 204 = on, 404 = off
gh api --method PUT "repos/$REPO/automated-security-fixes"
gh api "repos/$REPO/automated-security-fixes"               # {"enabled":true,...}
```

`.github/dependabot.yml` configures two `cargo` entries weekly (root manifest and
`tools/eos-repo-sign`) **and**, as of the same change that restored `.github/workflows/`,
the `github-actions` ecosystem weekly with a `security-actions` group split out from the
rest. An earlier revision of this section asked for that restoration as future work; it had
already happened, and the file's header says why: a SHA pin never goes stale loudly, so
something has to say when one is behind, and for SHA-pinned actions that something is
Dependabot. Nothing to do here — verify it is still there when you review the allowlist.

**Do not read a green Dependabot as "no vulnerabilities".** That is finding **C-13**:
Dependabot reported zero while `osv-scanner` found real advisories on the same tree.
Dependabot alerts here are a notification channel, not a gate. The gates are `cargo-deny`
in `rust-checks` (advisories + licences + bans + sources) and the scanner workflows in
`.github/workflows/`.

---

## 6. Private vulnerability reporting

**Measured off, 2026-08-30 — and this one is not cosmetic.** `SECURITY.md` tells reporters
to use *Security → Report a vulnerability* and links
<https://github.com/Gh0s777tt/E-OS/security/advisories/new>. With the setting off, that
form is not available to them. The project's published, preferred intake channel for
vulnerability reports is currently a link to a page a reporter cannot use; the fallback in
`SECURITY.md` is the maintainer's email address, which works, but nobody reads the second
option when the first one is presented as preferred.

Enable it, and the documented channel and the switch agree again.

Settings → **Code security** → *Private vulnerability reporting* → Enable.

```sh
REPO=Gh0s777tt/E-OS
gh api --method PUT "repos/$REPO/private-vulnerability-reporting"
gh api "repos/$REPO/private-vulnerability-reporting"        # {"enabled": true}
```

This is one of very few controls where the mirror is the *primary* surface: a reporter who
finds E-OS will find the GitHub repository, and GitLab Free has no equivalent private
advisory workflow.

---

## 7. Actions allowlist

Settings → Actions → General → *Actions permissions* → **Allow enterprise/owner actions,
and select non-owner actions** → paste the allowlist.

The allowlist must be **derived from the workflows, not written from memory** — the same
reasoning that makes `ci-integrity.sh` check 6 derive its expected set from the tree
instead of restating it. The script builds it by reading every `uses:` in
`.github/workflows/*.yml`:

```sh
grep -hoE 'uses:[[:space:]]*[A-Za-z0-9._-]+/[A-Za-z0-9._/-]+@[0-9a-f]{40}' \
  .github/workflows/*.yml | sed 's/.*uses:[[:space:]]*//; s/@.*/@*/' | sort -u
```

```sh
REPO=Gh0s777tt/E-OS
gh api --method PUT "repos/$REPO/actions/permissions/selected-actions" --input - <<'JSON'
{
  "github_owned_allowed": true,
  "verified_allowed": false,
  "patterns_allowed": ["step-security/harden-runner@*", "..."]
}
JSON
gh api "repos/$REPO/actions/permissions/selected-actions"    # verify
```

`verified_allowed: false` is deliberate: "any Marketplace-verified creator" is thousands
of publishers, which is not an allowlist.

**One thing about the derived list is not verified, and it is the thing that would break a
job.** Four of the twenty-five patterns carry a sub-path, because that is the form the
workflows use: `github/codeql-action/init@*`, `.../analyze@*`, `.../upload-sarif@*` and
`google/osv-scanner-action/osv-scanner-action@*`. Whether GitHub's matcher accepts a
sub-path pattern has not been tested here, and cannot be until a workflow actually runs on
this repository. The three `github/*` ones should be covered by `github_owned_allowed`
either way; `google/osv-scanner-action` is the one genuinely exposed. If a run is ever
blocked on it, add `google/osv-scanner-action@*` and re-run the script — do not "fix" it by
setting `verified_allowed: true`, which trades one blocked job for thousands of publishers.

**Why `owner/repo@*` and not the exact SHA.** The allowlist could pin the same 40-character
SHAs the workflows pin. It would be stricter, and it would also mean every action bump
turns into a red pipeline until someone remembers to update a setting that lives outside
the repository — a failure that looks like a broken CI rather than like a policy decision.
The threat this control answers is *a new third-party action appearing in a workflow*; the
SHA pin in the reviewed workflow file answers *which version of an approved action runs*.
Two controls, two jobs. If you do want the stricter form, drop the `sed` that rewrites
`@<sha>` to `@*` and accept the maintenance.

### 7.1 Default workflow token permissions

**Measured 2026-08-30: `write`, and Actions is allowed to approve pull requests.** Both
are GitHub's defaults, and both are wrong for this repository.

Settings → Actions → General → *Workflow permissions* → **Read repository contents
permission** and untick *Allow GitHub Actions to create and approve pull requests*.

```sh
gh api --method PUT repos/Gh0s777tt/E-OS/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
gh api repos/Gh0s777tt/E-OS/actions/permissions/workflow      # verify
```

This is the repository-wide floor under the `permissions: contents: read` that every
workflow in this suite declares at the top level. A workflow that forgets the declaration
still gets a read-only token. `can_approve_pull_request_reviews=false` matters more than it
looks on a single-maintainer repo: it is the setting that stops a bot from being the second
approver §3.3 says does not exist.

### 7.2 Environments — `prod` is declared by a workflow and does not exist

> **Corrected 2026-08-30.** This section previously read *"Not configured, deliberately …
> nothing in this suite deploys"*. That was false when it was written, and it was hiding a
> live decorative gate. Two jobs in `.github/workflows/` declare an environment.

Measured with `gh api repos/Gh0s777tt/E-OS/environments`: **one** environment exists,
`github-pages`, auto-created by the Pages service on 2026-06-07, whose only protection rule
is a branch policy. `prod` returns **404**.

| Declared by | Environment | Live state |
|---|---|---|
| `docs.yml`, job `deploy` (`actions/deploy-pages`) | `github-pages` | exists; branch policy only, **no required reviewers** |
| `release.yml`, job `publish` (cosign signing, asset upload) | `prod` | **does not exist** |

**Why the second row is a finding and not a to-do.** A job that names an environment does
not require that environment to exist: GitHub creates it on first use with no protection
rules and the job runs straight through. `release.yml`'s own header says *"the required
reviewers themselves live in repo Settings → Environments → prod and CANNOT be declared in
this file — configure them there"*. Nobody has. So the release pipeline currently carries a
comment describing an approval gate, and an `environment:` key that pauses nothing. **A
check that can only pass is not a check** — the same rule, one layer below the YAML.

Create it, with a reviewer:

Settings → **Environments** → *New environment* → `prod` → *Required reviewers* → add
`Gh0s777tt` → Save. Or:

```sh
REPO=Gh0s777tt/E-OS
UID_=$(gh api users/Gh0s777tt --jq .id)
gh api --method PUT "repos/$REPO/environments/prod" --input - <<JSON
{ "wait_timer": 0,
  "prevent_self_review": false,
  "reviewers": [ { "type": "User", "id": $UID_ } ],
  "deployment_branch_policy": null }
JSON
gh api "repos/$REPO/environments/prod" --jq '.protection_rules'   # verify
```

**`prevent_self_review` is `false` on purpose, and that is C-18 again.** The UI checkbox is
*Prevent self-review*; it stops the account that triggered a run from approving it. With
one maintainer, who is also the only account that can trigger a release, turning it on does
not add a second pair of eyes — it makes the release job unapprovable and the pipeline
deadlocks. `release.yml`'s header asks for it on; that instruction is only executable once
§13's second Owner exists, and the two files should be reconciled in that same change.
What the environment buys today is what release.yml's next sentence already admits: *"a
deliberate pause and an approval record, not four eyes"*. That is worth having; pretending
it is review is not.

`github-pages` is left with no required reviewer deliberately. It gates a documentation
deploy from the default branch, where an approval queue costs a click and prevents nothing
a branch policy does not already prevent. The script reports its reviewer count on every
run so the decision stays visible, and fails the run only for an environment that is
**declared but absent** — which is the case that makes a gate fictional rather than merely
permissive. It derives the names from `.github/workflows/` rather than from this table, for
the same reason the allowlist is derived (§7).

The one job that would most want a gated environment is not here to gate: the OS image
build needs podman and a 37 GB cache and runs on the self-hosted `eos-heavy` GitLab runner
(`build-image` in `.gitlab-ci.yml`), which GitHub Actions cannot host. What `prod` gates is
the *signing and publishing* of release artifacts, not their production.

---

## 8. Workflow approval for first-time contributors

Settings → Actions → General → *Fork pull request workflows from outside collaborators*
→ **Require approval for first-time contributors who are new to GitHub** at minimum;
**Require approval for all outside collaborators** is the stronger setting and costs one
click per genuine contributor.

**Manual step.** There is no `gh api` endpoint documented for this repository-level
setting that this page will vouch for, and guessing an endpoint that might exist is how
you get a script that reports success against a 404. The script prints this as an
outstanding manual item every run; it does not pretend to have set it.

Why it matters even on a mirror: a fork pull request against this repository runs workflow
code with a token scoped to *this* repository's runner. Requiring approval before the
first run is the control that makes `pull_request` triggers survivable at all — and it is
the other half of the rule that no workflow in this suite uses `pull_request_target` with
a checkout of untrusted code.

---

## 9. Two-factor authentication and hardware keys

**Manual step** — account security is not repository configuration and has no repository
API.

<https://github.com/settings/security>

- 2FA on, with a **hardware security key** as the primary method (passkey or WebAuthn).
- Register **at least two** keys. One registered key is a single point of failure that
  locks you out of your own root of trust; the second lives somewhere the first one is not.
- TOTP as backup, seed stored in the same place as the recovery codes.
- Download the recovery codes and store them offline. See §13 — they are half of the
  break-glass procedure.
- Do the same on GitLab (<https://gitlab.com/-/user_settings/account>). GitLab is the
  source of truth; an account takeover there is a supply-chain compromise of the OS, and
  the GitHub mirror would faithfully replicate it.

Enforcing 2FA for *other* members is an organisation setting. There is no organisation
(§13), so there is nothing to enforce and nobody to enforce it on.

---

## 10. SSO

**Not applicable, and this is not a gap to file.** SAML/OIDC single sign-on for repository
access is a GitHub Enterprise Cloud feature applied to an organisation. `Gh0s777tt/E-OS`
is owned by a personal account. There is no directory to federate with and no second
identity to federate.

If the repository ever moves into an organisation (§13), SSO becomes available on paid
plans and should be revisited then. Recording "SSO: N/A because personal account" is the
useful output here; recording "SSO: not configured" would imply a control that was
declined rather than one that does not exist.

---

## 11. Personal access token policy

Organisation-level PAT approval policies are, again, an organisation feature. What is
available on a personal account is discipline, applied to three specific credentials:

| Token | Where it lives | Rule |
|---|---|---|
| The **mirror push credential** | GitLab → Settings → Repository → Mirroring repositories | Fine-grained, single repository, *Contents: read+write* only. Rotate on a fixed cadence and after any laptop loss. Rotating it breaks the mirror until GitLab is updated — that is a two-minute outage of a copy, not of the project. |
| Your **workstation `gh` token** | `gh auth status` | Fine-grained where possible. It is the only token in this document with administrative reach; it should not exist on any machine you would not sign a release from. |
| Anything in **Actions secrets** | Settings → Secrets and variables → Actions | Should be empty of long-lived cloud or admin credentials. Cloud auth in this suite is OIDC; `scorecard.yml` documents its own refusal of an admin PAT. |

```sh
gh api repos/Gh0s777tt/E-OS/actions/secrets --jq '.secrets[].name'   # names only, never values
```

### 11.1 `MINISIGN_SECRET_KEY` is on the mirror — decide about it

That command returns exactly one name today: **`MINISIGN_SECRET_KEY`**. Its value is not
retrievable through the API and this page does not want it; the *name* is enough to raise
the question.

`keys/README.md` states that every secret key is user-held and kept off-repo, and
`scripts/make-release.sh` takes `MINISIGN_SECRET_KEY` as a **path** to a key file outside
the tree — so an Actions secret of that name cannot even be used the way the script expects
unless something first writes it to disk.

Measured rather than inferred, 2026-08-30: **`grep -rn MINISIGN .github/workflows/` returns
nothing.** Not one of the nine workflow files reads this secret. `release.yml` does sign,
but keyless — `sigstore/cosign-installer` plus `id-token: write`, so the signing identity is
a short-lived OIDC token and there is no long-lived key to store. Releases on the GitLab
side are cut by the `semantic-release` job in `.gitlab-ci.yml`. The secret therefore has no
consumer on either host, and the earlier reading of this paragraph — "the workflows that
consumed it were removed" — is no longer even the reason: the workflows came back, and the
one that signs deliberately does not want it.

The action is a decision, not a cleanup:

- If nothing on GitHub signs a release — **delete it.** A release-signing credential parked
  on a mirror is a standing grant with no consumer and no audience watching it.
- If a GitHub workflow is meant to sign releases — that is a change of where the root of
  trust for E-OS releases lives, and it belongs in an ADR before it belongs in a secret.

Either way it is an operator action. The script lists the name and warns; it does not
delete secrets, and nothing that logs should ever hold that value (`CLAUDE.md` §5, §10.3).

Review the account's tokens at <https://github.com/settings/tokens> and
<https://github.com/settings/personal-access-tokens>. Set an expiry on every one of them;
"no expiration" is the setting that turns a forgotten laptop into a permanent grant. There
is no API that lists your own PATs, so this is a calendar item, not a script.

---

## 12. Audit log review

### 12.1 Cadence

Personal accounts have a **security log**, not an organisation audit log, and it has no
REST API this page will point you at. It is a UI review:
<https://github.com/settings/security-log>

| When | What you are looking for |
|---|---|
| Monthly | New SSH/signing keys, new OAuth or GitHub App grants, new PATs, changes to `security_and_analysis`, ruleset edits, collaborator additions |
| After any credential rotation | That the *old* credential stopped being used, not just that the new one works |
| After any push-protection block or secret-scanning alert | Everything the compromised credential touched, on both hosts |
| Before cutting a release tag | That nothing modified the repository configuration since the last review |

Do the same on the GitLab side, where the real gates live: **Project → Settings → Audit
events**, and the group-level events if the `e-os` group grows members.

### 12.2 The inventory that is worth automating

Configuration drift on a repository is usually an *addition*, not a change: a new deploy
key, a new collaborator, a new webhook. The script lists all three on every run so the
diff is visible without a UI trip:

```sh
REPO=Gh0s777tt/E-OS
gh api "repos/$REPO/keys"          --jq '.[] | "\(.id) \(.title) read_only=\(.read_only)"'
gh api "repos/$REPO/collaborators" --jq '.[] | "\(.login) \(.role_name)"'
gh api "repos/$REPO/hooks"         --jq '.[] | "\(.id) active=\(.active) host=\((.config.url // "") | sub("^[a-z]+://"; "") | split("/")[0])"'
```

The script prints only the **host** of each webhook URL, never the full URL: a webhook URL
routinely carries a token in its path or query string, and this output is meant to be
pasteable into an issue.

Measured 2026-08-30: no deploy keys, one collaborator (`Gh0s777tt`, `admin`), and **one
active webhook to `webhook.zenhub.com`**. A webhook is a standing grant to a third party
to receive every event on this repository, and it outlives whatever prompted it. If ZenHub
is still in use, that is the answer; if it is not, delete the webhook. If a token ever
cannot read the hook list, the script says so and records it as an outstanding manual
item — it never reports "no webhooks" for a list it could not fetch.

---

## 13. Break-glass account — finding C-18

Today: one maintainer, one account, one set of credentials. If that account is lost, E-OS
loses the GitLab source of truth, the GitHub mirror, the release-signing key custody chain
(`keys/README.md`), and the ability to publish a fix for anything found in the meantime.
That is **C-18**, and it is the same finding as the "two approvals" impossibility in §3.3
— you cannot require a second reviewer that does not exist, and you cannot recover an
account that only one person can reach.

### 13.1 The structural fix

Move the repository into a **GitHub organisation** (free) and the GitLab project into a
group with more than one Owner. That single change unlocks, in one step, most of what this
document has had to record as unavailable:

- a second **Owner** who can restore access — the actual break-glass account
- repository **roles**, so a collaborator can hold `maintain` without holding `admin`
- **ruleset bypass actors** that are somebody other than the only writer, which is what
  makes §0.4 stop being true
- organisation **2FA enforcement** and **PAT approval policies** (§9, §11)
- a second reviewer, which turns §3.3's interim row into the target row

Nothing else in this document substitutes for it. Everything else is detection.

### 13.2 The interim procedure, until that happens

This is what "break-glass" means with one person, written down so it survives the person:

1. **Recovery codes** for GitHub and GitLab, printed, stored offline, in a different
   physical location from the hardware keys.
2. **Two hardware keys** per account (§9), stored apart.
3. **The signing keys are the irreplaceable part.** `keys/README.md` records that every
   secret key is user-held and off-repo: the minisign release key and the hybrid
   `eos-repo-sign` key (ed25519 + ML-DSA-65). Losing an account is recoverable; losing
   these means every future release is signed by a key no existing installation trusts.
   Their backup location and the procedure to use them belong in the sealed envelope, not
   in this file and not in this repository.
4. **A named successor** who has physical access to 1–3 and written instructions. A
   break-glass procedure nobody but the locked-out person can execute is not a procedure.
5. **A rehearsal date.** An untested recovery path is a belief about a recovery path. Same
   rule this project applies to CI: a check that has never run is not a check.

Items 1–3 are operator actions involving credentials, and are deliberately outside the
script — key material must not pass through tooling that logs (`CLAUDE.md` §5, §10.3).

---

## 14. Verification and drift

Applying a setting and checking a setting are different actions, and only the second one
tells you anything. Every step above has a read-back; the script performs the read-back
after every write and fails the run if the value it reads is not the value it wrote.

```sh
scripts/setup-github-security.sh --dry-run     # report only, changes nothing
```

Run it as a check, not just as a setup: it exits non-zero when the live configuration has
drifted from what this page describes, which makes it usable as a monthly review or as a
step before cutting a release tag.

| Setting | One-line proof |
|---|---|
| Actions enabled + allowlist | `gh api repos/$REPO/actions/permissions --jq '.enabled, .allowed_actions'` |
| Workflow token is read-only | `gh api repos/$REPO/actions/permissions/workflow --jq .default_workflow_permissions` |
| Secret scanning + push protection | `gh api repos/$REPO --jq '.security_and_analysis'` |
| Dependabot alerts | `gh api repos/$REPO/vulnerability-alerts` → HTTP 204 |
| Dependabot security updates | `gh api repos/$REPO/automated-security-fixes --jq .enabled` |
| Private vulnerability reporting | `gh api repos/$REPO/private-vulnerability-reporting --jq .enabled` |
| Rulesets present and their mode | `gh api repos/$REPO/rulesets --jq '.[] \| "\(.name) \(.enforcement)"'` |
| Every declared environment exists and gates | `gh api repos/$REPO/environments --jq '.environments[] \| "\(.name) \(.protection_rules \| map(.type) \| join(","))"'` |
| Nothing new has write access | `gh api repos/$REPO/collaborators --jq '.[].login'` |

Anything in §8, §9, §10, §11, §12.1 and §13 is a manual item by nature, and so is creating
the `prod` environment in §7.2 — the script *checks* that one and fails on it, but does not
write it, because which account approves a release is a policy decision and not a default.
The script prints all of them as an explicit outstanding list on every run rather than
omitting them, so "the script was green" never gets mistaken for "everything on this page
is done".

---

## 15. What this page deliberately does not do

- **It does not make GitHub the gate.** Every enforcing control belongs on GitLab
  (§0.5). If a future change makes GitHub authoritative, this page is wrong from the first
  line and needs rewriting, not patching.
- **It does not provision a long-lived admin token anywhere**, including to raise an
  OpenSSF Scorecard check that would benefit from one. `scorecard.yml` makes the same
  trade and states it in its header.
- **It does not touch key material.** No key generation, no key registration, no secret
  values read or printed. Those are operator actions.
- **It does not claim the mirror is protected.** A ruleset here is telemetry about a copy.
  The protection is `docs/ci.md` §4 plus the fix for C-6, and until
  `only_allow_merge_if_pipeline_succeeds` is on and merge requests are actually used, this
  project's real gate is still off no matter what is green on GitHub.
