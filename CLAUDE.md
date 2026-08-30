# CLAUDE.md — kontrakt pracy w E-OS

**Ostatni przegląd:** 2026-08-30 · **Właściciel:** Gh0s777tt · **Status:** obowiązujący

To jest **kontrakt, nie poradnik**. Reguły w §4 są twarde: zmiana, która ich nie spełnia, nie jest
skończona, niezależnie od tego, jak dobrze wygląda.

---

## 1. Czym jest ten produkt

E-OS to **dystrybucja Redox OS** — systemu z mikrojądrem napisanym w Rust — z dołożonym
łańcuchem zaufania: weryfikowanym rozruchem, hybrydowo podpisanym indeksem pakietów i kuratorowanym
pulpitem. Nie jest to system pisany od zera i nigdy nie należy go tak przedstawiać.

**Cel produktowy:** Redox z prawdziwym łańcuchem zaufania. Nie Tails, nie Qubes, nie GrapheneOS —
te robią co innego i porównywanie się z nimi jest nieuczciwe wobec czytelnika.

## 2. To repozytorium

Repozytorium **orkiestrujące**. Nie zawiera kodu systemu operacyjnego.

| Katalog | Zawartość |
|---|---|
| `recipes/` | receptury budowania — co z czego powstaje |
| `config/` | definicje obrazów per architektura i wariant |
| `src/` | **vendorowany upstreamowy `redox_cookbook`** — binarki `repo`, `repo_builder`, `cookbook_redoxer` |
| `tools/eos-repo-sign` | **kod własny E-OS** — podpis hybrydowy ed25519 + ML-DSA-65 |
| `scripts/` | automatyzacja budowania, podpisywania, publikacji i weryfikacji |
| `mk/`, `Makefile` | system budowania |
| `podman/` | definicje kontenerów |
| `docs/` | dokumentacja, w tym raporty audytu |

**Rozróżnienie, które ma znaczenie przy każdej zmianie:** `src/` to kod upstreamu. Nie oceniamy go
jako własnego i nie refaktoryzujemy dla estetyki — ale **ponosimy jego konsekwencje**, bo to on
buduje system. Kod własny to `tools/`, `scripts/`, `recipes/core/*` i cztery forki.

---

## 3. Polecenia — zweryfikowane, nie przepisane

Wszystkie sprawdzone 2026-08-30 na hoście referencyjnym (Apple Silicon macOS + podman).

### Budowanie

```bash
bash scripts/eos-build.sh x86_64      # albo aarch64
```

**Nie używaj `make all` z katalogu projektu.** Ten katalog leży na exFAT, którego podman nie
podmontuje; `eos-build.sh` buduje w wolumenie i to jest jedyna działająca ścieżka na tym hoście.

### Uruchamianie

```bash
bash scripts/ci-boot-smoke.sh ~/eos-artifacts/eos-x86_64-harddrive.img 300 --arch x86_64
# -> boot-smoke: PASS — reached userspace login
```

### Testy

```bash
podman run --rm --network=host -v eos-work:/work -v eos-root:/root localhost/redox-base:latest \
  bash -lc 'cd /work/redox && cargo test --release'
cd tools/eos-repo-sign && cargo test
```

Stan faktyczny: `redox_cookbook` ma **9 testów** (wszystkie w kodzie upstreamu),
`tools/eos-repo-sign` **9**, fork `eos-pkgutils` **33**. `src/bin/repo_builder.rs`
i `src/cook/package.rs` — **zero**. To jest dług, nie stan docelowy.

### Kontrole

```bash
bash scripts/ci-integrity.sh                    # bramka integralności (12 kontroli)
bash scripts/eos-repos.sh pins --strict         # -> pins ok=26 drift=0
shellcheck -f gcc $(git ls-files 'scripts/*.sh')
osv-scanner scan source --lockfile Cargo.lock
hadolint podman/*containerfile
gitleaks detect --config .gitleaks.toml --no-banner --redact
```

### Pakowanie i publikacja

```bash
EOS_REPO_SIGN_KEY=<ścieżka-poza-repo> bash scripts/publish-repo.sh x86_64-unknown-redox
```

Bez `EOS_REPO_SIGN_KEY` skrypt **odmawia** spakowania niepodpisanego indeksu. Obejście wymaga
jawnego `EOS_ALLOW_UNSIGNED=1` — i to jest wzorzec do naśladowania wszędzie indziej.

---

## 4. Styl, nazewnictwo i konwencje katalogów

- **Rust**: `rustfmt.toml` i `clippy.toml` są wspólne dla całego ekosystemu — jedna konfiguracja,
  nie dwadzieścia cztery. Kod własny E-OS ma **zero `unsafe`**; jeśli musisz go dodać, wymagany
  jest komentarz `SAFETY:` (bramka `ci-integrity.sh` kontrola 4).
- **Powłoka**: `set -euo pipefail`, `shellcheck` bez błędów. Obecny stan: **0 błędów** w 50 skryptach.
- **Commity**: Conventional Commits. Zakres to obszar, nie plik. Treść commita tłumaczy **dlaczego**
  i **co zmierzono**, nie powtarza diffa.
- **Końce linii**: `.gitattributes` jest jedynym źródłem prawdy. `CHANGELOG.md` jest przypięty na
  **CRLF** — bramka to sprawdza i psuje się to łatwo przy zapisie z Pythona w trybie tekstowym.
- **Nazewnictwo**: skrypty własne E-OS mają przedrostek `eos-`; skrypty odziedziczone z upstreamu
  zostają pod swoimi nazwami.
- **Dokumentacja**: nagłówek z tytułem, statusem, datą przeglądu i właścicielem.

---

## 5. Protokół weryfikacji — reguły twarde

Te reguły nie podlegają negocjacji ani ocenie sytuacyjnej. Każda z nich powstała po tym, jak jej
brak **coś zepsuł** — odniesienia są podane, żeby nie były abstrakcją.

### 5.1 Każda zmiana ma testy

Nowe albo zaktualizowane. Bez wyjątku milczącego.

**Jeśli testu napisać się nie da** — napisz wprost dlaczego i uzyskaj zgodę **przed** złożeniem
zmiany. „Nie dało się" bez uzasadnienia jest odmową, nie wyjaśnieniem.

### 5.2 Zmiana jest skończona dopiero, gdy przechodzą wszystkie

| Kontrola | Polecenie |
|---|---|
| build | `bash scripts/eos-build.sh <arch>` |
| pełny zestaw testów | `cargo test --release` w kontenerze **oraz** `cd tools/eos-repo-sign && cargo test` |
| lintery | `shellcheck`, `cargo clippy` |
| typy | `cargo check` |
| skanery bezpieczeństwa | `gitleaks`, `osv-scanner`, `hadolint` |
| bramka integralności | `bash scripts/ci-integrity.sh` |

**Zielony build nie jest dowodem.** Patrz §5.3.

### 5.3 Weryfikuj artefakt, nie kod wyjścia

**Każdą zmianę trzeba uruchomić, nie przemyśleć.** Do opisu zmiany wkleja się **prawdziwe wyjście
polecenia**, nie jego streszczenie.

Po zmianie dotykającej tego, co trafia do obrazu albo do indeksu, sprawdź **wytworzony plik**:

```bash
strings -a <binarka> | grep -q "<charakterystyczny ciąg nowej funkcji>"
grep -E "^(serial|expires)" repo.toml
# montowanie obrazu i odczyt jego zawartości
```

**Zmierzone trzy razy w ciągu jednego dnia** (`U-224`): build kończył się sukcesem, a zmiana nie
działała. `make` nie przebudowuje narzędzi hosta, więc indeks powstawał starą binarką i wychodził
bez pola, które źródło już potrafiło zapisać.

### 5.4 Bramka sprawdzająca obecność nie jest bramką

Każda kontrola musi mieć **test negatywny** — dowód, że potrafi odmówić.

Przykłady z tego repozytorium, wszystkie prawdziwe:
- `grep -q 'SYNC:' README.md` przechodzi przy dowolnej wartości markera. Marker deklarował `U-152`,
  gdy CHANGELOG był na `U-224` — **72 pozycje rozjazdu**, bramka zielona.
- `serial` z zamrożonego licznika zawsze spełnia `>= znacznik`. Zapadka wyglądała na uzbrojoną
  i nie chroniła niczego.
- `cmd | tail` w kontenerze oddaje status `tail`, nie `cmd`. `cargo: command not found` przejechało
  bez zatrzymania mimo `set -e`.

**Jeśli nie umiesz pokazać, kiedy kontrola pada — nie masz kontroli.**

### 5.5 Domyślnie fail-closed, wyjątek jawny

Budowa bez zabezpieczenia **wymaga jawnej zmiennej środowiskowej**. Wzorzec poprawny:
`publish-repo.sh` odmawia bez klucza, obejście to `EOS_ALLOW_UNSIGNED=1`.

Wzorzec błędny, wciąż obecny: brak klucza rozruchu daje bootloader **bez weryfikacji** i sukces
builda, a jedyne ostrzeżenie zjada `| tail -3` w `eos-build.sh:62` (znalezisko `C-2`).

### 5.6 Zmiany dotykające rozruchu, kryptografii, aktualizacji lub granic uprawnień

Wymagają **dodatkowo**, w opisie zmiany:

1. **pisemnej analizy ryzyka** — co się stanie, jeśli to zawiedzie, i kto to zauważy;
2. **planu wycofania** — konkretnych poleceń, nie „przywrócimy poprzednią wersję".

Obszary objęte: `recipes/core/bootloader`, `recipes/core/kernel`, `tools/eos-repo-sign`,
`src/cook/package.rs`, `src/bin/repo_builder.rs`, `config/*/eos.toml` w części `[[files]]`
dotyczącej kluczy i `login_schemes.toml`, oraz forki `eos-bootloader`, `eos-kernel`, `eos-pkgutils`.

### 5.7 Zakazy

- **Bez commitów na `main`.** Gałąź, potem merge request.
- **Bez `force-push`.** Nigdy, także „tylko na swojej gałęzi".
- **Bez sekretów.** Materiał klucza nie trafia do repozytorium ani do logu. Wygenerowanie klucza
  podpisującego jest **działaniem człowieka** i nie jest automatyzowane.
- **Bez niezwiązanych zmian w jednym MR.** Jedna zmiana logiczna na MR.
- **Bez ręcznej edycji plików generowanych.** `Cargo.lock`, `cookbook.lock`, `sbom/*.cdx.json`,
  `docs/licenses/THIRD_PARTY.md` — **regeneruj**, nie poprawiaj.
- **Bez `--wipe-caches`.**
- **Bez ręcznej edycji repozytoriów typu B.**

### 5.8 Dokumentacja w tym samym MR

`README.md`, `CHANGELOG.md`, `ROADMAP.md` i `ARCHITECTURE.md` aktualizuje się **w tej samej zmianie**,
która ich dotyczy. Nie w następnej, nie „przy okazji".

Audyt znalazł w tym repozytorium README twierdzące, że klucz nie istnieje, gdy istniał i był wpięty
w obraz, oraz wymieniające dwie aplikacje, których w obrazie nie ma. To jest koszt odkładania.

---

## 6. Definicja ukończenia

Zmiana jest skończona, gdy **wszystkie** punkty są prawdziwe:

- [ ] Build przechodzi — `bash scripts/eos-build.sh <arch>` kończy się `Done.`
- [ ] Testy przechodzą — pełny zestaw, nie wybrany podzbiór
- [ ] `shellcheck` bez błędów, `clippy` bez ostrzeżeń w kodzie własnym
- [ ] `bash scripts/ci-integrity.sh` → `integrity: PASS`
- [ ] `gitleaks`, `osv-scanner`, `hadolint` bez nowych trafień
- [ ] **Artefakt sprawdzony** — nie tylko kod wyjścia (§5.3)
- [ ] Test **negatywny** istnieje dla każdej dodanej kontroli (§5.4)
- [ ] Prawdziwe wyjście poleceń wklejone do opisu MR
- [ ] Dokumentacja zaktualizowana w tym samym MR (§5.8)
- [ ] Przy obszarach z §5.6 — analiza ryzyka i plan wycofania
- [ ] `CHANGELOG.md` ma wpis z odniesieniem do commita
- [ ] Commit podpisany, Conventional Commits, jedna zmiana logiczna

---

## 7. Zakazy — zebrane w jednym miejscu

Pełne uzasadnienia w §5.7. Tutaj lista do szybkiego sprawdzenia:

- commit na `main` · `force-push` · sekret w repozytorium lub w logu
- niezwiązane zmiany w jednym MR · ręczna edycja pliku generowanego
- ręczna edycja repozytorium typu B · `--wipe-caches`
- generowanie klucza podpisującego przez narzędzia (to działanie człowieka)

---

## 8. Pułapki tego repozytorium

Każda zmierzona, nie wydedukowana.

| # | Pułapka | Objaw | Obejście |
|---|---|---|---|
| P-1 | **`make` nie przebudowuje narzędzi hosta** — `$(FSTOOLS_TAG)` nie ma prerekwizytów źródłowych | build zielony, zmiana nieobecna w artefakcie | `eos-build.sh` buduje je przed `make`; docelowo napraw `mk/fstools.mk` |
| P-2 | **`make all` melduje „Nothing to be done"** i składa obraz ze starych artefaktów | obraz z poprzedniego kodu, bez ostrzeżenia | usuń `build/<arch>/<cfg>/repo.tag` przed budowaniem |
| P-3 | **`cmd \| tail` w kontenerze** oddaje status `tail` | błąd przejeżdża mimo `set -e` | `set -o pipefail` **po stronie kontenera** |
| P-4 | **Przekierowanie tworzy plik przed poleceniem** | zerowy plik udający artefakt | etapuj przez `.partial`, potem `mv` |
| P-5 | **Katalog projektu na exFAT** | podman nie podmontuje; `make` z katalogu nie działa | `scripts/eos-build.sh` |
| P-6 | **`redoxfs` nie ma trybu tylko-do-odczytu** | montowanie obrazu **go modyfikuje**; wielokrotne montowanie potrafi go uszkodzić | montuj **kopię**, nigdy oryginał |
| P-7 | **Nieudane `hdiutil attach -mountpoint`** zostawia pusty katalog blokujący kolejne montowania | objawy udają uszkodzenie APFS | `hdiutil detach -force`, potem `attach` **bez** `-mountpoint` |
| P-8 | **CHANGELOG jest CRLF** | zapis z Pythona w trybie tekstowym psuje końce linii; bramka pada | zapisuj binarnie, łącz przez `\r\n` |
| P-9 | **`eos-sync-buildtree.sh` kopiuje tylko pliki śledzone** | nowy plik nie trafia do drzewa budowania | `git add` przed synchronizacją |
| P-10 | **SELinux MCS na wolumenach podmana** | `EACCES` mimo uid 0 i `CAP_DAC_OVERRIDE` | `chcon -l s0` na pliku |
| P-11 | **`grep -c` wypisuje `0` i zwraca status ≠ 0** | `\|\| echo 0` dokleja drugie zero i psuje arytmetykę | sprawdzaj status osobno |
| P-12 | **Odczyt surowych urządzeń wymaga roota** | „błąd 5" z `fsck_apfs` **nie jest** dowodem uszkodzenia | nie diagnozuj na tej podstawie |

---

## 9. Skrypt weryfikacyjny

Docelowo jedno polecenie uruchamiające cały §5.2:

```bash
bash scripts/eos-verify.sh          # PENDING — patrz ROADMAP, PROMPT 4
```

**Ten skrypt jeszcze nie istnieje.** Do czasu jego powstania uruchamiaj kontrole z §2 pojedynczo.
Lokalna siatka zastępcza jest w `lefthook.yml` — zainstaluj raz:

```bash
brew install lefthook && lefthook install
```

Ma to znaczenie praktyczne: **CI nie działa od 2026-08-28** (wyczerpany limit minut GitLaba), więc
bramki lokalne są dziś jedyną działającą kontrolą. Szczegóły:
[`docs/audit/03-security-audit-2026-08-30.md`](docs/audit/03-security-audit-2026-08-30.md) §2.

---

## 10. Dokumentacja i jej utrzymanie

`README.md`, `CHANGELOG.md`, `ROADMAP.md`, `ARCHITECTURE.md` — aktualizowane **w tym samym MR**
co zmiana, którą opisują (§5.8). Nagłówek każdego dokumentu w `docs/` niesie tytuł, status,
datę przeglądu i właściciela.

Marker `<!-- SYNC: ... -->` w `README.md` deklaruje, do którego wpisu CHANGELOG-a README jest
zsynchronizowane. **Bramka sprawdza jego obecność, nie wartość** — utrzymanie zgodności jest
obowiązkiem człowieka, dopóki kontrola nie zostanie zaostrzona (ROADMAP, `S-4` sąsiedztwo).

---

## 11. Ekosystem — typy repozytoriów

**30 repozytoriów** w `repos.toml`. GitLab jest źródłem prawdy, GitHub lustrem tylko do odczytu
(`ADR-0001`). **Pomylenie typu repozytorium jest najkosztowniejszym błędem, jaki tu można popełnić.**

Listy poniżej są **sprawdzane maszynowo** wobec `repos.toml` przez `scripts/eos-check-repo-types.py`
(kontrola 7 w `ci-integrity.sh`). Rozjazd między tym plikiem a manifestem wywala bramkę — i o to chodzi.

### Typ A — komponenty własne E-OS

`E-OS` · `eos-control` · `eos-guard` · `eos-notes` · `eos-sysmon` · `eos-ui`

### Typ B — vendorowane lustra upstreamu *(READ-ONLY)*

`eos-coreutils` · `eos-extrautils` · `eos-ion` · `eos-liborbital` · `eos-netdb` · `eos-netutils` · `eos-orbclient` · `eos-orbterm` · `eos-redox-fatfs` · `eos-redoxer`

### Typ C — forki z łatkami E-OS

`eos-base` · `eos-bootloader` · `eos-installer` · `eos-kernel` · `eos-orbdata` · `eos-orbital` · `eos-orbutils` · `eos-pkgar` · `eos-pkgutils` · `eos-redoxfs` · `eos-relibc` · `eos-userutils`

### Typ D — repozytoria artefaktowe

`eos-pkg-aarch64` · `eos-pkg-x86_64`

---

## 12. Praca z lustrami i forkami

**Typ B — nigdy nie edytuj ręcznie.** Synchronizacja wyłącznie przez `scripts/sync-forks.sh`,
który **jest w tym repozytorium**. Każda ręczna zmiana to dywergencja, którą trzeba ponosić przy
**każdej** kolejnej synchronizacji — a nikt jej nie zobaczy, dopóki nie zaboli.

Lustro wolno mieć własne: `README*`, `LICENSE*`, `COPYING*`, `.gitlab-ci.yml`, `.github/*`,
`.gitignore`. Lista jest wymuszona w `scripts/eos-mirror-drift.sh:29`.
**Cokolwiek poza nią czyni z repozytorium typ C** — nie dlatego, że tak brzmi definicja, tylko
dlatego, że kodu nikt nie audytuje ani nie testuje w repo opisanym jako lustro.

> Ma to bezpośrednią konsekwencję dla dokumentacji: dołożenie do lustra `CHANGELOG.md`,
> `CLAUDE.md` czy `.editorconfig` **przekwalifikuje je na typ C** i wywali `eos-mirror-drift.sh`.
> Jeśli dokumentacja ma tam trafić, najpierw rozszerz listę w skrypcie — osobną zmianą,
> z uzasadnieniem.

**Typ C — utrzymuj rebaseowalność.** Łatki małe, tematyczne, każda z uzasadnieniem w treści
commita i ze statusem wobec upstreamu (*zgłoszona / przyjęta / lokalna na stałe*). Łatka bez
uzasadnienia jest długiem, którego nikt nie umie spłacić. Sprawdza to `scripts/eos-rebase-check.sh`.

**Forki nie mają automatycznego lustra.** Push wymaga **dwóch** poleceń — na GitLab i na GitHub.
Repozytorium główne ma działające lustro; forki nie.
