#!/usr/bin/env python3
"""Keep the published roadmap page from drifting away from ROADMAP.md.

WHY THIS EXISTS.  The owner asked for ONE plan file, and got it: eight documents were merged into
`ROADMAP.md`.  A rendered status page re-introduces exactly the failure that merge removed -- a
second place where the state of the project is written down -- unless something compares the two.
This is that something.

WHAT IT CHECKS (three rules, each able to fail on its own):

  1. Every milestone tile on the page carries `data-roadmap="M<n>"` AND SHOWS the status mark that
     ROADMAP.md section 3.4 gives that milestone.  The mark is read out of the tile's VISIBLE TEXT,
     not out of an attribute, because CLAUDE.md 5.4 says a gate on presence is not a gate: a hidden
     attribute could stay right while the tile a person reads goes wrong.  Here the checked value
     and the read value are the same characters.

  2. Every roadmap identifier cited anywhere in the page's prose exists as a row identifier in
     ROADMAP.md.  This catches the cheap kind of rot: an identifier renamed or dropped in the plan
     while the page keeps quoting it.

  3. Every `ADR-NNNN` cited on the page resolves to a file in `docs/adr/`.  ADRs are not roadmap
     rows, so rule 2 would let them rot silently; measured while writing this, the page cites
     ADR-0001 and ADR-0003, both of which exist -- the rule protects that, it does not assume it.

EXIT CODES follow the split from CLAUDE.md 13 (U-177): 0 clean, 1 the tree has a defect you fix by
editing the page or the plan, 2 the gate could not run and you fix the toolbox instead.

    scripts/eos-check-roadmap-page.py [--selftest]

`--selftest` is the negative control required by CLAUDE.md 5.4: it builds a page and a plan that
break each rule exactly once and demands that the checker reject each one, naming the right rule.
"""

import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAGE = os.path.join(ROOT, "docs", "roadmap", "index.html")
PLAN = os.path.join(ROOT, "ROADMAP.md")
ADR_DIR = os.path.join(ROOT, "docs", "adr")

# The marks ROADMAP.md uses in its state columns, longest first so the variation-selector forms of
# the emoji match before their bare code points do.
MARKS = ["⚙️", "✅", "🟡", "🔴", "💡", "🚧", "⚙"]

ID_RE = re.compile(r"\b((?:R|U|PR|TQ|RH|WS|CS|API|S|V2|ADR)-[A-Za-z0-9]+)\b")
ROW_ID_RE = re.compile(r"^\|\s*\**`?([A-Z][A-Za-z0-9]*-[A-Za-z0-9]+)`?\**\s*\|", re.M)
MILESTONE_ROW_RE = re.compile(r"^\|\s*\**(M[1-8])\b", re.M)
TILE_RE = re.compile(r'<[a-z]+[^>]*\bdata-roadmap="(M[1-8])"[^>]*>(.*?)</[a-z]+>', re.S)


def row_mark(line):
    """The status mark of a table row is the LAST cell that carries one -- the state column.

    Same rule as eos-check-roadmap.py, and for the same measured reason: descriptions quote marks
    ("was 🔴, now ✅") and reading the first one would report the sentence, not the state.
    """
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    for cell in reversed(cells):
        for mark in MARKS:
            if mark in cell:
                return mark
    return None


def plan_facts(plan_text):
    """-> (milestone marks, set of row identifiers) read out of ROADMAP.md."""
    milestones = {}
    for line in plan_text.split("\n"):
        m = MILESTONE_ROW_RE.match(line)
        if m and m.group(1) not in milestones:
            mark = row_mark(line)
            if mark:
                milestones[m.group(1)] = mark
    ids = set(ROW_ID_RE.findall(plan_text))
    ids |= set(MILESTONE_ROW_RE.findall(plan_text))
    return milestones, ids


def visible_text(html):
    """Drop the stylesheet and the tags; keep what a reader sees."""
    body = re.sub(r"<style>.*?</style>", " ", html, flags=re.S)
    body = re.sub(r"<script>.*?</script>", " ", body, flags=re.S)
    return re.sub(r"<[^>]+>", " ", body)


def check(page_text, plan_text, adr_ids):
    problems = []
    milestones, row_ids = plan_facts(plan_text)

    if not milestones:
        return None, "ROADMAP.md has no milestone rows M1-M8 -- the plan, not the page, moved"

    # -- rule 1: every milestone the plan knows about is on the page, showing the plan's mark.
    tiles = {mid: inner for mid, inner in TILE_RE.findall(page_text)}
    for mid in sorted(milestones):
        if mid not in tiles:
            problems.append('rule 1: %s has no tile on the page (expected data-roadmap="%s")' % (mid, mid))
            continue
        shown = [mark for mark in MARKS if mark in visible_text(tiles[mid])]
        if not shown:
            problems.append("rule 1: the %s tile shows no status mark; the plan says %s" % (mid, milestones[mid]))
        elif shown[0] != milestones[mid]:
            problems.append("rule 1: the %s tile shows %s, ROADMAP.md section 3.4 says %s"
                            % (mid, shown[0], milestones[mid]))
    for mid in sorted(set(tiles) - set(milestones)):
        problems.append("rule 1: the page has a %s tile that ROADMAP.md does not define" % mid)

    # -- rules 2 and 3: every identifier the page cites still exists somewhere.
    for ident in sorted(set(ID_RE.findall(visible_text(page_text)))):
        if ident.startswith("ADR-"):
            if ident not in adr_ids:
                problems.append("rule 3: the page cites %s, which is not a file in docs/adr/" % ident)
        elif ident not in row_ids:
            problems.append("rule 2: the page cites %s, which is not a row in ROADMAP.md" % ident)

    return problems, None


def adr_identifiers(adr_dir):
    out = set()
    for name in os.listdir(adr_dir):
        m = re.match(r"^(\d{4})-", name)
        if m:
            out.add("ADR-" + m.group(1))
    return out


def selftest():
    """Each mutation must be rejected, and rejected by the rule it breaks (CLAUDE.md 5.9 level 2)."""
    plan = "\n".join([
        "| **M1 - a thing** | what | deps | 🖥️ | 🟡 |",
        "| **M2 - another** | what | deps | 🖥️ | 🔴 |",
        "| `R-001` | a row | **WORKS TODAY** | ✅ |",
    ])
    page_ok = ('<div class="pill" data-roadmap="M1">🟡 10 of 11</div>'
               '<div class="pill" data-roadmap="M2">🔴 waiting</div>'
               '<p>see <code>R-001</code> and <code>ADR-0001</code></p>')
    adrs = {"ADR-0001"}

    cases = [
        ("clean page passes", page_ok, plan, None),
        ("wrong mark on a tile", page_ok.replace("🟡 10 of 11", "✅ 10 of 11"), plan, "rule 1"),
        ("tile missing entirely", page_ok.replace('<div class="pill" data-roadmap="M2">🔴 waiting</div>', ""), plan, "rule 1"),
        ("tile with no mark at all", page_ok.replace("🟡 10 of 11", "10 of 11"), plan, "rule 1"),
        ("citation of a dropped row", page_ok.replace("R-001", "R-999"), plan, "rule 2"),
        ("citation of a missing ADR", page_ok.replace("ADR-0001", "ADR-0042"), plan, "rule 3"),
    ]
    failures = 0
    for name, page, plan_text, want in cases:
        problems, instrument = check(page, plan_text, adrs)
        if instrument:
            print("  selftest %-28s INSTRUMENT: %s" % (name, instrument))
            failures += 1
            continue
        if want is None:
            ok = not problems
            got = "clean" if ok else problems[0]
        else:
            ok = bool(problems) and problems[0].startswith(want)
            got = problems[0] if problems else "accepted -- the gate did NOT fail"
        print("  selftest %-28s %s  (%s)" % (name, "ok" if ok else "FAIL", got))
        if not ok:
            failures += 1
    if failures:
        print("roadmap-page selftest: %d of %d cases wrong" % (failures, len(cases)))
        return 1
    print("roadmap-page selftest: %d cases, every mutation rejected by the rule it breaks" % len(cases))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()

    for path, what in ((PAGE, "the page"), (PLAN, "the plan")):
        if not os.path.isfile(path):
            print("roadmap-page: FAIL (instrument): %s is missing at %s" % (what, path))
            return 2
    if not os.path.isdir(ADR_DIR):
        print("roadmap-page: FAIL (instrument): docs/adr/ is missing at %s" % ADR_DIR)
        return 2

    page_text = io.open(PAGE, encoding="utf-8").read()
    plan_text = io.open(PLAN, encoding="utf-8").read()
    problems, instrument = check(page_text, plan_text, adr_identifiers(ADR_DIR))
    if instrument:
        print("roadmap-page: FAIL (instrument): %s" % instrument)
        return 2
    if problems:
        for p in problems:
            print("roadmap-page: %s" % p)
        print("roadmap-page: FAIL -- %d mismatch(es) between docs/roadmap/index.html and ROADMAP.md"
              % len(problems))
        return 1
    milestones, row_ids = plan_facts(plan_text)
    cited = len(set(ID_RE.findall(visible_text(page_text))))
    print("roadmap-page: %d milestone tiles match ROADMAP.md section 3.4, %d cited identifiers all resolve"
          % (len(milestones), cited))
    return 0


if __name__ == "__main__":
    sys.exit(main())
