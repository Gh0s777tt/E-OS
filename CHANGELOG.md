# Changelog

All notable changes to E-OS. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

**How this file was rebuilt.** Reconstructed on 2026-08-30 from `git log`, the three annotated
tags, and the one published release. Each entry names the commit that introduced it, so any line
can be checked. Entries were assigned to a release by finding the commit that first added them and
testing which tag range it falls in — not by guessing from dates.

**Releases.** There is exactly one published release object, [`v0.1.0`](https://github.com/Gh0s777tt/E-OS/releases/tag/v0.1.0).
`v0.2.0` is an annotated, signed tag with **no** release object; `eos-base-2026-06-06` is an
unsigned pre-history marker. Tag list: <https://github.com/Gh0s777tt/E-OS/tags>.

---

## [Unreleased]

Work since `v0.2.0` (2026-08-22): 78 commits.

### Added

- **U-161** — R-601` drives the installer end to end for the first time ([`d022574c6`](https://gitlab.com/e-os/e-os/-/commit/d022574c6), `test(install): drive the installer end to end; find R-F19 (U-161)`)
- **U-169** — x86_64 zbudowany i zbootowany po raz pierwszy; typ repozytorium przestał być zdaniem w dokumencie, a stał się polem, które CI egzekwuje ([`dbee16183`](https://gitlab.com/e-os/e-os/-/commit/dbee16183), `feat(gates): enforce repo type from the manifest; first x86_64 build + boot (U-1`)
- **U-176** — R-601` UDOWODNIONE ([`8bd2c79d6`](https://gitlab.com/e-os/e-os/-/commit/8bd2c79d6), `feat(R-601): partition -> install -> reboot -> login is PROVEN (U-176)`)
- **U-198** — Pierwsze podpisane repozytorium istnieje i weryfikuje się ([`a4669ff7c`](https://gitlab.com/e-os/e-os/-/commit/a4669ff7c), `feat(R-008): first signed repository, verified both ways -- and a name collision`)
- **U-199** — R-701` przygotowane, ale świadomie NIEAKTYWNE ([`3b4c2e5a4`](https://gitlab.com/e-os/e-os/-/commit/3b4c2e5a4), `feat(R-701): the E-OS package source, shipped inert because it would point at a `)
- **U-208** — Cały łańcuch pod Secure Boot ([`50bd29522`](https://gitlab.com/e-os/e-os/-/commit/50bd29522), `feat(secureboot): the installed system boots under Secure Boot too -- full chain`)
- **U-209** — R-008` zrobione (pierwsza podpisana publikacja żyje), i naprawa dwóch rzeczy z sesji operatora ([`92f09fdc9`](https://gitlab.com/e-os/e-os/-/commit/92f09fdc9), `feat(build): R-008 published + a build path that works on this exFAT host (U-209`)
- **U-210** — R-701` wpięte ([`cf2e63e89`](https://gitlab.com/e-os/e-os/-/commit/cf2e63e89), `feat(R-701): wire the aarch64 image to the published signed repo; teach the gate`)
- **U-211** — Audyt wobec `rhboot/shim-review`, triage norm i SCALENIE `ROADMAP.md` do `ROADMAP-v2.md ([`a38061843`](https://gitlab.com/e-os/e-os/-/commit/a38061843), `feat(boot): verify kernel and initfs by signature; shim-review audit; merge road`)
- **U-212** — V2-MS02 ([`a38061843`](https://gitlab.com/e-os/e-os/-/commit/a38061843), `feat(boot): verify kernel and initfs by signature; shim-review audit; merge road`)
- **U-220** — Pomiar POSIX-a (`V2-STD01`) ([`f3eb2dfd9`](https://gitlab.com/e-os/e-os/-/commit/f3eb2dfd9), `test(posix): unblock the POSIX suite and record a tenth hang upstream does not l`)
- **U-221** — V2-STD01 ([`ca18ca4bd`](https://gitlab.com/e-os/e-os/-/commit/ca18ca4bd), `test(posix): the first POSIX numbers this project has ever had, and three hangs `)
- **U-222** — V2-STD01` DOMKNIĘTE ([`308cd2402`](https://gitlab.com/e-os/e-os/-/commit/308cd2402), `test(posix): full POSIX.1-2024 result, 4267/5650, and a correction to the partia`)
- **U-228** — `R-611b`: `scripts/make-release.sh` pakuje nośnik instalacyjny obok `harddrive.img`, jego sha256 idzie do tego samego `SHA256SUMS`, więc obejmuje go podpis minisign. Do dziś pętla brała wyłącznie `harddrive.img`, a brak nośnika był **ciszą**, nie błędem. Nazwa pochodzi z `mk/config.mk` przez `make print-installer-medium`, żeby wzorzec miał jeden dom. Po drodze zmierzone i zamknięte dwie dalsze usterki: ścieżka `build/$arch/eos/` była zaszyta na sztywno, a `.config` ustawia `CONFIG_NAME` przez `?=`, więc `CONFIG_NAME=desktop` zmieszałby dwie konfiguracje w jednym `SHA256SUMS`; oraz `VERSION` domyślnie `0.1.0`, gdy build stempluje `EOS_VERSION=0.2.0` w nazwę nośnika — teraz domyślnie `make print-eos-version`, a niezgodność jest odmową, nie przemianowaniem. Testy: `scripts/eos-test-make-release.sh`, 7 przypadków (4 odmowy), wpięte do `verify.sh` jako etap `release-pack` (15 → **16 etapów**). Kontrola przeciwna na kodzie sprzed zmiany: **5 padło, 2 przeszły**. Mutacja obnażyła wadę w samym teście — po usunięciu kontroli istnienia nośnika 7/7 nadal przechodziło, bo test mierzył awarię `cp`, nie moją bramkę; po zaostrzeniu asercji ta sama mutacja zabija dokładnie jeden, właściwy test ([`97982bdef`](https://gitlab.com/e-os/e-os/-/commit/97982bdef), `feat(R-611b): make-release.sh pakuje nośnik instalacyjny obok obrazu dysku`)
- **U-230** — `R-611c`: nośnik instalacyjny wiezie `EFI/EOS/eos-secureboot.der` i `EFI/EOS/README.txt`. E-OS podpisuje własny bootloader **własnym** kluczem, więc na obcym pececie z Secure Bootem potrzebny jest jeden krok właściciela — wgranie certyfikatu do firmware. Trzymanie go gdzie indziej zawodzi dokładnie wtedy, gdy jest potrzebny: człowiek stoi przed menu firmware z pendrivem i maszyną, która nie startuje. Format **DER**, bo taki przyjmują menu UEFI. Offset ESP **odczytywany z GPT**, nie zakładany na 1 MiB (`R-609` planuje przepartycjonowanie). Jeden skrypt `scripts/eos-esp-add-cert.sh`, wołany przez `eos-build.sh` **i** oba zadania `build-image` — nie dwie kopie. Kontrola wymagana przez zadanie działa **wewnątrz** skryptu, na plikach wyjętych z ESP: certyfikat weryfikuje `BOOTX64.EFI` (x86_64) i `BOOTAA64.EFI` (aarch64), a świeżo wygenerowany obcy certyfikat jest **odmawiany**. Mutacja: podanie obcego certyfikatu jako wysyłanego → `FAIL -- the shipped certificate does NOT verify the shipped bootloader`, kod 1. Zmierzone: 813 B + 1535 B, 788 480 B wolne na 1 MiB ESP ([`148474bed`](https://gitlab.com/e-os/e-os/-/commit/148474bed), `feat(R-611c): nośnik wiezie certyfikat Secure Boot i instrukcję jego wgrania`)

### Changed

- **U-154** — R-F18` located to the second: an 84-second stall inside USB HID bring-up ([`881c23330`](https://gitlab.com/e-os/e-os/-/commit/881c23330), `docs(R-F18): locate the 84-second USB HID stall by wall clock (U-154)`)
- **U-155** — R-F18` measured to the root: a shared-INTx interrupt storm, and my `U-154` hypothesis was wrong ([`3449d8e80`](https://gitlab.com/e-os/e-os/-/commit/3449d8e80), `docs(R-F18): measure the shared-INTx storm; my USB hypothesis was wrong (U-155)`)
- **U-157** — R-F18`: the storming line identified by counter, and a kernel fix I wrote, tested and then reverted because it did nothing ([`c0249e9fa`](https://gitlab.com/e-os/e-os/-/commit/c0249e9fa), `docs(R-F18): count the storming line; revert a kernel fix that did nothing (U-15`)
- **U-159** — R-F14` and `R-F15` closed ([`cccead168`](https://gitlab.com/e-os/e-os/-/commit/cccead168), `ci(lint): gate shell scripts and the root manifest (U-159, R-F14, R-F15)`)
- **U-160** — CLAUDE.md gains the testing, auditing and record-keeping discipline this session kept learning the hard way ([`71b99feb7`](https://gitlab.com/e-os/e-os/-/commit/71b99feb7), `docs(claude): add the testing, auditing and record-keeping discipline (U-160)`)
- **U-162** — R-F19` halved: the filesystem is created, the failure is in populating it ([`b42730a0c`](https://gitlab.com/e-os/e-os/-/commit/b42730a0c), `docs(R-F19): the filesystem is created; the failure is in populating it (U-162)`)
- **U-163** — R-F20`: seven core recipes ship as UPSTREAM prebuilt binaries, not from the pinned forks ([`e0178636b`](https://gitlab.com/e-os/e-os/-/commit/e0178636b), `docs(R-F20): seven core recipes ship as upstream binaries, not the pinned forks `)
- **U-164** — R-F20` has teeth: the client-side manifest signature verification is NOT in the image ([`795be5c22`](https://gitlab.com/e-os/e-os/-/commit/795be5c22), `docs(R-F20): the client-side manifest verification is not in the image (U-164)`)
- **U-166** — R-F19` root-caused: the install completes and then `unmount_path` fails ([`e131f6adb`](https://gitlab.com/e-os/e-os/-/commit/e131f6adb), `docs(R-F19): the install completes; unmount_path is what fails (U-166)`)
- **U-167** — CLAUDE.md` przepisany po polsku, rozszerzony o typy repozytoriów i cele docelowe ([`8e39f4068`](https://gitlab.com/e-os/e-os/-/commit/8e39f4068), `docs(claude): rewrite CLAUDE.md in Polish; add repo types and target state (U-16`)
- **U-168** — braki z listy TODO domknięte: `cookbook.lock` śledzony, bramka pokrycia, SBOM, rustdoc, ADR-y i diagramy ([`b373e8cca`](https://gitlab.com/e-os/e-os/-/commit/b373e8cca), `ci(gates): track cookbook.lock, gate coverage, add SBOM/rustdoc/ADRs (U-168)`)
- **U-173** — końce linii przestały być nawykiem edytora, a stały się polityką w `.gitattributes`; po drodze dwa moje wejściowe założenia okazały się fałszywe ([`3eb3590ac`](https://gitlab.com/e-os/e-os/-/commit/3eb3590ac), `ci(gates): pin line endings with .gitattributes; gate them as check 8 (U-173)`)
- **U-177** — kontrola 7 wypisywała „typy się nie zgadzają" na KAŻDY niezerowy kod wyjścia ([`026387523`](https://gitlab.com/e-os/e-os/-/commit/026387523), `docs(gates): record U-177 -- check 7 tells "the instrument did not run" from "br`)
- **U-178** — domknięcie `U-173`: trzy rzeczy zapisane tam jako niezweryfikowane są zmierzone, a przegląd ekosystemu pokazał, gdzie ta sama pułapka czeka ([`cad953dd8`](https://gitlab.com/e-os/e-os/-/commit/cad953dd8), `docs(U-173): close the three unverified claims and record the ecosystem survey (`)
- **U-182** — R-F19` domknięte ([`b378df96a`](https://gitlab.com/e-os/e-os/-/commit/b378df96a), `docs(roadmap): close R-F19 -- the entry had been contradicting itself (U-182)`)
- **U-183** — R-701a` zweryfikowane w obrazie i zamienione w bramkę ([`9b78e3b06`](https://gitlab.com/e-os/e-os/-/commit/9b78e3b06), `ci(gates): keep the upstream package source disabled -- check 9 (U-183)`)
- **U-186** — Audyt wszystkich drzew: 80 nieaktualnych migawek, zero utraconej pracy, i reguły w `CLAUDE.md` §20, żeby to się nie powtarzało ([`1522bf6bf`](https://gitlab.com/e-os/e-os/-/commit/1522bf6bf), `docs(hygiene): audit every tree, archive 80 stale snapshots, add CLAUDE.md 20 (U`)
- **U-190** — docs/tokeny.md ([`1a8abddb8`](https://gitlab.com/e-os/e-os/-/commit/1a8abddb8), `docs: one place for every token, starting with the one that needs none (U-190)`)
- **U-201** — Audyt 143 twierdzeń o stanie projektu: 75 prawdziwych, 34 częściowo, 32 fałszywe ([`a7945205e`](https://gitlab.com/e-os/e-os/-/commit/a7945205e), `docs(audit): 143 claims checked -- 32 false; two hardware blockers were on no li`)
- **U-202** — docs/plan-do-sprzetu.md ([`c0abcc1c6`](https://gitlab.com/e-os/e-os/-/commit/c0abcc1c6), `docs(plan): the road from QEMU to a physical PC, ordered by what unblocks what (`)
- **U-203** — ROADMAP-v2.md` + strona ([`b0b6805fa`](https://gitlab.com/e-os/e-os/-/commit/b0b6805fa), `docs(roadmap): ROADMAP-v2 -- second-generation plan grounded in measurement (U-2`)
- **U-204** — ROADMAP-v2` rozszerzone o rdzeń samego systemu E-OS ([`a3af5c2a6`](https://gitlab.com/e-os/e-os/-/commit/a3af5c2a6), `docs(roadmap): extend ROADMAP-v2 with the E-OS system core itself (U-204)`)
- **U-214** — Porządki na dysku ([`1dd003b6e`](https://gitlab.com/e-os/e-os/-/commit/1dd003b6e), `chore(disk): reclaim 121 GB, and record the cleanup rule the measurement forced `)
- **U-223** — V2-MS13`/`V2-MS14`/`V2-MS15 ([`990247ca5`](https://gitlab.com/e-os/e-os/-/commit/990247ca5), `docs: record U-223 -- V2-MS13/14/15 landed, and the frozen-serial defect found w`)
- **U-225** — Testowanie wielostopniowe i pokrycie mierzone na bieżąco wpisane do kontraktu: `CLAUDE.md` §5.9 (osiem poziomów, z tabelą sześciu przypadków z tej sesji, gdzie jeden kierunek testowania świecił na zielono przy zepsutej rzeczy) i §5.10 (pokrycie przy każdym przebiegu `verify.sh`, podłoga 38 % na kodzie własnym, doradczo na vendorowanym); §6 rozszerzone o cztery pozycje kontrolne ([`fdb1ad91b`](https://gitlab.com/e-os/e-os/-/commit/fdb1ad91b), `docs(claude): testowanie wielostopniowe i pokrycie mierzone na bieżąco`)
- **U-227** — `ROADMAP.md` i `ROADMAP-v2.md` scalone w **jedną** roadmapę po angielsku, 1861 linii: jeden rejestr przedmiotowy jako źródło statusu, widok czasowy wyprowadzony z niego, jedna legenda zamiast trzech alfabetów. 236 z 237 identyfikatorów obecnych (brakujący `V2-Nx` to wzorzec rodziny); kolizje `R-70x`/`R-80x` rozstrzygnięte w Aneksie B, wycofane identyfikatory wypisane w Aneksie C z powodem. `ROADMAP-v2.md` zastąpiony wskaźnikiem — **nie skasowany**, pełny tekst pod `git show 87e8194b1:ROADMAP-v2.md` (zweryfikowane: 122 262 bajty, zgodne z Aneksem C.2) ([`85acaffef`](https://gitlab.com/e-os/e-os/-/commit/85acaffef), `docs(roadmap): scal ROADMAP i ROADMAP-v2 w jedną roadmapę po angielsku`)

### Fixed

- **`verify.sh` uruchamia teraz `coverage` i `cargo-deny`** — oba etapy od dawna meldowały `SKIPPED — not installed`, choć narzędzia **były zainstalowane**. `cargo` pochodzi z homebrew i nie dodaje `~/.cargo/bin` do `PATH`, czyli dokładnie katalogu, w którym `cargo install` je umieszcza. Zmierzone po poprawce: `coverage` 4 s i `cargo-deny` 3 s zamiast `0s SKIPPED`, `16 PASS · 0 SKIPPED`.
- **U-153** — R-F16` root-caused and fixed ([`1662771aa`](https://gitlab.com/e-os/e-os/-/commit/1662771aa), `fix(gic): root-cause R-F16 -- a read-modify-write on a W1C register (U-153)`)
- **U-156** — R-F10` closed: the bootloader now unlocks the filesystem it was actually built against ([`5709a5921`](https://gitlab.com/e-os/e-os/-/commit/5709a5921), `fix(tcb): the bootloader now unlocks the filesystem it was built against (U-156,`)
- **U-158** — eos-setup-mirrors.sh` would have destroyed the published package repos, and could not be audited without a credential ([`ba254d21d`](https://gitlab.com/e-os/e-os/-/commit/ba254d21d), `fix(mirrors): stop --apply from overwriting the published package repos (U-158)`)
- **U-165** — R-F20` fixed: every E-OS-forked recipe is built from its fork again, and `R-703`'s client half is back in the image ([`6067b8e47`](https://gitlab.com/e-os/e-os/-/commit/6067b8e47), `fix(build): build E-OS forks from source again; R-703's client half is back (U-1`)
- **U-170** — R-F19` rozwiązane ([`034ac22ce`](https://gitlab.com/e-os/e-os/-/commit/034ac22ce), `fix(R-F19): root-cause and fix the unmount EPERM; unmask the real install failur`)
- **U-171** — R-F19` odsłoniło łańcuch: instalacja przeszła z „0 plików" do „13 679 i kopiuje"; po drodze trzy nowe usterki i jedno moje błędne twierdzenie ([`def3c8134`](https://gitlab.com/e-os/e-os/-/commit/def3c8134), `fix(R-F21,R-F22): install now runs; record R-F23 and correct my own speed claim `)
- **U-172** — dlaczego `R-601` nie da się dziś udowodnić: to koszt, nie usterka ([`60def9e37`](https://gitlab.com/e-os/e-os/-/commit/60def9e37), `fix(harness): stop the driver burning a core after the VM dies; record R-F24 (U-`)
- **U-174** — .gitlab-ci.yml` był niepoprawny od `U-168` i każdy pipeline od 2026-08-27 14:47 tworzył ZERO zadań ([`69e7401e9`](https://gitlab.com/e-os/e-os/-/commit/69e7401e9), `fix(ci): quote script items so .gitlab-ci.yml parses; pipelines create jobs agai`)
- **U-175** — zadanie `integrity` w CI nie instalowało `python3`, więc kontrola 7 nie mogła się wykonać ([`d2bbdfbb6`](https://gitlab.com/e-os/e-os/-/commit/d2bbdfbb6), `fix(ci): install python3 in the integrity job so check 7 can run (U-175)`)
- **U-179** — R-F18` zmierzone i przeformułowane ([`c75422b99`](https://gitlab.com/e-os/e-os/-/commit/c75422b99), `fix(R-F18): measure it -- any two PCI devices sharing an INTx line storm, not ju`)
- **U-180** — R-F18` naprawione ([`93d206a7d`](https://gitlab.com/e-os/e-os/-/commit/93d206a7d), `fix(R-F18): the driver acked interrupts that were not its own (U-180)`)
- **U-181** — Sprostowanie do `U-180`: `install-smoke` PRZECHODZI, a `R-F25` nie było usterką ([`5817ca3b2`](https://gitlab.com/e-os/e-os/-/commit/5817ca3b2), `fix(record): retract R-F25 -- install-smoke passes; the instrument was broken (U`)
- **U-185** — make` nie buduje z tego repozytorium ([`5b4f00722`](https://gitlab.com/e-os/e-os/-/commit/5b4f00722), `fix(build): make does not build from this repo -- sync tool + doc drift (U-185)`)
- **U-187** — Trzy usterki naprawione, a najciekawsza znalazła się sama ([`bbe81c758`](https://gitlab.com/e-os/e-os/-/commit/bbe81c758), `fix(gates): close R-F02 and R-F13; the new gate caught a bug I had just written `)
- **U-188** — R-F06` naprawione ([`6da5b9fee`](https://gitlab.com/e-os/e-os/-/commit/6da5b9fee), `fix(pkg-lib): a keyless remote is an error, not a panic -- R-F06 (U-188)`)
- **U-189** — Bramka, która nigdy nie zadziałała, i zarzut, który okazał się nietrafiony ([`f7f52fa5e`](https://gitlab.com/e-os/e-os/-/commit/f7f52fa5e), `fix(ci): docs-currency had never run once; correct a stale x86_64 note (U-189)`)
- **U-200** — Publikacja przygotowana ([`6330140b0`](https://gitlab.com/e-os/e-os/-/commit/6330140b0), `fix(publish): one variable name, a stale comment, and a README for the artefact `)
- **U-219** — Poprawka bezpieczeństwa w jądrze: `Iopl` wymaga teraz roota ([`6799db569`](https://gitlab.com/e-os/e-os/-/commit/6799db569), `fix(kernel): bump to the Iopl privilege fix; raw port I/O now requires root (U-2`)
- **U-224** — Klucz `R-702` istnieje ([`51cac0382`](https://gitlab.com/e-os/e-os/-/commit/51cac0382), `fix(build): rebuild the host tools, stop exporting empty artifacts, and correct `)
- **U-226** — Zapis stanu łańcucha weryfikacji był nieprawdziwy w **obu** dokumentach: roadmapa twierdziła `verify.sh: 15 PASS`, `CLAUDE.md` §13.1 `12 PASS · 3 SKIPPED`; pomiar dał 13 PASS · 2 SKIPPED i kod 2. Po doinstalowaniu `cargo-llvm-cov` i `cargo-deny`: **15 PASS · 0 FAIL · 0 SKIPPED**. Drugie znalezisko: `CLAUDE.md` i `verify.sh:109` mówiły, że bramki `scripts/eos-check-tar-pins.py` „w drzewie nie ma" — bramka jest. Przeszła kontrolę mutacyjną dwustopniowo, bo pierwsza mutacja (`recipes/libs/atk`) trafiła **obok domknięcia obrazu** i dała exit 0 ([`cd323056a`](https://gitlab.com/e-os/e-os/-/commit/cd323056a), `docs(verify): popraw zapis stanu łańcucha -- bramka tar-pins istnieje`)
- **U-229** — `R-608`: `docs/getting-started/install.md` mówi prawdę o nazwie nośnika, procedurze zapisu i **składni instalatora**. Trzy usterki: (1) dokument w dwóch miejscach kazał zbudować `redox-live.iso`, cel **nieistniejący** od `R-611a`; (2) §3 podawało `redox_installer <config.toml> <disk>` — **odwrotnie**, bo `src/bin/installer.rs:208` w przypiętej rewizji `74726c889b` bierze `parser.args.first()` jako ścieżkę do `install(config, path)`, więc pozycyjny argument to **dysk**, a użytkownik wycelowałby instalator w swój plik TOML; (3) blok weryfikacji pobrania nie znał nośnika pakowanego przez `R-611b`. Nie zmieniona świadomie rozbieżność wersji (obraz stempluje `0.1.0 (Genesis)`, nośnik nazywa się `0.2.0`) — podbicie liczby uczyniłoby dokument kłamliwym, więc jest **opisana**. Sprawdzony i **odrzucony** czwarty, pozorny zarzut: binarka `redox_installer_gui` istnieje, buduje się z podkatalogu `gui/`. Domknięte też dwie specyfikacje, które zapisywały odwróconą składnię jako rozjazd otwarty ([`cae1445dc`](https://gitlab.com/e-os/e-os/-/commit/cae1445dc), `docs(R-608): install.md mówi prawdę o nazwie nośnika, procedurze zapisu i składni instalatora`)

### Security

- **U-184** — Klucz podpisujący: jedno polecenie dla człowieka, reszta zautomatyzowana ([`930738a2b`](https://gitlab.com/e-os/e-os/-/commit/930738a2b), `feat(keys): one command for the human, everything else automated (U-184)`)
- **U-191** — Mapa pięciu warstw autentyczności ([`e121edc1e`](https://gitlab.com/e-os/e-os/-/commit/e121edc1e), `docs(keys): map the five authenticity layers; record the lost release key (U-191`)
- **U-192** — Procedura obu kluczy krok po kroku ([`6fa2f5b35`](https://gitlab.com/e-os/e-os/-/commit/6fa2f5b35), `docs(keys): step-by-step for both keys; correct my own claim from U-191 (U-192)`)
- **U-193** — Krok 0 procedury kluczy był niekompletny i zapętliłby operatora ([`49f0d32dc`](https://gitlab.com/e-os/e-os/-/commit/49f0d32dc), `docs(keys): step 0 was incomplete and would have looped the operator (U-193)`)
- **U-194** — Katalog projektu stoi na exFAT z `noowners ([`69db24429`](https://gitlab.com/e-os/e-os/-/commit/69db24429), `fix(keys): the project volume is exFAT+noowners, so a secret cannot be protected`)
- **U-195** — Wznawianie z `U-194` było blokowane przez własną kontrolę skryptu ([`d8098a196`](https://gitlab.com/e-os/e-os/-/commit/d8098a196), `fix(keys): resume was blocked by the script's own guard, and demanded a compiler`)
- **U-196** — Klucz podpisujący indeks pakietów istnieje i jest przypięty ([`d8957773b`](https://gitlab.com/e-os/e-os/-/commit/d8957773b), `fix(keys): the repo-signing key is pinned; three defects found while checking th`)
- **U-197** — R-702` domknięte po stronie obrazu ([`becfce6cf`](https://gitlab.com/e-os/e-os/-/commit/becfce6cf), `feat(R-702): the pinned key is in the image, byte-exact -- and what that does no`)
- **U-205** — R-F26` ZAMKNIĘTE ([`7024bff00`](https://gitlab.com/e-os/e-os/-/commit/7024bff00), `docs(keys): R-F26 closed -- operator rotated the minisign release key (U-205)`)
- **U-206** — V2-N03 ([`a30520680`](https://gitlab.com/e-os/e-os/-/commit/a30520680), `feat(secureboot): sign the bootloader and prove it under Secure Boot, no Microso`)
- **U-207** — Integracja podpisu bootloadera domknięta ([`f518a4cc8`](https://gitlab.com/e-os/e-os/-/commit/f518a4cc8), `feat(secureboot): sign the bootloader in its recipe -- the live ISO boots under `)
- **U-213** — V2-MS12 ([`03aa86a93`](https://gitlab.com/e-os/e-os/-/commit/03aa86a93), `fix(pkg): correct V2-MS12's premise, guard the package key, stop promising prote`)
- **U-218** — Tor B: `V2-MS01` (SBAT) i `V2-MS05` (hermetyczne podpisywanie) zrobione ([`8183c9c4b`](https://gitlab.com/e-os/e-os/-/commit/8183c9c4b), `feat(boot): SBAT in both UEFI bootloaders, hermetic signing, and the SELinux lab`)

---

## [0.2.0] - 2026-08-22

Tag: [`v0.2.0`](https://github.com/Gh0s777tt/E-OS/releases/tag/v0.2.0) — annotated and **signed**; no release object exists for it.

233 commits since `v0.1.0`. This is the wave that added the E-OS applications, the verified boot chain, Secure Boot signing, the hybrid package-index signature, and the supply-chain gates.

### Added

- **U-071** — E-OS Settings ([`f3ef3ca4d`](https://gitlab.com/e-os/e-os/-/commit/f3ef3ca4d), `feat(settings)+fix(greeter): E-OS Settings [R-D01] + audiod nie blokuje sesji [R`)
- **U-072** — Graphical session no longer blocked by audio (`R-F07`) + display regression surfaced (`R-F08`) ([`f3ef3ca4d`](https://gitlab.com/e-os/e-os/-/commit/f3ef3ca4d), `feat(settings)+fix(greeter): E-OS Settings [R-D01] + audiod nie blokuje sesji [R`)
- **U-076** — First-boot forces a password on the shipped passwordless account (`R-602`) ([`6826e3a27`](https://gitlab.com/e-os/e-os/-/commit/6826e3a27), `feat(oobe): kreator first-boot wymusza haslo (R-602 text/getty) + bump eos-useru`)
- **U-077** — First-boot also forces a change of the default `root/password` (`R-602`) ([`2e103eb0f`](https://gitlab.com/e-os/e-os/-/commit/2e103eb0f), `feat(oobe): first-boot wymusza zmiane domyslnego root/password (R-602) [U-077]`)
- **U-079** — The graphical greeter now enforces the first-boot password too (`R-602`) ([`afd4387d9`](https://gitlab.com/e-os/e-os/-/commit/afd4387d9), `feat(oobe): graficzny greeter wymusza haslo — P0 default-creds zamkniete na KAZD`)
- **U-086** — E-OS Notes ([`fd6ac270d`](https://gitlab.com/e-os/e-os/-/commit/fd6ac270d), `feat(apps)+recipes: E-OS Notes — first E-OS original app (U-086)`)
- **U-088** — eos-ui ([`f9d415bd7`](https://gitlab.com/e-os/e-os/-/commit/f9d415bd7), `feat(ui)+recipes: extract eos-ui shared Slint backend; eos-notes uses it (U-088)`)
- **U-089** — E-OS Guard ([`1cd284009`](https://gitlab.com/e-os/e-os/-/commit/1cd284009), `feat(apps)+recipes: E-OS Guard — second original app, integrity monitor (U-089)`)
- **U-094** — E-OS Sysmon ([`d7c95fa86`](https://gitlab.com/e-os/e-os/-/commit/d7c95fa86), `feat(apps)+recipes: E-OS Sysmon — third original app, system monitor (U-094)`)
- **U-096** — E-OS Control v2 ([`6d3dc87e5`](https://gitlab.com/e-os/e-os/-/commit/6d3dc87e5), `feat(eos-control): process grouping + force-kill — bump pin af7a932→fed7e32 (U-0`)
- **U-097** — E-OS Control v3 ([`d9968546c`](https://gitlab.com/e-os/e-os/-/commit/d9968546c), `feat(eos-control): rank processes by memory + total-memory readout — bump pin fe`)
- **U-098** — Launcher clock: local date + timezone (was UTC `HH:MM` only) ([`84db806f5`](https://gitlab.com/e-os/e-os/-/commit/84db806f5), `feat(launcher): local date+timezone clock — bump orbutils cf121dc→94dcc91, ship `)
- **U-099** — Launcher Start-menu type-to-search ([`8dd7f17a0`](https://gitlab.com/e-os/e-os/-/commit/8dd7f17a0), `feat(launcher): Start-menu type-to-search — bump orbutils 94dcc91→7b1268b, compl`)
- **U-100** — Compositor screenshot ([`7c90fd48f`](https://gitlab.com/e-os/e-os/-/commit/7c90fd48f), `feat(compositor): Super-P screenshot — bump orbital 7ee7c04→38226c7, R-D04 done `)
- **U-101** — Status tray: real icons + click-to-Settings ([`22aecc805`](https://gitlab.com/e-os/e-os/-/commit/22aecc805), `feat(launcher): functional status tray — icons + click-to-Settings, bump orbutil`)
- **U-102** — Notifications: a minimal daemon + client (`eos-notifyd` / `eos-notify`) ([`6c5de19ae`](https://gitlab.com/e-os/e-os/-/commit/6c5de19ae), `feat(notifications): minimal eos-notifyd/eos-notify — bump orbutils 60c262d→8ad7`)
- **U-103** — netsurf: build from source as a PIE (partial ([`d0b6aafff`](https://gitlab.com/e-os/e-os/-/commit/d0b6aafff), `feat(netsurf): build from source as PIE + fix host-toolchain 404 (U-103, partial`)
- **U-105** — netsurf: local default homepage + click-to-launch verified ([`5f7a48afa`](https://gitlab.com/e-os/e-os/-/commit/5f7a48afa), `feat(netsurf): local about:welcome homepage + verify click-to-launch (U-105)`)
- **U-106** — eos-control: Network tab (live `/etc/net` config + stack status) ([`b102cb5cd`](https://gitlab.com/e-os/e-os/-/commit/b102cb5cd), `feat(control): Network tab — live /etc/net config + stack status (U-106)`)
- **U-107** — eos-control: Storage tab (root filesystem usage via `statvfs`) ([`a17fe6fe2`](https://gitlab.com/e-os/e-os/-/commit/a17fe6fe2), `feat(control): Storage tab — root filesystem usage via statvfs (U-107)`)
- **U-108** — eos-control: Power tab (reboot / shutdown) ([`d6a8a22d9`](https://gitlab.com/e-os/e-os/-/commit/d6a8a22d9), `feat(control): Power tab (reboot/shutdown) — UI + confirm work, action needs pri`)
- **U-109** — eos-control: power actions now WORK ([`1bbd712b2`](https://gitlab.com/e-os/e-os/-/commit/1bbd712b2), `feat(control): power actions work — eos-power shim + password dialog (U-109, R-D`)
- **U-110** — eos-control: Sound tab (master volume via audiod's `audio:volume`) ([`3e759bcb3`](https://gitlab.com/e-os/e-os/-/commit/3e759bcb3), `feat(control): Sound tab via audiod audio:volume (U-110) + fix container build f`)
- **U-111** — build: fix the Podman container build for repo paths containing a space ([`3e759bcb3`](https://gitlab.com/e-os/e-os/-/commit/3e759bcb3), `feat(control): Sound tab via audiod audio:volume (U-110) + fix container build f`)
- **U-132** — the two R-902 pins are bumped and gated ([`ab19dd552`](https://gitlab.com/e-os/e-os/-/commit/ab19dd552), `feat(pins): bump the two R-902 pins after a full gate run; allowlist now empty (`)
- **U-133** — x86_64 boots, boot-smoke now covers it, and the live-USB path onto real hardware is documented ([`ba364edc3`](https://gitlab.com/e-os/e-os/-/commit/ba364edc3), `feat(ci): boot-smoke x86_64 too, and document the live-USB path to metal (U-133)`)
- **U-146** — a second disk silently stops the boot ([`0ddb394b2`](https://gitlab.com/e-os/e-os/-/commit/0ddb394b2), `test(boot): reproduce the silent second-disk boot stall (U-146, R-F16)`)
- **U-150** — R-F16` located exactly, by making `init` say where it is ([`92ec5ab44`](https://gitlab.com/e-os/e-os/-/commit/92ec5ab44), `test(boot): locate R-F16 inside redoxfs, and attach the target over USB (U-150)`)

### Changed

- **U-073** — R-D01 Settings render-verified end-to-end + `R-F08` root-caused ([`21551e227`](https://gitlab.com/e-os/e-os/-/commit/21551e227), `docs(R-D01): render Settings zweryfikowany + R-F08 root-cause (auto-aktywacja VT`)
- **U-074** — R-F08` fully root-caused (docs only) ([`ee2bf4e0c`](https://gitlab.com/e-os/e-os/-/commit/ee2bf4e0c), `docs(R-F08): pełna diagnoza root-cause (fbcond kradnie VT2 po greeterze) [U-074]`)
- **U-082** — Installer GUI produced a non-bootable disk; randd trusted failed rdrand (`G1`, entropy) ([`f2e480e9a`](https://gitlab.com/e-os/e-os/-/commit/f2e480e9a), `recipes: bump installer + base pins for G1 + rdrand fixes (U-082)`)
- **U-083** — aarch64 system clock no longer stuck at 1970 on an ACPI boot ([`65b1786b8`](https://gitlab.com/e-os/e-os/-/commit/65b1786b8), `recipes: bump bootloader + base pins for aarch64 clock fix (U-083)`)
- **U-084** — Fork CI revived ([`71b059540`](https://gitlab.com/e-os/e-os/-/commit/71b059540), `ci+recipes: revive fork CI in the e-os namespace — bump 9 pins (U-084)`)
- **U-087** — E-OS Notes verified fully interactive ([`c3aa2ad36`](https://gitlab.com/e-os/e-os/-/commit/c3aa2ad36), `recipes: bump eos-notes pin — TextInput keyboard fix (U-087)`)
- **U-091** — pages` must not block the OS build (`allow_failure`) ([`a3a2637c1`](https://gitlab.com/e-os/e-os/-/commit/a3a2637c1), `docs+ci: documentation standard, ARCHITECTURE, app guide, docs PDF + enforcement`)
- **U-092** — Heavy `build-image` detached from the shared-runner light tier (`needs: []`) ([`a3a2637c1`](https://gitlab.com/e-os/e-os/-/commit/a3a2637c1), `docs+ci: documentation standard, ARCHITECTURE, app guide, docs PDF + enforcement`)
- **U-093** — Documentation standard + tooling ([`a3a2637c1`](https://gitlab.com/e-os/e-os/-/commit/a3a2637c1), `docs+ci: documentation standard, ARCHITECTURE, app guide, docs PDF + enforcement`)
- **U-112** — eos-control: Network settings pane ([`00ef512ef`](https://gitlab.com/e-os/e-os/-/commit/00ef512ef), `docs(control): record R-902 Network settings pane (U-112) + bump eos-control pin`)
- **U-114** — ci(pins): un-redden the daily pipeline ([`0260ef8a2`](https://gitlab.com/e-os/e-os/-/commit/0260ef8a2), `ci(pins): allowlist the two R-902 pin holds; un-redden the daily pipeline (U-114`)
- **U-115** — docs: the great re-sync ([`c3a55959c`](https://gitlab.com/e-os/e-os/-/commit/c3a55959c), `docs: great re-sync to U-113 reality; ship screenshots on the docs site (U-115)`)
- **U-116** — docs(claude): CLAUDE.md re-synced with reality (its own "keep this file honest" rule) ([`579ca7bb0`](https://gitlab.com/e-os/e-os/-/commit/579ca7bb0), `docs(claude): re-sync CLAUDE.md with repo reality (U-116)`)
- **U-118** — supply-chain: every fetched build binary is now SHA256-pinned (audit §4 items 1–3) ([`86d715692`](https://gitlab.com/e-os/e-os/-/commit/86d715692), `build(supply-chain): SHA256-pin every fetched build binary (U-118)`)
- **U-121** — mirror hygiene: the stray ImgBot work is merged, the divergent branch retired ([`799556715`](https://gitlab.com/e-os/e-os/-/commit/799556715), `docs(changelog): record the ImgBot merge + mirror-branch cleanup (U-121)`)
- **U-123** — ops: the `eosbuild` container finally has a written way back ([`922b432b8`](https://gitlab.com/e-os/e-os/-/commit/922b432b8), `ops(ci): document + script the eosbuild container recovery (U-123)`)
- **U-124** — the U-114 outage was never data loss ([`c259335d6`](https://gitlab.com/e-os/e-os/-/commit/c259335d6), `ops(ci): eosbuild caches live in named volumes; recovery script kept them (U-124`)
- **U-127** — the shipping session was never "the COSMIC desktop" ([`2946c6ad1`](https://gitlab.com/e-os/e-os/-/commit/2946c6ad1), `docs: the shipping session is orbital, not "the COSMIC desktop" (U-127, R-D12)`)
- **U-129** — README re-verified against `U-118`…`U-128` and its `SYNC` marker finally moved ([`cbd9ef5ed`](https://gitlab.com/e-os/e-os/-/commit/cbd9ef5ed), `docs(readme): re-verify against U-118..U-128 and move the SYNC marker (U-129)`)
- **U-130** — usbnetd` RX was never broken ([`1597fe0b3`](https://gitlab.com/e-os/e-os/-/commit/1597fe0b3), `docs: usbnetd RX was never broken — recover the lost U-056/U-057 records (U-130,`)
- **U-131** — "history lives in the git log" was not quite true, and it was about to manufacture a false finding ([`bb4855006`](https://gitlab.com/e-os/e-os/-/commit/bb4855006), `docs(changelog): pre-U-071 history lives on an archived branch, not main's log (`)
- **U-136** — the text every user actually reads was still advertising a desktop we don't ship and a handbook that 404s ([`c14b7c174`](https://gitlab.com/e-os/e-os/-/commit/c14b7c174), `docs(image): fix the welcome text users actually read (U-136, R-D12 residue)`)
- **U-138** — CLAUDE.md gains the three sections it was missing: cadence, releases, and the host it actually runs on ([`2a22a8d82`](https://gitlab.com/e-os/e-os/-/commit/2a22a8d82), `docs(claude): add cadence, release discipline and host context (U-138)`)
- **U-139** — branch hygiene: 14 branches down to 5, and the mirror turns out not to replicate deletions ([`160e6995f`](https://gitlab.com/e-os/e-os/-/commit/160e6995f), `chore(repo): prune nine dead branches; record that the mirror ignores deletions `)
- **U-145** — the 13 recipes that actually ship are pinned ([`1c175c2ac`](https://gitlab.com/e-os/e-os/-/commit/1c175c2ac), `build(supply-chain): pin the 13 recipes that actually ship (U-145, R-F11)`)
- **U-147** — correcting my own `R-F16` wording: the defect is narrower than I published ([`5616cf99b`](https://gitlab.com/e-os/e-os/-/commit/5616cf99b), `docs(R-F16): correct my own scope claim -- the defect is initfs-only (U-147)`)
- **U-151** — a dead end on `R-F16`, recorded so the next attempt does not repeat it: `redoxfs` cannot be instrumented through stdout or stderr ([`74240c320`](https://gitlab.com/e-os/e-os/-/commit/74240c320), `docs(R-F16): record a dead end -- redoxfs cannot be instrumented via stdio (U-15`)

### Fixed

- **U-075** — vesad: don't panic on a malformed bootloader-env line (`R-F09`) ([`a4165f5f4`](https://gitlab.com/e-os/e-os/-/commit/a4165f5f4), `fix(vesad): bump eos-base 98f22879 (R-F09 env-parse bez paniki) [U-075]`)
- **U-078** — Boot lands directly on the graphical greeter ([`61cb53e41`](https://gitlab.com/e-os/e-os/-/commit/61cb53e41), `fix(boot): pulpit startuje bez Super+F3 — greeter trzyma VT3 (R-F08) [U-078]`)
- **U-080** — Live-ISO text console (VT2) works again ([`7809be3d1`](https://gitlab.com/e-os/e-os/-/commit/7809be3d1), `fix(boot): konsola tekstowa VT2 dziala na live — getty 2 odblokowany (R-601) [U-`)
- **U-085** — Standalone installer writes the right EFI boot file without env `TARGET`; virtio drivers no ([`938ad8389`](https://gitlab.com/e-os/e-os/-/commit/938ad8389), `fix(installer,virtio)+recipes: config-driven installer target; graceful legacy v`)
- **U-104** — netsurf: fix the first-render crash ([`ceb732057`](https://gitlab.com/e-os/e-os/-/commit/ceb732057), `fix(netsurf): drop SDL_RESIZABLE — fix first-render use-after-munmap, browser re`)
- **U-113** — eos-control: render-verify of the Sieć tab surfaced (and fixed) a real on-device gap (`R-902`) ([`194cd8090`](https://gitlab.com/e-os/e-os/-/commit/194cd8090), `fix(control): U-113 — render-verify Sieć tab; fix netcfg-namespace read gap`)
- **U-125** — integrity` gate: stop scanning 15 GB of vendored upstream Rust and calling it "our own ([`b968453b3`](https://gitlab.com/e-os/e-os/-/commit/b968453b3), `fix(ci): scope the integrity gate to tracked sources (U-125)`)
- **U-128** — README roadmap Gantt: one missing brace made its theme directive invalid ([`edc995ece`](https://gitlab.com/e-os/e-os/-/commit/edc995ece), `fix(readme): close the mermaid init directive on the roadmap Gantt (U-128)`)
- **U-148** — the `R-F16` mechanism I published twice was wrong ([`89dcddc76`](https://gitlab.com/e-os/e-os/-/commit/89dcddc76), `fix(docs): correct the R-F16 mechanism, and record R-F17 (U-148)`)
- **U-149** — R-F17` fixed: a kernel return value that is correct by design no longer kills the storage driver ([`14353b3f5`](https://gitlab.com/e-os/e-os/-/commit/14353b3f5), `fix(irq): stop aborting nvmed on a stale INTx ack (U-149, R-F17)`)

### Security

- **U-081** — Security-fix pins land in the image ([`f70e5ac1e`](https://gitlab.com/e-os/e-os/-/commit/f70e5ac1e), `recipes(security): bump base/redoxfs/pkgutils pins — K-01, K-06, UB fix, R-703 (`)
- **U-090** — Guard v2 ([`616454916`](https://gitlab.com/e-os/e-os/-/commit/616454916), `recipes: bump eos-guard to v2 — permission audit + baseline digest (U-090)`)
- **U-095** — E-OS Control ([`1ca28d6ae`](https://gitlab.com/e-os/e-os/-/commit/1ca28d6ae), `feat(apps)+recipes: E-OS Control — unified control center, replaces sysmon+guard`)
- **U-117** — docs(coverage): close the "why is this here?" gaps the audit found in our own tree ([`010fd7057`](https://gitlab.com/e-os/e-os/-/commit/010fd7057), `docs(coverage): document patches/, orbdata pin, src/ vendoring, eos-repo-sign (U`)
- **U-119** — eos-repo-sign: keygen can no longer leak or clobber the repo-signing key (audit §4 item 6) ([`12b61cd64`](https://gitlab.com/e-os/e-os/-/commit/12b61cd64), `fix(eos-repo-sign): keygen writes 0600 secret, refuses to clobber keys (U-119)`)
- **U-120** — unsigned publish is now an explicit opt-in, not a silent default (audit §4 item 4) + gitleaks ([`75734e37e`](https://gitlab.com/e-os/e-os/-/commit/75734e37e), `sec(publish): unsigned publish requires EOS_ALLOW_UNSIGNED=1; gitleaks review (U`)
- **U-122** — docs(hardening): the supply-chain gates get their reference section ([`193c418c3`](https://gitlab.com/e-os/e-os/-/commit/193c418c3), `docs(hardening): reference section for the U-118/U-120 supply-chain gates (U-122`)
- **U-126** — docs honesty pass: the signing chain, the install guide, and a reality-ledger that ([`cd3a2dacb`](https://gitlab.com/e-os/e-os/-/commit/cd3a2dacb), `docs: separate publisher-side signing from the client half that does not exist (`)
- **U-134** — I got the signing chain wrong in `U-126 ([`21b81199b`](https://gitlab.com/e-os/e-os/-/commit/21b81199b), `docs(security): the client verifier exists — correct U-126 and un-invert the tru`)
- **U-135** — the pinned repo key had nowhere to land ([`879e2633b`](https://gitlab.com/e-os/e-os/-/commit/879e2633b), `feat(security): give the pinned repo key somewhere to land (U-135, R-702)`)
- **U-137** — one malformed vendor key could take down every driver binding at boot ([`a9295f974`](https://gitlab.com/e-os/e-os/-/commit/a9295f974), `fix(pcid): a malformed vendor key no longer breaks all driver binding (U-137, R-`)
- **U-140** — the pre-commit secret gate was decorative, `unsafe` had no rule at all, and nothing was signed ([`50ac4a066`](https://gitlab.com/e-os/e-os/-/commit/50ac4a066), `feat(security): close the secret gate, gate unsafe, state the signing gap (U-140`)
- **U-141** — full-ecosystem audit: the security posture document was itself the worst offender ([`1d3c62ea6`](https://gitlab.com/e-os/e-os/-/commit/1d3c62ea6), `docs(security): re-measure the posture table; six audit findings become R-F10..R`)
- **U-142** — docs/plan.md ([`c521590b1`](https://gitlab.com/e-os/e-os/-/commit/c521590b1), `docs(plan): editions, compartmentalisation model, and the order that is the cont`)
- **U-143** — E-OS images no longer ship a package source that undermines their own hardening (`R-701a`) ([`0a4677a6c`](https://gitlab.com/e-os/e-os/-/commit/0a4677a6c), `security(image): stop shipping the upstream package source (U-143, R-701a)`)
- **U-144** — raw IP sockets are no longer handed to every user program ([`c77a0fbde`](https://gitlab.com/e-os/e-os/-/commit/c77a0fbde), `security(net): take raw IP sockets away from user programs (U-144, R-904a)`)
- **U-152** — signing was already live and the docs said otherwise; the tag gap was structural; and a tag would have hung CI ([`374da27de`](https://gitlab.com/e-os/e-os/-/commit/374da27de), `docs(signing): re-measure signing, correct the DCO claim, unhang tag CI (U-152)`)

---

## [0.1.0] - 2026-06-07

Release: [`v0.1.0`](https://github.com/Gh0s777tt/E-OS/releases/tag/v0.1.0) — the only published release object.

**Reconstructed from `git log`, not from this file.** `CHANGELOG.md` did not exist yet at this tag; its own header records that history before `U-071` predates the file. The 18 commits between `eos-base-2026-06-06` and `v0.1.0` are Conventional Commits with unambiguous subjects, so the list below is a faithful reconstruction rather than an invention.

### Added

- feat(eos): E-OS build config + OS-level rebrand + desktop screenshot ([`0d14ebc12`](https://gitlab.com/e-os/e-os/-/commit/0d14ebc12))
- feat(bootloader): red/black E-OS bootloader theme (built from source) ([`897fa66d6`](https://gitlab.com/e-os/e-os/-/commit/897fa66d6))
- feat(userutils): brand console login prompt to "eos login:" (built from source) ([`919a84809`](https://gitlab.com/e-os/e-os/-/commit/919a84809))
- feat(orbdata): E-OS red/black login greeter + desktop wallpaper (built from source) ([`5dc7e14e9`](https://gitlab.com/e-os/e-os/-/commit/5dc7e14e9))
- feat(orbdata): E-OS launcher menu icon (replace Redox R), refresh previews ([`d57a356c1`](https://gitlab.com/e-os/e-os/-/commit/d57a356c1))
- feat(aarch64): E-OS aarch64 desktop config (full branding) ([`82af7a440`](https://gitlab.com/e-os/e-os/-/commit/82af7a440))
- feat(docs): mdBook documentation site + GitHub Pages workflow (R-1004) ([`60d938127`](https://gitlab.com/e-os/e-os/-/commit/60d938127))

### Changed

- build: point patched recipes at E-OS source forks (reproducible main) ([`4a09cf7c3`](https://gitlab.com/e-os/e-os/-/commit/4a09cf7c3))
- docs: aarch64 + reproducibility status (ROADMAP/README) + aarch64 bootloader screenshot ([`5799602bf`](https://gitlab.com/e-os/e-os/-/commit/5799602bf))
- docs(roadmap): refine R-401b - aarch64 boot blocker is upstream redoxfs/relibc, not disk-specific ([`6aca114b8`](https://gitlab.com/e-os/e-os/-/commit/6aca114b8))
- docs(install): document the graphical/TUI installer + image flashing (R-1001) ([`467a78020`](https://gitlab.com/e-os/e-os/-/commit/467a78020))
- docs(lts): lts/0.1 support line + policy (R-1002) ([`0fecbf6c7`](https://gitlab.com/e-os/e-os/-/commit/0fecbf6c7))
- docs(packages): E-OS package repository guide + publish helper (R-1003) ([`b4d2bfab8`](https://gitlab.com/e-os/e-os/-/commit/b4d2bfab8))

### Security

- brand: establish E-OS identity, docs, security & automation ([`cad6d4895`](https://gitlab.com/e-os/e-os/-/commit/cad6d4895))
- feat(fortify): CycloneDX SBOM + checksums + release workflow (R-301/R-302) ([`f17427863`](https://gitlab.com/e-os/e-os/-/commit/f17427863))
- docs(security): threat model + hardening + disk-encryption guides (R-304/R-305) ([`5f61baeef`](https://gitlab.com/e-os/e-os/-/commit/5f61baeef))
- fix(deps): bump time 0.3.44 -> 0.3.47 (CVE-2026-25727 stack-exhaustion DoS) ([`0d90e5c71`](https://gitlab.com/e-os/e-os/-/commit/0d90e5c71))
- feat(release): minisign-sign checksums + E-OS release public key (R-301) ([`630d98e40`](https://gitlab.com/e-os/e-os/-/commit/630d98e40))

---

## Before `v0.1.0`

**Not reconstructable, and deliberately not invented.** Everything before the
`eos-base-2026-06-06` marker is inherited Redox OS history — 9 849 commits that are upstream's
work, not E-OS's. Ten numbered items (`U-001`–`U-006`, `U-008`, `U-012`–`U-014`) referenced by
older documents appear nowhere in `main`'s history: they live on the archived, disjoint branch
`archive/pre-migration-de-phase1` and can be read with
`git show origin/archive/pre-migration-de-phase1:CHANGELOG.md`. That branch is **not an ancestor**
of `main`, so a citation to it resolves only there.
