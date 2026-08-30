#!/usr/bin/env python3
"""Every recipe reachable from an image config must pin the blake3 of its tarball.

WHY. src/cook/fetch.rs warns and continues when a `tar` source carries no `blake3`, and
src/config.rs installs a default mirror rewrite sending every ftp.gnu.org URL to a third-party
mirror. Together that means an unpinned tarball is fetched from a host the project has no
relationship with and built without an integrity check. Measured 2026-08-30: exactly one recipe in
the image closure was in that state -- `mpc`, a dependency of gcc13, the cross-compiler that
produces every E-OS binary.

SCOPE. Only the closure reachable from config/*/eos.toml. Recipes outside it are reported as
advisory, because an unpinned recipe nobody builds is untidy, not dangerous.
"""
import os
import re
import sys

try:
    import tomllib  # Python 3.11+
except ImportError:  # 3.9 / 3.10
    import tomli as tomllib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RECIPES = os.path.join(ROOT, "recipes")


def config_closure():
    """Package names declared across the include chain of every config/*/eos.toml."""
    names, seen = set(), set()

    def load(path):
        if path in seen or not os.path.exists(path):
            return
        seen.add(path)
        with open(path, "rb") as fh:
            data = tomllib.load(fh)
        for name, spec in (data.get("packages") or {}).items():
            if spec != "ignore":
                names.add(name)
        for inc in data.get("include") or []:
            load(os.path.normpath(os.path.join(os.path.dirname(path), inc)))

    for arch in ("x86_64", "aarch64"):
        load(os.path.join(ROOT, "config", arch, "eos.toml"))

    # The toolchain is NOT reachable from the image configs, and it is exactly where the defect this
    # gate exists for was found: mpc is a dependency of gcc13, which mk/prefix.mk cooks directly.
    # Seed those roots explicitly, parsed from the makefile so the list cannot rot silently.
    prefix = os.path.join(ROOT, "mk", "prefix.mk")
    if os.path.exists(prefix):
        text = open(prefix, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"\$\(REPO_BIN\)\s+cook\s+([^\n]+)", text):
            for token in m.group(1).split():
                if token.startswith("$") or token.startswith("-"):
                    continue
                names.add(token.split(":", 1)[-1])
    return names


def recipe_index():
    """name -> (path, parsed recipe)."""
    out = {}
    for base, dirs, files in os.walk(RECIPES):
        if "wip" in base.split(os.sep) or "recipe.toml" not in files:
            continue
        path = os.path.join(base, "recipe.toml")
        try:
            with open(path, "rb") as fh:
                out[os.path.basename(base)] = (path, tomllib.load(fh))
        except Exception:
            continue
    return out


def main():
    index = recipe_index()
    frontier, closure = list(config_closure()), set()
    while frontier:
        name = frontier.pop()
        if name in closure or name not in index:
            continue
        closure.add(name)
        _, recipe = index[name]
        # Dependencies live in three places depending on the recipe's shape. gcc13 declares them
        # under [build], which the first version of this walker missed entirely — which is how the
        # gate managed to pass while the very recipe it was written for stayed unpinned.
        for section in (recipe, recipe.get("package") or {}, recipe.get("build") or {}):
            if not isinstance(section, dict):
                continue
            for key in ("dependencies", "build_dependencies"):
                value = section.get(key)
                if isinstance(value, list):
                    frontier.extend(v.split(":", 1)[-1] for v in value if isinstance(v, str))

    unpinned_in, unpinned_out = [], []
    for name, (path, recipe) in sorted(index.items()):
        src = recipe.get("source") or {}
        has_tar = bool(src.get("tar") or recipe.get("tar"))
        has_b3 = bool(src.get("blake3") or recipe.get("blake3"))
        if has_tar and not has_b3:
            rel = os.path.relpath(path, ROOT)
            (unpinned_in if name in closure else unpinned_out).append((name, rel))

    for name, rel in unpinned_out:
        print(f"  advisory: {name} has a tar source with no blake3 ({rel}) — not in the image closure")

    if unpinned_in:
        print(f"BAD: {len(unpinned_in)} recipe(s) in the image closure fetch a tarball with no blake3:")
        for name, rel in unpinned_in:
            print(f"  {name}  ({rel})")
        print("  Fetch the tarball from its canonical host, verify it against the upstream")
        print("  checksum, compute blake3, and add it to the recipe.")
        return 1

    print(f"  ok: every recipe in the image closure pins its tarball ({len(closure)} recipes walked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
