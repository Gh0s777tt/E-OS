#!/usr/bin/env python3
"""Every section this contract cites must exist, and its sections must be in order.

WHY THIS EXISTS.  `CLAUDE.md` is the document every other document and merge request cites.  It had
accumulated **18 citations to sections that do not exist** -- `§4.2`, `§4.3`, `§10.1`, `§10.3` and
friends, all survivors of an older numbering -- and its own `## 19. TODO` sat physically AFTER
`## 21`.  Nothing noticed, because no gate had ever read the document's own cross-references.  A
contract that cites itself wrongly teaches a reader to stop following its citations, which is worse
than having none.

THREE RULES, each able to fail on its own:

  1. Every `§N` / `§N.M` citation in CLAUDE.md resolves to a heading in CLAUDE.md -- unless it is
     qualified as a cross-document reference (see rule 2).
  2. A citation qualified with ROADMAP (`ROADMAP §3.4`, `ROADMAP.md §11.3`, `§1.4 roadmapy`) is
     checked against ROADMAP.md's headings instead.  Cross-document references are legitimate; what
     is not legitimate is leaving the reader to guess which document a bare `§` means.
  3. Top-level sections appear in ascending numeric order.  Out-of-order sections are how `§19`
     ended up after `§21` and stayed there.

EXIT CODES follow the project split (U-177): 0 clean, 1 the tree has a defect, 2 the gate could not
run and you fix the toolbox instead.

    scripts/eos-check-claude-refs.py [--selftest]
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTRACT = os.path.join(ROOT, "CLAUDE.md")
PLAN = os.path.join(ROOT, "ROADMAP.md")

CITE_RE = re.compile(r"§\s*([0-9]+(?:\.[0-9]+)*)")
HEAD_RE = re.compile(r"^(#{2,6})\s+([0-9]+(?:\.[0-9]+)*)", re.M)
TOP_RE = re.compile(r"^##\s+([0-9]+)\.", re.M)
# How far back to look for a document qualifier before a citation. Long enough for
# "ROADMAP.md §3.4" and "stoi w ROADMAP §11.3", short enough not to swallow a whole sentence.
QUALIFIER_WINDOW = 24
QUALIFIER_RE = re.compile(r"(?:ROADMAP(?:\.md)?|roadmap[ayie]*)\W{0,4}$", re.I)
# A trailing qualifier: "(§1.4 roadmapy)" reads the other way round.
TRAILING_RE = re.compile(r"^\s*(?:roadmap[ayie]*|ROADMAP(?:\.md)?)\b")


def headings(text):
    """Every section number a citation could point at, including implied parents."""
    out = set()
    for m in HEAD_RE.finditer(text):
        parts = m.group(2).split(".")
        for i in range(1, len(parts) + 1):
            out.add(".".join(parts[:i]))
    return out


def check(contract, plan):
    problems = []
    own = headings(contract)
    theirs = headings(plan)
    if not own:
        return None, "CLAUDE.md has no numbered headings -- the document, not the citations, moved"

    for m in CITE_RE.finditer(contract):
        num = m.group(1)
        before = contract[max(0, m.start() - QUALIFIER_WINDOW):m.start()]
        after = contract[m.end():m.end() + 12]
        cross = bool(QUALIFIER_RE.search(before)) or bool(TRAILING_RE.match(after))
        line = contract.count("\n", 0, m.start()) + 1
        if cross:
            if num not in theirs:
                problems.append("rule 2: line %d cites ROADMAP §%s, which is not a heading there"
                                % (line, num))
        elif num not in own:
            problems.append("rule 1: line %d cites §%s, which is not a heading in CLAUDE.md"
                            % (line, num))

    order = [int(x) for x in TOP_RE.findall(contract)]
    for i in range(1, len(order)):
        if order[i] < order[i - 1]:
            problems.append("rule 3: section %d appears after section %d -- top-level sections must "
                            "be in ascending order" % (order[i], order[i - 1]))
    return problems, None


def selftest():
    contract = "\n".join([
        "## 1. First", "text", "## 2. Second", "see §1 and §2.1",
        "### 2.1 Sub", "and ROADMAP §9.9 and §7.7 roadmapy", "## 3. Third",
    ])
    plan = "\n".join(["## 9. Nine", "### 9.9 Deep", "## 7. Seven", "### 7.7 Deep"])
    cases = [
        ("clean document passes", contract, plan, None),
        ("citation of a missing own section", contract.replace("§2.1", "§2.9"), plan, "rule 1"),
        ("qualified citation, missing there", contract.replace("ROADMAP §9.9", "ROADMAP §9.8"), plan, "rule 2"),
        ("trailing qualifier is honoured", contract.replace("§7.7 roadmapy", "§7.6 roadmapy"), plan, "rule 2"),
        ("sections out of order", contract.replace("## 3. Third", "## 1. Again"), plan, "rule 3"),
    ]
    fails = 0
    for name, c, p, want in cases:
        problems, instrument = check(c, p)
        if instrument:
            print("  selftest %-36s INSTRUMENT: %s" % (name, instrument)); fails += 1; continue
        if want is None:
            ok = not problems
            got = "clean" if ok else problems[0]
        else:
            ok = bool(problems) and problems[0].startswith(want)
            got = problems[0] if problems else "accepted -- the gate did NOT fail"
        print("  selftest %-36s %s  (%s)" % (name, "ok" if ok else "FAIL", got))
        if not ok:
            fails += 1
    if fails:
        print("claude-refs selftest: %d of %d cases wrong" % (fails, len(cases)))
        return 1
    print("claude-refs selftest: %d cases, every mutation rejected by the rule it breaks" % len(cases))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    for path, what in ((CONTRACT, "CLAUDE.md"), (PLAN, "ROADMAP.md")):
        if not os.path.isfile(path):
            print("claude-refs: FAIL (instrument): %s is missing at %s" % (what, path))
            return 2
    contract = io.open(CONTRACT, encoding="utf-8").read()
    plan = io.open(PLAN, encoding="utf-8").read()
    problems, instrument = check(contract, plan)
    if instrument:
        print("claude-refs: FAIL (instrument): %s" % instrument)
        return 2
    if problems:
        for p in problems:
            print("claude-refs: %s" % p)
        print("claude-refs: FAIL -- %d unresolved reference(s) in CLAUDE.md" % len(problems))
        return 1
    n = len(CITE_RE.findall(contract))
    print("claude-refs: %d section citations, all resolve; %d top-level sections in order"
          % (n, len(TOP_RE.findall(contract))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
