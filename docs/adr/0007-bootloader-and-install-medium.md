# ADR-0007 — Bootloader nośnika instalacyjnego i systemu zainstalowanego

- **Status:** Propozycja — do zatwierdzenia. Nic z tego nie jest zaimplementowane.
  - Zastrzeżenie do tego zdania, żeby nie wprowadzało w błąd: **decyzja utrwala stan, który
    już działa i jest dowiedziony** (`U-206`–`U-212`). Nowe są wyłącznie pozycje oznaczone
    **DO ZBUDOWANIA** i **NOWY PODSYSTEM** — i to one są propozycją.
- **Data:** 2026-08-30
- **Kontekst:** [`ADR-0005`](0005-secure-boot-without-microsoft.md),
  [`ADR-0006`](0006-path-to-microsoft-verification.md), `V2-N03`, `V2-MS01`, `V2-MS02`,
  `V2-MS04`, `R-604`, `R-607`, `R-609`, `R-707`, `R-710`
- **Dowód:** `U-206`, `U-207`, `U-208`, `U-210`, `U-212`, `U-218`;
  `recipes/core/bootloader/recipe.toml:4-6,24-31,34,73,108,113`;
  `recipes/core/bootloader/sbat.csv` (158 B);
  `scripts/eos-secureboot-proof.sh`, `scripts/eos-boot-verify-proof.sh`;
  `scripts/install-smoke-drive.py:136-153`; `mk/disk.mk:20-35`; `Makefile:16-17`;
  `scripts/make-release.sh:20-49`; `scripts/dual-boot.sh`; `redox.ipxe` (89 B);
  `docs/architecture/system-updates.md` §1.4 (za `installer.rs:565-660`)
- **Zakres:** bootloader nośnika instalacyjnego i systemu zainstalowanego, zawartość ESP,
  ścieżka rozruchu UEFI i BIOS, hybrydowość nośnika, jego sumy i podpisy, oraz bramka
  na artefakcie bootloadera.
- **Czego ta ADR NIE rozstrzyga:** **rozmiaru ESP i układu partycji** — to jest zakres
  [`ADR-0008`](0008-filesystem-and-partition-layout.md) D5, patrz D6 niżej; mechaniki
  aktualizacji i miejsca wskaźnika slotu ([`ADR-0009`](0009-system-update-mechanism.md));
  stosu szyfrowania ([`ADR-0010`](0010-encryption-stack.md)); architektury kreatora
  ([`ADR-0011`](0011-installer-wizard-architecture.md)); strategii wobec Microsoftu
  (`ADR-0005`, `ADR-0006`).

## Legenda znaczników

Każda zamówiona zdolność dostaje znacznik. Bez znacznika przy zdolności napisanej słownikiem
Linuksa dokument obiecywałby GRUB-a, systemd-boota i TPM-a na systemie, który nie ma żadnego
z nich.

| Znacznik | Znaczenie |
|---|---|
| **JEST** | działa dzisiaj — z dowodem: `plik:linia`, nazwa binarki, pozycja `R-*`/`U-*` |
| **DO ZBUDOWANIA** | wykonalne na Redoksie bez nowego podsystemu |
| **NOWY PODSYSTEM** | wymaga zbudowania czegoś, czego Redox nie ma w ogóle |
| **NIEREALNE DZIŚ** | zależy od ekosystemu, którego nie ma i nie będzie szybko |

`[NIEZWERYFIKOWANE]` oznacza twierdzenie, którego **nie potwierdziłem w tym drzewie**; przy
każdym piszę, co sprawdzić i gdzie. Źródła forków (`eos-bootloader`, `eos-installer`) **nie są
w tym drzewie rozwinięte** — sprawdzone: `recipes/core/bootloader/` i `recipes/core/installer/`
zawierają wyłącznie `recipe.toml` (plus `sbat.csv` przy bootloaderze).

---

## Kontekst

Pytanie do rozstrzygnięcia jest jedno i brzmi dosłownie tak: **czy nośnik instalacyjny i system
zainstalowany uruchamiają bootloader Redoksa, czy wprowadzamy GRUB2 / systemd-boot / rEFInd —
i co to robi z łańcuchem zaufania, który już istnieje.**

Pytanie nie jest hipotetyczne. Jedyna ścieżka dual-boot obecna dziś w drzewie,
`scripts/dual-boot.sh`, **jest integracją z systemd-bootem**: wymaga `bootctl --print-esp-path`,
kopiuje bootloader do `${ESP}/EFI/redox.efi` i pisze `${ESP}/loader/entries/redox.conf`. Skrypt
jest upstreamowy, uruchamiany na **hoście linuksowym**, i — jak stwierdza
`docs/architecture/installer.md` §1.2 — **nigdy nie był przez E-OS przetestowany**. Wybór
„bootloader Redoksa czy cudzy" jest więc już w drzewie zrobiony w dwie strony naraz.

### Co jest zmierzone, a nie założone

| fakt | dowód |
|---|---|
| bootloader to fork `eos-bootloader`, gałąź `eos-rebased`, rev `87b214b5b481…` | `recipes/core/bootloader/recipe.toml:4-6` |
| podpis Secure Boot następuje **w stage podczas `cook`**, kluczem operatora z `build/sb-signing/{mok.key,mok.crt}` | `recipe.toml:108`; `ADR-0005` §Integracja |
| SBAT jest wstrzykiwany **przed** podpisem (Authenticode pokrywa całą binarkę) | `recipe.toml:73`, `scripts/eos-add-sbat.py`, `sbat.csv` = `eos-bootloader,1,E-OS,…` |
| klucz weryfikacji ładunku jest **wkompilowany** w binarkę (32 surowe bajty w `src/eos-boot-verify.pub.bin`, feature `verify-boot`) | `recipe.toml:24-31` (kontrola „32 raw bytes" w `:28`, feature w `:31`); uzasadnienie w komentarzu: ta binarka jest jedynym artefaktem, który uwierzytelnia firmware (`V2-N03`) |
| bootloader weryfikuje jądro i initfs ed25519 nad `SHA-512(rola ‖ długość_le ‖ dane)`, z separacją domen | `V2-MS02` / `U-212` |
| dowód Secure Boota ma **kontrolę negatywną z obcym kluczem** (3 przypadki) | `scripts/eos-secureboot-proof.sh:75-88` |
| ten dowód sprawdza **mechanizm firmware'u, nie wydany artefakt**: bierze zbudowany `bootloader-live.efi` i **przepodpisuje go kluczem jednorazowym**, na syntetycznym ESP (20 MiB `mkfs.vfat`, sam bootloader, bez RedoxFS-a) | `eos-secureboot-proof.sh:41-62` — dlatego potrzebna jest bramka z D8 |
| dowód weryfikacji jądra ma **kontrolę negatywną z jednym przestawionym bajtem** (2 przypadki) | `scripts/eos-boot-verify-proof.sh:2-14` |
| **oba nośniki** — live ISO i `harddrive.img` — bootują pod firmware z Secure Bootem naszym kluczem i dają `Access Denied` z obcym | `U-208`, `U-210`. **Zakres, którego nie wolno rozszerzać:** `x86_64`, QEMU + edk2 (`eos-secureboot-proof.sh:24,28` — `ARCH=x86_64` na stałe). Na **fizycznym** firmware nigdy (`installer.md` §9.3 pkt 7), a na **aarch64** — czyli na architekturze, na której projekt realnie pracuje — Secure Boot **nie ma żadnego dowodu** |
| **bootloader ma już menu**: „video-mode menu", czytane z **emulowanej klawiatury**, `l` przełącza tryb live, Enter zamyka | `scripts/install-smoke-drive.py:136-153`, cytat menu: `Press l to disable live mode` |
| jądro i initfs leżą **w RedoxFS-ie** pod `/usr/lib/boot/`, nie na ESP | `docs/architecture/system-updates.md` §1.4 (`recipes/core/kernel/recipe.toml:14`, `recipes/core/base/recipe.toml:27`) |
| bootloader pyta o hasło FDE i **odblokowuje RedoxFS**, dopiero potem ładuje z niego jądro | `docs/architecture/installer-wizard.md` §5.5 |
| instalator tworzy **dokładnie trzy** partycje: `BIOS` 1 MiB, `EFI` **1 MiB** (`efi_partition_size`), reszta RedoxFS | `system-updates.md` §1.4, za `installer.rs:565-660` |
| ESP nośnika składany jest z paczki `bootloader.pkgar` (`fetch_bootloaders` czyta `usr/lib/boot/bootloader-live.efi`), a nie z `--write-bootloader` | `U-207`; `mk/disk.mk` mimo to nadal podaje `--write-bootloader=…` |
| netboot istnieje: `redox.ipxe` (89 B) chainloaduje `bootloader-live.efi`, obraz live jako `initrd` po HTTP | `redox.ipxe`, `scripts/network-boot.sh` (host linuksowy, `dnsmasq`, `iptables`) |
| **nośnik instalacyjny nie jest wydawany**: `make-release.sh` pakuje wyłącznie `harddrive.img`, więc `redox-live.iso` nie ma sumy w `SHA256SUMS` ani podpisu minisign | `make-release.sh:20-30,49-51`; `installer.md` §1.2 pkt 1; `CLAUDE.md` §17 („Podpisany obraz ISO — ❌ brak") |
| podpisywany jest **manifest sum**, nie artefakty: `minisign -Sm SHA256SUMS`, klucz operatora poza repo | `make-release.sh:49-51`; warstwa 4 z `docs/reference/keys-and-tokens.md` §6a |
| wypalenie nośnika na USB jest **cudzym narzędziem na hoście**: `make popsicle` woła `popsicle-gtk` | `Makefile:16-17` |

**Trzy poprawki do rejestru, zgodnie z `CLAUDE.md` §4.5.** Nie „później" — tu, w dokumencie,
który je zauważył.

1. **Rewizja bootloadera.** `ROADMAP.md` (§5.1) cytuje rev `b249982f`. Receptura mówi
   `87b214b5b481be7f7049fbb07cf927961b00da5b` (`recipe.toml:6`), i to samo mówi
   `repos.toml:43`. `b249982f` to rev **zamknięcia `R-F10`** (`ROADMAP.md:280`, `U-156`) —
   czyli roadmapa cytuje stan sprzed późniejszych podbić i jest **nieaktualna**. O ile
   dokładnie — nie wiem: historii forka nie da się tu sprawdzić, `git` był w tym zadaniu
   zabroniony, a `recipes/core/bootloader/source` nie istnieje.
2. **`0x2f600` to 194 048 B, nie 193 536 B.** `installer.md` §5.2 i `ADR-0008` D5 podają
   `0x2f600 = 193 536 B`; 193 536 to `0x2F400`. Liczba wchodzi do rachunku ESP-u w obu
   dokumentach, więc błąd nie jest kosmetyczny. Ten ADR używa **194 048 B**.
3. **`ROADMAP.md` wskazuje `recipe.toml:52-65` jako miejsce podpisu.** Podpis jest
   w `:89-114` (`sbsign` w `:108`); `:52-65` to budowanie bootloadera UEFI i komentarz o SBAT.

**Częściowa odpowiedź na otwarte pytanie z `installer.md` §3.3 — i granica tej odpowiedzi.**
Dokument instalatora zostawia jako `[NIEZWERYFIKOWANE]`, czy rozruch BIOS-owy z GPT idzie przez
partycję BIOS boot, czy przez lukę za ochronnym MBR-em. `system-updates.md` §1.4 (za
`installer.rs:565-660`) mówi, że **partycja nr 1 ma typ `BIOS` i 1 MiB** — czyli miejsce na
stage1 istnieje i jest zaalokowane. **To nie zamyka pytania:** istnienie partycji nie dowodzi,
że instalator zapisuje tam stage1, a nie w lukę. Pytanie **zostaje otwarte**, bo rozstrzyga je
odczyt kodu, a `recipes/core/installer/source` w tym drzewie nie istnieje. **Co sprawdzić:**
funkcja pisząca MBR/GPT w `eos-installer`, albo `dd` pierwszych 2048 sektorów zbudowanego
`harddrive.img` i porównanie z zawartością partycji nr 1. Wnioskowanie z samego układu partycji
byłoby dokładnie tym, czego zakazuje `CLAUDE.md` §4.3.

---

## Decyzja

### D1 — Jeden bootloader, jedna paczka, jeden klucz, oba nośniki

Nośnik instalacyjny i system zainstalowany uruchamiają **wyłącznie bootloader E-OS**
(`bootloader-live.efi` / `bootloader.efi`), pochodzący z **tej samej paczki**
`bootloader.pkgar`, podpisany **tym samym kluczem operatora**, niosący SBAT i weryfikujący
jądro oraz initfs. **Znacznik: JEST.**

Konsekwencja, którą trzeba wypowiedzieć, bo nie jest oczywista: **właściciel maszyny wnosi
jeden klucz i ten jeden klucz obsługuje obie fazy**. Gdyby nośnik i cel były podpisane różnymi
kluczami, enrollment byłby dwukrotny — i to jest praktyczny powód, dla którego trzymamy jedną
paczkę, a nie tylko elegancja.

### D2 — Nie wprowadzamy GRUB2, systemd-boota ani rEFInd

Ani jako pierwszego stopnia, ani jako menu chainloadującego nasz bootloader, ani „tylko na
nośniku". Uzasadnienie w sekcji **Odrzucone warianty** — z rachunkiem zysków, nie z preferencji.

`scripts/dual-boot.sh` **przestaje być ścieżką E-OS**. Jest upstreamowy, wymaga systemd-boota
i hosta linuksowego, i nigdy nie był testowany. Do zrobienia: nagłówek w pliku mówiący to wprost
albo wycofanie skryptu wraz z `R-609`. **Znacznik: DO ZBUDOWANIA** (jedna zmiana tekstu).

### D3 — Shim pozostaje odrzucony; `ADR-0005` i `ADR-0006` nie są tu otwierane ponownie

Ten ADR ich nie zmienia i nie powtarza. Jedyne, co dokłada: **shim nie wraca tylnymi drzwiami
jako „ale GRUB byłby łatwiejszy do podpisania przez Microsoft"** — byłby, i to jest prawda
(recenzenci deklarują kompetencje wyłącznie w GRUB2 i systemd-boocie, `ROADMAP.md` §5.1), ale
korzyść jest warunkowa wobec `V2-MS10`, które **nie jest decyzją techniczną**.

### D4 — Menu wyboru systemów rozwiązuje firmware, nie bootloader

Dual-boot obsługujemy dwiema drogami, w tej kolejności:

1. **Wpis `Boot####` + `BootOrder` w NVRAM** przez UEFI Runtime Services, wskazujący
   `EFI/EOS/bootloader.efi`. **Znacznik: DO ZBUDOWANIA albo NOWY PODSYSTEM** — rozstrzyga to,
   czy Redox wystawia zmienne UEFI z przestrzeni użytkownika. **`[NIEZWERYFIKOWANE]`**;
   **co sprawdzić:** obecność schematu `efivars` w `eos-kernel` i w `eos-bootloader`.
   To **nie jest nowy projekt** — `installer.md` §7.5 opisuje dokładnie tę pracę, z tym samym
   znacznikiem warunkowym i tym samym pytaniem otwartym. Ten ADR ją potwierdza jako drogę
   pierwszą, nie zakłada dla niej nowej pozycji i nie ma dla niej pozycji `R-*` (sprawdzone:
   w `ROADMAP.md` nie ma pozycji o NVRAM/`efivars`) — jeśli ma powstać,
   należy do `R-609`.
2. **Menu rozruchowe firmware'u** (F12 / F8 / Esc — zależnie od producenta) jako droga
   gwarantowana, bez żadnej zależności od nas. Nośnik ma wieźć listę klawiszy w
   `EFI/EOS/README.txt`. **Znacznik: DO ZBUDOWANIA** (plik tekstowy).

Ta decyzja ma cenę i nie zamierzam jej ukrywać: **przy braku dostępu do zmiennych UEFI
dual-boot jest ręcznym zabiegiem w menu firmware'u.** To jest gorsze doświadczenie niż menu
GRUB-a. Wybieramy je świadomie, bo alternatywa kosztuje korzeń łańcucha zaufania (wariant F).

### D5 — Zapis na ESP: `EFI/EOS/`, cudzej ścieżki awaryjnej nie dotykamy

- Na **naszym** ESP (świeża instalacja, cały dysk) piszemy `EFI/EOS/bootloader.efi` **oraz**
  ścieżkę awaryjną `EFI/BOOT/BOOT{X64,AA64}.EFI`, bo bez wpisu NVRAM ona jest jedynym, co
  firmware uruchomi bez konfiguracji.
- Na **cudzym** ESP (instalacja obok, `R-609`) piszemy **wyłącznie** `EFI/EOS/`. Nadpisanie
  `EFI/BOOT/BOOTX64.EFI` cudzej instalacji jest odrzucone — to ścieżka, którą Windows uważa
  za swoją.
- Nośnik wiezie dodatkowo `EFI/EOS/eos-secureboot.der` (postać DER, bo tego oczekują menedżery
  kluczy w firmware) i `EFI/EOS/README.txt`.

**Znacznik: DO ZBUDOWANIA**, jako część `R-609` — nie nowa pozycja.

### D6 — ESP musi urosnąć ponad 1 MiB; **rozmiar rozstrzyga `ADR-0008` D5, nie ten dokument**

**Poprawka do wcześniejszej wersji tej sekcji, jawnie, bo była błędem projektowym.** Pierwotnie
ustalała tu `efi_partition_size = 100 MiB`. To jest **kolizja decyzji**: `ADR-0008` — którego
zadeklarowanym zakresem jest *„układ partycji przy instalacji na goły sprzęt — ESP, root,
`/home`…"* — rozstrzyga w D5 **512 MiB**, tego samego dnia, w tej samej serii dokumentów. Dwie
ADR-y z dwiema różnymi liczbami dla tego samego pola to dokładnie dwa źródła prawdy, których
projekt ma już udokumentowany koszt (`U-164`). **Wiążąca jest `ADR-0008` D5.**

Ten ADR wnosi do tamtej decyzji wyłącznie **budżet po stronie bootloadera** — dane wejściowe,
nie werdykt:

| pozycja | rozmiar | źródło |
|---|---|---|
| `bootloader-live.efi` | 232 504 B | zmierzony w **drzewie budowania**, `/work/redox/build/x86_64/eos/` w wolumenie `eos-work` — nie w tym repozytorium (`CLAUDE.md` §20.1); tę samą ścieżkę czyta `eos-secureboot-proof.sh:44` |
| `bootloader.efi` systemu zainstalowanego | **194 048 B** (`0x2f600`, log instalacji, `R-F19`) | `system-updates.md` §1.4 |
| trzy kopie (bieżąca, poprzednia, ratunkowa) | 3 × 194 048 B = **582 144 B ≈ 569 KiB** | rachunek; `system-updates.md` §5.2 pkt 2 — schemat `.NEW` → `rename` → `.PREV` |
| certyfikat DER + `README.txt` + `install-journal.toml` | < 100 KiB | D5; `installer.md` §6.3 |

**Wniosek po stronie bootloadera jest jednoznaczny i słabszy, niż wyglądał:** trzy kopie
bootloadera **mieszczą się w dzisiejszym 1 MiB** (569 KiB z 1024 KiB) — mówi to wprost
`system-updates.md` §5.2 pkt 2. Sam bootloader **nie jest** argumentem za powiększeniem ESP-u.
Argumentami są rzeczy spoza tego ADR-a: staging `R-707`, dziennik instalacji i minimum FAT32 —
i wszystkie trzy są policzone w `ADR-0008` D5.

**Jedyny argument, który należy do tego dokumentu.** FAT32 wymaga minimum **65 525 klastrów**;
przy 512 B na klaster to 33 548 800 B ≈ **32 MiB**. Partycja 1 MiB **nie może** więc być FAT32 —
jest FAT12 albo FAT16. Specyfikacja UEFI dopuszcza FAT12/16 na nośnikach **wymiennych**, a na
dysku stałym wymaga FAT32. Pod edk2 w QEMU dzisiejszy ESP działa — bo `harddrive.img` bootuje
pod tym firmware (`U-208`, `U-210`) — ale **firmware producenta nie musi go przyjąć**, i to
jest dokładnie ta klasa awarii, której QEMU nie pokaże (`installer.md` §9.3 pkt 1).
**`[NIEZWERYFIKOWANE]`, jaki wariant FAT-a formatuje dziś instalator**; **co sprawdzić:**
wywołanie formatujące w `eos-installer/src/installer.rs` oraz `file`/`fsstat` na drugiej
partycji zbudowanego `harddrive.img`.

**Sprostowanie cytatu.** Wcześniejsza wersja tej sekcji powoływała się tu na `U-162` jako na
dowód, że *„firmware edk2 odczytało `BOOTAA64.EFI` z ESP"*. `U-162` mówi co innego: to oględziny
dysku **po nieudanym przebiegu instalacji**, które wykazały, że instalator ten plik **zapisał**
(2 tablice GPT, 1 `BOOTAA64.EFI`, 11 sygnatur RedoxFS). O odczycie przez firmware nie mówi nic.
Dowodem na odczyt jest rozruch obrazu, czyli `U-208`/`U-210`.

**Znacznik: DO ZBUDOWANIA**, ale **jako `ADR-0008` D5**, przypięte do `R-609` i `R-707`. Ten
ADR nie zakłada dla tego osobnej pozycji.

### D7 — Legacy BIOS zostaje jako tor B, **jawnie bez kotwicy zaufania**

`bootloader.bios` i `bootloader-live.bios` budują się dla `i586`/`i686`/`x86_64`
(`recipe.toml`), z twardym budżetem 384 KiB, **celowo bez SBAT** (płaski obraz NASM bez tablicy
sekcji PE; żadne firmware nie czyta SBAT w rozruchu legacy). Na aarch64 BIOS-owy bootloader nie
istnieje w ogóle.

Weryfikacja jądra działa i na tej ścieżce, ale **nie jest kotwicą**: `docs/threat-model.md` mówi
wprost, że stage1/2/3 to surowe sektory, których nic nie uwierzytelnia, więc kto może zapisać
jądro, może podmienić weryfikator. **Instalator ma to napisać na ekranie, nie w dokumentacji.**
**Znacznik: DO ZBUDOWANIA** (jeden ekran).

### D8 — Bramka na artefakcie: niepodpisany bootloader albo bootloader bez klucza weryfikacji **przewraca wydanie**

To jest jedyna pozycja w tym ADR-ze, która naprawia coś, co dziś jest zepsute, i wynika wprost
z zasady projektu: **kontrola, która nie może zawieść, nie jest kontrolą.**

Dziś receptura degraduje się łagodnie i **słusznie** — bez klucza nie udaje, że podpisała
(`recipe.toml:113`: `no Secure Boot key … bootloaders left UNSIGNED`; `recipe.toml:34`:
`no boot key … bootloader will NOT verify what it loads`). Problem jest piętro wyżej:
**jedynym śladem obu tych sytuacji jest linia w logu `cook`**. `make all` złoży obraz,
`ci-boot-smoke.sh` da PASS (bo z wyłączonym Secure Bootem taki obraz bootuje), a
`make-release.sh` spakuje go do wydania. Bootloader, który **niczego nie weryfikuje**, przechodzi
przez cały potok bez jednego czerwonego światła.

Proponowana kontrola, sprawdzana **na artefakcie**, nie na recepturze (`CLAUDE.md` §21.6):

1. wydobyć `bootloader{,-live}.efi` z ESP zbudowanego obrazu,
2. `sbverify --cert <cert operatora>` — musi przejść,
3. sprawdzić, że binarka niesie 32 bajty klucza weryfikacji z `build/boot-signing/boot.pub.bin`,
4. sprawdzić obecność sekcji `.sbat`.

**Kontrola negatywna, bez której to nie jest bramka:** zbudować raz bez
`build/sb-signing/` i raz bez `build/boot-signing/` i zobaczyć, że każdy z tych przebiegów
**pada z nazwą brakującej rzeczy** — i że różni się komunikatem od awarii przyrządu
(`CLAUDE.md` §13, `U-177`).

**Znacznik: DO ZBUDOWANIA.** To jest bliski sąsiad `V2-MS04` (bramka Secure Boot w CI) i
proponuję **rozszerzyć `V2-MS04`**, a nie zakładać nowej pozycji: tamta pozycja mówi „dowód
przestaje zależeć od jednego laptopa", ta dokłada „i nie da się wydać obrazu bez dowodu".

Pułapka wdrożeniowa do powtórzenia, bo kosztowała już jeden fałszywy dowód (`U-208`): **podpis
następuje wyłącznie przy świeżym `cook`**; zbuforowana paczka bootloadera nie zostanie
przepodpisana przez `make all` — dlatego `scripts/eos-sb-setup-key.sh` unieważnia paczkę przy
kładzeniu klucza. Bramka z D8 łapie właśnie ten przypadek.

### D9 — Podbicie generacji SBAT jest rzadkie, jawne i spóźnione względem debiutu

Podbicie `eos-bootloader,1,…` na `2` sprawia, że firmware **odmówi uruchomienia poprzedniego
bootloadera** — czyli wycofanie bootloadera przestaje działać. Dlatego podbicie następuje
**dopiero po tym, jak nowy bootloader udowodni się w polu**, nigdy w tym samym wydaniu, w którym
debiutuje. To powtórzenie ustalenia z `system-updates.md` **§5.5** („SBAT — jedyna istniejąca
dziś ścieżka unieważnienia"; §5.4 to TPM), wpisane tutaj, bo należy do decyzji o bootloaderze,
a nie o aktualizacjach. **Znacznik: JEST** (mechanizm — `sbat.csv`, 158 B, generacja `1`),
**DO ZBUDOWANIA** (polityka zapisana i egzekwowana).

**Jak ta polityka zawodzi.** Nie ma dziś nic, co by zatrzymało podbicie generacji: `sbat.csv`
to plik tekstowy w recepturze, a jego zmiana przechodzi przez `cook` bez pytania. Porażka jest
**cicha i nieodwracalna w polu** — objawia się dopiero u użytkownika, który nie może wrócić do
poprzedniego bootloadera. Egzekutorem może być tylko bramka porównująca generację w `sbat.csv`
z generacją w poprzednim wydaniu i żądająca jawnego przełącznika — inaczej „polityka" jest
notatką, nie kontrolą (`CLAUDE.md` §6, §13).

**A teraz rzecz, której ten dokument nie miał prawa przemilczeć: kto właściwie egzekwuje SBAT.**
`V2-MS01`, `system-updates.md` §5.5 i wcześniejsza wersja tej sekcji mówią o SBAT jak o
**działającej** ścieżce unieważniania. Zmierzone jest co innego: że sekcja `.sbat` **jest
w obu binarkach UEFI** (`U-218`, 158 B, RVA `0x42000`/`0x43000`) i że nie psuje podpisu. Że
**cokolwiek ją czyta** — nie jest w tym projekcie zmierzone ani razu. W praktyce SBAT
egzekwuje **shim**, porównując linie generacji ze zmienną `SbatLevel`, a E-OS shima **świadomie
nie ma** (`ADR-0006`). **`[NIEZWERYFIKOWANE]`, czy edk2 albo firmware producenta w ogóle
parsuje `.sbat` bez shima**; **co sprawdzić:** przebieg `eos-secureboot-proof.sh` z podniesionym
poziomem unieważnienia w zmiennych firmware'u i sprawdzenie, czy bootloader z generacją `1`
zostanie odrzucony. Dopóki takiego przebiegu nie ma, uczciwy opis brzmi: **sekcja `.sbat`
jest przygotowaniem, a nie działającą dziś kotwicą unieważniania** — i D9 opisuje politykę
dla mechanizmu, którego egzekwowania jeszcze nie widzieliśmy na czerwono (`CLAUDE.md` §4.1).

### D10 — Nośnik jest artefaktem wydania; dziś nim nie jest, i to jest największa dziura w tym ADR-ze

Dokument nazywa się „nośnik instalacyjny", więc musi powiedzieć, co się z tym nośnikiem dzieje
po zbudowaniu. Odpowiedź jest niewygodna i zmierzona:

- `make-release.sh:20-30` pakuje **wyłącznie** `build/$arch/eos/harddrive.img`. `redox-live.iso`
  w pętli nie ma. Więc `SHA256SUMS` i `SHA256SUMS.minisig` **nie pokrywają pliku, który
  użytkownik wypala na pendrive'a**. Podpisujemy obraz preinstalowany, wydajemy nośnik
  instalacyjny — dwa różne pliki (`installer.md` §1.2 pkt 1; `CLAUDE.md` §17 mówi to samo:
  *„Podpisany obraz ISO — ❌ brak; ISO nie jest publikowane"*).
- Podpisywany jest **manifest sum**, nie artefakty: `minisign -Sm "$OUT/SHA256SUMS"`
  (`make-release.sh:49-51`), kluczem operatora trzymanym poza repo. Dla użytkownika znaczy to
  jedno: **weryfikacja pobranego pliku jest dwustopniowa** — najpierw `minisign -Vm SHA256SUMS`
  kluczem `keys/eos-release.pub`, potem `sha256sum -c`. Kto sprawdzi tylko sumę, nie sprawdził
  niczego, bo sumę można przepisać razem z plikiem.
- Ten model ma dziś **niezależną wadę poza zakresem tego ADR-a**: połowy prywatnej klucza
  `eos-release.pub` (`DCEC85BA6057ED4A`) nikt nie posiada (`R-F26`, `U-191`), więc nowego
  wydania **nie da się podpisać tym kluczem, którym dokumentacja każe weryfikować**.

**Decyzja:** nośnik wchodzi do **istniejącej warstwy 4**, przez rozszerzenie pętli
`make-release.sh` o drugi artefakt na architekturę. **Nie tworzymy drugiego mechanizmu podpisu**
i nie zakładamy nowej pozycji — to jest decyzja **B3 z `installer.md` §2.4**, tu wyłącznie
potwierdzona jako wiążąca dla nośnika. **Znacznik: DO ZBUDOWANIA.**

**Jak ta kontrola zawodzi dziś: nie zawodzi, bo jej nie ma.** Brak sumy nośnika nie jest błędem,
tylko ciszą — `make-release.sh` sprawdza obecność `harddrive.img` (`:22-25`) i o ISO nie pyta.
Po zmianie brak `eos-<ver>-<arch>-installer.img` ma kończyć skrypt kodem ≠ 0 z nazwą
brakującego pliku. To jest różnica między kontrolą a dekoracją (`CLAUDE.md` §13).

### D11 — Nośnik wiezie własną weryfikację i tryb ratunkowy; nie wiezie cudzych binarek EFI

- **Sprawdzenie nośnika po zapisie.** Pozycja menu licząca SHA-256 nośnika i porównująca ją
  z `SHA256SUMS` wiezionym **na tym samym nośniku**, którego podpis minisign weryfikujemy
  kluczem `keys/eos-release.pub`. Zamienia zgłoszenie *„instalator się wywala"* w *„nośnik jest
  uszkodzony"*. **Znacznik: DO ZBUDOWANIA** — to jest `installer.md` §8.4, nie nowa praca.
  **Tryb porażki tej kontroli:** suma liczona z **tego samego** nośnika wykryje uszkodzony
  zapis, ale **nie** wykryje podmiany przy pobieraniu, jeśli napastnik podmienił obraz razem
  z wiezionym `SHA256SUMS` — chroni przed tym wyłącznie podpis, i dlatego weryfikacja podpisu
  jest w tej pozycji obowiązkowa, a nie opcjonalna.
- **Tryb ratunkowy na tym samym nośniku.** Nośnik **jest** systemem ratunkowym, bo wiezie pełny
  userland w RAM; brakuje wyłącznie menu *zainstaluj / ratuj / sprawdź nośnik*.
  **Znacznik: DO ZBUDOWANIA** — `installer.md` §8.1. Z jednym brakiem, który trzeba nazwać
  tutaj, bo dotyczy rozruchu: **`fsck` dla RedoxFS nie istnieje** — `build/fstools/bin/` ma
  `redoxfs` i `redoxfs-mkfs`, nic więcej. To cytat za `installer.md` §8.1, nie odczyt:
  w **tym** drzewie `build/fstools/` w ogóle nie ma (`build/` zawiera trzy pozycje, patrz
  *Czego nie udało się zweryfikować* pkt 8). **Znacznik: NOWY PODSYSTEM**, i **pozycja już
  istnieje: `R-615`** (`ROADMAP.md`, `[P2·XL·🖥️]`, 🔴). Nie zakładam dla tego
  niczego nowego — przy okazji: `installer.md` §8.1 nadal twierdzi *„nie znalazłem dla niej
  pozycji `R-*`"*, co po powstaniu `R-615` jest **nieaktualne** i wymaga poprawki.
- **memtest i inne cudze binarki EFI na nośniku: odrzucone.** Memtest86+ to obcy obraz EFI.
  Umieszczenie go na nośniku znaczy albo uruchamianie niepodpisanego kodu z naszej ścieżki
  rozruchu, albo podpisanie cudzej binarki naszym kluczem — a to jest wprost sprzeczne z D1
  i z jedyną linią SBAT, którą kontrolujemy. **Znacznik: odrzucone** (nie „brak" —
  świadoma decyzja).
- **Wypalenie nośnika na USB.** `make popsicle` woła `popsicle-gtk` (`Makefile:16-17`) — to
  **cudze narzędzie GTK na hoście linuksowym**, nie część E-OS i nie coś, co utrzymujemy.
  **Znacznik: JEST**, z zakresem: host, nie system. Na macOS-ie i Windowsie użytkownik i tak
  używa `dd` / Rufusa / Ventoya, i dokumentacja ma to mówić zamiast sugerować własne narzędzie.

---

## Odrzucone warianty

Każdy wariant dostaje uczciwie policzone **zyski** — bo bez nich sekcja jest agitacją, a nie
zapisem decyzji.

### A. GRUB2

**Co byśmy zyskali (realnie, nie na pokaz):** rozpoznawalne menu; `os-prober`, który wykrywa
Windows i Linuksa i sam pisze wpisy; jedna konfiguracja obsługująca BIOS i UEFI; konsola
szeregowa i obsługa klawiaturą dopracowane od dwóch dekad; `grub-install` piszący wpisy NVRAM
za nas (czyli D4 rozwiązane cudzą pracą); wreszcie — **jedyny obok systemd-boota drugi stopień,
w którym `rhboot/shim-review` deklaruje kompetencje**, więc gdyby `V2-MS10` kiedyś zapadło,
ścieżka do Microsoftu byłaby krótsza.

**Co byśmy stracili:**

1. GRUB nie czyta RedoxFS-a ani formatu jądra Redoksa, więc **musi chainloadować nasz
   bootloader**. Przy **włączonym** Secure Boocie chainload i tak przechodzi przez `LoadImage`
   firmware'u, więc podpis nie ginie — ale przy **wyłączonym** Secure Boocie, czyli w
   konfiguracji, którą `ADR-0005` przewiduje dla obcego x86_64 jako jedną z dwóch dróg,
   **nic nie weryfikuje ani GRUB-a, ani chainloadu**, a naszą kotwicę omija się podmianą
   jednego pliku `.efi`. Dziś w tej samej sytuacji trzeba podmienić binarkę, którą firmware
   uruchamia bezpośrednio.
2. **Podwojenie podpisywanej powierzchni.** GRUB podpisany przez dystrybucję nie jest podpisany
   *naszym* kluczem, więc i tak musielibyśmy go podpisywać sami — czyli utrzymywać własny build
   GRUB-a, z jego historią podatności w ścieżce rozruchu (klasa BootHole). Nasza linia SBAT
   opisuje `eos-bootloader`, nie GRUB-a; unieważnianie dziurawego GRUB-a nie byłoby naszą
   ścieżką.
3. **Miejsce.** ESP ma dziś 1 MiB (D6; docelowo `ADR-0008` D5). GRUB core plus moduły to dziesiątki MiB, ładowane
   z systemu plików, który GRUB musi umieć przeczytać.
4. **Koszt utrzymania w tym drzewie.** GRUB-a nie ma w cookbooku. Byłby to nowy fork typu C
   (`CLAUDE.md` §11) z obowiązkiem rebaseowalności, drugi harmonogram synchronizacji i drugi
   przedmiot audytu `mirror-drift`.
5. Setki tysięcy linii C w ścieżce rozruchu systemu, którego cała teza brzmi „mikrojądro
   w Ruście".

**Werdykt: odrzucony.** Jedyny zysk, którego nie da się odtworzyć inaczej, to wykrywanie innych
systemów — a tego chcemy w **instalatorze** (`R-604`, `R-609`), gdzie użytkownik podejmuje
decyzję, a nie w ścieżce rozruchu.

### B. systemd-boot

**Co byśmy zyskali:** to najmniejszy z trzech (~100 KiB), czyta wyłącznie ESP i nie potrzebuje
sterowników systemów plików, ma prosty i stabilny format wpisów (`loader/entries/*.conf`,
Boot Loader Spec), dobrze rozpoznaje Windows, a **w tym drzewie już istnieje integracja z nim**:
`scripts/dual-boot.sh` pisze `${ESP}/EFI/redox.efi` i `redox.conf`. Wariant B jest więc jedynym,
którego kawałek jest napisany.

**Co byśmy stracili:**

1. **To jest jego prawdziwy koszt i jest ciężki.** systemd-boot uruchamia to, co potrafi
   `LoadImage` **z ESP**. Żeby stał się realnym pierwszym stopniem, jądro i initfs musiałyby
   przenieść się z RedoxFS-a na ESP — czyli **z woluminu zaszyfrowanego AES-XTS na jawną
   partycję FAT**. Dziś bootloader pyta o hasło, odblokowuje RedoxFS i **dopiero z niego** bierze
   jądro (`installer-wizard.md` §5.5, które nazywa to *„szyfrowany `/boot` — JEST w części, która
   ma znaczenie"*). Wariant B tę własność **kasuje**. To nie jest niewygoda, to regres
   bezpieczeństwa opisany w naszym własnym modelu zagrożeń.
2. Ten sam problem chainloadu i podwojonego podpisu co w GRUB-ie.
3. Konwencje systemd (wpisy BLS typu 1/2, `initrd=`, wiersz poleceń w pliku wpisu) nie mapują
   się na protokół rozruchu Redoksa — trzeba by je udawać.
4. Wnosimy komponent systemd do systemu, w którym **systemd nie istnieje**.

**Werdykt: odrzucony.** A `scripts/dual-boot.sh` przestaje być ścieżką E-OS (D2).

### C. rEFInd

**Co byśmy zyskali:** to najuczciwszy kandydat, bo jest **menu, a nie loaderem** — czyli robi
dokładnie tę jedną rzecz, której nam brakuje. Sam skanuje ESP i wykrywa cudze loadery bez
konfiguracji, jest graficzny i motywowalny (co pasuje do czerwono-czarnej estetyki E-OS),
obsługuje się z klawiatury i może współistnieć ze ścieżką awaryjną.

**Co byśmy stracili:**

1. Automatyczne wykrywanie to z definicji **„uruchom dowolną binarkę EFI, którą znajdziesz"**.
   Z wyłączonym Secure Bootem to jest wykonanie nieuwierzytelnionego kodu przed naszym. Z
   włączonym — firmware odrzuci cudze wpisy i użytkownik dostanie menu, w którym Windows kończy
   się `Access Denied`, co czyta się jako *„E-OS zepsuł mi Windowsa"*.
2. Trzeci podpisywany artefakt i druga ścieżka unieważniania, której nie kontrolujemy.
3. rEFInd jest **wyłącznie UEFI**, więc maszyny BIOS-owe i tak zostają przy naszym bootloaderze
   — dwa różne doświadczenia rozruchu w jednym produkcie.
4. Funkcja, której naprawdę chcemy — *„na tym dysku jest inny system"* — jest potrzebna
   **przed** zapisem, w instalatorze (`R-604`), a nie po instalacji w menu.

**Werdykt: odrzucony.** Potwierdza to wniosek, do którego `installer.md` §3.2 doszedł
niezależnie.

### D. shim podpisany przez Microsoft + MOK

**Co byśmy zyskali:** zniknąłby ten jeden krok właściciela na obcym x86_64 — czyli dokładnie
cel postawiony przez właściciela projektu.

**Co byśmy stracili / czego nie da się kupić pracą:** okno podwójnego podpisu zamknęło się
**2026-06-27**, więc shim wydany dziś jest podpisany wyłącznie przez `Microsoft UEFI CA 2023`
i maszyna mająca w `db` tylko `Microsoft Corporation UEFI CA 2011` **go nie uruchomi** —
pokrycie sprzętu byłoby **węższe** niż dwa lata temu. Do tego: wpis do rejestru osoby prawnej,
certyfikat EV, dwa kontakty bezpieczeństwa z PGP, klucz w module **FIPS 140-2 Level 2**, oraz
etykieta `custom second-stage` dla własnego bootloadera w Ruście i dodatkowa pełna recenzja
(zmierzone: 5,5 tygodnia do 7 miesięcy **przy komplecie dokumentów**).

**Werdykt: odrzucony**, decyzją `ADR-0006`, nieotwieraną tutaj. **Znacznik: NIEREALNE DZIŚ.**

### E. Dwa stosy: cudze menu na nośniku, nasz bootloader na dysku

**Co byśmy zyskali:** nośnik jest miejscem, gdzie problemy mają kształt menu (instalacja,
ratunek, sprawdzenie nośnika, memtest), a system zainstalowany zostałby nietknięty. Brzmi jak
kompromis, który bierze zysk i zostawia koszt.

**Co byśmy stracili:** **dowód, który już mamy.** `U-208`/`U-210` obejmują **oba** nośniki —
live ISO i `harddrive.img` — pod prawdziwym firmware z Secure Bootem, z kontrolą negatywną.
Wymiana pierwszego stopnia na nośniku **unieważnia połowę tego dowodu** i podwaja macierz
przebiegów QEMU. Dokładamy też nową klasę zgłoszeń: *„z pendrive'a bootuje, po instalacji nie"*
— dwa różne pierwsze stopnie to dwa różne zbiory awarii firmware'u.

**Werdykt: odrzucony.** Menu na nośniku (*zainstaluj / ratuj / sprawdź nośnik*, `installer.md`
§8.1) budujemy **w naszym bootloaderze i w środowisku live**, gdzie menu już istnieje
(`install-smoke-drive.py:136-153`) — nie przez import cudzego loadera.

### F. Nasz bootloader dostaje menu wyboru systemów i chainloaduje cudze loadery

**Co byśmy zyskali:** żadnego cudzego kodu, jeden podpisany artefakt, jedna linia SBAT — i mimo
to menu, którego użytkownicy oczekują.

**Co byśmy stracili:** bootloader musiałby enumerować ESP, parsować FAT i wołać `LoadImage` na
binarkach, których nie kontrolujemy — czyli **artefakt, którego całą racją bytu jest „weryfikuje
to, co ładuje", stałby się uruchamiaczem rzeczy nieweryfikowanych**. Do tego dwa fakty
o kruchości: `R-F10` (`ROADMAP.md:280`) zmierzył, że bootloader deklarował `redoxfs = "0.8"`
i rozwiązywał go **z crates.io**, podczas gdy system plików obrazu powstawał z przypiętego
forka `eos-redoxfs` — czyli kod pytający o hasło FDE i odblokowujący root był **innym kodem**
niż ten, który ten root tworzy; zamknięte w `U-156` przez `eos-bootloader@b249982f29`. A
`system-updates.md` §4.3 stwierdza, że **bootloader dziś niczego nie zapisuje** — więc nawet
„zapamiętaj mój wybór" jest nową zdolnością, nie opcją.

**Werdykt: odrzucony na dziś.** Uczciwa alternatywa to menu rozruchowe firmware'u (D4).

### G. Brak bootloadera — firmware ładuje jądro / jeden scalony obraz EFI (UKI)

**Co byśmy zyskali:** najmniej artefaktów, jeden podpis obejmujący całość, koniec pytania
„który stopień co weryfikuje".

**Co byśmy stracili:** jądro Redoksa nie jest obrazem PE, a protokół rozruchu zakłada loader,
który przygotuje mapę pamięci, wczyta obraz do RAM w trybie live i wyeksportuje
`DISK_LIVE_ADDR`/`DISK_LIVE_SIZE` do środowiska **jądra**, oraz — przede wszystkim — **zapyta
o hasło FDE i odblokuje RedoxFS, zanim jądro w ogóle istnieje**. UKI oznaczałby albo rezygnację
z FDE, albo przeniesienie kryptografii woluminu do jądra.

**Werdykt: odrzucony. Znacznik: NOWY PODSYSTEM**, bez korzyści dzisiaj.

### H. iPXE jako pierwszy stopień nośnika

**Co byśmy zyskali:** netboot dla pracowni i flot — **i to już istnieje**, w czterech linijkach
(`redox.ipxe`).

**Co byśmy stracili:** `redox.ipxe` pobiera obraz live po **HTTP, bez weryfikacji transportu**;
iPXE sam musiałby być podpisany pod Secure Bootem; netstack wiąże tylko pierwszą kartę
(`R-905`), nie ma IPv6 (`R-903`) ani Wi-Fi; a instalacja jest **offline z założenia**
(`installer.md` §4.4, decyzja N1).

**Werdykt: odrzucony jako droga nośnika.** Zostaje jako wygoda deweloperska —
**i ma być tak oznaczony**, bo dziś nic nie mówi, że nie jest przetestowany.
**Znacznik: `[NIEZWERYFIKOWANE]`**; **co sprawdzić:** czy `scripts/network-boot.sh` w ogóle
przechodzi na hoście linuksowym z bieżącym obrazem.

---

## Tabela zdolności

Jeden znacznik na wiersz — **z dwoma wyjątkami, które są warunkowe i mają tu wypisane, co je
rozstrzyga**: wpis NVRAM (obecność `efivars`) i netboot iPXE (przebieg na hoście). Zmyślenie
im jednego znacznika byłoby mniej uczciwe niż pokazanie widełek.

| zdolność | znacznik | dowód / zakres |
|---|---|---|
| bootloader UEFI podpisany naszym kluczem, **oba** nośniki | **JEST** | `ADR-0005`, `U-207`/`U-208`/`U-210` — **x86_64, QEMU/edk2**; aarch64 i fizyczne firmware bez dowodu |
| kontrola negatywna Secure Boota (obcy klucz → odmowa) | **JEST** | `eos-secureboot-proof.sh`, 3 przypadki — na **kluczu jednorazowym**, nie na kluczu wydania |
| sekcja `.sbat` w obu bootloaderach UEFI, wstrzykiwana przed podpisem | **JEST** | `V2-MS01`/`U-218`, 158 B, RVA `0x42000`/`0x43000` |
| SBAT jako **działająca** ścieżka unieważniania | **`[NIEZWERYFIKOWANE]`** | nikt nie zmierzył, czy cokolwiek bez shima czyta `.sbat`; D9 |
| weryfikacja jądra i initfs ed25519 z separacją domen | **JEST** | `V2-MS02`/`U-212`, `eos-boot-verify-proof.sh` |
| klucz weryfikacji **wkompilowany** w binarkę bootloadera | **JEST** | `recipe.toml:24-31` |
| menu bootloadera z klawiatury (tryb wideo, `l`, Enter) | **JEST** | `install-smoke-drive.py:136-153` |
| bootloader BIOS dla `i586`/`i686`/`x86_64`, budżet 384 KiB | **JEST**, bez kotwicy zaufania | `recipe.toml`; `docs/threat-model.md` |
| partycja BIOS boot 1 MiB (typ `BIOS`) **istnieje** | **JEST** | `system-updates.md` §1.4. Czy stage1 idzie tam, czy w lukę za MBR-em — **`[NIEZWERYFIKOWANE]`**, patrz *Kontekst*; `installer.md` §3.3 zostaje otwarte |
| jądro i initfs ładowane z **zaszyfrowanego** RedoxFS-a po odblokowaniu | **JEST** | `installer-wizard.md` §5.5 |
| hybrydowy MBR + GPT + ISO9660 na obu obrazach | **JEST** | sygnatury: `0` kod x86, `512` `EFI PART`, `0x8001` `CD001` — zmierzone w drzewie budowania, nie w tym repo |
| rozruch z **DVD** (nie z USB) | **NOWY PODSYSTEM** | `installer.md` §2.2 — firmware wystartuje, ale system nie ma sterownika ISO9660 i nie znajdzie roota |
| netboot iPXE | **JEST w drzewie**, `[NIEZWERYFIKOWANE]` w działaniu | `redox.ipxe`, `scripts/network-boot.sh`; rozstrzyga jeden przebieg na hoście linuksowym |
| wypalenie nośnika na USB z hosta | **JEST**, poza E-OS | `Makefile:16-17` → `popsicle-gtk` (GTK, Linux) |
| **sumy i podpis nośnika w wydaniu** | **DO ZBUDOWANIA** | D10; dziś `make-release.sh:20-30` pakuje tylko `harddrive.img` — nośnika nie ma w `SHA256SUMS` |
| podpisany jest **manifest sum**, nie każdy artefakt | **JEST** | `make-release.sh:49-51`, `minisign -Sm SHA256SUMS`; warstwa 4 (`keys-and-tokens.md` §6a) |
| klucz prywatny do podpisu wydania | **brak** — `R-F26`/`U-191` | połowy prywatnej `DCEC85BA6057ED4A` nikt nie posiada; poza zakresem tego ADR-a, ale unieważnia D10 do czasu rotacji |
| sprawdzenie nośnika po zapisie (SHA-256 + podpis) | **DO ZBUDOWANIA** | D11; `installer.md` §8.4 |
| tryb ratunkowy na tym samym nośniku | **DO ZBUDOWANIA** | D11; `installer.md` §8.1 |
| `fsck` dla RedoxFS (warunek sensownego trybu ratunkowego) | **NOWY PODSYSTEM** | pozycja **`R-615`** istnieje (`ROADMAP.md`) — nie zakładam nowej |
| memtest / cudze binarki EFI na nośniku | **odrzucone** | D11 — niepodpisany obcy kod albo podpisanie cudzej binarki naszym kluczem |
| bramka Secure Boot w CI | **DO ZBUDOWANIA** | `V2-MS04`, dziś 🔴 |
| bramka „niepodpisany / bez klucza weryfikacji" **na artefakcie** | **DO ZBUDOWANIA** | D8, rozszerzenie `V2-MS04` |
| certyfikat `.der` + `README.txt` na nośniku, ekran Secure Boot | **DO ZBUDOWANIA** | `installer.md` §3.1 |
| ESP większy niż 1 MiB (`efi_partition_size`) | **DO ZBUDOWANIA** | **decyduje `ADR-0008` D5 (512 MiB)**; D6 wnosi tylko budżet bootloadera i argument FAT32 |
| zapis do `EFI/EOS/`, nienadpisywanie cudzego `EFI/BOOT` | **DO ZBUDOWANIA** | D5, `R-609` |
| wpis rozruchowy `Boot####`/`BootOrder` w NVRAM | **DO ZBUDOWANIA** albo **NOWY PODSYSTEM** | D4, zależnie od `efivars` |
| ekran „ta maszyna startuje przez BIOS, integralność rozruchu nie jest chroniona" | **DO ZBUDOWANIA** | D7 |
| polityka podbijania generacji SBAT | **DO ZBUDOWANIA** | D9, za `system-updates.md` **§5.5** |
| procedura rotacji klucza Secure Boot | **DO ZBUDOWANIA** | patrz *Konsekwencje*, dług 5 |
| GRUB2 / systemd-boot / rEFInd | **odrzucone** | warianty A, B, C |
| menu wyboru systemów w naszym bootloaderze | **odrzucone** | wariant F |
| shim + MOK, `dbx`, unieważnianie przez Microsoft | **NIEREALNE DZIŚ** | `ADR-0006`, `V2-MS10`/`V2-MS11`; jedyny kandydat na własną ścieżkę unieważniania to SBAT — a jego egzekwowania nikt nie zmierzył (D9) |
| wybór slotu A/B przez bootloader (wskaźnik w atrybutach GPT) | **NOWY PODSYSTEM** | `R-710b`, `system-updates.md` §4.6 |
| trwały licznik prób rozruchu zapisywany przez bootloader | **NOWY PODSYSTEM** | `R-707`; bootloader dziś **niczego nie zapisuje** |
| weryfikacja obrazu live **przed** pivotem (dziś ładowany do RAM nieweryfikowany) | **NOWY PODSYSTEM** | `docs/threat-model.md` |
| scalony obraz EFI (UKI) | **NOWY PODSYSTEM** | wariant G |
| measured boot / TPM 2.0 / zapieczętowanie klucza FDE | **NIEREALNE DZIŚ** | `R-913` / `V2-N02`; warstwa 5 pusta (`keys-and-tokens.md` §6a) |
| FIDO2 / token sprzętowy w ścieżce rozruchu | **NIEREALNE DZIŚ** | brak stosu CTAP i brak obsługi FIDO w `usbhidd`; inwentarz obrazu wymienia FIDO2 wśród rzeczy, których nie ma |

---

## Jak wygląda porażka każdej kontroli w tym łańcuchu

Zasada projektu w formie tabeli. Kolumna ostatnia jest najważniejsza.

| kontrola | jak wygląda porażka | co ją wywołuje | czy dziś zapala się na czerwono |
|---|---|---|---|
| firmware odrzuca bootloader niepodpisany albo podpisany obcym kluczem | `Access Denied` na ekranie | brak podpisu; klucz spoza `db` | **tak** — dowiedzione, 3 przypadki (`eos-secureboot-proof.sh`) |
| **ten sam dowód wobec artefaktu wydania** | **żadna** — dowód przejdzie także wtedy, gdy wydany bootloader jest niepodpisany | skrypt bierze `bootloader-live.efi` i **sam go podpisuje kluczem jednorazowym** (`eos-secureboot-proof.sh:41-50`), więc mierzy firmware, nie nasz podpis | **nie** — i to jest cała treść D8 |
| ten sam dowód na aarch64 | brak — nie jest uruchamiany | `ARCH=x86_64` na stałe (`eos-secureboot-proof.sh:24`) | **nie** — architektura, na której projekt pracuje, nie ma dowodu Secure Boota |
| suma kontrolna i podpis **nośnika** w wydaniu | **żadna** — brak sumy nie jest błędem, tylko ciszą | `make-release.sh` nie ma `redox-live.iso` w pętli (`:20-30`) | **nie** — naprawa: D10 |
| SBAT odrzuca wycofaną generację bootloadera | nieznana — **nigdy nie zaobserwowana** | podniesiony poziom unieważnienia w firmware | **nie wiadomo** — nie ma przypadku testowego; bez shima nie wiemy nawet, kto miałby to egzekwować (D9) |
| bootloader odrzuca jądro z podmienionym bajtem | odmowa rozruchu | zmiana `usr/lib/boot/kernel` bez ważnego `.sig` | **tak** — dowiedzione, 2 przypadki (`eos-boot-verify-proof.sh`) |
| bootloader zbudowany **bez** `build/boot-signing/` | **żadna** — system startuje, weryfikacja nie istnieje | pusty katalog kluczy na maszynie budującej | **nie** — jedyny ślad to linia w logu `cook` (`recipe.toml:34`). **To nie jest kontrola.** Naprawa: D8 |
| bootloader zbudowany **bez** `build/sb-signing/` | obraz nie wystartuje pod Secure Bootem, ale wystartuje z wyłączonym | j.w. | **nie** — `make-release.sh` tego nie sprawdza. Naprawa: D8 |
| zbuforowana paczka bootloadera po położeniu klucza | podpis „jest", ale w paczce go nie ma | `make all` bez świeżego `cook` | **częściowo** — `eos-sb-setup-key.sh` unieważnia paczkę; bramka z D8 domyka |
| tryb live: cały obraz do RAM **nieweryfikowany**, zanim jądro zostanie z niego wzięte | brak | z założenia, każdy rozruch nośnika | **nie** — zapisane w `docs/threat-model.md` jako ograniczenie `V2-MS02` |
| BIOS: stage1/2/3 to surowe sektory | weryfikacja jest dowodem manipulacji, nie kotwicą | rozruch legacy | **nie** — i tak ma być; D7 każe to napisać na ekranie |

---

## Czego to NIE robi i przed czym NIE chroni

Ta sekcja nie jest zastrzeżeniem prawnym. Jest listą zdań, których po przyjęciu tego ADR-a
**nie wolno napisać w dokumentacji użytkownika** — każde ma pod sobą pomiar.

1. **Nie czyni łańcucha rozruchu zweryfikowanym.** `V2-MS02` weryfikuje **jądro i initfs**
   i nic więcej. `initfs` niesie sterowniki dysku; `xhcid`, `e1000d`, `usbhidd`, `usbscsid`,
   `ihdad`, `rtl8168d` i kilkanaście innych ładują się z **niepodpisanego** roota po
   zamontowaniu, przez `pcid`, a IOMMU nie ma (`acpid/src/acpi.rs:461`:
   `//TODO (hangs on real hardware): Dmar::init(&this);`). Podmieniony sterownik dostaje DMA —
   czyli to samo przejęcie, innym plikiem (`docs/threat-model.md`).
2. **Nie chroni trybu live.** Cały obraz jest wczytywany do RAM **bez weryfikacji**, zanim
   zostanie z niego wzięte jądro. Dotyczy to **nośnika instalacyjnego**, czyli dokładnie tego,
   o czym jest ten dokument (`threat-model.md`, `installer-wizard.md` §5.5).
3. **Nie chroni przed cofnięciem.** Poprawnie podpisane **starsze**, dziurawe jądro nadal się
   zweryfikuje i uruchomi. Zapadka to `R-704`, otwarta; a bez TPM-a nie ma dla niej sprzętowej
   kotwicy (`system-updates.md` §5.4 pkt 3).
4. **Nie chroni przed napastnikiem z fizycznym dostępem.** Bootloader leży na **nieszyfrowanym**
   ESP i sam pyta o hasło FDE, więc atak na monit jest **w modelu**, nie poza nim
   (`docs/encryption.md`, „Caveats": *„an attacker who can tamper with the (unencrypted)
   bootloader could attack the prompt"*). Nie ma anti-evil-maid, bo nie ma measured bootu
   (`R-913`, warstwa 5 pusta).
5. **Na BIOS-ie nie ma kotwicy w ogóle.** Stage1/2/3 to surowe sektory, których nic nie
   uwierzytelnia; podpis jądra jest tam **dowodem manipulacji, nie korzeniem zaufania** (D7).
6. **Nie daje menu wyboru systemów.** Świadomie (D2, D4, wariant F). Dual-boot to wpis NVRAM
   albo klawisz w menu firmware'u — i przy braku `efivars` zostaje wyłącznie ten klawisz.
7. **Nie obiecuje rozruchu na fizycznym sprzęcie.** Wszystko powyżej zmierzone pod QEMU/TCG.
   `R-601` jest udowodnione wyłącznie w emulacji, `R-607` (4Kn + macierz na realnym firmware)
   jest otwarte, a `installer.md` §9.3 wymienia dziewięć rzeczy, których QEMU nie pokaże —
   z „firmware nie widzi nośnika" na pierwszym miejscu.
8. **Nie sięga dalej niż maszyna budująca.** Klucz Secure Boota leży jako **zwykły plik** bez
   hasła w `build/sb-signing/` (`V2-MS06` 🔴), klucz podpisujący pakiety jawnym tekstem, a obie
   jego kopie na jednym komputerze (`V2-MS12`, znalezisko `C-11`, `ROADMAP.md`).
   Kto przejmie tę maszynę, podpisze wszystko poprawnie.
9. **Nie czyni Secure Boota automatycznym.** Firmware ufa **kluczom**, nie systemom. Na obcym
   x86_64 właściciel musi wnieść klucz albo wyłączyć Secure Boot — trzeciej drogi nie ma
   (`ADR-0005`, `U-206`).
10. **Nie obiecuje powtarzalności bajtowej** nośnika. `R-303`/`V2-MS07` są otwarte, więc
    zdanie „to jest ten sam obraz" jest twierdzeniem, nie pomiarem.

---

## Konsekwencje

**Co staje się łatwiejsze.** Jeden podpisywany artefakt, jeden klucz do wniesienia przez
właściciela, jedna linia SBAT, jeden harness dowodowy. **Część utrwalająca (D1–D3) nie kosztuje
nic wdrożeniowo** — jej wartością jest zamknięcie pytania, które w drzewie jest dziś otwarte
w dwie strony (`scripts/dual-boot.sh`). Dowody `U-206`, `U-208`, `U-210`, `U-212` pozostają
ważne bez żadnej zmiany. Reszta (D4–D5, D7–D11) kosztuje i jest wyceniona niżej — zdanie
„ten ADR nic nie kosztuje" byłoby prawdziwe tylko dla pierwszych trzech decyzji.

**Co staje się trudniejsze.** Nie ma menu wyboru systemów. Dual-boot zależy od wpisu NVRAM,
a przy jego braku — od menu rozruchowego firmware'u, czyli od klawisza, który u każdego
producenta jest inny. Użytkownicy przychodzący z Linuksa będą prosić o GRUB-a; dokumentacja ma
odpowiadać tym ADR-em, a nie „nie da się".

**Dług, który powstaje, i kiedy go spłacić:**

1. **ESP ponad 1 MiB** — dług realny, ale **nie ten ADR go wycenia**: rozmiar ustala
   `ADR-0008` D5 (512 MiB), przy `R-609` albo `R-707`. Stąd zostaje tu jedno zadanie:
   rozstrzygnąć **wariant FAT-a**, bo to argument z ścieżki rozruchu, nie z układu partycji.
2. **Bramka na artefakcie** (D8) — **teraz**, bo jest tania i dotyczy rzeczy, która dziś nie ma
   żadnego czerwonego światła. Rozszerzenie `V2-MS04`, nie nowa pozycja.
3. **Nośnik do wydania** (D10) — rozszerzenie pętli `make-release.sh`, czyli decyzja B3
   z `installer.md` §2.4. Uwaga na kolejność: **bez rotacji klucza wydania (`R-F26`) podpis
   nowego `SHA256SUMS` jest niewykonalny**, więc D10 bez `R-F26` daje sumy bez podpisu, czyli
   pół kontroli.
4. **Wpis NVRAM** (D4) — najpierw pomiar, czy Redox wystawia `efivars`; dopiero potem wycena.
   Bez tego pomiaru nie da się nawet powiedzieć, czy to `M`, czy `XL`.
5. **Polityka SBAT** (D9) — przed pierwszym podbiciem generacji, nie po.
6. **Rotacja klucza Secure Boot** — dziś nieopisana, a ma nieoczywisty kształt: system
   **zainstalowany** działa dalej (jego klucz wciąż jest w `db`), ale **nowy nośnik podpisany
   nowym kluczem nie wystartuje** na maszynie, która wniosła stary. Procedurę trzeba napisać
   **zanim** rotacja nastąpi. Powiązane: `V2-MS06` (klucz na tokenie).
7. **Trzy poprawki w rejestrze** (sekcja *Kontekst*): rev bootloadera w `ROADMAP.md`,
   zakres linii podpisu w `ROADMAP.md`, oraz **`0x2f600 = 194 048 B`** w `installer.md`
   §5.2 i `ADR-0008` D5 (dziś obie mówią 193 536 B, czyli `0x2F400`).
8. **Dowód Secure Boota na aarch64** — dziś `eos-secureboot-proof.sh` jest x86_64-only,
   a aarch64 jest architekturą, na której projekt realnie pracuje. Naturalne miejsce:
   `V2-MS04`, razem z bramką z D8.
9. **Zawężenie twierdzenia o SBAT** w `ROADMAP.md` (`V2-MS01`) i `system-updates.md`
   §5.5 — oba mówią „własna ścieżka unieważniania"; zmierzona jest wyłącznie **obecność
   sekcji**. Poprawić na twierdzenie zakresowe albo dołożyć przypadek testowy (D9).
10. **`installer.md` §8.1 twierdzi, że dla `fsck` nie ma pozycji `R-*`** — jest: `R-615`
    (`ROADMAP.md`). Zdanie stało się nieaktualne po jej założeniu.
11. **`mk/disk.mk` nadal podaje `--write-bootloader=…`** (`disk.mk:32`), mimo że ESP powstaje z
   `bootloader.pkgar` (`U-207`). Flaga jest dziś nieszkodliwa, ale myląca — czytelnik zakłada,
   że to ona decyduje o tym, co uruchamia firmware. Do usunięcia albo do opatrzenia komentarzem.

**Czego ta decyzja **nie** rozstrzyga:** wyboru slotu A/B (`R-710b`), trwałego licznika prób
rozruchu (`R-707`) ani measured bootu (`R-913`). Wszystkie trzy wymagają, żeby bootloader
**zapisywał stan**, czego dziś nie robi — i to jest jedna zmiana o niebanalnych konsekwencjach,
zasługująca na własny ADR, gdy `R-707` ruszy.

---

## Czego nie udało się zweryfikować

Lista jest częścią dokumentu, nie przypisem.

1. **Wnętrze `eos-bootloader`.** `recipes/core/bootloader/source` **nie istnieje** w tym drzewie
   (sprawdzone). Wszystko o zachowaniu bootloadera pochodzi z receptury, ze skryptów dowodowych,
   z harnessu i z rejestru — nigdy z odczytu jego kodu na miejscu. **Sprawdzić:** świeży klon
   forka na rev `87b214b5b481…` albo `recipes/core/bootloader/source` po `make c.bootloader`.
2. **Wnętrze `redox_installer`.** `recipes/core/installer/` zawiera wyłącznie `recipe.toml`.
   Układ partycji (`installer.rs:565-660`), `efi_partition_size` i wariant FAT-a cytuję
   za `docs/architecture/system-updates.md` §1.4, nie z odczytu.
3. **Czy Redox wystawia zmienne UEFI z przestrzeni użytkownika** — rozstrzyga, czy D4 to
   **DO ZBUDOWANIA**, czy **NOWY PODSYSTEM**.
4. **Jaki wariant FAT-a formatuje instalator na ESP** i czy 1 MiB przechodzi na firmware innym
   niż edk2 (D6).
5. **Czy `scripts/network-boot.sh` / `redox.ipxe` działają z bieżącym obrazem** (wariant H).
6. **Czy `installer-gui` da się obsłużyć wyłącznie klawiaturą** na ekranie Secure Boota z D7 —
   to samo otwarte pytanie co `installer.md` §4.5.
7. **Żadne znalezisko `C-*` nie jest w tym dokumencie cytowane z pierwszej ręki.**
   `docs/audit/03-security-audit-2026-08-30.md` leży na gałęzi `fix/p0-audit-findings`,
   a polecenia `git` były w tym zadaniu zabronione. Jedyne `C-*`, które tu pada — `C-11` —
   cytuję za `ROADMAP.md`, czyli z drzewa, nie z briefu.
8. **Rozmiary artefaktów.** `bootloader-live.efi` = 232 504 B oraz hybrydowość obu obrazów
   (`0` kod x86, `512` `EFI PART`, `0x8001` `CD001`) pochodzą z **drzewa budowania**
   w wolumenie `eos-work`. W tym repozytorium `build/` zawiera wyłącznie `container.tag`,
   `hostbuild-eos-control` i `id_ed25519.pub.toml` — katalogu `build/x86_64/eos/` **nie ma**
   (sprawdzone). Każda liczba o obrazie jest więc twierdzeniem o **innym** drzewie
   (`CLAUDE.md` §20.1); powtórzenie pomiaru wymaga `scripts/eos-sync-buildtree.sh` i budowania.
9. **Którędy idzie stage1 na BIOS-ie** — patrz *Kontekst*. Istnienie partycji typu `BIOS`
   nie jest dowodem, że instalator do niej pisze.
10. **Czy ESP zapisany przez instalatora przechodzi na firmware producenta** — nie da się tego
    rozstrzygnąć pod QEMU z definicji (`installer.md` §9.3 pkt 1). Wymaga jednej fizycznej
    maszyny (`M1` w `ROADMAP.md`).
11. **Czy cokolwiek egzekwuje SBAT bez shima** (D9). Zmierzone jest wyłącznie to, że sekcja
    `.sbat` istnieje i nie psuje podpisu — nigdy to, że jakikolwiek firmware ją czyta i na jej
    podstawie odmawia rozruchu. To jest różnica między „mamy własną ścieżkę unieważniania"
    a „mamy pole, w którym ta ścieżka mogłaby kiedyś zadziałać".

---

## Powiązania

- [`ADR-0005`](0005-secure-boot-without-microsoft.md) — własny klucz, zaufanie wnosi właściciel
- [`ADR-0006`](0006-path-to-microsoft-verification.md) — dlaczego shim odpada dziś
- [`ADR-0004`](0004-hybrid-manifest-signature.md) — podpis manifestu (warstwa 3)
- [`ADR-0008`](0008-filesystem-and-partition-layout.md) — **D5 rozstrzyga rozmiar ESP**; ten ADR
  wnosi do niej wyłącznie budżet bootloadera i argument FAT32 (D6)
- [`Instalator E-OS na nośniku USB`](../architecture/installer.md) — §1.2 pkt 1 (nośnik poza
  wydaniem), §2.2, §2.4 (decyzja B3), §3.1–§3.4, §5.2, §5.6, §7.3–§7.5, §8.1, §8.4, §9.3
- [`System aktualizacji`](../architecture/system-updates.md) — §1.4 (układ partycji), §4.3, §4.6, §5.2, §5.5 (SBAT)
- [`Kreator instalacji`](../architecture/installer-wizard.md) — §5.5 (co realnie chroni FDE)
- [`../threat-model.md`](../security/threat-model.md) — granice `V2-MS02`
- [`../keys-and-tokens.md`](../reference/keys-and-tokens.md) §6a — pięć warstw kluczy
