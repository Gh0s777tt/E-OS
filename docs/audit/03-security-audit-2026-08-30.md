---
title: Audyt bezpieczeństwa
status: historical record
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# Audyt bezpieczeństwa

**Data:** 2026-08-30 · **Tryb:** wyłącznie do odczytu · **HEAD:** `51cac0382`
**Skanery uruchomione realnie:** `gitleaks 8.30.1`, `trivy`, `osv-scanner`, `shellcheck`, `hadolint`
**Powiązane:** [`00-inventory`](00-inventory-2026-08-30.md) · [`01-code-audit`](01-code-audit-2026-08-30.md) · [`02-feature-inventory`](02-feature-inventory-2026-08-30.md)

---

## 1. Model zagrożeń

### 1.1 Aktywa

| Aktywo | Gdzie | Dlaczego cenne |
|---|---|---|
| **Klucz podpisujący indeks repozytorium** (ed25519 + ML-DSA-65) | magazyn operatora poza repozytorium | kto go ma, dostarcza dowolny pakiet każdej maszynie z E-OS |
| **Klucz podpisujący pakiety** (`build/id_ed25519.toml`, ed25519) | **w drzewie budowania**, tryb 600 | podpisuje każdy `.pkgar` |
| **Klucz weryfikacji rozruchu** (`build/boot-signing/boot.key`) | **w drzewie budowania**, tryb 600 | podpisuje jądro i initfs |
| **Klucz Secure Boot / MOK** (`build/sb-signing/mok.key`) | drzewo budowania + `~/keys` | podpisuje bootloadery EFI |
| **Klucz wydań minisign** | `~/klucze-eos/eos-release.key` | podpisuje pliki wydania |
| **Maszyna budująca** | Mac operatora + wolumen podmana | jednoosobowy punkt, w którym wszystkie powyższe się spotykają |
| **Dane użytkownika na urządzeniu** | RedoxFS, opcjonalnie AES-XTS | — |

### 1.2 Przeciwnicy i co realnie mogą

| Przeciwnik | Zdolność | Czy obecne mechanizmy zatrzymują |
|---|---|---|
| **Napastnik w sieci między urządzeniem a repozytorium** | podmiana pakietów, cofnięcie indeksu | **TAK** — podpis hybrydowy + przypięty klucz w obrazie + hasze blake3 egzekwowane na bajtach (`U-223`) + `serial`/`expires` (`V2-MS15`). **Ale**: żywy indeks aarch64 jest sprzed `V2-MS15`, więc bez ochrony antycofkowej |
| **Kto przejmie `static.redox-os.org`** | podmiana **30 z 65** pakietów obrazu | **NIE** — TOFU, klucz z tego samego hosta (raport A §5.2). **To jest największa dziura w łańcuchu dostaw** |
| **Kto przejmie lustro GitHub** | podmiana źródeł dla 22 z 26 receptur | **NIE** — build ciągnie z lustra, nie ze źródła prawdy; nic nie porównuje głów |
| **Napastnik lokalny z kontem `user`** | 25 schematów jądra, w tym `sudo` | **CZĘŚCIOWO** — brak `ip` odbiera surowe gniazda; brak piaskownicy znaczy, że kompromitacja przeglądarki = kompromitacja konta |
| **Złośliwy `.pkgar` podany narzędziom hosta** | przepełnienie offsetu / panika | **NIE na hoście** — poprawka `cb8ae7b` jest w forku, host buduje `pkgar-core` z upstreamu (faza 0 §3.1) |
| **Kradzież laptopa** | dane w spoczynku | **TAK, jeśli włączono** — AES-XTS jest opcją przy instalacji, nie domyślną |
| **Kto przejmie maszynę budującą** | wszystko | **NIE** — cztery klucze prywatne leżą w drzewie budowania i w katalogu domowym |

### 1.3 Granice zaufania

```
[static.redox-os.org] ──TOFU── [maszyna budująca] ──podpis──> [obraz] ──przypięty klucz──> [urządzenie]
        │                            │                                                          │
   30/65 pakietów            4 klucze prywatne                                        user: 25 schematów
   klucz z tego                w drzewie/HOME                                          bez `ip`, z `sudo`
   samego hosta                                                                        BEZ piaskownicy
```

**Najsłabsze ogniwo jest na samym początku, nie na końcu.** Warstwy 3–5 (podpis indeksu, podpis
pakietów, weryfikacja rozruchu) są zbudowane starannie i działają. Wejście do łańcucha — pobieranie
binarek upstreamu i źródeł z lustra — nie ma żadnej kotwicy.

---

## 2. Lista kontrolna łańcucha dostaw

**Uwaga metodyczna:** projekt **nie używa GitHub Actions** (`R-004`, wyłączone na koncie; zero
plików w `.github/workflows`). Pozycje właściwe wyłącznie dla Actions są oznaczone **N/D**
z podaniem odpowiednika GitLab-owego i jego stanu.

| Pozycja | Stan | Dowód | Naprawa |
|---|---|---|---|
| **Ochrona gałęzi** | **PRESENT** | `glab api projects/82957024/protected_branches` → `main`: push=Maintainers, merge=Maintainers | — |
| **Blokada force-push** | **PRESENT** | tamże: `allow_force_push: False`; GitHub: `allow_force_pushes.enabled: False` | — |
| **Wymagane recenzje** | **MISSING** | `glab api .../approvals` → `approvals_before_merge: 0` | ustawić ≥1; **ale** patrz uwaga poniżej |
| **Zatwierdzenie przez CODEOWNERS** | **PARTIAL** | `.github/CODEOWNERS` istnieje (635 B), po stronie GitLaba brak reguł zatwierdzania | dodać `CODEOWNERS` w GitLabie i regułę |
| **Podpisane commity** | **PARTIAL** | commity **są** podpisywane (`%G?` = `G`), ale **nie jest to wymuszone**: GitHub `required_signatures: False`, GitLab nie ma push rules (404 — plan płatny) | wymusić w regułach albo hakiem |
| **Wymagane statusy CI przed scaleniem** | **PRESENT, ale obchodzone** | `only_allow_merge_if_pipeline_succeeds: True` **oraz** `only_allow_merge_if_all_discussions_are_resolved: True` — a **wszystkie commity idą prosto na `main`** (0 MR-ów w historii), więc bramka nigdy się nie stosuje | zablokować bezpośredni push na `main` |
| **Rulesets** | **MISSING** | brak; GitLab push rules niedostępne w planie | — |
| **Domyślny `GITHUB_TOKEN` tylko do odczytu** | **N/D** | brak Actions | — |
| **Uprawnienia per zadanie** | **N/D** | brak Actions | GitLab: zadania biorą `CI_JOB_TOKEN` o zakresie projektu |
| **Brak nadużycia `pull_request_target`** | **N/D** | brak Actions | — |
| **Brak `${{ github.* }}` w `run:`** | **N/D** | brak Actions | — |
| **Sekrety przez `env:`** | **PRESENT** | `.gitlab-ci.yml` nie interpoluje sekretów do skryptów; `EOS_REPO_SIGN_KEY` czytany ze środowiska | — |
| **Skanowanie sekretów** | **PRESENT (dwa niezależne)** | GitHub: `secret_scanning: enabled`, `push_protection: enabled`; GitLab CI: zadanie `secret-scan` (gitleaks) | — |
| **Ochrona przy pushu** | **PRESENT** | GitHub `secret_scanning_push_protection: enabled` | — |
| **Sekrety środowiskowe** | **MISSING** | brak zdefiniowanych środowisk GitLab | — |
| **Brak sekretów w kodzie** | **PRESENT** | `gitleaks` na **8153 commitach**: 1 trafienie, **fałszywe** (klucz publiczny 32 B); GitHub secret scanning: `[]` — **zero alertów** | dopisać ścieżkę do allowlisty z uzasadnieniem |
| **Krótkotrwałe tokeny / OIDC** | **MISSING** | brak integracji chmurowej, więc i brak potrzeby — ale i brak polityki | — |
| **Rotacja sekretów** | **PARTIAL** | klucz wydań minisign **zrotowany** (`R-F26`); brak harmonogramu dla pozostałych czterech | spisać politykę rotacji |
| **Akcje przypięte do pełnego SHA** | **N/D** | brak Actions | — |
| **Dependabot + aktualizacje bezpieczeństwa** | **PRESENT, ale nieskuteczny** | `dependabot_security_updates: enabled`, a `gh api .../dependabot/alerts` → **0 otwartych**, podczas gdy `osv-scanner` na tym samym `Cargo.lock` znajduje **2** | dodać `osv-scanner` do CI |
| **Przegląd zależności** | **MISSING** | brak `dependency-review` | — |
| **SCA** | **PARTIAL** | `deny.toml` (cargo-deny) istnieje i biega w CI — ale CI nie działa od 28 sierpnia | uruchamiać `osv-scanner` lokalnie w hooku |
| **SBOM** | **PARTIAL** | `sbom/eos-0.1.0-*.cdx.json` — **tylko dla 0.1.0**, przy wydanym `v0.2.0`; zadanie CI `sbom` generuje artefakt z `expire_in: 30 days` i **nie commituje** | generować SBOM per tag i commitować |
| **Podpisywanie artefaktów** | **PRESENT (własne, nie Sigstore)** | `tools/eos-repo-sign` — hybryda ed25519+ML-DSA-65; minisign dla wydań; `sbsign` dla EFI | rozważyć cosign dla artefaktów CI |
| **Allowlista akcji** | **N/D** | brak Actions | — |
| **Zatwierdzanie workflow dla nowych osób** | **N/D** | brak Actions; GitLab: `request_access_enabled: True` | rozważyć wyłączenie |
| **Efemeryczne runnery** | **PRESENT** | `shared_runners_enabled: True` — współdzielone runnery GitLaba są efemeryczne | — |
| **Izolacja runnera własnego** | **PARTIAL** | `.gitlab-ci.yml` ma warstwę „heavy" na runnerze własnym (Mac operatora) — ta sama maszyna, na której leżą klucze prywatne | oddzielić budowanie od przechowywania kluczy |
| **Izolacja zadań** | **PRESENT** | zadania w kontenerach (`alpine:3`, `rust:slim`) | — |
| **Dzienniki audytu** | **PARTIAL** | GitLab trzyma dzienniki na poziomie projektu; brak własnego zbierania | — |
| **CodeQL / SAST** | **MISSING** | brak jakiegokolwiek SAST; `clippy` jest lintem, nie SAST-em | dodać `semgrep` albo `cargo-geiger` |
| **DAST** | **MISSING** | brak | niski priorytet — to system operacyjny, nie usługa |
| **Skanowanie kontenerów** | **MISSING** | `podman/*containerfile` nieskanowane; `hadolint` uruchomiony **przeze mnie**: 7 uwag, w tym **3× `DL3008`** (brak przypiętych wersji apt) | dodać `hadolint` do CI |
| **Skanowanie IaC** | **N/D** | brak Terraform/K8s | — |
| **OpenSSF Scorecard** | **MISSING** | brak | — |
| **Hooki pre-commit (gitleaks)** | **PRESENT** | `lefthook.yml` — lokalne hooki odwzorowujące lekką warstwę CI | — |
| **MFA i klucze sprzętowe** | **[NIEZWERYFIKOWANE]** | nie da się sprawdzić z API dla cudzego konta | — |
| **SSO** | **N/D** | konto osobiste, nie organizacja | — |
| **Polityka PAT** | **[NIEZWERYFIKOWANE]** | `gh auth status` pokazuje token `gho_*` (OAuth), ale zakresu i terminu nie widzę | — |
| **Konta awaryjne** | **MISSING** | projekt jednoosobowy — **brak jakiegokolwiek drugiego dostępu**. Utrata konta = utrata projektu | dodać drugiego maintainera albo procedurę odzyskania |
| **Plan reagowania na incydenty** | **PARTIAL** | `SECURITY.md` opisuje **zgłaszanie** (dwa realne kanały), nie opisuje **reagowania** | dopisać sekcję: kto, w jakim czasie, jak wydaje poprawkę |

> **Uwaga do „wymaganych recenzji".** W projekcie jednoosobowym wymóg recenzji jest teatrem:
> jedyna osoba zatwierdzałaby własne zmiany. **Realną wartość ma tu co innego** — zablokowanie
> bezpośredniego pushu na `main`, żeby bramka `only_allow_merge_if_pipeline_succeeds` (już
> włączona!) zaczęła cokolwiek znaczyć. Dziś jest ustawiona **i całkowicie omijana**.

---

## 3. Wyniki skanerów — realne wyjście

### 3.1 `gitleaks 8.30.1` — pełna historia

```
8153 commits scanned.
scanned ~9412984 bytes (9.41 MB) in 1.68s
leaks found: 1
```

Jedyne trafienie: `generic-api-key` w `keys/eos-pkg-signing.pub.toml:1`. **Fałszywy alarm** —
plik ma 74 B i jedno pole `pkey` o wartości **64 znaków hex = 32 bajty**, czyli publiczny klucz
ed25519. Potwierdzenie niezależne: **GitHub secret scanning zwraca pustą listę** dla tego repo.

**Ale:** plik dodano **2026-08-29**, czyli **po** ostatnim udanym pipeline (2026-08-28 03:01).
Gdy limit CI się odnowi, zadanie `secret-scan` **padnie** i będzie wyglądać na regresję.

### 3.2 `osv-scanner` — podatności zależności

| Repozytorium | Pakietów | Podatności | Najpoważniejsze |
|---|---|---|---|
| `E-OS` (główne) | 163 | **2** | `anyhow 1.0.102` → 1.0.103; `lru 0.16.3` → 0.18.2 |
| **`eos-pkgutils`** | 247 | **20** | `rustls-webpki 0.103.4` (**6 zaleceń**), `quinn-proto 0.11.13` (4, CVSS do 8.7), `ring 0.17.8` (2), `rand 0.9.2` (2), `crossbeam-epoch`, `bytes`, `number_prefix` (**bez poprawki**) |
| `eos-kernel` | 50 | **2** | `linked_list_allocator 0.9.1` — `RUSTSEC-2022-0063` |
| `eos-bootloader` | 55 | **0** | — |
| `tools/eos-repo-sign` | 57 | **0** | — |

**Co z tego trafia do produktu — zmierzone `strings` na `/usr/bin/pkg` (5 164 488 B) z obrazu:**

| Biblioteka | W obrazie | Zalecenia |
|---|---|---|
| `rustls-webpki-0.103.4` | **TAK** (11 trafień, wersja odczytana z binarki) | **6** |
| `rustls-0.23.31`, `-0.26.2`, `-0.27.7` | **TAK** — trzy wersje naraz | — |
| `ring` | **TAK** (95 trafień) | 2 |
| `reqwest-0.12.28` | TAK | — |
| `quinn-proto` | **NIE** (0 trafień) | — |

**HIGH.** `rustls-webpki` waliduje certyfikaty TLS, a `pkg` po TLS pobiera pakiety. Sześć otwartych
zaleceń w warstwie decydującej „czy to właściwy serwer".
**Łagodzące:** indeks jest dodatkowo podpisany hybrydowo i weryfikowany kluczem przypiętym
w obrazie, hasze blake3 są egzekwowane na bajtach, **a kanał jest dziś wyłączony** (raport B §3.1).
Ścieżka jest zamknięta — do momentu opublikowania repozytorium.

**`linked_list_allocator 0.9.1` w jądrze — i dlaczego NIE jest to dziś podatność do wykorzystania.**
`RUSTSEC-2022-0063` opisuje trzy zapisy poza zakresem: (1) `init` z rozmiarem `< 3·usize`,
(2) `extend` z rozmiarem `< 2·usize`, (3) `extend` na **pustej** stercie. W E-OS:
`src/allocator/mod.rs:8` → `KERNEL_HEAP_SIZE = rmm::MEGABYTE`, a `src/allocator/linked_list.rs:34`
woła `extend(KERNEL_HEAP_SIZE)` **wyłącznie wewnątrz `alloc`, gdy `allocate_first_fit` zawiedzie**,
czyli na stercie już zainicjowanej i niepustej. **Żaden z trzech wariantów nie jest osiągalny.**
Waga: **MEDIUM jako dług** (czteroletnie przypięcie, jedyny alokator jądra, `pub use
self::linked_list::Allocator` bez alternatywy), **nie HIGH jako podatność**.

### 3.3 `trivy fs` (vuln + secret + misconfig)

```
Number of language-specific files  num=2
Detected config files              num=0
podatności: brak · sekrety: 0 · błędy konfiguracji: brak
```

**Zero trafień — i to jest informacja o skanerze, nie o projekcie.** Trivy nie znalazł
`RUSTSEC-2026-0190` ani `-0253`, które `osv-scanner` znajduje w tym samym pliku; wykrył też
**0 plików konfiguracyjnych**, bo pliki kontenerów nazywają się `*-containerfile`, a nie
`Dockerfile`. **Wniosek operacyjny: trivy sam nie wystarczy dla projektu w Rust.**

### 3.4 `hadolint` na plikach kontenerów

```
podman/redox-base-containerfile:5       DL3008 warning: Pin versions in apt get install
podman/redox-base-containerfile:5       DL3009 info:    Delete the apt lists after installing
podman/redox-gdb-containerfile:3        DL3008 warning
podman/redox-gdb-containerfile:11       DL3013 warning: Pin versions in pip
podman/redox-gdb-containerfile:11       DL3042 warning: Avoid pip cache dir
podman/redox-toolchain-containerfile:5  DL3008 warning
podman/redox-toolchain-containerfile:5  DL3009 info
```

**3× `DL3008`** to bezpośrednia przyczyna, dla której **środowisko budowania nie jest
reprodukowalne** (raport A §2.1).

### 3.5 `shellcheck` na 50 śledzonych `scripts/*.sh`

**0 błędów**, 16 ostrzeżeń, 24 uwagi. W skryptach E-OS-owych **dwa** ostrzeżenia
(`SC2034` w `eos-secureboot-proof.sh:24`, `SC2164` w `eos-sync-buildtree.sh:26`).
19 błędów w całym repozytorium siedzi wyłącznie w plikach **vendorowanych**
(`build.sh`, `native_bootstrap.sh`, `podman_bootstrap.sh`) i w `recipes/wip`.

---

## 4. Bezpieczeństwo produktu

### 4.1 Kryptografia — dobre wybory

| Zastosowanie | Algorytm | Ocena |
|---|---|---|
| Hasła użytkowników | **argon2id**, `m=19456, t=2, p=1` | **dobre** — właściwy wybór, sensowne parametry |
| Podpis indeksu repozytorium | **ed25519 + ML-DSA-65 (FIPS 204)**, hybryda | **bardzo dobre** — odporność na przyszłego przeciwnika kwantowego bez utraty zgodności |
| Podpis pakietów | ed25519 (pkgar) | standard |
| Weryfikacja rozruchu | ed25519 nad **SHA-512(role ‖ len_le ‖ data)** | **bardzo dobre** — separacja domen i wiązanie długości; podpisany initfs **nie zweryfikuje się** jako jądro |
| Szyfrowanie dysku | **AES-XTS**, z przyspieszeniem ARMv8 na aarch64 | właściwy tryb dla dysku; **KDF nie zweryfikowany** — `[NIEZWERYFIKOWANE]` |
| Integralność pakietów | blake3 | dobre |
| TLS | rustls (w `pkg`) + OpenSSL 3.5.3 (dla `curl`/`git`) | dwa niezależne stosy; rustls z podatnym `webpki` |

**Nie znalazłem ani jednego użycia MD5/SHA-1/RC4/DES w roli bezpieczeństwa.** To rzadkie i warte
odnotowania.

### 4.2 Łańcuch rozruchu — zbudowany dobrze, z domyślną furtką

**Co działa:**

```rust
// eos-bootloader/src/main.rs:436-451
#[cfg(feature = "verify-boot")]
match read_small_in_tx(tx, &sig_path) {
    Some(sig) => eos_boot_verify::verify_or_panic(path, role, slice, &sig),
    None => panic!("{}: no signature at {} -- refusing to boot unverified code (V2-MS02)", path, sig_path),
}
```

Weryfikacja biegnie **przed** sprawdzeniem magic bytes i przed jakimkolwiek użyciem bajtów —
komentarz w kodzie wprost tłumaczy dlaczego (`elf_entry()` czyta `e_entry` z tego bufora i skacze).
Brak podpisu → odmowa. Zerowy klucz → odmowa (`eos_boot_verify.rs:50-56`).
**Zweryfikowane w wysyłanym artefakcie:** ciąg „refusing to boot unverified" jest obecny
w `bootloader.efi` i `bootloader-live.efi`.

**HIGH — domyślna postawa jest fail-open.** Cały blok siedzi za `#[cfg(feature = "verify-boot")]`,
a cecha włącza się **wyłącznie gdy istnieje `build/boot-signing/boot.pub.bin`**
(`recipes/core/bootloader/recipe.toml:26-36`). Bez klucza receptura wypisuje

```
V2-MS02: no boot key at build/boot-signing/ -- bootloader will NOT verify what it loads
```

**i build kończy się sukcesem.** Gorzej: `scripts/eos-build.sh:62` przepuszcza `make` przez
`| tail -3`, więc **to ostrzeżenie nie ma szans się pokazać**. Maszyna bez klucza wyprodukuje
obraz bez weryfikacji rozruchu i nikt się nie dowie.

**Poprawka:** wymagać jawnego `EOS_ALLOW_UNVERIFIED_BOOT=1`, żeby zbudować bez klucza — dokładnie
ten wzorzec, którego projekt **już używa** w `publish-repo.sh` (`EOS_ALLOW_UNSIGNED=1`).
**Nakład:** 30 min.

### 4.3 Granice uprawnień

`/etc/login_schemes.toml` — lista dozwolonych schematów jądra per użytkownik; `root` = `*`,
`user` = 25 wyliczonych. **Odebranie `ip`** (`R-904a`) to realne utwardzenie: brak surowych gniazd
IP dla nieuprzywilejowanego konta.

**Trzy zastrzeżenia:**

1. **HIGH — granica po koncie, nie po aplikacji.** `netsurf` parsujący wrogi HTML ma te same
   25 schematów co powłoka, w tym `file`, `proc`, `pty`, `sudo`. **Brak piaskownicy** znaczy,
   że kompromitacja przeglądarki to kompromitacja sesji.
2. **[NIEZWERYFIKOWANE]** — `user` dostaje `debug`, `memory`, `irq`, `serio`, `sys`. Czy któryś
   pozwala czytać pamięć cudzego procesu albo wpinać się w przerwania, **nie wiem** i nie będę
   zgadywał. **To pierwsze pytanie do rozstrzygnięcia.**
3. `sudo` na liście `user` — konieczne do administracji, ale bez dodatkowej bariery.

### 4.4 Autentyczność aktualizacji — kompletna i wyłączona

| Warstwa | Stan |
|---|---|
| Podpis indeksu (hybryda) | **działa** — zweryfikowałem żywy indeks aarch64 (79 pakietów): ed25519 **OK** + ML-DSA-65 **OK** |
| Klucz przypięty w obrazie | **jest** — `/etc/pkg/eos-repo-sign.pub.toml` |
| Klucz pakietów przypięty w obrazie | **jest** — `/etc/pkg/packages.toml` → `[pubkeys.local] pkey = "abf34ee5…"`, bajtowo zgodny z `keys/eos-pkg-signing.pub.toml` |
| Hasze blake3 egzekwowane na bajtach | **tak** od `U-223` |
| Ochrona antycofkowa (`serial`) | **w kodzie tak**, w **żywym indeksie aarch64 NIE** — opublikowany przed `V2-MS15` |
| **Aktywne źródło pakietów w obrazie x86_64** | **BRAK** — oba wpisy w `/etc/pkg.d/` zakomentowane |

**HIGH.** Zainstalowany system x86_64 **nie ma jak dostać poprawki bezpieczeństwa**. Cała, dobrze
zbudowana warstwa autentyczności jest gotowa i **nieużywana**.

### 4.5 Dane w spoczynku i w tranzycie

- **W spoczynku:** AES-XTS **opcjonalne** przy instalacji (nie domyślne). Potwierdzone
  w `redoxfs`, `redoxfs-mkfs`, `redox_installer_tui`.
- **W tranzycie:** `pkg` → rustls (z podatnym `webpki`); `curl`/`git`/`wget` → OpenSSL 3.5.3
  (aktualny). **`git 2.13.1`** jest pobieraną binarką upstreamu i ma dziewięć lat CVE.
- **Brak zapory** — obraz zawiera `sshd`, `dhcpd`, `netstack` i żadnego filtrowania portów.
- **Brak trwałego dziennika** — po incydencie nie ma czego czytać.

---

## 5. Znaleziska bezpieczeństwa — uszeregowane

| # | Waga | Znalezisko | Dowód | Naprawa | Nakład |
|---|---|---|---|---|---|
| C-1 | **HIGH** | **TOFU dla 30 z 65 pakietów obrazu** — klucz podpisujący pobierany z tego samego hosta, który serwuje pakiety | `src/cook/fetch_repo.rs:48`, `src/lib.rs:11`, plik `build/remotes/pub_key_static.redox-os.org.toml` istnieje | przypiąć oczekiwany klucz upstreamu w repo i porównywać | 4 h |
| C-2 | **HIGH** | **Weryfikacja rozruchu jest fail-open**, a jedyne ostrzeżenie tłumione przez `\| tail -3` | `recipes/core/bootloader/recipe.toml:26-36`, `scripts/eos-build.sh:62` | wymagać `EOS_ALLOW_UNVERIFIED_BOOT=1` | 30 min |
| C-3 | **HIGH** | **Podatny `rustls-webpki 0.103.4` (6 zaleceń) w wysyłanej binarce `pkg`** | `strings /usr/bin/pkg` → `rustls-webpki-0.103.4`; `osv-scanner` | podbić fork `eos-pkgutils` | 2 h |
| C-4 | **HIGH** | **Brak aktywnego kanału aktualizacji na x86_64** — system nie dostanie poprawek | `/etc/pkg.d/50_eos`, `50_redox` — oba zakomentowane | opublikować repo x86_64 i włączyć | 1 d |
| C-5 | **HIGH** | **Brak piaskownicy** — przeglądarka ma 25 schematów konta, w tym `file`, `proc`, `sudo` | `/etc/login_schemes.toml` | schematy per proces dla `netsurf` | 1 tydz. |
| C-6 | **HIGH** | **Bramka CI jest ustawiona i całkowicie omijana** — 0 MR-ów, wszystko prosto na `main` | `only_allow_merge_if_pipeline_succeeds: True` + `protected_branches` push=Maintainers | zablokować bezpośredni push na `main` | 15 min |
| C-7 | **HIGH** | **Cała siatka bramek nie działa od 2026-08-28** (`ci_quota_exceeded`) | 45/46 pipeline'ów czerwonych, zadania w 0 s | uruchamiać `lefthook` lokalnie; runner własny | — |
| C-8 | **HIGH** | **`git 2.13.1` (2017) w obrazie** — pobierana binarka upstreamu | `strings /usr/bin/git` → `2.13.1` | dodać wyjątek `source` i zbudować nowszego | 4 h |
| C-9 | **HIGH** | **Brak trwałego dziennika audytu** | brak `auditd`/`syslogd`/`journalctl` w 285 binarkach | demon logów + rotacja | 1 tydz. |
| C-10 | **HIGH** | **Brak zapory** przy obecnym `sshd` i pełnym stosie sieciowym | brak `iptables`/`nft`/`pf` w obrazie | filtr pakietów albo świadome udokumentowanie braku | 2 tyg. |
| C-1b | **HIGH** | **Tarball `mpc` (zależność `gcc13`) pobierany bez sumy kontrolnej z lustra podstawionego domyślnie** — jedyny z 19 przepisów GNU bez `blake3` | `src/config.rs:173-180` (brak `cookbook.toml`), `recipes/libs/mpc/recipe.toml`, `src/cook/fetch.rs:394-403` ostrzega i jedzie dalej | dopisać `blake3`; `break` → twardy błąd; kontrola w `ci-integrity.sh` | 1 h |
| C-1c | **HIGH** | **`blake3` niesprawdzany dla przepisów zależnych, a zadeklarowana wartość publikowana jako tożsamość źródła** | `src/cook/fetch.rs:541`, `:375-377`, `:368` | liczyć hasz zawsze, gdy zadeklarowany; `ident` z policzonego | 3 h |
| C-11 | **MEDIUM** | **Cztery klucze prywatne na maszynie budującej**, która jest też runnerem CI „heavy" | `build/boot-signing/boot.key`, `build/sb-signing/mok.key`, `build/id_ed25519.toml`, `~/klucze-eos/` | oddzielić podpisywanie od budowania | 1 tydz. |
| C-12 | **MEDIUM** | **Żywy indeks aarch64 bez `serial`/`expires`** — brak ochrony antycofkowej w produkcji | pobrany indeks: brak obu pól | republikacja po `V2-MS15` | 1 d |
| C-13 | **MEDIUM** | **Dependabot włączony, ale zgłasza 0** przy 2 realnych podatnościach | `gh api dependabot/alerts` → `[]`; `osv-scanner` → 2 | dodać `osv-scanner` do CI i hooka | 1 h |
| C-14 | **MEDIUM** | **SBOM tylko dla 0.1.0** przy wydanym `v0.2.0`; generowany SBOM wygasa po 30 dniach | `sbom/eos-0.1.0-*.cdx.json` | generować i commitować per tag | 2 h |
| C-15 | **MEDIUM** | **Brak SAST** | brak `semgrep`/CodeQL/`cargo-geiger` | dodać `semgrep` | 4 h |
| C-16 | **MEDIUM** | **`linked_list_allocator 0.9.1` w jądrze** — dług, nie podatność osiągalna | `RUSTSEC-2022-0063`; ścieżki niedostępne (§3.2) | podbić do ≥0.10.2 | 2 h |
| C-17 | **MEDIUM** | **Kontener budowania niereprodukowalny** — 3× `DL3008` | `hadolint` | przypiąć wersje apt | 2 h |
| C-18 | **MEDIUM** | **Brak konta awaryjnego** — projekt jednoosobowy, utrata konta = utrata projektu | brak drugiego maintainera | procedura odzyskania | 1 d |
| C-19 | **LOW** | **Fałszywy alarm gitleaks czeka na odnowienie limitu CI** | `keys/eos-pkg-signing.pub.toml` dodany 29.08, po ostatnim zielonym | allowlist z uzasadnieniem | 15 min |
| C-20 | **LOW** | **Podpisywanie commitów nie jest wymuszone** | GitHub `required_signatures: False` | hak `pre-push` | 30 min |
| C-21 | **[NIEZWERYFIKOWANE]** | **`user` ma schematy `debug`, `memory`, `irq`, `serio`, `sys`** | `/etc/login_schemes.toml` | ustalić semantykę i odebrać zbędne | — |

---

## 6. Czego NIE zbadano

- **MFA, klucze sprzętowe, zakres PAT** — niewidoczne przez API dla tego konta.
- **KDF szyfrowania dysku** — potwierdziłem AES-XTS w binarkach, nie zbadałem wyprowadzania klucza
  z hasła. To istotne pytanie i zostaje otwarte.
- **Obraz aarch64** — cała analiza produktu dotyczy x86_64.
- **Semantyka schematów jądra** (C-21).
- **Zachowanie `pkg` przy 404 na `id_ed25519.pub.toml`** na opublikowanym hoście aarch64.
- **DAST** — nieadekwatny dla systemu operacyjnego.
