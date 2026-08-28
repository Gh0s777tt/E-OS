# 🧭 E-OS ROADMAP v2 — od QEMU do prawdziwego komputera, i dalej

> **To jest osobny dokument.** `ROADMAP.md` (v1) prowadzi bieżące `R-NNN`/`U-NNN`; tu jest
> **plan rozwoju drugiej generacji**: sterowniki dysków i nowych technologii, rozbudowa
> `eos-guard` w pakiet bezpieczeństwa i `eos-notes` w szyfrowany notatnik.
>
> **Każdy stan poniżej jest zmierzony w plikach**, nie przepisany z podsumowań — audyt `U-201`
> (143 twierdzenia, 32 fałszywe) i `U-203` (inwentarz sterowników + realny stan aplikacji).
> Gdzie coś jest prognozą, a nie pomiarem, jest to napisane wprost.

Legenda: ✅ mamy · 🟡 częściowo · 🔴 brak · 🖥️ da się z Maca · 🐧 wymaga Linuksa/WSL2 · ⚙️ wymaga sprzętu

---

## 0. Trzy osie, na których stoi ten plan

Każda pozycja jest klasyfikowana w trzech wymiarach naraz, bo mylenie ich to źródło złudzeń:

1. **Stan** — mamy / częściowo / brak (zmierzone).
2. **Gdzie da się to zrobić** — Mac / Linux / dopiero sprzęt.
3. **Co odblokowuje** — bo kolejność wynika z zależności, nie z atrakcyjności.

> **Zasada nadrzędna:** *najpierw zmierz na metalu, potem planuj.* Nic w repozytorium nigdy nie
> działało na fizycznym sprzęcie — każdy zielony ptaszek to QEMU. Etap 0 z
> [`plan-do-sprzetu.md`](docs/plan-do-sprzetu.md) jest przed wszystkim innym w tym dokumencie.

---

## 1. Sterowniki — co mamy, czego brakuje, co zbudować

### 1.1 Co JEST w obrazie (zmierzone w `base.pkgar`, obie architektury)  ✅

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

### 1.2 Martwe wpisy do posprzątania (`R-803`)  🟡

Na **aarch64** obraz wiezie pliki `pcid.d/ac97d.toml`, `vboxd.toml` oraz initfs `ahcid`/`ided`,
których **binaria nie istnieją** dla tej architektury (Makefile kopiuje wszystkie `config.toml`
bez względu na architekturę). To nie awaria, ale bałagan, który każe zgadywać. **Zadanie:**
warunkowe kopiowanie `pcid.d` po architekturze.

### 1.3 Sterowniki dysków — co zbudować, co to daje

| poz. | co zbudować | co to daje | gdzie | stan |
|---|---|---|---|---|
| **V2-D01** | `ahcid`/`ided` **dla aarch64** albo usunięcie martwych wpisów | uczciwy obraz aarch64; SATA na płytach ARM | 🖥️ Mac (QEMU) | 🟡 |
| **V2-D02** | **NVMe: SMART/health, TRIM/discard, multi-queue** | trwałość i wydajność na realnych SSD; dziś `nvmed` jest minimalny | 🖥️ Mac (QEMU) → ⚙️ walidacja | 🔴 |
| **V2-D03** | **SDHCI/eMMC generyczny** (nie tylko RPi) | karty SD i eMMC w laptopach/tabletach x86 | ⚙️ wymaga krzemu | 🔴 |
| **V2-D04** | **RAID 0/5/10 z parzystością** (`R-912`, rozszerza `raid1d`) | realna macierz; dwa dyski w QEMU wystarczą do testu | 🖥️ Mac (QEMU) | 🔴 planowane |
| **V2-D05** | **USB4 / Thunderbolt storage** (`R-932`) | zewnętrzne obudowy NVMe, hot-plug PCIe | ⚙️ wymaga krzemu | 🔴 |
| **V2-D06** | **UFS** (Universal Flash Storage) | pamięć w nowoczesnych urządzeniach mobilnych | ⚙️ wymaga krzemu | 🔴 brak w roadmapie w ogóle |

### 1.4 Nowe technologie — magistrale, które blokują resztę

| poz. | co | co odblokowuje | gdzie | stan |
|---|---|---|---|---|
| **V2-N01** | **Magistrala I2C + I2C-HID** (`R-916`) | **touchpady laptopów**, czujniki, Type-C PD — dziś **nie istnieje żadna** | ⚙️ realny sprzęt | 🔴 blokada T3 |
| **V2-N02** | **TPM 2.0 (TIS/CRB) + measured boot** (`R-913`) | measured boot, sealing kluczy; `swtpm` w QEMU pozwala **wstępnie** zbudować na Macu | 🖥️ Mac (swtpm) → ⚙️ PCR na sprzęcie | 🔴 |
| **V2-N03** | **Podpisany bootloader / Secure Boot** (`R-F27`) | instalacja **bez wchodzenia do BIOS-u** — dziś `bootloader.efi` nikt nie podpisuje | 🐧/⚙️ MOK albo shim | 🔴 najgłośniejsza bariera |

---

## 2. Co da się z Maca, co wymaga Linuksa, co wymaga sprzętu

To rozstrzyga, **czego można dotknąć dziś**, a co czeka na inny host albo na fizyczny komputer.

### 2.1 🖥️ Da się z tego Maca (podman + QEMU/TCG)
- Zbudować **i uruchomić** obraz **aarch64** — pełna, sprawdzona ścieżka.
- Zbudować i uruchomić **x86_64** pod emulacją TCG (wolno, ale działa od `U-172`).
- Zbudować bazowe aplikacje COSMIC (`cosmic-edit`/`files`/`term`).
- Wypalić pendrive z `redox-live.iso` (`dd` — każdy host to potrafi).
- Cały samosprawdzający się toolchain (bramki, podpisy, reproducery).

### 2.2 🐧 Wymaga Linuksa (lub Windows + WSL2)
- **Rozszerzone aplikacje COSMIC** (`cosmic-store`/`settings`/`reader`) — ich `fontconfig → host:gperf`
  toolchain jest publikowany **tylko** dla `x86_64-linux`; na tym aarch64-Macu daje 404.
- **Szybka, akcelerowana emulacja (KVM)** — macOS ma tylko `hvf`, który wywraca się pod obciążeniem
  (`R-F23`) i daje ~1,9×; sensowna szybkość x86_64 CI wymaga runnera z KVM.

### 2.3 ⚙️ Wymaga fizycznego sprzętu
- **Pierwszy rozruch na metalu** — nic tu nigdy nie działało na sprzęcie.
- Dowód, że x86_64 działa na realnym pececie (zbudowane i boot-smoke pod emulacją, ale nie na metalu).
- Walidacja `vesad`/GOP, NVMe/AHCI, `xhcid`, kart sieciowych — to ma sens dopiero na firmware.
- **Wyłączenie Secure Boot** (bo bootloader niepodpisany) i **komputer stacjonarny** (bo brak I2C-HID = brak touchpada).

---

## 3. `eos-guard` → pakiet bezpieczeństwa

### 3.1 Co `eos-guard` robi DZIŚ (zmierzone w binarce)  ✅
Kontroler integralności plików: hashuje `blake3` pliki w `/usr/bin` i `/etc`, trzyma wzorzec w
SQLite, na żądanie skanuje i klasyfikuje Ok/New/Modified/Removed, ostrzega o setuid, wykrywa
własną manipulację. GUI w Slint. **To wszystko** — jednozadaniowy, nie pakiet.

### 3.2 Czego brakuje do pakietu, i co jest **realne**
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

### 3.3 Kolejność (`V2-S`)
- **V2-S01** 🖥️ — biblioteka `tcp:`/`udp:`/`icmp:` + pierwsze CLI: port scan, DNS, ping, whois, banner.
- **V2-S02** 🖥️ — plik+CPU: hash calculator, metadata extractor, YARA/Sigma matcher, log analyzer.
- **V2-S03** 🖥️ — klient HTTP(S) → website/SQLi/XSS/cert checker, URL/IOC reputation.
- **V2-S04** 🖥️ — dashboard „Personal Cybersecurity" spinający powyższe (Slint, jak `eos-guard`).
- **V2-S05** ⚙️ — prymitywy: capture promiscuous i szyna hot-plug → sniffer, USB tracker (zmiana w jądrze).

---

## 4. `eos-notes` → szyfrowany notatnik

### 4.1 Co `eos-notes` robi DZIŚ (zmierzone)  ✅
Notatki tekstowe (tytuł + treść) w SQLite WAL, autozapis, lista w panelu, filtr podłańcuchem,
usuwanie. GUI Slint. **Brak** Markdown, **brak** szyfrowania, tabów, tagów, linków, załączników.
Do wielkiej listy życzeń jest bardzo daleko — i uczciwie to trzeba powiedzieć.

### 4.2 **Część funkcji system już ma** — nie pisać ich od nowa
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

### 4.3 Realna kolejność (`V2-Nx`), od fundamentu
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

## 5. Co system ma „sam z siebie" (i co z tego wynika)

Pytanie z prośby: *czy system sam posiada niektóre z tych funkcji?* Tak — i to zmienia plan,
bo część pracy to **podłączenie**, nie **napisanie**:

- **Szyfrowanie dysku** — RedoxFS AES-XTS (`R-502`), z akceleracją ARMv8 Crypto.
- **Podpisy i integralność** — `eos-repo-sign` (ed25519 + ML-DSA-65), `eos-guard` (blake3).
- **Izolacja** — model capability, namespace per proces, IPC-only, brak `sudo:` bez uprawnień.
- **Sieć user-space** — `smoltcp`, schematy `tcp:`/`udp:`/`icmp:` — fundament pod narzędzia recon.
- **Bezpieczeństwo pamięci** — cały stos w Rust; `zeroize` dla kluczy.

---

## 6. Zależności — co przed czym

```
Etap 0: pierwszy rozruch na metalu (plan-do-sprzetu.md)
   └─→ V2-N03 Secure Boot ─→ instalacja bez BIOS-u
   └─→ V2-D01/D02 dyski ─→ realna instalacja
   └─→ V2-N01 I2C-HID ─→ laptopy (touchpad)
eos-guard: V2-S01 sieć → V2-S02 plik/CPU → V2-S03 HTTP → V2-S04 dashboard → V2-S05 prymitywy (jądro)
eos-notes: V2-NT01 Markdown → V2-NT02 szyfrowanie → NT03 organizacja → NT04 linki → … → NT10 wtyczki/sync
```

---

## 7. Czego ten plan świadomie NIE obiecuje

- **Nic tu nie działało na sprzęcie.** Wszystko powyżej to prognoza z kodu i danych upstreamu,
  dopóki Etap 0 tego nie zmieni w pomiar.
- **Trzy klasy narzędzi bezpieczeństwa są zablokowane** brakiem prymitywu OS (sniffer, USB-tracker,
  docker) — wymagają najpierw zmiany w systemie, nie tylko nowej aplikacji.
- **GPU 3D, HDR, USB4, akceleracja graficzna** pozostają zależne od sprzętu i poza ścieżką QEMU.
- **Secure Boot pozostaje wyłączany ręcznie**, dopóki `V2-N03` nie zostanie zrobione.
