#!/usr/bin/env python3
"""Czy CLAUDE.md §11 i repos.toml zgadzają się co do typu każdego repozytorium.

Typ decyduje o regułach (lustro = tylko do odczytu, fork = musi zostać rebaseowalny),
więc dokument niezgodny z manifestem po cichu stosuje złe reguły. Tak zginęła kliencka
weryfikacja podpisu manifestu w U-164: realny kod leżał w repo czytanym jako lustro.

Offline. Sieciową połowę robi scripts/eos-mirror-drift.sh (porównuje deklarację z forkiem).

KONTRAKT WYJŚCIA — czyta go kontrola 7 w scripts/ci-integrity.sh (U-177):

    0   `repo-types: OK — ...`              porównanie WYKONANE, typy zgodne
    1   `repo-types: MISMATCH — ...`        porównanie WYKONANE, jest rozjazd (wypisany wyżej)
    2   `repo-types: CANNOT-MEASURE — ...`  do porównania NIE DOSZŁO: brak/nieczytelny plik,
                                            brak sekcji, manifest bez pola `type`

Kod 2 mówi o NARZĘDZIU, nie o niezmienniku — nie orzeka, czy typy się zgadzają. Do
rozróżnienia nie wystarcza sam kod wyjścia i nigdy nie wystarczał: interpreter, który nie
jest pythonem 3, przewraca się na f-stringu z SyntaxError i kodem **1**, czyli dokładnie
tak, jak prawdziwy rozjazd. Dlatego werdykt jest również LINIĄ na stdout — wypisuje ją samo
porównanie, więc przebieg, który do porównania nie doszedł, nie umie jej podrobić (§4.2).
"""
import re, sys

OK, MISMATCH, CANNOT_MEASURE = 0, 1, 2


def cannot_measure(why):
    """Kod 2: nic nie zostało zmierzone, więc nie wolno orzekać o typach."""
    print(f"repo-types: CANNOT-MEASURE — {why}")
    sys.exit(CANNOT_MEASURE)


def read(path):
    try:
        return open(path, encoding="utf-8").read()
    except OSError as e:
        cannot_measure(f"nie mogę odczytać {path}: {e}")


doc = read("CLAUDE.md")
man = read("repos.toml")

declared = {}
for b in man.split("[[repo]]")[1:]:
    n = (re.search(r'^\s*name\s*=\s*"([^"]+)"', b, re.M) or [None, ""])[1]
    t = (re.search(r'^\s*type\s*=\s*"([^"]+)"', b, re.M) or [None, ""])[1]
    if not t:
        cannot_measure(f"repos.toml: {n or chr(60)+'bez nazwy'+chr(62)} nie ma pola `type` — nie ma czego porównać")
    declared[n] = t

if not declared:
    cannot_measure("repos.toml: ani jednego bloku [[repo]] — to nie jest manifest, który chcę porównać")

try:
    sec = doc[doc.index("## 11."):doc.index("## 12.")]
except ValueError:
    cannot_measure("CLAUDE.md: nie znaleziono sekcji 11 albo 12")

bad = 0
# A repository declared with any other `type` used to fall into no `expect` set at all: it was
# never compared with anything, so it could not produce a mismatch -- while still counting as
# checked. Name the unknown types first; a value this gate does not understand is not a value
# it may quietly ignore.
unknown_types = sorted({t for t in declared.values() if t not in "ABCD"})
for t in unknown_types:
    names = sorted(n for n, tt in declared.items() if tt == t)
    print(f"  repos.toml deklaruje nieznany typ {t!r} dla: {', '.join(names)}")
    print(f"  Ten skrypt porównuje wyłącznie typy A-D, więc te wpisy NIE zostały sprawdzone.")
    bad += 1
for typ in "ABCD":
    m = re.search(rf"### Typ {typ} .*?\n(.*?)\n\n", sec, re.S)
    listed = set(re.findall(r"`([A-Za-z0-9_-]+)`", m.group(1))) if m else set()
    expect = {n for n, t in declared.items() if t == typ}
    for r in sorted(listed - expect):
        print(f"  typ {typ}: CLAUDE.md wymienia {r}, repos.toml nie"); bad += 1
    for r in sorted(expect - listed):
        print(f"  typ {typ}: repos.toml mówi {r}, CLAUDE.md pomija"); bad += 1

if bad:
    print(f"repo-types: MISMATCH — {bad} rozjazd(ów) między CLAUDE.md §11 a repos.toml")
    sys.exit(MISMATCH)
print(f"repo-types: OK — {len(declared)} repozytoriów, typy zgodne z CLAUDE.md §11")
sys.exit(OK)
