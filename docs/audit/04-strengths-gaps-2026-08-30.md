# Mocne strony, luki i priorytety

**Data:** 2026-08-30 · **Tryb:** wyłącznie do odczytu
**Podstawa:** [`00-inventory`](00-inventory-2026-08-30.md) · [`01-code-audit`](01-code-audit-2026-08-30.md) · [`02-feature-inventory`](02-feature-inventory-2026-08-30.md) · [`03-security-audit`](03-security-audit-2026-08-30.md)

---

## 1. Mocne strony — konkretnie, nie ogólnikowo

**Te rzeczy trzeba chronić przy każdej refaktoryzacji.** Każda ma dowód.

| # | Mocna strona | Dlaczego to naprawdę dobre | Dowód |
|---|---|---|---|
| S-1 | **Łańcuch zaufania rozruchu z separacją domen** | ed25519 nad `SHA-512(role ‖ len_le ‖ data)`; weryfikacja **przed** magic bytes i przed użyciem bajtów; podpisany initfs **nie zweryfikuje się** jako jądro. To jest projekt, nie „dodaliśmy podpis" | `eos_boot_verify.rs:16-17,72-81`; `main.rs:436-451`; ciąg obecny w wysyłanych `.efi` |
| S-2 | **Podpis indeksu odporny na przyszłość** | hybryda ed25519 + **ML-DSA-65 (FIPS 204)**; **zweryfikowany na żywym, opublikowanym indeksie** (79 pakietów aarch64) — obie połowy przechodzą, po zmianie jednego bajtu obie odmawiają, kod wyjścia 1 | uruchomiony `eos-repo-sign verify` |
| S-3 | **Hasze pakietów egzekwowane na bajtach, na każdej ścieżce** | `install` też pobiera i weryfikuje manifest; wcześniej robił to tylko `update`. **33 testy** w forku, po obu stronach każdej bramki | `eos-pkgutils` rev `e28063ee`, `U-223` |
| S-4 | **Klucze faktycznie przypięte w obrazie** | `/etc/pkg/eos-repo-sign.pub.toml` **oraz** `[pubkeys.local] pkey = "abf34ee5…"` w `packages.toml`, bajtowo zgodny z `keys/` i z drzewem budowania | odczytane z zamontowanego obrazu |
| S-5 | **Higiena repozytorium na poziomie, którego nie ma większość projektów** | **0** śledzonych śmieci, **0** plików >1 MB, **0** nieśledzonych, **0** błędów shellcheck w 50 skryptach, **0** TODO w kodzie własnym, **0** sekretów w 8153 commitach | zmierzone |
| S-6 | **Wszystkie 26 przypięć zgadza się co do znaku z głowami gałęzi** | zero dryfu w ekosystemie 30 repozytoriów | `glab api` per gałąź |
| S-7 | **Sterowniki i stos sieciowy w przestrzeni użytkownika** | 16 sterowników jako procesy; awaria sterownika nie zabija jądra. To architektoniczna przewaga, nie hasło marketingowe | `/lib/drivers` w obrazie |
| S-8 | **Wybory kryptograficzne bez ani jednego błędu** | argon2id (`m=19456,t=2,p=1`), AES-XTS, blake3, ed25519, ML-DSA-65. **Zero MD5/SHA-1/RC4/DES** w roli bezpieczeństwa | przeszukanie kodu i obrazu |
| S-9 | **`cookbook.lock` i `.config` są śledzone i uzasadnione ADR-em** | świeży klon buduje to samo, co drzewo deweloperskie; bramka `ci-integrity.sh` kontrola 6 pada, gdy fork nie dostanie reguły `source` | `ADR-0002`, `U-168`, `U-169` |
| S-10 | **Kultura komentarza „dlaczego", nie „co"** | komentarze w `.gitlab-ci.yml`, recepturach i `CLAUDE.md` tłumaczą **powód** decyzji i **co zmierzono**. Rzadkie i bardzo wartościowe przy przekazywaniu projektu | całe repozytorium |
| S-11 | **CHANGELOG jako rejestr dowodów** | 1067 linii, każdy wpis z pomiarem i uzasadnieniem; da się odtworzyć, dlaczego coś wygląda tak, a nie inaczej | `CHANGELOG.md` |
| S-12 | **Odebranie schematu `ip` nieuprzywilejowanemu użytkownikowi** | brak surowych gniazd IP dla `user` — realne utwardzenie ponad upstream | `/etc/login_schemes.toml`, `R-904a` |
| S-13 | **Obraz nie niesie toolchainu ani pakietu testowego** | 20 zbudowanych pakietów nie zainstalowano, w tym `gcc13`, `gnu-binutils`, `os-test-bins` | `packages.toml` vs `repo/` |
| S-14 | **Skrypty zawodzą bezpiecznie tam, gdzie to policzono** | `publish-repo.sh` odmawia spakowania niepodpisanego indeksu; obejście wymaga jawnego `EOS_ALLOW_UNSIGNED=1` | `publish-repo.sh:44-48` |

---

## 2. Luki — uszeregowane wg wpływu × prawdopodobieństwa

| # | Luka | Wpływ | Prawdop. | Nakład | Pierwszy krok |
|---|---|---|---|---|---|
| G-1 | **Brak aktywnego kanału aktualizacji (x86_64)** | **krytyczny** — żadnej poprawki bezpieczeństwa nigdy | **pewne** (stan bieżący) | 1 d | opublikować repo x86_64 (klucz **jest**, kod **jest**) |
| G-2 | **TOFU dla 30 z 65 pakietów obrazu** | **krytyczny** — przejęcie `static.redox-os.org` = dowolny kod w obrazie | niskie–średnie | 4 h | przypiąć klucz upstreamu w `keys/` i porównywać |
| G-3 | **Brak piaskownicy aplikacji** | wysoki — kompromitacja przeglądarki = kompromitacja konta | średnie | 1–2 tyg. | schematy per proces dla `netsurf` |
| G-4 | **Weryfikacja rozruchu fail-open, ostrzeżenie tłumione** | wysoki — obraz bez weryfikacji wygląda identycznie | średnie | 30 min | `EOS_ALLOW_UNVERIFIED_BOOT=1` |
| G-5 | **CI martwe od 2 dni; bramki ustawione i omijane** | wysoki — cała siatka nie działa, a 0 MR-ów sprawia, że i tak by nie działała | **pewne** | 15 min + koszt | zablokować push na `main`; `lefthook` lokalnie |
| G-6 | **Brak trwałego dziennika audytu** | wysoki — po incydencie nie ma czego czytać | pewne | 1 tydz. | demon logów + rotacja |
| G-7 | **Brak zapory przy obecnym `sshd`** | wysoki | średnie | 2 tyg. | filtr pakietów albo wyłączyć `sshd` domyślnie |
| G-8 | **`git 2.13.1` i inne stare porty** | wysoki — 9 lat CVE w narzędziu klonującym cudzy kod | średnie | 4 h | wyjątek `source` + nowsza wersja |
| G-9 | **Zero testów kodu, który podpisuje i publikuje** | wysoki dla utrzymania — dwie wady w tydzień znalezione ręcznie | **pewne** | 2 d | testy dla `repo_builder` i `cook/package` |
| G-10 | **Build ciągnie źródła z lustra, nie ze źródła prawdy** | średni–wysoki | niskie | 2 h | przepiąć 22 receptury na `gitlab.com/e-os` |
| G-2b | **Tarball `mpc` bez sumy kontrolnej, z lustra podstawionego domyślnie** — dotyczy zależności kompilatora skrośnego | **krytyczny** — kontrola nad kompilatorem | niskie | 1 h | dopisać `blake3` z wydania GNU, nie z lustra |
| G-2c | **`blake3` niesprawdzany dla przepisów zależnych**, a zadeklarowany hasz publikowany jako tożsamość | wysoki — repozytorium twierdzi coś o niesprawdzonych bajtach | pewne na ścieżce toolchainu | 3 h | liczyć hasz niezależnie od `is_deps` |
| G-11 | **Cztery klucze prywatne na maszynie budującej = runnerze CI** | wysoki, jeśli maszyna padnie | niskie | 1 tydz. | oddzielić podpisywanie |
| G-12 | **Brak konta awaryjnego** | **krytyczny dla ciągłości** | niskie, ale nieodwracalne | 1 d | drugi maintainer albo procedura |
| G-13 | **Podatny `rustls-webpki` w wysyłanym `pkg`** | wysoki, gdy kanał ruszy | średnie | 2 h | podbić fork |
| G-14 | **Dokumentacja rozjeżdża się z produktem** | średni — README twierdzi rzeczy nieprawdziwe (klucz „nie istnieje", `eos-guard`/`eos-sysmon` „shipped") | **pewne** | 3 h | bramka na wartość markera SYNC, nie obecność |
| G-15 | **`make` nie przebudowuje narzędzi hosta** | średni, ale **cichy** | pewne bez obejścia | 1 h | prerekwizyty źródłowe w `mk/fstools.mk` |
| G-16 | **Kontener budowania niereprodukowalny** | średni | pewne | 2 h | przypiąć wersje apt |
| G-17 | **Rozjazd wersji w 4 miejscach** (obraz mówi 0.1.0, tag `v0.2.0`) | średni | pewne | 1 h | jedno źródło wersji |
| G-18 | **Brak Wi-Fi** | średni dla użyteczności | pewne | 1 mies.+ | decyzja produktowa |
| G-19 | **Brak SAST** | średni | — | 4 h | `semgrep` w CI i hooku |
| G-20 | **SBOM tylko dla 0.1.0** | niski–średni | pewne | 2 h | generować per tag |

---

## 3. Backlog priorytetowy

### P0 — zrobić w tym tygodniu

| Zadanie | Nakład | Dlaczego P0 | Odn. |
|---|---|---|---|
| Zablokować bezpośredni push na `main` | **15 min** | bramka `only_allow_merge_if_pipeline_succeeds` **już jest włączona** i całkowicie omijana. Najtańsza poprawka w całym audycie | C-6, G-5 |
| `EOS_ALLOW_UNVERIFIED_BOOT=1` wymagane do budowy bez klucza | **30 min** | dziś maszyna bez klucza cicho produkuje obraz bez weryfikacji rozruchu, a ostrzeżenie zjada `\| tail -3` | C-2, G-4 |
| Naprawić panikę `repo` przy pustym wyniku wyszukiwania | **15 min** | `repo.rs:1700` indeksuje pusty wektor; wywala TUI w trakcie długiego budowania | A §5.3 |
| Dopisać `keys/eos-pkg-signing.pub.toml` do allowlisty gitleaks **z uzasadnieniem** | **15 min** | po odnowieniu limitu `secret-scan` padnie i będzie wyglądać na regresję | C-19 |
| Prerekwizyty źródłowe dla `$(FSTOOLS_TAG)` | **1 h** | usuwa przyczynę „build zielony, ochrona nieobecna" | C, A §5.1, G-15 |
| Wskazać w README **własną** kopię `podman_bootstrap.sh` | **15 min** | dziś pierwsze polecenie nowej osoby to `curl | bash` z ruchomej gałęzi cudzego repo | A §2.3 |
| Poprawić trzy nieprawdziwe zdania w README i `CLAUDE.md` §11 | **1 h** | „klucz nie istnieje" (istnieje), „`eos-guard`/`eos-sysmon` shipped" (nie ma ich w obrazie), „`sync-forks.sh` nie ma w tym repo" (jest) | G-14 |

**Suma P0: ~3,5 godziny.** To jest cały koszt zamknięcia sześciu problemów, w tym dwóch o wadze HIGH.

### P1 — w tym miesiącu

| Zadanie | Nakład | Odn. |
|---|---|---|
| Dopisać `blake3` do `recipes/libs/mpc/recipe.toml` **i** zamienić `break` w `fetch.rs:394` na twardy błąd | 1 h | C-1b, G-2b |
| Liczyć `blake3` niezależnie od `is_deps`; `ident` z policzonego hasza | 3 h | C-1c, G-2c |
| Przypiąć klucz upstreamu i porównywać w `sync_keys()` | 4 h | C-1, G-2 |
| Opublikować repozytorium x86_64 i włączyć `50_eos` | 1 d | C-4, G-1 |
| Republikować indeks aarch64 z `serial`/`expires` | 1 d | C-12 |
| Podbić fork `eos-pkgutils` (`rustls-webpki`, `ring`, `rand`) | 2 h | C-3, G-13 |
| Testy dla `repo_builder.rs` i `cook/package.rs` | 2 d | G-9 |
| `osv-scanner` do CI **i** do `lefthook` | 1 h | C-13 |
| Przypiąć wersje apt w plikach kontenerów | 2 h | C-17, G-16 |
| Zbudować `git` ze źródła w nowszej wersji | 4 h | C-8, G-8 |
| Przepiąć 22 receptury z lustra na `gitlab.com/e-os` | 2 h | G-10 |
| Jedno źródło wersji produktu | 1 h | G-17 |
| Drugi maintainer albo udokumentowana procedura odzyskania | 1 d | C-18, G-12 |
| SBOM generowany i commitowany per tag | 2 h | C-14 |

### P2 — kwartał

| Zadanie | Nakład | Odn. |
|---|---|---|
| Piaskownica: schematy per proces, zaczynając od `netsurf` | 1–2 tyg. | C-5, G-3 |
| Demon logów i rotacja | 1 tydz. | C-6, G-6 |
| Filtrowanie pakietów albo świadome wyłączenie `sshd` domyślnie | 2 tyg. | C-10, G-7 |
| Oddzielić podpisywanie od maszyny budującej | 1 tydz. | C-11, G-11 |
| `semgrep` w CI | 4 h | C-15, G-19 |
| Podbić `linked_list_allocator` do ≥0.10.2 | 2 h | C-16 |
| Rozstrzygnąć semantykę schematów `debug`/`memory`/`irq` dla `user` | 2 d | C-21 |

### P3 — kiedyś, świadomie

Wi-Fi · kopie zapasowe · VPN/Tor · OpenSSF Scorecard · DAST · antywirus
(ostatni prawdopodobnie **nigdy** — monitor integralności jest właściwszą odpowiedzią)

---

## 4. Konfrontacja z porównywalnymi projektami

Porównanie po **właściwościach**, nie po marketingu. „Ahead/level/behind" dotyczy konkretnej cechy.

| Cecha | E-OS | Qubes | Tails | Whonix | Silverblue | NixOS | GrapheneOS | Pozycja E-OS |
|---|---|---|---|---|---|---|---|---|
| **Bezpieczeństwo pamięciowe rdzenia** | jądro, sterowniki, libc, większość userlandu w **Rust** | C (Xen+Linux) | C | C | C | C | C + hardened malloc | **AHEAD** — nikt z tej listy nie ma jądra w Rust |
| **Izolacja sterowników** | user-space, awaria nie zabija jądra | VM per urządzenie | monolit | monolit | monolit | monolit | monolit | **AHEAD** względem wszystkich poza Qubes; **BEHIND** Qubes |
| **Izolacja aplikacji** | **brak** — granica po koncie | **VM per aplikacja** | AppArmor | VM | Flatpak+bwrap | bwrap | seccomp+SELinux per app | **BEHIND WSZYSTKICH** |
| **Podpis indeksu pakietów** | **hybryda PQ** ed25519+ML-DSA-65 | RPM/GPG | APT | APT | RPM/GPG | podpisy narzędziowe | podpisy Android | **AHEAD** — nikt nie wysyła hybrydy PQ |
| **Weryfikowany rozruch** | ed25519 z separacją domen, fail-closed | AEM/TPM | — | — | Secure Boot | Secure Boot (lantif) | **verified boot + rollback** | **LEVEL** z Silverblue; **BEHIND** GrapheneOS |
| **Kanał aktualizacji** | **nieaktywny (x86_64)** | działa | działa | działa | atomowy | atomowy | atomowy + A/B | **BEHIND WSZYSTKICH** — to jest najgorsza pozycja E-OS |
| **Reprodukowalność budowania** | brak (apt bez wersji, znaczniki czasu) | częściowa | **wysoka** | wysoka | częściowa | **najwyższa w branży** | wysoka | **BEHIND** |
| **Aktualizacje atomowe / rollback** | brak | — | amnezja z założenia | — | **tak** | **tak** | **tak** | **BEHIND** |
| **Szyfrowanie dysku** | AES-XTS, opcjonalne | LUKS, domyślne | trwałe wolumeny | LUKS | LUKS | LUKS | domyślne, sprzętowe | **BEHIND** (opcjonalne vs domyślne) |
| **Anonimowość sieciowa** | brak | opcjonalna | **cała przez Tor** | **cała przez Tor** | brak | brak | brak | N/D — inny cel |
| **Dojrzałość ekosystemu** | 65 pakietów | tysiące | tysiące | tysiące | tysiące | **80 000+** | Android | **BEHIND o rzędy wielkości** |
| **Ślad dowodowy decyzji** | ADR + CHANGELOG z pomiarami | RFC | dokumentacja | dokumentacja | — | RFC | — | **AHEAD** — rzadka jakość |

**Uczciwa konkluzja.** E-OS **nie konkuruje** dziś z Qubes/Tails/GrapheneOS na ich polu i nie
powinien tak się pozycjonować: brakuje mu izolacji aplikacji, atomowych aktualizacji i ekosystemu.
Ma natomiast **dwie rzeczy, których nie ma żaden z nich** — mikrojądro w Rust z izolowanymi
sterownikami oraz podpis indeksu odporny na przeciwnika kwantowego. Naturalne porównanie to
**„Redox z prawdziwym łańcuchem zaufania"**, nie „Tails dla paranoików".

---

## 5. Co zapobiegłoby powtarzającym się problemom

W tym audycie i w fazie 0 **ten sam wzorzec wrócił siedem razy**: *kontrola, która potrafi tylko
przejść, nie jest kontrolą.* Zamrożony `serial`, marker SYNC sprawdzany na obecność, `| tail -3`
zjadające ostrzeżenie, `make` niebudujący narzędzi, `cmd | tail` oddające status `tail`,
przekierowanie tworzące plik zerowy, bramka MR-owa przy zerze MR-ów. Poniżej to, co realnie
przerwałoby ten łańcuch.

### 5.1 Skrypty do dodania

| Skrypt | Co robi | Który problem zabija |
|---|---|---|
| `scripts/eos-verify-artifact.sh` | po każdym buildzie sprawdza **artefakt, nie kod wyjścia**: `strings` na binarkach szuka charakterystycznych literałów nowych funkcji; `grep` na `repo.toml` szuka `serial`; odmawia eksportu przy braku | zamrożony `serial`, „build zielony, ochrona nieobecna" |
| `scripts/eos-mirror-heads.sh` | porównuje głowy gałęzi GitLab↔GitHub dla wszystkich 30 repozytoriów | rozjazd `eos-pkg-aarch64` (faza 0 §5.2), którego **nic nie pilnuje** |
| `scripts/eos-doc-currency.sh` | sprawdza **wartość** markera SYNC wobec najnowszego `U-` w CHANGELOG i wartości rewizji w README forków wobec `repos.toml` | 72 pozycje rozjazdu, 15 README z nieaktualną rewizją |
| `scripts/eos-deps-audit.sh` | `osv-scanner` na wszystkich plikach blokad ekosystemu, próg na wagę | Dependabot zgłaszający 0 przy 2 realnych |
| `scripts/eos-image-manifest.sh` | wypisuje z obrazu: pakiety, binarki, wersje, źródła pakietów, stan `login_schemes` — do porównania między wydaniami | rozjazd deklaracji z produktem |

### 5.2 Reguły lintowania

| Reguła | Gdzie | Wykrywa |
|---|---|---|
| **Zakaz `\| tail` i `\| head` w skryptach budowania** bez `set -o pipefail` po stronie odbiorcy | `shellcheck` + własna reguła w `ci-integrity.sh` | tłumione ostrzeżenia (bootloader), fałszywe zero (`cargo` w kontenerze) |
| **Zakaz przekierowania `>` do pliku docelowego** — wymóg `.partial` + `mv` | reguła w `ci-integrity.sh` | zerowy `.iso` udający artefakt |
| **Każdy cel `make`, który produkuje binarkę, musi mieć prerekwizyt źródłowy** | reguła na `mk/*.mk` | `$(FSTOOLS_TAG)` bez prerekwizytów |
| **`missing_docs` + `deny(unsafe_code)`** dla skrzynek E-OS-owych | `clippy.toml` (częściowo jest) | — |
| **Każdy nowy plik w `keys/` musi mieć wpis w `.gitleaks.toml` albo test dowodzący, że to klucz publiczny** | `ci-integrity.sh` | fałszywy alarm czekający na odnowienie limitu |

### 5.3 Reguły do `CLAUDE.md`

Trzy, wyprowadzone z tego, co faktycznie poszło źle:

> **§X.1 — Weryfikuj artefakt, nie kod wyjścia.** Po każdej zmianie dotykającej tego, co trafia do
> obrazu albo do indeksu, sprawdź **wytworzony plik**: `strings` na binarce, `grep` na
> wygenerowanym pliku, montowanie obrazu. Zielony build **nie jest dowodem**, że zmiana zadziałała.
> Zmierzone trzy razy w ciągu jednego dnia (`U-224`).

> **§X.2 — Bramka sprawdzająca obecność nie jest bramką.** Każda kontrola musi mieć test
> **negatywny**: dowód, że potrafi odmówić. `grep -q 'SYNC:'` przechodzi przy dowolnej wartości;
> `serial` z zamrożonego licznika zawsze spełnia `>= znacznik`. Jeśli nie umiesz pokazać, kiedy
> kontrola pada — nie masz kontroli.

> **§X.3 — Domyślna postawa musi być fail-closed, a wyjątek jawny.** Brak klucza rozruchu dziś daje
> obraz bez weryfikacji i ostrzeżenie w logu. Wzorzec, którego projekt **już używa** poprawnie
> (`EOS_ALLOW_UNSIGNED=1` w `publish-repo.sh`), należy zastosować wszędzie: **budowa bez
> zabezpieczenia wymaga jawnej zmiennej**, nie jest domyślna.

### 5.4 Automatyzacja procesu

1. **Zablokować push na `main`** — 15 minut, uruchamia bramkę, która już jest opłacona i włączona.
2. **`lefthook` jako siatka zastępcza na czas martwego CI** — `integrity`, `shellcheck`,
   `osv-scanner` lokalnie przed pushem. CI nie działa od dwóch dni i to się powtórzy.
3. **Runner własny dla warstwy „heavy"** — ale **nie na maszynie z kluczami** (C-11).
4. **Cotygodniowe zadanie porównujące obraz z poprzednim wydaniem** (`eos-image-manifest.sh`),
   żeby regresja typu „`eos-guard` przestał się instalować" wyszła od razu, a nie w audycie.

---

## 6. Jedna rzecz, którą warto zrobić najpierw

**Zablokować bezpośredni push na `main`.** Piętnaście minut. Bramka
`only_allow_merge_if_pipeline_succeeds` jest **już włączona**, `only_allow_merge_if_all_discussions_are_resolved`
też, ochrona gałęzi działa, force-push jest zablokowany — a wszystko to nie ma żadnego znaczenia,
bo **w całej historii projektu nie było ani jednego merge requesta** i każdy commit szedł prosto
na `main`. To jedyne miejsce w tym audycie, gdzie **cała infrastruktura jest gotowa, opłacona
i nieużywana**, a koszt uruchomienia jest bliski zeru.

Drugie w kolejności, też tanie: **`EOS_ALLOW_UNVERIFIED_BOOT=1`** (30 minut) — bo dziś maszyna bez
klucza rozruchu produkuje obraz bez weryfikacji, wygląda to identycznie, a jedyny sygnał ostrzegawczy
jest zjadany przez `| tail -3`.
