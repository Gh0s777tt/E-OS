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

Stan faktyczny: `redox_cookbook` ma **15 testów** (12 w `src/lib.rs` + 3 w `src/bin/repo.rs`;
9 z nich to kod upstreamu, 6 dołożono 2026-08-30 w `2c836aef5` i `0029fb7e6`),
`tools/eos-repo-sign` **9**, fork `eos-pkgutils` **33**. `src/bin/repo_builder.rs`
i `src/cook/package.rs` — **zero**. To jest dług, nie stan docelowy.

### Kontrole

```bash
bash scripts/ci-integrity.sh                    # bramka integralności (20 kontroli + sonda 0)
python3 scripts/eos-check-roadmap.py            # kontrola 16: kotwice, numery, jeden status na ID, ✅ tylko z dowodem
bash scripts/eos-check-assets.sh                # kontrola 17: duplikaty, > 5 MB, sieroty w assets/
python3 scripts/eos-check-summary.py            # kontrola 18: docs/SUMMARY.md = drzewo docs/
python3 scripts/eos-check-roadmap-page.py       # kontrola 19: strona roadmapy = ROADMAP.md §3.4
python3 scripts/eos-check-changelog-sections.py # kontrola 20: wpis nie stoi pod wydaniem, które już wyszło
bash scripts/eos-repos.sh pins --strict         # -> pins ok=25 drift=1 (non-allowlisted=0) split-pin=0
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
  `docs/reference/third-party-licenses.md` — **regeneruj**, nie poprawiaj.
- **Bez `--wipe-caches`.**
- **Bez ręcznej edycji repozytoriów typu B.**

### 5.8 Dokumentacja w tym samym MR

`README.md`, `CHANGELOG.md`, `ROADMAP.md` i `ARCHITECTURE.md` aktualizuje się **w tej samej zmianie**,
która ich dotyczy. Nie w następnej, nie „przy okazji".

Audyt znalazł w tym repozytorium README twierdzące, że klucz nie istnieje, gdy istniał i był wpięty
w obraz, oraz wymieniające dwie aplikacje, których w obrazie nie ma. To jest koszt odkładania.

### 5.9 Testowanie wielostopniowe — jeden kierunek to za mało

Jeden test sprawdzający jedną rzecz w jeden sposób daje **jeden** rodzaj pewności i **fałszywe
poczucie** reszty. Ta sesja dostarczyła na to tyle przykładów, że przestaje to być teorią:

| co pokazało zieleń | czego nie sprawdzało |
|---|---|
| `make build/fstools.tag` → „up to date" | binarka instalatora miała datę sprzed **dwóch miesięcy** |
| `cargo test` → „ok" | test uruchomiono na **starej** kompilacji, bo `cp -p` przeniósł datę pliku |
| `_ => bail!("block size not supported")` | gałąź **nieosiągalna** — wartość była stałą 512 |
| `grep BOOTX64` na całym obrazie | trafiał w ciąg **wewnątrz roota**, nie w ESP |
| `pins --strict` → DRIFT | porównywał z **lustrem GitHuba**, nie z GitLabem |
| „wszystkie gałęzie scalają się czysto" | lokalny klon miał **nieaktualne referencje** |

Dlatego każda zmiana warta testu jest testowana na **kilku poziomach**, a nie na jednym.
Nie wszystkie poziomy dotyczą każdej zmiany — ale pominięcie poziomu jest **decyzją do
uzasadnienia**, nie domyślnym zachowaniem.

**Poziom 1 — kontrakt.** Test jednostkowy na to, co funkcja obiecuje. Wejście, wyjście, błąd.

**Poziom 2 — mutacja.** *Czy ten test w ogóle potrafi zawieść?* Zepsuj celowo to, czego test
pilnuje, i sprawdź, że pada — **i że pada właśnie ten test, a nie inny**. Test, którego nigdy
nie widziałeś na czerwono, jest hipotezą, nie kontrolą. Przy `R-607a` mutacja przepuszczająca
4096 zabiła dokładnie jeden z trzech testów; to jest ten dowód.

**Poziom 3 — ścieżka porażki.** Sprawdź, co się dzieje, gdy jest **źle**: brak pliku, złe hasło,
przerwane zasilanie, urządzenie zgłaszające bzdurę. Większość defektów tej sesji siedziała
w ścieżkach, których nikt nie przeszedł, bo wszyscy testowali sukces.

**Poziom 4 — kontrola przeciwna.** Uruchom ten sam pomiar na kodzie **sprzed** zmiany. Jeżeli
przed i po wygląda tak samo, nie zmierzyłeś swojej zmiany. Przy `R-612a` dopiero to pokazało
różnicę: stary kod → `FAT12, 1× BOOTX64`, nowy → `brak systemu plików, 0× BOOTX64`.

> **Mierz to polecenie, które wykona się w produkcji, nie to, które wpisałeś ręcznie.** Zmierzone
> 2026-09-03 (`PR-008`): ustaliłem ręcznie, że `cargo zigbuild --target x86_64-unknown-linux-gnu`
> buduje produkt na Linuksa — i to była prawda. Potem napisałem `packaging/release.sh`, który dla
> Linuksa wołał **zwykłe `cargo build`**, i ogłosiłem cel za udowodniony. Nagłówek skryptu twierdził
> przy tym, że kros na Linuksa **nie działa** — co też kiedyś było prawdą i przestało nią być po
> włączeniu `fontconfig-dlopen`. Cztery niezależne przebiegi wpadły w to samo: każdy skompilował
> całość poprawnie i padł **na linkowaniu**, po ~20 minutach, na `ld: unknown options: --as-needed`.
> Pomiar był prawdziwy, a mimo to fałszywie uzasadniał zdanie o **skrypcie**, bo skrypt robił coś
> innego niż pomiar. Odtąd: dowodem na „cel X się buduje" jest **przebieg tej ścieżki, którą pójdzie
> CI i operator**, a nie równoważnego polecenia wpisanego z palca.

**Poziom 5 — integracja na prawdziwym poleceniu.** Nie na zastępniku. `make live`, nie „symulacja
make". Jeżeli produkt buduje się w kontenerze z `--device /dev/fuse`, to test bez tego urządzenia
mierzy inny system.

**Poziom 6 — artefakt.** Otwórz to, co powstało (§5.3). Sygnatury, rozmiary, zawartość — nie kod
wyjścia. `file` mówiące „bootable" i `dd` czytające `CD001` z offsetu 0x8001 to dwa różne dowody
tej samej rzeczy i warto mieć oba.

**Poziom 7 — adwersarz.** Przy zmianach dotyczących uprawnień, kluczy, rozruchu i aktualizacji:
spróbuj **złamać** gwarancję, nie potwierdzić ją. Zapis dowolnego pliku przez `/tmp/pkg_download`
został udowodniony podstawieniem dowiązania i zmierzeniem 868 992 bajtów zapisanych jako root —
żaden test funkcjonalny by tego nie pokazał.

**Poziom 8 — goły sprzęt.** QEMU nie dowodzi, że firmware uruchomi nośnik, że dysk 4Kn zostanie
poprawnie rozpoznany ani że sterownik zadziała na prawdziwym chipsecie. Co wymaga metalu, jest
oznaczone ⚙️ w roadmapie i **nie liczy się jako zweryfikowane**, dopóki ktoś tego nie uruchomi.

### 5.10 Pokrycie mierzone na bieżąco, z podłogą, która potrafi zawieść

Pokrycie jest **mierzone przy każdym przebiegu** `scripts/verify.sh`, nie raz na kwartał.

| zakres | reguła |
|---|---|
| `tools/eos-repo-sign` — kod własny E-OS | **bramka**: `cargo llvm-cov --fail-under-lines 38` |
| `Cargo.toml` w korzeniu — vendorowany `redox_cookbook` | **doradczo**: liczba wypisana, bez progu |

Asymetria jest celowa: bramkowanie pokrycia cudzego kodu to relitygowanie drzewa, którego nie
utrzymujemy (§11, typ B/C).

Trzy reguły, bez wyjątków:

1. **Podłoga nigdy nie spada.** Podniesienie progu jest zwykłym commitem. Obniżenie wymaga
   zgody właściciela i uzasadnienia w treści commita.
2. **Liczba bez kierunku jest bezużyteczna.** W opisie zmiany podaje się pokrycie **przed
   i po**, nie samo „po".
3. **Wysokie pokrycie nie jest dowodem.** Można mieć 100% linii i zero testów mutacyjnych —
   wtedy wiadomo, że kod się *wykonał*, nie że jest *sprawdzony*. Pokrycie mówi, czego
   **na pewno nie sprawdzono**; nie mówi, co sprawdzono dobrze.

Bieżący stan, zmierzony 2026-08-31 (`cargo llvm-cov --summary-only`): `tools/eos-repo-sign`
— **41,06 % linii** (263 linie, 155 niepokrytych), **38,12 % regionów**, **33,96 % funkcji**;
próg 38. Vendorowany
cookbook — 9 testów, bez progu.

### 5.11 Każda zmiana jest weryfikowana, zanim nazwie się skończoną — tabela: rodzaj zmiany → kontrola

Reguły §5.1–§5.10 mówią *jak* weryfikować kod. Ta tabela mówi, **co uruchomić dla każdego rodzaju
zmiany**, żeby żadna klasa plików nie wchodziła do `main` bez kontroli, która potrafi zaświecić na
czerwono. Zasada: **nie ma zmiany „tylko w dokumentacji", „tylko w konfiguracji" ani „tylko w
skrypcie" — jest zmiana, która ma swoją bramkę, albo zmiana, której nie wolno scalić.** Jeśli dla
rodzaju zmiany bramki nie ma, pierwszym krokiem jest ją dopisać (do `scripts/verify.sh` albo
`scripts/ci-integrity.sh`), a dopiero drugim — zrobić zmianę. Wynik każdej kontroli (prawdziwe
wyjście, nie „przeszło") wkleja się do opisu MR (§6).

| co zmieniasz | co musi przejść przed commitem | polecenie | test negatywny (§5.4) |
|---|---|---|---|
| kod własny (`tools/`, forki typu A) | fmt, clippy `-D warnings`, `cargo test`, pokrycie ≥ podłoga (§5.10), `cargo-deny`, `osv-scanner` | `bash scripts/verify.sh` | jeden test, który pada bez zmiany — pokazany na czerwono |
| kod vendorowany (typ B, `src/`, `recipes/**`) | forma upstreamu (`ADR-0003`), `ci-integrity.sh` kontrole 1/4/5, `cargo test` na manifeście głównym; pin blake3 dla tarballi (kontrola 12) | `bash scripts/verify.sh --fast && bash scripts/ci-integrity.sh` | zepsuty TOML receptury → `eos-check-tar-pins.py` BAD |
| `config/**/*.toml` | składnia TOML, kontrola 9 (`50_redox`/klucz), lista pakietów istnieje w `recipes/` (`eos-check-tar-pins.py`), boot-smoke tej architektury, gdy zmienia się zestaw pakietów lub init | `bash scripts/ci-integrity.sh && bash scripts/ci-boot-smoke.sh <arch>` | wpis pakietu bez receptury → czerwono |
| `mk/*.mk`, `Makefile`, `podman/*` | `make -n <cel>` na czysto, `hadolint` na containerfile'ach, `actionlint`/`yamllint` nie dotyczą; **każdy cel z `$(MAKE)` propaguje status** (P-14 nie dotyczy, ale `mk/repo.mk` — pułapka `;` vs `&&`) | `bash scripts/verify.sh --fast` + jeden pełny `eos-build.sh <arch>` przy zmianie ścieżki budowania | wymuszony błąd w celu podrzędnym → `make` kończy się ≠ 0 |
| `scripts/*.sh`, `scripts/hooks/*` | `shellcheck -S error` (blokuje) i `-S warning` (doradczo, ale nowe trafienia w skryptach **własnych** się usuwa), kontrole 5/13 (`set -u` w `$(( ))`, tablice pod `set -u`), **nagłówek z opisem i `--help`**, kod wyjścia 1 ≠ 2 (§11.3) | `bash scripts/verify.sh --fast` | uruchom skrypt na wejściu, na którym ma paść — musi paść, a nie zakończyć się 0 (§5.9, poziom 2) |
| `scripts/*.py` | `python3 -m py_compile`, kontrola 14 (ścieżki w dokumentach), `pyflakes` gdy jest | `bash scripts/ci-integrity.sh` | jak wyżej |
| `.gitlab-ci.yml`, `.github/workflows/*.yml` | `yamllint`, `actionlint` (GitHub), `glab ci lint` (GitLab); żadne nowe `allow_failure: true` bez zdania *dlaczego* w komentarzu; każda nowa bramka ma `rules`, które **kiedyś są prawdziwe** | `bash scripts/verify.sh --fast` (etap `actionlint`) + `glab ci lint` | `allow_failure` przypadkowo `true` → recenzent ma to zobaczyć w diffie; dla joba: podmień polecenie na `false` na gałęzi i sprawdź, że pipeline jest czerwony |
| dokumentacja (`*.md`, `docs/SUMMARY.md`) | kontrola 14 (`eos-check-doc-paths.py`), kotwice `](#...)` istnieją, **brak zdublowanych numerów podsekcji**, CRLF zachowane tam, gdzie przypięte (`CHANGELOG.md`), `lychee --offline` gdy jest, `mdbook build` gdy zmienia się `SUMMARY.md`; **ROADMAP:** każdy nowy ID unikalny w rodzinie (Annex A), status ✅ tylko z dowodem `U-NNN`/MR/#issue w tym samym wierszu | `python3 scripts/eos-check-doc-paths.py && bash scripts/ci-integrity.sh` + `scripts/eos-check-roadmap.py` (kotwice, duplikaty, ID) | wstaw ścieżkę do nieistniejącego pliku → kontrola 14 czerwona; zdubluj `### 6.3` → skrypt czerwony |
| `docs/roadmap/index.html` (strona statusu) | kontrola 19 (`eos-check-roadmap-page.py`): każdy kafelek kamienia milowego **pokazuje** znacznik z `ROADMAP.md` §3.4, każdy cytowany identyfikator istnieje jako wiersz roadmapy, każdy `ADR-NNNN` jako plik w `docs/adr/`. Strona **nie jest** drugą roadmapą — jest jej widokiem | `python3 scripts/eos-check-roadmap-page.py && bash scripts/ci-integrity.sh` | przestaw znacznik po jednej ze stron → czerwono z nazwą kamienia; ukryj `ROADMAP.md` → **exit 2**, nie 1 |
| `CHANGELOG.md` | wpis `U-NNN`/MR z **czym zweryfikowano**; CRLF; numer nie użyty wcześniej; **wpis stoi w sekcji, do której należy** — kontrola 20 odmawia, gdy wiersz pod `## [x.y.z] - DATA` cytuje datę **późniejszą** niż to wydanie | `bash scripts/ci-integrity.sh` (CRLF, sekcje) | przenieś dzisiejszy wpis pod wydane `[0.2.0]` → czerwono z numerem wiersza |
| `CLAUDE.md` | każde nazwane polecenie/skrypt/sekcja istnieje (kontrola 14 + `grep -n 'CLAUDE.md §'` w repo, gdy zmieniasz numerację) | jak dokumentacja | usuń nazwany skrypt → kontrola 14 czerwona |
| `keys/`, `.gitleaks.toml`, `osv-scanner.toml`, `deny.toml` | `gitleaks detect` na drzewie, `pins --strict`, dla kluczy: **wyłącznie publiczne** i opisane w `keys/README.md` | `bash scripts/verify.sh` (etapy `gitleaks`, `cargo-deny`, `osv-scanner`) | podłóż fałszywy klucz prywatny w tymczasowym pliku → `gitleaks` czerwony (i usuń go) |
| `assets/`, `docs/img/` | żaden plik > 5 MB bez pytania (§7); brak duplikatów (ta sama suma w dwóch katalogach); każdy obraz cytowany z dokumentu | `scripts/eos-check-assets.sh` | duplikat → czerwono |
| receptura nowego produktu / repozytorium typu A | pin w `repos.toml` **i** w recepturze zgodny (`pins --strict`), lustro GitHub zsynchronizowane, boot-smoke z nowym pakietem, wiersz w README *Shipped* | `bash scripts/eos-repos.sh pins --strict && bash scripts/ci-boot-smoke.sh <arch>` | rozjazd pinów → `pins --strict` ≠ 0 |

**Trzy pułapki, przez które ta tabela istnieje.** (1) Zmiana „tylko w dokumentacji" scaliła
`docs/architecture/overview.md` jako drugi punkt wejścia obok `ARCHITECTURE.md` i przez rok nikt nie
wiedział, który jest pierwszy (Annex C.2 roadmapy). (2) `ROADMAP.md` dostał dwa razy `### 6.3`
(2026-09-02) — kotwica wskazywała pierwszy, treść była w drugim; żadna bramka tego nie widziała.
(3) `.github/workflows/docs.yml:6` przez tygodnie wskazywał nieistniejącą ścieżkę, bo kontrola 14
wyłączała się na całej linii z URL-em (§1.4 roadmapy). Każda z tych trzech była „zmianą bez ryzyka".

---

## 6. Definicja ukończenia

Zmiana jest skończona, gdy **wszystkie** punkty są prawdziwe:

- [ ] Build przechodzi — `bash scripts/eos-build.sh <arch>` kończy się `Done.`
- [ ] Testy przechodzą — pełny zestaw, nie wybrany podzbiór
- [ ] `shellcheck` bez błędów, `clippy` bez ostrzeżeń w kodzie własnym
- [ ] `bash scripts/ci-integrity.sh` → `integrity: PASS`
- [ ] **Kontrola z tabeli §5.11 dla każdego rodzaju zmienionego pliku** uruchomiona, wynik wklejony; brak bramki dla rodzaju = najpierw bramka
- [ ] `gitleaks`, `osv-scanner`, `hadolint` bez nowych trafień
- [ ] **Artefakt sprawdzony** — nie tylko kod wyjścia (§5.3)
- [ ] Test **negatywny** istnieje dla każdej dodanej kontroli (§5.4)
- [ ] **Mutacja wykonana** — kontrola widziana na czerwono, i to ta właściwa (§5.9, poziom 2)
- [ ] **Kontrola przeciwna** — ten sam pomiar na kodzie sprzed zmiany (§5.9, poziom 4)
- [ ] **Pokrycie przed i po** w opisie zmiany; podłoga nie spadła (§5.10)
- [ ] Poziomy testowania z §5.9 przejrzane; każdy pominięty **uzasadniony**, nie przemilczany
- [ ] Prawdziwe wyjście poleceń wklejone do opisu MR
- [ ] Dokumentacja zaktualizowana w tym samym MR (§5.8)
- [ ] **Doc-comments** — `//!`/`///` na każdym nowym elemencie publicznym (`pub fn/struct/enum/trait/mod`); ten sam punkt stoi w szablonie MR (`.gitlab/merge_request_templates/Default.md:19`), który twierdzi, że powtarza tę listę — do 2026-09-02 twierdził nieprawdę, bo tej pozycji tu nie było. `eos-ui` egzekwuje to lintem `#![warn(missing_docs)]`; pozostałe crate'y własne jeszcze nie (`API-003`)
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
| P-1 | ~~**`make` nie przebudowuje narzędzi hosta**~~ — **NAPRAWIONE `f667d9c12`, 2026-08-30**: `mk/fstools.mk:72` daje `$(FSTOOLS_TAG)` 29 prerekwizytów źródłowych przez `COOKBOOK_HOST_SRC` (`:70`). Wpis zostaje jako historia, bo `eos-build.sh` nadal przebudowuje je jawnie — to już pas bezpieczeństwa, nie obejście | — | — |
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
| P-13 | **Powłoką hosta jest zsh, a on nie wypełnia `PIPESTATUS`** | `${PIPESTATUS[0]}` i `${PIPESTATUS[1]}` są **puste**, więc `EXIT=` wychodzi puste i wygląda jak sukces | w zsh użyj `${pipestatus[1]}` (od 1); w skryptach wołaj `bash`, gdzie `PIPESTATUS` działa |
| P-14 | **`eos-build.sh:33` synchronizuje repozytorium do drzewa budowania przed KAŻDĄ budową** (`eos-sync-buildtree.sh --apply`) | łatka diagnostyczna wstawiona w `/work/redox/config/...` **znika** przed kompilacją, a przebieg wygląda na wykonany — 2026-09-02 dwa przebiegi „diagnostyczne" testowały niezmienioną konfigurację i niemal doprowadziły do fałszywego wniosku „to nie ten getty" | zmiany plików **śledzonych** (konfiguracja, skrypty) testuj w repozytorium; drzewo nadaje się tylko na łatki w miejscach, których sync nie dotyka (np. `recipes/*/source`). Po budowie sprawdź, że zmiana **jest** w drzewie, zanim uwierzysz w wynik |
| P-15 | **Bash 3.2 (powłoka systemowa macOS) kończy SKRYPT kodem 0, gdy `set -u` trafi na nieustawioną nazwę wewnątrz `$(( ))`** | zmierzone 2026-09-02: `echo "$UNSET"` → status 1, ale `x=$(( 1 + UNSET ))` → status **0**, mimo wypisanego `unbound variable`. Bramka przerywa się w połowie i melduje CI sukces. Złapane w `ci-boot-smoke.sh`: wywołanie `<obraz> --arch x86_64` (forma z jego własnej linii użycia) wstawiało `--arch` do `TIMEOUT`, a stamtąd do arytmetyki | nie wpuszczaj wartości pochodzących z argumentów do `$(( ))` bez walidacji (`case "$X" in ''|*[!0-9]*) ... esac`). Uzupełnia P-13: zsh nie ma `PIPESTATUS`, bash 3.2 gubi kod wyjścia — obie psują wnioskowanie po statusie |
| P-16 | **`mktemp -d` na macOS ignoruje `TMPDIR`** — bez szablonu BSD `mktemp` pyta system o katalog tymczasowy (`_CS_DARWIN_USER_TEMP_DIR`) i **nie patrzy na zmienną środowiskową**, więc `TMPDIR=/duzy/wolumen` nie przekierowuje niczego | zmierzone 2026-09-03: `TMPDIR=/Volumes/EOS-Podman/tmp bash -c 'mktemp -d'` → `/var/folders/…/tmp.Sri6BifKTz`; to samo w podpowłoce wnuka. Skutek: `eos-esp-add-cert.sh` kopiuje obraz 1400 MiB na **dysk wewnętrzny**, a nie tam, gdzie wskazano. Przy 578 MiB wolnego 40-minutowa budowa padła na **ostatnim** kroku (`fcopyfile failed: No space left on device`), po poprawnym złożeniu obu obrazów | podawaj szablon jawnie: `mktemp -d "${TMPDIR:-/tmp}/nazwa.XXXXXX"`. I sprawdzaj miejsce **przed** kopiowaniem obrazu, nie po — §21.1 mówi „zmierz, który dysk boli”, a ten krok nie mierzył żadnego |

---

## 9. Skrypt weryfikacyjny

Jedno polecenie uruchamiające cały §5.2 **istnieje** — ta sekcja przez tygodnie twierdziła, że nie
(nazywała je `eos-verify.sh` i „PENDING"), podczas gdy `scripts/verify.sh` miał 16 etapów i chodził
przed każdym commitem (§13.1). Poprawione 2026-09-03; to samo zdanie stoi w ROADMAP §11.3.

```bash
bash scripts/verify.sh              # 16 etapów; --fast pomija wolne skany i mówi o tym w podsumowaniu
```

Haki lokalne są w `lefthook.yml`. **Zmierzone 2026-09-03 rano: na tym hoście nie były
zainstalowane** (`.git/hooks` zawierał tylko pliki `*.sample`, `core.hooksPath` pusty), więc
opisywany w README i `docs/security/index.md` „zamknięty na czerwono" skan sekretów przed commitem
**nie chodził** na tej maszynie, a `scripts/hooks/pre-push` też nie. **Naprawione tego samego dnia**
(`RH-006`): `lefthook install` + linia `hygiene`, której żąda nagłówek `.pre-commit-config.yaml`,
więc dziesięć hooków z tego pliku wreszcie gdziekolwiek chodzi. Sprawdzaj artefakt, nie kod wyjścia:

```bash
brew install lefthook pre-commit && lefthook install && ls .git/hooks | grep -v sample
bash scripts/verify.sh --fast   # etap `hooks` — pada, gdy w TEJ kopii roboczej haka nie ma
```

**Dowód, że hak naprawdę odmawia**, a nie tylko istnieje: podstawiony token kształtu
`glpat-<20 znaków>` daje `leaks found: 1`, `git commit` kończy się **kodem 1**, czubek gałęzi się
nie zmienia. Uwaga na pułapkę pomiaru — pierwsza próba użyła **przykładowego klucza AWS
z dokumentacji**, który reguły `gitleaks` mają na liście dozwolonych: wynik brzmiał
`no leaks found`, commit przeszedł i wyglądało to **dokładnie jak zepsuty hak**. Mutacja, która
chybia, jest nie do odróżnienia od bramki, która nie działa (§5.9 poziom 2).

`.pre-commit-config.yaml` **nie jest** drugim menedżerem haków — jego własny nagłówek każe wywoływać
go *z* lefthooka, i od 2026-09-03 ta linia w `lefthook.yml` stoi.

Ma to znaczenie praktyczne, ale **nie tak jednoznaczne, jak tu wcześniej stało**. Limit minut
współdzielonych GitLaba wyczerpuje się **z przerwami**, a nie na stałe od 2026-08-28: był
wyczerpany od 2026-08-28 do rana 2026-09-01, potem tego dnia przeszło **kilkadziesiąt** w pełni
zielonych przebiegów, a późnym popołudniem wyczerpał się ponownie. Warstwa **własnego** runnera
minut nie zużywa i chodzi niezależnie — `build-image` przeszedł 2026-09-01 o 19:14 UTC.
Bramki lokalne **nie są** więc jedyną działającą kontrolą; są jedyną, o której z góry wiadomo,
że się wykona. Szczegóły:
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

**37 repozytoriów** w `repos.toml`. GitLab jest źródłem prawdy, GitHub lustrem tylko do odczytu
(`ADR-0001`). **Pomylenie typu repozytorium jest najkosztowniejszym błędem, jaki tu można popełnić.**

Listy poniżej są **sprawdzane maszynowo** wobec `repos.toml` przez `scripts/eos-check-repo-types.py`
(kontrola 7 w `ci-integrity.sh`). Rozjazd między tym plikiem a manifestem wywala bramkę — i o to chodzi.

### Typ A — komponenty własne E-OS

`E-OS` · `eos-control` · `eos-guard` · `eos-notes` · `eos-sysmon` · `eos-ui` · `eos-sheets` · `eos-slides` · `eos-drive` · `eos-store` · `eos-website` · `eos-support`

### Typ B — vendorowane lustra upstreamu *(READ-ONLY)*

`eos-coreutils` · `eos-extrautils` · `eos-ion` · `eos-liborbital` · `eos-netdb` · `eos-netutils` · `eos-orbclient` · `eos-orbterm` · `eos-redox-fatfs` · `eos-redoxer`

### Typ C — forki z łatkami E-OS

`eos-base` · `eos-bootloader` · `eos-installer` · `eos-kernel` · `eos-orbdata` · `eos-orbital` · `eos-orbutils` · `eos-pkgar` · `eos-pkgutils` · `eos-redoxfs` · `eos-relibc` · `eos-userutils` · `eos-users`

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

**Typ B — vendorowane lustro**
1. Zmiana pochodzi **wyłącznie** z `sync-forks.sh`, nigdy z ręki.
2. Różnica wobec upstreamu jest **zerowa** albo świadomie udokumentowana z powodem.
3. Pin podbity w `repos.toml` **i** w przepisie; `pins --strict` zielone.
4. Obraz przebudowany, `boot-smoke` PASS — synchronizacja lustra potrafi zmienić ABI.
5. **Sprawdzone, że to, co zbudowane, to to, co przypięte** (`eos-source-rules.sh`, §9).

**Typ C — fork z łatkami**
1. Wszystko z typu A, plus:
2. Każda łatka ma uzasadnienie i status wobec upstreamu.
3. `git rebase` na aktualny upstream **przechodzi bez konfliktów** albo konflikt jest
   rozwiązany i opisany.
4. Push na **oba** hosty przed podbiciem pina, każdy zweryfikowany `git ls-remote` (§1.6).

**Typ D — repozytorium pakietów**
1. Zmiana wyłącznie przez `publish-repo-pages.sh` / `publish-repo.sh`.
2. `repo.toml` **podpisany** — publikacja bez podpisu jest odmawiana, chyba że świadomie
   `EOS_ALLOW_UNSIGNED=1` (`U-120`), czego **nie robimy** dla niczego publicznego.
3. Żadnych luster (§11, typ D).
4. Klient potrafi zweryfikować manifest — a to **sprawdza się w artefakcie**, nie w forku
   (`U-164`).

## 13. CI/CD jako egzekutor, nie jako sugestia

**Stan faktyczny (17 zadań, 5 etapów):** `secret-scan` (gitleaks, pełna historia) ·
`integrity` (20 kontroli niezmienników plus sonda przyrządów jako kontrola 0) · `pin-check` (`pins --strict`) · `docs-currency` ·
`renovate` · `rust-checks` (fmt, clippy `-D warnings`, `cargo test` na **obu** manifestach,
`cargo-deny check advisories`) · `shell-lint` (shellcheck: błędy blokują, ostrzeżenia
doradcze) · `pages` · `docs-pdf` · `semantic-release` · `build-image` ·
`build-image-x86_64` · `coverage` · `sbom` · `rustdoc` · oraz dwa zadania **scheduled**,
które wymagają sieci i klonują upstreamy: `mirror-drift` (blokujące) i `rebase-check`
(doradcze). Zaplanuj je w *Settings → CI/CD → Schedules*; dziennie w zupełności wystarczy.

**Zasada:** bramka na `|| true` jest **ozdobą**, nie bramką (`U-140`). Jeśli sprawdzenie
nie może zapalić się na czerwono, nie istnieje.

**Druga strona tej samej zasady (`U-177`): czerwone musi mówić, CO jest złamane — drzewo
czy przyrząd.** Kontrola, która nie mogła się wykonać, i kontrola, która wykryła usterkę,
wymagają przeciwnych reakcji, więc nie wolno im wypisywać tego samego komunikatu. Gorszy
wariant tej samej wady to zielone: `git grep` bez gita wypisuje pusto, a pusto czyta się
jak „czysto". Stąd w `ci-integrity.sh` osobne `FAIL (instrument):` i sonda narzędzi przed
pierwszą kontrolą — §4.2 zastosowane do samej bramki.

**Docelowo pipeline ma padać przy:**

| Warunek | Stan dziś |
|---|---|
| wykryty sekret (gitleaks) | ✅ **działa**, hook + CI na pełnej historii |
| CVE w zależnościach (`cargo-deny check advisories`) | ✅ **działa** na obu manifestach (`U-159`) |
| błędy shellcheck w `scripts/` | ✅ **działa** (ostrzeżenia jeszcze doradcze) |
| niezgodność pinów | ✅ **działa** (`pins --strict`) |
| składnia bash 4 na hoście z bash 3.2 | ✅ **działa** (kontrola 5) |
| **spadek pokrycia testami** | ✅ **działa** (`U-168`) — `coverage` gatuje `tools/eos-repo-sign` progiem 38% (zmierzona baza 38,84%); vendorowany manifest raportowany, nie gatowany |
| **typ repo niezgodny z tym, co fork faktycznie niesie** | ✅ **działa** (`U-169`) — `mirror-drift` porównuje `type` z `repos.toml` z pomiarem na forku i **pada**; offline'owy odpowiednik to kontrola 7 (`CLAUDE.md` §11 vs `repos.toml`) |
| **przepis z forkiem E-OS pobierany jako binarka upstreamu** | ✅ **działa** (`U-168`, kontrola 6) — `cookbook.lock` jest śledzony, a bramka pada z nazwą przepisu |
| **ciche znormalizowanie końców linii** | ✅ **działa** (`U-173`, kontrola 8) — `.gitattributes` powstrzymuje gita, kontrola 8 edytor: pada przed pushem, nazywając plik, któremu zniknął CRLF |
| **pusta tablica rozwijana pod `set -u`** | ✅ **działa** (kontrola 13) — skrypt PARSUJE się w bashu 3.2 i pada dopiero w czasie wykonania, na jednej gałęzi, więc kontrola 5 (wzorce składniowe) tego **nie widziała**. Zmierzone: `ci-install-smoke.sh` padł na `VIDEO_ARGS[@]: unbound variable`, a `ci-integrity` w tym samym drzewie wypisał `ok` i kod 0. Bramka wskazuje plik, linię i zmienną |
| **bramka, która nie mogła się wykonać** | ✅ **działa** (`U-177`) — brak `git`/`grep`/`awk` albo katalog spoza drzewa roboczego przerywa `ci-integrity.sh` **przed** pierwszą kontrolą; brak `python3` lub pliku pomocniczego pada jako `FAIL (instrument):` w kontroli 6 i 7, nigdy jako złamany niezmiennik |
| **konflikt rebase łatek** | ⚠️ **doradcze** (`U-169`) — `rebase-check` wykrywa konflikt przez `git merge-tree`, ale nie blokuje: ruch upstreamu to nie nasza usterka, chodzi o to, by dowiedzieć się **teraz**, a nie przy następnej synchronizacji |
| **`cargo-audit`** | ⚠️ świadomie pominięty w CI jako nadmiarowy wobec `cargo-deny`; lokalnie w `local-scan.sh` |

Braki są wypisane w **TODO** na końcu tego dokumentu. Nie udawaj, że istnieją.

### 13.1 `scripts/verify.sh` — jedno polecenie przed **każdym** commitem

```sh
bash scripts/verify.sh            # pełny łańcuch
bash scripts/verify.sh --fast     # bez wolnych skanów — NIE jest pełną weryfikacją
bash scripts/verify.sh --help
```

Skrypt przechodzi cały łańcuch — format → lint → typecheck → build → test → bramki projektu →
skany bezpieczeństwa — i **kończy się kodem niezerowym przy dowolnej porażce**. **Wywołuje** te
same polecenia co pipeline'y (`ci-integrity.sh`, `cargo fmt/clippy/check/build/test`,
`shellcheck`, `actionlint`, `hadolint`, `cargo-llvm-cov`, `gitleaks`, `cargo-deny`,
`osv-scanner`, `semgrep`), a nie opisuje ich reguł po raz drugi — druga kopia reguły to kopia, która się
rozjeżdża (§6, `U-164`).

**Dlaczego wymagane, a nie zalecane.** Trzy pomiary, nie trzy opinie: bramki GitLaba padają
w ~0 s na `ci_quota_exceeded` od 2026-08-28 (C-7); GitHub Actions dla tego repozytorium **w
ogóle się nie uruchamia** — 2026-08-30 minimalny workflow `on: push` na świeżej gałęzi nie
wyprodukował **żadnego** przebiegu, ani zakolejkowanego, ani czerwonego (pomiar zostaje
powtarzalny **nie jest** — `.github/workflows/_canary.yml` nie ma ani na `main`, ani na żadnym
z obu zdalnych; został tylko jako nieaktualna referencja śledząca w jednym klonie. Albo wrócić
z pobieralnym kanarkiem, albo nie obiecywać powtarzalności); a C-6 mówi, że każdy commit w historii szedł
prosto na `main`, więc nawet działający pipeline sprawdzałby kod **po** publikacji i
zlustrzaniu. Przebieg na własnej maszynie jest dziś jedyną bramką, o której wiadomo, że się
wykona.

| Zachowanie | Dlaczego tak |
|---|---|
| brak narzędzia = `SKIPPED` **i kod niezerowy** | `gitleaks \|\| true` przepuścił podłożony klucz, drukując zielone (`U-140`); skaner nieobecny daje ten sam wynik co skaner wyłączony. Świadome odstępstwo: `--allow-missing` — wtedy podsumowanie wypisuje, czego **nie** zmierzono |
| `exit 1` ≠ `exit 2` | 1 = bramka **znalazła wadę**, naprawiasz drzewo. 2 = bramka **nie mogła się wykonać**, naprawiasz przybornik. Ten sam podział co `FAIL (instrument):` w `ci-integrity.sh` (`U-177`) |
| `--fast` pomija coverage, `cargo-deny`, `osv-scanner`, `semgrep` | …i mówi o tym w podsumowaniu: zielone z `--fast` **nie jest** pełną weryfikacją |
| każdy etap wykonuje się także po porażce wcześniejszego | jeden przebieg ma dać cały obraz, a nie pierwszą skargę |

**Czego `verify.sh` NIE dowodzi** — i nie udaje, że dowodzi: `pin-check` (**nie klonuje** —
robi po jednym `git ls-remote` na przypięty fork, 26 z nich, czyli 26 rund do github.com;
poprawione w przeglądzie 2026-08-30, wcześniej ten akapit i nagłówek `verify.sh` mówiły
„klonuje", czego `scripts/eos-repos.sh:104` nie robi), `docs-currency` (potrzebuje bazy diffa
MR), `mirror-drift` / `rebase-check` (zadania scheduled, te **klonują** każdy fork i jego
upstream), `build-image` + `ci-boot-smoke.sh` (podman i 37 GB cache'u, runner `eos-heavy`)
oraz `dependency-review` z `security.yml` — to zadanie **blokuje**, ale porównuje graf
zależności między bazą a głową pull requesta przez API GitHuba, a na laptopie nie ma pary
baza/głowa. Te uruchamiasz osobno — §20.5 i tabela wyżej.

**Zmierzone 2026-08-31 na tym drzewie** (macOS, `/bin/bash` 3.2), **16 etapów**:

| przebieg | wynik | kod |
|---|---|---|
| pełny, **przed** doinstalowaniem narzędzi | 13 PASS · 0 FAIL · 2 `SKIPPED (could not run)` | **2** |
| pełny, **po** `cargo install cargo-llvm-cov cargo-deny` | **15 PASS · 0 FAIL · 0 SKIPPED** | **0** |
| pełny, po dołożeniu etapu `release-pack` (`R-611b`) | **16 PASS · 0 FAIL · 0 SKIPPED** | **0** |

Ta para wierszy jest tu celowo — pokazuje **kierunek**, nie samą liczbę (§5.10 reguła 2).
Dwa `SKIPPED (could not run)` w pierwszym przebiegu to `coverage` i `cargo-deny`; obu
narzędzi po prostu nie było na hoście, i dlatego skrypt kończył się kodem **2**
(nie 1 — bramka nie znalazła wady, tylko nie mogła się wykonać).

**Poprawka wobec zapisu z 2026-08-30 (§2 reguła 4).** Poprzednia wersja tej tabeli mówiła
o **trzech** pominiętych etapach, w tym `tar-pins` „bramki nie ma". Bramka **jest** —
`scripts/eos-check-tar-pins.py` powstał 2026-08-30 wieczorem, a ten akapit i tekst pomocy
`verify.sh` nie zostały wtedy zaktualizowane. To ten sam koszt odkładania, o którym mówi
§5.8, popełniony w dokumencie, który tego zakazuje.

Bramka `tar-pins` przeszła **kontrolę mutacyjną** (§5.9 poziom 2), i to dwustopniową, bo
pierwsze podejście było fałszywe: usunięcie `blake3` z `recipes/libs/atk` dało wyłącznie
`advisory` i **exit 0** — `atk` nie leży w domknięciu obrazu, więc mutacja nie dotknęła
ścieżki blokującej. Dopiero usunięcie `blake3` z `recipes/terminal/bash` (jedna z **15**
receptur w domknięciu, które pinują tarball) dało **exit 1** z nazwą receptury; po
przywróceniu — exit 0 i czyste drzewo. Mutacja, która trafia obok, wygląda dokładnie jak
bramka, która nie działa; różnicę widać tylko wtedy, gdy się ją sprawdzi.

Kontrola negatywna (`§4.1`), dwie, obie zmierzone, nie założone: po podmianie etapu
`hadolint` na plik z błędnie sformułowaną instrukcją przebieg daje `hadolint FAIL` i
`exit 1`; po przywróceniu wcześniejszej usterki etapu `osv-scanner` (`-L` wskazujące
`Cargo.toml` zamiast `Cargo.lock`) — `osv-scanner FAIL` i `exit 1`. Skrypt potrafi zapalić
się na czerwono, nie tylko na zielono.

**Poprawka z przeglądu 2026-08-30, zostawiona widoczna (§2 reguła 4).** Etap `osv-scanner`
podawał do `-L` **manifest** `Cargo.toml`, a nie plik blokady. `osv-scanner` nie traktuje
tego jako węższego skanu, tylko kończy się kodem 127 z `could not determine extractor
suitable to this file` — więc vendorowany graf (163 pakiety, ten z zależnościami `git`)
**nie był w ogóle sprawdzany**, a bramka meldowała to jako wadę drzewa. Po poprawce:
163 + 57 pakietów, `osv-scanner.toml` wczytany, `0 issues`. Dołożony został też etap
`hadolint`, bo `lint.yml` `containerfiles` **blokuje** na `podman/*containerfile`, a
`verify.sh` twierdził wcześniej, że żadne zadanie w tym drzewie hadolinta nie uruchamia.

Łańcuch jest dziś **kompletny na tym hoście** — ale zieleń 16/16 kupiona jest tym, że ktoś
doinstalował dwa narzędzia. Na czystej maszynie ten sam commit da 14 PASS · 2 SKIPPED i kod 2, i to jest
zachowanie **poprawne**: brak skanera daje ten sam wynik co skaner wyłączony, więc skrypt
odmawia nazwania tego zielonym. Nie zamykaj tego przez `--allow-missing`.

**Była tu znana flaga w vendorowanym manifeście — **naprawiona `758be384e`, 2026-09-01**.
`cook::cook_build::tests::file_system_loop_no_infinite_loop` padał, bo czytał globalną
konfigurację inicjowaną przez **inny** test w tym samym binarium. Nie był to wyścig o CPU, jak
tu wcześniej stało, tylko **deterministyczna zależność od zestawu celów**: przechodził pod
`cargo test` i padał pod `cargo test --tests`, którego używa `llvm-cov`. Jest teraz jedna
wspólna konfiguracja testowa, inicjowana przez tego, kto pierwszy jej potrzebuje. Zmierzone po
poprawce: **0 porażek na 20** przebiegów bezczynnych i **0 na 6** przy obciążonym procesorze.
Wpis zostaje jako historia; jeśli ta nazwa testu znów się zaczerwieni, to **jest** regresja.
`verify.sh` tego **nie
obchodzi** przez `--test-threads=1`: lokalna zieleń kupiona rozjazdem z CI to nadal czerwony
pipeline, a flaga w bramce jest wadą do naprawienia, nie do schowania w bramce.

## 14. Bezpieczeństwo — kierunek i etapy

**Model docelowy:** bezpieczeństwo oparte na **zdolnościach** (capability-based), z
mikrojądrem jako TCB. Schematy i przestrzenie nazw Redoksa są mechanizmem — root **nie
jest** wszechwładny, bo dostęp zależy od zdolności, nie od UID-a (co zmierzono w `U-161`:
`sudo` i root padają identycznie).

**Etapami, świadomie, bez udawania że już są:**

1. **Kompartmentalizacja w duchu Qubes OS** — pakiet `contain` jako odpowiednik AppVM;
   `Namespace::fork()` jest nieuprzywilejowany i potrafi wyłącznie **zawężać**. Dziś
   wyłączony; włączenie i polityka per aplikacja to `R-1010`/krok 10 planu.
2. **Niemutowalny root w duchu Talos Linux** — obraz podpisany, aktualizacja A/B z
   wycofaniem (`R-706`, `R-707`, `R-710`).
3. **Enklawy (Gramine/SGX)** — dopiero po (1) i (2); dziś **poza zakresem**, wpisane jako
   kierunek, nie jako plan.

**Klucze podpisujące pakiety:** docelowo **HSM lub Vault**. Dziś klucz **tajny** leży poza
repozytorium w rękach operatora (`keys/README.md`), a w drzewie jest tylko część publiczna.
Klucz hybrydowy (ed25519 + ML-DSA-65) opisany w `docs/security/index.md`.
**Generowanie klucza jest działaniem człowieka (§10.1).**

**`unsafe`:** każdy blok z `SAFETY:` (§10.2), a docelowo `#![deny(unsafe_code)]`
w komponentach krytycznych własnych E-OS. Każdy pozostawiony `unsafe` ma nieść
uzasadnienie **oraz plan usunięcia**.

## 15. Dokumentacja — struktura docelowa

**Jest dziś:** mdBook (`book.toml`, `docs/SUMMARY.md`), 109 śledzonych plików w `docs/`
(78 markdownów), w tym
`docs/architecture/overview.md`, `docs/security/threat-model.md`, `docs/reference/hardware-matrix.md`,
`docs/design-*.md`, `docs/adr`-podobne uzasadnienia rozsiane po CHANGELOG-u.
`mdbook-mermaid` jest wpięty w `pages` i `docs-pdf`.

**Cele i ich stan** (`U-168` domknęło część z nich — kolumna *Stan* jest
aktualizowana przy każdej zmianie, nagłówek nie zastępuje tabeli):

| Cel | Stan |
|---|---|
| `docs/architecture/` z diagramami **Mermaid** | ✅ **jest** (`U-168`): topologia repozytoriów i ścieżka budowania, wpisane do `SUMMARY.md` |
| `docs/THREAT_MODEL.md` | ⚠️ **świadomie zostaje** `docs/security/threat-model.md` — 19 odsyłaczy w 11 plikach, w tym historyczny wpis CHANGELOG-a; zmiana nazwy dla samej wielkości liter zerwałaby je albo wymusiła przepisanie zapisu historycznego (§2 reguła 4) |
| `docs/adr/` — decyzje architektoniczne (ADR) | ✅ **jest** (`U-168`): szablon + ADR-0001…0004 wyciągnięte z realnych decyzji; CHANGELOG pozostaje dowodem |
| `docs/hardware/` — macierz kompatybilności | ⚠️ jest `docs/reference/hardware-matrix.md` + `HARDWARE.md` |
| CHANGELOG generowany z Conventional Commits | ⚠️ `semantic-release` jest w CI, ale wpisy `U-NNN` pisane są ręcznie i **niosą dowody** — automat ich nie zastąpi |
| Dokumentacja HTML ze zrzutami z QEMU | ⚠️ mdBook + `assets/screenshots/`; **MkDocs nie jest używany** |
| `rustdoc` dla API | ✅ **jest** (`U-168`): zadanie `rustdoc` publikuje dokumentację `tools/eos-repo-sign` jako artefakt |

## 16. Testowanie

**Jest dziś:** `cargo test` na obu manifestach (15 testów vendorowanego cookbooka + 9
w `eos-repo-sign`), `ci-boot-smoke.sh` (dowód bootu w QEMU **x86_64 i aarch64** — obie PASS,
exit 0, zmierzone 2026-09-01; #15 zamknięte),
`repro-intx-lines.sh` (10-konfiguracyjny strażnik regresji z kolumną czasu),
`ci-install-smoke.sh` (dwuetapowy dowód instalacji), `--selftest` w aplikacjach GUI.

**Docelowo — nic z poniższych nie jest jeszcze wpięte:**

- **`cargo nextest`** zamiast `cargo test` (równoległość, czytelny raport) — ❌ brak.
- **Testy integracyjne w QEMU dla x86_64 *i* aarch64** — ✅ **obie działają**
  (`boot-smoke: PASS — reached userspace login`, exit 0, zmierzone 2026-09-01).
  aarch64 był zepsuty przez część sierpnia — LTO scalało ramki stosu ponad stos DXE
  firmware'u (#15, `known-issues.md`). `build-image-x86_64` jest `manual`.

  Do 2026-09-01 stało tu: *„aarch64 działa; x86_64 nigdy nie był bootowany na tym
  hoście”*. Pierwsza połowa **była prawdziwa i przestała być**; druga **nigdy nie była
  prawdziwa**. Dowody, że aarch64 bootował: `R-401b/c/d` RESOLVED 2026-06-08
  (`docs/reference/known-issues.md`), `hardware-matrix.md` „boots to `eos login:`”
  zweryfikowane 2026-06-18, `build-troubleshooting.md` boot-smoke PASS 2026-07-24,
  oraz zrzut ekranu greetera `docs/img/eos-aarch64-live-iso-greeter.png` (800×600,
  wniesiony `c3a55959c`, 2026-08-14). Dowody, że x86_64 bootował: `U-169` w
  CHANGELOG-u, `ci-boot-smoke.sh:11` (pomiar 2026-08-21) i pomiar dzisiejszy.

  **Zapisane, bo sam się na to nabrałem:** najpierw przeszukałem wyłącznie
  `~/eos-artifacts/` — same awarie — i napisałem „brak zapisu udanego bootu aarch64”.
  To był wniosek z **jednego** katalogu ogłoszony jako wniosek ze wszystkich źródeł.
  Dowody leżały w `docs/`. Zanim napiszesz „nie ma dowodu”, wymień miejsca, w których
  szukałeś.
- **`cargo-fuzz`** dla parserów wejścia niezaufanego (matcher katalogu sterowników,
  `repo.toml`, deskryptory HID) — ❌ brak.
- **`miri`** dla kodu `unsafe` — ❌ brak.
- **Pokrycie (`cargo-llvm-cov`)** — ✅ **jest** (`U-168`). Zmierzone przy `U-168`: `tools/eos-repo-sign` **38,84%**, vendorowany cookbook **2,92%**. **Ponownie 2026-09-01: 41,06% i 6,26%** — oba wzrosły, próg 38% ma dziś ~3 punkty zapasu. Stare liczby zostają, bo to one uzasadniają wybór progu. Bramka obejmuje wyłącznie kod własny; próg 38% ma łapać **regresję**, a nie certyfikować 38% jako dobry wynik. Sprawdzone, że potrafi paść (przy progu 60% kończy się błędem).

## 17. Wydania — odtwarzalność i łańcuch dostaw

**Jest dziś:** `scripts/make-release.sh` (sumy SHA256 + podpis **minisign**, odmawia
publikacji niepodpisanej bez `EOS_ALLOW_UNSIGNED=1`), katalog `sbom/`, tag adnotowany
i podpisany (`v0.2.0`), pipeline `semantic-release`.

**Docelowo:**

- **Build odtwarzalny** — ten sam wejściowy commit daje bit w bit ten sam obraz.
  ⚠️ Dziś **nie jest zweryfikowany**, a `.config`/`cookbook.lock` poza gitem wprost temu
  przeczą (§9, `R-F20`).
- **SBOM (`cargo-cyclonedx`)** — ✅ **wpięty** (`U-168`): zadanie `sbom` generuje CycloneDX
  1.3 dla obu manifestów jako artefakt (zweryfikowane: 47 komponentów dla
  `eos-repo-sign`). SBOM-y obrazów w `sbom/` nadal powstają ręcznie.
- **Podpis artefaktów (`cosign`)** — ❌ brak; dziś minisign.
- **Podpisany obraz ISO** — ❌ brak; obraz to `harddrive.img`, ISO nie jest publikowane.

## 18. Praca z AI w tym repozytorium

1. **Zanim cokolwiek zmienisz — ustal typ repozytorium (§11)** i zastosuj reguły tego typu.
2. **Niejasne? Pytaj, nie zgaduj.** Dotyczy zwłaszcza granicy B/C: repo wyglądające na
   czyste lustro potrafi nieść kod E-OS (`U-164`).
3. **Mierz, nie wnioskuj** (§4.3). Trzy razy w jednej sesji opublikowano błędny wniosek
   wyprowadzony z tego, gdzie urwał się log.
4. **Sprawdź instrument, zanim uwierzysz w wynik negatywny** (§4.2).
5. **Nie twierdź, że działa, jeśli nie uruchomiłeś testów.** Cytuj wynik.
6. **Poprawiaj własne opublikowane wnioski jawnie** (§2, reguła 4; §4.5).
7. **Nigdy nie dotykaj tokenów i kluczy** (§5, §10.3). Zadania wymagające poświadczeń
   oddajesz człowiekowi.
8. **Łatka diagnostyczna żyje wyłącznie w drzewie build kontenera**, nigdy w forku, i jest
   cofana przed commitem — a obraz po cofnięciu przebudowany i sprawdzony `boot-smoke`.


## 20. Higiena drzew — rób to na bieżąco, nie „potem"

Ten rozdział powstał z pomiarów, nie z przeczucia. Każda reguła ma pod sobą konkretną
usterkę, która realnie kosztowała czas.

### 20.1 To repozytorium **nie jest** tym, z czego buduje `make`

`make` buduje z `/work/redox` w wolumenie `eos-work` — **osobnego klonu** lustra GitHub.
Nic ich automatycznie nie synchronizuje. Objaw rozjazdu jest **cichy**: `U-185` pokazał
przypięcie klucza, które poprawnie trafiło do `config/aarch64/eos.toml` *tutaj*, podczas gdy
build użył kopii *tam* — i obraz wyszedł bez klucza, **bez jednego błędu po drodze**.

> **Przed każdym budowaniem, którego wynik ma coś dowodzić:**
> ```
> scripts/eos-sync-buildtree.sh          # pokaż różnice
> scripts/eos-sync-buildtree.sh --apply  # wyrównaj
> scripts/eos-build.sh [arch]           # albo: zsynchronizuj I zbuduj w wolumenie
> ```
> Bez tego zdanie „obraz zawiera X" jest twierdzeniem o **nieznanym** drzewie.

### 20.2 Katalogi `<fork>-<gałąź>/` są nieaktualnymi migawkami, nie źródłem prawdy

Obok tego repozytorium leżało ~80 katalogów w rodzaju `eos-base-eos-july/`,
`eos-kernel-master/`, zduplikowanych dodatkowo w `E-OS Github/`. **To nie są repozytoria
gita** — to rozpakowane archiwa. Nie da się z nich pchać, nie widać w nich historii i
**starzeją się w ciszy**: w `U-186` żaden z nich nie zawierał poprawek `R-F18` ani `R-F24`,
choć obie były wypchnięte, a `eos-base-eos-july` odpowiadał rewizji `816546df^` — **jeden
commit przed** przypięciem.

Zostały **przeniesione do `../_archiwum-migawek/`, którego dziś nie ma** — sprawdzone 2026-09-01:
katalog projektu zawiera `E-OS/` i cztery ukryte pliki, `find` i `mdfind` nie znajdują archiwum,
Kosz jest pusty. Zdanie o przeniesieniu zamiast usunięcia przestało obowiązywać, i nie wiadomo
od kiedy. Pierwotnie trafiły tam razem z
`PRZECZYTAJ-MNIE.md` wyjaśniającym, czym są. Katalog projektu zawiera teraz **wyłącznie
`E-OS/` i to archiwum**. Jeśli kiedyś znów pojawią się takie katalogi obok repozytorium —
przenieś je tam od razu, zamiast czytać.

> **Czytając kod forka, czytaj fork** — świeży klon albo `recipes/*/source` w drzewie
> budowania po `--apply`. Migawka nadaje się do szybkiego zerknięcia i **do niczego więcej**.
> Diagnoza postawiona na migawce po wypchnięciu poprawki będzie fałszywa.

### 20.3 `recipes/*/source` nie jest czystym klonem upstreamu

Cookbook nakłada tam łatki receptury. `git checkout -- .` w takim drzewie **usuwa je** i
build pada w miejscu bez związku z przyczyną — w `U-185` na `unresolved imports
nix::unistd::Group, User` w `nushell`. Żeby odzyskać czysty stan, **usuń `source/` i
`target/`** i pozwól cookbookowi pobrać oraz załatać od nowa.

### 20.4 Łatka diagnostyczna żyje wyłącznie w drzewie budowania

Nigdy w forku, nigdy w commicie. Cofnij ją, **zanim** przypniesz nową rewizję — inaczej
`git checkout <rev>` w drzewie receptury odmówi nadpisania i build stanie (`U-185`).
Po cofnięciu przebuduj i przepuść boot-smoke, żeby wiedzieć, co naprawdę mierzysz.

### 20.5 Po wypchnięciu zmiany w forku — domknij pętlę od razu

W jednym ciągu, nie „przy okazji":

1. `git push` do **obydwu** zdalnych (`origin` **i** `gitlab` — forki nie mają lustra, §1.6),
2. zaktualizuj `pinned_rev` w `repos.toml` **oraz** `rev` w `recipes/*/recipe.toml`,
3. `scripts/eos-repos.sh pins` — musi dać `drift=0`,
4. `scripts/eos-sync-buildtree.sh --apply`,
5. przebuduj i uruchom bramkę, która tę zmianę pokrywa.

Pominięcie kroku 4 to dokładnie usterka z §20.1: pomiar dotyczy wtedy starego kodu.

### 20.6 Sprawdź przyrząd, zanim uwierzysz w wynik

`U-186`: audyt szukający „pracy, której nigdzie nie wypchnięto" porównywał pliki przez
`git hash-object`. Dla pliku **spoza** repozytorium git nie stosuje filtrów z
`.gitattributes`, więc plik z CRLF dostaje inny skrót niż jego znormalizowany odpowiednik w
historii — i **każdy plik z CRLF wychodził jako „nieobecny"**. Poprawny wywołanie to
`git hash-object --path <ścieżka-względna> <plik>`. Po korekcie: **0 z 3657** zamiast 6.

> Zanim zgłosisz brak czegoś, **udowodnij, że przyrząd znajduje to, co istnieje** (§4.2).
> Wynik negatywny z niesprawdzonego narzędzia to nie wynik.

### 20.7 `pgrep` bez `-f` nie widzi długich nazw procesów

macOS obcina `comm` do 15 znaków, więc `pgrep qemu-system-aarch64` **nigdy** nie trafia.
W `U-181` każdy odczyt „qemu: 0" był fałszywy, a ja na tej podstawie uznałem żywe przebiegi
za martwe i uruchamiałem kolejne, spowalniając te działające. Używaj `pgrep -f` albo `ps`.

## 21. Sprzątanie — kasuje się **plik**, nigdy **katalog**

### 21.1 Najpierw zmierz, **który** dysk boli — prawie nigdy ten, na który patrzysz

Zmierzone 2026-08-29, przed sprzątaniem: dysk **zewnętrzny** (drzewo projektu) miał
**1,2 TiB wolnego**, a **wewnętrzny** — 23 GiB przy 89 % zajętości. Sprzątanie w katalogu
projektu zwalniało więc miejsce tam, gdzie go nie brakowało.

> **Zanim skasujesz cokolwiek „dla miejsca": wypisz `df -h` OBU dysków i powiedz, który
> sprzątasz.** Bez tego zdania sprzątanie jest ryzykiem bez zysku.

**Układ nośników jest myląco rozproszony i warto go znać, zanim ktoś zaproponuje „przeniesienie
buildów na zewnętrzny" — bo one już tam są** (zmierzone `U-214`, ustawione 2026-08-15):

| gdzie | co | nośnik |
|---|---|---|
| `/Volumes/Project itp` (exFAT, 1,8 TiB) | drzewo projektu, repo, `~/eos-artifacts` **nie** | zewnętrzny |
| `/Volumes/EOS-Podman` (**APFS**, 300 GiB, sparsebundle na powyższym) | **dysk maszyny podmana** `eos-build-arm64.raw` (80 GB), a w nim wolumeny `eos-work` i `eos-root` | zewnętrzny |
| `~/.local/share/containers` | **dowiązanie** → `/Volumes/EOS-Podman/containers` — ten sam i-węzeł, nie kopia | — |
| `/System/Volumes/Data` (228 GiB) | system, `~/Library`, `~/eos-artifacts` | wewnętrzny |

Dwa wnioski, oba kosztowałyby czas, gdyby ich nie zapisać. Po pierwsze: **budowanie nie zajmuje
dysku wewnętrznego** — jedyne, co tam zostaje po pracy, to `~/eos-artifacts`. Po drugie:
sparsebundle jest **APFS-em na exFAT-cie**, więc maszyna dostaje porządny system plików mimo
nośnika — ale zależy od tego, żeby wolumen zewnętrzny był zamontowany i **czytelny**. Gdy
2026-08-29 macOS cofnął uprawnienie do wolumenów wymiennych, podman działał dalej wyłącznie
dlatego, że `diskimages-helper` trzymał już otwarte deskryptory; wymuszony `diskutil unmount`
wyrwałby wtedy nośnik spod działającej maszyny razem z 37 GB cache'u.

**`du` na exFAT myli się o rząd wielkości.** Jednostka alokacji to 1 MiB (`diskutil info` →
*Allocation Block Size*), więc każdy plik zajmuje minimum 1 MiB. Zmierzone: `recipes/` to
**6,6 GB według `du` i 1,9 MB realnej treści** w 3376 plikach — 99,97 % to puste miejsce
w klastrach, nie śmieci. Migawka forka Ion: **1,35 MiB treści w 906 MiB**. Cytuj **obie**
liczby — `du -sh` i sumę rzeczywistą — albo nie cytuj żadnej (§4.3).

### 21.2 Zasada nadrzędna — i dlaczego sama nie wystarcza

> **Kasuj wyłącznie to, co potrafisz odtworzyć jednym poleceniem — i zapisz to polecenie
> obok, we wpisie CHANGELOG-a, ZANIM skasujesz.**

Warunek **konieczny, nie wystarczający**. Dwa kontrprzykłady zmierzone w tym drzewie:

1. **Odtwarzalny ≠ te same bajty.** `release/*.tar.gz` odtwarza `publish-repo.sh` jednym
   poleceniem — ale skrypt **podpisuje manifest na nowo**, więc suma kontrolna wyjdzie inna.
   Pytanie brzmi nie „czy umiem to zbudować", tylko **„czy umiem odtworzyć TE bajty".**
2. **Odtwarzalny katalog potrafi zawierać nieodtwarzalny plik.** Drzewo w wolumenie `eos-work`
   jest w całości odtwarzalne — **poza `build/id_ed25519.toml`**, kluczem, którym podpisano
   78 opublikowanych pakietów, istniejącym w jednej kopii. `rm -rf build/` kasuje ten klucz;
   `rm build/jakiś-plik` — nie.

**Stąd forma reguły: kasujesz plik, nigdy katalog.** Wyjątek jest jeden i wprost usankcjonowany
w §20.3: `recipes/*/source` i `recipes/*/target`, bo cookbook odtwarza je od zera. Wszędzie
indziej **wylistuj pliki, przeczytaj listę, skasuj listę.**

Trzeci warunek, niezależny od odtwarzalności: **czy coś tego jeszcze nie czyta.**
`build/container.tag` ma **0 bajtów** i wygląda na pusty log — a `mk/podman.mk` czyni go
stemplem `make`. „Pliki zerowej długości" nie są bezpieczną kategorią; są kategorią, która
*wygląda* bezpiecznie. Tak samo `repo.tag` (`U-212`).

### 21.2b Gdy kontener nie czyta pliku, którego jest właścicielem — SELinux MCS

Objaw jest sprzeczny sam ze sobą i dlatego myli: `ls -n` pokazuje właściciela `0 0` i tryb `600`,
proces ma `CAP_DAC_OVERRIDE`, a odczyt zwraca `EACCES`. **Świeży plik `600` w tym samym katalogu
czyta się bez problemu** — i to jest krok, który rozstrzyga.

Przyczyna: maszyna podmana to Fedora CoreOS z SELinuksem w trybie `Enforcing`, a każdy kontener
dostaje **losową parę kategorii MCS**. Pliki dziedziczą kategorie kontenera, który je utworzył,
więc kontener z innymi kategoriami jest odcięty. Zmierzone (`U-218`) na kluczu podpisującym pakiety:

```
container_file_t:s0            id_ed25519.pub.toml   <- czytelny
container_file_t:s0:c22,c82    id_ed25519.toml       <- EACCES z każdego innego kontenera
```

Skutek był **cichy i kosztowny**: `cook` kończył się `Package archive error: Permission denied
… "Reading secret"`, więc **żaden pakiet x86_64 nie powstawał**, a `make` i tak składał obraz
z tego, co zastał. Rozpoznanie:

```bash
podman machine ssh eos-build 'sudo ls -Z <ścieżka-w-wolumenie>'
```

Naprawa to wyrównanie etykiety do katalogu (`s0`, jak reszta wolumenu) — **po sprawdzeniu, że
plik ma kopię zapasową**:

```bash
podman machine ssh eos-build 'sudo chcon -l s0 <ścieżka>'
```

Nie „naprawiaj" tego przez `--security-opt label=disable` — to wyłącza izolację dla całego
kontenera zamiast poprawić jeden plik.

### 21.3 Czego **nigdy** nie kasujesz

- **Klucze i wszystko bez kopii zapasowej.** `build/id_ed25519.toml`, `build/sb-signing/`,
  `build/boot-signing/`. Jeśli nie potrafisz wskazać drugiej kopii — to nie jest śmieć,
  to jedyny egzemplarz.
- **Wolumeny `eos-work` i `eos-root`** — 37 GB cache'u budowania. `--wipe-caches` nigdy.
- **Cokolwiek śledzonego przez gita.**
- **Artefakt, który jest dowodem.** Pułapka zmierzona w `U-214`: `eos-x86_64-harddrive.img`
  i `eos-x86_64-live.iso` wyglądały na automatyczny wypluwek builda i leżały **dokładnie pod
  ścieżką, którą `scripts/eos-build.sh` nadpisuje przy każdym uruchomieniu** — a były jedynymi
  nośnikami prawdziwego certyfikatu `CN=E-OS Secure Boot`. Dowód, którego nie da się odtworzyć
  jednym poleceniem, **przenieś do `~/eos-artifacts/dowody/` i nazwij tym, czego dowodzi.**

### 21.4 Wolno bez pytania

Tylko to, i tylko po przejściu §21.2:

| co | polecenie odtwarzające — **zapisz je we wpisie** |
|---|---|
| `tools/*/target/` | `cargo build --release --manifest-path tools/<nazwa>/Cargo.toml` |
| `recipes/*/source`, `recipes/*/target` | `make c.<przepis>` — procedura w §20.3 |
| `prefix/` w katalogu projektu | pobierze się sam z `static.redox-os.org`; build i tak używa kopii w wolumenie |
| sidecary `._*`, `.DS_Store` | `dot_clean -m .` — Finder odtwarza je sam, 0 śledzonych w gicie |
| twoja sonda / łatka diagnostyczna | ona i tak miała zniknąć — §20.4 |
| obrazy, których dowód jest **już zapisany** w CHANGELOG-u | `scripts/eos-build.sh <arch>` |

### 21.5 Wymaga pytania właściciela

Kosz systemowy, cudze projekty, archiwa, cokolwiek starszego niż bieżąca praca. Zmierz,
pokaż listę z rozmiarami i **poczekaj na odpowiedź** — nawet gdy jesteś pewien. Przy
`_archiwum-migawek` (51 GB) pewność była uzasadniona co do 16 713 z 16 715 plików; te dwa
pozostałe nie istniały nigdzie w gicie, bo publikacja orphan-commitem zniszczyła historię forka.
Kasowanie „całości, bo wszystko odtwarzalne" straciłoby je bezpowrotnie.

### 21.6 Trzy pułapki, które udają sukces

Wszystkie trzy zmierzone tego samego dnia (`U-224`), wszystkie kończyły się **zielonym buildem**:

1. **`make` NIE buduje narzędzi hosta.** `REPO_BIN` w `mk/config.mk` to zwykła ścieżka do
   `./target/release/repo`; make używa tego, co tam leży. Zmiana w `src/bin/repo_builder.rs`
   nie działa, dopóki ktoś ręcznie nie zbuduje binarki — build przechodzi, indeks wygląda
   poprawnie, a nowe pole **po prostu go nie ma**. `eos-build.sh` buduje je teraz zawsze.
2. **`cmd | tail` w kontenerze oddaje status `tail`, nie `cmd`.** `set -euo pipefail` w skrypcie
   zewnętrznym **nie obowiązuje** wewnątrz `bash -lc` — `cargo: command not found` przewinęło
   się bez zatrzymania czegokolwiek. Trzeba `set -o pipefail` po stronie kontenera.
3. **Przekierowanie tworzy plik zanim polecenie ruszy.** `podman run ... cat brak > plik`
   zostawia **plik zerowy**, który wygląda jak artefakt do wydania. Etapuj przez `.partial`
   i nie zostawiaj pustych.

Wspólny mianownik: **kontrola, która potrafi tylko przejść, nie jest kontrolą.** Po każdej
zmianie sprawdzaj sam artefakt (`strings` na binarce, `grep` na wygenerowanym pliku), a nie to,
że polecenie zwróciło zero.

### 21.7 Wolumen EOS-Podman: nie montuj przez `-mountpoint`

Nieudane `hdiutil attach -mountpoint /Volumes/EOS-Podman` **zostawia pusty katalog**, który
blokuje każdą kolejną próbę montowania — objaw wygląda wtedy jak uszkodzenie APFS
(„niemontowalny system plików", `mount_apfs: Input/output error`, `fsck` melduje zły
superblok). Katalogu nie usuniesz bez roota, bo `/Volumes` należy do roota. **Lekarstwo:**
`hdiutil detach /dev/diskN -force`, potem `hdiutil attach` **bez** `-mountpoint`. Uwaga: odczyt
surowych urządzeń (`dd if=/dev/rdiskN`) wymaga roota, więc „błąd 5" z `fsck_apfs` uruchomionego
jako użytkownik **nie jest dowodem uszkodzenia** — nie diagnozuj na tej podstawie.
Ten rozdział powstał z prośby o porządek („kasować niepotrzebne pliki, stare buildy, żeby nie
zajmowały miejsca") i z pomiaru, który tę prośbę **przeformułował** (`U-214`). Pomiar pokazał
trzy rzeczy naraz: sprzątano dysk, na którym było 1,2 TiB wolnego; prawie cały raportowany
rozmiar okazał się artefaktem systemu plików; a katalog, który każdy kasuje odruchowo, trzyma
klucz istniejący w **jednej kopii bez backupu**.

## 19. TODO — czego naprawdę brakuje

Ta lista jest tym, do czego odsyłają §13 i §16. Zasada: pozycja stąd znika dopiero, gdy
**da się wskazać dowód**, że rzecz działa — nie gdy została zaplanowana.

### Otwarte usterki (blokują `R-601`)

| ID | Rzecz | Stan |
|---|---|---|
| `R-F19` | `unmount_path` → `rmdir /scheme/<nazwa>` trafiało **do demona redoxfs**, nie do menedżera schematów, i odbijało się od korzenia (`EPERM`). | ✅ **naprawione** (`U-170`, `eos-redoxfs` `58824d7` + `eos-installer` `02be2b5`); **nie** potwierdzone end-to-end — ścieżka staje wcześniej na `R-F21` |
| `R-F21` | `package_files()` czytało bazę pakietów ze starej ścieżki `/pkg`. | ✅ **naprawione** (`U-171`) — czyta przez `PackageState::from_sysroot`; przepisane, bo klucz też się przeniósł do `packages.toml` |
| `R-F22` | `copy_file()` przewracało instalację na pierwszym pliku, który konfiguracja już zapisała (`/etc/issue`, 1 z 65 wpisów `[[files]]`). | ✅ **naprawione** (`U-171`) — istniejący cel pomijany; konfiguracja wygrywa |
| `R-601` | partycja → instalacja → reboot → login | ✅ **UDOWODNIONE** (`U-176`), potwierdzone ponownie **z poprawką `R-F18`** (`U-181`) |
| `R-F23` | Pod `hvf` gość ginie na `synchronous_exception_at_el0` przy obciążeniu — dwa razy, w dwóch różnych procesach, także przy `-smp 1`. | 🚧 P1 — harness zostaje na TCG; `EOS_SMOKE_ACCEL=hvf` odtwarza |
| `R-F24` | `try_fast_install()` czytał środowisko **procesu**, a zmienne live są w środowisku **jądra** (`/scheme/sys/env`). | ✅ **naprawione** (`U-176`) — 6,8 h → ~6 min |
| `R-F18` | Sterownik potwierdzał przerwanie **przed** sprawdzeniem, czy jego urządzenie coś zgłosiło — czyli odmaskowywał dzieloną linię za cudze przerwanie. | ✅ **naprawione** (`U-180`) — `virq 37` 16 829 830 → 8; 160 s → 16 s |

### Narzędzia, których w repo nie ma

| Narzędzie | Decyzja |
|---|---|
| `cosign` | ❌ Zadanie da się napisać, ale **klucz podpisujący generuje człowiek** (§5, §10.3) — narzędzie, które loguje, nie może go dotknąć. Do wykonania przez operatora, nie przez automat. |
| `nextest` | ⏳ Do podmiany za `cargo test`; korzyść to równoległość i czytelniejszy raport, nie nowa zdolność. Niski priorytet. |
| `miri` | ⛔ **Świadomie pominięty** — E-OS-owy kod Rust ma **zero** bloków `unsafe` (pilnuje tego kontrola 4), a `miri` bada właśnie UB w `unsafe`. Uruchamianie go na vendorowanym drzewie oznaczałoby utrzymywanie dywergencji (ADR-0003). |
| `cargo-fuzz` | ⛔ **Świadomie pominięty tutaj** — parsery warte fuzzowania (`pkgar`, RedoxFS, `redox_installer`) mieszkają w **forkach**, nie w tym repo. Miejsce dla nich to CI forka. |
| `cargo-audit` | ⛔ Nadmiarowy wobec `cargo-deny check advisories`; lokalnie w `local-scan.sh`. |

### Wymaga człowieka, nie automatu

- **`eos-setup-mirrors.sh --apply`** — potrzebuje PAT GitHuba. Nigdy nie podawaj tokenu
  narzędziu; to zadanie operatora (§5).
- **Klucz podpisujący** — generowanie jest **celowo** niezautomatyzowane.

### Nadal niezweryfikowane

- **Odtwarzalność builda** — ten sam commit → ten sam obraz bit w bit. `.config` i
  `cookbook.lock` są już **śledzone** (`U-168`, `U-169`), więc główna przeszkoda zniknęła,
  ale samego porównania **nikt jeszcze nie wykonał**. Dopóki nie wykona — to nie jest fakt.
- **SBOM obrazu** — `sbom` pokrywa manifesty Rusta; SBOM-y obrazów w `sbom/` nadal
  powstają ręcznie.
- **Podpisane ISO** — obraz to `harddrive.img`; ISO nie jest publikowane.

**Forki nie mają automatycznego lustra.** Push wymaga **dwóch** poleceń — na GitLab i na GitHub.
Repozytorium główne ma działające lustro; forki nie.
