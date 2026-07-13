<!-- E-OS feature proposals — roadmap audit, 2026-07-13. Language: Polish (owner's working language). -->

# Propozycje funkcji E-OS (poza jawnymi żądaniami)

14 funkcji dobranych pod bezpieczny, telemetryczno-wolny pulpit Crimson, wykorzystujących to, co E-OS **już ma** w kodzie: `raid1d`, RedoxFS AES-XTS FDE, hybrydowe podpisy PQ (`tools/eos-repo-sign`), izolację mikrojądra, schematy-jako-capability (`/scheme/*`), `pcid`/`hwd` i zweryfikowany łańcuch `pkgar` ed25519+blake3. Uporządkowane tak, by **kumulować** trzy flagowce (installer / update / driver-manager).

---

## Filar wspólny (odblokowuje flagowce — zrób najpierw)

### 1. `eos-devd` — demon inwentaryzacji sprzętu (`/scheme/devices`)
- **Co robi:** Ujednolica trzy istniejące, rozjechane źródła (`pcid` → `/scheme/pci`, porty USB z `xhcid`, enumeracja platform/ACPI/DT z `hwd`) w jeden czytelny, lspci/lsusb-podobny inwentarz: vendor/device/class + `bound-driver` + flaga `bound?`. Wykorzystuje gotowe API `PciFunctionHandle.config().func.full_device_id`.
- **Dlaczego pasuje do E-OS:** To **strona odczytu** Driver-Managera i Security Dashboardu naraz. `hwd` już rozpoznaje `PNP0C0A` (bateria) i `PNP0C50` (I2C-HID) po nazwie — potrafimy więc pokazać „urządzenie wykryte, brak sterownika", co samo w sobie jest anty-scamowym UX (użytkownik nie szuka fałszywego sterownika w sieci).
- **Effort:** M · **Zależność:** `pcid`, `xhcid`, `hwd` (wszystko w drzewie) · **QEMU teraz:** TAK (aarch64/TCG).

### 2. Natywna aplikacja `E-OS Settings` (orbital/orbclient, bez libcosmic)
- **Co robi:** Panel-host (Update, Drivers, Display, Network, Audio, Users, Date&Time, Security) zbudowany na orbital/orbclient — **bez** zależności fontconfig→`host:gperf`, która blokuje `cosmic-settings` na hoście Apple Silicon (404 redoxer host-toolchain).
- **Dlaczego pasuje do E-OS:** Flagowe „Settings → Update" i „Driver Manager" **nie mają dziś gdzie mieszkać** — na obu architekturach brak jakiegokolwiek panelu ustawień. Launcher (`launcher/src/package.rs:179`) już odkrywa apki przez wpisy `.desktop`, więc integracja to jeden plik `.desktop`. Omija zablokowany host-toolchain **i** martwe GitHub Actions (buduje się natywnie na aarch64).
- **Effort:** L · **Zależność:** orbital, `eos-orbutils` (fork w drzewie) · **QEMU teraz:** TAK.
- **Kolejność:** wszystkie flagowe panele (Update/Driver) zależą od tego shellu — to twarda zależność, nie równoległa.

---

## Bezpieczeństwo i zaufanie (rdzeń tożsamości Crimson)

### 3. Security Dashboard (`Settings → Security`)
- **Co robi:** Jeden ekran statusu realnego, zweryfikowanego hartowania: FDE aktywne (AES-XTS), W⊕X + mmap ASLR + overflow-checks (R-306), stan RAID-1 (`raid1d` degraded/healthy), status podpisu repo, data ostatniej weryfikacji manifestu, ostrzeżenie o domyślnych poświadczeniach. Zielone/czerwone kafle #E50914.
- **Dlaczego pasuje do E-OS:** E-OS ma nietypowo mocny, **realnie zweryfikowany** fundament bezpieczeństwa, którego użytkownik nigdzie nie widzi. Dashboard zamienia audytowalne fakty (nie telemetrię) w widoczną wartość i wyłapuje regresje (np. FDE off, mirror zdegradowany).
- **Effort:** M · **Zależność:** #1, #2 · **QEMU teraz:** TAK.

### 4. Weryfikator zaufania podpisanych sterowników (UI + wymuszony łańcuch)
- **Co robi:** W Driver-Managerze każdy sterownik pokazuje: źródło = **wyłącznie** podpisane repo E-OS, weryfikacja blake3+ed25519 (+ML-DSA-65 doradczo wg R-503), uruchomienie pod W⊕X/ASLR. Instalacja spoza repo jest niemożliwa konstrukcyjnie.
- **Dlaczego pasuje do E-OS:** To **jawnie sformułowana** wygrana bezpieczeństwa: kasuje całą windowsową klasę ataku „poluj na sterownik / fałszywy instalator". Napastnik potrzebowałby off-repo klucza prywatnego, nie przekonującej strony.
- **Effort:** M · **Zależność:** #1, katalog sterowników (poniżej), `eos-repo-sign` · **QEMU teraz:** TAK (logika); realny bind — real-HW.
- **UWAGA hartująca:** dziś `match_function` parsuje klucze katalogu przez `i64::from_str_radix(...).unwrap()` — wrogi/uszkodzony wpis **panikuje `pcid-spawner` i psuje CAŁE bindowanie przy boocie**. Zanim katalog stanie się pobieralnym plikiem, trzeba zamienić `unwrap()` na skip-on-error.

### 5. Menedżer uprawnień/capability aplikacji
- **Co robi:** UI listujące, które schematy (`/scheme/*` = capability w Redox) dana aplikacja może otworzyć (net, disk, input, display), z możliwością odbierania. Mikrojądrowa izolacja Redoxa czyni to egzekwowalnym na poziomie jądra, nie kosmetycznym.
- **Dlaczego pasuje do E-OS:** Model schematów-jako-capability to natywna przewaga mikrojądra — żaden monolit tego nie daje tanio. Telemetryczno-wolny pulpit powinien dać użytkownikowi widoczną kontrolę nad tym, co apka „widzi".
- **Effort:** L · **Zależność:** rozszerzenia schematów jądra/relibc · **QEMU teraz:** częściowo (odczyt tak; egzekwowanie odbierania — M pracy w jądrze).

### 6. Wymuszenie poświadczeń w kreatorze (naprawa krytycznej luki)
- **Co robi:** Firstboot/OOBE **wymusza** zmianę hasła głównego użytkownika, wygasza domyślne `root/password`, generuje `machine-id` + klucze host SSH.
- **Dlaczego pasuje do E-OS:** Każdy zbudowany obraz startuje dziś jako `user` (bez hasła) + `root/password` (`eos.aarch64.toml:82,106`) — po odblokowaniu FDE to pełny dostęp roota. To **żywa** luka, nie hipotetyczna; dokumentacja wręcz każe „naprawić ręcznie".
- **Effort:** S–M · **Zależność:** OOBE (flagowiec instalatora) · **QEMU teraz:** TAK.

---

## Odporność i odzyskiwanie (kumuluje update + storage)

### 7. Snapshot + rollback systemu (RedoxFS/`raid1d`-backed)
- **Co robi:** Przed każdym `pkg update`/apply robi snapshot zamienianych plików + `package.toml`; `eos-update rollback` wraca do poprzedniego stanu. Dziennik commitu, by crash w połowie `rename`-loop dało się wznowić/cofnąć.
- **Dlaczego pasuje do E-OS:** Dziś `transaction.commit()` mutuje żywy FS pętlą `rename` **bez trwałego dziennika** — utrata zasilania zostawia stan pół-zaaplikowany, a „restartowalność" żyje tylko w pamięci procesu. To bezpośrednio hartuje flagowy update-system dla realnych dysków.
- **Effort:** L (snapshot plikowy) → XL (A/B sloty) · **Zależność:** update-daemon, RedoxFS · **QEMU teraz:** TAK.

### 8. Recovery / tryb ratunkowy (drugie menu bootloadera)
- **Co robi:** Wpis bootloadera „E-OS Recovery": minimalne środowisko z `pkg`, weryfikatorem FDE, `raid1d` assemble/rebuild i „apply-on-reboot" dla nieudanego update jądra/base.
- **Dlaczego pasuje do E-OS:** Update jądra/base/relibc idzie dziś przez **in-place replace żywego systemu** — zły kernel może zabrickować realną instalację bez drogi powrotu. `raid1d` już wspiera degraded-boot; recovery to naturalny host dla resync/rebuild.
- **Effort:** L · **Zależność:** `eos-bootloader` (fork w drzewie), `raid1d` · **QEMU teraz:** TAK.

### 9. Rozbudowa `eos health` / „doctor"
- **Co robi:** Jedna komenda + kafel w Settings: sanity-check FDE, spójność `raid1d` (i **scrub per-blok** — dziś `raid1d` nie ma sum kontrolnych per-blok, nie wykryje bit-rot ani który mirror jest autorytatywny), świeżość repo, martwe wpisy katalogu sterowników (patrz niżej), luki numeracji.
- **Dlaczego pasuje do E-OS:** Diagnostyka lokalna, bez telemetrii, wpisuje się w ethos. Wyłapie realne, **obecne** defekty: `ac97d.toml`/`vboxd.toml` w `/usr/lib/pcid.d/` wskazują na binaria, których nie ma w drzewie → urządzenie matchuje, `Command::new` faila, sprzęt zostaje niezbindowany.
- **Effort:** M · **Zależność:** #1 · **QEMU teraz:** TAK.

---

## Dostawa i weryfikowalność (odblokowuje update/driver mimo martwych Actions)

### 10. Offline bundle sterowników wbudowany w ISO instalatora
- **Co robi:** Podpisany `pkgar` katalog + zestaw sterowników na nośniku instalacyjnym, wygenerowany z istniejących `/usr/lib/pcid.d/*.toml` + `xhcid/drivers.toml`, tak by day-one pokrycie = pokrycie z obrazu — bez sieci przy instalacji.
- **Dlaczego pasuje do E-OS:** Ścieżka instalatora **już przypina klucz** (`installer_key`, `pubkey:Some`), więc offline-bundle jest weryfikowalny natywnie. Omija zablokowane GitHub Pages/Actions (R-1003) — sterowniki dostajesz bez działającego backendu repo.
- **Effort:** M · **Zależność:** rozbicie sterowników na per-driver `pkgar` (poniżej) · **QEMU teraz:** TAK.

### 11. Podpisany katalog sprzęt→sterownik (versioned device-ID map)
- **Co robi:** Wersjonowana mapa `device-ID → driver-package+wersja+arch` jako własny `pkgar`, podpisana kluczem hybrydowym R-503, pobierana+weryfikowana+cache'owana lokalnie. Zasiew z obecnych TOML-i.
- **Dlaczego pasuje do E-OS:** To brakujące „źródło prawdy" dla Driver-Managera. Musi pogodzić **trzy** katalogi (`initfs.toml` + `usr/lib/pcid.d/*` + `xhcid/drivers.toml`) — bez tego update sterownika = podmiana całego monolitycznego `base.pkgar`.
- **Effort:** M (katalog) + L (rozbicie base na `drv-*`) · **Zależność:** #4 hartowanie parsera, `eos-repo-sign` · **QEMU teraz:** TAK.

### 12. Reproducible-build verifier dla użytkownika
- **Co robi:** Lokalne narzędzie: użytkownik przelicza sumy swojego obrazu i porównuje z podpisanym (ML-DSA+ed25519) manifestem — bez zaufania do serwera.
- **Dlaczego pasuje do E-OS:** Naprawia realny defekt: `release/SHA256SUMS` wskazuje **nieistniejące** `eos-0.1.0-<arch>.img` (faktyczny artefakt to `build/<arch>/eos/harddrive.img`, inna treść/data), a instrukcje `install.md` każą `sha256sum -c` pliku, którego nie ma. Verifier musi liczyć sumy nad **rzeczywistym** artefaktem. Wpisuje się w telemetryczno-wolne, „ufaj-ale-sprawdź".
- **Effort:** S · **Zależność:** lokalny `make release` (nie-Actions) · **QEMU teraz:** TAK (to host-side).

---

## Pulpit i telemetryczno-wolny ethos

### 13. Lokalny crash-reporter (nigdy nie wychodzi z maszyny)
- **Co robi:** Łapie panic/data-abort (np. dzisiejszy `netsurf` ET_EXEC, ESR 0x92000047; osierocone okno SDL), zapisuje lokalnie z kontekstem, pokazuje w Settings → Security. **Zero** wysyłki sieciowej — użytkownik sam decyduje o eksporcie.
- **Dlaczego pasuje do E-OS:** Telemetryczno-wolny pulpit nie może „dzwonić do domu", ale i tak potrzebuje diagnostyki. Lokalny reporter to jedyna spójna z ethosem droga; od razu ma realny materiał (netsurf, `virtio-rngd` deadlock).
- **Effort:** M · **Zależność:** hak panic w relibc/jądrze · **QEMU teraz:** TAK.

### 14. Funkcjonalny system tray + host-firewall UI
- **Co robi:** Zamienia trzy **dekoracyjne** PNG (net/vol/settings — dziś bez handlerów) w żywe: stan sieci z netstack, popup głośności przez `audiod`, koło zębate uruchamia `E-OS Settings`. Dokłada prosty panel host-firewall nad schematami `ip/udp/tcp/raw`.
- **Dlaczego pasuje do E-OS:** Ikony wyglądają na klikalne, a milczą — psuje wrażenie daily-drivera. Dodatkowo: netstack eksponuje **surowy schemat `raw`** bez żadnej warstwy filtrowania ingress/egress — dla projektu „hardened, security-first" brak host-firewalla to realna luka postawy bezpieczeństwa, nie tylko brak funkcji.
- **Effort:** M (tray) + L (firewall) · **Zależność:** #2, netstack · **QEMU teraz:** TAK (tray); firewall — częściowo (bez NIC w domyślnym boocie aarch64 `virt`).

---

## Kolejność wdrażania (twarde zależności)

1. **#1 `eos-devd`** i **#2 `E-OS Settings`** — fundament; bez nich Driver/Update/Security/Permissions nie mają gdzie żyć.
2. **#6 wymuszenie poświadczeń** i **#4 hartowanie parsera katalogu** — żywe luki krytyczne, tanie, rób równolegle.
3. **#11 katalog + rozbicie `drv-*`** → **#10 offline bundle** → **#4 UI zaufania sterowników** (Driver-Manager gotowy).
4. **#7 snapshot/rollback** + **#8 recovery** → hartują flagowy update-system dla realnych dysków.
5. **#3 Security Dashboard**, **#9 doctor**, **#13 crash-reporter**, **#14 tray/firewall** — nadbudowa spinająca całość w widoczną, audytowalną wartość Crimson.

**Realizm QEMU:** 12 z 14 w pełni robialnych **teraz** na aarch64/TCG (host Apple Silicon). Egzekwowanie odbierania capability (#5) i realny bind sterowników (#4) mają część wymagającą real-HW rig. Żadna z propozycji nie zależy od martwych GitHub Actions — #10 i #12 wręcz je omijają.