#!/usr/bin/env python3
"""One Definition of Done, and every copy of it points here.

WHY THIS EXISTS.  Measured 2026-09-03: this project had THREE checklists claiming to be the
Definition of Done -- `CLAUDE.md` section 6 with 18 items, `CONTRIBUTING.md` with a different 14,
and the merge-request template with 8 while its header said it *was* "the Definition of Done from
CLAUDE.md".  None referred to the others, and they had already drifted apart.  Three copies of one
rule is three answers to one question, and the reader who ticks the eight-item list believes they
are done (ROADMAP `RH-011`).

THE RULE, deliberately narrow: any document other than `CLAUDE.md` that carries a "Definition of
Done" heading must, inside that section, point at `CLAUDE.md` section 6.  It does NOT compare item
text -- the contract is Polish and `CONTRIBUTING.md` is English, so a textual diff would be noise,
and a gate that cries wolf is a gate people route around.  What it enforces is that a reader who
lands on a copy is told where the whole list lives.

It also refuses the specific false claim that started this: a copy asserting that it IS the
Definition of Done, rather than a view of it.

Exit codes: 0 clean, 1 a copy is unanchored or claims completeness, 2 the gate could not run.

    scripts/eos-check-dod-refs.py [--selftest]
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTRACT = os.path.join(ROOT, "CLAUDE.md")
COPIES = [
    "CONTRIBUTING.md",
    os.path.join(".gitlab", "merge_request_templates", "Default.md"),
]

HEAD_RE = re.compile(r"^#{1,6}\s*.*Definition of Done.*$", re.M | re.I)
# "CLAUDE.md §6", "CLAUDE.md section 6", "§6 of CLAUDE.md" -- any of them anchors the reader.
ANCHOR_RE = re.compile(r"CLAUDE\.md[^\n]{0,40}(?:§|section\s*)\s*6\b", re.I)
# The claim that made the eight-item list look authoritative.
FALSE_CLAIM_RE = re.compile(
    r"(?:is|are)\s+the\s+Definition\s+of\s+Done(?!\s+(?:for|from)?\s*[^\n]{0,30}\bfull\b)", re.I)


def section_text(text, start):
    """From a heading to the next heading of the same or higher level, or the end."""
    line_start = text.rfind("\n", 0, start) + 1
    heading = text[line_start:text.find("\n", start)]
    level = len(heading) - len(heading.lstrip("#"))
    rest = text[text.find("\n", start) + 1:]
    nxt = re.search(r"^#{1,%d}\s" % max(level, 1), rest, re.M)
    return rest[:nxt.start()] if nxt else rest


def check(docs, contract):
    """docs: {path: text}. contract: CLAUDE.md text."""
    problems = []
    if not re.search(r"^##\s*6\.", contract, re.M):
        return None, "CLAUDE.md has no section 6 -- the contract moved, not the copies"

    for path, text in docs.items():
        if text is None:
            problems.append("rule 0: %s is listed as a copy but does not exist" % path)
            continue
        # UNCONDITIONAL, and the first version of this rule was not. It only fired on documents
        # carrying a literal "Definition of Done" heading -- and CONTRIBUTING.md carries its
        # checklist under "Pull / merge request checklist", so deleting its anchor passed the
        # gate green. A rule keyed on a heading checks the heading, not the thing (CLAUDE.md
        # §5.4). These files are listed here BECAUSE they carry a copy of the checklist; that
        # is the fact being enforced, so the anchor is required outright.
        if not ANCHOR_RE.search(text):
            problems.append("rule 1: %s carries a copy of the checklist and never points at "
                            "CLAUDE.md section 6" % path)
        if FALSE_CLAIM_RE.search(text):
            problems.append('rule 2: %s claims to BE the Definition of Done; it is a view of it, '
                            "and the full list is CLAUDE.md section 6" % path)
    return problems, None


def selftest():
    contract = "## 6. Definicja ukonczenia\n- [ ] a\n"
    good = "## Definition of Done\n\nFull list: CLAUDE.md §6.\n- [ ] x\n"
    cases = [
        ("an anchored copy passes", {"c.md": good}, contract, None),
        ("an unanchored copy is refused", {"c.md": "## Definition of Done\n- [ ] x\n"}, contract, "rule 1"),
        # The case the first version of this gate let through: a copy whose checklist sits under
        # a heading that does not say "Definition of Done" at all.
        ("an unanchored copy under another heading is refused",
         {"c.md": "## Pull / merge request checklist\n- [ ] x\n"}, contract, "rule 1"),
        ("a copy claiming to BE it is refused",
         {"c.md": good + "\nThis checklist is the Definition of Done.\n"}, contract, "rule 2"),
        ("a missing copy is refused", {"c.md": None}, contract, "rule 0"),
        ("no section 6 is an instrument fault", {"c.md": good}, "## 5. Something\n", "INSTRUMENT"),
        ("'section 6' spelling also anchors",
         {"c.md": "## Definition of Done\n\nSee CLAUDE.md section 6.\n"}, contract, None),
    ]
    fails = 0
    for name, docs, con, want in cases:
        problems, instrument = check(docs, con)
        if want == "INSTRUMENT":
            ok = instrument is not None
            got = instrument or "no instrument fault reported"
        elif want is None:
            ok = not problems and not instrument
            got = "clean" if ok else (instrument or problems[0])
        else:
            ok = bool(problems) and problems[0].startswith(want)
            got = problems[0] if problems else "accepted -- the gate did NOT fail"
        print("  selftest %-40s %s  (%s)" % (name, "ok" if ok else "FAIL", got))
        if not ok:
            fails += 1
    if fails:
        print("dod-refs selftest: %d of %d cases wrong" % (fails, len(cases)))
        return 1
    print("dod-refs selftest: %d cases, every rule refuses what it should" % len(cases))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if not os.path.isfile(CONTRACT):
        print("dod-refs: FAIL (instrument): CLAUDE.md is missing at %s" % CONTRACT)
        return 2
    contract = io.open(CONTRACT, encoding="utf-8").read()
    docs = {}
    for rel in COPIES:
        p = os.path.join(ROOT, rel)
        docs[rel] = io.open(p, encoding="utf-8").read() if os.path.isfile(p) else None
    problems, instrument = check(docs, contract)
    if instrument:
        print("dod-refs: FAIL (instrument): %s" % instrument)
        return 2
    if problems:
        for p in problems:
            print("dod-refs: %s" % p)
        print("dod-refs: FAIL -- %d unanchored copy/copies of the Definition of Done" % len(problems))
        return 1
    print("dod-refs: %d copies of the Definition of Done, all pointing at CLAUDE.md section 6"
          % len(docs))
    return 0


if __name__ == "__main__":
    sys.exit(main())
