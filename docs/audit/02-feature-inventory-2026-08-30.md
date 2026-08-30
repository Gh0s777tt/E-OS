# Inwentarz funkcji produktu — co E-OS naprawdę dostarcza

**Data:** 2026-08-30 · **Tryb:** wyłącznie do odczytu · **Podstawa:** obraz `eos-x86_64-harddrive.img`
(1 468 006 400 B) zamontowany i przeczytany, nie dokumentacja
**Powiązane:** [`00-inventory-2026-08-30.md`](00-inventory-2026-08-30.md)

> **Metoda.** Wszystko poniżej pochodzi z **zamontowanego obrazu**: `/etc/pkg/packages.toml`
> (manifest zainstalowanych pakietów), listing `/usr/bin` i `/bin` (285 binarek), `/etc`,
> oraz `strings` na konkretnych plikach wykonywalnych. Wersje pochodzą z receptur **i**
> z binarek, gdzie dało się je odczytać. Deklaracje z `config/*.toml` są traktowane jako
> **zamiar**, nie jako fakt — i tam, gdzie się rozjeżdżają, jest to wskazane.
>
> **Uwaga metodyczna, którą trzeba podać:** `redoxfs` nie ma trybu tylko-do-odczytu. Moje
> pierwsze montowania **uszkodziły kopię obrazu w drzewie budowania** (błąd sumy bloku `0x2656`).
> Dalsza praca szła na **kopiach wyeksportowanego artefaktu**, który jest sprawny. Kopia
> w drzewie budowania jest do odtworzenia jednym przebiegiem `make` i nie jest to utrata danych,
> ale jest to szkoda, którą wyrządziłem i którą tu odnotowuję.

---

## 1. Liczby, od których trzeba zacząć

| Miara | Wartość | Skąd |
|---|---|---|
| Pakietów **zadeklarowanych** w łańcuchu konfiguracji | 52 (51 aktywnych + `orbterm` jawnie wyłączony) | `config/x86_64/eos.toml` → `desktop.toml` → `desktop-minimal.toml` → `minimal.toml` → `base.toml` + `server.toml` |
| Pakietów **zbudowanych** | 85 | `repo/x86_64-unknown-redox/*.pkgar` |
| Pakietów **zainstalowanych w obrazie** | **65** | `/etc/pkg/packages.toml` |
| Łączny rozmiar zainstalowanych | **536,0 MB** | suma `storage_size` |
| Binarek w `/usr/bin` + `/bin` | **285** | listing obrazu |
| Pakiety chronione przed usunięciem | `base`, `base-initfs`, `ion`, `kernel`, `libgcc`, `libstdcxx`, `pkg`, `relibc` | `protected` w `packages.toml` |

**Dwadzieścia pakietów zbudowano, ale nie zainstalowano** — w tym cały toolchain (`gcc13`,
`gcc13.cxx`, `gnu-binutils`, `gnu-make`, `gnu-grep`, `sed`, `mpc`, `libgmp`, `libmpfr`),
biblioteki X11 (`libxau`, `libxcb`, `libxkbcommon`) i **`os-test-bins`**. To dobrze: obraz
desktopowy **nie niesie kompilatora ani pakietu testowego**.

**Jeden pakiet zadeklarowany nie został zainstalowany** — `orbterm`, i jest to **celowe**:
`config/desktop.toml:26` ustawia `orbterm = "ignore"` z komentarzem *„orbterm from desktop-minimal
should be ignored"*; zastępuje go `cosmic-term`.

---

## 2. Tabela komponentów — co JEST

| Kategoria | Komponent | Wersja | Po co | Konfiguracja | Powierzchnia ataku | Lepsza alternatywa |
|---|---|---|---|---|---|---|
| **Środowisko graficzne** | `orbital` (serwer wyświetlania + WM + kompozytor) | fork `38226c74b` | rdzeń pulpitu Crimson | `/ui/`, motyw E-OS | serwer wyświetlania dostępny dla `user` przez schemat `orbital` | brak sensownej — to natywny stos Redoksa |
| | `orblogin`, `launcher`, `background`, `desktop` | z `orbutils` `8ad7cd8fa` | logowanie, pasek, tapeta | `/ui/apps` | `orblogin` obsługuje pierwsze uruchomienie i hasła | — |
| **Terminal** | `cosmic-term` | `032a10796` | emulator terminala | — | parsowanie sekwencji sterujących | `orbterm` jest w repo, ale **świadomie wyłączony** |
| **Powłoki** | `ion` (domyślna), `bash` 5.2.15, `nu` (nushell), `sh` | — | powłoka systemowa i interaktywne | `/etc/profile`, `/etc/bash.bashrc` | `ion` jest powłoką logowania **root i user** (`/etc/passwd`) | `bash` 5.3 jest nowszy |
| **Edytory** | `vim` 9.1.0821, `nano` 7.2, `kibi`, `cosmic-edit` | tar/git | edycja tekstu w CLI i GUI | — | `vim` ma dużą powierzchnię (skrypty, modelines) | — |
| **Notatki** | `eos-notes` (własny E-OS) | `9f9eae6e7` | Slint + SQLite/WAL | — | SQLite w przestrzeni użytkownika | — |
| **Menedżer plików** | `cosmic-files` | `28546795b` | GUI plików | — | parsowanie typów MIME (`shared-mime-info` 2.4) | — |
| **Przeglądarka** | `netsurf-fb` 3.11 | tar | przeglądarka WWW (framebuffer) | — | **duża** — parser HTML/CSS/obrazów na niezaufanych danych | Firefox/Chromium **nie są** portowalne na Redox dziś; NetSurf to realistyczny wybór |
| **Panel sterowania** | `eos-control` (własny E-OS) | `40dc67fde` | scala monitor systemu i **monitor integralności plików** (blake3 + SQLite) | — | czyta system plików | — |
| **Powiadomienia / zasilanie / sieć** | `eos-notify`, `eos-notifyd`, `eos-power`, `eos-netcfg`, `eos-settings` | z `orbutils`/E-OS | usługi pulpitu | — | `eos-notifyd` to demon | — |
| **Menedżer pakietów** | `pkg` (z `eos-pkgutils`, gałąź `eos`, `e28063ee2`) | fork | instalacja i aktualizacja pakietów | `/etc/pkg.d/*`, `/etc/pkg/packages.toml`, `/etc/pkg/eos-repo-sign.pub.toml` | **HTTPS + TLS**; patrz §5 — wysyła podatny `rustls-webpki` | — |
| **Instalator** | `redox_installer`, `_gui`, `_tui` | `c8d32ad39` | instalacja na dysk | — | zapisuje partycje, tworzy konta | — |
| **System plików** | `redoxfs` + `redoxfs-mkfs`, `-ar`, `-clone`, `-resize`, `raid1d` | `58824d70a` | natywny FS z sumami kontrolnymi bloków | — | sumy blokowe wykrywają uszkodzenia (sam to zaobserwowałem) | — |
| **Szyfrowanie dysku** | **AES-XTS w `redoxfs`** | — | pełne szyfrowanie przy instalacji | oferowane w `redox_installer_tui` | patrz §5 — nie zweryfikowałem KDF | LUKS2 nie istnieje na Redoksie |
| **SSH** | OpenSSH 9.8 (`ssh`, `sshd`, `scp`, `sftp`, `ssh-keygen`, `ssh-agent`) | tar | zdalny dostęp | `/etc/ssh/sshd_config` | `sshd` jest w obrazie | OpenSSH 10.x jest nowszy |
| **TLS / krypto** | OpenSSL **3.5.3** (potwierdzone w binarce), `ca-certificates` | tar | TLS dla `curl`, `wget`, `git` | `/etc/ssl/openssl.cnf` | aktualna gałąź, dobrze | — |
| **Sieć** | `netstack`, `dhcpd`, `dns`, `ifconfig`, `netstat`, `ping`, `nc`, `curl`, `wget` | `netutils` `d3f578488` | stos sieciowy w przestrzeni użytkownika | `/etc/net/*` | stos w user-space — **mniejsza** powierzchnia w jądrze niż w monolicie | — |
| **Sterowniki** | `pcid`, `pcid-spawner`, `inputd`, `audiod`, `fbcond`, `ipcd`, `ptyd`, `raid1d`, `redoxerd` | z `base` `816546df2` | sterowniki jako **procesy user-space** | `[[drivers]]` w `config/*/eos.toml` | awaria sterownika **nie zabija jądra** — to architektoniczna przewaga | — |
| **Kontrola dostępu** | `/etc/login_schemes.toml` | konfiguracja E-OS | **lista dozwolonych schematów per użytkownik** | patrz §4 | `root` = `*`, `user` = 25 wyliczonych schematów | to jest odpowiednik MAC natywny dla mikrojądra |
| **Uprawnienia** | `sudo`, `su`, `passwd`, `useradd/mod/del`, `groupadd/mod/del` | `userutils` `a43ba3e53` | eskalacja i zarządzanie kontami | `/etc/passwd`, `/etc/shadow` | hasła: **argon2id** (potwierdzone w `/etc/shadow`) | — |
| **Sumy kontrolne** | `b3sum`, `b2sum`, `sha*sum`, `sha3*sum`, `shake*sum`, `md5sum`, `hashsum` | `uutils` | weryfikacja integralności ręczna | — | — | — |
| **Narzędzia CLI** | `coreutils`+`uutils`, `findutils`, `diffutils` 3.6, `file` 5.46, `ripgrep`, `git` **2.13.1**, `gettext` 0.22.5, `zstd` 1.5.7, `patchelf` 0.18.0, `bottom`/`btm`, `uutils-procps` | mieszane | podstawowy zestaw | — | patrz §5 — `git 2.13.1` to rok 2017 | — |

---

## 3. Czego NIE MA — zweryfikowane przeszukaniem 285 binarek obrazu

To jest sedno tego raportu. Każda pozycja sprawdzona wyszukaniem konkretnych nazw programów
w listingu obrazu, nie założeniem.

| Kategoria | Stan | Szukano | Waga |
|---|---|---|---|
| **Antywirus / skaner malware** | **BRAK** | `clamscan`, `clamd`, `freshclam`, `rkhunter`, `chkrootkit` | **MEDIUM** — dla systemu bez binarek osób trzecich to obrona mało istotna; realny zamiennik (monitor integralności) **jest** w `eos-control` |
| **Zapora sieciowa** | **BRAK** | `iptables`, `nft`, `pfctl`, `ufw`, `firewalld` | **HIGH** — obraz ma `sshd`, `netstack`, `dhcpd` i **żadnego filtrowania pakietów**. Jedyna kontrola to lista schematów (§4), która działa per-użytkownik, nie per-port |
| **VPN / Tor / proxy** | **BRAK** | `tor`, `openvpn`, `wg`, `wireguard`, `proxychains`, `torsocks` | **MEDIUM** — nie jest obiecywane w README; staje się luką dopiero, gdy projekt pozycjonuje się obok Tails/Whonix (patrz raport D) |
| **Kopie zapasowe** | **BRAK** | `restic`, `borg`, `duplicity`, `rsnapshot` | **MEDIUM** — jest `tar` i `redoxfs-clone`, więc da się ręcznie; brak narzędzia i brak harmonogramu |
| **Piaskownica aplikacji** | **BRAK** | `bwrap`, `bubblewrap`, `firejail`, `nsjail`, `minijail` | **HIGH** — patrz §4: izolacja jest na poziomie **użytkownika**, nie **aplikacji**. `netsurf` (parser HTML na niezaufanych danych) biegnie z pełnymi uprawnieniami `user` |
| **MAC typu SELinux/AppArmor** | **BRAK w klasycznej postaci** | `setenforce`, `getenforce`, `aa-status`, `semanage` | **LOW** — bo istnieje mechanizm równoważny architektonicznie (§4). Ale **nie ma etykiet ani polityki per proces** |
| **Demon logów / audytu** | **BRAK** | `auditd`, `syslogd`, `rsyslogd`, `journalctl`, `logger` | **HIGH** — jest `dmesg` i schemat `log`, ale **nie ma trwałego, przeglądalnego dziennika zdarzeń**. Po incydencie nie ma czego czytać |
| **Menedżer haseł** | **BRAK** | `pass`, `gopass`, `keepassxc` | **LOW** |
| **Wirtualizacja** | **BRAK** | `qemu`, `kvm`, `virsh` | **LOW** — non-goal |
| **Aktualizacje — mechanizm** | `pkg` **JEST** | — | ale patrz niżej |
| **Aktualizacje — kanał** | **WYŁĄCZONY** | `/etc/pkg.d/*` | **HIGH** — patrz §3.1 |

### 3.1 Obraz nie ma **żadnego aktywnego źródła pakietów**

Oba pliki w `/etc/pkg.d/` mają jedyny wpis URL **zakomentowany**:

```
50_eos:   # E-OS package source (R-701). Signed with the key at /etc/pkg/eos-repo-sign.pub.toml.
          # NOT enabled: the repository below has not been published yet (R-008).
          #https://gh0s777tt.github.io/eos-pkg-x86_64/pkg

50_redox: # Upstream Redox packages are NOT enabled on E-OS images (R-701a).
          # These binaries are built without E-OS hardening flags and the channel is
          # unauthenticated on the client until R-702/R-703 land. Uncomment only if you
          # understand and accept both.
          #https://static.redox-os.org/pkg
```

**To jest spójne i uczciwe**, a nie zaniedbanie: kanał x86_64 faktycznie nie jest opublikowany
(potwierdzone w fazie 0 — GitHub Pages zwraca 404 dla `eos-pkg-x86_64`), a upstream jest wyłączony
z podanym uzasadnieniem. Bramka CI `integrity` pilnuje tego wprost („no image ships an active
unauthenticated package source").

**Ale konsekwencja jest twarda:** zainstalowany system **nie ma jak się zaktualizować**. Nie ma
poprawek bezpieczeństwa dla `git 2.13.1`, `expat 2.5.0` ani niczego innego, dopóki właściciel nie
opublikuje repozytorium i nie odkomentuje wiersza. Dla x86_64 to dziś **system bez ścieżki
aktualizacji**.

> Asymetria wobec aarch64: tam repozytorium **jest** opublikowane (79 pakietów, podpis weryfikuje
> się kluczem z repo — faza 0 §10), więc `50_eos` na tamtym obrazie miałby sens. Nie sprawdzałem
> obrazu aarch64 — `[NIEZWERYFIKOWANE]`.

---

## 4. Kontrola dostępu — to, co E-OS ma zamiast SELinuksa

`/etc/login_schemes.toml` przydziela **listę dozwolonych schematów jądra per użytkownik**.
W Redoksie „wszystko jest schematem" (URL-em), więc odebranie schematu odbiera całą klasę operacji.

```toml
[user_schemes.root]
schemes = ["*"]

[user_schemes.user]
schemes = [
  "debug","event","memory","pipe","serio","irq","time","sys",   # jądro
  "rand","null","zero","log",                                    # bazowe
  "icmp","tcp","udp",                                            # sieć — "ip" USUNIĘTE (R-904a)
  "shm","chan","uds_stream","uds_dgram",                         # IPC
  "file","display.vesa","display*","proc","pty","sudo","audio","orbital",
]
```

**Co to daje.** `user` **nie ma schematu `ip`** — czyli nie ma surowych gniazd IP, a więc nie
podrobi pakietów ani nie podsłucha warstwy 3. To jest realne utwardzenie, wprowadzone świadomie
(`R-904a`), i jest to lepsza granica niż typowe „user może wszystko, czego nie zabroni firewall".

**Czego to nie daje, i trzeba powiedzieć to wprost:**

1. **Granica biegnie po użytkowniku, nie po aplikacji.** `netsurf` parsujący wrogi HTML ma
   dokładnie te same 25 schematów co powłoka użytkownika: `file` (cały system plików w zasięgu
   uprawnień użytkownika), `proc`, `pty`, `sudo`. Kompromitacja przeglądarki to kompromitacja
   sesji. **To jest ta luka, którą w innych systemach zamyka piaskownica** — i której tu nie ma.
2. **`user` dostaje schematy, które wyglądają na uprzywilejowane:** `debug`, `memory`, `irq`,
   `serio`, `sys`. Czy któryś z nich pozwala odczytać pamięć cudzego procesu albo wpiąć się
   w przerwania — **`[NIEZWERYFIKOWANE]`**. Nie znam semantyki tych schematów na tyle, żeby
   twierdzić jedno lub drugie, a zgadywanie w audycie bezpieczeństwa jest gorsze niż milczenie.
   **To jest pierwsze pytanie, które bym zadał na miejscu właściciela.**
3. **`sudo` jest na liście `user`.** To potrzebne do administracji, ale znaczy, że łańcuch
   „przeglądarka → powłoka → `sudo`" nie ma po drodze żadnej dodatkowej bariery poza hasłem.
4. **Nie ma polityki per proces, etykiet ani trybu wymuszania/permisywnego.** Nie da się
   powiedzieć „ten program ma tylko `file` i `display`". Wszystko albo nic, na poziomie konta.

**Ocena:** jako mechanizm to jest **dobre i tanie** — kilkadziesiąt linii konfiguracji daje
granicę, której monolityczne systemy potrzebują całego LSM. Jako **kompletna kontrola dostępu**
to jest **za mało**, bo nie izoluje aplikacji od siebie w obrębie jednego konta.

---

## 5. Bezpieczeństwo dostarczanych komponentów — konkrety

### 5.1 Podatne biblioteki **trafiają do obrazu** (potwierdzone na binarce)

`osv-scanner` na `Cargo.lock` forka `eos-pkgutils`: **20 unikalnych podatności / 247 pakietów**.
Nie wszystkie trafiają do produktu — sprawdziłem, które. `strings` na `/usr/bin/pkg` (5 164 488 B)
z obrazu:

| Biblioteka | Wersja w obrazie | Zalecenia | Czy wysyłana |
|---|---|---|---|
| `rustls-webpki` | **0.103.4** | **6** (`RUSTSEC-2026-0049/0098/0099/0104`, `GHSA-82j2/965h/pwjx/xgp8`) | **TAK** — 11 trafień w binarce |
| `rustls` | 0.23.31, 0.26.2, 0.27.7 | — | **TAK** — trzy różne wersje naraz |
| `ring` | (0.17.8 wg lock) | 2 (`RUSTSEC-2025-0009`) | **TAK** — 95 trafień |
| `reqwest` | 0.12.28 | — | TAK |
| `quinn-proto` | 0.11.13 | 4, w tym CVSS **8.7** | **NIE** — 0 trafień, nie wchodzi do binarki |

**To jest najpoważniejsze znalezisko tego raportu.** `rustls-webpki` to kod **walidujący
certyfikaty TLS**, a `pkg` to program, który po TLS **pobiera pakiety do zainstalowania**.
Sześć otwartych zaleceń w warstwie decydującej o tym, czy rozmawiamy z właściwym serwerem.

Łagodzące, i trzeba to powiedzieć: (a) indeks pakietów jest **dodatkowo** podpisany hybrydowo
ed25519+ML-DSA-65 i weryfikowany kluczem **przypiętym w obrazie** (`/etc/pkg/eos-repo-sign.pub.toml`
— potwierdzone, plik jest), a od `U-223` hasze blake3 są egzekwowane na bajtach; (b) kanał jest
dziś **wyłączony** (§3.1), więc `pkg` nikąd się nie łączy. Czyli: **podatność jest wysyłana,
ale ścieżka jest zamknięta** — do momentu włączenia repozytorium.

### 5.2 Bardzo stare wersje dostarczanych programów

Wersje potwierdzone z **binarek w obrazie**, nie z receptur:

| Program | Wersja w obrazie | Wydana | Ocena |
|---|---|---|---|
| **`git`** | **2.13.1** | **2017-06** | **HIGH** — dziewięć lat i cała seria CVE od tego czasu (m.in. wykonanie kodu przez submoduły, obejścia ścieżek). `git clone` z niezaufanego źródła to realny wektor |
| `sdl1` | **1.2** | ~2012, **EOL** | **MEDIUM** — SDL 1.2 nie jest utrzymywane; SDL2/3 istnieje |
| `diffutils` | 3.6 | 2017 | LOW |
| `expat` | 2.5.0 | 2023 | **MEDIUM** — 2.6.x zamyka `CVE-2023-52425` i serię z 2024 |
| `bash` | 5.2.15 | 2023 | LOW |
| `openssh` | 9.8 | 2024 | LOW–MEDIUM |
| `netsurf` | 3.11 | 2023 | MEDIUM (parser na niezaufanych danych) |
| `openssl3` | **3.5.3** | aktualne | **dobrze** |
| `libpng` 1.6.46, `freetype2` 2.13.3, `zstd` 1.5.7, `xkeyboard-config` 2.44 | — | aktualne | dobrze |

Wzorzec: **biblioteki są świeże, programy użytkowe potrafią być bardzo stare.** To typowe przy
portowaniu — port `gita` raz zadziałał i nikt go nie ruszał — ale `git 2.13.1` w obrazie
systemu nazywającego się utwardzonym jest sprzecznością samą w sobie.

### 5.3 Rzeczy, które są zrobione dobrze i trzeba to powiedzieć

| Element | Stan | Dowód |
|---|---|---|
| **Hasła** | `argon2id`, `m=19456, t=2, p=1` | `/etc/shadow`: `root;$argon2id$v=19$m=19456,t=2,p=1$…` |
| **Puste hasło `user` jest wymuszane przy pierwszym logowaniu** | działa w obu ścieżkach | `login` zawiera *„Set a new password to continue"* i *„has no password"*; `orblogin` — *„First-boot setup / New password / Confirm password"* |
| **Weryfikacja rozruchu** | jądro i initfs weryfikowane **przed** użyciem bajtów | `eos-bootloader/src/main.rs:436-451`; brak podpisu → `panic`; zerowy klucz → `panic` |
| **Separacja domen w podpisie rozruchu** | ed25519 nad `SHA-512(role ‖ len_le ‖ data)` | `eos_boot_verify.rs:16-17, 72-81` — podpisany initfs nie zweryfikuje się jako jądro |
| **Klucz repozytorium przypięty w obrazie** | jest | `/etc/pkg/eos-repo-sign.pub.toml` obecny w obrazie |
| **Klucz pakietów przypięty w obrazie** | jest | `/etc/pkg/packages.toml` → `[pubkeys.local] pkey = "abf34ee5…"` |
| **Brak toolchainu i pakietu testowego w obrazie** | potwierdzone | 20 zbudowanych pakietów nie zainstalowano, w tym `gcc13`, `gnu-binutils`, `os-test-bins` |
| **Sterowniki w przestrzeni użytkownika** | architektura mikrojądra | `pcid`, `inputd`, `audiod`, `fbcond` jako procesy |
| **Odebranie schematu `ip` użytkownikowi** | zrobione świadomie | `login_schemes.toml`, `R-904a` |

---

## 6. Sterowniki — 16 sztuk, wszystkie w przestrzeni użytkownika

`/lib/drivers` i `/usr/lib/drivers` (identyczne):

```
ac97d  e1000d  ihdad  ihdgd  ixgbed  rtl8139d  rtl8168d  sb16d
usbctl  usbhidd  usbhubd  usbnetd  usbscsid  vboxd  virtio-netd  xhcid
```

Dźwięk (`ac97d`, `ihdad`, `sb16d`), sieć przewodowa (`e1000d`, `ixgbed`, `rtl8139d`, `rtl8168d`,
`virtio-netd`), USB (`xhcid`, `usbctl`, `usbhubd`, `usbhidd`, `usbnetd`, `usbscsid`), grafika
(`ihdgd`), wirtualizacja (`vboxd`).

**Czego nie ma:** Wi-Fi (żadnego), Bluetooth, NVMe, GPU poza Intelem (`ihdgd`), drukowania.
Sieć bezprzewodowa to dla systemu desktopowego brak odczuwalny natychmiast.

---

## 7. Czym E-OS **JEST** dzisiaj

> E-OS to **dystrybucja Redox OS** dla x86_64 i aarch64, dostarczająca 65 pakietów (536 MB)
> na mikrojądrze w Rust, z pulpitem graficznym Crimson (`orbital` + trzy aplikacje COSMIC +
> trzy aplikacje własne), przeglądarką NetSurf, powłokami `ion`/`bash`/`nushell`, kompletem
> narzędzi CLI, OpenSSH i OpenSSL 3.5.3, szesnastoma sterownikami w przestrzeni użytkownika
> i pełnym szyfrowaniem dysku AES-XTS oferowanym przy instalacji. Wyróżnia go wobec upstreamu
> **realnie działający łańcuch zaufania rozruchu** (bootloader weryfikuje jądro i initfs
> podpisem ed25519 z separacją domen, odmawiając startu przy braku podpisu), **przypięte
> w obrazie klucze** repozytorium i pakietów, **hybrydowy podpis indeksu** ed25519+ML-DSA-65
> egzekwowany na bajtach pakietów, hasła na `argon2id`, wymuszone ustawienie hasła przy
> pierwszym logowaniu oraz **lista dozwolonych schematów jądra per użytkownik** odbierająca
> nieuprzywilejowanemu użytkownikowi surowe gniazda IP. Jest to system **działający i spójny**,
> ale **bez aktywnego kanału aktualizacji na x86_64**, bez zapory, bez piaskownicy aplikacji,
> bez trwałego dziennika audytu i z kilkoma bardzo starymi programami użytkowymi na czele
> z `git 2.13.1`.

## 8. Czym E-OS **TWIERDZI, że jest** — i różnica

| Deklaracja (źródło) | Rzeczywistość | Różnica |
|---|---|---|
| „memory-safe **operating system written in Rust**" (`README:78`) | prawda dla jądra, sterowników, relibc i większości userlandu; ale w obrazie są też `openssl3`, `expat`, `freetype2`, `libpng`, `libjpeg`, `zstd`, `netsurf`, `git`, `vim` — **C** | **rozbieżność częściowa.** „Rust everywhere" jest hasłem, nie stanem: znaczna część powierzchni ataku (parsery obrazów, XML, HTML, TLS-owy OpenSSL) to C |
| „Capability-secure ... **Least-privilege by construction**" (`README`) | `login_schemes.toml` daje granicę **per użytkownik**, nie per aplikacja | **rozbieżność.** Least-privilege dotyczy kont, nie procesów. `netsurf` ma te same 25 schematów co powłoka |
| „`keys/eos-repo-sign.pub.toml` **does not exist yet** (`R-702`)" (`README:134`) | plik **istnieje** (4075 B, 28 sierpnia) i **jest wpięty w obraz** jako `/etc/pkg/eos-repo-sign.pub.toml` | **twierdzenie nieprawdziwe.** README jest 72 pozycje CHANGELOG-a w tyle (faza 0 §6.3) |
| „**eos-guard** (filesystem-integrity monitor) i **eos-sysmon** (system monitor), **both native Crimson apps**" (`README:141`) | **żadnego z nich nie ma w obrazie** — ani binarki, ani wpisu w launcherze. Funkcje scalono w `eos-control`, co dokumentuje komentarz w `config/x86_64/eos.toml` | **twierdzenie nieaktualne.** Produkt jest dobry, opis wymienia dwie aplikacje, które nie istnieją jako osobne |
| „**USB RNDIS** network driver (`usbnetd`; full duplex, pcap-verified)" | `usbnetd` **jest** w `/usr/lib/drivers` | **zgodne** |
| „**RAID-1 mirroring** — userspace `raid1d`" | `raid1d` **jest** w obrazie | **zgodne** |
| „**Full-disk encryption** ... RedoxFS AES-XTS ... **ARMv8 Crypto Extensions**" | AES-XTS potwierdzone w `redoxfs`, `redoxfs-mkfs` i `redox_installer_tui`; przyspieszenie ARMv8 dotyczy **tylko aarch64** | **zgodne, ale sformułowane mylnie** — na x86_64 to ścieżka programowa |
| „**Graphical OOBE** — first-boot password enrolment" | `orblogin` zawiera „First-boot setup / New password / Confirm password"; `login` — „Set a new password to continue" | **zgodne** |
| „**NetSurf built from source as a PIE** — real web browsing" | `netsurf-fb` 3.11 w obrazie | **zgodne** |
| `eos-welcome`: „Apps: Files, Text Editor, Terminal (**COSMIC apps**)" | `cosmic-files`, `cosmic-edit`, `cosmic-term` — obecne | **zgodne** |
| `eos-welcome`: „Full-disk encryption (AES-XTS) is offered at install — **recommended**" | oferowane, potwierdzone w binarce instalatora | **zgodne** |
| `/etc/os-release`: `VERSION_ID="0.1.0"`, `PRETTY_NAME="E-OS 0.1.0 (Genesis)"` | ostatni tag to **`v0.2.0`** (podpisany, 22 sierpnia); README ma badge „0.2.0 dev"; `Cargo.toml` — `0.1.0` | **rozbieżność wersji w czterech miejscach naraz.** System raportuje inną wersję, niż wydano |
| `/etc/os-release` wskazuje `github.com/Gh0s777tt/E-OS` | źródłem prawdy jest **GitLab** (`ADR-0001`) | **rozbieżność** — obraz kieruje użytkownika na lustro |

### 8.1 Podsumowanie różnicy w jednym zdaniu

**Produkt jest lepszy, niż wynikałoby z jego najsłabszych deklaracji, i słabszy, niż wynikałoby
z najmocniejszych.** Łańcuch rozruchu, przypięte klucze i podpis indeksu są realne i działają —
a README twierdzi, że klucza nie ma. Jednocześnie „capability-secure, least-privilege by
construction" opisuje granicę, która w praktyce biegnie po koncie użytkownika, a nie po aplikacji,
i której nie wspiera żadna piaskownica.

---

## 9. Czego brakuje najbardziej — kolejność wg wagi

| # | Brak | Waga | Dlaczego to boli akurat tutaj |
|---|---|---|---|
| 1 | **Aktywny kanał aktualizacji na x86_64** | **HIGH** | System z `git 2.13.1` i `expat 2.5.0` nie ma jak dostać poprawki. Cała warstwa podpisów jest gotowa i nieużywana |
| 2 | **Piaskownica aplikacji** | **HIGH** | Przeglądarka na niezaufanych danych ma pełne uprawnienia konta. To największa dysproporcja między obietnicą „least-privilege" a stanem |
| 3 | **Trwały dziennik audytu** | **HIGH** | Po incydencie nie ma czego czytać. Jest `dmesg` i schemat `log`, nie ma demona ani rotacji |
| 4 | **Zapora / filtrowanie pakietów** | **HIGH** | W obrazie jest `sshd` i pełen stos sieciowy, bez żadnej kontroli portów |
| 5 | **Wi-Fi** | MEDIUM | Dla systemu desktopowego brak odczuwalny od pierwszej minuty |
| 6 | **Kopie zapasowe** | MEDIUM | Jest `tar` i `redoxfs-clone`; nie ma narzędzia ani harmonogramu |
| 7 | **VPN / Tor** | MEDIUM | Nie jest obiecywane — staje się luką dopiero przy pozycjonowaniu obok Tails/Whonix |
| 8 | **Antywirus** | LOW | Przy braku ekosystemu binarek osób trzecich monitor integralności w `eos-control` jest właściwszą odpowiedzią |
