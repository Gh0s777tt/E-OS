# Macierz zgodności — co z czym działa

- **Zmierzone:** 2026-08-30, na gałęzi `feat/m1-bootable-medium` (bieżące drzewo robocze).
- **Metoda:** odczyt plików przypięć w drzewie + trzy bramki uruchomione lokalnie
  (`eos-repos.sh pins`, `ci-integrity.sh`, `eos-source-rules.sh`) + jeden eksperyment
  odtwarzający awarię `--locked` (§6.1). Nic tutaj nie jest przepisane z podsumowań.
- **Czego ten dokument NIE jest:** listą życzeń ani planem. Jeśli coś jest przewidywaniem,
  a nie pomiarem, jest to oznaczone `[PROGNOZA]` albo `[NIEZWERYFIKOWANE]`.
- **Kontrola adwersaryjna (2026-08-30, ta sama data).** Przebiegi `eos-repos.sh pins`,
  `ci-integrity.sh`, `eos-source-rules.sh`, `eos-check-repo-types.py`, `gitleaks detect`
  oraz trzyprzebiegowy eksperyment z §6.1 powtórzone niezależnie — wszystkie liczby zgodne.
  Cytaty plik:linia sprawdzone w drzewie. Poprawione przy tej okazji: wiersz `recipes/libs/mpc`
  w §8.1 (to **nie** jest nowa receptura, tylko `+14` linii do istniejącej), liczba przepisanych
  odnośników zewnętrznych w §8.3 (**siedem**, nie osiem), zakres `.github/workflows/` w §5.1,
  dowód na allowlistę gitleaks w §7 oraz cytat `cb8ae7b` w §4 (pochodzi z `ROADMAP.md`, nie
  z kodu). Dopisana szósta powierzchnia przypięcia — skróty tarballi — i sprzeczność między
  docstringiem `eos-check-tar-pins.py` a `src/cook/fetch.rs:118-124` (§1).

> ## ⚠️ To jest stan **PRZED** scaleniem czegokolwiek
>
> Dziewięć MR-ów jest otwartych, **zero scalonych**. Wszystko poniżej opisuje drzewo takie,
> jakie jest teraz — nie takie, jakie będzie po `main`. Sekcja [§8](#8-co-się-zmieni-po-scaleniu)
> rozpisuje, którą komórkę tej macierzy przesuwa który MR.
>
> Druga rzecz, którą trzeba wiedzieć od razu: **CI nie egzekwuje dziś żadnej z tych bramek.**
> GitLab CI zwraca `ci_quota_exceeded` (pipeline `2803590199`, wszystkie zadania 0 s),
> a GitHub Actions nie tworzą uruchomień. Jedynym miejscem, gdzie bramki faktycznie się
> wykonują, jest maszyna kontrybutora. Każdy „PASS" w tym dokumencie to przebieg lokalny,
> nie zielony pipeline.

---

## 1. Sześć powierzchni przypięcia — i co która trzyma

Przypięcia nie leżą w jednym pliku i **nie pilnują tego samego artefaktu**. To jest źródło
większości rozjazdów w tym projekcie, więc najpierw rozdział ról:

| # | Powierzchnia | Co przypina | Kto to konsumuje | Bramka |
|---|---|---|---|---|
| 1 | `repos.toml` | 30 repozytoriów: typ, rola, hosty, `pinned_branch`, `pinned_rev` | `scripts/eos-repos.sh` (clone/update/status/pins/mirrors) | `pin-check` (`pins --strict`) |
| 2 | `recipes/*/*/recipe.toml` — pola `git`/`branch`/`rev` | **źródło, z którego kompiluje się OBRAZ** | cookbook (`repo`, `repo_builder`) | `pin-check`, `ci-integrity.sh` kontrola 6 |
| 3 | `Cargo.toml` + `Cargo.lock` w korzeniu | **narzędzia HOSTA** (`redox_cookbook`: `repo`, `repo_builder`, `cookbook_redoxer`) | `cargo` na maszynie budującej | `--locked` w `verify.sh` i `ci.yml` — **oba pliki istnieją tylko na `chore/security-hardening`**; w `.gitlab-ci.yml`, który jest na wszystkich gałęziach, `--locked` **nie ma** (§6.2) |
| 4 | `tools/eos-repo-sign/Cargo.toml` + `Cargo.lock` | narzędzie podpisujące `repo.toml` (ed25519 + ML-DSA-65) | `cargo`, budowane osobno (własny `[workspace]`) | `--locked`, `cargo-deny`, clippy `-D warnings` |
| 5 | `rust-toolchain.toml` + `mk/prefix.mk:29` | toolchain hosta i toolchain krzyżowy Redoksa | `rustup` / `make prefix` | brak bramki porównującej te dwa (§5) |
| 6 | `recipes/*/*/recipe.toml` — `[source] tar` + `blake3`/`sha256` | **archiwa stron trzecich**, nie git | cookbook (`src/cook/fetch.rs`) | **żadna na tej gałęzi**; kontrola 12 (`eos-check-tar-pins.py`) przychodzi dopiero z `!3` — §8.1 |

Powierzchnia 6, zmierzona dziś dwoma niezależnymi sposobami. Zgrubnie: **397 źródeł `tar =`
w `recipes/`, z czego 178 ma `blake3` albo `sha256`**. Dokładnie — przez uruchomienie skryptu
kontroli 12 z `fix/p0-audit-findings` na **bieżącym** drzewie (kopia do katalogu tymczasowego,
bez przełączania gałęzi): **dokładnie jedna receptura w domknięciu `config/*/eos.toml` ciąga
tarball bez skrótu — `mpc` (`recipes/libs/mpc/recipe.toml`)**, exit 1; poza domknięciem siedem
kolejnych (`bash-completion`, `iperf3`, `jq`, `libinotify-stub`, `liburcu`, `nginx`,
`sdl2-image`) i te skrypt raportuje jako doradcze.

Jedno zastrzeżenie, bo trafiłem na sprzeczność i jej nie wygładzam. Docstring
`scripts/eos-check-tar-pins.py` (na `fix/p0-audit-findings`) uzasadnia kontrolę zdaniem, że
`src/cook/fetch.rs` przy braku `blake3` „ostrzega i idzie dalej". W drzewie tego **nie widać**:
w bieżącym drzewie `src/cook/fetch.rs:118-124` (na `main` te same linie to `:119-121`, na
`fix/p0-audit-findings` `:119-121` — plik różni się między gałęziami, ale ta gałąź kodu nie)
woła `bail_other_err!` z komunikatem `Please add blake3 = … to <recipe>`, czyli **przerywa**. Ścieżka, na której to
faktycznie tylko ostrzega — jeśli istnieje — jest stąd `[NIEZWERYFIKOWANE]`; ryzyko z §1
wiersz 6 opieram na braku bramki, nie na tym zdaniu z docstringa.

Powierzchnie 2 i 3 opisują **dwa różne artefakty**: to, co jedzie na urządzeniu, i to, co
buduje/pakuje na maszynie budującej. Zgodność między nimi nie jest automatyczna i dziś jej
nie ma w trzech przypadkach — [§4](#4-narzędzia-hosta-vs-obraz--jedyny-realny-rozjazd-wersji).

---

## 2. `repos.toml` — 30 repozytoriów, cztery typy

Typ pochodzi z pola `type` w `repos.toml` i **nie** jest zdaniem w dokumencie; kontrola 7
w `scripts/ci-integrity.sh` porównuje go z `CLAUDE.md` §11 i **wychodzi niezerowo** przy rozjeździe.
Zadanie `integrity` woła ją w `.gitlab-ci.yml:30-36` — ale ten pipeline dziś nie wstaje
(`ci_quota_exceeded`), więc jedynym miejscem, gdzie ta kontrola cokolwiek zatrzymuje, jest
przebieg lokalny.

Zmierzone dziś (`python3 scripts/eos-check-repo-types.py`):
`repo-types: OK — 30 repozytoriów, typy zgodne z CLAUDE.md §11`

| Typ | Znaczenie | Reguła | Ile | Przypięte w recepturze |
|---|---|---|---|---|
| **A** | komponent własny E-OS | pełne standardy, wolno projektować | 6 | 4 z 6 |
| **B** | vendorowane lustro `redox-os` (**RO**) | nigdy nie edytuj ręcznie | 10 | 10 z 10 |
| **C** | fork z łatkami | utrzymuj rebaseowalność | 12 | 12 z 12 |
| **D** | repozytorium pakietów (**RO**) | publikacja tylko skryptem | 2 | 0 z 2 |

**Cztery repozytoria bez przypięcia w recepturze** (`pinned_in_recipe = false`) — i dlaczego:

| Repo | Typ | Dlaczego nie jest przypięte | Gdzie leży jego wersja |
|---|---|---|---|
| `E-OS` | A | to **jest** to repozytorium | tag gita (`v0.2.0`) — patrz §5.2 |
| `eos-ui` | A | zależność gitowa `eos-notes`/`eos-control`, nie osobny pakiet obrazu | `Cargo.lock` **każdego konsumenta osobno** — nie w tym drzewie |
| `eos-pkg-x86_64` | D | artefakty `.pkgar`, wynik a nie wejście | indeks `repo.toml` podpisany kluczem z `keys/eos-repo-sign.pub.toml` |
| `eos-pkg-aarch64` | D | jw. | jw. |

> `eos-ui` jest jedynym węzłem grafu bez krawędzi w tym drzewie: nie ma go w żadnej recepturze
> ani w `Cargo.toml`. Czym dokładnie jest w produkcie — `[NIEZWERYFIKOWANE]` z poziomu tego
> repozytorium; trzeba przeczytać `Cargo.lock` po stronie `eos-notes`/`eos-control`.

---

## 3. Macierz przypięć obrazu — 26 receptur

Kolumny `PIN` i `TIP` z przebiegu `bash scripts/eos-repos.sh pins` (2026-08-30, z siecią).
Wynik zbiorczy: **`---- pins ok=25 drift=1 (non-allowlisted=0) split-pin=0 ----`**. Jeden dryf jest **celowy i wpisany** na `scripts/pin-allowlist.txt` wraz z warunkiem usunięcia (`eos-installer`, `R-604a` czeka na dowód end-to-end); `split-pin` liczy repozytoria, w których receptura i manifest wskazują **różne** rewizje — to nigdy nie jest zamierzone i nie da się tego wyciszyć listą.

Zweryfikowałem osobno, skryptem porównującym oba pliki, że **`pinned_rev` i `pinned_branch`
w `repos.toml` zgadzają się z polami `rev`/`branch` w recepturze dla wszystkich 26 pozycji**
(0 rozjazdów). Skrócone rewizje poniżej to 10 znaków — pełne 40 leży w `repos.toml`.

### 3.1 Rdzeń krytyczny (typ C) — bez tego system nie wstaje

| Repo | Receptura | Gałąź | Rewizja | vs tip |
|---|---|---|---|---|
| `eos-base` | `recipes/core/base` | `eos-july` | `816546df2a` | OK |
| `eos-bootloader` | `recipes/core/bootloader` | `eos-rebased` | `87b214b5b4` | OK |
| `eos-kernel` | `recipes/core/kernel` | `eos-july` | `68a510358d` | OK |
| `eos-redoxfs` | `recipes/core/redoxfs` | `master` | `58824d70a0` | OK |
| `eos-relibc` | `recipes/core/relibc` | `eos-july` | `c9345130e2` | OK |

### 3.2 Rdzeń (typ B i C)

| Repo | Typ | Receptura | Gałąź | Rewizja | vs tip |
|---|---|---|---|---|---|
| `eos-coreutils` | B | `recipes/core/coreutils` | `master` | `049a259565` | OK |
| `eos-extrautils` | B | `recipes/core/extrautils` | `master` | `afbac08e38` | OK |
| `eos-installer` | C | `recipes/core/installer` | `master` | `c8d32ad39e` | OK |
| `eos-ion` | B | `recipes/core/ion` | `master` | `1da444c867` | OK |
| `eos-netdb` | B | `recipes/core/netdb` | `master` | `8977054ec6` | OK |
| `eos-netutils` | B | `recipes/core/netutils` | `master` | `d3f5784888` | OK |
| `eos-pkgar` | C | `recipes/core/pkgar` | `master` | `78e644ad5f` | OK |
| `eos-pkgutils` | C | `recipes/core/pkgutils` | **`eos`** | `e28063ee2f` | OK |
| `eos-userutils` | C | `recipes/core/userutils` | `eos-july` | `a43ba3e530` | OK |

> **Rozkład gałęzi w całym zbiorze 26:** `master` ×16, `main` ×4, `eos-july` ×4
> (`eos-base`, `eos-kernel`, `eos-relibc`, `eos-userutils`), `eos-rebased` ×1
> (`eos-bootloader`), `eos` ×1 (`eos-pkgutils`). Dwie ostatnie to jedyne nazwy własne
> w zbiorze i obie coś znaczą: `eos` niesie kliencką weryfikację podpisu manifestu (`R-703`).
> Ta sama rewizja `e28063ee2f` jest przypięta **drugi raz**, w `Cargo.toml:46` — §4.

### 3.3 Warstwa graficzna i aplikacje własne

| Repo | Typ | Receptura | Gałąź | Rewizja | vs tip |
|---|---|---|---|---|---|
| `eos-orbclient` | B | `recipes/demos/orbclient` | `master` | `be1d51efce` | OK |
| `eos-orbdata` | C | `recipes/gui/orbdata` | `master` | `bda3e43094` | OK |
| `eos-orbital` | C | `recipes/gui/orbital` | `master` | `38226c74b0` | OK |
| `eos-orbterm` | B | `recipes/gui/orbterm` | `master` | `c2a1026a0f` | OK |
| `eos-orbutils` | C | `recipes/gui/orbutils` | `master` | `8ad7cd8fa8` | OK |
| `eos-liborbital` | B | `recipes/libs/liborbital` | `master` | `76ba2e79ac` | OK |
| `eos-guard` | A | `recipes/gui/eos-guard` | `main` | `0626360752` | OK |
| `eos-notes` | A | `recipes/gui/eos-notes` | `main` | `9f9eae6e7a` | OK |
| `eos-sysmon` | A | `recipes/gui/eos-sysmon` | `main` | `b50f81a8b7` | OK |
| `eos-control` | A | `recipes/gui/eos-control` | `main` | `40dc67fde3` | OK |

### 3.4 Biblioteki i narzędzia deweloperskie

| Repo | Typ | Receptura | Gałąź | Rewizja | vs tip |
|---|---|---|---|---|---|
| `eos-redox-fatfs` | B | `recipes/libs/redox-fatfs` | `master` | `26caa09089` | OK |
| `eos-redoxer` | B | `recipes/dev/redoxer` | `master` | `974c1482c2` | OK |

### 3.5 Przypięcie to nie to samo co obecność w obrazie

`pins --strict` może być zielone, a poprawki i tak **nie ma w obrazie**. Tak zginęła kliencka
weryfikacja podpisu w `U-164` (`ROADMAP.md:287`, znalezisko `R-F20`). Decydują dwa dodatkowe
pliki, oba **śledzone** (i to była poprawka — wcześniej były gitignorowane; `.gitignore:3-6`
i `:19-20` nazywają obie zmiany: `cookbook.lock` w `U-168`, `.config` w `U-169`):

| Plik | Co ustala | Stan zmierzony |
|---|---|---|
| `.config` | `REPO_BINARY?=1` — cookbook **domyślnie pobiera gotowy pakiet** zamiast kompilować | `1` |
| `cookbook.lock` | wyjątki per przepis: `fsrule = "source"` | 28 wpisów |

Bramka: `scripts/eos-source-rules.sh`, wołana przez kontrolę 6 w `ci-integrity.sh`.
Zmierzone dziś: `source-rules: OK — all 26 E-OS-forked recipes are set to build from source`.

Gdyby `REPO_BINARY=1` i brakowało wyjątku, obraz dostałby **binarkę z `static.redox-os.org`**
mimo poprawnie przypiętego forka. Skrypt wywodzi listę z drzewa (`grep` po URL-u forka
w recepturach), a nie z ręcznej listy — dlatego receptura dodana później nie znika po cichu.

---

## 4. Narzędzia hosta vs obraz — jedyny realny rozjazd wersji

Korzeniowy `Cargo.toml` buduje `redox_cookbook` — silnik, który **produkuje** pakiety i pisze
manifest. Receptury budują to, co je **czyta** na urządzeniu. Zmierzone z `Cargo.lock`
(numery linii z bieżącej gałęzi):

| Zależność w `Cargo.toml` | Host buduje z | Obraz buduje z | Rewizja w `Cargo.lock` | Zgodne? |
|---|---|---|---|---|
| `redox-pkg` (`Cargo.toml:46`) | **`eos-pkgutils`** | `eos-pkgutils` `e28063ee2f` | `e28063ee2f` (`Cargo.lock:860`) | ✅ **tak** |
| `pkgar`, `pkgar-core`, `pkgar-keys` | upstream `redox-os` | `eos-pkgar` `78e644ad5f` | `ee2bcb2af9` (`Cargo.lock:706/719/730`) | 🔴 **nie** |
| `redox_installer` | upstream `redox-os` | `eos-installer` `c8d32ad39e` | `1c2534e44c` (`Cargo.lock:898`) | 🔴 **nie** |
| `redoxer` | upstream `redox-os` | `eos-redoxer` `974c1482c2` | `e4c40952b1` (`Cargo.lock:921`) | 🔴 **nie** |

**Co to znaczy w praktyce.** `redox-pkg` został naprawiony (`V2-MS15`, komentarz nad
`Cargo.toml:46` opisuje dokładnie ten powód: producent i konsument manifestu były różnymi
bazami kodu). Trzy pozostałe wciąż są rozjechane. Najostrzejszy przypadek to `pkgar`: fork
niesie poprawkę `cb8ae7b` (`R-F03`) usuwającą panikę osiągalną przez atakującego na skróconym
`.pkgar` — **źródłem tego zdania jest `ROADMAP.md:275`, nie kod**: forka nie ma w tym drzewie,
więc treść commitu `cb8ae7b` jest stąd `[NIEZWERYFIKOWANE]`. Po stronie hosta
`src/cook/cook_build.rs:119` woła `pkgar_core::PackageSrc::read_entries`
**po stronie hosta**, czyli dokładnie na nieutwardzonej ścieżce. Utwardzony parser jedzie na
urządzeniu, nieutwardzony na maszynie budującej.

**Powtarzalność budowania nie jest tym zagrożona** — `Cargo.lock` przypina konkretne commity
dla wszystkich pięciu. Zagrożona jest zgodność producenta z konsumentem.

**Rozkład hostów źródłowych** (zmierzony przez `git grep` po gałęziach): na
`feat/m1-bootable-medium`, `main` i czterech innych gałęziach **26/26 receptur ciąga z
`github.com/Gh0s777tt`**, czyli z **lustra**, mimo że ADR-0001 ustala GitLab jako źródło
prawdy. Jedyna gałąź, gdzie jest odwrotnie (26/26 z `gitlab.com/e-os`), to
`fix/p0-audit-findings` — patrz §8.

### 4.1 `tools/eos-repo-sign` — druga skrzynka, inne reguły

| Cecha | Wartość | Dowód |
|---|---|---|
| Wersja | `0.1.0` | `tools/eos-repo-sign/Cargo.toml:3` |
| Edition | `2021` (korzeń ma `2024`) | `Cargo.toml:4` vs korzeń `Cargo.toml:5` |
| Workspace | **własny** — nie należy do workspace'u cookbooka | `[workspace]` w linii 11 |
| Zależności gitowe | **zero** | `grep -c 'source = "git' tools/eos-repo-sign/Cargo.lock` → `0` |
| Zależności | `ml-dsa 0.1`, `ed25519-dalek 2`, `rand_core 0.6`, `signature 2` | linie 14–17 |

Bo nie ma tu żadnego `git+`, `--locked` kupuje co innego niż w korzeniu: **nie** egzekwowanie
pinów (nie ma czego), tylko powtarzalność — semver-kompatybilny bump nie wejdzie nieprzejrzany.
To jedyny manifest trzymany w pełnym rygorze: `fmt --check`, `clippy -D warnings`, `cargo-deny
check` (pełne: advisories + licenses + bans + sources), progi pokrycia. Korzeniowy jest
vendorowany i celowo ma tylko `test` + `check advisories`.

---

## 5. Toolchain

### 5.1 Rust

| Gdzie | Wartość | Rola |
|---|---|---|
| `rust-toolchain.toml:2` | `nightly-2026-05-24` | toolchain **hosta**: `redox_cookbook`, `eos-repo-sign`, wszystkie bramki `cargo` |
| `mk/prefix.mk:29` | `UPSTREAM_RUSTC_VERSION=2026-05-24` | toolchain **krzyżowy** pobierany z `static.rust-lang.org`, buduje kod na `*-unknown-redox` |
| `rust-toolchain.toml:3` | `rust-src`, `rustfmt`, `clippy` | komponenty; `profile = "minimal"` |

Obie daty są dziś **te same** i to nie jest zbieg okoliczności — ale **żadna bramka tego nie
porównuje**: `grep -rn 'UPSTREAM_RUSTC_VERSION\|rust-toolchain' scripts/` nie zwraca nic.
Rozjazd tych dwóch wartości byłby cichy aż do błędu linkowania w `make prefix`.

Zmierzone na siedmiu gałęziach (`main`, `feat/m1-bootable-medium`, `fix/p0-audit-findings`,
`chore/security-hardening`, `chore/repo-restructure`, `chore/docs-rebuild`,
`docs/installer-design`): **wszystkie mają identyczny `channel = "nightly-2026-05-24"`.**
Żaden otwarty MR nie rusza toolchainu.

`ci.yml` **świadomie nie ma osi wersji Rusta** i **nie używa** `dtolnay/rust-toolchain`:
ta akcja eksportuje `RUSTUP_TOOLCHAIN`, które ma pierwszeństwo nad plikiem, więc po cichu
podmieniłaby pin. Instaluje przez `rustup toolchain install` (`ci.yml:164`), które czyta plik;
powód jest zapisany w komentarzu `ci.yml:155-160`. **Uwaga na zakres:** `.github/workflows/`
nie istnieje ani na `main`, ani w bieżącym drzewie roboczym — te osiem workflow'ów leży
**wyłącznie** na `chore/security-hardening` (`git ls-tree -r --name-only main --
.github/workflows/` → pusto). Zdanie powyżej opisuje więc plik z niescalonej gałęzi, nie
bramkę, która dziś gdziekolwiek działa.

### 5.2 Wersja produktu — `G-17`, **NIE naprawione**

Cztery miejsca, trzy różne odpowiedzi:

| Gdzie | Wartość | Co to znaczy |
|---|---|---|
| tag gita | **`v0.2.0`** (2026-08-22, podpisany) | to, co użytkownik pobiera |
| `mk/config.mk:185` | `EOS_VERSION?=0.2.0` | **tylko nazwa pliku** nośnika, i mówi to wprost |
| `config/x86_64/eos.toml:99`, `config/aarch64/eos.toml:97` | `VERSION_ID="0.1.0"` | co system **raportuje o sobie** w `/etc/os-release` |
| `config/base.toml:104` | `VERSION_ID="0.9.0"` | odziedziczone po Redoksie, nie po E-OS |

Piąte miejsce, którego lista `G-17` nie wymienia, a które znalazłem czytając drzewo:
`recipes/other/eos/recipe.toml:17` i `:113` **wpisują `E-OS 0.1.0 Genesis` na sztywno**
w `/usr/bin/eos-welcome` i `/usr/share/eos/eos-release`. Zmiana `VERSION_ID` nie ruszy tych
dwóch — trzeba edytować skrypt receptury.

`mk/config.mk:172-184` jest jedynym z tych miejsc, które **przyznaje się do rozjazdu**
w komentarzu i zawęża swój zakres do nazwy pliku. Wersja **nie jest** wywodzona z gita
świadomie: `git describe` w drzewie budowania zwraca `roadmap-u066`, bo klon, w którym
działa `make`, niesie własne tagi.

**Żadna bramka nie porównuje tych czterech (pięciu) wartości.** `EOS_VERSION` istnieje
**wyłącznie** na `feat/m1-bootable-medium` — na `main` i pięciu innych gałęziach
`grep -c EOS_VERSION mk/config.mk` daje `0`.

---

## 6. Co się psuje, gdy przypięcie się rozjedzie

### 6.1 Świeży przykład: `Cargo.lock` wskazywał GitHuba, `Cargo.toml` GitLaba

To jest udokumentowana awaria z tego projektu i **odtworzyłem ją dzisiaj**, żeby nie opisywać
jej z pamięci. Kopia korzeniowego `Cargo.toml` + `Cargo.lock` w katalogu tymczasowym,
`src/` podlinkowany, toolchain `nightly-2026-05-24`:

| Przebieg | `Cargo.toml` | `Cargo.lock` | Polecenie | Wynik |
|---|---|---|---|---|
| **kontrola negatywna** | GitHub | GitHub | `cargo metadata --locked --offline` | **exit 0** |
| **awaria** | GitLab | GitHub | `cargo metadata --locked --offline` | **exit 101** |
| **to samo bez `--locked`** | GitLab | GitHub | `cargo metadata --offline` | **exit 0**, lock **przepisany** |

Komunikat z przebiegu 2, dosłownie:

```
error: cannot update the lock file .../Cargo.lock because --locked was passed to prevent this
```

Przebieg 3 jest ważniejszy od przebiegu 2. Bez `--locked` cargo **nie zgłasza błędu** — po cichu
przepisuje `Cargo.lock`, wypisując tylko `Locking 1 package…`, i kończy się sukcesem. Po tym
przebiegu plik na dysku wskazywał już GitLaba. **Rozjazd nie znika, tylko przestaje być widoczny.**

### 6.2 Która bramka to łapie — i która nie

| Bramka | Polecenie | Łapie rozjazd `Cargo.lock`? | Gdzie żyje |
|---|---|---|---|
| `verify.sh` etapy `typecheck` / `build` / `test` | `cargo check/build/test --locked` na **obu** manifestach | ✅ **tak** | **tylko** `chore/security-hardening` |
| `ci.yml` zadanie `rust` | `cargo build --locked`, `cargo test --locked` | ✅ **tak** | **tylko** `chore/security-hardening` |
| `.gitlab-ci.yml` zadanie `rust-checks` | `cargo test --manifest-path Cargo.toml` — **bez `--locked`** | 🔴 **nie** | wszystkie gałęzie |
| `pin-check` (`eos-repos.sh pins --strict`) | `git ls-remote` vs `pinned_rev` | 🔴 nie — patrzy na receptury, nie na `Cargo.lock` | wszystkie gałęzie |
| `ci-integrity.sh` kontrola 6 | `eos-source-rules.sh` | 🔴 nie — patrzy na `cookbook.lock` | wszystkie gałęzie |

Sprawdzone: `grep -n -- '--locked' .gitlab-ci.yml` zwraca **wyłącznie** dwa `cargo install
… --locked` (linie 208, 225) — instalację narzędzi, nie budowanie projektu. Identycznie na
`chore/security-hardening`. Czyli: **jedyne bramki, które łapią ten rozjazd, istnieją na
jednej gałęzi, a ta gałąź nie jest scalona.**

Uczciwie: `verify.sh` sam to opisuje w komentarzu nad `stage_typecheck`, i mówi, że `--locked`
kupuje co innego w każdym z manifestów. W korzeniu **trzy z czterech** repozytoriów gitowych są
brane po **gałęzi bez `rev`** (`pkgar`, `installer`, `redoxer`), więc ich głowy przesuwają się
pod manifestem — `--locked` jest tam jedyną rzeczą, która zatrzymuje ciche wchłonięcie ruchu
upstreamu. Policzone z `Cargo.lock`, nie założone: sześć pakietów z czterech repozytoriów.

### 6.3 Pozostałe tryby rozjazdu

| Co się rozjeżdża | Objaw | Bramka | Zmierzony stan |
|---|---|---|---|
| `recipe.rev` vs głowa gałęzi forka | obraz budowany ze starszego kodu, cicho | `pins --strict` | 26 OK, 0 drift |
| `repos.toml pinned_rev` vs `recipe.rev` | dwa źródła prawdy mówią co innego | **brak dedykowanej bramki**; `pins` czyta tylko `repos.toml` | zweryfikowane ręcznie: 26/26 zgodne |
| gałąź forka usunięta / zmieniona nazwa | `BRANCH-GONE:<br>` w `pins` | `pins --strict` | 0 |
| receptura z forkiem bez `fsrule = "source"` | obraz dostaje binarkę upstreamu mimo dobrego pinu (`R-F20`) | `ci-integrity.sh` kontrola 6 | OK, 26/26 |
| `type` w `repos.toml` vs `CLAUDE.md` §11 | do repo stosowane są złe reguły (`U-164`) | `ci-integrity.sh` kontrola 7 | OK, 30 repo |
| fork linkuje forkowany crate **z crates.io** | fork poprawny, pin poprawny, **artefakt zawiera cudzy kod** (`R-F10`, `R-F19`, `R-F20`) | `scripts/eos-fork-linkage.py` | **wymaga rozpakowanych źródeł** — nie da się uruchomić w lekkim CI, tylko w kontenerze budującym |
| `rust-toolchain.toml` vs `mk/prefix.mk:29` | błąd linkowania w `make prefix` | **żadna** | oba `2026-05-24` |
| wersja produktu w 4–5 miejscach | system raportuje inną wersję niż wydana | **żadna** | rozjechane (`G-17`) |

**Dopuszczalny rozjazd** obsługuje `scripts/pin-allowlist.txt` — dziś **pusty**, i plik sam
mówi, że to stan docelowy. Dwa wpisy `R-902` (`eos-control`, `eos-installer`) zostały wyczyszczone
w `U-132` po wykonaniu przebiegu bramki, na który czekały. Wpis w tym pliku musi podawać
**warunek usunięcia**, nie tylko powód.

---

## 7. Stan bramek per gałąź (zmierzony 2026-08-30)

| Gałąź | integrity | pin-check | source-rules | gitleaks | `verify.sh` |
|---|---|---|---|---|---|
| `feat/m1-bootable-medium` | ✅ **PASS (11)** ¹ | ✅ **26 OK / 0 drift** ¹ | ✅ **OK 26/26** ¹ | 🔴 **FAIL** (2 trafienia) ¹ | brak pliku ¹ |
| `main` | PASS ² | — | — | 🔴 FAIL ² | brak pliku ¹ |
| `chore/docs-rebuild`, `chore/repo-restructure`, `docs/installer-design` | PASS ² | — | — | 🔴 FAIL ² | brak pliku ¹ |
| `fix/p0-audit-findings` | — | — | — | ✅ PASS ² | **brak pliku** ¹ — „7/7" to nie `verify.sh` ³ |
| `chore/security-hardening` | — | — | — | ✅ PASS ² | **14 PASS, 0 FAIL, 1 SKIPPED** ² |

> ¹ uruchomione przeze mnie w tej sesji na wypisanej gałęzi — wynik cytowany niżej.
> ² przejęte ze stanu faktycznego przekazanego do tego zadania (pomiar z tego samego dnia).
> **Nie odtwarzałem go**, bo wymagałby przełączania gałęzi, a to zmiana stanu repozytorium.
> Jeden wyjątek: kolumna `gitleaks` **jest** potwierdzona pośrednio dla `main` i dla trzech
> gałęzi z wiersza niżej — ich `.gitleaks.toml` nie ma wpisów `keys/` (pomiar w bloku poniżej),
> a wersja z `main` jest bajt w bajt identyczna z tą w bieżącym drzewie (`diff` po `git show` →
> bez różnic). gitleaks skanuje historię, nie stan gałęzi, więc wynik musi być ten sam
> `FAIL (2)`. Analogicznie `✅ PASS` dla `fix/p0-audit-findings` i `chore/security-hardening`:
> ich konfiguracja, puszczona na tej samej historii, daje `no leaks found`.
>
> ³ **Rozbieżność, którą zgłaszam zamiast wygładzić.** Stan przekazany do tego zadania podaje
> dla `fix/p0-audit-findings` wynik „7/7 PASS". `scripts/verify.sh` na tej gałęzi **nie
> istnieje** — sprawdzone bez przełączania: `git ls-tree -r --name-only fix/p0-audit-findings
> | grep -c '^scripts/verify.sh$'` → `0`. Ten sam pomiar na siedmiu gałęziach daje `verify.sh`
> **wyłącznie** na `chore/security-hardening` (tam też jedyne 8 workflow'ów GitHuba).
> Wniosek: „7/7" pochodzi z innego zestawu bramek niż łańcuch `verify.sh` (który ma 15 etapów).
> Czym dokładnie było tych siedem — **`[NIEZWERYFIKOWANE]`**; nie wpisuję tego do kolumny,
> w której by nie znaczyło tego, co nagłówek obiecuje.
>
> „PASS (11)" to **11 linii `ok:`** wypisanych przez `ci-integrity.sh` na tej gałęzi.
> `CLAUDE.md:39` i `:497` mówią o „8 kontrolach" — dokument jest starszy od skryptu;
> wierz przebiegowi, popraw `CLAUDE.md`.

**Dlaczego gitleaks pada** — zmierzone, nie założone. `gitleaks detect --source .` na bieżącej
gałęzi: `leaks found: 2`, oba `generic-api-key`, entropia ~3.8:

- `keys/eos-pkg-signing.pub.toml` (commit `03aa86a9`)
- `keys/upstream-redox-pkg.pub.toml` (commit `2c836aef`)

Oba to klucze **PUBLICZNE**: 74 bajty, jedno pole `pkey`, 64 znaki hex = 32 bajty = klucz
publiczny ed25519. Sekret pkgara ma zupełnie inny kształt (salt, nonce, zaszyfrowany blob).
To jest znalezisko `C-19` — fałszywy alarm.

Jest tu detal, który łatwo przeoczyć: `keys/upstream-redox-pkg.pub.toml` **nie istnieje**
w bieżącym drzewie roboczym (`ls keys/` go nie pokazuje) — jest tylko na
`fix/p0-audit-findings`. gitleaks skanuje **historię**, 8206 commitów, więc flaguje go i tak.
Wniosek praktyczny: usunięcie pliku nie zdejmie alarmu; zdejmie go **wyłącznie** allowlista.

Allowlista z uzasadnieniem (`.gitleaks.toml`) żyje **tylko** na `fix/p0-audit-findings`
i `chore/security-hardening` — te dwie wersje pliku są **bajt w bajt identyczne** (`diff` po
`git show` obu → bez różnic). Na `main`, w bieżącym drzewie i na trzech pozostałych gałęziach
`.gitleaks.toml` istnieje, ale nie ma w nim tych dwóch wpisów. Zmierzone na siedmiu gałęziach:

```
git show <gałąź>:.gitleaks.toml | grep -c 'keys/'
  fix/p0-audit-findings 2 · chore/security-hardening 2
  main 0 · feat/m1-bootable-medium 0 · chore/repo-restructure 0
  chore/docs-rebuild 0 · docs/installer-design 0
```

Że ta allowlista faktycznie zdejmuje oba trafienia, **zmierzyłem, a nie założyłem**: ten sam
skan historii z konfiguracją z `fix/p0-audit-findings` daje `no leaks found`
(`gitleaks detect --source . --config <konfiguracja z fix/p0> --no-banner --redact`, 8206
commitów). Wpisy to dwie ścieżki w globalnym `[allowlist].paths`, linie 41 i 50.

**`1 SKIPPED` na `chore/security-hardening`** to etap `tar-pins`, i to nie jest „prawie zielone":
`verify.sh` mówi wprost, że bramka `eos-check-tar-pins.py` **nie istnieje na tej gałęzi** —
jest nienapisana, a nie przechodząca. Skrypt sam nazywa to `does not exist in this tree`.
Ten plik przychodzi z `fix/p0-audit-findings` jako nowa kontrola 12.

---

## 8. Co się zmieni po scaleniu

Wszystko poniżej to **różnice zmierzone przez `git diff main..<gałąź>`** na plikach przypięć.
Skutki oznaczone `[PROGNOZA]` wynikają z odczytu kodu bramek, nie z przebiegu po scaleniu.

### 8.1 `e-os/e-os` !3 — `fix/p0-audit-findings`

Największy ruch w macierzy. **38 plików w zakresie przypięć** — i ta liczba jest sumą,
nie odczytem z jednego `--stat`: `git diff --name-only main..fix/p0-audit-findings --
'recipes/*/*/recipe.toml'` daje **36**, plus `Cargo.toml` i `Cargo.lock`. Cały MR to 147 plików.

| Zmiana | Dowód | Skutek dla tej macierzy |
|---|---|---|
| **26/26 receptur przełączonych z `github.com/Gh0s777tt` na `gitlab.com/e-os`** | `git diff main..fix/p0-audit-findings -- recipes/` | §4 „rozkład hostów" odwraca się: build przestaje zależeć od lustra, zaczyna od źródła prawdy (ADR-0001) |
| `Cargo.toml:46` + `Cargo.lock:860` też na GitLaba | oba pliki, `git show` | rozjazd z §6.1 **zamknięty po obu stronach naraz** — to jest właśnie ta naprawa |
| `eos-source-rules.sh` uczy się drugiego hosta | linia 41 — `grep -rlE` z alternatywą na oba hosty | **bez tej zmiany kontrola 6 by pękła**: stary `grep` szukał tylko `Gh0s777tt/eos-`, nie znalazłby nic i skrypt wyszedłby z `found no E-OS-forked recipes — that is itself wrong` |
| nowa kontrola 12 w `ci-integrity.sh` | `+15` linii, woła `eos-check-tar-pins.py` | zdejmuje `SKIPPED` z §7 — etap `tar-pins` dostaje wreszcie skrypt |
| allowlista gitleaks dla dwóch kluczy publicznych | `.gitleaks.toml`, linie 41 i 50 | gitleaks przestaje padać (`C-19`). **Zmierzone, nie prognozowane**: skan tej samej historii z tą konfiguracją → `no leaks found` — §7 |
| `recipes/libs/mpc` dostaje `blake3` na tarballu | `+14` linii do **istniejącego** pliku (`git ls-tree main -- recipes/libs/mpc/` zwraca blob; na `main` plik ma 18 linii) | zamyka jedyną dziurę w powierzchni 6 z §1 — potwierdzone przebiegiem: skrypt kontroli 12 na bieżącym drzewie wypisuje `BAD: 1 recipe(s) … mpc` i wychodzi z 1. `mpc` jest zależnością `gcc13`, czyli kompilatora krzyżowego produkującego każdą binarkę E-OS |

> **`pin-check` po tym scaleniu nadal odpyta GitHuba**, nie GitLaba: `cmd_pins`
> (`scripts/eos-repos.sh:104`) robi `git ls-remote "$gh"`, a `repos.toml` **nie jest**
> w diffie tego MR-a. Powstaje asymetria: receptury ciągną z GitLaba, bramka weryfikuje
> względem lustra. Dopóki lustro nadąża, wynik jest ten sam; lustra **nie mają
> automatycznej synchronizacji**. `[PROGNOZA]` — nie da się tego sprawdzić przed scaleniem.

### 8.2 `e-os/e-os` !4 — `chore/security-hardening`

| Zmiana | Dowód | Skutek |
|---|---|---|
| `scripts/verify.sh` + 8 workflow'ów GitHuba | `git ls-tree -r --name-only chore/security-hardening` | **jedyna** gałąź, która wnosi bramki `--locked` z §6.2 — dopóki nie scalona, awaria z §6.1 nie jest łapana nigdzie |
| `Cargo.lock`: `anyhow 1.0.102→1.0.104`, `lru 0.16.3→0.16.4` | `git diff main..chore/security-hardening -- Cargo.lock` | jedyny ruch wersji w tym MR; `Cargo.toml` **bez zmian** — to bump w granicach semver |
| allowlista gitleaks | `.gitleaks.toml` | jw. — `C-19` |

**Kolizja do rozstrzygnięcia przy scalaniu:** `fix/p0-audit-findings` i
`chore/security-hardening` **obie** ruszają `Cargo.lock` i **obie** dodają allowlistę gitleaks.
`!3` zmienia w locku URL `redox-pkg`, `!4` zmienia wersje dwóch pakietów z rejestru — to różne
linie, ale ten sam plik. **Kolejność ma znaczenie i nie da się jej odgadnąć**: po scaleniu
trzeba przepuścić `cargo metadata --locked` (§6.1), bo scalony `Cargo.lock` może nie zgadzać
się z żadnym z dwóch `Cargo.toml`. `[PROGNOZA]`

### 8.3 `e-os/e-os` !2 — `chore/repo-restructure`

| Zmiana | Dowód | Skutek |
|---|---|---|
| przebudowa `docs/` na `getting-started/`, `guides/`, `architecture/`, `reference/`, `security/`, `archive/` | `git ls-tree -r --name-only chore/repo-restructure -- docs/` | **ten plik jest już zapisany pod docelową ścieżką** `docs/reference/`; wszystkie odnośniki `../*.md` poniżej trzeba będzie przepiąć |
| 10 receptur — zmiany **tylko w komentarzach** ze ścieżkami dokumentów | `git diff main..chore/repo-restructure -- recipes/` | `docs/known-issues.md → docs/reference/known-issues.md`, `docs/forks.md → docs/architecture/forks.md`. **Żadne `git`/`branch`/`rev` nie zmienione** — macierz §3 bez ruchu |

> **Znalezione przy okazji tego pomiaru, do naprawy przed scaleniem `!2`.** Przepisanie
> ścieżek trafiło również w **adresy URL do cudzych repozytoriów**, gdzie `docs/building.md`
> to ścieżka w projekcie, którego nie kontrolujemy. **Siedem** takich linii, wszystkie
> w komentarzach (policzone, nie oszacowane: cały diff `recipes/` to 10 plików i 11 dodanych
> linii, z czego 4 to poprawne przepisanie ścieżek wewnętrznych, a 7 — te poniżej):
>
> ```
> -# build instructions: https://github.com/mongodb/mongo/blob/master/docs/building.md
> +# build instructions: https://github.com/mongodb/mongo/blob/master/docs/getting-started/building.md
> ```
>
> Dotknięte, po jednej linii na receptę: `recipes/wip/db/mongodb6`, `mongodb7`,
> `recipes/wip/emu/game-console/obliteration`, `xenia-canary`, `recipes/wip/shells/cicada`,
> `elvish`, `recipes/wip/vm/cloud-hypervisor` — siedem receptur, siedem linii.
> Są to komentarze, więc **build się nie psuje** — psuje się dokumentacja: siedem odnośników
> prowadzi teraz pod adresy, które w tamtych projektach nie istnieją. Odtworzenie (`^\+`, żeby
> nie policzyć dwa razy strony `-` diffu):
> `git diff main..chore/repo-restructure -- recipes/ | grep -c '^+.*github\.com/.*docs/getting-started/'`
> → `7`. Sześć z nich kończy się na `building.md`; siódma to `cicada`, gdzie przepisana ścieżka
> to `docs/getting-started/install.md`.

### 8.4 `e-os/e-os` !1 — `chore/docs-rebuild`

`git diff --stat main..chore/docs-rebuild` na plikach przypięć jest **pusty**. Zero wpływu
na tę macierz.

### 8.5 Gałęzie bez MR-a

| Gałąź | Wpływ na macierz |
|---|---|
| `docs/installer-design` | brak — diff przypięć pusty |
| `feat/m1-bootable-medium` | brak zmian przypięć wobec `main`; wnosi `EOS_VERSION?=0.2.0` i `INSTALLER_MEDIUM_NAME` do `mk/config.mk` (§5.2) |

### 8.6 MR-y w `eos-installer` i `eos-pkgutils` — tu jest prawdziwe ryzyko

Sześć z dziewięciu otwartych MR-ów leży **poza tym repozytorium**:
`eos-installer` !1/!2/!3, `eos-pkgutils` !1/!2/!3.

Ich scalenie **przesuwa głowę gałęzi forka**. Rewizja przypięta w recepturze zostaje tam,
gdzie jest — więc:

| Co się stanie | Który wiersz macierzy | Bramka |
|---|---|---|
| `eos-installer` !1/!2/!3 scalone → tip `master` ≠ `c8d32ad39e` | §3.2, `recipes/core/installer` | `pins --strict` → `DRIFT (recipe behind fork)` → **exit 1** |
| `eos-pkgutils` !1/!2/!3 scalone → tip `eos` ≠ `e28063ee2f` | §3.2 **i** §4 (`Cargo.toml:46` + `Cargo.lock:860`) | `pins --strict` → **exit 1**; `Cargo.toml` zostaje na starej rewizji, więc **`redox-pkg` wraca do stanu rozjechanego z §4** |

Drugi wiersz jest ważniejszy. `eos-pkgutils` to **jedyne** repozytorium przypięte w dwóch
miejscach naraz. Scalenie tam bez podbicia **obu** przypięć odtwarza dokładnie tę wadę,
którą `V2-MS15` zamknął: producent manifestu (host) i konsument (obraz) znowu byłyby różnymi
bazami kodu. `pins --strict` zobaczy tylko połowę problemu — recepturę. Rozjazdu
`Cargo.toml:46` nie widzi **żadna** bramka; `--locked` go nie złapie, bo `Cargo.toml`
i `Cargo.lock` pozostaną wzajemnie spójne, tylko przestarzałe.

**Procedura po scaleniu któregokolwiek z tych sześciu MR-ów** (kolejność jest istotna):

1. `bash scripts/eos-repos.sh pins` — odczytaj nowy tip.
2. Podbij `rev` **i** w `repos.toml`, **i** w `recipes/core/<nazwa>/recipe.toml`.
3. Dla `eos-pkgutils` **dodatkowo**: `Cargo.toml:46` → `cargo update -p redox-pkg` →
   sprawdź `Cargo.lock:860`.
4. `cargo metadata --locked --offline` — kontrola negatywna z §6.1.
5. `bash scripts/ci-integrity.sh` i `bash scripts/eos-source-rules.sh`.

---

## 9. Jak odtworzyć każdą liczbę z tego dokumentu

```sh
# §2 — typy i liczność
python3 scripts/eos-check-repo-types.py
grep -c '^\[\[repo\]\]' repos.toml

# §3 — przypięcia vs głowy forków (wymaga sieci)
bash scripts/eos-repos.sh pins

# §3.5 — czy przypięcie faktycznie trafia do obrazu
bash scripts/eos-source-rules.sh
bash scripts/ci-integrity.sh

# §4 — narzędzia hosta
grep -n 'source = "git' Cargo.lock | sort -u
grep -c 'source = "git' tools/eos-repo-sign/Cargo.lock

# §5 — toolchain
grep channel rust-toolchain.toml
grep -n UPSTREAM_RUSTC_VERSION mk/prefix.mk

# §6.2 — które bramki mają --locked
grep -n -- '--locked' .gitlab-ci.yml
git show chore/security-hardening:scripts/verify.sh | grep -n -- '--locked'

# §7 — gitleaks: stan bieżący i dowód, że allowlista z !3 go zdejmuje
gitleaks detect --source . --no-banner --redact -v
git show fix/p0-audit-findings:.gitleaks.toml > /tmp/gl.toml
gitleaks detect --source . --config /tmp/gl.toml --no-banner --redact

# §1 powierzchnia 6 — przypięcia archiwów
grep -rl '^tar = ' recipes/*/*/recipe.toml recipes/*/*/*/recipe.toml | wc -l
grep -rlE '^(blake3|sha256) = ' recipes/*/*/recipe.toml recipes/*/*/*/recipe.toml | wc -l

# §8.1 / §1 powierzchnia 6 — czy recepta mpc jest nowa (nie jest) i co pokazuje kontrola 12
git ls-tree main -- recipes/libs/mpc/
git diff --stat main..fix/p0-audit-findings -- recipes/libs/mpc/
git show fix/p0-audit-findings:scripts/eos-check-tar-pins.py > scripts/.tarpins-tmp.py
python3 scripts/.tarpins-tmp.py; rm -f scripts/.tarpins-tmp.py

# §8.3 — przepisane odnośniki do cudzych repozytoriów
git diff main..chore/repo-restructure -- recipes/ | grep -c '^+.*github\.com/.*docs/getting-started/'

# raporty audytu (żyją tylko na fix/p0-audit-findings)
git show fix/p0-audit-findings:docs/audit/00-inventory-2026-08-30.md
```

## 10. Czego ten dokument nie dowodzi

- **Nie sprawdza, czy przypięta rewizja się kompiluje.** `pins` porównuje SHA z `git ls-remote`.
  Że zbiór 26 rewizji buduje razem działający obraz, dowodzi wyłącznie
  `make CI=1 … all` + `scripts/ci-boot-smoke.sh` — nie uruchamiane w tej sesji.
- **Nie sprawdza, co cargo faktycznie zlinkowało w recepturach.** Robi to
  `scripts/eos-fork-linkage.py`, który potrzebuje rozpakowanych `recipes/*/*/source/`
  (nieśledzonych), więc działa tylko w kontenerze budującym. `[NIEZWERYFIKOWANE]` czy któraś
  z 26 receptur ciąga forkowany crate z crates.io.
- **Nie sprawdza stanu luster.** `eos-mirror-drift.sh` porównuje deklarację typu z realną
  zawartością forka; to zadanie `scheduled`, wymaga klonowania każdego forka i upstreamu.
  Nie uruchamiane tutaj.
- **Nie sprawdza treści MR-ów po stronie GitLaba** — lista dziewięciu MR-ów pochodzi ze stanu
  przekazanego do tego zadania, nie z własnego odpytania API. Zmierzyłem **gałęzie lokalne**,
  które im odpowiadają.
- **Sam nie jest bramkowany.** Rewizje w §3 są przepisane z `repos.toml` i **rozjadą się przy
  pierwszym podbiciu pinu**. `docs/ecosystem.md` świadomie nie powtarza hashy właśnie z tego
  powodu — tutaj są, bo bez nich macierz zgodności nie jest macierzą, ale **źródłem prawdy
  pozostaje `repos.toml`**. Przy rozbieżności: wierz `repos.toml`, popraw ten plik.

---

**Odnośniki:** [`repos.toml`](../../repos.toml) · [`CLAUDE.md` §11](../../CLAUDE.md) ·
[forki i komponenty vendorowane](../architecture/forks.md) · [komponenty ekosystemu](../architecture/ecosystem.md) ·
[ADR-0001 — GitLab źródłem prawdy](../adr/0001-gitlab-as-source-of-truth.md) ·
[ADR-0002 — budowanie z forków, nie z binarek upstreamu](../adr/0002-build-from-forks-not-upstream-binaries.md) ·
[CI/CD](../operations/ci.md) · [znane problemy](known-issues.md)
