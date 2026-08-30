# Aktualizacje systemu — na żywo, aktywacja przy restarcie

- **Status:** Propozycja — do zatwierdzenia. Nic z tego nie jest zaimplementowane.
- **Data:** 2026-08-30
- **Zakres:** mechanizm dostarczania i aktywacji aktualizacji systemu E-OS: wybór modelu,
  pobieranie i staging, weryfikacja kryptograficzna, atomowa aktywacja z wycofaniem, styk
  z FDE i Secure Bootem, kanały i polityki, UX, ścieżka migracji.
- **Pozycje roadmapy, które ten dokument obsługuje:** `R-704`, `R-705`, `R-706`, `R-707`,
  `R-708`, `R-709`, `R-710`, `R-711`, `R-712`. Wszystko, co proponuję, przypina się do
  **istniejących** identyfikatorów — nie zakładam nowych nazw na tę samą pracę.
- **Powiązane:** `ADR-0009` (decyzja o mechanizmie — ten dokument jest jej analizą, ADR ją
  zapisuje), `ADR-0008` (system plików i układ partycji — od niego zależy §1.3 i §1.5),
  `ADR-0007` (bootloader i nośnik instalacyjny — cytuje §1.4, §4.3, §4.6, §5.2, §5.5),
  `ADR-0004` (hybrydowy podpis manifestu), `ADR-0005` (Secure Boot bez Microsoftu),
  `ADR-0006` (ścieżka do weryfikacji Microsoftu — SBAT, §5.5), `docs/encryption.md`,
  `ROADMAP.md` §6.2, §5.3 (kamienie M5–M8 odpowiadają etapom E0–E8 z §9),
  `docs/update-system-design.md` (starszy, angielski projekt tej samej warstwy — patrz §11.2,
  jego numeracja `R-70x` **koliduje** z `ROADMAP.md`).
- **Numeracja sekcji tego pliku jest stabilna.** `ADR-0007`, `ADR-0008` i `ADR-0009` cytują
  §1.1–§1.5, §3.2, §4.1–§4.3, §4.6, §5.2, §5.4, §8.5 oraz **§11 poz. 3**. Nowy materiał
  dopisujemy jako §0.1 albo na końcu — przenumerowanie unieważniłoby te odsyłacze po cichu.

---

## 0. Słownik zamówienia a rzeczywistość E-OS

Zamówienie na ten dokument jest napisane słownikiem Linuksa. E-OS to dystrybucja Redoksa:
mikrojądro w Ruście, RedoxFS, sterowniki w przestrzeni użytkownika. Poniżej każda zamówiona
zdolność dostaje znacznik. Bez tej tabeli reszta dokumentu byłaby obietnicą instalatora
linuksowego na systemie, który nie ma ani jednego z tych klocków.

| Zamówiona zdolność | Znacznik | Dowód / co to znaczy |
|---|---|---|
| ostree | **NIEREALNE DZIŚ** | `libostree` to biblioteka linuksowa oparta na GLib/GIO, twardych dowiązaniach w magazynie obiektów i `/ostree` na ext4/xfs. Redox nie ma GLib, nie ma tego modelu dowiązań, a RedoxFS nie ma z tym nic wspólnego. Portowanie = przepisanie, nie zależność. |
| systemd-sysupdate | **NIEREALNE DZIŚ** | część systemd. E-OS używa `init` Redoksa — jednostki leżą pod `/usr/lib/init.d/` (`config/aarch64/eos.toml:82`, `:674`, `:692`), a w całej konfiguracji są **dokładnie dwa** typy usług, oba jednorazowe (§6.3). Systemd nie występuje w żadnym przepisie ani konfiguracji. |
| Aktualizacje w stylu Mendera (obraz A/B) | **NOWY PODSYSTEM** | wymaga slotów w bootloaderze i drugiej partycji roota. Instalator tworzy **dokładnie trzy** partycje (§1.4). To jest `R-710`. |
| Migawki btrfs / ZFS | **NIEREALNE DZIŚ** | żaden z tych systemów plików nie istnieje na Redoksie. |
| Migawki RedoxFS | **NOWY PODSYSTEM** | RedoxFS jest wewnętrznie copy-on-write (`docs/architecture.md:82`), ale **nie eksponuje żadnego API migawek ani subwoluminów**. Rozstrzygnięcie w §1.3. |
| Transakcyjny menedżer pakietów | **DO ZBUDOWANIA** | `pkgar` ma transakcje, ale **w pamięci** i bez dziennika (`R-706`, §4.1). |
| Kontrola pasma przy pobieraniu | **DO ZBUDOWANIA** | pobieranie to `curl -sSL` odpalany jako proces potomny (`curl_backend.rs:28`). Dodanie `--limit-rate` to jedna flaga. |
| Wznawialne pobieranie | **DO ZBUDOWANIA** | ta sama linia: brak `-C -`, brak zapisu częściowego. |
| Aktualizacje różnicowe | **DO ZBUDOWANIA** | pkgar w E-OS jest **nieskompresowany** i ma tablicę wpisów z `offset`+`size`+`blake3` — czyli jest adresowalny zakresami HTTP bez wymyślania formatu delty (§2.3). |
| Podpisane metadane repozytorium | **JEST** | `repo.toml.sig`, hybryda ed25519 + ML-DSA-65 (`ADR-0004`, `tools/eos-repo-sign`). Uwaga: **na urządzeniu weryfikowana jest tylko połowa ed25519** (§3.1). |
| Podpis per pakiet | **JEST** | pkgar: ed25519 nad nagłówkiem + blake3 każdego wpisu (`pkgar-core` `Header::new` → `crypto_sign_open`). |
| Przypięcie hasza pakietu do podpisanego indeksu | **JEST** | `V2-MS13`/`V2-MS14` (`U-223`), `enforce_manifest_blake3()` w `pkgar_backend/mod.rs:145`. |
| Ochrona przed cofnięciem **indeksu** | **JEST** | `V2-MS15`: `Repository::serial` + `Repository::expires` (`package.rs:383`, `:391`), zapadka w `check_manifest_freshness()`. |
| Ochrona przed cofnięciem **pakietu** | **DO ZBUDOWANIA** | **to jest dziura** — `R-704`, opisana i nazwana w §3.2. |
| Hierarchia kluczy i rotacja | **DO ZBUDOWANIA** | `R-711`. Dziś: pkgar wiąże pakiet z **dokładnie jednym** kluczem wbudowanym w nagłówek, bez keyringu i bez listy unieważnień. |
| Bezpieczeństwo repozytorium w stylu TUF | **częściowo DO ZBUDOWANIA, częściowo NIEREALNE DZIŚ** | §3.4 — rozbite na role. |
| Powtarzalne budowanie | **DO ZBUDOWANIA** | `R-303` mówi wprost, że znaczniki czasu obrazu wciąż się różnią. Bajtowa powtarzalność **nie jest** osiągnięta. |
| Atomowa aktywacja przy restarcie | **DO ZBUDOWANIA** | `R-707`. Dziś jądro podmienia się **w locie** (§4.1). |
| Licznik prób rozruchu + auto-rollback | **NOWY PODSYSTEM** | wymaga trwałego licznika, który czyta i zapisuje **bootloader**. Dziś bootloader nie ma żadnego stanu zapisywalnego. |
| Ponowne zapieczętowanie TPM po aktualizacji | **NIEREALNE DZIŚ** | **E-OS nie ma TPM** — nie ma czego pieczętować ani odpieczętowywać. §5.4. |
| Żywe łatanie jądra | **NIEREALNE DZIŚ** (w formie linuksowej) / **DO ZBUDOWANIA** (w formie mikrojądrowej) | §6. |
| Kanały stable / testing / edge | **DO ZBUDOWANIA** | jeden kanał (`stable`, aarch64) już jedzie — patrz wiersz niżej; **rozdzielenia na kanały nie ma**: gałąź `lts/0.1` istnieje (`R-1002` 🟡), ale nie ma dla niej osobnego adresu, a `testing`/`edge` nie istnieją wcale. §7.1. |
| Wdrożenia etapowe | **DO ZBUDOWANIA** | wymaga tożsamości per maszyna, której dziś nie ma — `R-606` (hostname `eos` dla każdej instalacji). |
| Lustra offline | **DO ZBUDOWANIA** | `pkg-lib` już obsługuje źródło lokalne (ścieżka bez zdalnych repozytoriów, `V2-MS14`). |
| Kanał aktualizacji jako adres URL | **częściowo JEST** | `50_eos` jest **aktywne na aarch64** i wskazuje `https://gh0s777tt.github.io/eos-pkg-aarch64/pkg` (`config/aarch64/eos.toml:737-741`, `U-210`); na x86_64 ta sama linia jest **zakomentowana** (`config/x86_64/eos.toml:767-772`) — to jest znalezisko `C-4`. |
| Staging do nieaktywnego slotu | **DO ZBUDOWANIA** (katalog przejściowy) / **NOWY PODSYSTEM** (prawdziwy drugi slot) | dziś nie ma ani jednego, ani drugiego. §2.2, §1.4. |
| Odzyskiwanie po zaniku zasilania w trakcie commitu | **DO ZBUDOWANIA** | dziś **nie istnieje**: stan transakcji żyje wyłącznie w pamięci procesu, baza pakietów zapisywana jest nieatomowo (§4.1, §8.5). To jest `R-706`. |
| Wycofanie jednym poleceniem (warstwa plikowa) | **DO ZBUDOWANIA** | kopie zamienianych plików + odwrócenie delty w `packages.toml` pod tym samym dziennikiem (§4.5). Nośnika brak, ale i nowego podsystemu nie trzeba. |
| Kontrole zdrowia po aktualizacji | **DO ZBUDOWANIA** | jedyny istniejący dziś odpowiednik to `scripts/ci-boot-smoke.sh`, i robi **mniej**, niż zwykle się o nim mówi — patrz §4.4. |
| Powiadomienie o dostępnej aktualizacji | **częściowo JEST** | `eos-notifyd` działa (toast przez odpytywany plik, `R-D03` 🟡); brak schematu `notify:`, kolejki, ikon i akcji. Panel ma gdzie mieszkać: `R-D01` **zbudowany i działa**, 9 paneli (`ROADMAP.md`). §8.1. |
| Zaplanowane instalacje / okna serwisowe | **DO ZBUDOWANIA, ale trwale kalekie** | wymagają zaufanego czasu, którego nie ma: brak klienta NTP i synchronizacji RTC (`docs/reality-ledger.md:127`, `:144`). §8.3. |
| Aktualizacje awaryjne (`severity = "critical"`) | **DO ZBUDOWANIA** | wyłącznie polityka nad istniejącą weryfikacją; nie dodaje ani nie omija żadnej kontroli z §3.6. §7.3. |
| Wymuszenie polityki, której użytkownik nie zmieni | **NIEREALNE DZIŚ** | brak piaskownicy i MAC-a (`C-5`, `R-1010`); root zmienia każdy plik konfiguracji. §7.4. |
| Zdalne poświadczanie (remote attestation) | **NIEREALNE DZIŚ** | brak TPM i pomiarów rozruchu (`docs/threat-model.md:79` — łańcuch measured-boot jest wpisany jako **brakujący**, `R-913`). §5.4. |
| Tryb ratunkowy / naprawa z nośnika instalacyjnego | **DO ZBUDOWANIA**, **poza zakresem tego dokumentu** | maszyna zepsuta poza zasięgiem wycofania nie ma dziś żadnej ścieżki odzyskania (`docs/reality-ledger.md`, „No recovery/rescue path"; konto awaryjne to `R-614c`/`C-18`). Nazywam to tutaj, żeby nikt nie wziął `eos-update rollback` za odpowiedź na ten przypadek. |

---

## 0.1 Czego ten projekt NIE robi i przed czym NIE chroni

Ta sekcja jest tu, bo bez niej reszta czyta się jak obietnica. Każdy punkt ma dowód. Punkty
1–2 i 8 są **skutkiem wybranego wariantu** (§1.5) i zostaną z nami także po `R-710b`; punkty
3–7 i 9–10 są **granicami podłoża**, których ten dokument nie przesuwa i nie udaje, że przesuwa.

1. **Nie chroni przed napastnikiem z fizycznym dostępem.** ESP jest nieszyfrowany i
   nieuwierzytelniony, a rekomendowany licznik prób rozruchu ma na nim leżeć (§4.3) — kto ma
   śrubokręt, przekręci go albo wyzeruje. To jest zgodne z modelem: `docs/encryption.md`
   („Caveats", `:95-99`) mówi wprost, że **hasło jest jedynym sekretem**, bez powiązania z
   TPM/Secure Bootem.
2. **Nie chroni przed rootem na tej maszynie.** Zapadka `serial` leży w zwykłym pliku
   (`etc/pkg/repo-state.toml`), przyszły `package_serial` w `packages.toml`. Root kasuje oba i
   traci historię (§3.2). Nie ma piaskownicy ani MAC-a (`C-5`, `R-1010`), więc żadna polityka
   nie jest wymuszalna — jest konwencją (§7.4).
3. **Nie daje odporności postkwantowej u klienta.** Hybryda ed25519 + ML-DSA-65 jest hybrydą
   **po stronie wydawcy**; urządzenie sprawdza tylko połowę ed25519 (§3.1, `R-503`).
4. **Nie chroni przed kompromitacją klucza podpisującego pakiety.** pkgar wiąże pakiet z
   **dokładnie jednym** kluczem, bez keyringu i bez listy unieważnień (`R-711`), a klucz jest
   generowany przez narzędzie budowania i trzymany jawnym tekstem (`src/cook/package.rs:42-43`,
   `V2-MS12` 🟡, znalezisko `C-11`). Keyring z §3.3 to **propozycja**, nie stan.
5. **Nie dowodzi, że opublikowany pakiet odpowiada opublikowanemu źródłu.** Bez powtarzalności
   budowania (`R-303`/`V2-MS07`) łańcuch podpisów dowodzi wyłącznie, że coś podpisał właściciel
   klucza (§3.5).
6. **Nie obejmuje sterowników ładowanych z roota po montowaniu.** ~16 sterowników jedzie z
   niepodpisanego roota, bez IOMMU (`docs/hardening.md:171`). Aktualizacja ich pakietów
   przechodzi tę samą weryfikację co każdy inny pakiet, ale **rozruch ich nie weryfikuje** —
   `V2-MS02` pokrywa jądro i initfs, nie resztę.
7. **Nie działa tam, gdzie nie ma kanału.** Na x86_64 nie ma dziś aktywnego źródła
   (`config/x86_64/eos.toml:767-772`, `C-4`), więc cały ten projekt jest tam martwy.
8. **Nie daje niepilnowanego restartu na maszynie z FDE.** Bootloader pyta o hasło przy każdym
   rozruchu (§5.1); „automatyczna aktualizacja w nocy" kończy się na monicie.
9. **Nie ma trybu ratunkowego.** Wycofanie działa dla stanu, który system zdążył zapisać.
   Maszyna, która nie wstaje i nie ma z czego wrócić, potrzebuje nośnika — a tej ścieżki
   projekt nie ma (`docs/reality-ledger.md`, „No recovery/rescue path").
10. **Nie jest audytowany kryptograficznie.** Ani FDE (`docs/encryption.md:97-98`), ani ta
    warstwa. Brak audytu nie jest wadą projektu aktualizacji — jest granicą tego, co wolno
    o nim powiedzieć na zewnątrz.

---

## 1. Wybór mechanizmu

### 1.1 Cztery warianty wobec tego projektu

| Wariant | Co daje | Czego wymaga na E-OS | Koszt | Znacznik |
|---|---|---|---|---|
| **A. Dwa roothy A/B, obraz blokowy** (Mender / RAUC / ChromeOS) | wycofanie jednym restartem, aktualizacja nigdy nie dotyka działającego roota | druga partycja RedoxFS, wybór slotu w bootloaderze, trwały licznik prób rozruchu, zmiana układu partycji **w instalatorze** | XL | **NOWY PODSYSTEM** |
| **B. Migawka systemu plików + podmiana roota** (btrfs/ZFS, `snapper`) | tanie wycofanie, bez podwojenia miejsca | prymityw migawek w RedoxFS **i** narzędzie do jego obsługi **i** wybór podwoluminu w bootloaderze | XL, z czego większość w cudzym forku | **NOWY PODSYSTEM** |
| **C. Transakcyjny menedżer pakietów z dziennikiem** (rpm-ostree bez ostree, nix-ish) | odzyskiwanie po zaniku zasilania, wycofanie plikowe, działa dziś w QEMU | dziennik zamiaru, kopia zamienianych plików, atomowy zapis bazy pakietów | L | **DO ZBUDOWANIA** |
| **D. To, co jest dzisiaj** — `pkg update` in-place | nic ponad instalację | — | — | **JEST**, i jest niebezpieczne (§4.1) |

### 1.2 ostree i systemd-sysupdate — dlaczego nie „weźmiemy ich"

Obie rzeczy są **komponentami linuksowymi**, nie formatami. `libostree` opiera się na GLib/GIO,
magazynie obiektów adresowanym haszem i **twardych dowiązaniach** wiążących drzewo wdrożenia z
tym magazynem; jego model wdrożeń zakłada `/sysroot`, `/ostree/deploy/...` i bootloader, który
czyta wygenerowane wpisy BLS. `systemd-sysupdate` jest częścią systemd i zakłada `systemd-boot`
albo GRUB-a, `.v/`-owe katalogi wersji i partycje typu GPT rozpoznawane przez Discoverable
Partitions Spec.

E-OS nie ma **żadnego** z tych elementów: nie ma GLib, nie ma systemd, nie ma BLS, nie ma DPS,
a bootloader jest własny (`recipes/core/bootloader/`, fork `eos-bootloader`). Wzięcie ostree
oznaczałoby napisanie go od nowa w Ruście na Redoksa. Wolno **pożyczyć ich pomysły** — i
pożyczam poniżej — ale nie wolno pisać w planie „użyjemy ostree", bo to zdanie nie ma na tym
systemie desygnatu.

### 1.3 Czy RedoxFS ma migawki — rozstrzygnięcie

**Nie.**

- Repozytorium opisuje RedoxFS jako *„Copy-on-write, optionally-encrypted filesystem"*
  (`docs/architecture.md:82`). Copy-on-write to własność **wewnętrznej alokacji**, a nie
  funkcja użytkownika.
- W całym drzewie nie ma narzędzia, wywołania ani schematu do robienia migawek:
  `grep -rni snapshot docs/ recipes/ mk/ scripts/ config/` daje wyłącznie **propozycje**
  (`docs/feature-proposals.md:51`) i **plany** (`docs/update-system-design.md:104`), zero
  implementacji. Z RedoxFS-a budowane są tylko dwie binarki: `redoxfs-mkfs` i demon
  montujący `redoxfs` (`mk/fstools.mk:25`).
- Nie ma też subwoluminów, więc nie ma czego wskazywać bootloaderowi jako „inny root".
- **Sprawdzone w samym źródle RedoxFS-a**, w drzewie budowania
  (`recipes/core/redoxfs/source`, fork `eos-redoxfs` rev `58824d70`): `src/transaction.rs`
  używa copy-on-write **wewnętrznie** (linie 233, 474, 1947), ale nie eksponuje żadnego API
  migawek ani wersjonowania. `src/clone.rs` — jedyny plik, który brzmi jak migawka — to
  **klon drzewa plików** (`clone_at`, używany przez fast-clone instalatora): kopiuje
  zawartość, a nie tworzy taniego punktu w czasie, i nosi `//TODO: handle hard links`.

Wniosek dla projektu: **wariant B jest wykluczony na dziś nie dlatego, że jest gorszy, tylko
dlatego, że nie ma na czym go oprzeć.** `clone_at` nie jest migawką i nie wolno go za nią
podstawiać: koszt kopii jest liniowy wobec danych, a nie stały wobec metadanych, więc
„migawka przed każdą aktualizacją" znaczyłaby drugą kopię roota przy każdym `pkg update`.
Gdyby RedoxFS kiedyś dostał prawdziwy prymityw migawek, wariant B jest tańszy od A (nie
podwaja miejsca) i wtedy warto go rozważyć ponownie — ale wpisywanie go dziś do planu byłoby
planowaniem cudzej pracy w cudzym repozytorium. To samo rozstrzygnięcie zapisują `ADR-0008`
(gdzie należy) i `ADR-0009` D2 (który je przyjmuje, a nie powtarza).

**Zastrzeżenie o prowieniencji, bo ono decyduje, ile to zdanie waży:** powyższe pochodzi z
**drzewa budowania**, nie z tego repozytorium — `recipes/core/redoxfs/` zawiera tutaj wyłącznie
`recipe.toml`, a źródła pobiera cookbook (`CLAUDE.md` §20.1: to są dwa różne drzewa i nic ich
nie synchronizuje automatycznie). Kontrola do powtórzenia na świeżym checkoucie:
`grep -rn "snapshot\|subvol" <checkout eos-redoxfs>/src` — dziś **zero trafień**.

### 1.4 Dlaczego układ partycji jest tu decyzją krytyczną

Instalator tworzy **dokładnie trzy** partycje i cały pozostały dysk oddaje jednemu RedoxFS-owi
(`installer.rs:565-660` — odczytane w **drzewie budowania**, `recipes/core/installer/source`;
w tym repozytorium leży tylko `recipe.toml`, więc czytelnik nie sprawdzi tego stąd. `ADR-0007`
i `ADR-0008` opierają na tej tabeli własne decyzje, więc jej prowieniencja musi być jawna —
patrz §11 poz. 10):

| # | Typ GPT | Nazwa | Rozmiar |
|---|---|---|---|
| 1 | `BIOS` | `BIOS` | 1 MiB (zawiera tablice GPT) |
| 2 | `EFI` | `EFI` | 1 MiB domyślnie (`efi_partition_size`) |
| 3 | `LINUX_FS` | `REDOX` | **cała reszta dysku** |

Z tego wynikają trzy twarde fakty:

1. **Nie ma miejsca na drugi root.** Sloty A/B nie są zmianą w systemie aktualizacji —
   są zmianą w **instalatorze**. Maszyna zainstalowana dziś nigdy nie dostanie slotów bez
   przepartycjonowania.
2. Dlatego `R-710` (sloty A/B) jest w rzeczywistości sprzężone z `R-609` (ręczne
   partycjonowanie / instalacja obok). To jest **rozszerzenie** obu pozycji, nie nowa praca:
   ten sam kod `with_whole_disk()` musi nauczyć się układu innego niż „jeden root do końca dysku".
3. **Partycja EFI ma 1 MiB, a zapas jest mniejszy, niż wygląda.** Rozmiary bootloadera są
   **mierzone i rozbieżne**, więc podaję je wszystkie zamiast jednej wygodnej liczby:
   `0x2f600` = **194 048 B (189,5 KiB)** w logu instalacji (`R-F19`); **164 352 B** dla
   aarch64/UEFI po włączeniu LTO w `V2-MS02` (`U-212`); **232 504 B** dla
   `bootloader-live.efi` w zbudowanym drzewie `build/x86_64/eos/`; `U-207` zmierzył skok
   183 → 227 KB po regeneracji. Licz na **najgorszym** przypadku: przy 232 504 B trzy kopie
   to **697 512 B ≈ 681 KiB**, czyli mieszczą się w 1 MiB, ale **bez uwzględnienia narzutu
   FAT-a** (tablice, katalog, rozmiar klastra). Dwie kopie mieszczą się bezpiecznie, trzy są
   na granicy — i to jest liczba, którą trzeba sprawdzić przed wdrożeniem A/B na ESP, a nie
   po. Jądro i initfs **nie leżą na ESP**, tylko w RedoxFS-ie pod `/usr/lib/boot/`
   (`recipes/core/kernel/recipe.toml:14-15`, `recipes/core/base/recipe.toml:27`). Slot A/B na
   E-OS to więc slot **RedoxFS-a**, a nie slot ESP-u.

### 1.5 Rekomendacja

**Wariant C teraz, wariant A później — i dokładnie w tej kolejności.**

Uzasadnienie wobec systemu plików i bootloadera **tego** projektu:

- Wariant B jest niemożliwy (§1.3).
- Wariant A wymaga trzech rzeczy naraz, z których żadna nie istnieje: drugiego roota
  (zmiana instalatora), wyboru slotu w bootloaderze (zmiana `eos-bootloader`) i **trwałego
  licznika prób rozruchu zapisywanego przez bootloader** (dziś bootloader niczego nie
  zapisuje). To jest `R-710` i słusznie stoi na 💡 z zależnością od `R-707`.
- Wariant C daje **największą redukcję ryzyka na jednostkę pracy**, bo naprawia to, co dziś
  jest realnie zepsute: rename-pętlę bez dziennika (§4.1). Jest w całości wykonywalny na
  aarch64 pod QEMU, czyli na jedynym stanowisku, na którym ten projekt potrafi cokolwiek
  udowodnić.
- Wariant C jest **warunkiem** wariantu A, a nie jego konkurentem: A/B potrzebuje dziennika,
  kontroli zdrowia i wycofania tak samo. Zbudowanie A bez C dałoby sloty, których nikt nie
  umie bezpiecznie przełączyć.

**Odwołanie do roadmapy:** rekomendacja nie tworzy nowych pozycji. Wariant C to `R-706`
(transakcja + dziennik) plus `R-707` (baza i jądro przy restarcie). Wariant A to **dokładnie**
`R-710` — *„sloty A/B roota + aktualizacje różnicowe"* — z jednym uściśleniem, którego opis
`R-710` dziś nie zawiera: **część różnicowa jest tania i niezależna od slotów** (§2.3), więc
`R-710` warto rozciąć na `R-710a` (różnicowe, `[P2·M]`, nie potrzebuje `R-707`) i `R-710b`
(sloty A/B, `[P3·XL]`, potrzebuje `R-707` **i** `R-609`).

**Stan tej propozycji: przyjęta.** `ROADMAP.md` zapisuje rozcięcie jako wiążące,
z adnotacją, że pochodzi z tej sekcji, a `ROADMAP.md` (kamień M8) wiąże `R-710a`,
`R-710b` i `R-609` w jeden etap. Piszę to tutaj, żeby nikt nie potraktował §1.5 jako otwartego
wniosku i nie zgłosił go drugi raz pod inną nazwą.

---

## 2. Pobieranie i staging do nieaktywnego slotu

### 2.1 Punkt wyjścia — zmierzony, nie założony

`pkg-lib` pobiera przez proces potomny:

```
Command::new("curl").arg("-sSL").arg(remote_path)   // curl_backend.rs:28
```

Strumień idzie prosto do `DownloadBackendWriter`. Z tej jednej linii wynika wszystko, czego
brakuje:

| Cecha | Stan | Znacznik |
|---|---|---|
| Wznawianie po zerwaniu | brak `-C -`, brak pliku częściowego — zerwanie = pobieranie od zera | **DO ZBUDOWANIA** |
| Limit pasma | brak `--limit-rate` | **DO ZBUDOWANIA** |
| Limit czasu | brak `--max-time` / `--connect-timeout` — martwy host wisi | **DO ZBUDOWANIA** |
| Postęp | `callback.download_increment()` **jest** i działa | **JEST** |
| Weryfikacja przed zapisem do systemu | jest, i to na bajtach (`V2-MS13`) | **JEST** |

Trzy z tych czterech braków to flagi `curl`-a. To nie jest architektura — to jest zaniedbanie,
które da się zamknąć w jednym MR-ze przy `R-705`.

### 2.2 Staging: gdzie

Dopóki nie ma slotów (§1.5), „nieaktywny slot" to **katalog przejściowy w tym samym
RedoxFS-ie**:

```
/var/lib/eos-update/
├── journal.toml          # zamiar + postęp, fsync przed każdą zmianą fazy
├── staged/<serial>/      # zweryfikowane .pkgar, gotowe do zastosowania
├── rollback/<serial>/    # kopie plików, które commit nadpisze
└── pending/              # jądro, initfs, base — stosowane przy restarcie (R-707)
```

Po `R-710b` `staged/` znika, a jego rolę przejmuje nieaktywna partycja. **Ważne dla migracji:**
układ dziennika projektujemy tak, żeby ta zamiana nie zmieniała formatu dziennika — dziennik
opisuje *zamiar*, nie *nośnik*.

**Koszt miejsca, powiedziany wprost:** wariant C podwaja zajętość tylko dla zamienianych plików
(kopie w `rollback/`). Wariant A podwaja **cały root**. Przy obrazie rzędu 460 MB kopiowanym
przez instalator (`R-F24`, zmierzone) drugi slot to kolejne kilkaset MB — na maszynie z małym
SSD to jest decyzja, którą użytkownik musi podjąć **przy instalacji**, bo później jej nie
podejmie (§1.4).

### 2.3 Aktualizacje różnicowe — na czym je oprzeć

Tu projekt ma nieoczywistą przewagę i szkoda byłoby jej nie użyć.

Fakt 1: pkgar **gotowany lokalnie** jest nieskompresowany. `cook` woła
`pkgar::create_with_flags(...)` z `Packaging::LZMA2` tylko gdy `cook_config.compressed`
(`src/cook/package.rs:110-121`), a domyślną wartością jest
`extract_env("COOKBOOK_COMPRESSED", false)` (`src/config.rs:149`), której `.config` nie
nadpisuje. Czyli dla tych pakietów dziś: `Packaging::Uncompressed`.

**Fakt 1 ma granicę i trzeba ją podać razem z nim, bo inaczej cała ta sekcja obiecuje więcej,
niż pokrywa.** `.config` ustawia `REPO_BINARY?=1`, więc cookbook **domyślnie pobiera** gotowy
`<przepis>.pkgar` ze `static.redox-os.org`, a gotuje ze źródła wyłącznie te przepisy, które
mają w `cookbook.lock` wpis `fsrule = "source"` — dziś **28 z nich** (`CLAUDE.md` §9,
`ADR-0002`). Opublikowany indeks liczył **85 pakietów** (`U-224`), więc część artefaktów w
kanale została zbudowana **poza tym drzewem** i ich flaga `Packaging` nie zależy od
`COOKBOOK_COMPRESSED`. Konsekwencja projektowa jest konkretna: delta z tej sekcji działa
**per pakiet**, nie globalnie, a klient i tak musi umieć spaść do pełnego pobrania (§2.4,
wiersz o fladze `Packaging`).

Fakt 2: format pkgar trzyma tablicę wpisów, gdzie każdy wpis to
`{ blake3: [u8;32], offset: u64, size: u64, mode, path }` (`pkgar-core/src/entry.rs:11`).

Z tych dwóch faktów wynika mechanizm różnicowy, którego **nie trzeba wymyślać**:

1. Klient ma zainstalowaną wersję pakietu i jej tablicę wpisów (`var/lib/packages/*.pkgar_head`).
2. Pobiera **sam nagłówek** nowej wersji (podpisany ed25519, weryfikowalny osobno) — to kilka
   do kilkudziesięciu KiB zamiast całego pakietu.
3. Porównuje `blake3` wpis po wpisie. Pobiera **zakresami HTTP `Range`** wyłącznie te wpisy,
   których hasz się zmienił, korzystając z `offset`+`size`.
4. Weryfikacja się nie zmienia: każdy wpis i tak ma sprawdzany blake3 przy rozpakowaniu, a
   nagłówek jest przypięty do podpisanego `repo.toml` (`V2-MS13`).

To jest delta **na poziomie plików**, nie bajtów. Nie dorówna `bsdiff`-owi na jednym wielkim
binarium, ale na typowej aktualizacji, gdzie zmienia się kilka plików w pakiecie, oszczędność
jest tego samego rzędu — a koszt to jedna funkcja i flaga `curl --range`, bez nowego formatu,
bez nowego narzędzia po stronie wydawcy i **bez osłabiania weryfikacji**.

**Cena, którą trzeba nazwać:** ten mechanizm działa **tylko** przy `Packaging::Uncompressed`.
Włączenie `COOKBOOK_COMPRESSED=1` zabija adresowalność zakresami (LZMA2 to jeden strumień) i
unieważnia całą tę sekcję. To musi być zapisane jako **niezmiennik budowania**, najlepiej jako
kolejna kontrola w `scripts/ci-integrity.sh` — dokładnie w duchu kontroli 9 z `U-183`: fakt,
który dziś jest prawdziwy przypadkiem, jutro przestaje być prawdziwy bez śladu.

**Jak ta kontrola zawodzi — i dlatego nie wolno jej napisać na `COOKBOOK_COMPRESSED`.** Bramka
sprawdzająca zmienną środowiskową albo `.config` mierzy **zamiar**, a mierzyć trzeba
**artefakt**: pakiety wciągnięte przez `REPO_BINARY=1` przechodzą obok tej zmiennej i mogą być
skompresowane, a bramka i tak zaświeci na zielono. To jest ta sama wada, którą `U-183`
naprawiał przy `50_redox` (pomiar w obrazie, nie w pliku źródłowym) i którą `U-224` złapał
przy `repo_builder` (zielony build, pole nieobecne w indeksie). Kontrola musi więc czytać
**flagę `Packaging` z nagłówków opublikowanych `.pkgar`** i mieć kontrolę negatywną: pakiet
zbudowany z `COOKBOOK_COMPRESSED=1` **musi** ją przewrócić. Bez tej negatywnej połowy jest to
ozdoba (`CLAUDE.md` §4.1, §13).

Znacznik: **DO ZBUDOWANIA**, rozmiar M, przypisane do `R-710a` (§1.5).

### 2.4 Fallback do pełnego pakietu

Kontrola, która nie może zawieść, nie jest kontrolą — więc opisuję, jak ta zawodzi:

| Warunek porażki | Wykrycie | Reakcja |
|---|---|---|
| Serwer ignoruje `Range` i zwraca 200 zamiast 206 | kod odpowiedzi ≠ 206 | pełne pobranie pakietu |
| Lustro nie obsługuje `Range` w ogóle | jak wyżej | pełne pobranie, jednorazowa notatka w dzienniku |
| Nagłówek zmienił `offset` wszystkich wpisów (przebudowa) | liczba trafionych wpisów < progu (np. < 25%) | pełne pobranie — delta byłaby droższa |
| Zszyty pakiet nie zgadza się z `header.blake3` | istniejące `enforce_manifest_blake3()` | **odrzucenie**, pełne pobranie, a przy drugiej porażce twardy błąd |
| Pakiet nieskompresowany po stronie klienta, skompresowany po stronie repo | flaga `Packaging` w nagłówku | pełne pobranie |

Domyślnie: **przy każdej wątpliwości pobierz całość**. Delta jest optymalizacją pasma, nigdy
warunkiem poprawności.

### 2.5 Kontrola pasma i okna pobierania

- `--limit-rate` z konfiguracji (`/etc/eos-update.toml`), domyślnie bez limitu.
- `--max-time`, `--connect-timeout` — obowiązkowo, żeby martwe lustro nie wieszało demona.
- Okno pobierania (np. 01:00–05:00) — **zależy od zaufanego czasu, którego nie ma** (§8.3).
  Co gorsza, **w `ROADMAP.md` nie ma ani jednej pozycji na źródło czasu** (sprawdzone:
  zero trafień na „NTP"/„RTC"), więc to nie jest zależność czekająca w kolejce, tylko luka
  poza planem. Dopóki tak jest, okna są „najlepszym staraniem" i **tak muszą być nazwane
  w UI** — a domyślny harmonogram liczy się od rozruchu, nie od zegara ściennego (§8.3).

---

## 3. Weryfikacja kryptograficzna

### 3.1 Co jest zbudowane — i dokładnie jak daleko sięga

To jest najsilniejsza warstwa tego projektu i nie należy jej przepisywać od zera. Stan
zmierzony w kodzie:

| Warstwa | Mechanizm | Dowód | Znacznik |
|---|---|---|---|
| Indeks repozytorium | `repo.toml.sig`, hybryda ed25519 + ML-DSA-65 | `ADR-0004`, `tools/eos-repo-sign` | **JEST** |
| Weryfikacja indeksu na urządzeniu | `verify_repo_manifest` → `manifest_sig::verify_manifest_ed25519` | `pkg-lib/src/manifest_sig.rs`, przypięte `eos-pkgutils@14505ecd` (`ROADMAP.md:342`) | **JEST W KODZIE, NIEDOWIEDZIONE NA ŻYWO** — `R-703` stoi na 🟡 (`ROADMAP.md`): pełnego fetch+verify nikt jeszcze nie złapał w działaniu, a `U-197` mówi wprost, że ścieżki `RepoManifestUnsigned`/`RepoManifestSigInvalid` pozostają nieprzebiegnięte. Precedens `U-164` (dokumentacja nazywała to zaimplementowanym, gdy w artefakcie tego nie było) zakazuje tu znacznika **JEST** bez tego zastrzeżenia. |
| Klucz przypięty w obrazie | `/etc/pkg/eos-repo-sign.pub.toml`, 4075 B, zmierzone w działającym systemie | `R-702` ✅ (`U-197`, `U-224`) | **JEST** |
| Przypięcie pakietu do indeksu | `enforce_manifest_blake3()` — odrzuca `.pkgar`, którego hasz nagłówka nie jest tym z podpisanego indeksu | `pkgar_backend/mod.rs:145` (`V2-MS13`) | **JEST** |
| Ta sama kontrola na ścieżce `install` | `V2-MS14` | `U-223` | **JEST** |
| Świeżość indeksu | `serial` (zapadka) + `expires` | `package.rs:383,391`, `check_manifest_freshness()` | **JEST** |
| Podpis per pakiet | ed25519 nad nagłówkiem, blake3 per wpis | `pkgar-core` `Header::new` | **JEST** |
| Podpis jądra i initfs | **ed25519 nad `SHA-512(role ‖ len_le ‖ data)`** — prehasz jest częścią konstrukcji, nie szczegółem; bootloader odmawia startu bez podpisu | `recipes/core/kernel/recipe.toml:16-24` (tag roli, prehasz, `openssl pkeyutl -sign -rawin`), `recipes/core/base/recipe.toml:27-33`, dowód end-to-end z kontrolą negatywną w `U-212` | **JEST** |

**Trzy zastrzeżenia, które trzeba mówić razem z tą tabelą, bo inaczej jest kłamstwem przez
przemilczenie:**

1. **ML-DSA-65 nie jest weryfikowane na urządzeniu.** Komentarz w `manifest_sig.rs` mówi to
   wprost: *„On-device we verify the **ed25519** layer... ML-DSA verification stays host-side"*
   — cytat pochodzi z forka `eos-pkgutils` w drzewie budowania, nie z tego repozytorium
   (patrz §11 poz. 11). Niezależne potwierdzenie **w tym drzewie**: `ROADMAP.md:342` wymienia
   *„promote ML-DSA-65 from advisory to required per `R-503`"* jako pozycję **pozostałą**, a
   `ROADMAP.md` liczy `R-503` wśród warunków, których ten dokument nie zamyka.
   Hybryda jest dziś hybrydą **po stronie wydawcy**. Odporność postkwantowa istnieje w
   artefakcie, nie w kliencie.
2. **Zapadka antycofkowa leży w zwykłym pliku** — `etc/pkg/repo-state.toml` (`pkg-lib/src/lib.rs:37`),
   który root może skasować. Kod sam to przyznaje: *„this is not a TPM counter and must not be
   described as one"* (znów: fork w drzewie budowania). Potwierdzenie w tym drzewie: `U-223`
   kończy się zdaniem *„znacznik antycofkowy leży w zwykłym pliku obok przypiętego klucza, więc
   root na maszynie może go skasować — to ochrona przed napastnikiem w sieci, nie przed
   lokalnym"*. Ta sama granica dotyczy `package_serial` z §3.2.
3. **Połowa `expires` zależy od zegara, którego nie ma.** Brak źródła NTP/RTC (`docs/reality-ledger.md:144`),
   więc na maszynie bez sensownego zegara `expires` odpada i zostaje sama zapadka — czyli
   ochrona przed *freeze* jest słabsza niż ochrona przed *rollback*.

### 3.2 Dziura `R-704` — nazwana wprost

**Dziś poprawnie podpisany STARSZY pakiet wciąż się instaluje.** To nie jest teoria, to jest
sześć linii kodu:

```rust
// pkg-lib/src/library.rs:141-149
for package in packages {
    if let Some(source_hash) = repo_list.packages.get(package.as_str()) {
        if let Some(local_hash) = local_list.installed.get(package.as_str()) {
            if local_hash.blake3 != *source_hash {   // ← jedyne kryterium
                new_packages.push(package);
```

Decyzja „czy aktualizować" opiera się **wyłącznie** na tym, czy hasz się różni. Nie na wersji,
nie na dacie publikacji, nie na numerze budowania. Struktura `Package` ma pole `version` i
`time_identifier` (`package.rs:30,45`) — i **żadne z nich nie jest w tej decyzji użyte**.

Skutek: `V2-MS15` zamknął cofnięcie **całego indeksu**, ale nie cofnięcie **pojedynczego
pakietu wewnątrz świeżego indeksu**. Wydawca (albo ktoś, kto przejmie infrastrukturę
publikacji) może opublikować indeks z `serial = N+1`, zawierający starą, dziurawą wersję
jednego pakietu. Klient zobaczy „hasz inny niż zainstalowany", uzna to za aktualizację i
zainstaluje **cofnięcie**. Wszystkie podpisy są przy tym poprawne i wszystkie kontrole
przechodzą.

**Poprawka (`R-704`, zakres):**

- Do `repo.toml` per pakiet: `version` (już jest w schemacie) **i** monotoniczny
  `package_serial`. Oba objęte podpisem indeksu, więc nie trzeba nowego klucza.
- Klient: odmawia instalacji, gdy `nowy.package_serial < zainstalowany.package_serial`,
  chyba że użytkownik jawnie zażądał cofnięcia (`eos-update rollback --to <serial>`), i wtedy
  zapisuje to w dzienniku audytu jako świadomą decyzję operatora.
- Znacznik zainstalowanego `package_serial` trafia do `packages.toml` — czyli tam, gdzie już
  jest baza stanu.

**Jak ta kontrola zawodzi:** identycznie jak zapadka indeksu — root kasuje `packages.toml`
i traci historię. Nie da się tego naprawić bez zaufanego licznika sprzętowego, a tego nie ma
(§5.4). Trzeba to **napisać w dokumentacji dla administratora** (`R-712`), a nie ukryć.

### 3.3 Hierarchia kluczy i rotacja (`R-711`)

Stan dzisiaj — trzy niezależne klucze, bez wspólnego korzenia:

| Klucz | Co podpisuje | Gdzie żyje połowa tajna | Gdzie żyje połowa publiczna |
|---|---|---|---|
| `eos-repo-sign` (ed25519 + ML-DSA-65) | `repo.toml` | magazyn operatora poza repo (`U-224`) | `/etc/pkg/eos-repo-sign.pub.toml` w obrazie |
| klucz pakietów (ed25519) | każdy `.pkgar` | **`build/id_ed25519.toml` w drzewie budowania, jawnym tekstem, generowany przez cookbook przy pierwszym braku** (`src/cook/package.rs:42-43`). Kopia zapasowa istnieje i jest zweryfikowana co do bajtu (`~/.eos-keys/eos-pkg-signing.secret.toml`, `U-216`), ale **obie leżą na jednym komputerze** — `V2-MS12` 🟡, znalezisko `C-11` | wbudowany w nagłówek pakietu; publiczna połowa zapisana w `keys/eos-pkg-signing.pub.toml` |
| klucz rozruchu (ed25519) | jądro, initfs | `build/boot-signing/boot.key`, poza repo | wkompilowany w bootloader (`V2-MS02`) |
| klucz Secure Boot (X.509) | `bootloader.efi` | `build/sb-signing/mok.key`, poza repo | w firmware, wgrany przez właściciela (`ADR-0005`) |

Dwie rzeczy trzeba powiedzieć bez owijania:

1. **Klucz podpisujący pakiety jest przechowywany jawnym tekstem i generowany przez narzędzie
   budowania** (`V2-MS12`). To jest najsłabsze ogniwo w całej tabeli i nie jest problemem
   systemu aktualizacji — jest problemem custody, który system aktualizacji odziedziczy.
2. **pkgar nie ma keyringu.** Nagłówek zawiera dokładnie jeden `public_key: [u8;32]`
   (`pkgar-core/src/header.rs:16`) i weryfikacja to `crypto_sign_open` wobec **tego** klucza.
   Rotacja klucza pakietów oznacza dziś **przepodpisanie i republikację całego repozytorium**
   (`V2-MS12` szacuje 642 MB), a unieważnienie starego klucza nie ma gdzie zostać zapisane.

**Projekt rotacji (`R-711`, znacznik DO ZBUDOWANIA — nie NOWY PODSYSTEM, bo nośnik już jest):**

- Wprowadzić **keyring w obrazie**: `/etc/pkg/keys.d/`, katalog kluczy publicznych z polami
  `not_before` / `not_after` / `revoked`, **objęty podpisem indeksu** (czyli publikowany jako
  część `repo.toml`, a nie jako osobny kanał zaufania).
- Rotacja = nowy klucz wchodzi z `not_before` w przyszłości, stary dostaje `not_after`.
  Okres zakładkowy, w którym oba są ważne, jest **wymagany**, bo maszyna offline przez rok
  musi mieć czym zweryfikować to, co zastanie.
- Unieważnienie = wpis `revoked` w keyringu **plus** podbicie `serial`, żeby zapadka
  wymusiła pobranie nowej listy.
- Klucz przypięty w obrazie (`eos-repo-sign`) pozostaje **kotwicą i nie rotuje się zdalnie** —
  jego rotacja wymaga nowego obrazu albo aktualizacji bazy przy restarcie (`R-707`). To jest
  celowe: kotwica, którą da się wymienić przez ten sam kanał, który uwierzytelnia, nie jest kotwicą.

**Jak to zawodzi:** maszyna, która przespała cały okres zakładkowy i ma tylko unieważniony
klucz, **nie zaktualizuje się** i musi zostać przeinstalowana albo naprawiona nośnikiem
offline. To jest świadomy koszt, nie usterka — i musi być w `R-712`.

### 3.4 Bezpieczeństwo repozytorium w stylu TUF — co bierzemy, czego nie

TUF rozkłada zaufanie na role, żeby kompromitacja jednej nie wystarczyła. Rozbicie wobec E-OS:

| Rola TUF | Odpowiednik w E-OS | Znacznik |
|---|---|---|
| `targets` (co jest w repo, z haszami) | `repo.toml` + `repo.toml.sig` | **JEST** |
| `snapshot` (spójność zestawu w czasie) | `serial` w `repo.toml` | **JEST** (`V2-MS15`) |
| `timestamp` (świeżość, krótkie ważności) | `expires` w `repo.toml` | **JEST**, ale bezzębne bez zegara (§3.1) |
| `root` (klucze i progi, rotacja) | keyring z §3.3 | **DO ZBUDOWANIA** (`R-711`) |
| Progi wielopodpisowe (*m z n*) | brak | **NIEREALNE DZIŚ** — wymaga **wielu operatorów**; ten projekt ma jednego, a próg 1-z-1 to teatr |
| Delegacje ról na podrepozytoria | brak | **NIEREALNE DZIŚ** — nie ma podrepozytoriów |
| Rejestr przejrzystości (transparency log) | brak | **NIEREALNE DZIŚ** — wymaga niezależnego świadka, czyli drugiej strony |

Uczciwa konkluzja: E-OS ma **trzy z czterech kluczowych ról TUF** i brakuje mu roli `root`.
Nie ma natomiast **żadnej** z własności TUF-a, które wymagają więcej niż jednej strony — i nie
zdobędzie ich przez kod. Pisanie w materiałach zewnętrznych „bezpieczeństwo w stylu TUF" bez
tego rozróżnienia byłoby powtórzeniem błędu z `V2-MS15`, gdzie publikowane README obiecywało
ochronę przed *freeze*, której nie było.

### 3.5 Powtarzalne budowanie

**Znacznik: DO ZBUDOWANIA, i to jest warunek wstępny, nie ozdoba.**

`R-303` mówi wprost, że znaczniki czasu obrazu wciąż się różnią, więc bajtowa powtarzalność
**nie jest** osiągnięta. Dla systemu aktualizacji ma to konkretną konsekwencję: bez
powtarzalności **nikt poza operatorem nie może sprawdzić, że opublikowany pakiet odpowiada
opublikowanemu źródłu**. Cały łańcuch podpisów dowodzi wtedy tylko tego, że „to podpisał
właściciel klucza", a nie „to jest to, co obiecano".

Minimalny zakres, w kolejności rosnącego kosztu: `SOURCE_DATE_EPOCH` w `cook`, deterministyczna
kolejność wpisów w pkgar (tablica jest sortowana? — patrz §11), usunięcie ścieżek budowania
z binariów (`--remap-path-prefix`), przypięcie wersji łańcucha narzędzi (jest:
`rust-toolchain.toml`). To jest praca na `R-303`, a nie na `R-7xx` — ale system aktualizacji
powinien ją **wymagać**, a nie tylko na nią liczyć.

### 3.6 Kolejność kontroli — i jak każda zawodzi

Kontrola, która nie może zawieść, nie jest kontrolą. Poniżej pełna sekwencja, z jawnym
zachowaniem przy porażce. Żaden bajt nie dotyka żywego systemu przed punktem 8.

| # | Kontrola | Zawodzi gdy | Reakcja |
|---|---|---|---|
| 1 | Klucz kotwiczący obecny | brak `/etc/pkg/eos-repo-sign.pub.toml` | **dziś: ostrzeżenie i kontynuacja.** Docelowo: twarda odmowa dla źródeł zdalnych. To jest zmiana zachowania i musi być świadoma. |
| 2 | Podpis indeksu (ed25519) | podpis nie pasuje / plik uszkodzony | odmowa, zero pobrań |
| 3 | Podpis indeksu (ML-DSA-65) | **dziś niesprawdzany na urządzeniu** | zakres `R-503` |
| 4 | Zapadka `serial` | `serial < watermark` | odmowa — „to jest powtórka" |
| 5 | Ważność `expires` | `now > expires` **i** zegar wiarygodny | odmowa; przy niewiarygodnym zegarze — ostrzeżenie |
| 6 | `package_serial` per pakiet | starszy niż zainstalowany | **DO ZBUDOWANIA — `R-704`** |
| 7 | Hasz pakietu = hasz z podpisanego indeksu | niezgodność | odmowa (`enforce_manifest_blake3`) |
| 8 | Podpis nagłówka pkgar + blake3 każdego wpisu | niezgodność | odmowa, transakcja nietknięta |
| 9 | Ochrona przed wyjściem ze ścieżki | wpis wskazuje poza katalog docelowy | odmowa (`check_path`) |
| 10 | Dziennik zamiaru zapisany i zsynchronizowany | zapis się nie powiódł | **odmowa startu commitu** — bez dziennika nie ma commitu (§4.2) |

Punkt 1 zasługuje na osobne zdanie, bo dziś jest miękki: brak przypiętego klucza daje
ostrzeżenie, a nie odmowę. To było uzasadnione, gdy klucza nie było (`R-702` zamknięte dopiero
w `U-197`/`U-224`). Teraz klucz **jest w obu obrazach**, więc miękkość jest już tylko długiem —
i jej usunięcie należy do `R-704` jako najtańsza jego część.

---

## 4. Atomowa aktywacja przy restarcie

### 4.1 Punkt wyjścia jest zły i trzeba to powiedzieć

`R-706` opisuje to poprawnie i potwierdzam w kodzie.

**Zastosowanie aktualizacji to pętla `rename` bez dziennika:**

```rust
// pkgar-0.2.2/src/transaction.rs:350
pub fn commit(&mut self) -> Result<usize, Error> {
    self.reset_committed();
    while self.actions.len() > 0 { self.commit_one()?; }   // fs::rename, po jednym
    Ok(self.committed)
}
```

Licznik `committed` i stos `actions` żyją **wyłącznie w pamięci procesu**
(`transaction.rs:104-107`). Zanik zasilania w połowie pętli zostawia system, w którym część
plików jest z nowej wersji, część ze starej, a **nic tego nie odnotowało**. Po restarcie nie ma
z czego odtworzyć ani co cofnąć.

**Do tego baza pakietów zapisywana jest nieatomowo:**

```rust
// pkg-lib/src/package_state.rs:95
std::fs::write(&packages_path, self.to_toml())
```

To jest truncate-then-write bez pliku tymczasowego, bez `rename`, bez `fsync`. Zanik zasilania
w tym miejscu zostawia `/etc/pkg/packages.toml` **pusty albo obcięty** — czyli system, który
nie wie, co ma zainstalowane. Tego `R-706` w opisie nie wymienia, a powinien: to jest gorsze
od przerwanej pętli rename, bo niszczy **metadane**, a nie zawartość.

**Trzecia rzecz, tego samego rodzaju:** zapadka antycofkowa też idzie przez
`let _ = fs::write(&path, ...)` (`pkgar_backend/mod.rs:213`), z jawnie zignorowanym błędem.
Komentarz nazywa to „best effort" i to jest uczciwe — ale w połączeniu z §3.1 znaczy tyle, że
kontrola świeżości może po cichu nie zapisać nowego znacznika.

**Wniosek:** nie budujemy A/B na tym fundamencie. Najpierw dziennik.

### 4.2 Dziennik zamiaru (`R-706`)

Model: **zamiar zapisany przed działaniem, faza po fazie, każda zsynchronizowana.**

```
IDLE → SPRAWDZANIE → DOSTĘPNE → POBIERANIE → ZWERYFIKOWANE
     → KOPIA_ZAPASOWA → COMMIT → ZATWIERDZONE
                      ↘ ODZYSKIWANIE → WYCOFANE
```

- `journal.toml` niesie: `serial` źródłowy i docelowy, listę pakietów, listę **plików** z
  ich stanem (`pending` / `backed_up` / `renamed`), znacznik czasu i wynik.
- Zapis dziennika: zawsze `tmp` + `rename` + `fsync` katalogu. Ten sam wzorzec **trzeba
  wsteczne nałożyć na `PackageState::to_sysroot()`** — to jest najtańsza pojedyncza poprawka
  w całym dokumencie i powinna wejść przed resztą `R-706`.
- Przy starcie `eos-updated` czyta dziennik. Faza inna niż `ZATWIERDZONE` lub `IDLE` znaczy,
  że poprzedni przebieg został przerwany → **dokończ albo cofnij**, w zależności od tego, czy
  wszystkie pliki mają kopie zapasowe.

**Jak to zawodzi:** jeżeli `fsync` na RedoxFS-ie nie daje gwarancji trwałości, której się po
nim spodziewamy, cały ten mechanizm jest ozdobą. **Tego nie zweryfikowałem** — patrz §11.
Kontrola: napisać test, który przerywa QEMU w losowym momencie commitu (`-snapshot` + zabicie
procesu) i sprawdzić, czy system wstaje w stanie spójnym. Bez tego testu `R-706` nie wolno
oznaczyć jako zrobione.

### 4.3 Licznik prób rozruchu i automatyczne wycofanie (`R-707`)

Aktualizacja bazy, jądra i `relibc` **nie może** być stosowana na żywo — dziś jest, i to
jest największe pojedyncze ryzyko w tym systemie (`R-707`, potwierdzone w §1.4: jądro leży
pod `/usr/lib/boot/kernel` w tym samym RedoxFS-ie, który `pkg` modyfikuje).

Projekt:

1. `eos-updated` odkłada nowe `kernel`, `kernel.sig`, `initfs`, `initfs.sig` do
   `/var/lib/eos-update/pending/` — **razem z podpisami**, bo bez podpisu bootloader odmówi
   startu (`V2-MS02`), a niedopasowana para to niebootowalna maszyna.
2. Zapisuje `/boot/eos-update-pending` z docelowym `serial`.
3. Przy restarcie **bootloader** czyta flagę, weryfikuje podpisy pending, przenosi je na
   miejsce i **zwiększa licznik prób**.
4. Po udanym rozruchu `eos-updated` wykonuje kontrole zdrowia (§4.4) i **zeruje licznik**.
5. Jeżeli licznik osiągnie N (proponuję **3**) bez wyzerowania — bootloader przywraca
   poprzednie jądro i initfs, które trzyma pod `/usr/lib/boot/kernel.prev`.

**Tu jest sedno klasyfikacji: to jest NOWY PODSYSTEM, nie rozszerzenie.** Powód: dzisiejszy
bootloader **niczego nie zapisuje**. Weryfikuje podpisy, prosi o hasło RedoxFS-a, ładuje jądro.
Nadanie mu zdolności zapisu to zmiana o niebanalnych konsekwencjach — bootloader działa
**przed** odszyfrowaniem roota, więc licznik musi leżeć albo na nieszyfrowanym ESP (i wtedy
napastnik z fizycznym dostępem może go wyzerować lub przekręcić), albo w RedoxFS-ie (i wtedy
bootloader musi umieć **zapisywać** do zaszyfrowanego RedoxFS-a, czego dziś nie robi).

Rekomendacja: **licznik na ESP, i powiedzieć wprost, że nie chroni przed napastnikiem
fizycznym** — bo ten i tak jest poza modelem (`docs/encryption.md`, „Caveats"). Licznik broni
przed **złą aktualizacją**, a nie przed człowiekiem z śrubokrętem.

**Jak ten licznik zawodzi — trzy tryby, każdy do obsłużenia w projekcie, nie po awarii:**

| Tryb porażki | Skutek, jeśli go zignorować | Co robi projekt |
|---|---|---|
| Zapis licznika na ESP nie powiódł się (FAT pełny, uszkodzony sektor, brak sterownika) | licznik nie rośnie → **automatyczne wycofanie nigdy się nie odpali**, a wygląda na uzbrojone | brak możliwości zapisu licznika = **odmowa przełączenia w tryb pending**; aktualizacja klasy `boot` nie startuje bez działającego licznika |
| Licznik rośnie, ale kontrola zdrowia nie potrafi go wyzerować (np. `eos-updated` nie wstał) | wycofanie po 3 rozruchach z **poprawnej** aktualizacji | to jest cena projektu i jest właściwa: system, w którym demon aktualizacji nie wstaje, **nie jest zdrowy**. Ale musi to napisać w komunikacie (§8.4), a nie milczeć |
| Napastnik z fizycznym dostępem zeruje albo przekręca licznik na nieszyfrowanym ESP | wycofanie wyłączone albo wymuszone | **poza modelem** i tak nazwane (§0.1 poz. 1). Nie udajemy, że plik na ESP jest kotwicą |

### 4.4 Kontrole zdrowia

Nowy system jest „zdrowy", gdy przejdzie zestaw kontroli w ciągu T sekund od startu.
Proponowany zestaw — celowo ubogi, bo bogaty zestaw sam staje się przyczyną wycofań:

| Kontrola | Skąd | Dlaczego ta |
|---|---|---|
| `init` doszedł do celu `00_base.target` | init | jeśli nie, nic innego nie ma znaczenia |
| root zamontowany do zapisu | `redoxfs` | bez tego nie da się nawet zapisać wyniku |
| baza pakietów parsuje się | `packages.toml` | wykrywa uszkodzenie z §4.1 |
| pojawiła się zachęta do logowania **na konsoli szeregowej** | getty na `/scheme/debug` | to jest dokładnie warunek PASS istniejącego harnessu (`scripts/ci-boot-smoke.sh:96`, wzorzec `eos login:|^Login:|Username:`) |
| w logu nie ma paniki ani nieobsłużonego wyjątku | log szeregowy | ten sam wzorzec, którego harness używa jako FAIL (`ci-boot-smoke.sh:99-101`) |

**Uściślenie, bo łatwo tu obiecać więcej, niż harness robi.** `scripts/ci-boot-smoke.sh`
**niczego nie liczy** i nie ma progu: dopasowuje trzy literały — `KERNEL PANIC`,
`RELIBC PANIC`, `UNHANDLED EXCEPTION` — i pada na **pierwszym** trafieniu (`:99-101`), a
przechodzi, gdy w logu pojawi się zachęta do logowania (`:96`). Nie widzi też greetera
graficznego: `orblogin` nie występuje w żadnym z tych wzorców, więc „system wstał do pulpitu"
jest dla tego narzędzia **niesprawdzalne**. Pierwsza wersja tej sekcji mówiła o „liczniku
wyjątków" i „tym samym progu co harness `R-601`" — obu tych rzeczy w skrypcie nie ma i zdanie
było fałszywe; poprawiam je tutaj, zamiast przepisać po cichu (`CLAUDE.md` §2 reguła 4).

**Jak ten zestaw zawodzi:** kontrola zdrowia, która sama nie potrafi się wykonać (demon nie
wstał, log szeregowy nie jest dostępny na docelowym sprzęcie, terminal graficzny zamiast
serialu), jest nieodróżnialna od kontroli, która wykryła usterkę — a te dwie sytuacje wymagają
przeciwnych reakcji (`CLAUDE.md` §13, `U-177`). Dlatego zestaw musi rozdzielać wynik
**„niezdrowy"** od **„nie zmierzono"**, a `eos-updated` traktować drugie jak pierwsze
(zliczyć próbę rozruchu, nie wyzerować licznika) i **powiedzieć to w komunikacie** (§8.4).

### 4.5 Wycofanie jednym poleceniem

**Znacznik: DO ZBUDOWANIA.** Dziś nie istnieje żadna z trzech części: ani kopie zamienianych
plików, ani odwracalna delta w `packages.toml`, ani polecenie. Nośnik jest — to zwykłe pliki
pod dziennikiem z §4.2 — więc to nie jest nowy podsystem.

```
eos-update rollback            # o jedną generację wstecz
eos-update rollback --to 41    # do konkretnego serial
eos-update history             # co, kiedy, z czego na co
```

Warstwa aplikacyjna: przywrócenie plików z `rollback/<serial>/` plus odwrócenie delty w
`packages.toml`, wszystko pod tym samym dziennikiem. Warstwa bazy i jądra: przełożenie flagi
i restart. Liczba trzymanych generacji — konfigurowalna, domyślnie **2** (bieżąca + jedna
wstecz), bo miejsce na dysku jest realnym ograniczeniem (§2.2).

**Świadome cofnięcie musi ominąć kontrolę z §3.2** — i musi zostawić po sobie wpis audytu.
To jedyne miejsce, w którym instalacja starszego pakietu jest dozwolona.

### 4.6 Gdzie mieszka wskaźnik aktywnego slotu (po `R-710b`)

Po wprowadzeniu slotów A/B trzeba odpowiedzieć na pytanie, którego wariant C nie stawia:
**skąd bootloader wie, który root jest aktywny?**

| Miejsce | Zaleta | Wada |
|---|---|---|
| Atrybuty GPT (bity priorytetu, jak ChromeOS) | standardowe, poza systemem plików, bootloader już czyta GPT | zapis GPT z poziomu działającego systemu jest ryzykowny; crate `gpt` jest po stronie hosta, nie Redoksa |
| Plik na ESP | prosty, bootloader już czyta ESP (FAT) | **ESP jest nieszyfrowany i nieuwierzytelniony** — napastnik offline przestawia slot |
| Wewnątrz RedoxFS-a | chroniony przez FDE | bootloader musiałby wybrać root **zanim** zna hasło — kurczę-jajko |

Rekomendacja: **atrybuty GPT**, bo są jedynym miejscem, które bootloader czyta przed
odszyfrowaniem i które nie wymaga od niego montowania niczego. Cena: trzeba dołożyć zapis
GPT po stronie Redoksa, którego dziś nie ma (instalator robi to na hoście). To jest część
kosztu `R-710b` i należy go tam wpisać, a nie odkryć w trakcie.

---

## 5. Współdziałanie z FDE, Secure Bootem i pomiarami

### 5.1 Pełne szyfrowanie dysku

**Znacznik: JEST**, i dla systemu aktualizacji jest to zaskakująco łagodne.

RedoxFS szyfruje AES-XTS-128 kluczem wyprowadzonym z hasła, wdrażane **przy instalacji**
(`docs/encryption.md:7-8`, `:15`). KDF to **Argon2id** w wersji `V0x13` z **domyślnymi,
niekonfigurowalnymi parametrami** (`ParamsBuilder::new()` ustawia wyłącznie `output_len` = 16;
`recipes/core/redoxfs/source/src/key.rs`, odczytane w drzewie budowania — §11 poz. 11).
Bootloader pyta o hasło przy każdym rozruchu.

Dwie rzeczy z tego kodu mają znaczenie dla **restartu po aktualizacji**, więc notuję je tutaj,
a nie tylko w dokumencie o szyfrowaniu:

- Odblokowanie **iteruje po wszystkich 64 slotach klucza** (`src/header.rs:31` deklaruje
  `key_slots: [KeySlot; 64]`, pętla w `:121`), więc **błędne hasło kosztuje 64 wyprowadzenia
  Argon2id**, a poprawne w slocie 0 — jedno. Na maszynie, która wstaje po aktualizacji, literówka
  w haśle to nie sekunda opóźnienia, tylko wielokrotność kosztu KDF.
- W tej pętli stoi `slot.cipher(password).unwrap()` z komentarzem `//TODO: handle errors` —
  **ścieżka paniki przy odblokowaniu**. To jest fakt o stanie obecnym, nie propozycja, i jest
  dokładnie tym, czego nie chce się mieć w komponencie stojącym między aktualizacją a rozruchem.

Konsekwencje dla aktualizacji:

- Demon aktualizacji działa **po** odszyfrowaniu, więc staging, dziennik i kopie zapasowe
  są chronione tak samo jak reszta systemu. **Nic tu nie trzeba robić.**
- **Ale:** aktualizacja bazy stosowana przy restarcie (`R-707`) wykonuje się w bootloaderze,
  czyli po podaniu hasła, ale przed startem systemu. Znaczy to, że **niepilnowany restart
  po aktualizacji jest niemożliwy na maszynie z FDE** — ktoś musi wpisać hasło. Dla serwera
  to jest realne ograniczenie i musi być w `R-712`.
- Nie ma auto-odblokowania i nie ma depozytu klucza — **z założenia**
  (`docs/encryption.md`, „Booting an encrypted E-OS"). Nie proponuję tego zmieniać; proponuję,
  żeby UI aktualizacji **mówił**, że zaplanowana instalacja z restartem zatrzyma się na
  monicie o hasło.

### 5.2 Secure Boot i aktualizacja bootloadera

Aktualizacja bootloadera jest **najniebezpieczniejszą operacją w całym systemie** i zasługuje
na własną ścieżkę.

Fakty (`ADR-0005`, `U-207`, `U-208`, weryfikowane w `recipes/core/bootloader/recipe.toml`):

- `bootloader.efi` i `bootloader-live.efi` są podpisywane **w stage podczas `cook`**, kluczem
  operatora z `build/sb-signing/`, i mają wstrzyknięty SBAT **przed** podpisem (bo podpis
  Authenticode obejmuje cały plik).
- Firmware uruchamia bootloader **wtedy i tylko wtedy**, gdy jest podpisany **i** klucz jest
  zaufany — udowodnione trzema przypadkami, z kontrolą negatywną.
- Instalator składa ESP z paczki `bootloader.pkgar`, czytając `usr/lib/boot/bootloader-live.efi`.

Z tego wynikają trzy reguły dla aktualizacji:

1. **Nowy bootloader musi być podpisany tym samym kluczem, który właściciel wgrał do
   firmware.** Aktualizacja, która dostarczy bootloader podpisany nowym kluczem, zamieni
   działającą maszynę w cegłę na najbliższym restarcie. Klient **musi** przed zapisem na ESP
   sprawdzić, że nowy binarny plik weryfikuje się tym samym certyfikatem co obecny.
   **Jak ta kontrola zawodzi:** system nie ma dziś ani weryfikatora Authenticode, ani miejsca,
   w którym przechowywałby certyfikat właściciela — `mok.crt` żyje w **drzewie budowania**
   (`build/sb-signing/mok.crt`, `scripts/eos-sb-setup-key.sh:41-46`), nie w zainstalowanym
   systemie. Dopóki tak jest, kontrola jest **niewykonalna na urządzeniu**, więc aktualizacja
   bootloadera musi być **domyślnie wyłączona**, a nie „sprawdzana najlepszym staraniem".
   Wpisanie jej do planu bez tego zdania dałoby kontrolę, która potrafi tylko przejść.
2. **Zapis na ESP musi być A/B nawet w wariancie C.** Zapisujemy `BOOT<ARCH>.EOS.NEW`
   (`BOOTAA64` / `BOOTX64`, zależnie od architektury), weryfikujemy, dopiero potem `rename` na
   `BOOT<ARCH>.EFI`, zachowując `BOOT<ARCH>.EFI.PREV`. FAT na ESP nie daje transakcji, ale daje
   `rename`, i to wystarczy dla jednego pliku. Miejsce jest **ciasne, nie luźne**: ESP ma
   1 MiB, a największy zmierzony bootloader to 232 504 B, więc trzy kopie to ~681 KiB **przed**
   narzutem FAT-a (§1.4). Dwie kopie są bezpieczne, trzecia wymaga pomiaru na docelowym ESP,
   zanim ktokolwiek na niej oprze projekt.
3. **Aktualizacja bootloadera jest domyślnie osobną, jawnie potwierdzaną operacją**, nigdy
   częścią „zaktualizuj wszystko". Ryzyko jest jakościowo inne niż przy każdym innym pakiecie.

### 5.3 Podpis jądra i initfs — nierozdzielna para

`V2-MS02`: bootloader weryfikuje **ed25519 nad `SHA-512(role ‖ len_le ‖ data)`** i **odmawia
startu bez podpisu**. Prehasz i tag roli nie są ozdobą: bez tagu poprawnie podpisany initfs
przeszedłby jako jądro, a długość wiąże rozmiar (`U-212`, 8/8 kontroli, w tym 6 negatywnych).
Pliki `.sig` powstają w stage podczas `cook` (`recipes/core/kernel/recipe.toml:16-47`,
`recipes/core/base/recipe.toml:27-33`) i jadą jako wpisy pkgar-a z tego samego stage — dlatego
docierają na każdy nośnik.

Reguła: **`kernel` i `kernel.sig` muszą być stosowane atomowo, jako jedna jednostka.**
Dzisiejsza pętla rename nie daje takiej gwarancji — dwa `rename` w losowej kolejności, między
którymi może zabraknąć prądu, dają jądro bez pasującego podpisu, czyli **maszynę, która się
nie uruchomi**. To jest konkretny scenariusz, w którym dzisiejszy `R-706` nie jest teoretyczny.

W wariancie C rozwiązanie to `pending/` (§4.3): bootloader przenosi **oba** pliki dopiero
po zweryfikowaniu obu. W wariancie A problem znika, bo cały slot jest weryfikowany przed
przełączeniem.

### 5.4 TPM — E-OS go nie ma, i co z tego wynika

**E-OS nie ma TPM.** Nie ma sterownika TPM, nie ma stosu TSS, nie ma PCR-ów, nie ma
zapieczętowania. Dowód **w tym drzewie**, żeby czytelnik mógł go sprawdzić bez dostępu do
materiałów roboczych: `docs/threat-model.md:79` wymienia łańcuch **measured-boot (TPM)** wśród
rzeczy, których **nie ma** (`R-913`), a `docs/encryption.md:99-100` mówi wprost: *„No **TPM /
Secure Boot** binding — the password alone protects the disk"*.
Poza TPM-em brak też FIDO2: `ADR-0010` §3.4 rozstrzyga to jako **NIEREALNE DZIŚ**, bo klucz
byłby potrzebny **w bootloaderze**, przed startem jakiegokolwiek sterownika USB.

Zamówiona „polityka ponownego zapieczętowania po aktualizacji jądra/bootloadera" **nie ma na
tym systemie desygnatu**. Nie da się jej ani zaimplementować, ani sensownie zaprojektować „na
zapas", bo jej kształt zależy od nieistniejących decyzji: która implementacja TPM, które PCR-y,
jaka polityka, jaki fallback przy utracie stanu.

Co z tego wynika **naprawdę**, i co warto zapisać zamiast pustego rozdziału:

1. **Aktualizacja jądra nie ma żadnego skutku kryptograficznego poza samą weryfikacją podpisu.**
   Nie ma pomiaru, który by się zmienił, więc nie ma czego ponownie pieczętować. To upraszcza
   projekt — i dokładnie o tyle osłabia gwarancje.
2. **Nie ma zdalnego poświadczania (remote attestation).** Wdrożenie korporacyjne nie może
   dowieść, że maszyna faktycznie zastosowała aktualizację; może tylko przyjąć jej własny
   raport. To trzeba napisać w §7.4, a nie ukryć.
3. **Ochrona przed cofnięciem nie ma sprzętowej kotwicy.** Zapadka `serial` i przyszły
   `package_serial` leżą w plikach (§3.1, §3.2). Na Linuksie odpowiedzią jest licznik
   monotoniczny TPM; tutaj takiej odpowiedzi nie ma i **nie należy udawać, że jest**.
4. Jeśli TPM kiedyś się pojawi, pierwszą rzeczą, którą warto do niego przenieść, jest właśnie
   ten licznik — nie klucz FDE. Klucz FDE za TPM-em bez PIN-u obniża bezpieczeństwo wobec
   dzisiejszego modelu (hasło przy każdym rozruchu), a licznik za TPM-em je podnosi.

**Znacznik dla całej sekcji zamówienia: NIEREALNE DZIŚ.** Wymaga sterownika TPM (nie ma),
stosu TSS w Ruście na Redoksie (nie ma) i pomiarów rozruchu (nie ma).

### 5.5 SBAT — jedyna istniejąca dziś ścieżka unieważnienia

**Znacznik: JEST** (sam mechanizm) / **DO ZBUDOWANIA** (polityka podbijania generacji).

Warto to odnotować, bo jest to zdolność, którą projekt **ma**, a która w kontekście
aktualizacji łatwo umyka: `recipes/core/bootloader/sbat.csv` (dziś generacja
`eos-bootloader,1`) wstrzykiwany przez `scripts/eos-add-sbat.py` **przed** podpisem
Authenticode (`recipes/core/bootloader/recipe.toml:63-75`, `V2-MS01`/`U-218`) daje E-OS-owi
**własny numer generacji**, który firmware porównuje — czyli własny tor
unieważniania dziurawych bootloaderów, bez czekania na wpis DBX, który może opublikować
tylko Microsoft (`ADR-0006`).

Konsekwencja dla systemu aktualizacji: **podbicie generacji SBAT jest operacją nieodwracalną**.
Po niej firmware odmówi uruchomienia **poprzedniego** bootloadera, czyli wycofanie
bootloadera przestaje działać. Dlatego podbicie SBAT musi być rzadkie, jawne i wykonywane
dopiero po tym, jak nowy bootloader udowodni się w polu — nigdy w tym samym wydaniu, w którym
nowy bootloader debiutuje.

---

## 6. Żywe łatanie jądra

### 6.1 Dlaczego pytanie brzmi tu inaczej

Na Linuksie żywe łatanie (`kpatch`, `kGraft`, `livepatch`) rozwiązuje konkretny problem:
jądro monolityczne ma miliony linii i sterowniki w środku, więc restart jest drogi, a łata
w jądrze bywa pilna. Mechanizm to podmiana funkcji w locie przez `ftrace`, z modelem
spójności opartym na stanie stosów wszystkich wątków.

E-OS ma **mikrojądro**. Sterowniki są w przestrzeni użytkownika — **~16 sterowników** ładowanych
z roota po jego zamontowaniu (`docs/hardening.md:171`), wszystkie poza jądrem. W jądrze zostaje
harmonogram, pamięć, IPC, przerwania.

To zmienia rachunek w obie strony:

- **Powierzchnia, która wymagałaby żywego łatania, jest drastycznie mniejsza.** Większość
  usterek, które na Linuksie są „poprawkami jądra" — sterowniki, stos sieciowy, system plików
  — na E-OS-ie jest **zwykłymi pakietami przestrzeni użytkownika**. `R-F16` (GIC) i `R-F18`
  (INTx) to przykłady prawdziwych usterek jądra; `R-F19`, `R-F21`, `R-F24` to usterki
  userlandu, które na Linuksie byłyby w jądrze.
- **Za to samo jądro jest trudniejsze do łatania na żywo, nie łatwiejsze.** Nie ma `ftrace`,
  nie ma ładowalnych modułów, nie ma infrastruktury do podmiany symboli. Jądro Redoksa jest
  jednym statycznie zlinkowanym obrazem ładowanym przez bootloader.

### 6.2 Klasyfikacja

| Zdolność | Znacznik | Uzasadnienie |
|---|---|---|
| Żywe łatanie jądra w stylu `kpatch`/`livepatch` | **NIEREALNE DZIŚ** | wymaga `ftrace` (nie ma), ładowalnych modułów (nie ma), relokacji symboli w locie (nie ma) i modelu spójności stosów. To nie jest port — to jest nowy podsystem w jądrze, którego koszt jest porównywalny z resztą tego dokumentu razem wziętą, przy powierzchni problemu mniejszej niż na Linuksie. |
| **Restart sterownika bez restartu systemu** | **DO ZBUDOWANIA** | to jest mikrojądrowy odpowiednik żywego łatania — i pokrywa **większość** przypadków, dla których żywe łatanie w ogóle wymyślono |
| Restart usługi systemowej (netstack, `raid1d`, `orbital`) | **DO ZBUDOWANIA** | ta sama maszyneria |
| Aktualizacja aplikacji bez restartu | **JEST** | `pkg` już to robi; problem jest nie w podmianie, tylko w braku transakcji (§4.1) |

### 6.3 Co blokuje odpowiednik mikrojądrowy — i to jest konkret

`init` Redoksa nie jest nadzorcą. W całym drzewie konfiguracji występują **dokładnie dwa**
typy usług:

```
$ grep -rho 'type = "[a-z_]*"' config/*.toml config/*/*.toml | sort | uniq -c
   1 type = "oneshot"
   4 type = "oneshot_async"
```

Nie ma typu `restart`, nie ma polityki restartu, nie ma nadzoru nad procesem po starcie.
`init` uruchamia usługi i o nich zapomina; jedyną relacją między nimi jest `requires_weak`
(`config/aarch64/eos.toml:84` w postaci dyrektywy, `:678` w postaci pola jednostki). Historia z `25_raid1d.service` (`R-601`/`U-080`) pokazuje
nawet, że `init` drenuje usługi **jednowątkowo**, więc jedna usługa potrafiła zablokować
kolejne.

Dlatego „restart sterownika po aktualizacji" wymaga najpierw **nadzorcy**: czegoś, co wie,
że proces żyje, potrafi go zatrzymać, wymienić plik i uruchomić ponownie, a przy niepowodzeniu
przywrócić poprzednią wersję. To jest praca, która **nie ma dziś pozycji w roadmapie** —
najbliższa jest `R-805` (*„`pcid` wiążący na żądanie, bez restartu"*), ale ona dotyczy
**wiązania urządzeń**, a nie cyklu życia procesu sterownika.

### 6.4 Rekomendacja

**Nie budować żywego łatania jądra. Zbudować restart komponentu, i to nie w ramach `R-7xx`.**

Konkretnie:

1. System aktualizacji dzieli pakiety na trzy klasy: `app` (podmiana natychmiastowa),
   `service` (podmiana + restart usługi — **wymaga nadzorcy**), `boot` (jądro, initfs, base,
   relibc, bootloader — wyłącznie przy restarcie, `R-707`).
2. Klasa `service` jest **wyłączona** do czasu, aż nadzorca powstanie. Do tego momentu
   wszystko, co nie jest `app`, idzie ścieżką restartu. To jest bezpieczne i uczciwe.
3. Nadzorca to rozszerzenie `R-805` albo nowa pozycja `R-8xx` — należy do toru sterowników
   i cyklu życia usług, nie do toru aktualizacji. Wpisanie go w `R-7xx` zaciemniłoby, czyja
   to praca.
4. **Pilne poprawki bezpieczeństwa w jądrze wymagają restartu. Kropka.** Trzeba to napisać
   w `R-712` i w UI: „ta aktualizacja wymaga ponownego uruchomienia" nie jest wadą projektu,
   tylko jego świadomą właściwością.

---

## 7. Kanały, wdrożenia etapowe, polityki

### 7.1 Kanały

| Kanał | Co to | Stan |
|---|---|---|
| `stable` | linia wydawnicza (`0.1.x` „Genesis") | **częściowo JEST** — kanał **działa na aarch64**: `50_eos` jest odkomentowane i wskazuje `https://gh0s777tt.github.io/eos-pkg-aarch64/pkg` (`config/aarch64/eos.toml:737-741`, `R-701` 🟡 / `U-209`+`U-210`: 78 pakietów, 893 MB, HTTP 200). Na **x86_64 kanału nie ma** — linia jest zakomentowana (`config/x86_64/eos.toml:767-772`), znalezisko `C-4` |
| `lts` | `lts/0.1`, wyłącznie poprawki bezpieczeństwa | **częściowo JEST** — gałąź i polityka istnieją (`R-1002`, 🟡); **nie ma osobnego adresu kanału**, więc dziś jest to gałąź w gicie, a nie kanał aktualizacji |
| `testing` | kandydaci do wydania | **DO ZBUDOWANIA** |
| `edge` | czubek budowania, wyłącznie na życzenie | **DO ZBUDOWANIA** |

Mechanizm już istnieje i nie wymaga nowego formatu: kanał to **adres URL** w
`/etc/pkg.d/50_eos`, a `pkg-lib` czyta katalog `/etc/pkg.d/`, po jednym adresie na linię,
pomijając linie zaczynające się od `#` (`config/aarch64/eos.toml:721-722`). Zmiana kanału to
przepisanie jednego pliku — operacja klasy „zmiana ustawień konta", więc **z jawnym
potwierdzeniem**.

**Bramka, która tego pilnuje, i którą trzeba rozszerzyć razem z kanałami:** kontrola 9 w
`scripts/ci-integrity.sh` (`U-183`, nauczona rozpoznawania w `U-210`) dopuszcza aktywny adres
zdalny **wyłącznie** wtedy, gdy to host `gh0s777tt.github.io/eos-pkg-` **i** konfiguracja
przypina klucz. Każdy nowy kanał musi przez nią przejść, inaczej wjedzie jako źródło
nieuwierzytelnione. To jest istniejący egzekutor, nie propozycja — i dobrze, żeby projekt
kanałów o niego zahaczył, zamiast wymyślać własny.

Twarde ograniczenie, które trzeba tu wpisać: **`serial` jest per repozytorium, więc każdy kanał
ma własną zapadkę.** Przejście z `edge` na `stable` to przejście na indeks z niższym `serial`,
co zapadka odrzuci. Rozwiązanie: znacznik kanału w `repo-state.toml` i osobna zapadka per kanał.
To jest szczegół, który wyjdzie w implementacji `R-704`, i lepiej go zaprojektować teraz.

### 7.2 Wdrożenia etapowe

**Znacznik: DO ZBUDOWANIA, ale zablokowane przez `R-606`.**

Etapowe wdrożenie („5% maszyn dziś, 25% jutro") wymaga, żeby maszyna umiała stabilnie
odpowiedzieć na pytanie „którym procentem jestem". Dziś **nie umie**: `R-606` mówi wprost, że
hostname jest zapieczony na `eos` dla każdej instalacji, nie ma `machine-id`, a klucze SSH
hosta są niezarządzane.

Kolejność jest więc wymuszona: `R-606` → dopiero potem etapowe wdrożenia. Sam mechanizm jest
prosty i nie wymaga serwera: `bucket = blake3(machine_id ‖ serial) mod 100`, a podpisany indeks
niesie `rollout_percent`. Klient sam decyduje, czy jest w fali. **Zero telemetrii, zero
identyfikacji maszyny po stronie serwera** — to jest właściwość, nie oszczędność.

**Jak to zawodzi:** wydawca nie wie, ile maszyn faktycznie wzięło aktualizację, bo nikt nie
raportuje. Przy poważnej usterce jedyną reakcją jest ustawienie `rollout_percent = 0` w nowym
indeksie i podbicie `serial` — czyli zatrzymanie fali, ale nie cofnięcie tych, którzy już wzięli.
Ci muszą użyć `eos-update rollback` (§4.5) albo dostać poprawkę.

### 7.3 Aktualizacje awaryjne

**Znacznik: DO ZBUDOWANIA.** Jedno pole w podpisanym indeksie plus reguła w demonie; żadnego
nowego kanału zaufania, żadnego nowego klucza.

Aktualizacja awaryjna różni się **wyłącznie polityką**, nigdy weryfikacją. Konkretnie:

- Flaga `severity = "critical"` w podpisanym indeksie, per pakiet.
- Omija okna odroczenia (§7.4), ale **nie** omija żadnej kontroli z §3.6.
- Powiadomienie jest natrętne (modalne, nie toast) — bo dla tego jednego przypadku natrętność
  jest właściwa.
- **Nigdy nie omija zgody użytkownika na restart.** System, który sam się restartuje, straci
  zaufanie szybciej, niż zyska bezpieczeństwo — a na maszynie z FDE i tak nie wstanie bez
  hasła (§5.1).

### 7.4 Polityki korporacyjne

| Polityka | Mechanizm | Znacznik |
|---|---|---|
| Okno odroczenia (odłóż o N dni) | pole w `/etc/eos-update.toml`, egzekwowane przez demona | **DO ZBUDOWANIA** |
| Okno serwisowe (stosuj tylko wt. 02:00–04:00) | jw. | **DO ZBUDOWANIA**, ale **zależne od zegara, którego nie ma** (§8.3) |
| Zamrożenie na konkretnym `serial` | `pin_serial` w konfiguracji; klient odmawia przekroczenia | **DO ZBUDOWANIA** |
| Lustro offline | `/etc/pkg.d/` z adresem wewnętrznym lub ścieżką lokalną | **DO ZBUDOWANIA** — nośnik już jest |
| Raportowanie do centrali | — | **NIEREALNE DZIŚ** — nie ma agenta zarządzania ani kanału zwrotnego, a bez TPM raport i tak byłby niepoświadczalny (§5.4) |
| Wymuszenie polityki, której użytkownik nie zmieni | — | **NIEREALNE DZIŚ** — nie ma piaskownicy ani MAC-a (finding C-5), root zmienia każdy plik konfiguracji |

Ostatni wiersz jest niewygodny i dlatego trzeba go zostawić: **polityka korporacyjna na E-OS
jest dziś konwencją, nie wymuszeniem.** Administrator, który zakłada, że użytkownik z rootem
nie ominie okna serwisowego, zakłada błędnie.

### 7.5 Lustra offline

Ścieżka istnieje i jest już przetestowana z innego powodu: `V2-MS14` wprowadził jawne
zwolnienie dla źródeł **bez zdalnych repozytoriów** — bo `redox_installer` instaluje z
`cookbook/repo`, gdzie `repo.toml.sig` jeszcze nie istnieje. Ten sam mechanizm obsłuży lustro
offline, ale **z odwrotną polityką**: lustro korporacyjne to źródło zdalne w sensie zaufania,
więc **musi** być podpisane i **nie** korzysta ze zwolnienia. Rozróżnienie: zwolnienie dotyczy
źródeł lokalnych *podczas budowania obrazu*, nie ścieżek plikowych w ogóle.

---

## 8. UX i zanik zasilania

### 8.1 Powiadomienia

**Znacznik: częściowo JEST.** `R-D03` — `eos-notifyd` z toastem działa, ale jest odpytywanym
plikiem, bez schematu `notify:`, bez kolejki, bez ikon i akcji. Panel „Ustawienia →
Aktualizacja" (`R-708`) ma gdzie mieszkać: `R-D01` (natywny panel sterowania E-OS Settings)
jest **zbudowany i działa**, 9 paneli wyrenderowanych (`ROADMAP.md`).

Czyli `R-708` nie jest już blokowane brakiem powłoki ustawień — starszy dokument
(`docs/update-system-design.md` §1.4) twierdzi inaczej i jest w tym punkcie **nieaktualny**.

### 8.2 „Zaktualizuj i uruchom ponownie"

Trzy oddzielne, widoczne kroki — bo staging to nie szczegół implementacji, tylko obietnica
składana użytkownikowi:

1. **Pobierz** — postęp z `download_increment` (istnieje), rozmiar, czas, przycisk pauzy.
2. **Zweryfikowano, gotowe do zastosowania** — stan trwały. Użytkownik może tu zostać dowolnie
   długo. To jest stan, w którym nic jeszcze nie dotknęło systemu.
3. **Zastosuj** (i, dla klasy `boot`, **Uruchom ponownie**) — dopiero tutaj coś się zmienia.

Przy klasie `boot` przycisk mówi wprost: **„Zastosuje się przy następnym uruchomieniu"**, a
przy FDE dokładamy zdanie o monicie o hasło (§5.1).

### 8.3 Instalacje zaplanowane — i dlaczego są słabsze, niż wyglądają

**Znacznik: DO ZBUDOWANIA, ale trwale kalekie** — nie z braku kodu, tylko z braku źródła czasu.

**Nie ma źródła zaufanego czasu.** Nie ma klienta NTP, nie ma synchronizacji RTC — zapisane
dwa razy w `docs/reality-ledger.md` (`:127` jako ryzyko `R-704`, `:144` jako luka pokrycia:
*„no RTC-sync or NTP client anywhere (clock is UTC HH:MM, no date)"*). Komentarz przy `expires`
w kodzie mówi to samo: *„a machine with no usable clock loses this half"* (cytat z forka
`eos-pkgutils` w drzewie budowania — §11 poz. 11).

Skutki, które muszą trafić do UI i do `R-712`:

- „Instaluj codziennie o 03:00" jest **najlepszym staraniem**, nie gwarancją.
- Okno serwisowe (§7.4) dziedziczy tę samą słabość.
- Połowa `expires` w ochronie przed zamrożeniem jest niewiarygodna na maszynie ze złym zegarem.

Rekomendacja: zamiast czasu bezwzględnego domyślnie używać **czasu względnego od rozruchu**
(„sprawdzaj 15 minut po starcie i co 24 h pracy"), bo licznik monotoniczny od startu jest
wiarygodny, a zegar ścienny nie. Harmonogram na godzinę oferować, ale z widocznym
zastrzeżeniem.

### 8.4 Raportowanie postępu i porażek

Porażka musi mówić **co się stało, czy system jest zmieniony, i co zrobić** — trzy zdania,
zawsze w tej kolejności:

| Klasa porażki | Komunikat | Stan systemu |
|---|---|---|
| Sieć niedostępna | „Nie udało się połączyć z serwerem aktualizacji." | **niezmieniony** |
| Podpis indeksu nie pasuje | „Odmowa: podpis serwera aktualizacji jest nieprawidłowy." | **niezmieniony** |
| Powtórka (`serial` poniżej zapadki) | „Odmowa: serwer podał starszy zestaw niż ostatnio widziany." | **niezmieniony** |
| Hasz pakietu ≠ hasz z indeksu | „Odmowa: pobrany pakiet nie zgadza się z podpisanym spisem." | **niezmieniony** |
| Commit przerwany | „Aktualizacja przerwana; przywrócono poprzedni stan." | **przywrócony z dziennika** |
| Nowe jądro nie wstało | „Nowa wersja nie uruchomiła się 3 razy; wrócono do poprzedniej." | **cofnięty przez bootloader** |

Pierwsze cztery wiersze mają wspólną, najważniejszą cechę: **system jest niezmieniony**, bo
wszystko dzieje się przed jakąkolwiek mutacją. Ta własność jest jedynym powodem, dla którego
te komunikaty mogą być spokojne.

### 8.5 Zanik zasilania w połowie aktualizacji

To jest pytanie, na które ten dokument istnieje, więc odpowiadam tabelą — osobno dla stanu
dzisiejszego i po `R-706`/`R-707`.

| Faza | **DZIŚ** | **Po `R-706` + `R-707`** |
|---|---|---|
| Pobieranie | pobrane bajty przepadają, system nietknięty | wznowienie od miejsca przerwania (`-C -`), system nietknięty |
| Weryfikacja | nietknięty | nietknięty |
| Kopia zapasowa plików | *nie istnieje* | dziennik `backed_up`, powtórzenie od zera przy starcie |
| **Pętla `rename` (commit)** | **część plików z nowej wersji, część ze starej, zero śladu — nie da się ani dokończyć, ani cofnąć** (`transaction.rs:350`, stan tylko w pamięci) | dziennik zna listę i stan każdego pliku → **dokończenie albo cofnięcie** przy starcie |
| **Zapis bazy pakietów** | **`packages.toml` obcięty albo pusty — system nie wie, co ma zainstalowane** (`package_state.rs:95`, `fs::write` bez `tmp`+`rename`) | `tmp` + `rename` + `fsync` → stara albo nowa wersja, nigdy pół |
| Zapis zapadki antycofkowej | błąd cicho zignorowany (`let _ = fs::write`) | zapis atomowy; porażka = twardy błąd |
| Podmiana jądra | **jądro bez pasującego `.sig` = maszyna, która się nie uruchomi** (§5.3) | jądro i initfs stosowane przez bootloader jako **jedna jednostka**, po weryfikacji obu |
| Pierwszy rozruch na nowym jądrze | brak siatki — zła aktualizacja zostaje na stałe | licznik prób, po 3 porażkach automatyczny powrót do `kernel.prev` |

**Podsumowanie jednym zdaniem:** dzisiaj zanik zasilania w złym momencie potrafi zostawić
maszynę w stanie, z którego nie ma automatycznego wyjścia — a w najgorszym przypadku
niebootowalną. To nie jest ryzyko teoretyczne, tylko bezpośrednia konsekwencja trzech linii
kodu wskazanych powyżej. Dlatego `R-706` jest w tym dokumencie ważniejsze niż `R-710`.

---

## 9. Ścieżka migracji — od `pkg` in-place do tego projektu

Zasada porządkująca: **każdy etap kończy się stanem, który jest lepszy od poprzedniego nawet
jeśli następny nigdy nie powstanie.** Żadnego etapu nie wolno oznaczyć jako zrobiony bez
dowodu w działaniu.

| Etap | Co dostajemy | Pozycje `R-*` | Gdzie dowodliwe | Rozmiar |
|---|---|---|---|---|
| **E0 — przestań tracić dane** | atomowy zapis `packages.toml` i `repo-state.toml` (`tmp`+`rename`+`fsync`); `curl` dostaje `--max-time`, `--connect-timeout`, `-C -`, `--limit-rate` | część `R-706`, część `R-705` | QEMU aarch64 | **S** |
| **E1 — domknij weryfikację** | `package_serial` per pakiet (dziura z §3.2); brak przypiętego klucza = **odmowa**, nie ostrzeżenie; testy e2e decyzji o aktualizacji | **`R-704`**, **`R-709`** | QEMU aarch64 | M |
| **E2 — demon i CLI** | `eos-updated` + `/scheme/eos-update`, maszyna stanów, harmonogram, `eos-update check\|list\|apply\|history` | **`R-705`** (zależy od `R-703`, `R-D03`) | QEMU aarch64 | L |
| **E3 — transakcja z dziennikiem** | dziennik zamiaru, kopie zamienianych plików, odzyskiwanie po zaniku zasilania, `eos-update rollback` | **`R-706`** | QEMU aarch64 + **test przerwania zasilania** | XL |
| **E4 — baza i jądro przy restarcie** | `pending/`, flaga dla bootloadera, licznik prób, automatyczny powrót do `kernel.prev`, atomowa para `kernel`+`kernel.sig` | **`R-707`** | **metal / x86** — bootloader nie jest dowodliwy w pętli GUI pod Mac-QEMU | XL |
| **E5 — panel i dokumentacja** | „Ustawienia → Aktualizacja" w `R-D01`, powiadomienia, historia i wycofanie z GUI; dokumentacja przepływu i modelu zaufania | **`R-708`**, **`R-712`** | QEMU (render) + metal (pełny przebieg) | L + S |
| **E6 — rotacja kluczy** | keyring `/etc/pkg/keys.d/` z `not_before`/`not_after`/`revoked`, objęty podpisem indeksu | **`R-711`** | QEMU aarch64 | M |
| **E7 — różnicowe** | pobieranie zakresami po `Entry.offset`, fallback do pełnego pakietu, bramka czytająca flagę `Packaging` **z nagłówków opublikowanych pakietów** (nie ze zmiennej budowania — §2.3) | **`R-710a`** (rozcięcie `R-710`, §1.5, przyjęte w `ROADMAP.md`) | QEMU aarch64 | M |
| **E8 — sloty A/B** | drugi root, wybór slotu w bootloaderze, wskaźnik w atrybutach GPT, wycofanie jednym restartem | **`R-710b`** + **`R-609`** (partycjonowanie) | **metal** | XL |

Poza tą ścieżką, ale wymagane, żeby cokolwiek z niej miało sens:

- **`R-701`** — kanał aktualizacji na x86_64. Na aarch64 kanał **działa** (`U-209`/`U-210`),
  na x86_64 **nie ma go wcale**: `50_eos` jest zakomentowane (`config/x86_64/eos.toml:767-772`),
  a zdalne `eos-pkg-x86_64` serwuje samo README (`U-223`). To jest znalezisko `C-4`. System
  aktualizacji bez czego aktualizować jest projektem, nie systemem — i dotyczy to **połowy**
  wspieranych architektur, nie całości.
- **`R-303`** — powtarzalność budowania (§3.5).
- **`V2-MS12`** — custody klucza podpisującego pakiety, dziś jawnym tekstem.
- **`R-606`** — tożsamość per maszyna, bez której nie ma etapowych wdrożeń (§7.2).
- **`R-503`** — promocja ML-DSA-65 z advisory na required po stronie klienta (§3.1).

**Kolejność jest wymuszona, nie preferowana:** E1 przed E2 (demon nie może stosować
niedokończonej weryfikacji), E3 przed E4 (nie ma sensu stosować jądra przy restarcie bez
dziennika), E4 przed E8 (sloty bez licznika prób rozruchu to sloty, których nie da się
bezpiecznie przełączyć).

---

## 10. Odrzucone warianty

**Wzięcie ostree albo systemd-sysupdate.** Odrzucone, bo nie istnieją na tym systemie i
portowanie ich to napisanie ich od nowa (§1.2). Wpisanie ich do planu dałoby harmonogram
opisujący pracę, której nikt nie umie wycenić.

**Migawki jako podstawa wycofania.** Odrzucone, bo RedoxFS nie ma prymitywu migawek (§1.3).
**Osobno odrzucam podstawienie pod nie `clone_at` z `src/clone.rs`** — kuszące, bo istnieje i
jest już używane przez fast-clone instalatora, ale to **kopia drzewa plików**, nie tani punkt
w czasie: koszt rośnie z danymi, a nie z metadanymi, więc „migawka przed każdą aktualizacją"
znaczyłaby drugą kopię roota przy każdym `pkg update`. Do tego `clone_at` nosi
`//TODO: handle hard links`. Wariant migawkowy jest tańszy od A/B i wart powrotu, jeśli
prawdziwy prymityw kiedyś powstanie — ale planowanie dziś czegoś, czego nośnik leży w cudzym
repozytorium i nie jest zaplanowany, to planowanie cudzej pracy.

**Sloty A/B jako pierwszy krok.** Odrzucone jako **kolejność**, nie jako cel. A/B wymaga
zmiany instalatora, zmiany bootloadera i trwałego licznika prób rozruchu — trzech rzeczy
naraz, żadnej z nich dziś nie ma. A przede wszystkim: A/B bez dziennika i kontroli zdrowia
daje sloty, których nie da się bezpiecznie przełączyć. Zostaje jako E8/`R-710b`.

**Aktualizacja obrazem blokowym całego roota (`dd` nowej partycji).** Odrzucone, bo E-OS ma
działający, podpisany format pakietowy z weryfikacją na bajtach (`V2-MS13`) i wyrzucenie go
na rzecz obrazów kosztowałoby całą tę warstwę zaufania. Ponadto obraz blokowy uniemożliwia
aktualizacje różnicowe w tanim wariancie z §2.3.

**Delta bajtowa (`bsdiff`/`courgette`).** Odrzucone na rzecz delty per wpis pkgar (§2.3).
Uzasadnienie: delta bajtowa wymaga nowego formatu, nowego narzędzia po stronie wydawcy,
przechowywania każdej pary wersji i **nowej powierzchni weryfikacji** — a delta per wpis
korzysta z haszy, które i tak są już podpisane. Stosunek zysku do ryzyka jest zły.

**Automatyczne stosowanie aktualizacji bezpieczeństwa bez pytania.** Odrzucone, choć jest to
domyślne zachowanie wielu systemów. Powód konkretny, nie ideologiczny: na maszynie z FDE
system i tak nie wstanie bez ręcznego wpisania hasła (§5.1), więc „automatyczne" znaczyłoby
w praktyce „zatrzymane na monicie, bez nadzoru, do następnego przyjścia użytkownika". Domyślnie
pobieranie automatyczne, stosowanie za zgodą.

**Żywe łatanie jądra.** Odrzucone (§6.4): koszt porównywalny z resztą tego dokumentu, przy
powierzchni problemu mniejszej niż na Linuksie, bo sterowniki są w przestrzeni użytkownika.
Właściwą inwestycją jest nadzorca procesów zdolny zrestartować sterownik — i należy ona do
toru `R-8xx`, nie `R-7xx`.

**Zapieczętowanie TPM i zdalne poświadczanie.** Odrzucone, bo E-OS nie ma TPM (§5.4). Nie
projektuję polityki ponownego zapieczętowania dla nieistniejącego układu — jej kształt zależy
od decyzji, których nikt jeszcze nie podjął.

---

## 11. Czego nie udało się zweryfikować

Pozycje oznaczone **[NIEZWERYFIKOWANE]**, z jawnym wskazaniem, co trzeba sprawdzić.

1. **[ZWERYFIKOWANE — korekta poprzedniej wersji tej pozycji] RedoxFS nie ma prymitywu
   migawek.** Poprzednia wersja §11 wpisywała to jako niezweryfikowane, bo opierało się
   wyłącznie na drzewie E-OS. Źródło forka **zostało odczytane** (`recipes/core/redoxfs/source`
   w drzewie budowania, `eos-redoxfs` rev `58824d70`): `src/transaction.rs` używa CoW
   wewnętrznie (233, 474, 1947) bez API użytkownika, a `src/clone.rs` (`clone_at`) to klon
   drzewa plików z `//TODO: handle hard links`, nie tani punkt w czasie. §1.3 poprawione.
   **Co pozostaje ograniczeniem:** odczyt pochodzi z **drzewa budowania**, którego to
   repozytorium nie zawiera i z którym nic go nie synchronizuje (`CLAUDE.md` §20.1), więc
   kontrolę trzeba powtórzyć na świeżym checkoucie tego pina, zanim ktoś oprze na niej wydanie.

2. **[NIEZWERYFIKOWANE] Jaką trwałość daje `fsync` na RedoxFS-ie.** Cały projekt dziennika
   (§4.2) opiera się na założeniu, że `fsync` pliku i katalogu daje trwałość. Nie potwierdziłem
   tego ani w kodzie, ani testem. **Sprawdzić:** semantykę `Fsync` w schemacie `file:` oraz
   test przerwania QEMU w połowie commitu. Bez tego `R-706` nie wolno uznać za zrobione.

3. **[NIEZWERYFIKOWANE] Czy bootloader potrafi cokolwiek zapisać.** Zakładam w §4.3, że nie
   potrafi, i na tym opieram klasyfikację licznika prób rozruchu jako **NOWY PODSYSTEM**.
   Wnioskuję to z opisów (`ADR-0005`, `docs/encryption.md`) — źródło `eos-bootloader` rev
   `87b214b5` nie jest lokalnie dostępne. **Sprawdzić:** czy bootloader ma jakąkolwiek ścieżkę
   zapisu do ESP albo RedoxFS-a, i pod jakim adresem szuka jądra.

4. **[NIEZWERYFIKOWANE] Dokładna ścieżka, spod której bootloader ładuje jądro.** Ustaliłem, że
   receptury składają jądro i initfs pod `usr/lib/boot/` w stage (a więc w RedoxFS-ie), ale nie
   przeczytałem kodu wyszukiwania w bootloaderze. Ma to znaczenie dla §4.3 i §5.3.

5. **[NIEZWERYFIKOWANE] Czy tablica wpisów pkgar ma deterministyczną kolejność.** Ma to
   znaczenie zarówno dla powtarzalności budowania (§3.5), jak i dla stabilności `offset`-ów,
   na których opiera się delta (§2.3). **Sprawdzić:** czy `pkgar::create_with_flags` sortuje
   wpisy, czy bierze je w kolejności obchodzenia katalogu.

6. **[NIEZWERYFIKOWANE] Czy `curl` w obrazie obsługuje `-C -` i `--range`.** Backend odpala
   zewnętrzny `curl` (`curl_backend.rs:28`), więc zdolności zależą od tego, jak zbudowano
   binarkę w obrazie. **Sprawdzić:** `curl --version` w działającym obrazie i faktyczne
   działanie żądania zakresowego.

7. **[NIEZWERYFIKOWANE] Czy serwer kanału (GitHub/GitLab Pages) obsługuje `Range`.** Statyczne
   Pages zwykle obsługuje, ale nie sprawdziłem — a od tego zależy, czy delta z §2.3 działa na
   docelowej infrastrukturze, czy tylko na własnym lustrze.

8. **[NIEZWERYFIKOWANE co do numeracji] Rejestr znalezisk audytu.** Identyfikatory `C-4`
   (brak kanału na x86_64), `C-5` (brak piaskownicy), `C-9` (brak dziennika audytu), `C-11`
   (klucze prywatne na maszynie budującej) cytuję **za briefem**: sam dokument
   `docs/audit/03-security-audit-2026-08-30.md` leży na gałęzi `fix/p0-audit-findings`, a w tym
   drzewie roboczym `docs/audit/` zawiera wyłącznie `AUDIT-2026-07-13.md` i `AUDIT-2026-08-14.md`
   (zakaz poleceń `git`). **Same fakty pod tymi numerami są jednak potwierdzone w drzewie i to
   trzeba oddzielić od numeracji:** `ROADMAP.md` (C-4, C-5, C-9, C-11). Gdyby numeracja w audycie okazała się inna, do poprawienia są
   **etykiety**, nie twierdzenia.

9. **[NIEZWERYFIKOWANE] Czy `eos-notifyd` ma API nadające się do powiadomień o aktualizacji.**
   Wiem z `R-D03`, że działa i pokazuje toast przez odpytywany plik. Nie sprawdziłem, czy da
   się przez niego pokazać powiadomienie z akcją („Uruchom ponownie teraz").

10. **[NIEZWERYFIKOWANE W TYM REPOZYTORIUM] Układ partycji z §1.4.** `installer.rs:565-660`
    odczytano w **drzewie budowania**; tutaj `recipes/core/installer/` zawiera wyłącznie
    `recipe.toml`. Ma to wagę większą niż zwykłe zastrzeżenie, bo na tej tabeli opierają
    własne rozstrzygnięcia `ADR-0007` (§„partycja BIOS boot 1 MiB") i `ADR-0008`
    (`efi_partition_size` = 1 MiB) — trzy dokumenty na jednym nieodtworzonym odczycie.
    **Sprawdzić:** `grep -n "efi_partition_size\|with_whole_disk" <checkout eos-installer>/src`
    oraz rzeczywiste rozmiary partycji w zbudowanym `harddrive.img`.

11. **[NIEZWERYFIKOWANE W TYM REPOZYTORIUM] Wszystkie cytaty z `pkg-lib`, `pkgar` i
    `pkgar-core`.** Dotyczy `curl_backend.rs:28`, `library.rs:141-149`, `package_state.rs:95`,
    `pkgar_backend/mod.rs:145`/`:213`, `package.rs:383`/`:391`, `lib.rs:37`, `manifest_sig.rs`,
    `transaction.rs:350`/`:104-107`, `entry.rs:11`, `header.rs:16`. Żaden z tych plików nie
    istnieje w tym repozytorium — mieszkają w forkach `eos-pkgutils` i `eos-pkgar`, pobieranych
    przez cookbook. Numery linii są więc prawdziwe **wobec konkretnych pinów**
    (`repos.toml`) i zestarzeją się po pierwszym rebase'ie. Cytat, którego czytelnik nie
    sprawdzi, jest twierdzeniem, nie dokumentacją (`CLAUDE.md` §2) — dlatego mówię to tutaj
    raz, zamiast dopisywać do każdego wiersza.

12. **[NIEZWERYFIKOWANE] Flaga `Packaging` pakietów pobranych jako binarki upstreamu.**
    `REPO_BINARY?=1` sprawia, że przepisy spoza 28 pozycji `cookbook.lock` wjeżdżają jako
    gotowe `.pkgar` ze `static.redox-os.org` (§2.3). Nie odczytałem nagłówków tych pakietów,
    więc **nie wiem, ile z 85 opublikowanych pakietów jest nieskompresowanych** — a od tego
    zależy, jaką część kanału pokrywa delta z §2.3. **Sprawdzić:** odczyt flagi `Packaging`
    z nagłówków w `repo/` i policzenie obu klas.

### 11.2 Kolizja numeracji, którą trzeba rozstrzygnąć poza tym dokumentem

`docs/update-system-design.md` (angielski, starszy) używa **innego przypisania `R-70x`** niż
`ROADMAP.md`: w jego tabeli §7 `R-703` to demon, `R-704` to wycofanie, `R-705` to panel GUI,
`R-708` to A/B. W `ROADMAP.md` te same numery znaczą co innego (`R-703`
weryfikacja manifestu, `R-704` anti-rollback, `R-708` panel GUI, `R-710` A/B).

Ten dokument trzyma się numeracji **`ROADMAP.md`** jako obowiązującej. Starszy
dokument ma też co najmniej dwa nieaktualne twierdzenia: że nie ma powłoki ustawień (`R-D01`
jest zbudowane i działa, `ROADMAP.md`) i że domyślne źródło wskazuje na
`static.redox-os.org` (zamknięte w `R-701a`/`U-183`, a od `U-210` aarch64 wskazuje na własne,
podpisane repo).

**Częściowe rozstrzygnięcie już zapadło i trzeba je tu zacytować, żeby nie zgłosić sprawy
drugi raz:** `ROADMAP.md` zapisuje decyzję, że w przestrzeni `R-7xx` **nie mintuje się
żadnego nowego identyfikatora** (`R-701`…`R-712` + `R-701a`) i przyjmuje jako wiążące
rozcięcie `R-710` na `R-710a`/`R-710b`. Ten dokument nie dokłada więc trzeciego znaczenia do
dwuznacznych numerów.

**Co pozostaje otwarte, i to jest praca poza tym plikiem:** sam
`docs/update-system-design.md` nadal używa kolidujących identyfikatorów i nadal nie ma
nagłówka mówiącego, że jest archiwalny. **Rekomendacja bez zmian:** oznaczyć go jako
archiwalny i przekierować tutaj albo przenumerować do zgodności. Dopóki tego nie zrobiono,
**każde zdanie zawierające „`R-704`" w repozytorium jest dwuznaczne** — raz znaczy „wycofanie",
raz „ochrona przed wycofaniem", a to znaczenia niemal przeciwne.
