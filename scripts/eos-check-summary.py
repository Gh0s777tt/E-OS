#!/usr/bin/env python3
"""ci-integrity check 18 -- docs/SUMMARY.md mirrors the docs tree.

mdBook renders ONLY the pages SUMMARY.md lists.  A page that is not listed is written, tracked,
linked from other pages -- and absent from the published site.  The 2026-07-13 audit found eight
such pages; on 2026-09-03 there were fourteen (ADR-0007..0011, the four installer/update
specifications, and five reference/security pages).  Nothing failed, because nothing looked.

Two rules:
  1. every tracked docs/**/*.md is listed in SUMMARY.md -- except the dated and private trees
     (docs/archive/, docs/audit/, docs/prompts/), docs/img/README.md, and SUMMARY.md itself;
  2. every `(path.md)` link in SUMMARY.md points at a file that exists.

Exit 0 clean, 1 on any defect, 2 if the check cannot run.  `--selftest` builds a synthetic tree
that violates each rule once and expects exit 1.
"""
import os
import re
import subprocess
import sys
import tempfile

SKIP_PREFIX = ("docs/archive/", "docs/audit/", "docs/prompts/")
SKIP_EXACT = ("docs/SUMMARY.md", "docs/img/README.md")
LINK_RE = re.compile(r"\]\(([^)#\s]+\.md)(?:#[^)]*)?\)")


def tracked_docs(root):
    try:
        out = subprocess.run(["git", "-C", root, "ls-files", "-z", "--", "docs/*.md"],
                             capture_output=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError) as e:
        print("CANNOT RUN: git ls-files failed: %s" % e)
        return None
    return [p for p in out.decode("utf-8").split("\0") if p]


def check(root):
    docs = tracked_docs(root)
    if docs is None:
        return 2
    summary = os.path.join(root, "docs", "SUMMARY.md")
    try:
        with open(summary, encoding="utf-8") as f:
            text = f.read()
    except OSError as e:
        print("CANNOT RUN: %s" % e)
        return 2
    links = LINK_RE.findall(text)
    linked = set(os.path.normpath(os.path.join("docs", l)) for l in links)
    defects = []
    for p in sorted(docs):
        if p.startswith(SKIP_PREFIX) or p in SKIP_EXACT:
            continue
        if os.path.normpath(p) not in linked:
            defects.append("%s is tracked but not listed in docs/SUMMARY.md" % p)
    for l in links:
        target = os.path.normpath(os.path.join(root, "docs", l))
        if not os.path.isfile(target):
            defects.append("docs/SUMMARY.md links to a missing file: %s" % l)
    for d in defects:
        print("FAIL: " + d)
    print("summary-check: %d tracked pages, %d listed, %d defects" % (len(docs), len(links), len(defects)))
    return 1 if defects else 0


def selftest():
    t = tempfile.mkdtemp()
    try:
        os.makedirs(os.path.join(t, "docs", "guides"))
        open(os.path.join(t, "docs", "guides", "a.md"), "w").write("# a\n")
        open(os.path.join(t, "docs", "guides", "unlisted.md"), "w").write("# b\n")
        open(os.path.join(t, "docs", "SUMMARY.md"), "w").write("# Summary\n- [a](guides/a.md)\n- [gone](guides/gone.md)\n")
        subprocess.run(["git", "-C", t, "init", "-q"], check=True)
        subprocess.run(["git", "-C", t, "add", "-A"], check=True)
        subprocess.run(["git", "-C", t, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "t"], check=True)
        rc = check(t)
    finally:
        subprocess.run(["rm", "-rf", t])
    if rc != 1:
        print("SELFTEST FAILED: expected exit 1, got %d" % rc)
        return 1
    print("selftest ok: an unlisted page and a dead link each fired, exit 1")
    return 0


def main():
    if "--selftest" in sys.argv[1:]:
        sys.exit(selftest())
    if "-h" in sys.argv[1:] or "--help" in sys.argv[1:]:
        print(__doc__)
        sys.exit(0)
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    sys.exit(check(root))


if __name__ == "__main__":
    main()
