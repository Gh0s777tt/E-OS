---
title: Droga z QEMU na prawdziwy komputer — plan punkt po punkcie
status: archived
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# 🎯 Droga z QEMU na prawdziwy komputer — plan punkt po punkcie

Ten dokument odpowiada na jedno pytanie: **co zrobić, w jakiej kolejności, żeby E-OS dało się
zainstalować na fizycznym komputerze i dalej rozwijać.** Każda pozycja ma trzy rzeczy: **co
zrobić**, **co to daje** i **co można wykorzystać zamiast pisać od zera**.

Wszystkie stany są zweryfikowane w plikach (`U-201`, 143 twierdzenia, cytaty `plik:linia`), a nie
przepisane z wcześniejszych podsumowań — bo z tamtej listy **32 twierdzenia okazały się fałszywe**.

---

## Zasada porządkująca całość

> **Najpierw zmierz na metalu, potem planuj.**

Nic w tym repozytorium nigdy nie działało na fizycznym sprzęcie — każda weryfikacja to QEMU
(`scripts/ci-boot-smoke.sh`, `repro-intx-lines.sh`, `ci-install-smoke.sh`). **Pierwszy rozruch na
prawdziwym komputerze da więcej informacji niż miesiąc planowania**, bo zamieni prognozy w pomiary.
Dlatego Etap 0 jest przed wszystkim innym, mimo że wygląda skromnie.

---

## ETAP 0 — pierwszy rozruch na metalu  ·  1 wieczór  ·  **zrób to najpierw**

### 0.1 Zbuduj obraz x86_64
```
make CI=1 ARCH=x86_64 CONFIG_NAME=eos all
```
**Uwaga:** samo `make CI=1 all` buduje **aarch64**, mimo że `docs/getting-started/building.md` twierdzi inaczej —
architekturę trzeba podać jawnie.

**Co to daje:** jedyny obraz, który ma szansę uruchomić typowego peceta. x86_64 jest zbudowany i
przeszedł `boot-smoke` pod emulacją (`U-172`), ale **nigdy nie na sprzęcie**.

### 0.2 Zapisz na pendrive
`scripts/ventoy.sh` **nie zadziała** — ma zaszyte `CONFIGS=(demo desktop)` i nie zna `eos`
(`R-F28`). Do czasu poprawki: zwykłe `dd` obrazu `redox-live.iso`.

### 0.3 **Secure Boot: wgraj nasz certyfikat albo wyłącz** ← wybierz jedno
**Nieaktualne jest twierdzenie, że nikt nie podpisuje bootloadera** — `recipes/core/bootloader/`
`recipe.toml:52-65` podpisuje **oba** bootloadery (`bootloader.efi` i `bootloader-live.efi`)
w czasie `cook`, gdy operator poda klucz (`scripts/eos-sb-setup-key.sh`). Udowodnione na obu
nośnikach kluczem operatora (`U-210`), z kontrolą negatywną: obcy klucz → `Access Denied`.

Masz zatem dwie drogi, obie poprawne:
- **wgraj certyfikat E-OS** do firmware (`db`/MOK) — instalacja przy włączonym Secure Boot;
- **albo wyłącz Secure Boot** — szybsze, jeśli tylko testujesz.

Automatyczna instalacja *bez* żadnego z tych kroków wymagałaby shima podpisanego przez
Microsoft — dlaczego tego dziś nie robimy, mówi [`ADR-0006`](../adr/0006-path-to-microsoft-verification.md).

### 0.4 Wybierz **komputer stacjonarny, nie laptop**
Omijasz w ten sposób największą lukę: **nie ma sterownika I2C**, więc nie ma I2C-HID, więc
**żaden nowoczesny touchpad nie zadziała** (`R-916`). Klawiatura i mysz USB działają przez `xhcid`.

### 0.5 Zapisz, gdzie stanął
To jest właściwy produkt tego etapu. Kolejność objawów mówi, czego brakuje:

| dokąd doszło | wniosek |
|---|---|
| firmware nie widzi nośnika | Secure Boot włączony albo zły zapis nośnika |
| bootloader startuje, brak obrazu | `vesad` nie dostał framebufera z UEFI GOP |
| jest obraz, „no root filesystem" | brak sterownika dysku (NVMe/AHCI) dla tego kontrolera |
| jest login, brak klawiatury | `xhcid` nie związał kontrolera USB |
| jest pulpit, brak sieci | brak sterownika tej karty (jest tylko `e1000d`) |

---

## ETAP 1 — łańcuch rozruchu  ·  duża praca  ·  odblokowuje „instalację bez grzebania w BIOS-ie"

### 1.1 Podpisany bootloader (`R-F27`)
**Co zrobić:** podpisać `bootloader.efi` — własnym kluczem z rejestracją w MOK (użytkownik
uruchamia `mokutil`), albo przez `shim` podpisany przez Microsoft (ich proces przeglądu).
**Co to daje:** instalację bez wchodzenia do BIOS-u. **Bez tego E-OS pozostaje systemem dla
kogoś, kto umie i chce wyłączyć Secure Boot.**
**Co wykorzystać:** `shim` z Fedory/Debiana jako wzorzec; klucz podpisujący **nie jest** żadnym z
istniejących — patrz [`keys-and-tokens.md`](../reference/keys-and-tokens.md) §6a, warstwa 5 nie istnieje.

### 1.2 Naprawa `ventoy.sh` (`R-F28`)  ·  mała praca
**Co to daje:** powtarzalny nośnik USB zamiast ręcznego `dd`.

---

## ETAP 2 — sprzęt podstawowy  ·  bez tego nie ma czego renderować

### 2.1 Dysk — sprawdzić, nie pisać
`nvmed`, `ahcid` i `virtio-blkd` **są w obrazie**. Ale `R-803` sam ostrzega, że część wpisów
wskazuje na **nieobecne binaria** — więc pierwsze zadanie to *sprawdzić*, nie pisać nowy sterownik.

### 2.2 Sieć — realna luka
Jest **tylko `e1000d`**, i to wpięte wyłącznie w konfiguracji x86_64. Typowy pecet ma Realtek albo
nowszego Intela. **Co to daje:** bez sieci nie ma pakietów, aktualizacji ani przeglądarki.
**Co wykorzystać:** `R-910` wskazuje RTL8125 i Intel I225/I226 jako pierwsze cele.

### 2.3 Wejście — działa, ale nie na laptopie
`xhcid` + `usbhidd` obsłużą klawiaturę i mysz USB. **I2C-HID nie istnieje** i to nie jest
„nietestowane" — nie ma całej magistrali I2C (`R-916`).

---

## ETAP 3 — instalacja obok istniejącego systemu

**Stan:** instalator **kasuje cały dysk**. Instalacji obok Windowsa czy Linuksa **nie ma**.
`scripts/dual-boot.sh` istnieje, ale jest upstreamowy, wymaga hosta linuksowego i **nie był przez
E-OS testowany**.

**Co to daje:** możliwość używania E-OS na jedynym komputerze, jaki się ma — czyli różnicę między
„ciekawostką na zapasowym sprzęcie" a „systemem, z którym się żyje".

---

## ETAP 4 — infrastruktura sterowników (`R-801`…`R-805`)

**Dlaczego dopiero teraz:** to fundament pod *zarządzanie* sterownikami, a nie pod ich *istnienie*.
Na pustym metalu potrzebujesz najpierw dysku i sieci; katalog sterowników bez sterowników nic nie
daje.

| poz. | co zrobić | co to daje |
|---|---|---|
| `R-801` | `eos-devd` — inwentarz urządzeń (`/scheme/devices`) | wiadomo, **co** jest w komputerze, zanim zgadniesz sterownik |
| `R-802` | podpisany katalog ID → pakiet | sterownik nie jest kodem z internetu |
| `R-804` | pakiety `pkgar` per sterownik | aktualizacja sterownika bez przebudowy obrazu |
| `R-805` | `pcid` spawn-on-demand | wiązanie bez restartu |
| `R-807` | lista „urządzenie jest, sterownika brak" | **to** mówi, co pisać dalej — zamiast zgadywania |

---

## ETAP 5 — grafika  ·  najdalej, wbrew pozorom

### Korekta punktu wyjścia
Częsty błąd w podsumowaniach: „E-OS nie ma żadnego sterownika GPU". **`virtio-gpud` JEST w
obrazie** — w initfs obu architektur, z wpisem w `/lib/pcid.d/initfs.toml` (zweryfikowane,
`U-201`). Punkt startu jest więc lepszy, niż się wydaje.

### 5.1 Co działa dziś
`vesad` (framebuffer z firmware) + Orbital (kompozytor programowy) + rendering programowy.
**Slint, Iced, egui i winit działają już teraz.** Brak GPU **nie blokuje** rozwoju interfejsu.

### 5.2 Kolejność, gdyby jednak brać się za GPU
1. **VirtIO GPU 2D** — już jest; wykorzystać, zanim napisze się cokolwiek nowego.
2. **VirtIO GPU 3D przez virglrenderer** — akceleracja **testowalna w QEMU**, bez fizycznego GPU.
3. **Intel modesetting** — upstream Redoksa zaczął (Kaby Lake, Tiger Lake), dokumentacja Intela
   jest publiczna, iGPU jest najczęstsze, i **nie wymaga zamkniętego firmware'u**.
4. **AMD przez `linux-kpi`** — Red Bear OS pokazał, że `amdgpu` się kompiluje.

**Czego nie robić na start:** NVIDIA (zamknięty firmware GSP, Nova dopiero w szkielecie) i pełna
akceleracja 3D od razu.

---

## Co wykorzystać, zamiast pisać od zera

| źródło | co z niego bierzemy |
|---|---|
| upstream Redox | modesetting Intela, `virtio-gpud`, sterowniki bazowe |
| Red Bear OS | `linux-kpi`, `redox-drm`, `firmware-loader` — dowód, że `amdgpu` da się skompilować |
| Mesa3D | LLVMpipe (jest), Lavapipe, backend do napisania |
| dokumentacja Linux DRM | model UMD/KMD jako wzorzec architektury |
| `HARDWARE.md` | **dane upstreamowe, nie nasze** — rozkład awarii: touchpad, USB, sieć |

---

## Czego ten plan świadomie NIE obiecuje

**Secure Boot pozostanie wyłączany ręcznie**, dopóki `R-F27` nie zostanie zrobione. **Żaden pomiar
w tym repozytorium nie pochodzi ze sprzętu** — wszystko powyżej to prognoza oparta na kodzie i na
danych upstreamu, i Etap 0 istnieje właśnie po to, żeby ją zastąpić faktami.
