#!/usr/bin/env bash
# E-OS local security scan (R-005): integrity gates + gitleaks (if installed) +
# cargo-audit (if cargo is available). Best-effort; used by the launchd timer and
# runnable by hand. GitLab CI runs the always-on cloud version.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT" || exit 1; rc=0
bash scripts/ci-integrity.sh || rc=1
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --source . --no-banner --redact -v || rc=1
else echo "gitleaks: not installed (brew install gitleaks) — skipped"; fi
if command -v cargo >/dev/null 2>&1; then
  command -v cargo-audit >/dev/null 2>&1 || cargo install --locked cargo-audit >/dev/null 2>&1 || true
  for lock in Cargo.lock tools/eos-repo-sign/Cargo.lock; do
    # A real advisory MUST fail the scan (was `|| true`, which hid every CVE).
    if [ -f "$lock" ]; then ( cd "$(dirname "$lock")" && cargo audit ) || rc=1; fi
  done
else echo "cargo-audit: cargo absent here (run in the build container: podman exec eosbuild ...)"; fi
exit $rc
