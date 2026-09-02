#!/usr/bin/env python3
"""ci-integrity check 15 -- refuse a tracked build artefact or cache.

CLAUDE.md has always said not to commit caches or build artefacts. Nothing enforced it, and on
2026-09-01 two .pyc files reached `main` in a single day, both through `git add -A` in commits
that were about something else entirely. Neither was noticed by gitleaks, by integrity, or by
review -- a compiled cache is not a secret and not a defect, so nothing was looking.

The cost is not disk. A tracked .pyc changes every time anyone imports the module, so it shows
up as a spurious modification in `git status`, gets swept into the next `git add -A`, and
teaches people to ignore noise in their working tree. That is how the second one got in.

Exit 0 clean, 1 on any tracked artefact, 2 if the check itself could not run.
"""
import re
import subprocess
import sys

# Patterns are anchored on the whole tracked path. Each entry says what it catches, because a
# pattern nobody can explain is a pattern nobody dares to change.
FORBIDDEN = [
    (r"(^|/)__pycache__/", "Python bytecode cache directory"),
    (r"\.py[cod]$", "compiled Python module"),
    (r"(^|/)\.pytest_cache/", "pytest cache"),
    (r"(^|/)node_modules/", "installed npm dependencies"),
    (r"(^|/)target/(debug|release)/", "cargo build output"),
    (r"\.o$|\.a$|\.so$|\.dylib$", "compiled object or library"),
    (r"(^|/)\.DS_Store$", "macOS Finder metadata"),
    (r"(^|/)\._[^/]+$", "macOS AppleDouble sidecar"),
]

# Deliberate exceptions. An entry must say WHY, and what would retire it.
ALLOW = {
    # keys/*.pub.bin and similar are content, not build output; none match the patterns above
    # today. Kept as the place to record one rather than loosening a pattern.
}


def main():
    r = subprocess.run(["git", "ls-files"], capture_output=True, text=True)
    if r.returncode != 0:
        print("no-caches: cannot run `git ls-files` -- not a work tree?", file=sys.stderr)
        return 2
    files = r.stdout.split()
    if not files:
        print("no-caches: `git ls-files` returned nothing; refusing to report clean",
              file=sys.stderr)
        return 2

    hits = []
    for f in files:
        if f in ALLOW:
            continue
        for pat, why in FORBIDDEN:
            if re.search(pat, f):
                hits.append((f, why))
                break

    if not hits:
        print("no-caches: ok -- %d tracked files, no build artefact or cache among them"
              % len(files))
        return 0

    print("no-caches: %d tracked file(s) are build artefacts or caches\n" % len(hits))
    for f, why in sorted(hits):
        print("  %s\n      %s" % (f, why))
    print("\nUntrack them (the files stay on disk):")
    print("    git rm --cached <path>")
    print("and add a rule to .gitignore, or record a reason in ALLOW in")
    print("scripts/eos-check-no-caches.py with the condition that would retire it.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
