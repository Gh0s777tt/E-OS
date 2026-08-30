---
title: Nieaktualne migawki — nie są źródłem prawdy
status: archived
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Nieaktualne migawki — **nie są źródłem prawdy**

Katalogi obok to **rozpakowane archiwa**, a nie repozytoria gita. Nie mają `.git`, nie da się
z nich pchać, nie widać w nich historii i **starzeją się w ciszy**.

## Dlaczego tu trafiły

Leżały bezpośrednio w katalogu projektu, wyglądając jak repozytoria robocze, i były przez to
czytane jako źródło prawdy. W sierpniu 2026 doprowadziło to do sytuacji, w której diagnoza
błędu opierała się na kodzie **sprzed** wypchniętej poprawki:

* żadna z migawek nie zawierała poprawek `R-F18` ani `R-F24`, choć obie były już w forkach,
* `eos-installer-master` pochodził z 25 lipca, a poprawka `R-F24` — z 28 sierpnia,
* `eos-base-eos-july` odpowiada rewizji `816546df^`, czyli **jeden commit przed** przypięciem.

Reguła, która z tego wynikła, jest w `E-OS/CLAUDE.md` §20.2.

## Czy coś tu ginie? Nie — sprawdzone, nie założone

Audyt (`U-186`) objął **26 forków i 40 migawek**. Dla każdego pliku liczony był identyfikator
blobu gita i sprawdzana jego obecność w **całej** historii forka:

```
migawek ocenionych:      40
z unikalną treścią:       0
nieudanych klonów:        0
```

Zero plików, których treść nie istniałaby w historii. Wszystko, co tu leży, jest już
zacommitowane i wypchnięte.

> **Uwaga metodologiczna, bo sam się na tym potknąłem.** `git hash-object` **bez** `--path`
> nie stosuje filtrów z `.gitattributes`, więc plik z CRLF dostaje inny skrót niż jego
> znormalizowany odpowiednik w historii i wychodzi jako „nieobecny". Pierwszy przebieg zgłosił
> tak 6 plików; po dodaniu `--path` — **0 z 3657**. Wada przesuwała wynik wyłącznie w stronę
> *zawyżania* liczby brakujących, więc raporty „0 nieobecnych" pozostają wiarygodne.

## Czego używać zamiast tego

```bash
# kod forka — świeży klon, gałąź z repos.toml
git clone --branch <gałąź> https://github.com/Gh0s777tt/<fork>.git

# albo drzewo, z którego naprawdę buduje make (po wyrównaniu):
scripts/eos-sync-buildtree.sh --apply
```

## Kiedy to skasować

Kiedy tylko zechcesz — to kopie treści, która jest w forkach. Przeniesione, a nie usunięte,
żeby decyzja należała do Ciebie, a nie do narzędzia.
