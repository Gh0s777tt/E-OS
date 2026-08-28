# ADR-0005: Secure Boot bez zależności od Microsoftu

- **Status:** Przyjęty i **udowodniony end-to-end** (`U-206`)
- **Kontekst:** `R-F27`, `V2-N03`

## Problem

`bootloader.efi` jest budowany **niepodpisany**, więc pecet UEFI z włączonym Secure Boot (stan
fabryczny od ~2012) go **odrzuca**. Właściciel projektu chce **automatycznej instalacji** i
**bez przechodzenia przez proces przeglądu Microsoftu** (shim). E-OS jest osobnym systemem, ale
to nie zwalnia go z Secure Boot: firmware ufa **kluczom**, nie systemom.

## Decyzja

Nie ma sposobu, by na **zablokowanym pececie x86_64** z egzekwowanym Secure Boot uruchomić
nieznany bootloader **automatycznie i bez Microsoftu** — to konstrukcja, nie biurokracja. Wobec
tego E-OS przyjmuje **model własnego klucza + zaufanie kontrolowane przez właściciela**:

1. **Podpisujemy `bootloader.efi` własnym kluczem** (`scripts/eos-sign-bootloader.sh`, `sbsign`).
   Klucz podpisujący jest **działaniem człowieka** i żyje **poza repozytorium**, jak każdy klucz.
2. **Zaufanie wnosi właściciel maszyny**, jedną z dróg, żadna nie wymaga Microsoftu:
   - **aarch64 / ARM** — główna, przetestowana architektura E-OS — zwykle **nie wymusza** Secure
     Boot albo pozwala właścicielowi być właścicielem magazynu zaufania. **To najbliżej
     automatycznej instalacji** i akurat tam projekt jest najsilniejszy.
   - **sprzęt wydawany przez nas** — pre-enroll klucza; w pełni automatyczne na naszych urządzeniach.
   - **x86_64 obcy sprzęt** — właściciel raz **wpina nasz klucz** (enrollment) albo **wyłącza
     Secure Boot**. Jeden świadomy krok, dobrze udokumentowany.

**Świadomie NIE wybieramy** ścieżki shim podpisanego przez Microsoft — eliminowałaby ten jeden
krok właściciela na x86_64, ale wprowadza zależność i proces przeglądu, których projekt nie chce.

## Dowód (nie deklaracja)

`scripts/eos-secureboot-proof.sh` uruchamia trzy przypadki pod QEMU z **prawdziwym firmware
Secure Boot** (edk2), na **kluczach jednorazowych**:

| firmware ufa | bootloader | wynik | co dowodzi |
|---|---|---|---|
| **naszemu** kluczowi | podpisany (nasz) | ✅ **uruchomiony** | firmware przyjmuje nasz bootloader |
| naszemu kluczowi | niepodpisany | 🔴 odrzucony | sam podpis jest wymagany |
| **obcemu** kluczowi | podpisany (nasz) | 🔴 odrzucony | wymagane jest **zaufanie do klucza**, nie sam fakt podpisu |

Firmware uruchamia bootloader **wtedy i tylko wtedy**, gdy jest podpisany **oraz** klucz jest
zaufany. Kontrola „obcy klucz" jest tu istotna: wcześniejsza kontrola, która tylko włączała
Secure Boot bez ustawienia Platform Key, była **nieważna** — brak PK to tryb setup, w którym
bootuje wszystko (`U-206`).

## Konsekwencje

- **Automatyczna instalacja jest realna na aarch64** i na sprzęcie własnym; na obcym x86_64
  wymaga jednego kroku właściciela — i dokumentacja musi to mówić wprost.
- Klucz Secure Boot to **kolejny klucz operatora**, poza repozytorium (jak `eos-repo-sign` i
  minisign) — patrz `docs/tokeny.md`.
- Wpięcie **podpisanego** bootloadera do obrazu/ISO (`--write-bootloader`) to następny krok
  integracyjny; mechanizm jest udowodniony, brakuje tylko prawdziwego klucza i złożenia obrazu.

## Integracja (`U-207`)

Podpis należy do **receptury bootloadera**, nie do kroku po budowie. Instalator składa ESP live ISO z paczki `bootloader.pkgar` (`fetch_bootloaders` czyta `usr/lib/boot/bootloader-live.efi`), więc jedynym miejscem, które trafia do bootloadera ładowanego przez firmware, jest podpis **w stage podczas `cook`** — tam cały łańcuch (blake3 → repo.toml → repo.toml.sig → ESP) liczy się nad podpisanym plikiem. Podpisanie kopii z `--write-bootloader` niczego nie dawało (to „dodatkowy" zapis, nie źródło ESP). `recipes/core/bootloader/recipe.toml` podpisuje oba bootloadery, gdy operator poda klucz w `build/sb-signing/` (poza repo); bez klucza — niepodpisane (graceful degrade).

**Dowiedzione end-to-end:** świeże live ISO pod QEMU z firmware Secure Boot startuje pełny system (E-OS Bootloader → RedoxFS) gdy firmware ufa naszemu kluczowi, i daje Access Denied z obcym. Bootloader **systemu zainstalowanego** (ta sama paczka) sygnowany jest tym samym mechanizmem — pozostaje jako naturalne rozszerzenie.
