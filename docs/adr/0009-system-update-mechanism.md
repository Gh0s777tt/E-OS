# ADR-0009 — Mechanizm aktualizacji systemu: transakcja z dziennikiem teraz, sloty A/B potem

- **Status:** Propozycja — do zatwierdzenia. Nic z tego nie jest zaimplementowane.
- **Data:** 2026-08-30
- **Dowód:** `R-704`, `R-706`, `R-707`, `R-710`, `R-609`, `R-701`, znalezisko `C-4`;
  `docs/architecture/system-updates.md` §1.1–§1.5, §3.2, §4.1–§4.3, §6.3, §8.5;
  `docs/architecture/installer.md` §5.2, §5.3, §7.3; `recipes/core/kernel/recipe.toml:14`,
  `:19-24`; `recipes/core/base/recipe.toml:26-27`; `mk/ci.mk:7`; `config/x86_64/ci.toml:215`;
  `scripts/ci-integrity.sh`; `ROADMAP.md` §8.1, §6.2, §5.3, Annex B, §6.4, §6.5;
  `ADR-0008` §D4
- **Zakres:** wybór mechanizmu aktualizacji systemu E-OS, wymuszona kolejność prac i klasy
  aktywacji pakietów.
- **Czego ten ADR NIE rozstrzyga:** układu partycji i jego liczb (`ADR-0008` §D4), stosu
  szyfrowania (`ADR-0010`), strategii Secure Boota (`ADR-0005`, `ADR-0006`), architektury
  kreatora (`ADR-0011`) ani protokołu pobierania, kanałów i UI — te są w
  `docs/architecture/system-updates.md` §2, §7, §8.
- **Zależy od:** **`ADR-0008`** (system plików korzenia i układ partycji, 2026-08-30, obecny
  w drzewie). Ten ADR jest jego następstwem, nie decyzją równoległą — patrz
  §„Zależność od ADR-0008".
- **Powiązane:** `ADR-0004` (podpis manifestu), `ADR-0005` (Secure Boot bez Microsoftu),
  `ADR-0007` (nośnik instalacyjny), `docs/encryption.md`

## Legenda znaczników

| Znacznik | Znaczenie |
|---|---|
| **JEST** | działa dzisiaj — z dowodem: plik:linia, nazwa binarki, pozycja `R-*`/`V2-*`/`U-*` |
| **DO ZBUDOWANIA** | wykonalne na Redoksie bez nowego podsystemu |
| **NOWY PODSYSTEM** | wymaga zbudowania czegoś, czego Redox nie ma w ogóle |
| **NIEREALNE DZIŚ** | zależy od ekosystemu, którego nie ma i nie będzie szybko |

`[NIEZWERYFIKOWANE]` oznacza twierdzenie, którego **nie potwierdziłem w drzewie**; przy każdym
piszę, co sprawdzić i gdzie. Źródła forków (`eos-pkgar`, `eos-pkgutils`, `eos-installer`,
`eos-redoxfs`, `eos-bootloader`) **nie są rozwinięte w tym checkoucie** — `recipes/core/*/`
zawierają wyłącznie `recipe.toml`, a `build/x86_64/eos/` nie istnieje. Każdy cytat `plik:linia`
z ich wnętrza jest cytatem **z drugiej ręki**, za `docs/architecture/system-updates.md`.

## Kontekst

Aktualizacja systemu E-OS jest dziś **instalacją pakietów na żywym systemie plików, bez
dziennika i bez siatki bezpieczeństwa**. Pięć faktów, każdy sprawdzalny, wymusza decyzję:

1. **Commit mutuje żywy FS pętlą `rename`, ze stanem wyłącznie w pamięci procesu**
   (`pkgar` `src/transaction.rs:350`, licznik `committed` i stos `actions` w
   `transaction.rs:104-107`). Zanik zasilania w połowie pętli zostawia część plików z nowej
   wersji, część ze starej, i **zero śladu** — nie da się ani dokończyć, ani cofnąć. To jest
   `R-706`.
2. **Baza pakietów zapisywana jest nieatomowo** — `std::fs::write` bez `tmp`+`rename`+`fsync`
   (`pkg-lib` `src/package_state.rs:95`). Przerwanie zostawia `/etc/pkg/packages.toml` obcięty
   albo pusty, czyli system, który **nie wie, co ma zainstalowane**. To jest gorsze od przerwanej
   pętli rename, bo niszczy metadane, a nie zawartość. Opis `R-706` w `ROADMAP.md` §5.3 tego
   nie wymienia; §12.5 (kamień M5) **już tak** — „atomowy zapis `packages.toml`/`repo-state.toml`"
   jest tam wpisany jako `R-706` (część).
3. **Jądro i initfs podmieniają się w locie.** Leżą pod `/usr/lib/boot/` w tym samym RedoxFS-ie,
   który `pkg` modyfikuje — jądro z `recipes/core/kernel/recipe.toml:14`, initfs z **innej
   receptury**, `recipes/core/base/recipe.toml:26-27` (`ROLE_TAG="e-os.boot.initfs"`,
   `PAYLOAD=…/usr/lib/boot/initfs`) — a bootloader odmawia startu bez pasującego podpisu
   (`V2-MS02`, `recipes/core/kernel/recipe.toml:19-24`). Dwa niezależne `rename` w losowej
   kolejności dają jądro bez pasującego `.sig`, czyli **maszynę, która się nie uruchomi**.
   To jest `R-707`. Że są to **dwa pakiety**, a nie jeden, podnosi koszt: atomowa musi być para
   `kernel`+`kernel.sig` **i** para `initfs`+`initfs.sig`, złożone z dwóch osobnych pkgarów.
4. **Brak ochrony przed cofnięciem pojedynczego pakietu.** Decyzja „czy aktualizować" opiera się
   wyłącznie na `local_hash.blake3 != *source_hash` (`pkg-lib` `src/library.rs:141-149`); pola
   `version` i `time_identifier` istnieją i **nie są w tej decyzji użyte**. Poprawnie podpisany
   STARSZY pkgar wciąż się instaluje. To jest `R-704`.
5. **Zapadka antycofkowa zapisuje się „best effort" i błąd jest jawnie ignorowany** —
   `let _ = fs::write(&path, …)` (`pkgar_backend/mod.rs:213`, za `system-updates.md` §4.1).
   Komentarz w kodzie nazywa to wprost. Skutek: kontrola świeżości indeksu (`V2-MS15`) może
   **po cichu nie zapisać** nowego znacznika, a wtedy zapadka nie zapada. To jest fakt o stanie
   obecnym, który psuje zdanie „warstwa zaufania zostaje nietknięta" (§Konsekwencje) i dlatego
   stoi tutaj, a nie w przypisie.

Do tego kontekst wydawniczy: **nie ma aktywnego kanału aktualizacji na x86_64** (znalezisko `C-4`;
`R-701` 🟡 — publikacja i `50_eos` działają na aarch64, `U-209`/`U-210`). Mechanizm aktualizacji
bez czego aktualizować jest projektem, a nie systemem.

Wybór mechanizmu jest więc wyborem między czterema wariantami, a nie ćwiczeniem z porównania
Linuksów. Pełna analiza jest w `docs/architecture/system-updates.md` §1; tutaj zapada decyzja.

## Klasyfikacja zamówionych zdolności

Tabela obejmuje **każdą** zdolność z zamówienia dotyczącą warstwy aktualizacji, także te, które
już działają — bez wierszy **JEST** dokument czytałby się jak deklaracja, że nie ma nic, a to
nieprawda i akurat na tym, co jest, stoi decyzja D1.

### Co już działa

| Zamówiona zdolność | Znacznik | Dowód |
|---|---|---|
| Podpis per pakiet | **JEST** | pkgar: ed25519 nad nagłówkiem + blake3 każdego wpisu (`pkgar-core` `Header::new` → `crypto_sign_open`; `system-updates.md` §0, §3.1) |
| Podpisane metadane repozytorium | **JEST**, z zastrzeżeniem | `repo.toml.sig`, hybryda ed25519 + ML-DSA-65 (`ADR-0004`, `tools/eos-repo-sign`). Na urządzeniu weryfikowana jest **tylko połowa ed25519** (`system-updates.md` §3.1) |
| Przypięcie hasza pakietu do podpisanego indeksu | **JEST** | `V2-MS13`/`V2-MS14` (`U-223`), egzekwowane **na bajtach** na każdej ścieżce włącznie z `install` (`ROADMAP.md`) |
| Ochrona przed cofnięciem **indeksu** | **JEST**, ale zapis zapadki jest „best effort" | `V2-MS15`: `Repository::serial` + `Repository::expires`, zapadka w `check_manifest_freshness()`. Patrz §Kontekst p. 5 — zapis idzie przez `let _ = fs::write` |
| Weryfikacja jądra i initfs przez bootloader | **JEST** | `V2-MS02`, udowodnione z kontrolą negatywną (`U-212`): `recipes/core/kernel/recipe.toml:19-24`, `recipes/core/base/recipe.toml:26-27` |
| Aktualizacja aplikacji bez restartu | **JEST** | `pkg` to robi dziś; problem jest nie w podmianie, tylko w braku transakcji (§Kontekst p. 1) |

### Co da się zbudować na tym, co jest

| Zamówiona zdolność | Znacznik | Dowód / co to znaczy |
|---|---|---|
| **Transakcyjny menedżer pakietów z dziennikiem** | **DO ZBUDOWANIA** | `pkgar` ma transakcje, ale w pamięci i bez dziennika. Nośnik (format, podpisy, weryfikacja na bajtach) już istnieje. To jest `R-706` |
| Atomowa aktywacja jądra/bazy przy restarcie | **DO ZBUDOWANIA** | `R-707`; katalog `pending/` + flaga to praca w demonie, nie w jądrze |
| Wycofanie jednym poleceniem (warstwa plikowa) | **DO ZBUDOWANIA** | kopie zamienianych plików + odwrócenie delty w `packages.toml`, pod tym samym dziennikiem |
| Ochrona przed cofnięciem **pakietu** | **DO ZBUDOWANIA** | `R-704`; `package_serial` per pakiet w podpisanym indeksie — bez nowego klucza i bez nowego kanału zaufania |
| Aktualizacje różnicowe | **DO ZBUDOWANIA** | pkgar w E-OS jest `Packaging::Uncompressed` i ma tablicę wpisów z `offset`+`size`+`blake3`, więc jest adresowalny zakresami HTTP bez nowego formatu delty (`system-updates.md` §2.3). **Warunkowo** — patrz §Jak ta decyzja zawodzi p. 4 |
| Kontrola pasma i wznawialne pobieranie | **DO ZBUDOWANIA** | pobieranie to `curl -sSL` jako proces potomny, bez `--limit-rate` i bez `-C -` (`system-updates.md` §0, §2.5). Dwie flagi, nie architektura |
| Rotacja i unieważnianie kluczy na urządzeniu | **DO ZBUDOWANIA** | `R-711`: pkgar wiąże pakiet z **dokładnie jednym** kluczem w nagłówku, bez keyringu i bez listy unieważnień (`ROADMAP.md`) |
| Kanały stable / testing / edge | **DO ZBUDOWANIA** | gałąź `lts/0.1` istnieje (`R-1002`), reszta to konfiguracja `/etc/pkg.d/` (`system-updates.md` §7.1) |
| Lustra offline | **DO ZBUDOWANIA** | `pkg-lib` obsługuje już źródło lokalne (ścieżka bez zdalnych repozytoriów, `V2-MS14`) |
| Wdrożenia etapowe (procent populacji) | **DO ZBUDOWANIA**, dziś zablokowane | wymaga tożsamości per maszyna, której nie ma: hostname to `eos` dla **każdej** instalacji — `R-606` |
| Powtarzalne budowanie jako podstawa niezależnej weryfikacji | **DO ZBUDOWANIA** | `R-303` mówi wprost, że znaczniki czasu obrazu wciąż się różnią; bajtowa powtarzalność **nie jest** osiągnięta |
| Bezpieczeństwo repozytorium w stylu TUF | **częściowo DO ZBUDOWANIA, częściowo NIEREALNE DZIŚ** | rozbicie na role w `system-updates.md` §3.4 |
| **Zapis na ESP z działającego systemu** — A/B bootloadera (D7), flaga i licznik prób rozruchu (`R-707`) | **DO ZBUDOWANIA, ale dziś bez nośnika** | `redox-fatfs` **nie wchodzi do obrazu `eos`**: w całym `config/` jedyne niezakomentowane wystąpienie to `config/x86_64/ci.toml:215`, a w `config/{aarch64,i586,riscv64gc}/ci.toml` linia jest zakomentowana. Łańcuch `x86_64/eos.toml → ../desktop.toml → desktop-minimal.toml + server.toml → minimal.toml → base.toml` nie ciągnie go nigdzie. Zanim D7 i `R-707` zaistnieją, trzeba rozstrzygnąć: FAT jako pakiet w obrazie czy crate wlinkowany w `eos-updated` |

### Czego nie ma i trzeba by zbudować od zera

| Zamówiona zdolność | Znacznik | Dowód / co to znaczy |
|---|---|---|
| **Sloty A/B (dwa roothy, przełączane przy restarcie)** | **NOWY PODSYSTEM** | wymaga drugiej partycji roota, wyboru slotu w bootloaderze i trwałego licznika prób rozruchu. Instalator tworzy dziś **dokładnie trzy** partycje i oddaje resztę dysku jednemu RedoxFS-owi (`installer.rs:565-660` — **cytat z drugiej ręki**, za `system-updates.md` §1.4; źródła instalatora nie ma w tym drzewie). To jest `R-710b` |
| Licznik prób rozruchu + automatyczne wycofanie | **NOWY PODSYSTEM** | dzisiejszy bootloader **niczego nie zapisuje** — nadanie mu zdolności zapisu przed odszyfrowaniem roota jest zmianą jakościową (`system-updates.md` §4.3). Do tego dochodzi brak FAT-a po stronie systemu, wiersz wyżej |
| **Migawki RedoxFS jako podstawa wycofania** | **NOWY PODSYSTEM**, a praktycznie **NIEREALNE DZIŚ** | RedoxFS jest wewnętrznie copy-on-write (`docs/architecture.md:82`), ale **nie eksponuje żadnego API migawek ani subwoluminów**; `clone.rs` to klon drzewa plików, nie tani punkt w czasie. Patrz §„Zależność od ADR-0008" |
| Nadzorca procesów (warunek klasy `service` z D6) | **NOWY PODSYSTEM** | `init` Redoksa ma **dokładnie dwa** typy usług, `oneshot` i `oneshot_async`, i nie nadzoruje niczego po starcie (`system-updates.md` §6.3). Nie ma pozycji w roadmapie; najbliższa, `R-805`, dotyczy wiązania urządzeń, nie cyklu życia procesu. Ten ADR numeru **nie zakłada** |
| Migawki btrfs / ZFS | **NIEREALNE DZIŚ** | żaden z tych systemów plików nie istnieje na Redoksie — ani jako root, ani jako cel montowania, ani do odczytu (`installer.md` §5.3) |
| ostree | **NIEREALNE DZIŚ** | biblioteka linuksowa na GLib/GIO, twardych dowiązaniach i `/ostree`; Redox nie ma żadnego z tych klocków. Port = przepisanie |
| systemd-sysupdate | **NIEREALNE DZIŚ** | część systemd; E-OS używa `init` Redoksa. Systemd nie istnieje w obrazie |
| Ponowne zapieczętowanie TPM po aktualizacji | **NIEREALNE DZIŚ** | **E-OS nie ma TPM** — nie ma czego pieczętować (`docs/encryption.md`, „Caveats": brak powiązania z TPM/Secure Bootem, hasło jest jedynym sekretem) |
| Odblokowanie aktualizacji kluczem FIDO2 / kartą | **NIEREALNE DZIŚ** | nie ma stosu FIDO2 ani CTAP w obrazie; nie ma też czego nimi odblokowywać poza hasłem woluminu (`ADR-0010`) |
| Żywe łatanie jądra | **NIEREALNE DZIŚ** | brak `ftrace`, brak modułów ładowalnych, brak relokacji symboli w locie. Mikrojądrowy odpowiednik (restart sterownika) to **DO ZBUDOWANIA**, ale wymaga nadzorcy i należy do toru `R-8xx` |

## Decyzja

**D1. Mechanizmem aktualizacji E-OS jest transakcyjny menedżer pakietów z trwałym dziennikiem
zamiaru — wariant C.** Nie obraz A/B, nie migawka. Zakres: `R-706` (dziennik, kopie zamienianych
plików, odzyskiwanie po zaniku zasilania, wycofanie plikowe) plus `R-707` (baza, jądro, initfs
i bootloader stosowane przy restarcie, z awaryjnym powrotem).

**D2. Wariant migawkowy jest wykluczony — nie jako gorszy, tylko jako pozbawiony nośnika.**
RedoxFS nie ma prymitywu migawek ani subwoluminów. To rozstrzygnięcie należy do `ADR-0008`
i ten ADR je przyjmuje, a nie powtarza. Konsekwencja jest twarda: **nie wolno pisać w planie
„wycofanie przez migawkę"**, bo to zdanie nie ma dziś desygnatu na tym systemie. Gdyby RedoxFS
kiedyś dostał migawki, wariant B jest **tańszy od A/B** (nie podwaja miejsca) i wtedy tę decyzję
należy zrewidować nowym ADR-em, a nie doklejką do tego.

**D3. Sloty A/B pozostają celem, ale jako `R-710b`, po `R-707`.** A/B nie jest zmianą w systemie
aktualizacji — jest **zmianą w układzie partycji**, czyli w instalatorze. Maszyna zainstalowana
dziś nigdy nie dostanie slotów bez przepartycjonowania. Sprzężenie `R-710b` ↔ `R-609`
**jest już w rejestrze i nie odkrywam go tutaj**: `ROADMAP.md` §3.4 (M8 wymaga M2 i M4
przez `R-609`), §12.7 (*„`R-609` staje się warunkiem `R-710b`"*) i graf w §12.8
(`R-609 partycjonowanie ────→ E8 R-710b`). Ten ADR to sprzężenie potwierdza i czyni z niego
warunek D1, nic więcej.

**D4. Rozcięcie `R-710` na `R-710a`/`R-710b` jest przyjęte — ale nie jest ustanowione tutaj.**
Zaproponował je `docs/architecture/system-updates.md` §1.5, a wiążącym uczyniła je już
`ROADMAP.md` Annex B D4 (*„Adoptuję to rozcięcie jako wiążące"*), z zapisem w §6.2.
Ten ADR go używa w niezmienionym kształcie: `R-710a` — aktualizacje różnicowe, `[P2·M]`,
**nie potrzebuje ani slotów, ani `R-707`**; `R-710b` — sloty A/B, `[P3·XL]`, potrzebuje `R-707`
**i** `R-609`. To jest podpodział istniejącej pozycji, nie nowa nazwa dla tej samej pracy —
i nie jest nowym ustaleniem tego dokumentu. Wpisuję to wprost, żeby ten ADR nie wyglądał
na drugie źródło tej samej decyzji.

**D5. Kolejność jest wymuszona, nie preferowana.** `R-706` (dziennik) przed `R-707`
(apply-on-reboot) przed `R-710b` (sloty). Powód: A/B bez dziennika, kontroli zdrowia i licznika
prób daje sloty, **których nikt nie umie bezpiecznie przełączyć**. Wariant C nie jest konkurentem
wariantu A — jest jego warunkiem.

**D6. Pakiety dzielą się na trzy klasy aktywacji:** `app` (podmiana natychmiastowa — to działa
dziś), `service` (podmiana + restart usługi, **wyłączona** do czasu powstania nadzorcy procesów;
`init` Redoksa ma **dokładnie dwa** typy usług, `oneshot` i `oneshot_async`, nie ma typu
`restart` ani polityki restartu i nie nadzoruje niczego po starcie — `system-updates.md` §6.3),
`boot` (jądro, initfs, `base`, `relibc`, bootloader — **wyłącznie przy restarcie**).
Do czasu nadzorcy wszystko, co nie jest `app`, idzie ścieżką restartu. Cena jest wymierna
i trzeba ją nazwać: **każda poprawka bezpieczeństwa w sterowniku wymaga restartu maszyny**,
dokładnie tak samo jak poprawka w jądrze. Nadzorca nie ma dziś pozycji w roadmapie i ten ADR
żadnej nie zakłada (D8).

**D7. Aktualizacja bootloadera jest osobną, jawnie potwierdzaną operacją**, nigdy częścią
„zaktualizuj wszystko", i **musi** przed zapisem sprawdzić, że nowy plik weryfikuje się tym samym
certyfikatem, który właściciel wgrał do firmware (`ADR-0005`). Aktualizacja dostarczająca
bootloader podpisany innym kluczem zamienia działającą maszynę w cegłę na najbliższym restarcie.
Zapis na ESP jest A/B nawet w wariancie C: `BOOT*.EFI.NEW` → weryfikacja → `rename`, z zachowaniem
`BOOT*.EFI.PREV`. FAT nie daje transakcji, ale daje `rename`, i dla jednego pliku to wystarczy.

**Warunek, którego dziś nie ma, i bez którego D7 opisuje operację na woluminie, którego nie da
się otworzyć:** działający system E-OS **nie widzi ESP**. `redox-fatfs` nie wchodzi do obrazu
`eos` — w całym `config/` jedyne niezakomentowane wystąpienie to `config/x86_64/ci.toml:215`,
a na aarch64/i586/riscv64gc linia jest zakomentowana; łańcuch `include` obrazu `eos` nie ciągnie
go nigdzie. Instalator zapisuje ESP z własnego procesu (`installer.md` §7.3), co **nie** jest
dowodem, że zrobi to demon aktualizacji. Przed `R-707` trzeba więc rozstrzygnąć jedno pytanie:
FAT jako pakiet w obrazie czy crate wlinkowany w `eos-updated`. To samo dotyczy flagi
`pending/` i licznika prób rozruchu, jeśli mają leżeć na ESP.

**D8. Ten ADR nie tworzy żadnych nowych identyfikatorów** — ani `R-7xx`, ani `R-8xx` na
nadzorcę z D6. Kolizja numeracji jest realna: `docs/update-system-design.md` (starszy, angielski,
21 396 B) używa przestrzeni `R-70x` **na inną pracę** — tam `R-704` znaczy „wycofanie",
w rejestrze znaczy „**anti**-rollback"; znaczenia niemal przeciwne.

**Ale rozstrzygnięcie już zapadło i ten ADR je przyjmuje, a nie otwiera na nowo.**
`ROADMAP.md` Annex B ustala: (D1) wiążąca jest numeracja `ROADMAP.md` jako
rejestru projektu; (D2) starszych dokumentów **nie przenumerowujemy** — dostają nagłówek
„NUMERACJA ARCHIWALNA" z tabelą odpowiedników, bo przepisanie identyfikatorów zerwałoby
odsyłacze z `CHANGELOG.md`; (D4) w rodzinie `R-7xx` nie powstaje ani jeden nowy numer.
Wcześniejsza wersja tego punktu pisała „oznaczyć **albo** przenumerować" — to było wznowienie
zamkniętej sprawy i sprzeczność z §12.1 D2. Poprawka jest tu widoczna, a nie cicha
(`CLAUDE.md` §2 reguła 4).

**Stan wykonania, sprawdzony w drzewie 2026-08-30:** decyzja jest podjęta i **niewykonana**.
`docs/update-system-design.md` nie ma nagłówka „NUMERACJA ARCHIWALNA" (`grep` → 0 trafień),
a `scripts/ci-integrity.sh` nie ma bramki z §12.1 D5 — plik ma preflight i kontrole 7–11,
żadna nie dotyczy identyfikatorów. Do czasu wykonania **każde zdanie z `R-704` w tym projekcie
pozostaje dwuznaczne**, ten dokument włącznie.

**D9. Rezerwa na drugi root jest warunkiem `R-710b`, ale jej liczby ustala `ADR-0008`, nie ten
dokument.** `ADR-0008` §D4 rozstrzyga układ: root ograniczony do **24 GiB**, nieprzydzielony
ogon **24 GiB** od dysku **≥ 128 GiB** w górę. Progu **256 GiB** z `installer.md` §5.3
**nie powtarzam** — `ADR-0008` §D4 obniża go świadomie do 128 GiB, bo przy roocie ograniczonym
do 24 GiB ogon przestaje kosztować połowę dysku, i wskazuje te trzy miejsca w `installer.md`
jako do poprawienia. Ten ADR dokłada wyłącznie uzasadnienie od strony aktualizacji: bez rezerwy
`R-710b` wymaga pełnej reinstalacji, a geometria zapada **nieodwracalnie** w chwili instalacji,
bo zmiany rozmiaru RedoxFS-a nie mamy. Jeżeli `ADR-0008` §D4 zmieni liczby, zmieniają się one
w jednym miejscu — tutaj nie ma drugiego źródła prawdy.

## Odrzucone warianty

**Wariant B — migawka systemu plików + podmiana roota (btrfs/ZFS, `snapper`).** Odrzucony,
bo **nie ma na czym go oprzeć**: RedoxFS nie eksponuje migawek ani subwoluminów, a `clone.rs`
kopiuje zawartość zamiast tworzyć tani punkt w czasie. To nie jest ocena jakości — to brak
nośnika. Gdyby prymityw powstał, wariant B bije A/B kosztem miejsca; do tego czasu wpisanie go
do planu byłoby planowaniem **cudzej pracy w cudzym repozytorium**.

**Wariant A jako pierwszy krok.** Odrzucony jako **kolejność**, nie jako cel. Wymaga trzech
rzeczy naraz, z których żadna nie istnieje: drugiego roota (zmiana instalatora), wyboru slotu
w bootloaderze (zmiana `eos-bootloader`) i trwałego licznika prób rozruchu zapisywanego przez
bootloader (dziś bootloader nie zapisuje nic). Zostaje jako `R-710b`.

**Wariant D — zostawić `pkg update` jak jest.** Odrzucony wprost, bo dzisiejszy stan potrafi
zostawić maszynę **niebootowalną bez automatycznego wyjścia** (§Kontekst, punkty 1–3). To nie
jest ryzyko teoretyczne, tylko bezpośrednia konsekwencja trzech linii kodu.

**Wzięcie ostree albo systemd-sysupdate.** Odrzucone, bo to **komponenty linuksowe, nie
formaty**. E-OS nie ma GLib, systemd, BLS ani Discoverable Partitions Spec, a bootloader jest
własny. „Użyjemy ostree" to zdanie bez desygnatu; wolno pożyczać ich pomysły i to robimy.

**Aktualizacja obrazem blokowym całego roota (`dd` nowej partycji).** Odrzucona, bo E-OS ma
działający, podpisany format pakietowy z weryfikacją na bajtach (`V2-MS13`), a wymiana go na
obrazy kosztowałaby całą tę warstwę zaufania. Dodatkowo obraz blokowy zabija tanie aktualizacje
różnicowe z `R-710a`.

**Delta bajtowa (`bsdiff` / `courgette`).** Odrzucona na rzecz delty per wpis pkgar. Delta
bajtowa wymaga nowego formatu, nowego narzędzia po stronie wydawcy, przechowywania każdej pary
wersji i **nowej powierzchni weryfikacji**; delta per wpis korzysta z haszy, które i tak są już
podpisane. Stosunek zysku do ryzyka jest zły.

**Zapieczętowanie TPM i zdalne poświadczanie po aktualizacji.** Odrzucone, bo **E-OS nie ma
TPM** — nie ma sterownika, stosu TSS ani PCR-ów. Nie projektujemy polityki ponownego
pieczętowania dla nieistniejącego układu; jej kształt zależy od decyzji, których nikt nie podjął.
Skutek uboczny, który trzeba powiedzieć: aktualizacja jądra **nie ma żadnego skutku
kryptograficznego poza weryfikacją podpisu**, i dokładnie o tyle są słabsze gwarancje.

**Żywe łatanie jądra.** Odrzucone: koszt porównywalny z resztą tej warstwy, przy powierzchni
problemu **mniejszej niż na Linuksie**, bo sterowniki E-OS-a żyją w przestrzeni użytkownika
i są zwykłymi pakietami — `ROADMAP.md` §8.1 wylicza **16 kategorii** sterowników w obrazie
(binarek jest więcej, bo część kategorii ma po kilka). Właściwą inwestycją jest nadzorca zdolny
zrestartować sterownik — i należy ona do toru `R-8xx`, nie `R-7xx`. Ten ADR numeru nie zakłada
(D8); najbliższa istniejąca pozycja, `R-805`, dotyczy **wiązania urządzeń**, a nie cyklu życia
procesu sterownika (`system-updates.md` §6.3).

**Automatyczne stosowanie aktualizacji bezpieczeństwa bez pytania.** Odrzucone, i powód jest
konkretny, nie ideologiczny: na maszynie z FDE system **nie wstanie bez ręcznego wpisania
hasła**, więc „automatyczne" znaczyłoby w praktyce „zatrzymane na monicie, bez nadzoru, do
następnego przyjścia użytkownika". Domyślnie: pobieranie automatyczne, stosowanie za zgodą.

## Zależność od ADR-0008 (system plików)

Ta decyzja **wynika** z ADR-0008 i bez niego nie jest ważna. `ADR-0008` **jest w drzewie**
(2026-08-30) i rozstrzygnął tak, jak D2 zakładał — poniższa tabela to zestawienie z jego
faktycznej treści, nie z domysłu. Zależność jest jednokierunkowa i wygląda tak:

| Co rozstrzyga `ADR-0008` | Skutek dla tego ADR-u |
|---|---|
| Root to **RedoxFS**, jedyny system plików korzenia | wariant „obraz blokowy obcego FS" nie ma sensu; format pakietowy zostaje kotwicą |
| RedoxFS **nie ma migawek ani subwoluminów** | **wariant B odpada** (D2) — nie ma czego wskazać bootloaderowi jako „inny root" |
| RedoxFS ma natywne szyfrowanie AES-XTS-128, klucz z hasła | staging, dziennik i kopie zapasowe są chronione tak samo jak reszta systemu — **w warstwie aktualizacji nie trzeba tu robić nic**; ceną jest brak niepilnowanego restartu (§Konsekwencje) |
| Sumy RedoxFS to `seahash` — niekryptograficzne i bez klucza | integralność zaktualizowanych plików opiera się **wyłącznie** na blake3 z pkgara i podpisie ed25519, nigdy na systemie plików |

Do tego dochodzi `ADR-0008` §D4, który ustala **liczby** rezerwy pod slot B (root 24 GiB, ogon
24 GiB, próg 128 GiB) — patrz D9. Ten ADR ich nie powtarza i nie ma własnej wersji.

**Jedyny znany warunek, przy którym ta decyzja się przewraca:** jeżeli okaże się, że fork
`Gh0s777tt/eos-redoxfs` (rev `58824d70`) ma nieudokumentowany prymityw migawek — **D1 i D2
trzeba zrewidować nowym ADR-em**, bo wariant B jest wtedy tańszy od `R-710b` i przejmuje jego
rolę. Ani `ADR-0008`, ani ten dokument tego forka **nie czytały** (źródła nie ma w drzewie),
więc warunek zostaje otwarty i jest tu zapisany wprost, a nie przemilczany.

## Czego ten mechanizm NIE robi i przed czym NIE chroni

Ta sekcja istnieje, żeby po zatwierdzeniu nikt nie przeczytał D1 jako obietnicy, której tam nie
ma. Każda pozycja jest konsekwencją decyzji, nie brakiem do nadrobienia w tym samym zakresie.

**Czego nie robi**

- **Nie cofa systemu do stanu z chwili X.** Wariant C cofa **pliki, które transakcja zamieniła**,
  i nic poza tym. Zmiany w `/home`, w bazach danych aplikacji i w konfiguracji dopisanej po
  aktualizacji zostają. Punktu w czasie nie ma, bo nie ma migawek (D2).
- **Nie chroni działającego systemu przed samą aktualizacją.** Klasa `app` podmienia pliki pod
  żywymi procesami. Proces, który trzyma otwarty stary plik, dostaje niespójny obraz świata do
  własnego restartu — a nadzorcy, który by go zrestartował, nie ma (D6).
- **Nie aktualizuje niczego bez człowieka na maszynie z FDE.** Restart zatrzyma się na monicie
  o hasło. „Automatycznie" znaczy tu wyłącznie „automatycznie pobrane".
- **Nie daje aktualizacji na x86_64.** Nie ma tam aktywnego kanału (`C-4`, `R-701`). Dokument
  opisuje mechanizm dla obu architektur; jedna z nich nie ma dziś czego pobierać.
- **Nie naprawia systemu plików uszkodzonego przez zanik zasilania.** Dziennik zna zamiar
  transakcji, nie stan RedoxFS-a. `fsck` dla RedoxFS-a nie istnieje — `ROADMAP.md` §6.2
  zakłada na to osobną pozycję `R-615` (**NOWY PODSYSTEM**).
- **Nie weryfikuje, że pobrany kod robi to, co mówi źródło.** Weryfikuje, że bajty zgadzają się
  z podpisanym indeksem. Powtarzalne budowanie, które dopiero łączy jedno z drugim, **nie jest
  osiągnięte** (`R-303`).

**Przed czym nie chroni**

- **Przed napastnikiem z fizycznym dostępem.** ESP jest jawny i firmware musi go czytać. Licznik
  prób rozruchu na nim broni przed **złą aktualizacją**, nie przed człowiekiem ze śrubokrętem
  (`docs/encryption.md`, „Caveats").
- **Przed lokalnym rootem.** Zapadki świeżości i `package_serial` leżą w zwykłych plikach
  w rootcie. Root je skasuje i straci historię. Kotwicy sprzętowej nie ma i **nie udajemy,
  że jest**.
- **Przed przejęciem maszyny budującej.** Klucz podpisujący pakiety jest generowany przez
  cookbook i przechowywany jawnym tekstem (`V2-MS12` 🟡, znalezisko `C-11`). Kto go weźmie,
  podpisze dowolny pakiet, a wszystkie kontrole klienta przejdą.
- **Przed cofnięciem pojedynczego pakietu — dopóki `R-704` nie jest zrobione.** Dziś poprawnie
  podpisany **starszy** pkgar wciąż się instaluje (§Kontekst p. 4).
- **Przed dostarczeniem bootloadera podpisanego innym kluczem** — dopóki kontrola z D7 nie
  istnieje. Skutek takiej aktualizacji to cegła na najbliższym restarcie.
- **Przed niczym, co dzieje się przed uruchomieniem jądra.** To jest zakres `ADR-0005`
  i `V2-MS02`, nie ten.

## Konsekwencje

**Co staje się łatwiejsze**

- Odzyskiwanie po zaniku zasilania przestaje być losowe. Dziennik zna listę plików i stan każdego
  z nich, więc przerwany przebieg da się **dokończyć albo cofnąć** przy starcie.
- Cała praca `R-706` jest dowodliwa **pod QEMU na aarch64** — czyli na jedynym stanowisku, na
  którym ten projekt potrafi cokolwiek udowodnić. Dopiero `R-707` wymaga metalu.
- Najtańsza pojedyncza poprawka w tej warstwie — `tmp`+`rename`+`fsync` w
  `PackageState::to_sysroot()` — jest rozmiaru **S** i można ją zrobić przed resztą, bez czekania
  na architekturę.
- Warstwa zaufania zostaje nietknięta: podpis indeksu, przypięcie hasza, zapadka `serial`
  i podpis per pakiet działają dalej (`ADR-0004`, `V2-MS13`, `V2-MS15`). Z jednym zastrzeżeniem,
  które trzeba nieść razem z tym zdaniem: **zapis zapadki jest „best effort" i błąd jest
  ignorowany** (§Kontekst p. 5, tryb porażki 7).

**Co staje się trudniejsze i jaki dług powstaje**

- **Wycofanie jest plikowe, nie blokowe.** Cofa to, co transakcja zamieniła; nie cofa skutków
  ubocznych, które zostawiły procesy działające między aktualizacją a wycofaniem. A/B cofa
  wszystko jednym przełącznikiem — i tej własności wariant C nie ma i mieć nie będzie.
- **Podwojona zajętość dla zamienianych plików** (kopie w `rollback/`), domyślnie 2 generacje.
  Mniej niż A/B (który podwaja **cały** root), ale nie zero.
- **Niepilnowany restart po aktualizacji jest niemożliwy na maszynie z FDE** — ktoś musi wpisać
  hasło. Dla serwera to realne ograniczenie i musi być w `R-712` oraz w UI.
- **Ochrona przed cofnięciem nie ma sprzętowej kotwicy.** Zapadka `serial` i przyszły
  `package_serial` leżą w zwykłych plikach, które root skasuje. Na Linuksie odpowiedzią jest
  licznik monotoniczny TPM; tutaj takiej odpowiedzi nie ma i **nie należy udawać, że jest**.
- **Podbicie generacji SBAT jest nieodwracalne** — po nim firmware odmówi uruchomienia
  poprzedniego bootloadera, czyli wycofanie bootloadera przestaje działać. Musi być rzadkie,
  jawne i nigdy w tym samym wydaniu, w którym nowy bootloader debiutuje.
- **`R-701` (kanał na x86_64, znalezisko `C-4`) staje się blokadą wdrożenia, nie tłem.** Ten ADR
  opisuje mechanizm dla obu architektur; na x86_64 nie ma dziś czego pobierać.

**Jak ta decyzja zawodzi** — bo kontrola, która nie może zawieść, nie jest kontrolą:

1. **Dziennik jest ozdobą, jeśli `fsync` na RedoxFS-ie nie daje trwałości, której się po nim
   spodziewamy.** Cały wariant C stoi na tym założeniu i **nie jest ono zweryfikowane**.
   Kontrola: test przerywający QEMU w losowym momencie commitu i sprawdzający, czy system wstaje
   spójny. **Bez tego testu `R-706` nie wolno oznaczyć jako zrobione.**
2. **Licznik prób rozruchu na nieszyfrowanym ESP jest przestawialny przez napastnika
   z fizycznym dostępem.** Przyjmujemy to świadomie: licznik broni przed **złą aktualizacją**,
   a nie przed człowiekiem ze śrubokrętem, który i tak jest poza modelem zagrożeń
   (`docs/encryption.md`). Alternatywa — licznik w RedoxFS-ie — wymagałaby od bootloadera
   zapisu do zaszyfrowanego woluminu przed poznaniem hasła.
3. **Kontrola zdrowia po restarcie może uznać za zdrowy system, który jest zepsuty w sposób
   przez nią niemierzony.** Zestaw kontroli jest celowo ubogi, bo bogaty sam staje się przyczyną
   wycofań. Przyjmujemy fałszywie pozytywne, odrzucamy fałszywie negatywne.
4. **Delta różnicowa przestaje działać po cichu przy `COOKBOOK_COMPRESSED`** — LZMA2 to jeden
   strumień, więc adresowalność zakresami znika. **I to nie jest hipoteza:** `mk/ci.mk:7` ustawia
   `COOKBOOK_COMPRESSED=true` w `CI_COOKBOOK_CONFIG`, eksportowanym przez cele `server`,
   `desktop`, `demo` (`mk/ci.mk:21`) i `ci-os-test` (`:50`). `Packaging::Uncompressed` jest
   prawdą wyłącznie na ścieżce `.config` (`REPO_BINARY=1`, `ARCH=aarch64`, `CONFIG_NAME=eos` —
   ta zmienna tam nie występuje). Dwie ścieżki budowania dają dwa różne formaty pakietu, i nic
   tego nie pilnuje: `scripts/ci-integrity.sh` ma dziś preflight i kontrole 7–11, żadna nie
   dotyczy kompresji. `R-710a` bez tego niezmiennika jest zbudowany na przypadku.
5. **Anti-rollback zawodzi u lokalnego roota**, który skasuje `packages.toml` i straci historię.
   Nie da się tego naprawić bez zaufanego licznika sprzętowego. Musi to być w dokumentacji dla
   administratora (`R-712`), a nie ukryte.
6. **A/B na ESP z D7 i licznik prób rozruchu z `R-707` nie mają dziś nośnika.** Działający system
   nie ma sterownika FAT: `redox-fatfs` nie wchodzi do obrazu `eos` (jedyne niezakomentowane
   wystąpienie w `config/` to `config/x86_64/ci.toml:215`). Tryb porażki jest cichy i najgorszej
   klasy: `eos-updated` zgłosi „nie mogę otworzyć ESP" **albo** — jeśli ktoś dołoży FAT bez
   sprawdzenia semantyki `rename` — zapisze `BOOT*.EFI.NEW` i nie dokończy podmiany, zostawiając
   ESP z dwoma plikami i firmware startujące ze starego. **Kontrola, która musi powstać przed
   `R-707`:** test w QEMU, który po zapisie odczytuje ESP z zewnątrz i porównuje bajty
   z oczekiwanym stanem po każdej z trzech faz.
7. **Zapadka świeżości może nie zapaść i nikt się nie dowie** — zapis idzie przez
   `let _ = fs::write` z jawnie odrzuconym błędem (§Kontekst p. 5). Kontrola, która nie może
   zgłosić porażki, nie jest kontrolą; poprawka jest rozmiaru **S** i należy do tego samego
   pakietu roboczego co atomowy zapis `packages.toml`.

## Czego nie udało się zweryfikować

Sprawdzone w drzewie 2026-08-30, bez poleceń `git` (w tym zadaniu zabronione).

- **[ZWERYFIKOWANE — sprostowanie]** Wcześniejsza wersja tej sekcji twierdziła, że `ADR-0008`
  nie istnieje, a `docs/adr/` kończy się na `0006`. **To już nieprawda:** katalog zawiera
  `0000`–`0011`, a `docs/adr/0008-filesystem-and-partition-layout.md` (37 458 B) rozstrzyga tak
  samo, jak zakładał D2 — root to RedoxFS, brak migawek i subwoluminów, rezerwa pod slot B.
  Różnica, którą trzeba było naprawić: `ADR-0008` §D4 stawia próg rezerwy na **128 GiB**
  i ogon **24 GiB**, a nie 256 GiB — patrz D9. Poprawka jest widoczna, nie cicha
  (`CLAUDE.md` §2 reguła 4). Ta sama uwaga dotyczy `ROADMAP.md` Annex B D6,
  która wciąż mówi „`docs/adr/` kończy się dziś na `ADR-0006`" i przypisuje `ADR-0008` inną
  treść („kolejność transakcji instalacji"). **To jest do poprawienia w `ROADMAP.md`**, nie tutaj.
- **[NIEZWERYFIKOWANE] Wszystkie cytaty `plik:linia` z wnętrza forków.** `recipes/core/pkgar/`,
  `recipes/core/pkgutils/`, `recipes/core/installer/`, `recipes/core/redoxfs/`
  i `recipes/core/bootloader/` zawierają **wyłącznie** `recipe.toml` (sprawdzone: żaden katalog
  `recipes/core/*/source` nie istnieje, `build/x86_64/eos/` też nie). Zweryfikowałem jedynie
  rewizje, na które wskazują receptury: `eos-pkgar` `78e644ad`, `eos-pkgutils` `e28063ee`,
  `eos-installer` `c8d32ad3`, `eos-redoxfs` `58824d70`, `eos-bootloader` `87b214b5`.
  Cytaty `transaction.rs:350`, `transaction.rs:104-107`, `package_state.rs:95`,
  `library.rs:141-149`, `pkgar_backend/mod.rs:213` i `installer.rs:565-660` biorę za
  `docs/architecture/system-updates.md` §4.1, §3.2 i §1.4. **Sprawdzić** przy checkoutcie forków.
- **[NIEZWERYFIKOWANE] Czy `redox-fatfs` w ogóle udostępnia `rename` i pracę do zapisu na
  Redoksie.** Na tym stoi D7 i tryb porażki 6. Zweryfikowane jest tylko to, czego pakietu
  **nie ma w obrazie** (`config/`), nie to, co potrafi. **Sprawdzić:** `eos-redox-fatfs`
  rev `26caa0908977976c424762f10ba4ed2176cba2a3` (`recipes/libs/redox-fatfs/recipe.toml`).
- **[NIEZWERYFIKOWANE] Czy bootloader potrafi cokolwiek zapisać.** Na tym opiera się
  klasyfikacja licznika prób rozruchu jako **NOWY PODSYSTEM**. Źródło `eos-bootloader`
  rev `87b214b5` nie jest lokalnie dostępne (`recipes/core/bootloader/` to `recipe.toml`
  + `sbat.csv`). **Sprawdzić:** czy istnieje jakakolwiek ścieżka zapisu do ESP lub RedoxFS-a
  i pod jakim adresem szuka jądra.
- **[NIEZWERYFIKOWANE] Trwałość `fsync` na RedoxFS-ie** — punkt 1 w „Jak ta decyzja zawodzi".
  Cały wariant C stoi na tym założeniu.
- **[NIEZWERYFIKOWANE] Czy tablica wpisów pkgar ma deterministyczną kolejność.** Od tego zależy
  stabilność `offset`-ów, na których stoi `R-710a`.
- **[NIEZWERYFIKOWANE] Treść znaleziska `C-4`** (i `C-11`, użytego w §„Przed czym nie chroni").
  `docs/audit/` zawiera tylko `AUDIT-2026-07-13.md` i `AUDIT-2026-08-14.md`;
  `03-security-audit-2026-08-30.md` leży na gałęzi `fix/p0-audit-findings`, której nie czytałem.
  **Substancja `C-4` jest jednak potwierdzona w drzewie**: `ROADMAP.md` (`R-701` 🟡 —
  `50_eos` aktywne tylko na aarch64). Za briefem idzie sam **numer**, nie fakt.

## Powiązania

- [`ADR-0004`](0004-hybrid-manifest-signature.md) — hybrydowy podpis indeksu, warstwa zaufania,
  której ten mechanizm nie zmienia
- [`ADR-0005`](0005-secure-boot-without-microsoft.md) — klucz, którym musi weryfikować się nowy
  bootloader (D7)
- [`ADR-0007`](0007-bootloader-and-install-medium.md) — nośnik i łańcuch podpisu wydania
- [`ADR-0008`](0008-filesystem-and-partition-layout.md) — **warunek tej decyzji**: brak migawek
  (D2) i liczby rezerwy pod slot B (D9)
- [`ADR-0010`](0010-encryption-stack.md) — FDE, brak TPM2/FIDO2, źródło ograniczenia
  „brak niepilnowanego restartu"
- [`docs/architecture/system-updates.md`](../architecture/system-updates.md) — pełny projekt
  warstwy; ten ADR rozstrzyga z niego wyłącznie wybór mechanizmu i kolejność
- [`ROADMAP.md`](../../ROADMAP.md) §5.3, §3.4, §6.2, §6.4, §6.5, Annex B — rejestr pozycji
  `R-7xx`, rozstrzygnięcie kolizji numeracji i graf zależności
