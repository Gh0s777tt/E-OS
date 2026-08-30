# ADR-0008 — System plików korzenia i układ partycji

- **Status:** Propozycja — do zatwierdzenia. Nic z tego nie jest zaimplementowane.
- **Data:** 2026-08-30
- **Dowód:** `U-162`/`R-F19`, `R-604`, `R-607`, `R-609`/`R-609d`, `R-615`, `R-707`,
  `R-710b`, `docs/architecture.md:82`, `docs/update-system-design.md:104`,
  `scripts/eos-sign-boot-payload.sh:32`, `scripts/eos-boot-verify-proof.sh:13`,
  `config/x86_64/eos.toml`, `config/aarch64/eos.toml`, `mk/config.mk:174`, `mk/fstools.mk:25`,
  `docs/encryption.md`, `docs/architecture/installer.md` §5, §8,
  `docs/architecture/system-updates.md` §1.3–§1.5, §4.6 i §11, `ROADMAP-v2.md:887`, `:921`,
  `:977`
- **Zakres:** system plików korzenia i **układ partycji przy instalacji na goły sprzęt** —
  ESP, root, `/home`, swap, rezerwa pod sloty A/B, nazwy i typy wpisów GPT.
- **Czego ta ADR NIE rozstrzyga:** mechaniki aktualizacji i miejsca wskaźnika aktywnego slotu
  (`ADR-0009`, `docs/architecture/system-updates.md`), strategii Secure Boot (`ADR-0005`,
  `ADR-0006`), architektury kreatora i granicy silnik/frontend (`ADR-0011`,
  `docs/architecture/installer-wizard.md`), **stosu szyfrowania — slotów kluczy, klucza
  odzyskiwania i narzędzia `redoxfs-keys`** (`ADR-0010`). Ta ADR jest **odbiorcą** decyzji
  z `ADR-0010`, nie ich drugim autorem; gdzie potrzebuje pliku klucza (D6), cytuje ją
  zamiast projektować to samo po raz drugi.

## Legenda znaczników

Każda zamówiona zdolność dostaje dokładnie jeden znacznik. Bez tego dokument obiecywałby
instalator linuksowy na systemie, który nie ma ani jednego linuksowego klocka.

| Znacznik | Znaczenie |
|---|---|
| **JEST** | działa dzisiaj — z dowodem: plik:linia, nazwa binarki, pozycja `R-*` |
| **DO ZBUDOWANIA** | wykonalne na Redoksie bez nowego podsystemu |
| **NOWY PODSYSTEM** | wymaga zbudowania czegoś, czego Redox nie ma w ogóle |
| **NIEREALNE DZIŚ** | zależy od ekosystemu, którego nie ma i nie będzie szybko |

`[NIEZWERYFIKOWANE]` oznacza twierdzenie, którego **nie potwierdziłem w drzewie**. Przy każdym
takim znaczniku piszę, co trzeba sprawdzić i gdzie. Źródła forków (`eos-installer`,
`eos-redoxfs`, `eos-bootloader`) **nie są rozwinięte w tym drzewie** — sprawdzone:
`recipes/core/installer/` i `recipes/core/redoxfs/` zawierają wyłącznie `recipe.toml`, a
`build/fstools/` i `build/x86_64/eos/` nie istnieją w tym checkoucie. Twierdzenia o wnętrzu
instalatora i RedoxFS-a pochodzą z briefu, ze specyfikacji w `docs/architecture/` albo
z `ROADMAP-v2.md` — nigdy z odczytu kodu na miejscu.

---

## Kontekst

### K1. Co instalator tworzy dzisiaj — i dlaczego to zamyka drogę

Instalator tworzy **dokładnie trzy** partycje i cały pozostały dysk oddaje jednemu RedoxFS-owi
(`installer.rs:565-660`, za `docs/architecture/system-updates.md` §1.4, weryfikowane tam
w źródle):

| # | Typ GPT | Nazwa | Rozmiar |
|---|---|---|---|
| 1 | `BIOS` | `BIOS` | 1 MiB |
| 2 | `EFI` | `EFI` | **1 MiB** domyślnie (`efi_partition_size`) |
| 3 | `LINUX_FS` | `REDOX` | **cała reszta dysku** |

Pomiar po instalacji potwierdza kształt: **2 tablice GPT**, `BOOTAA64.EFI` na ESP,
**11 sygnatur RedoxFS** na dysku docelowym (`R-F19`/`U-162`).

Z „root do końca dysku" wynikają trzy rzeczy, które są **przedmiotem tej ADR**, a nie
przedmiotem dokumentu o aktualizacjach:

1. **Nie ma miejsca na drugi root.** Sloty A/B nie są zmianą w systemie aktualizacji — są
   zmianą w **układzie partycji**, czyli w instalatorze.
2. **Nie ma osobnego `/home`.** Reinstalacja z zachowaniem danych jest niewykonalna, bo
   `/home` leży wewnątrz roota, a reinstalacja roota to format
   (`docs/architecture/installer.md` §8.2).
3. **Maszyna zainstalowana dziś nigdy nie dostanie slotów bez przepartycjonowania** — a
   przepartycjonowanie bez zmiany rozmiaru RedoxFS-a znaczy: pełna reinstalacja z utratą danych.

Instalator budowania przyjmuje `--skip-partition` (`general.skip_partitions`), który pomija
zapis tablic GPT — istotne tylko dla obrazów, nie dla instalacji na dysk.

### K2. Czym RedoxFS jest, a czym nie jest

| cecha | stan w RedoxFS | dowód | znacznik |
|---|---|---|---|
| copy-on-write **wewnętrzny** | tak | `docs/architecture.md:82`; `src/transaction.rs` (za briefem) | **JEST** |
| migawki / subwoluminy dla użytkownika | **nie** | `docs/update-system-design.md:104`: *„no mature snapshot/subvolume primitive"*; `grep -rni snapshot docs/ recipes/ mk/ scripts/ config/` daje **28 trafień w 14 plikach**, i żadne nie jest prymitywem: propozycje (`docs/feature-proposals.md:51`), plany (`update-system-design.md`, `system-updates.md`) oraz **trafienia bez związku** — aplikacja GNOME Snapshot (`recipes/wip/gnome/snapshot/recipe.toml:3`), adresy tarballi `git.zx2c4.com/*/snapshot/`, komentarze w `mk/fetch-sha256.txt:20`, `scripts/ci-integrity.sh:316`, `scripts/docs-pdf.sh:36` | **NOWY PODSYSTEM** |
| klon drzewa plików (`clone_at`) | tak, używany przez fast-clone instalatora | `src/clone.rs` (za briefem), z `//TODO: handle hard links` | **JEST**, ale to **kopia**, nie tani punkt w czasie |
| sumy kontrolne danych | **seahash** — ani kryptograficzny, ani kluczowany | `scripts/eos-boot-verify-proof.sh:13`, cytowany w `installer.md` §5.3 | **NOWY PODSYSTEM** |
| szyfrowanie natywne AES-XTS-128 | tak, wdrażane przy instalacji | `docs/encryption.md` | **JEST** |
| KDF Argon2id, wyjście 16 B | tak, parametry **domyślne i niekonfigurowalne** | `src/key.rs` (za briefem) | **JEST** / konfigurowalność: **DO ZBUDOWANIA** |
| 64 sloty kluczy w nagłówku | tak — format na dysku już dopuszcza wiele haseł i plik klucza | `src/header.rs:31` (za briefem) | **JEST** (format), narzędzia: **DO ZBUDOWANIA** |
| `fsck` | **brak** — budowane są tylko `redoxfs-mkfs` i demon montujący `redoxfs` | `mk/fstools.mk:25` (buduje z `recipes/core/redoxfs/source`, nie wylicza binarek), `mk/config.mk:174` (`REDOXFS_MKFS=$(FSTOOLS)/bin/redoxfs-mkfs`); **pomiar** w `installer.md` §8.1: `build/fstools/bin/` ma te dwie i nic więcej | **NOWY PODSYSTEM**, pozycja `R-615` |
| zmiana rozmiaru online | `[NIEZWERYFIKOWANE]` | — | — |
| send/receive, kompresja | `[NIEZWERYFIKOWANE]` | — | — |

Dwie z tych pozycji rozstrzygają całą tę ADR: **brak migawek** i **brak zmiany rozmiaru**.

### K3. Dlaczego wybór systemu plików determinuje A/B

Wycofanie aktualizacji ma na świecie dwie tanie realizacje: **migawka systemu plików**
(btrfs/ZFS + `snapper`) albo **dwa sloty roota** (Mender, RAUC, ChromeOS).
`docs/architecture/system-updates.md` §1.1 zestawia je jako warianty B i A.

Wariant B odpada nie dlatego, że jest gorszy, tylko dlatego, że **nie ma na czym go oprzeć**:
prymitywu migawek w RedoxFS nie ma, a subwoluminów nie ma, więc bootloaderowi nie ma czego
wskazać jako „inny root" (`system-updates.md` §1.3). Zostaje wariant A — a wariant A to
**dwa woluminy RedoxFS**, czyli **dwie partycje**. Dlatego pytanie „na czym oprzeć wycofanie"
jest w tym projekcie pytaniem o **układ dysku przy instalacji**, i musi być rozstrzygnięte
tutaj, zanim ktokolwiek zainstaluje E-OS na trwałe.

Krótko: **na Redoksie nie da się zdecydować o aktualizacjach po instalacji.** Geometria
zapadła w chwili zapisu GPT.

### K4. Rozmiar bloku — kontrola, która nie może zawieść

Cała arytmetyka układu zależy od jednej liczby, której instalator **nie odczytuje**:

- `src/disk_wrapper.rs:28` → `let block_size = 512;` z komentarzem
  `// TODO: get real block size: disk_metadata.blksize() works on disks but not image files`
- `src/installer.rs:604` → `match block_size { 512 => Lb512, _ => bail!("block size … not supported") }`

Skoro `block_size` jest stałą, gałąź `_ => bail!` jest **martwym kodem**. Na dysku 4Kn
instalator nie odmówi — policzy geometrię GPT na złym rozmiarze sektora. To jest `R-607`
i podręcznikowy przykład zasady tego projektu: *kontrola, która nie może zawieść, nie jest
kontrolą*. **Każda liczba w §D4 jest warunkowa wobec naprawy `R-607`.**

### K5. Swapu nie ma nigdzie

Przeszukanie źródeł instalatora i `config/*.toml` nie znajduje żadnego wsparcia dla swapu
(za briefem; jedyne trafienie to niezwiązany komentarz o „path swap"). Nie znalazłem też
w `ROADMAP-v2.md` pozycji `R-*` dla wymiany stron. Pytanie „czy robimy partycję swap" jest
więc dziś pytaniem do **jądra**, nie do instalatora.

### K6. Dwie istniejące specyfikacje przeczą sobie w arytmetyce

To trzeba nazwać, bo ta ADR to naprawia:

- `docs/architecture/installer.md` §5.2: `EOS-ROOT` = **„reszta minus `/home`"**.
- `docs/architecture/installer.md` §5.3: przy dyskach ≥ 256 GiB zostaw **nieprzydzielony ogon
  równy rozmiarowi roota**.

Obie reguły naraz nie mogą być prawdziwe: jeśli root jest „resztą", to ogon równy rootowi
zajmuje połowę dysku i root przestaje być resztą. Rozstrzygnięcie poniżej **ogranicza root
liczbowo**, przez co ogon staje się tani i dobrze zdefiniowany.

---

## Decyzja

### D1. Root to RedoxFS. Jedyny wariant. **JEST**

`ext4`, `btrfs`, `ZFS`, `XFS` nie istnieją na Redoksie **ani jako root, ani jako cel montowania,
ani nawet do odczytu**. W drzewie jest jeden sterownik obcego systemu plików: `redox-fatfs`
(FAT, dla ESP). To nie jest wybór projektowy — to stan drzewa. Uczciwe omówienie, co dokładnie
tracimy, jest w „Odrzucone warianty".

### D2. Tablica partycji: GPT zawsze, MBR wyłącznie ochronny. **JEST**

Stan faktyczny (`U-162`: dwie tablice GPT na dysku docelowym). Wyrównanie **1 MiB** dla każdej
partycji — wybrane dlatego, że 1 MiB jest wielokrotnością zarówno 512 B, jak i 4096 B, więc
układ przeżyje naprawę `R-607` bez zmiany liczb. Zmieni się wtedy **arytmetyka LBA**, nie
granice partycji.

### D3. Rozmiar bloku jest odpytywany, nie zakładany. **DO ZBUDOWANIA** (`R-607`)

Warunek wstępny wszystkiego poniżej. `DiskWrapper::open` ma zwrócić rzeczywisty rozmiar sektora
urządzenia; przy wartości innej niż 512 lub 4096 instalator **odmawia przed jakimkolwiek
zapisem**.

**Jak ta kontrola może zawieść:** dokładnie tak jak dziś — przez to, że nigdy się nie odpali.
Dlatego przyjęcie `R-607` wymaga testu, który ją **wywoła**: dysk 4Kn w QEMU
(`-device nvme,logical_block_size=4096` `[NIEZWERYFIKOWANE]` co do składni w wersji QEMU
używanej przez harness) i oczekiwany wynik = odmowa albo poprawna geometria, nigdy zapis
policzony na 512.

### D4. Układ kanoniczny — cztery pozycje i jedna rezerwa. **DO ZBUDOWANIA**

| # | nazwa | typ | zawartość | obecność |
|---|---|---|---|---|
| 1 | `EOS-ESP` | EFI System (FAT) | bootloader, dziennik instalacji, staging `R-707` | zawsze |
| 2 | `EOS-BIOSBOOT` | `21686148-6449-6E6F-744E-656564454649` | — | tylko x86_64 przy rozruchu legacy |
| 3 | `EOS-ROOT-A` | RedoxFS | system, jądro i initfs (`/usr/lib/boot/`), staging aktualizacji | zawsze |
| 4 | `EOS-HOME` | RedoxFS | dane użytkowników | od 64 GiB w górę |
| — | *(ogon nieprzydzielony)* | — | rezerwa pod `EOS-ROOT-B` | od 128 GiB w górę |

Rozmiary, klasami dysku. `D` = rozmiar dysku zgłoszony przez urządzenie:

| klasa `D` | `EOS-ESP` | `EOS-BIOSBOOT` | `EOS-ROOT-A` | ogon | `EOS-HOME` |
|---|---|---|---|---|---|
| `D` < 9 GiB | — | — | — | — | **odmowa instalacji** |
| 9 GiB ≤ `D` < 64 GiB | 512 MiB | 1 MiB | reszta (≥ 8 GiB) | 0 | brak |
| 64 GiB ≤ `D` < 128 GiB | 512 MiB | 1 MiB | **24 GiB** | 0 (opcja użytkownika) | reszta |
| `D` ≥ 128 GiB | 512 MiB | 1 MiB | **24 GiB** | **24 GiB** | reszta |

Skąd te liczby — każda z rachunku, nie z upodobania:

- **Minimalny root 8 GiB.** Ładunek systemu to `filesystem_size = 1400` MiB dla obu architektur
  (`config/x86_64/eos.toml`, `config/aarch64/eos.toml`) ≈ 1,37 GiB. Staging pokoleniowy
  aktualizacji trzyma kopię zamienianych plików per pokolenie
  (`docs/update-system-design.md` §4.2 → `/var/lib/eos-update/rollback/<index>/`), więc trzy
  zachowane pokolenia to do ~4 GiB. Plus pamięć podręczna pkgar. 8 GiB to **minimum bez
  zapasu**, a nie rozmiar komfortowy.
- **Root docelowy 24 GiB** ≈ 17× ładunek. Mieści system, kilka pokoleń wycofania, cache i
  lokalnie doinstalowane pakiety. Powyżej tego dane należą do `/home`.
- **Odmowa poniżej 9 GiB**: 8 GiB roota + 512 MiB ESP + 1 MiB + wyrównania.
- **ESP 512 MiB** — uzasadnienie osobno w D5.

Użytkownik może **każdą** z tych liczb nadpisać w trybie ręcznym (`R-609`) i w pliku
odpowiedzi (`docs/architecture/installer-wizard.md` §13.2, sekcja `[setup]`). Tabela jest
**domyślną**, nie ograniczeniem.

**Zmiana wobec istniejących specyfikacji, świadoma i do naniesienia tam:**
`installer.md` §5.2 mówi „root = reszta minus `/home`", §5.3 stawia próg ogona na 256 GiB,
a §8.2 proponuje osobne `/home` dopiero od 256 GiB. Ponieważ ta ADR **ogranicza root do
24 GiB**, ogon przestaje kosztować połowę dysku (na 128 GiB to 18,8 %), więc próg schodzi do
128 GiB, a osobne `/home` staje się domyślne od 64 GiB.

Razem z D5 (błędna liczba `0x2f600`) i D7 (ogon przypisany jednemu odbiorcy, nie „swap albo
A/B") daje to **pięć poprawek do naniesienia w `installer.md`** — wyliczone w tabeli długu.
ADR jest tu nadrzędna, bo rozstrzyga sprzeczność opisaną w K6. Czego natomiast **nie** zmienia:
ESP 512 MiB, które §5.2 ustala już dziś i które ta ADR wyłącznie potwierdza (D5).

### D5. ESP ma 512 MiB, nie 1 MiB. **DO ZBUDOWANIA**

**To nie jest nowa decyzja i nie udaję, że jest.** `installer.md` §5.2 już stawia ESP na
**512 MiB**, z tym samym powodem (staging `R-707`, initfs ~21 MiB). Ta ADR ją potwierdza,
dokłada powód 3 (nieodwracalność) i wiąże ją z `R-607`.

Dziś `efi_partition_size` daje **1 MiB** (`system-updates.md` §1.4). Bootloader zapisany na ESP
ma `0x2f600` = **194 048 B ≈ 189,5 KiB** (`R-F19`/`U-162`, pomiar na `BOOTAA64.EFI`), więc dwie
kopie **się mieszczą** — i na tym kończy się, co się mieści.

> **Korekta liczby, którą ta ADR wcześniej powtarzała za `installer.md`.** Wcześniejsza wersja
> tego akapitu podawała 193 536 B. To jest błędne przeliczenie `0x2f600` (193 536 = `0x2f400`).
> `installer.md` §5.2 niesie **ten sam błąd** i wymaga poprawki; `system-updates.md` §1.4 ma
> poprawnie („~194 KiB"). Na wniosek to nie wpływa — 1 MiB nie wystarcza tak samo przy obu
> liczbach — ale zła liczba w dokumencie, który każe ufać liczbom, kosztuje więcej niż waży.

Powody podniesienia:

1. **`R-707` (stosowanie przy restarcie) będzie stagingować jądro i initfs.** Initfs to
   ~21 MiB — liczba nie z szacunku, tylko z komentarza w
   `scripts/eos-sign-boot-payload.sh:32` („second 21 MiB copy of the initfs"). Na 1 MiB to
   się nie zmieści nigdy.
2. **Dziennik instalacji mieszka na ESP** (`installer.md` §6.3), bo to jedyna partycja
   czytelna z zewnątrz, gdy RedoxFS jeszcze nie powstał.
3. **ESP-u nie da się powiększyć po fakcie**, bo za nim leży root, a RedoxFS-a nie umiemy
   przesunąć ani zmniejszyć. Błąd jest jednokierunkowy: za duży ESP kosztuje 512 MiB, za mały
   kosztuje reinstalację.
4. **1 MiB nie może być FAT32** (FAT32 wymaga ≥ 65525 klastrów; przy 512 B/klaster to
   31,99 MiB), więc dzisiejszy ESP jest FAT12 albo FAT16. `installer.md` §5.2 wpisuje docelowo
   **FAT32** — a to jest osiągalne dopiero powyżej ~32 MiB, czyli jest to czwarty powód
   podniesienia, nie osobna sprawa. `[NIEZWERYFIKOWANE]`, jaki wariant FAT wybiera instalator
   i czy każde firmware przyjmuje dzisiejszy. **To nie jest `redox-fatfs`:** ten crate
   (`recipes/libs/redox-fatfs/recipe.toml`, rev `26caa090`) jest sterownikiem
   **uruchomieniowym** Redoksa, a instalator budowania jest narzędziem **hosta**, budowanym
   `cargo install --path recipes/core/installer/source` (`mk/fstools.mk:24`).
   **Sprawdzić:** ścieżkę formatowania ESP w `eos-installer` rev `c8d32ad3`
   (`recipes/core/installer/recipe.toml`) i odczyt ESP na fizycznym UEFI z macierzy `R-607`.

### D6. Osobny `/home` jest domyślny od 64 GiB. **DO ZBUDOWANIA**

Nie jest to preferencja estetyczna. To **jedyna droga** do reinstalacji z zachowaniem danych,
bo alternatywa — selektywne kasowanie plików poza `/home` w żywym systemie plików — nie ma
migawek, którymi dałoby się ją cofnąć, a jej przerwanie zostawia wolumin w stanie
nienazwanym (`installer.md` §8.2).

Trzy konsekwencje, które trzeba wziąć razem z decyzją:

- **FDE: dwa woluminy to dwa odblokowania.** Root odblokowuje bootloader hasłem. `/home` jest
  osobnym woluminem RedoxFS z **własnym nagłówkiem i własnymi 64 slotami kluczy**.
  Rozwiązanie: **plik klucza dla `/home` zapisany w roocie**, wpięty w jeden ze slotów — format
  na dysku już to dopuszcza (`src/header.rs:31`, za briefem), brakuje wyłącznie narzędzia.
  **Znacznik: DO ZBUDOWANIA**, nie NOWY PODSYSTEM.
  **Narzędzia tu nie projektuję i nie zakładam dla niego drugiej pozycji:** `ADR-0010`
  §„Etap 2" ma już `redoxfs-keys` (wypisz sloty, dodaj hasło, **dodaj plik klucza**) razem
  z warunkiem odbioru, którego nie powtarzam własnymi słowami — „slot niepusty" nie jest
  dowodem, że da się wejść; dowodem jest udane wyprowadzenie klucza. Ta ADR jest
  **odbiorcą** tego narzędzia, nie jego drugim właścicielem.
  Zakres poprawy modelu zaufania, nazwany dokładnie: wobec napastnika **offline** (skradziony
  dysk) nic się nie pogarsza — klucz do `/home` leży w woluminie chronionym tym samym hasłem.
  Wobec napastnika, który przejął **działający, odblokowany** root, pogarsza się wprost: plik
  klucza jest wtedy do odczytania, więc `/home` **nie jest** osobną domeną zaufania i nie wolno
  go tak sprzedawać. `ADR-0010` mówi to samo o plikach klucza w ogóle — plik klucza zawsze
  dostępny nie jest drugim czynnikiem.
- **`[NIEZWERYFIKOWANE]`: czy E-OS ma w ogóle mechanizm montowania drugiego woluminu przy
  starcie.** Przeszukałem `config/*.toml` i `config/*/*.toml` — nie ma nic w rodzaju `fstab`
  ani listy montowań. **Sprawdzić:** `init` i `/etc/init.d/` w `eos-base` (źródło nie jest
  rozwinięte w tym drzewie). Jeśli takiego mechanizmu nie ma, `/home` na osobnej partycji
  przesuwa się z **DO ZBUDOWANIA** na **DO ZBUDOWANIA + jedna pozycja w `eos-base`**, i to
  trzeba wpisać do `R-609`, a nie odkryć w trakcie.
- **Podwaja liczbę woluminów bez `fsck`.** To jest realny koszt, nie formalność: dwa woluminy
  to dwa miejsca, w których uszkodzenie po zaniku zasilania nie ma innej odpowiedzi niż
  reinstalacja. Decyzja pozostaje, bo zachowanie `/home` przy reinstalacji jest warte więcej
  niż jednolitość — ale brak `fsck` dla RedoxFS pozostaje **najpoważniejszym brakiem** całego
  tego obszaru.
  **Korekta:** wcześniejsza wersja tego akapitu powtarzała za `installer.md` §8.1, że nie ma
  na to pozycji `R-*` i że jest to „luka także w roadmapie". **To jest już nieaktualne** —
  roadmapa tę lukę zamknęła w reakcji na tamto zdanie: `ROADMAP-v2.md:887` i `:950` zakładają
  **`R-615`** („`fsck` dla RedoxFS", **NOWY PODSYSTEM**, `[P2·XL·🖥️]`, 🔴). Ta ADR nie zakłada
  nowej pozycji i nie nadaje tej pracy drugiej nazwy; osobne `/home` **podnosi wagę `R-615`**,
  bo mnoży liczbę woluminów, których nie ma czym sprawdzić.

### D7. Bez partycji swap. **NOWY PODSYSTEM**

Nie tworzymy partycji, której nic w systemie nie potrafi użyć. Instalator zamiast tego podaje
**wymóg RAM: 4 GiB** dla nośnika (`installer.md` §4.1: `filesystem_size = 1400`,
`EOS_SMOKE_MEM=4096`).

`[NIEZWERYFIKOWANE]`, **czy jądro Redoksa ma jakąkolwiek wymianę stron.** **Sprawdzić:**
podsystem pamięci w `eos-kernel`. Jeżeli ma, tę decyzję trzeba zrewidować — ale nawet wtedy
kolejność jest: najpierw jądro, potem instalator.

Ważne przy tym, i lepiej powiedzieć to teraz: **ogon rezerwowy z D4 nie jest rezerwą na swap.**
Jest przypisany do `EOS-ROOT-B`. Gdyby swap kiedyś powstał, konkuruje o tę samą przestrzeń —
bo `/home` zajmuje resztę dysku i nie umiemy go zmniejszyć.

To jest **czwarta świadoma zmiana wobec `installer.md`**, i trzeba ją nazwać, bo inaczej dwa
dokumenty projektu mówią co innego o tym samym obszarze dysku: §5.2 pisze, że ogon zostaje
nieprzydzielony, „żeby przyszły swap **albo** drugi slot A/B miał gdzie powstać". Rezerwa
zapisana dwóm odbiorcom naraz nie jest rezerwą dla żadnego — pierwszy, który po nią sięgnie,
unieważnia drugiego, i to bez żadnego komunikatu. Ta ADR przypisuje ogon **jednemu** odbiorcy
(`EOS-ROOT-B`); `installer.md` §5.2 wymaga w tym miejscu poprawki.

### D8. Projektujemy pod **pojedynczy root teraz**, z geometrią przygotowaną pod A/B. **NOWY PODSYSTEM** dla samego A/B

To jest rozstrzygnięcie zamówionego pytania i brzmi ono: **nie budujemy slotów A/B teraz, ale
zostawiamy im miejsce — jako obszar nieprzydzielony, nie jako drugą partycję.**

Uzasadnienie po kolei:

- **Dlaczego nie A/B od razu.** A/B wymaga trzech rzeczy naraz, z których żadna nie istnieje:
  drugiego roota (ta ADR), wyboru slotu w bootloaderze (`eos-bootloader`) i **trwałego licznika
  prób rozruchu zapisywanego przez bootloader** — a dziś bootloader niczego nie zapisuje.
  To ostatnie jest **założeniem, nie pomiarem**, i tak je traktuję: `system-updates.md` §11
  poz. 3 zakłada dokładnie to samo i z tego samego powodu — źródło `eos-bootloader`
  rev `87b214b5` nie jest rozwinięte w tym drzewie. `[NIEZWERYFIKOWANE]`. To jest `R-710`
  i słusznie stoi na 💡 z zależnością od `R-707`. Zbudowanie slotów bez dziennika i kontroli
  zdrowia dałoby sloty, których nikt nie umie bezpiecznie przełączyć.
- **Dlaczego jednak rezerwa.** Bo tej decyzji nie da się odłożyć: geometria zapada przy
  instalacji, a zmiany rozmiaru RedoxFS-a nie mamy. Rezerwa kosztuje 24 GiB na dysku ≥ 128 GiB
  i oszczędza pełną reinstalację.
- **Dlaczego obszar nieprzydzielony, a nie gotowa pusta partycja `EOS-ROOT-B`.** Trzy powody:
  1. **Druga sygnatura RedoxFS na dysku może zdezorientować wykrywanie roota.** To nie jest
     czysta niewiadoma i nie warto jej tak zostawiać: `docs/encryption.md` opisuje w
     bootloaderze **skan partycji**, który przy zaszyfrowanym roocie połykał `ENOKEY`,
     logował go jako *„BlockIo error: Required key not available"* i **pomijał urządzenie**
     (naprawione w `eos-bootloader@083d9fae`). Bootloader **przechodzi więc po urządzeniach
     i próbuje otworzyć RedoxFS**, a nie odczytuje wskazania z wpisu GPT. `U-162` mierzy do
     tego **11 sygnatur RedoxFS** na jednym dysku.
     Czego nadal nie wiem — i to jest sedno: czy skan filtruje po typie albo nazwie wpisu
     i co robi, gdy kandydatów jest **dwóch**. `[NIEZWERYFIKOWANE]`. **Sprawdzić:** ścieżkę
     wyszukiwania w `eos-bootloader` rev `87b214b5`. Dopóki to jest niewiadome, tworzenie
     drugiego woluminu RedoxFS jest ryzykiem rozruchowym bez żadnej dzisiejszej korzyści.
  2. Pusta partycja to **trwała strata 24 GiB**, jeśli `R-710b` nigdy nie powstanie. Obszar
     nieprzydzielony można oddać użytkownikowi jednym poleceniem.
  3. Dołożenie wpisu GPT w wolnym ogonie **nie przesuwa niczego** — ani ESP, ani roota, ani
     `/home`. To jest cała treść „przygotowania".
- **Migracja.** Maszyna zainstalowana **pod tą ADR** dostaje sloty przez: utworzenie
  `EOS-ROOT-B` w ogonie, zapis nowego roota, przełączenie wskaźnika. Bez ruszania danych.
  Maszyna zainstalowana **dziś** (root do końca dysku, brak `/home`) nie dostaje slotów
  w żaden sposób poza pełną reinstalacją z utratą danych. Trzeba to powiedzieć wprost, a nie
  odkryć przy pierwszym wydaniu A/B: **instalacje sprzed tej ADR są ślepą uliczką dla `R-710b`.**

### D9. Nazwy i typy wpisów GPT. **DO ZBUDOWANIA**

- **Nazwy** (`EOS-ESP`, `EOS-BIOSBOOT`, `EOS-ROOT-A`, `EOS-HOME`, później `EOS-ROOT-B`)
  zastępują dzisiejsze `BIOS` / `EFI` / `REDOX`. Nazwa jest darmowa, pisana i tak, i jest
  identyfikatorem czytelnym przez obce narzędzia — co ma znaczenie przy dual-boocie i przy
  `R-604` (identyfikacja celu przed skasowaniem).
- **Typ GUID dla woluminów RedoxFS pozostaje bez zmian** — dziś `LINUX_FS`. Zmiana na własny
  GUID kupiłaby niewiele (Linux i tak nie zamontuje RedoxFS-a, bo nie ma sterownika), a
  kosztowałaby zmianę w instalatorze **i** ryzyko regresji rozruchu, dopóki nie wiadomo, po
  czym bootloader szuka roota (D8, punkt 1). **Rewizja po odczytaniu `eos-bootloader`.**
  Cena decyzji, nazwana: linuksowe narzędzia partycjonujące pokażą naszą partycję jako
  „Linux filesystem" i mogą zaproponować jej użycie.
- **Bity atrybutów GPT 48–63 zostają zarezerwowane** pod priorytet slotu (model ChromeOS).
  To jest przygotowanie dla `ADR-0009` / `system-updates.md` §4.6, który rekomenduje atrybuty
  GPT jako miejsce wskaźnika aktywnego slotu — bo to jedyne miejsce, które bootloader czyta
  **przed** odszyfrowaniem i bez montowania czegokolwiek. Ta ADR **nie** rozstrzyga wskaźnika;
  zapewnia tylko, że układ go nie wyklucza.

---

## Odrzucone warianty

### 1. btrfs jako root

**Co by dało — uczciwie, bo to dużo.** Tanie i atomowe migawki, więc wycofanie aktualizacji
przez podmianę subwoluminu zamiast slotów A/B (wariant B z `system-updates.md` §1.1, tańszy
od A, bo **nie podwaja miejsca**). Subwoluminy `@` i `@home` w jednej puli, więc **cała
arytmetyka z D4 i D6 przestałaby być potrzebna** — nie trzeba dzielić dysku, bo root i `/home`
dzielą wolne miejsce. Do tego sumy kontrolne danych, kompresja, zmiana rozmiaru online,
`send/receive` do kopii zapasowych.

**Dlaczego go tu nie ma.** To nie jest jeden brakujący klocek, tylko cztery:

1. Nie ma **żadnego** sterownika btrfs — nawet do odczytu.
2. Bootloader musiałby umieć czytać btrfs **i wybierać subwolumin**, a bootloader jest
   najkruchszym elementem tego systemu. Dowód, bez przymiotników: `R-F10` (✅ zamknięte
   w `U-156`) zastało go rozwiązującego `redoxfs = "0.8"` **z crates.io, bez
   `[patch.crates-io]`**, podczas gdy obraz niósł fork `eos-redoxfs` — czyli kod, który
   odblokowuje root przy starcie, był innym kodem niż ten, który ten root tworzy i nim
   zarządza, a żadna bramka tego nie widziała. Wcześniejsza wersja tego zdania dopisywała
   „latami"; nie ma na to liczby w rejestrze, więc jej tu nie ma.
3. FDE w E-OS jest **wewnątrz** RedoxFS-a. btrfs nie ma natywnego szyfrowania, więc trzeba by
   pod niego dołożyć warstwę typu dm-crypt — której też nie ma i która jest osobnym
   podsystemem jądra.
4. Implementacja btrfs z zapisem to praca wieloletnia zespołu wyspecjalizowanego; formatu
   nie da się „podejrzeć i dopisać".

**Znacznik: NIEREALNE DZIŚ.** I to jest kosztowne odrzucenie, nie oczywiste: gdyby btrfs był,
`ADR-0009` byłaby o połowę krótsza, a ta ADR w ogóle by nie musiała rozstrzygać podziału dysku.

### 2. ZFS jako root

**Co by dało.** Wszystko, co btrfs, plus rzeczy, których btrfs nie ma na tym poziomie
dojrzałości: sumy kontrolne **kryptograficznej klasy** (fletcher4/SHA-256) zamiast naszego
**seahasha, który nie jest ani kryptograficzny, ani kluczowany**; szyfrowanie natywne per
zbiór danych; klony i `send/receive`; RAID-Z jako odpowiedź na `R-912` bez pisania własnej
parzystości.

**Dlaczego go tu nie ma.** OpenZFS to setki tysięcy linii C napisanych pod VFS Solarisa,
z warstwą zgodności (SPL) i własnym zarządcą pamięci (ARC), który zakłada, że jest w jądrze
monolitycznym i widzi globalny stan pamięci. W mikrojądrze serwer systemu plików żyje
w przestrzeni użytkownika — ARC musiałby zostać przepisany, nie przeniesiony. Portu w Ruście
z zapisem nie ma. Licencja (CDDL) akurat **nie** jest tu przeszkodą — E-OS nie jest GPL —
i warto to powiedzieć, żeby nikt nie odrzucał ZFS-a z niewłaściwego powodu. Przeszkodą jest
koszt portu i model pamięci.

**Znacznik: NIEREALNE DZIŚ.** Co z tego zostaje jako dług: **problem seahasha nie znika przez
odrzucenie ZFS-a.** Uszkodzenie danych na roocie jest dziś przez system plików niewykrywalne,
a jedyne, co mamy obok, to blake3 pkgar przy instalacji pakietu, podpis ed25519 nad jądrem
i initfs (`V2-MS02`) oraz monitor integralności `eos-guard` (blake3, `[packages.eos-control]`
w `config/x86_64/eos.toml`) — **JEST**, ale to kontrola po fakcie, nie ochrona ścieżki odczytu.
Silne sumy w RedoxFS pozostają **NOWYM PODSYSTEMEM**.

### 3. ext4 albo XFS jako root

Odrzucone dwukrotnie. Po pierwsze — nie istnieją, jak reszta. Po drugie, i to jest ważniejsze:
**nawet gdyby istniały, nic by tu nie zmieniły**, bo żaden z nich nie ma migawek, więc wariant
B nadal by odpadał i nadal trzeba by robić A/B partycyjne. Jedyne, co by dały, to znajomość
narzędzi i `fsck` — a `fsck` możemy dostać taniej, pisząc go dla RedoxFS-a.
**NIEREALNE DZIŚ**, i bez żalu.

### 4. LVM z cienkimi migawkami pod RedoxFS-em

Migawka poniżej systemu plików rozwiązałaby wycofanie bez zmiany RedoxFS-a. Odrzucone: nie ma
warstwy device-mapper ani niczego, co by nią było, a napisanie jej to nowy podsystem jądra
o zasięgu porównywalnym z całą resztą tego dokumentu. **NIEREALNE DZIŚ.**

### 5. `raid1d` jako „A/B dla ubogich"

Kuszące, bo `raid1d` **jest** w obrazie — RAID-1 w przestrzeni użytkownika, z trybem
zdegradowanym i resyncem (`ROADMAP-v2` §3.1). `docs/update-system-design.md:105` wprost nazywa
go *„poor-man's A/B substrate"* i **od razu zastrzega**, że nie jest zaprojektowany jako
mechanizm wycofania.

Odrzucone jako podstawa A/B, z trzech powodów: rozerwanie lustra, żeby dostać dwa roothy,
**niszczy redundancję** — czyli zamienia jedną własność na drugą, zamiast dodać; `raid1d`
nie ma semantyki wyboru slotu przy rozruchu; a przede wszystkim **instalator nie umie dziś
instalować na `raid1d` w ogóle** (`installer.md` §5.5).

Instalacja na `raid1d` zostaje jako osobna, sensowna funkcja — **DO ZBUDOWANIA**, `R-912` /
`V2-D04` — ale nie jako odpowiedź na aktualizacje.

*(Uwaga historyczna, bo oszczędza czyjś tydzień: teoria, że `raid1d` „trzyma" dysk docelowy
i dlatego instalacja się nie udaje, żyła w `R-601` miesiącami i została **obalona pomiarem**
w `U-153`.)*

### 6. Utworzenie pustej partycji `EOS-ROOT-B` już przy instalacji

Odrzucone — uzasadnienie w D8: druga sygnatura RedoxFS przy nieznanym mechanizmie wykrywania
roota to ryzyko rozruchowe bez dzisiejszej korzyści, a pusta partycja to trwała strata miejsca,
jeśli `R-710b` nie powstanie. Obszar nieprzydzielony daje to samo przygotowanie za zero.

### 7. Partycja swap „na zapas"

Odrzucone: byłaby to partycja, której **nic w systemie nie potrafi użyć** (K5), a jej wpis GPT
trzeba by potem usuwać. Dodatkowo konkurowałaby o dokładnie tę samą przestrzeń, co ogon pod
slot B — a rezerwować dwa razy tego samego miejsca się nie da.

### 8. Osobne partycje `/var` i `/usr`

Odrzucone. Na Linuksie robi się to dla kwot, dla atomowości aktualizacji `/usr` i dla
oddzielenia logów. U nas: kwot nie ma, atomowość rozwiązujemy dziennikiem i slotami, a **każda
dodatkowa partycja to kolejna nieodwołalna decyzja o rozmiarze**, bo zmiany rozmiaru nie mamy.
Gorzej: staging aktualizacji żyje w roocie (`/var/lib/eos-update/...`), więc odcięcie `/var`
czyni przestrzeń stagingową nieprzewidywalną dokładnie w momencie, gdy jej brak boli najbardziej.

### 9. MBR jako główna tablica partycji

Odrzucone: limit 2 TiB, cztery partycje główne, brak nazw wpisów i brak bitów atrybutów, na
których ma stanąć wskaźnik slotu (D9). GPT jest już stanem faktycznym (`U-162`).

### 10. Zmniejszanie istniejących NTFS/ext4, żeby zrobić miejsce na E-OS

Odrzucone jako funkcja instalatora: zmniejszenie cudzego systemu plików wymaga **jego
zrozumienia**, a my nie mamy nawet odczytu. Uczciwa ścieżka to wykrycie sygnatur i komunikat
*„zwolnij miejsce w tamtym systemie, wróć tutaj"* (`installer.md` §5.6 pkt 4–5). To jest
różnica między niewygodą a utratą danych. **NIEREALNE DZIŚ.**

---

## Konsekwencje

**Co staje się łatwiejsze**

- **Reinstalacja z zachowaniem `/home`** przestaje być niewykonalna (`installer.md` §8.2).
  Dziś jest niewykonalna wyłącznie z powodu układu partycji, nie z powodu braku kodu.
- **`R-710b` (sloty A/B) przestaje wymagać przepartycjonowania** na maszynach instalowanych od
  tej ADR w górę. Zostaje mu praca w bootloaderze i licznik prób rozruchu — czyli to, czym
  faktycznie jest.
- **`R-604` dostaje twardsze dane do ekranu potwierdzenia**: nazwy wpisów GPT zamiast numerów
  w menu, i konkretna lista operacji („utworzę 4 partycje, sformatuję 3, zostawię 24 GiB
  nieprzydzielone").
- **`R-707` przestaje być zablokowane przez rozmiar ESP** (D5).

**Co staje się trudniejsze**

- **Root jest ograniczony do 24 GiB i nie da się go powiększyć.** Kto zapełni root, nie ma
  drogi wyjścia poza reinstalacją. Łagodzenie: staging aktualizacji i cache pakietów mają
  własne limity (do ustalenia w `ADR-0009`), a lokalne budowanie (`sys-build.toml`, cookbook
  w `/home/user/cookbook`) należy do `/home`. `[NIEZWERYFIKOWANE]`, czy RedoxFS ma zmianę
  rozmiaru online — jeśli ma, ten akapit trzeba przepisać, a decyzja robi się mniej kosztowna.
- **Dwa woluminy RedoxFS pod FDE to dwie rzeczy do odblokowania.** Bez pliku klucza w slocie
  (D6) użytkownik dostałby drugi monit o hasło — czego nie zaakceptujemy, więc plik klucza
  jest **warunkiem** osobnego `/home`, a nie ulepszeniem.
- **Dwa woluminy to dwa woluminy bez `fsck`.**

**Jaki dług powstaje i kiedy go spłacić**

| dług | kiedy | pozycja |
|---|---|---|
| `R-607` (realny rozmiar bloku) musi wejść **przed** pierwszą instalacją na NVMe 4Kn | przed macierzą sprzętową | `R-607`, `[P2·M·metal]` |
| poprawić `installer.md`: §5.2 (root „reszta"; ogon „swap **albo** A/B" → D7; `0x2f600` = 193 536 B → **194 048 B**), §5.3 (próg ogona 256 GiB → 128 GiB), §8.2 (`/home` od 256 GiB → 64 GiB) | razem z przyjęciem tej ADR | — |
| narzędzie do slotów kluczy RedoxFS (plik klucza dla `/home`) | razem z osobnym `/home` | **`ADR-0010` §„Etap 2" (`redoxfs-keys`)** — nie `R-609`; `ADR-0010` odnotowuje, że rejestr nie ma na to żadnej pozycji `R-*`, i to tam należy ją założyć |
| mechanizm montowania drugiego woluminu przy starcie, jeśli go nie ma | j.w. | rozszerzenie `R-609` / `eos-base` |
| `fsck` dla RedoxFS | otwarte; osobne `/home` podnosi wagę, bo mnoży woluminy | **`R-615`** — pozycja **istnieje** (`ROADMAP-v2.md:887`, `:950`), nie zakładać drugiej |
| silne sumy kontrolne w RedoxFS | otwarte | **NOWY PODSYSTEM** |
| instalacje sprzed tej ADR nie dostaną A/B bez reinstalacji | do zakomunikowania przy `R-710b` | `R-710` |

**Przypięcie do roadmapy — bez nowych identyfikatorów.** Ta ADR nie tworzy pozycji `R-*`.
Jest **układową połową `R-609`** („ręczne partycjonowanie / instalacja obok", 💡, `[P3·XL]`,
wymaga `R-604`) — konkretnie `R-609d` („tryby partycjonowania w stanie S4: ręczny edytor GPT,
ponowne użycie istniejącego ESP, instalacja w wolnym miejscu, wykrywanie innych systemów po
ESP", `ROADMAP-v2.md:921`) — i **warunkiem wstępnym `R-710b`** (sloty A/B, `[P3·XL]`, wymaga
`R-707` **i** `R-609`).

Rozcięcie `R-710` na `R-710a`/`R-710b` **nie jest już propozycją**, i wcześniejsza wersja tego
akapitu myliła się, pisząc, że `system-updates.md` §1.5 je „proponuje": `ROADMAP-v2.md:977`
przyjmuje je **jako wiążące**, `R-710b` stoi w kamieniu milowym M8 (`:930`) i w grafie
zależności (`:1018`), a `:1051` zapisuje dokładnie tę zależność, którą ta ADR uzasadnia —
„`R-710b` wymaga `R-609`, a nie tylko `R-707`". Ta ADR dokłada do tego **uzasadnienie
geometryczne**, a nie nowy numer. `R-710a` (aktualizacje różnicowe) jest od niej niezależne.
Nie dodaję nowych numerów `R-7xx`, bo przestrzeń `R-70x` jest dziś dwuznaczna między
`ROADMAP.md` a `docs/update-system-design.md` (`system-updates.md` §11.2) i dołożenie trzeciego
znaczenia pogorszyłoby sprawę.

---

## Jak ta decyzja może zawieść — kontrole i ich porażki

Zasada projektu: *kontrola, która nie może zawieść, nie jest kontrolą.* Dla każdej kontroli
wprowadzanej przez tę ADR piszę, jak wygląda jej porażka i jaki test ją wywołuje.

| kontrola | jak wygląda porażka | co ją wywołuje | test, który musi istnieć |
|---|---|---|---|
| odczyt rozmiaru bloku (D3) | instalator liczy GPT na 512 B na dysku 4Kn i zapisuje uszkodzoną geometrię — **stan dzisiejszy** | `block_size` pozostaje stałą | dysk 4Kn w QEMU: albo poprawna geometria, albo odmowa; **nigdy** zapis. **Tego testu dziś nie da się uruchomić** — składnia QEMU dla 4Kn w wersji używanej przez harness jest `[NIEZWERYFIKOWANE]` (poz. 9), więc pierwszą pracą przy `R-607` jest **stanowisko**, a nie poprawka: bez niego „naprawiliśmy `R-607`" byłoby twierdzeniem bez kontroli negatywnej |
| odmowa poniżej 9 GiB (D4) | instalacja rusza, kończy się brakiem miejsca w połowie zapisu | zły próg albo próg liczony po zapisie GPT | dysk 1 MiB poniżej progu → odmowa **przed** pierwszym zapisem |
| rezerwa ogona (D8) | ogon zjedzony przez `/home`, `EOS-ROOT-B` nie ma gdzie powstać | arytmetyka „reszta" zastosowana po kolei zamiast po odjęciu rezerwy | po instalacji: ostatni użyteczny LBA minus koniec `EOS-HOME` = dokładnie rozmiar rezerwy. **Ten test sam ma tryb porażki i trzeba go znać:** liczy w LBA, więc na dysku 4Kn **przed** naprawą `R-607` przejdzie na zielono, mierząc jednostkę 8× za małą. Uruchamiać **po** D3, nigdy zamiast |
| plik klucza `/home` (D6) | dwie porażki, przeciwne: **(a)** `/home` otwiera się plikiem, który nie powinien pasować; **(b)** plik jest poprawny, a montowanie **panikuje** zamiast odmówić — i to jest dziś prawdopodobniejsze | (a) brak weryfikacji slotu; (b) `slot.cipher(password).unwrap()` w pętli po 64 slotach (za briefem) | test negatywny (podmieniony plik → **odmowa**, nie panika) **oraz** pozytywny (plik poprawny → montowanie bez restartu procesu). Warunek odbioru dla obu należy do `ADR-0010` §„Etap 2": dowodem jest udane wyprowadzenie klucza, nie niepusty slot |
| dziennik instalacji bez sekretów (`installer.md` §6.3) | hasło FDE trafia na **nieszyfrowany** ESP | logowanie całej konfiguracji „na wszelki wypadek" | przebieg z FDE, potem `grep` hasła w `EFI/EOS/install-journal.toml` → zero trafień |
| identyfikacja celu (`R-604`) | użytkownik kasuje nie ten dysk | menu numeryczne bez identyfikacji — **stan dzisiejszy** | przebieg z dwoma dyskami o różnej kolejności wyliczania PCI |

Do tej listy dochodzi jedna porażka, której **nie umiemy dziś przetestować** i trzeba to
powiedzieć: `slot.cipher(password).unwrap()` w pętli po 64 slotach ma komentarz
`//TODO: handle errors` (za briefem) — czyli ścieżka **paniki** przy odblokowaniu. Dopóki to
stoi, „odmowa montowania zamiast paniki" jest wymaganiem, nie opisem.

---

## Czego ten układ NIE robi i przed czym NIE chroni

Układ partycji jest geometrią, nie kontrolą bezpieczeństwa. Poniższe nie są zastrzeżeniami
do zamiatania pod dywan — to zakres, poza którym każde zdanie z tej ADR przestaje być prawdziwe.

**Nie chroni niczego poza rootem i `/home` — a i tam tylko przed napastnikiem offline.**

- **ESP jest nieszyfrowany i nieuwierzytelniony.** Wynika to z tego, że firmware musi go
  przeczytać, zanim istnieje jakikolwiek klucz. `system-updates.md` §4.6 nazywa to wprost przy
  wyborze miejsca na wskaźnik slotu: *„ESP jest nieszyfrowany i nieuwierzytelniony — napastnik
  offline przestawia slot"*. Ten sam wniosek dotyczy dziennika instalacji z D4: leży na ESP,
  bo ma być czytelny bez E-OS-a, więc **każdy z dostępem do dysku go czyta i podmienia**.
  Stąd wymóg z tabeli kontroli: w dzienniku nie ma sekretów — nie dlatego, że tak ładniej,
  tylko dlatego, że ESP jest jawny.
- **Brak powiązania z TPM i z Secure Bootem.** `docs/encryption.md` §„Caveats": *„No TPM /
  Secure Boot binding — the password alone protects the disk; an attacker who can tamper with
  the (unencrypted) bootloader could attack the prompt."* Ten układ tego nie zmienia i nie ma
  jak: piąta warstwa zaufania jest pusta (`R-913` / `V2-N02`, **NIEREALNE DZIŚ**). „Dysk jest
  zaszyfrowany" nie znaczy „ten dysk w tej maszynie".
- **Kryptografia nie ma audytu osoby trzeciej.** `docs/encryption.md`, tamże: *„E-OS has not
  had a third-party cryptographic audit."*
- **Osobne `/home` nie jest osobną domeną zaufania.** Plik klucza z D6 leży w roocie, więc
  przejęcie działającego roota daje `/home` za darmo. Ten podział kupuje **reinstalację
  z zachowaniem danych**, i tylko to.

**Nie wykrywa uszkodzenia i nie umie go naprawić.**

- **Sumy RedoxFS to seahash** — ani kryptograficzny, ani kluczowany
  (`scripts/eos-boot-verify-proof.sh:13`). Ciche uszkodzenie danych na roocie jest przez
  system plików **niewykrywalne**, a napastnik z dostępem do dysku dostaje przeliczenie sumy
  za darmo. Obok stoi wyłącznie kontrola po fakcie: blake3 pkgar przy instalacji pakietu,
  podpis ed25519 nad jądrem i initfs (`V2-MS02`) oraz `eos-guard`. Żadne z nich nie chroni
  ścieżki odczytu.
- **Nie ma `fsck` (`R-615`).** Odpowiedzią na uszkodzenie po zaniku zasilania jest
  reinstalacja. Ta ADR **pogarsza** tę sytuację ilościowo, tworząc drugi wolumin.
- **Nie ma migawek**, więc żadna operacja opisana wyżej nie ma taniego cofnięcia.

**Nie zabezpiecza przed pomyłką operatora — to robi `R-604`, nie geometria.**
Nazwy wpisów GPT z D9 nie są uwierzytelnione: każde obce narzędzie może je zmienić, a typ
`LINUX_FS` sprawia, że linuksowe partycjonery pokażą naszą partycję jako „Linux filesystem"
i mogą zaproponować jej użycie. `EOS-ROOT-A` jest **etykietą dla człowieka i dla ekranu
potwierdzenia**, nie dowodem tożsamości partycji.

**Nie rozstrzyga niczego o rozruchu i aktualizacjach.** Wskaźnik aktywnego slotu, licznik prób
rozruchu, kolejność aktywacji — `ADR-0009` i `system-updates.md` §4.3, §4.6. Ta ADR zapewnia
wyłącznie, że układ ich nie wyklucza.

**Nie działa wstecz.** Maszyny zainstalowane przed przyjęciem tej ADR (root do końca dysku,
brak `/home`) nie dostają ani slotów, ani reinstalacji z zachowaniem danych — bez pełnej
reinstalacji z utratą danych. Zamiana kolejności tych dwóch zdań w komunikacji byłaby
wprowadzaniem w błąd.

---

## Zbiorcza tabela znaczników

| zdolność | znacznik | dowód / zakres |
|---|---|---|
| RedoxFS jako root | **JEST** | `mk/config.mk:174` (`REDOXFS_MKFS`), `mk/fstools.mk:25`; `U-162` |
| GPT + ochronny MBR | **JEST** | `U-162` |
| ESP + FAT (`redox-fatfs`) | **JEST** | `U-162` |
| FDE AES-XTS-128 na roocie | **JEST** | `docs/encryption.md` |
| Argon2id jako KDF woluminu | **JEST** | `src/key.rs` (za briefem) |
| 64 sloty kluczy w formacie na dysku | **JEST** | `src/header.rs:31` (za briefem) |
| CoW wewnętrzny w RedoxFS | **JEST** | `docs/architecture.md:82` |
| klon drzewa (`clone_at`, fast-clone) | **JEST** | `src/clone.rs` (za briefem) |
| monitor integralności `eos-guard` (blake3) | **JEST** | `config/x86_64/eos.toml` |
| `raid1d` (RAID-1 w przestrzeni użytkownika) | **JEST** | `ROADMAP-v2` §3.1 |
| ESP 512 MiB zamiast 1 MiB | **DO ZBUDOWANIA** | D5 |
| nazwy wpisów GPT `EOS-*` | **DO ZBUDOWANIA** | D9 |
| osobna partycja `/home` | **DO ZBUDOWANIA** | D6, rozszerzenie `R-609` |
| plik klucza dla drugiego woluminu (slot RedoxFS) | **DO ZBUDOWANIA** | D6; format już to dopuszcza. Narzędzie należy do **`ADR-0010`, etap 2** (`redoxfs-keys`), nie do tej ADR |
| ogon nieprzydzielony pod slot B | **DO ZBUDOWANIA** | D8 |
| konfigurowalne parametry Argon2id | **DO ZBUDOWANIA** | `key.rs` + zapis parametrów w slocie (za briefem); przedmiot **`ADR-0010`**, tu dla kompletności |
| realny rozmiar bloku (4Kn) | **DO ZBUDOWANIA** | `R-607` |
| tryb ręczny / instalacja obok | **DO ZBUDOWANIA** | `R-609` (💡, `[P3·XL]`), rozpisane jako `R-609a`–`R-609d` (`ROADMAP-v2.md:915`–`:921`) |
| wykrywanie obcych systemów po ESP | **DO ZBUDOWANIA** | `R-609d` (`ROADMAP-v2.md:921`); odczyt FAT-a już mamy |
| instalacja na `raid1d` | **DO ZBUDOWANIA** | `R-912` / `V2-D04` |
| montowanie drugiego woluminu przy starcie | **`[NIEZWERYFIKOWANE]` → DO ZBUDOWANIA** | brak `fstab` w `config/`; sprawdzić `eos-base` |
| sloty A/B roota | **NOWY PODSYSTEM** | `R-710b` — rozcięcie przyjęte jako wiążące (`ROADMAP-v2.md:977`); wymaga `R-707`, `R-609` i zapisu w bootloaderze |
| trwały licznik prób rozruchu | **NOWY PODSYSTEM** | bootloader `[NIEZWERYFIKOWANE]` nie zapisuje niczego |
| migawki / subwoluminy RedoxFS | **NOWY PODSYSTEM** | `update-system-design.md:104` |
| silne (kryptograficzne) sumy danych | **NOWY PODSYSTEM** | dziś seahash |
| `fsck` dla RedoxFS | **NOWY PODSYSTEM** | **`R-615`** (`ROADMAP-v2.md:887`, `[P2·XL·🖥️]`) — brak narzędzia, ale pozycja **jest** |
| swap / wymiana stron | **NOWY PODSYSTEM** | brak w drzewie; pytanie do jądra |
| btrfs jako root | **NIEREALNE DZIŚ** | brak sterownika, brak wsparcia w bootloaderze, brak warstwy szyfrującej pod spodem |
| ZFS jako root | **NIEREALNE DZIŚ** | koszt portu i model pamięci (ARC) wobec mikrojądra |
| ext4 / XFS jako root | **NIEREALNE DZIŚ** | nie istnieją, a i tak nie dałyby migawek |
| LVM / device-mapper | **NIEREALNE DZIŚ** | brak warstwy |
| zmiana rozmiaru NTFS/ext4 | **NIEREALNE DZIŚ** | brak odczytu tych systemów plików |
| TPM2 / measured boot / powiązanie klucza | **NIEREALNE DZIŚ** | `R-913` / `V2-N02`; piąta warstwa zaufania pusta |

---

## Czego nie udało się zweryfikować

Lista jest częścią decyzji, nie przypisem do niej.

1. **Wnętrze `redox_installer` i RedoxFS-a.** `recipes/core/installer/` i
   `recipes/core/redoxfs/` zawierają wyłącznie `recipe.toml`; `build/fstools/` nie istnieje
   w tym checkoucie. Wszystkie odwołania do `installer.rs`, `disk_wrapper.rs`, `header.rs`,
   `key.rs`, `clone.rs` pochodzą **z briefu**, nie z odczytu. **Sprawdzić:**
   `make fstools_fetch`, potem odczyt.
2. **Po czym bootloader znajduje root** — po typie GPT, nazwie wpisu, czy przez skan sygnatur.
   Rozstrzyga D8 (czy wolno utworzyć drugi wolumin RedoxFS) i D9 (czy wolno zmienić typ GUID).
   **Sprawdzić:** `eos-bootloader` rev `87b214b5`.
3. **Czy bootloader potrafi cokolwiek zapisać.** Rozstrzyga, czy licznik prób rozruchu jest
   **NOWYM PODSYSTEMEM**, czy tylko pracą do zrobienia. Zakładam, że nie potrafi.
4. **Czy jądro Redoksa ma wymianę stron.** Rozstrzyga D7. **Sprawdzić:** podsystem pamięci
   w `eos-kernel`.
5. **Czy RedoxFS ma zmianę rozmiaru online, `send/receive` i kompresję.** Brak migawek jest
   udokumentowany (`update-system-design.md:104`); reszta nie. Zmiana rozmiaru wpływa wprost
   na koszt ograniczenia roota do 24 GiB.
6. **Czy E-OS ma jakikolwiek mechanizm montowania drugiego woluminu przy starcie.**
   Przeszukałem `config/*.toml` i `config/*/*.toml` — nic. **Sprawdzić:** `init`
   i `/etc/init.d/` w `eos-base`.
7. **Jaki wariant FAT formatuje instalator na ESP** i czy 1 MiB przechodzi na fizycznym UEFI.
   Wpływa na D5.
8. **Rozmiar ESP tworzonego dziś** — `efi_partition_size = 1 MiB` cytuję za
   `system-updates.md` §1.4, który czytał źródło; sam go nie odczytałem.
9. **Składnia QEMU dla dysku 4Kn** w wersji używanej przez harness — potrzebna do testu z D3.
10. **Rejestr znalezisk audytu** (`C-*`) leży na gałęzi `fix/p0-audit-findings` i nie został
    tu odczytany. Zakres tego braku, żeby nie brzmiał groźniej, niż jest: **ta ADR nie opiera
    żadnego twierdzenia na żadnym `C-*`** — nie ma w niej ani jednego takiego odwołania.
    Jeżeli ktoś będzie ją rozszerzał o konto awaryjne (`C-18`, `R-614c`) albo o kanał
    aktualizacji (`C-4`), musi najpierw przeczytać rejestr, a nie brief.
11. **Czy `installer.md` §5.2 i §8.2 zostaną poprawione** pod liczby z D4–D7. Dopóki nie
    zostaną, projekt ma **dwa** opisy tego samego układu dysku, różniące się progami
    (128 vs 256 GiB), rozmiarem roota i odbiorcą ogona. To nie jest ryzyko teoretyczne:
    ta ADR powstała właśnie dlatego, że §5.2 i §5.3 przeczyły sobie w arytmetyce (K6).

---

## Powiązania

- Instalator na nośniku USB: [`../architecture/installer.md`](../architecture/installer.md) §5, §6, §8
- Kreator: [`../architecture/installer-wizard.md`](../architecture/installer-wizard.md) §4.8, §5.5, §13
- Profile i plik odpowiedzi: [`../architecture/installer-profiles.md`](../architecture/installer-profiles.md)
- Aktualizacje: [`../architecture/system-updates.md`](../architecture/system-updates.md) §1.3–§1.5, §4.6;
  `ADR-0009` (mechanizm aktualizacji)
- Rozruch i zaufanie: [`0005-secure-boot-bez-microsoftu.md`](0005-secure-boot-bez-microsoftu.md),
  [`0006-sciezka-do-weryfikacji-microsoftu.md`](0006-sciezka-do-weryfikacji-microsoftu.md)
- Szyfrowanie: [`0010-stos-szyfrowania.md`](0010-stos-szyfrowania.md) — sloty kluczy, klucz
  odzyskiwania, `redoxfs-keys`, czyli warunek D6; oraz [`../encryption.md`](../encryption.md)
- Model zagrożeń: [`../threat-model.md`](../threat-model.md)
- Roadmapa: `ROADMAP-v2.md` — `R-604`, `R-607`, `R-609` (`R-609a`–`R-609d`), **`R-615`**,
  `R-707`, `R-710a`/`R-710b`, `R-912`, `R-913`
