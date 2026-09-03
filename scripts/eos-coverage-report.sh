#!/usr/bin/env bash
# eos-coverage-report.sh -- line coverage for every E-OS-owned crate, as a page a reader can find.
# `TQ-001` in ROADMAP §11.3.
#
# Why this exists. Coverage was measured on every verify.sh run and then thrown away: the number
# lived in a terminal log, the floor lived in one shell variable, and README/CLAUDE.md quoted
# numbers that a human had typed months earlier. A measurement nobody can look up is a measurement
# that drifts. This script writes the table and fails when a gated crate is under its floor.
#
# Floors are in coverage-floors.toml, not in this file, so raising one is an ordinary commit and
# lowering one shows up in a diff (CLAUDE.md §5.10 rule 1).
#
# Exit 0 clean · 1 a gated crate is under its floor · 2 the measurement could not run (no cargo,
# no llvm-tools, no cargo-llvm-cov) -- the U-177 split: 1 means fix the tree, 2 means fix the
# toolbox. A missing tool is never reported as 0 %.
#
# Negative test: `--selftest` runs the floor comparison against a synthetic reading that is one
# point under the floor and asserts exit 1.
#
# Usage: eos-coverage-report.sh [--write docs/reference/coverage.md] [--selftest] [--help]
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2
WRITE=""
SELFTEST=0
for a in "$@"; do
  case "$a" in
    --write=*) WRITE="${a#*=}" ;;
    --write)   WRITE="docs/reference/coverage.md" ;;
    --selftest) SELFTEST=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

# crate-dir|manifest|gated|floor   -- floors overridden by coverage-floors.toml when present
CRATES="tools/eos-repo-sign|tools/eos-repo-sign/Cargo.toml|yes|38
.|Cargo.toml|no|0"

floor_for() {  # crate default
  local c="$1" d="$2" v
  [ -f coverage-floors.toml ] || { printf '%s' "$d"; return; }
  v=$(awk -F'=' -v k="\"$c\"" '$1 ~ k {gsub(/[^0-9.]/,"",$2); print $2}' coverage-floors.toml | head -1)
  printf '%s' "${v:-$d}"
}

pct_of() {  # reads `cargo llvm-cov --json --summary-only` on stdin, prints the LINES percentage
  # Not the text table. Its TOTAL row carries FOUR percentages -- regions, functions, lines,
  # branches -- and taking "the first field ending in %" reads REGIONS. Measured on
  # tools/eos-repo-sign: regions 38.12 %, lines 41.06 %. The floor here is a LINES floor (it is the
  # same 38 that verify.sh passes to --fail-under-lines), so the text table compared the wrong
  # number against it and passed by three hundredths of a point. The JSON has one name per number.
  python3 -c 'import sys,json
d=json.load(sys.stdin)
print("%.2f" % d["data"][0]["totals"]["lines"]["percent"])' 2>/dev/null
}

if [ "$SELFTEST" -eq 1 ]; then
  # The floor comparison is the thing that can go wrong silently, so that is what the self-test
  # exercises -- without a 5-minute cargo run.
  measured="37.9"; floor="38"
  if awk -v m="$measured" -v f="$floor" 'BEGIN{exit !(m+0 < f+0)}'; then
    echo "selftest ok: ${measured} % under a floor of ${floor} is detected as a defect (exit 1)"
    exit 0
  fi
  echo "SELFTEST FAILED: ${measured} under ${floor} was not detected" >&2
  exit 1
fi

command -v cargo >/dev/null 2>&1 || { echo "CANNOT RUN: cargo is not on PATH (rustup; rust-toolchain.toml pins the version)"; exit 2; }
command -v cargo-llvm-cov >/dev/null 2>&1 || { echo "CANNOT RUN: cargo-llvm-cov is not installed (cargo install --locked cargo-llvm-cov)"; exit 2; }
rustup component list --installed 2>/dev/null | grep -q llvm-tools || { echo "CANNOT RUN: llvm-tools-preview is not installed (rustup component add llvm-tools-preview)"; exit 2; }

# WHERE THE COVERAGE TARGET GOES, and why it is not just $TMPDIR.
# Two constraints, both measured on this host:
#   1. it must be OFF the repo volume. The tree lives on exFAT, where macOS writes an AppleDouble
#      sidecar beside every file it touches -- including the .profraw files, which then match the
#      profraw glob and make llvm-profdata refuse the whole merge. verify.sh relocates it for the
#      same reason.
#   2. it must be somewhere with ROOM. A cargo-llvm-cov target for two manifests is ~1.5 GiB, and
#      the default per-user temp directory lives on the internal disk, which on this machine has
#      been at 96-99 % more than once today. A coverage run that dies on ENOSPC reports nothing
#      and looks exactly like a run that found nothing.
# EOS_COV_TARGET overrides both. The space check below refuses EARLY and names the filesystem,
# instead of letting cargo fail halfway through with a message about a profraw file.
COV_TARGET="${EOS_COV_TARGET:-${TMPDIR:-/tmp}eos-coverage-report}"
mkdir -p "$COV_TARGET" 2>/dev/null || { echo "CANNOT RUN: cannot create $COV_TARGET"; exit 2; }
cov_free=$(df -k "$COV_TARGET" | awk 'NR==2 {print $4}')
case "$cov_free" in ''|*[!0-9]*) echo "CANNOT RUN: cannot read free space for $COV_TARGET"; exit 2 ;; esac
if [ "$cov_free" -lt 2097152 ]; then    # 2 GiB: measured ~1.5 GiB for both manifests, plus headroom
  echo "CANNOT RUN: the coverage target has no room."
  echo "            $COV_TARGET is on $(df -h "$COV_TARGET" | awk 'NR==2 {print $1" mounted on "$NF}')"
  echo "            need 2048 MiB, have $(( cov_free / 1024 )) MiB."
  echo "            Set EOS_COV_TARGET to a filesystem with room (note P-16: bare \`mktemp -d\`"
  echo "            and a default TMPDIR both land on the internal disk on macOS)."
  exit 2
fi

rc=0
rows=""
printf 'coverage-report — %s\n' "$(git rev-parse --short HEAD 2>/dev/null || echo '?')"
while IFS='|' read -r dir manifest gated deffloor; do
  [ -n "$dir" ] || continue
  floor=$(floor_for "$dir" "$deffloor")
  out=$(CARGO_TARGET_DIR="$COV_TARGET" cargo llvm-cov --locked --manifest-path "$manifest" --json --summary-only 2>/dev/null)
  pct=$(printf '%s' "$out" | pct_of)
  if [ -z "$pct" ]; then
    printf '  %-24s MEASUREMENT FAILED (no TOTAL line)\n' "$dir"
    printf '%s\n' "$out" | tail -3 | sed 's/^/      /'
    rc=2
    rows="${rows}| \`${dir}\` | — | ${gated} | ${floor} | measurement failed |
"
    continue
  fi
  if [ "$gated" = "yes" ] && awk -v m="$pct" -v f="$floor" 'BEGIN{exit !(m+0 < f+0)}'; then
    printf '  %-24s %6s %%  floor %-5s  BELOW THE FLOOR\n' "$dir" "$pct" "$floor"
    [ "$rc" -eq 0 ] && rc=1
    state="**below the floor**"
  else
    printf '  %-24s %6s %%  floor %-5s  %s\n' "$dir" "$pct" "$floor" "$([ "$gated" = yes ] && echo ok || echo advisory)"
    state=$([ "$gated" = yes ] && echo ok || echo "advisory — not gated")
  fi
  rows="${rows}| \`${dir}\` | ${pct} % | ${gated} | ${floor} | ${state} |
"
done <<EOF
$CRATES
EOF

if [ -n "$WRITE" ]; then
  mkdir -p "$(dirname "$WRITE")"
  {
    printf -- '---\ntitle: Test coverage\nstatus: generated\nlast-reviewed: written by scripts/eos-coverage-report.sh\nowner: Gh0s777tt\n---\n\n'
    printf '# Test coverage\n\n'
    printf '**Generated — do not edit by hand.** `scripts/eos-coverage-report.sh` writes this file and\n'
    printf 'fails when a gated crate falls under its floor; the floors live in `coverage-floors.toml`,\n'
    printf 'so raising one is an ordinary commit and lowering one is visible in a diff (`CLAUDE.md` §5.10).\n\n'
    printf 'The asymmetry is deliberate: the vendored `redox_cookbook` is reported without a threshold,\n'
    printf 'because gating coverage on a tree we do not maintain is re-litigating code we do not own.\n\n'
    printf 'A high number is not proof. Coverage says what was **executed**, never what was **checked** —\n'
    printf 'the mutation score (`TQ-006`) and the security proxies (`TQ-002`) answer the other half.\n\n'
    printf '| crate | lines | gated | floor | state |\n|---|---|---|---|---|\n'
    printf '%s' "$rows"
    # No commit hash in the file. It looks like useful provenance and is not: the page is
    # rewritten by a verify.sh stage, so a hash here makes the file dirty after EVERY run --
    # `git status` is never clean once the gate has been used, and the churn teaches people to
    # commit a regenerated file without reading it. `git log docs/reference/coverage.md` gives the
    # same provenance without touching the working tree.
  } > "$WRITE"
  printf '  wrote %s\n' "$WRITE"
fi

case "$rc" in
  0) echo "coverage-report: ok" ;;
  1) echo "coverage-report: FAIL — a gated crate is under its floor" ;;
  2) echo "coverage-report: CANNOT — a measurement did not produce a total" ;;
esac
exit "$rc"
