# Kreator instalacji E-OS — specyfikacja UX i techniczna

- **Status:** Propozycja — do zatwierdzenia. Nic z tego nie jest zaimplementowane.
- **Kontekst roadmapy.** Pozycje nadrzędne: `R-601` (udowodnione), `R-603`, `R-604`, `R-605`,
  `R-606`, `R-607`, `R-608`, `R-609`, `R-610`, `R-D01`, `R-D08`, `R-904`, `R-913`, `R-930`.
  **Rozpisanie na zadania zrobiła już `ROADMAP.md` §6** (epik **EP-2**, kamienie **M3**
  i **M4**): `R-603a`–`R-603e`, `R-604a`–`R-604d`, `R-607a`/`R-607b`,
  `R-601d`/`R-601e`, `R-608a`, `R-609a`–`R-609d`, `R-711`, `R-1010`, oraz dwie pozycje
  **założone tam z tego dokumentu** — `R-815` (kanał komend administracyjnych do dysków)
  i `R-D13` (katalog i18n + bramka parytetu kluczy). **Ten dokument nie zakłada żadnego
  nowego identyfikatora** i przy każdej propozycji podaje istniejący numer; §15 jest pełnym
  mapowaniem.
- **Dokumenty siostrzane:** [`installer-profiles.md`](installer-profiles.md) — schemat danych
  profili i funkcji; tutaj opisana jest **semantyka i UX**, struktura danych jest tam i nie jest
  tutaj powtarzana. [`installer.md`](installer.md) — nośnik instalacyjny i partycjonowanie
  (m.in. **swap**, którego ten dokument nie omawia). [`../adr/0010-encryption-stack.md`](../adr/0010-encryption-stack.md)
  — stos szyfrowania, **rozstrzyga §5**. [`../adr/0011-installer-wizard-architecture.md`](../adr/0011-installer-wizard-architecture.md)
  — architektura silnik/rdzeń/frontendy, **rozstrzyga §2**.
- **Dokumenty źródłowe:** [`../install.md`](../getting-started/install.md), [`../encryption.md`](../guides/encryption.md),
  [`../threat-model.md`](../security/threat-model.md), [`../hardening.md`](../security/hardening.md),
  [`../known-issues.md`](../reference/known-issues.md),
  [`../adr/0005-secure-boot-without-microsoft.md`](../adr/0005-secure-boot-without-microsoft.md),
  [`ROADMAP.md`](../../ROADMAP.md).

**Skąd pochodzą cytaty z wnętrza instalatora i RedoxFS.** W tym drzewie roboczym
`recipes/core/installer/` i `recipes/core/redoxfs/` zawierają **wyłącznie `recipe.toml`** —
katalogu `source/` nie ma (sprawdzone: `ls recipes/core/installer` → `recipe.toml`). Każdy cytat
z `installer_tui.rs`, `installer.rs`, `disk_wrapper.rs`, `key.rs`, `header.rs` czy `clone.rs`
pochodzi z **briefu autorytatywnego**, który czytał rozwinięte drzewo budowania, i jest oznaczony
**[z briefu]** — tak samo jak w `ADR-0010` i `ADR-0011`. Sprawdzenie na miejscu:
`make fstools_fetch`, potem lektura `recipes/core/{installer,redoxfs}/source`. Wszystko bez tego
znacznika jest odczytane z tego drzewa i ma podaną ścieżkę z numerem linii.

---

## 0. Jak czytać ten dokument

E-OS jest dystrybucją **Redox OS** — mikrojądro w Ruście, RedoxFS, sterowniki w przestrzeni
użytkownika. Zamówienie na ten kreator jest napisane słownikiem Linuksa (LUKS2, dm-crypt, TPM2,
FIDO2, `mitigations=off`). Prawie żadnego z tych klocków w Redoksie nie ma. Dokument, który by to
przemilczał, obiecywałby instalator, którego nie da się zbudować, więc **każda zamówiona zdolność
dostaje znacznik**:

| Znacznik | Znaczenie |
|---|---|
| **JEST** | działa dzisiaj — z dowodem (plik:linia, nazwa binarki, pozycja `R-*`) |
| **DO ZBUDOWANIA** | wykonalne na Redoksie bez nowego podsystemu — podany zakres i koszt |
| **NOWY PODSYSTEM** | wymaga czegoś, czego Redox nie ma w ogóle — nazwane wprost |
| **NIEREALNE DZIŚ** | zależy od ekosystemu, którego nie ma i szybko nie będzie |
| **[NIEZWERYFIKOWANE]** | nie dało się potwierdzić — podane, co dokładnie sprawdzić |
| **[z briefu]** | odczytane w rozwiniętym drzewie budowania, nie na tej gałęzi — patrz nagłówek |

Znacznik dotyczy **zdolności**, nie ambicji. „LUKS2" i „konfigurowalny szyfr woluminu" to dwie
różne rzeczy i dostają dwa różne znaczniki.

**Zasada, która obowiązuje w całym dokumencie:** *kontrola, która nie może zawieść, nie jest
kontrolą.* Każda proponowana bariera ma opisany tryb porażki. Sekcja bez opisu porażki jest
niedokończona.

### 0.1 Czego ten kreator NIE robi i przed czym NIE chroni

Lista zbiorcza, żeby nie trzeba było jej składać z czternastu sekcji. Każda pozycja ma rozwinięcie
w sekcji podanej obok; **żadna z nich nie jest „wkrótce"** — to jest stan na dzień zatwierdzenia.

**Kreator nie robi:**

1. **Nie partycjonuje ręcznie i nie instaluje obok innego systemu.** Jedyny tryb to „cały dysk";
   `R-609`/`R-609d`. (§4.8)
2. **Nie robi kopii zapasowej niczego.** Ani przed zapisem, ani po. (§4.3)
3. **Nie czyta zawartości obcych systemów plików** — rozpoznanie jest po sygnaturze, bo E-OS nie
   ma sterownika NTFS ani ext4. (§4.4)
4. **Nie odczyta modelu, numeru seryjnego ani SMART-u dysku** przed `R-815`. Identyfikacja
   degraduje się do ścieżki, rozmiaru, typu interfejsu i wymienności. (§4.1, §4.2)
5. **Nie cofa niczego po punkcie bez powrotu (S8).** Nie ma migawki ani „undo" — RedoxFS **nie ma
   API migawek**, `clone.rs` to klon drzewa plików, nie tani punkt w czasie **[z briefu]**. (§9.3)
6. **Nie uruchamia skryptów `%pre`/`%post`** z pliku odpowiedzi — świadomie. (§13.5)
7. **Nie wysyła żadnej telemetrii** i nie ma opcji, żeby ją włączyć. (§12)
8. **Nie mówi po żadnym języku poza pl/en** i nie ma dziś **żadnej** infrastruktury i18n
   (`R-D13`, NOWY PODSYSTEM). (§11)
9. **Nie obsłuży czytnika ekranu** — nie ma stosu dostępności ani syntezy mowy. (§10)
10. **Nie oferuje swapu** — nie ma go w systemie; rzecz należy do [`installer.md`](installer.md)
    §5.2 i `ADR-0008` D7, nie do kreatora.
11. **Nie naprawi uszkodzonego RedoxFS** — `fsck` nie istnieje (`R-615`, NOWY PODSYSTEM).

**Szyfrowanie, które kreator włącza, nie chroni przed:**

12. **Nikim, kto ma dostęp do działającego systemu** — klucz jest wtedy w RAM.
13. **Atakiem na sam monit o hasło.** Bootloader na ESP jest **jawny**, nie ma powiązania z TPM
    ani measured boot (`R-913`); `docs/guides/encryption.md` „Caveats" mówi to wprost. (§5.5)
14. **Podmienionym sterownikiem.** ~16 sterowników ładuje się z roota **niepodpisanych**, a IOMMU
    nie ma (`Dmar::init` to TODO) — urządzenie czyta i pisze dowolny adres fizyczny. (§5.5, §6.5.2)
15. **Trybem live.** Cały obraz nośnika wczytywany jest do RAM **bez weryfikacji** — a to jest
    nośnik, na którym stoi kreator. (§5.5)
16. **Ścieżką BIOS.** stage1/2/3 to surowe sektory, których nic nie uwierzytelnia. (§5.5)
17. **Zapomnieniem hasła.** Nie ma escrow ani automatycznego odblokowania — **z założenia**.
    Klucz odzyskiwania to `DO ZBUDOWANIA`, nie `JEST`. (§5.7)
18. **Cold-bootem, DMA ani analizą entropii dysku.** (§5.2, §5.6)
19. **Niczym, co wymagałoby audytu kryptografii** — E-OS go nie przeszedł (`docs/guides/encryption.md`).

**Czego nie ma w systemie, więc żaden profil tego nie włączy:** zapory (`R-904`, `C-10`),
piaskownicy (`C-5`, `R-1010`), trwałego dziennika audytu (`C-9`), konta awaryjnego (`C-18`),
Tora, VPN-a, trybu amnezyjnego, TPM-a, FIDO2, LVM-a, btrfs/ZFS, systemd, ostree. (§6.4, §6.5)

**Wreszcie: każdy zielony wynik w tym projekcie pochodzi z QEMU.** Nic z tego nigdy nie działało
na fizycznym sprzęcie (`ROADMAP.md` §14.1, `R-607`/`R-607b`).

---

## 1. Punkt wyjścia — co instalator robi dzisiaj

Odczytane z plików, nie przepisane z podsumowań. Wiersze bez znacznika mają dowód **w tym
drzewie**; wiersze z **[z briefu]** pochodzą z rozwiniętego drzewa budowania i nie da się ich
tutaj potwierdzić — powód i procedura sprawdzenia są w nagłówku.

| Fakt | Dowód |
|---|---|
| Silnik: `redox_installer` **0.2.42**, fork `eos-installer` rev `74726c889bdf` | wersja: `repo/aarch64-unknown-redox/installer.toml:2` (`version = "0.2.42"`); fork i rewizja: `recipes/core/installer/recipe.toml:3-5`; nazwa binarki hosta: `mk/config.mk:172` |
| Front-endy: `redox_installer_tui` i `redox_installer_gui` — **oba są w obrazie** | `config/server.toml:20` (`installer = {}`) i `config/desktop.toml:20` (`installer-gui = {}`), oba wciągane przez `config/{aarch64,x86_64}/eos.toml`; binarka GUI: `recipes/gui/installer-gui/manifest` (`binary=/usr/bin/redox_installer_gui`) |
| Umie: GPT + EFI/BIOS, RedoxFS, pełne szyfrowanie AES-XTS, weryfikacja pkgar ed25519, fast-clone | `docs/getting-started/install.md` §2–3, `ROADMAP.md` `R-F24` |
| Instalacja end-to-end **udowodniona 3× z rzędu** (partycja → instalacja → reboot → login) — **wyłącznie pod QEMU/TCG** | `R-601`, `scripts/ci-install-smoke.sh`, `ROADMAP.md` §14.1 |
| Wybór dysku to **gołe menu numeryczne**: `Select a drive from 1 to N`, pozycje to ścieżki `/scheme/disk/...` | `scripts/install-smoke-drive.py:202,209`; w kodzie: `choose_disk()` w `src/bin/installer_tui.rs` **[z briefu]** |
| `disk_paths()` iteruje po schematach `disk*`, **pomija partycje** i zwraca **wyłącznie ścieżkę i rozmiar**. Na Linuksie jest **pustą funkcją** (`fn disk_paths(_paths: &mut Vec<…>) {}`) | `src/bin/installer_tui.rs` **[z briefu]** |
| Komentarz upstreamu w `installer_tui.rs:15-17` nazywa całą brakującą pracę: `1. Linux: Implement disk listing…` · `2. Allow partitioning to allow dual boot…` · `3. Prompt everything (disk password, users, preconfigured packages, import from existing img)` | **[z briefu]** |
| Dysk, z którego wystartowano, **nie jest wypisany** — bo jest zajęty, a nie dlatego, że ktoś go odfiltrował | `scripts/install-smoke-drive.py:205-206` — **komentarz harnessu**, czyli obserwacja, nie reguła w instalatorze |
| Monit o szyfrowanie: jedno pytanie „redoxfs password (empty for none)"; **niewidoczne na konsoli szeregowej** | `docs/getting-started/install.md` §2, `scripts/install-smoke-drive.py:214-216` |
| Kont nie tworzy, pakietów nie wybiera — klonuje domyślne z `base.toml` | `R-603`, `docs/getting-started/install.md` §2 (ostrzeżenie) |
| Hostname każdej instalacji to `eos` | `config/aarch64/eos.toml:58-61` (`path = "/etc/hostname"`, `data = "eos"`), tak samo w `config/x86_64/eos.toml`; `R-606` |
| `DiskWrapper::open` zawsze raportuje rozmiar bloku 512 (`src/disk_wrapper.rs:28`, `// TODO: get real block size…`) → strażnik `match block_size { 512 => …, _ => bail!(…) }` w `src/installer.rs:604` jest **martwym kodem** i dysk 4Kn zostanie zapisany z geometrią liczoną na złym sektorze | **[z briefu]**; pozycja: `R-607` / `R-607a` |
| Instalacja z pliku konfiguracyjnego **działa już dziś**: `redox_installer <diskpath.img> [--config=file.toml] [--write-bootloader[=PATH]] [--live]`, w tym `[general] encrypt_disk` i `general.skip_partitions` | składnia: `src/bin/installer.rs` **[z briefu]**, potwierdzona w `ROADMAP.md` `R-609b`. **Uwaga:** `docs/getting-started/install.md` podaje przestarzałą formę `redox_installer <config.toml> <disk>` — to jest przypadek `R-608`, nie druga poprawna składnia |
| Scalanie konfiguracji **nie deduplikuje**: `Config::merge` → `self.files.extend(other_files)`, wygrywa ostatni wpis | `docs/reference/known-issues.md` |
| RedoxFS: KDF to **Argon2id** (`argon2::Algorithm::Argon2id`, `Version::V0x13`, wyjście 16 B), parametry **domyślne i niekonfigurowalne** (`ParamsBuilder::new()` ustawia wyłącznie `output_len`) | `src/key.rs` **[z briefu]**; szerzej `ADR-0010` |
| RedoxFS: nagłówek ma **64 sloty klucza** — `pub key_slots: [KeySlot; 64]`; `KeySlot` = `salt` + para `EncryptedKey` (dwa klucze, bo AES-XTS) | `src/header.rs:31` **[z briefu]** |
| RedoxFS: odblokowanie **iteruje po wszystkich 64 slotach**, a w pętli stoi `slot.cipher(password).unwrap()` z `//TODO: handle errors` — **ścieżka paniki przy odblokowaniu** | `src/header.rs:121` **[z briefu]** |
| RedoxFS **nie ma API migawek ani wersjonowania**; CoW jest wewnętrzny (`src/transaction.rs:233,474,1947`), a `src/clone.rs` (`clone_at`, użyte przez fast-clone) to **klon drzewa plików**, nie tani punkt w czasie — z `//TODO: handle hard links` | **[z briefu]** |
| Ścieżka plik-po-pliku: **0,101 MiB/s, 31 plików/min, ~6,8 h** na 13 679 plików; ścieżka blokowa: **1,3 MB/s, 460 MB, ~6 min** (QEMU/TCG) | `ROADMAP.md` `R-F24` (`U-176`) |
| **Rozjazd przypięcia, do rozstrzygnięcia przed zatwierdzeniem** | `recipes/core/redoxfs/recipe.toml:6` i `repos.toml:67` przypinają `eos-redoxfs` na `58824d70a07b…`, a `U-156` (zamknięcie `R-F10`) opisuje `555359ef61`. To **dwie różne rewizje**; wszystkie fakty o RedoxFS powyżej odnoszą się do tego, co przeczytał brief, i nie umiem stąd powiedzieć, która rewizja tam leżała. `ADR-0010` notuje to samo |

**Wniosek:** silnik działa i jest udowodniony pod emulacją. Brakuje **wszystkiego, co jest nad
nim** — czyli dokładnie tego, co opisuje ten dokument. To jest rozszerzenie `R-603`/`R-604`
(rozpisane w `ROADMAP.md` §6 jako `R-603a`–`R-603e` i `R-604a`–`R-604d`), a nie nowa praca
obok nich.

---

## 2. Architektura kreatora

### 2.1 Trzy warstwy, jedna prawda

```
┌─ front-end TUI ─────────┐   ┌─ front-end GUI ─────────┐
│ redox_installer_tui     │   │ redox_installer_gui     │   ← tylko rysują i zbierają klawisze
└───────────┬─────────────┘   └───────────┬─────────────┘
            └──────────────┬──────────────┘
                           ▼
             ┌─ eos-setup-core (biblioteka) ─────────────────────┐
             │ maszyna stanów · walidacja · solver zależności    │  ← cała logika, zero rysowania
             │ ocena ryzyka · budowa pliku odpowiedzi           │
             └───────────┬───────────────────────┬───────────────┘
                         ▼                       ▼
        ┌─ dane (JEDNO źródło prawdy) ─┐   ┌─ redox_installer (silnik) ─┐
        │ funkcje, profile, teksty i18n│   │ GPT/ESP/RedoxFS/pkgar      │
        │ /usr/share/eos/setup/**.toml │   │ — istnieje, nie zmieniamy  │
        └──────────────────────────────┘   └────────────────────────────┘
```

**Znacznik: DO ZBUDOWANIA.** Nie wymaga niczego, czego Redox nie ma: to biblioteka w Ruście plus
dwa istniejące front-endy plus pliki TOML w obrazie. Koszt: `L`. Oba front-endy już istnieją
(`config/server.toml:20`, `config/desktop.toml:20`), więc to jest przebudowa, nie start od zera.
**Pozycja: `R-603a`** (`ROADMAP.md` §6.4, M3) — nie nowa praca.

**Nie dopisujemy nowego silnika instalacji.** `redox_installer` przeszedł przez pięć usterek,
z których każda ukrywała następną (`R-F19` → `R-F21` → `R-F22` → `R-F24`), i dopiero teraz działa.
Kreator siada **nad** nim i jego wyjściem jest ten sam `config.toml`, który silnik już przyjmuje.
Rozstrzygnięcie „nowy silnik czy rozszerzenie" należy do `ADR-0011`, nie do tego dokumentu.

**Dług, który to rozwiązuje — nazwany, bo jest konkretny.** Granica silnik/frontend **dziś
przecieka**: `installer_tui.rs` ma **własne** `disk_paths()` i `choose_disk()` **[z briefu]**, więc
logika wyboru celu — czyli operacji nieodwracalnej — żyje we frontendzie. Dlatego GUI i TUI mogą
się rozjechać, i dlatego parytet z §2.3 nie jest dziś sprawdzalny. Przeniesienie tej logiki do
biblioteki **to jest** `R-603a`.

### 2.2 Kontrakt front-end ↔ rdzeń

Front-end **nie zna reguł**. Dostaje z rdzenia opis ekranu i odsyła zdarzenia:

| Kierunek | Wiadomość | Zawartość |
|---|---|---|
| rdzeń → front | `Screen` | id stanu, tytuł (klucz i18n), lista kontrolek, stan przycisków wstecz/dalej |
| rdzeń → front | `Diagnostics` | lista ostrzeżeń/błędów z poziomem, kluczem i18n i wskazaniem kontrolki |
| front → rdzeń | `Event` | `Set{control, value}`, `Next`, `Back`, `Cancel` |
| rdzeń → front | `Progress` | faza, procent, ostatnia linia dziennika |

Serializacja: TOML/JSON po potoku (rdzeń może działać w tym samym procesie jako biblioteka —
potok jest po to, żeby dało się go **testować i podsłuchiwać**, i żeby GUI nie musiało działać
z tymi samymi uprawnieniami co część zapisująca dysk).

### 2.3 Parytet GUI ↔ TUI — i jak go egzekwować

Parytet zadeklarowany jest bezwartościowy. Definicja operacyjna:

> Ten sam plik odpowiedzi przepuszczony przez TUI i przez GUI produkuje **bajtowo identyczny**
> `config.toml` wyjściowy i identyczną listę ostrzeżeń.

**Bramka (`DO ZBUDOWANIA`, `S`) — to jest `R-601d`, nie nowa pozycja** (`ROADMAP.md` §6.4,
M3: *„Bramka parytetu GUI ↔ TUI: oba frontendy muszą pokrywać ten sam zbiór stanów"*). Kształt:
test w CI, który uruchamia `eos-setup --replay <answers.toml>` w trybie `--frontend=tui`
i `--frontend=gui-headless`, i porównuje oba wyjścia. Bramka nie sprawdza pikseli — sprawdza,
że logika jest jedna.

**Jak ta kontrola zawodzi:** jeżeli GUI doda własną walidację po swojej stronie (kuszące, bo
szybsze), test przejdzie, a użytkownik GUI zobaczy inne ostrzeżenia. Dlatego bramka musi
porównywać także **`Diagnostics`**, nie tylko `config.toml`. Drugi tryb porażki: front-end
milcząco obcina listę kontrolek, których nie umie narysować. Rdzeń musi więc odrzucać ekran,
w którym front-end nie potwierdził wyrenderowania wszystkich kontrolek o poziomie
`obowiązkowa`.

> **`R-D08` mówi wprost:** pełny przepływ *live → greeter → installer-gui → instalacja* **nigdy
> nie był testowany od końca do końca**; `R-601` udowodnił ścieżkę TUI, nie tę. Parytet zaczyna
> się od zamknięcia `R-D08`, inaczej dokumentujemy parytet z czymś, czego nikt nie uruchomił.

### 2.4 Gdzie to mieszka w obrazie

| Artefakt | Ścieżka | Uwaga |
|---|---|---|
| binarka kreatora | `/usr/bin/eos-setup` | uruchamiana też z `installer-gui` |
| dane funkcji i profili | `/usr/share/eos/setup/features/*.toml`, `/profiles/*.toml` | patrz `installer-profiles.md` |
| teksty | `/usr/share/eos/setup/i18n/<lang>.toml` | patrz §10 |
| plik odpowiedzi z tej instalacji | `/var/log/eos-setup/answers.toml` (w zainstalowanym systemie) | patrz §12 |
| dziennik przebiegu | `/var/log/eos-setup/run-<ts>.log` | jawnie **bez** sekretów, patrz §11 |

---

## 3. Maszyna stanów

### 3.1 Stany

```
  S0 Powitanie i język
        │
  S1 Wywiad o przeznaczeniu maszyny            (można pominąć → S2)
        │
  S2 Rekomendacja profilu + uzasadnienie
        │
  S3 Wybór dysku docelowego                     ◄── §4
        │
  S4 Tryb rozdysponowania dysku                 (dziś: tylko „cały dysk", §4.6)
        │
  S5 Szyfrowanie                                ◄── §5
        │
  S6 Funkcje szczegółowe                        ◄── §7
        │
  S7 Tożsamość: konta, hostname, strefa, układ klawiatury   (R-603/R-606)
        │
  S8 Podsumowanie i diff  ═══ PUNKT BEZ POWROTU ═══
        │
  S9 Zapis                                      (postęp, bez „wstecz")
        │
  S10 Koniec: co dalej, plik odpowiedzi, klucz odzyskiwania
```

### 3.2 Reguły przejść

1. **Wstecz działa wszędzie do S8 włącznie.** Po S8 nie ma powrotu — bo tablica partycji jest już
   nadpisana. Kreator mówi to **przed** S8, nie po.
2. **Wstecz nie kasuje odpowiedzi.** Wejście na S5 z nowym dyskiem zachowuje wybór szyfrowania,
   o ile nadal jest ważny; jeżeli nie jest — kreator pokazuje **co unieważnił i dlaczego**,
   zamiast cicho przestawić.
3. **Zmiana profilu na S2 nie nadpisuje ręcznych zmian z S6** bez pytania. Ekran zmiany profilu
   pokazuje diff: „ta zmiana cofnie 3 twoje ustawienia — pokaż które".
4. **Anuluj** jest dostępne do S8 i nie zostawia niczego na dysku. Po S8 „Anuluj" zmienia się
   w „Przerwij" i ma inną semantykę (§9.3).
5. **Każdy stan da się osiągnąć z pliku odpowiedzi**, i wtedy jest pomijany. Stan, którego nie da
   się wyrazić w pliku odpowiedzi, nie może istnieć — inaczej tryb nienadzorowany jest kłamstwem.

### 3.3 Punkt bez powrotu — jak wygląda

S8 jest jedynym ekranem z przyciskiem, który niszczy dane. Kolejność jest celowa: **najpierw
pokaż, co zniknie, potem poproś o potwierdzenie, nigdy odwrotnie.** Szczegóły w §4.5.

---

## 4. Ekran S3/S4 — wybór dysku docelowego

### 4.1 Czego wymaga zamówienie i co da się dostarczyć

| Pole na ekranie | Znacznik | Skąd wziąć / czego brakuje |
|---|---|---|
| **Ścieżka urządzenia** (`/scheme/disk/...`) | **JEST** | już wypisywane przez TUI (`install-smoke-drive.py:209`; `disk_paths()` **[z briefu]**) |
| **Rozmiar** | **JEST w silniku, DO ZBUDOWANIA na ekranie** (`S`) | `disk_paths()` zwraca **ścieżkę i rozmiar** **[z briefu]** — czyli dane są, brakuje wypisania ich **przed** wyborem, nie po. Pozycja: `R-603a` |
| **Rzeczywisty rozmiar bloku (512 / 4Kn)** | **DO ZBUDOWANIA** (`M`) — **`R-607a`** | dziś `DiskWrapper::open` **zawsze** zwraca 512 (`src/disk_wrapper.rs:28` **[z briefu]**). Wymaga odczytu z `nvmed`/`ahcid`, czyli **`R-815`** |
| **Model i numer seryjny** | **NOWY PODSYSTEM** (`M`) — **`R-815`** | wymaga NVMe *Identify Controller* / ATA *IDENTIFY DEVICE* wystawionego przez sterownik. **[NIEZWERYFIKOWANE]** — sterowniki są w forku `eos-base`, poza tym drzewem. **Co sprawdzić:** czy `drivers/storage/nvmed` implementuje `Identify` (opcode `0x06`) i czy `/scheme/disk` ma jakikolwiek kanał metadanych poza `read`/`write`. |
| **Typ interfejsu** (NVMe / AHCI / USB / virtio) | **DO ZBUDOWANIA** (`S`) | wynika z nazwy schematu i ze sterownika, który go zarejestrował; docelowo z `eos-devd` (`R-801`) |
| **Nośnik wymienny tak/nie** | **DO ZBUDOWANIA** (`S`) | dla USB wynika z tego, że urządzenie przyszło przez `usbscsid`; dla reszty **[NIEZWERYFIKOWANE]** (N12) |
| **Zdrowie SMART** | **NOWY PODSYSTEM** (`L`) — **`R-815`** | patrz §4.2 |
| **Istniejące partycje** | **DO ZBUDOWANIA** (`M`) — `R-604a` | GPT/MBR trzeba przeczytać, a nie tylko zapisać; silnik już umie pisać GPT, a `disk_paths()` **pomija partycje** **[z briefu]**, więc czytania nie ma w ogóle |
| **Rozpoznane systemy operacyjne** | **DO ZBUDOWANIA** (`M`) — `R-604a`, `R-609d` | rozpoznanie po GUID typu partycji + sygnaturze systemu plików + obecności `EFI/*/BOOT*.EFI` na ESP; patrz §4.4 |

> **`ROADMAP.md` §6.4 stawia to samo ograniczenie i trzeba je powtórzyć tutaj:** *„M3 działa
> bez `R-815`. Identyfikacja dysku degraduje się wtedy do ścieżki, rozmiaru, typu interfejsu
> i wymienności — czyli **mniej**, niż mówi zamówienie."* To ma być napisane **na ekranie**,
> a nie odkryte przy zgłoszeniu.

### 4.2 SMART — klasyfikacja i co dokładnie trzeba zbudować

**Znacznik: NOWY PODSYSTEM (`L`). Pozycja: `R-815`** — założona przez `ROADMAP.md` §6.2 i §6.4
**na podstawie tej sekcji**, w rodzinie `R-8xx`, bo `R-812`–`R-814` są zarezerwowane przez
`docs/architecture/driver-manager.md`. Powody, po kolei:

1. W obrazie nie ma żadnego narzędzia SMART. Jedyny ślad w drzewie to receptura
   `recipes/wip/tools/smartmontools/recipe.toml`, której pierwsza linia brzmi
   `#TODO compilation error` — czyli nie kompiluje się i nie jest w żadnej konfiguracji.
2. SMART nie jest funkcją systemu plików ani warstwy blokowej — to **komenda administracyjna
   urządzenia**: NVMe *Get Log Page* (opcode `0x02`, log `0x02` = SMART/Health) albo ATA
   `SMART READ DATA` przez pass-through. Żadna z nich nie przechodzi przez zwykłe `read`/`write`.
3. Redox wystawia dyski jako schematy plikowe. **Nie ma kanału na komendę administracyjną.**
   To jest ta brakująca część: potrzebny jest kontrakt „polecenie do urządzenia" w `/scheme/disk`
   (albo osobny `/scheme/diskctl`), zaimplementowany osobno w `nvmed` i `ahcid`.

**Zakres do zbudowania:** (a) rozszerzenie protokołu schematu dyskowego o zapytanie
metadanych/log; (b) implementacja NVMe Identify + Get Log Page w `nvmed`; (c) ATA IDENTIFY
i SMART w `ahcid`; (d) czytnik po stronie kreatora. Punkty (b) i (c) dają **przy okazji** model,
numer seryjny i rzeczywisty rozmiar bloku, czyli domykają też `R-607a` i identyfikację dysku
z `R-604a`, a bezpiecznemu kasowaniu z profilu Ghost (§6.5.2) dają jedyną drogę, jaka istnieje.
To argument, żeby zrobić to raz i porządnie, a nie doklejać model dysku osobno.

**[NIEZWERYFIKOWANE]:** czy `eos-base` ma już jakąkolwiek ścieżkę komend administracyjnych.
**Co sprawdzić:** `drivers/storage/nvmed/src/**` — obecność struktur `IdentifyController`,
`GetLogPage`; `drivers/storage/ahcid/src/**` — `ATA_CMD_IDENTIFY`; oraz czy scheme dyskowy
obsługuje cokolwiek poza `Read`/`Write`/`Fstat`.

**Zachowanie kreatora, dopóki tego nie ma:** ekran **mówi wprost** „E-OS nie potrafi dziś
odczytać modelu ani stanu zdrowia tego dysku", zamiast pokazywać puste pole albo — gorzej —
zielony znacznik „OK". Pusty wskaźnik zdrowia czytany jest jako „zdrowy"; to jest ta sama
klasa błędu co martwy strażnik 512 z `R-607`.

### 4.3 Ostrzeżenie o destrukcji

Ekran S4 pokazuje, **co zniknie**, w kolejności od najbardziej bolesnego:

```
  ⚠  /scheme/disk/nvme0n1  —  477 GiB  —  NVMe  —  model: (nieodczytany)

     Zawartość, którą E-OS rozpoznaje:
       1.  260 MiB   EFI System            zawiera: EFI/Microsoft/BOOT/bootmgfw.efi
       2.  16 MiB    Microsoft reserved
       3.  475 GiB   Basic data (NTFS)     etykieta: "Windows"
       4.  520 MiB   Windows Recovery

     Instalacja skasuje TABLICĘ PARTYCJI i WSZYSTKIE cztery pozycje.
     Kopii zapasowej nie zrobi nic — ani ten kreator, ani E-OS.
```

**Znacznik: DO ZBUDOWANIA (`M`). Pozycja: `R-604a`** (identyfikacja dysku) + `R-604b` (ekran
różnicowy przed zapisem). Odczyt GPT/MBR i rozpoznanie systemów plików po sygnaturze to zwykły
kod; nic w Redoksie tego nie blokuje. Wiersz „model:" pozostaje pusty do `R-815` — i ma być
**wypisany jako nieodczytany**, nie pominięty (§4.2).

### 4.4 Rozpoznawanie obcych systemów — i granica uczciwości

Rozpoznajemy po: GUID typu partycji (GPT), sygnaturze systemu plików w superbloku (NTFS, ext4,
FAT32, APFS, RedoxFS), oraz zawartości ESP (`EFI/*/BOOT*.EFI`, `EFI/Microsoft/…`, `EFI/redox*`).

**Czego NIE robimy:** nie montujemy obcych systemów plików. E-OS nie ma sterownika NTFS ani ext4
w obrazie, a montowanie nieznanego systemu plików kodem, którego nie ma, jest po prostu
niemożliwe. Rozpoznanie jest więc **po sygnaturze, nie po zawartości**, i ekran musi to mówić:
„rozpoznano NTFS — nie odczytano, co w nim jest".

**Tryb porażki:** dysk z uszkodzoną tablicą GPT albo z egzotycznym układem zostanie opisany jako
„nierozpoznany". Kreator **nie może** wtedy powiedzieć „dysk pusty". Musi powiedzieć „nie
rozpoznaję układu tego dysku — jeżeli coś na nim jest, zniknie" i **podnieść** próg
potwierdzenia, a nie obniżyć.

### 4.5 Bariera potwierdzenia (`R-604`, zadania `R-604a`–`R-604c`)

Dzisiaj: wpisanie `1` w menu numerycznym kasuje dysk (`choose_disk()` **[z briefu]**). Docelowo
trzy warstwy:

| Warstwa | Co robi | Tryb porażki |
|---|---|---|
| **1. Pokaż** | pełna zawartość dysku, jak w §4.3 | użytkownik nie czyta; dlatego warstwa 1 sama nie wystarcza |
| **2. Przepisz** | wpisanie identyfikatora celu — **numeru seryjnego**, gdy jest, inaczej ścieżki schematu | przepisanie da się zrobić bezmyślnie, kopiuj-wklej; dlatego identyfikator ma być **inny dla każdego dysku** i **widoczny na ekranie tylko raz**, nad polem |
| **3. Odliczanie** | 5 s bezczynności przycisku „Skasuj i zainstaluj" po ostatniej zmianie ekranu | przełamywalne czekaniem; jego rolą jest złapać **odruch**, nie napastnika |

**Świadoma decyzja:** nie stosujemy modalnego „Czy na pewno?" jako jedynej bariery. Modal na
jedno kliknięcie jest odruchowo odklikiwany i to jest zmierzone zachowanie ludzi, nie opinia.

**Tryb nienadzorowany omija warstwy 2 i 3** — i właśnie dlatego plik odpowiedzi musi zawierać
jawną zgodę na destrukcję z **nazwą celu w środku** (§12.3). Zgoda `--assume-yes` bez nazwy celu
jest odrzucana.

### 4.6 Odmowa niebezpiecznych celów

Kreator **odmawia** (twardo, bez opcji „i tak zrób") w tych przypadkach. Cała tabela to **`R-604c`**
(*„odmowa niebezpiecznych celów"*, zależna od `R-607a`):

| Warunek | Uzasadnienie | Znacznik |
|---|---|---|
| Cel jest urządzeniem, z którego uruchomiono system | instalacja nadpisałaby własne źródło w trakcie czytania | **DO ZBUDOWANIA** — dziś **nie ma takiej reguły**; zajęty dysk po prostu nie trafia na listę, co odnotowuje komentarz harnessu (`install-smoke-drive.py:205-206`). Skutek uboczny to nie kontrola. |
| Cel zawiera plik odpowiedzi używany w tym przebiegu | j.w. | **DO ZBUDOWANIA** (`S`) |
| Rozmiar celu < `filesystem_size` + ESP + margines | instalacja padnie w połowie, zostawiając nierozruchowy dysk | **DO ZBUDOWANIA** (`S`); `filesystem_size = 1400` (MiB) w `config/aarch64/eos.toml:8` i `config/x86_64/eos.toml:11` |
| **Nie udało się odczytać rzeczywistego rozmiaru bloku** | dysk 4Kn zapisany z założeniem 512 daje uszkodzoną tablicę partycji; dziś strażnik 512 jest martwym kodem (`R-607`/`R-607a`) | **DO ZBUDOWANIA** (`M`) — **odmowa, nie założenie**. To jest odwrócenie dzisiejszego zachowania. Bez `R-815` „odczytać" znaczy „dostać prawdziwą liczbę ze sterownika", a takiego kanału dziś nie ma — więc reguła zaczyna działać dopiero z nim, i do tego czasu **jest deklaracją, nie kontrolą**. |

Kreator **ostrzega, ale pozwala** przy:

- celu **wymiennym** (USB) — patrz §4.7;
- celu, na którym rozpoznano inny system operacyjny — z pełnym wyliczeniem z §4.3;
- dysku, dla którego SMART zgłasza przekroczony próg — gdy SMART już będzie (§4.2).

**Tryb porażki całej sekcji:** lista odmów jest tak dobra, jak rozpoznanie, na którym stoi.
Przy nierozpoznanym układzie dysku (§4.4) żadna z reguł „zawiera system X" się nie odpali.
Dlatego reguła rozmiarowa i reguła bloku są **niezależne od rozpoznania** — działają na
surowych liczbach.

### 4.7 Instalacja na USB

Trzy różne rzeczy, które zamówienie zlewa w jedną:

| Co | Znacznik | Stan |
|---|---|---|
| **Wypalenie nośnika instalacyjnego na USB przez `dd`** | **JEST** | `docs/getting-started/install.md` §4 — `harddrive.img` i `redox-live.iso` |
| **Wypalenie przez `popsicle`** | **[NIEZWERYFIKOWANE]** | cel istnieje — `Makefile:16-17`: `popsicle: $(BUILD)/redox-live.iso` → `popsicle-gtk …` — ale wywołuje **linuksowe narzędzie GTK po stronie hosta**, którego na hoście budowania tego projektu (macOS/Apple Silicon, `CLAUDE.md` §9) nie ma; `installer.md:94` mówi wprost, że ta ścieżka **nigdy nie była testowana przez E-OS**. Istnienie celu Make nie jest dowodem na „JEST" |
| **Wypalenie przez Ventoy (`scripts/ventoy.sh`)** | **NIE DZIAŁA dziś** | `R-F28`: skrypt ma zaszyte `ARCHS=(i686 x86_64)` i `CONFIGS=(demo desktop)`, a `CONFIG_NAME=eos` w nim **nie występuje** — zbuduje i skopiuje cudzy obraz (`ROADMAP.md`, `installer.md:142`, `docs/archive/hardware-plan.md`). Kreator nie może się na to powoływać |
| **Instalacja E-OS *na* pendrive jako cel** | **DO ZBUDOWANIA** (`S`) | silnik pisze na dowolne `/scheme/disk/...`; brakuje wykrycia „to jest wymienne" i ostrzeżenia |
| **Instalacja z USB na USB** (źródło i cel wymienne) | **DO ZBUDOWANIA** (`M`) | wymaga rozróżnienia źródła od celu — patrz pierwsza reguła odmowy w §4.6 (`R-604c`) |

Nazwa nośnika, jego suma i podpis należą do [`installer.md`](installer.md) §2 (`R-611a`–`R-611c`),
nie tutaj. Kreator zakłada wyłącznie, że dostanie nośnik dający się sprawdzić — i **od 2026-09-01
tak jest**: `scripts/make-release.sh:94-96` dokłada `sha256` nośnika do tego samego `SHA256SUMS`,
który `:115` podpisuje `minisign`.

Wcześniej obejmowany był wyłącznie `harddrive.img`, więc zdanie „sprawdź podpis pobranego
nośnika" byłoby w kreatorze nieprawdą operacyjną. Teraz nie jest — i to jest warunek, który
kreator może wreszcie postawić.

Ostrzeżenie przy celu wymiennym jest rzeczowe, nie straszące: instalacja na pendrive **działa**,
ale nośniki USB mają mniejszą wytrzymałość zapisu i wolniejszy zapis losowy, a odłączenie w trakcie
pracy systemu plików to uszkodzenie. Podajemy zmierzone tempo instalacji, żeby użytkownik wiedział,
na co się pisze: **ścieżka blokowa ~6 min / 460 MB**, **ścieżka plik-po-pliku ~6,8 h** — obie liczby
z `R-F24`, obie z QEMU/TCG, więc na metalu będą inne (`R-607` tego jeszcze nie zmierzył).

### 4.8 Partycjonowanie ręczne i instalacja obok

**To jest `R-609`** („ręczne partycjonowanie / instalacja obok / dual-boot", `[P3·XL]`,
zależne od `R-604`), rozpisane w `ROADMAP.md` §6.4 jako **`R-609d`** (ręczny edytor GPT,
ponowne użycie istniejącego ESP z zapisem **wyłącznie** do `EFI/EOS/`, instalacja w wolnym
miejscu, wykrywanie innych systemów po ESP). Tam też stoi granica, którą trzeba tu powtórzyć:
**zmiana rozmiaru NTFS/ext4 to NIEREALNE DZIŚ**, bo nie mamy nawet odczytu tych systemów plików.
Ten dokument **nie tworzy dla tego nowej nazwy** i nie przyspiesza tej
pozycji. Kreator projektowany jest tak, żeby stan **S4 był rozszerzalny**: dziś jedna opcja
(„użyj całego dysku"), jutro trzy („obok istniejącego systemu", „w wolnym miejscu", „ręcznie").
Model danych ekranu S4 od początku ma pole `mode`, żeby dodanie trybów nie zmieniało formatu
pliku odpowiedzi.

Uwaga do `R-609`: `scripts/dual-boot.sh` **już istnieje**, ale to skrypt **linuksowy**, który
instaluje Redoksa w wolnym miejscu z hosta i dopisuje wpis do `systemd-boot`. To nie jest
ścieżka wewnątrz kreatora i nie należy jej mylić z `R-609`.

---

## 5. Ekran S5 — szyfrowanie

### 5.1 Fakt strukturalny, od którego zależy cała reszta

**Szyfrowanie w E-OS jest własnością systemu plików, nie warstwy blokowej.** RedoxFS szyfruje
sam siebie: AES-XTS-128 (`docs/guides/encryption.md`), klucz wyprowadzany z hasła przez
**Argon2id** — `argon2::Algorithm::Argon2id`, `Version::V0x13`, wyjście 16 bajtów, zależność
`argon2 = "0.4"` (`src/key.rs` **[z briefu]**). `docs/guides/encryption.md` pisze samo „argon2", bez
wariantu; wariant jest **odczytany ze źródła**, nie zgadnięty.
Redox **nie ma device-mappera**, więc nie ma czego układać w warstwy: nie da się „założyć
drugiego dm-crypta pod pierwszym", bo nie ma pierwszego jako urządzenia.

Wszystkie zamówione warianty warstwowe (LUKS na LUKS, kaskada dm-crypt, nagłówek odłączony,
wolumin ukryty) zakładają **stosowalną warstwę blokową**. To jest jeden brak, z którego wynika
pięć „nie da się". Nazwanie go raz jest uczciwsze niż pięć osobnych wymówek.

**[NIEZWERYFIKOWANE] i warte sprawdzenia:** `raid1d` — userspace'owy RAID1, który **jest**
w obrazie — musi w jakiejś formie wystawiać urządzenie blokowe złożone z innych. Jeżeli robi to
przez schemat, który RedoxFS potrafi otworzyć jako dysk, to jest **zalążek** stosowalnej warstwy
blokowej i cała ta sekcja wygląda inaczej. **Co sprawdzić:** `eos-base`,
`drivers/storage/raid1d/src/**` — czy rejestruje schemat typu dyskowego i czy `redoxfs` potrafi
go użyć jako urządzenia docelowego.

### 5.2 Zbiorcza tabela zamówionych opcji

Koszt wydajności podany jako **mnożnik pracy CPU na sektor** (arytmetyka, obroni się) plus
**prognoza przepustowości** (założenie, oznaczone). Podstawa prognoz:

> **Założenie P1 [NIEZWERYFIKOWANE]:** AES-XTS ze wsparciem sprzętowym (ARMv8 CE — E-OS ma to
> włączone, `--cfg aes_armv8`, `R-502`; AES-NI na x86_64) osiąga rząd **1–5 GB/s na rdzeń**.
> **Założenie P2 [NIEZWERYFIKOWANE]:** Serpent/Twofish bez wsparcia sprzętowego osiągają rząd
> **100–300 MB/s na rdzeń**. Obie liczby to typowe wyniki `cryptsetup benchmark` z Linuksa,
> **nie pomiar na E-OS**. `R-502` mówi „benchmarked", ale w `ROADMAP.md` i `CHANGELOG.md` nie ma
> ani jednej liczby przepustowości — więc traktujemy to jako niezmierzone.
> **Czego trzeba, żeby zmierzyć:** benchmark odczytu/zapisu RedoxFS, ten sam nośnik, cztery
> przebiegi (szyfrowany/nie × `aes_armv8` wł./wył.), na **fizycznym** dysku — czyli po `R-607`.
> Pod QEMU/TCG pomiar jest bezwartościowy: emulacja jest ~1,9× wolniejsza (`R-F23`), a instalacja
> plik-po-pliku mierzy 0,101 MiB/s, więc szyfrowanie i tak nie jest wąskim gardłem.

| Zamówiona opcja | Znacznik | Koszt CPU | Przed czym chroni | Przed czym **nie** chroni | Utrata klucza |
|---|---|---|---|---|---|
| **RedoxFS AES-XTS-128 hasłem** (dzisiejsza) | **JEST** | 1× (odniesienie) | dane w spoczynku: zgubiony/skradziony wyłączony sprzęt | działającym systemem, podmianą bootloadera, DMA, cold-boot | **całkowita utrata danych** — brak escrow i brak automatycznego odblokowania z założenia |
| **Argon2id jako KDF woluminu** | **JEST** | jednorazowo przy odblokowaniu | atakiem słownikowym w tempie, jakie narzuca funkcja pamięciochłonna | jw. | jw. |
| **64 sloty klucza w formacie na dysku** | **JEST** | 0 | — (to nośnik zdolności, nie zdolność) | niczym samo z siebie — **brakuje narzędzi**, patrz `ADR-0010` | jw. |
| **Konfigurowalny szyfr woluminu** (np. AES-XTS-256) | **DO ZBUDOWANIA** (`M`) | ~1,4× (AES-256 = 14 rund vs 10) | to samo, przy większym marginesie na przyszłość | to samo co wyżej | jw. |
| **Argon2id z konfigurowalnymi parametrami** | **DO ZBUDOWANIA** (`S`–`M`) | jednorazowo przy starcie, nie na sektor | atakiem słownikowym na hasło | jw. | jw. |
| **Zgodność z formatem LUKS2** | **NIEREALNE DZIŚ** | — | — | — | — |
| **LUKS na LUKS (dwie warstwy)** | **NIEREALNE DZIŚ** | ~2× gdyby istniało | teoretycznie: złamaniem jednej warstwy | j.w. + podwaja kod w TCB | utrata **którejkolwiek** = utrata całości |
| **Kaskada AES-XTS + Serpent/Twofish** | **NOWY PODSYSTEM** (`XL`) | ~2× praca; prognoza przepustowości **~10–15× wolniej** niż samo AES (P1+P2) | złamaniem AES — zdarzeniem, którego nie ma | niczym więcej niż jedna warstwa | jw. |
| **Szyfrowany `/boot`** | **JEST w części, która ma znaczenie** — §5.5 | 0 (nic dodatkowego) | odczytem jądra i initfs z wyłączonego dysku | bootloaderem na ESP (jawny), ścieżką BIOS, trybem live | jw. |
| **Nagłówek odłączony na nośniku wymiennym** | **NOWY PODSYSTEM** (`L`) | 0 na sektor | „na dysku nie widać, że to szyfrowany RedoxFS" | analizą entropii, świadkiem, sprzętem | **utrata nośnika = utrata danych**, nawet gdy hasło się zna |
| **Klucz: hasło** | **JEST** | — | jw. | jw. | całkowita |
| **Klucz: plik klucza** | **DO ZBUDOWANIA** (`M`) | — | wygodą przy odblokowaniu automatycznym | nikim, kto ma nośnik z plikiem | całkowita, jeśli brak drugiego slotu |
| **Klucz: FIDO2** | **NIEREALNE DZIŚ** | — | — | — | — |
| **Klucz: TPM2 z polityką PCR** | **NIEREALNE DZIŚ** | — | — | — | — |
| **Klucz odzyskiwania** | **DO ZBUDOWANIA** (`M`) | — | utratą hasła głównego | jw. co reszta | to **jest** ratunek na utratę klucza — dlatego jest najważniejszą pozycją tej listy |
| **Wolumin ukryty / plausible deniability** | **NIEREALNE DZIŚ** | — | — | — | — |

### 5.3 LUKS2, Argon2id i „konfigurowalny szyfr" — rozdzielenie

Zamówienie skleja trzy różne rzeczy pod jedną nazwą. Rozdzielone:

**a) Zgodność z formatem LUKS2 — NIEREALNE DZIŚ.**
LUKS2 to format nagłówka **nad dm-cryptem**. dm-crypt jest modułem device-mappera w jądrze
Linuksa. Redox jest mikrojądrem bez device-mappera i bez modułów w ogóle. Zaimplementowanie
LUKS2 znaczyłoby: napisać warstwę blokową w przestrzeni użytkownika, przepisać dm-crypt,
przepisać cryptsetup, i doprowadzić bootloader do czytania nagłówka LUKS2 **zanim** cokolwiek
się zamontuje. To nie jest „duży ticket", to jest inny system operacyjny. Odrzucone w §16.

**b) Konfigurowalny szyfr woluminu — DO ZBUDOWANIA (`M`).**
Zdolność jest osiągalna bez LUKS-a: RedoxFS ma nagłówek i **64 sloty klucza** —
`pub key_slots: [KeySlot; 64]` (`src/header.rs:31` **[z briefu]**), gdzie `KeySlot` to `salt`
plus para `EncryptedKey` (dwa klucze, bo AES-XTS). Rozszerzenie nagłówka o identyfikator szyfru
i wybór implementacji jest zwykłą pracą.
**Koszt ukryty, który trzeba wycenić uczciwie:** `R-F10` pokazał, że bootloader przez lata
używał **innej** wersji RedoxFS niż system (crates.io 0.8 vs fork 0.9), i „dziś to
interoperuje" było prawdą tylko przez przypadek. Pierwsza zmiana formatu nagłówka po obu
stronach **unieruchamia szyfrowany dysk**. Każda zmiana formatu musi więc iść z bramką
boot-smoke na obu architekturach, na dysku szyfrowanym — inaczej dodajemy dokładnie tę usterkę,
którą projekt właśnie zamknął.

**c) Argon2id na woluminie — sam KDF jest JEST; *konfigurowalne parametry* to DO ZBUDOWANIA (`S`–`M`).**
To są dwie różne rzeczy i wcześniejsza wersja tej sekcji je myliła — pytała
**[NIEZWERYFIKOWANE]**, jaki to wariant, choć odpowiedź jest w źródle. Poprawka, jawnie:

- **Wariant: Argon2id.** `argon2::Algorithm::Argon2id`, `argon2::Version::V0x13`, wyjście
  16 bajtów, zależność `argon2 = "0.4"` — `src/key.rs` **[z briefu]**. `docs/guides/encryption.md`
  pisze samo „argon2"; to jest niedopowiedzenie dokumentu, nie niewiadoma.
- **Parametry są DOMYŚLNE i niekonfigurowalne.** `ParamsBuilder::new()` ustawia **wyłącznie**
  `output_len` **[z briefu]** — `t`, `m`, `p` zostają na wartościach domyślnych crate'a.
- **Nie są więc zapisane w nagłówku.** Konsekwencja jest praktyczna: udostępnienie parametrów
  wymaga **i** zmiany w `key.rs`, **i** miejsca na nie w slocie — czyli dotyka formatu, ze
  wszystkim, co o zmianach formatu mówi akapit o `R-F10` poniżej.

Hasła **kont** też używają `argon2id` (`redox_users`), ale to inny sekret i inna ścieżka —
nie należy tego mieszać.

Ekran kreatora **nie pokazuje suwaka parametrów KDF**, dopóki parametry nie trafią do slotu:
kontrolka, która niczego nie zmienia, jest gorsza niż jej brak. Pełny plan etapowy jest
w [`ADR-0010`](../adr/0010-encryption-stack.md), nie tutaj.

**d) Koszt złego hasła jest realny i wynika z pętli odblokowania.**
Odblokowanie **iteruje po wszystkich 64 slotach** (`src/header.rs:121` **[z briefu]**). Poprawne
hasło w slocie 0 kosztuje **jedno** wyprowadzenie Argon2id; błędne kosztuje **64**. To jest
asymetria działająca na naszą korzyść przy zgadywaniu — i przeciwko użytkownikowi, który się
pomylił, bo każda pomyłka jest 64× droższa od trafienia. Dwie rzeczy, które z tego wynikają dla
kreatora: (1) monit o hasło musi znieść zauważalną zwłokę po **błędnym** wpisaniu i nie wolno mu
tego interpretować jako awarii; (2) klucz odzyskiwania trafi do **wyższego** slotu, więc jego
użycie będzie wolniejsze niż hasła głównego — i tak trzeba to opisać, zamiast tłumaczyć potem
zgłoszenie „klucz odzyskiwania się zawiesza".

**e) W tej samej pętli jest ścieżka paniki — to fakt o stanie obecnym, nie propozycja.**
`slot.cipher(password).unwrap()` z komentarzem `//TODO: handle errors` (`src/header.rs:121`
**[z briefu]**). Panika przy odblokowaniu roota nie ma gdzie się wyświetlić i wygląda dla
użytkownika jak martwy komputer. `ADR-0010` prowadzi to jako **Etap 0** (`DO ZBUDOWANIA`, `S`);
kreator nie może tego naprawić, ale **musi** to uwzględnić w §9.1 jako klasę „błąd środowiskowy
poza zasięgiem kreatora".

### 5.4 Kaskada szyfrów — dlaczego odradzamy, a nie tylko „nie mamy"

**Znacznik: NOWY PODSYSTEM (`XL`).** Wymaga: warstwy blokowej (§5.1) + drugiej implementacji
szyfru (Serpent/Twofish nie ma w drzewie) + wsparcia w bootloaderze.

Ale nawet gdyby istniała, jest to zły wybór i trzeba to powiedzieć:

- **Chroni przed jednym zdarzeniem: kryptoanalitycznym złamaniem AES.** Takiego zdarzenia nie
  ma, a gdyby było, to znacznie wcześniej przewróciłoby cały łańcuch zaufania E-OS (podpisy,
  repozytorium, TLS), a nie tylko dysk.
- **Nie chroni przed niczym z listy realnych zagrożeń** z `docs/security/threat-model.md` §3: działający
  system, DMA bez IOMMU, podmieniony bootloader, słabe hasło.
- **Kosztuje** ~2× pracy CPU na każdy sektor i — przy Serpencie bez akceleracji — prognozowane
  **10–15× spadku przepustowości** (założenia P1+P2, §5.2).
- **Podwaja powierzchnię kodu kryptograficznego w TCB** w systemie, który
  `docs/guides/encryption.md` opisuje jako **nieaudytowany przez stronę trzecią**. Dwa nieaudytowane
  szyfry to nie dwa razy więcej bezpieczeństwa, tylko dwa razy więcej miejsc na błąd
  implementacyjny.

Rekomendacja kreatora, gdyby opcja kiedyś istniała: **domyślnie wyłączona, opisana tym akapitem**.

### 5.5 Szyfrowany `/boot` — tu akurat jesteśmy dalej niż zamówienie zakłada

**Znacznik: JEST — w części, która ma znaczenie.** To jedyna pozycja z listy, gdzie E-OS wypada
lepiej niż typowy linuksowy domyślny układ, i warto to powiedzieć tak samo głośno jak braki.

E-OS **nie ma osobnej partycji `/boot`**. Jądro i initfs leżą **wewnątrz szyfrowanego
RedoxFS**, a bootloader je stamtąd wyjmuje po odblokowaniu:

> bootloader pyta `RedoxFS password (1/10):`, odblokowuje AES-XTS RedoxFS, **ładuje z niego
> jądro** i dochodzi do `eos login:` — zweryfikowane end-to-end na aarch64 i x86_64 pod UEFI
> (`docs/guides/encryption.md`).

Do tego, od `V2-MS02`/`U-212`, bootloader **weryfikuje podpisem ed25519** jądro i initfs, które
ładuje, i odmawia startu po zmianie jednego bajtu (`scripts/eos-boot-verify-proof.sh`
z kontrolą negatywną). Sam bootloader jest podpisany kluczem operatora i Secure Boot jest
udowodniony z kontrolą negatywną (`ADR-0005`, `U-206`, `U-208`).

**Co zostaje jawne — i to trzeba pokazać na ekranie:**

| Element | Stan | Co z tego wynika |
|---|---|---|
| bootloader na ESP | jawny | atak na sam **monit o hasło** jest w modelu zagrożeń (`docs/guides/encryption.md`, „Caveats") |
| ścieżka **BIOS** (nie-UEFI) | stage1/2/3 to surowe sektory, których nic nie uwierzytelnia | podpis jądra jest tam **dowodem manipulacji, nie kotwicą zaufania** (`threat-model.md` §6) |
| tryb **live** | cały obraz wczytywany do RAM **bez weryfikacji** przed pobraniem z niego jądra | dotyczy nośnika instalacyjnego, czyli tego, na którym stoi kreator |
| ~16 sterowników ładowanych z roota po montowaniu | **niepodpisane**, brak IOMMU (`eos-base`, `drivers/acpid/src/acpi.rs:461`: `//TODO (hangs on real hardware): Dmar::init(&this);`) | podmieniony sterownik dostaje DMA — czyli to samo przejęcie, innym plikiem |
| **brak powiązania z TPM / measured boot** | `R-913`, nie istnieje | nie ma anti-evil-maid |

### 5.6 Nagłówek odłączony na nośniku wymiennym

**Znacznik: NOWY PODSYSTEM (`L`).**

Wymaga: (a) rozdzielenia nagłówka RedoxFS od danych w formacie na dysku; (b) **nowej ścieżki
wykrywania urządzeń w bootloaderze** — bootloader musiałby przed odblokowaniem przeskanować
drugi nośnik. Bootloader jest najkruchszym elementem tego systemu (`R-F10`: przez lata używał
innej wersji RedoxFS; `docs/guides/encryption.md`: panikował na szyfrowanym roocie zamiast pytać
o hasło). Dokładanie tam wykrywania USB przed odblokowaniem to praca w najgorszym możliwym
miejscu.

**Przed czym chroni:** przed tym, że na dysku **widać**, iż jest tam szyfrowany RedoxFS.
**Przed czym nie chroni:** dysk pełen danych o wysokiej entropii i tak wygląda jak dysk pełen
danych o wysokiej entropii. Chowa **etykietę**, nie **fakt**.
**Utrata klucza:** utrata nośnika z nagłówkiem = **całkowita utrata danych**, nawet przy znanym
haśle. To jest jedyna opcja z tej listy, która **dodaje** nowy sposób bezpowrotnej utraty danych,
i kreator musiałby to napisać w pierwszym zdaniu, nie w przypisie.

### 5.7 Sposoby odblokowania — FIDO2 i TPM2

**FIDO2 — NIEREALNE DZIŚ.** Nie chodzi tylko o brak stosu CTAP2/`hmac-secret` w systemie.
Blokada jest twardsza: klucza używa się **przy rozruchu, w bootloaderze**, czyli **przed
uruchomieniem jakiegokolwiek sterownika**. Bootloader musiałby mieć własny stos USB HID i własną
implementację CTAP2. `usbhidd` w systemie nic tu nie pomaga — on startuje później.

**TPM2 z polityką PCR — NIEREALNE DZIŚ.** `ROADMAP.md` §8.4 mówi wprost o TPM 2.0
i measured boot: *„nie istnieje; piąta warstwa zaufania z `docs/reference/keys-and-tokens.md` wciąż pusta"*
(`R-913`). Brakuje sterownika TPM, brakuje dziennika zdarzeń TCG, brakuje pomiarów w bootloaderze
— a polityka PCR bez pomiarów jest polityką nad pustym zbiorem. To jest **cały łańcuch**, nie
jedna funkcja.

**Klucz odzyskiwania — DO ZBUDOWANIA (`M`) i to jest priorytet.** Dziś jedynym sekretem
chroniącym dysk jest hasło i **nie ma żadnej drogi powrotu** (`docs/guides/encryption.md`: *„there is
no key-escrow or auto-unlock (by design)"*). Zapomniane hasło = utracone dane. Drugi slot klucza,
zapisany jako wysokoentropijny ciąg pokazany **raz** na ekranie S10 z żądaniem przepisania go
z powrotem (dowód, że został zapisany), jest funkcją o największym stosunku wartości do kosztu
w całej tej sekcji.

**Format na dysku już to dopuszcza — brakuje wyłącznie narzędzi.** Nagłówek ma **64 sloty**
(`src/header.rs:31` **[z briefu]**), więc drugie hasło, plik klucza i klucz odzyskiwania nie
wymagają zmiany formatu. To jest korekta wcześniejszej wersji tej sekcji, która pytała
**[NIEZWERYFIKOWANE]**, „czy `KeySlot` już jest liczbą mnogą" — jest, i to zmienia znacznik
z „NOWY PODSYSTEM w formacie" na **DO ZBUDOWANIA w narzędziach**. `ADR-0010` §2 notuje tę samą
korektę i prowadzi ją jako Etap 1.

**Bramka, bez której to jest kartka papieru bez pokrycia:** wygenerowany klucz odzyskiwania musi
zostać **użyty do odblokowania** w tym samym przebiegu testowym, a przypadek negatywny (błędny
klucz) **odrzucony**. Bez kontroli negatywnej „klucz zapisany" znaczy tylko „ciąg wyświetlony".

**Czego w rejestrze brakuje i czego ten dokument nie zakłada:** nie ma pozycji `R-*` na
**zarządzanie slotami klucza woluminu** (klucz odzyskiwania, wiele haseł, plik klucza, kopia
nagłówka). `ADR-0010` §4 nazywa tę lukę i wskazuje naturalne miejsce — domknięty epik `R-5xx`.
**Numer nadaje `ROADMAP.md`**, nie ten dokument i nie ADR.

### 5.8 Wolumin ukryty i plausible deniability — realne ograniczenia

**Znacznik: NIEREALNE DZIŚ.** I nawet gdyby było realne, sprzedawanie tego jako ochrony byłoby
nieuczciwe. Poniżej ograniczenia, które obowiązują **niezależnie od systemu operacyjnego** —
łącznie z tymi, które je oferują:

1. **Ślady poza dyskiem.** Kopie zapasowe, obrazy z chmury, kopie plików na innych nośnikach,
   dzienniki routera, historia zakupów nośnika. Ukryty wolumin chroni jeden dysk, nie życie.
2. **Ślady w systemie gospodarza.** Listy ostatnio otwartych plików, miniatury, pliki tymczasowe,
   pamięć wymiany. E-OS nie ma dziś **żadnego** mechanizmu bezpiecznego kasowania (§6.5.2), więc
   ślad zostaje.
3. **SSD i NVMe niweczą założenie o nadpisaniu.** Wear-leveling i nadmiarowa pojemność (OP)
   powodują, że „nadpisany" sektor fizycznie nadal istnieje w innym miejscu kości. Bez komendy
   administracyjnej urządzenia (której E-OS nie ma, §4.2) nie da się tego kontrolować.
4. **Sam kod zdradza funkcję.** Bootloader, który potrafi otworzyć ukryty wolumin, **zawiera
   kod do otwierania ukrytego woluminu**. Jest publiczny, podpisany i możliwy do sprawdzenia.
   Przeciwnik, który widzi E-OS, wie, że funkcja istnieje — więc „to jest zwykły dysk" nie jest
   już wiarygodne.
5. **Statystyka wolnego miejsca.** Ukryty wolumin żyje w „wolnym miejscu" zewnętrznego. Zapis do
   zewnętrznego niszczy ukryty; ochrona przed tym jest widoczna w zachowaniu wolnego miejsca.
   Wielokrotne migawki tego samego dysku ujawniają zmiany w obszarze deklarowanym jako pusty.
6. **Model zagrożenia jest ludzki, nie techniczny.** Przy przymusie fizycznym albo prawnym
   (jurysdykcje, w których odmowa podania hasła jest sama w sobie karalna) przeciwnik nie
   analizuje dysku — pyta dalej. Deniability nie kończy przesłuchania.

**Stanowisko:** ta funkcja nie trafia do kreatora nawet jako „wyszarzona, wkrótce". Jeżeli
kiedykolwiek powstanie, ekran musi zaczynać się od listy powyżej, a nie od pola hasła.
Alternatywa uczciwa i tania: **osobny nośnik, fizycznie oddzielony**, o którym istnieniu decyduje
człowiek, a nie format nagłówka.

### 5.9 Co ekran S5 pokazuje w wersji do zbudowania

Trzy opcje, nie trzynaście:

```
  (•) Zaszyfruj dysk hasłem                          [ZALECANE dla wszystkich profili]
      RedoxFS AES-XTS-128, klucz z hasła (argon2).
      Chroni: dane na wyłączonym, zgubionym lub skradzionym sprzęcie.
      NIE chroni: przed nikim, kto ma dostęp do działającego systemu; nie ma
        powiązania z TPM ani Secure Bootem, więc bootloader jest jawny i atak na
        sam monit o hasło jest w modelu zagrożeń.
      Jeśli zapomnisz hasła — danych nie odzyska nikt. Nie ma furtki.
      Kryptografia E-OS nie przeszła audytu strony trzeciej (pre-1.0).

  ( ) Zaszyfruj + wygeneruj klucz odzyskiwania       [DO ZBUDOWANIA — ADR-0010 Etap 1;
                                                      pozycji R-* na sloty klucza rejestr
                                                      jeszcze nie ma, patrz §5.7]
  ( ) Bez szyfrowania                                [odradzane; wymaga potwierdzenia]
```

Pozycje niedostępne **nie są ukrywane** — są wypisane w rozwijanym „Czego E-OS dziś nie ma"
z jednozdaniowym powodem każda (LUKS2, kaskada, TPM2, FIDO2, wolumin ukryty). Ukrywanie braków
sprawia, że użytkownik zakłada, iż ich nie potrzebuje.

---

## 6. Profile użycia

Schemat danych — pola, typy, wersjonowanie, walidacja — jest w
[`installer-profiles.md`](installer-profiles.md). Tutaj: **co profil znaczy i jak się zachowuje**.

### 6.1 Definicja

**Profil to nazwana, wersjonowana wiązka: ustawień + pakietów + usług + reguł hartowania,
przechowywana jako dane, nie jako kod.** Warunki, które muszą być spełnione, żeby to zdanie
było prawdziwe:

1. **Profil nie zawiera logiki.** Żadnych warunków, żadnych skryptów. Wszystko, co profil chce
   „zrobić", jest deklaracją wartości funkcji z §7.
2. **Profil jest wersjonowany dwoma numerami:** wersją **schematu** (kompatybilność formatu)
   i wersją **treści** (co ktoś zmienił). Instalacja zapisuje oba do
   `/var/log/eos-setup/answers.toml`.
3. **Profil da się zastosować w całości albo wcale.** Częściowo zastosowany profil to stan,
   którego nikt nie opisał, więc nie istnieje.
4. **Każde ustawienie profilu jest odwracalne w kreatorze** (S6) i widoczne w diffie (S8).

**Znacznik dla mechanizmu profili: DO ZBUDOWANIA (`L`).** Nic tu nie wymaga nowego podsystemu —
wymaga formatu danych, czytnika i dyscypliny. **Znaczniki dla poszczególnych *zawartości*
profili są różne** i to jest sedno §6.3–§6.5.

### 6.2 Dziedziczenie i kompozycja — z pułapką, która już raz ugryzła

**Sam mechanizm dziedziczenia w konfiguracji instalatora: JEST.** `config/x86_64/eos.toml:7`
i `config/aarch64/eos.toml:4` to `include = ["../desktop.toml"]`, a `config/` ma gotowy zestaw
warstw: `base.toml`, `minimal.toml`, `desktop.toml`, `desktop-minimal.toml`, `server.toml`,
`dev.toml`. Zamówienie „profil dziedziczy po bazowym i nadpisuje go" opisuje więc rzecz, która
**już działa** — na poziomie plików. **Czego nie ma:** scalania **decyzji** zamiast plików,
blokad („tego nie wolno nadpisać") i wykrywania kolizji. To jest `R-603c+` w `ROADMAP.md` §6.4.

Profil kreatora dziedziczy analogicznie: `bazuje_na = "business"`. Rozstrzyganie: **głębokie,
kluczowane scalanie**, nie konkatenacja list.

To nie jest szczegół. Dzisiejszy `redox_installer` scala konfiguracje **konkatenacją bez
deduplikacji**:

> `Config::merge` → `self.files.extend(other_files)` — brak deduplikacji, wygrywa ostatni wpis
> na dysku (`docs/reference/known-issues.md`).

Kosztowało to `R-F08`: `desktop.toml` włącza `desktop-minimal.toml` **i** `server.toml`, oba
ciągną `minimal.toml`, więc stara definicja `30_console` z `inputd -A 2` lądowała **po** poprawionej
i wygrywała — pulpit tracił fokus na rzecz konsoli tekstowej. Diagnoza zajęła osobne śledztwo.

**Wymagania wynikające z tego doświadczenia:**

| Wymaganie | Powód |
|---|---|
| Scalanie **kluczowane** po `path` dla plików i po nazwie dla pakietów/usług | konkatenacja daje wynik zależny od kolejności `include` |
| **Wykrywanie kolizji**: dwa profile ustawiają tę samą funkcję na różne wartości → błąd walidacji, nie ciche wygranie ostatniego | cicha wygrana ostatniego = `R-F08` |
| **Diff pochodzenia**: przy każdej wartości w S8 widać, **który profil ją ustawił** | inaczej nie da się debugować własnego profilu |
| Maksymalna **głębokość dziedziczenia: 3**, cykle odrzucane przy wczytaniu | głębsze drzewa są nieczytelne dla człowieka, a to jest funkcja dla ludzi |

### 6.3 Profil **Gamer** — i dlaczego jego główna obietnica jest dziś pusta

Zamówienie: „rozluźnione mitygacje" z ostrzeżeniem i **zmierzonym** kompromisem. Uczciwa
odpowiedź jest niewygodna.

**a) Czego dokładnie miałoby dotyczyć rozluźnienie?**
Mitygacje, które E-OS faktycznie ma, są wypisane w `docs/security/hardening.md` §„Build-time hardening":

| Mitygacja | Gdzie | Czy da się wyłączyć przy instalacji? |
|---|---|---|
| `overflow-checks = true` (jądro, `eos-base`, `relibc`) | profil release | **Nie.** To flaga **kompilacji**. Wyłączenie = inny obraz, nie inny wybór w kreatorze. |
| `panic = "abort"` | profil release | **Nie.** J.w. |
| ASLR przestrzeni użytkownika (`KERNEL_ASLR`) | `eos-kernel`, `find_free_near` | **Może.** Jest bramkowane flagą — **[NIEZWERYFIKOWANE]**, czy to `cfg` kompilacji, czy parametr rozruchu. |
| W⊕X przestrzeni użytkownika (`KERNEL_WX_USER`) | `eos-kernel`, `wx_sanitize` | **Może.** J.w. |
| Pasy ochronne (`ASLR_GUARD_PAGES`) | `eos-kernel` | **Może.** J.w. |

**Co sprawdzić:** w `eos-kernel` — czy `KERNEL_ASLR` / `KERNEL_WX_USER` / `ASLR_GUARD_PAGES` są
odczytywane z parametrów rozruchu, czy rozstrzygane w czasie kompilacji. Jeżeli kompilacji, to
„profil Gamer z rozluźnionymi mitygacjami" **nie jest wyborem instalacyjnym** i kreator nie może
go oferować — musiałby to być osobny wariant obrazu.

**b) Mitygacji, o które ludziom chodzi, w E-OS nie ma.**
Kiedy w świecie Linuksa mówi się „mitigations=off dla FPS", chodzi o mitygacje spekulacyjne CPU:
KPTI, retpoline, IBRS/IBPB, MDS, L1TF. **[NIEZWERYFIKOWANE], ale prawdopodobne, że w `eos-kernel`
nie ma żadnej z nich.** **Co sprawdzić:** `grep -riE "kpti|retpoline|ibrs|ibpb|spec_ctrl|mds|l1tf"`
w `eos-kernel`. Jeżeli wynik jest pusty, to **nie ma czego rozluźniać** — a profil, który obiecuje
zysk z wyłączenia czegoś, czego nie ma, jest po prostu fałszywy.

**c) Zmierzyć się tego dziś nie da — i wiadomo dlaczego.**
`R-930` mówi wprost: podłoża akceleracji GPU 3D/compute **nie ma** (*„`grep vulkan|opengl|GEM|shader` = 0"*).
Nie ma sterownika 3D, nie ma gier, więc nie ma obciążenia, na którym mierzy się FPS ani opóźnienia
wejścia. Do tego cały pomiar w projekcie idzie pod emulacją TCG (~1,9× wolniej, `R-F23`), bo
akceleracja `hvf` wywraca system.

**Czego trzeba, żeby zmierzyć — konkretnie:**
1. Ustalić, że mitygacja jest przełączalna **w czasie rozruchu** (punkt a).
2. Sprzęt fizyczny — `R-607` (macierz instalacji na prawdziwym firmware). Pod TCG wynik nie
   znaczy nic.
3. Obciążenie odniesienia. Bez `R-930` nie ma go w postaci gry; **zastępczo** da się zmierzyć
   coś uczciwie nazwanego: przepustowość `mmap`/`mprotect` (dotyka `wx_sanitize`), czas startu
   procesu, przepustowość I/O. To **nie jest FPS** i nie wolno tego tak nazywać.
4. Metodologia: ≥5 przebiegów, mediana i rozrzut, jedna zmienna naraz.

**d) Co więc profil Gamer zawiera dzisiaj — uczciwie.**
Rzeczy realne i niekontrowersyjne: zestaw pakietów (emulatory, narzędzia), ustawienia pulpitu
(motyw ciemny, brak wygaszacza), brak usług serwerowych, brak wymuszania blokady ekranu.
**Znacznik: DO ZBUDOWANIA (`S`)** dla tej zawartości.
Pozycja „rozluźnione mitygacje": **NIEREALNE DZIŚ do uzasadnienia** — nie z powodu braku kodu,
tylko z powodu braku możliwości pomiaru. Kreator pokazuje ją jako niedostępną z tym zdaniem,
zamiast dawać przełącznik bez liczby obok.

> **Reguła dla całego kreatora:** żaden przełącznik „wydajność kosztem bezpieczeństwa" nie
> pojawia się bez zmierzonej liczby przy nim. Przełącznik bez liczby to zaproszenie do
> obniżenia bezpieczeństwa w zamian za nic.

### 6.4 Profil **Business / Enterprise**

Zawartość i znaczniki:

| Element profilu | Znacznik | Uwaga |
|---|---|---|
| Wymuszone szyfrowanie dysku | **JEST** | `[general] encrypt_disk`, `docs/guides/encryption.md` |
| Wymuszenie mocnego hasła przy pierwszym starcie | **JEST** | `R-602` — zweryfikowane na **każdej** ścieżce logowania (getty, serial, greeter graficzny) |
| Zawężone `login_schemes.toml` dla konta interaktywnego | **JEST jako dane** | `config/base.toml:24+`; gotowy zestaw do usunięcia (`memory`, `irq`, `serio`) w `docs/security/hardening.md` §7 — z zastrzeżeniem autora, że nie jest to boot-weryfikowane pod obecnym harnessem |
| Minimalny zestaw pakietów | **JEST** | mechanizm `[packages]` w konfiguracji instalatora |
| Przypięty klucz repozytorium, weryfikacja podpisu | **JEST** | `R-702` ✅, `V2-MS13`–`V2-MS15`; hasze blake3 sprawdzane przed rozpakowaniem |
| Tożsamość per-maszyna: unikalny hostname, machine-id, klucze SSH hosta | **DO ZBUDOWANIA** | to jest dokładnie `R-606`; dziś każda instalacja to `eos` |
| Konto awaryjne / break-glass | **DO ZBUDOWANIA** (`S`) | finding **C-18** (brak konta awaryjnego) |
| Zapora / filtr pakietów | **DO ZBUDOWANIA** | **`R-904`** — netstack wystawia `ip`/`udp`/`tcp`/`raw` (raw włączony) z **zerowym filtrowaniem**; finding **C-10** |
| Trwały dziennik audytu | **NOWY PODSYSTEM** (`L`) | finding **C-9** — nie ma czego konfigurować, trzeba to napisać |
| Piaskownica aplikacji | **NOWY PODSYSTEM** (`XL`) | finding **C-5**; `recipes/core/contain` istnieje, ale jest **zakomentowany** w `config/server.toml:14` z adnotacją *„needs to update dependencies"* — czyli nie ma go w obrazie |
| Kanał aktualizacji na x86_64 | **DO ZBUDOWANIA** | finding **C-4**; `R-701` — publikacja zrobiona, `50_eos` aktywne **tylko na aarch64** |
| Przyłączenie do domeny / LDAP / Kerberos / centralna polityka | **NIEREALNE DZIŚ** | nie ma ani jednego klocka; to jest ekosystem, nie funkcja |
| Zdalne zarządzanie flotą, MDM | **NIEREALNE DZIŚ** | j.w. |

**Wniosek do napisania na ekranie:** profil Business dostarcza dziś sensowną **stację roboczą
z szyfrowanym dyskiem i zawężonymi uprawnieniami**. Nie dostarcza niczego, co w słowniku
korporacyjnym znaczy „zarządzalna flota". Nazwa profilu nie może tego sugerować — dlatego
w interfejsie występuje jako **„Stacja robocza (biuro)"**, nie „Enterprise".

### 6.5 Profil **Ghost** — aktywiści, dziennikarze, osoby zagrożone

To jest profil, przy którym nieuczciwość ma najwyższą cenę. Zamówienie mówi wprost: napisz,
przed czym **nie** chroni.

#### 6.5.1 Co profil realnie daje

| Element | Znacznik |
|---|---|
| Szyfrowanie dysku wymuszone, bez opcji pominięcia | **JEST** |
| Minimalny zestaw pakietów (mniej kodu = mniejsza powierzchnia) | **JEST** |
| Najostrzejsze `login_schemes.toml` | **JEST jako dane** |
| Brak usług nasłuchujących; `openssh` niezainstalowany | **JEST** (`[packages]`) |
| Wymuszone hasło przy pierwszym starcie | **JEST** (`R-602`) |
| Brak zapisanego pliku odpowiedzi na zainstalowanym systemie | **DO ZBUDOWANIA** (`S`) — profil wyłącza zapis z §13.4 |

#### 6.5.2 Przed czym ten profil NIE chroni — lista pełna

| Brak | Znacznik | Konsekwencja dla osoby zagrożonej |
|---|---|---|
| **Tor** | **NOWY PODSYSTEM** (`XL`) | ruch sieciowy jest przypisywalny do adresu IP; nic tego nie ukrywa |
| **VPN / WireGuard** | **NOWY PODSYSTEM** (`L`) | wymaga urządzenia tunelowego, którego w netstacku nie ma. **[NIEZWERYFIKOWANE]** — **co sprawdzić:** czy netstack (`smoltcp`) w `eos-base` wystawia jakikolwiek interfejs typu tun/tap |
| **Randomizacja adresu MAC** | **DO ZBUDOWANIA** (`M`) | stały adres sprzętowy jest rozgłaszany w każdej sieci, do której się podłączysz — to trwały identyfikator urządzenia. **[NIEZWERYFIKOWANE]** — **co sprawdzić:** czy `e1000d`/`rtl8168d` pozwalają zapisać adres (rejestry RAL/RAH) i czy netstack bierze MAC z konfiguracji |
| **Bezpieczne kasowanie** | **DO ZBUDOWANIA** dla nadpisywania (`M`) / **NOWY PODSYSTEM** dla kasowania sprzętowego (`L`) — **`R-815`** | usunięty plik jest odzyskiwalny. W obrazie **nie ma żadnego narzędzia do kasowania**; w drzewie są dwie receptury WIP i żadna nie jest w konfiguracji: `recipes/wip/storage/wiper` (`#TODO not compiled or tested`, źródło `github.com/ikebastuz/wiper` — **[NIEZWERYFIKOWANE]**, czy to w ogóle narzędzie do nadpisywania, czy przeglądarka zajętości dysku, na co wskazuje nazwa upstreamu) i `recipes/wip/storage/bleachbit` (`#TODO test`). **Nadpisywanie i tak nie wystarcza na SSD/NVMe** (wear-leveling) — potrzebna jest komenda urządzenia (`nvme format --ses`, ATA Secure Erase), czyli ten sam brakujący kanał administracyjny co przy SMART (§4.2) |
| **Zapora** | **DO ZBUDOWANIA** (`R-904`) | zero filtrowania pakietów; `raw` włączony |
| **Piaskownica aplikacji** | **NOWY PODSYSTEM** (C-5) | jedna przejęta aplikacja ma pełne uprawnienia użytkownika, w tym dostęp do jego plików |
| **Dziennik audytu** | **NOWY PODSYSTEM** (C-9) | po incydencie nie da się ustalić, co się stało |
| **IOMMU / izolacja DMA** | **NOWY PODSYSTEM** (`XL`) | podłączone urządzenie może czytać i zapisywać **dowolny** adres fizyczny — w tym pamięć jądra. Potwierdzone: `eos-base`, `drivers/acpid/src/acpi.rs:461` `//TODO (hangs on real hardware): Dmar::init(&this);`, a w `eos-kernel` zero plików z `iommu`/`smmu`/`dmar` (`threat-model.md` §6, `U-187`). **To dotyczy wprost scenariusza „ktoś podłączył coś do twojego laptopa"** |
| **Szyfrowanie pamięci / ochrona przed cold-boot** | **NIEREALNE DZIŚ** | klucz jest w RAM działającego systemu |
| **Measured boot / anti-evil-maid** | **NIEREALNE DZIŚ** (`R-913`) | podmieniony bootloader może przechwycić hasło; Secure Boot chroni przed **niepodpisanym** bootloaderem, nie przed fizycznym dostępem do firmware |
| **Ochrona metadanych w czasie pracy** | **NIEREALNE DZIŚ** | FDE chroni dane w spoczynku; działający system pokazuje wszystko |
| **Anonimowość na poziomie systemu (jak Tails)** | **NIEREALNE DZIŚ** | brak trybu amnezyjnego, brak wymuszonego routingu przez Tor, brak kasowania RAM przy wyłączeniu |
| **Walidacja na fizycznym sprzęcie** | — | **każdy** zielony ptaszek w tym projekcie to QEMU (`ROADMAP.md` §14.1); `R-607` otwarte |
| **Audyt kryptografii przez stronę trzecią** | — | `docs/guides/encryption.md`: *„E-OS has not had a third-party cryptographic audit"* |

#### 6.5.3 Zdanie, które kreator musi wyświetlić

Nie w dokumentacji. Na ekranie, przed wyborem profilu Ghost, wielkimi literami nagłówka:

> **Jeżeli od tego wyboru zależy twoje bezpieczeństwo fizyczne lub wolność — nie używaj dziś
> E-OS.** Użyj Tails albo Qubes OS: są dojrzałe, audytowane i zaprojektowane dokładnie do tego.
> Profil Ghost w E-OS zmniejsza powierzchnię ataku typowej stacji roboczej. Nie zapewnia
> anonimowości sieciowej, nie chroni przed przeciwnikiem z fizycznym dostępem do sprzętu
> i nie był nigdy sprawdzony w warunkach, o których mówisz.

Profil pozostaje dostępny — ludzie mają prawo do własnych decyzji. Ale decyzja podjęta bez tej
informacji nie jest decyzją.

### 6.6 Profile własne, eksport i import

| Zdolność | Znacznik | Uwagi |
|---|---|---|
| Utworzenie profilu z bieżących wyborów w S8 | **DO ZBUDOWANIA** (`S`) | zapis tego samego formatu co profile wbudowane |
| Dziedziczenie po profilu wbudowanym | **DO ZBUDOWANIA** (`S`) | §6.2, głębokość ≤3 |
| Eksport do pliku | **DO ZBUDOWANIA** (`S`) | jeden plik TOML, czytelny dla człowieka |
| Import z nośnika | **DO ZBUDOWANIA** (`M`) | **z barierą, patrz niżej** |
| Podpisany profil organizacyjny | **DO ZBUDOWANIA** (`M`) | podpis ed25519 tym samym mechanizmem co `eos-repo-sign`; klucz przypinany jak `R-702` |

**Bariera przy imporcie — obowiązkowa.** Zaimportowany profil to **niezaufane dane**, które
zmieniają ustawienia bezpieczeństwa. Reguły:

1. Import **nigdy nie stosuje się sam**. Zawsze ląduje w S8 jako diff do zatwierdzenia.
2. Diff **wyróżnia osobno** wszystko, co obniża poziom zabezpieczeń względem profilu bazowego —
   nagłówkiem „Ten profil **osłabia** 4 ustawienia", z wypisaniem których.
3. Profil bez podpisu daje ostrzeżenie; profil z podpisem **nieznanego klucza** też — brak
   przypiętego klucza to TOFU, a projekt tę lekcję już odrobił przy `R-702`.
4. Profil **nie może** ustawić pól, których nie ma w schemacie — nieznane klucze są błędem
   wczytania, nie są ignorowane. Ciche ignorowanie nieznanych pól to droga do „profil
   twierdził, że wyłącza X, a kreator tego pola nie znał".

**Tryb porażki:** użytkownik importuje profil od kogoś zaufanego i przeklikuje diff. Bariera
z punktu 2 istnieje właśnie po to, żeby przeklikanie było trudniejsze niż przeczytanie — dlatego
osłabienia są na **osobnym ekranie**, nie w środku długiej listy.

---

## 7. Prowadzona konfiguracja funkcji

### 7.1 Wywiad o przeznaczeniu maszyny (S1)

Trzy do pięciu pytań, po ludzku, bez żargonu. Przykład:

```
  Do czego będzie służyć ta maszyna?
    ( ) Codzienna praca i internet
    ( ) Praca zawodowa z danymi firmowymi
    ( ) Gry i rozrywka
    ( ) Serwer / urządzenie bez monitora
    ( ) Praca wymagająca podwyższonej ochrony

  Czy ktoś poza tobą ma fizyczny dostęp do tej maszyny?
    ( ) Nie   ( ) Czasem (dom, biuro)   ( ) Tak, i to jest problem

  Czy ta maszyna wychodzi z domu?
    ( ) Nie   ( ) Czasem   ( ) Stale
```

**Wynik wywiadu jest rekomendacją, nie decyzją.** Ekran S2 pokazuje:

```
  Proponuję profil: Stacja robocza (biuro)

  Dlaczego:
    • „praca z danymi firmowymi"  → szyfrowanie dysku wymuszone
    • „maszyna wychodzi z domu"   → szyfrowanie + krótszy czas do blokady ekranu
    • „czasem ktoś ma dostęp"     → zawężone uprawnienia konta interaktywnego

  Czego ten profil NIE robi:
    • nie ma zapory (E-OS jeszcze jej nie ma — R-904)
    • nie ma dziennika audytu (C-9)
    • nie łączy się z domeną ani z systemem zarządzania flotą

  [ Przyjmij ]   [ Wybierz inny profil ]   [ Skonfiguruj ręcznie ]
```

Uzasadnienie jest **wyliczeniem reguł, które się odpaliły**, a nie zdaniem napisanym przez
projektanta. Każda linia „→" pochodzi z danych i da się do niej dojść w
[`installer-profiles.md`](installer-profiles.md). Uzasadnienie napisane ręcznie rozjeżdża się
z regułami przy pierwszej zmianie profilu.

### 7.2 Co niesie każda funkcja — semantyka pól

Struktura w [`installer-profiles.md`](installer-profiles.md). Tutaj **znaczenie** i kto tego
używa:

| Pole | Znaczenie | Kto czyta |
|---|---|---|
| `id` | stabilny identyfikator, **nigdy nie zmieniany** — plik odpowiedzi sprzed roku musi się wczytać | kreator, plik odpowiedzi, dokumentacja |
| nazwa naturalna | to, co widzi człowiek; bez skrótów i bez nazw wewnętrznych | kreator, dokumentacja |
| opis działania | **co system robi inaczej**, gdy funkcja jest włączona — mechanizm, nie hasło | kreator, dokumentacja |
| skutki włączenia | cztery osie: **wydajność · prywatność · zgodność · użyteczność**; każda z wartością i **uzasadnieniem** | kreator (ekran szczegółów), S8 |
| skutki wyłączenia | osobne pole, bo „nie włączone" ≠ „nic się nie dzieje" | kreator, S8 |
| zależności / konflikty / implikacje | wejście solvera (§7.3) | solver |
| znaczenie dla modelu zagrożeń | odwołanie do adwersarza z `docs/security/threat-model.md` §3 | S8, ocena ryzyka |
| zalecenie per profil | `zalecane` / `neutralne` / `odradzane` + powód | ekran funkcji |
| **znacznik dojrzałości** | `JEST` / `DO ZBUDOWANIA` / `NOWY PODSYSTEM` / `NIEREALNE DZIŚ` | kreator: czy kontrolka jest aktywna |
| **dowód** | `plik:linia`, nazwa binarki albo pozycja `R-*` | dokumentacja, przegląd |

Dwa ostatnie pola są tym, co odróżnia ten projekt od katalogu życzeń. Kreator **wyświetla
funkcje niedostępne** jako wyszarzone, z powodem i identyfikatorem `R-*` — użytkownik widzi
mapę, nie wyciętą dziurę.

### 7.3 Zależności, konflikty, solver

Trzy relacje: `wymaga` (twarda), `koliduje` (twarda), `implikuje` (miękka — włącza, ale da się
cofnąć ręcznie).

Rozstrzyganie: przejście domknięcia przechodniego z **wykryciem cyklu przy wczytaniu danych**
(cykl w danych = błąd bramki CI, nie błąd u użytkownika). Przy konflikcie kreator **nie wybiera
sam** — pokazuje obie funkcje, kto której wymaga, i pyta.

**Tryb porażki:** solver jest tak dobry jak deklaracje w danych. Funkcja, której autor zapomniał
zadeklarować `wymaga`, przejdzie walidację i zawiedzie **przy zapisie**, czyli po punkcie bez
powrotu. Dlatego: **bramka CI**, która dla każdego profilu wbudowanego przechodzi pełny przebieg
`eos-setup --replay` i sprawdza, że wynikowy `config.toml` się buduje. Deklaracja niesprawdzona
przebiegiem jest deklaracją.

### 7.4 Jedno źródło prawdy dla opisów i dokumentacji

Wymóg z zamówienia: opisy funkcji siedzą w tych samych plikach danych co funkcje, z i18n, żeby
kreator i dokumentacja czytały z jednego miejsca.

**Realizacja:**
1. Dane funkcji w `/usr/share/eos/setup/features/*.toml` (i w repo pod `config/setup/features/`).
2. Teksty **nie są wpisane w dane** — dane trzymają **klucze i18n**, teksty żyją
   w `i18n/<lang>.toml` (§10).
3. Strona dokumentacji `docs/setup-features.md` jest **generowana** z tych samych plików przez
   `scripts/gen-setup-docs.py` (**DO ZBUDOWANIA**, `S`) — **to jest `R-608a`**, nie nowa pozycja.
   Nowa strona musi też trafić do `docs/SUMMARY.md`, inaczej mdBook ją zignoruje (`CLAUDE.md` §2).
4. **Bramka CI:** regeneracja i `diff` — rozjazd = czerwony pipeline. To ten sam wzorzec co
   istniejąca bramka `docs-currency` (`.gitlab-ci.yml:80`).

**Jak ta kontrola zawodzi:** ktoś edytuje wygenerowany plik ręcznie i „naprawia" bramkę,
dopisując wyjątek. Zabezpieczenie: wygenerowany plik ma w pierwszej linii nagłówek
`<!-- GENEROWANE z config/setup/features/ — nie edytuj ręcznie -->`, a bramka sprawdza obecność
tego nagłówka **osobno** od porównania treści. Druga porażka: klucz i18n bez tłumaczenia —
patrz §10.

### 7.5 Ekran S8 — podsumowanie i diff

Cztery bloki, w tej kolejności:

**Blok 1 — Co zostanie zniszczone.** Powtórzenie §4.3. Na górze, zawsze, bez zwijania.

**Blok 2 — Co zostanie zainstalowane.** Dysk, układ partycji, szyfrowanie, konta, hostname,
strefa, układ klawiatury, liczba pakietów, profil (nazwa + wersja treści).

**Blok 3 — Diff wobec profilu.** Tylko to, co odbiega od czystego profilu, z pochodzeniem:

```
  Odstępstwa od profilu „Stacja robocza (biuro)" (wersja treści 3):
    ~ Blokada ekranu po bezczynności   10 min → wyłączona     (twoja zmiana)
    + Serwer SSH                        wyłączony → włączony  (twoja zmiana)
    ~ Uprawnienia konta                 zawężone → domyślne   (profil „moja-firma")
```

**Blok 4 — Najryzykowniejsze wybory.** Maksymalnie **pięć** pozycji, uporządkowanych, każda
z jednym zdaniem konsekwencji i przyciskiem „Cofnij tę decyzję":

```
  1. Dysk nie będzie zaszyfrowany — każdy, kto weźmie ten dysk, odczyta wszystko.  [Cofnij]
  2. Serwer SSH będzie działał — E-OS nie ma zapory (R-904), więc będzie widoczny
     dla całej sieci, do której się podłączysz.                                     [Cofnij]
  3. Blokada ekranu wyłączona — odejście od maszyny zostawia otwartą sesję.         [Cofnij]
```

**O „ocenie bezpieczeństwa": jedna liczba, ale nigdy jako argument.**
Pokazujemy ją, bo ludzie porównują konfiguracje i liczba do tego służy. Ale:

- liczba jest **wyliczana z listy nazwanych ryzyk**, każde z jawną wagą w danych, i **klik na
  liczbę pokazuje tę listę** — inaczej jest to wyrocznia;
- pokazywana jest **względem punktu odniesienia** („profil bazowy: 78, twoja konfiguracja: 61"),
  nie jako ocena absolutna;
- **nigdy nie jest zielona.** Maksimum osiągalne dziś to nie jest „bezpiecznie" — to „tyle, ile
  ten system dziś umie", przy braku zapory, piaskownicy, dziennika audytu i IOMMU. Skala kończy
  się na „najlepsze, co E-OS dziś potrafi", i pod spodem jest link do `docs/security/threat-model.md` §6.

**Tryb porażki oceny:** liczba zaczyna żyć własnym życiem — ludzie optymalizują punkty zamiast
bezpieczeństwa, a autorzy profili dobierają wagi pod wynik. Zabezpieczenie: wagi leżą
w **wersjonowanych danych**, zmiana wagi jest widoczna w diffie repozytorium, a blok 4 (lista
konkretnych ryzyk) jest **ważniejszy wizualnie** niż liczba.

---

## 8. Reguły walidacji

Trzy poziomy, wykonywane po **każdej** zmianie:

| Poziom | Zachowanie | Przykłady |
|---|---|---|
| **Błąd** | blokuje przejście dalej | cel mniejszy niż `filesystem_size`+ESP; nieznany rozmiar bloku (§4.6); nieznany klucz w importowanym profilu; cykl zależności; puste hasło przy wymuszonym szyfrowaniu; hostname niezgodny z RFC 1123 |
| **Ostrzeżenie** | wymaga świadomego potwierdzenia | brak szyfrowania; cel wymienny; rozpoznany inny system operacyjny; usługa nasłuchująca przy braku zapory; profil importowany bez podpisu |
| **Informacja** | tylko wyświetlana | prognoza czasu instalacji; liczba pakietów; wybrany układ klawiatury |

Reguły szczegółowe:

1. **Hasła.** Minimum długości + sprawdzenie względem listy najczęstszych — **nie** wymuszanie
   „jedna wielka litera i znak specjalny" (to obniża entropię i zmusza do zapisywania na
   kartce). Wskaźnik siły pokazuje **oszacowaną liczbę prób**, nie „słabe/średnie/mocne".
2. **Hasło szyfrowania ≠ hasło konta** — ostrzeżenie, gdy identyczne: to dwa różne sekrety
   o różnych modelach zagrożeń.
3. **Walidacja jest po stronie rdzenia, nigdy front-endu.** Front-end, który sam waliduje, łamie
   parytet (§2.3).
4. **Każda reguła ma identyfikator** (`V-nnn`) i pojawia się w `Diagnostics` z tym
   identyfikatorem — dzięki temu test parytetu porównuje identyfikatory, nie teksty.
5. **Walidacja końcowa przed S9** przechodzi **cały** zestaw jeszcze raz, na kompletnym stanie.
   Reguły sprawdzane tylko przy zmianie pola nie łapią sprzeczności wprowadzonej z innej strony.

---

## 9. Obsługa błędów i przerwań

### 9.1 Taksonomia

| Klasa | Przykład | Zachowanie |
|---|---|---|
| **Wejściowy** | za krótkie hasło | inline przy kontrolce, bez modala |
| **Środowiskowy** | dysk zniknął, brak sieci przy instalacji online | komunikat + konkretne działanie („podłącz ponownie i naciśnij Odśwież") |
| **Silnika, przed punktem bez powrotu** | brak miejsca | powrót do S3/S4 ze stanem zachowanym |
| **Silnika, po punkcie bez powrotu** | błąd zapisu w połowie | §9.3 |
| **Wewnętrzny** | panika, nieoczekiwany stan | §9.4 |
| **Poza zasięgiem kreatora** | panika **bootloadera** przy odblokowaniu dysku — `slot.cipher(password).unwrap()` z `//TODO: handle errors` w pętli po 64 slotach (`src/header.rs:121` **[z briefu]**) | kreator **nie może** tego obsłużyć: dzieje się przy następnym rozruchu, w innym programie. Może natomiast **nie pogłębiać** — nie zachęcać do haseł, których nie da się wpisać w bootloaderze (§11), i wypisać na S10, jak wygląda pierwsze odblokowanie. Naprawa: `ADR-0010` Etap 0 |

### 9.2 Jak wygląda komunikat

Trzy części, zawsze: **co się stało** (bez kodu błędu jako jedynej treści) · **co to znaczy dla
twoich danych** · **co możesz zrobić teraz**. Pełny błąd techniczny jest w rozwijanym „Szczegóły"
i **da się go skopiować** — bo trafi do zgłoszenia.

Precedens z tego projektu, dlaczego to nie jest kosmetyka: `R-F19` — instalator zgłaszał
`Operation not permitted`, a prawdziwa usterka była w odmontowaniu schematu i **przykrywała wynik
właściwej instalacji**. Komunikat, który nie mówi, na którym etapie coś padło, kosztował miesiące.

### 9.3 Błąd po punkcie bez powrotu

To jest najważniejszy przypadek i musi być rozpisany, bo **na tym etapie dysk jest już
uszkodzony**.

```
  Instalacja przerwała się w trakcie zapisu.

  Stan dysku /scheme/disk/nvme0n1:
    • tablica partycji: ZAPISANA (poprzednia zawartość dysku jest utracona)
    • partycja ESP:     zapisana
    • RedoxFS:          zapisany CZĘŚCIOWO — ten dysk NIE URUCHOMI systemu

  Ten dysk nie jest w stanie używalnym. Możesz:
    [ Spróbuj ponownie od zapisu ]   [ Wybierz inny dysk ]   [ Zapisz dziennik i wyjdź ]

  Co się stało: <jedno zdanie>          [Szczegóły techniczne]
```

**Zasada:** kreator **nie udaje**, że da się cofnąć. Mówi dokładnie, co jest na dysku, bo od tego
zależy, czy użytkownik ma jeszcze czego szukać narzędziami odzyskiwania.

**Kroki są odnotowywane na bieżąco** w `/var/log/eos-setup/run-<ts>.log` w RAM-dysku środowiska
live, żeby po awarii dało się odtworzyć, **do którego kroku doszło**. Dziennik **nie zawiera
haseł ani kluczy** — patrz §11.

### 9.4 Panika i przerwanie przez człowieka

- **Ctrl-C / zamknięcie okna przed S8:** wyjście natychmiast, nic nie zostało zapisane.
- **Ctrl-C po S8:** ignorowane. Zamiast tego jawny przycisk „Przerwij", który prowadzi do
  ekranu z §9.3. Przerwanie zapisu tablicy partycji w losowym momencie jest gorsze niż
  dokończenie i zgłoszenie.
- **Panika kreatora:** przechwycona; wyświetlony ekran z §9.3 ze stanem „nieznany" i wyraźnym
  „traktuj ten dysk jako uszkodzony". Panika, która pokazuje pusty ekran, zostawia człowieka
  bez informacji o dysku.

---

## 10. Dostępność

**Punktem odniesienia jest TUI, nie GUI.** To nie jest ustępstwo — instalacja tekstowa nad
konsolą szeregową działa i jest udowodniona: `R-601` **UDOWODNIONE** (`U-176`), trzy przebiegi
z rzędu, sterowane skryptem po serialu (`scripts/install-smoke-drive.py`).

*(Poprawka wobec wcześniejszej wersji: stało tu „po naprawie GIC w `U-153`, która odblokowała
wejście UART". `U-153` naprawił read-modify-write na rejestrze GIC typu write-one-to-clear, przez
co maskowanie jednej linii INTx maskowało **linię dysku rozruchowego** i boot ginął w initfs —
z wejściem UART nie ma to związku. Odblokowanie ścieżki instalacji przyszło z `R-F19`→`R-F24`,
domkniętych w `U-176`.)*

| Wymóg | Znacznik | Uwaga |
|---|---|---|
| Pełna obsługa z klawiatury, bez myszy, w obu front-endach | **DO ZBUDOWANIA** (`M`) | w GUI **[NIEZWERYFIKOWANE]** — **co sprawdzić:** czy `orbclient`/`orbital` dostarcza kolejność Tab i fokus klawiatury |
| Widoczny wskaźnik fokusu | **DO ZBUDOWANIA** (`S`) | |
| Kontrast tekstu ≥ 4,5:1, elementy interaktywne ≥ 3:1 | **DO ZBUDOWANIA** (`S`) | dotyczy motywu Crimson |
| **Żadna informacja przekazywana wyłącznie kolorem** | **DO ZBUDOWANIA** (`S`) | ostrzeżenia mają ikonę i słowo, nie tylko czerwień |
| Skalowanie tekstu (≥125%, ≥150%) bez utraty treści | **DO ZBUDOWANIA** (`M`) | |
| **Brak limitów czasowych** na jakimkolwiek ekranie | **DO ZBUDOWANIA** (`S`) | wyjątek: 5-sekundowe odliczenie z §4.5, które **opóźnia**, a nie wymusza |
| Praca nad konsolą szeregową (80×24) | **JEST** | ścieżka udowodniona w `R-601` |
| Czytnik ekranu | **NIEREALNE DZIŚ** | brak jakiegokolwiek stosu dostępności i syntezy mowy w Redoksie. Sterownik dźwięku (`ihdad`) istnieje, ale to jest jedyny klocek z całego łańcucha (API dostępności → drzewo semantyczne → TTS → wyjście audio) |
| Alternatywa dla czytnika: **wyjście tekstowe kreatora** | **DO ZBUDOWANIA** (`S`) | `eos-setup --dump-screen` wypisuje bieżący ekran jako czysty tekst na stdout — daje się przekierować do zewnętrznego narzędzia na innej maszynie |
| Powiększenie / wysoki kontrast w środowisku live | **DO ZBUDOWANIA** (`M`) | ustawiane w S0, bo po S0 jest za późno dla osoby, która nie odczytała S0 |

**Uczciwie:** dostępność nie ma tu bramki automatycznej — nie ma czym testować. Zabezpieczeniem
jest lista kontrolna w przeglądzie zmian, przechodzona ręcznie przy każdej zmianie ekranów, plus
wymóg, żeby **każdy ekran dało się przejść wyłącznie klawiaturą pod konsolą szeregową**. To jest
kontrola słaba i tak trzeba ją nazwać.

---

## 11. Lokalizacja

**Stan wyjściowy: żadnej infrastruktury i18n w projekcie nie ma.** To jest zweryfikowane, i to
w sposób, który sam był korektą: `docs/archive/reality-ledger.md` (nota `U-126`) odnotowuje, że wcześniejsza
teza o istniejącej „bramce parytetu i18n" w `CLAUDE.md` była **wymyślona** — `grep` nie znajduje
niczego, nie ma też takiej bramki w `lefthook.yml` ani w CI. Pakiet `gettext` występuje w niektórych
konfiguracjach (`config/server.toml:18`), ale jako zależność portów, nie jako mechanizm dla
własnych aplikacji.

**Znacznik: NOWY PODSYSTEM (`M`). Pozycja: `R-D13`** — założona przez `ROADMAP.md` §6.2 i §6.4
**na podstawie tej sekcji i `installer-profiles.md` §9**, w rodzinie `R-Dxx`, bo brak dotyczy
całej powłoki (`eos-control` ma napisy zaszyte w kodzie), nie samego instalatora. Ten dokument
**nie zakłada dla i18n osobnego numeru**.

| Decyzja | Uzasadnienie |
|---|---|
| Format: płaski TOML `klucz = "tekst"` na język, w `/usr/share/eos/setup/i18n/<lang>.toml` | żadnej nowej zależności; instalator już czyta TOML |
| **Nie gettext**, nie fluent | gettext to `.po`/`.mo` i narzędzia w łańcuchu budowania; fluent to kolejna biblioteka. Kreator ma kilkaset ciągów, nie kilkadziesiąt tysięcy |
| Języki startowe: **polski i angielski** | dokumentacja projektu i tak jest dwujęzyczna (`docs/adr/*` po polsku) |
| **Bramka parytetu kluczy** (`DO ZBUDOWANIA`, `S`) | brak klucza w tłumaczeniu = błąd CI, nie ciche wypadnięcie na angielski |
| Wybór języka na S0, **przed** czymkolwiek innym | osoba, która nie czyta po angielsku, nie może przejść przez ekran wyboru języka po angielsku; S0 pokazuje nazwy języków **w tych językach** |
| Układ klawiatury osobno od języka | są różne; wybór układu wpływa na **wpisywane hasło** — patrz niżej |

**Pułapka, którą trzeba obsłużyć:** hasło szyfrowania wpisane pod jednym układem klawiatury,
a wpisywane przy rozruchu pod innym, **nie odblokuje dysku**. Bootloader pyta o hasło zanim
cokolwiek wczyta konfigurację układu — **[NIEZWERYFIKOWANE]**, jakiego układu używa monit
`RedoxFS password`. **Co sprawdzić:** obsługa klawiatury w `eos-bootloader`, `src/main.rs`.
Do czasu ustalenia kreator **pokazuje wpisywane hasło szyfrowania na żądanie** (przycisk „pokaż")
i ostrzega przy znakach spoza ASCII. To nie jest ozdoba — to jedyna dostępna ochrona przed
bezpowrotną utratą danych z powodu układu klawiatury.

---

## 12. Telemetria

**Polityka: brak. Nie „opt-in" — brak.**

| Reguła | Egzekwowanie |
|---|---|
| `eos-setup` nie wykonuje **żadnego** połączenia sieciowego | bramka CI: analiza symboli/`grep` po API sieciowym w skrzynce kreatora; test uruchamiający kreator ze **schematami sieciowymi poza przestrzenią nazw** (`login_schemes.toml` potrafi to wyrazić) — kreator ma przejść instalację offline **bez ani jednego błędu** |
| Jedyny dopuszczalny ruch sieciowy w czasie instalacji to **pobranie pakietów** z podpisanego repozytorium E-OS | to jest `R-605`; domyślnie **wyłączone** — domyślną ścieżką pozostaje offline live-clone |
| Dzienniki (`/var/log/eos-setup/`) **nie zawierają** haseł, kluczy, numerów seryjnych ani identyfikatorów sprzętu | filtr przy zapisie + test jednostkowy przepuszczający syntetyczne sekrety przez logger |
| Dziennik **nie jest nigdzie wysyłany**; zgłoszenie błędu to świadome działanie człowieka | brak jakiegokolwiek mechanizmu wysyłki w kodzie |

**Dlaczego nie „opt-in":** opt-in wymaga zbudowania i utrzymania punktu odbiorczego, polityki
retencji i procedury usuwania danych. Projekt ma dziś **jednego opiekuna**, nie ma dziennika
audytu (C-9) i nie ma zasobów na obsługę danych osobowych. Zbieranie telemetrii, której nie da
się porządnie chronić, jest gorsze niż jej brak. Jeżeli kiedyś powstanie — będzie miała własne
ADR i własny model zagrożeń, a nie pole wyboru w kreatorze.

**Tryb porażki tej polityki:** zależność wciągnięta do kreatora „przy okazji" robi połączenie
(np. sprawdzenie certyfikatów, DNS). Dlatego bramką jest **test przy odciętej sieci**, a nie
przegląd kodu — przegląd nie widzi tego, co robi zależność zależności.

---

## 13. Plik odpowiedzi i tryb nienadzorowany

### 13.1 Punkt wyjścia — to już częściowo działa

**Znacznik: JEST (w ograniczonym zakresie). Pozycja rozszerzenia: `R-609b`.**
`redox_installer <diskpath.img> [--config=file.toml] [--write-bootloader[=PATH]] [--live]`
(`src/bin/installer.rs` **[z briefu]**) **jest** instalacją nienadzorowaną sterowaną plikiem;
`--skip-partition` / `general.skip_partitions` pomija zapis tablic GPT. `[general] encrypt_disk = "…"`
włącza pełne szyfrowanie nieinteraktywnie.

> **Uwaga o dwóch składniach — domknięta.** `docs/getting-started/install.md` §3 podawało
> `redox_installer <config.toml> <disk>`. To była przestarzała forma i przypadek `R-608`
> (dokumentacja rozjechana z binarką), a nie druga dopuszczalna składnia. Kreator generuje plik
> dla formy z `--config=`. **Poprawione 2026-08-31 w `R-608`**, po zmierzeniu w przypiętej
> rewizji instalatora `74726c889b`: `src/bin/installer.rs:208` bierze `parser.args.first()`
> jako ścieżkę przekazywaną do `install(config, path)`.

**Rozróżnienie, które musi być trzymane konsekwentnie w całym dokumencie:** `redox_installer` to
instalator **budowania** — działa na **pliku obrazu**. Instalacja na goły sprzęt uruchamiana
z nośnika to `installer_tui` / `installer-gui` na maszynie docelowej. Cała luka opisana w §1 i §4
zależy od tego rozróżnienia.

Dzisiejszy format wyraża: `[general]` (`prompt`, `filesystem_size`,
`target`, `encrypt_disk`), `[packages]`, `[[files]]` (`path`, `data`, `mode`, `symlink`,
`directory`, `postinstall`), `[users.*]` (`password`, `uid`, `gid`, `shell`), `[groups.*]`.

Czego **nie** wyraża: wyboru dysku (jest argumentem wiersza poleceń), profilu, funkcji, zgody na
destrukcję, tożsamości per-maszyna.

### 13.2 Rozszerzenie — sekcja `[setup]`

**Znacznik: DO ZBUDOWANIA (`M`). Pozycja: `R-609b`.** Nowa sekcja **obok** istniejących, tak żeby
stary plik dalej działał — i **rozszerzenie istniejącego formatu**, nie drugi równoległy system
konfiguracji; dwa źródła prawdy w tym drzewie mają już swoją cenę (`R-F08`, `U-164`):

- `schema_version` — odrzucenie pliku z nowszym schematem, zamiast zgadywania;
- `profile` + `profile_content_version`;
- `features` — wartości funkcji (tylko odstępstwa od profilu, żeby plik był czytelny);
- `target` — wybór celu **opisowo**, nie po numerze w menu: po numerze seryjnym, gdy będzie
  (§4.2), inaczej po ścieżce schematu + rozmiarze jako kontroli;
- `destructive_consent` — patrz §13.3;
- `identity` — hostname, strefa, układ klawiatury, machine-id (`R-606`);
- `encryption` — metoda i **źródło** hasła (nigdy samo hasło, patrz niżej).

**Sekrety nie trafiają do pliku odpowiedzi.** Dzisiejsze `encrypt_disk = "twoje-hasło"` jest
funkcjonalne, ale zapisuje hasło jawnym tekstem. Rozszerzenie dodaje `encryption.password_source`
= `prompt` (domyślnie) | `file:<ścieżka>` | `stdin`. Wariant z hasłem w pliku pozostaje możliwy dla
zgodności i dla laboratoriów — i **jest oznaczony w kreatorze jako niebezpieczny przy zapisie**.

### 13.3 Zgoda na destrukcję w trybie nienadzorowanym

Tryb nienadzorowany omija warstwy 2 i 3 z §4.5. Zastępuje je jedno pole, które **musi nazwać
cel**:

```toml
[setup.destructive_consent]
erase = "disk/nvme0n1"          # albo numer seryjny, gdy dostępny
size_bytes = 512110190592       # kontrola: nie zgadza się → odmowa
acknowledged_by = "operator-imie"
```

Reguły:
- `--assume-yes` **bez** tej sekcji jest odrzucane. Flaga zgody, która nie nazywa celu, jest
  flagą „skasuj cokolwiek znajdziesz".
- Niezgodność `size_bytes` → odmowa. To łapie przypadek, w którym ścieżka schematu wskazuje na
  inny dysk niż przy tworzeniu pliku — realny scenariusz przy zmiennej kolejności wyliczania.
- Reguły odmowy z §4.6 obowiązują **tak samo** i **nie da się ich wyłączyć flagą**. Reguła, którą
  da się wyłączyć flagą, nie jest regułą.

### 13.4 Wygenerowanie pliku odpowiedzi z przebiegu

Ekran S8 ma „Zapisz te wybory jako plik odpowiedzi". Zapis następuje **przed** zapisem na dysk
(S9), żeby plik istniał także wtedy, gdy instalacja padnie — i żeby dało się powtórzyć dokładnie
ten sam przebieg. Sekrety zastępowane są `password_source = "prompt"`.

Po instalacji plik trafia do `/var/log/eos-setup/answers.toml` w zainstalowanym systemie —
**z wyjątkiem profilu Ghost**, który to wyłącza (§6.5.1), bo taki plik jest dokładnym opisem
konfiguracji bezpieczeństwa maszyny.

### 13.5 Czego ten tryb **nie** obejmuje

Kickstart w świecie linuksowym oznacza także skrypty `%pre`/`%post`. **Nie wprowadzamy ich.**
Skrypt w pliku odpowiedzi zamienia deklaratywne dane w wykonywalny kod z uprawnieniami
instalatora — i unieważnia sensowność podpisywania profili (§6.6), bo podpisany profil
z dowolnym skryptem jest po prostu podpisanym zdalnym wykonaniem kodu. Jeżeli coś ma dziać się
po instalacji, dzieje się to przez **usługę zadeklarowaną w profilu**, którą widać w diffie S8.

---

## 14. Zbiorcze zestawienie znaczników

Wszystkie zamówione zdolności w jednym miejscu.

### Wybór dysku (§4)

| Zdolność | Znacznik | Pozycja |
|---|---|---|
| Wyliczenie dysków ze ścieżką urządzenia | **JEST** | — |
| Rozmiar (silnik go zna, ekran go nie pokazuje), typ interfejsu, wymienność | **DO ZBUDOWANIA** (`S`) | `R-603a` |
| Rzeczywisty rozmiar bloku (4Kn) | **DO ZBUDOWANIA** (`M`) | `R-607a`, wymaga `R-815` |
| Model i numer seryjny | **NOWY PODSYSTEM** (`M`) | **`R-815`** |
| Zdrowie SMART | **NOWY PODSYSTEM** (`L`) | **`R-815`** |
| Istniejące partycje i rozpoznanie systemów | **DO ZBUDOWANIA** (`M`) | `R-604a` |
| Ostrzeżenie o destrukcji + przepisanie identyfikatora | **DO ZBUDOWANIA** (`M`) | `R-604a`, `R-604b` |
| Odmowa niebezpiecznych celów | **DO ZBUDOWANIA** (`M`) | `R-604c` |
| Wypalenie nośnika instalacyjnego na USB przez `dd` | **JEST** | — |
| To samo przez `popsicle` / Ventoy | **[NIEZWERYFIKOWANE]** / **nie działa** (`R-F28`) | `R-611` (`installer.md`) |
| Instalacja na USB jako cel | **DO ZBUDOWANIA** (`S`) | `R-604c` (rozróżnienie źródła i celu) |
| Partycjonowanie ręczne / obok / dual-boot | **DO ZBUDOWANIA** (`XL`) | **`R-609`** / `R-609d` |
| Zmiana rozmiaru NTFS/ext4 pod instalację obok | **NIEREALNE DZIŚ** | nie ma nawet odczytu tych FS |

### Szyfrowanie (§5)

| Zdolność | Znacznik |
|---|---|
| FDE hasłem (AES-XTS-128) | **JEST** |
| Argon2id jako KDF woluminu | **JEST** **[z briefu]** — `src/key.rs` |
| 64 sloty klucza w formacie na dysku | **JEST** **[z briefu]** — `src/header.rs:31` |
| Obsługa błędów zamiast paniki przy odblokowaniu (`slot.cipher(...).unwrap()`) | **DO ZBUDOWANIA** (`S`) — `ADR-0010` Etap 0 |
| Migawka woluminu / cofnięcie instalacji | **NOWY PODSYSTEM** — RedoxFS **nie ma API migawek** **[z briefu]** |
| Szyfrowany `/boot` (jądro i initfs w szyfrowanym woluminie) | **JEST** |
| Weryfikacja podpisu jądra i initfs przez bootloader | **JEST** (`V2-MS02`) |
| Konfigurowalny szyfr woluminu | **DO ZBUDOWANIA** (`M`) |
| Konfigurowalne parametry Argon2id woluminu | **DO ZBUDOWANIA** (`S`–`M`) |
| Klucz odzyskiwania (drugi slot) | **DO ZBUDOWANIA** (`M`) |
| Plik klucza | **DO ZBUDOWANIA** (`M`) |
| Nagłówek odłączony | **NOWY PODSYSTEM** (`L`) |
| Kaskada szyfrów (AES + Serpent/Twofish) | **NOWY PODSYSTEM** (`XL`) — odradzane |
| Zgodność z formatem LUKS2 | **NIEREALNE DZIŚ** |
| LUKS na LUKS | **NIEREALNE DZIŚ** |
| FIDO2 | **NIEREALNE DZIŚ** |
| TPM2 z polityką PCR | **NIEREALNE DZIŚ** — `R-913` |
| Wolumin ukryty / plausible deniability | **NIEREALNE DZIŚ** — i odradzane jako iluzja |

### Profile i funkcje (§6–§7)

| Zdolność | Znacznik |
|---|---|
| Profile jako wersjonowane dane | **DO ZBUDOWANIA** (`L`) |
| Dziedziczenie, eksport, import | **DO ZBUDOWANIA** (`M`) |
| Podpisany profil organizacyjny | **DO ZBUDOWANIA** (`M`) |
| Profil Gamer — zawartość (pakiety, pulpit) | **DO ZBUDOWANIA** (`S`) |
| Profil Gamer — „rozluźnione mitygacje" | **NIEREALNE DZIŚ do uzasadnienia** (brak pomiaru, `R-930`, `R-607`) |
| Profil Business — szyfrowanie, uprawnienia, minimalny zestaw | **DO ZBUDOWANIA** (`M`), składniki **JEST** |
| Profil Business — tożsamość per-maszyna | **DO ZBUDOWANIA** — `R-606` |
| Profil Business — zapora | **DO ZBUDOWANIA** — `R-904` |
| Profil Business — dziennik audytu | **NOWY PODSYSTEM** — C-9 |
| Profil Business — piaskownica | **NOWY PODSYSTEM** — C-5 |
| Profil Business — domena / LDAP / MDM | **NIEREALNE DZIŚ** |
| Profil Ghost — zawartość realna | **DO ZBUDOWANIA** (`M`) |
| Ghost — Tor | **NOWY PODSYSTEM** (`XL`) |
| Ghost — VPN | **NOWY PODSYSTEM** (`L`) |
| Ghost — randomizacja MAC | **DO ZBUDOWANIA** (`M`) |
| Ghost — bezpieczne kasowanie (nadpisanie) | **DO ZBUDOWANIA** (`M`) |
| Ghost — bezpieczne kasowanie (komenda urządzenia) | **NOWY PODSYSTEM** (`L`) |
| Ghost — tryb amnezyjny / anonimowość systemowa | **NIEREALNE DZIŚ** |
| Wywiad + rekomendacja z uzasadnieniem | **DO ZBUDOWANIA** (`M`) |
| Opisy funkcji jako jedno źródło prawdy + generowanie docs | **DO ZBUDOWANIA** (`M`) |
| Ekran diff + ocena ryzyka + lista najryzykowniejszych wyborów | **DO ZBUDOWANIA** (`M`) |

### Reszta (§2, §8–§13)

| Zdolność | Znacznik | Pozycja |
|---|---|---|
| Silnik + trzy front-endy (CLI budowania, TUI, GUI) | **JEST** (istnieją) | — |
| Przeniesienie logiki wyboru dysku z frontendu do biblioteki | **DO ZBUDOWANIA** (`L`) | `R-603a` |
| Bramka parytetu GUI/TUI | **DO ZBUDOWANIA** (`S`) | `R-601d` |
| Przepływ live → greeter → GUI → instalacja, przetestowany | **DO ZBUDOWANIA** (`L`) | `R-D08` |
| Maszyna stanów, walidacja, obsługa błędów, S8 z diffem | **DO ZBUDOWANIA** (`L`) | `R-603b`, `R-604b`, `R-604d` |
| Walidator profili i funkcji (`bad` vs `cannot`) | **DO ZBUDOWANIA** (`M`) | `R-609a` |
| Dostępność klawiaturowa i tekstowa | **DO ZBUDOWANIA** (`M`) | brak pozycji — patrz §15 |
| Czytnik ekranu | **NIEREALNE DZIŚ** | — |
| Lokalizacja (pl/en) + bramka parytetu kluczy | **NOWY PODSYSTEM** (`M`) | **`R-D13`** |
| Brak telemetrii + bramka odciętej sieci | **DO ZBUDOWANIA** (`S`) | brak pozycji — patrz §15 |
| Plik odpowiedzi / instalacja nienadzorowana | **JEST** częściowo; rozszerzenie **DO ZBUDOWANIA** (`M`) | `R-609b` |

---

## 15. Kolejność wdrożenia i przypięcie do roadmapy

Ten dokument **nie tworzy nowych identyfikatorów**. Rozpisanie zrobiła `ROADMAP.md` §6
(epik **EP-2**, kamienie **M3** i **M4**); poniżej mapowanie sekcja → zadanie, żeby nikt nie
nadał tej samej pracy drugiej nazwy.

| Etap | Praca | Sekcja | Pozycja `R-*` |
|---|---|---|---|
| **1** | Zamknąć przepływ GUI end-to-end (live → greeter → installer-gui → instalacja) | §2.3 | **`R-D08`** — bez tego parytet GUI/TUI jest niesprawdzalny |
| **1b** | Bramka parytetu GUI ↔ TUI | §2.3 | **`R-601d`** |
| **1c** | Logika wyboru dysku z frontendu do biblioteki | §2.1, §2.2 | **`R-603a`** |
| **2** | Identyfikacja dysku, ostrzeżenie o destrukcji, ekran różnicowy przed zapisem | §4.1–§4.4 | **`R-604a`**, **`R-604b`** |
| **2b** | Odmowa niebezpiecznych celów | §4.6 | **`R-604c`** |
| **2c** | Potwierdzenie per osłabienie polityki (import profilu, S8 blok 4) | §6.6, §7.5 | **`R-604d`** |
| **2d** | Rzeczywisty rozmiar bloku (warunek odmowy z §4.6) | §4.1, §4.6 | **`R-607a`**; macierz na metalu: `R-607b` |
| **2e** | Kanał komend administracyjnych do dysków (SMART, IDENTIFY, rozmiar bloku, secure erase) | §4.2, §6.5.2 | **`R-815`** |
| **3** | Maszyna stanów S0–S10, walidacja, S8 z diffem i oceną ryzyka | §3, §7.5, §8, §9 | **`R-603b`** |
| **3b** | Model danych profili i funkcji (typy `serde` + resolver) | §6, §7.2, §7.3 | **`R-603c`**; dziedziczenie z blokadami: `R-603c+` |
| **3c** | Konta, hostname, strefa, układ klawiatury we front-endach (stan S7) | §3.1 | **`R-603d`** |
| **3d** | Tożsamość per-maszyna | §6.4 | **`R-606`** |
| **3e** | Weryfikacja podpisu profilu na urządzeniu | §6.6 | **`R-603e`**, wymaga **`R-711`** (bez keyringu podpis jest nieodwoływalny) |
| **4** | Walidator profili z rozróżnieniem `bad` (zły plik) od `cannot` (system nie umie) | §7.3, §8 | **`R-609a`** |
| **4b** | Dokumentacja generowana z tych samych danych co kreator | §7.4 | **`R-608a`** |
| **4c** | Plik odpowiedzi: sekcja `[setup]`, zgoda na destrukcję, zapis z przebiegu | §13 | **`R-609b`** |
| **4d** | Treść profili Gamer / Business / Ghost — wyłącznie to, co da się dowieźć | §6.3–§6.5 | **`R-609c`** |
| **4e** | Katalog i18n + bramka parytetu kluczy (pl/en) | §11 | **`R-D13`** |
| **5** | Doprowadzić `docs/getting-started/install.md` do zgodności. **Zmierzone dziś:** §2 jest już poprawione (ostrzeżenie o kontach i pakietach, `install.md:58-64`); otwarte zostaje `install.md:78` — przestarzała składnia CLI — oraz nazwa artefaktu (`R-611a`) | §1, §13.1, §16 poz. 3 | **`R-608`** |
| **6** | Ścieżka online z podpisanego repo E-OS, świadoma architektury | §12 | **`R-605`** (`C-4` na x86_64) |
| **7** | Tryby partycjonowania w stanie S4 | §4.8 | **`R-609`** / **`R-609d`** |
| **8** | Przypadki harnessu: FDE, przerwanie, dwa dyski, 4Kn, BIOS | §4.6, §9.3 | **`R-601e`** |
| **Poza** | Zapora jako funkcja profilu | §6.4, §6.5.2 | **`R-904`** (`C-10`) |
| **Poza** | Piaskownica jako warunek bezpiecznego importu profilu | §6.6 | **`R-1010`** (`C-5`) |
| **Poza** | TPM / measured boot jako opcja szyfrowania | §5.7 | **`R-913`** / `V2-N02` |

**Korekta wobec wcześniejszej wersji tej sekcji.** Stała tu teza: *„Jedna nowa praca, która nie
ma dziś pozycji: kanał komend administracyjnych do dysków … kandydat na osobną pozycję w rodzinie
`R-8xx` — do rozstrzygnięcia przy zatwierdzaniu"*. **To już zostało rozstrzygnięte** i pozostawienie
tamtego zdania groziło dołożeniem drugiej nazwy do tej samej pracy. `ROADMAP.md` §6.2 i §6.4
zakładają ją jako **`R-815`** — numer wybrany dlatego, że `R-812`–`R-814` rezerwuje
`docs/architecture/driver-manager.md`. Tak samo i18n z §11 ma już **`R-D13`**. **Żadnej z tych dwóch
nie wolno zakładać ponownie.**

**Czego w rejestrze nadal nie ma** — nazwane, nie ponumerowane, bo numer nadaje `ROADMAP.md`:

1. **Zarządzanie slotami klucza woluminu** (klucz odzyskiwania, wiele haseł, plik klucza, kopia
   nagłówka) — §5.7; lukę nazywa też `ADR-0010` §4 i wskazuje domknięty epik `R-5xx`.
2. **Dostępność** (§10) i **bramka odciętej sieci dla telemetrii** (§12) — nie mają pozycji
   w żadnej rodzinie. To realny brak rejestru, a nie przeoczenie tego dokumentu.

---

## 16. Odrzucone warianty

**1. Zaimplementować LUKS2 na Redoksie.**
Wymagałoby warstwy blokowej z możliwością stosowania, portu dm-crypta, portu cryptsetupa
i obsługi nagłówka LUKS2 w bootloaderze przed montowaniem. To nie jest duży ticket, tylko inny
system operacyjny. **Wybrane zamiast:** rozwijanie nagłówka RedoxFS (§5.3b) — daje **zdolność**
(konfigurowalny szyfr, parametry KDF) bez **formatu**, a wiele slotów klucza format
**już ma** (`[KeySlot; 64]`, §5.7), więc kosztem jest tam wyłącznie narzędzie. Cena, którą płacimy jawnie:
zaszyfrowanego dysku E-OS nie otworzy się linuksowym `cryptsetup`. Trzeba to napisać na ekranie
S5, a nie odkryć przy próbie odzyskiwania danych.

**2. Kreator jako osobna aplikacja obok istniejącego instalatora.**
Kusi, bo nie trzeba ruszać `redox_installer`. Odrzucone: dałoby **dwie** ścieżki instalacji
z dwiema definicjami tego, co się dzieje z dyskiem, a to jest dokładnie ta klasa rozjazdu, która
w `R-F10` przez lata trzymała bootloader na innej wersji RedoxFS niż system. **Wybrane:** kreator
nad istniejącym silnikiem, którego wyjściem jest `config.toml`, który silnik już przyjmuje.

**3. Opisy funkcji w kodzie kreatora, dokumentacja pisana osobno.**
Odrzucone przez precedens: `R-608` powstało z rozjazdu między `docs/getting-started/install.md` a binarką.
**Sprawdzone w drzewie, i część tego precedensu jest już nieaktualna** — to trzeba powiedzieć,
zamiast powtarzać formułę: `docs/getting-started/install.md` §2 **niesie dziś jawne ostrzeżenie**
*„It does not create accounts, and it does not let you pick packages"*, więc zdanie
„§2 opisuje tworzenie kont, którego binarka nie robi" **przestało być prawdziwe**.
Rozjazd, który stąd wynikał — składnia `redox_installer <config.toml> <disk>` zamiast
`redox_installer <diskpath.img> [--config=file.toml]`, oraz nazwa artefaktu — **został
zamknięty 2026-08-31** w `R-608` i `R-611a`. Argument zostaje w mocy, ale stoi
na **zmierzonym** przykładzie, nie na cytacie z pamięci. Dwa źródła prawdy zawsze się rozjadą;
pytanie brzmi tylko, kiedy ktoś to zauważy — i tu odpowiedź brzmi: po tym, jak jedno z nich
zostało po cichu naprawione, a drugie dalej je cytowało.
**Wybrane:** generowanie docs z danych + bramka porównująca (§7.4).

**4. Wolumin ukryty jako „opcja dla zaawansowanych".**
Odrzucone. Funkcja, której gwarancji nie potrafimy dotrzymać, jest gorsza niż jej brak, bo
zmienia zachowanie użytkownika — ktoś zrobi coś ryzykownego, licząc na ochronę, której nie ma.
§5.8 wymienia ograniczenia obowiązujące **nawet w systemach, które tę funkcję mają**.
**Wybrane:** brak funkcji + jawne wyjaśnienie w rozwijanej liście „czego E-OS nie ma".

**5. Telemetria opt-in „żeby wiedzieć, na czym ludzie instalują".**
Wartość jest realna: projekt nie ma **ani jednego** wiersza w macierzy sprzętowej dla E-OS.
Odrzucone mimo to — jeden opiekun, brak dziennika audytu (C-9), brak procedury retencji.
**Wybrane:** ekran S10 proponuje **ręczne** zgłoszenie raportu sprzętowego, z pokazaniem
dokładnej treści przed wysłaniem i wysyłką wykonaną przez człowieka, nie przez system.

**6. Ocena bezpieczeństwa jako jedna liczba bez rozbicia.**
Odrzucone: liczba bez uzasadnienia jest wyrocznią i zaczyna być optymalizowana zamiast
bezpieczeństwa. **Wybrane:** liczba **plus** lista nazwanych ryzyk z wagami w wersjonowanych
danych, przy czym lista jest wizualnie ważniejsza od liczby (§7.5).

**7. Skrypty `%pre`/`%post` w pliku odpowiedzi (pełny kickstart).**
Odrzucone — §13.5. Podpisany profil z dowolnym skryptem to podpisane zdalne wykonanie kodu.

---

## 17. Czego nie udało się zweryfikować

Zebrane w jednym miejscu, z tym, co dokładnie sprawdzić.

| Nr | Niewiadoma | Gdzie sprawdzić |
|---|---|---|
| N1 | Czy sterowniki dyskowe wystawiają jakikolwiek kanał komend administracyjnych (SMART, IDENTIFY, rozmiar bloku) | `eos-base`: `drivers/storage/nvmed/src/**` (`IdentifyController`, `GetLogPage`), `drivers/storage/ahcid/src/**` (`ATA_CMD_IDENTIFY`); protokół schematu dyskowego poza `Read`/`Write` |
| ~~N2~~ | ~~Wariant i parametry KDF woluminu RedoxFS~~ — **ODPOWIEDZIANE, wpis był błędny**: KDF to **Argon2id** (`Version::V0x13`, wyjście 16 B), a parametry są **domyślne i niekonfigurowalne** (`ParamsBuilder::new()` ustawia tylko `output_len`), czyli **nie ma ich w nagłówku**. `src/key.rs` **[z briefu]**, §5.3c | do potwierdzenia na miejscu: `make fstools_fetch`, potem `recipes/core/redoxfs/source/src/key.rs` |
| ~~N3~~ | ~~Czy `KeySlot` jest liczbą mnogą~~ — **ODPOWIEDZIANE, wpis był błędny**: `pub key_slots: [KeySlot; 64]`, `src/header.rs:31` **[z briefu]**. Format dopuszcza wiele haseł, plik klucza i klucz odzyskiwania **już dziś**; brakuje wyłącznie narzędzi (§5.7, `ADR-0010`) | jw.: `recipes/core/redoxfs/source/src/header.rs` |
| N2a | **Która rewizja `eos-redoxfs` jest wiążąca.** Przepis i `repos.toml` przypinają `58824d70a07b…` (`recipes/core/redoxfs/recipe.toml:6`, `repos.toml:67`), a `U-156` (zamknięcie `R-F10`) opisuje `555359ef61`. Fakty z briefu odnoszą się do tego, co leżało w drzewie budowania — **nie umiem stąd powiedzieć, do której** | porównać `git -C recipes/core/redoxfs/source rev-parse HEAD` w drzewie budowania z `repos.toml:67`; `ADR-0010` notuje ten sam rozjazd |
| N4 | Czy `raid1d` wystawia stosowalne urządzenie blokowe, którego RedoxFS mógłby użyć jako celu | `eos-base`: `drivers/storage/raid1d/src/**` |
| N5 | Czy `KERNEL_ASLR`, `KERNEL_WX_USER`, `ASLR_GUARD_PAGES` są przełączalne w czasie **rozruchu**, czy tylko kompilacji | `eos-kernel`: `find_free_near`, `wx_sanitize` i sposób odczytu tych flag |
| N6 | Czy w `eos-kernel` istnieją jakiekolwiek mitygacje spekulacyjne CPU (bez nich „rozluźnione mitygacje" nie mają desygnatu) | `eos-kernel`: `grep -riE "kpti\|retpoline\|ibrs\|ibpb\|spec_ctrl\|mds\|l1tf"` |
| N7 | Czy netstack wystawia interfejs tun/tap (warunek VPN) | `eos-base`: netstack/`smoltcp`, lista schematów |
| N8 | Czy sterowniki sieciowe pozwalają ustawić adres MAC (warunek randomizacji) | `eos-base`: `drivers/net/e1000d` (rejestry RAL/RAH), `rtl8168d`; skąd netstack bierze MAC |
| N9 | Jakiego układu klawiatury używa monit `RedoxFS password` w bootloaderze | `eos-bootloader`: obsługa klawiatury w `src/main.rs` |
| N10 | Czy `orbclient`/`orbital` dostarcza kolejność Tab i widoczny fokus klawiatury (warunek dostępności GUI) | `eos-orbutils`/`orbclient`, obsługa zdarzeń klawiatury |
| N11 | Przepustowość AES-XTS na E-OS — `R-502` mówi „benchmarked", ale w `ROADMAP.md`/`CHANGELOG.md` nie ma żadnej liczby | wymaga pomiaru na fizycznym dysku, po `R-607`; wszystkie liczby w §5.2 są prognozą z założeń P1/P2 |
| N12 | Czy dyski wymienne da się rozpoznać poza ścieżką USB (`usbscsid`) | `eos-base`: rejestracja schematów dyskowych |
| N13 | Treść findings C-4, C-5, C-9, C-10, C-11, C-12, C-18 — cytowane **za briefem**, nie odczytane z gałęzi `fix/p0-audit-findings` (polecenia `git` były w tym przebiegu zabronione) | `docs/audit/03-security-audit-2026-08-30.md` na gałęzi `fix/p0-audit-findings` |
| N14 | **Każdy cytat oznaczony `[z briefu]`** — `disk_paths()`, `choose_disk()`, komentarz `installer_tui.rs:15-17`, `disk_wrapper.rs:28`, `installer.rs:604`, składnia CLI, `key.rs`, `header.rs:31,121`, `clone.rs`, `transaction.rs` — pochodzi z **rozwiniętego drzewa budowania**, nie z tej gałęzi: `recipes/core/{installer,redoxfs}/` zawierają wyłącznie `recipe.toml`. Nie podważam ich; podaję, że nie zostały odczytane tutaj | `make fstools_fetch`, potem `recipes/core/installer/source` i `recipes/core/redoxfs/source`; przy okazji **wpisać numery linii odczytane na miejscu** |
| N15 | Czy `harddrive.img` i `redox-live.iso` niosą realną strukturę ISO 9660. Brief podaje sygnaturę `CD001` pod `0x8001` w obu, a `installer.md` §1.2 pkt 13 twierdzi przeciwnie (*„w drzewie nie ma śladu ISO9660"*). **Dwa dokumenty siostrzane mówią co innego** — to nie zmienia niczego w tym dokumencie (kreator używa `dd`), ale musi zostać rozstrzygnięte przed zatwierdzeniem `installer.md` §2.2 | `xxd -s 0x8000 -l 16 build/x86_64/eos/redox-live.iso`, `file` na obu artefaktach |
| N16 | Czy `popsicle` faktycznie zapisuje artefakt E-OS na USB — cel istnieje w `Makefile`, ale `installer.md:94` mówi, że nigdy nie był testowany | `Makefile:16-17` woła `popsicle-gtk` na hoście; sprawdzić na hoście linuksowym i na fizycznym nośniku (`R-607b`) |
