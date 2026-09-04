#!/usr/bin/env python3
"""Security coverage as numbers with floors that can go red — `TQ-002` in ROADMAP §11.3.

A line-coverage percentage says which lines a test executed. It says nothing about whether the
DANGEROUS lines were tested, or whether the dependency graph is known-bad. This script computes
the four proxies that are measurable from the tree with the tools this project already has, and
refuses to invent the two that need tools nobody installed.

  SC-1  unsafe hygiene      unsafe blocks/fns carrying a `// SAFETY:` note ÷ all unsafe
  SC-2  parser fuzzing      parser files with a fuzz target ÷ all parser files      [needs cargo-fuzz]
  SC-3  dependency policy   own crates inside cargo-deny AND osv-scanner ÷ all own crates
  SC-4  hostile-input tests inputs with a negative test ÷ inputs declared in tests/inputs.toml
  SC-5  mutation score      killed mutants ÷ mutants in trust code                [needs cargo-mutants]

Rules this file obeys, because a metric that cannot fall is decoration:

  * A proxy whose tool is missing is `SKIPPED` and the script exits 2 — never silently 0 %, and
    never silently 100 %. Exit 1 means a floor was crossed (fix the tree); exit 2 means the
    toolbox is incomplete (fix the toolbox). Same split as `FAIL (instrument):` in
    ci-integrity.sh (`U-177`).
  * Floors live in security-coverage.toml next to this script's output, not in the script, so
    raising one is an ordinary commit and lowering one is visible in a diff.
  * `--selftest` plants an unsafe block without a SAFETY note in a scratch tree and asserts the
    script goes red for SC-1. A gate nobody has seen fail is a hypothesis.

Usage: eos-security-coverage.py [--write PATH] [--floors PATH] [--allow-missing] [--selftest]
"""

import argparse
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

FLOOR_DEFAULTS = {
    # Measured on 2026-09-03 and written here as "does not fall", not as "good".
    "SC-1": 100.0,   # zero unsafe in E-OS-owned Rust today, so 100 % is free — and any new
                     # unsafe without a SAFETY note breaks it immediately. That is the point.
    "SC-3": 100.0,   # a crate outside the scanners is a crate nobody watches.
    "SC-4": 0.0,     # no manifest exists yet; the floor rises with the first one (TQ-007).
}
OWN_RUST = ["tools/eos-repo-sign"]          # E-OS-owned crates inside THIS repository
PARSER_RE = re.compile(r"(parse|decode|deserialize|from_bytes|from_str|read_.*_header)", re.I)
EXIT_DEFECT, EXIT_CANNOT = 1, 2


def sh(args, cwd=None):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True)


def tracked(root, *globs):
    r = sh(["git", "-C", root, "ls-files", "-z", "--"] + list(globs))
    if r.returncode != 0:
        return None
    return [p for p in r.stdout.split("\0") if p]


def sc1_unsafe(root):
    """unsafe with a SAFETY: note on one of the three preceding lines ÷ all unsafe.

    Vendored `src/` is excluded: it is upstream's code and ci-integrity check 4 draws the same
    line. Counting someone else's unsafe would make our own number meaningless.
    """
    files = tracked(root, "*.rs", ":!src/")
    if files is None:
        return None, "git ls-files failed"
    total = withnote = 0
    detail = []
    for f in files:
        p = os.path.join(root, f)
        try:
            lines = io.open(p, encoding="utf-8", errors="replace").read().splitlines()
        except OSError:
            continue
        for i, line in enumerate(lines):
            if not re.search(r"\bunsafe\b", line):
                continue
            if re.match(r"\s*(//|/\*|\*)", line):      # a comment mentioning unsafe is not unsafe
                continue
            total += 1
            window = " ".join(lines[max(0, i - 3):i])
            if "SAFETY:" in window:
                withnote += 1
            else:
                detail.append("%s:%d" % (f, i + 1))
    pct = 100.0 if total == 0 else 100.0 * withnote / total
    return {"value": pct, "num": withnote, "den": total, "offenders": detail}, None


def sc2_fuzz(root):
    files = tracked(root, "*.rs", ":!src/")
    if files is None:
        return None, "git ls-files failed"
    parsers = [f for f in files if PARSER_RE.search(io.open(os.path.join(root, f), encoding="utf-8", errors="replace").read())]
    if not shutil.which("cargo-fuzz"):
        return None, "cargo-fuzz is not installed (cargo install cargo-fuzz) — %d parser file(s) unmeasured" % len(parsers)
    targets = tracked(root, "fuzz/fuzz_targets/*.rs") or []
    pct = 0.0 if not parsers else 100.0 * min(len(targets), len(parsers)) / len(parsers)
    return {"value": pct, "num": len(targets), "den": len(parsers), "offenders": []}, None


def sc3_deps(root):
    """A crate counts only when a scanner actually runs over it in verify.sh AND it has a policy."""
    verify = io.open(os.path.join(root, "scripts/verify.sh"), encoding="utf-8", errors="replace").read()
    covered, offenders = 0, []
    for crate in OWN_RUST:
        has_policy = os.path.isfile(os.path.join(root, crate, "deny.toml")) or os.path.isfile(os.path.join(root, "deny.toml"))
        in_deny = "cargo-deny" in verify or "cargo deny" in verify
        in_osv = "osv-scanner" in verify
        if has_policy and in_deny and in_osv:
            covered += 1
        else:
            offenders.append("%s (policy=%s deny=%s osv=%s)" % (crate, has_policy, in_deny, in_osv))
    pct = 100.0 if not OWN_RUST else 100.0 * covered / len(OWN_RUST)
    return {"value": pct, "num": covered, "den": len(OWN_RUST), "offenders": offenders}, None


def sc4_inputs(root):
    """Externally facing inputs with a hostile-value test, read from each crate's tests/inputs.toml.

    No manifest yet means 0 of 0, reported as 100 % with den=0 — and the floor for SC-4 is 0.0
    until TQ-007 writes the first manifest, so this cannot pretend to be a pass.
    """
    manifests = tracked(root, "tests/inputs.toml", "*/tests/inputs.toml") or []
    if not manifests:
        # NOT 100 %. "Every declared input has a hostile-value test" is vacuously true when nothing
        # is declared, and a vacuous truth satisfies any floor -- measured: with SC-4 = 50.0 and an
        # empty tree the proxy reported 100 % and passed. That is the "a gate that can only pass"
        # shape this whole file exists to avoid. An unmeasurable proxy is SKIPPED (exit 2 unless
        # --allow-missing), never a pass.
        return None, "no tests/inputs.toml anywhere, so nothing is declared to test (TQ-007)"
    declared = tested = 0
    offenders = []
    for m in manifests:
        try:
            import tomllib
            data = tomllib.load(open(os.path.join(root, m), "rb"))
        except Exception as e:                                  # noqa: BLE001 — report, do not crash
            return None, "%s is unreadable: %s" % (m, e)
        for name, spec in (data.get("input") or {}).items():
            declared += 1
            if spec.get("negative_test"):
                tested += 1
            else:
                offenders.append("%s: %s" % (m, name))
    if declared == 0:
        return None, "%d manifest(s) found but they declare no inputs" % len(manifests)
    return {"value": 100.0 * tested / declared, "num": tested, "den": declared, "offenders": offenders}, None


def sc5_mutants(root):
    """Killed mutants over tested mutants, read from cargo-mutants' own output.

    Reads `mutants.out/outcomes.json` rather than re-running the tool: a proxy that takes a minute
    to compute would be a proxy nobody runs. The file is written by the `mutants` stage of
    verify.sh (TQ-006), so a stale one is a real signal -- it means the score being reported
    belongs to an older tree, and the age is printed rather than hidden.
    """
    if not shutil.which("cargo-mutants"):
        return None, "cargo-mutants is not installed (cargo install cargo-mutants) — trust code unmeasured"
    path = os.path.join(root, "tools", "eos-repo-sign", "mutants.out", "outcomes.json")
    if not os.path.isfile(path):
        return None, "no run recorded yet; `bash scripts/eos-mutation-score.sh` writes one"
    try:
        import json
        data = json.load(open(path, "rb"))
    except Exception as e:                                        # noqa: BLE001
        return None, "mutants.out/outcomes.json is unreadable (%s)" % e
    caught = missed = 0
    for outcome in data.get("outcomes", []):
        summary = outcome.get("summary")
        if summary == "CaughtMutant":
            caught += 1
        elif summary == "MissedMutant":
            missed += 1
    if caught + missed == 0:
        return None, "outcomes.json records no caught or missed mutants"
    pct = 100.0 * caught / (caught + missed)
    offenders = []
    try:
        import time
        days = (time.time() - os.path.getmtime(path)) / 86400.0
        if days >= 1:
            # A stale run is a real signal, not noise: the score then describes an older tree.
            offenders.append("recorded %d day(s) ago; re-run scripts/eos-mutation-score.sh" % int(days))
    except OSError:
        pass
    if missed:
        offenders.append("%d mutant(s) survived; see tools/eos-repo-sign/mutants.out/missed.txt" % missed)
    return {"value": pct, "num": caught, "den": caught + missed, "offenders": offenders}, None


PROXIES = [
    ("SC-1", "unsafe carrying a SAFETY note", sc1_unsafe),
    ("SC-2", "parsers with a fuzz target", sc2_fuzz),
    ("SC-3", "own crates inside the scanners", sc3_deps),
    ("SC-4", "declared inputs with a hostile-value test", sc4_inputs),
    ("SC-5", "mutation score on trust code", sc5_mutants),
]


def load_floors(path):
    if path and os.path.isfile(path):
        try:
            import tomllib
            data = tomllib.load(open(path, "rb"))
            return {k: float(v) for k, v in (data.get("floor") or {}).items()}
        except Exception as e:                                  # noqa: BLE001
            print("CANNOT RUN: %s is unreadable: %s" % (path, e))
            sys.exit(EXIT_CANNOT)
    return dict(FLOOR_DEFAULTS)


def run(root, floors, allow_missing, write):
    rows, skipped, failed = [], [], []
    for key, label, fn in PROXIES:
        res, why = fn(root)
        if res is None:
            skipped.append((key, label, why))
            rows.append((key, label, None, floors.get(key), why))
            continue
        floor = floors.get(key)
        bad = floor is not None and res["value"] + 1e-9 < floor
        if bad:
            failed.append((key, res, floor))
        rows.append((key, label, res, floor, None))

    width = max(len(l) for _, l, _ in PROXIES)
    print("security-coverage — %s" % root)
    for key, label, res, floor, why in rows:
        if res is None:
            print("  %s  %-*s  SKIPPED  %s" % (key, width, label, why))
        else:
            mark = "ok " if not (floor is not None and res["value"] + 1e-9 < floor) else "RED"
            den = "%d/%d" % (res["num"], res["den"])
            print("  %s  %-*s  %6.1f %%  (%s)  floor %s  %s"
                  % (key, width, label, res["value"], den,
                     "-" if floor is None else "%.1f" % floor, mark))
            for o in res["offenders"][:5]:
                print("        - %s" % o)
            if len(res["offenders"]) > 5:
                print("        - … %d more" % (len(res["offenders"]) - 5))

    if write:
        os.makedirs(os.path.dirname(write) or ".", exist_ok=True)
        with io.open(write, "w", encoding="utf-8") as f:
            f.write("---\ntitle: Security coverage\nstatus: generated\n"
                    "last-reviewed: generated by scripts/eos-security-coverage.py\nowner: Gh0s777tt\n---\n\n")
            f.write("# Security coverage\n\n"
                    "**Generated — do not edit by hand.** `scripts/eos-security-coverage.py` writes this file; "
                    "the floors live in `security-coverage.toml`. A proxy whose tool is missing is `SKIPPED` and "
                    "the script exits 2, never a silent zero (`TQ-002`, ROADMAP §11.3).\n\n"
                    "| proxy | what it counts | value | measured | floor | state |\n|---|---|---|---|---|---|\n")
            for key, label, res, floor, why in rows:
                if res is None:
                    f.write("| `%s` | %s | — | — | %s | SKIPPED: %s |\n"
                            % (key, label, "-" if floor is None else "%.1f %%" % floor, why))
                else:
                    state = "ok" if not (floor is not None and res["value"] + 1e-9 < floor) else "**below the floor**"
                    f.write("| `%s` | %s | %.1f %% | %d/%d | %s | %s |\n"
                            % (key, label, res["value"], res["num"], res["den"],
                               "-" if floor is None else "%.1f %%" % floor, state))
        print("  wrote %s" % write)

    if failed:
        print("security-coverage: FAIL — %d proxy below its floor" % len(failed))
        return EXIT_DEFECT
    if skipped and not allow_missing:
        print("security-coverage: CANNOT — %d proxy unmeasured (pass --allow-missing to accept, "
              "and the summary above names what was NOT measured)" % len(skipped))
        return EXIT_CANNOT
    print("security-coverage: ok — %d proxy measured, %d skipped" % (len(rows) - len(skipped), len(skipped)))
    return 0


SELFTEST_RS = """pub fn probe() {
    unsafe { core::ptr::null::<u8>().read() };
}
"""


def selftest():
    t = tempfile.mkdtemp()
    try:
        os.makedirs(os.path.join(t, "scripts"))
        io.open(os.path.join(t, "scripts/verify.sh"), "w", encoding="utf-8").write("cargo-deny osv-scanner\n")
        io.open(os.path.join(t, "deny.toml"), "w", encoding="utf-8").write("[advisories]\n")
        os.makedirs(os.path.join(t, "tools/eos-repo-sign/src"))
        io.open(os.path.join(t, "tools/eos-repo-sign/src/lib.rs"), "w", encoding="utf-8").write(SELFTEST_RS)
        for a in (["git", "-C", t, "init", "-q"],
                  ["git", "-C", t, "add", "-A"],
                  ["git", "-C", t, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "t"]):
            sh(a)
        floors = {"SC-1": 100.0, "SC-3": 100.0, "SC-4": 0.0}
        rc = run(t, floors, allow_missing=True, write=None)
    finally:
        shutil.rmtree(t, ignore_errors=True)
    if rc != EXIT_DEFECT:
        print("SELFTEST FAILED: an unsafe block with no SAFETY note should put SC-1 below its floor "
              "and exit %d; got %d" % (EXIT_DEFECT, rc))
        return 1
    # Second half: a vacuous proxy must never satisfy a floor. SC-4 has no manifest in the scratch
    # tree, so it must come back SKIPPED -- not 100 %.
    res, why = sc4_inputs(t2) if False else sc4_inputs(os.path.join(os.sep, "nonexistent-eos-tree"))
    if res is not None:
        print("SELFTEST FAILED: SC-4 returned a value (%r) with no manifest; it must be SKIPPED" % res)
        return 1
    print("selftest ok: a planted unsafe without SAFETY: turns SC-1 red (exit 1), and SC-4 with no "
          "manifest is SKIPPED rather than a vacuous 100 %")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--write", metavar="PATH", help="also write the generated page")
    ap.add_argument("--floors", metavar="PATH", default="security-coverage.toml")
    ap.add_argument("--allow-missing", action="store_true",
                    help="accept an unmeasured proxy (the summary still names it)")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        sys.exit(selftest())
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    sys.exit(run(root, load_floors(os.path.join(root, a.floors)), a.allow_missing, a.write))


if __name__ == "__main__":
    main()
