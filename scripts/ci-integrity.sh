#!/usr/bin/env bash
# E-OS integrity gates — fast, dependency-free invariants that replace part of the
# (dead) GitHub Actions checks. Runs in GitLab CI and the local pre-push hook.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
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

[ "$fail" -eq 0 ] && echo "integrity: PASS" || echo "integrity: FAIL"
exit $fail
