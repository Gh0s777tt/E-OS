#!/usr/bin/env python3
"""`config/optional-apps.toml` says the truth about what each optional application owns.

WHY THIS GATE EXISTS.  The installer will DELETE the files this manifest names when a person
declines an application. A manifest that has drifted from its recipe therefore does one of two
harmful things: it leaves a launcher entry pointing at a binary that is gone, or it tries to delete
a path that no longer exists and has to decide whether that is an error. Neither is discoverable by
reading the manifest -- both need the recipe beside it.

FOUR RULES, each able to fail on its own:

  1. Every application in the manifest is a package in BOTH image configs. An optional application
     that ships in one architecture and not the other is a promise the installer cannot keep.
  2. Every application in the manifest has a recipe under `recipes/`.
  3. Every file the manifest claims is actually installed by that recipe -- matched against the
     `${COOKBOOK_STAGE}/...` paths in its build script, plus the binary the crate produces, which
     `cookbook_cargo` installs into `usr/bin` without naming it in the script.
  4. Every file the recipe installs into a shared directory is claimed by the manifest. This is the
     direction that matters most: a recipe that starts shipping a second launcher entry, with the
     manifest unaware, leaves that entry behind after a removal.
  5. The copy embedded in each image config -- the one the installer will actually read, at
     `/usr/share/eos/optional-apps.toml` -- is byte-for-byte this file. Two copies of a rule is one
     copy that goes stale, and this pair is worse than most: the gate would be checking the
     repository's copy while the installer acted on the image's.

Exit codes: 0 clean, 1 the manifest and a recipe disagree, 2 the gate could not run.

    scripts/eos-check-optional-apps.py [--selftest]
"""

import io
import os
import re
import sys

try:
    import tomllib
except ImportError:  # pragma: no cover - python < 3.11
    tomllib = None

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "config", "optional-apps.toml")
CONFIGS = [os.path.join(ROOT, "config", a, "eos.toml") for a in ("aarch64", "x86_64")]
STAGE_RE = re.compile(r"\$\{COOKBOOK_STAGE\}(/[A-Za-z0-9/_.-]+)")


def recipe_path(app):
    for root, dirs, files in os.walk(os.path.join(ROOT, "recipes")):
        if os.path.basename(root) == app and "recipe.toml" in files:
            return os.path.join(root, "recipe.toml")
    return None


def recipe_files(text, app):
    """Files a recipe installs: the staged paths it names, plus the binary cargo installs."""
    out = set()
    for p in STAGE_RE.findall(text):
        # Directories are created, not installed; only leaf files are removable artefacts.
        if "." in os.path.basename(p) or re.search(r"/\d\d_", p):
            out.add(p)
    if "cookbook_cargo" in text:
        out.add("/usr/bin/" + app)
    return out


def embedded_manifest(config_text):
    """The `data` of the [[files]] entry that ships the manifest, or None."""
    m = re.search(r'path = "/usr/share/eos/optional-apps\.toml"\s*\ndata = """\n(.*?)"""',
                  config_text, re.S)
    return m.group(1) if m else None


def check(manifest, configs, recipes, source_text=None):
    """manifest: dict. configs: {name: text}. recipes: {app: text or None}."""
    problems = []
    if not manifest:
        return None, "config/optional-apps.toml declares no applications"

    for app, entry in sorted(manifest.items()):
        for name, text in configs.items():
            if "[packages.%s]" % app not in text:
                problems.append("rule 1: %s is offered as optional but is not a package in %s"
                                % (app, name))
        text = recipes.get(app)
        if text is None:
            problems.append("rule 2: %s has no recipe under recipes/" % app)
            continue
        claimed = set(entry.get("files", []))
        actual = recipe_files(text, app)
        for f in sorted(claimed - actual):
            problems.append("rule 3: %s claims %s, which its recipe does not install" % (app, f))
        for f in sorted(actual - claimed):
            problems.append("rule 4: %s installs %s, which the manifest does not claim -- a "
                            "removal would leave it behind" % (app, f))

    if source_text is not None:
        for name, text in configs.items():
            embedded = embedded_manifest(text)
            if embedded is None:
                problems.append("rule 5: %s ships no /usr/share/eos/optional-apps.toml, so the "
                                "installer would have nothing to read" % name)
            elif embedded != source_text:
                problems.append("rule 5: the manifest embedded in %s differs from "
                                "config/optional-apps.toml -- edit the file, not the block" % name)
    return problems, None


def selftest():
    cfg = {"aarch64": "[packages.demo]\n", "x86_64": "[packages.demo]\n"}
    recipe = 'script = """\ncookbook_cargo\ncp x "${COOKBOOK_STAGE}/usr/share/ui/apps/30_demo"\n"""'
    good = {"demo": {"files": ["/usr/bin/demo", "/usr/share/ui/apps/30_demo"]}}
    cases = [
        ("a manifest that matches its recipe", good, cfg, {"demo": recipe}, None),
        ("an app missing from one config", good,
         {"aarch64": "[packages.demo]\n", "x86_64": ""}, {"demo": recipe}, "rule 1"),
        ("an app with no recipe", good, cfg, {"demo": None}, "rule 2"),
        ("a claimed file the recipe never installs",
         {"demo": {"files": ["/usr/bin/demo", "/usr/share/ui/apps/30_demo", "/usr/share/ghost.png"]}},
         cfg, {"demo": recipe}, "rule 3"),
        ("a recipe file the manifest forgot",
         {"demo": {"files": ["/usr/bin/demo"]}}, cfg, {"demo": recipe}, "rule 4"),
        ("an empty manifest is an instrument fault", {}, cfg, {}, "INSTRUMENT"),
    ]
    # Rule 5 needs the source text, so it gets its own pair rather than a sixth column above.
    embed = 'path = "/usr/share/eos/optional-apps.toml"\ndata = """\nSRC"""'
    r5 = [
        ("the embedded copy matches the file", "SRC", {"aarch64": embed}, None),
        ("the embedded copy has drifted", "OTHER", {"aarch64": embed}, "rule 5"),
        ("no embedded copy at all", "SRC", {"aarch64": "[packages.demo]\n"}, "rule 5"),
    ]
    fails = 0
    for name, man, c, r, want in cases:
        problems, instrument = check(man, c, r)
        if want == "INSTRUMENT":
            ok = instrument is not None
            got = instrument or "no instrument fault"
        elif want is None:
            ok = not problems and not instrument
            got = "clean" if ok else (instrument or problems[0])
        else:
            ok = bool(problems) and problems[0].startswith(want)
            got = problems[0] if problems else "accepted -- the gate did NOT fail"
        print("  selftest %-42s %s  (%s)" % (name, "ok" if ok else "FAIL", got[:78]))
        if not ok:
            fails += 1
    for name, src, c, want in r5:
        problems, _ = check(good, c, {"demo": recipe}, src)
        r5p = [p for p in problems if p.startswith("rule 5")]
        if want is None:
            ok = not r5p; got = "clean" if ok else r5p[0]
        else:
            ok = bool(r5p); got = r5p[0] if r5p else "accepted -- the gate did NOT fail"
        print("  selftest %-42s %s  (%s)" % (name, "ok" if ok else "FAIL", got[:78]))
        if not ok:
            fails += 1
    total = len(cases) + len(r5)
    if fails:
        print("optional-apps selftest: %d of %d cases wrong" % (fails, total))
        return 1
    print("optional-apps selftest: %d cases, every rule refuses what it should" % total)
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    if tomllib is None:
        print("optional-apps: FAIL (instrument): python3 has no tomllib (needs 3.11+)")
        return 2
    if not os.path.isfile(MANIFEST):
        print("optional-apps: FAIL (instrument): %s is missing" % MANIFEST)
        return 2
    configs = {}
    for p in CONFIGS:
        if not os.path.isfile(p):
            print("optional-apps: FAIL (instrument): %s is missing" % p)
            return 2
        configs[os.path.relpath(p, ROOT)] = io.open(p, encoding="utf-8").read()
    manifest = tomllib.load(io.open(MANIFEST, "rb"))
    recipes = {}
    for app in manifest:
        p = recipe_path(app)
        recipes[app] = io.open(p, encoding="utf-8").read() if p else None
    source_text = io.open(MANIFEST, encoding="utf-8").read()
    problems, instrument = check(manifest, configs, recipes, source_text)
    if instrument:
        print("optional-apps: FAIL (instrument): %s" % instrument)
        return 2
    if problems:
        for p in problems:
            print("optional-apps: %s" % p)
        print("optional-apps: FAIL -- %d disagreement(s) between the manifest and the recipes"
              % len(problems))
        return 1
    n = sum(len(v.get("files", [])) for v in manifest.values())
    print("optional-apps: %d applications, %d files; every claimed file installed by its recipe, "
          "every installed file claimed, and both image configs ship this exact manifest"
          % (len(manifest), n))
    return 0


if __name__ == "__main__":
    sys.exit(main())
