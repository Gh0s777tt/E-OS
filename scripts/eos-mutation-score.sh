#!/usr/bin/env bash
# Mutation score for the E-OS-owned crate, with a floor that can go red.
#
#   scripts/eos-mutation-score.sh [--selftest] [--help]
#
# WHY THIS EXISTS, WHEN COVERAGE ALREADY HAS A FLOOR.  Coverage says a line RAN. It cannot say the
# test would have NOTICED had the line been wrong. Measured on this crate 2026-09-04: line coverage
# 41.06 % and a mutation score of 52.2 %, and among the survivors was
#
#     src/main.rs: replace && with || in verify        MISSED
#
# `verify()`'s `ed_ok && pq_ok` is the entire guarantee a hybrid signature makes -- both algorithms
# must verify, so that a break of either one alone is not enough. Nothing in the suite could tell
# that from `||`. The line was covered. It was not checked.
#
# WHAT THE FLOOR IS FOR. Regression, not certification. 58 % is not a good score; it is below the
# 60.4 % measured after the tests that killed the `verify` mutant, so a future change that stops
# checking something turns this red. Raising it is an ordinary commit. Lowering it needs the
# owner's agreement and a reason in the commit body -- the same rule as the coverage floor (§5.10).
#
# WHAT CANNOT BE KILLED, and why the floor is not 100:
#   * `replace | with ^ in hex_decode` is an EQUIVALENT mutant. The two nibbles occupy disjoint
#     bits, so `(hi << 4) | lo` and `(hi << 4) ^ lo` agree on every possible input. No test can
#     distinguish them, and pretending otherwise would mean writing one that lies.
#   * `replace <fn> with ()` for `keygen`, `sign`, `verify` and `main`. These read files, write
#     files and call `die()`, which exits the process. They are exercised by
#     `scripts/publish-repo.sh` against a real index, not by unit tests.
#   * fourteen mutants in `main`'s argument dispatch, for the same reason.
#
# Exit codes: 0 at or above the floor, 1 below it, 2 the gate could not run.
set -uo pipefail

FLOOR_FILE="mutation-floor.txt"
CRATE="tools/eos-repo-sign"

cannot() { printf 'mutation-score: cannot run -- %s\n' "$*" >&2; exit 2; }

case "${1:-}" in
  -h|--help) sed -n '2,34p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

# parse_summary <text> -> "caught missed" on stdout, or nothing when the line is absent.
# cargo-mutants prints one summary line; everything else in this script depends on reading it
# correctly, so it is a function with its own tests rather than an inline sed.
parse_summary() {
  printf '%s\n' "$1" | sed -n 's/.*: \([0-9]\{1,\}\) missed, \([0-9]\{1,\}\) caught.*/\2 \1/p' | tail -1
}

# score <caught> <missed> -> integer percent, floored. Integer arithmetic on purpose: bash has no
# floats, and a floor comparison that silently truncates differently on two machines is worse than
# a coarse one that does not.
score() {
  local caught="$1" missed="$2" total
  total=$(( caught + missed ))
  [ "$total" -gt 0 ] || { echo 0; return; }
  echo $(( caught * 100 / total ))
}

selftest() {
  local fails=0 got
  check() { # <label> <expected> <actual>
    if [ "$2" = "$3" ]; then printf '  selftest %-46s ok (%s)\n' "$1" "$3"
    else printf '  selftest %-46s FAIL (got %s, wanted %s)\n' "$1" "$3" "$2"; fails=$((fails+1)); fi
  }
  got="$(parse_summary '55 mutants tested in 52s: 19 missed, 29 caught, 7 unviable')"
  check "a real summary line is parsed" "29 19" "$got"
  got="$(parse_summary '53 mutants tested in 45s: 22 missed, 24 caught, 7 unviable')"
  check "another one, different numbers" "24 22" "$got"
  got="$(parse_summary 'no summary here at all')"
  check "a line with no summary yields nothing" "" "$got"
  # The failure this shape of parser actually has: matching the FIRST number it sees.
  got="$(parse_summary 'Found 99 mutants to test
55 mutants tested in 52s: 19 missed, 29 caught, 7 unviable')"
  check "the summary wins over an earlier count" "29 19" "$got"
  check "score rounds down, never up" "60" "$(score 29 19)"
  check "score of a perfect run" "100" "$(score 10 0)"
  check "score of a hopeless run" "0" "$(score 0 10)"
  check "no mutants is 0, not a division by zero" "0" "$(score 0 0)"
  if [ "$fails" -gt 0 ]; then
    printf 'mutation-score selftest: %d case(s) wrong\n' "$fails"; return 1
  fi
  printf 'mutation-score selftest: 8 cases, the parser and the arithmetic both behave\n'
  return 0
}

[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }

command -v cargo >/dev/null 2>&1 || cannot "cargo is not on PATH"
command -v cargo-mutants >/dev/null 2>&1 || cannot "cargo-mutants is missing (cargo install cargo-mutants)"
[ -d "$CRATE" ] || cannot "$CRATE is not here; run me from the repository root"
[ -f "$FLOOR_FILE" ] || cannot "$FLOOR_FILE is missing -- the floor is data, not a default"

floor="$(tr -dc '0-9' < "$FLOOR_FILE")"
case "$floor" in ''|*[!0-9]*) cannot "$FLOOR_FILE does not contain a number" ;; esac

# -j 1 DELIBERATELY. Measured 2026-09-04: the same tree gave 14, 18 and 21 missed on -j 4 and a
# stable 21 on -j 1. Parallel runs share a target directory and time out under contention, and a
# timeout is counted as MISSED -- so a parallel run reports a score that depends on how busy the
# machine was. A gate whose number moves with the weather is not a gate.
out="$(cd "$CRATE" && cargo mutants --no-shuffle --timeout 120 -j 1 2>&1)"
summary="$(parse_summary "$out")"
[ -n "$summary" ] || cannot "cargo-mutants printed no summary line; last output: $(printf '%s' "$out" | tail -1)"

caught="${summary% *}"
missed="${summary#* }"
pct="$(score "$caught" "$missed")"

printf 'mutation-score: %s%% (%s caught, %s missed) floor %s%%\n' "$pct" "$caught" "$missed" "$floor"
if [ "$pct" -lt "$floor" ]; then
  printf 'mutation-score: FAIL -- %s%% is below the floor of %s%%\n' "$pct" "$floor" >&2
  printf 'mutation-score:        a test stopped noticing something. The survivors are listed in\n' >&2
  printf 'mutation-score:        %s/mutants.out/missed.txt\n' "$CRATE" >&2
  exit 1
fi
