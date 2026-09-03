#!/usr/bin/env bash
# scripts/verify.sh — the whole gate chain, locally, in one command.
#
# ── WHY THIS FILE EXISTS ──────────────────────────────────────────────────────────────
# Three measurements, not three opinions:
#   * C-7 — the SHARED light tier fails in ~0 s with `ci_quota_exceeded`, intermittently:
#     dead 2026-08-28 → the 2026-09-01 quota reset, green that whole day, dead again by
#     evening. The self-hosted `eos-heavy` tier spends no shared minutes and is NOT covered
#     by this — build-image succeeded on 2026-09-01 in 1299 s, running boot-smoke on both
#     images and install-smoke through to a login prompt on the installed disk.
#   * GitHub Actions does not execute for this repository either. Measured 2026-08-30: a
#     minimal push-triggered workflow on a fresh branch produced NO run — not queued, not
#     failed. `.github/workflows/_canary.yml` keeps that measurable: it does nothing but
#     prove a runner was reached, so nobody has to believe the claim second-hand.
#   * C-6 — every commit BEFORE 2026-08-30 went straight to `main`. Since then each landed
#     through a merge request (38 merged as of 2026-09-01) with a merge_request_event
#     pipeline on the MR head. What survives: the branch is published before that pipeline
#     finishes, and the pipeline requirement has been switched off and back on to merge
#     while the shared quota was exhausted.
# Together: the run on a contributor's own machine is currently the only gate that is
# certain to execute before a push. This script is that run.
#
# ── WHAT IT IS AND IS NOT ─────────────────────────────────────────────────────────────
# It CALLS the same commands the pipelines call; it does not restate their rules. A second
# copy of a rule is a copy that drifts, and the rule that drifts is the one that stops
# catching things (U-164). Each stage below names the CI job it is the twin of.
#
# COVERED (blocking in CI, runnable on a laptop):
#   .gitlab-ci.yml   rust-checks · shell-lint · integrity · coverage · secret-scan
#   ci.yml           gates · rust · coverage
#   lint.yml         rust · shell · containerfiles
#   security.yml     semgrep (blocking tier) · gitleaks · osv-scanner
#
# DELIBERATELY NOT COVERED, and why — a list of what a green run here does NOT prove:
#   * `pin-check` (`scripts/eos-repos.sh pins --strict`) does one `git ls-remote` per
#     pinned fork — 26 of them (`pinned_in_recipe = true` in repos.toml), no clones, but
#     26 round trips to github.com (scripts/eos-repos.sh:104). Run it by hand when you
#     bump a pin (CLAUDE.md §1.6, §20.5); it is not a per-commit check and turning it into
#     one would make this script useless offline.
#   * `docs-currency` needs an MR diff base. Its local half is a human reading §2.
#   * `mirror-drift` / `rebase-check` are scheduled jobs that clone every fork AND its
#     redox-os upstream.
#   * `build-image` / `ci-boot-smoke.sh` need podman and a ~37 GB incremental cache, and
#     run on the self-hosted `eos-heavy` runner (`tags: [eos-heavy]`, .gitlab-ci.yml:353).
#     Nothing here builds or boots an image.
#   * `dependency-review` BLOCKS in security.yml (`fail-on-severity: low`), and still has
#     no twin here — not because it is soft, but because there is nothing to run: it diffs
#     the dependency graph between a pull request's base and head through the GitHub API,
#     and a laptop has no base/head pair. `osv-scanner` below answers the part a local run
#     can answer, the resolved graph as it stands.
#   * CodeQL, trivy, grype, scorecard: advisory in CI — security.yml's own
#     BLOCKING/ADVISORY header is where that is decided, and it lists these four there.
#     No local twin is worth the wall clock. podman/*containerfile also gets an advisory
#     trivy config pass in security.yml `iac-scan`; the BLOCKING containerfile gate is
#     hadolint in lint.yml `containerfiles`, and THAT one is mirrored below.
#
# ── HOW IT REPORTS ────────────────────────────────────────────────────────────────────
# A missing tool is NOT a pass. `gitleaks || true` in the pre-commit hook let a planted
# private key sail through while the hook printed green (U-140); a scanner that is simply
# absent produces the identical outcome, and a summary table that prints PASS beside a
# check nobody ran is the same lie with better formatting. So an absent tool is SKIPPED
# *and* makes the run non-zero, until you pass --allow-missing and own that decision.
#
# Red must say WHICH thing is broken — the tree or the instrument (U-177, CLAUDE.md §13),
# because the two demand opposite responses. That split is in the exit code:
#     0  everything that ran passed, and everything ran
#     1  a check FAILED — the tree is broken, fix the finding
#     2  nothing failed, but something could not be measured — fix your toolbox
#
# ── HOUSE CONSTRAINTS ─────────────────────────────────────────────────────────────────
# * Runs on /bin/bash 3.2 (the dev host, CLAUDE.md §9): no `declare -A`, no `mapfile`, no
#   `${x^^}`. ci-integrity.sh check 5 gates exactly that, and this file is in its scope.
# * The tree lives under a path containing a space (/Volumes/Project itp/…), so every
#   expansion here is quoted because it splits here for real, not in theory (U-159).
# * It installs NOTHING. A local "lint" that downloads binaries is a supply-chain step in
#   disguise; .gitlab-ci.yml pins the cargo-deny 0.20.2 tarball by sha256 for exactly that
#   reason. Missing tools are reported with the command to install them, and that is all.
set -euo pipefail

# Same idiom as ci-integrity.sh, same reason: `|| exit` because a failed cd used to leave
# a gate linting whatever directory it happened to be in and reporting PASS on the wrong
# tree (U-159).
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 2

M_OWNED="tools/eos-repo-sign/Cargo.toml"     # E-OS-owned: full strictness
M_VENDORED="Cargo.toml"                      # vendored redox_cookbook: tests + advisories
COVERAGE_FLOOR=38                            # 38.84 % at U-168, 41.06 % on 2026-09-01 — a trap
L_VENDORED="Cargo.lock"                      # lockfiles: osv-scanner reads these, not the manifests
L_OWNED="tools/eos-repo-sign/Cargo.lock"
TAR_PIN_GATE="scripts/eos-check-tar-pins.py"

CANNOT=77            # a stage's "I could not run" exit — the U-177 half of red
FAST=0
ALLOW_MISSING=0
STAGE_NOTE=""        # set by a stage to explain a SKIPPED/FAIL line in the table

usage() {
  cat <<'EOF'
scripts/verify.sh — run the local equivalent of the CI gate chain.

  bash scripts/verify.sh [--fast] [--allow-missing] [--help]

Stages, in order — these are the names the summary table prints, so a red line
there maps to exactly one row here:
  fmt          cargo fmt --check                   (E-OS-owned crate only)
  clippy       cargo clippy -D warnings            (E-OS-owned crate only)
  shell-lint   shellcheck over scripts/*.sh        (errors block, warnings advisory)
  actionlint   actionlint over .github/workflows/*.yml
  hadolint     hadolint over podman/*containerfile (errors block)
  typecheck    cargo check --locked                (both manifests)
  build        cargo build --locked                (both manifests)
  test         cargo test  --locked                (both manifests)
  coverage     cargo llvm-cov floor                (E-OS-owned crate only)   [slow]
  integrity    scripts/ci-integrity.sh
  tar-pins     scripts/eos-check-tar-pins.py       (every tar source in the image closure has a blake3)
  hooks        lefthook's hooks are installed in THIS working copy (RH-006)
  release-pack scripts/eos-test-make-release.sh    (make-release.sh packs the install medium, and can refuse)
  gitleaks     gitleaks detect over the full history
  cargo-deny   advisories/licences/bans/sources                              [slow]
  osv-scanner  both Cargo.lock files                                         [slow]
  semgrep      ERROR severity over tools/ and scripts/                       [slow]

Options:
  --fast            Skip the slow stages: coverage, cargo-deny, osv-scanner, semgrep.
                    Those skips are your deliberate choice and do NOT fail the run — but
                    the summary says so, because a --fast green is not a full green.
  --allow-missing   Do not fail the run for stages that could not execute because a tool
                    is not installed. They are still printed as SKIPPED. Use it when you
                    know what you are not measuring; do not make it a habit.
  --help            This text.

Exit status:
  0  everything that ran passed, and everything ran
  1  a check FAILED — a defect in the tree
  2  nothing failed, but a check could not be measured — a defect in the toolbox

Every stage runs even after an earlier one fails, so one run gives the whole picture
rather than the first complaint.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --fast)          FAST=1 ;;
    --allow-missing) ALLOW_MISSING=1 ;;
    -h|--help)       usage; exit 0 ;;
    *) printf 'verify: unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# ── instruments before results (CLAUDE.md §4.2) ───────────────────────────────────────
# Not decoration. If this script runs somewhere without the tree, `shellcheck scripts/*.sh`
# gets an unexpanded glob, `git grep` finds nothing, and several stages report an answer
# about a tree nobody looked at. Abort instead of degrading.
preflight_missing=""
for f in "$M_OWNED" "$M_VENDORED" scripts/ci-integrity.sh; do
  [ -f "$f" ] || preflight_missing="$preflight_missing $f"
done
if [ -n "$preflight_missing" ]; then
  printf 'FAIL (instrument): verify.sh is not looking at an E-OS tree — missing:%s\n' "$preflight_missing" >&2
  printf '      Nothing was measured. This is NOT a check failing.\n' >&2
  exit 2
fi

# ── result table ──────────────────────────────────────────────────────────────────────
# Four parallel indexed arrays rather than one associative array: bash 3.2 has no
# `declare -A`, and ci-integrity.sh check 5 fails any script that pretends otherwise.
ids=(); results=(); notes=(); times=()

record() {  # id status note seconds
  ids+=("$1"); results+=("$2"); notes+=("$3"); times+=("$4")
}

# `cargo install` drops binaries in ~/.cargo/bin, but on this host cargo itself comes
# from homebrew's rustup (/opt/homebrew/opt/rustup/bin/cargo), which never puts that
# directory on PATH. Without this, `coverage` and `cargo-deny` report CANNOT RUN and
# suggest installing tools that are already installed -- and the next person installs
# them a second time. Measured 2026-09-01: both binaries present, neither on PATH.
case ":$PATH:" in
  *":$HOME/.cargo/bin:"*) ;;
  *) [ -d "$HOME/.cargo/bin" ] && PATH="$PATH:$HOME/.cargo/bin" && export PATH ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }

# A stage declares a missing tool through this, then returns $CANNOT.
missing_tool() {  # tool install-hint
  STAGE_NOTE="$1 not installed — $2"
  return 0
}

is_slow() {
  case "$1" in
    coverage|coverage-report|cargo-deny|osv-scanner|semgrep) return 0 ;;
    *) return 1 ;;
  esac
}

run_stage() {  # id function
  local id="$1" fn="$2" start rc
  if [ "$FAST" -eq 1 ] && is_slow "$id"; then
    record "$id" SKIPPED "deliberate: --fast" 0
    printf '\n── %-12s SKIPPED (--fast)\n' "$id"
    return 0
  fi
  printf '\n──────── %s ────────\n' "$id"
  STAGE_NOTE=""
  start=$SECONDS
  # `set -e` is suspended for a function called in a condition, so a multi-command stage
  # would otherwise return only its LAST command's status and swallow the rest. Every
  # stage below therefore ends each command with an explicit `|| return 1`.
  if "$fn"; then
    rc=0
  else
    rc=$?
  fi
  if [ "$rc" -eq 0 ]; then
    record "$id" PASS "$STAGE_NOTE" "$((SECONDS - start))"
  elif [ "$rc" -eq "$CANNOT" ]; then
    record "$id" SKIPPED "${STAGE_NOTE:-could not run}" "$((SECONDS - start))"
    printf 'SKIPPED: %s\n' "${STAGE_NOTE:-could not run}"
  else
    record "$id" FAIL "${STAGE_NOTE:-exit $rc}" "$((SECONDS - start))"
  fi
  return 0
}

# ══ format ════════════════════════════════════════════════════════════════════════════
# .gitlab-ci.yml `rust-checks` / ci.yml `rust`.
#
# THE ASYMMETRY IS DELIBERATE, here and in every Rust stage below. fmt and clippy cover
# tools/eos-repo-sign only. The root manifest is the vendored upstream redox_cookbook
# (CLAUDE.md §11 type B): holding somebody else's tree to this project's style bar means
# either rewriting it and carrying that divergence through every sync, or drowning it in
# allow attributes until the gate means nothing. Tests and advisories DO cover it, because
# it is the engine that builds every image — untested upstream code we ship is still code
# we ship (R-F15).
stage_format() {
  have cargo || { missing_tool cargo "install rustup (rust-toolchain.toml pins the version)"; return "$CANNOT"; }
  cargo fmt --manifest-path "$M_OWNED" -- --check || return 1
}

# ══ lint ══════════════════════════════════════════════════════════════════════════════
stage_clippy() {
  have cargo || { missing_tool cargo "install rustup (rust-toolchain.toml pins the version)"; return "$CANNOT"; }
  cargo clippy --locked --manifest-path "$M_OWNED" -- -D warnings || return 1
}

# .gitlab-ci.yml `shell-lint`, split kept exactly as it is there: errors BLOCK, warnings
# are printed and advisory. The first run over these scripts found 3 errors and 18
# warnings (U-159); driving the warnings to zero is worth a change of its own rather than
# the change that introduces the gate. The `|| true` below is on the ADVISORY print, never
# on the blocking line — that distinction is the whole of U-140.
#
# `scripts/*.sh` and not a find: a glob skips leading-dot files, which is what keeps the
# macOS AppleDouble sidecars (`scripts/._foo.sh`, gitignored, binary) out of the lint.
# Running the linter over one of those yields SC2148 -- a failure about a macOS metadata
# file, not about the tree. (Written without the linter's own directive keyword at the start
# of a comment line, because that is parsed as a directive and is itself an error.)
stage_shell_lint() {
  have shellcheck || { missing_tool shellcheck "brew install shellcheck"; return "$CANNOT"; }
  echo "--- advisory (warnings and above) ---"
  shellcheck -f gcc -S warning scripts/*.sh || true
  echo "--- blocking (errors only) ---"
  shellcheck -f gcc -S error scripts/*.sh || return 1
}

# No CI job runs actionlint, so this is the one stage here with no twin in a pipeline. It
# earns that: the workflows in .github/workflows/ cannot be verified by running them (see
# the header — Actions does not execute for this repository), so nothing downstream of a
# push checks them at all. Not the ONLY instrument that reads them — lint.yml's `yaml` job
# runs yamllint over .github (blocking at errors) and .pre-commit-config.yaml's
# `eos-actionlint` hook runs this same tool at commit time — but yamllint checks YAML, not
# workflow semantics, and a hook is only as present as the developer who installed it.
#
# SHELLCHECK_OPTS is not cosmetic. actionlint shells out to shellcheck for every `run:`
# block at shellcheck's default severity, which reports info-level findings and exits 1 —
# a different, tighter bar than the errors-block/warnings-advisory split this project
# settled on for its own scripts. Pinning it to `-S error` keeps one rule for shell in
# this repository instead of two that disagree.
stage_actionlint() {
  have actionlint || { missing_tool actionlint "brew install actionlint"; return "$CANNOT"; }
  if [ ! -d .github/workflows ]; then
    STAGE_NOTE=".github/workflows/ is absent — nothing was linted"
    return "$CANNOT"
  fi
  SHELLCHECK_OPTS="-S error" actionlint .github/workflows/*.yml || return 1
}

# lint.yml `containerfiles`, which BLOCKS at `failure-threshold: error` over every
# podman/*containerfile. Those files are named the way upstream Redox names them, so there
# is no `Dockerfile` here and every tool that looks for one finds nothing and passes —
# which is why lint.yml discovers the list instead of trusting a default, and why the glob
# is checked below before it is used.
#
# One invocation, errors only. hadolint prints every finding regardless of the threshold,
# so the warnings stay visible in the log and the threshold decides only what fails — the
# same shape as shell-lint above, without needing a second pass to produce it. Measured on
# this tree 2026-08-30 with hadolint 2.15.1 (the version lint.yml's action reports too):
# ZERO at error across all three files, and below the threshold DL3008 x3, DL3013 x1,
# DL3042 x1 as warnings plus DL3009 x2 as info. Pinning apt and pip versions in a build
# container inherited from upstream Redox is a real maintenance decision, not one to make
# from inside a lint change; what would make the warnings blocking is settling that
# question and then moving BOTH this line and lint.yml to `warning` in one change.
#
# Verified able to fail, because a threshold nobody has seen go red is an assumption
# (CLAUDE.md §4.1): pointed at a containerfile with a malformed instruction, hadolint at
# this same threshold exits 1.
stage_hadolint() {
  have hadolint || { missing_tool hadolint "brew install hadolint"; return "$CANNOT"; }
  # The glob is tested before it is used. With no match bash hands hadolint the literal
  # string `podman/*containerfile` and the resulting "file not found" would be recorded as
  # a defect in files nobody read — an empty set is a broken instrument, not a clean tree.
  # `podman/._*containerfile` (macOS AppleDouble sidecars, gitignored, binary) are excluded
  # for free: a leading dot does not match a leading `*`.
  set -- podman/*containerfile
  if [ ! -f "$1" ]; then
    STAGE_NOTE="no file matched podman/*containerfile — nothing was linted"
    return "$CANNOT"
  fi
  hadolint --failure-threshold error "$@" || return 1
}

# ══ typecheck / build / test ══════════════════════════════════════════════════════════
# `--locked` on every one of them, but it buys two DIFFERENT things, because the manifests
# are not symmetric here either. The ROOT manifest resolves six packages out of four git
# repositories (counted in Cargo.lock, not assumed), and THREE of those repositories are
# taken by BRANCH with no `rev`: gitlab.redox-os.org's pkgar — which supplies pkgar,
# pkgar-core and pkgar-keys — plus installer and redoxer. Only the eos-pkgutils fork
# carries a rev. So three branch heads move underneath this manifest: --locked means the
# build resolves to the reviewed revisions or fails loudly, and without it a moved upstream
# branch is absorbed silently and Cargo.lock becomes decoration — the shape of R-F20, an
# artefact that does not contain what the pins say it contains. tools/eos-repo-sign has NO git dependency at all — checked, not assumed:
# zero `git+` sources in its Cargo.lock — so there --locked buys reproducibility instead,
# and a semver-compatible bump cannot enter unreviewed.
#
# Both are a tightening beyond .gitlab-ci.yml `rust-checks`, which runs a bare `cargo test`.
# ci.yml `rust` already took the same step for the same reason, so this agrees with the
# pipeline rather than diverging from it: a drifted lock turns red here first.
stage_typecheck() {
  have cargo || { missing_tool cargo "install rustup (rust-toolchain.toml pins the version)"; return "$CANNOT"; }
  cargo check --locked --manifest-path "$M_OWNED" || return 1
  cargo check --locked --manifest-path "$M_VENDORED" || return 1
}

stage_build() {
  have cargo || { missing_tool cargo "install rustup (rust-toolchain.toml pins the version)"; return "$CANNOT"; }
  cargo build --locked --manifest-path "$M_OWNED" || return 1
  cargo build --locked --manifest-path "$M_VENDORED" || return 1
}

# KNOWN FLAKE in the vendored manifest, measured here 2026-08-30 rather than guessed at:
# `cook::cook_build::tests::file_system_loop_no_infinite_loop` panics at src/config.rs:209
# with "Configuration is not initialized" — it reads a global that another test in the same
# binary initialises, so whether it passes depends on which order the threads got.
#
# It is a race, and its odds go UP with CPU contention: 2 failures in 18 default (parallel)
# runs on an otherwise idle machine, 5 in 6 runs taken while other jobs were competing for
# the CPU, 0 in 3 runs with `-- --test-threads=1`. A busy shared CI runner is therefore the
# worst case for it, not the best. NOT established here: which test initialises that global,
# and whether upstream has since fixed it.
#
# If this stage goes red on that ONE test name and nothing else, it is not your change. It is
# also not fixed here, twice over: src/ is the vendored upstream redox_cookbook, and adding
# `--test-threads=1` would make this script disagree with CI — .gitlab-ci.yml `rust-checks`
# and ci.yml `rust` both run a plain `cargo test`, so a local green bought that way would
# still be a red pipeline. A flaky gate is a real defect; hiding it inside the gate that is
# supposed to report it is the worse of the two.
stage_test() {
  have cargo || { missing_tool cargo "install rustup (rust-toolchain.toml pins the version)"; return "$CANNOT"; }
  cargo test --locked --manifest-path "$M_OWNED" || return 1
  # --test-threads=1 on the VENDORED suite, and this is not a preference.
  # cook::cook_build::tests::file_system_loop_no_infinite_loop reads the global config, which
  # only some tests initialise, and the config is per-thread. Run in parallel it is a coin
  # flip: 1 failure in 3 runs here. Proved pre-existing and unrelated to anything in this
  # branch — on a clean origin/main worktree, `cargo test --manifest-path Cargo.toml
  # file_system_loop` fails every time with "Configuration is not initialized"
  # (src/config.rs:209). Serialising makes the gate deterministic; it does NOT fix the test,
  # which is recorded as its own finding. A gate that is a coin flip is worse than no gate,
  # because it teaches people to re-run until green.
  cargo test --locked --manifest-path "$M_VENDORED" -- --test-threads=1 || return 1
}

# .gitlab-ci.yml `coverage` / ci.yml `coverage`. The floor sits just under the measured
# 38.84 % (U-168): it exists to catch a REGRESSION, not to certify 38 % as good, and it
# was verified able to fail (at 60 the job exits non-zero). The vendored manifest is
# reported and not gated, for the R-F15 reason above.
#
# llvm-tools-preview is probed separately from cargo-llvm-cov. Without it the tool fails
# with a message about instrumentation that reads like a coverage failure, and this
# project has already paid for a gate that reported a broken instrument as a broken tree
# (U-177, check 7).
stage_coverage() {
  have cargo || { missing_tool cargo "install rustup (rust-toolchain.toml pins the version)"; return "$CANNOT"; }
  have cargo-llvm-cov || { missing_tool cargo-llvm-cov "cargo install --locked cargo-llvm-cov"; return "$CANNOT"; }
  if ! rustup component list --installed 2>/dev/null | grep -q llvm-tools; then
    STAGE_NOTE="llvm-tools-preview is not installed — rustup component add llvm-tools-preview"
    return "$CANNOT"
  fi
  # Build coverage OFF the repo volume. This tree lives on exFAT, where macOS writes an
  # AppleDouble sidecar (`._name`) beside every file it touches -- including the .profraw
  # files cargo-llvm-cov emits, while the run is in progress. The sidecars match the profraw
  # glob and llvm-profdata then refuses the whole merge:
  #   warning: ._eos-repo-sign-....profraw: unrecognized instrumentation profile encoding format
  #   error: no profile can be merged
  # Deleting them first does not help; they are recreated during the test run. Relocating the
  # target directory to the local filesystem removes the cause instead of racing it. This is
  # the host's filesystem, not the coverage of this code -- a Linux runner never sees it, which
  # is why ci.yml does not carry this line.
  local cov_target="${TMPDIR:-/tmp}eos-verify-llvm-cov"

  # Advisory, and actually advisory: no threshold, and a failure here does NOT fail the stage.
  # Matches .gitlab-ci.yml `coverage`, which ends this line with `|| true` for the same reason
  # -- the vendored cookbook is upstream's code and gating its coverage would be re-litigating
  # a tree we do not own. The number is printed so a regression is visible to a human.
  echo "--- advisory: vendored redox_cookbook ---"
  # Advisory means "do not gate on upstream's coverage NUMBER". It was never meant to swallow a
  # TEST FAILURE. Measured 2026-09-01 on main: cargo test exited 101 under llvm-cov with
  # `cook::cook_build::tests::file_system_loop_no_infinite_loop ... FAILED`, and the only thing a
  # human saw was the one-line "advisory leg did not complete" below -- no test name, no count.
  # The outcome (stage does not fail) is deliberate and unchanged; what changes is that a
  # failing test is now named. See issue #20.
  local adv_log="${cov_target}.advisory.log"
  if CARGO_TARGET_DIR="$cov_target" \
     cargo llvm-cov --locked --manifest-path "$M_VENDORED" --summary-only 2>&1 | tee "$adv_log"
  then :; fi
  # `cmd | tee` yields tee's status (P-3), so ask the artifact, not the exit code.
  if grep -qE '^test result: FAILED' "$adv_log" 2>/dev/null; then
    echo "  !! the vendored cookbook's TESTS FAILED under llvm-cov (not just low coverage):"
    grep -E '^test .* \.\.\. FAILED$' "$adv_log" | sed 's/^/       /'
    grep -E '^test result: FAILED' "$adv_log" | sed 's/^/       /'
    echo "     Not failing this stage -- upstream code, and the \`test\` stage above is the"
    echo "     authority on test outcomes. \`test\` runs \`cargo test\`; llvm-cov runs"
    echo "     \`cargo test --tests\`, which builds a different set of targets, so a test"
    echo "     that leans on state another test set up can pass in one and fail in the"
    echo "     other. Measured 2026-09-01: file_system_loop_no_infinite_loop panics with"
    echo "     'Configuration is not initialized' (src/config.rs:209). Issue #20."
  elif ! grep -qE '^  *TOTAL|^Filename' "$adv_log" 2>/dev/null; then
    echo "  (advisory leg did not complete and produced no coverage table — not failing the stage)"
  fi

  echo "--- blocking: E-OS-owned tools/eos-repo-sign ---"
  CARGO_TARGET_DIR="$cov_target" \
    cargo llvm-cov --locked --manifest-path "$M_OWNED" --summary-only \
    --fail-under-lines "$COVERAGE_FLOOR" || return 1
}

# ══ the project's own gates ═══════════════════════════════════════════════════════════
# Called, never reimplemented: these scripts ARE the rules, and a YAML or bash paraphrase
# of them is a second definition that drifts out of step in silence.
stage_coverage_report() {
  # TQ-001. The `coverage` stage above measures and gates; this one PUBLISHES, so the number stops
  # living only in a terminal log that scrolls away. A measurement nobody can look up is a
  # measurement that drifts -- README and CLAUDE.md both quoted coverage figures a human had typed
  # months earlier. Floors are in coverage-floors.toml, not in the script (CLAUDE.md 5.10 rule 1).
  # Negative test: `bash scripts/eos-coverage-report.sh --selftest`.
  bash scripts/eos-coverage-report.sh --write=docs/reference/coverage.md
  local rc=$?
  [ "$rc" -eq 2 ] && return "$CANNOT"
  return "$rc"
}

stage_security_coverage() {
  # TQ-002. Line coverage says which lines RAN. It says nothing about whether the dangerous ones
  # were CHECKED, or whether the dependency graph is known-bad. Five proxies (SC-1..SC-5) with
  # floors that can go red; a proxy whose tool is absent is SKIPPED and the script exits 2 -- never
  # a silent 0 %, never a silent 100 %. Negative test: `--selftest` plants an unsafe block with no
  # SAFETY note and asserts SC-1 goes under its floor.
  # --allow-missing is passed deliberately: cargo-fuzz and cargo-mutants are not installed on this
  # host (TQ-004 installs them), and the summary NAMES what was not measured rather than pretending
  # it was. The day those two land, drop this flag and the stage tightens by itself.
  python3 scripts/eos-security-coverage.py --allow-missing --write docs/reference/security-coverage.md
  local rc=$?
  [ "$rc" -eq 2 ] && return "$CANNOT"
  return "$rc"
}

stage_integrity() {
  bash scripts/ci-integrity.sh || return 1
}

# The tarball-pin gate. It is asked for by the CI hardening brief and by .github/workflows/ci.yml,
# and it DOES NOT EXIST in this tree — not on disk, not in the index, not referenced by any
# other script. So this stage reports what is true: the check could not run.
#
# It reports SKIPPED rather than PASS because a pass would claim every recipe's tarball is
# pinned, which nothing here measured. It reports SKIPPED rather than FAIL because the tree
# is not what is broken — the gate was never written, and no contributor can fix that by
# installing something. Under the default rules a SKIPPED stage still makes this run
# non-zero (exit 2), which is the honest state: this chain is incomplete until somebody
# writes that script.
#
# The two pin gates that DO exist are not substitutes: `eos-repos.sh pins --strict` checks
# recipe git REVISIONS against 26 fork tips over the network, and `eos-fork-linkage.py`
# needs recipes/*/source, which is untracked and only exists inside the build container
# (CLAUDE.md §9).
# R-611b. The release script is the only thing that decides what a release CONTAINS, and
# nothing else in this chain exercises it -- shellcheck reads it, but shellcheck cannot tell
# whether a missing install medium is refused or silently skipped, which is exactly the
# defect this gate was written for. The suite builds throwaway trees; it touches neither the
# real build tree nor release/.
RELEASE_TEST="scripts/eos-test-make-release.sh"
stage_release_pack() {
  if [ ! -f "$RELEASE_TEST" ]; then
    STAGE_NOTE="$RELEASE_TEST does not exist in this tree"
    return "$CANNOT"
  fi
  have make || { missing_tool make "xcode-select --install"; return "$CANNOT"; }
  bash "$RELEASE_TEST" || return 1
}

# ══ local hooks ═══════════════════════════════════════════════════════════════════════
# ROADMAP `RH-006`. Measured 2026-09-03 on the development host: `.git/hooks` held only the
# `*.sample` files and `core.hooksPath` was unset, so NEITHER lefthook's fail-closed gitleaks
# pre-commit NOR `scripts/hooks/pre-push` ran on this machine -- while README.md and
# docs/security/index.md both described that scan as the thing standing between a secret and the
# mirror. The documentation was describing a clone that had run `lefthook install`, and nobody had.
#
# WHY THIS STAGE CAN PASS ON CI WITHOUT BEING A LOOPHOLE. The invariant is "this WORKING COPY runs
# its hooks". An ephemeral CI checkout has no developer to protect and no hooks by design, so the
# invariant is not violated there -- it is inapplicable, and saying so is honest where pretending to
# measure it would not be. Off CI the stage fails closed. Negative test: `mv .git/hooks/pre-commit`
# aside with CI unset -> FAIL naming the file; put it back -> PASS.
stage_hooks() {
  local hook
  if [ -n "${CI:-}" ]; then
    STAGE_NOTE="not applicable: an ephemeral CI checkout has no developer hooks"
    return 0
  fi
  [ -d .git ] || { STAGE_NOTE="no .git directory here -- cannot tell whether hooks are installed"; return "$CANNOT"; }
  hook=".git/hooks/pre-commit"
  if [ ! -f "$hook" ]; then
    STAGE_NOTE="$hook does not exist -- run: brew install lefthook && lefthook install"
    return 1
  fi
  if ! grep -q lefthook "$hook"; then
    STAGE_NOTE="$hook exists but is not lefthook's -- two hook managers race for this file (see .pre-commit-config.yaml)"
    return 1
  fi
  STAGE_NOTE="lefthook hooks installed: $(ls .git/hooks | grep -v '\.sample$' | tr '\n' ' ')"
}

stage_tar_pins() {
  if [ ! -f "$TAR_PIN_GATE" ]; then
    STAGE_NOTE="$TAR_PIN_GATE does not exist in this tree — the gate is unwritten, not passing"
    return "$CANNOT"
  fi
  have python3 || { missing_tool python3 "brew install python"; return "$CANNOT"; }
  python3 "$TAR_PIN_GATE" || return 1
}

# ══ security ══════════════════════════════════════════════════════════════════════════
# .gitlab-ci.yml `secret-scan` / security.yml `gitleaks`. Full history, not the working
# tree: a secret that reached a commit is a secret that reached the mirror, and the only
# real fix from there is a history rewrite. Not in the --fast set, because it is not slow
# — measured 2026-08-30 on this tree: 8184 commits, 9.92 MB, 1.7 s.
#
# --config is passed explicitly rather than left to gitleaks' directory lookup: the
# allowlist in .gitleaks.toml is justified entry by entry (U-120), and a config that
# silently failed to load would change the verdict without changing the output.
stage_gitleaks() {
  have gitleaks || { missing_tool gitleaks "brew install gitleaks"; return "$CANNOT"; }
  if [ -f .gitleaks.toml ]; then
    gitleaks detect --source . --config .gitleaks.toml --no-banner --redact || return 1
  else
    STAGE_NOTE=".gitleaks.toml is missing — the justified allowlist would not be applied"
    return "$CANNOT"
  fi
}

# .gitlab-ci.yml `rust-checks`. Full `check` (advisories + licences + bans + sources) on
# E-OS-owned code; `check advisories` only on the vendored manifest, because licences and
# sources are upstream's choices and gating those is re-litigating somebody else's tree.
#
# CI runs a sha256-pinned cargo-deny release tarball (0.20.2, download-verify-extract,
# U-118). This script does not download it. Fetching and executing a binary is not a thing
# a lint command should do behind a developer's back — install it once, deliberately.
stage_cargo_deny() {
  have cargo-deny || { missing_tool cargo-deny "cargo install --locked cargo-deny"; return "$CANNOT"; }
  cargo deny --manifest-path "$M_OWNED" check || return 1
  cargo deny --manifest-path "$M_VENDORED" check advisories || return 1
}

# security.yml `osv-scanner`, and that job BLOCKS on purpose: C-13 is that Dependabot
# reported 0 advisories for this repository while osv-scanner found real ones. A second
# database is not redundancy when the first one is the thing that was wrong.
# osv-scanner.toml at the repo root is picked up automatically; each entry there carries
# an `ignoreUntil`, so a stale exception comes back on its own instead of hiding forever.
stage_osv() {
  have osv-scanner || { missing_tool osv-scanner "brew install osv-scanner"; return "$CANNOT"; }
  # Lockfiles, not manifests. `-L Cargo.toml` is not a mistake osv-scanner tolerates: it
  # exits 127 with "could not determine extractor suitable to this file", which this stage
  # reported as a defect in the tree rather than as its own bug.
  osv-scanner scan source -L "$L_VENDORED" -L "$L_OWNED" || return 1
}

# security.yml `semgrep`, blocking tier: ERROR severity over E-OS-owned code (tools/ and
# scripts/), the same owned-vs-vendored boundary `shell-lint` and `rust-checks` draw. The
# advisory whole-tree pass and the SARIF upload stay in CI; what a contributor needs
# before pushing is the tier that can turn the pipeline red.
#
# READ THIS BEFORE TREATING A GREEN HERE AS A RUST OR SHELL RESULT. A green is real but it
# is much narrower than the scope line above suggests, and semgrep says so itself. Measured
# by running this exact stage on this tree, 2026-08-30, semgrep 1.175.0, 14 s, exit 0:
#
#     Scanning 64 files tracked by git with 48 Code rules:
#     Scanning 6 files with 19 python rules.
#     Ran 19 rules on 6 files: 0 findings.
#
# 64 files in `tools scripts`, SIX of them scanned — exactly the six scripts/*.py. At ERROR
# severity `p/rust` contributes nothing at all (security.yml counted it against the live
# registry: 11 rules, zero at ERROR) and no ERROR rule in `p/security-audit` declares rust
# or bash, so the one Rust crate and the 52 shell scripts had NO rule pointed at them. On
# those two this stage cannot go red today, and a green here is not a statement about them.
#
# It stays blocking for two reasons that are not "it might be useful": the Python surface it
# does gate is gated by nothing else in this chain, and the stage turns red on its own the
# day either pack gains a Rust or bash rule at ERROR — no edit here required. The owned Rust
# and shell are gated by `clippy`, `cargo-deny` and `shell-lint` above; that is where their
# regressions surface. Note too that semgrep limits itself to files TRACKED BY GIT, so a new
# script is unscanned until it is added — the same trap that invalidated a negative control
# in U-159.
#
# Still unmeasured: this tier has never run in a pipeline. The one that would have produced
# that baseline has been quota-dead since 2026-08-28 (C-7), so the 0 above is one host's
# result, not CI's. If a run is red, the answer is the finding or a justified `nosemgrep` on
# the line — not softening this stage.
stage_semgrep() {
  have semgrep || { missing_tool semgrep "pipx install semgrep (or brew install semgrep)"; return "$CANNOT"; }
  semgrep scan \
    --metrics=off \
    --disable-version-check \
    --config=p/rust \
    --config=p/security-audit \
    --severity=ERROR \
    --error \
    tools scripts || return 1
}

# ══ the chain ═════════════════════════════════════════════════════════════════════════
printf 'verify: E-OS local gate chain — %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
if [ "$FAST" -eq 1 ]; then
  printf 'verify: --fast — the slow stages will be SKIPPED, not run\n'
fi
if [ "$ALLOW_MISSING" -eq 1 ]; then
  printf 'verify: --allow-missing — absent tools will not fail this run\n'
fi

run_stage fmt         stage_format
run_stage clippy      stage_clippy
run_stage shell-lint  stage_shell_lint
run_stage actionlint  stage_actionlint
run_stage hadolint    stage_hadolint
run_stage typecheck   stage_typecheck
run_stage build       stage_build
run_stage test        stage_test
run_stage coverage    stage_coverage
run_stage coverage-report stage_coverage_report
run_stage sec-coverage  stage_security_coverage
run_stage integrity   stage_integrity
run_stage hooks       stage_hooks
run_stage tar-pins    stage_tar_pins
run_stage release-pack stage_release_pack
run_stage gitleaks    stage_gitleaks
run_stage cargo-deny  stage_cargo_deny
run_stage osv-scanner stage_osv
run_stage semgrep     stage_semgrep

# ══ summary ═══════════════════════════════════════════════════════════════════════════
n_pass=0; n_fail=0; n_missing=0; n_fast=0
printf '\n'
printf '════════════════════════════════════════════════════════════════════════════════\n'
printf '  %-12s %-8s %5s  %s\n' "STAGE" "RESULT" "TIME" "NOTE"
printf '  ──────────────────────────────────────────────────────────────────────────────\n'
i=0
while [ "$i" -lt "${#ids[@]}" ]; do
  printf '  %-12s %-8s %4ss  %s\n' "${ids[$i]}" "${results[$i]}" "${times[$i]}" "${notes[$i]}"
  case "${results[$i]}" in
    PASS) n_pass=$((n_pass + 1)) ;;
    FAIL) n_fail=$((n_fail + 1)) ;;
    SKIPPED)
      case "${notes[$i]}" in
        "deliberate: --fast") n_fast=$((n_fast + 1)) ;;
        *)                    n_missing=$((n_missing + 1)) ;;
      esac
      ;;
  esac
  i=$((i + 1))
done
printf '  ──────────────────────────────────────────────────────────────────────────────\n'
printf '  total: %d stages — %d PASS · %d FAIL · %d SKIPPED (could not run) · %d SKIPPED (--fast)\n' \
  "${#ids[@]}" "$n_pass" "$n_fail" "$n_missing" "$n_fast"
printf '════════════════════════════════════════════════════════════════════════════════\n'

# The verdict, and which kind of red it is. A FAIL outranks a SKIPPED: a broken tree is
# the more urgent of the two, and it is also the one a green toolbox cannot hide.
rc=0
if [ "$n_fail" -gt 0 ]; then
  rc=1
  printf 'verify: FAIL — %d stage(s) found a defect. Fix the finding.\n' "$n_fail"
elif [ "$n_missing" -gt 0 ] && [ "$ALLOW_MISSING" -eq 0 ]; then
  rc=2
  printf 'verify: INCOMPLETE — %d stage(s) could not run. Nothing failed; nothing proved them clean.\n' "$n_missing"
  printf '        Install what the NOTE column names, or re-run with --allow-missing and\n'
  printf '        know that you are pushing on a partial measurement.\n'
elif [ "$n_missing" -gt 0 ]; then
  printf 'verify: PASS (with %d stage(s) NOT measured — --allow-missing was given)\n' "$n_missing"
else
  printf 'verify: PASS\n'
fi

if [ "$n_fast" -gt 0 ] && [ "$rc" -eq 0 ]; then
  printf '        --fast skipped %d slow stage(s). This is not a full verification;\n' "$n_fast"
  printf '        run without --fast before you push.\n'
fi
exit "$rc"
