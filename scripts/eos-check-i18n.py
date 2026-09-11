#!/usr/bin/env python3
"""Bramka i18n dla README — sprawdza WARTOŚĆ znacznika, nie jego obecność.

Powód (CLAUDE.md §5.4): `grep -q 'SYNC:' README.md` przechodzi przy dowolnej wartości markera, więc
marker zestarzał się niezauważony — dziś mówi U-224, a CHANGELOG stoi na U-230. Ta bramka nie może
powtórzyć tego błędu, więc każda z trzech reguł porównuje wartość, a --selftest dowodzi, że potrafi
paść.

Kod wyjścia: 0 ok · 1 wykryto usterkę · 2 nie dało się sprawdzić (brak gita, brak README).
"""
import re, subprocess, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
MASTER = "README.md"
MARKER = re.compile(r"<!--\s*I18N-SOURCE:\s*README\.md@([0-9a-f]{40})", re.I)
ROW    = re.compile(r"^\s*(?:`\[[a-z-]+\]`|\[`\[[a-z-]+\]`\]\([^)]*\))(?:\s*·\s*(?:`\[[a-z-]+\]`|\[`\[[a-z-]+\]`\]\([^)]*\)))*\s*$", re.M)
LINK   = re.compile(r"\[`\[([a-z-]+)\]`\]\(([^)]+)\)")
SELF   = re.compile(r"`\[([a-z-]+)\]`(?!\])")

def sh(*a):
    return subprocess.run(a, cwd=ROOT, capture_output=True, text=True)

def fail(msg):  print("bad: " + msg); return 1
def cannot(msg):print("cannot: " + msg); return 2
def ok(msg):    print("i18n: " + msg);  return 0

def check(rules=(1, 2)):
    master = ROOT / MASTER
    if not master.is_file():
        return cannot(f"{MASTER} does not exist")
    r = sh("git", "log", "-1", "--format=%H", "--", MASTER)
    if r.returncode != 0 or not r.stdout.strip():
        return cannot("git could not report the last commit touching " + MASTER)
    head = r.stdout.strip()

    translations = sorted(p.name for p in ROOT.glob("README.*.md"))
    if not translations:
        return ok("no translations present, nothing to gate")

    rc = 0
    # rule 1 — every translation names the master revision it was made from, and is not behind it
    for name in (translations if 1 in rules else []):
        text = (ROOT / name).read_text(encoding="utf-8")
        m = MARKER.search(text)
        if not m:
            rc |= fail(f"{name} carries no I18N-SOURCE marker")
            continue
        sha = m.group(1)
        if sha == head:
            continue
        anc = sh("git", "merge-base", "--is-ancestor", sha, head)
        if anc.returncode != 0:
            rc |= fail(f"{name} names {sha[:9]}, which is not an ancestor of {MASTER}@{head[:9]}")
            continue
        behind = sh("git", "rev-list", "--count", f"{sha}..{head}", "--", MASTER).stdout.strip()
        rc |= fail(f"{name} is {behind} commit(s) behind {MASTER} (marker {sha[:9]}, head {head[:9]})")

    # rule 2 — the language row lists exactly the files that exist: no dead links, no missing locale
    have = {n.split(".")[1] for n in translations} | {"en"}
    for name in ([MASTER] + translations if 2 in rules else []):
        text = (ROOT / name).read_text(encoding="utf-8")
        row = ROW.search(text)
        if not row:
            rc |= fail(f"{name} has no language row")
            continue
        listed = set(SELF.findall(row.group(0))) | {c for c, _ in LINK.findall(row.group(0))}
        if listed != have:
            rc |= fail(f"{name} language row lists {sorted(listed)}, files on disk are {sorted(have)}")
        for code, target in LINK.findall(row.group(0)):
            if not (ROOT / target).is_file():
                rc |= fail(f"{name} language row links to {target}, which does not exist")

    return rc or ok(f"{len(translations)} translation(s) current with {MASTER}@{head[:9]}, language rows agree with disk")

def selftest():
    """Prove each rule can go red ON ITS OWN.

    The first draft of this selftest passed for the wrong reason: the probe file it created also
    broke rule 2, so check() returned 1 even though rule 1 was never exercised. A selftest that
    cannot distinguish which rule fired is not a selftest (CLAUDE.md 21.6).
    """
    rc = 0
    r = sh("git", "log", "-2", "--format=%H", "--", MASTER)
    shas = r.stdout.split()
    if len(shas) < 2:
        return cannot("selftest needs at least two commits touching " + MASTER)
    older = shas[1]
    row = "`[en]` · `[__selftest__]`"
    probe = ROOT / "README.__selftest__.md"

    # case 1 -- stale marker, rule 1 ONLY
    probe.write_text(f"<!-- I18N-SOURCE: README.md@{older} -->\n{row}\n", encoding="utf-8")
    try:
        red = check(rules=(1,))
    finally:
        probe.unlink()
    if red != 1:
        rc |= fail(f"selftest case 1: a stale marker did not redden rule 1 alone (rc={red})")

    # case 2 -- language rows disagreeing with the files on disk, rule 2 ONLY.
    # NOTE: this probe reddens rule 2 through the row/disk mismatch, not through the dead-link
    # branch -- adding a file changes the expected locale set before the link is ever resolved.
    # The dead-link branch is therefore NOT covered by a negative test; say so rather than imply it.
    head = sh("git", "log", "-1", "--format=%H", "--", MASTER).stdout.strip()
    probe.write_text(
        f"<!-- I18N-SOURCE: README.md@{head} -->\n"
        "`[__selftest__]` · [`[zz]`](README.zz.md)\n", encoding="utf-8")
    try:
        red = check(rules=(2,))
    finally:
        probe.unlink()
    if red != 1:
        rc |= fail(f"selftest case 2: a row/disk disagreement did not redden rule 2 alone (rc={red})")

    # case 3 -- a clean tree must be green, or the gate is stuck red
    if check() != 0:
        rc |= fail("selftest case 3: the gate is not green on the tree as it stands")

    return rc or ok("selftest: 3 cases -- stale marker, row/disk disagreement, clean tree")

if __name__ == "__main__":
    sys.exit(selftest() if "--selftest" in sys.argv else check())
