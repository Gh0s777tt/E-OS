# ADR-0001 — GitLab jest źródłem prawdy, GitHub lustrem tylko do odczytu

- **Status:** Przyjęty
- **Data:** 2026-08-23 (spisane; decyzja obowiązuje wcześniej)
- **Dowód:** `CLAUDE.md` §5, `repos.toml`, `scripts/eos-setup-mirrors.sh`, `U-152`, `U-158`

## Kontekst

Ekosystem to 30 repozytoriów na dwóch hostach. GitHub Actions są wyłączone na poziomie
konta, więc CI musi żyć na GitLabie. Bez jednego źródła prawdy każdy push wymagałby
decyzji „gdzie właściwie", a rozjazd wykryto by dopiero przy budowaniu.

## Decyzja

`gitlab.com/e-os/e-os` jest źródłem prawdy. GitHub (`Gh0s777tt/*`) jest **lustrem tylko do
odczytu**, zasilanym push-mirrorem GitLaba. Przepisy pobierają przypięte rewizje z lustra
GitHuba, bo to ono jest publicznie dostępne bez uwierzytelnienia.

## Odrzucone warianty

- **GitHub jako źródło prawdy** — odpada, bo Actions są wyłączone, a CI jest warunkiem
  koniecznym (§13).
- **Tylko GitLab, bez lustra** — odpada, bo przepisy cookbooka pobierają źródła po HTTPS
  i publiczna dostępność ma znaczenie dla odtwarzalności builda u kogoś innego.
- **Ręczne pushe na oba hosty dla wszystkiego** — odrzucone dla meta-repo (lustro robi to
  lepiej), **wymuszone dla forków**, bo one lustra nie mają (§1.6).

## Konsekwencje

- Meta-repo: push **wyłącznie na GitLab**; ręczny push na GitHuba ściga się z lustrem.
- Forki: **dwa pushe**, każdy zweryfikowany `git ls-remote` przed podbiciem pina.
- **Lustro replikuje pushe, ale nie kasowania** — usunięcie gałęzi trzeba wykonać osobno.
- Gałąź trafia na lustro w sekundy, **tag dopiero przy następnym przebiegu (~5 min)**
  (`U-152`) — cisza przez dwie minuty nie jest awarią.
- Repozytoria pakietów (`role = "pkg"`) **nie mogą** mieć lustra: push-mirror nadpisałby
  opublikowaną zawartość (`U-158`).
