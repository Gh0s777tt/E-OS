# 🧭 E-OS ROADMAP v2 — scalona mapa rozwoju

> **To jest JEDYNA roadmapa projektu.** `ROADMAP.md` (v1) został **scalony do tego dokumentu**
> 2026-08-29 (`U-211`) i pozostaje wyłącznie jako archiwum historyczne — wszystkie 74 otwarte
> pozycje `R-*` żyją teraz w §9.
>
> **Aktualizacja 2026-08-29 wieczór** (`U-212`–`U-216`): `V2-MS02` **zrobione i udowodnione**;
> `V2-MS03` zamknięte; `V2-MS12` **skorygowane co do przesłanki** — klienci NIE przypinają klucza
> pakietów, więc rotacja niczego nie zamykała; w jego miejsce doszły `V2-MS13`–`V2-MS15`, w tym
> **jedyna pozycja `[P0]` w całej roadmapie**. Sprzątanie dysku (`U-214`) odzyskało 121 GB i dało
> `CLAUDE.md` §21.
>
> **Każdy stan poniżej jest zmierzony w plikach albo w binarkach**, nie przepisany z podsumowań —
> audyt `U-201` (143 twierdzenia, 32 fałszywe), `U-203` (inwentarz sterowników), a dla §2 własne
> odczyty nagłówka PE i repozytorium `rhboot/shim-review` sklonowanego lokalnie.
> Gdzie coś jest prognozą, a nie pomiarem, jest to napisane wprost.

**Legenda scalona** (v1 miała ✅/🚧/⏳/💡, v2 ✅/🟡/🔴 — poniżej jeden zestaw):
✅ zrobione · 🟡 częściowo · 🔴 planowane · 💡 pomysł · ❌ wycofane
🖥️ da się z Maca · 🐧 wymaga Linuksa/WSL2 · ⚙️ wymaga sprzętu · 🔑 wymaga działania operatora

---

## 0. Trzy osie, na których stoi ten plan

Każda pozycja jest klasyfikowana w trzech wymiarach naraz, bo mylenie ich to źródło złudzeń:

1. **Stan** — zrobione / częściowo / planowane (zmierzone).
2. **Gdzie da się to zrobić** — Mac / Linux / dopiero sprzęt / operator.
3. **Co odblokowuje** — bo kolejność wynika z zależności, nie z atrakcyjności.

> **Zasada nadrzędna:** *najpierw zmierz na metalu, potem planuj.* Nic w repozytorium nigdy nie
> działało na fizycznym sprzęcie — każdy zielony ptaszek to QEMU. Etap 0 z
> [`plan-do-sprzetu.md`](docs/archive/hardware-plan.md) jest przed wszystkim innym w tym dokumencie.

---

## 1. Rdzeń systemu E-OS — gdzie jest sam system

### 1.1 Kamienie milowe (wydania)

| wersja | co wnosi | stan |
|---|---|---|
| **v0.1.0 „Genesis"** | baza Redox na nowym upstreamie, boot do logowania, licencja AGPL | ✅ osiągnięte (6 poz. `R-10x`) |
| **v0.2.0 „Identity"** | desktop **Crimson**, OOBE (hasło), branding, przebrandowane ciągi | 🟡 otagowane; otwarte `R-201`, `R-207` |
| **v0.3.0 „Fortify"** | **podpisane obrazy, SBOM, reprodukowalny pipeline wydań** | 🟡 podpisy ✅, reprodukowalność `R-303` otwarta |
| **v0.4.0 „Reach"** | parytet **x86_64**, macierz sprzętowa, pełne pokrycie sterowników | 🔴 otwarte `R-402`, `R-403` |
| **v1.0.0 „Prime"** | **stabilne ABI**, polityka LTS, repozytorium pakietów | 🟡 gałąź `lts/0.1` i polityka istnieją (`R-1002`); ABI dopiero przy 1.0 |

### 1.2 Filary rdzenia

| filar | co to daje | gdzie | stan |
|---|---|---|---|
| **Jądro (mikrojądro Rust)** | naprawione GIC/INTx (`R-F16`/`R-F18`), stabilny rozruch aarch64 | 🖥️ Mac | ✅ |
| **Rozruch → instalacja → login** | `R-601` **UDOWODNIONE** — partycja → instalacja → reboot → login, **3× z rzędu** pod QEMU | 🖥️ Mac | ✅ |
| **x86_64** | buduje **i bootuje** pod TCG (`U-172`); obraz i ISO 1400 MiB zbudowane `U-210` | 🖥️ Mac → ⚙️ metal | 🟡 |
| **Desktop Crimson** | greeter, launcher, taskbar, tray, powiadomienia — **obecne w obrazie i wyrenderowane**; poszczególne panele wciąż otwarte (`R-D01`–`R-D03`, `R-D08`) | 🖥️ Mac | 🟡 |
| **OOBE (pierwszy start)** | wymuszenie hasła **działa i jest zweryfikowane**; tożsamość per-maszyna do zrobienia (`R-602`/`R-606`) | 🖥️ Mac | 🟡 |
| **Szyfrowanie dysku (FDE)** | RedoxFS AES-XTS z akceleracją ARMv8 Crypto (`R-502`) | 🖥️ Mac | ✅ |
| **Podpisy post-kwantowe** | hybryda ed25519 + ML-DSA-65 (`R-503`), klucz wygenerowany i przypięty (`U-196`/`U-197`) | 🖥️ Mac | ✅ |
| **Repozytorium pakietów** | **pierwsza publikacja ZROBIONA** (`R-008`/`U-209`): 78 pakietów, 893 MB, HTTP 200; `50_eos` **aktywne na aarch64**, x86_64 czeka na publikację | 🖥️ Mac + 🔑 | 🟡 |
| **Weryfikacja podpisu u klienta** | ✅ **egzekwowana na bajtach** — hasze blake3 z podpisanego manifestu sprawdzane przed rozpakowaniem, na każdej ścieżce włącznie z `install`, plus licznik i termin ważności indeksu (`V2-MS13`/`V2-MS14`/`V2-MS15`, `U-223`) | 🖥️ Mac | ✅ |
| **Demon aktualizacji `eos-update`** | `R-705` demon, `R-706` transakcja+rollback, `R-704` anti-rollback, `R-707` apply-on-reboot | 🖥️ Mac | 🔴 |
| **Reprodukowalny pipeline wydań** | tag → obraz → wydanie (`R-303`); **bajtowa** reprodukowalność niezweryfikowana | 🐧 CI + 🔑 | 🟡 |
| **Podpisany bootloader / Secure Boot** | ✅ udowodnione kluczem operatora (§2.1), a od `U-212` bootloader **weryfikuje też jądro i initfs** — nietknięty obraz bootuje, jeden zmieniony bajt jest odrzucony | 🖥️ Mac · 🔑 | ✅ |
| **Measured boot / TPM 2.0** | `R-913` — nie istnieje; piąta warstwa zaufania z `docs/reference/keys-and-tokens.md` wciąż pusta | ⚙️ | 🔴 |

### 1.3 Znana niestabilność, powiedziana wprost
- **`R-F23`** — E-OS wywraca się pod akceleracją `hvf` na Apple Silicon pod obciążeniem
  (`synchronous_exception_at_el0`, dwa różne procesy, `-smp 1` też), dlatego cały pomiar idzie
  pod emulacją TCG (~1,9× wolniej — zmierzone, nie „rząd wielkości").
- **`R-601` udowodnione wyłącznie pod QEMU/TCG** — na fizycznym firmware (`R-607`) jeszcze nie.
- **`R-F12`** — bramki CI **raportują, nie blokują**: `only_allow_merge_if_pipeline_succeeds =
  false`, 0 merge requestów w historii, 10 088 commitów prosto na `main`.

---

## 2. Secure Boot i weryfikacja Microsoftu — pełny audyt wobec `rhboot/shim-review`

Cel postawiony wprost: *„żeby nasz system działał na każdym sprzęcie tak, jak powinien"*.
Poniżej jest audyt każdego wymogu z [`rhboot/shim-review`](https://github.com/rhboot/shim-review)
— repozytorium sklonowane lokalnie i przeczytane w całości (README 39 bloków pytań,
`docs/submitting.md`, `docs/reviewer-guidelines.md`, `ISSUE_TEMPLATE.md`) — plus stan certyfikatów
na sierpień 2026.

### 2.1 Co JUŻ mamy (zmierzone, nie deklarowane)  ✅

| wymóg shim-review | stan E-OS | dowód |
|---|---|---|
| **Źródło bootloadera publiczne, przypięte** | ✅ | `recipes/core/bootloader/recipe.toml:4-6` → `eos-bootloader`, rev `b249982f`; toolchain przypięty `nightly-2026-05-24` |
| **Budowane ze źródeł, nie pobierane binarnie** | ✅ | `cookbook.lock:7-8` `fsrule = "source"`; wymusza to bramka `ci-integrity.sh` (check 6) |
| **Cały łańcuch rozruchu open source** | ✅ | AGPL-3.0 (`LICENSE`), fork bootloadera MIT, wszystkie 28 forków publiczne |
| **Projekt podpisuje własne artefakty EFI** | ✅ | `recipes/core/bootloader/recipe.toml:52-65` — podpis w recepturze, w czasie `cook` |
| **Secure Boot udowodniony z kontrolą negatywną** | ✅ | `eos-secureboot-proof.sh`: nasz klucz+podpis → boot; nasz klucz+niepodpisany → odrzucony; obcy klucz+nasz podpis → odrzucony |
| **Oba nośniki pokryte** | ✅ | `U-208`: live ISO **i** zainstalowany `harddrive.img` bootują pod SB; obcy klucz → `Access Denied` |
| **Podpis kluczem operatora** | ✅ | `U-210`: `CN=E-OS Secure Boot`, ważny do 2036-08-25; `sbverify` OK na obu bootloaderach |
| **`SectionAlignment` ≥ 4096** | ✅ | **zmierzone**: `SectionAlignment=4096` — twardy wymóg Microsoftu spełniony |
| **Brak sekcji W+X** | ✅ | **zmierzone**: `.text` R-X, `.data` RW-, `.rdata`/`.reloc` R-- — żadna nie łączy zapisu z wykonaniem |
| **Bit `NX_COMPAT`** | ✅ | **zmierzone**: `DllCharacteristics=0x8160` → `NX_COMPAT` **ustawiony**, plus `DYNAMIC_BASE` i `HIGH_ENTROPY_VA` |
| **Kontakt bezpieczeństwa + proces** | 🟡 | `SECURITY.md` ma prywatne zgłoszenia i SLA (ack ≤72 h, ocena ≤7 d, plan ≤30 d) — brak drugiego kontaktu i ścieżki CVE |
| **Zaufanie do własnych aktualizacji** | ✅ | hybrydowy klucz ed25519+ML-DSA-65 przypięty w obrazie (`keys/eos-repo-sign.pub.toml`) |

> Warto to powiedzieć wprost: **trzy twarde wymogi Microsoftu dotyczące kształtu binarki PE są już
> spełnione** i nikt tego wcześniej nie sprawdził. Bootloader E-OS jest pod tym względem gotowy.

### 2.2 Czego brakuje technicznie  🔴

| brak | co to znaczy | nakład |
|---|---|---|
| **`.sbat`** | shim 16.1 **odmawia załadowania** obrazu bez sekcji `.sbat` (`pe.c:489-497`, `EFI_SECURITY_VIOLATION`). Zmierzone: w całym drzewie **zero** wystąpień SBAT — jedyne trafienie to `sbattach --remove`, czyli nazwa narzędzia. Nasza binarka nie ma tej sekcji. | S |
| **Łańcuch przez shim** | model shim wymaga `shim.efi` jako pierwszego stopnia, a drugi stopień musi wołać protokół weryfikacji shima (`shim_lock` / `EFI_SECURITY2_ARCH_PROTOCOL`) dla wszystkiego, co ładuje dalej | L |
| **Bootloader nie weryfikuje tego, co ładuje** | zmierzone w `src/main.rs`: `load_to_memory()` sprawdza **tylko bajty magiczne** — `\x7FELF` dla jądra i `RedoxFtw` dla initfs. Żadnego podpisu, żadnego hasza. To jest dokładnie to, co recenzenci nazywają „wykonaniem nieuwierzytelnionego kodu". | L |
| **Brak odpowiednika „lockdown"** | pytanie 16 szablonu z podpowiedzią: *„If it does not, we are not likely to sign your shim"*. `eos-kernel` nie ma ładowalnych modułów (to mikrojądro), więc pytanie przekłada się na sterowniki w user-space — i tej historii jeszcze nie ma | XL |
| **Ochrona klucza** | dziś: zwykły plik RSA-2048 bez hasła (`-nodes`). Microsoft wymaga sprzętowego modułu **FIPS 140-2 Level 2** i dwuskładnikowej autoryzacji | M |
| **Podpisany SBOM SPDX w sekcji `.sbom`** | wymóg od 20 października 2025; nazwa firmy w SBOM musi **dokładnie** zgadzać się z nazwą w certyfikacie EV | S–M |
| **Mechanizm unieważniania** | *„strong revocation mechanism for everything the shim loads, directly and subsequently"* — hasze starych binarek do DBX | L |
| **Reprodukowalność bajtowa** | twardy próg: *„nobody will trust and sign a binary that is not reproducible"*. U nas `R-303` mówi wprost, że znaczniki czasu obrazu wciąż się różnią, a `recipe.toml:54` robi **niehermetyczny `apt-get install sbsigntool`** w czasie budowania | M |
| **Bramka Secure Boot w CI** | żaden job w `.gitlab-ci.yml` nie woła `eos-secureboot-proof.sh` — dowód istnieje tylko na laptopie opiekuna | M |
| **Trzy dokumenty kłamią** | `docs/security/threat-model.md:79`, `docs/security/hardening.md:168` i `docs/archive/hardware-plan.md:39-41` wciąż twierdzą, że nic nie podpisuje bootloadera. Recenzent czyta dokumenty bezpieczeństwa — sprzeczność z kodem to sygnał ostrzegawczy o dojrzałości procesu | XS |

### 2.3 Czego brakuje **poza techniką** — i to jest prawdziwa blokada

Te pozycje nie są kwestią kodu i żadna ilość pracy programistycznej ich nie zdejmie:

| wymóg | treść | stan E-OS |
|---|---|---|
| **Osoba prawna** | *„Company/tax register entries or equivalent"* — wpis do rejestru, który recenzent zweryfikuje | 🔴 brak |
| **Certyfikat EV** | do podpisania `.cab` w Microsoft Hardware Dev Center; w zgłoszeniu trzeba podać wystawcę **i** podmiot | 🔴 brak |
| **Dwa kontakty bezpieczeństwa** | dwie osoby, klucze PGP, weryfikacja przez zaszyfrowany mail z losowymi słowami | 🔴 jedna osoba |
| **Trwałość projektu** | wytyczne recenzentów, dosłownie: *„A tiny 1-man outfit may just go away without warning"* | 🔴 projekt jednoosobowy |
| **Uzasadnienie, że shim jest w ogóle potrzebny** | `docs/submitting.md` otwiera pytaniem: *„Are you 100% sure that you need this? … for small deployments it's often possible (and easier!) to add public keys directly into firmware"* — czyli opisem tego, co E-OS **już robi** | 🟡 trzeba obronić |
| **Nietypowy drugi stopień** | *„we really only have experience with using GRUB2 or systemd-boot … asking us to endorse anything else is going to require some convincing"*; recenzenci mają na to osobną etykietę `custom second-stage` | 🔴 własny bootloader w Ruście |

### 2.4 Stan certyfikatów w sierpniu 2026 — i dlaczego to zmienia rachunek

| certyfikat | ważność | rola |
|---|---|---|
| `Microsoft Corporation UEFI CA 2011` | **wygasł 2026-06-27** | podpisywał dotąd wszystkie shimy Linuksa |
| `Microsoft UEFI CA 2023` | do 2038-06-13 | **jedyny**, którym Microsoft podpisuje dziś shim |
| `Microsoft Corporation KEK CA 2011` | **wygasł 2026-06-24** | autoryzował zapisy do `db`/`dbx` |
| `Microsoft Corporation KEK 2K CA 2023` | do 2038-03-02 | następca |

Trzy konsekwencje, które trzeba wypowiedzieć razem:

1. **Okno podwójnego podpisu jest zamknięte.** Microsoft: *„Update 6/26/26: Approved Signing
   Submissions now only return binaries signed with the 2023 UEFI CA."* Shim wydany E-OS dzisiaj
   byłby podpisany **wyłącznie** kluczem 2023.
2. **Maszyna, która ma w `db` tylko CA 2011, takiego shima NIE uruchomi.** To jest dokładne
   przeciwieństwo celu „działa na każdym sprzęcie". Ścieżka shim daje dziś pokrycie **węższe**
   niż w 2024 — i będzie się poszerzać dopiero z wymianą parku maszyn.
3. **Wygaśnięcie to nie unieważnienie.** Firmware sprawdza obecność w `db` i nieobecność w `dbx`,
   **nie sprawdza daty ważności**. Maszyny, które dziś bootują, będą bootować dalej; Microsoft
   wprost odradza usuwanie CA 2011 z `db`.

### 2.5 Wniosek i rekomendacja

**Ścieżka shim nie jest dziś dla E-OS osiągalna** — i blokują ją rzeczy pozatechniczne
(osoba prawna, certyfikat EV, HSM, dwa kontakty, trwałość), a nie brak kodu. Zmierzony czas
przejścia recenzji, gdy wszystko się ma: **od ~5,5 tygodnia do ~7 miesięcy** (273 zgłoszenia
z etykietą „accepted", 42 otwarte), wymagane **trzy niezależne recenzje, w tym jedna akredytowana**.

Dlatego rekomendacja jest dwutorowa i **nie unieważnia** [`ADR-0005`](docs/adr/0005-secure-boot-without-microsoft.md):

- **Tor A (obowiązujący, działa dziś):** własny klucz + zaufanie kontrolowane przez właściciela.
  To jest **gotowe i udowodnione** (§2.1). Na aarch64 i na własnym sprzęcie daje instalację bez
  jednego kliknięcia w BIOS-ie; na obcym x86_64 kosztuje jeden krok właściciela.
- **Tor B (przygotowanie, bez zobowiązania):** zrobić **te elementy z §2.2, które mają wartość
  same w sobie**, niezależnie od tego, czy zgłoszenie do Microsoftu kiedykolwiek nastąpi —
  SBAT, weryfikacja podpisu w bootloaderze, klucz na tokenie, reprodukowalność, bramka w CI,
  naprawa trzech kłamiących dokumentów. Każda z nich podnosi bezpieczeństwo E-OS **teraz**.

To jest zapisane jako [`ADR-0006`](docs/adr/0006-path-to-microsoft-verification.md).

### 2.6 Zadania (`V2-MS`)

| poz. | co | dlaczego warto **niezależnie** od Microsoftu | gdzie | stan |
|---|---|---|---|---|
| **V2-MS01** 🖥️ | **Sekcja `.sbat`** w obu bootloaderach UEFI | ✅ **ZROBIONE** (`U-218`): 158 B, `eos-bootloader,1,E-OS,…`, dokładana **przed** podpisem (Authenticode pokrywa całą binarkę); oba podpisy nadal ważne, BIOS nietknięty. Daje własną ścieżkę unieważniania wersji zamiast czekania na DBX | 🖥️ Mac | ✅ |
| **V2-MS02** 🖥️ | **Bootloader weryfikuje jądro i initfs** podpisem, nie bajtami magicznymi | ✅ **ZROBIONE i udowodnione** (`U-212`): nietknięty obraz bootuje, jedna zmiana bajtu w jądrze → **odmowa**. Zakres celowo wąski — patrz §11 | 🖥️ Mac · 🔑 | ✅ |
| **V2-MS03** 🖥️ | **Naprawić trzy dokumenty**: `threat-model.md`, `hardening.md`, `plan-do-sprzetu.md` | ✅ **ZROBIONE** (`U-211`) — twierdziły, że nikt nie podpisuje bootloadera; nieprawda od `U-207`. Przy okazji `U-216` poprawił `docs/reference/keys-and-tokens.md`, który mylił się w dwóch punktach o warstwie 2 | 🖥️ Mac | ✅ |
| **V2-MS04** 🖥️ | **Bramka Secure Boot w CI** — wpiąć `eos-secureboot-proof.sh` do `.gitlab-ci.yml` | dowód przestaje zależeć od jednego laptopa | 🐧 CI | 🔴 |
| **V2-MS05** 🖥️ | **Hermetyczne podpisywanie** — `sbsigntool` z obrazu bazowego zamiast `apt-get` w czasie `cook` | ✅ **ZROBIONE** (`U-218`): wersja narzędzia podpisującego łańcuch rozruchu jest teraz częścią przypiętego opisu builda, a krok nie wymaga sieci | 🖥️ Mac | ✅ |
| **V2-MS06** 🔑 | **Klucz na tokenie sprzętowym** (PKCS#11, YubiKey/Nitrokey) zamiast pliku bez hasła | klucz podpisujący rozruch leży dziś jako zwykły plik | 🔑 operator | 🔴 |
| **V2-MS07** 🖥️ | **Reprodukowalność bajtowa** obrazu i binarki EFI + publikowanie haszy | `R-303`; warunek konieczny każdej recenzji, ale i tak potrzebny do wydań | 🐧 CI | 🔴 |
| **V2-MS08** 🖥️ | **SBOM SPDX** generowany przy każdym buildzie (dziś statyczny dla 0.1.0 i cicho się starzeje) | uczciwy spis składników; wymóg Microsoftu od 10.2025 | 🖥️ Mac | 🔴 |
| **V2-MS09** 🖥️ | **Odpowiednik lockdown** dla mikrojądra: opisać i wymusić, czego user-space nie może po włączonym SB | jedyne pytanie shim-review z podpowiedzią „bo inaczej nie podpiszemy" | 🖥️ Mac | 🔴 |
| **V2-MS10** 🔑 | **Decyzja biznesowa**: osoba prawna + certyfikat EV + drugi kontakt bezpieczeństwa | dopiero to odblokowuje zgłoszenie; nie jest to praca programistyczna | 🔑 operator | 🔴 |
| **V2-MS11** 🖥️ | **Chainload przez shim** + protokół weryfikacji (dopiero po V2-MS10) | ostatni krok toru B; bez V2-MS10 bezcelowy | 🖥️ Mac | 💡 |
| **V2-MS13** 🖥️ | **Egzekwować blake3 z podpisanego manifestu przy instalacji** — dziś `PkgarBackend::install()` sprawdza pakiet **wyłącznie** kluczem pobranym z tego samego hosta; w całym `pkg-lib` są **dwa** porównania blake3 i **żadne nie jest kontrolą integralności** (`library.rs:144`, `package_state.rs:278` — oba decydują „czy aktualizować") | **To jest prawdziwa dziura, nie V2-MS12.** Kto przejmie host pakietów, zostawia oryginalne `repo.toml`+`.sig` (zweryfikują się), podmienia `id_ed25519.pub.toml` na swój i przepodpisuje pakiety — klient instaluje dowolny kod, a przypięty klucz hybrydowy **niczego nie zatrzymuje**. Działa **dziś na aarch64**, bo źródło jest aktywne. Dopiero ta zmiana sprawia, że warstwa 3 chroni treść, a nie samą listę nazw | 🖥️ Mac | ✅ |
| **V2-MS14** 🖥️ | **`pkg install <nazwa>` w ogóle nie weryfikuje manifestu** — robi to tylko `update` i `-a` (`pkg-cli/src/main.rs:187-191` → `process_packages()` woła `get_all_package_names()` wyłącznie przy `all == true`) | najczęstsza operacja użytkownika omija jedyną działającą weryfikację | 🖥️ Mac | ✅ |
| **V2-MS12** 🔑 | **Klucz podpisujący pakiety** — cookbook **generuje go sam**, jest przechowywany **jawnym tekstem** (`skey` = 128 znaków hex; `docs/reference/keys-and-tokens.md` twierdził inaczej), a bramka z `U-213` wykrywa jego utratę i rozjazd | 🟡 **Kopia zapasowa ISTNIEJE i jest zweryfikowana** (`U-216`): `~/.eos-keys/eos-pkg-signing.secret.toml`, suma zgodna co do bajtu, na **innym nośniku** niż oryginał. Zostaje: (a) trzecia kopia **poza tym Makiem** — dziś obie leżą na jednym komputerze, (b) uczynienie go kluczem operatora, ale **po `V2-MS13`**, bo sama rotacja nie zamyka dziury i kosztuje republikację 642 MB | 🔑 operator | 🟡 **[P2]** |
| **V2-MS15** 🖥️ | **Brak ochrony przed rollback/freeze, wbrew publicznej deklaracji** — `repo.toml` ma tylko `build_id`, zero znacznika czasu, licznika i wygaśnięcia; host może w nieskończoność serwować starą, **poprawnie podpisaną** parę indeks+pakiety | README publikowany przez `publish-repo-pages.sh` obiecuje ochronę przed *freeze* i *rollback*, której **nie ma** — a to tekst kierowany na zewnątrz | 🖥️ Mac | ✅ |

## 3. Sterowniki — co mamy, czego brakuje, co zbudować

### 3.1 Co JEST w obrazie (zmierzone w `base.pkgar`, obie architektury)  ✅

| kategoria | sterowniki w obrazie | uwaga |
|---|---|---|
| **Dysk NVMe** | `nvmed` | obie arch., root bootuje z NVMe w QEMU |
| **Dysk SATA/AHCI** | `ahcid`, `ided` | **tylko x86_64** — na aarch64 wpisy wskazują na nieobecne binaria (`R-803`) |
| **Dysk VirtIO** | `virtio-blkd` | obie arch., zweryfikowane |
| **Pamięć USB** | `usbscsid` | obie arch.; E-OS **włączył** to, co upstream wyłączył |
| **Karta SD (RPi)** | `bcm2835-sdhcid` | **tylko aarch64/Raspberry Pi**, nigdy nie związany na sprzęcie |
| **USB host** | `xhcid`, `usbhubd`, `usbctl` | obie arch. |
| **Wejście USB** | `usbhidd` | klawiatura/mysz; obie arch. |
| **Wejście PS/2** | `ps2d` | **tylko x86_64** (usługa poprawnie bramkowana po architekturze) |
| **Sieć Intel** | `e1000d` (+id `e1000e` 0x10D3) | id `e1000e` **tylko x86_64**; QEMU q35 |
| **Sieć Realtek** | `rtl8168d`, `rtl8139d` | obie arch.; „obecne, brak modelu QEMU do testu" |
| **Sieć Intel 10G** | `ixgbed` | obie arch., nietestowane |
| **Sieć VirtIO** | `virtio-netd` | obie arch. |
| **Sieć USB (RNDIS)** | `usbnetd` | obie arch.; dodatek E-OS, pcap-verified |
| **Ekran** | `vesad` (framebuffer), `virtio-gpud` (2D) | obie arch. — **`virtio-gpud` JEST w obrazie**, wbrew częstemu twierdzeniu |
| **Dźwięk** | `ihdad` (Intel HDA), `ac97d`/`sb16d` (x86_64) | `ihdad` — codec RIRB timeout blokuje dźwięk w QEMU |
| **RAID-1** | `raid1d` | **autorski komponent E-OS**, nie upstream; tryb zdegradowany, resync |

### 3.2 Martwe wpisy do posprzątania (`R-803`)  🟡

Na **aarch64** obraz wiezie pliki `pcid.d/ac97d.toml`, `vboxd.toml` oraz initfs `ahcid`/`ided`,
których **binaria nie istnieją** dla tej architektury (Makefile kopiuje wszystkie `config.toml`
bez względu na architekturę). To nie awaria, ale bałagan, który każe zgadywać. **Zadanie:**
warunkowe kopiowanie `pcid.d` po architekturze.

### 3.3 Sterowniki dysków — co zbudować, co to daje

| poz. | co zbudować | co to daje | gdzie | stan |
|---|---|---|---|---|
| **V2-D01** | `ahcid`/`ided` **dla aarch64** albo usunięcie martwych wpisów | uczciwy obraz aarch64; SATA na płytach ARM | 🖥️ Mac (QEMU) | 🟡 |
| **V2-D02** | **NVMe: SMART/health, TRIM/discard, multi-queue** | trwałość i wydajność na realnych SSD; dziś `nvmed` jest minimalny | 🖥️ Mac (QEMU) → ⚙️ walidacja | 🔴 |
| **V2-D03** | **SDHCI/eMMC generyczny** (nie tylko RPi) | karty SD i eMMC w laptopach/tabletach x86 | ⚙️ wymaga krzemu | 🔴 |
| **V2-D04** | **RAID 0/5/10 z parzystością** (`R-912`, rozszerza `raid1d`) | realna macierz; dwa dyski w QEMU wystarczą do testu | 🖥️ Mac (QEMU) | 🔴 planowane |
| **V2-D05** | **USB4 / Thunderbolt storage** (`R-932`) | zewnętrzne obudowy NVMe, hot-plug PCIe | ⚙️ wymaga krzemu | 🔴 |
| **V2-D06** | **UFS** (Universal Flash Storage) | pamięć w nowoczesnych urządzeniach mobilnych | ⚙️ wymaga krzemu | 🔴 brak w roadmapie w ogóle |

### 3.4 Nowe technologie — magistrale, które blokują resztę

| poz. | co | co odblokowuje | gdzie | stan |
|---|---|---|---|---|
| **V2-N01** | **Magistrala I2C + I2C-HID** (`R-916`) | **touchpady laptopów**, czujniki, Type-C PD — dziś **nie istnieje żadna** | ⚙️ realny sprzęt | 🔴 blokada T3 |
| **V2-N02** | **TPM 2.0 (TIS/CRB) + measured boot** (`R-913`) — **piąta, wciąż pusta warstwa zaufania** z `docs/reference/keys-and-tokens.md` | measured boot, sealing kluczy; `swtpm` w QEMU pozwala **wstępnie** zbudować na Macu | 🖥️ Mac (swtpm) → ⚙️ PCR na sprzęcie | 🔴 |
| **V2-N03** | **Podpisany bootloader / Secure Boot** (`R-F27`) — ✅ **ZROBIONE** (`U-206`–`U-210`) | podpis w recepturze; live ISO **oraz** system zainstalowany bootują pod Secure Boot kluczem operatora (`CN=E-OS Secure Boot`, do 2036), odrzucane z obcym. Dalsze kroki: §2.6 | 🖥️ Mac · 🔑 | ✅ |

---

## 4. Co da się z Maca, co wymaga Linuksa, co wymaga sprzętu

To rozstrzyga, **czego można dotknąć dziś**, a co czeka na inny host albo na fizyczny komputer.

### 4.1 🖥️ Da się z tego Maca (podman + QEMU/TCG)
- Zbudować **i uruchomić** obraz **aarch64** — pełna, sprawdzona ścieżka.
- Zbudować i uruchomić **x86_64** pod emulacją TCG (wolno, ale działa od `U-172`).
- Zbudować bazowe aplikacje COSMIC (`cosmic-edit`/`files`/`term`).
- Wypalić pendrive z `redox-live.iso` (`dd` — każdy host to potrafi).
- Cały samosprawdzający się toolchain (bramki, podpisy, reproducery).

### 4.2 🐧 Wymaga Linuksa (lub Windows + WSL2)
- **Rozszerzone aplikacje COSMIC** (`cosmic-store`/`settings`/`reader`) — ich `fontconfig → host:gperf`
  toolchain jest publikowany **tylko** dla `x86_64-linux`; na tym aarch64-Macu daje 404.
- **Szybka, akcelerowana emulacja (KVM)** — macOS ma tylko `hvf`, który wywraca się pod obciążeniem
  (`R-F23`) i daje ~1,9×; sensowna szybkość x86_64 CI wymaga runnera z KVM.

### 4.3 ⚙️ Wymaga fizycznego sprzętu
- **Pierwszy rozruch na metalu** — nic tu nigdy nie działało na sprzęcie.
- Dowód, że x86_64 działa na realnym pececie (zbudowane i boot-smoke pod emulacją, ale nie na metalu).
- Walidacja `vesad`/GOP, NVMe/AHCI, `xhcid`, kart sieciowych — to ma sens dopiero na firmware.
- **Komputer stacjonarny** (bo brak I2C-HID = brak touchpada). Secure Boot **nie jest już powodem** —
  bootloader jest podpisany; na obcym x86_64 zostaje jeden krok właściciela (wgranie certyfikatu).

---

## 5. `eos-guard` → pakiet bezpieczeństwa

### 5.1 Co `eos-guard` robi DZIŚ (zmierzone w binarce)  ✅
Kontroler integralności plików: hashuje `blake3` pliki w `/usr/bin` i `/etc`, trzyma wzorzec w
SQLite, na żądanie skanuje i klasyfikuje Ok/New/Modified/Removed, ostrzega o setuid, wykrywa
własną manipulację. GUI w Slint. **To wszystko** — jednozadaniowy, nie pakiet.

### 5.2 Czego brakuje do pakietu, i co jest **realne**
Kluczowe ustalenie: **większość narzędzi „recon" i „blue team" to czysty user-space** — E-OS ma
schematy `tcp:`, `udp:`, `icmp:`, `file:`, a `argon2` jest już w drzewie. Ale trzy klasy są
**zablokowane brakiem prymitywu**, i trzeba to powiedzieć wprost, zamiast obiecywać.

**✅ Realne teraz (schematy istnieją, sprawdzone):**
| narzędzie | na czym stoi |
|---|---|
| Port scanner / Network scanner | `tcp:` connect (zweryfikowany) |
| Ping & Traceroute (ping) | `icmp:echo` (jest w `netutils`) |
| Banner grabbing | `tcp:` connect + read |
| WHOIS | `tcp:` :43 |
| DNS Lookup / Subdomain enum | `udp:` :53 (zweryfikowany) |
| Password strength / generator / hashing | `argon2` w drzewie, plik+CPU |
| YARA / Sigma / Log analyzer / Event log parser | plik + CPU |
| Metadata extractor / Hash calculator | plik + CPU |
| Malware hash / IOC / URL reputation checker | `tcp:`+TLS jako klient API |
| File integrity checker | **już jest** — to `eos-guard` |
| File recovery / Memory dump **analyzer** | z dostarczonego **obrazu** (plik) |

**🟡 Realne z pracą (prymityw jest, ale root-only albo do potwierdzenia):**
| narzędzie | czego wymaga |
|---|---|
| Traceroute (pełny) | potwierdzić, że `icmp:` dostarcza Time-Exceeded |
| SQL Injection / XSS / Website scanner | klient HTTP(S) — do napisania na `tcp:`+TLS |
| SYN/stealth scan | surowy `ip:` (`smoltcp RawSocket`, root-only od `U-144`) |
| File recovery **na żywym dysku** | schemat `disk:`/`nvme:`, root-only |
| Memory acquisition **na żywym procesie** | `proc:` + root; pełny RAM przez ścieżkę jądra |
| Vulnerability / Cloud / Compliance / Docker-image scanner | klient zdalnego API HTTPS (port SDK) |
| Brute-force / Rate limiter / Alert / SIEM / Threat-intel dashboard | logika app + `eos-devd` do inwentarza |

**🔴 Zablokowane brakiem prymitywu (nie obiecywać, dopóki nie powstanie):**
| narzędzie | brakujący prymityw |
|---|---|
| **Packet sniffer / pcap** | brak schematu przechwytywania w trybie promiscuous, brak BPF/tap |
| **USB Activity Tracker (na żywo)** | brak szyny zdarzeń hot-plug/uevent |
| **Docker Security Scanner (lokalny)** | brak runtime OCI/kontenerów w Redoksie |

> **Wniosek dla `eos-guard`:** rozbudowa idzie od rzeczy plik+CPU i `tcp:`/`udp:` (dowożalne),
> przez klienty HTTPS, po prymitywy, które trzeba najpierw **dołożyć do systemu** (capture, hot-plug).
> „Ransomware simulator (safe lab)" i „CSRF demo lab" są bezpieczne jako aplikacje edukacyjne.

### 5.3 Kolejność (`V2-S`)
- **V2-S01** 🖥️ — biblioteka `tcp:`/`udp:`/`icmp:` + pierwsze CLI: port scan, DNS, ping, whois, banner.
- **V2-S02** 🖥️ — plik+CPU: hash calculator, metadata extractor, YARA/Sigma matcher, log analyzer.
- **V2-S03** 🖥️ — klient HTTP(S) → website/SQLi/XSS/cert checker, URL/IOC reputation.
- **V2-S04** 🖥️ — dashboard „Personal Cybersecurity" spinający powyższe (Slint, jak `eos-guard`).
- **V2-S05** ⚙️ — prymitywy: capture promiscuous i szyna hot-plug → sniffer, USB tracker (zmiana w jądrze).

---

## 6. `eos-notes` → szyfrowany notatnik

### 6.1 Co `eos-notes` robi DZIŚ (zmierzone)  ✅
Notatki tekstowe (tytuł + treść) w SQLite WAL, autozapis, lista w panelu, filtr podłańcuchem,
usuwanie. GUI Slint. **Brak** Markdown, **brak** szyfrowania, tabów, tagów, linków, załączników.
Do wielkiej listy życzeń jest bardzo daleko — i uczciwie to trzeba powiedzieć.

### 6.2 **Część funkcji system już ma** — nie pisać ich od nowa
To jest najważniejsze dla planu: kilka „funkcji notatnika" to naprawdę **funkcje systemu**, które
wystarczy podłączyć.

| funkcja z listy | co system już daje |
|---|---|
| Szyfrowanie treści | **RedoxFS AES-XTS** (FDE, `R-502`) + hybrydowy podpis `R-503` — silnik jest |
| Sandboxing wtyczek / „zero-trust" | **model capability + namespace** Redoksa — to fundament OS, nie funkcja app |
| Weryfikacja integralności notatki | **`eos-guard`** (blake3) — do podłączenia, nie do napisania |
| Podpis Ed25519 | narzędzie `eos-repo-sign` (ed25519 + ML-DSA-65) — ta sama krypto |
| Memory zeroization | crate `zeroize`, `Rust memory safety` — praktyka całego drzewa |
| Izolacja procesów, IPC-only | **architektura mikrojądra** — już tak działa |

### 6.3 Realna kolejność (`V2-Nx`), od fundamentu
| poz. | co | dlaczego tu |
|---|---|---|
| **V2-NT01** 🖥️ | **Markdown**: edycja, Live Preview, Source Mode, bloki kodu, tabele, listy, checklisty | rdzeń — bez tego reszta wisi w próżni |
| **V2-NT02** 🖥️ | **Szyfrowanie per-notatka** (AES-256-GCM / XChaCha20, klucz z Argon2id) | najważniejsza cecha; krypto jest w drzewie, brak tylko integracji |
| **V2-NT03** 🖥️ | **Organizacja**: foldery, tagi zagnieżdżone, właściwości, szablony, Daily Notes | zamienia edytor w system wiedzy |
| **V2-NT04** 🖥️ | **Linki `[[…]]` + backlinki + Graph View** | to jest „drugi mózg", sedno modelu Obsidian |
| **V2-NT05** 🖥️ | **FTS** (pełnotekst), Quick Switcher, Command Palette | nawigacja skalująca się do tysięcy notatek |
| **V2-NT06** 🖥️ | **Bases** (widoki tabela/karty/lista z metadanych) | notatki jako baza danych |
| **V2-NT07** 🖥️ | **Canvas** (nieskończone płótno) | wizualna burza mózgów |
| **V2-NT08** 🖥️/⚙️ | **Zaawansowane bezpieczeństwo**: recovery seed (BIP39), auto-lock, decoy vault, steganografia, HMAC, audit log | warstwa nad V2-NT02; część (anti-screenshot) wymaga wsparcia OS |
| **V2-NT09** 🖥️ | **Załączniki szyfrowane, eksport PDF/HTML/MD, import Notion/Evernote/CSV** | wymiana ze światem |
| **V2-NT10** 🖥️ | **System wtyczek** (SDK Rust, sandbox w namespace) + E2EE sync | rozszerzalność i synchronizacja zero-knowledge |

> **Uwaga wprost:** anti-screenshot, anti-screen-recording i „blur on blur" wymagają współpracy
> serwera wyświetlania (Orbital); dopóki tego API nie ma, są **niewykonalne po stronie samej
> aplikacji**. Nie obiecuję ich jako gotowych — są w V2-NT08 jako zależne od OS.

---


---

## 7. Normy i standardy — co z listy warto, a co jest pułapką

Lista norm została przeanalizowana w całości. Wynik jest asymetryczny i trzeba to powiedzieć
wprost: **kilka pozycji ma świetny stosunek wartości do nakładu, kilka to zobowiązanie prawne,
a większość certyfikacji to dla projektu tej wielkości pułapka na lata i setki tysięcy dolarów.**
Umieszczenie ich wszystkich na roadmapie jako celów byłoby nieuczciwe.

### 7.1 Zrób to — najlepszy stosunek wartości do nakładu

| poz. | norma | co daje E-OS | nakład | stan |
|---|---|---|---|---|
| **V2-STD01** 🖥️ | **POSIX (ISO/IEC 9945)** — zmierzyć `relibc` zestawem `os-test` | ✅ **ZMIERZONE, pełny przebieg** (`U-222`): **4267/5650 = 75,5 %** wg POSIX.1-2024; **bez 207 testów `udp`**, które zawodzą przez brak karty sieciowej w obrazie — **78,4 %**. Najlepiej: `stdio` 100 %, `io` 94 %, `include` 83 %. Najgorzej: **`pty` 0/29** (terminale niezaimplementowane — `TODO: ioctl TIOCSCTTY`), `namespace` 18 %, `basic/complex` 0/66. **933 z 1382 niezaliczeń to brakujące nagłówki**, nie błędne działanie. Znalezione **3 wieszacze spoza listy upstreamu** — bez nich zestaw nie kończy się w ogóle | 🖥️ Mac | ✅ |
| **V2-STD02** 🖥️ | **Audyt `unsafe` + Miri + fuzzing parserów** | postawa E-OS jest już **lepsza niż upstream** (`overflow-checks=true`, `panic=abort`, ASLR mmap, W^X przy syscall) — brakuje spisu bloków `unsafe` z inwariantem i UB-testów | **S–M** | 🔴 |
| **V2-STD03** 🖥️ | **NIST SP 800-53 Rel. 5.2.0** jako *lista kontrolna projektowa*, nie certyfikacja | nowe kontrole 5.2.0 (`SI-07(12)` integralność aktualizacji, `SA-24`, `SA-15(13)` proweniencja) mapują się **jeden do jednego** na `R-701`/`R-702`/`R-703`, które i tak robimy | **S** — strona mapowania | 🔴 |
| **V2-STD04** 🖥️ | **NIAP PP_OS v4.3** jako samoocena (nie certyfikacja) | to, czego realnie żądają zamówienia publiczne w USA — i czytelna lista wymagań, którą można sobie odhaczyć **dzisiaj**. Połowę `FPT` E-OS prawdopodobnie już spełnia | **S–M** | 🔴 |
| **V2-STD05** 🖥️ | **Determinizm czasowy — pierwszy pomiar** | zmierzone u upstreamu: z 196 programów Open POSIX TPS **buduje się 46, nie buduje 150**; każdy test `sched_setscheduler` nie kompiluje się. W E-OS nie ma **ani jednego** pomiaru opóźnień | **M** | 🔴 |

### 7.2 Zobowiązanie prawne — jedyne na liście

| poz. | norma | co to znaczy | nakład | stan |
|---|---|---|---|---|
| **V2-STD06** | **European Accessibility Act — dyrektywa (UE) 2019/882** | **obowiązuje od 28 czerwca 2025** i **wymienia systemy operacyjne wprost** (art. 2 ust. 1 lit. a); art. 3 pkt 38 obejmuje także wolnostojące oprogramowanie. Wiąże, gdy E-OS jest udostępniany na rynku UE *„w ramach działalności handlowej"* — **bezpłatność nie zwalnia**, decyduje handlowy charakter | XL (program, nie funkcja) | 🔴 |
| **V2-STD07** 🖥️ | **API dostępności (AccessKit)** — warunek konieczny wszystkiego powyżej | dziś desktop Slint/Orbital nie ma **żadnego** API dostępności. Bez niego załącznik I pkt 2 lit. n EAA (*„interfejs dla technologii wspomagających"*) jest nie do spełnienia, a `EN 301 549` pkt 11.5.2 nieosiągalny. **AccessKit jest natywnie rustowy i Slint go wspiera** — to realna ścieżka | XL (6–18 mies.) | 🔴 |
| **V2-STD08** 🖥️ | **EN 301 549 / WCAG 2.2 AA** jako specyfikacja inżynierska | to jest dokument, który mówi **konkretnie co zbudować**; zbudowanie do 2.2 AA pokrywa naraz EAA, Section 508 i amerykański Title II bez przeróbek | M–L | 🔴 |

> **Uczciwie:** czysto niekomercyjne wydanie AGPL prawdopodobnie nie podpada pod EAA. Ale w chwili,
> gdy pojawi się jakakolwiek forma komercjalizacji, ten obowiązek jest **już aktywny**, a nie
> przyszły. Lepiej wiedzieć o tym teraz niż po pierwszej fakturze.

### 7.3 Mamy to architektonicznie — opisać, nie budować

| norma | dlaczego E-OS jest już blisko | czego brakuje |
|---|---|---|
| **Ochrona typu SELinux/AppArmor** | E-OS ma **lepszy substrat** niż LSM doklejony do monolitu: wszystko jest schematem, sterowniki/FS/sieć/wyświetlanie w user-space, uprawnienie = zbiór osiągalnych schematów. `raw` jest już bramkowany do roota (`U-144`) | brak języka polityki, brak audytu odmów, brak przejść domen przy `exec` |
| **Zero-Trust Kernel** | spełnione **na granicy syscall** (mikrojądro, sterowniki w user-space, brak ambientnej władzy) | **to nie jest norma** — nie ma dokumentu NIST ani ISO o „zero-trust kernel". Cytować SP 800-207 jako źródło zasady i mówić wprost, że zastosowanie do jądra to nasze własne ujęcie. Realna luka: **brak IOMMU/SMMU**, więc sterownik w user-space wciąż może zrobić DMA gdzie chce |
| **Secure Boot & TPM 2.0** | Secure Boot ✅ udowodniony z kontrolą negatywną — lepiej niż większość projektów na tym etapie | TPM 2.0 nie istnieje (`R-913`); dopóki go nie ma, „dysk jest zaszyfrowany" nie znaczy „ten dysk w tej maszynie" |
| **UEFI** | bootloader to poprawny `PE32+` dla `${ARCH}-unknown-uefi`, bootuje przez OVMF/EDK2 na obu architekturach, a §2.1 dokłada trzy zmierzone atrybuty PE | brak testów UEFI SCT, brak `EFI_MEMORY_ATTRIBUTE_PROTOCOL` |
| **ACPI** | realna, nietrywialna robota: `R-401f` zrobił routing `_PRT` INTx (log: *128 entries*), aarch64 bootuje pod ACPI **i** device tree, `acpid` ma działający interpreter AML dla EC | brak S3, brak `_PSR`/baterii/stref termicznych, brak wielosegmentowego ECAM (`R-809`) |

### 7.4 Świadome „nie" — i dlaczego, żeby nie wracało

| norma | powód odrzucenia |
|---|---|
| **Common Criteria / EAL** | 175–750 tys. USD i 7–24 miesiące na poziom EAL4. E-OS ma zerowy pakiet dowodowy (ADV/AGD/ALC/ATE/AVA). **PP_OS jako samoocena** (V2-STD04) daje 80% wartości za 1% kosztu |
| **FIPS 140-3** | **dwa nasze algorytmy nie są zatwierdzone**: BLAKE3 nie ma statusu FIPS w ogóle, a Argon2 nie jest zatwierdzonym KDF do haseł (SP 800-132 chce PBKDF2). Certyfikacja wymagałaby wymiany rdzenia kryptografii na **gorszy** |
| **ISO/IEC 27001** | certyfikuje **organizację**, nie oprogramowanie: przegląd zarządczy, niezależny audyt wewnętrzny, zdefiniowane role. Dla projektu jednoosobowego ta machineria nie ma sensu |
| **DO-178C, IEC 61508, IEC 62304, ISO 26262** | wszystkie certyfikują **komponent w kontekście produktu**, nie system operacyjny. Certyfikowalnym artefaktem byłoby samo mikrojądro (skala seL4: 3–5+ osobolat), bez kompozytora i menedżera pakietów. Do tego dochodzą blokady konkretne: brak szeregowania priorytetowego i **zero pomiarów opóźnień** — „freedom from interference" w wymiarze czasowym nie da się nawet *argumentować* |
| **Ferrocene** | jedyna pozycja bezpośrednio rustowa i tym bardziej warto być precyzyjnym: **żaden cel `*-unknown-redox` nie jest kwalifikowany**, kwalifikowany host to wyłącznie x86-64 Linux/glibc, a certyfikowana jest **tylko biblioteka `core`** — `alloc`, `std` i `test` są nieskwalifikowane. E-OS używa `alloc` i `std` wszędzie |
| **LSB** | standard **martwy**: ostatnie wydanie 5.0 w 2015, Debian porzucił w 2015, Ubuntu poszło za nim, były opiekun w 2023 napisał, że projekt „jest w zasadzie porzucony" |
| **ADA Title III** | nie ma normy technicznej pod Title III dla oprogramowania, a system operacyjny nie jest „miejscem publicznym". Pozycja jest tu wyłącznie jako **kontrola zakresu** — żeby „zgodność z ADA" nie posłużyła kiedyś za uzasadnienie prac, których ta ustawa nie wymaga |
| **ISO 21434 / UNECE R155** | poza zakresem (desktop), ale warto odnotować strategicznie: motoryzacja i przemysł to **jedyny** rynek, gdzie mikrojądro w Ruście z małym TCB ma naturalną przewagę |
| **Vulkan / DirectX / DDI** | konformancja Vulkana to program adopcyjny: **30 000 USD** plus stos, którego nie ma. `R-930` mówi to precyzyjnie: `grep vulkan|opengl|GEM|shader = 0`; najpierw musi powstać odpowiednik KMS/DRM |
| **OCI (kontenery)** | `runtime-spec` jest **z definicji linuksowy** — jego prymitywy izolacji *to* przestrzenie nazw i cgroups. Ale uwaga: E-OS ma **lepiej dopasowany prymityw, tylko wyłączony** — `recipes/core/contain`. Cel to nie konformancja OCI, tylko włączenie i opisanie własnej izolacji |

## 8. Co system ma „sam z siebie" (i co z tego wynika)

Pytanie z prośby: *czy system sam posiada niektóre z tych funkcji?* Tak — i to zmienia plan,
bo część pracy to **podłączenie**, nie **napisanie**:

- **Szyfrowanie dysku** — RedoxFS AES-XTS (`R-502`), z akceleracją ARMv8 Crypto.
- **Podpisy i integralność** — `eos-repo-sign` (ed25519 + ML-DSA-65), `eos-guard` (blake3).
- **Izolacja** — model capability, namespace per proces, IPC-only, brak `sudo:` bez uprawnień.
- **Sieć user-space** — `smoltcp`, schematy `tcp:`/`udp:`/`icmp:` — fundament pod narzędzia recon.
- **Bezpieczeństwo pamięci** — cały stos w Rust; `zeroize` dla kluczy.

---


---

---

## 9. Scalony rejestr zadań — wszystkie otwarte pozycje `R-*` z ROADMAP v1

`ROADMAP.md` liczył **143 pozycje: 67 zrobionych, 16 w toku, 43 planowanych, 16 pomysłów,
1 wycofana.** Zrobione zostają w archiwum; **wszystkie 75 nieukończonych jest poniżej.**
Mapowanie znaczników: 🚧 → 🟡, ⏳ → 🔴, 💡 → 💡, ❌ → ❌.

### 9.1 Kamienie milowe i repozytorium

| poz. | co | stan |
|---|---|---|
| `R-201` | pełna strona dokumentacji, zielone CI, hardening repo | 🟡 |
| `R-207` | używalny zestaw narzędzi „z pudełka" po świeżej instalacji | 🟡 |
| `R-303` | reprodukowalny pipeline wydań (tag → obraz → wydanie); **bajtowa** reprodukowalność otwarta → `V2-MS07` | 🟡 |
| `R-402` | rozszerzone pokrycie sprzętu/sterowników | 🔴 |
| `R-403` | macierz testów na realnym sprzęcie | 💡 |
| `R-1002` | gałąź LTS + polityka stabilności — **gałąź `lts/0.1` i polityka istnieją**; otwarte jest samo zobowiązanie ABI przy 1.0 | 🟡 |
| `R-1003` | repozytorium pakietów — **lista „pozostało" była nieaktualna**: pierwsza publikacja ✅ (`R-008`), `50_eos` wpięte na aarch64 ✅, klucz wygenerowany ✅. **Realnie zostaje: publikacja x86_64 i ekosystem aplikacji** | 🟡 |

### 9.2 Poprawki korektowe i bezpieczeństwa (`R-Fxx`)

| poz. | co | stan |
|---|---|---|
| `R-F04` | uszczelnić arytmetykę `raid1d` i split-brain — poprawki bezpieczeństwa weszły (`U-068`); zostaje `raid1d resolve` + `clippy::arithmetic_side_effects` w całym repo. **Blokuje `R-912`/`V2-D04`** | 🟡 |
| `R-F05` | numeracja i dryf dokumentacji; **istotne dla tego scalenia** — zdefiniować mapowanie `R-NNN`↔`U-NNN`, tym bardziej że doszła przestrzeń `V2-*` | 🟡 |
| `R-F12` | bramki CI raportują zamiast blokować (`only_allow_merge_if_pipeline_succeeds = false`, 0 MR-ów). **XS nakładu, systemowa konsekwencja**: każda inna bramka integralności działa po publikacji i po mirrorze | 🟡 |
| `R-F23` | niestabilność pod `hvf` na Apple Silicon — patrz §1.3 | 🟡 |
| `R-F27` | Secure Boot — **ZAMKNIĘTE** (`U-206`–`U-210`), przeniesione do §2 jako `V2-N03` ✅ | ✅ |
| `R-F28` | `scripts/ventoy.sh` nie potrafi zbudować obrazu E-OS (`ARCHS=(i686 x86_64)`, `CONFIGS=(demo desktop)`, `CONFIG_NAME=eos` nie występuje). **Rozważyć usunięcie zamiast naprawy** — `dd` z §4.1 i tak działa | 🔴 |
| `R-F25` | ❌ **WYCOFANE** (`U-181`) — to nie była usterka, tylko zepsuty przyrząd pomiarowy | ❌ |

### 9.3 Powłoka graficzna (`R-Dxx`)

| poz. | co | stan |
|---|---|---|
| `R-D01` | natywny panel sterowania **E-OS Settings** (orbital/orbclient, bez libcosmic) — **zbudowany i działa**, 9 paneli wyrenderowanych. **Jedyne miejsce, gdzie mogą zamieszkać `R-708` i `R-806`** | 🟡 |
| `R-D02` | funkcjonalny tray — ikony i klik do Settings ✅; zostaje stan na żywo (sieć z netstacka, głośność przez `audiod` — **blokowane brakiem dźwięku w QEMU**) | 🟡 |
| `R-D03` | demon powiadomień — minimalny działa (`eos-notifyd`, toast); zostaje schemat `notify:` zamiast odpytywanego pliku, kolejka, ikony/akcje | 🟡 |
| `R-D08` | zawartość launchera zweryfikowana; **zostaje pełny przepływ live → greeter → installer-gui → instalacja**, nigdy nietestowany od końca do końca (`R-601` udowodnił ścieżkę TUI, nie tę) | 🟡 |
| `R-D09` | okno netsurfa nieskalowalne (`R-D06` usunął `SDL_RESIZABLE`, żeby ominąć use-after-munmap) | 🔴 |

### 9.4 Instalator i pierwszy start (`R-6xx`)

| poz. | co | stan |
|---|---|---|
| `R-602` | kreator OOBE — wymuszenie hasła ✅ zweryfikowane na każdej ścieżce logowania; zostaje tożsamość per-maszyna | 🟡 |
| `R-603` | konto/hostname/locale we front-endach instalatora | 🔴 |
| `R-604` | zabezpieczenia przed destrukcją — dziś kasowanie całego dysku chowa się za gołym menu numerycznym bez identyfikacji dysku | 🔴 |
| `R-605` | skierować instalator na podpisane repo E-OS, świadome architektury | 🔴 |
| `R-606` | tożsamość per-maszyna: unikalny hostname (dziś każda instalacja to `eos`), machine-id, klucze SSH hosta | 🔴 |
| `R-607` | realny rozmiar bloku (4Kn) + macierz instalacji na prawdziwym firmware — `DiskWrapper::open` zawsze raportuje 512 | 🔴 |
| `R-608` | poprawić dokumentację instalacji, żeby zgadzała się z GUI | 🔴 |
| `R-610` | przepiąć zależności builda instalatora na źródła E-OS | 🔴 |
| `R-609` | ręczne partycjonowanie / instalacja obok (dual-boot) — dziś tylko kasowanie całego dysku | 💡 |

### 9.5 System aktualizacji (`R-7xx`)

| poz. | co | stan |
|---|---|---|
| `R-701` | własne źródło aktualizacji — **publikacja ✅ (`U-209`), `50_eos` aktywne na aarch64 (`U-210`)**; zostaje x86_64 | 🟡 |
| `R-702` | przypiąć klucz publiczny repo, zabić TOFU — klucz **wpięty w oba obrazy** (`/etc/pkg/eos-repo-sign.pub.toml`), połowa tajna u operatora, para **zweryfikowana podpisem próbnym** (`U-224`) | ✅ |
| `R-703` | **weryfikacja podpisanego manifestu u klienta** — połowa wydawcy gotowa; pełny fetch+verify niezłapany na żywo | 🟡 |
| `R-704` | anti-rollback / świeżość + przypinanie haszy — dziś **poprawnie podpisany STARSZY pkgar wciąż się instaluje** | 🔴 |
| `R-705` | demon `eos-update` + cienkie CLI (check→resolve→verify→download→stage→apply) | 🔴 |
| `R-706` | transakcyjne wgrywanie ze stanem przejściowym i jednym krokiem wycofania | 🔴 |
| `R-707` | baza/jądro stosowane przy restarcie z awaryjnym powrotem — **dziś jądro podmienia się w locie, zła aktualizacja lub zanik zasilania może zabić realny dysk** | 🔴 |
| `R-708` | panel „Ustawienia → Aktualizacja" (mieszka w `R-D01`) | 🔴 |
| `R-709` | testy integracyjne decyzji o aktualizacji — dziś zero pokrycia e2e | 🔴 |
| `R-711` | rotacja/unieważnianie kluczy na urządzeniu — pkgar wiąże pakiet z **dokładnie jednym** kluczem, bez keyringu i bez listy unieważnień | 🔴 |
| `R-712` | dokumentacja przepływu aktualizacji dla użytkownika i administratora | 🔴 |
| `R-710` | sloty A/B roota + aktualizacje różnicowe | 💡 |

### 9.6 Menedżer sterowników (`R-8xx`)

| poz. | co | stan |
|---|---|---|
| `R-801` | demon inwentarza `eos-devd` (`/scheme/devices`) — scalić `pcid`, `xhcid` i `hwd` w jeden czytelny spis | 🔴 |
| `R-802` | podpisany katalog sterowników (device-ID → pakiet), własny pkgar podpisany kluczem hybrydowym | 🔴 |
| `R-803` | uszczelnić dopasowywanie wobec niezaufanego katalogu — panika naprawiona (`U-137`); **zostaje sprzątanie martwych wpisów `pcid.d` na aarch64** (§3.2) | 🟡 |
| `R-804` | rozbić sterowniki na osobne pakiety pkgar (dziś wszystko w `base.pkgar`) | 🔴 |
| `R-805` | `pcid` wiążący na żądanie, bez restartu | 🔴 |
| `R-806` | GUI menedżera sterowników (Ustawienia → Sterowniki), instalacja **wyłącznie** z podpisanego repo | 🔴 |
| `R-807` | trwały spis „urządzenie obecne, brak sterownika" | 🔴 |
| `R-808` | wiązanie urządzeń platformowych w `hwd` (ACPI `_HID`/`_CID`, DT `compatible`) | 🔴 |
| `R-809` | wielosegmentowa enumeracja PCI (ECAM/MCFG) — dziś `pcid` skanuje tylko magistralę 0, 0x80 i mostki | 🔴 |
| `R-811` | naprawić założenie `hwd` o `acpid` na aarch64 — `acpid` startuje wewnątrz `AcpiBackend::new`, więc **nigdy nie rusza na głównym celu deweloperskim** | 🔴 |
| `R-810` | A/B sterowników + watchdog cofający po nieudanym rozruchu | 💡 |

### 9.7 Łączność i warstwy sprzętowe (`R-9xx`)

| poz. | co | stan |
|---|---|---|
| `R-903` | IPv6 od końca do końca — netstack kompilowany wyłącznie `proto-ipv4` | 🔴 |
| `R-904` | **zapora / filtr pakietów** — netstack wystawia `ip`/`udp`/`tcp`/`raw` (raw włączony) z **zerowym filtrowaniem**; dotkliwa luka jak na system „security-first" | 🔴 |
| `R-905` | wiele kart sieciowych / multi-homing | 🔴 |
| `R-906` | odnawianie dzierżawy DHCP (T1/T2) — `dhcpd` jest jednorazowy, długo działająca maszyna cicho traci adres | 🔴 |
| `R-907` | `e1000e` (8086:10d3, domyślna karta q35) w bazowym katalogu `e1000d` | 🔴 |
| `R-910` | [T2] sterowniki wielogigabitowe (RTL8125 2,5G) | 🔴 |
| `R-911` | [T2] USB Audio Class (`usbaudiod`) — weryfikowalne w QEMU przez `-device usb-audio` | 🔴 |
| `R-912` | [T2] programowy RAID 0/5/10 (rozszerza `raid1d`) → `V2-D04`; **blokowane przez `R-F04`** | 🔴 |
| `R-913` | [T2/T3] TPM 2.0 + measured boot → `V2-N02`; piąta warstwa zaufania | 🔴 |
| `R-914` | [T2] sprzętowa akceleracja SHA dla weryfikacji podpisów pkgar | 🔴 |
| `R-916` | **[T3-blokada] magistrala I2C + I2C-HID** → `V2-N01`; blokuje czujniki, touchpady laptopów i Type-C PD; warunek `R-932` i `R-935` | 🔴 |
| `R-917` | [T2/T3] zarządzanie kolorem + wiele monitorów — **jedyna pozycja wyświetlania, która NIE potrzebuje brakującej akceleracji 3D**, bo warstwa modeset już jest | 🔴 |
| `R-923` | [T2] zweryfikować na krzemie sterowniki „obecne, ale niezwiązane": `ihdgd`, `bcm2835-sdhcid`, `rtl8168d`, `ixgbed`. **To pozycja o uczciwości** — „Present" w macierzy znaczy dziś „skompilowane", nie „działa" | 🔴 |
| `R-918` | [T3] API sterowania LED-ami na istniejącym sterowniku EC | 💡 |
| `R-920` | [T3] stos Bluetooth LE (HCI/L2CAP/SDP/GATT — dziś zero) | 💡 |
| `R-921` | [T3] pierwszy chipset Wi-Fi (rozpoznanie) | 💡 |
| `R-922` | [T3] uśpienie ACPI S3 + bateria/temperatury (dziś `acpid` umie tylko wyłączanie) | 💡 |
| `R-924` | [T3] poszerzyć zasięg architektur (RISC-V; ścieżka HVF/KVM aarch64) | 💡 |
| `R-930` | [T4] podłoże akceleracji GPU 3D/compute — `grep vulkan\|opengl\|GEM\|shader = 0` | 💡 |
| `R-931` | [T4] jakość obrazu: HDR / VRR / wysokie odświeżanie — wszystko zależne od `R-930` | 💡 |
| `R-932` | [T4] USB4 v2 / Thunderbolt 5 / USB-C PD 240 W → `V2-D05` | 💡 |
| `R-933` | [T4] NPU / lokalny stos AI — niemożliwe przed `R-930` | 💡 |
| `R-934` | [T4] modem 5G/eSIM, NFC, UWB | 💡 |
| `R-935` | [T4] biometria sprzętowa — większość zależna od nieobecnego I2C (`R-916`) | 💡 |
| `R-936` | [T4] przyszłość 2026–2028: Wi-Fi 8, Bluetooth 7, USB4 v3, PCIe 7, CXL 3 | 💡 |

### 9.8 Sprzeczności wykryte przy scalaniu (rozstrzygnięte tutaj)

Scalenie ujawniło pięć miejsc, gdzie oba dokumenty mówiły co innego. Rozstrzygnięcia:

1. **`R-F27` / `V2-N03`** — v1 miał ⏳, v2 „🟡 czeka na klucz". **Oba nieaktualne**: `U-210` zamknął
   to kluczem operatora. → **✅**
2. **Desktop Crimson** — v2 stawiał ✅, v1 trzymał cztery otwarte `R-Dxx`. ✅ dotyczyło *obecności
   w obrazie*, nie *kompletności*. → **🟡**, z pozycjami wypisanymi w §9.3.
3. **`R-1002` LTS** — v2 stawiał 🔴, a gałąź `lts/0.1` i polityka **istnieją**. → **🟡**
4. **`R-1003` repozytorium** — jego lista „pozostało" wymieniała trzy rzeczy zrobione gdzie indziej
   w tym samym pliku. → przepisane uczciwie w §9.1.
5. **`R-705` vs `R-706`** — v2 przypisywał „transakcyjne wgrywanie z wycofaniem" do `R-705`;
   w v1 wycofanie to zakres `R-706`. → rozdzielone w §9.5.
## 10. Zależności — co przed czym

```
Etap 0: pierwszy rozruch na metalu (plan-do-sprzetu.md)
   └─→ V2-N03 Secure Boot ✅ ─→ instalacja bez BIOS-u (aarch64 i własny sprzęt)
   └─→ V2-D01/D02 dyski ─→ realna instalacja
   └─→ V2-N01 I2C-HID ─→ laptopy (touchpad)
Secure Boot, tor B: V2-MS03 dokumenty → V2-MS01 SBAT → V2-MS02 weryfikacja jądra
                  → V2-MS05 hermetyczność → V2-MS04 CI → V2-MS07 reprodukowalność
                  → V2-MS06 token → [V2-MS10 decyzja biznesowa] → V2-MS11 chainload
Normy:  V2-STD01 pomiar POSIX → porty aplikacji;  V2-STD07 AccessKit → V2-STD08 EN 301 549 → V2-STD06 EAA
eos-guard: V2-S01 sieć → V2-S02 plik/CPU → V2-S03 HTTP → V2-S04 dashboard → V2-S05 prymitywy (jądro)
eos-notes: V2-NT01 Markdown → V2-NT02 szyfrowanie → NT03 organizacja → NT04 linki → … → NT10 wtyczki/sync
```

---

## 11. Czego ten plan świadomie NIE obiecuje

- **Nic tu nie działało na sprzęcie.** Wszystko powyżej to prognoza z kodu i danych upstreamu,
  dopóki Etap 0 tego nie zmieni w pomiar.
- **Trzy klasy narzędzi bezpieczeństwa są zablokowane** brakiem prymitywu OS (sniffer, USB-tracker,
  docker) — wymagają najpierw zmiany w systemie, nie tylko nowej aplikacji.
- **GPU 3D, HDR, USB4, akceleracja graficzna** pozostają zależne od sprzętu i poza ścieżką QEMU.
- **Secure Boot jest zrobiony, ale własnym kluczem.** Na obcym x86_64 wciąż potrzebny jest
  **jeden krok właściciela** (wgranie certyfikatu w firmware). Ścieżka „działa od razu na każdym
  pececie" wymaga podpisu Microsoftu, który — jak pokazuje §2.3 — blokują dziś sprawy
  pozatechniczne, nie kod.
- **Podpis pakietów chroni treść — od `U-223`.** Hasze blake3 z podpisanego manifestu są
  egzekwowane na bajtach, które faktycznie się instalują (`V2-MS13`), na **każdej** ścieżce, bo
  `install` też pobiera i weryfikuje manifest (`V2-MS14`), a indeks niesie licznik i termin
  ważności, więc poprawnie podpisany **stary** indeks jest odrzucany (`V2-MS15`). Zamknięty atak:
  kto przejmie host pakietów, nie odtworzy już „manifest OK, pakiet OK" podstawiając własny klucz
  i przepodpisując pakiety — hasz nie zgadza się z tym, co podpisał wydawca.
- **Czego to nie obejmuje, i trzeba to mówić wprost:** znacznik antycofkowy leży w zwykłym pliku
  obok przypiętego klucza, więc **root na maszynie może go skasować**. To ochrona przed
  napastnikiem w sieci, nie przed lokalnym. Źródło bez zdalnych repozytoriów jest z egzekwowania
  indeksu **świadomie zwolnione** — w trakcie budowania obrazu `redox_installer` ma już wpisany
  przypięty klucz, a `repo.toml.sig` jeszcze nie istnieje; bez tego wyjątku **każdy build by padał**.
- **Publikacja repozytorium NIE jest zablokowana na kluczu — wcześniejszy zapis był błędny (`U-224`).**
  Połowa tajna **istnieje** w magazynie operatora poza repozytorium, a nie w `keys/`, gdzie jej
  szukałem; para została **zweryfikowana podpisem próbnym**: ed25519 i ML-DSA-65 obie przechodzą
  wobec połowy publicznej z repozytorium, a po zmianie jednego bajtu obie odmawiają (kod wyjścia 1).
  Klucz publiczny jest **wpięty w oba obrazy** jako `/etc/pkg/eos-repo-sign.pub.toml`, a wartości
  w `config/x86_64` i `config/aarch64` zgadzają się z `keys/eos-repo-sign.pub.toml` co do znaku.
  `publish-repo.sh` **zawodzi bezpiecznie**: bez `EOS_REPO_SIGN_KEY` odmawia spakowania
  niepodpisanego indeksu, a obejście wymaga jawnego `EOS_ALLOW_UNSIGNED=1`.
- **Czego naprawdę brakuje do publikacji:** zbudowanych pakietów. Zdalne
  `gh0s777tt.github.io/eos-pkg-x86_64` serwuje dziś **samo README** (Pages włączone, każda ścieżka
  daje 404), a lokalna kopia repozytorium przepadła przy porządkach `U-214` — więc **nie ma dziś
  czego cofać ani zamrażać**, a ochrona z `V2-MS15` zacznie działać z pierwszym prawdziwym wydaniem.
- **Weryfikacja jądra i initfs istnieje (`V2-MS02`), ale NIE znaczy „zweryfikowany łańcuch rozruchu".**
  `initfs` niesie wyłącznie sterowniki dyskowe; `xhcid`, `e1000d`, `usbhidd`, `usbscsid`, `ihdad`,
  `rtl8168d` i dziesięć innych ładuje się z **niepodpisanego** roota po jego zamontowaniu, przez
  `pcid` — a bez IOMMU podmieniony sterownik dostaje DMA, czyli ten sam efekt innym plikiem.
- **Brak anty-rollbacku**: starsze, poprawnie podpisane i podatne jądro nadal przejdzie.
- **Na BIOS-ie to nie jest kotwica zaufania**, tylko świadectwo naruszenia — stage1/2/3 to surowe
  sektory, których nic nie uwierzytelnia.
- **W trybie live** cały obraz dysku jest wczytywany do RAM **bez weryfikacji**, zanim jądro
  zostanie z niego odczytane.
- **Żadna certyfikacja z §7 nie jest obiecana.** §7.1 to pomiary i samooceny, nie certyfikaty;
  §7.4 to lista świadomych odmów z uzasadnieniem.
- **Desktop nie ma API dostępności** — dopóki `V2-STD07` nie powstanie, zgodność z EAA i
  EN 301 549 jest nieosiągalna, nie „częściowa".

---

## 12. Instalator na goły sprzęt, kreator i aktualizacje A/B — epiki, kamienie milowe, zadania

- **Status:** Propozycja — do zatwierdzenia. Nic z tego nie jest zaimplementowane.
- **Data:** 2026-08-30
- **Wpina w rejestr cztery specyfikacje, w trzech torach:**
  [`docs/architecture/installer.md`](docs/architecture/installer.md) ·
  [`docs/architecture/installer-wizard.md`](docs/architecture/installer-wizard.md) +
  [`docs/architecture/installer-profiles.md`](docs/architecture/installer-profiles.md) ·
  [`docs/architecture/system-updates.md`](docs/architecture/system-updates.md).
- **Decyzje, na których stoi:** `ADR-0007`–`ADR-0011` (istnieją, `docs/adr/`; przypisanie
  w §12.1 D6) oraz dwie decyzje, które **ADR-a nie mają** i są tam nazwane.
- **Czego ta sekcja NIE robi:** nie powtarza projektu z tych dokumentów, nie otwiera na nowo
  `ADR-0004`–`ADR-0011` i **nie wymyśla nowych nazw dla pracy, która ma już pozycję
  `R-*`**. Robi jedno: zamienia cztery dokumenty projektowe w epiki → kamienie milowe → zadania
  z zależnościami, tak żeby dało się je pojedynczo odhaczyć albo pojedynczo obalić.

### 12.0 Konwencja tej sekcji

**Stan** — zestaw scalony z nagłówka tego pliku: ✅ zrobione · 🟡 częściowo · 🔴 planowane ·
💡 pomysł · ❌ wycofane. Znaczniki v1 (🚧/⏳) mapują się na 🟡/🔴 dokładnie tak, jak zrobiło to
§9; **nie wprowadzam trzeciego zestawu do jednego dokumentu.**

**Gdzie** — 🖥️ Mac/QEMU · 🐧 Linux/CI · ⚙️ fizyczny sprzęt · 🔑 działanie operatora.

**Praca** — notacja `[priorytet·rozmiar·gdzie]` jak w `ROADMAP.md` (`[P1·M·any]`, `[P2·M·metal]`).

**Zdolność** — jeden znacznik na pozycję, taki sam jak w czterech specyfikacjach:

| Znacznik | Znaczenie |
|---|---|
| **JEST** | działa dzisiaj — z dowodem: plik:linia, nazwa binarki, pozycja `R-*` |
| **DO ZBUDOWANIA** | wykonalne na Redoksie bez nowego podsystemu |
| **NOWY PODSYSTEM** | wymaga zbudowania czegoś, czego Redox nie ma w ogóle |
| **NIEREALNE DZIŚ** | zależy od ekosystemu, którego nie ma i nie będzie szybko |

Bez tej kolumny rejestr obiecywałby instalator linuksowy na systemie, który nie ma ani jednego
z linuksowych klocków. `[NIEZWERYFIKOWANE]` znaczy: nie potwierdziłem tego w drzewie — i przy
każdym takim znaczniku stoi, co sprawdzić.

---

### 12.1 Najpierw kolizja identyfikatorów — bez tego rozstrzygnięcia nie wolno dopisać ani jednego `R-7xx`

**Dwie** przestrzenie nazw `R-*` mają dziś po dwa różne znaczenia. Pierwsza jest znana; drugą
znalazłem, pisząc tę sekcję, i jest tego samego rodzaju.

#### (a) `R-70x` — `ROADMAP` kontra `docs/update-system-design.md`

Zmierzone w `docs/update-system-design.md:165-172` (tabela §7) wobec `ROADMAP.md:339-351`:

| ID | `docs/update-system-design.md` §7 | `ROADMAP.md` / `ROADMAP-v2.md` §9.5 |
|---|---|---|
| `R-701` | wpiąć `eos-repo-sign` w `publish-repo-pages.sh` | uruchomić własne źródło aktualizacji |
| `R-702` | `verify_manifest()` w `pkg-lib`, koniec TOFU | **przypiąć klucz repo**, koniec TOFU |
| `R-703` | usługa `eos-updated` + `/scheme/eos-update`, staging z dziennikiem | **kliencka weryfikacja podpisanego manifestu** |
| `R-704` | **rollback** pokoleniowy (migawka zastąpionych plików) | **anti-rollback** / świeżość + przypięcie hasza |
| `R-705` | panel Ustawienia → Aktualizacja | demon `eos-update` + CLI |
| `R-706` | harmonogram, polityki auto-apply, wybór kanału | **transakcja ze stanem przejściowym + wycofanie jednym krokiem** |
| `R-708` | **sloty A/B + delty** | panel Ustawienia → Aktualizacja |

Jedyny numer, który w obu dokumentach znaczy to samo, to `R-707` (baza/jądro stosowane przy
restarcie z awaryjnym powrotem). Pozostałe sześć — nie.

`R-704` znaczy raz „wycofanie", raz „ochrona przed wycofaniem" — **znaczenia niemal
przeciwne**. Każde zdanie w projekcie zawierające `R-704` jest dziś dwuznaczne.

#### (b) `R-80x` — `ROADMAP` kontra `docs/driver-manager-design.md` *(nowe znalezisko)*

`docs/driver-manager-design.md:9` deklaruje wprost: *„Scope codes: R-800 … R-814 (this document
defines the range)"* — czyli **rezerwuje piętnaście numerów**, których `ROADMAP` używa do czego
innego. Zmierzone:

| ID | `docs/driver-manager-design.md` | `ROADMAP-v2.md` §9.6 |
|---|---|---|
| `R-801` | podpisany katalog sterowników (`:91`) | demon inwentarza `eos-devd` |
| `R-802` | uszczelnienie dopasowywania (`:154`) | podpisany katalog sterowników |
| `R-803` | `pcid` wiążący na żądanie (`:216`) | uszczelnienie dopasowywania + martwe wpisy `pcid.d` |
| `R-806` | pakowanie sterownika jako pkgar (`:232`) | GUI menedżera sterowników |
| `R-809` | Ustawienia + panel Sterowniki (`:269`) | wielosegmentowa enumeracja PCI (ECAM) |

Rozjazd **nie jest jednolitym przesunięciem** — i to jest gorsze niż gdyby był, bo nie da się
go naprawić jedną operacją. Zmierzone przełożenie: `R-801`→`R-802` i `R-802`→`R-803`
(przesunięcie o jeden), ale `R-803`→**`R-805`**, `R-806`→**`R-804`**, `R-809`→**`R-806`**.
`R-811…R-814` są w tamtym dokumencie zarezerwowane zbiorczo na weryfikację na krzemie
(`:271`), a w `ROADMAP-v2.md` §9.6 istnieje z tego zakresu tylko `R-811` — o zupełnie innej
treści (założenie `hwd` o `acpid` na aarch64).

#### Rozstrzygnięcia

**D1 — obowiązuje numeracja `ROADMAP.md`/`ROADMAP-v2.md`.** Powód nie jest arbitralny: to jest
rejestr projektu, do którego odsyła `CLAUDE.md` §2, i jedyne miejsce, gdzie stan pozycji jest
utrzymywany. Dwa dokumenty projektowe są opisami podsystemów, nie rejestrem.

**D2 — starszych dokumentów NIE przenumerowujemy.** Przepisanie identyfikatorów w
`docs/update-system-design.md` i `docs/driver-manager-design.md` zerwałoby odsyłacze z
`CHANGELOG.md` i z pozostałych dokumentów, a `CLAUDE.md` §2 reguła 4 wymaga, żeby poprawka była
**widoczna**, nie cicha. Zamiast tego oba dostają na górze blok:

```
> **NUMERACJA ARCHIWALNA — nie obowiązuje.** Identyfikatory `R-*` w tym pliku znaczą co innego
> niż w `ROADMAP-v2.md`, która jest rejestrem projektu (§12.1). Tabela odpowiedników niżej.
> Aktualny projekt tej warstwy: `docs/architecture/system-updates.md`.
```

plus tabelę odpowiedników z §12.1(a)/(b). Koszt: dwa nagłówki. Zysk: przestaje istnieć zdanie,
którego nie da się jednoznacznie przeczytać.

**D3 — wolne zakresy po tej decyzji.** Zmierzone przed napisaniem tej sekcji:
`grep -rho '<ID>' --include='*.md' --include='*.toml' --include='*.sh' --include='*.yml' .`
dawał **0** dla każdego numeru mintowanego niżej. **Tego pomiaru nie da się już powtórzyć
dosłownie** — te numery żyją teraz w tym pliku, w czterech specyfikacjach i w `ADR-0007`–`ADR-0011`.
Powtarzalna wersja: `grep -rl '<ID>' --include='*.md' .` musi zwracać **wyłącznie** pliki z tej
serii; trafienie w `ROADMAP.md`, w `docs/update-system-design.md` albo w
`docs/driver-manager-design.md` znaczy, że numer jednak był zajęty.

| rodzina | zajęte w rejestrze | zajęte poza rejestrem | pierwszy wolny bezpieczny |
|---|---|---|---|
| `R-6xx` | `R-601`…`R-610` | — | **`R-611`** — żaden dokument nie deklaruje zakresu w tej rodzinie |
| `R-7xx` | `R-701`…`R-712` + `R-701a` | `docs/update-system-design.md` §7 używa `R-701`…`R-708` na inną pracę | **żadnego nie mintuję** — patrz D4 |
| `R-8xx` | `R-801`…`R-811` (`R-800` w rejestrze **nie występuje**; `R-812`–`R-814` też nie) | `driver-manager-design.md:9` rezerwuje **zakresowo** `R-800`…`R-814` | **`R-815`** — pierwszy poza zadeklarowanym cudzym zakresem |
| `R-Dxx` | `R-D01`…`R-D12` | — | **`R-D13`** |

**D4 — w rodzinie `R-7xx` nie powstaje ani jeden nowy numer.** Cała praca z
`system-updates.md` przypina się do istniejących `R-704`…`R-712`, a jedyne „nowe" identyfikatory
to **rozcięcie `R-710` na `R-710a`/`R-710b`**, które proponuje sam
`docs/architecture/system-updates.md` §1.5 i które nie dokłada trzeciego znaczenia: `R-710` już
dziś znaczy *„sloty A/B roota + aktualizacje różnicowe"*, a rozcięcie tylko rozdziela te dwie
połowy, bo mają **różne zależności** (różnicowe nie potrzebują `R-707`, sloty potrzebują).
Adoptuję to rozcięcie jako wiążące.

**D5 — bramka, która ma paść.** Do `scripts/ci-integrity.sh` dochodzi **kontrola 12** (zmierzone:
plik ma dziś kontrole `0`…`11`, banery `# ── N.`): każdy plik
w `docs/`, który używa identyfikatorów `R-[0-9]{3}` **w znaczeniu innym niż rejestr**, musi nieść
nagłówek z D2. Wersja mechanizowalna i minimalna: `grep -q 'NUMERACJA ARCHIWALNA'` w
`docs/update-system-design.md` **i** `docs/driver-manager-design.md`, inaczej kontrola pada
z nazwą pliku. **Jak ta kontrola zawodzi:** usuń nagłówek z jednego pliku → czerwone z jego
nazwą; usuń `grep` z `PATH` → `FAIL (instrument):`, nigdy „złamany niezmiennik" (`CLAUDE.md`
§13, wzorzec z `U-177`). Dziś takiej kontroli **nie ma**, więc rozjazd jest ciszą — dokładnie
tą klasą usterki, którą §9.8 wyłapało ręcznie przy scalaniu.

**D6 — ADR-y do tych decyzji. `ADR-0007`…`ADR-0011` już istnieją** (zmierzone `ls docs/adr/`,
2026-08-30) i **nie są tym, co wcześniejsza wersja tej tabeli im przypisywała**. Tamta wersja
twierdziła, że `docs/adr/` kończy się na `ADR-0006` i że numery 0007–0011 są dopiero
„zarezerwowane" — oba zdania były fałszywe, a przypisanie treści rozjeżdżało się z rzeczywistymi
dokumentami przy `ADR-0008` i `ADR-0010`. Stan zmierzony, z tytułów plików:

| numer | plik i faktyczna decyzja |
|---|---|
| `ADR-0007` | `0007-bootloader-i-nosnik-instalacyjny.md` — bootloader nośnika instalacyjnego i systemu zainstalowanego |
| `ADR-0008` | `0008-system-plikow-i-uklad-partycji.md` — system plików korzenia i **układ partycji** (ESP, root, `/home`, swap, rezerwa pod A/B) |
| `ADR-0009` | `0009-mechanizm-aktualizacji-systemu.md` — transakcja z dziennikiem teraz, sloty A/B potem |
| `ADR-0010` | `0010-stos-szyfrowania.md` — **stos szyfrowania dysku** (AES-XTS-128, Argon2id, 64 sloty klucza) |
| `ADR-0011` | `0011-architektura-kreatora-instalacji.md` — jeden silnik, jeden rdzeń, dwa frontendy |

**Dwie decyzje, na których stoją kamienie milowe, NIE MAJĄ ADR-a** — i to jest brak, nie
przeoczenie w zapisie:

| decyzja bez ADR-a | gdzie dziś mieszka | który kamień na niej stoi |
|---|---|---|
| kolejność transakcji instalacji: **root i weryfikacja przed ESP** | `installer.md` §6.2 (pięć faz) | **M2**, a częściowo już `R-612a` w M1 |
| profile i funkcje jako **rozszerzenie** istniejącego TOML-a, nie drugi system | `installer-profiles.md` §1.1 + §1.3 („Odrzucone warianty") | **M4** |

Do czasu, aż powstaną, zależność kamienia jest **na sekcję specyfikacji**, nie na numer ADR-a.
Jeżeli przy zatwierdzaniu te decyzje dostaną własne ADR-y (`ADR-0012`, `ADR-0013` — pierwsze
wolne), **popraw tę tabelę, a nie kamienie milowe**: zależność jest na decyzję, nie na numer.

---

### 12.2 Trzy epiki

| epik | co dowozi | specyfikacja | rodziny `R-*` | stan |
|---|---|---|---|---|
| **EP-1 — Nośnik instalacyjny jako produkt** | pendrive, który realny człowiek pobiera, sprawdza podpisem, wypala i instaluje z niego na realny dysk | `installer.md` | `R-601`, `R-604`, `R-607`, `R-608`, `R-609`, **`R-611`–`R-615`**, `R-F28` | 🔴 |
| **EP-2 — Kreator instalacji i model profili** | jeden silnik, dwa frontendy bez rozjazdu; dane funkcji i profili jako **jedno** źródło prawdy dla kreatora, dokumentacji i trybu nienadzorowanego | `installer-wizard.md`, `installer-profiles.md` | `R-603`, `R-604`, `R-605`, `R-606`, `R-608`, `R-609`, `R-D08`, `R-711`, `R-1010`, **`R-815`**, **`R-D13`** | 🔴 |
| **EP-3 — Aktualizacje: transakcja, aktywacja przy restarcie, sloty A/B** | aktualizacja, której przerwanie nie zostawia cegły; wycofanie jednym poleceniem; dopiero na końcu A/B | `system-updates.md` | `R-704`–`R-712`, `R-710a`/`R-710b`, **`R-816`**, oparte o `R-701`, `R-303`, `R-503`, `R-606`, `V2-MS12` | 🔴 |

**Dlaczego trzy, a nie jeden.** Mają różne stanowiska dowodowe. EP-1 kończy się na ⚙️ metalu
i bez niego jest niedowiedziony. EP-2 jest w całości 🖥️ dowodliwy pod QEMU. EP-3 jest 🖥️ do
etapu E3 włącznie, a od E4 (`R-707`) wymaga ⚙️, bo bootloadera nie da się dowieść w pętli GUI
pod Mac-QEMU (`system-updates.md` §9).

**Czego te epiki celowo nie obejmują:** Secure Boot poza tym, co z niego wynika dla nośnika
(rozstrzygnięte w `ADR-0005`/`ADR-0006`, tor B w §2.6), oraz warstwy sterowników (`R-8xx`) poza
**dwiema** pozycjami, których te dokumenty potrzebują i które nie mają dziś domu: `R-815`
(kanał komend do dysków, warunek pełnej identyfikacji dysku) i `R-816` (nadzorca procesów,
warunek klasy pakietów `service`). Obie leżą w rodzinie `R-8xx`, bo dotyczą sterowników
i cyklu życia usług, a nie instalatora ani aktualizacji.

---

### 12.3 Kamienie milowe — z jawnymi zależnościami

Zasada porządkująca, wzięta z `system-updates.md` §9 i obowiązująca tu wszystkie trzy epiki:
**każdy kamień kończy się stanem lepszym od poprzedniego nawet wtedy, gdy następny nigdy nie
powstanie.**

| kamień | co dowozi | wymaga | gdzie | stan |
|---|---|---|---|---|
| **M1 — „pendrive, który instaluje na realny dysk"** | najmniejszy pionowy plaster: nazwany, podpisany nośnik → rozruch na fizycznym pececie → instalacja na wewnętrzny dysk → reboot **z wyjętym nośnikiem** → `eos login:` | `ADR-0007` (bootloader nośnika), `ADR-0008` (układ partycji); `R-601` ✅ (dowód `U-176`); `V2-N03` ✅ (podpisany bootloader); **jedna fizyczna maszyna x86_64** | 🖥️ + 🐧 + ⚙️ + 🔑 | 🔴 |
| **M2 — „przerwana instalacja nie zostawia cegły"** | transakcja pięciofazowa z dziennikiem na ESP, wznawialność, weryfikacja ładunku ścieżki blokowej, tryb ratunkowy i sprawdzenie nośnika | **M1** (bo sprawdzenie nośnika porównuje się z `SHA256SUMS` z `R-611b`), `installer.md` §6.2 (**decyzja bez ADR-a**, §12.1 D6), `R-607a` | 🖥️ + ⚙️ | 🔴 |
| **M3 — „kreator: jedna prawda dla GUI i TUI"** | maszyna stanów S0–S10, logika wyboru dysku **w bibliotece**, bariery `R-604`, konta/hostname/locale, tożsamość per-maszyna, bramka parytetu GUI↔TUI | **M1**, `ADR-0011` (granica silnik↔frontend), `ADR-0010` (co ekran S5 może obiecać), `R-D08` (przepływ GUI nigdy nietestowany end-to-end), `R-604a` z M1 | 🖥️ | 🔴 |
| **M4 — „profile i tryb nienadzorowany"** | model danych profili i funkcji w TOML-u z dziedziczeniem i blokadami, walidator, migracje, ekran różnicy, plik odpowiedzi zapisywany przez kreator, i18n | **M3**, `installer-profiles.md` §1.1/§1.3 (**decyzja bez ADR-a**, §12.1 D6), `R-D13`, `R-711` (dla unieważniania podpisu profilu), `R-1010` (piaskownica importu — **nie dowieziona**, patrz §12.9) | 🖥️ | 🔴 |
| **M5 — „aktualizacje: przestań tracić dane i domknij weryfikację"** (E0+E1) | atomowy zapis stanu, `curl` z limitami i wznawianiem, `package_serial` per pakiet, brak przypiętego klucza = **odmowa**, testy e2e decyzji | `ADR-0009`; `R-703` 🟡, `R-702` ✅, `V2-MS13`/`V2-MS14`/`V2-MS15` ✅ | 🖥️ | 🔴 |
| **M6 — „demon i transakcja z dziennikiem"** (E2+E3) | `eos-updated` + `/scheme/eos-update` + CLI; dziennik zamiaru, kopie zamienianych plików, `eos-update rollback`, odzyskiwanie po zaniku zasilania | **M5**, `R-D03` (powiadomienia), **`R-706` dzieli semantykę dziennika z `R-612c`** — jeden format, nie dwa | 🖥️ | 🔴 |
| **M7 — „baza i jądro przy restarcie + panel"** (E4+E5) | `pending/`, flaga dla bootloadera, licznik prób rozruchu, automatyczny powrót do `kernel.prev`, panel w `R-D01`, dokumentacja przepływu | **M6**, `R-D01` ✅ (9 paneli), **⚙️ metal** — bootloader nie jest dowodliwy w pętli GUI pod Mac-QEMU | ⚙️ | 🔴 |
| **M8 — „rotacja kluczy, różnicowe, sloty A/B"** (E6+E7+E8) | keyring z `not_before`/`not_after`/`revoked`; pobieranie zakresami po `Entry.offset`; drugi root i wybór slotu w bootloaderze | **M7** (`R-707`), **M2** i **M4** przez `R-609` (bo A/B to zmiana **układu partycji**, czyli instalatora), `R-303` | ⚙️ | 💡 |

**Zależności, które łatwo przeoczyć, więc są tu wypisane wprost:**

- **M8 wymaga M2, nie tylko M7.** `system-updates.md` §1.4 mierzy to w źródle: instalator tworzy
  **dokładnie trzy** partycje i cały ogon dysku oddaje jednemu RedoxFS-owi
  (`installer.rs:565-660`). Slotów A/B nie da się dołożyć do maszyny zainstalowanej dziś bez
  przepartycjonowania — to jest praca w **instalatorze** (`R-609`), a nie w systemie aktualizacji.
- **M1 nie wymaga M5.** Instalacja z nośnika jest offline z założenia (`installer.md` §4.4), więc
  brak kanału aktualizacji na x86_64 (znalezisko `C-4`) **nie blokuje M1**. Blokuje wszystko, co
  po instalacji.
- **M3 wymaga `R-604a` z M1, nie odwrotnie.** Identyfikacja dysku jest w M1, bo bez niej nie
  wolno puścić nikogo na fizyczny dysk; reszta `R-604` (odmowy, ekran różnicowy) idzie w M3.
- **M2 wymaga `R-607a` (rozmiar bloku), nie całego `R-607`.** Programowa połowa jest 🖥️
  i tania; macierz sprzętowa `R-607b` jest ⚙️ i rozciąga się na M1…M7.

---

### 12.4 M1 rozpisany na zadania — każde weryfikowalne osobno

**Kryterium akceptacji całego M1, w jednym zdaniu, obalalne:** na **jednym** fizycznym pececie
x86_64 obraz zapisany `dd` na pendrive'a startuje z firmware, instalator widzi wewnętrzny dysk
i identyfikuje go czymś więcej niż numerem, instalacja kończy się sukcesem, a maszyna **z wyjętym
pendrivem** bootuje do `eos login:`. Nieudany przebieg też jest wynikiem, **jeżeli zapisze, gdzie
stanął** — formularz objawów jest gotowy w `docs/plan-do-sprzetu.md` §0.5.

To jest jeden wiersz macierzy z `installer.md` §9.2. Jeden. Nie dziesięć.

| # | poz. | zadanie | zdolność | dowód, że zadanie jest zrobione — **i jak pada** | praca |
|---|---|---|---|---|---|
| 1 | **`R-611a`** | Cel `mk/disk.mk` produkuje `eos-<wer>-<arch>-installer.img` zamiast `redox-live.iso`. **Powód nie brzmi „to nie jest ISO"** — plik **jest** ISO 9660 (§12.9). Powód: `.iso` obiecuje płytę, która się nie uruchomi, a `redox-live.iso` nie mówi ani czyj to system, ani jaka wersja, ani że to instalator (`installer.md` §2.1, gdzie to uzasadnienie zostało poprawione po pomiarze) | **DO ZBUDOWANIA** | `make CI=1 ARCH=x86_64 CONFIG_NAME=eos live` daje plik o nowej nazwie; **pada**, gdy cel odwołuje się do starej ścieżki. Dziś `mk/disk.mk:20` i `Makefile:13-17` (cele `live`, `popsicle`) znają wyłącznie `redox-live.iso`; łącznie `grep -c redox-live Makefile mk/*.mk` → **13 trafień w 4 plikach** (`Makefile` 6, `mk/ci.mk` 3, `mk/disk.mk` 3, `mk/qemu.mk` 1), więc zmiana nazwy nie jest jednolinijkowa | `[P1·S·🖥️]` |
| 2 | **`R-611b`** | `scripts/make-release.sh` pakuje nośnik **obok** `harddrive.img`, liczy jego `sha256` do `SHA256SUMS` i obejmuje go podpisem minisign | **DO ZBUDOWANIA** | usuń nośnik przed uruchomieniem → skrypt kończy się `≠0` z nazwą brakującego pliku, tak jak dziś dla `harddrive.img` (`make-release.sh:22-25`). **Dziś brak nośnika nie jest błędem, tylko ciszą** — zmierzone: pętla `for arch in $ARCHES` bierze wyłącznie `build/$arch/eos/harddrive.img` | `[P0·S·🖥️🔑]` |
| 3 | **`R-611c`** | Nośnik wiezie `EFI/EOS/eos-secureboot.der` + `EFI/EOS/README.txt` (instrukcja wgrania certyfikatu do firmware) | **DO ZBUDOWANIA** | `sbverify --cert` z pliku z nośnika na `EFI/BOOT/BOOTX64.EFI` z tego samego nośnika → OK; ten sam test z obcym certyfikatem → **odmowa**. Kontrola negatywna jest częścią zadania, nie dodatkiem | `[P1·S·🖥️]` |
| 4 | **`R-601a`** | Zadania `build-image` / `build-image-x86_64` budują **też** nośnik i eksportują go jako artefakt | **DO ZBUDOWANIA** | zmierzone dziś: `grep -c "redox-live" .gitlab-ci.yml` → **0**. Po zmianie: usuń krok → job czerwony, artefaktu brak | `[P1·S·🐧]` |
| 5 | **`R-601b`** | `scripts/ci-install-smoke.sh` startuje **z nośnika**, nie z `harddrive.img`, i jest wpięty w CI na harmonogramie | **DO ZBUDOWANIA** | zmierzone dziś: `grep -c "install-smoke" .gitlab-ci.yml` → **0**. Kontrola negatywna: uruchom harness na obrazie bez instalatora → FAIL, nie „PASS z ciszy" | `[P1·M·🐧]` |
| 6 | **`R-601c`** | Ten sam harness działa na **x86_64** | **DO ZBUDOWANIA** | zmierzone dziś: `scripts/ci-install-smoke.sh:32` → `[ "$ARCH" = "aarch64" ] \|\| { echo "install-smoke: only aarch64 is wired up"; exit 2; }`. Kontrola negatywna to sam ten `exit 2` przed poprawką | `[P0·M·🖥️]` |
| 7 | **`R-607a`** | `DiskWrapper::open` pyta urządzenie o rzeczywisty rozmiar bloku; przy 4Kn instalator **odmawia** zamiast liczyć geometrię GPT na 512 | **DO ZBUDOWANIA** | QEMU `logical_block_size=4096`: **przed** poprawką instalacja przechodzi z błędną arytmetyką LBA, **po** — jawna odmowa. To ożywia martwy `_ => bail!` z `installer.rs:604`, bo `disk_wrapper.rs:28` ma dziś `let block_size = 512;` na sztywno. Podręcznikowe *„kontrola, która nie może zawieść, nie jest kontrolą"* | `[P0·M·🖥️]` |
| 8 | **`R-612a`** | **Odwrócenie kolejności zapisu:** ESP i bootloader dopiero **po** zapisaniu roota; przerwanie zostawia dysk, który nadal bootuje stary system | **DO ZBUDOWANIA** | zabij VM w połowie fazy 1 → na dysku **nie ma** bootloadera bez roota. Dziś harness opisuje przeciwny wynik: *„stage 2 then found an unbootable disk"* (`scripts/install-smoke-drive.py`). Najlepszy stosunek wartości do kosztu w całym EP-1 | `[P0·S·🖥️]` |
| 9 | **`R-604a`** | Wybór dysku pokazuje **ścieżkę urządzenia, rozmiar, typ interfejsu i wymienność**; potwierdzenie kasowania przez **przepisanie ścieżki urządzenia**, nie przez numer | **DO ZBUDOWANIA** | dwa dyski w QEMU: wpisanie złej nazwy → odmowa, zero zapisów. Dziś jest „gołe menu numeryczne bez identyfikacji dysku" (`R-604`), a harness oczekuje literału `Select a drive from 1 to`. **Numer w menu zmienia się między uruchomieniami**, jeśli zmieni się kolejność wyliczania PCI | `[P0·M·🖥️]` |
| 10 | **`R-608`** *(część)* | `docs/install.md` mówi prawdę o **nazwie artefaktu i procedurze zapisu** po `R-611a` | **DO ZBUDOWANIA** | `grep -c 'redox-live.iso' docs/install.md` → 0 po zmianie; kontrola: dokument opisujący nieistniejący plik jest wadą, nie kosmetyką (`CLAUDE.md` §2) | `[P1·XS·🖥️]` |
| 11 | **`R-607b`** *(jeden wiersz)* | **Pierwszy przebieg na metalu.** Jeden pecet, wypełniony formularz objawów, wynik zapisany w `docs/hardware-matrix.md` jako **pierwszy wiersz z E-OS** | **DO ZBUDOWANIA** | dziś macierz sprzętowa ma **zero wierszy z E-OS** — `docs/hardware-matrix.md` jest zmierzona pod QEMU, a `HARDWARE.md` niesie dane upstreamu. Kryterium: rozruch → widzi dysk → instalacja → reboot bez nośnika → login | `[P0·M·⚙️]` |

**Czego M1 świadomie nie zawiera, choć kusi:** naprawy wpisu El Torito dla EFI (`R-611d` —
hybryda **już jest zbudowana**, wadliwy jest jeden wpis w katalogu rozruchowym; wygoda dla
Ventoya i VM, nie warunek), dziennika instalacji (`R-612c` — M2), trybu ratunkowego (`R-614` — M2),
kont i hostname'u we frontendach (`R-603` — M3), kanału aktualizacji (M5). M1 ma dowieźć
**jedną rzecz**: że pendrive z E-OS instaluje E-OS na fizycznym dysku. Wszystko, co tego nie
przybliża, jest w kolejnych kamieniach.

**Ryzyko M1, nazwane teraz, żeby nie zaskoczyło potem:** dziewięć z jedenastu zadań jest
🖥️ dowodliwych, ale zadanie 11 jest ⚙️ i **jedyne**, które rozstrzyga. `installer.md` §9.3
wymienia dziewięć rzeczy, których QEMU nie udowodni — pierwsza z nich to *„czy firmware w ogóle
uruchomi nasz nośnik"*, a to jest w praktyce najczęstsza awaria i z definicji nie ma jej
w emulatorze.

---

### 12.5 M2–M8 — zadania

#### M2 — przerwana instalacja nie zostawia cegły

| poz. | zadanie | zdolność | praca |
|---|---|---|---|
| `R-612b` | Faza 2 „weryfikacja" przed commitem: ponowny odczyt ładunku, blake3 per pakiet na ścieżce plikowej | **JEST** (weryfikacja pkgar, `V2-MS13`/`U-223`) → **DO ZBUDOWANIA** jako faza transakcji | `[P1·M·🖥️]` |
| `R-613` | Suma całego skopiowanego obszaru na **ścieżce blokowej** (`try_fast_install`), porównana z sumą obrazu podpisaną w warstwie 4 | **DO ZBUDOWANIA**; **`[NIEZWERYFIKOWANE]`, co `try_fast_install()` weryfikuje dziś** — sprawdzić `eos-installer` `installer.rs` ok. linii 765 | `[P0·M·🖥️]` |
| `R-612c` | Dziennik `EFI/EOS/install-journal.toml` na ESP: rekord intencji przed każdą fazą, `fsync`, znacznik ukończenia po. **Ten sam format co `journal.toml` z `R-706`** | **DO ZBUDOWANIA** | `[P2·L·🖥️]` |
| `R-612d` | Wznawialność: przy starcie instalator czyta dziennik z ESP każdego widocznego dysku; *wznów* albo *odrzuć* | **DO ZBUDOWANIA**, wymaga `R-612c` | `[P2·M·🖥️]` |
| `R-614a` | Menu nośnika: *zainstaluj* / *ratuj* / *sprawdź nośnik*; sprawdzenie liczy sha256 i porównuje z `SHA256SUMS` wiezionym na nośniku, którego podpis weryfikuje `keys/eos-release.pub` | **DO ZBUDOWANIA**, wymaga `R-611b` | `[P2·M·🖥️]` |
| `R-614b` | Naprawa offline: odtworzenie ESP i bootloadera, odtworzenie jądra i initfs **razem z `.sig`**, reset hasła po zamontowaniu roota | **DO ZBUDOWANIA** | `[P2·M·🖥️]` |
| `R-614c` | Konto awaryjne / reset hasła z nośnika — powiązane ze znaleziskiem `C-18` | **DO ZBUDOWANIA**; treść `C-18` cytowana **za briefem** — `[NIEZWERYFIKOWANE]` | `[P2·S·🖥️]` |
| `R-604b` | Ekran różnicowy przed zapisem: dokładna lista operacji, zapis rusza dopiero po nim | **DO ZBUDOWANIA** | `[P1·M·🖥️]` |
| `R-604c` | Odmowa niebezpiecznych celów (dysk z nośnikiem, jedyny dysk z innym systemem bez jawnego przełącznika) | **DO ZBUDOWANIA**, wymaga `R-607a` | `[P1·M·🖥️]` |
| `R-615` | **`fsck` dla RedoxFS** | **NOWY PODSYSTEM** — pomiar `build/fstools/bin/` (`redoxfs` i `redoxfs-mkfs`, nic więcej) pochodzi z `installer.md` §8.1 i **nie jest odtwarzalny w czystym drzewie**: `build/` ma dziś tylko `container.tag`, `hostbuild-eos-control`, `id_ed25519.pub.toml`, a `build/fstools/` nie istnieje. Odtworzyć po `make fstools`. To luka **także w roadmapie**: `installer.md` §8.1 nie znalazł dla niej żadnej pozycji `R-*`, więc powstaje tutaj | `[P2·XL·🖥️]` |
| `R-607b` | Macierz na metalu: kolejne wiersze — firmware AMI/Insyde/Phoenix, NVMe/AHCI/USB, 512e i 4Kn, BIOS legacy, dysk z Windowsem i z Linuksem | **DO ZBUDOWANIA** | `[P2·M·⚙️]` |

#### M3 — kreator: jedna prawda dla GUI i TUI

| poz. | zadanie | zdolność | praca |
|---|---|---|---|
| `R-603a` | **Przeniesienie logiki wyboru dysku z frontendu do biblioteki.** Dziś `installer_tui` ma własne `disk_paths()` i `choose_disk()`, więc GUI i TUI mogą się rozjechać — i to jest konkretny dług, nie hipoteza | **DO ZBUDOWANIA**; silnik z dwoma frontendami **JEST** (`src/lib.rs` + `src/bin/installer.rs` + `src/bin/installer_tui.rs`, GUI jako osobny crate `gui/` z `redox_installer = { path = ".." }`) | `[P1·L·🖥️]` |
| `R-603b` | Maszyna stanów S0–S10, reguły przejść, punkt bez powrotu, walidacja, ekran S8 z różnicą i oceną ryzyka | **DO ZBUDOWANIA** | `[P1·L·🖥️]` |
| `R-603c` | Model danych profili i funkcji w TOML-u: typy `serde` + resolver (`installer-profiles.md` §3) | **DO ZBUDOWANIA** | `[P1·M·🖥️]` |
| `R-603d` | Konta, hostname, strefa czasowa, układ klawiatury zbierane przez oba frontendy i podawane do `config.users`/`hostname` zamiast domyślnych z `base.toml` | **DO ZBUDOWANIA**; baza stref czasowych = **NOWY PODSYSTEM** (dziś `/etc/tz-offset` to stała liczba); układy klawiatury `[NIEZWERYFIKOWANE]` — sprawdzić `eos-orbital`, `eos-orbdata` | `[P1·L·🖥️]` |
| `R-603e` | Weryfikacja podpisu **profilu** na urządzeniu | **DO ZBUDOWANIA**, wymaga `R-711` (bez keyringu podpis profilu jest nieodwoływalny) | `[P2·M·🖥️]` |
| `R-606` | Tożsamość per-maszyna: unikalny hostname (dziś **każda** instalacja to `eos`), `machine-id`, klucze hosta SSH | **DO ZBUDOWANIA** | `[P1·S·🖥️]` |
| `R-605` | Ścieżka online z podpisanego repo E-OS, świadoma architektury | **JEST** na aarch64 · **DO ZBUDOWANIA** na x86_64 (znalezisko `C-4`) | `[P1·M·🖥️]` |
| `R-D08` | Pełny przepływ live → greeter → `installer-gui` → instalacja, **nigdy nietestowany od końca do końca** | **DO ZBUDOWANIA** | `[P1·L·🖥️]` |
| `R-601d` | Bramka parytetu GUI ↔ TUI: oba frontendy muszą pokrywać ten sam zbiór stanów | **DO ZBUDOWANIA** | `[P2·S·🖥️]` |
| `R-601e` | Brakujące przypadki harnessu: FDE (dziś harness wysyła puste hasło), przerwanie w fazie 1/3, dwa dyski i wybór złego, dysk 4Kn, rozruch BIOS | **DO ZBUDOWANIA**; przypadek przerwania jest **jedynym** testem transakcji z M2 | `[P1·M·🖥️]` |
| `R-815` | **Kanał komend administracyjnych do dysków** (SMART, IDENTIFY, rozmiar bloku, secure erase) | **NOWY PODSYSTEM** — `installer-wizard.md` §15 nazywa to jedyną nową pracą bez pozycji i lokuje w rodzinie `R-8xx`, bo dotyka `nvmed`/`ahcid`, nie instalatora. Odblokowuje model i numer seryjny w `R-604`, domyka `R-607a`, jest nośnikiem bezpiecznego kasowania w profilu Ghost. **`[NIEZWERYFIKOWANE]`, czy sterowniki wystawiają dziś jakikolwiek taki kanał** — sprawdzić `eos-base`: `drivers/storage/nvmed/src/**`, `drivers/storage/ahcid/src/**` | `[P2·L·⚙️]` |

> **M3 działa bez `R-815`.** Identyfikacja dysku degraduje się wtedy do ścieżki, rozmiaru, typu
> interfejsu i wymienności — czyli **mniej**, niż mówi zamówienie (model, numer seryjny, SMART).
> To trzeba napisać na ekranie, a nie odkryć przy zgłoszeniu.

#### M4 — profile i tryb nienadzorowany

| poz. | zadanie | zdolność | praca |
|---|---|---|---|
| `R-603c`+ | Dziedziczenie profili **z blokadami** — mechanizm `include = [...]` **JEST** (`config/x86_64/eos.toml:7` → `["../desktop.toml"]`, a `config/desktop.toml:3` ciągnie dalej `["desktop-minimal.toml", "server.toml"]`, więc łańcuch jest już dwupoziomowy), ale scala pliki, nie decyzje, i nie ma blokad | **DO ZBUDOWANIA** | `[P1·M·🖥️]` |
| `R-609a` | Walidator profili i funkcji z rozróżnieniem `bad` (plik zły) od `cannot` (system nie umie) | **DO ZBUDOWANIA** | `[P1·M·🖥️]` |
| `R-608a` | **Dokumentacja generowana z tych samych danych** co kreator — jedno źródło prawdy zamiast dwóch | **DO ZBUDOWANIA**; precedens jest zmierzony: `R-608` istnieje wyłącznie dlatego, że `docs/install.md` §2 opisuje funkcje, których binarka nie ma | `[P1·S·🖥️]` |
| `R-D13` | **Katalog łańcuchów i18n** + bramka parytetu kluczy (pl/en) | **NOWY PODSYSTEM** — nie istnieje **żadna** infrastruktura i18n; `eos-control` ma napisy zaszyte w kodzie, a wcześniejsze twierdzenie o bramce i18n było zmyślone (`U-126`). `installer-profiles.md` §9 mówi wprost: „Brak pozycji roadmapy — do założenia". Zakładam ją tutaj, w rodzinie `R-Dxx`, bo to sprawa całej powłoki, nie samego instalatora | `[P2·M·🖥️]` |
| `R-609b` | Plik odpowiedzi: sekcja `[setup]`, zgoda na destrukcję w trybie nienadzorowanym, **wygenerowanie pliku odpowiedzi z przebiegu kreatora** | **JEST częściowo** — `redox_installer --config=file.toml` **to już jest** instalacja nienadzorowana; brakuje wyłącznie tego, żeby kreator plik **zapisywał**, a TUI/GUI umiały go wczytać | `[P1·M·🖥️]` |
| `R-604d` | Ekran różnicy z potwierdzeniem **per osłabienie polityki** (rozszerzenie bariery z `R-604` z „kasowania dysku" na „osłabienie hartowania") | **DO ZBUDOWANIA** | `[P2·M·🖥️]` |
| `R-609c` | Profile `Gamer` / `Business` / `Ghost` — **wyłącznie treść, którą da się dowieźć** | mieszane; rozbicie w `installer-wizard.md` §14. Ghost: Tor **NOWY PODSYSTEM**, VPN **NOWY PODSYSTEM**, tryb amnezyjny **NIEREALNE DZIŚ**; Business: zapora **NOWY PODSYSTEM** (`R-904`, `C-10`), dziennik audytu **NOWY PODSYSTEM** (`C-9`), domena/LDAP/MDM **NIEREALNE DZIŚ**. **Rozjazd między specyfikacjami, do usunięcia przy zatwierdzaniu:** `installer-wizard.md` §14 klasyfikuje zaporę jako **DO ZBUDOWANIA — `R-904`**, a `installer-profiles.md` §8 poz. 22 jako **NOWY PODSYSTEM** (*„na Redoksie nie ma netfiltera"*). Rejestr przyjmuje odczyt z `installer-profiles.md`, bo niesie uzasadnienie; poprawka należy do `installer-wizard.md` | `[P2·M·🖥️]` |
| `R-609d` | Tryby partycjonowania w stanie S4: ręczny edytor GPT, ponowne użycie istniejącego ESP (zapis **wyłącznie** do `EFI/EOS/`), instalacja w wolnym miejscu, wykrywanie innych systemów po ESP | **DO ZBUDOWANIA**; zmiana rozmiaru NTFS/ext4 — **NIEREALNE DZIŚ**, bo nie mamy nawet odczytu tych systemów plików. To jest `R-609` (💡, `[P3·XL·any]`) rozpisane, nie nowa praca | `[P3·XL·🖥️]` |

#### M5–M8 — EP-3, według etapów E0–E8 z `system-updates.md` §9

**Ta tabela nosiła wcześniej opisy bez znaczników zdolności** — a to jest dokładnie ten obszar,
w którym zamówienie mówi słownikiem Linuksa (ostree, systemd-sysupdate, sloty A/B, delty,
live-patching). Kolumna jest przywrócona; jedna pozycja na wiersz nie wystarcza, więc rozbicie
per zdolność stoi obok.

| kamień | etapy | pozycje | co dowozi | zdolność | praca |
|---|---|---|---|---|---|
| **M5** | E0, E1 | `R-706` (część), `R-705` (część), **`R-704`**, `R-709` | atomowy zapis `packages.toml`/`repo-state.toml`; `curl` z `--max-time`/`-C -`/`--limit-rate`; `package_serial` per pakiet — **dziś poprawnie podpisany STARSZY pkgar wciąż się instaluje**; brak przypiętego klucza = odmowa; testy e2e | atomowy zapis stanu **DO ZBUDOWANIA** · limity `curl` **DO ZBUDOWANIA** · anti-rollback per pakiet **DO ZBUDOWANIA** (indeks już chroniony, `V2-MS15` ✅) · odmowa bez przypiętego klucza **DO ZBUDOWANIA** (klucz przypięty, `R-702` ✅) | `[P1·M·🖥️]` |
| **M6** | E2, E3 | **`R-705`**, **`R-706`** | `eos-updated` + `/scheme/eos-update` + CLI; dziennik zamiaru, kopie zamienianych plików, `eos-update rollback`, odzyskiwanie po zaniku zasilania. Dziś `transaction.commit()` mutuje **żywy** system plików pętlą `rename` bez persystowanego dziennika | demon + schemat **DO ZBUDOWANIA** · dziennik zamiaru **DO ZBUDOWANIA** (trwałość `fsync` na RedoxFS-ie **`[NIEZWERYFIKOWANE]`**, `ADR-0009`) · wycofanie przez **migawkę** — **odpada**, RedoxFS nie ma prymitywu (§12.9) | `[P1·XL·🖥️]` |
| **M7** | E4, E5 | **`R-707`**, **`R-708`**, **`R-712`** | `pending/`, flaga dla bootloadera, automatyczny powrót do `kernel.prev`, atomowa para `kernel`+`kernel.sig`; panel w `R-D01`; dokumentacja przepływu. Dziś jądro podmienia się **w locie** — zła aktualizacja albo zanik zasilania może zabić realny dysk | staging `pending/` **DO ZBUDOWANIA** · **licznik prób rozruchu — NOWY PODSYSTEM** (`ADR-0009`: wymaga ścieżki **zapisu** z bootloadera; czy taka istnieje, jest `[NIEZWERYFIKOWANE]`) · panel w `R-D01` **DO ZBUDOWANIA** (powłoka ✅) | `[P2·XL·⚙️]` |
| **M8** | E6, E7, E8 | **`R-711`**, **`R-710a`**, **`R-710b`** + **`R-609`** | keyring `/etc/pkg/keys.d/` z `not_before`/`not_after`/`revoked` objęty podpisem indeksu; pobieranie zakresami po `Entry.offset`; drugi root i wybór slotu w bootloaderze | keyring/unieważnianie **DO ZBUDOWANIA** · **delty — DO ZBUDOWANIA, nie nowy format**: pkgar jest nieskompresowany i ma `offset`+`size`+`blake3` · **sloty A/B — DO ZBUDOWANIA, ale nie na maszynie zainstalowanej dziś** (wymaga przepartycjonowania, `R-609`) · `ostree`/`systemd-sysupdate` jako podstawa — **NIEREALNE DZIŚ** (`system-updates.md` §1.2) | `[P2·M·🖥️]` + `[P3·XL·⚙️]` |

**Poza tą ścieżką, ze znacznikiem, bo zamówienie o to pyta wprost:** żywe łatanie jądra w stylu
`kpatch`/`livepatch` — **NIEREALNE DZIŚ** (brak `ftrace`, brak modułów ładowalnych, brak
relokacji symboli w locie; `system-updates.md` §6.2). Mikrojądrowy odpowiednik — **restart
sterownika bez restartu systemu** — jest **DO ZBUDOWANIA**, ale wymaga nadzorcy procesów, który
**dziś nie istnieje i nie miał pozycji w rejestrze**: `init` zna dokładnie dwa typy usług
(`oneshot`, `oneshot_async`) i po starcie niczego nie nadzoruje. Ta sekcja zakłada dla niego
**`R-816`** (§12.6).

**Poza ścieżką E0–E8, ale bez tego cała EP-3 jest projektem, nie systemem:** `R-701` (kanał na
x86_64 — dziś **brak aktywnego**, `C-4`), `R-303`/`V2-MS07` (powtarzalność), `V2-MS12` (custody
klucza podpisującego pakiety — dziś jawnym tekstem), `R-606` (tożsamość per maszyna — bez niej
nie ma wdrożeń etapowych), `R-503` (promocja ML-DSA-65 z advisory na required u klienta).

---

### 12.6 Nowe identyfikatory założone przez tę sekcję — pełny zapis

Osiem pozycji nadrzędnych. Każda ma powód, dla którego **nie da się jej powiesić** na
istniejącej, i dowód, że numer jest wolny.

| poz. | co | dlaczego nowa, a nie rozszerzenie | zdolność | stan |
|---|---|---|---|---|
| `R-611` | **Nośnik instalacyjny jako produkt wydania** (`a` nazwa i cel Make, `b` suma + podpis, `c` certyfikat SB na nośniku, `d` **naprawa wpisu El Torito dla EFI**) | `R-301` (podpisane sumy wydania) jest ✅ **zamknięte** i dotyczy `harddrive.img`. Podpisujemy obraz preinstalowany, a wydajemy nośnik instalacyjny — **to dwa różne pliki**. Rozszerzanie zamkniętej pozycji ukryłoby ten fakt. **`d` nie jest „zbudowaniem hybrydy"** — hybryda jest zmierzona i **JEST** (§12.9); wadliwy jest jeden wpis w katalogu rozruchowym | **DO ZBUDOWANIA** | 🔴 |
| `R-612` | **Transakcja instalacji** (`a` kolejność root→ESP, `b` faza weryfikacji, `c` dziennik na ESP, `d` wznawialność) | `R-706` to transakcja **aktualizacji** w `pkg-lib`; to jest transakcja **instalacji** w `redox_installer` — inne drzewo kodu, inny moment. Wspólny jest **format dziennika**, i to jest wpisane w `R-612c` jako wymóg, żeby nie powstały dwie semantyki wznawiania | **DO ZBUDOWANIA** | 🔴 |
| `R-613` | **Weryfikacja ładunku na ścieżce blokowej** | Ścieżka plikowa jest pokryta przez `V2-MS13`/`V2-MS14` ✅ (blake3 z podpisanego manifestu). Ścieżka blokowa kopiuje **bajty z RAM**, nie pakiety, więc ta weryfikacja z definicji nie zachodzi — a wybieramy ją domyślnie, bo różnica to ~6 min wobec ~6,8 h (`U-176`) | **DO ZBUDOWANIA** | 🔴 |
| `R-614` | **Nośnik jako system ratunkowy** (`a` menu + sprawdzenie nośnika, `b` naprawa offline, `c` konto awaryjne) | Osobny nośnik ratunkowy jest **odrzucony** (`installer.md` §10 poz. 7): drugi artefakt to druga suma, drugi podpis i drugi obiekt, który się zestarzeje. To jest zawartość **tego** nośnika, więc nie ma innej pozycji, na której mogłaby usiąść | **DO ZBUDOWANIA** | 🔴 |
| `R-615` | **`fsck` dla RedoxFS** | `installer.md` §8.1: *„Nie znalazłem dla niej pozycji `R-*` — to jest luka także w roadmapie"*. Zmierzone: `build/fstools/bin/` ma `redoxfs` i `redoxfs-mkfs`, nic więcej. System plików bez narzędzia sprawdzającego znaczy, że odpowiedzią na uszkodzenie po zaniku zasilania jest reinstalacja | **NOWY PODSYSTEM** | 🔴 |
| `R-815` | **Kanał komend administracyjnych do dysków** (SMART, IDENTIFY, rozmiar bloku, secure erase) | `installer-wizard.md` §15 nazywa to jedyną nową pracą bez pozycji i lokuje w `R-8xx`, bo dotyka `nvmed`/`ahcid`. **`R-812`–`R-814` są zarezerwowane** przez `docs/driver-manager-design.md:9`, więc pierwszy bezpieczny numer to `R-815` (§12.1 D3) | **NOWY PODSYSTEM** | 🔴 |
| `R-816` | **Nadzorca procesów / cykl życia usług** — zatrzymanie usługi, podmiana pliku, ponowne uruchomienie, powrót do poprzedniej wersji przy niepowodzeniu | Warunek klasy pakietów `service` z `ADR-0009` D6 i **jedyna droga do mikrojądrowego odpowiednika żywego łatania**. `init` zna dziś **dokładnie dwa** typy usług — `oneshot` i `oneshot_async` (`system-updates.md` §6.3) — i po starcie niczego nie nadzoruje. Najbliższa istniejąca pozycja, `R-805` (*„`pcid` wiążący na żądanie"*), dotyczy **wiązania urządzeń**, a nie cyklu życia procesu. `ADR-0009` D8 świadomie **nie zakłada** numeru i odsyła do rejestru — czyli tutaj. Rodzina `R-8xx`, bo to tor sterowników i usług, nie aktualizacji; wpisanie w `R-7xx` zaciemniłoby, czyja to praca | **NOWY PODSYSTEM** | 🔴 |
| `R-D13` | **Katalog łańcuchów i18n + bramka parytetu kluczy** | `installer-profiles.md` §9: *„roadmapa go nie ma"* — zdanie **już nieaktualne**, bo ta pozycja je zamknęła; sam dokument to odnotowuje. Rodzina `R-Dxx`, a nie `R-6xx`, bo brak dotyczy całej powłoki (`eos-control` ma napisy zaszyte w kodzie), nie samego instalatora | **NOWY PODSYSTEM** | 🔴 |

**Dowód wolności numerów.** Wykonany **przed** dopisaniem tej sekcji (2026-08-30):
`grep -rho '<ID>' --include='*.md' --include='*.toml' --include='*.sh' --include='*.yml' .`
→ **0** dla `R-611`, `R-612`, `R-613`, `R-614`, `R-615`, `R-616`, `R-815`, `R-816`, `R-D13`
oraz dla wszystkich sub-identyfikatorów literowych użytych powyżej.

**Ten pomiar jest już nieodtwarzalny w tej postaci** — po dopisaniu §12, czterech specyfikacji
i `ADR-0007`–`ADR-0011` te numery mają trafienia. Powtarzalna forma kontroli, i to ona
obowiązuje przy zatwierdzaniu:

```
grep -rl '<ID>' --include='*.md' .
```

musi zwrócić **wyłącznie** `ROADMAP-v2.md`, `docs/architecture/*.md` i `docs/adr/00{07..11}-*.md`.
Trafienie w `ROADMAP.md`, `docs/update-system-design.md` albo `docs/driver-manager-design.md`
znaczy, że numer jednak był zajęty i mintowanie było błędem. Zmierzone dla `R-611`, `R-612`,
`R-613`, `R-614`, `R-615`, `R-815`, `R-816`, `R-D13`: warunek spełniony. `R-616` pozostaje
**niezajęty** i jest pierwszym wolnym numerem w rodzinie `R-6xx` po tej sekcji.

---

### 12.7 Rozszerzenia istniejących pozycji — co jest tą samą pracą

Tu nie powstaje żaden nowy numer. Zapis jest po to, żeby nikt nie założył drugiej pozycji na to,
co już ma swoją.

| istniejąca poz. | co dokłada ta sekcja | to samo czy rozszerzenie |
|---|---|---|
| `R-601` ✅ | `R-601a`–`R-601e`: nośnik w CI, harness z nośnika, x86_64, parytet GUI/TUI, brakujące przypadki (FDE, przerwanie, dwa dyski, 4Kn, BIOS) | **rozszerzenie**. `R-601` zostaje ✅ **co do dowodu z `U-176`** — partycja → instalacja → reboot → login, 3× z rzędu. Otwarte są **braki pokrycia**, nie dowód. To rozróżnienie jest tym samym, które §9.8 poz. 2 zrobiło dla desktopu |
| `R-603` 🔴 | `R-603a`–`R-603e`: granica silnik/frontend, maszyna stanów, model danych, konta/hostname/locale, podpis profilu | **ta sama praca, sformalizowana.** `installer-wizard.md` §15 i `installer-profiles.md` §9 mówią to samo: te dokumenty dostarczają `R-603` model danych i maszynę stanów, nie zastępują go |
| `R-604` 🔴 | `R-604a`–`R-604d`: identyfikacja dysku, ekran różnicowy, odmowy, potwierdzenie per osłabienie polityki | **rozszerzenie**: `R-604` mówi o barierze przed kasowaniem dysku; dochodzi bariera przed **osłabieniem polityki** na tym samym ekranie |
| `R-605` 🔴 | funkcja `pkg.source.eos` ze `stage_by_arch` | **ta sama praca** |
| `R-606` 🔴 | funkcja `sys.identity` | **ta sama praca** |
| `R-607` 🔴 | rozcięcie na `R-607a` (rzeczywisty rozmiar bloku, 🖥️, `[P0·M]`) i `R-607b` (macierz na firmware, ⚙️, `[P2·M]`) | **rozcięcie**, bo połowy mają różne stanowiska dowodowe i różne priorytety; dziś jedna pozycja nosi obie i przez to całość stoi na `[P2·metal]`, choć programowa połowa jest tania i blokuje M1 |
| `R-608` 🔴 | `R-608a`: dokumentacja **generowana** z danych funkcji zamiast pisanej osobno | **rozszerzenie** z „popraw dokument" na „rozjazd jest niemożliwy" |
| `R-609` 💡 | `R-609a`–`R-609d`: walidator, plik odpowiedzi, profile, tryby partycjonowania | **rozpisanie**, nie nowa praca — **ale tylko `R-609d` naprawdę należy do rodzica.** `R-609` znaczy w rejestrze *„ręczne partycjonowanie / instalacja obok"*; walidator profili, plik odpowiedzi i profile Gamer/Business/Ghost **nie są partycjonowaniem**, więc te trzy sub-litery dokładają rodzicowi trzecie znaczenie — dokładnie ta usterka, którą §12.1 rozstrzyga dla `R-70x` i `R-80x`. **Do rozstrzygnięcia przy zatwierdzaniu (D7):** przenumerować `R-609a`/`R-609b`/`R-609c` na `R-616a`–`R-616c` („model profili i tryb nienadzorowany", `R-616` jest wolny, §12.6) i poprawić w tym samym ruchu `installer-profiles.md` §9 oraz `installer-wizard.md` §15, które już te numery cytują — albo świadomie przyjąć rozjazd i zapisać go tutaj. **Nie zostawiać bez decyzji.** Uwaga druga: `R-609` staje się **warunkiem `R-710b`** (§12.3) — A/B to zmiana układu partycji |
| `R-704`…`R-712` | całość `system-updates.md` | **ta sama praca.** Ten dokument obsługuje `R-704`, `R-705`, `R-706`, `R-707`, `R-708`, `R-709`, `R-710`, `R-711`, `R-712` i nie zakłada nowych nazw |
| `R-710` 💡 | rozcięcie na `R-710a` (różnicowe, `[P2·M]`, **nie potrzebuje `R-707`**) i `R-710b` (sloty A/B, `[P3·XL]`, potrzebuje `R-707` **i** `R-609`) | **rozcięcie** proponowane przez `system-updates.md` §1.5, przyjęte tu jako wiążące |
| `R-711` 🔴 | keyring i unieważnianie — warunek `R-603e` (podpis profilu bez unieważniania jest nieodwołalny) | **ta sama praca**, nowy konsument |
| `R-904` 🔴 | funkcja `net.firewall` istnieje w schemacie **po to, żeby brak był widoczny** | **reprezentowane jako brak** |
| `R-913` 🔴 | wiązanie z TPM jako opcja szyfrowania | **granica** — poza zasięgiem, wpisane jako granica, nie jako plan |
| `R-1010` ⚠️ | włączenie `contain` — warunek piaskownicy dla importu profilu | **zależność**, ale **pozycji nie ma w rejestrze**: jedyne wystąpienie poza dokumentami tej serii to `CLAUDE.md:545` („włączenie i polityka per aplikacja to `R-1010`/krok 10 planu"). §9 `ROADMAP-v2.md` jej nie zna. Wobec D1 (rejestrem jest `ROADMAP.md`/`ROADMAP-v2.md`) trzeba ją albo **założyć w §9**, albo cytować jako „krok 10 planu", a nie jako `R-*`. Do rozstrzygnięcia przy zatwierdzaniu |
| `R-D08` 🟡 | pełny przepływ live → greeter → `installer-gui` → instalacja | **ta sama praca**, warunek `R-601d` (parytet) |
| `R-F28` 🔴 | `scripts/ventoy.sh` nie zna konfiguracji `eos` (`CONFIGS=(demo desktop)`, `ARCHS=(i686 x86_64)`) | **bez zmian** — nadal *„rozważyć usunięcie zamiast naprawy"*; `dd` jest drogą kanoniczną (`installer.md` §10 poz. 9) |
| `V2-MS12` 🟡 | custody klucza podpisującego pakiety | **zależność EP-3**, bez zmiany zakresu |

---

### 12.8 Graf zależności

```
EP-1 nośnik:
  R-611a nazwa ─→ R-611b suma+podpis ─→ R-614a sprawdzenie nośnika
  R-611a ─→ R-601a CI buduje ─→ R-601b harness z nośnika ─→ R-601c x86_64
  R-607a rozmiar bloku ──┬─→ R-604c odmowy
                         └─→ R-607b macierz na metalu (⚙️)
  R-612a kolejność root→ESP ─→ R-612b weryfikacja ─→ R-612c dziennik ─→ R-612d wznawianie
  R-613 suma ścieżki blokowej ─→ R-612b
  R-604a identyfikacja ─→ R-604b ekran różnicowy ─→ R-604d per osłabienie polityki

  M1 = {R-611a,b,c · R-601a,b,c · R-607a · R-612a · R-604a · R-608(część) · R-607b(1 wiersz)}
  M2 = {R-612b,c,d · R-613 · R-614a,b,c · R-604b,c · R-615 · R-607b(reszta)}   wymaga M1

EP-2 kreator:
  R-603a granica silnik/frontend ─→ R-603b maszyna stanów ─→ R-603c model danych
  R-D08 przepływ GUI ─→ R-601d bramka parytetu
  R-603c ─→ R-608a docs z danych ·  R-603c ─→ R-609b plik odpowiedzi
  R-711 keyring ─→ R-603e podpis profilu ·  R-D13 i18n ─→ M4
  R-815 kanał komend do dysków ─→ pełna identyfikacja w R-604a i domknięcie R-607a  (⚙️)

  M3 wymaga M1, ADR-0011, R-D08
  M4 wymaga M3, ADR-0010, R-D13, R-711

EP-3 aktualizacje (etapy z system-updates.md §9):
  E0 atomowy zapis ─→ E1 R-704 anti-rollback + R-709 testy
     └─→ E2 R-705 demon ─→ E3 R-706 dziennik ─→ E4 R-707 restart (⚙️) ─→ E5 R-708 panel
                                                        └─→ E8 R-710b sloty A/B (⚙️)
  E6 R-711 keyring i E7 R-710a różnicowe są RÓWNOLEGŁE — nie potrzebują R-707
  R-609 partycjonowanie ────────────────────────────────→ E8 R-710b
  R-816 nadzorca procesów ─→ klasa pakietów `service` (ADR-0009 D6); do jego powstania
                             wszystko poza klasą `app` idzie ścieżką restartu

  M5={E0,E1}  M6={E2,E3} wymaga M5  M7={E4,E5} wymaga M6 + ⚙️
  M8={E6,E7,E8} wymaga M7 ORAZ M2 i M4 przez R-609

Poza ścieżką, ale warunkujące sens EP-3:
  R-701 kanał x86_64 (C-4) · R-303/V2-MS07 powtarzalność · V2-MS12 custody klucza
  R-606 tożsamość per maszyna · R-503 ML-DSA-65 required
```

---

### 12.9 Czego ten plan świadomie NIE obiecuje — dla instalatora, kreatora i aktualizacji

Przedłużenie §11 na ten obszar. Ta lista jest częścią planu, nie przypisem do niego.

- **Nic z §12 nie jest zaimplementowane.** Każdy stan powyżej to 🔴 albo 💡 poza pozycjami
  jawnie oznaczonymi ✅, które pochodzą sprzed tej sekcji. Dopóki M1 nie ma wypełnionego wiersza
  macierzy, **cała EP-1 jest projektem, nie systemem**.
- **Nie obiecujemy LUKS2, dm-crypt, LVM, btrfs, ZFS, XFS, ostree, systemd-sysupdate,
  systemd-boot, GRUB2, shim+MOK, TPM2, FIDO2 ani kernel live-patchingu.** Żaden z tych klocków
  nie istnieje na Redoksie i żaden nie jest po cichu podmieniony na coś innego. Ze znacznikami,
  bo lista bez nich niczego nie rozstrzyga: LUKS2 / dm-crypt / LVM / btrfs / ZFS / XFS / ostree /
  systemd-sysupdate / systemd-boot / GRUB2 / shim+MOK — **NIEREALNE DZIŚ** (zależą od ekosystemu
  Linuksa, którego tu nie ma); TPM2 — **NOWY PODSYSTEM** (`R-913`/`V2-N02`, piąta warstwa
  zaufania z `docs/tokeny.md` wciąż pusta); FIDO2 — **NOWY PODSYSTEM** (wymaga stosu USB HID
  i CTAP2); żywe łatanie jądra — **NIEREALNE DZIŚ** (`system-updates.md` §6.2: brak `ftrace`,
  modułów ładowalnych i relokacji symboli w locie). FDE to RedoxFS
  **AES-XTS-128** z kluczem z hasła — **bez audytu kryptograficznego osoby trzeciej** i **bez
  powiązania z TPM/Secure Bootem**, więc hasło jest jedynym sekretem, a bootloader jest
  nieszyfrowany, czyli atak na sam monit o hasło pozostaje w modelu.
- **Nie obiecujemy restartu usługi ani sterownika po aktualizacji.** `init` zna dokładnie dwa
  typy usług (`oneshot`, `oneshot_async`) i po starcie niczego nie nadzoruje, więc klasa pakietów
  `service` z `ADR-0009` D6 jest **wyłączona** do czasu powstania `R-816`. Do tego momentu
  wszystko, co nie jest klasą `app`, idzie ścieżką **restartu systemu** — i tak trzeba to napisać
  w UI, a nie ukrywać za słowem „bezproblemowo".
- **Zaszyfrowanego dysku E-OS nie otworzy linuksowy `cryptsetup`** — i to musi być na ekranie
  kreatora, a nie odkryte przy próbie odzyskiwania danych.
- **Nie obiecujemy migawek ani wycofania przez migawkę.** RedoxFS jest wewnętrznie CoW, ale
  **nie eksponuje API migawek**; `clone.rs` to klon **drzewa plików**, nie tani punkt w czasie.
  Wariant „migawka + podmiana roota" odpada nie dlatego, że jest gorszy, tylko dlatego, że **nie
  ma na czym go oprzeć**.
- **Nie obiecujemy slotów A/B na maszynie zainstalowanej dziś.** Instalator tworzy trzy partycje
  i cały ogon dysku oddaje jednemu RedoxFS-owi. A/B bez przepartycjonowania nie powstanie —
  i dlatego `R-710b` wymaga `R-609`, a nie tylko `R-707`.
- **Nie obiecujemy rozruchu z DVD — ale hybryda NIE jest pracą do wykonania.** Poprzednia wersja
  tego punktu mówiła, że hybrydowe ISO jest *„DO ZBUDOWANIA po stronie hosta (`xorriso`)"*
  i że *„system nie ma sterownika ISO9660, więc płyta wystartuje bootloadera i nie znajdzie
  roota"*. **Oba zdania są fałszywe** i powielały błąd, który `installer.md` §1.2 pkt 13 i §2.2
  wycofały po pomiarze. Stan zmierzony sygnaturami, rozbity na znaczniki:
  - MBR + GPT + ISO 9660 + El Torito w jednym pliku — **JEST** (offset 0 kod x86, 512 `EFI PART`,
    0x8001 `CD001`, 0x8801 `EL TORITO SPECIFICATION`; oba obrazy, `file` → *ISO 9660 CD-ROM
    filesystem data (DOS/MBR boot sector) 'Redox OS' (bootable)*). Zamówione „hybrydowe ISO dla
    USB i DVD" jest po stronie formatu **spełnione**; nie wolno tego wpisywać jako pracy.
  - wpis El Torito dla platformy **EFI** wskazuje puste bajty — **DO ZBUDOWANIA** (`R-611d`).
    Wpis, który wskazuje zera, to kontrola udająca zdolność.
  - sterownik napędu optycznego (ATAPI / SCSI MMC) — **NOWY PODSYSTEM**, brak w `recipes/`.
  - rozruch z DVD od końca do końca — **NIEREALNE DZIŚ**, wymaga obu powyższych.

  **Argument „bez sterownika ISO9660 płyta nie znajdzie roota" był postawiony na złej
  przesłance:** ISO 9660 na tym nośniku to **atrapa 42 KiB** (21 sektorów po 2048 B), a root —
  RedoxFS — leży w **trzeciej partycji GPT**. Bootloader i `lived` czytają surowe bloki, nie
  katalog ISO; roota nie ma w ISO 9660 **na żadnym nośniku, także na pendrivie**, i to nie
  przeszkadza. Blokadą dla płyty jest brak sterownika napędu, nie brak systemu plików.
- **Nie obiecujemy `fsck`.** `R-615` to NOWY PODSYSTEM. Do jego powstania jedyną odpowiedzią na
  uszkodzenie systemu plików po zaniku zasilania jest reinstalacja — i tak trzeba to napisać
  użytkownikowi.
- **Nie obiecujemy swapu.** Nie występuje ani w konfiguracjach, ani w dokumentacji.
  **`[NIEZWERYFIKOWANE]`, czy jądro Redoksa ma jakąkolwiek wymianę stron** — sprawdzić
  w `eos-kernel`, w podsystemie pamięci. Jeżeli ma, decyzja o układzie partycji wymaga rewizji.
- **Nie obiecujemy modelu, numeru seryjnego ani SMART-u dysku przed `R-815`.** `disk_paths()`
  zwraca dziś **ścieżkę i rozmiar**, i nic więcej; na Linuksie jest **pustą funkcją**. Ekran
  wyboru dysku z zamówienia istnieje dziś w jednej czwartej.
- **Nie obiecujemy touchpada, czytnika ekranu ani Wi-Fi w instalatorze.** Touchpad wymaga
  magistrali I2C, której **nie ma żadnej** (`R-916`/`V2-N01`); czytnik ekranu wymaga działającego
  audio; Wi-Fi nie istnieje — więc **instalator sieciowy jest odrzucony**, nie odłożony.
- **Nie obiecujemy, że tryb live jest zweryfikowany.** Cały obraz jest wczytywany do RAM
  **bez weryfikacji**, zanim jądro zostanie z niego odczytane. `V2-MS02` weryfikuje jądro
  i initfs **po** tym punkcie. Zamknięcie tej luki to NOWY PODSYSTEM w bootloaderze i **nie jest
  tu obiecywane** (rozszerza §11).
- **Nie obiecujemy integralności rozruchu na BIOS-ie.** stage1/2/3 to surowe sektory, których
  nic nie uwierzytelnia; kto może zapisać jądro, może podmienić weryfikator. Instalator ma to
  napisać **na ekranie**, nie w dokumentacji.
- **Nie obiecujemy piaskownicy dla importu profilu.** `contain` istnieje i jest **wyłączony**
  (`R-1010`, znalezisko `C-5`). Do jego włączenia import profilu nie ma izolacji — i model
  zaufania z `installer-profiles.md` §6 stoi na przeglądzie przez człowieka, nie na piaskownicy.
- **Nie obiecujemy trwałego dziennika audytu.** `R-612c` daje dziennik **instalacji** na ESP,
  a `R-706` dziennik **aktualizacji**. Systemowego dziennika audytu nie ma (znalezisko `C-9`)
  i ta sekcja go nie dowozi.
- **Nie obiecujemy zapory na nośniku ani w profilach — NOWY PODSYSTEM.** `R-904` / `C-10`:
  netstack wystawia `ip`/`udp`/`tcp`/`raw` z **zerowym filtrowaniem**, a punktu zaczepienia
  w rodzaju netfiltera nie ma. Funkcja `net.firewall` jest w schemacie po
  to, żeby ten brak był **widoczny w spisie**, a nie żeby udawać, że jest.
- **Nie obiecujemy profilu Ghost w wersji z zamówienia.** Tor i VPN to NOWE PODSYSTEMY, tryb
  amnezyjny i „anonimowość systemowa" — NIEREALNE DZIŚ, wolumin ukryty jest **odradzany jako
  iluzja**, a bezpieczne kasowanie komendą urządzenia czeka na `R-815`.
- **Nie obiecujemy „rozluźnionych mitygacji" w profilu Gamer.** Nie ma pomiaru, a
  **`[NIEZWERYFIKOWANE]`, czy w `eos-kernel` istnieją jakiekolwiek mitygacje spekulacyjne** —
  bez tego przełącznik nie ma desygnatu. Sprawdzić:
  `grep -riE "kpti|retpoline|ibrs|ibpb|spec_ctrl|mds|l1tf"` w `eos-kernel`.
- **Nie obiecujemy ochrony przed cofnięciem pakietu przed `R-704`.** Indeks jest chroniony
  (`V2-MS15` ✅ — `serial` + `expires`), **pakiet nie**: poprawnie podpisany **starszy** pkgar
  wciąż się instaluje.
- **Nie obiecujemy, że łańcuch zaufania sięga dalej niż maszyna budująca.** Klucz podpisujący
  pakiety generuje się sam, leży **jawnym tekstem**, a obie jego kopie są na **jednym
  komputerze** (`V2-MS12` 🟡, znalezisko `C-11`).
- **Nie obiecujemy powtarzalności bajtowej** wydania ani nośnika — `R-303`/`V2-MS07` są otwarte,
  a bez nich zdanie „to jest ten sam obraz" jest twierdzeniem, nie pomiarem.
- **Nie obiecujemy, że QEMU cokolwiek z M1 rozstrzygnie.** `installer.md` §9.3 wymienia dziewięć
  rzeczy, których emulacja nie pokaże — w tym najczęstszą awarię w praktyce, czyli „firmware nie
  widzi nośnika". Dziesięć wierszy macierzy sprzętowej to **dziesięć osobnych pomiarów**, nie
  jedna pozycja do odhaczenia.

---

### 12.10 Czego nie zweryfikowałem, pisząc tę sekcję

W tym samym oddechu co reszta, zgodnie z `CLAUDE.md` §2 regułą 3.

1. **Nie czytałem kodu forków.** `recipes/core/installer/` i `recipes/core/redoxfs/` zawierają
   w tym drzewie **wyłącznie `recipe.toml`** (sprawdzone `ls`). Wszystkie twierdzenia o
   `installer.rs`, `disk_wrapper.rs`, `key.rs`, `header.rs`, `clone.rs` i `transaction.rs`
   pochodzą z briefu i z czterech specyfikacji, **nie z odczytu na miejscu**.
   **Sprawdzić:** rozwinąć źródła w drzewie budowania (`scripts/eos-sync-buildtree.sh --apply`,
   potem `recipes/*/source`) i potwierdzić `disk_wrapper.rs:28`, `installer.rs:604`,
   `installer.rs:565-660` oraz `installer.rs:765`.
2. **Nie czytałem `docs/audit/03-security-audit-2026-08-30.md`.** Znaleziska `C-4`, `C-5`, `C-9`,
   `C-10`, `C-11`, `C-12`, `C-18` cytuję **za briefem** — plik leży na gałęzi
   `fix/p0-audit-findings`, a polecenia `git` były w tym zadaniu zabronione.
   **Sprawdzić:** `git show fix/p0-audit-findings:docs/audit/03-security-audit-2026-08-30.md`.
3. **Poprawione, bo było fałszywe: `ADR-0007`–`ADR-0011` ISTNIEJĄ.** Stało tu, że `docs/adr/`
   kończy się na `ADR-0006` i że numery 0007–0011 są dopiero zarezerwowane. `ls docs/adr/`
   pokazuje jedenaście ADR-ów plus szablon i `README`. Co gorsza, przypisanie treści było
   błędne przy dwóch z nich: `ADR-0008` to **układ partycji**, nie kolejność transakcji
   instalacji, a `ADR-0010` to **stos szyfrowania**, nie model profili. Tabela w §12.1 D6
   jest przepisana wobec tytułów plików, a dwie decyzje **bez ADR-a** są tam nazwane wprost.
   **Czego nadal nie wiem:** nie przeczytałem treści tych ADR-ów w całości — czytałem
   nagłówki, `Zakres` i sekcje `D*` cytowane w tej sekcji. Odsyłacze do `ADR-0009` D6/D8
   i `ADR-0008` §D4 są sprawdzone; reszta nie.
4. **Nie zweryfikowałem, czy `R-812`–`R-814` mają w `docs/driver-manager-design.md` przypisaną
   indywidualną treść.** Dokument wymienia je zbiorczo (`:271`, „R-811…R-814 — Real-HW
   coverage"), więc rezerwacja jest zakresowa. `R-815` jest bezpieczny w obu odczytach, ale
   przy zatwierdzaniu warto rozstrzygnąć, czy tamten zakres w ogóle zostaje.
5. **Nie zmierzyłem kosztu żadnego z zadań.** Rozmiary `S/M/L/XL` są przepisane z czterech
   specyfikacji i z `ROADMAP.md`, a tam gdzie ich nie było — oszacowane. **Zero z nich to
   pomiar.**
6. **Rozstrzygnięte pomiarem, nie zostawione jako niewiadoma: `scripts/ci-integrity.sh` ma
   dziś kontrole `0`…`11`.** Zmierzone `grep -n '── [0-9]*\.' scripts/ci-integrity.sh` →
   banery `0.`, `7.`, `8.`, `9.`, `10.`, `11.` plus komentarze `# 1)`…`# 6)`; kontrola `0` to
   sonda przyrządów z `CLAUDE.md` §4.2. Nowa bramka z §12.1 D5 jest więc **kontrolą 12**.
   **Osobne znalezisko, poza zakresem tej sekcji:** `CLAUDE.md` §0 i §13 nadal mówią
   o **ośmiu** kontrolach — dokumentacja rozjechała się z bramką o trzy pozycje. To wada wobec
   `CLAUDE.md` §2 reguły 4, do naprawy w `CLAUDE.md`, nie tutaj.
7. **Nie uruchomiłem żadnej z proponowanych kontroli negatywnych.** Kolumna „dowód, że zadanie
   jest zrobione — i jak pada" w §12.4 opisuje **zamierzony** kształt testu. Zgodnie z
   `CLAUDE.md` §4.1 żaden z nich nie jest testem, dopóki ktoś nie zobaczy, jak pada bez poprawki
   i przechodzi z nią.
8. **Pomiary na zbudowanym drzewie nie są dziś odtwarzalne.** Rozmiary artefaktów, sygnatury
   hybrydy i zawartość `build/fstools/bin/` pochodzą z sesji, w której drzewo budowania
   istniało. W czystym drzewie `build/` zawiera **wyłącznie** `container.tag`,
   `hostbuild-eos-control` i `id_ed25519.pub.toml` — nie ma `build/x86_64/eos/` ani
   `build/fstools/`. **Sprawdzić:** odtworzyć `make CI=1 ARCH=x86_64 CONFIG_NAME=eos live`
   i `make fstools`, a potem powtórzyć pomiary offsetów i listę binarek.
9. **Nie przeczytałem kodu bootloadera.** Klasyfikacja licznika prób rozruchu jako
   **NOWY PODSYSTEM** (§12.5, M7) stoi na tym, że bootloader nie ma ścieżki zapisu —
   za `ADR-0009`, nie z odczytu. `recipes/core/bootloader/` to w tym drzewie `recipe.toml`
   + `sbat.csv`. **Sprawdzić:** `eos-bootloader` rev `87b214b5` — czy istnieje jakakolwiek
   ścieżka zapisu do ESP lub RedoxFS-a.
