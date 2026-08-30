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
