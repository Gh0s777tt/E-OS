#!/usr/bin/env bash
# Every E-OS-authored shell script must fail loudly. Inherited ones are exempt, by name.
#
#   scripts/eos-check-shell-strict.sh [--selftest] [--help]
#
# WHY THIS EXISTS, AND WHY IT DEMANDS LESS THAN YOU MIGHT EXPECT.
#
# ROADMAP `RH-016` said "16 of 60 shell files set nothing, 36 lack -e". Measured on this tree with
# the whole file scanned rather than a 25-line window -- the first attempt used a window and
# reported `verify.sh` itself as setting nothing, which was false -- the real split is:
#
#     E-OS-OWNED     15 with `set -euo pipefail`, 15 with `set -uo pipefail`, ZERO with nothing
#     INHERITED      30 files, most setting nothing at all
#
# So the owned code is uniformly disciplined, and every file in the alarming count was a vendored
# cookbook helper. Acting on the original number would have meant editing upstream files and
# carrying that divergence through every sync (ADR-0003) -- a fix worse than the defect.
#
# WHAT IS REQUIRED: `-u` and `pipefail`. An unset variable and a swallowed pipeline status are
# silent wrong answers, and this project has been bitten by both (P-3, P-13, P-15).
#
# WHAT IS NOT REQUIRED: `-e`. Fifteen owned scripts deliberately run `set -uo pipefail` without it
# because they are gates and harnesses that INSPECT exit codes -- `ci-integrity.sh` collects
# failures instead of dying on the first, `ci-boot-smoke.sh` reads a timeout's status. Demanding
# `-e` would break exactly the scripts whose job is to keep running and report.
#
# Exit codes: 0 clean, 1 a script is missing the settings, 2 the gate could not run.
set -uo pipefail

die()    { printf 'shell-strict: %s\n' "$*" >&2; }
cannot() { printf 'shell-strict: cannot run -- %s\n' "$*" >&2; exit 2; }

case "${1:-}" in
  -h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

# E-OS-authored, per CLAUDE.md section 4: own scripts carry the `eos-` prefix, inherited ones keep
# their upstream names. `ci-*`, `hooks/`, `examples/` and `upstream/` are ours too.
is_owned() {
  case "$1" in
    scripts/eos-*|scripts/ci-*|scripts/verify.sh|scripts/hooks/*|examples/*|upstream/*) return 0 ;;
    *) return 1 ;;
  esac
}

# The first `set -` line anywhere in the file, not in a fixed window: several of these scripts
# carry a header comment longer than any window worth guessing.
first_set_line() { grep -m1 -E '^[[:space:]]*set[[:space:]]+-[a-zA-Z]' "$1" 2>/dev/null; }

check_file() {  # <path> <the set line, possibly empty> -> 0 ok, 1 not strict enough
  local f="$1" line="$2"
  if [ -z "$line" ]; then
    die "$f sets no shell options at all; E-OS scripts need at least 'set -uo pipefail'"
    return 1
  fi
  if ! printf '%s' "$line" | grep -qE 'set[[:space:]]+-[a-zA-Z]*u'; then
    die "$f does not set -u; an unset variable would expand to nothing and be obeyed"
    return 1
  fi
  if ! printf '%s' "$line" | grep -q 'pipefail'; then
    die "$f does not set pipefail; a failing command in a pipe would be judged by the last one (P-3)"
    return 1
  fi
  return 0
}

selftest() {
  local tmp rc fails=0
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/eos-shell-strict.XXXXXX")" || cannot "mktemp failed"
  trap 'rm -rf "$tmp"' RETURN
  run() { # <want-rc> <label> <set-line>
    local want="$1" label="$2" line="$3"
    check_file "fake.sh" "$line" >/dev/null 2>&1; rc=$?
    if [ "$rc" -eq "$want" ]; then printf '  selftest %-38s ok (exit %s)\n' "$label" "$rc"
    else printf '  selftest %-38s FAIL (exit %s, wanted %s)\n' "$label" "$rc" "$want"; fails=$((fails+1)); fi
  }
  run 0 "set -euo pipefail passes"        "set -euo pipefail"
  run 0 "set -uo pipefail passes"         "set -uo pipefail"
  run 1 "nothing set is refused"          ""
  run 1 "set -e alone is refused"         "set -e"
  run 1 "set -eu without pipefail refused" "set -eu"
  run 1 "set -o pipefail without -u refused" "set -o pipefail"

  # The ownership rule is half the gate, so it gets cases of its own.
  ownrun() { # <want-rc> <path>
    is_owned "$2"; rc=$?
    if [ "$rc" -eq "$1" ]; then printf '  selftest %-38s ok\n' "owned($2)=$1"
    else printf '  selftest %-38s FAIL (got %s)\n' "owned($2)=$1" "$rc"; fails=$((fails+1)); fi
  }
  ownrun 0 "scripts/eos-build.sh"
  ownrun 0 "scripts/ci-integrity.sh"
  ownrun 0 "scripts/hooks/pre-push"
  ownrun 1 "scripts/find-recipe.sh"
  ownrun 1 "scripts/print-recipe.sh"

  if [ "$fails" -gt 0 ]; then
    printf 'shell-strict selftest: %d case(s) wrong\n' "$fails"; return 1
  fi
  printf 'shell-strict selftest: 11 cases, every rule refuses what it should\n'
  return 0
}

[ "${1:-}" = "--selftest" ] && { selftest; exit $?; }

command -v git >/dev/null 2>&1 || cannot "git is missing"
command -v grep >/dev/null 2>&1 || cannot "grep is missing"
git rev-parse --show-toplevel >/dev/null 2>&1 || cannot "not inside a git working tree"

owned=0; bad=0; exempt=0
while IFS= read -r f; do
  case "$f" in */.*|.*) continue ;; esac
  [ -f "$f" ] || continue
  case "$f" in
    *.sh) ;;
    *) head -c 80 "$f" 2>/dev/null | grep -qE '^#!.*(bash|sh)([[:space:]]|$)' || continue ;;
  esac
  case "$f" in recipes/*|src/*) continue ;; esac
  if ! is_owned "$f"; then exempt=$((exempt+1)); continue; fi
  owned=$((owned+1))
  check_file "$f" "$(first_set_line "$f")" || bad=$((bad+1))
done < <(git ls-files)

if [ "$owned" -eq 0 ]; then
  cannot "no E-OS-owned shell scripts found -- the instrument, not the tree"
fi
if [ "$bad" -gt 0 ]; then
  printf 'shell-strict: FAIL -- %d of %d E-OS-owned scripts are not strict enough\n' "$bad" "$owned"
  exit 1
fi
printf 'shell-strict: %d E-OS-owned scripts all set -u and pipefail (%d inherited scripts exempt)\n' \
  "$owned" "$exempt"
