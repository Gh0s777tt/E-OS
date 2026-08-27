#!/usr/bin/env bash
# E-OS integrity gates — fast, dependency-free invariants that replace part of the
# (dead) GitHub Actions checks. Runs in GitLab CI and the local pre-push hook.
set -uo pipefail
# `|| exit 1`: this is a GATE. A failed cd used to leave it linting whatever directory it
# happened to be in and reporting PASS on the wrong tree.
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")" || exit 1
fail=0
ok(){ printf '  ok: %s\n' "$1"; }
bad(){ printf 'FAIL: %s\n' "$1"; fail=1; }

# 1) No debug / plaintext-secret prints in our own Rust sources (R-F01 guard).
# `git grep` (tracked files only) rather than `grep -r .`: the recursive form also
# walked the gitignored prefix/ — 15 GB of vendored upstream Rust stdlib — and
# build/, so any working tree that had ever been built failed this gate on
# upstream doc-examples containing the word "password", while CI passed because a
# fresh clone has neither directory. The gate's own comment says "our own"
# sources, and tracked == ours (fork sources land in the gitignored
# recipes/*/source and are gated by their own repos' CI). This makes a local run
# mean exactly what the CI run means, and it is far faster over a 24 GB tree.
hits=$(git grep -InE 'println!\s*\(.*[Pp]assword|TODO:? *Remove this debug' -- '*.rs' 2>/dev/null || true)
if [ -n "$hits" ]; then bad "debug/plaintext-secret print:"; echo "$hits"; else ok "no debug/password prints"; fi

# 2) Docs must not point users at a concrete phantom release image (R-003 guard).
hits=$(grep -rInE 'eos-[0-9]+\.[0-9]+\.[0-9]+-(x86_64|aarch64)\.img' docs/ README.md 2>/dev/null || true)
if [ -n "$hits" ]; then bad "docs reference a concrete eos-<ver>-<arch>.img (use the build/ path or make-release):"; echo "$hits"; else ok "no phantom-artifact doc refs"; fi

# 3) README carries the SYNC marker kept in step with CHANGELOG/ROADMAP.
grep -q 'SYNC:' README.md && ok "README SYNC marker present" || bad "README SYNC marker missing"

# 4) Every `unsafe` in E-OS-owned Rust carries a `SAFETY:` note (R-F01 sibling).
# Scope excludes src/: that is the VENDORED redox_cookbook (package name
# `redox_cookbook`, upstream author), and all nine of its unsafe blocks live in
# src/cook/pty.rs. Annotating upstream code would create divergence to re-apply on
# every sync, for no safety gain — the same reasoning that keeps third-party ports
# on upstream flags (CLAUDE.md 3). E-OS-owned Rust here has ZERO unsafe today, so
# this gate is introduced while the count is nil and can never accrue a backlog.
# The forks (kernel/base/relibc) carry the real unsafe and are gated by their own CI.
hits=$(git grep -nI 'unsafe' -- '*.rs' ':!src/' 2>/dev/null | while IFS=: read -r f l _; do
  # A SAFETY: note must sit on one of the three lines above the unsafe.
  awk -v n="$l" 'NR>=n-3 && NR<n' "$f" 2>/dev/null | grep -q 'SAFETY' || echo "$f:$l"
done)
if [ -n "$hits" ]; then
  bad "unsafe without a SAFETY: note (state the invariant that makes it sound):"; echo "$hits"
else ok "every unsafe in E-OS-owned Rust is justified"; fi

# 5) No bash-4-only syntax in E-OS-owned scripts (R-F14).
# The dev host ships /bin/bash 3.2 (CLAUDE.md 9), so `declare -A`, `${x^^}`, `${x,,}`,
# `mapfile` and `readarray` parse in CI and fail on the machine the work is done on. This
# has cost time twice already: scripts/eos-check.sh used ${ARCH^^} (fixed in U-124) and
# scripts/check-ci-config.sh used `declare -A` (fixed in U-159). Comment lines are ignored
# so the notes explaining those very fixes do not trip their own gate. Scope is scripts/:
# build.sh and the *_bootstrap.sh at the repo root are inherited upstream, and upstream/
# targets machines with bash 4 -- the same reasoning that keeps check 4 out of src/.
# This file excludes itself: it necessarily contains the very patterns it looks for, so
# in scope it matched its own regex literal and failed on a clean tree. Its own syntax is
# covered by `bash -n` and by the shell-lint job.
hits=$(git grep -nE 'declare -A|mapfile|readarray|\$\{[A-Za-z_][A-Za-z0-9_]*\^\^|\$\{[A-Za-z_][A-Za-z0-9_]*,,' -- 'scripts/*.sh' ':!scripts/ci-integrity.sh' 2>/dev/null \
  | awk -F: '{ line=$0; sub(/^[^:]*:[0-9]*:/, "", line); if (line !~ /^[[:space:]]*#/) print }')
if [ -n "$hits" ]; then
  bad "bash-4-only syntax in scripts/ (the dev host has bash 3.2):"; echo "$hits"
else ok "no bash-4-only syntax in E-OS scripts"; fi

# 6) Every E-OS-forked recipe is pinned to build from its fork (R-F20).
# .config sets REPO_BINARY=1, which makes cookbook DOWNLOAD <recipe>.pkgar from
# static.redox-os.org unless cookbook.lock carries an fsrule = "source" exception. Those
# exceptions were hand-maintained and rotted: 13 of 26 forked recipes had been missed, so
# pkg-lib's manifest-signature verification -- R-703's client half -- was absent from the
# image while every document called it implemented (U-164). cookbook.lock is tracked as of
# U-168 precisely so this is reviewable, and eos-source-rules.sh derives the expected set
# from the tree rather than restating it.
if [ -f cookbook.lock ]; then
  if out=$(bash scripts/eos-source-rules.sh 2>&1); then
    ok "every E-OS-forked recipe builds from its fork"
  else
    bad "recipes with an E-OS fork are not pinned to source (they would be downloaded):"
    echo "$out"
  fi
else
  bad "cookbook.lock is missing — the build would silently download upstream binaries"
fi

# ── 7. Repo types in CLAUDE.md §11 match the `type` field in repos.toml ──────
# The type decides the rules (mirror = read-only, fork = must stay rebaseable), so a
# document disagreeing with the manifest silently applies the wrong ones. Offline half;
# the network half is scripts/eos-mirror-drift.sh, which compares the type to the fork.
if out=$(python3 scripts/eos-check-repo-types.py 2>&1); then
  ok "CLAUDE.md repo types match repos.toml"
else
  bad "CLAUDE.md §11 and repos.toml disagree on repository types:"
  echo "$out"
fi


# ── 8. Line endings stay as .gitattributes pins them (U-169 guard) ──────────
# Twelve tracked files are stored with CRLF: CHANGELOG.md, and eleven vendored
# cookbook files that no E-OS commit has ever touched. Nothing recorded that until
# U-173, so an editor that rewrote CHANGELOG.md on save turned a one-line append
# into a 2036-line whitespace diff (1018 insertions, 1018 deletions) and detached
# `git blame` from every measurement those entries cite. That is what happened in
# U-169, and it had to be spotted and reverted by hand.
# .gitattributes stops GIT from converting these files; this check stops an EDITOR
# from doing it, by failing the pre-push hook before the damage reaches a remote.
# The list is read out of .gitattributes rather than restated here, so the two
# cannot drift -- the same reasoning that makes check 6 derive its set from the
# tree (eos-source-rules.sh) instead of hard-coding it.
if [ ! -f .gitattributes ]; then
  bad ".gitattributes is missing — line endings are unpinned (U-173)"
else
  cr=$(printf '\r')
  pinned=$(awk '/^# --- eos:crlf-pinned ---$/{on=1;next} /^# --- end eos:crlf-pinned ---$/{on=0} on && $0 !~ /^#/ && NF {print $1}' .gitattributes)
  eol_hits=""
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    if [ ! -f "$f" ]; then
      eol_hits="$eol_hits
  $f — pinned in .gitattributes but not in the tree"
    elif ! grep -q "$cr" "$f"; then
      eol_hits="$eol_hits
  $f — CRLF normalised away; do not commit that diff (see U-173)"
    fi
  done <<EOF
$pinned
EOF
  # CHANGELOG.md is held to the stricter form: EVERY line ends CRLF. A partially
  # normalised file — one LF-only line appended by a tool that got it wrong — still
  # holds CRs elsewhere and would sail through the has-a-CR test above.
  if [ -f CHANGELOG.md ]; then
    lf_only=$(grep -cv "$cr\$" CHANGELOG.md 2>/dev/null || true)
    if [ "${lf_only:-0}" -ne 0 ]; then
      eol_hits="$eol_hits
  CHANGELOG.md — $lf_only line(s) end LF, not CRLF"
    fi
  fi
  if [ -n "$eol_hits" ]; then
    bad "line endings no longer match .gitattributes:"; echo "$eol_hits"
  else
    ok "CRLF-pinned files keep their line endings"
  fi
fi
[ "$fail" -eq 0 ] && echo "integrity: PASS" || echo "integrity: FAIL"
exit $fail
