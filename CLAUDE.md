# CLAUDE.md — jak pracujemy w E-OS

> **Ten plik jest kontraktem, nie poradnikiem.** Opisuje, co musi być prawdą, zanim
> zmiana trafi do repozytorium. Powstał z błędów popełnionych w tym drzewie — każda
> reguła ma numer wpisu w `CHANGELOG.md`, który ją wymusił.
>
> **Numeracja §1–§10 jest stabilna i nie wolno jej przenumerowywać.** Kilkanaście
> wpisów CHANGELOG-a cytuje `§1.6`, `§4.1`, `§10.1`; przesunięcie numerów unieważniłoby
> je po cichu — co §2 wprost zakazuje. Nowy materiał dopisujemy jako §11 i dalej.

## 0. Co to za repozytorium (przeskanowane, nie założone)

| | |
|---|---|
| **Typ repo** | **A — komponent własny E-OS** (repo orkiestrujące całym ekosystemem) |
| **Licencja** | **AGPL-3.0-or-later** (`LICENSE`); pliki odziedziczone z Redoksa zostają na MIT — patrz `NOTICE` |
| **Język / toolchain** | Rust `nightly-2026-05-24`, edition 2024 (`rust-toolchain.toml`), komponenty: `rust-src`, `rustfmt`, `clippy` |
| **Skrzynka główna** | `redox_cookbook` — **vendorowany silnik budowania z upstreamu**, binarki `repo`, `repo_builder`, `cookbook_redoxer` |
| **Skrzynka własna** | `tools/eos-repo-sign` — hybrydowe podpisywanie manifestu (ed25519 + ML-DSA-65) |
| **Build** | GNU Make + `mk/*.mk`, wykonywany w kontenerze podmana; `flake.nix` obecny |
| **CI** | **GitLab CI** (`.gitlab-ci.yml`, 12 zadań / 5 etapów). **GitHub nie ma workflowów** — tylko `CODEOWNERS`, `dependabot.yml`, szablony |
| **Dokumentacja** | mdBook (`book.toml`, `docs/SUMMARY.md`), 38 plików `.md` w `docs/` |
| **Skrypty** | 38 w `scripts/`, w tym `sync-forks.sh` i `publish-repo-pages.sh` — **oba obecne lokalnie** |

**Etapy CI i zadania (stan faktyczny):**

```
verify : secret-scan · integrity · pin-check · docs-currency · renovate
test   : rust-checks · shell-lint
docs   : pages · docs-pdf
release: semantic-release
build  : build-image · build-image-x86_64
```

**Komendy, które realnie coś robią:**

```sh
make CI=1 ARCH=aarch64 CONFIG_NAME=eos all   # pełny obraz (w kontenerze)
bash scripts/ci-integrity.sh                 # bramka niezmienników (8 kontroli)
bash scripts/eos-repos.sh pins --strict      # zgodność pinów, 26 repo
bash scripts/ci-boot-smoke.sh <obraz>        # dowód: boot dochodzi do `eos login:`
bash scripts/repro-intx-lines.sh <obraz>     # strażnik regresji R-F16 (10 konfiguracji)
cargo fmt --manifest-path tools/eos-repo-sign/Cargo.toml -- --check
cargo clippy --manifest-path tools/eos-repo-sign/Cargo.toml -- -D warnings
cargo test  --manifest-path tools/eos-repo-sign/Cargo.toml
cargo test  --manifest-path Cargo.toml       # 9 testów vendorowanego cookbooka
shellcheck -S error scripts/*.sh             # blokujące; ostrzeżenia doradcze
gitleaks detect --source . --no-banner --redact
```

**Układ na dysku (po uporządkowaniu, `U-186`):** `E-OS Project/` zawiera teraz
**wyłącznie dwie pozycje** — to repozytorium w `E-OS/` oraz `_archiwum-migawek/`. Katalog
nadrzędny **nie jest** repozytorium. W archiwum leży 80 nieaktualnych, rozpakowanych kopii
forków (plus `e-os-main/`, czyli kopia tego repo), które wcześniej stały bezpośrednio obok i
były przez to czytane jak źródło prawdy. **Nie są nim** — patrz §20.2. Build ich nie używa:
pobiera przypięte rewizje (§1.6, §11).


## 1. Definicja ukończenia — nic nie wychodzi, dopóki wszystko poniżej nie jest prawdą

Zmiana (poprawka, funkcja, skrypt, refaktor, wybór technologii) **nie jest gotowa**, dopóki:

1. **Kompiluje się** — `cargo check` dla docelowej architektury w kontenerze budującym.
2. **Integruje się** — `make CI=1 … all` przechodzi, a jeśli zmiana dotyka obrazu,
   `scripts/ci-boot-smoke.sh` kończy się PASS (boot dochodzi do `eos login:`).
3. **Ma dowód działania i kontrolę negatywną** — realny ślad, nigdy założenie: log
   z serialu, marker `--selftest`, pcap albo screendump. Podaj dowód **i** napisz, że
   widziałeś, jak sprawdzenie **pada bez poprawki** i przechodzi z nią. Zielone
   sprawdzenie, którego nigdy nie widziałeś na czerwono, nie jest dowodem (§4.1).
   Identyczny wynik przed i po **nie jest naprawą** — cofnij ją i wyjaśnij dlaczego (§4.4).
4. **Jest udokumentowana** — patrz §2. Każda nowa funkcja, skrypt, API i technologia
   opisane **co + dlaczego**. Bez wyjątków: nieudokumentowane = nieukończone.
5. **Jest zapisana** — wpis w `CHANGELOG.md` (`[U-NNN]`, co + dlaczego + jak zweryfikowane),
   komunikat w stylu Conventional Commits, zmiana mała i samodzielna.
6. **Jest przypięta i wypchnięta** — jeśli zmienił się fork: **najpierw** commit na
   **oba hosty**, potem podbicie `repos.toml` + rewizji w przepisie;
   `scripts/eos-repos.sh pins --strict` musi być zielone. Przepisy pobierają dokładną
   rewizję z lustra GitHuba, a **forki nie mają push-mirrora** — każdy wymaga dwóch
   osobnych pushy i weryfikacji `git ls-remote` na obu hostach.

## 2. Dokumentacja jest częścią pracy, nie dodatkiem

**Zasada:** po każdej ukończonej pracy zaktualizuj *każdy* dokument, którego dotyka, tak
żeby czytelnik pierwszy raz w życiu widzący projekt rozumiał, *czym* to jest i *po co*.

| Dokument | Rola | Aktualizuj gdy |
|---|---|---|
| `README.md` | Wizytówka: czym jest E-OS, status | zmiana widoczna dla użytkownika (nosi znacznik `SYNC:` — pilnuj prawdziwości) |
| `CHANGELOG.md` | Każda zmiana, numerowana `U-NNN` | **każda** zmiana |
| `ROADMAP.md` | Żywy plan, statusy ✅ 🚧 ⏳ | zmienia się status pozycji |
| `docs/*.md` → mdBook | Podręcznik (projekt, build, sprzęt, bezpieczeństwo, CI) | **nowe strony wpisz do `docs/SUMMARY.md`**, inaczej mdBook je zignoruje |
| `docs/design-*.md` | Jeden dokument projektowy na nietrywialny podsystem: *dlaczego*, odrzucone warianty, pułapki | projektujesz lub istotnie zmieniasz podsystem |
| `HARDWARE.md`, `docs/hardware-*` | Macierz wsparcia sprzętu | zmiana wsparcia sterownika/architektury |
| `SECURITY.md`, `docs/threat-model.md` | Postawa bezpieczeństwa i model zagrożeń | zmiana hardeningu lub łańcucha zaufania |
| `repos.toml` | Manifest repo + pinów (źródło prawdy ekosystemu) | każde podbicie pina |

**Poprzeczka:** nagłówki i jedno zdanie „co to jest / po co istnieje" na górze każdego
dokumentu; wyjaśniaj kompromisy i **odrzucone** warianty; linkuj powiązane dokumenty;
przykłady mają być uruchamialne.

**Pisz zapis tak, żeby ktoś inny mógł go sprawdzić.** Zdanie, którego czytelnik nie
zweryfikuje, jest twierdzeniem, nie dokumentacją. Cztery reguły — każdej nauczyło to
drzewo boleśnie (odpowiednik testowy w §4):

1. **Cytuj dowód w miejscu.** Komenda, liczba, `plik:linia`, rewizja. „Burza przerwań na
   dzielonej linii" to opinia; „`virq 37` = 11 054 068 wobec 8 851 na timerze, z
   `/scheme/sys/irq`" to zapis (`U-157`).
2. **Zakresuj twierdzenie do tego, co zmierzone — ani szerzej.** Podaj architekturę, host,
   konfigurację. `U-146` twierdziło „dwie linie INTx nie mogą działać naraz" na podstawie
   pomiaru z fazy initfs i było błędne przy pierwszym spojrzeniu na późniejszy etap bootu;
   `U-147` musiało to zawęzić, `U-148` jeszcze raz.
3. **Powiedz, czego *nie* zweryfikowałeś**, w tym samym oddechu co to, co zweryfikowałeś.
   Wpis wyliczający same sukcesy czyta się jak twierdzenie o kompletności, którego nie
   udźwignie.
4. **Poprawiaj w miejscu i zostaw poprawkę widoczną.** Gdy dokument okazuje się błędny,
   napraw go **i** zapisz, że był błędny oraz dlaczego — nie przepisuj po cichu. Czytelnik,
   który kiedyś oparł się na starym zdaniu, musi wiedzieć, że się zmieniło.

## 3. Standardy kodu — komentarze też są dokumentacją

- **Komentarz tłumaczy *dlaczego*, nie *co*.** Kod mówi, co robi; komentarz ma powiedzieć,
  jaki problem rozwiązuje i co zostało odrzucone.
- **Demon nie panikuje na sytuacji odwracalnej.** `unwrap()` na błędzie, który da się
  obsłużyć, to awaria całego sterownika — lekcja `U-085` (virtio-core) i `U-149`
  (`R-F17`: sterownik abortował na wartości zwracanej poprawnej z założenia).
- **Porty firm trzecich zostają na formie upstreamu.** Nie „poprawiamy" vendorowanego kodu
  kosmetycznie — każda dywergencja to koszt przy każdej synchronizacji (§11, typ B).
- **Conventional Commits** dla komunikatów; commit mały i samodzielny.

## 4. Dyscyplina weryfikacji — przetestuj, udowodnij test, zaudytuj twierdzenie

Każda poprawka przechodzi trzy bramki, w tej kolejności:

1. **Kompilacja** — `cargo check` w kontenerze wobec sysroota docelowego.
2. **Integracja** — `make … all` + `boot-smoke` PASS.
3. **Runtime** — dowód z serialu / `--selftest` / pcap / screendump.

Aplikacje GUI bez ekranu dostarczają `eos-<app> --selftest`, które dowodzi niewizualnego
rdzenia (wypisuje `…-SELFTEST-OK`, sprawdzane z logu serialu jednorazową sondą w init.d —
**sondy nigdy nie commitujemy**). Render GUI dowodzi się screendumpem.

### 4.1 Test, którego nie widziałeś padającego, nie jest testem

Samo przejście nic nie dowodzi — test może przechodzić na starym kodzie, na niewłaściwym
drzewie albo na niczym. **Pokaż, jak pada na wadzie, a potem jak przechodzi na poprawce.**
Obie połowy, za każdym razem, i napisz o tym we wpisie.

To nie jest teoria. Każde z poniższych było zielone i nie chroniło niczego:

- Hook `gitleaks` kończył się na `|| true`, więc podłożony klucz prywatny commitował się
  bez przeszkód (`U-140`).
- Bramka bash-4 łapała **własny literał regexu** i padała na czystym drzewie (`U-159`).
- Kontrola negatywna tej samej bramki była nieważna: `git grep` widzi wyłącznie pliki
  **śledzone**, więc nieśledzona sonda niczego nie dowodziła, dopóki nie zrobiono
  `git add -N` (`U-159`).
- `cd` bez `|| exit` w `ci-integrity.sh` — czyli w **samej bramce** — kazałby jej sprawdzać
  przypadkowy katalog i meldować PASS na niewłaściwym drzewie (`U-159`).

### 4.2 Udowodnij narzędzie, zanim uwierzysz w wynik negatywny

„Brak wyjścia" znaczy jedno z dwojga: kod się nie wykonał albo **nie mierzysz tego, co
myślisz**. Rozdziel te możliwości, zanim cokolwiek stwierdzisz.

`U-151` orzekło, że `redoxfs` „nie da się instrumentować", po dwóch kanałach bez wyniku.
To było błędne: przepis `base` kopiuje `redoxfs` do `initfs/bin/`, więc przebudowa samego
`r.redoxfs` zostawiała w initfs **starą binarkę** (§9). Rozstrzygnął dopiero test
bezwarunkowy: `panic!` w pierwszej linii `main()` — po którym boot **i tak** doszedł do
logowania, co jest niemożliwe, jeśli uruchamiana jest ta binarka (`U-153`). Trzy podejścia
poszły na mierzenie kodu, który nigdy nie startował.

**Kontroluj zmienne.** Jeden eksperyment przy `R-F18` „przeszedł", bo przeniesienie
`-device` na koniec linii poleceń QEMU zmieniło jego slot PCI, przez co urządzenie
przestało dzielić badaną linię przerwań (`U-157`).

**Kontekst błędu nie zastąpi sondy.** Kontekst mówi, **która operacja zawiodła**, ale
milczy o tym, **czy ten kod w ogóle się wykonał**. Przy `R-F19` trzy kolejne milczące
markery były dwuznaczne między „niewinny" a „nigdy nie uruchomiony"; dopiero bezwarunkowe
sondy `PROBE-*` rozstrzygnęły to w jednym przebiegu i pokazały, że badana była gałąź, w
którą program nie wchodzi (`U-166`).

### 4.3 Mierz, nie wnioskuj

Z wnioskowania wzięły się wszystkie błędne konkluzje w tym drzewie, publikowane po trzykroć:

- Punkt blokady odczytano z tego, **gdzie urwał się log serialu**, zamiast z miejsca, w
  którym kod zgłasza gotowość. `pcid-spawner` obwiniono dwa razy i nigdy nie był winny
  (`U-146`, `U-147`, poprawione w `U-148`).
- Rozstrzygnęło dopiero zmuszenie `init` do opowiadania o swoich jednostkach (`U-150`),
  potem odpytywanie logu **zegarem ściennym**, które znalazło 84-sekundową dziurę
  niewidoczną w znacznikach czasu (`U-154`), a na koniec liczniki przerwań kernela z
  `/scheme/sys/irq` — 11 054 068 na jednej linii wobec 8 851 na timerze (`U-157`).

Gdy da się coś policzyć — policz. Zacytuj liczbę we wpisie.

### 4.4 Zmiana, która niczego nie mierzy, nie idzie do repo

Jeśli przed i po jest identycznie, to nie jest poprawka — niezależnie od tego, jak dobrze
brzmi uzasadnienie. Cofnij ją i zapisz dlaczego. `U-157` zrobiło dokładnie to ze zmianą
modelu przerwań w kernelu, która była **prawdopodobnie bardziej poprawna**, a zmierzyła
**111 s przed i 111 s po**: nic nie dawała, a groziła trwałym zamaskowaniem dzielonej linii
przy śmierci jednego sterownika. Brzmieć sensownie to nie jest dowód.

### 4.5 Audyt: twierdzenie bez aktualnego dowodu jest wadą

Dokumentacja gnije po cichu, więc **weryfikuj twierdzenia w obszarze, który i tak ruszasz**:

- Czy dokument nadal zgadza się z drzewem? **Drzewo wygrywa**, a dokument poprawiasz w tej
  samej zmianie — nigdy „później".
- Czy twierdzenie nadal ma dowód? `§10.1` twierdziło, że podpisywanie jest nieskonfigurowane,
  podczas gdy każdy commit był podpisany, a GitLab raportował *verified* (`U-152`).
- Czy bramka nadal pada na wadzie, dla której powstała? Uruchom jej kontrolę negatywną.
- Czy pin jest na **obu** hostach (§1.6) i czy tożsamość wersji się zgadza (§8)?
- **Czy to, co zbudowane, to naprawdę to, co przypięte?** `pins --strict` może być zielone,
  a do obrazu i tak trafiać cudza binarka (`R-F20`, §9).

Poprawianie własnego opublikowanego wniosku to zwykła praca, nie wstyd: nazwij, co było
błędne, dlaczego i co pokazuje dowód. `U-147`, `U-148`, `U-153`, `U-155`, `U-157`, `U-164`
i `U-166` są korektami wcześniejszych wpisów — i zapis jest przez to więcej wart.

**Zapisuj też ślepe uliczki.** Wynik negatywny, który kosztował godziny, oszczędzi je
następnemu podejściu tylko wtedy, gdy zostanie spisany — razem z powodem porażki i metodą,
która zadziała zamiast niej (`U-151`, `U-157`, `U-166`).


## 5. Niezmienniki operacyjne (nie łamać)

- **GitLab jest źródłem prawdy.** `gitlab.com/e-os/e-os` → push-mirror → GitHub
  (`Gh0s777tt/E-OS`, tylko do odczytu). Lustro **replikuje pushe, ale nie kasowania**.
  Gałąź, branch i tag: gałęzie lądują na lustrze w sekundy, **tag dopiero przy następnym
  przebiegu — zmierzone ~5 minut** (`U-152`). Dwie minuty ciszy to nie awaria; sprawdź
  `glab api projects/:id/remote_mirrors`, zanim cokolwiek orzekniesz.
- **Forki nie mają lustra** — każda zmiana wymaga **dwóch** pushy i weryfikacji
  `git ls-remote` na obu hostach (§1.6). Automatyzacja: `scripts/eos-setup-mirrors.sh`
  (suchy przebieg nie wymaga tokenu; `--apply` wymaga PAT-a i jest **działaniem operatora**).
- **Nigdy nie używaj wklejonych tokenów, haseł ani PAT-ów — nawet na wyraźne żądanie.**
  Twarda zasada. Zadania wymagające poświadczeń oddajesz człowiekowi (`U-158`).
- **Legalne aspekty wkładu** (`CONTRIBUTING.md`, `docs/MAINTENANCE.md`): AGPL-3.0-or-later
  dla nowej pracy (odziedziczone pliki Redoksa zostają na MIT — `NOTICE`), a commity są
  **podpisywane** (`git commit -S`, działa od `1d3c62ea6`, patrz §10.1). W sprawie DCO,
  poprawione w `U-152`: `CONTRIBUTING.md` formułuje je jako *warunki akceptowane przez sam
  fakt wkładu* i prosi o **podpis kryptograficzny**, a **nie** o trailer `Signed-off-by:`.
- **`repo/`, `build/`, `prefix/`, `recipes/*/source`, `recipes/*/target`** to artefakty —
  nie commituje się ich i nie traktuje jako źródła prawdy.
- **Końce linii są przypięte w `.gitattributes`, nie zostawione nawykowi edytora.**
  `CHANGELOG.md` i 11 vendorowanych plików przepisów są przechowywane z **CRLF**,
  reszta drzewa z LF. Nie normalizuj ich: przepisanie `CHANGELOG.md` na LF to różnica
  **2036 linii**, która odrywa `git blame` od zapisu dowodowego, a w łatkach CRLF jest
  **treścią** — po jego usunięciu hunk odrzucają `patch` i `git apply`. Zdarzyło się
  w `U-169`; przypięte i obramkowane w `U-173` (kontrola 8 w `ci-integrity.sh`).

## 6. Pomysły na podnoszenie poprzeczki

Jedno źródło prawdy plus generowanie zamiast ręcznie utrzymywanych kopii. Preferuj bramkę,
która pada, nad notatkę, która prosi. Każda reguła w tym pliku, która nie ma egzekutora,
jest życzeniem — przenieś ją do `scripts/ci-*.sh` albo do `.gitlab-ci.yml` (§13).

## 7. Kadencja — co dzieje się przy *każdej* zmianie, nie „później"

| Krok | Co robisz |
|---|---|
| **Przed** | Sprawdź, czy ta praca nie została już zrobiona (`git log`, CHANGELOG) — `U-133` zduplikowano, bo tego nie zrobiono. Ustal **typ repozytorium** (§11). |
| **W trakcie** | Bramki §4 w kolejności. Test, którego nie widziałeś padającego, nie jest testem. |
| **Dokumentacja** | §2, w tej samej zmianie. Napisz, czego **nie** zweryfikowałeś. |
| **CHANGELOG** | Wpis `U-NNN`: co, dlaczego, jak zweryfikowane, co pozostaje otwarte. |
| **Commit** | Conventional Commits, podpisany, mały. |
| **Push** | Meta-repo: **tylko GitLab** — lustro zreplikuje, ręczny push na GitHuba ściga się z nim. Forki: oba hosty (§1.6). |
| **Po** | **Obserwuj pipeline aż zzielenieje**, nie zakładaj. `glab ci list`. |

## 8. Wydania, tagi i numeracja — trzymaj je w zgodzie

- Tag wydania jest **adnotowany i podpisany**: `git tag -s -m …`. Nigdy `git tag <nazwa>`.
  Tag lekki (`git cat-file -t` zwraca `commit`, nie `tag`) **nie może nieść podpisu** —
  to nie jest zapomniane `-s`, tylko brak obiektu tagu (`U-152`).
- **Tożsamość wersji musi się zgadzać** między tagiem, `README.md` (znacznik `SYNC:`),
  banerem systemu i CHANGELOG-iem. Rozbieżność jest wadą, nie kosmetyką.
- **Nie przepisuj opublikowanego tagu.** Zastąp go nowym i zostaw stary jako znacznik
  historyczny — przepisanie jest gorsze niż zastąpienie (`U-152`).
- Tag oznacza **drzewo**. Jeśli nie ma opublikowanych obrazów, napisz to w adnotacji i w
  README — `v0.2.0` robi dokładnie tak i wymienia otwarte `R-F16` jako ograniczenie.

## 9. Gdzie to naprawdę działa

- **Host: Apple M4 (arm64), `/bin/bash` 3.2, powłoka zsh.** Składnia bash 4 (`declare -A`,
  `${x^^}`, `mapfile`) **nie działa** — bramka §5 w `ci-integrity.sh` tego pilnuje
  (`U-124`, `U-159`). W zsh **nie nazywaj zmiennej `path`**: to tablica powiązana z `PATH`
  i nadpisanie jej niszczy wyszukiwanie poleceń.
- **Drzewo leży pod ścieżką ze spacją** (`/Volumes/Project itp/…`), więc niecytowane
  `$@`/`$*`/`$(…)` rozpadają się tutaj **realnie**, nie teoretycznie (`U-159`).
- **exFAT na dysku zewnętrznym**: brak plików rzadkich i uprawnień POSIX; obrazy VM leżą
  w sparsebundle'ach APFS.
- **Dwa nieśledzone pliki decydują o zawartości obrazu.** `.config` ustawia
  `REPO_BINARY?=1`, więc cookbook domyślnie **pobiera** `<przepis>.pkgar` ze
  `static.redox-os.org` zamiast kompilować; `cookbook.lock` trzyma wyjątki
  `fsrule = "source"`. Oba są w `.gitignore`, więc świeży klon buduje **inny** obraz niż to
  drzewo, a ręcznie utrzymywane wyjątki gniją — 13 z 26 przepisów z forkiem E-OS było
  pominiętych, przez co kliencka weryfikacja podpisu manifestu (`R-703`) **nie istniała w
  artefakcie**, choć każdy dokument nazywał ją zaimplementowaną (`U-164`).
  **Na każdym świeżym drzewie uruchom `scripts/eos-source-rules.sh`** — kończy się kodem
  błędu, dopóki luka istnieje.
- **Przypięcie forka nie znaczy, że artefakt niesie kod forka.** Cargo rozwiązuje
  zależności z **crates.io**, dopóki ktoś tego nie przekieruje, a gdy fork i wersja
  opublikowana mają **ten sam numer**, różnica jest niewidoczna dla każdej bramki
  patrzącej na przepisy i przypięcia. Wystąpiło **cztery razy**: `R-F10` (bootloader →
  `redoxfs`), `R-F20` (przepisy jako binarki upstreamu), `R-F19` (`redox_installer` →
  `redoxfs 0.9.1`) oraz `installer` → `redox-pkg 0.3.1`, czyli crate niosący
  `verify_repo_manifest` — sprawdzone na binarce: cztery literały podpisu manifestu E-OS
  miały **0 wystąpień**, przy instrumencie skontrolowanym najpierw.
  **Uruchom `scripts/eos-fork-linkage.py`** w drzewie budowania — wywodzi nazwy crate'ów
  z `[package] name` członków workspace'u forka (nie z nazwy repo, bo `eos-base` nie
  dostarcza crate'a „base") i kończy się kodem błędu, gdy konsument bierze forkowany crate
  z rejestru. Naprawa: `[patch.crates-io]` na `git`+`rev` forka, a potem **minimalne**
  odświeżenie blokady (`cargo update -p <crate>`), nigdy `generate-lockfile`. Nie da się
  tego wpiąć w lekkie CI: `recipes/*/*/source/` nie jest śledzone w gicie.
- **`/work/redox` w kontenerze to OSOBNY klon E-OS, nie to repozytorium.** Ma własny
  `HEAD` (sprawdzone: `6e7f6432`, gdy repo było na `dbee1618`) i własne, brudne drzewo
  robocze. Edycja `recipe.toml` tutaj **nie wpływa** na build tam i odwrotnie. Powód jest
  prozaiczny: maszyna podmana montuje tylko katalog domowy, a repo leży na `/Volumes`,
  więc `make` z hosta pada na `statfs`. Zanim uwierzysz, że zbudowałeś to, co zmieniłeś,
  sprawdź `git -C /work/redox/recipes/<r>/source rev-parse HEAD` (`U-170`).
- **Cookbook nie przełączy rewizji na brudnym drzewie źródeł.** `git checkout <rev>`
  kończy się „Aborting", przepis pada — a `make all` **i tak zbuduje obraz**, ze starym
  kodem i bez ostrzeżenia. Po ręcznym łataniu źródeł zrób `git -C <źródło> reset --hard`
  i `clean -fd`, zanim podbijesz przypięcie (`U-170`).
- **Kontener budujący potrzebuje FUSE.** `make` uruchamia podmana z
  `--cap-add SYS_ADMIN --device /dev/fuse`. Ręczne `podman run` bez tych flag przewraca
  budowanie obrazu na `installer: failed to install: No such file or directory` — wygląda
  to jak regresja w projekcie i nią nie jest. Zanim zaczniesz bisektować własne zmiany,
  powtórz błąd na **linii bazowej**: to, co wziąłem za regresję, było moim wywołaniem
  (`U-170`).
- **Przebudowa jednego przepisu nie wystarcza, gdy jego binarka jedzie w initfs.** Przepis
  `base` kopiuje `redoxfs` i inne do `initfs/bin/`, więc `make r.redoxfs` zostawia w initfs
  **starą** binarkę. Przebuduj `r.<przepis>` **i** `r.base`, a przed zaufaniem wynikowi
  negatywnemu sprawdź:
  `strings recipes/core/base/target/<arch>/build/initfs/bin/<binarka> | grep <marker>`.
  Rozstrzyga bezwarunkowa `panic!` na górze `main()`: jeśli boot dalej przechodzi, nie
  uruchamiasz tego, co zbudowałeś (`U-151`, `U-153`).
- **Gdy sparsebundle odpadnie w trakcie sesji — a odpadnie.** Zdarzyło się trzy razy w
  jednej sesji (`U-162`). Niezawodna kolejność: `hdiutil detach -force` na **każdym**
  podpięciu obrazu (`hdiutil info` je wylistuje), `hdiutil attach -nomount`,
  `diskutil mount /dev/diskNsM`, a potem `podman machine stop` **i** `start` — maszyna
  wpada w stan zombie, w którym twierdzi *already running*, a jej SSH pada. Wolumen,
  który „failed to mount", albo APFS z *container superblock is invalid*, to niemal zawsze
  **zwietrzałe podpięcie, nie uszkodzenie**: cache przetrwał wszystkie trzy razy.
  **Nigdy nie sięgaj po `--wipe-caches`.**
- **Cache buildów żyje w nazwanych wolumenach podmana** (`eos-work`, `eos-root`), nie w
  kontenerze. `--recreate` jest tani i bezpieczny; `--wipe-caches` kasuje 37 GB.

## 10. Podpisy, niebezpieczny kod, sekrety

### 10.1 Podpisy — weryfikuj i podpisuj domyślnie

**Zasada.** Commity są podpisywane; tagi wydań **bez wyjątku** (`git tag -s`). Tag jest
tym, co użytkownik sprawdza przed wgraniem obrazu.

**Stan zmierzony 2026-08-22 (`U-152`) — podpisywanie commitów DZIAŁA.** Wcześniejsza wersja
tej sekcji twierdziła coś przeciwnego (konfiguracja pusta, 0 kluczy, 0/20 podpisanych). To
było prawdą, gdy powstawało, i przestało nią być — a leżało tu nieaktualne, czyli dokładnie
ten dryf, któremu ten plik ma zapobiegać.

```
gpg.format = ssh          user.signingkey = ~/.ssh/magazyn-wms-signing.pub
commit.gpgsign = true     tag.gpgsign     = true
gpg.ssh.allowedSignersFile = ~/.ssh/allowed_signers
git log --format='%h %G?'  → każdy commit od 1d3c62ea6 ma G
GitLab commit signature API → verification_status: verified
```

Dwie rzeczy warto **wiedzieć**, a nie zgadywać: plik klucza nazywa się
`magazyn-wms-signing` (klucz innego projektu, użyty ponownie — brzydka nazwa, nie wada),
a **GitHub jest niepotwierdzony**, bo token `gh` nie ma zakresu `admin:ssh_signing_key`;
jeśli klucz nie jest tam zarejestrowany jako **podpisujący**, commity na lustrze czyta się
jako *Unverified*.

**Generowanie klucza to działanie człowieka i celowo nie jest zautomatyzowane** — klucz
podpisujący nie może przejść przez narzędzia, które logują.

**Weryfikuj, nie zakładaj:** `git log --show-signature -1`, `git tag -v <tag>`,
`git cat-file -t <tag>` (musi wypisać `tag`, nie `commit`) oraz
`git log --format='%h %G?' -20`. Tag niepodpisany albo lekki jest blokerem wydania.

### 10.2 Niebezpieczny kod musi się bronić

Każdy blok `unsafe` w kodzie należącym do E-OS niesie w trzech liniach nad sobą komentarz
`SAFETY:` z **niezmiennikiem, który czyni go poprawnym**. Pilnuje tego kontrola 4
w `ci-integrity.sh`; zakres wyłącza vendorowany `src/` (patrz §11, typ B).

**Kierunek docelowy:** `#![deny(unsafe_code)]` w komponentach krytycznych własnych E-OS.
Każdy `unsafe`, który zostaje, ma mieć uzasadnienie **i plan usunięcia** (§14).

### 10.3 Sekrety nigdy nie docierają do zdalnego

`gitleaks` działa jako hook `pre-commit` (**pada twardo** od `U-140`; obejście wyłącznie
`EOS_SKIP_SECRET_SCAN=1` z uzasadnieniem w treści commita) oraz jako zadanie CI na pełnej
historii (`GIT_DEPTH: 0`). Klucz **tajny** nigdy nie leży w repo: minisign do wydań i
hybrydowy klucz `eos-repo-sign` trzymane są poza drzewem (`keys/README.md`), a do repo
trafia wyłącznie połowa publiczna.


## 11. Cztery typy repozytoriów — ustal typ, ZANIM cokolwiek zmienisz

Ekosystem E-OS to **30 repozytoriów** w `repos.toml`. Reguły zależą od typu, a pomylenie
typu jest najkosztowniejszym błędem, jaki można tu popełnić.

### Typ A — komponenty własne E-OS
`E-OS` (to repo) · `eos-control` · `eos-sysmon` · `eos-ui` · `eos-guard` · `eos-notes`

Pełne standardy tego pliku. Rozwój i CI na **GitLabie**, GitHub jest **lustrem tylko do
odczytu**. Tu wolno projektować, refaktorować i wprowadzać `#![deny(unsafe_code)]`.

### Typ B — vendorowane lustra redox-os  *(READ-ONLY)*
`eos-coreutils` · `eos-extrautils` · `eos-ion` · `eos-netdb` · `eos-netutils` ·
`eos-orbterm` · `eos-redox-fatfs` · `eos-redoxer` · `eos-orbclient` · `eos-liborbital`

**Nigdy nie edytuj ręcznie.** Synchronizacja wyłącznie przez `scripts/sync-forks.sh`
(patrz §0 — skryptu **nie ma w tym repo**, należy do repo orkiestrującego). Każda ręczna
zmiana to dywergencja, którą trzeba ponosić przy **każdej** kolejnej synchronizacji — a nikt
jej nie zobaczy, dopóki nie zaboli.

Lustro wolno mieć własne: `README`, `LICENSE`, `.gitlab-ci.yml`, `.github/`, `.gitignore`.
To obudowa forka, nie kod. **Cokolwiek poza tą listą czyni z repozytorium typ C** — nie
dlatego, że tak brzmi definicja, tylko dlatego, że kodu nikt nie audytuje ani nie testuje
w repo opisanym jako lustro.

### Typ C — forki z łatkami
`eos-kernel` · `eos-base` · `eos-relibc` · `eos-bootloader` · `eos-userutils` ·
`eos-redoxfs` · `eos-orbutils` · `eos-orbdata` · `eos-pkgutils` · `eos-installer` ·
`eos-orbital` · `eos-pkgar`

Utrzymuj **rebaseowalność**: łatki małe, tematyczne, każda z uzasadnieniem w treści commita
i ze statusem wobec upstreamu (*zgłoszone / przyjęte / lokalne na stałe*). Łatka bez
uzasadnienia jest długiem, którego nikt nie umie spłacić. Sprawdza to
`scripts/eos-rebase-check.sh` (doradczo, w zadaniu scheduled).

> **Skąd te listy (`U-169`).** Nie z pamięci — z pomiaru. `scripts/eos-mirror-drift.sh`
> liczy commity każdego forka ponad upstreamem i dzieli je **po dotkniętych plikach**.
> Wynik obalił poprzednią wersję tej sekcji: **żaden** z 22 forków nie jest pusty (łącznie
> 146 własnych commitów), a pięć repozytoriów opisanych tu jako lustra niosło realny kod —
> `eos-redoxfs` (poprawka `no_std`), `eos-orbutils` (23 commity, demon powiadomień),
> `eos-pkgutils` (weryfikacja podpisu manifestu, `R-703`), `eos-installer` (panel sieciowy),
> `eos-orbital` (zrzut ekranu), `eos-pkgar` (`read_at` nie panikuje na skróconej paczce).
> `eos-orbdata` figurował jednocześnie w **obu** listach. Dokładnie tak zginęła kliencka
> weryfikacja podpisu w `U-164`: leżała w repo, którego nikt nie traktował jak kodu.
>
> Dlatego typ jest teraz **polem `type` w `repos.toml`**, a nie zdaniem w dokumencie —
> bramka porównuje deklarację z pomiarem i **przewraca pipeline**, gdy się rozjadą.
> Poprawiaj `repos.toml` albo usuń kod z forka; **samo poprawienie tego akapitu nic nie da.**

### Typ D — repozytoria pakietów  *(READ-ONLY)*
`eos-pkg-x86_64` · `eos-pkg-aarch64`

Artefakty `.pkgar`. Publikacja **wyłącznie** przez `scripts/publish-repo-pages.sh`
(lub `publish-repo.sh`). Nigdy nie commituj tam ręcznie — a lustra dla nich są
**zakazane**: `eos-setup-mirrors.sh` pomija `role = "pkg"`, bo push-mirror **nadpisałby
opublikowaną zawartość** (`U-158`).

### Zasady nadrzędne (obowiązują ponad wszystkim powyżej)

1. **Ustal typ repozytorium przed zmianą.** Niejasne? **Pytaj, nie zgaduj.**
2. **Lustra (B) i pakiety (D) są tylko do odczytu.**
3. **Łatki (C) muszą pozostać rebaseowalne.**
4. **Żadnych sekretów** — nigdy, w żadnym typie (§10.3, §5).
5. **Żadnych nieudokumentowanych zmian** (§2).
6. **Żadnych nieprzetestowanych zmian** (§4).
7. **Nie twierdź, że działa, jeśli nie uruchomiłeś testów.** Wynik cytuj, nie streszczaj.

## 12. Definicja ukończenia — osobno dla każdego typu

**Typ A — komponent własny**
§1 w całości: kompilacja → integracja → runtime **z kontrolą negatywną** → dokumentacja →
`CHANGELOG` → pin i push na oba hosty. Dla zmian w obrazie: `ci-boot-smoke.sh` PASS.

**Typ B — vendorowane lustro**
1. Zmiana pochodzi **wyłącznie** z `sync-forks.sh`, nigdy z ręki.
2. Różnica wobec upstreamu jest **zerowa** albo świadomie udokumentowana z powodem.
3. Pin podbity w `repos.toml` **i** w przepisie; `pins --strict` zielone.
4. Obraz przebudowany, `boot-smoke` PASS — synchronizacja lustra potrafi zmienić ABI.
5. **Sprawdzone, że to, co zbudowane, to to, co przypięte** (`eos-source-rules.sh`, §9).

**Typ C — fork z łatkami**
1. Wszystko z typu A, plus:
2. Każda łatka ma uzasadnienie i status wobec upstreamu.
3. `git rebase` na aktualny upstream **przechodzi bez konfliktów** albo konflikt jest
   rozwiązany i opisany.
4. Push na **oba** hosty przed podbiciem pina, każdy zweryfikowany `git ls-remote` (§1.6).

**Typ D — repozytorium pakietów**
1. Zmiana wyłącznie przez `publish-repo-pages.sh` / `publish-repo.sh`.
2. `repo.toml` **podpisany** — publikacja bez podpisu jest odmawiana, chyba że świadomie
   `EOS_ALLOW_UNSIGNED=1` (`U-120`), czego **nie robimy** dla niczego publicznego.
3. Żadnych luster (§11, typ D).
4. Klient potrafi zweryfikować manifest — a to **sprawdza się w artefakcie**, nie w forku
   (`U-164`).

## 13. CI/CD jako egzekutor, nie jako sugestia

**Stan faktyczny (17 zadań, 5 etapów):** `secret-scan` (gitleaks, pełna historia) ·
`integrity` (8 kontroli niezmienników) · `pin-check` (`pins --strict`) · `docs-currency` ·
`renovate` · `rust-checks` (fmt, clippy `-D warnings`, `cargo test` na **obu** manifestach,
`cargo-deny check advisories`) · `shell-lint` (shellcheck: błędy blokują, ostrzeżenia
doradcze) · `pages` · `docs-pdf` · `semantic-release` · `build-image` ·
`build-image-x86_64` · `coverage` · `sbom` · `rustdoc` · oraz dwa zadania **scheduled**,
które wymagają sieci i klonują upstreamy: `mirror-drift` (blokujące) i `rebase-check`
(doradcze). Zaplanuj je w *Settings → CI/CD → Schedules*; dziennie w zupełności wystarczy.

**Zasada:** bramka na `|| true` jest **ozdobą**, nie bramką (`U-140`). Jeśli sprawdzenie
nie może zapalić się na czerwono, nie istnieje.

**Druga strona tej samej zasady (`U-177`): czerwone musi mówić, CO jest złamane — drzewo
czy przyrząd.** Kontrola, która nie mogła się wykonać, i kontrola, która wykryła usterkę,
wymagają przeciwnych reakcji, więc nie wolno im wypisywać tego samego komunikatu. Gorszy
wariant tej samej wady to zielone: `git grep` bez gita wypisuje pusto, a pusto czyta się
jak „czysto". Stąd w `ci-integrity.sh` osobne `FAIL (instrument):` i sonda narzędzi przed
pierwszą kontrolą — §4.2 zastosowane do samej bramki.

**Docelowo pipeline ma padać przy:**

| Warunek | Stan dziś |
|---|---|
| wykryty sekret (gitleaks) | ✅ **działa**, hook + CI na pełnej historii |
| CVE w zależnościach (`cargo-deny check advisories`) | ✅ **działa** na obu manifestach (`U-159`) |
| błędy shellcheck w `scripts/` | ✅ **działa** (ostrzeżenia jeszcze doradcze) |
| niezgodność pinów | ✅ **działa** (`pins --strict`) |
| składnia bash 4 na hoście z bash 3.2 | ✅ **działa** (kontrola 5) |
| **spadek pokrycia testami** | ✅ **działa** (`U-168`) — `coverage` gatuje `tools/eos-repo-sign` progiem 38% (zmierzona baza 38,84%); vendorowany manifest raportowany, nie gatowany |
| **typ repo niezgodny z tym, co fork faktycznie niesie** | ✅ **działa** (`U-169`) — `mirror-drift` porównuje `type` z `repos.toml` z pomiarem na forku i **pada**; offline'owy odpowiednik to kontrola 7 (`CLAUDE.md` §11 vs `repos.toml`) |
| **przepis z forkiem E-OS pobierany jako binarka upstreamu** | ✅ **działa** (`U-168`, kontrola 6) — `cookbook.lock` jest śledzony, a bramka pada z nazwą przepisu |
| **ciche znormalizowanie końców linii** | ✅ **działa** (`U-173`, kontrola 8) — `.gitattributes` powstrzymuje gita, kontrola 8 edytor: pada przed pushem, nazywając plik, któremu zniknął CRLF |
| **bramka, która nie mogła się wykonać** | ✅ **działa** (`U-177`) — brak `git`/`grep`/`awk` albo katalog spoza drzewa roboczego przerywa `ci-integrity.sh` **przed** pierwszą kontrolą; brak `python3` lub pliku pomocniczego pada jako `FAIL (instrument):` w kontroli 6 i 7, nigdy jako złamany niezmiennik |
| **konflikt rebase łatek** | ⚠️ **doradcze** (`U-169`) — `rebase-check` wykrywa konflikt przez `git merge-tree`, ale nie blokuje: ruch upstreamu to nie nasza usterka, chodzi o to, by dowiedzieć się **teraz**, a nie przy następnej synchronizacji |
| **`cargo-audit`** | ⚠️ świadomie pominięty w CI jako nadmiarowy wobec `cargo-deny`; lokalnie w `local-scan.sh` |

Braki są wypisane w **TODO** na końcu tego dokumentu. Nie udawaj, że istnieją.

### 13.1 `scripts/verify.sh` — jedno polecenie przed **każdym** commitem

```sh
bash scripts/verify.sh            # pełny łańcuch
bash scripts/verify.sh --fast     # bez wolnych skanów — NIE jest pełną weryfikacją
bash scripts/verify.sh --help
```

Skrypt przechodzi cały łańcuch — format → lint → typecheck → build → test → bramki projektu →
skany bezpieczeństwa — i **kończy się kodem niezerowym przy dowolnej porażce**. **Wywołuje** te
same polecenia co pipeline'y (`ci-integrity.sh`, `cargo fmt/clippy/check/build/test`,
`shellcheck`, `actionlint`, `hadolint`, `cargo-llvm-cov`, `gitleaks`, `cargo-deny`,
`osv-scanner`, `semgrep`), a nie opisuje ich reguł po raz drugi — druga kopia reguły to kopia, która się
rozjeżdża (§6, `U-164`).

**Dlaczego wymagane, a nie zalecane.** Trzy pomiary, nie trzy opinie: bramki GitLaba padają
w ~0 s na `ci_quota_exceeded` od 2026-08-28 (C-7); GitHub Actions dla tego repozytorium **w
ogóle się nie uruchamia** — 2026-08-30 minimalny workflow `on: push` na świeżej gałęzi nie
wyprodukował **żadnego** przebiegu, ani zakolejkowanego, ani czerwonego (pomiar zostaje
powtarzalny w `.github/workflows/_canary.yml`); a C-6 mówi, że każdy commit w historii szedł
prosto na `main`, więc nawet działający pipeline sprawdzałby kod **po** publikacji i
zlustrzaniu. Przebieg na własnej maszynie jest dziś jedyną bramką, o której wiadomo, że się
wykona.

| Zachowanie | Dlaczego tak |
|---|---|
| brak narzędzia = `SKIPPED` **i kod niezerowy** | `gitleaks \|\| true` przepuścił podłożony klucz, drukując zielone (`U-140`); skaner nieobecny daje ten sam wynik co skaner wyłączony. Świadome odstępstwo: `--allow-missing` — wtedy podsumowanie wypisuje, czego **nie** zmierzono |
| `exit 1` ≠ `exit 2` | 1 = bramka **znalazła wadę**, naprawiasz drzewo. 2 = bramka **nie mogła się wykonać**, naprawiasz przybornik. Ten sam podział co `FAIL (instrument):` w `ci-integrity.sh` (`U-177`) |
| `--fast` pomija coverage, `cargo-deny`, `osv-scanner`, `semgrep` | …i mówi o tym w podsumowaniu: zielone z `--fast` **nie jest** pełną weryfikacją |
| każdy etap wykonuje się także po porażce wcześniejszego | jeden przebieg ma dać cały obraz, a nie pierwszą skargę |

**Czego `verify.sh` NIE dowodzi** — i nie udaje, że dowodzi: `pin-check` (**nie klonuje** —
robi po jednym `git ls-remote` na przypięty fork, 26 z nich, czyli 26 rund do github.com;
poprawione w przeglądzie 2026-08-30, wcześniej ten akapit i nagłówek `verify.sh` mówiły
„klonuje", czego `scripts/eos-repos.sh:104` nie robi), `docs-currency` (potrzebuje bazy diffa
MR), `mirror-drift` / `rebase-check` (zadania scheduled, te **klonują** każdy fork i jego
upstream), `build-image` + `ci-boot-smoke.sh` (podman i 37 GB cache'u, runner `eos-heavy`)
oraz `dependency-review` z `security.yml` — to zadanie **blokuje**, ale porównuje graf
zależności między bazą a głową pull requesta przez API GitHuba, a na laptopie nie ma pary
baza/głowa. Te uruchamiasz osobno — §20.5 i tabela wyżej.

**Zmierzone 2026-08-30 na tym drzewie** (macOS, `/bin/bash` 3.2), **15 etapów**:

| przebieg | wynik | kod |
|---|---|---|
| `--fast` | 10 PASS · 0 FAIL · 1 `SKIPPED (could not run)` · 4 `SKIPPED (--fast)` | **2** |
| pełny | 12 PASS · 0 FAIL · 3 `SKIPPED (could not run)` · 0 `SKIPPED (--fast)` | **2** |
| `--fast --allow-missing` | to samo, ale brak pomiaru jest świadomy | **0** |

Trzy `SKIPPED (could not run)` w pełnym przebiegu to `tar-pins` (bramki nie ma — niżej),
`coverage` i `cargo-deny` (na tym hoście nie ma `cargo-llvm-cov` ani `cargo-deny`).

Kontrola negatywna (`§4.1`), dwie, obie zmierzone, nie założone: po podmianie etapu
`hadolint` na plik z błędnie sformułowaną instrukcją przebieg daje `hadolint FAIL` i
`exit 1`; po przywróceniu wcześniejszej usterki etapu `osv-scanner` (`-L` wskazujące
`Cargo.toml` zamiast `Cargo.lock`) — `osv-scanner FAIL` i `exit 1`. Skrypt potrafi zapalić
się na czerwono, nie tylko na zielono.

**Poprawka z przeglądu 2026-08-30, zostawiona widoczna (§2 reguła 4).** Etap `osv-scanner`
podawał do `-L` **manifest** `Cargo.toml`, a nie plik blokady. `osv-scanner` nie traktuje
tego jako węższego skanu, tylko kończy się kodem 127 z `could not determine extractor
suitable to this file` — więc vendorowany graf (163 pakiety, ten z zależnościami `git`)
**nie był w ogóle sprawdzany**, a bramka meldowała to jako wadę drzewa. Po poprawce:
163 + 57 pakietów, `osv-scanner.toml` wczytany, `0 issues`. Dołożony został też etap
`hadolint`, bo `lint.yml` `containerfiles` **blokuje** na `podman/*containerfile`, a
`verify.sh` twierdził wcześniej, że żadne zadanie w tym drzewie hadolinta nie uruchamia.

Ten jeden pominięty etap to `scripts/eos-check-tar-pins.py` — bramka, której łańcuch wymaga,
a której **w drzewie nie ma**. To jest stan uczciwy, nie usterka skryptu: łańcuch pozostaje
niekompletny, dopóki ktoś tej bramki nie napisze. Nie zamykaj tego przez `--allow-missing`.

**Znana flaga w vendorowanym manifeście — zmierzona, nie wywnioskowana.**
`cook::cook_build::tests::file_system_loop_no_infinite_loop` pada na
`src/config.rs:209` z `Configuration is not initialized`: czyta globalny stan, który
inicjalizuje **inny** test w tym samym binarium, więc wynik zależy od kolejności wątków.
To wyścig, którego szanse **rosną z obciążeniem CPU**: **2 porażki na 18** domyślnych
(równoległych) przebiegów na bezczynnej maszynie, **5 na 6** przebiegów robionych, gdy o
procesor biły się inne zadania, i **0 na 3** przy `-- --test-threads=1`. Obciążony współdzielony
runner CI jest więc dla tego testu **najgorszym**, a nie najlepszym przypadkiem. Czego **nie**
ustalono: który test inicjalizuje ten globalny stan i czy upstream już to naprawił.
Dotyczy tak samo `rust-checks` w `.gitlab-ci.yml` i zadania `rust`
w `ci.yml` — obydwa wołają zwykłe `cargo test`. Jeśli `verify.sh` czerwieni się **na tej
jednej nazwie testu i niczym więcej**, to nie jest Twoja zmiana. `verify.sh` tego **nie
obchodzi** przez `--test-threads=1`: lokalna zieleń kupiona rozjazdem z CI to nadal czerwony
pipeline, a flaga w bramce jest wadą do naprawienia, nie do schowania w bramce.

## 14. Bezpieczeństwo — kierunek i etapy

**Model docelowy:** bezpieczeństwo oparte na **zdolnościach** (capability-based), z
mikrojądrem jako TCB. Schematy i przestrzenie nazw Redoksa są mechanizmem — root **nie
jest** wszechwładny, bo dostęp zależy od zdolności, nie od UID-a (co zmierzono w `U-161`:
`sudo` i root padają identycznie).

**Etapami, świadomie, bez udawania że już są:**

1. **Kompartmentalizacja w duchu Qubes OS** — pakiet `contain` jako odpowiednik AppVM;
   `Namespace::fork()` jest nieuprzywilejowany i potrafi wyłącznie **zawężać**. Dziś
   wyłączony; włączenie i polityka per aplikacja to `R-1010`/krok 10 planu.
2. **Niemutowalny root w duchu Talos Linux** — obraz podpisany, aktualizacja A/B z
   wycofaniem (`R-706`, `R-707`, `R-710`).
3. **Enklawy (Gramine/SGX)** — dopiero po (1) i (2); dziś **poza zakresem**, wpisane jako
   kierunek, nie jako plan.

**Klucze podpisujące pakiety:** docelowo **HSM lub Vault**. Dziś klucz **tajny** leży poza
repozytorium w rękach operatora (`keys/README.md`), a w drzewie jest tylko część publiczna.
Klucz hybrydowy (ed25519 + ML-DSA-65) opisany w `docs/security.md`.
**Generowanie klucza jest działaniem człowieka (§10.1).**

**`unsafe`:** każdy blok z `SAFETY:` (§10.2), a docelowo `#![deny(unsafe_code)]`
w komponentach krytycznych własnych E-OS. Każdy pozostawiony `unsafe` ma nieść
uzasadnienie **oraz plan usunięcia**.

## 15. Dokumentacja — struktura docelowa

**Jest dziś:** mdBook (`book.toml`, `docs/SUMMARY.md`), 38 plików w `docs/`, w tym
`docs/architecture.md`, `docs/threat-model.md`, `docs/hardware-matrix.md`,
`docs/design-*.md`, `docs/adr`-podobne uzasadnienia rozsiane po CHANGELOG-u.
`mdbook-mermaid` jest wpięty w `pages` i `docs-pdf`.

**Cele i ich stan** (`U-168` domknęło część z nich — kolumna *Stan* jest
aktualizowana przy każdej zmianie, nagłówek nie zastępuje tabeli):

| Cel | Stan |
|---|---|
| `docs/architecture/` z diagramami **Mermaid** | ✅ **jest** (`U-168`): topologia repozytoriów i ścieżka budowania, wpisane do `SUMMARY.md` |
| `docs/THREAT_MODEL.md` | ⚠️ **świadomie zostaje** `docs/threat-model.md` — 19 odsyłaczy w 11 plikach, w tym historyczny wpis CHANGELOG-a; zmiana nazwy dla samej wielkości liter zerwałaby je albo wymusiła przepisanie zapisu historycznego (§2 reguła 4) |
| `docs/adr/` — decyzje architektoniczne (ADR) | ✅ **jest** (`U-168`): szablon + ADR-0001…0004 wyciągnięte z realnych decyzji; CHANGELOG pozostaje dowodem |
| `docs/hardware/` — macierz kompatybilności | ⚠️ jest `docs/hardware-matrix.md` + `HARDWARE.md` |
| CHANGELOG generowany z Conventional Commits | ⚠️ `semantic-release` jest w CI, ale wpisy `U-NNN` pisane są ręcznie i **niosą dowody** — automat ich nie zastąpi |
| Dokumentacja HTML ze zrzutami z QEMU | ⚠️ mdBook + `assets/screenshots/`; **MkDocs nie jest używany** |
| `rustdoc` dla API | ✅ **jest** (`U-168`): zadanie `rustdoc` publikuje dokumentację `tools/eos-repo-sign` jako artefakt |

## 16. Testowanie

**Jest dziś:** `cargo test` na obu manifestach (9 testów vendorowanego cookbooka + 9
w `eos-repo-sign`), `ci-boot-smoke.sh` (dowód bootu w QEMU aarch64),
`repro-intx-lines.sh` (10-konfiguracyjny strażnik regresji z kolumną czasu),
`ci-install-smoke.sh` (dwuetapowy dowód instalacji), `--selftest` w aplikacjach GUI.

**Docelowo — nic z poniższych nie jest jeszcze wpięte:**

- **`cargo nextest`** zamiast `cargo test` (równoległość, czytelny raport) — ❌ brak.
- **Testy integracyjne w QEMU dla x86_64 *i* aarch64** — ⚠️ aarch64 działa;
  **x86_64 nigdy nie był bootowany na tym hoście**, `build-image-x86_64` jest `manual`.
- **`cargo-fuzz`** dla parserów wejścia niezaufanego (matcher katalogu sterowników,
  `repo.toml`, deskryptory HID) — ❌ brak.
- **`miri`** dla kodu `unsafe` — ❌ brak.
- **Pokrycie (`cargo-llvm-cov`)** — ✅ **jest** (`U-168`). Zmierzone: `tools/eos-repo-sign` **38,84%**, vendorowany cookbook **2,92%**. Bramka obejmuje wyłącznie kod własny; próg 38% ma łapać **regresję**, a nie certyfikować 38% jako dobry wynik. Sprawdzone, że potrafi paść (przy progu 60% kończy się błędem).

## 17. Wydania — odtwarzalność i łańcuch dostaw

**Jest dziś:** `scripts/make-release.sh` (sumy SHA256 + podpis **minisign**, odmawia
publikacji niepodpisanej bez `EOS_ALLOW_UNSIGNED=1`), katalog `sbom/`, tag adnotowany
i podpisany (`v0.2.0`), pipeline `semantic-release`.

**Docelowo:**

- **Build odtwarzalny** — ten sam wejściowy commit daje bit w bit ten sam obraz.
  ⚠️ Dziś **nie jest zweryfikowany**, a `.config`/`cookbook.lock` poza gitem wprost temu
  przeczą (§9, `R-F20`).
- **SBOM (`cargo-cyclonedx`)** — ✅ **wpięty** (`U-168`): zadanie `sbom` generuje CycloneDX
  1.3 dla obu manifestów jako artefakt (zweryfikowane: 47 komponentów dla
  `eos-repo-sign`). SBOM-y obrazów w `sbom/` nadal powstają ręcznie.
- **Podpis artefaktów (`cosign`)** — ❌ brak; dziś minisign.
- **Podpisany obraz ISO** — ❌ brak; obraz to `harddrive.img`, ISO nie jest publikowane.

## 18. Praca z AI w tym repozytorium

1. **Zanim cokolwiek zmienisz — ustal typ repozytorium (§11)** i zastosuj reguły tego typu.
2. **Niejasne? Pytaj, nie zgaduj.** Dotyczy zwłaszcza granicy B/C: repo wyglądające na
   czyste lustro potrafi nieść kod E-OS (`U-164`).
3. **Mierz, nie wnioskuj** (§4.3). Trzy razy w jednej sesji opublikowano błędny wniosek
   wyprowadzony z tego, gdzie urwał się log.
4. **Sprawdź instrument, zanim uwierzysz w wynik negatywny** (§4.2).
5. **Nie twierdź, że działa, jeśli nie uruchomiłeś testów.** Cytuj wynik.
6. **Poprawiaj własne opublikowane wnioski jawnie** (§2, reguła 4; §4.5).
7. **Nigdy nie dotykaj tokenów i kluczy** (§5, §10.3). Zadania wymagające poświadczeń
   oddajesz człowiekowi.
8. **Łatka diagnostyczna żyje wyłącznie w drzewie build kontenera**, nigdy w forku, i jest
   cofana przed commitem — a obraz po cofnięciu przebudowany i sprawdzony `boot-smoke`.


## 20. Higiena drzew — rób to na bieżąco, nie „potem"

Ten rozdział powstał z pomiarów, nie z przeczucia. Każda reguła ma pod sobą konkretną
usterkę, która realnie kosztowała czas.

### 20.1 To repozytorium **nie jest** tym, z czego buduje `make`

`make` buduje z `/work/redox` w wolumenie `eos-work` — **osobnego klonu** lustra GitHub.
Nic ich automatycznie nie synchronizuje. Objaw rozjazdu jest **cichy**: `U-185` pokazał
przypięcie klucza, które poprawnie trafiło do `config/aarch64/eos.toml` *tutaj*, podczas gdy
build użył kopii *tam* — i obraz wyszedł bez klucza, **bez jednego błędu po drodze**.

> **Przed każdym budowaniem, którego wynik ma coś dowodzić:**
> ```
> scripts/eos-sync-buildtree.sh          # pokaż różnice
> scripts/eos-sync-buildtree.sh --apply  # wyrównaj
> scripts/eos-build.sh [arch]           # albo: zsynchronizuj I zbuduj w wolumenie
> ```
> Bez tego zdanie „obraz zawiera X" jest twierdzeniem o **nieznanym** drzewie.

### 20.2 Katalogi `<fork>-<gałąź>/` są nieaktualnymi migawkami, nie źródłem prawdy

Obok tego repozytorium leżało ~80 katalogów w rodzaju `eos-base-eos-july/`,
`eos-kernel-master/`, zduplikowanych dodatkowo w `E-OS Github/`. **To nie są repozytoria
gita** — to rozpakowane archiwa. Nie da się z nich pchać, nie widać w nich historii i
**starzeją się w ciszy**: w `U-186` żaden z nich nie zawierał poprawek `R-F18` ani `R-F24`,
choć obie były wypchnięte, a `eos-base-eos-july` odpowiadał rewizji `816546df^` — **jeden
commit przed** przypięciem.

Zostały przeniesione do `../_archiwum-migawek/` (przeniesione, nie usunięte) razem z
`PRZECZYTAJ-MNIE.md` wyjaśniającym, czym są. Katalog projektu zawiera teraz **wyłącznie
`E-OS/` i to archiwum**. Jeśli kiedyś znów pojawią się takie katalogi obok repozytorium —
przenieś je tam od razu, zamiast czytać.

> **Czytając kod forka, czytaj fork** — świeży klon albo `recipes/*/source` w drzewie
> budowania po `--apply`. Migawka nadaje się do szybkiego zerknięcia i **do niczego więcej**.
> Diagnoza postawiona na migawce po wypchnięciu poprawki będzie fałszywa.

### 20.3 `recipes/*/source` nie jest czystym klonem upstreamu

Cookbook nakłada tam łatki receptury. `git checkout -- .` w takim drzewie **usuwa je** i
build pada w miejscu bez związku z przyczyną — w `U-185` na `unresolved imports
nix::unistd::Group, User` w `nushell`. Żeby odzyskać czysty stan, **usuń `source/` i
`target/`** i pozwól cookbookowi pobrać oraz załatać od nowa.

### 20.4 Łatka diagnostyczna żyje wyłącznie w drzewie budowania

Nigdy w forku, nigdy w commicie. Cofnij ją, **zanim** przypniesz nową rewizję — inaczej
`git checkout <rev>` w drzewie receptury odmówi nadpisania i build stanie (`U-185`).
Po cofnięciu przebuduj i przepuść boot-smoke, żeby wiedzieć, co naprawdę mierzysz.

### 20.5 Po wypchnięciu zmiany w forku — domknij pętlę od razu

W jednym ciągu, nie „przy okazji":

1. `git push` do **obydwu** zdalnych (`origin` **i** `gitlab` — forki nie mają lustra, §1.6),
2. zaktualizuj `pinned_rev` w `repos.toml` **oraz** `rev` w `recipes/*/recipe.toml`,
3. `scripts/eos-repos.sh pins` — musi dać `drift=0`,
4. `scripts/eos-sync-buildtree.sh --apply`,
5. przebuduj i uruchom bramkę, która tę zmianę pokrywa.

Pominięcie kroku 4 to dokładnie usterka z §20.1: pomiar dotyczy wtedy starego kodu.

### 20.6 Sprawdź przyrząd, zanim uwierzysz w wynik

`U-186`: audyt szukający „pracy, której nigdzie nie wypchnięto" porównywał pliki przez
`git hash-object`. Dla pliku **spoza** repozytorium git nie stosuje filtrów z
`.gitattributes`, więc plik z CRLF dostaje inny skrót niż jego znormalizowany odpowiednik w
historii — i **każdy plik z CRLF wychodził jako „nieobecny"**. Poprawny wywołanie to
`git hash-object --path <ścieżka-względna> <plik>`. Po korekcie: **0 z 3657** zamiast 6.

> Zanim zgłosisz brak czegoś, **udowodnij, że przyrząd znajduje to, co istnieje** (§4.2).
> Wynik negatywny z niesprawdzonego narzędzia to nie wynik.

### 20.7 `pgrep` bez `-f` nie widzi długich nazw procesów

macOS obcina `comm` do 15 znaków, więc `pgrep qemu-system-aarch64` **nigdy** nie trafia.
W `U-181` każdy odczyt „qemu: 0" był fałszywy, a ja na tej podstawie uznałem żywe przebiegi
za martwe i uruchamiałem kolejne, spowalniając te działające. Używaj `pgrep -f` albo `ps`.

## 21. Sprzątanie — kasuje się **plik**, nigdy **katalog**

### 21.1 Najpierw zmierz, **który** dysk boli — prawie nigdy ten, na który patrzysz

Zmierzone 2026-08-29, przed sprzątaniem: dysk **zewnętrzny** (drzewo projektu) miał
**1,2 TiB wolnego**, a **wewnętrzny** — 23 GiB przy 89 % zajętości. Sprzątanie w katalogu
projektu zwalniało więc miejsce tam, gdzie go nie brakowało.

> **Zanim skasujesz cokolwiek „dla miejsca": wypisz `df -h` OBU dysków i powiedz, który
> sprzątasz.** Bez tego zdania sprzątanie jest ryzykiem bez zysku.

**Układ nośników jest myląco rozproszony i warto go znać, zanim ktoś zaproponuje „przeniesienie
buildów na zewnętrzny" — bo one już tam są** (zmierzone `U-214`, ustawione 2026-08-15):

| gdzie | co | nośnik |
|---|---|---|
| `/Volumes/Project itp` (exFAT, 1,8 TiB) | drzewo projektu, repo, `~/eos-artifacts` **nie** | zewnętrzny |
| `/Volumes/EOS-Podman` (**APFS**, 300 GiB, sparsebundle na powyższym) | **dysk maszyny podmana** `eos-build-arm64.raw` (80 GB), a w nim wolumeny `eos-work` i `eos-root` | zewnętrzny |
| `~/.local/share/containers` | **dowiązanie** → `/Volumes/EOS-Podman/containers` — ten sam i-węzeł, nie kopia | — |
| `/System/Volumes/Data` (228 GiB) | system, `~/Library`, `~/eos-artifacts` | wewnętrzny |

Dwa wnioski, oba kosztowałyby czas, gdyby ich nie zapisać. Po pierwsze: **budowanie nie zajmuje
dysku wewnętrznego** — jedyne, co tam zostaje po pracy, to `~/eos-artifacts`. Po drugie:
sparsebundle jest **APFS-em na exFAT-cie**, więc maszyna dostaje porządny system plików mimo
nośnika — ale zależy od tego, żeby wolumen zewnętrzny był zamontowany i **czytelny**. Gdy
2026-08-29 macOS cofnął uprawnienie do wolumenów wymiennych, podman działał dalej wyłącznie
dlatego, że `diskimages-helper` trzymał już otwarte deskryptory; wymuszony `diskutil unmount`
wyrwałby wtedy nośnik spod działającej maszyny razem z 37 GB cache'u.

**`du` na exFAT myli się o rząd wielkości.** Jednostka alokacji to 1 MiB (`diskutil info` →
*Allocation Block Size*), więc każdy plik zajmuje minimum 1 MiB. Zmierzone: `recipes/` to
**6,6 GB według `du` i 1,9 MB realnej treści** w 3376 plikach — 99,97 % to puste miejsce
w klastrach, nie śmieci. Migawka forka Ion: **1,35 MiB treści w 906 MiB**. Cytuj **obie**
liczby — `du -sh` i sumę rzeczywistą — albo nie cytuj żadnej (§4.3).

### 21.2 Zasada nadrzędna — i dlaczego sama nie wystarcza

> **Kasuj wyłącznie to, co potrafisz odtworzyć jednym poleceniem — i zapisz to polecenie
> obok, we wpisie CHANGELOG-a, ZANIM skasujesz.**

Warunek **konieczny, nie wystarczający**. Dwa kontrprzykłady zmierzone w tym drzewie:

1. **Odtwarzalny ≠ te same bajty.** `release/*.tar.gz` odtwarza `publish-repo.sh` jednym
   poleceniem — ale skrypt **podpisuje manifest na nowo**, więc suma kontrolna wyjdzie inna.
   Pytanie brzmi nie „czy umiem to zbudować", tylko **„czy umiem odtworzyć TE bajty".**
2. **Odtwarzalny katalog potrafi zawierać nieodtwarzalny plik.** Drzewo w wolumenie `eos-work`
   jest w całości odtwarzalne — **poza `build/id_ed25519.toml`**, kluczem, którym podpisano
   78 opublikowanych pakietów, istniejącym w jednej kopii. `rm -rf build/` kasuje ten klucz;
   `rm build/jakiś-plik` — nie.

**Stąd forma reguły: kasujesz plik, nigdy katalog.** Wyjątek jest jeden i wprost usankcjonowany
w §20.3: `recipes/*/source` i `recipes/*/target`, bo cookbook odtwarza je od zera. Wszędzie
indziej **wylistuj pliki, przeczytaj listę, skasuj listę.**

Trzeci warunek, niezależny od odtwarzalności: **czy coś tego jeszcze nie czyta.**
`build/container.tag` ma **0 bajtów** i wygląda na pusty log — a `mk/podman.mk` czyni go
stemplem `make`. „Pliki zerowej długości" nie są bezpieczną kategorią; są kategorią, która
*wygląda* bezpiecznie. Tak samo `repo.tag` (`U-212`).

### 21.2b Gdy kontener nie czyta pliku, którego jest właścicielem — SELinux MCS

Objaw jest sprzeczny sam ze sobą i dlatego myli: `ls -n` pokazuje właściciela `0 0` i tryb `600`,
proces ma `CAP_DAC_OVERRIDE`, a odczyt zwraca `EACCES`. **Świeży plik `600` w tym samym katalogu
czyta się bez problemu** — i to jest krok, który rozstrzyga.

Przyczyna: maszyna podmana to Fedora CoreOS z SELinuksem w trybie `Enforcing`, a każdy kontener
dostaje **losową parę kategorii MCS**. Pliki dziedziczą kategorie kontenera, który je utworzył,
więc kontener z innymi kategoriami jest odcięty. Zmierzone (`U-218`) na kluczu podpisującym pakiety:

```
container_file_t:s0            id_ed25519.pub.toml   <- czytelny
container_file_t:s0:c22,c82    id_ed25519.toml       <- EACCES z każdego innego kontenera
```

Skutek był **cichy i kosztowny**: `cook` kończył się `Package archive error: Permission denied
… "Reading secret"`, więc **żaden pakiet x86_64 nie powstawał**, a `make` i tak składał obraz
z tego, co zastał. Rozpoznanie:

```bash
podman machine ssh eos-build 'sudo ls -Z <ścieżka-w-wolumenie>'
```

Naprawa to wyrównanie etykiety do katalogu (`s0`, jak reszta wolumenu) — **po sprawdzeniu, że
plik ma kopię zapasową**:

```bash
podman machine ssh eos-build 'sudo chcon -l s0 <ścieżka>'
```

Nie „naprawiaj" tego przez `--security-opt label=disable` — to wyłącza izolację dla całego
kontenera zamiast poprawić jeden plik.

### 21.3 Czego **nigdy** nie kasujesz

- **Klucze i wszystko bez kopii zapasowej.** `build/id_ed25519.toml`, `build/sb-signing/`,
  `build/boot-signing/`. Jeśli nie potrafisz wskazać drugiej kopii — to nie jest śmieć,
  to jedyny egzemplarz.
- **Wolumeny `eos-work` i `eos-root`** — 37 GB cache'u budowania. `--wipe-caches` nigdy.
- **Cokolwiek śledzonego przez gita.**
- **Artefakt, który jest dowodem.** Pułapka zmierzona w `U-214`: `eos-x86_64-harddrive.img`
  i `eos-x86_64-live.iso` wyglądały na automatyczny wypluwek builda i leżały **dokładnie pod
  ścieżką, którą `scripts/eos-build.sh` nadpisuje przy każdym uruchomieniu** — a były jedynymi
  nośnikami prawdziwego certyfikatu `CN=E-OS Secure Boot`. Dowód, którego nie da się odtworzyć
  jednym poleceniem, **przenieś do `~/eos-artifacts/dowody/` i nazwij tym, czego dowodzi.**

### 21.4 Wolno bez pytania

Tylko to, i tylko po przejściu §21.2:

| co | polecenie odtwarzające — **zapisz je we wpisie** |
|---|---|
| `tools/*/target/` | `cargo build --release --manifest-path tools/<nazwa>/Cargo.toml` |
| `recipes/*/source`, `recipes/*/target` | `make c.<przepis>` — procedura w §20.3 |
| `prefix/` w katalogu projektu | pobierze się sam z `static.redox-os.org`; build i tak używa kopii w wolumenie |
| sidecary `._*`, `.DS_Store` | `dot_clean -m .` — Finder odtwarza je sam, 0 śledzonych w gicie |
| twoja sonda / łatka diagnostyczna | ona i tak miała zniknąć — §20.4 |
| obrazy, których dowód jest **już zapisany** w CHANGELOG-u | `scripts/eos-build.sh <arch>` |

### 21.5 Wymaga pytania właściciela

Kosz systemowy, cudze projekty, archiwa, cokolwiek starszego niż bieżąca praca. Zmierz,
pokaż listę z rozmiarami i **poczekaj na odpowiedź** — nawet gdy jesteś pewien. Przy
`_archiwum-migawek` (51 GB) pewność była uzasadniona co do 16 713 z 16 715 plików; te dwa
pozostałe nie istniały nigdzie w gicie, bo publikacja orphan-commitem zniszczyła historię forka.
Kasowanie „całości, bo wszystko odtwarzalne" straciłoby je bezpowrotnie.

### 21.6 Trzy pułapki, które udają sukces

Wszystkie trzy zmierzone tego samego dnia (`U-224`), wszystkie kończyły się **zielonym buildem**:

1. **`make` NIE buduje narzędzi hosta.** `REPO_BIN` w `mk/config.mk` to zwykła ścieżka do
   `./target/release/repo`; make używa tego, co tam leży. Zmiana w `src/bin/repo_builder.rs`
   nie działa, dopóki ktoś ręcznie nie zbuduje binarki — build przechodzi, indeks wygląda
   poprawnie, a nowe pole **po prostu go nie ma**. `eos-build.sh` buduje je teraz zawsze.
2. **`cmd | tail` w kontenerze oddaje status `tail`, nie `cmd`.** `set -euo pipefail` w skrypcie
   zewnętrznym **nie obowiązuje** wewnątrz `bash -lc` — `cargo: command not found` przewinęło
   się bez zatrzymania czegokolwiek. Trzeba `set -o pipefail` po stronie kontenera.
3. **Przekierowanie tworzy plik zanim polecenie ruszy.** `podman run ... cat brak > plik`
   zostawia **plik zerowy**, który wygląda jak artefakt do wydania. Etapuj przez `.partial`
   i nie zostawiaj pustych.

Wspólny mianownik: **kontrola, która potrafi tylko przejść, nie jest kontrolą.** Po każdej
zmianie sprawdzaj sam artefakt (`strings` na binarce, `grep` na wygenerowanym pliku), a nie to,
że polecenie zwróciło zero.

### 21.7 Wolumen EOS-Podman: nie montuj przez `-mountpoint`

Nieudane `hdiutil attach -mountpoint /Volumes/EOS-Podman` **zostawia pusty katalog**, który
blokuje każdą kolejną próbę montowania — objaw wygląda wtedy jak uszkodzenie APFS
(„niemontowalny system plików", `mount_apfs: Input/output error`, `fsck` melduje zły
superblok). Katalogu nie usuniesz bez roota, bo `/Volumes` należy do roota. **Lekarstwo:**
`hdiutil detach /dev/diskN -force`, potem `hdiutil attach` **bez** `-mountpoint`. Uwaga: odczyt
surowych urządzeń (`dd if=/dev/rdiskN`) wymaga roota, więc „błąd 5" z `fsck_apfs` uruchomionego
jako użytkownik **nie jest dowodem uszkodzenia** — nie diagnozuj na tej podstawie.
Ten rozdział powstał z prośby o porządek („kasować niepotrzebne pliki, stare buildy, żeby nie
zajmowały miejsca") i z pomiaru, który tę prośbę **przeformułował** (`U-214`). Pomiar pokazał
trzy rzeczy naraz: sprzątano dysk, na którym było 1,2 TiB wolnego; prawie cały raportowany
rozmiar okazał się artefaktem systemu plików; a katalog, który każdy kasuje odruchowo, trzyma
klucz istniejący w **jednej kopii bez backupu**.

## 19. TODO — czego naprawdę brakuje

Ta lista jest tym, do czego odsyłają §13 i §16. Zasada: pozycja stąd znika dopiero, gdy
**da się wskazać dowód**, że rzecz działa — nie gdy została zaplanowana.

### Otwarte usterki (blokują `R-601`)

| ID | Rzecz | Stan |
|---|---|---|
| `R-F19` | `unmount_path` → `rmdir /scheme/<nazwa>` trafiało **do demona redoxfs**, nie do menedżera schematów, i odbijało się od korzenia (`EPERM`). | ✅ **naprawione** (`U-170`, `eos-redoxfs` `58824d7` + `eos-installer` `02be2b5`); **nie** potwierdzone end-to-end — ścieżka staje wcześniej na `R-F21` |
| `R-F21` | `package_files()` czytało bazę pakietów ze starej ścieżki `/pkg`. | ✅ **naprawione** (`U-171`) — czyta przez `PackageState::from_sysroot`; przepisane, bo klucz też się przeniósł do `packages.toml` |
| `R-F22` | `copy_file()` przewracało instalację na pierwszym pliku, który konfiguracja już zapisała (`/etc/issue`, 1 z 65 wpisów `[[files]]`). | ✅ **naprawione** (`U-171`) — istniejący cel pomijany; konfiguracja wygrywa |
| `R-601` | partycja → instalacja → reboot → login | ✅ **UDOWODNIONE** (`U-176`), potwierdzone ponownie **z poprawką `R-F18`** (`U-181`) |
| `R-F23` | Pod `hvf` gość ginie na `synchronous_exception_at_el0` przy obciążeniu — dwa razy, w dwóch różnych procesach, także przy `-smp 1`. | 🚧 P1 — harness zostaje na TCG; `EOS_SMOKE_ACCEL=hvf` odtwarza |
| `R-F24` | `try_fast_install()` czytał środowisko **procesu**, a zmienne live są w środowisku **jądra** (`/scheme/sys/env`). | ✅ **naprawione** (`U-176`) — 6,8 h → ~6 min |
| `R-F18` | Sterownik potwierdzał przerwanie **przed** sprawdzeniem, czy jego urządzenie coś zgłosiło — czyli odmaskowywał dzieloną linię za cudze przerwanie. | ✅ **naprawione** (`U-180`) — `virq 37` 16 829 830 → 8; 160 s → 16 s |
| `R-601` | partycja → instalacja → reboot → login nadal **nieudowodnione**; blokuje `R-F19`. | 🚧 P0 |

### Narzędzia, których w repo nie ma

| Narzędzie | Decyzja |
|---|---|
| `cosign` | ❌ Zadanie da się napisać, ale **klucz podpisujący generuje człowiek** (§5, §10.3) — narzędzie, które loguje, nie może go dotknąć. Do wykonania przez operatora, nie przez automat. |
| `nextest` | ⏳ Do podmiany za `cargo test`; korzyść to równoległość i czytelniejszy raport, nie nowa zdolność. Niski priorytet. |
| `miri` | ⛔ **Świadomie pominięty** — E-OS-owy kod Rust ma **zero** bloków `unsafe` (pilnuje tego kontrola 4), a `miri` bada właśnie UB w `unsafe`. Uruchamianie go na vendorowanym drzewie oznaczałoby utrzymywanie dywergencji (ADR-0003). |
| `cargo-fuzz` | ⛔ **Świadomie pominięty tutaj** — parsery warte fuzzowania (`pkgar`, RedoxFS, `redox_installer`) mieszkają w **forkach**, nie w tym repo. Miejsce dla nich to CI forka. |
| `cargo-audit` | ⛔ Nadmiarowy wobec `cargo-deny check advisories`; lokalnie w `local-scan.sh`. |

### Wymaga człowieka, nie automatu

- **`eos-setup-mirrors.sh --apply`** — potrzebuje PAT GitHuba. Nigdy nie podawaj tokenu
  narzędziu; to zadanie operatora (§5).
- **Klucz podpisujący** — generowanie jest **celowo** niezautomatyzowane.

### Nadal niezweryfikowane

- **Odtwarzalność builda** — ten sam commit → ten sam obraz bit w bit. `.config` i
  `cookbook.lock` są już **śledzone** (`U-168`, `U-169`), więc główna przeszkoda zniknęła,
  ale samego porównania **nikt jeszcze nie wykonał**. Dopóki nie wykona — to nie jest fakt.
- **SBOM obrazu** — `sbom` pokrywa manifesty Rusta; SBOM-y obrazów w `sbom/` nadal
  powstają ręcznie.
- **Podpisane ISO** — obraz to `harddrive.img`; ISO nie jest publikowane.
