#!/usr/bin/env python3
"""Czy któryś przepis linkuje forkowany przez E-OS crate Z CRATES.IO zamiast z forka.

PO CO. To najdroższa powtarzalna wada w tym projekcie — trzy wystąpienia:
  * R-F10 — bootloader rozwiązywał `redoxfs` z crates.io; poprawki forka do niego nie
    docierały, a `[patch.crates-io]` nie przechodziło przez granicę 0.8 → 0.9.
  * R-F20 — przepisy z forkiem E-OS pobierane jako gotowe binarki upstreamu; kliencka
    weryfikacja podpisu manifestu (R-703) nie trafiła do obrazu mimo poprawnego forka.
  * R-F19 — `redox_installer` linkował `redoxfs = "0.9.1"` z crates.io, więc mount
    WEWNĄTRZ jego procesu omijał forka całkowicie; obie kopie miały ten sam numer wersji,
    co czyniło rozbieżność niewidoczną.
Wspólny wzorzec: fork jest poprawny, przypięcie jest poprawne, a **artefakt i tak zawiera
cudzy kod**. Żadna z istniejących bramek tego nie widzi, bo wszystkie patrzą na przepisy
i przypięcia, a nie na to, co cargo faktycznie rozwiązało.

CZEGO NIE ZGADUJE. Nazwy crate'ów bierze z `[package] name` w źródle forka, a nie z nazwy
repozytorium — `eos-base` nie dostarcza crate'a „base", a `eos-pkgutils` dostarcza kilku.

    scripts/eos-fork-linkage.py [/work/redox]

Wymaga rozpakowanych źródeł przepisów, więc miejsce dla niego jest w kontenerze budującym
(zadanie heavy), nie w lekkim CI — `recipes/*/*/source/` nie jest śledzone w gicie.
"""
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/work/redox")
recipes = root / "recipes"
if not recipes.is_dir():
    print(f"eos-fork-linkage: brak {recipes} — uruchom w drzewie budowania")
    sys.exit(2)

# 1. Ktore crate'y dostarczaja forki E-OS. Wprost z drzewa, bez zgadywania z nazwy repo.
provided = {}          # crate -> sciezka przepisu
for rt in recipes.glob("*/*/recipe.toml"):
    if "Gh0s777tt/eos-" not in rt.read_text(encoding="utf-8", errors="replace"):
        continue
    src = rt.parent / "source"
    root_toml = src / "Cargo.toml"
    if not root_toml.is_file():
        continue
    # Tylko crate'y, ktore fork FAKTYCZNIE dostarcza: pakiet w korzeniu plus
    # czlonkowie workspace'u. Rekurencyjne szukanie Cargo.toml wciaga vendorowane
    # zaleznosci i produkuje bzdury w rodzaju "redoxfs dostarcza cpufeatures".
    candidates = [root_toml]
    txt = root_toml.read_text(encoding="utf-8", errors="replace")
    wm = re.search(r'^\s*\[workspace\]\s*$(.*?)(^\s*\[[a-z]|\Z)', txt, re.S | re.M)
    if wm:
        for member in re.findall(r'"([^"*]+)"', (re.search(r'members\s*=\s*\[(.*?)\]',
                                                          wm.group(1), re.S) or [None, ""])[1]):
            mt = src / member / "Cargo.toml"
            if mt.is_file():
                candidates.append(mt)
    for ct in candidates:
        m = re.search(r'^\s*\[package\]\s*$(.*?)(^\s*\[|\Z)',
                      ct.read_text(encoding="utf-8", errors="replace"), re.S | re.M)
        if not m:
            continue
        n = re.search(r'^\s*name\s*=\s*"([^"]+)"', m.group(1), re.M)
        if n:
            provided.setdefault(n.group(1), rt.parent.name)

if not provided:
    print("eos-fork-linkage: nie znaleziono zadnego forka E-OS — to samo w sobie jest podejrzane")
    sys.exit(1)

# 2. Ktory przepis rozwiazuje ktorys z nich z rejestru.
bad = []
for lock in recipes.glob("*/*/source/Cargo.lock"):
    consumer = lock.parent.parent.name
    for blk in lock.read_text(encoding="utf-8", errors="replace").split("[[package]]")[1:]:
        n = re.search(r'^\s*name\s*=\s*"([^"]+)"', blk, re.M)
        s = re.search(r'^\s*source\s*=\s*"(registry\+[^"]+)"', blk, re.M)
        v = re.search(r'^\s*version\s*=\s*"([^"]+)"', blk, re.M)
        if n and s and n.group(1) in provided and consumer != provided[n.group(1)]:
            bad.append((consumer, n.group(1), v.group(1) if v else "?", provided[n.group(1)]))

print(f"crate'ow dostarczanych przez forki E-OS: {len(provided)}")
if not bad:
    print("Zaden przepis nie linkuje forkowanego crate'a z crates.io.")
    sys.exit(0)

print(f"\nZNALEZIONO {len(bad)} — przepis linkuje crate'a Z CRATES.IO, mimo ze E-OS ma jego fork:\n")
for consumer, crate, ver, owner in sorted(set(bad)):
    print(f"  {consumer:<18} -> {crate} {ver}  (fork w recipes/.../{owner})")
print("""
To NIE jest kosmetyka. Fork moze byc poprawny i przypiety, a artefakt i tak niesie cudzy
kod — ten sam numer wersji po obu stronach sprawia, ze roznica jest niewidoczna.
Napraw przez `[patch.crates-io]` w Cargo.toml konsumenta, wskazujac git+rev forka,
a potem odswiez Cargo.lock MINIMALNIE (`cargo update -p <crate>`), nie `generate-lockfile`.""")
sys.exit(1)
