# Tokeny — wszystko za jednym posiedzeniem

Ten dokument zbiera **każdy** token, jakiego potrzebuje E-OS, żeby dało się je założyć raz,
zamiast odkrywać brakujący przy każdej kolejnej czynności. Kolejność jest celowa: od rzeczy,
które **nie wymagają tokenu wcale**, po te, które wymagają najszerszych uprawnień.

---

## 0. Zasada, która nie ma wyjątków

> **Nie wklejaj tokenu do rozmowy z asystentem — nigdy, nawet na jego prośbę.**

Powód jest techniczny, nie ceremonialny: wszystko, co przechodzi przez wywołania narzędzi
asystenta, trafia do transkryptu sesji. Token, który tam trafi, trzeba uznać za ujawniony i
**unieważnić**, nawet jeśli nikt go nie widział. Asystent może natomiast:

* powiedzieć dokładnie, jaki token założyć i z jakim zakresem,
* przygotować i sprawdzić skrypty, które go używają,
* zweryfikować **skutek** (czy lustro działa, czy zadanie CI wystartowało) bez oglądania sekretu.

Wartość tokenu wpisujesz **wyłącznie** w interfejsie GitLaba/GitHuba albo w swojej powłoce.

---

## 1. Przegląd — co, gdzie, po co

| # | Token | Gdzie go wpisujesz | Zakres | Bez niego nie działa |
|---|---|---|---|---|
| — | *(żaden)* | GitLab → ustawienia projektu | — | `R-F12`: „Pipelines must succeed" |
| 1 | `GITHUB_MIRROR_PAT` | zmienna w Twojej powłoce | GitHub classic: `repo` | jednorazowe ustawienie luster push |
| 2 | `EOS_GH_TOKEN` | zmienna w Twojej powłoce | GitHub classic: `repo` | `sync-forks.sh --push` |
| 3 | `GITLAB_TOKEN` | GitLab → CI/CD → Variables | GitLab: `api` | `semantic-release` (wydania) |
| 4 | `RENOVATE_TOKEN` | GitLab → CI/CD → Variables | GitLab: `api` | bot aktualizujący zależności |

**1 i 2 mogą być tym samym tokenem.** Oba potrzebują `repo` na GitHubie i oba działają
z Twojej maszyny. Jeśli chcesz jeden — załóż go raz i wyeksportuj pod obiema nazwami.

**3 i 4 celowo trzymaj osobno.** Renovate to bot, który biegnie z harmonogramu i sięga do
API; wydania podpisują Twoje tagi. Wspólny token oznacza, że unieważnienie jednego psuje
drugie, a kompromitacja bota daje dostęp do wydań.

---

## 2. Krok bez tokenu — `R-F12` (zrób to najpierw)

To jedyna z tych rzeczy, którą załatwia **pole wyboru**, i dlatego jest pierwsza.

1. Otwórz **gitlab.com/e-os/e-os → Settings → Merge requests**.
2. Zaznacz **„Pipelines must succeed"**.
3. Zapisz (*Save changes*).

Co to zmienia: dziś każda bramka CI biegnie **po** tym, jak kod jest już na `main` i
zalustrzony — czyli jest powiadomieniem, nie bramką. Samo pole niczego nie wymusi, dopóki
zmiany idą prosto na `main`; realna zmiana to **przepuszczanie przez MR** wszystkiego, co
dotyka łańcucha zaufania, buildu albo przypięcia (`CLAUDE.md` §13).

---

## 3. Token GitHub — lustra i synchronizacja forków

Jeden token obsłuży oba zastosowania.

1. **github.com → Settings → Developer settings → Personal access tokens → Tokens (classic)**
   → **Generate new token (classic)**.
2. Nazwa: `E-OS mirrors + fork sync`. Wygaśnięcie: **90 dni** (krócej niż „bez końca" —
   rotacja jest tańsza niż zastanawianie się, gdzie ten token jeszcze działa).
3. Zakres: **tylko `repo`**. Nic więcej — bez `workflow`, bez `admin:*`, bez `delete_repo`.
4. Skopiuj wartość **do menedżera haseł od razu**; GitHub pokaże ją tylko ten jeden raz.

Użycie — w Twojej powłoce, nie w pliku w repozytorium:

```bash
read -rs -p "GitHub PAT: " TOK && export GITHUB_MIRROR_PAT="$TOK" EOS_GH_TOKEN="$TOK" && unset TOK
```

`read -rs` nie wypisuje wpisywanego tekstu i **nie zostawia go w historii powłoki** — inaczej
niż `export GITHUB_MIRROR_PAT=ghp_...`, które wyląduje w `~/.zsh_history`.

Następnie, w tej samej sesji powłoki:

```bash
scripts/eos-setup-mirrors.sh              # najpierw na sucho: pokaże, co zrobi
scripts/eos-setup-mirrors.sh --apply      # dopiero teraz ustawia lustra
```

> Skrypt **pomija** repozytoria z `role = "pkg"`. To nie jest szczegół: push-mirror
> nadpisałby opublikowaną zawartość pakietów (`U-158`).

---

## 4. `GITLAB_TOKEN` — wydania

1. **gitlab.com/e-os/e-os → Settings → Access tokens** → *Add new token*.
2. Nazwa `semantic-release`, rola **Maintainer**, zakres **`api`**, wygaśnięcie 90 dni.
3. **Settings → CI/CD → Variables → Add variable**:
   * Key: `GITLAB_TOKEN`
   * Value: wartość tokenu
   * **Masked: tak**, **Protected: tak**, **Expand variable reference: nie**

Zadanie `semantic-release` ma regułę `$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $GITLAB_TOKEN`,
więc **samo się pomija**, dopóki zmiennej nie ma — dodanie jej jest jedynym potrzebnym
przełącznikiem.

---

## 5. `RENOVATE_TOKEN` — bot zależności

Jak wyżej, osobny token o zakresie **`api`**, jako zmienna `RENOVATE_TOKEN`
(**masked**, **protected**).

Renovate biegnie **wyłącznie** z własnego harmonogramu (`SCHEDULE_TASK=renovate`) i ma
`allow_failure: true`, żeby bot od podbijania zależności nigdy nie zablokował pipeline'u
systemu operacyjnego. Harmonogram: **Settings → CI/CD → Schedules**, zmienna
`SCHEDULE_TASK` = `renovate`.

---

## 6. Sprawdzenie, że działa — bez pokazywania sekretu

```bash
# lustra: czy zdalne są ustawione (adresy, nie sekrety)
scripts/eos-repos.sh status | tail -5

# CI: czy zmienne istnieją — pokazuje KLUCZE, nie wartości
#   Settings -> CI/CD -> Variables

# wydania: po następnym pushu na main sprawdź, czy zadanie przestało się pomijać
#   CI/CD -> Pipelines -> ostatni -> semantic-release
```

Asystent może zweryfikować **każdy z tych skutków** — i powinien, zanim uznacie rzecz za
zrobioną (`CLAUDE.md` §4.4). Nie potrzebuje do tego wartości żadnego tokenu.

---

## 6a. Mapa kluczy — pięć warstw, które łatwo pomylić

Tokeny z tego dokumentu dają **dostęp**. Klucze poniżej dają **autentyczność** — to inna
rzecz i inne zasady. Warstwy są niezależne: żadna nie zastępuje pozostałych.

| # | Warstwa | Co dowodzi | Algorytm | Stan (`U-191`) |
|---|---|---|---|---|
| 1 | Podpisy commitów i tagów | kto napisał kod | SSH | ✅ działa |
| 2 | Podpisy per-pakiet | że `.pkgar` nie podmieniono | ed25519 (pkgar) | ✅ działa |
| 3 | Podpis manifestu repo | że lista pakietów jest nasza | ed25519 + ML-DSA-65 | 🚧 kod gotowy, **brak klucza** |
| 4 | Sumy kontrolne wydania | że pobrany obraz jest nasz | minisign | ⚠️ **klucz prywatny utracony** |
| 5 | Secure Boot / measured boot | że maszyna wystartowała z tego obrazu | — | ❌ nie istnieje (`R-913`) |

**Warstwy 1 i 2 nie wymagają od Ciebie niczego.** Commity podpisuje Twój klucz SSH
(`gpg.format = ssh`, `commit.gpgsign = true`), a każdy pakiet w obrazie — lokalny klucz
ed25519, który cookbook trzyma zaszyfrowany, z trybem `600`, w `build/` (katalog ignorowany
przez gita, więc klucz nigdy nie trafia do repozytorium).

### Warstwy 3 i 4 to DWA RÓŻNE klucze

Mylenie ich kończy się wygenerowaniem niewłaściwego albo nadpisaniem działającego:

| | warstwa 3 | warstwa 4 |
|---|---|---|
| narzędzie | `eos-repo-sign` | `minisign` |
| podpisuje | `repo.toml` (indeks pakietów) | `SHA256SUMS` (pliki wydania) |
| klucz publiczny | `keys/eos-repo-sign.pub.toml` | `keys/eos-release.pub` |
| jak założyć | `scripts/eos-key-bootstrap.sh` | `minisign -G` |
| kto weryfikuje | `pkg` na maszynie użytkownika | człowiek przed instalacją |

### Warstwa 4 — sytuacja wymaga decyzji

Klucz publiczny `keys/eos-release.pub` (minisign `DCEC85BA6057ED4A`) jest **zacommitowany w
repozytorium**, a `docs/install.md` i `docs/hardening.md` **instruują użytkowników**, żeby nim
weryfikowali pobrane pliki.

> **Sprostowanie do pierwszej wersji tej sekcji (`U-192`).** Napisałem tu, że klucz „jedzie w
> obrazie", opierając się na dwóch trafieniach `grep` na `eos-release` w `config/*/eos.toml`.
> **Oba dotyczyły komentarza o innym pliku** — `/usr/share/eos/eos-release`, identyfikatorze
> wydania. Sonda w **działającym obrazie** pokazuje, że `/usr/share/eos/` zawiera wyłącznie
> ten plik; klucza minisign w obrazie **nie ma**. Wniosek z liczby trafień, bez sprawdzenia,
> **co** trafiło, to ten sam błąd, który §20.6 każe wyłapywać u siebie. Konsekwencja jest
> dobra: rotacja **nie wymaga przebudowy obrazu ani przeobrazowania klientów**.

Połowy prywatnej nikt nie posiada. Wynikają z tego dwie rzeczy, i obie są prawdziwe naraz:

* **Nic się nie psuje po cichu.** `scripts/make-release.sh` **zawodzi bezpiecznie**: bez
  `MINISIGN_SECRET_KEY` odmawia złożenia wydania, zamiast wypuścić niepodpisane. Niepodpisane
  wymaga jawnego `EOS_ALLOW_UNSIGNED=1` (`U-120`).
* **Ale dokumentacja obiecuje weryfikację, której nie da się spełnić.** Dla każdego nowego
  wydania polecenie z `install.md` zawiedzie, bo nie będzie czego weryfikować.

**Zalecenie: rotować teraz.** Koszt rośnie z każdym wydaniem i z każdym obrazem, który ten
klucz roznosi:

```bash
minisign -G -p keys/eos-release.pub -s /ścieżka/poza-repo/eos-release.key
```

Nowy klucz publiczny zastępuje stary w `keys/`, klucz prywatny trafia **poza repozytorium**
i do kopii zapasowej, a `keys/eos-release.pub` wraca do bycia obietnicą, którą da się
dotrzymać. Rotacja unieważnia podpisy złożone starym kluczem — dla `0.1.0`/`0.2.0` to
akceptowalne, dla wydania z prawdziwymi użytkownikami już nie.

---

## 6b. Procedura — oba klucze, krok po kroku

Kolejność jest celowa. Klucz z warstwy 3 **trafia do obrazu**, klucz z warstwy 4 **nie** — więc
generujesz oba, a przebudowa jest **jedna**, na końcu.

Wszystko poniżej wykonujesz **Ty**, na swojej maszynie. Asystent nie bierze udziału w powstaniu
żadnego z tych kluczy i nie potrzebuje ich wartości, żeby sprawdzić skutek.

### Krok 0 — narzędzia (na tej maszynie brakuje obu, a `PATH` wymaga poprawki)

Sprawdzone na hoście: `minisign` nie jest zainstalowany, `rustup` **jest**, ale bez toolchaina
(`no installed toolchains`), a `cargo` jest potrzebny do zbudowania `eos-repo-sign`.

**Najpierw `PATH`, bo bez tego reszta kroku 0 nie zadziała.** Homebrew instaluje `rustup` jako
**keg-only** — jego `cargo` leży w `/opt/homebrew/opt/rustup/bin` i **nie jest** podlinkowany do
`PATH`. Bez poniższej linii `rustup default stable` wykona się, a `cargo` **nadal** będzie
„command not found", i `eos-key-bootstrap.sh` odeśle Cię z powrotem do `rustup` — w kółko.

```bash
echo 'export PATH="/opt/homebrew/opt/rustup/bin:$PATH"' >> ~/.zshrc
```

Potem **nowe okno terminala** (albo `source ~/.zshrc`) i dopiero:

```bash
rustup default stable
```

```bash
brew install minisign
```

Kontrola, że krok 0 się udał — obie linie muszą coś wypisać:

```bash
cargo --version && minisign -v
```

### Krok 1 — klucz podpisujący indeks pakietów (warstwa 3)

```bash
cd "E-OS"
scripts/eos-key-bootstrap.sh
```

Jedno polecenie robi całość: generuje parę hybrydową (ed25519 + ML-DSA-65), sprawdza tryb `0600`,
potwierdza, że sekret jest ignorowany przez gita, weryfikuje, że plik publiczny **nie zawiera**
materiału tajnego, przypina połowę publiczną do `config/{aarch64,x86_64}/eos.toml` pod
`/etc/pkg/eos-repo-sign.pub.toml` i uruchamia bramki. **Nie drukuje materiału klucza.**

Powstają dwa pliki, **w dwóch różnych miejscach**:

| plik | gdzie | co z nim |
|---|---|---|
| `~/.eos-keys/eos-repo-sign.secret.toml` | **dysk wewnętrzny** | **NIGDY** nie commituj; kopia zapasowa offline |
| `keys/eos-repo-sign.pub.toml` | w repozytorium | commitujesz — to on jedzie w obrazie |

> **Dlaczego sekret ląduje poza katalogiem projektu (`U-194`).** Katalog projektu stoi na
> wolumenie **exFAT** zamontowanym z opcją **`noowners`**. exFAT **nie przechowuje uprawnień
> POSIX**: narzędzie prosi o `0600`, plik i tak raportuje `700`, a `chmod` jest tam
> **bezczynny** — sprawdzone, ten sam plik dostaje `600` na dysku wewnętrznym, a `700` tutaj.
> `noowners` dodatkowo ignoruje właściciela. Klucz prywatny na takim wolumenie **nie ma
> żadnej ochrony systemu plików**: przeczyta go każde konto, które widzi dysk, a po
> podłączeniu nośnika do innego komputera — ktokolwiek. Domyślną ścieżkę zmienia
> `EOS_REPO_SIGN_KEY` — **ta sama zmienna**, której używają skrypty publikujące, więc
> ustawiona raz obsługuje i generowanie, i podpisywanie publikacji.

### Krok 2 — rotacja klucza wydań (warstwa 4)

Stary klucz publiczny odsuwasz, zamiast nadpisywać — żeby dało się jeszcze zweryfikować to, co
podpisano nim wcześniej:

```bash
mkdir -p keys/wycofane
git mv keys/eos-release.pub keys/wycofane/eos-release-DCEC85BA6057ED4A.pub
minisign -G -p keys/eos-release.pub -s ~/klucze-eos/eos-release.key
chmod 600 ~/klucze-eos/eos-release.key
```

Klucz **prywatny trafia poza repozytorium** — tu `~/klucze-eos/`, katalog, którego git nie widzi.
Ścieżka jest Twoim wyborem, byle nie w drzewie projektu.

Sprawdzenie, że rotacja się udała:

```bash
head -1 keys/eos-release.pub          # nowy odcisk, inny niż DCEC85BA6057ED4A
ls -l ~/klucze-eos/eos-release.key    # ma być -rw------- (600)
git status --short keys/              # klucz prywatny NIE MOŻE się tu pojawić
```

### Krok 3 — jedna przebudowa i weryfikacja w działającym systemie

```bash
scripts/eos-sync-buildtree.sh --apply     # bez tego build użyje starej konfiguracji
make CI=1 all
```

> Ten pierwszy wiersz nie jest formalnością. `make` buduje z osobnego drzewa w wolumenie i
> **nic go automatycznie nie synchronizuje** — pominięcie tego kroku sprawiło już raz, że
> poprawnie przypięty klucz nie znalazł się w obrazie, **bez jednego błędu po drodze**
> (`U-185`, `CLAUDE.md` §20.1).

Dowód, że klucz naprawdę jest w systemie, a nie tylko w pliku konfiguracyjnym:

```
ls /etc/pkg/          ->  eos-repo-sign.pub.toml  packages.toml
wc -c /etc/pkg/eos-repo-sign.pub.toml   ->  ten sam rozmiar co plik w keys/
```

Boot bez ostrzeżenia `no pinned repo-manifest key … NOT signature-verified` oznacza, że
klient przeszedł z trybu ostrzegawczego na **weryfikację zamykającą**: od tej chwili brakujący
albo nieprawidłowy podpis `repo.toml.sig` jest **błędem krytycznym**, nie uwagą.

### Krok 4 — commit połówek publicznych

```bash
git add keys/eos-repo-sign.pub.toml keys/eos-release.pub keys/wycofane/ config/
scripts/ci-integrity.sh          # kontrola 10 odrzuci commit, jeśli wciekł sekret
git commit -m "feat(keys): repo-signing key + release key rotation"
```

### Krok 5 — kopia zapasowa (rób to teraz, nie „potem")

Oba klucze prywatne, offline, w dwóch miejscach. **Nie ma odzyskiwania:**

* `eos-repo-sign keygen` **odmawia nadpisania** istniejącego pliku, więc klucza nie da się
  „wygenerować ponownie w miejsce" — jego utrata oznacza rotację i ponowne przypięcie u każdego
  klienta;
* utrata klucza minisign to dokładnie sytuacja, która wywołała `R-F26`.

### Czego ta procedura NIE daje

Po jej wykonaniu podpisane i weryfikowalne są: **kod** (warstwa 1), **pakiety** (2),
**indeks pakietów** (3) i **pliki wydania** (4). Nadal **nie** jest dowiedzione, że maszyna
wystartowała z niezmodyfikowanego obrazu — to warstwa 5 (Secure Boot / measured boot), która
w E-OS **nie istnieje** i jest jawnym non-goalem (`R-913`). Mówiąc „w pełni bezpieczny", warto
mieć tę granicę na uwadze.

---

## 7. Czego tu celowo NIE ma

**Klucza podpisującego wydania.** To nie jest token i nie należy do tej listy: patrz
[`keys/README.md`](../keys/README.md) i `scripts/eos-key-bootstrap.sh`. Generujesz go
**Ty, na swojej maszynie**, jednym poleceniem, a asystent nie bierze udziału w jego
powstaniu — bo klucz, który przeszedł przez cudze narzędzia, nie da się już zaświadczyć
jako nieskopiowany.

---

## 8. Rotacja i unieważnienie

* **Podejrzewasz wyciek — unieważnij natychmiast**, potem zastanawiaj się. Token jest tani,
  incydent nie.
* GitHub: *Settings → Developer settings → Tokens (classic)* → **Revoke**.
* GitLab: *Settings → Access tokens* → **Revoke**; zmienne CI usuwasz osobno w *CI/CD → Variables*.
* Po rotacji `RENOVATE_TOKEN` zadanie zgłasza *„Authentication failure"* — to znany objaw
  nieaktualnego tokenu, nie awaria bota (`docs/ci.md`).
