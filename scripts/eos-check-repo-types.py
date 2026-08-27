#!/usr/bin/env python3
"""Czy CLAUDE.md §11 i repos.toml zgadzają się co do typu każdego repozytorium.

Typ decyduje o regułach (lustro = tylko do odczytu, fork = musi zostać rebaseowalny),
więc dokument niezgodny z manifestem po cichu stosuje złe reguły. Tak zginęła kliencka
weryfikacja podpisu manifestu w U-164: realny kod leżał w repo czytanym jako lustro.

Offline. Sieciową połowę robi scripts/eos-mirror-drift.sh (porównuje deklarację z forkiem).
"""
import re, sys

doc = open("CLAUDE.md", encoding="utf-8").read()
man = open("repos.toml", encoding="utf-8").read()

declared = {}
for b in man.split("[[repo]]")[1:]:
    n = (re.search(r'^\s*name\s*=\s*"([^"]+)"', b, re.M) or [None, ""])[1]
    t = (re.search(r'^\s*type\s*=\s*"([^"]+)"', b, re.M) or [None, ""])[1]
    if not t:
        print(f"  repos.toml: {n or chr(60)+'bez nazwy'+chr(62)} nie ma pola `type`")
        sys.exit(1)
    declared[n] = t

try:
    sec = doc[doc.index("## 11."):doc.index("## 12.")]
except ValueError:
    print("  CLAUDE.md: nie znaleziono sekcji 11 albo 12"); sys.exit(1)

bad = 0
for typ in "ABCD":
    m = re.search(rf"### Typ {typ} .*?\n(.*?)\n\n", sec, re.S)
    listed = set(re.findall(r"`([A-Za-z0-9_-]+)`", m.group(1))) if m else set()
    expect = {n for n, t in declared.items() if t == typ}
    for r in sorted(listed - expect):
        print(f"  typ {typ}: CLAUDE.md wymienia {r}, repos.toml nie"); bad = 1
    for r in sorted(expect - listed):
        print(f"  typ {typ}: repos.toml mówi {r}, CLAUDE.md pomija"); bad = 1
sys.exit(bad)
