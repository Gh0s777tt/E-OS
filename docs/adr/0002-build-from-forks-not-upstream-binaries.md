---
title: ADR-0002 — Przepisy z forkiem E-OS budują się ze źródła, nie z binarek upstreamu
status: accepted
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# ADR-0002 — Przepisy z forkiem E-OS budują się ze źródła, nie z binarek upstreamu

- **Status:** Przyjęty
- **Data:** 2026-08-23
- **Dowód:** `U-163`, `U-164`, `U-165`, `R-F20`, `scripts/eos-source-rules.sh`, `cookbook.lock`

## Kontekst

Cookbook potrafi albo skompilować przepis ze źródła, albo **pobrać gotowy pakiet**
`<przepis>.pkgar` ze `static.redox-os.org`. Wyborem steruje `REPO_BINARY`, a wyjątki
per przepis trzyma `cookbook.lock`.

Oba pliki (`.config`, `cookbook.lock`) były **poza gitem**, a wyjątki dopisywano ręcznie.
Zmierzone konsekwencje: 26 przepisów deklaruje forka E-OS, **13 nie miało wyjątku**, więc
ich binarki pochodziły z cudzego serwera. `pins --strict` raportował `ok=26 drift=0` —
pin był prawdziwy, jego związek z artefaktem nie. Skutek najdotkliwszy: kliencka
weryfikacja podpisu manifestu (`R-703`) **nie istniała w obrazie**, choć `docs/security/index.md`
nazywała ją zaimplementowaną. Potwierdzone wyszukaniem czterech charakterystycznych
literałów w obrazie 1,4 GB: **0 trafień** przy działającej kontroli instrumentu.

## Decyzja

Każdy przepis, którego `recipe.toml` wskazuje na `github.com/Gh0s777tt/eos-*`, **musi**
budować się ze źródła. Listę **wyprowadza się z drzewa**, a nie utrzymuje ręcznie:
`scripts/eos-source-rules.sh`. `cookbook.lock` jest **śledzony przez gita** (`U-168`),
a kontrola 6 w `ci-integrity.sh` pada, gdy luka się otworzy.

## Odrzucone warianty

- **`REPO_BINARY=0` globalnie** — zmusiłoby do kompilowania także portów firm trzecich
  (`findutils`, `uutils`), co kosztuje godziny i nie daje nic: to nie jest kod E-OS.
- **Ręczna lista przepisów w skrypcie** — dokładnie ten mechanizm właśnie zgnił.
- **Pozostawienie `cookbook.lock` poza gitem** — sprawiało, że świeży klon budował inny
  obraz niż drzewo deweloperskie, bez żadnego śladu.

## Konsekwencje

- Zawartość obrazu jest **recenzowalna w code review** — `cookbook.lock` jest w diffie.
- Bramka lokalna i CI-owa pada, gdy dodany fork nie dostanie reguły.
- Porty firm trzecich nadal jadą jako binarki upstreamu — świadomie (§11 typ B).
- Odtwarzalność builda nadal **nie jest zweryfikowana** (`.config` wciąż poza gitem) —
  dług zapisany w §17 i na liście TODO.
