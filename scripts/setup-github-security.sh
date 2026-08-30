#!/usr/bin/env bash
# E-OS — GitHub repository security configuration, applied and then VERIFIED.
#
# Companion to docs/security/github-configuration.md. Read §0 of that page before running
# this with anything other than --dry-run. Short version: github.com/Gh0s777tt/E-OS is a
# push-mirror of gitlab.com/e-os/e-os. A branch rule here gates nothing — code arrives by
# push, never through a pull request — and it can REJECT the mirror push. So this script
# sets the controls that do real work on a copy of a tree (secret scanning, Dependabot,
# private vulnerability reporting, the Actions allowlist) and leaves branch rules alone
# unless you name a mode explicitly on the command line.
#
# Every write is read back. A 2xx is not evidence that a setting took effect —
# `security_and_analysis` in particular accepts fields a plan does not support and leaves
# them off without complaining. So each step compares what it wanted against what the API
# reports afterwards, and a mismatch is a failure. That is also what makes --dry-run usable
# as a monthly drift check: it writes nothing and still exits non-zero if the live
# configuration has moved away from this file.
#
# What it deliberately does NOT do:
#   * touch key material. Registering the SSH signing key (doc §3.4) stays a human action —
#     a signing key must not pass through tooling that logs (CLAUDE.md §5, §10.3).
#   * print a secret. Secret NAMES are listed because names are the inventory; values are
#     not retrievable and are not asked for. Webhook URLs are reduced to their HOST,
#     because a webhook URL routinely carries a token in its path or query string.
#   * guess an endpoint. Settings with no REST endpoint this script will vouch for
#     (fork-PR workflow approval, 2FA, PAT policy, audit-log review, break-glass) are
#     printed as an explicit MANUAL list on every run, so a green exit is never mistaken
#     for "everything in the document is done".
#
# Exit status: 0 only if every step this script attempted was applied AND verified.

set -uo pipefail

REPO="Gh0s777tt/E-OS"
RULESET_NAME="eos-main"
DRY_RUN=0
RULESET_MODE="skip"       # skip | evaluate | active
APPROVALS=0               # see doc §3.3 — 0 is the honest setting for one maintainer
CHECKS_ARG=""             # comma-separated required status checks; empty = discover

ROOT=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)
WFDIR="$ROOT/.github/workflows"

fail=0
MANUAL=""
DEFAULT_BRANCH=""
API_OUT=""
API_RC=0

usage() {
  cat <<'USAGE'
setup-github-security.sh — apply and verify the GitHub-side security configuration.

Usage:
  scripts/setup-github-security.sh [options]

Options:
  --repo OWNER/REPO      Repository to configure        (default: Gh0s777tt/E-OS)
  --dry-run              Write nothing. Read every setting and report drift.
                         Still exits non-zero if the live config differs — use this
                         as the scheduled check, not just as a preview.
  --branch-ruleset MODE  skip | evaluate | active       (default: skip)
                         skip     — report existing rulesets, create nothing.
                         evaluate — create the ruleset in dry-run enforcement, so
                                    violations are recorded and NOTHING is rejected.
                                    Organisation feature (Team/Enterprise); on a
                                    personal account the API refuses it and this
                                    script reports that rather than downgrading.
                         active   — ENFORCE. Read §0.2 of the document first: on a
                                    push-mirror this can reject the mirror push and
                                    stop mirroring silently.
  --approvals N          Required approving reviews     (default: 0)
                         N >= 1 also turns on CODEOWNERS review. On a single-maintainer
                         project any N >= 1 makes every PR unmergeable without an admin
                         bypass — that is finding C-18, see doc §3.3 and §13.
  --checks "a,b,c"       Required status check contexts. Omit to read the names off the
                         most recent run on the default branch. Names are never invented:
                         if none can be found, the rule is left out and you are told.
  -h, --help             This text.

Requires: gh (authenticated as the repository owner), jq.
Token: classic `repo` (measured sufficient for every call here), or fine-grained with
Administration:rw, Metadata:r, Webhooks:r. Add admin:repo_hook only if the webhook
listing is refused.

Full rationale, click paths and the GitLab equivalent of every control:
  docs/security/github-configuration.md
USAGE
}

# ── output ────────────────────────────────────────────────────────────────────────────
section() { printf '\n== %s\n' "$1"; }
ok()      { printf '  ok      : %s\n' "$1"; }
info()    { printf '  info    : %s\n' "$1"; }
warn()    { printf '  warn    : %s\n' "$1"; }
bad()     { printf '  FAIL    : %s\n' "$1"; fail=$((fail + 1)); }

# `cannot` is the other kind of red, and keeping it apart from `bad` is the point: the
# setting was never measured, so it is UNKNOWN rather than wrong. The two demand opposite
# responses — fix the repository, or fix the runner. Same split as ci-integrity.sh.
cannot()  { printf '  FAIL(instrument): %s\n' "$1"; fail=$((fail + 1)); }

manual() {
  MANUAL="$MANUAL
  - $1"
}

# `shift 2` on a flag whose value is missing is a no-op that returns non-zero. Without
# this guard the option loop never advanced and the script SPUN FOREVER, printing nothing
# at all — measured on `setup-github-security.sh --repo`. A hang is the worst failure mode
# available to a gate, because it is indistinguishable from work.
need_value() {
  [ "$#" -ge 2 ] || {
    printf 'missing value for %s\n\n' "$1" >&2
    usage >&2
    exit 2
  }
}

# ── API ───────────────────────────────────────────────────────────────────────────────
# api <METHOD> <path> [gh api args...]
# GET always runs, including under --dry-run: reporting the current state is the whole
# value of a dry run. Writes are skipped there and the caller is told what would be sent.
api() {
  local method="$1" path="$2"
  shift 2
  if [ "$method" = "GET" ]; then
    API_OUT=$(gh api -H "Accept: application/vnd.github+json" "$path" "$@" 2>&1)
  elif [ "$DRY_RUN" -eq 1 ]; then
    API_OUT="(dry-run: $method $path not sent)"
    API_RC=0
    return 0
  else
    API_OUT=$(gh api -H "Accept: application/vnd.github+json" \
      --method "$method" "$path" "$@" 2>&1)
  fi
  API_RC=$?
  return "$API_RC"
}

# jq over the last API response. An empty string means "the field is not there"; every
# other value is printed as it is, `false` included.
#
# This was `jq -r "$1 // \"\""`, and it was wrong in exactly the way this file spends the
# rest of its length trying to avoid. jq's `//` fires on `false` as well as on `null`, so
# every boolean-false setting read back as the empty string — the one value this script
# reserves for UNKNOWN. Measured consequences, both real:
#   * `private-vulnerability-reporting` answers {"enabled": false}; §6 printed
#     "is ''", i.e. a broken instrument, for a setting that is simply off. That is the
#     U-177 confusion (CLAUDE.md §13) reintroduced inside the tool meant to model it.
#   * worse, two of the settings this script WRITES are `false`
#     (`can_approve_pull_request_reviews`, `verified_allowed`). Their read-back could
#     therefore never equal the value written, so those two steps could only ever fail.
#     A check that can only fail is the same defect as one that can only pass.
api_field() {
  printf '%s' "$API_OUT" | jq -r "($1) | if . == null then \"\" else . end" 2>/dev/null
}

# expect <label> <wanted> <got>
expect() {
  if [ "$2" = "$3" ]; then
    ok "$1 = $3"
  elif [ "$DRY_RUN" -eq 1 ]; then
    bad "$1 is '$3', should be '$2' (dry-run: not changed)"
  else
    bad "$1 is '$3' after being set to '$2' — the API accepted the call and did not apply it"
  fi
}

# ── steps ─────────────────────────────────────────────────────────────────────────────

preflight() {
  section "0. preflight — prove the instruments work before trusting any verdict"
  local missing=""
  local t
  for t in gh jq; do
    command -v "$t" >/dev/null 2>&1 || missing="$missing $t"
  done
  if [ -n "$missing" ]; then
    cannot "not on PATH:$missing — nothing was measured"
    return 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    cannot "gh is not authenticated (run: gh auth login) — nothing was measured"
    return 1
  fi
  ok "gh authenticated, jq present"

  if ! api GET "repos/$REPO"; then
    cannot "cannot read repos/$REPO: $API_OUT"
    return 1
  fi
  DEFAULT_BRANCH=$(api_field '.default_branch')
  local private archived
  private=$(api_field '.private')
  archived=$(api_field '.archived')
  ok "repository $REPO (default branch: ${DEFAULT_BRANCH:-unknown})"
  if [ "$private" = "true" ]; then
    warn "repository is PRIVATE — secret scanning and Dependabot may need a paid plan here"
  fi
  if [ "$archived" = "true" ]; then
    cannot "repository is archived; every write below would be rejected"
    return 1
  fi
  return 0
}

step_actions() {
  section "2. Actions must be enabled (doc §2 — ten files in this tree still say it is not)"
  api GET "repos/$REPO/actions/permissions"
  if [ "$API_RC" -ne 0 ]; then
    cannot "cannot read Actions permissions: $API_OUT"
    return
  fi
  local enabled allowed
  enabled=$(api_field '.enabled')
  allowed=$(api_field '.allowed_actions')
  info "current: enabled=$enabled allowed_actions=${allowed:-<unset>}"

  if [ "$enabled" != "true" ] || [ "$allowed" != "selected" ]; then
    if ! api PUT "repos/$REPO/actions/permissions" \
      -F enabled=true -f allowed_actions=selected; then
      bad "could not enable Actions: $API_OUT"
      manual "Actions may be disabled at ACCOUNT level — https://github.com/settings/actions (a repository cannot enable what the account forbids)"
      return
    fi
  fi

  api GET "repos/$REPO/actions/permissions"
  expect "actions enabled" "true" "$(api_field '.enabled')"
  expect "actions allowed_actions" "selected" "$(api_field '.allowed_actions')"
}

# The allowlist is DERIVED from the workflows, never typed. Same reasoning as
# ci-integrity.sh check 6 deriving its expected set from the tree: a hand-maintained list
# of what CI runs rots the first time somebody adds a step, and it rots silently.
step_actions_allowlist() {
  section "7. Actions allowlist — derived from every SHA-pinned \`uses:\` in .github/workflows"
  if [ ! -d "$WFDIR" ]; then
    cannot "$WFDIR does not exist — the allowlist would be UNKNOWN, not empty"
    return
  fi

  local patterns
  patterns=$(find "$WFDIR" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) \
    -exec grep -hoE 'uses:[[:space:]]*[A-Za-z0-9._-]+/[A-Za-z0-9._/-]+@[0-9a-f]{40}' {} + \
    2>/dev/null | sed 's/.*uses:[[:space:]]*//' | sed 's/@.*/@*/' | sort -u)

  if [ -z "$patterns" ]; then
    # Writing an empty allowlist would block every third-party action, i.e. the whole
    # suite. Refusing to write it is the safe answer.
    bad "no SHA-pinned third-party \`uses:\` found in $WFDIR — refusing to write an empty allowlist"
    return
  fi
  printf '%s\n' "$patterns" | sed 's/^/  allow  : /'

  # An action referenced by tag rather than by SHA is invisible to the derivation above,
  # so it would be missing from the allowlist and BLOCKED at run time. That this is also
  # a pinning defect is somebody else's gate; the reason it is fatal *here* is narrower —
  # the list this script is about to write would not cover a step the suite runs.
  local unpinned
  unpinned=$(find "$WFDIR" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) \
    -exec grep -nE '^[[:space:]]*(-[[:space:]]+)?uses:' {} + 2>/dev/null \
    | grep -vE 'uses:[[:space:]]*\./' \
    | grep -vE 'uses:[[:space:]]*[A-Za-z0-9._-]+/[A-Za-z0-9._/-]+@[0-9a-f]{40}')
  if [ -n "$unpinned" ]; then
    bad "\`uses:\` without a 40-char SHA — the allowlist below would not cover it, and the"
    bad "  step would be blocked at run time. Pin it, then re-run:"
    printf '%s\n' "$unpinned" | sed 's/^/            /'
  fi

  local patterns_json
  patterns_json=$(printf '%s\n' "$patterns" | jq -R . | jq -s .)

  # `verified_allowed: false` on purpose — "any Marketplace-verified creator" is thousands
  # of publishers, which is not an allowlist. The derived list keeps the GitHub-owned
  # actions too, whether or not `github_owned_allowed` already covers them, so this reads
  # as the complete inventory of foreign code the repository executes.
  #
  # NOT VERIFIED, and it decides whether this list blocks a step: three entries carry a
  # sub-path (`github/codeql-action/init@*`, `.../analyze@*`, `.../upload-sarif@*`,
  # `google/osv-scanner-action/osv-scanner-action@*`) because that is the form the
  # workflows `uses:`. Whether GitHub's matcher accepts a sub-path pattern has not been
  # tested here — Actions has never executed on this repository (docs/ci.md), so there is
  # no run to test it against. The codeql ones are `github/*` and should be covered by
  # `github_owned_allowed` regardless; the osv-scanner one is not. If a run is ever blocked
  # on it, add `google/osv-scanner-action@*` and re-run — do not widen this to
  # `verified_allowed`.
  api PUT "repos/$REPO/actions/permissions/selected-actions" --input - <<EOF
{ "github_owned_allowed": true, "verified_allowed": false, "patterns_allowed": $patterns_json }
EOF
  if [ "$API_RC" -ne 0 ]; then
    bad "could not set the Actions allowlist: $API_OUT"
    return
  fi

  api GET "repos/$REPO/actions/permissions/selected-actions"
  if [ "$API_RC" -ne 0 ]; then
    # This endpoint only answers once allowed_actions is `selected`, so on a repository
    # that has never been configured the read failure IS the drift, not a broken runner.
    if [ "$DRY_RUN" -eq 1 ]; then
      bad "no allowlist is configured (allowed_actions is not 'selected' yet)"
    else
      cannot "cannot read back the allowlist: $API_OUT"
    fi
    return
  fi
  expect "allowlist verified_allowed" "false" "$(api_field '.verified_allowed')"
  local live wanted
  live=$(printf '%s' "$API_OUT" | jq -r '.patterns_allowed[]?' 2>/dev/null | sort -u)
  wanted=$(printf '%s\n' "$patterns")
  if [ "$live" = "$wanted" ]; then
    ok "allowlist matches the workflows ($(printf '%s\n' "$wanted" | wc -l | tr -d ' ') patterns)"
  else
    bad "allowlist does not match the workflows; live set:"
    printf '%s\n' "$live" | sed 's/^/            /'
  fi
}

step_workflow_token() {
  section "7.1 default workflow token permissions"
  api PUT "repos/$REPO/actions/permissions/workflow" \
    -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
  if [ "$API_RC" -ne 0 ]; then
    bad "could not set default workflow permissions: $API_OUT"
    return
  fi
  api GET "repos/$REPO/actions/permissions/workflow"
  if [ "$API_RC" -ne 0 ]; then
    cannot "cannot read back workflow permissions: $API_OUT"
    return
  fi
  # The floor under the `permissions: contents: read` every workflow declares: a file that
  # forgets the declaration still gets a read-only token.
  expect "default_workflow_permissions" "read" "$(api_field '.default_workflow_permissions')"
  # On a one-maintainer repo this is not a formality: it stops a bot being the second
  # approver that doc §3.3 says does not exist.
  expect "can_approve_pull_request_reviews" "false" "$(api_field '.can_approve_pull_request_reviews')"
}

# Read-only, and it fails the run. A job that declares `environment: prod` does NOT require
# the environment to exist: GitHub creates it on first use with no protection rules, so the
# approval the workflow's own header promises never happens and the release publishes
# straight through. That is a gate that can only pass, described in a comment as a gate —
# the exact defect this project keeps re-finding (U-140, CLAUDE.md §13).
#
# The names are DERIVED from the workflows, like the allowlist in §7 and for the same
# reason. Nothing is written: which account approves a release is a policy decision that
# needs a numeric user id, and inventing either would produce a green line for an
# environment gated on nobody.
step_environments() {
  section "7.2 environments — every \`environment:\` a workflow declares must really exist"
  if [ ! -d "$WFDIR" ]; then
    cannot "$WFDIR does not exist — the declared environments are UNKNOWN, not none"
    return
  fi

  local names
  names=$(find "$WFDIR" -maxdepth 1 -type f \( -name '*.yml' -o -name '*.yaml' \) \
    -exec awk '
      /^[[:space:]]*environment:[[:space:]]*$/ { want = 1; next }
      want && /^[[:space:]]*name:[[:space:]]*[A-Za-z0-9._-]+[[:space:]]*$/ {
        sub(/^[[:space:]]*name:[[:space:]]*/, ""); sub(/[[:space:]]*$/, "")
        print; want = 0; next
      }
      /^[[:space:]]*environment:[[:space:]]*[A-Za-z0-9._-]+[[:space:]]*$/ {
        sub(/^[[:space:]]*environment:[[:space:]]*/, ""); sub(/[[:space:]]*$/, "")
        print
      }
      { want = 0 }
    ' {} + 2>/dev/null | sort -u)

  if [ -z "$names" ]; then
    info "no workflow declares an environment — nothing to verify (doc §7.2)"
    return
  fi

  local n reviewers
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    api GET "repos/$REPO/environments/$n"
    if [ "$API_RC" -ne 0 ]; then
      bad "environment '$n' is declared by a workflow but does not exist on the repository"
      info "  GitHub creates it on first use WITHOUT protection rules, so the approval the"
      info "  workflow claims to wait for never happens. Settings → Environments → New."
      continue
    fi
    reviewers=$(printf '%s' "$API_OUT" \
      | jq -r '[.protection_rules[]? | select(.type == "required_reviewers") | .reviewers[]?] | length' 2>/dev/null)
    [ -n "$reviewers" ] || reviewers=0
    if [ "$reviewers" -ge 1 ]; then
      ok "environment $n exists, required reviewers = $reviewers"
    else
      # Not a failure by itself: `github-pages` is created by the Pages service and gates a
      # documentation deploy, where an approval queue buys nothing. It IS a failure for any
      # environment a workflow leans on as a gate — doc §7.2 says which and why.
      warn "environment $n exists with NO required reviewers — it pauses nothing (doc §7.2)"
    fi
  done <<EOF
$names
EOF
}

step_secret_scanning() {
  section "4. secret scanning + push protection"
  api PATCH "repos/$REPO" --input - <<'EOF'
{ "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
} }
EOF
  if [ "$API_RC" -ne 0 ]; then
    bad "could not enable secret scanning: $API_OUT"
  fi

  # Sent separately, and a refusal here is a warning rather than a failure: these two
  # fields are not offered on every plan, and one unsupported field in the payload above
  # would have taken the two that matter down with it.
  api PATCH "repos/$REPO" --input - <<'EOF'
{ "security_and_analysis": {
    "secret_scanning_non_provider_patterns": { "status": "enabled" },
    "secret_scanning_validity_checks": { "status": "enabled" }
} }
EOF
  if [ "$API_RC" -ne 0 ]; then
    warn "non-provider patterns / validity checks not accepted on this plan (optional)"
  fi

  api GET "repos/$REPO"
  if [ "$API_RC" -ne 0 ]; then
    cannot "cannot read back security_and_analysis: $API_OUT"
    return
  fi
  expect "secret_scanning" "enabled" "$(api_field '.security_and_analysis.secret_scanning.status')"
  expect "secret_scanning_push_protection" "enabled" \
    "$(api_field '.security_and_analysis.secret_scanning_push_protection.status')"
  local extra
  extra=$(api_field '.security_and_analysis.secret_scanning_non_provider_patterns.status')
  [ "$extra" = "enabled" ] && ok "secret_scanning_non_provider_patterns = enabled"
  extra=$(api_field '.security_and_analysis.secret_scanning_validity_checks.status')
  [ "$extra" = "enabled" ] && ok "secret_scanning_validity_checks = enabled"

  info "push protection can reject a MIRROR push. That is the one rejection to want:"
  info "  purge the secret on GitLab and rotate it — never bypass it here (doc §4)."
  return 0
}

step_dependabot() {
  section "5. Dependabot alerts + security updates"
  # 204 No Content on success, and on GET: 204 = enabled, 404 = disabled. There is no body
  # to inspect, so the exit status IS the value.
  api PUT "repos/$REPO/vulnerability-alerts" >/dev/null 2>&1
  if api GET "repos/$REPO/vulnerability-alerts" >/dev/null 2>&1; then
    ok "dependabot alerts = enabled"
  else
    bad "dependabot alerts are still disabled"
  fi

  api PUT "repos/$REPO/automated-security-fixes" >/dev/null 2>&1
  api GET "repos/$REPO/automated-security-fixes"
  if [ "$API_RC" -ne 0 ]; then
    cannot "cannot read back automated-security-fixes: $API_OUT"
  else
    expect "dependabot security updates" "true" "$(api_field '.enabled')"
  fi

  # C-13: Dependabot reported zero while osv-scanner found real advisories on this tree.
  # Alerts here are a notification channel; the gates are cargo-deny in `rust-checks` and
  # the scanner workflows. Do not read a quiet Dependabot as a clean dependency tree.
  info "C-13: a green Dependabot is not a clean tree — cargo-deny and osv-scanner are the gates"
}

step_pvr() {
  section "6. private vulnerability reporting"
  api PUT "repos/$REPO/private-vulnerability-reporting" >/dev/null 2>&1
  api GET "repos/$REPO/private-vulnerability-reporting"
  if [ "$API_RC" -ne 0 ]; then
    cannot "cannot read back private vulnerability reporting: $API_OUT"
    return
  fi
  expect "private vulnerability reporting" "true" "$(api_field '.enabled')"
  # SECURITY.md already sends reporters to /security/advisories/new. That link 404s for
  # them until this is on, so the documented intake channel and the switch have to agree.
  info "SECURITY.md points reporters at the advisory form — this is the switch behind it"
}

# Required status check names are READ, never typed. A required check whose name matches
# no real check run blocks forever and teaches people to use the bypass.
discover_checks() {
  if [ -n "$CHECKS_ARG" ]; then
    printf '%s' "$CHECKS_ARG" | tr ',' '\n' | sed 's/^ *//' | sed 's/ *$//' | grep -v '^$' | sort -u
    return
  fi
  [ -n "$DEFAULT_BRANCH" ] || return 0
  api GET "repos/$REPO/commits/$DEFAULT_BRANCH/check-runs"
  [ "$API_RC" -eq 0 ] || return 0
  # _canary.yml is a temporary branch canary and must never gate the default branch.
  printf '%s' "$API_OUT" | jq -r '.check_runs[]?.name' 2>/dev/null \
    | grep -v '^canary$' | sort -u
}

step_ruleset() {
  section "3. branch ruleset (mode: $RULESET_MODE)"
  api GET "repos/$REPO/rulesets"
  if [ "$API_RC" -ne 0 ]; then
    cannot "cannot list rulesets: $API_OUT"
    return
  fi
  local existing
  existing=$(printf '%s' "$API_OUT" | jq -r '.[]? | "\(.id) \(.name) \(.enforcement)"' 2>/dev/null)
  if [ -n "$existing" ]; then
    printf '%s\n' "$existing" | sed 's/^/  ruleset: /'
  else
    info "no rulesets on this repository"
  fi

  if [ "$RULESET_MODE" = "skip" ]; then
    # The default, and it is a decision rather than an omission: on a push-mirror the
    # enforcing controls belong on GitLab (doc §0.5). A rule here gates nothing and can
    # reject the mirror push.
    info "skip — the gate for this project is GitLab (docs/ci.md §4). Pass"
    info "  --branch-ruleset evaluate|active to create one anyway; read doc §0.2 first."
    return
  fi

  local codeowners="false"
  [ "$APPROVALS" -ge 1 ] && codeowners="true"
  if [ "$APPROVALS" -ge 1 ]; then
    warn "approvals=$APPROVALS on a single-maintainer project makes every PR unmergeable"
    warn "  without an admin bypass — that is C-18, see doc §3.3 and §13."
  fi

  local rules
  rules=$(jq -n --argjson n "$APPROVALS" --argjson co "$codeowners" '[
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": {
        "required_approving_review_count": $n,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": $co,
        "require_last_push_approval": $co,
        "required_review_thread_resolution": true,
        "allowed_merge_methods": ["squash", "rebase"]
    } }
  ]')

  local checks
  checks=$(discover_checks)
  if [ -n "$checks" ]; then
    printf '%s\n' "$checks" | sed 's/^/  check  : /'
    local sc
    sc=$(printf '%s\n' "$checks" | jq -R '{context: .}' | jq -s \
      '{type: "required_status_checks", parameters: {strict_required_status_checks_policy: true, required_status_checks: .}}')
    rules=$(printf '%s' "$rules" | jq --argjson r "$sc" '. + [$r]')
  else
    # Leaving the rule out is the honest outcome. Inventing a context name would produce a
    # rule that can only fail, which is the same defect as a check that can only pass.
    warn "no status-check names found — the required-status-checks rule is LEFT OUT."
    warn "  Run the suite once on $DEFAULT_BRANCH, or pass --checks \"name,name\"."
  fi

  # required_signatures is absent on purpose. CLAUDE.md §10.1 records that the SSH signing
  # key is not registered on the GitHub account as a SIGNING key, so GitHub reads every
  # mirrored commit as Unverified — the rule would reject the whole mirror. Doc §3.4 is the
  # sequence that makes it safe; it starts with a human registering a key.
  local body
  body=$(jq -n --arg name "$RULESET_NAME" --arg enf "$RULESET_MODE" --argjson rules "$rules" \
    '{name: $name, target: "branch", enforcement: $enf,
      conditions: {ref_name: {include: ["~DEFAULT_BRANCH"], exclude: []}},
      rules: $rules}')

  local id
  id=$(printf '%s' "$existing" | awk -v n="$RULESET_NAME" '$2 == n {print $1; exit}')

  if [ -n "$id" ]; then
    api PUT "repos/$REPO/rulesets/$id" --input - <<EOF
$body
EOF
  else
    api POST "repos/$REPO/rulesets" --input - <<EOF
$body
EOF
  fi
  if [ "$API_RC" -ne 0 ]; then
    if [ "$RULESET_MODE" = "evaluate" ]; then
      # Not downgraded to `active` on purpose: `active` is the mode that can break the
      # mirror, and silently substituting it for the mode the operator asked for would be
      # the worst thing this script could do.
      bad "evaluate mode refused. It is an organisation feature (Team/Enterprise Cloud);"
      bad "  this repository is on a personal account. NOT falling back to active. $API_OUT"
    else
      bad "could not write the ruleset: $API_OUT"
    fi
    return
  fi

  api GET "repos/$REPO/rulesets"
  if [ "$API_RC" -ne 0 ]; then
    cannot "cannot read back the rulesets: $API_OUT"
    return
  fi
  local live_mode
  live_mode=$(printf '%s' "$API_OUT" \
    | jq -r --arg n "$RULESET_NAME" '.[]? | select(.name == $n) | .enforcement' 2>/dev/null)
  expect "ruleset $RULESET_NAME enforcement" "$RULESET_MODE" "${live_mode:-<absent>}"

  if [ "$RULESET_MODE" = "active" ]; then
    warn "ACTIVE. If the GitLab push mirror starts failing, this is why — doc §0.2."
    warn "  Check GitLab → Settings → Repository → Mirroring repositories now, not later."
  fi
}

# Configuration drift on a repository is usually an ADDITION — a new deploy key, a new
# collaborator, a new webhook — so the inventory is printed on every run, including
# --dry-run, and is meant to be diffed by eye against the previous run.
step_inventory() {
  section "12.2 inventory (read-only) — what currently has access"
  api GET "repos/$REPO/keys"
  if [ "$API_RC" -eq 0 ]; then
    local keys
    keys=$(printf '%s' "$API_OUT" | jq -r '.[]? | "\(.id) \(.title) read_only=\(.read_only)"')
    if [ -n "$keys" ]; then printf '%s\n' "$keys" | sed 's/^/  key    : /'; else info "no deploy keys"; fi
  else
    warn "cannot list deploy keys: $API_OUT"
  fi

  api GET "repos/$REPO/collaborators"
  if [ "$API_RC" -eq 0 ]; then
    printf '%s' "$API_OUT" | jq -r '.[]? | "\(.login) \(.role_name)"' | sed 's/^/  user   : /'
  else
    warn "cannot list collaborators: $API_OUT"
  fi

  # HOST only, never the full URL: a webhook URL routinely carries a token in its path or
  # query string, and this output is meant to be pasteable into an issue.
  api GET "repos/$REPO/hooks"
  if [ "$API_RC" -eq 0 ]; then
    local hooks
    hooks=$(printf '%s' "$API_OUT" | jq -r '.[]? |
      "\(.id) active=\(.active) host=\((.config.url // "") | sub("^[a-z]+://"; "") | split("/")[0])"')
    if [ -n "$hooks" ]; then printf '%s\n' "$hooks" | sed 's/^/  hook   : /'; else info "no webhooks"; fi
  else
    # Never report "no webhooks" for a list that could not be fetched — a webhook is a
    # standing grant to a third party, and "none found" and "not looked at" are opposite
    # answers. Classic `repo` was enough when this was measured; admin:repo_hook is the
    # documented scope if it ever is not.
    warn "cannot list webhooks: $API_OUT"
    manual "Webhooks were NOT listed — check Settings → Webhooks by hand, or: gh auth refresh -s admin:repo_hook"
  fi

  # NAMES only. Values are not retrievable through the API and are not wanted here.
  api GET "repos/$REPO/actions/secrets"
  if [ "$API_RC" -eq 0 ]; then
    local secrets
    secrets=$(printf '%s' "$API_OUT" | jq -r '.secrets[]?.name')
    if [ -n "$secrets" ]; then
      printf '%s\n' "$secrets" | sed 's/^/  secret : /'
      # Names, because names are the inventory. Cloud auth in this suite is OIDC, so a
      # long-lived credential here needs a consumer that still exists — doc §11.1 works
      # through the one that was found when this was written.
      warn "review each of these against a workflow that still uses it (doc §11, §11.1)"
    else
      ok "no Actions secrets configured"
    fi
  else
    warn "cannot list Actions secret names: $API_OUT"
  fi
}

collect_manual_items() {
  manual "Fork-PR workflow approval (doc §8) — Settings → Actions → General → 'Require approval for first-time contributors'. No endpoint this script will vouch for; set it in the UI."
  manual "2FA with two hardware keys, recovery codes stored offline (doc §9) — https://github.com/settings/security — and the same on GitLab, which is the source of truth."
  manual "SSH SIGNING key registration (doc §3.4) — https://github.com/settings/keys, type 'Signing Key'. Until this is done GitHub reads mirrored commits as Unverified (CLAUDE.md §10.1) and a required-signatures rule would reject the mirror."
  manual "SSO (doc §10) — N/A: Enterprise Cloud + organisation only. Record it as not-applicable, not as not-configured."
  manual "PAT policy (doc §11) — set an expiry on every token; scope the mirror push credential to Contents:rw on this repository only; review https://github.com/settings/tokens."
  manual "Audit-log review (doc §12.1) — https://github.com/settings/security-log monthly, and after every credential rotation. GitLab: Project → Settings → Audit events."
  manual "Break-glass / C-18 (doc §13) — one maintainer, one account. The structural fix is moving into an organisation with a second Owner; the interim procedure is recovery codes + two hardware keys + off-repo signing-key custody + a named successor + a rehearsal date."
  manual "Ten tracked files still state that GitHub Actions is disabled account-wide (doc §2), while the repository reports it ENABLED: .gitlab-ci.yml:2, README.md:47, ROADMAP.md:92, docs/MAINTENANCE.md:17, docs/ecosystem.md:96, docs/install.md:8, docs/security.md:55, docs/reality-ledger.md:3+101, docs/update-system-design.md:145, keys/README.md:85. Measured by grep 2026-08-30 — docs/ci.md, .github/dependabot.yml and SECURITY.md had already been corrected and are NOT on the list any more."
  manual "Environments (doc §7.2): 'prod' is declared by .github/workflows/release.yml but does not exist, so its required-reviewer gate is fictional — see section 7.2 above. Creating it needs a reviewer decision and a numeric user id, so this script reports it and does not write it."
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --repo)            need_value "$@"; REPO="$2";          shift 2 ;;
      --dry-run)         DRY_RUN=1; shift ;;
      --branch-ruleset)  need_value "$@"; RULESET_MODE="$2";  shift 2 ;;
      --approvals)       need_value "$@"; APPROVALS="$2";     shift 2 ;;
      --checks)          need_value "$@"; CHECKS_ARG="$2";    shift 2 ;;
      -h|--help)         usage; exit 0 ;;
      *)                 printf 'unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
  done

  case "$RULESET_MODE" in
    skip|evaluate|active) ;;
    *) printf 'invalid --branch-ruleset: %s (skip|evaluate|active)\n' "$RULESET_MODE" >&2; exit 2 ;;
  esac
  case "$APPROVALS" in
    ''|*[!0-9]*) printf 'invalid --approvals: %s (a non-negative integer)\n' "$APPROVALS" >&2; exit 2 ;;
  esac
  case "$REPO" in
    */*) ;;
    *) printf 'invalid --repo: %s (expected OWNER/REPO)\n' "$REPO" >&2; exit 2 ;;
  esac

  printf 'E-OS GitHub security configuration — %s\n' "$REPO"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'MODE: dry-run. Nothing is written. Exit is non-zero if the live config has drifted.\n'
  else
    printf 'MODE: apply. Every write is read back and a mismatch fails the run.\n'
  fi
  printf 'Rationale, click paths, GitLab equivalents: docs/security/github-configuration.md\n'

  preflight || { printf '\nAborted: nothing was measured.\n'; exit 1; }

  step_actions
  step_actions_allowlist
  step_workflow_token
  step_environments
  step_secret_scanning
  step_dependabot
  step_pvr
  step_ruleset
  step_inventory

  collect_manual_items
  section "MANUAL — no API, or deliberately not automated. Not covered by the exit status."
  printf '%s\n' "$MANUAL"

  section "result"
  if [ "$fail" -eq 0 ]; then
    printf 'github-security: PASS (%s)\n' "$([ "$DRY_RUN" -eq 1 ] && echo "no drift" || echo "applied and verified")"
    exit 0
  fi
  printf 'github-security: FAIL — %s step(s)\n' "$fail"
  exit 1
}

main "$@"
