#!/usr/bin/env python3
"""Every pinned recipe must have been BUILT from the revision it is pinned to.

Runs INSIDE the build tree (recipes/*/source only exists there), after `make`, before an
image is exported.

WHY THIS EXISTS. Measured 2026-09-01, on a real build that shipped:

    recipe.toml                     rev  = 4f230035e2   (new, just bumped)
    recipes/core/bootloader/source  HEAD = 87b214b      (OLD)
    the exported image              carried the OLD bootloader

`git checkout <rev>` inside the recipe source had been REFUSED because a file there was
modified (CLAUDE.md §20.4), so cookbook built the old tree. The build printed `Done.` and
exported the image. Three existing checks all stayed green, each correctly within its own
scope:

  * `pins --strict` compares the repo's files and the fork's remote -- it never looks in
    the build tree;
  * eos-build.sh's freshness guard compares image MTIMES before and after -- and the image
    genuinely was produced by that run, just from the wrong source;
  * eos-source-rules.sh proves a recipe is BUILT rather than downloaded (R-F20) -- it says
    nothing about WHICH revision was built.

Three correct checks, and a gap between them. This closes it.

WHAT IT DOES NOT DO. It does not touch anything. Local modifications under `source/` can be
entirely legitimate -- `recipes/core/bootloader/recipe.toml:24-30` copies the operator's boot
verification key into `src/eos-boot-verify.pub.bin` on every build, so a dirty tree is the
NORMAL state there. Modifications are therefore REPORTED, never removed, and only ever as an
explanation for a revision mismatch: they are the usual reason a checkout was refused.
"""
import os
import re
import subprocess
import sys

ROOT = os.getcwd()
RECIPES = os.path.join(ROOT, "recipes")
REV_RE = re.compile(r'^\s*rev\s*=\s*"([0-9a-fA-F]{7,40})"', re.M)


def git(args, cwd):
    try:
        r = subprocess.run(["git"] + args, cwd=cwd, capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError) as err:
        return None, str(err)
    if r.returncode != 0:
        return None, (r.stderr or r.stdout).strip()
    return r.stdout.strip(), ""


def main():
    if not os.path.isdir(RECIPES):
        print("FAIL (instrument): no recipes/ under %s -- am I in the build tree?" % ROOT,
              file=sys.stderr)
        return 2

    checked = 0
    mismatches = []
    unbuilt = []
    for dirpath, dirnames, filenames in os.walk(RECIPES):
        if "recipe.toml" not in filenames:
            continue
        dirnames[:] = [d for d in dirnames if d not in ("source", "target")]
        try:
            with open(os.path.join(dirpath, "recipe.toml"), encoding="utf-8",
                      errors="replace") as fh:
                text = fh.read()
        except OSError as err:
            print("FAIL (instrument): cannot read %s: %s" % (dirpath, err), file=sys.stderr)
            return 2
        m = REV_RE.search(text)
        if not m:
            continue                      # not pinned to a revision: nothing to check
        want = m.group(1)
        rel = os.path.relpath(dirpath, ROOT)
        src = os.path.join(dirpath, "source")
        if not os.path.isdir(os.path.join(src, ".git")):
            unbuilt.append(rel)           # never fetched in this tree; not a mismatch
            continue
        checked += 1
        head, err = git(["rev-parse", "HEAD"], src)
        if head is None:
            print("FAIL (instrument): git failed in %s/source: %s" % (rel, err), file=sys.stderr)
            return 2
        if not head.startswith(want) and not want.startswith(head):
            dirty, _ = git(["status", "--porcelain"], src)
            # `git status --porcelain` is "XY path"; XY is two status columns, but a
            # renamed entry prints "R  old -> new". Slicing a fixed 3 characters ate the
            # first letter of the path -- measured: `src/...` printed as `rc/...`. Split
            # on whitespace and keep the last field, which is the path in every form.
            files = [ln.split()[-1] for ln in (dirty or "").splitlines() if ln.strip()][:5]
            mismatches.append((rel, want, head, files))

    if not checked:
        print("FAIL (instrument): no fetched recipe sources found -- nothing was measured",
              file=sys.stderr)
        return 2

    if mismatches:
        print("built revision does not match the pinned revision:")
        for rel, want, head, files in mismatches:
            print("  %s" % rel)
            print("      recipe.toml pins : %s" % want)
            print("      source/ HEAD is  : %s" % head)
            if files:
                print("      modified in source/ (a checkout is refused when files are dirty;")
                print("      this is often legitimate -- recipes inject keys here -- so it is")
                print("      reported, not removed): %s" % ", ".join(files))
        print("  The image would carry the revision under source/, not the pinned one.")
        return 1

    extra = " (%d pinned recipes not fetched in this tree)" % len(unbuilt) if unbuilt else ""
    print("ok: %d fetched recipe source(s) match their pinned revision%s" % (checked, extra))
    return 0


if __name__ == "__main__":
    sys.exit(main())
