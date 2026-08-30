# Decyzje SemVer — 2026-08-30

**Status:** propozycja do zatwierdzenia · **Ostatni przegląd:** 2026-08-30 ·
**Zakres:** `e-os/e-os`, `e-os/eos-installer`, `e-os/eos-pkgutils` — wyłącznie zmiany
**niescalone** · **Właściciel:** utrzymujący E-OS

---

## 0. Metoda i sprostowania do briefu

Wszystko poniżej zmierzone 2026-08-30 na drzewie
`/Volumes/Project itp/Projekty/E-OS Project/E-OS` (gałąź robocza `feat/m1-bootable-medium`)
oraz przez `glab api` na `gitlab.com`. Numery linii pochodzą z plików, nie z opisów MR-ów.

Dwa sprostowania, bo wpływają na zakres decyzji:

1. **Otwartych MR-ów jest jedenaście, nie dziewięć.** Zmierzone:
   `glab mr list` → `e-os/e-os` **4**, `eos-installer` **4**, `eos-pkgutils` **3**.
   Brief wymienia dla `eos-installer` trzy; czwarty to
   **`eos-installer!4` — `fix(deps): 12 podatności → 2 w drzewie zależności instalatora`**
   (gałąź `fix/dependency-advisories`, SHA `d2124486`). Nie był ujęty w bilansie i zmienia
   uzasadnienie wersji instalatora.
2. **`docs/reference/` nie istnieje na gałęzi roboczej.** Zmierzone
   `git ls-tree --name-only <gałąź> -- docs/reference`: trafienie **tylko** na
   `chore/repo-restructure` i `fix/p0-audit-findings`; na `main`, `feat/m1-bootable-medium`,
   `chore/docs-rebuild`, `chore/security-hardening` i `docs/installer-design` — nic. Katalog
   powstaje dopiero w `e-os/e-os!2` (`chore/repo-restructure`, 51 przeniesień `git mv`,
   zmierzone `git show --name-status -M d73fd1590 | grep -c '^R'` → 51).
   **Ten plik nie jest zacommitowany na żadnej gałęzi** — `git status` pokazuje go jako
   `?? docs/reference/`. Po scaleniu !2 ścieżka będzie ta sama, więc pogodzenie sprowadza się
   do zacommitowania go tam, gdzie leży.

### Topologia gałęzi (zmierzona `git merge-base --is-ancestor`)

```
main
 ├── chore/docs-rebuild (12)  ⊂  chore/repo-restructure (16)  ⊂  fix/p0-audit-findings (29)
 │        !1                          !2                              !3
 ├── chore/security-hardening (12)                      — niezależna
 │        !4
 └── docs/installer-design (3)  ⊂  feat/m1-bootable-medium (10)   — bez MR-ów
```

Liczby w nawiasach to `git rev-list --count main..<gałąź>`. Konsekwencja dla wersjonowania:
**!3 zawiera !1 i !2**, więc scalenie samego !3 dostarcza cały stos A. `!4` i stos M1 są
rozłączne. Jedna wersja produktu opisuje **sumę** tych trzech stosów — nie da się wydać
części, bo `feat/m1-bootable-medium` nie zawiera `fix/p0-audit-findings` i odwrotnie.

---

## 1. Reguła 0.x — rozstrzygnięta wprost, zanim padną liczby

SemVer 2.0.0 §4 mówi: *„Major version zero (0.y.z) is for initial development. Anything MAY
change at any time."* §5: *„Version 1.0.0 defines the public API."* Czyli formalnie **przed
1.0.0 nic nie wymusza podbicia MAJOR** i każda z poniższych zmian łamiących mogłaby wylądować
w PATCH-u, nie łamiąc specyfikacji.

To jest jednak licencja na milczenie, a nie na porządek. Przyjmuję regułę powszechną w
ekosystemie Rusta i **zaimplementowaną w narzędziach tego repozytorium**: przy zerowym MAJOR
rolę MAJOR pełni **MINOR**, a rolę MINOR — **PATCH**:

| SemVer po 1.0 | E-OS przed 1.0 | Przykład |
|---|---|---|
| MAJOR (łamiące) | **MINOR** | 0.2.0 → 0.3.0 |
| MINOR (dodające) | PATCH lub MINOR | 0.2.0 → 0.2.1 |
| PATCH (poprawka) | **PATCH** | 0.2.0 → 0.2.1 |

To nie jest arbitralne. Dwa dowody z drzewa:

- `release-please-config.json` (na `chore/security-hardening`, dodany w !4) ma
  **`"bump-minor-pre-major": true`** — czyli automat wydań, który ten projekt sam sobie
  skonfigurował, przy zmianie łamiącej przed 1.0 podbije MINOR, nie MAJOR.
- Cargo interpretuje `^0.2.0` jako `>=0.2.0, <0.3.0` — pierwsza niezerowa cyfra jest
  granicą kompatybilności.

**KONFLIKT DO ROZSTRZYGNIĘCIA PRZED PIERWSZYM TAGIEM.** W drzewie są **dwa** narzędzia wydań
o przeciwnej polityce przed 1.0, oba skonfigurowane:

- `.releaserc.json` (na `main` **i nadal** na `chore/security-hardening`) — semantic-release,
  `branches: ["main"]`, `tagFormat: "v${version}"`, plugin `@semantic-release/gitlab`.
- `release-please-config.json` + `.release-please-manifest.json` (dodane w !4) — release-please,
  `release-type: "simple"`, `bump-minor-pre-major: true`, `changelog-path: "RELEASE-NOTES.md"`.

Zachowanie semantic-release przy MAJOR z wersji 0.x — **[NIEZWERYFIKOWANE]**, nie uruchamiałem
go. Nie o to jednak chodzi: dwa automaty wydań na jednym repozytorium to jeden automat za dużo.
**Wybrać jeden przed tagowaniem v0.3.0.**

### Dlaczego nie 1.0.0

Odrzucam wprost, bo pokusa jest realna: zmian łamiących jest tu dużo i „skoro i tak łamiemy,
to może już 1.0". Nie — 1.0.0 jest **obietnicą stabilnego API**, a mierzalny stan projektu jej
nie unosi:

- żaden rozruch na **prawdziwym sprzęcie** nigdy nie nastąpił —
  `docs/plan-do-sprzetu.md:16-18`: *„Nic w tym repozytorium nigdy nie działało na fizycznym
  sprzęcie — każda weryfikacja to QEMU"*, oraz `CHANGELOG.md:140`: *„zero boot claim has ever
  been made on metal; every one is QEMU"*. `ROADMAP.md:420` nazywa osobną listę „What needs
  the x86 rig or real hardware", a `ROADMAP-v2.md:886` mierzy skutek: `docs/hardware-matrix.md`
  ma **zero wierszy z E-OS**,
- `R-601` (partycja → instalacja → reboot → login) został udowodniony po raz pierwszy
  dopiero w `U-176` (`ROADMAP.md:323`) i tylko pod TCG,
- **obie** bramki CI są martwe: GitLab `ci_quota_exceeded` od 2026-08-28, GitHub Actions nie
  wykonują się w ogóle (opis `e-os/e-os!4`),
- obraz, który dziś dostaje użytkownik, przedstawia się jako **0.1.0**
  (`config/x86_64/eos.toml:98-99`), a ostatni tag to `v0.2.0`. Deklarowanie 1.0.0 nad
  niespójnością, której się jeszcze nie posprzątało, byłoby napisem, nie faktem.

---

## 2. `e-os/e-os`

### Wersja obecna → proponowana

| | |
|---|---|
| **Ostatni tag** | `v0.2.0` |
| **Wersja w obrazie** (`config/x86_64/eos.toml:98-99`, `config/aarch64/eos.toml:96-97`) | `0.1.0 (Genesis)` |
| **`mk/config.mk:185`** | `EOS_VERSION?=0.2.0` — **tylko na `feat/m1-bootable-medium`**; zmierzone `git show <gałąź>:mk/config.mk \| grep EOS_VERSION` na wszystkich siedmiu gałęziach: trafienie w jednej, na `main` **zera** (zmienną dodaje `50d2c2c2e`) |
| **`config/base.toml:104-105`** | `0.9.0` — patrz §2.4, to **nie** jest wersja E-OS |
| **`Cargo.toml:2-3`** | `redox_cookbook` `0.1.0` — wersja wendorowanego narzędzia budującego upstreamu, nie produktu |
| **PROPONOWANA** | **`v0.3.0`** |

**Uzasadnienie w jednym zdaniu:** w niescalonym materiale są co najmniej **trzy** zmiany
łamiące dla kogoś, kto buduje własne obrazy, a przed 1.0 zmiana łamiąca podbija MINOR.

### 2.1 Zmiany ŁAMIĄCE (każda samodzielnie wymusza `0.3.0`)

#### B-1. Bootloader bez klucza przestaje się budować (`f4500f932`, MR !3)

`recipes/core/bootloader/recipe.toml` drukował ostrzeżenie *„no boot key at build/boot-signing/
-- bootloader will NOT verify what it loads"* i budował dalej z **wyłączoną weryfikacją**,
kończąc kodem 0. Teraz budowanie bez klucza **kończy się kodem 1** (`recipe.toml:51` na
`fix/p0-audit-findings`: `exit 1`), chyba że podano `EOS_ALLOW_UNVERIFIED_BOOT=1`
(`recipe.toml:33`, gałąź `elif`).

To jest **najostrzejsza** zmiana łamiąca w całym zestawie, bo dotyczy stanu **domyślnego**:
ktokolwiek nigdy nie uruchomił `scripts/eos-sb-setup-key.sh`, ten dziś buduje bez klucza i jego
budowanie po scaleniu **przestaje działać**. Furtka istnieje, ale trzeba ją dopisać do własnego
polecenia albo do własnego CI — czyli akcja po stronie użytkownika, definicja zmiany łamiącej.

Kontrargument, który odrzucam: „to była wada, więc naprawa nie jest łamiąca". Naprawą jest
**odmowa**, a odmowa jest łamiąca niezależnie od tego, jak słuszna. Poprzednie zachowanie było
niebezpieczne, ale było **działającą, udokumentowaną ścieżką** (recepta sama je opisywała).

#### B-2. Nazwa i ścieżka nośnika (`50d2c2c2e`, `feat/m1-bootable-medium`) — patrz §5.1

`mk/disk.mk:20` zmienia cel z `$(BUILD)/redox-live.iso` na `$(INSTALLER_MEDIUM)`
(`mk/config.mk:194-195`: `eos-$(EOS_VERSION)-$(ARCH)-installer.img`). **Aliasu nie ma.**
Zmierzone: `git grep -c redox-live feat/m1-bootable-medium -- Makefile mk/` → **1 trafienie**,
i to komentarz w `mk/config.mk`. Reguły produkującej stary plik w drzewie nie ma.

#### B-3. Przypięcie klucza upstreamu (`2c836aef5`, MR !3) — patrz §5.2

`src/cook/fetch_repo.rs:58` `pin_upstream_key` **bezwarunkowo nadpisuje** plik klucza dla
każdego zdalnego repozytorium przy każdym uruchomieniu (`:77` `for (_, remote) in
repo.remote_map.iter_mut()`, `:83` `RepoPublicKeyFile::new(pin.pkey).save(&cached)` bez żadnego
warunku) i **panikuje**, jeśli `keys/upstream-redox-pkg.pub.toml` jest nieczytelny
(`:59-66`). Ścieżka pinu to `const` (`:39`), nie zmienna — nie ma żadnej zmiennej środowiskowej
ani opcji konfiguracyjnej, która by to wyłączała. Wszystkie linie z gałęzi
`fix/p0-audit-findings`.

#### B-4. Bramka 12: nieprzypięte archiwum wywraca `ci-integrity.sh` (`f8ac1b09b`, MR !3)

Nowa kontrola w `scripts/ci-integrity.sh:339` (wywołanie `python3
scripts/eos-check-tar-pins.py`) — **każda** recepta osiągalna z konfiguracji obrazu musi mieć
`blake3`. Oba pliki istnieją na `fix/p0-audit-findings` (zmierzone `git ls-tree`). Wzrost
domknięcia z 52 do 77 receptur i przebieg w obie strony (bez pinu `BAD: 1 recipe(s)`, kod 1)
pochodzą **z opisu `f8ac1b09b`**; sam skryptu nie uruchamiałem.

Łamiące dla każdego, kto niesie własne receptury — bramka, która wcześniej przechodziła, teraz
odmawia. To bramka, nie środowisko uruchomieniowe, więc waży mniej niż B-1, ale jest zmianą
kontraktu dla współpracujących.

#### B-5. Przeniesienie drzewa dokumentacji (`d73fd1590`, MR !2)

51 przeniesień `git mv`, 294 odnośniki naprawione **wewnątrz** repozytorium. Odnośniki
**zewnętrzne** — do opublikowanego podręcznika (`DOCUMENTATION_URL` w os-release), do zgłoszeń,
do czegokolwiek poza repozytorium — przestają działać, bo `docs/tokeny.md` staje się
`docs/reference/keys-and-tokens.md` itd.

Łamiące w słabszym sensie (adresy dokumentacji, nie kod), ale to jest publiczna powierzchnia
projektu, który sam publikuje handbook. Odnotować w informacjach o wydaniu z tabelą przekierowań.

### 2.2 Zmiany DODAJĄCE (MINOR — same z siebie dałyby `0.2.x` → `0.3.0` albo `0.2.1`)

| Zmiana | Dowód |
|---|---|
| Cel `make print-installer-medium` — jedno miejsce, o które skrypty pytają o ścieżkę nośnika | `Makefile:14-15` na `feat/m1-bootable-medium` (`.PHONY: print-installer-medium` + reguła); na `main` tego celu nie ma |
| `scripts/verify.sh` — cały łańcuch bramek lokalnych jednym poleceniem, 602 linie | `chore/security-hardening`, `git diff --stat` |
| Osiem workflow'ów GitHub Actions + `.pre-commit-config.yaml` + `dependabot.yml` + `CODEOWNERS` + `osv-scanner.toml` | `chore/security-hardening`, 29 plików, +7395 linii |
| `scripts/setup-github-security.sh` (740 linii) + `docs/security/github-configuration.md` + `docs/security/incident-response.md` | jw. |
| Kontrola 12 i `scripts/eos-check-tar-pins.py` (dodatek; jej **egzekwowanie** to B-4) | `f8ac1b09b` |
| `keys/upstream-redox-pkg.pub.toml` — nowy przypięty klucz | `2c836aef5` |
| Trzy uruchamialne przykłady, komplet szablonów zgłoszeń | `4c2492bc7`, `40612a79f` |
| ADR-0007..0011 + `docs/architecture/installer{,-wizard,-profiles}.md`, `system-updates.md` (~10 800 linii) | `docs/installer-design` |
| `redox.ipxe` jako szablon z podstawianiem i kontrolą `grep -q` | `mk/disk.mk:37-38` na `feat/m1-bootable-medium`; `redox.ipxe:4` = `@INSTALLER_MEDIUM_NAME@` (na `main` = `redox-live.iso`) — **uwaga**, patrz §5.1: dla kogoś, kto serwuje ten plik surowo, to jest regres |
| `docs/licenses/THIRD_PARTY.md` — wcześniej nie istniał | `1d7c23810` |

### 2.3 Zmiany będące POPRAWKAMI (PATCH)

Te poprawki **nie leżą w jednym MR-ze**, a to zmienia, co da się wydać. Zmierzone
`git branch --contains <sha>`: `0029fb7e6`, `f667d9c12`, `24a3b390d`, `5a0ec5195`, `36513fb85`,
`75c92ee87` → `fix/p0-audit-findings` (**!3**); `d3a8e9bcb` → `chore/security-hardening`
(**!4**); `984b614cc`, `94a2e57c7`, `57fe451ed`, `81cec7659` → `feat/m1-bootable-medium`, czyli
gałąź **bez MR-a** — te cztery nie mają dziś żadnej otwartej drogi do `main`.

| Poprawka | Dowód |
|---|---|
| `repo` TUI panikował, gdy wyszukiwanie w dzienniku nic nie znalazło — 5 indeksowań poza zakres + 1 niedomiar `usize` | `0029fb7e6` (MR !3); „dwa z trzech testów padają na kodzie sprzed poprawki" — z opisu commita, nie z własnego przebiegu |
| `$(FSTOOLS_TAG)` miał **zero** wymagań przy `PODMAN_BUILD=0` — `make` nie przebudowywał `repo`, `repo_builder`, `cookbook_redoxer` | `f667d9c12`, `mk/fstools.mk` |
| `$(FSTOOLS)` nie przebudowywał instalatora ani RedoxFS **od dwóch miesięcy** | `984b614cc` (`feat/m1-bootable-medium`) |
| `Cargo.lock` wskazywał GitHuba, gdy `Cargo.toml` wskazywał GitLaba — `cargo test --locked` padał **tylko na tej gałęzi** | `24a3b390d`, jedna linia |
| `anyhow` 1.0.102 → 1.0.104 (RUSTSEC-2026-0190); `lru` udokumentowany jako nieosiągalny z `ignoreUntil = 2026-11-30` | `d3a8e9bcb` — uwaga: to gałąź `chore/security-hardening` (**!4**), nie !3 |
| Allowlista gitleaks dla dwóch **publicznych** kluczy (C-19) | `5a0ec5195` + `2c836aef5` (`.gitleaks.toml`) |
| `eos-sync-buildtree.sh`: ignorowane błędy `cp`, `cp -p` przenoszące mtime hosta, mylący komunikat SELinux/MCS | `36513fb85` |
| Obrazy bazowe kontenerów przypięte po **digeście**, nie po ruchomym tagu | `75c92ee87`, 3 pliki `podman/*containerfile` |
| 7 zepsutych odnośników w dokumentacji; README twierdził dwie nieprawdy | `94a2e57c7`, `57fe451ed` (`feat/m1-bootable-medium`) — po naprawie **410 OK, 0 błędów** na tej gałęzi |
| Cofnięcie trzech przedwczesnych ✅ w roadmapie | `81cec7659` (`feat/m1-bootable-medium`) |

### 2.4 Przypadek graniczny: repointing GitHub → GitLab (`8ec46a1c7`)

22 z 26 receptur pobierało źródła z **kopii lustrzanej**, wbrew ADR-0001. Zdanie *„wszystkie 26
referencji rozwiązywały się przed przeniesieniem do **identycznych rewizji**"* pochodzi z opisu
`8ec46a1c7`, nie z mojego przebiegu — **[NIEZWERYFIKOWANE]** co do samego porównania rewizji.
Sens klasyfikacji jednak trzyma: zmienia się, **skąd** przychodzą bajty, nie **które**.

Ale ta sama zmiana przestawia adresy **wpalone w obraz**. Zmierzone: commit rusza 31 plików,
w tym `config/x86_64/eos.toml` i `config/aarch64/eos.toml` (po 10 linii) oraz
`recipes/other/eos/recipe.toml`. To są dokładnie te pliki, które zapisują `HOME_URL`,
`SUPPORT_URL`, `BUG_REPORT_URL`, `DOCUMENTATION_URL` w `/usr/lib/os-release`
(`config/x86_64/eos.toml:104-107`), `/etc/motd` (`:131`) oraz `/usr/share/eos/eos-release`
(`:29` wskazuje `recipes/other/eos`). To jest widoczna dla użytkownika zawartość systemu.

**Klasyfikacja: MINOR, nie łamiące.** Nic, co działało, nie przestaje działać; zmienia się
treść pliku metadanych. Odnotować, bo to jedyna zmiana w tym MR-ze, którą użytkownik zobaczy
na własnym ekranie.

### 2.5 G-17 — warunek konieczny wydania, nie osobne zadanie

Zmierzone dziś:

| Miejsce | Wartość | Co to naprawdę jest |
|---|---|---|
| tag produktu | `v0.2.0` | to, co pobiera użytkownik |
| `config/x86_64/eos.toml:98-99` | `0.1.0 (Genesis)` | **to widzi użytkownik** — `/usr/lib/os-release`, `postinstall = true` |
| `config/aarch64/eos.toml:96-97` | `0.1.0 (Genesis)` | jw. |
| `mk/config.mk:185` | `0.2.0` | rządzi **wyłącznie nazwą pliku** nośnika — i **istnieje tylko na `feat/m1-bootable-medium`**; na `main` tej zmiennej nie ma wcale |
| `config/base.toml:104-105` | `0.9.0` | **wersja upstreamu Redoksa**, nadpisywana przez `eos.toml` |
| `Cargo.toml:3` | `0.1.0` | crate `redox_cookbook` — narzędzie budujące upstreamu |

**Rozstrzygnięcie, którego G-17 nie zawiera, a powinno:** `config/base.toml` **nie należy do**
rozjazdu. Oba pliki zapisują tę samą ścieżkę `/usr/lib/os-release`, a `config/*/eos.toml`
robi to z `postinstall = true` i wygrywa; potwierdza to zapis z rozruchu w `CHANGELOG.md:140`
(`E-OS 0.1.0 "Genesis"` → `eos login:`). `base.toml` jest wendorowaną konfiguracją Redoksa i
**zmiana jej byłaby rozjazdem z upstreamem bez zysku**. Tak samo `Cargo.toml` — to nie jest
wersja produktu.

Rozjazd realny sprowadza się do **trzech** miejsc: tag `v0.2.0`, obraz `0.1.0`, nazwa pliku
`0.2.0` — ale **dopiero po scaleniu M1**. Dziś, gdy nic nie jest scalone, w `main` istnieją
**dwa** z tych trzech: trzeci (`EOS_VERSION` w `mk/config.mk`) przychodzi razem z niescaloną
`feat/m1-bootable-medium` (`50d2c2c2e`). Formuła G-17 opisuje więc stan **docelowy** drzewa
roboczego, nie stan produktu.

**Wymóg przed tagowaniem `v0.3.0`:** `config/x86_64/eos.toml` i `config/aarch64/eos.toml`
muszą podawać `0.3.0`, tak samo `EOS_VERSION` w `mk/config.mk:185`. Bez tego numer wersji nie
znaczy nic: użytkownik pobiera `v0.3.0`, uruchamia i czyta `0.1.0`. Docelowo jedno źródło —
`EOS_VERSION` podstawiany do konfiguracji tak, jak `mk/disk.mk` podstawia go dziś do
`redox.ipxe` — ale minimum na to wydanie to trzy zgodne liczby i bramka, która to sprawdza.

---

## 3. `e-os/eos-installer`

### Wersja obecna → proponowana

| | |
|---|---|
| **`Cargo.toml:3` (gałąź `master`)** | `0.2.42` |
| **Tagi w repozytorium** | **42 tagi**, `0.2.42` … `0.2.1` — **wszystkie z upstreamu**, odziedziczone przy forkowaniu (zmierzone `glab api projects/e-os%2Feos-installer/repository/tags?per_page=100`) |
| **`repository =`** | `https://gitlab.redox-os.org/redox-os/installer` — nadal upstream |
| **Rewizja przypięta w E-OS** | `repos.toml:116` `c8d32ad39e5c778fb8aec51c953f2898d9e55495`, gałąź `master`, `type = "C"` |
| **PROPONOWANA** | **`0.2.42+eos.1`** |

### 3.1 Dlaczego metadane budowania, a nie zwykłe podbicie

To jest fork **typu C** (`repos.toml:109`). Konsekwencje zmierzone, nie założone:

- Numer `0.2.42` i cała seria tagów **należą do upstreamu**. Podbicie do `0.2.43` oznacza, że
  gdy upstream wyda `0.2.43`, będą istniały **dwa różne artefakty o tym samym numerze**. To
  jest dokładnie ta kolizja, dla uniknięcia której polityka forków w ogóle istnieje
  (`eos-installer!1`: *utrzymuj łatki nadające się do rebase'u*).
- E-OS konsumuje ten fork **po rewizji**, nie po wersji (`repos.toml:116`, `pinned_rev`), więc
  podbicie numeru operacyjnie nie kupuje **niczego**.
- SemVer §10: metadane budowania (`+`) są **ignorowane w porównywaniu wersji** — a to jest
  prawda, którą chcemy zapisać: `0.2.42+eos.1` **jest** upstreamowym 0.2.42 plus łatki E-OS i
  nie udaje wydania upstreamu.
- Odrzucam wariant z pre-release (`0.2.43-eos.1`): SemVer §9 daje mu **niższy** priorytet niż
  `0.2.43`, a Cargo domyślnie nie dopasowuje pre-release do wymagania `^0.3.1`. To by realnie
  zepsuło rozwiązywanie zależności — patrz `redox-pkg` w §4.

Dziś `Cargo.toml` mówi `0.2.42`, choć gałąź niesie już siedem commitów E-OS ponad ten tag
(od `75b6bd56` do `c8d32ad3`). Ten numer **już** jest nieprawdziwy. `+eos.1` to pierwsze
przypisanie znacznika forka, nie liczenie wstecz.

### 3.2 Uzasadnienie per zmiana

| MR | Klasa | Uzasadnienie |
|---|---|---|
| **!1** `chore/repo-restructure` | **żadna** (dokumentacja) | 5 plików, **ani jednego pliku źródłowego**: `.editorconfig`, `CLAUDE.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, +312 linii. Nie zmienia żadnego artefaktu. Sam z siebie nie jest zdarzeniem wersjonującym. |
| **!2** R-607a, rozmiar bloku | **PATCH** (+ nowa ścieżka błędu) | patrz §5.4 |
| **!3** R-612a, kolejność zapisu | **PATCH** (+ nowa ścieżka błędu po powodzeniu callbacku) | patrz §5.3 |
| **!4** podatności zależności | **PATCH** | wyłącznie `Cargo.lock`. 12 podatności w 8 pakietach → 2. `quinn-proto` 0.11.13→0.11.17 (RUSTSEC-2026-0037, ocena 8,7), `rustls-webpki` 0.103.9→0.103.15, `bytes`, `crossbeam-epoch`, `anyhow`, `rand` 0.9.2→0.9.3 wymuszony `--precise` (bezpośrednia zależność, `Cargo.toml:35`). Zostają `ring 0.17.8` (bierzemy fork Redoksa, którego najnowsza gałąź **jest** `redox-0.17.8`) i `number_prefix 0.4.0` (pakiet nieutrzymywany). Zmiana lockfile'a **nie dotyka** konsumentów biblioteki — Cargo ignoruje `Cargo.lock` zależności — więc dotyczy wyłącznie budowanych binarek. |

### 3.3 Powierzchnia, którą trzeba było sprawdzić, zanim padnie „PATCH"

`eos-installer` **jest biblioteką**, nie tylko binarką: `Cargo.toml:21-23` (gałąź `master`)
deklaruje `[lib] name = "redox_installer" path = "src/lib.rs"` obok **dwóch** `[[bin]]` —
`Cargo.toml:11-14` (`redox_installer`) i `:16-19` (`redox_installer_tui`); `src/bin/` zawiera
dokładnie te dwa pliki. `with_whole_disk` i `DiskWrapper::open` są `pub`. Dlatego zmiany zachowania w !2 i !3 **są** zmianami widocznymi
przez API — i dlatego obie wymagają wpisu w informacjach o wydaniu, mimo klasy PATCH.

Gdyby wersjonować ten fork niezależnie od upstreamu, poprawny numer byłby **`0.3.0`** (nowe
tryby błędu na funkcjach publicznych → przed 1.0 podbicie MINOR). Odrzucam to z powodów §3.1,
nie dlatego, że zmiany są błahe.

---

## 4. `e-os/eos-pkgutils`

### Wersja obecna → proponowana

| | |
|---|---|
| **`Cargo.toml` `[workspace.package] version`** | `0.3.1` — identycznie na `master` i na `eos` |
| **Crate biblioteczny** | `pkg-lib` → nazwa pakietu **`redox-pkg`**, `[lib] name = "pkg"` |
| **Tagi** | `0.3.1` … `0.1.2` — z upstreamu |
| **Rewizja przypięta w E-OS** | `repos.toml:176` `e28063ee2f6ffee19322dedaf2d0e4ab737feb75`, gałąź `eos`, `type = "C"` |
| **PROPONOWANA** | **`0.3.1+eos.1`** |

Uzasadnienie schematu — identyczne jak §3.1, z jednym wzmocnieniem: `redox-pkg` **jest**
rozwiązywany po wersji. `eos-installer/Cargo.toml:36` ma
`redox-pkg = { version = "0.3.1", features = ["indicatif"], optional = true }`. Wymaganie
`^0.3.1` dopasuje `0.3.1+eos.1` (metadane budowania są ignorowane), ale **nie** dopasowałoby
`0.3.2-eos.1`. To przesądza wybór między §10 a §9 SemVera na korzyść metadanych budowania.

### 4.1 Uzasadnienie per zmiana

| MR | Klasa | Uzasadnienie |
|---|---|---|
| **!1** `chore/repo-restructure` | **żadna** | te same 5 plików dokumentacji, +312 linii, zero plików źródłowych |
| **!2** podatności zależności | **PATCH** | wyłącznie `Cargo.lock`. 11 podatności w 7 pakietach → 2. Drzewo `rand 0.9.2` **znika w całości** (było zdublowaną rozwiązką obok 0.10.2). `pkg` jest instalowany w obrazie, więc to drzewo jest powierzchnią ataku **na działającym systemie** — to podnosi wagę, nie klasę |
| **!3** katalog pobierania | **PATCH dla użytkownika, MINOR dla API** | poniżej |

### 4.2 `!3` rozłożony na części — bo klasy się różnią

Zmierzone z diffa (`pkg-lib/src/repo_manager.rs`, `pkg-lib/src/net_backend/mod.rs`,
`pkg-lib/Cargo.toml`):

**Poprawka (PATCH), i to poważna.** `DOWNLOAD_DIR` to `/tmp/pkg_download/`
(`pkg-lib/src/lib.rs:26`, `const`, prywatna) — stała nazwa pod katalogiem zapisywalnym dla
wszystkich, z przewidywalnymi nazwami plików (`<remote>_<pakiet>.pkgar`), tworzona
`create_dir_all` bez sprawdzenia właściciela. `File::create` **podąża za dowiązaniem
symbolicznym**. Razem: zapis do dowolnego pliku z uprawnieniami tego, kto uruchamia `pkg`,
czyli na prawdziwym systemie roota. Demonstracja przed poprawką — nieuprzywilejowany
użytkownik podłożył dowiązanie, root zostawił plik 868 992 B pod ścieżką wybraną przez
atakującego — pochodzi **z opisu MR-a**; sam jej nie odtwarzałem, **[NIEZWERYFIKOWANE]**
co do przebiegu. Zweryfikowałem natomiast kod: ścieżkę, brak sprawdzenia właściciela przed
poprawką i trzy gołe `create_dir_all`, które poprawka zastępuje.

**Nowy tryb błędu na API publicznym (MINOR).** `ensure_private_dir`
(`pkg-lib/src/repo_manager.rs:36`, gałąź MR-a `fix/download-dir-symlink`) zastępuje trzy gołe
`create_dir_all` i **odmawia**, gdy katalog jest dowiązaniem, nie jest katalogiem, albo
**należy do innego uid**. Wywołuje się z `sync_keys_internal` (`:384`), `download` (`:422`) i
**`local_search` (`:452`), która jest `pub` (`:451`)**. Skutek praktyczny: `/tmp/pkg_download` utworzony wcześniej przez innego
użytkownika — albo przez roota w poprzednim przebiegu kontenera, gdy bieżący idzie bez roota —
sprawia, że `pkg` **przestaje działać**, choć wcześniej działał. Sam MR to nazywa:
*„Residual, and deliberate: a local user can still deny service by pre-creating
/tmp/pkg_download"*. To jest świadomy regres dostępności i musi być w informacjach o wydaniu.

**Zawężenie wspieranych platform (MINOR, może łamiące).** `pkg-lib/Cargo.toml` zyskuje
`libc = "0.2"` jako zależność **nieopcjonalną** (diff MR-a: jedna linia dodana w
`[dependencies]`, bez `optional`), a `repo_manager.rs:18` importuje
`std::os::unix::fs::{MetadataExt, OpenOptionsExt, PermissionsExt}` **bez `cfg`**. Po tej
zmianie `pkg-lib` **na pewno** nie kompiluje się poza Uniksem. Czy kompilował się wcześniej —
**[NIEZWERYFIKOWANE]**, nie próbowałem. E-OS celuje w Redoksa i Linuksa, więc realnego
konsumenta to nie dotyczy, ale nowa obowiązkowa zależność w grafie biblioteki jest zdarzeniem
co najmniej MINOR.

**Zmiany nazw plików tymczasowych (bez klasy).** Pobrania lądują pod prywatną nazwą
`.<pid>.<n>.part` i są przemianowywane (`rename` w obrębie katalogu jest atomowy), a nazwa
robocza w `get_package_pkgar` jest teraz unikalna. Naprawia to również realną chybotliwość
testów i błąd *„missing field `pkey`"*, gdy dwaj wywołujący pobierali klucz jednocześnie.
Nic tych nazw nie czyta.

Gdyby wersjonować niezależnie: **`0.4.0`**. Ze schematem forka: `0.3.1+eos.1`.

### 4.3 Znalezisko przy okazji — dwie rewizje `pkgutils` naraz, obie „0.3.1"

`eos-installer/Cargo.toml:86` (`[patch.crates-io]`) przypina
`redox-pkg = { git = "https://github.com/Gh0s777tt/eos-pkgutils.git", rev = "cf36a01b9b" }`,
a `repos.toml:176` przypina recepturę na `e28063ee`. Z dziennika gałęzi `eos` zmierzone:
`cf36a01b` (2026-08-27) leży **trzy commity przed** `e28063ee` (2026-08-30) — brakuje mu
`14505ecd` i `f26f7767` (*„enforce the signed index on package bytes, on every install path"*).

Czyli instalator — składnik, który **zapisuje świeży system na dysk** — linkuje `pkg-lib` bez
wymuszenia podpisanego indeksu, a obraz dostaje wersję z nim. Obie noszą numer `0.3.1`, więc
żadna bramka patrząca na wersje tego nie zobaczy.

To jest bezpośredni argument za `+eos.N`: numer, który **zmienia się razem z treścią forka**,
uczyniłby ten rozjazd widocznym. Ponadto ten sam `[patch.crates-io]` wskazuje **GitHuba**, czyli
kopię lustrzaną, wbrew ADR-0001 i wbrew temu, co `e-os/e-os!3` (`8ec46a1c7`) właśnie przestawił
na GitLaba w repozytorium głównym. Osobne znalezisko, nie wersjonowanie — ale trafia w ten sam
mechanizm.

---

## 5. Cztery pytania rozstrzygnięte

### 5.1 Czy zmiana nazwy `redox-live.iso` → `eos-<wer>-<arch>-installer.img` jest ŁAMIĄCA?

**TAK. Jednoznacznie.** To najlepiej udokumentowana zmiana łamiąca w całym zestawie.

Dowody z drzewa `feat/m1-bootable-medium`:

1. **Cel zniknął, aliasu nie ma.** `mk/disk.mk:20` brzmiał
   `$(BUILD)/redox-live.iso: $(FSTOOLS) $(REPO_TAG) redox.ipxe`, brzmi
   `$(INSTALLER_MEDIUM): …`. `git grep -c redox-live` po `Makefile` i `mk/` daje **1** — komentarz
   w `mk/config.mk`. Reguły produkującej stary plik nie ma.
   *(Kod wyjścia 2 z `make build/x86_64/eos/redox-live.iso` pochodzi z opisu commita `50d2c2c2e`;
   sam tego polecenia nie uruchamiałem — nie mam tu drzewa budowania. Brak reguły zmierzyłem.)*
2. **Zasięg dowodzi, że nazwa była nośna.** Commit ruszył **14 plików**: `Makefile`, `build.sh`,
   `mk/ci.mk`, `mk/config.mk`, `mk/disk.mk`, `mk/qemu.mk`, `redox.ipxe` i **siedem skryptów**
   (`ci-boot-smoke.sh`, `eos-boot-setup-key.sh`, `eos-build.sh`, `install-smoke-drive.py`,
   `network-boot.sh`, `qemu-driver-check.sh`, `ventoy.sh`). Kto ma własny skrypt o tym samym
   kształcie — a `dd if=…/redox-live.iso` to procedura z dokumentacji — ten po scaleniu ma
   skrypt, który nic nie znajdzie.
3. **Dokumentacja użytkownika NIE została poprawiona.** Zmierzone na gałęzi
   `feat/m1-bootable-medium`: `docs/install.md:38` —
   `make CONFIG_NAME=eos ARCH=x86_64 build/x86_64/eos/redox-live.iso`, `docs/install.md:100-101`
   — `make … live  # -> build/x86_64/eos/redox-live.iso` oraz
   `sudo dd if=build/x86_64/eos/redox-live.iso of=/dev/sdX …`. Do tego `ROADMAP.md:185`,
   `docs/plan-do-sprzetu.md:37` i `docs/ci.md:100`. Licznik: `grep -c 'redox-live.iso'
   docs/install.md` → **3**.

   **PRZED scaleniem a PO — rozróżnienie, bez którego to zdanie byłoby nieprawdziwe.** Na `main`
   `mk/disk.mk:20` nadal brzmi `$(BUILD)/redox-live.iso: $(FSTOOLS) $(REPO_TAG) redox.ipxe`
   (zmierzone `git show main:mk/disk.mk`), a `docs/install.md:38` na `main` podaje tę samą
   ścieżkę. Czyli **dziś, gdy nic nie jest scalone, udokumentowane polecenie zgadza się z
   budowaniem**. Rozjazd „dokument opisuje nieistniejący plik" istnieje **wyłącznie na
   niescalonej gałęzi `feat/m1-bootable-medium`** i dosięgnie użytkownika dopiero **po**
   scaleniu M1. Dlatego to warunek wydania, a nie awaria produkcyjna.

   To nie jest kosmetyka: audyt dryfu na tej samej gałęzi wymienia te same ścieżki
   (`docs/audit/98-doc-drift-2026-08-30.md:387-391`) i wskazuje właściciela zadania
   (`:393-396` → `ROADMAP-v2.md:885`, pozycja **`R-608`** *(część)*, kryterium
   `grep -c 'redox-live.iso' docs/install.md` → 0), notując przy tym, że
   `docs/plan-do-sprzetu.md` i `docs/ci.md` *„nie mają właściciela w żadnym zadaniu M1"*.
   **Uwaga do tych trzech numerów:** ten plik audytu jest dziś modyfikowany w drzewie roboczym
   (`git status` → `M docs/audit/98-doc-drift-2026-08-30.md`), a numery linii zdążyły się
   przesunąć w trakcie pisania tego dokumentu. Wiążący jest cytat, nie numer; przy kolejnym
   przeglądzie sprawdzić `grep -n 'redox-live' docs/audit/98-doc-drift-2026-08-30.md`.
4. **`redox.ipxe` stał się szablonem.** Na `feat/m1-bootable-medium` `redox.ipxe:4` brzmi
   `initrd http://${next-server}:8080/@INSTALLER_MEDIUM_NAME@`; podstawienie robi
   `mk/disk.mk:37` (`sed "s/@INSTALLER_MEDIUM_NAME@/$(INSTALLER_MEDIUM_NAME)/"`) z kontrolą
   `grep -q` w `:38`, przy kopiowaniu do `BUILD`. Na `main` ta sama linia brzmi
   `initrd http://${next-server}:8080/redox-live.iso` — czyli plik z repozytorium jest tam
   nadal serwowalny wprost. **Po** scaleniu M1 kto serwuje plik z repozytorium przez HTTP,
   serwuje literalny znacznik: regres dla ścieżki rozruchu sieciowego, dziś jeszcze nieobecny.

**Kontrargument, który rozważyłem i odrzucam:** *„`make live` nadal działa, więc nic się nie
zepsuło."* Cele `live` i `popsicle` faktycznie działają — ale **wytwarzają plik pod inną
ścieżką**, a zepsute jest wszystko, co tę ścieżkę zna. Dodatkowo nowa nazwa zawiera wersję
(`eos-$(EOS_VERSION)-$(ARCH)-installer.img`), więc **ścieżka artefaktu zmienia się przy każdym
podbiciu wersji z założenia**. Bez `make print-installer-medium` byłoby to złamanie
powtarzalne; z nim jest jednorazowe. Nowy cel jest właśnie tym, co zmienia to z krwawienia w
jedno cięcie — i dlatego należy do zmian dodających, a nie jest kosmetyką.

**Warunek wydania:** poprawić `docs/install.md`, `ROADMAP.md:185`, `docs/plan-do-sprzetu.md:37`
i `docs/ci.md` **w tym samym wydaniu**. Wersja, która przenosi artefakt i zostawia dokumentację
wskazującą stary, jest gorsza niż brak wersji.

### 5.2 Czy przypięcie klucza upstreamu (C-1) jest łamiące dla kogoś, kto budował własne obrazy?

**TAK, ale wąsko — i to trzeba powiedzieć precyzyjnie, bo szeroka odpowiedź w obie strony
byłaby nieprawdziwa.**

**NIE łamie** konfiguracji domyślnej. `init_binary_repo()` w `src/cook/fetch_repo.rs` dodaje
**dokładnie jedno** zdalne repozytorium — `crate::REMOTE_PKG_SOURCE`, czyli
`https://static.redox-os.org/pkg` (`src/lib.rs:11`) — a przypięta wartość ma być kluczem
właśnie tego hosta. Cztery świadectwa (żywy host, wcześniejszy cache w tym drzewie, migawki
archive.org z 2023 i 2024, wszystkie bajt w bajt) są **cudzym pomiarem**: tabela stoi w
`keys/README.md:82+` na `fix/p0-audit-findings` oraz w opisie `2c836aef5`. Zweryfikowałem, że
ta tabela i procedura tam są; samych świadectw nie powtarzałem — wartość klucza
**[NIEZWERYFIKOWANE]**. Kto buduje domyślnie, ten zauważy jedynie, że klucz przestał być
pobierany.

**ŁAMIE trzy klasy przypadków**, wszystkie w kodzie, nie w domysłach:

1. **Własna kopia repozytorium pakietów.** `pin_upstream_key` przechodzi
   `for (_, remote) in repo.remote_map.iter_mut()` i **bezwarunkowo zapisuje** przypięte bajty
   do `pub_key_<nazwa>.toml` **każdego** zdalnego repozytorium, przy **każdym** uruchomieniu.
   Kto przestawił `REMOTE_PKG_SOURCE` na własne lustro z pakietami podpisanymi własnym
   kluczem, temu ten klucz jest nadpisywany kluczem upstreamu i `pkgar::extract` odmawia.
   **Nie ma zmiennej środowiskowej ani opcji, która by to wyłączyła** — `UPSTREAM_PUBKEY_PIN`
   jest stałą `const`, a zapis bezwarunkowy. Jedyne wyjście to edycja
   `keys/upstream-redox-pkg.pub.toml`. To jest dokładnie *„ktoś, kto budował własne obrazy"*
   z pytania.
2. **Uruchomienie spoza katalogu głównego / niepełny checkout.** `UPSTREAM_PUBKEY_PIN` to
   ścieżka **względna** (`"keys/upstream-redox-pkg.pub.toml"`), a przy błędzie odczytu funkcja
   **panikuje**. Wcześniej ta sama sytuacja kończyła się pobraniem klucza i budowaniem dalej.
3. **Istniejące drzewo budowania z innym kluczem w cache'u.** Teraz budowanie pada na
   ekstrakcji. **To jest zachowanie zamierzone i poprawne** — ten przypadek *jest* podatnością —
   ale z punktu widzenia użytkownika to przebieg, który wczoraj był zielony, a dziś nie jest.

**Wniosek do wydania:** klasyfikuję jako **łamiące**, wpisuję do informacji o wydaniu z opisem
klasy 1 i procedurą ponownego przypięcia (`keys/README.md` §3 już ją zawiera: potwierdź nową
wartość z więcej niż jednego źródła, zmień w **osobnym** commicie, nie łącz z niczym innym).
Samo w sobie nie przesądza numeru — B-1 i B-2 i tak wymuszają `0.3.0` — ale przemilczenie tego
w informacjach o wydaniu byłoby wprowadzaniem w błąd.

### 5.3 Czy zmiana kolejności zapisu ESP/root w instalatorze jest łamiąca?

**NIE dla użytkownika instalatora. TAK jako zmiana zachowania funkcji publicznej — do
odnotowania, ale nie do podbicia MINOR-u.**

Co się zmieniło (`eos-installer!3`, `src/installer.rs`): `with_whole_disk` zapisywał ESP i
`BOOTX64.EFI` **przed** systemem plików root. Instalacja przerwana pomiędzy zostawiała dysk z
poprawnym GPT i ESP wyglądającym na rozruchowy, wskazującym system, którego nigdy nie zapisano —
firmware ładuje bootloader i ląduje donikąd. Teraz RedoxFS idzie pierwszy, ESP po nim; zapis
ESP wydzielono do `write_efi_partition`.

Dlaczego **nie** łamiące dla użytkownika:

- Żaden udokumentowany kontrakt nie obiecywał kolejności zapisu. Obiecywany był **wynik**:
  dysk, z którego da się uruchomić system.
- Poprzednia kolejność nie miała działającego przypadku do zepsucia. Miała przypadek
  **mylący**: „wygląda na zainstalowane, a nie jest". Nowa daje „widocznie niezainstalowane" —
  firmware nie znajduje wpisu rozruchowego, spada na następne urządzenie (pendrive, z którego
  startowano) i operator uruchamia instalator ponownie.
- Zmierzone w obie strony (opis MR-a), zabijając instalator na tym samym etapie
  (`timeout -s KILL 5`) i oglądając obszar ESP **pod offsetem 1 MiB**, a nie przeszukując cały
obraz:
  stary kod → `ESP: FAT12, 1x BOOTX64`; nowy → `ESP: no filesystem, 0x BOOTX64`; instalacja
  ukończona nadal daje FAT12 z dokładnie jednym wpisem BOOTX64. Pierwsza wersja tego testu
  przeszukiwała cały obraz 1,4 GB i trafiała w łańcuch znaków **wewnątrz systemu plików root**
  (offset ~263 MB) — test był zły, nie zmiana. To odnotowuję, bo bez zawężenia do ESP dowód
  by nie istniał.

Co **jednak** trzeba wpisać do informacji o wydaniu (to jest crate biblioteczny — `[lib]
name = "redox_installer"`, a `with_whole_disk` jest `pub`):

- **Nowa ścieżka błędu po powodzeniu callbacku.** Kod brzmi teraz
  `let result = with_redoxfs(...)?;` → `DiskWrapper::open(disk_path.as_ref())?` →
  `write_efi_partition(...)?` → `Ok(result)`. Wartość `T` jest zwracana **dopiero jeśli zapis
  ESP też się powiedzie**. Wywołujący, którego callback się powiódł, może teraz dostać `Err`
  tam, gdzie wcześniej dostawał `Ok`. Dysk jest otwierany ponownie, bo `with_redoxfs` musi
  przejąć swój wycinek (`D: Disk + Send + 'static`, wątek montujący).
- **Kolejność efektów ubocznych widziana z callbacku.** Konsument, którego callback zakładał
  istnienie ESP w trakcie działania, nie znajdzie go już.

I to, co MR mówi wprost, a co należy powtórzyć, żeby nikt nie przeczytał więcej, niż napisano:
**to nie zachowuje poprzedniego systemu operacyjnego.** GPT jest zapisywany, zanim którakolwiek
partycja może zostać wypełniona, więc stara tablica partycji znika dużo wcześniej, a nowy root
i tak nadpisuje stare dane. Żadna kolejność tych zapisów nie kupi „nadal uruchamia to, co było".

### 5.4 Czy odmowa instalacji na dysku 4Kn jest łamiąca, skoro wcześniej „działała" (błędnie)?

**NIE.** I to jest przypadek, w którym słowo „działała" trzeba zakwestionować, zanim odpowie
się na pytanie.

Stan sprzed zmiany, zmierzony z diffa `eos-installer!2`:

```rust
// src/disk_wrapper.rs:27-28 — gałąź `master`, czyli stan sprzed MR !2. Cytat dosłowny.
// TODO: get real block size: disk_metadata.blksize() works on disks but not image files
let block_size = 512;
```

i w `src/installer.rs:604-610` (ten sam stan, cytat dosłowny — ramię `_` jest blokowe,
nie jednolinijkowe; wcześniejsza wersja tego dokumentu skracała je i przez to zmyślała cytat):

```rust
let gpt_block_size = match block_size {
    512 => gpt::disk::LogicalBlockSize::Lb512,
    _ => {
        // TODO: support (and test) other block sizes
        bail!("block size {block_size} not supported");
    }
};                          // ← to ramię `_` było NIEOSIĄGALNE
```

Skoro `block_size` była **stałą 512**, ramię `_` nie mogło się nigdy wykonać. Na dysku 4Kn
instalator **nie odmawiał**: rozkładał GPT na rozmiarze sektora, którego napęd nie ma, i
produkował tablicę partycji, **której firmware nie potrafi odczytać**. Kontrola, która może
tylko przejść, nie jest kontrolą.

Dlatego „wcześniej działała" nie jest prawdziwym opisem. Wcześniej **kończyła się kodem 0 i
zostawiała nierozruchowy dysk**. Nie ma tu działającego zachowania, które odmowa psuje —
kontrakt („zainstalowany, uruchamialny system") nigdy na 4Kn nie był spełniony. Zmiana
zamienia **cichą korupcję na jawny błąd**, a to jest definicja poprawki, nie złamania.

Wzmacnia to intencja utrwalona w samym kodzie: odmowa **była już napisana** (ramię `bail!`) —
brakowało jej tylko osiągalności. `gpt_logical_block_size` wydzielono właśnie po to, żeby dało
się ją **przetestować**, i testy pilnują kierunku: `refuses_4kn_until_it_is_supported` wymaga,
by komunikat wymieniał odrzucony rozmiar, a `refuses_nonsense_sizes` odrzuca `0, 1, 513, 1024,
8192` (oba w `src/installer.rs`, `mod block_size_tests` dodany przez MR !2). Kto zmapuje 4096 na
`Lb4096` bez poprawienia arytmetyki — `src/installer.rs:613`:
`let gpt_reserved = 34 * 512; // GPT always reserves 34 512-byte sectors`, a wszystkie
przesunięcia partycji liczone są w jednostkach 512-bajtowych — temu ten test padnie.

**Co jednak zmienia się w API i musi być odnotowane.** `DiskWrapper::open` jest `pub` i zyskuje
tryby błędu, których wcześniej mieć nie mógł, bo nic nie pytał urządzenia:

- Redox — `st_blksize` (wypełniany przez sterownik blokowy z samego urządzenia); **`0` jest
  błędem**, nie pretekstem do powrotu do 512,
- Linux, urządzenie blokowe — `ioctl(BLKSSZGET)`; niepowodzenie `ioctl` daje `Err`, wartość
  `<= 0` daje `Err`. Świadomie **nie** `st_blksize` (tam to podpowiedź preferowanego I/O, a nie
  logiczny rozmiar sektora, w którym GPT liczy LBA) i **nie** `BLKPBSZGET` (fizyczny: napęd
  512e zgłasza 4096 fizyczne / 512 logiczne, a GPT idzie za logicznym),
- wszystko inne, w tym **każdy plik obrazu** — 512.

Zwięźle: **odmowa nie jest łamiąca; nowy tryb błędu na funkcji publicznej jest zmianą
zachowania i idzie do informacji o wydaniu.** Klasa: PATCH.

**Czego to NIE dowodzi**, i sam MR to mówi: zachowanie wobec **prawdziwego** urządzenia 4Kn nie
zostało zweryfikowane. W kontenerze budowania nie ma urządzeń pętlowych (`modprobe`, `/dev/loopN`),
więc `losetup --sector-size 4096` nie da się uruchomić. To jest `R-607b`, wiersz „na gołym
sprzęcie" w M1.

---

## 6. Podsumowanie decyzji

| Repozytorium | Obecna | **Proponowana** | Czynnik przesądzający |
|---|---|---|---|
| `e-os/e-os` | `v0.2.0` (tag); obraz mówi `0.1.0` | **`v0.3.0`** | trzy zmiany łamiące (B-1 bootloader fail-closed, B-2 nazwa nośnika, B-3 przypięcie klucza); przed 1.0 łamiące → MINOR |
| `e-os/eos-installer` | `0.2.42` (numer upstreamu) | **`0.2.42+eos.1`** | fork typu C konsumowany po rewizji; podbicie kolidowałoby z wydaniami upstreamu. Niezależnie byłoby `0.3.0` |
| `e-os/eos-pkgutils` | `0.3.1` (numer upstreamu) | **`0.3.1+eos.1`** | jw.; dodatkowo `^0.3.1` w instalatorze dopasowuje metadane budowania, a nie dopasowałoby pre-release. Niezależnie byłoby `0.4.0` |

### Warunki konieczne przed tagowaniem `v0.3.0`

Każdy z nich jest sprawdzalny; żaden nie jest opinią.

1. **G-17 domknięty do trzech zgodnych liczb.** `config/x86_64/eos.toml`,
   `config/aarch64/eos.toml` i `mk/config.mk:185` = `0.3.0`. `config/base.toml` **zostawić** —
   to wersja upstreamu, nadpisywana (§2.5). Sprawdzenie: bramka porównująca tag z `VERSION_ID`
   w obu konfiguracjach. **Kolejność wymuszona:** człon `mk/config.mk` da się spełnić dopiero
   **po** scaleniu M1, bo `EOS_VERSION` dziś na `main` nie istnieje (§2, §2.5). Przed M1 warunek
   redukuje się do dwóch konfiguracji obrazu.
2. **Dokumentacja nośnika poprawiona.** `grep -c 'redox-live.iso' docs/install.md` → **0**;
   to samo dla `ROADMAP.md:185`, `docs/plan-do-sprzetu.md:37` i `docs/ci.md:100`. Stan
   wyjściowy zmierzony dziś na `feat/m1-bootable-medium`: `docs/install.md` **3**,
   `ROADMAP.md` **5**, `docs/plan-do-sprzetu.md` **1**, `docs/ci.md` **1** trafienie na
   `redox-live`. Warunek dotyczy wyłącznie wydania **po** scaleniu M1 — przed nim te
   dokumenty opisują plik, który naprawdę istnieje (§5.1).
3. **Jedno narzędzie wydań.** Usunąć `.releaserc.json` albo
   `release-please-config.json` + `.release-please-manifest.json`. Dwa naraz to dwa różne
   numery na to samo wydanie.
4. **Gitleaks zielony na `main`.** Dziś `main` i cztery gałęzie mają **FAIL** na dwóch plikach
   kluczy **publicznych**; allowlista istnieje wyłącznie na `fix/p0-audit-findings` i
   `chore/security-hardening`. Scalenie !3 to zamyka.
5. **Rozjazd rewizji `pkgutils` rozstrzygnięty** (§4.3): `eos-installer` łata `redox-pkg` na
   `cf36a01b`, receptura przypina `e28063ee`. Zrównać albo świadomie uzasadnić.
6. **Kolejność scalania.** Stos A: wystarczy **!3** (zawiera !1 i !2). Potem **!4** (rozłączny).
   Potem M1 (`docs/installer-design` ⊂ `feat/m1-bootable-medium`), który dziś nie ma MR-a.

### Czego nie zweryfikowano

- Zachowania semantic-release przy zmianie łamiącej z wersji `0.x` — **[NIEZWERYFIKOWANE]**.
- Czy `pkg-lib` kompilował się poza Uniksem **przed** `eos-pkgutils!3` — **[NIEZWERYFIKOWANE]**.
  Po zmianie na pewno nie (bezwarunkowe `use std::os::unix::fs::…`).
- Zachowania instalatora wobec prawdziwego urządzenia 4Kn — **[NIEZWERYFIKOWANE]**, `R-607b`.
- Kodu wyjścia `make build/x86_64/eos/redox-live.iso` po zmianie nazwy — pochodzi z opisu
  commita `50d2c2c2e`; samodzielnie zmierzyłem jedynie **brak reguły** produkującej tę ścieżkę.
- Wartości przypiętego klucza upstreamu — **[NIEZWERYFIKOWANE]**. Cztery świadectwa czytałem
  z `keys/README.md:82+` i opisu `2c836aef5`, nie powtarzałem ich (§5.2).
- Demonstracji zapisu przez dowiązanie w `eos-pkgutils!3` (plik 868 992 B) —
  **[NIEZWERYFIKOWANE]**, z opisu MR-a; zweryfikowany jest kod, nie przebieg ataku (§4.2).
- Pomiarów ESP z `eos-installer!3` i `!2` (`timeout -s KILL 5`, FAT12 / brak systemu plików) —
  z opisów MR-ów; zweryfikowany jest kształt kodu i testy, nie same uruchomienia (§5.3, §5.4).
- Wzrostu domknięcia receptur 52 → 77 w B-4 — z opisu `f8ac1b09b`; sam skryptu nie uruchamiałem.
- Żadnej bramki CI nie da się dziś uruchomić zdalnie: GitLab zwraca `ci_quota_exceeded`,
  GitHub Actions nie tworzą uruchomień. Wszystkie wyniki bramek w tym dokumencie są lokalne
  albo cytowane z opisów MR-ów.
- Żadna z powyższych wersji nie została nigdzie zapisana ani otagowana. **Nic nie jest
  scalone** — wszystkie jedenaście MR-ów jest otwartych, a stos M1 nie ma nawet MR-a. Ten
  dokument jest propozycją; nic nie zostało wykonane.
