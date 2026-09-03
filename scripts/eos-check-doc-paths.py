#!/usr/bin/env python3
"""ci-integrity check 14 -- refuse a `docs/...md` reference that points at no file.

Run with --fix to rewrite the unambiguous ones in place.

Why this exists rather than another one-off sweep. The tree was reorganised once
(d73fd1590) and mentions of the old paths stayed behind in running text. Issue #12
fixed one path, #17 counted eight and found ~141 hits; a full scan found 230 across
22 paths. Each sweep left the next drift free to accumulate, because nothing failed
when a stale path appeared. This is the thing that fails.

`lychee --offline` does not catch these: they are not broken *links*, they are
mentions in backticks. A reader follows one and lands on nothing.

Three kinds of match are NOT drift, and getting them wrong is how a sweep does harm:

  1. the tail of someone else's URL. recipes/wip/**/recipe.toml cite
     https://github.com/transmission/.../docs/Building-Transmission.md and friends.
     Those paths are correct -- in that project.
  2. a dated record. docs/audit/, docs/archive/, CHANGELOG.md, semver-decisions-*,
     github-configuration.md quote a state as of a date, often with a line number.
     Rewriting the path silently rewrites the finding.
  3. a deliberate exception, e.g. docs/THREAT_MODEL.md is recorded in CLAUDE.md as a
     decision, and docs/setup-features.md names a page that is generated and does not
     exist yet.

Exit 0 clean, 1 on any drift, 2 if the check itself could not run.
"""
import os
import re
import subprocess
import sys

SCAN_EXT = (".md", ".sh", ".py", ".toml", ".yml", ".yaml", ".rs")
DATED_PREFIX = ("docs/audit/", "docs/archive/")
# This file itself. It names dead paths as EXAMPLES of what it detects -- in the module
# docstring and in the comment explaining why line numbers are dropped -- so scanning it
# makes the gate fail on its own prose. Discovered the hard way: on the branch the file was
# still UNTRACKED, `git ls-files` does not list untracked files, so the gate never scanned
# itself and verify.sh went green; the merge made it tracked and main went red. Same class
# as P-9 in CLAUDE.md, where a tracked-files-only tool cannot see a new file.
# Retire this entry if the examples are ever moved out into a fixture file.
SELF = "scripts/eos-check-doc-paths.py"

DATED_EXACT = {
    "CHANGELOG.md",
    "docs/reference/semver-decisions-2026-08-30.md",
    "docs/security/github-configuration.md",
}
# path -> why it is allowed to look dead. Every entry must say what would retire it.
ALLOW = {
    # The six plans merged into ROADMAP.md §17-§21 on 2026-09-03 and deleted. ROADMAP.md names
    # them as history (§11.7.1, the §17-§21 headers, §16, Annex C.2) -- exactly where a dead path
    # belongs. Every LIVE citation was rewritten (48 in 23 files, cite-rewrite) and check 14 now
    # sees nested paths, so a new mention anywhere else still fails. Retire these six entries when
    # Annex C.2 is pruned.
    "docs/archive/plan.md": "merged into ROADMAP §17, removed 2026-09-03; retire with Annex C.2",
    "docs/archive/hardware-plan.md": "merged into ROADMAP §18, removed 2026-09-03; retire with Annex C.2",
    "docs/archive/roadmap-connectivity.md": "merged into ROADMAP §19, removed 2026-09-03; retire with Annex C.2",
    "docs/archive/hardware-capabilities-roadmap.md": "merged into ROADMAP §20, removed 2026-09-03; retire with Annex C.2",
    "docs/archive/acpi-off-removal-plan.md": "merged into ROADMAP §20.5, removed 2026-09-03; retire with Annex C.2",
    "docs/archive/feature-proposals.md": "merged into ROADMAP §21, removed 2026-09-03; retire with Annex C.2",
    "docs/THREAT_MODEL.md":
        "recorded decision, CLAUDE.md; retire when that row goes",
    "docs/setup-features.md":
        "page is generated from profile files and does not exist yet "
        "(docs/architecture/installer-wizard.md); retire when it is generated",
    "docs/submitting.md":
        "file in rhboot/shim-review, not ours; retire never",
    "docs/reviewer-guidelines.md":
        "file in rhboot/shim-review, not ours; retire never",
}
# The filename must START with an alphanumeric, so prose like `docs/...md` in a comment
# is not mistaken for a path. This gate flagged its own description in ci-integrity.sh
# before that anchor was added.
# `/` is in the class since 2026-09-03: without it the gate saw `docs/foo.md` but not
# `docs/security/foo.md` -- 69 nested references in the tree were never checked (DOC-04).
REF = re.compile(r"docs/[A-Za-z0-9][A-Za-z0-9_./\-]*\.md")


def tracked_files():
    r = subprocess.run(["git", "ls-files"], capture_output=True, text=True)
    if r.returncode != 0:
        print("doc-paths: cannot run `git ls-files` -- not a work tree?", file=sys.stderr)
        sys.exit(2)
    return r.stdout.split()


def rename_map():
    """old path -> newest path, from git's own rename detection.

    Basename matching alone is not enough: docs/design-desktop-environment.md became
    docs/architecture/desktop-environment.md, so the name changed too. git recorded the
    rename with a similarity score; that is a fact, not a guess.
    """
    r = subprocess.run(
        ["git", "log", "--all", "--diff-filter=R", "--find-renames=25%",
         "--summary", "--format="],
        capture_output=True, text=True)
    if r.returncode != 0:
        return {}
    out = {}
    # " rename docs/{a.md => sub/b.md} (97%)"  or  " rename docs/{ => sub}/a.md (96%)"
    brace = re.compile(r"^ rename (.*)\{(.*) => (.*)\}(.*) \(\d+%\)$")
    plain = re.compile(r"^ rename (\S+) => (\S+) \(\d+%\)$")
    for line in r.stdout.splitlines():
        m = brace.match(line)
        if m:
            pre, a, b, post = m.groups()
            src = (pre + a + post).replace("//", "/")
            dst = (pre + b + post).replace("//", "/")
        else:
            m = plain.match(line)
            if not m:
                continue
            src, dst = m.groups()
        # git log walks newest-first; the first entry seen is the most recent rename.
        out.setdefault(src, dst)
    # follow chains: a -> b -> c should report a -> c
    for src in list(out):
        seen, dst = {src}, out[src]
        while dst in out and dst not in seen:
            seen.add(dst)
            dst = out[dst]
        out[src] = dst
    return out


def main():
    fix = "--fix" in sys.argv[1:]
    files = tracked_files()
    if not files:
        print("doc-paths: `git ls-files` returned nothing; refusing to report clean",
              file=sys.stderr)
        return 2
    tracked = set(files)
    renames = rename_map()

    # basename -> real paths, so the message can name where the file went
    index = {}
    for f in tracked:
        index.setdefault(os.path.basename(f), []).append(f)

    hits = []
    scanned = 0
    for f in files:
        if not f.endswith(SCAN_EXT):
            continue
        if f == SELF or f.startswith(DATED_PREFIX) or f in DATED_EXACT:
            continue
        try:
            with open(f, encoding="utf-8", errors="ignore") as fh:
                lines = fh.read().splitlines()
        except OSError:
            continue
        scanned += 1
        for lineno, line in enumerate(lines, 1):
            # A dated measurement inside a script is a record too.
            if "Measured by grep" in line:
                continue
            for m in REF.finditer(line):
                path = m.group(0)
                if path in tracked or path in ALLOW:
                    continue
                before = line[:m.start()]
                # Skip only when this match is the TAIL OF A URL, not merely when a URL happens
                # to appear earlier in the same line. `"http" in before` skipped the whole line,
                # so a dead docs path could not be reported at all on any line that also carried
                # a link -- and in a docs tree, that is a lot of lines. Look at the token this
                # match belongs to instead: everything back to the nearest separator.
                cut = max(before.rfind(c) for c in " \t([<\"'`|") + 1
                token = before[cut:]
                if token.startswith("http://") or token.startswith("https://"):
                    continue
                moved = [c for c in index.get(os.path.basename(path), []) if c != path]
                if not moved:
                    r = renames.get(path)
                    if r and r in tracked:
                        moved = [r]
                hits.append((f, lineno, path, moved))

    if not hits:
        print(f"doc-paths: ok -- {scanned} tracked files, no reference to a missing docs page")
        return 0

    if fix:
        # Rewrite only what this same scan classified as drift, and only where the
        # target is unambiguous. One implementation decides both "is this drift" and
        # "what does it become", so the two can never disagree.
        # Deduplicate (file, line, path): `hits` holds one entry per OCCURRENCE, and a
        # single re.sub rewrites every occurrence on that line at once. Without this the
        # second visit finds the line already rewritten and reports it as "left alone" --
        # the file would be correct and the summary would be a lie. Counting comes from
        # re.subn, not from the loop, for the same reason.
        edits = {}
        for f, lineno, path, moved in hits:
            if len(moved) != 1:
                continue
            edits.setdefault(f, set()).add((lineno, path, moved[0]))
        changed = stale = 0
        for f, items in edits.items():
            with open(f, encoding="utf-8") as fh:
                lines = fh.read().split("\n")
            for lineno, path, target in sorted(items):
                i = lineno - 1
                if i >= len(lines):
                    stale += 1
                    continue
                # Drop any ":NN" / ":NN-MM" suffix along with the path. The rename
                # similarity scores are 90-99%, not 100%: the files were EDITED as they
                # moved, so line numbers computed against the old path do not survive.
                # Measured on this tree: 13 of 26 such citations landed on a blank line,
                # a table separator or a ```mermaid fence. Rewriting the path while
                # keeping the number turns an obviously-broken citation into one that
                # looks precise and is wrong -- strictly worse. The path alone is true
                # and checkable; the reader can search. Live paths keep their numbers,
                # because nothing invalidated them.
                # The suffix can be a LIST: docs/encryption.md:8,17,19-24,21,88 occurs
                # once in this tree. Consuming only the first number would leave
                # ",17,19-24,..." glued to the new path -- caught by reading the diff,
                # not by the exit code.
                lines[i], n = re.subn(
                    re.escape(path)
                    + r"(?![\w/])(:\d+(?:-\d+)?(?:,\d+(?:-\d+)?)*)?",
                    target, lines[i])
                if n == 0:
                    stale += 1
                changed += n
            with open(f, "w", encoding="utf-8") as fh:
                fh.write("\n".join(lines))
        amb = sum(1 for _, _, _, m in hits if len(m) != 1)
        print(f"doc-paths --fix: rewrote {changed} reference(s) in {len(edits)} file(s)")
        if amb:
            print(f"doc-paths --fix: left {amb} alone -- no single unambiguous target")
        if stale:
            print(f"doc-paths --fix: {stale} line(s) no longer matched -- re-run to re-scan")
        return 0

    print(f"doc-paths: {len(hits)} reference(s) to a docs page that does not exist\n")
    for f, lineno, path, moved in sorted(hits):
        where = moved[0] if len(moved) == 1 else (
            "candidates: " + ", ".join(moved) if moved else "no file of that name -- "
            "check `git log --diff-filter=R --find-renames --summary`")
        print(f"  {f}:{lineno}\n      {path}  ->  {where}")
    print("\nFix the reference, or -- if it is a dated record or someone else's file --")
    print("add it to DATED_* / ALLOW in scripts/eos-check-doc-paths.py with a reason")
    print("and the condition that would retire the entry.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
