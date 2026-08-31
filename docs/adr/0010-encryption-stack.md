# ADR-0010 — Stos szyfrowania dysku

- **Status:** Propozycja — do zatwierdzenia. Nic z tego nie jest zaimplementowane.
- **Data:** 2026-08-30
- **Dowód:** `docs/encryption.md:8,17,19-24,21,88` i „Caveats", `R-502`, `R-913`/`V2-N02`,
  `R-F10`/`U-156`, `U-170`, `U-212`, `recipes/core/redoxfs/recipe.toml:6,15`, `repos.toml:67`,
  `mk/config.mk:47`, `mk/disk.mk:50`, `scripts/install-smoke-drive.py:218,220`,
  `docs/threat-model.md` §3/§6, `docs/architecture/installer-wizard.md` §5,
  `docs/architecture/installer-profiles.md` V-17/§3.2, `docs/architecture/installer.md` §5.4/§8.1/§9.1,
  oraz `src/key.rs` i `src/header.rs:31,121` w `eos-redoxfs` — patrz §0.
- **Zakres:** czym szyfrujemy wolumin systemowy, czym wyprowadzamy z hasła klucz, ile jest dróg
  wejścia i w jakiej kolejności to budujemy.
- **Czego ten ADR NIE rozstrzyga:** Secure Boota (`ADR-0005`, `ADR-0006`), kształtu ekranu
  szyfrowania w kreatorze (`docs/architecture/installer-wizard.md` §5) ani transakcji instalacji
  (`docs/architecture/installer.md` §6). Odwołuję się do nich; nie podejmuję ich od nowa.

## 0. Skąd pochodzą fakty

Ten ADR opiera się na trzech źródłach o różnej sile i rozdzielam je jawnie, bo od tego zależy,
które zdania wolno traktować jak pomiar.

| źródło | co z niego biorę | siła |
|---|---|---|
| drzewo na tej gałęzi | `recipes/core/redoxfs/recipe.toml`, `repos.toml`, `mk/config.mk:47`, `mk/disk.mk:50`, `scripts/install-smoke-drive.py`, `docs/*.md`, `ROADMAP*.md`, `CHANGELOG.md` | odczytane teraz |
| brief autorytatywny zadania | odczyt `src/key.rs` i `src/header.rs` z **rozwiniętego drzewa budowania** | cytat ze źródła, **nie z tej gałęzi** |
| dokumenty siostrzane | `docs/architecture/installer*.md`, `docs/architecture/system-updates.md` | propozycje, nie stan |

**Źródła `eos-redoxfs` nie ma na tej gałęzi.** `recipes/core/redoxfs/` zawiera wyłącznie
`recipe.toml`; `find . -name header.rs` nie zwraca nic; `Cargo.lock` nie zawiera wpisu
`redoxfs`. Wszystkie twierdzenia o `KeySlot`, o Argon2id i o pętli odblokowania pochodzą
**z briefu**, który odczytał je w `recipes/core/redoxfs/source` po pobraniu źródeł.
**Co sprawdzić przed zatwierdzeniem:** `make fstools_fetch` (albo `make fetch`), potem
`recipes/core/redoxfs/source/src/key.rs` i `.../src/header.rs` — i wpisać tu numery linii
odczytane na miejscu. Do tego czasu każdy taki fakt jest oznaczony **[wg briefu]**.

Przypięcie `eos-redoxfs` — **korekta wobec pierwszej wersji tej sekcji, która twierdziła, że
z tej gałęzi nie da się rozstrzygnąć, która rewizja obowiązuje. Da się, i to bez `git log`.**
Obowiązuje `58824d70a07b96e36456968723570bb8468e0dcf`: ta sama wartość stoi w `repos.toml:67`
(`pinned_rev`) i w `recipes/core/redoxfs/recipe.toml:6` (`rev`), a `scripts/eos-repos.sh pins
--strict` porównuje dokładnie te dwa miejsca. `555359ef61` jest rewizją **wcześniejszą**:
wstawiło ją zamknięcie `R-F10` (`U-156`: `b0f6dff6` → `555359ef61`), a podbiło `U-170`
(poprawka `R-F19`, *„Fixed in `eos-redoxfs` `58824d7`"*). Kolejność wpisów rozstrzyga kierunek:
`U-156` < `U-170`. Zdanie „dwie różne rewizje, nie wiadomo która" było więc twierdzeniem
o niesprawdzonym rejestrze, nie o rejestrze.

Co z tego **nie** wynika. Po pierwsze — że `key.rs` i `header.rs` są w obu rewizjach identyczne;
`U-170` opisuje swoją zmianę jako obsługę `rmdir` korzenia własnego schematu **w demonie**, czyli
poza tymi plikami, ale to jest opis, nie różnica. Po drugie — że brief na pewno czytał ten kod:
cookbook wymeldowuje `recipes/*/source` na rewizji z receptury, **ale nie przełącza rewizji na
brudnym drzewie źródeł** — wtedy przepis pada, a `make all` i tak buduje ze starego kodu
(`CLAUDE.md` §9). **Co sprawdzić:** po `make fstools_fetch` —
`git -C recipes/core/redoxfs/source rev-parse HEAD` (musi dać `58824d70…`) oraz
`git -C recipes/core/redoxfs/source diff 555359ef61..58824d70 -- src/key.rs src/header.rs`.
Do tego czasu liczba slotów i wariant KDF zostają **[wg briefu]**, a nie pomiarem.

### Legenda znaczników

| Znacznik | Znaczenie |
|---|---|
| **JEST** | działa dzisiaj — z dowodem: plik:linia, nazwa binarki, pozycja `R-*` |
| **DO ZBUDOWANIA** | wykonalne na Redoksie bez nowego podsystemu |
| **NOWY PODSYSTEM** | wymaga zbudowania czegoś, czego Redox nie ma w ogóle |
| **NIEREALNE DZIŚ** | zależy od ekosystemu, którego nie ma i nie będzie szybko |

---

## Kontekst

### 1.1 Co realnie jest

| element | dowód |
|---|---|
| AES-XTS-128 jako szyfr woluminu RedoxFS | `docs/encryption.md`; `docs/threat-model.md:29` |
| szyfrowanie wdrażane **przy instalacji**, nie w obrazie | `docs/encryption.md`, „Design note" |
| `redoxfs-mkfs --encrypt` i przelot flagi przez build | `mk/config.mk:47` (`REDOXFS_MKFS_FLAGS`), `mk/disk.mk:50` |
| instalacja nienadzorowana z `[general] encrypt_disk` | `docs/encryption.md` §1, `docs/getting-started/install.md` §3 |
| bootloader pyta o hasło i odblokowuje root **przed** załadowaniem jądra | `docs/encryption.md:19-24`, zweryfikowane end-to-end 2026-07-11 na aarch64 **i** x86_64 pod UEFI, 0 wyjątków / 0 panik |
| sprzętowe AES na aarch64 w ścieżce FDE | `R-502` (✅), `recipes/core/redoxfs/recipe.toml:15` → `RUSTFLAGS="--cfg aes_armv8"` |
| jedna wersja RedoxFS po obu stronach formatu (bootloader ↔ system) | `R-F10` zamknięte w `U-156`; `ci-boot-smoke.sh` PASS |
| KDF woluminu to **Argon2id**, `Version::V0x13`, wyjście 16 B, zależność `argon2 = "0.4"` | rodzina KDF potwierdzona **na tej gałęzi**: `docs/encryption.md:8` — *„the key derived from your password (**argon2**)"*. Wariant `id`, wersja i długość wyjścia: **[wg briefu]** — `src/key.rs` |
| nagłówek ma **64 sloty klucza**: `pub key_slots: [KeySlot; 64]` | **[wg briefu]** — `src/header.rs:31` |
| `KeySlot` = `salt` + para `EncryptedKey` (dwa klucze, bo AES-XTS) | **[wg briefu]** |

### 1.2 Korekta, która przesuwa połowę zamówienia o jedną klasę

Dwa zdania z dokumentów siostrzanych są, w świetle odczytu źródła, **nieprawdziwe**, i to jest
najważniejsza rzecz w tym ADR-ze:

1. `docs/architecture/installer.md` §5.4 mówi: *„`argon2id` w projekcie **jest**, ale to hasła
   kont, nie klucz woluminu"*, i klasyfikuje „Argon2id na woluminie" jako **NIEREALNE DZIŚ**.
   **Fałsz.** KDF woluminu **jest** Argon2id **[wg briefu]**, a sama rodzina KDF jest
   potwierdzona nawet bez briefu — `docs/encryption.md:8`. Zamówiona pozycja rozpada się na
   dwie: **algorytm — JEST**, **konfigurowalne parametry — DO ZBUDOWANIA**.
   Dwa dokumenty siostrzane mówią tu **różne rzeczy** i naprawa jest w każdym inna:
   `installer.md` §5.4 ma zły **znacznik** (NIEREALNE DZIŚ → JEST/DO ZBUDOWANIA), a
   `installer-wizard.md` §5.3c ma znacznik **dobry** (DO ZBUDOWANIA `S`–`M`) i tylko zbędne już
   **[NIEZWERYFIKOWANE]** przy wariancie KDF.
2. `docs/architecture/installer-wizard.md` §5.7 pyta **[NIEZWERYFIKOWANE]**, *„czy `KeySlot` już
   jest liczbą mnogą"*. **Jest — 64 sztuki [wg briefu].** Format na dysku **już dziś** dopuszcza
   wiele haseł, plik klucza i klucz odzyskiwania. Brakuje **wyłącznie narzędzi**.

Konsekwencja jest praktyczna, nie redakcyjna: klucz odzyskiwania, drugie hasło i plik klucza
**nie są nowym podsystemem i nie wymagają zmiany formatu na dysku**. To jest praca w warstwie
narzędzi nad formatem, który już ją przewiduje. Dokumenty siostrzane trzeba poprawić w tym
punkcie; ADR jest niezmienny, więc zapisuję korektę tutaj, a nie w nich.

### 1.3 Fakt strukturalny, z którego wynika pięć „nie da się"

**Szyfrowanie w E-OS jest własnością systemu plików, nie warstwy blokowej.** RedoxFS szyfruje
sam siebie. Redox **nie ma device-mappera** i nie ma stosowalnej warstwy blokowej, więc nie ma
czego układać w warstwy. Wszystkie zamówione warianty warstwowe — LUKS na LUKS, kaskada,
nagłówek odłączony, wolumin ukryty — zakładają, że taka warstwa istnieje. Nazwanie tego braku
raz jest uczciwsze niż pięć osobnych wymówek (za `docs/architecture/installer-wizard.md` §5.1).

**Jeden trop, który by to zmienił, i wciąż nie jest sprawdzony:** `raid1d` (`R-501`, ✅) jest
userspace'owym RAID-1 i musi w jakiejś formie wystawiać urządzenie złożone z innych.
**[NIEZWERYFIKOWANE]**, czy robi to schematem, który `redoxfs` potrafi otworzyć jako dysk
docelowy. **Co sprawdzić:** `eos-base`, `drivers/storage/raid1d/src/**`. Jeżeli tak — istnieje
zalążek stosowalnej warstwy blokowej i §3.2 wymaga rewizji.

### 1.4 Czego nie ma i co z tego wynika (zastrzeżenia, których nie wolno pominąć)

Cytuję `docs/encryption.md`, „Caveats", bo dokument o szyfrowaniu nie ma prawa ich zamazać:

- **Brak audytu kryptograficznego osoby trzeciej.** *„Don't rely on it for high-assurance use
  yet."* AES-XTS-128 jest zaimplementowane w Ruście i nikt z zewnątrz tego nie przejrzał.
- **Brak powiązania z TPM / Secure Boot.** Hasło jest **jedynym** sekretem, a bootloader na ESP
  jest jawny — atak na sam monit o hasło jest w modelu zagrożeń, nie poza nim.
- **Brak depozytu klucza i brak automatycznego odblokowania — z założenia.** Zapomniane hasło
  to dziś **całkowita, nieodwracalna utrata danych**.

Do tego dochodzi to, co mówi `docs/threat-model.md` §6 (pozycja „measured-boot (TPM) chain",
`R-913`), i to są cytaty stamtąd, nie parafraza: brak IOMMU — *„`Dmar::init` is still a TODO"*,
przez co podmieniony sterownik *„reaches DMA"*; kilkanaście sterowników (`xhcid`, `e1000d`,
`usbhidd`, `usbscsid`, `ihdad`, `rtl8168d` i dalsze) ładuje się z **niepodpisanego** roota po
zamontowaniu; w trybie live *„the whole disk image is read into RAM unverified"*. Szyfrowanie
chroni **wyłączony** sprzęt (`physical-lost-device` z §3 modelu) i nic ponadto.

### 1.5 Trzy usterki dnia dzisiejszego

To nie są propozycje, tylko stan:

1. **Ścieżka paniki w odblokowaniu.** Pętla po slotach zawiera `slot.cipher(password).unwrap()`
   z komentarzem `//TODO: handle errors` **[wg briefu]**, `src/header.rs:121`. Panika w tym
   miejscu to maszyna, która nie startuje i nie mówi dlaczego.
2. **Błędne hasło kosztuje do 64 wyprowadzeń Argon2id**, poprawne w slocie 0 — jedno
   **[wg briefu]**. To realna asymetria czasowa i realny koszt na starcie.
3. **Dokumentacja podaje dwa różne limity prób.** `docs/encryption.md:21` cytuje
   `RedoxFS password (1/10):`, a `docs/encryption.md:88` — `RedoxFS password (1/3):`. Trzeci zapis,
   `docs/encryption.md:17`, podaje monit jako `RedoxFS password (attempt/attempts):`, czyli bez
   liczby, więc nie rozstrzyga. Limit prób jest jedyną obroną przed zgadywaniem przy monicie, więc
   ta liczba musi być jedna i musi być zmierzona. **Co sprawdzić:** pętla monitu w `eos-bootloader`.

### 1.6 Co zamówiono — klasyfikacja

| zamówiona zdolność | znacznik | uzasadnienie w jednym zdaniu |
|---|---|---|
| FDE hasłem (dzisiejsza) | **JEST** | `docs/encryption.md`, zweryfikowane na obu architekturach |
| szyfrowany `/boot` | **JEST** | nie ma osobnego `/boot` — jądro i initfs leżą **wewnątrz** szyfrowanego roota (`installer-wizard.md` §5.5) |
| **Argon2id na woluminie — algorytm** | **JEST** | `src/key.rs` **[wg briefu]**; koryguje `installer.md` §5.4 |
| **Argon2id — konfigurowalne parametry** | **DO ZBUDOWANIA** | `ParamsBuilder::new()` ustawia tylko `output_len` **[wg briefu]**; parametry trzeba zapisać w slocie |
| wiele haseł / klucz odzyskiwania / plik klucza | **DO ZBUDOWANIA** | format ma 64 sloty **[wg briefu]**; brakuje narzędzi |
| konfigurowalny szyfr woluminu (np. AES-XTS-256) | **DO ZBUDOWANIA** | zmiana formatu nagłówka + wybór implementacji |
| **zgodność z formatem LUKS2** | **NIEREALNE DZIŚ** | LUKS2 to nagłówek **nad dm-cryptem**, a dm-crypta nie ma — §3.1 |
| **LUKS na LUKS** (dwie warstwy) | **NIEREALNE DZIŚ** | ta sama blokada co wyżej, podniesiona do kwadratu: warstwowanie wymaga warstwy, której nie ma — §1.3 |
| **kaskady szyfrów** (AES + Serpent/Twofish) | **NOWY PODSYSTEM** | wymaga warstwy blokowej + drugiego szyfru + wsparcia w bootloaderze — i jest złym wyborem, §3.3 |
| **TPM2 z polityką PCR** | **NIEREALNE DZIŚ** | `R-913`/`V2-N02`: brak sterownika, brak dziennika TCG, brak pomiarów |
| **FIDO2** | **NIEREALNE DZIŚ** | klucza używa się w bootloaderze, **przed** startem sterowników — §3.4 |
| **nagłówek odłączony** | **NOWY PODSYSTEM** | rozdzielenie nagłówka od danych + wykrywanie drugiego nośnika w bootloaderze — §3.5 |
| **wolumin ukryty / plausible deniability** | **NIEREALNE DZIŚ** | §3.6; i odrzucone także merytorycznie |
| **szyfrowany swap** | **NOWY PODSYSTEM** | swapu nie ma **w ogóle** — `ADR-0008` D7 („Bez partycji swap") i `installer.md` §5.2. Nie dubluję tej pozycji; szyfrowanie urządzenia, którego nie ma, nie jest osobną pracą, a gdy swap powstanie, ten wiersz wraca jako warunek jego przyjęcia |
| szyfrowanie ESP | **NIEREALNE DZIŚ** — i nie „dziś" | ESP czyta **firmware**, zanim uruchomi się jakikolwiek nasz kod; zaszyfrowany ESP to maszyna, która nie startuje. Żaden postęp w Redoksie tego nie zmieni, więc jest to jedyna pozycja tej tabeli, przy której „DZIŚ" jest za łagodne |
| depozyt klucza / auto-odblokowanie | **odrzucone z założenia** | `docs/encryption.md`; nie zmieniamy tego |

---

## Decyzja

### 2.1 Reguła nadrzędna

**Zostajemy przy natywnym szyfrowaniu RedoxFS i budujemy nad nim zarządzanie kluczami.**
Nie wnosimy do systemu drugiego formatu szyfrowania na dysku i nie wnosimy drugiej
implementacji szyfru.

Kolejność prac ustalam po dwóch kryteriach, w tej hierarchii:

1. **Ilu użytkowników trafia na tę awarię i jak bardzo jest nieodwracalna.** Zapomniane hasło
   dotyczy każdego, kto włączył FDE, i kosztuje wszystkie dane. Złamanie AES-128 nie dotyczy
   nikogo.
2. **Czy praca dotyka formatu na dysku.** Wszystko, co da się zrobić **bez** zmiany formatu,
   idzie przed wszystkim, co go zmienia — bo zmiana formatu ma po obu stronach bootloader,
   a `R-F10` pokazał, ile lat potrafi się ukrywać rozjazd między tymi stronami.

### 2.2 Etapy

**Etap 0 — usunąć panikę ze ścieżki odblokowania. `DO ZBUDOWANIA (S)`. Pierwsze.**
`slot.cipher(password).unwrap()` w pętli po slotach zamienia uszkodzony nagłówek w panikę
bootloadera. To jest ta sama klasa błędu, którą projekt już raz zapłacił: bootloader
**panikował** `Failed to open RedoxFS` na zaszyfrowanym roocie, zamiast zapytać o hasło
(`docs/encryption.md`, przypis o `eos-bootloader@083d9fae`).
*Jak ta poprawka może zawieść:* jeżeli nowa obsługa błędu zwinie wszystko do jednego komunikatu,
użytkownik nie odróżni „złe hasło" od „nagłówek uszkodzony" — a to dwie różne naprawy.
*Test negatywny, bez którego to nie jest kontrola:* obraz z jednym przestawionym bitem w slocie
ma dać **komunikat**, nie panikę, i inny komunikat niż złe hasło.

**Etap 1 — klucz odzyskiwania i drugi slot. `DO ZBUDOWANIA (M)`. Największy stosunek wartości
do kosztu w całym dokumencie.**
Dziś jedynym sekretem jest hasło i **nie ma żadnej drogi powrotu**. Format ma 64 sloty
**[wg briefu]**, więc to jest praca w narzędziach, **bez zmiany formatu**. Instalator generuje
wysokoentropijny ciąg, zapisuje go do drugiego slotu i pokazuje **raz**, żądając przepisania go
z powrotem (ekran S10 w `installer-wizard.md` §5.7).
*Jak ta kontrola zawodzi:* slot zapisany, ale nigdy nieotwarty. Instalator, który wpisze klucz
odzyskiwania i uzna to za sukces, sprzedaje kartkę papieru bez pokrycia.
*Czego wymagam:* po zapisie slotu instalator **zamyka i ponownie otwiera wolumin wyłącznie
kluczem odzyskiwania**, a przypadek negatywny (błędny klucz) musi zostać **odrzucony**. Bez tej
pary to jest dekoracja.
*Wiązania:* klucz odzyskiwania **nigdy** nie trafia do pliku odpowiedzi, do dziennika instalacji
(`installer.md` §6.3 już zabrania sekretów w dzienniku — ta reguła obejmuje i ten sekret) ani do
profilu. Dla `encrypt_disk` profile mają już regułę V-17 (`installer-profiles.md`): wartość
dosłowna = **odmowa**. Dla klucza odzyskiwania idę dalej: **nie jest reprezentowalny w profilu
w ogóle**, bo w odróżnieniu od hasła nie jest wybierany przez człowieka, tylko generowany —
więc jego obecność w pliku może służyć wyłącznie wyprowadzeniu go na zewnątrz.

**Etap 2 — narzędzie do slotów i plik klucza. `DO ZBUDOWANIA (M)`.**
Jedna binarka (roboczo `redoxfs-keys`): wypisz sloty, dodaj hasło, dodaj plik klucza, zmień,
usuń. Musi jechać na nośniku instalacyjnym — ale powód trzeba podać dokładnie, bo pierwsza wersja
tego akapitu podawała go za szeroko. Tryb ratunkowy z `installer.md` §8.1 ma dziś „montowanie
RedoxFS, także zaszyfrowanego (monit o hasło)" ze znacznikiem **JEST**, więc dysk **przy znanym
haśle** otworzy bez żadnego nowego narzędzia. Czego nie umie: naprawić dostępu, gdy hasło
przepadło, i dołożyć drugiego sekretu. To jest jedyny powód, dla którego `redoxfs-keys` jedzie
na nośniku.
*Jak to zawodzi — i to jest najgroźniejsza operacja w całym ADR-ze:* usunięcie **ostatniego**
działającego slotu to nieodwracalna utrata dysku, wykonana jednym poleceniem.
*Czego wymagam:* „slot niepusty" **nie jest** dowodem, że da się wejść — dowodem jest wyłącznie
udane wyprowadzenie klucza. Usunięcie slotu wymaga, żeby **w tej samej sesji** otwarto wolumin
**innym** slotem; inaczej narzędzie odmawia. Liczenie niezerowych bajtów jest tu tą samą klasą
pomyłki co strażnik rozmiaru bloku z `R-607`: kontrolą, która nie może zapalić się na czerwono.
*Uwaga o pliku klucza:* plik klucza na nośniku, który jest zawsze wpięty, **nie jest** drugim
czynnikiem — to hasło zapisane obok zamka. Domyślnie wyłączony, opisany tym zdaniem.

**Etap 3 — parametry Argon2id i identyfikator szyfru w slocie. `DO ZBUDOWANIA (S–M)`.
Jedna zmiana formatu, jedna bramka.**
Parametry Argon2 są dziś domyślne i niekonfigurowalne (`ParamsBuilder::new()` ustawia wyłącznie
`output_len` **[wg briefu]**). Wybór szyfru (np. AES-XTS-256) to ta sama praca: pole w slocie
plus rozgałęzienie w implementacji. **Robimy je razem**, bo dzielą jedyną kosztowną część —
bramkę zgodności formatu — a rozbicie ich na dwie zmiany oznacza przejście tej bramki dwa razy.
*Jak to zawodzi:* bootloader i `redoxfs-mkfs` interpretują nowy slot inaczej → **zaszyfrowany
dysk, którego nie da się otworzyć**. To dokładnie `R-F10`: przez lata bootloader używał innej
wersji RedoxFS niż system i „to interoperuje" było prawdą przez przypadek (`U-156`).
*Bramka, bez której ten etap nie wchodzi:* boot-smoke na **obu** architekturach, na **dysku
zaszyfrowanym**, w czterech przebiegach z jednego builda — wolumin w starym formacie i w nowym,
otwierany bootloaderem starym i nowym. Trzy przebiegi mają przejść, jeden (nowy wolumin, stary
bootloader) ma **odmówić czytelnym komunikatem**, a nie paniką. Bramka, w której wszystko
przechodzi, niczego nie mierzy.
*Sufit, o którym trzeba pamiętać przy strojeniu parametrów:* `m_cost` Argon2 to pamięć
**w bootloaderze**, nie w systemie — a bootloader BIOS-owy ma twardy budżet **384 KiB** rozmiaru
binarki, wymuszony w źródle (`times (384*1024)-($-$$)`; `ADR-0007`, `installer.md` §3.3:
*„twarde 384 KiB, nienaruszalne"*) i skrajnie ubogie środowisko. Ile z tego zostało, jest
**zmierzone, nie oszacowane**: po dołożeniu Ed25519 stage3 waży **308 580 B przy budżecie
347 136 B, zapas 11,1 %** — i dopiero po `lto=true` + `codegen-units=1`, bez których nie mieścił
się w ogóle (`U-212`). Do tego **[NIEZWERYFIKOWANE]**, ile pamięci roboczej ma tam alokator
i jakie są dziś wartości `m`/`t`/`p` (domyślne z `argon2` 0.4).
**Co sprawdzić:** `Params::DEFAULT_*` w wersji przypiętej w `Cargo.lock` forka oraz alokator
w `eos-bootloader`. Dopóki tego nie wiemy, **kreator nie pokazuje suwaka parametrów** —
kontrolka, która niczego nie zmienia, jest gorsza niż jej brak.

**Etap 4 — nic więcej, dopóki nie ma audytu.** Poszerzanie stosu kryptograficznego przed
przejrzeniem go przez stronę trzecią zwiększa powierzchnię błędu, a nie bezpieczeństwo.
To jest decyzja finansowa i organizacyjna, nie techniczna, więc nie dostaje znacznika — ale
dostaje miejsce w konsekwencjach (§4.3).

### 2.3 Czego świadomie NIE robimy

LUKS2, kaskady, TPM2, FIDO2, nagłówek odłączony, wolumin ukryty, depozyt klucza i
automatyczne odblokowanie. Powody — w kolejności, w jakiej zamówienie o nie prosiło — są
w §3. Żadna z tych pozycji nie trafia do kreatora nawet jako pozycja wyszarzona: opcja
wyszarzona to obietnica z datą, a my nie mamy dla nich daty.

### 2.4 Co z tego wynika dla kreatora i profili

- Ekran S5 (`installer-wizard.md` §5) pokazuje **dwa** wybory: szyfrować/nie, oraz — po Etapie 1
  — klucz odzyskiwania. Nic więcej. Lista opcji, których nie ma, nie jest funkcją.
- Ekran S5 mówi wprost, przed czym FDE **nie** chroni: działającym systemem, podmienionym
  bootloaderem, DMA bez IOMMU, cold-bootem. `docs/threat-model.md` §3 ma na to gotowe nazwy
  przeciwników i katalog funkcji ma ich używać (`installer-profiles.md`, `threat.model`).
- Funkcja `disk.encrypt` w katalogu (`installer-profiles.md` §3.2) dostaje `stage = "JEST"`
  i `evidence` wskazujące `docs/encryption.md` z datą weryfikacji 2026-07-11.
- Instalacja z FDE musi mieć **przypadek w harnessie**. Dziś go nie ma:
  `scripts/install-smoke-drive.py:220` wysyła **puste** hasło (`con.send("")`), a komentarz dwie
  linie wyżej (`:218`) mówi wprost *„Empty means an unencrypted install"*.
  Cała ścieżka szyfrowana jest więc poza regresją. To jest ta sama luka, którą
  `installer.md` §9.1 wymienia jako `S` — i jest to jedyny wiersz z tej tabeli, który blokuje
  **wszystkie** etapy tego ADR-a, bo bez niego żadnej z powyższych bramek nie ma na czym uruchomić.

---

## Odrzucone warianty

### 3.1 Przeniesienie LUKS2 — rachunek, nie wzruszenie ramion

Zamówienie prosi o LUKS2 wprost, więc wycena należy się wprost. LUKS2 to **format nagłówka nad
dm-cryptem**. Nie da się wziąć samego formatu: nagłówek opisuje urządzenie blokowe, którego
w Redoksie nie ma.

**Co trzeba napisać:**

| składnik | zakres | rozmiar |
|---|---|---|
| stosowalna warstwa blokowa (schemat wystawiający urządzenie zbudowane z innego) | precedens: `raid1d`, **[NIEZWERYFIKOWANE]** czy nadaje się jako podstawa (§1.3) | **L** |
| cel `crypt` nad tą warstwą — szyfrowanie sektorowe, klucz w pamięci, zarządzanie cyklem życia | najmniejszy kawałek: AES-XTS **już jest** w `redoxfs` | **M** |
| format LUKS2 na dysku | dwie kopie nagłówka, obszar JSON z sumami, obszar slotów z **AF-splitterem** (rozpraszanie antyforensyczne), parametry KDF per slot, obiekty `token`/`keyring`, opcjonalna integralność | **XL** |
| narzędzie klasy `cryptsetup` | `luksFormat`, `luksOpen`, `luksAddKey`, `luksChangeKey`, `luksKillSlot`, kopia i odtworzenie nagłówka | **L** |
| **bootloader czytający LUKS2 przed odblokowaniem** | parser JSON, AF-merge, Argon2id — w środowisku bez systemu operacyjnego, bez alokatora ogólnego przeznaczenia i z budżetem 384 KiB na ścieżce BIOS, z którego po samym Ed25519 zostało **11,1 %** (§2.2, Etap 3) | **XL** |
| migracja i współistnienie dwóch formatów w TCB | dokładnie klasa `R-F10` | **L** |

**Suma uczciwie:** to nie jest duży ticket, to jest **rok–dwa lata pracy jednej osoby**
(szacunek z powyższego rozkładu, **nie pomiar**) w komponencie, w którym każda pomyłka daje
**dysk, którego nie da się otworzyć**. Dla porównania: `R-F10` — rozjazd **jednej wersji jednej
biblioteki** po dwóch stronach tego samego formatu — przeleżał w projekcie latami i miał trzy
warstwy, z których każda zasłaniała następną (`U-156`).

**Co byśmy za to dostali — i tu rachunek się rozsypuje:**

- **Współpraca z Linuksem: bliska zeru.** Kontener LUKS2 zawierałby **RedoxFS**, którego żadne
  linuksowe narzędzie nie czyta. `cryptsetup luksOpen` powiódłby się i odsłonił system plików,
  z którym Linux nic nie zrobi. Zyskujemy zgodność **opakowania**, nie dostęp do danych.
- **Wiele slotów klucza: mamy 64** **[wg briefu]**. To jest właśnie ta zdolność, po którą
  najczęściej sięga się po LUKS-a, i ona już jest.
- **Argon2id: już jest** **[wg briefu]**.
- **Tokeny TPM2/FIDO2: LUKS2 daje miejsce, nie zawartość.** Token LUKS2 to wiązanie; żeby
  cokolwiek do niego włożyć, potrzeba sterownika TPM, stosu TSS, PCR-ów i dziennika TCG (`R-913`)
  albo stosu CTAP2 w bootloaderze. Po przeniesieniu LUKS2 mielibyśmy pustą przegródkę i **całą**
  pracę `R-913` nadal przed sobą.
- **Przejrzana implementacja: nie dostajemy jej.** To jedyny mocny argument za LUKS-em —
  `cryptsetup` i dm-crypt są od lat oglądane przez wiele oczu. Ale my byśmy je **napisali od
  nowa**, w Ruście, na mikrojądro. Dostalibyśmy **format** przejrzany przez innych i
  **implementację** nieprzejrzaną przez nikogo — czyli dokładnie ten sam stan co dziś, przy
  czterokrotnie większej ilości kodu w TCB.

**Dlaczego to nie jest pierwszy krok.** Bo nie naprawia żadnej z trzech rzeczy, które psują się
dzisiaj (§1.5): zapomniane hasło nadal kasuje dane, panika w pętli odblokowania nadal jest,
audytu nadal nie ma. Za ułamek tego kosztu — Etapy 0–2, rzędu setek linii nad formatem, który
**już** ma 64 sloty — usuwamy najczęstszą nieodwracalną awarię FDE, jaka istnieje.

### 3.2 Sama warstwa dm-crypt, bez formatu LUKS2

**Znacznik: NOWY PODSYSTEM.** Tańsze niż §3.1 o pozycje „format" i „narzędzie" (odpada `XL` + `L`),
ale zostaje `L` + `M` + `XL` — z bootloaderem w środku.

**Co by dało:** możliwość warstwowania (a więc kaskady i nagłówek odłączony) oraz szyfrowanie
woluminów innych niż RedoxFS. Tych ostatnich nie ma: jedyny inny system plików w drzewie to
`redox-fatfs` dla ESP, a ESP **musi** zostać jawny, bo czyta go firmware.

**Co by kosztowało na stałe:** dwie ścieżki szyfrowania w TCB. Natywnej ścieżki RedoxFS nie da
się usunąć, dopóki bootloader odblokowuje przez nią root — a przeniesienie roota to znowu koszt
z §3.1.

**Co zmieniłoby tę decyzję — konkretnie, żeby dało się to sprawdzić:** jeżeli stosowalna warstwa
blokowa powstanie **z innego powodu**, koszt krańcowy celu `crypt` spada z `L`+`M` do `M`.
Taki powód w rejestrze jest: `R-912` wymienia `R-501c` **root-on-RAID**, a `installer.md` §5.5
notuje, że instalator nie umie dziś instalować na `raid1d`. Gdy root-on-RAID zostanie zbudowany,
tę sekcję należy przeliczyć od nowa — i to jest jedyny warunek jej ponownego otwarcia.

### 3.3 Kaskada szyfrów

**Znacznik: NOWY PODSYSTEM (XL).** Odrzucona także merytorycznie, i to jest ważniejsze niż brak
klocków (rozwinięcie w `installer-wizard.md` §5.4):

- Chroni przed **jednym** zdarzeniem: kryptoanalitycznym złamaniem AES. Gdyby ono nastąpiło,
  przewróciłoby wcześniej cały łańcuch zaufania E-OS — podpisy, repozytorium, TLS — a nie tylko
  dysk. Broniłby się wtedy dysk w martwym systemie.
- Nie chroni przed **niczym** z listy realnych przeciwników z `docs/threat-model.md` §3.
- Kosztuje ~2× pracy CPU na sektor, a przy Serpencie bez akceleracji sprzętowej prognozowane
  10–15× spadku przepustowości (założenia P1/P2 z `installer-wizard.md` §5.2,
  **[NIEZWERYFIKOWANE]** — liczby z Linuksa, nie pomiar na E-OS).
- **Podwaja ilość nieaudytowanego kodu kryptograficznego w TCB.** Dwa nieprzejrzane szyfry to
  nie dwa razy więcej bezpieczeństwa, tylko dwa razy więcej miejsc na błąd implementacyjny.

### 3.4 TPM2 z polityką PCR i FIDO2

**Oba: NIEREALNE DZIŚ.**

**TPM2** — `R-913` / `V2-N02`: brak sterownika TIS/CRB, brak stosu TSS, brak dziennika zdarzeń
TCG, brak pomiarów w bootloaderze. Polityka PCR bez pomiarów jest polityką nad pustym zbiorem.
`ROADMAP.md` §8.4 mówi o piątej warstwie zaufania z `docs/reference/keys-and-tokens.md`, że **wciąż jest pusta**
(tabela w §6a, wiersz 5: „❌ nie istnieje"). To jest **cały łańcuch**, nie jedna funkcja, i ma
własną pozycję w rejestrze — nie tworzę dla niej drugiej nazwy.

**FIDO2** — blokada jest twardsza niż brak stosu CTAP2. Klucza używa się **przy rozruchu,
w bootloaderze**, czyli **przed** uruchomieniem jakiegokolwiek sterownika. `usbhidd` nic tu nie
pomaga, bo startuje później. Bootloader musiałby dostać własny stos USB HID i własną
implementację CTAP2 — w komponencie, który już raz panikował na zaszyfrowanym roocie.

Warto to powiedzieć wprost, bo to zmienia wymowę całego dokumentu: **dopóki nie ma TPM-a,
„dysk jest zaszyfrowany" nie znaczy „ten dysk w tej maszynie"** (`ROADMAP.md`). Nie ma
anti-evil-maid i ADR tego nie obiecuje.

### 3.5 Nagłówek odłączony na nośniku wymiennym

**Znacznik: NOWY PODSYSTEM (L).** Odrzucony jako praca do wykonania teraz.

Wymaga (a) rozdzielenia nagłówka od danych w formacie na dysku i (b) **nowej ścieżki wykrywania
urządzeń w bootloaderze**, który musiałby przed odblokowaniem przeskanować drugi nośnik.
Punkt (b) to praca w najkruchszym elemencie systemu — tym samym, który przez lata używał innej
wersji RedoxFS (`R-F10`) i panikował zamiast pytać o hasło (`docs/encryption.md`).

**Przed czym chroni:** przed tym, że na dysku **widać etykietę** szyfrowanego RedoxFS.
**Przed czym nie chroni:** dysk pełen danych o wysokiej entropii i tak wygląda jak dysk pełen
danych o wysokiej entropii. Chowa **etykietę**, nie **fakt**.
**Czym płaci:** to jedyna pozycja z całego zamówienia, która **dodaje nowy sposób bezpowrotnej
utraty danych** — zgubiony nośnik z nagłówkiem kasuje dysk mimo znanego hasła. Funkcja, której
pierwsze zdanie w interfejsie musiałoby brzmieć „to może skasować Twoje dane", nie wchodzi
przed klucz odzyskiwania, który je ratuje.

### 3.6 Wolumin ukryty / plausible deniability

**Znacznik: NIEREALNE DZIŚ**, i odrzucony **także wtedy, gdyby był realny**. Pełna lista
ograniczeń jest w `installer-wizard.md` §5.8; tu skracam do trzech, które przesądzają:

1. **Sam kod zdradza funkcję.** Bootloader zdolny otworzyć ukryty wolumin **zawiera kod do
   otwierania ukrytego woluminu**, jest publiczny i podpisany. Przeciwnik, który widzi E-OS, wie,
   że funkcja istnieje — więc „to jest zwykły dysk" przestaje być wiarygodne.
2. **E-OS nie ma bezpiecznego kasowania, a SSD unieważnia założenie o nadpisaniu.**
   Wear-leveling i nadmiarowa pojemność powodują, że „nadpisany" sektor fizycznie nadal istnieje.
3. **Model zagrożenia jest ludzki.** Przy przymusie prawnym albo fizycznym przeciwnik nie
   analizuje dysku, tylko pyta dalej. Deniability nie kończy przesłuchania.

Sprzedawanie tego jako ochrony byłoby nieuczciwe wobec ludzi, którzy sięgają po taką funkcję
dokładnie wtedy, gdy stawka jest najwyższa. Uczciwa i tania alternatywa: **osobny nośnik,
fizycznie oddzielony**.

### 3.7 Depozyt klucza i automatyczne odblokowanie

**Odrzucone — podtrzymuję decyzję z `docs/encryption.md`.** Hasło jest wpisywane przy każdym
rozruchu i tak zostaje. Klucz odzyskiwania z Etapu 1 **nie jest** depozytem: nie opuszcza
maszyny użytkownika, nie idzie na serwer i nie jest odtwarzalny przez nikogo poza posiadaczem
kartki. To rozróżnienie musi zostać w interfejsie, bo te dwie rzeczy wyglądają podobnie
i chronią przed czym innym.

Konsekwencja, którą trzeba powiedzieć głośno: na maszynie z FDE **nie ma niepilnowanego
restartu**. Ma to skutek dla systemu aktualizacji — aktualizacja bazy stosowana przy restarcie
zatrzyma się na monicie o hasło (`docs/architecture/system-updates.md` §5.1, przypisane do
`R-712`). Nie zmieniamy tego; wymagamy, żeby interfejs aktualizacji o tym mówił.

### 3.8 Nie robić nic

Wariant realny i dlatego wymieniony. Odrzucony z jednego powodu: **zapomniane hasło to dziś
całkowita utrata danych**, przy zerowej drodze powrotu i przy formacie, który ma 63 wolne sloty
**[wg briefu]**. Nierobienie nic nie jest tu zachowaniem stanu — jest utrzymywaniem awarii,
którą format pozwala usunąć bez zmiany formatu.

---

## Konsekwencje

### 4.1 Co staje się łatwiejsze

- **Zapomniane hasło przestaje kasować dane** (Etap 1). To jedyna zmiana w tym ADR-ze, którą
  zauważy zwykły użytkownik.
- **Tryb ratunkowy z `installer.md` §8.1 dostaje narzędzie**, którym można otworzyć dysk
  i naprawić dostęp (Etap 2). Dziś ma „montowanie RedoxFS, także zaszyfrowanego" i nic do
  zarządzania kluczami.
- **Nie powstaje drugi format na dysku.** Cały łańcuch — `redoxfs-mkfs`, instalator, bootloader
  — zostaje przy jednym opisie woluminu, którego rozjazd `U-156` właśnie zamknął.
- **Rozmowa o TPM/FIDO2 przestaje być rozmową o szyfrowaniu.** Ma swoją pozycję (`R-913`) i to
  tam należy.

### 4.2 Co staje się trudniejsze

- **Zostajemy z formatem niestandardowym.** Nie ma odzyskiwania z Linuksa, nie ma `cryptsetup`,
  nie ma cudzych narzędzi do nagłówka. **Każda droga odzyskania danych prowadzi przez nasze
  narzędzia** — więc muszą jechać na nośniku i muszą być testowane, inaczej „mamy klucz
  odzyskiwania" jest nieprawdą operacyjną.
- **Kopia nagłówka staje się pozycją obowiązkową.** Uszkodzony obszar slotów to utrata dysku
  przy poprawnym haśle. Nie ma dziś `fsck` dla RedoxFS (`installer.md` §8.1 nazywa to **NOWYM
  PODSYSTEMEM** i **luką w roadmapie**) — więc kopia nagłówka jest jedynym tanim zabezpieczeniem,
  jakie da się dołożyć teraz, i należy do Etapu 2.
- **Każda przyszła zmiana formatu ma stałą cenę:** bramka z §2.2, Etap 3. To jest cena za to,
  że `R-F10` już się nie powtórzy — i trzeba ją płacić za każdym razem, także wtedy, gdy zmiana
  wygląda na kosmetyczną.

### 4.3 Dług i kiedy go spłacić

| dług | termin |
|---|---|
| **brak audytu kryptograficznego osoby trzeciej** — dotyczy tego, co **już wydajemy** | przed pierwszym wydaniem reklamowanym jako nadające się do poważnego użytku; do tego czasu `docs/encryption.md` mówi prawdę i ma tak zostać |
| brak przypadku FDE w harnessie instalacji (`scripts/install-smoke-drive.py:220` — `con.send("")`, z komentarzem w linii 218) | **przed Etapem 0** — bez tego żadnej bramki nie ma na czym uruchomić |
| dwie różne liczby prób hasła w dokumentacji (§1.5 pkt 3) | przy Etapie 0, razem z obsługą błędów |
| **treść** `key.rs`/`header.rs` między `555359ef61` a `58824d70` — nie sama rewizja, ta jest rozstrzygnięta (§0) | przed zatwierdzeniem tego ADR-a — rozstrzyga, czy fakty **[wg briefu]** dotyczą treści, którą budujemy |
| brak IOMMU (`Dmar::init` = `//TODO`) i niepodpisane sterowniki z roota | poza tym ADR-em, ale ogranicza wartość FDE i musi być w opisie funkcji `disk.encrypt` |

### 4.4 Gdzie to należy w rejestrze — i czego świadomie NIE numeruję

**Nie tworzę nowych identyfikatorów `R-*`.** Powód jest konkretny, nie ostrożnościowy: brief
dokumentuje potwierdzoną **kolizję numeracji `R-70x`** między `ROADMAP.md` a
`docs/update-system-design.md`, w której `R-704` znaczy raz „rollback", a raz „anti-rollback" —
znaczenia niemal przeciwne. Dokładanie trzeciego źródła numerów do rejestru, który ma już
dwa i jest wewnętrznie sprzeczny, byłoby powtórzeniem tego samego błędu w innym epiku.

Pozycje istniejące, do których ta praca się przypina:

| praca z tego ADR-a | istniejąca pozycja | ta sama praca czy rozszerzenie |
|---|---|---|
| sprzętowe AES w ścieżce FDE | `R-502` ✅ | zrobione; nic nie dokładam |
| jedna wersja RedoxFS po obu stronach formatu | `R-F10` ✅ (`U-156`) | zamknięte; Etap 3 **korzysta** z jego bramki |
| TPM 2.0 / measured boot / pieczętowanie | `R-913`, `V2-N02` | **ta sama praca** — nie nazywam jej po raz drugi |
| przypadek FDE i przypadek 4Kn w harnessie | `R-601` (+ `R-607`) | **rozszerzenie zakresu**, zgodnie z `installer.md` §9.1 |
| tryb ratunkowy z narzędziem do kluczy | `installer.md` §8.1, `C-18` | rozszerzenie; `C-18` cytuję za briefem, **[NIEZWERYFIKOWANE]** co do brzmienia |
| instalacja na `raid1d`, root-on-RAID | `R-912` / `R-501c` | warunek ponownego otwarcia §3.2 |

**Czego w rejestrze nie ma:** pozycji na **zarządzanie slotami klucza woluminu** — klucz
odzyskiwania, wiele haseł, plik klucza, kopia nagłówka. To jest luka **także w roadmapie**, nie
tylko w kodzie, i tak samo jak brak pozycji na `fsck` (`installer.md` §8.1) powinna zostać
nazwana przez rejestr, a nie przez ADR. Naturalne miejsce to epik, który w `ROADMAP.md` nazywa
się **„Hardware capabilities (`R-50x`)"**, motyw: *„storage resilience + crypto performance
+ future-proof signing"* — a nie „`R-5xx`", jak podawała pierwsza wersja tego akapitu, i nie
z uciętym motywem. Wszystkie trzy wypisane tam pozycje — `R-501`, `R-502`, `R-503` — są ✅.
Żeby z tego nie wyszło „epik zamknięty": jego rozwinięcia `R-501b` (resync/rebuild) i `R-501c`
(root-on-RAID) żyją dalej, przypisane do `R-912`, więc przestrzeń `R-50x` nie jest wolna od pracy
— jest wolna od **tej** pracy. **Numer nadaje `ROADMAP.md`, nie ten dokument.**

---

## 5. Zbiorcza tabela znaczników

| zdolność | znacznik | etap |
|---|---|---|
| AES-XTS-128 na woluminie, klucz z hasła | **JEST** | — |
| szyfrowanie wdrażane przy instalacji | **JEST** | — |
| jądro i initfs wewnątrz szyfrowanego roota (bez osobnego `/boot`) | **JEST** | — |
| sprzętowe AES na aarch64 | **JEST** (`R-502`) | — |
| Argon2id jako KDF woluminu | **JEST** **[wg briefu]** | — |
| 64 sloty klucza w formacie na dysku | **JEST** **[wg briefu]** | — |
| obsługa błędów zamiast paniki przy odblokowaniu | **DO ZBUDOWANIA** (`S`) | 0 |
| klucz odzyskiwania (drugi slot) | **DO ZBUDOWANIA** (`M`) | 1 |
| wiele haseł | **DO ZBUDOWANIA** (`M`) | 2 |
| plik klucza | **DO ZBUDOWANIA** (`M`), domyślnie wyłączony | 2 |
| narzędzie do slotów + kopia nagłówka | **DO ZBUDOWANIA** (`M`) | 2 |
| konfigurowalne parametry Argon2id | **DO ZBUDOWANIA** (`S`–`M`) | 3 |
| konfigurowalny szyfr woluminu (AES-XTS-256) | **DO ZBUDOWANIA** (`M`) | 3 |
| zgodność z formatem LUKS2 | **NIEREALNE DZIŚ** | — |
| LUKS na LUKS (dwie warstwy) | **NIEREALNE DZIŚ** | — |
| warstwa dm-crypt (bez LUKS2) | **NOWY PODSYSTEM** | — |
| kaskada szyfrów | **NOWY PODSYSTEM** | — |
| nagłówek odłączony | **NOWY PODSYSTEM** | — |
| TPM2 + polityka PCR | **NIEREALNE DZIŚ** (`R-913`) | — |
| FIDO2 | **NIEREALNE DZIŚ** | — |
| wolumin ukryty | **NIEREALNE DZIŚ** | — |
| szyfrowany swap | **NOWY PODSYSTEM** (za `ADR-0008` D7 — nie dubluję) | — |
| szyfrowanie ESP | **NIEREALNE DZIŚ**, i trwale — §1.6 | — |
| depozyt klucza / auto-odblokowanie | **odrzucone z założenia** | — |

---

## 6. Czego nie udało się zweryfikować

Ta lista jest częścią dokumentu, nie przypisem do niego.

1. **Wnętrze `eos-redoxfs`.** Źródło nie jest rozwinięte na tej gałęzi. Wszystkie fakty
   **[wg briefu]** — Argon2id, `Version::V0x13`, wyjście 16 B, `key_slots: [KeySlot; 64]`,
   `unwrap()` w pętli, domyślne `ParamsBuilder` — pochodzą z odczytu w drzewie budowania, nie
   stąd. **Sprawdzić:** `make fstools_fetch`, potem `recipes/core/redoxfs/source/src/{key,header}.rs`.
2. **Czy `key.rs` i `header.rs` różnią się między `555359ef61` a `58824d70`.** Która rewizja
   obowiązuje, jest już **rozstrzygnięte** (§0: `58824d70`, `repos.toml:67` = `recipe.toml:6`,
   podbite w `U-170`) — otwarte zostaje wyłącznie to, czy brief mógł czytać starszą treść tych
   dwóch plików, oraz czy drzewo źródeł w kontenerze na pewno stało na tej rewizji.
   **Sprawdzić:** `git -C recipes/core/redoxfs/source rev-parse HEAD` oraz
   `git -C recipes/core/redoxfs/source diff 555359ef61..58824d70 -- src/key.rs src/header.rs`.
3. **Parametry Argon2 dziś w użyciu** (`m`, `t`, `p`) oraz ile pamięci roboczej ma alokator
   bootloadera. Rozstrzyga sufit strojenia z Etapu 3.
4. **Rzeczywisty limit prób hasła** w bootloaderze — dokumentacja podaje 3 i 10.
5. **Czy `raid1d` wystawia schemat dyskowy nadający się pod `redoxfs`.** Jeżeli tak, §3.2 wymaga
   przeliczenia. **Sprawdzić:** `eos-base`, `drivers/storage/raid1d/src/**`.
6. **Czy nagłówek RedoxFS ma kopię zapasową w formacie** (drugi egzemplarz na końcu woluminu).
   Rozstrzyga, czy „kopia nagłówka" z Etapu 2 to narzędzie, czy zmiana formatu.
7. **Liczby przepustowości AES-XTS na E-OS.** `R-502` mówi „benchmarked", ale w `ROADMAP.md`
   i `CHANGELOG.md` nie ma ani jednej liczby. Wszystkie porównania wydajności w §3.3 są
   **[NIEZWERYFIKOWANE]** i pochodzą z typowych wyników linuksowych.
8. **Brzmienie znaleziska `C-18`** (brak konta awaryjnego), jedynego `C-*`, którego ten ADR
   używa (§4.4). Cytowane za briefem. Sprawdzone na tej gałęzi: `docs/audit/` zawiera wyłącznie
   `AUDIT-2026-07-13.md` i `AUDIT-2026-08-14.md`, a ciąg `C-18` nie występuje w żadnym z nich —
   więc rejestr `C-*` naprawdę jest gdzie indziej, nie tylko „nie został poszukany".
   **Sprawdzić:** `git show fix/p0-audit-findings:docs/audit/03-security-audit-2026-08-30.md`.

---

## Powiązania

- Szyfrowanie dziś: [`../encryption.md`](../guides/encryption.md)
- Model zagrożeń: [`../threat-model.md`](../security/threat-model.md) §3, §6
- Ekran szyfrowania w kreatorze: [`installer-wizard.md`](../architecture/installer-wizard.md) §5
- Nośnik, transakcja, tryb ratunkowy: [`installer.md`](../architecture/installer.md) §5.4, §6, §8
- Profile i reguła V-17: [`installer-profiles.md`](../architecture/installer-profiles.md)
- FDE a aktualizacje: [`system-updates.md`](../architecture/system-updates.md) §5.1
- Rozruch i zaufanie: [`ADR-0005`](0005-secure-boot-without-microsoft.md),
  [`ADR-0006`](0006-path-to-microsoft-verification.md)
- Mapa kluczy (pięć warstw): [`../keys-and-tokens.md`](../reference/keys-and-tokens.md) §6a
