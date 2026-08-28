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
