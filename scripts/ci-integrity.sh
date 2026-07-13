#!/usr/bin/env bash
# E-OS integrity gates — fast, dependency-free invariants that replace part of the
# (dead) GitHub Actions checks. Runs in GitLab CI and the local pre-push hook.
set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
fail=0
ok(){ printf '  ok: %s\n' "$1"; }
bad(){ printf 'FAIL: %s\n' "$1"; fail=1; }

# 1) No debug / plaintext-secret prints in our own Rust sources (R-F01 guard).
hits=$(grep -rInE 'println!\s*\(.*[Pp]assword|TODO:? *Remove this debug' --include='*.rs' . 2>/dev/null | grep -v '/target/' || true)
if [ -n "$hits" ]; then bad "debug/plaintext-secret print:"; echo "$hits"; else ok "no debug/password prints"; fi

# 2) Docs must not point users at a concrete phantom release image (R-003 guard).
hits=$(grep -rInE 'eos-[0-9]+\.[0-9]+\.[0-9]+-(x86_64|aarch64)\.img' docs/ README.md 2>/dev/null || true)
if [ -n "$hits" ]; then bad "docs reference a concrete eos-<ver>-<arch>.img (use the build/ path or make-release):"; echo "$hits"; else ok "no phantom-artifact doc refs"; fi

# 3) README carries the SYNC marker kept in step with CHANGELOG/ROADMAP.
grep -q 'SYNC:' README.md && ok "README SYNC marker present" || bad "README SYNC marker missing"

[ "$fail" -eq 0 ] && echo "integrity: PASS" || echo "integrity: FAIL"
exit $fail
