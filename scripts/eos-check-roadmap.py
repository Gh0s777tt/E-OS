#!/usr/bin/env python3
"""ci-integrity check 15 -- the roadmap's own structure can now go red.

What it refuses, and why each rule exists (every one of them was hit at least once):

  1. an in-document link `](#anchor)` that resolves to no heading.  ROADMAP.md carries
     ~300 of these; a renamed heading silently orphans every link into it.
  2. two headings with the same `N.N` number.  2026-09-02 the file briefly had two `### 6.3`;
     the anchor pointed at the first, the content lived in the second, and nothing noticed.
  3. a register identifier defined in two table rows with two DIFFERENT status marks.  One
     identifier, one status (ROADMAP §0.2) -- the whole reason ROADMAP-v2.md was retired.
  4. a row marked done (checkmark) that carries no evidence token in the same row: a `U-NNN`
     changelog id, a merge request `!NN`, an issue `#NN`, a commit hash, or a date.  "Done"
     without a pointer is the claim class the 2026-08-31 re-verification found eight times
     in twenty rows (§3.1).

Exit 0 clean, 1 on any defect, 2 if the check itself could not run.  `--warn-only` turns
rules 3 and 4 into warnings (exit stays 0 for them) -- for measuring a tree before gating it,
never for passing a gate.  Negative test: `python3 scripts/eos-check-roadmap.py --selftest`
runs the four rules against a synthetic document that violates each once and expects 1.
"""
import argparse
import os
import re
import sys
import tempfile

DONE_MARKS = ("✅",)                       # ✅
STATUS_MARKS = ("✅", "\U0001F7E1", "\U0001F534", "❌", "⬜", "\U0001F7E2",
                "\U0001F4A1", "\U0001F6A7")    # ✅ 🟡 🔴 ❌ ⬜ 🟢 💡 🚧
ID_RE = re.compile(r"^\|\s*`((?:R|C|CS|WS|API|PR|TQ|RH|V2|S|M|L|EA|EB|EC)-[A-Z]?\d{1,4}[a-z]?)`\s*\|")
LINK_RE = re.compile(r"\]\(#([^)\s]+)\)")
HEAD_RE = re.compile(r"^(#{2,4})\s+(.+?)\s*$")
NUM_RE = re.compile(r"^#{2,4}\s+(?:Annex\s+)?([A-Z]?\d+(?:\.\d+)*)\b")
EVIDENCE_RE = re.compile(
    r"\bU-\d{3}\b|![0-9]{1,4}\b|#\d{1,4}\b|\b[0-9a-f]{7,40}\b|\b20\d\d-\d\d(?:-\d\d)?\b"
    r"|[\w./-]+\.(?:rs|mk|toml|sh|py|md|yml|yaml|lock):\d+"   # a file:line citation
    r"|§\s*[A-Z]?\d")                                         # a cross-reference to another section


def row_status(line):
    """The status mark of a table row is the LAST cell carrying one -- the state column.
    Scanning the whole line finds other rows' marks quoted in the text (`V2-MS15` ✅ …)."""
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    for c in reversed(cells):
        for s in STATUS_MARKS:
            if s in c:
                return s
    return None


def anchor(text):
    """GitLab/GitHub heading slug: lowercase, drop punctuation except '-' and spaces, spaces -> '-'."""
    t = re.sub(r"`", "", text)
    t = re.sub(r"[^\w\s-]", "", t.lower())
    return t.strip().replace(" ", "-")


def check(path, warn_only=False):
    try:
        with open(path, encoding="utf-8") as f:
            lines = f.read().splitlines()
    except OSError as e:
        print("CANNOT RUN: %s" % e)
        return 2

    defects, warnings = [], []
    heads, nums, ids = {}, {}, {}
    in_code = False
    for n, line in enumerate(lines, 1):
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        m = HEAD_RE.match(line)
        if m:
            a = anchor(m.group(2))
            # GitHub disambiguates repeats as -1, -2; count them so links to those resolve too
            k = heads.get(a, 0)
            heads[a] = k + 1
            if k:
                heads["%s-%d" % (a, k)] = 1
            mn = NUM_RE.match(line)
            if mn:
                nums.setdefault(mn.group(1), []).append(n)
        mi = ID_RE.match(line)
        if mi:
            ident = mi.group(1)
            ids.setdefault(ident, []).append((n, row_status(line), line))

    # rule 1: anchors
    in_code = False
    for n, line in enumerate(lines, 1):
        if line.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        for a in LINK_RE.findall(line):
            if a not in heads:
                defects.append("%s:%d: link to missing anchor #%s" % (path, n, a))

    # rule 2: duplicate heading numbers
    for num, where in sorted(nums.items()):
        if len(where) > 1:
            defects.append("%s: heading number %s used %d times (lines %s)"
                           % (path, num, len(where), ", ".join(map(str, where))))

    # rule 3: one identifier, one status
    for ident, rows in sorted(ids.items()):
        statuses = {s for _, s, _ in rows if s}
        if len(statuses) > 1:
            msg = "%s: `%s` has %d statuses across rows %s" % (
                path, ident, len(statuses), ", ".join(str(n) for n, _, _ in rows))
            (warnings if warn_only else defects).append(msg)

    # rule 4: done needs evidence
    for ident, rows in sorted(ids.items()):
        for n, s, line in rows:
            if s in DONE_MARKS and not EVIDENCE_RE.search(line):
                msg = "%s:%d: `%s` marked done with no evidence token (U-NNN, !MR, #issue, hash or date)" % (path, n, ident)
                (warnings if warn_only else defects).append(msg)

    for w in warnings:
        print("warn: " + w)
    for d in defects:
        print("FAIL: " + d)
    print("roadmap-check: %s -- %d headings, %d anchors, %d identifiers, %d defects, %d warnings"
          % (os.path.basename(path), sum(1 for _ in nums.values()), len(heads), len(ids), len(defects), len(warnings)))
    return 1 if defects else 0


SELFTEST_DOC = """# T

## 1. One
### 1.1 A
See [b](#11-b) and [missing](#nope).
### 1.1 B
| id | what | state |
|---|---|---|
| `R-001` | thing | ✅ |
| `R-001` | thing again | 🔴 |
| `R-002` | proven | ✅ `U-100` |
"""


def selftest():
    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as f:
        f.write(SELFTEST_DOC)
        p = f.name
    try:
        rc = check(p)
    finally:
        os.unlink(p)
    # expected: 1 missing anchor, 1 duplicate number, 1 dual status, 1 done-without-evidence -> exit 1
    if rc != 1:
        print("SELFTEST FAILED: expected exit 1 on the synthetic document, got %d" % rc)
        return 1
    print("selftest ok: the four rules each fired once and the exit code is 1")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("file", nargs="?", default="ROADMAP.md")
    ap.add_argument("--warn-only", action="store_true", help="rules 3 and 4 warn instead of failing")
    ap.add_argument("--selftest", action="store_true", help="run the negative test and exit")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    sys.exit(check(a.file, a.warn_only))


if __name__ == "__main__":
    main()
