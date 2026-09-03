#!/usr/bin/env python3
"""Refuse a CHANGELOG entry filed under a release that had already shipped when it happened.

WHY THIS EXISTS -- measured, not imagined.  On 2026-09-03 six top-level entries describing that
day's work sat under `## [0.2.0] - 2026-08-22`, a release tagged twelve days earlier.  Every other
gate was green: the file is valid Markdown, its CRLF endings were intact, `docs-currency` compares
the diff and does not read section headings, and the entries themselves were accurate -- only their
position lied.  A reader answering "what shipped in 0.2.0?" would have been told about work that
did not exist yet.

THE RULE, in one sentence: inside a section headed `## [x.y.z] - YYYY-MM-DD`, no line may cite a
date later than that release date.  `## [Unreleased]` carries no date and is therefore never
constrained -- which is the point, since that is where in-flight work belongs.

The counter-control (CLAUDE.md 5.9 level 4) was run before this file was written: against the
tree as it stood BEFORE the entries were moved, the rule reports six hits and names the lines;
against the corrected tree, zero.  A rule that reads the same on both sides of a fix has not
measured the fix.

EXIT CODES follow U-177: 0 clean, 1 the tree has a defect, 2 the gate could not run.

    scripts/eos-check-changelog-sections.py [--selftest]
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHANGELOG = os.path.join(ROOT, "CHANGELOG.md")

SECTION_RE = re.compile(r"^##\s+\[([^\]]+)\]\s*(?:-\s*(\d{4}-\d{2}-\d{2}))?\s*$")
DATE_RE = re.compile(r"\b(20\d\d-\d\d-\d\d)\b")


def check(text):
    """-> list of problem strings. Reads the file the way a person reads it: top to bottom."""
    problems = []
    section = None
    section_date = None
    saw_section = False
    for lineno, line in enumerate(text.split("\n"), 1):
        m = SECTION_RE.match(line.rstrip("\r"))
        if m:
            section, section_date = m.group(1), m.group(2)
            saw_section = True
            continue
        if not section_date:
            continue
        for cited in DATE_RE.findall(line):
            if cited > section_date:
                problems.append(
                    "line %d: %s is cited inside [%s], which shipped on %s -- an entry cannot "
                    "describe work that happened after its own release" % (lineno, cited, section, section_date))
    if not saw_section:
        return None
    return problems


def selftest():
    good = "\n".join([
        "## [Unreleased]",
        "- work from 2026-09-03, which belongs here and is never constrained",
        "## [0.2.0] - 2026-08-22",
        "- something measured on 2026-08-20",
        "- and something on the release day itself, 2026-08-22",
    ])
    bad = good.replace("- something measured on 2026-08-20",
                       "- something measured on 2026-09-03")
    cases = [
        ("a clean file passes", good, None),
        ("a later date inside a release", bad, "line 4"),
        ("no sections at all", "just prose, no headings", "instrument"),
    ]
    failures = 0
    for name, text, want in cases:
        problems = check(text)
        if want == "instrument":
            ok = problems is None
            got = "instrument" if ok else "read as a tree defect"
        elif want is None:
            ok = problems == []
            got = "clean" if ok else problems[0]
        else:
            ok = bool(problems) and want in problems[0]
            got = problems[0] if problems else "accepted -- the gate did NOT fail"
        print("  selftest %-30s %s  (%s)" % (name, "ok" if ok else "FAIL", got))
        if not ok:
            failures += 1
    if failures:
        print("changelog-sections selftest: %d of %d cases wrong" % (failures, len(cases)))
        return 1
    print("changelog-sections selftest: %d cases, each rejected or accepted as intended" % len(cases))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if not os.path.isfile(CHANGELOG):
        print("changelog-sections: FAIL (instrument): CHANGELOG.md is missing at %s" % CHANGELOG)
        return 2
    text = io.open(CHANGELOG, encoding="utf-8", newline="").read()
    problems = check(text)
    if problems is None:
        print("changelog-sections: FAIL (instrument): CHANGELOG.md has no `## [version]` headings "
              "-- the file changed shape, so nothing was judged")
        return 2
    if problems:
        for p in problems:
            print("changelog-sections: %s" % p)
        print("changelog-sections: FAIL -- %d entr%s filed under a release that had already shipped"
              % (len(problems), "y" if len(problems) == 1 else "ies"))
        return 1
    dated = len([1 for line in text.split("\n") if SECTION_RE.match(line.rstrip("\r"))])
    print("changelog-sections: %d sections, no entry dated after the release it sits in" % dated)
    return 0


if __name__ == "__main__":
    sys.exit(main())
