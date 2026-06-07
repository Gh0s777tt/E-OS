#!/usr/bin/env python3
"""Generate a CycloneDX 1.5 SBOM for an E-OS image from cooked package metadata.

Reads the per-package metadata the cookbook writes to repo/<target>/*.toml
(name, version, blake3, source_identifier) and emits a CycloneDX JSON BOM.
Deterministic: pass --timestamp (e.g. the E-OS HEAD commit date) so the same
tree always yields the same SBOM.
"""
import sys, os, json, glob, argparse


def parse_meta(path):
    d = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            k, v = k.strip(), v.strip()
            if len(v) >= 2 and v[0] == '"' and v[-1] == '"':
                v = v[1:-1]
            d[k] = v
    return d


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo-dir", required=True, help="repo/<target> dir with *.toml")
    ap.add_argument("--target", required=True)
    ap.add_argument("--eos-version", default="0.1.0")
    ap.add_argument("--eos-commit", default="")
    ap.add_argument("--timestamp", required=True, help="ISO-8601, e.g. E-OS HEAD commit date")
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    components = []
    for path in sorted(glob.glob(os.path.join(a.repo_dir, "*.toml"))):
        m = parse_meta(path)
        name = m.get("name")
        if not name:
            continue
        ver = m.get("version", "unknown")
        comp = {
            "type": "library",
            "name": name,
            "version": ver,
            "bom-ref": f"{name}@{ver}",
            "properties": [{"name": "redox:target", "value": m.get("target", a.target)}],
        }
        if m.get("blake3"):
            comp["hashes"] = [{"alg": "BLAKE3", "content": m["blake3"]}]
        if m.get("source_identifier"):
            comp["properties"].append(
                {"name": "redox:source_git_ref", "value": m["source_identifier"]}
            )
        components.append(comp)

    bom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "version": 1,
        "metadata": {
            "timestamp": a.timestamp,
            "tools": [{"vendor": "E-OS", "name": "gen-sbom.py"}],
            "component": {
                "type": "operating-system",
                "bom-ref": f"e-os@{a.eos_version}",
                "name": "E-OS",
                "version": a.eos_version,
                "description": f"E-OS {a.eos_version} ({a.target}) - a downstream of Redox OS",
                "properties": (
                    [{"name": "eos:commit", "value": a.eos_commit}] if a.eos_commit else []
                ),
            },
        },
        "components": components,
    }
    with open(a.out, "w", encoding="utf-8") as f:
        json.dump(bom, f, indent=2)
        f.write("\n")
    print(f"wrote {a.out}: {len(components)} components ({a.target})")


if __name__ == "__main__":
    main()
