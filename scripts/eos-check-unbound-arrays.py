#!/usr/bin/env python3
"""Refuse an empty array expanded under `set -u` -- fatal on the reference host's bash 3.2.

WHY THIS EXISTS. `ci-integrity.sh` check 5 greps for bash-4-ONLY SYNTAX (`declare -A`,
`mapfile`, `${x^^}`). It cannot see this one, because this is not a syntax error: the script
parses fine in bash 3.2 and dies at run time, on one branch, only when the array happens to be
empty.

MEASURED, 2026-08-31, on scripts/ci-install-smoke.sh:

    if [ "$ARCH" = "x86_64" ]; then
      VIDEO_ARGS=()                 # empty on THIS branch only
    else
      VIDEO_ARGS=(-device ramfb)
    fi
    "$QEMU" ... "${VIDEO_ARGS[@]}" ...

    -> scripts/ci-install-smoke.sh: line 100: VIDEO_ARGS[@]: unbound variable
    -> /bin/bash --version: 3.2.57(1)-release

The harness died before qemu started -- and in the same tree `ci-integrity.sh` printed
`ok: no bash-4-only syntax or GNU-only regex in E-OS scripts` and exited 0. A gate that lets
through the exact class of defect it exists for is the thing CLAUDE.md 4.1 forbids.

WHAT IT LOOKS FOR, and why it is narrow on purpose. Proving "this array can be empty here" in
general needs data-flow analysis nobody will maintain. So the rule is the one shape that
actually caused the bug and reads unambiguously:

  * the script turns on `set -u` (any `set` with `u` in its flags), AND
  * it assigns an EMPTY ARRAY LITERAL somewhere: NAME=(), AND
  * it expands ${NAME[@]} or ${NAME[*]} without the portable guard.

The guard is `${NAME[@]+"${NAME[@]}"}`; folding the elements into an array that is never empty
is the other fix, and the one ci-boot-smoke.sh has always used.

False negatives are accepted: an array emptied by `NAME=("${OTHER[@]}")` where OTHER is empty
is not caught. Better a check that is right about what it claims than one that guesses.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS = os.path.join(ROOT, "scripts")

SET_U = re.compile(r"^\s*set\s+-[A-Za-z]*u[A-Za-z]*\b|^\s*set\s+-o\s+nounset\b", re.M)
EMPTY_ARRAY = re.compile(r"^\s*(?:local\s+|declare\s+-a\s+|readonly\s+)?([A-Za-z_][A-Za-z0-9_]*)=\(\s*\)\s*(?:#.*)?$", re.M)


def unguarded_uses(text, name):
    """Line numbers where `name` is expanded as an array without the `+` guard."""
    out = []
    guard = "${%s[@]+" % name
    pat = re.compile(r"\$\{" + re.escape(name) + r"\[[@*]\]\}")
    for i, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("#"):
            continue
        if guard in line:
            continue
        if pat.search(line):
            out.append(i)
    return out


def main():
    if not os.path.isdir(SCRIPTS):
        print("FAIL (instrument): no scripts/ directory at %s" % SCRIPTS, file=sys.stderr)
        return 2
    findings = []
    checked = 0
    for name in sorted(os.listdir(SCRIPTS)):
        if not name.endswith(".sh"):
            continue
        path = os.path.join(SCRIPTS, name)
        try:
            with open(path, encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError as err:
            print("FAIL (instrument): cannot read %s: %s" % (path, err), file=sys.stderr)
            return 2
        checked += 1
        if not SET_U.search(text):
            continue
        for var in sorted({m.group(1) for m in EMPTY_ARRAY.finditer(text)}):
            for line_no in unguarded_uses(text, var):
                findings.append((name, line_no, var))

    if not checked:
        print("FAIL (instrument): no *.sh found under scripts/ -- the check measured nothing",
              file=sys.stderr)
        return 2

    if findings:
        print("empty array expanded under `set -u` -- fatal on bash 3.2:")
        for name, line_no, var in findings:
            print("  scripts/%s:%d  ${%s[@]}  (assigned empty as `%s=()` in this file)"
                  % (name, line_no, var, var))
        print("  fix: guard it -- ${%s[@]+\"${%s[@]}\"} -- or fold the elements into an array"
              % (findings[0][2], findings[0][2]))
        print("       that is never empty, the way scripts/ci-boot-smoke.sh does.")
        return 1

    print("ok: no empty array expanded under `set -u` (%d shell scripts walked)" % checked)
    return 0


if __name__ == "__main__":
    sys.exit(main())
