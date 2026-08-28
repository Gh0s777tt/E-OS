# ADR-0004 — Hybrydowy podpis manifestu repozytorium (ed25519 + ML-DSA-65)

- **Status:** Przyjęty i **wdrożony** (`U-196`/`U-197`) — publisher gotowy, klient w obrazie od `U-165`, klucz wygenerowany i przypięty. Treść decyzji poniżej pozostaje bez zmian, bo ADR jest niezmienny (`docs/adr/README.md`); zmienia się wyłącznie pole Status.
- **Data:** 2026-08-23
- **Dowód:** `docs/security.md`, `tools/eos-repo-sign`, `R-503`, `R-702`, `R-703`, `U-164`

## Kontekst

`repo.toml` wylicza hash blake3 każdego pakietu, więc podpis nad tym plikiem uwierzytelnia
całe repozytorium. Dotychczasową kotwicą zaufania jest **ed25519** (pkgar). Przeciwnik
zbierający dziś podpisane artefakty mógłby je sfałszować, gdy powstanie odpowiednio duży
komputer kwantowy.

## Decyzja

Podpis manifestu jest **hybrydowy**: klasyczny **ed25519** *oraz* postkwantowy
**ML-DSA-65** (FIPS 204). Fałszerstwo wymaga złamania **obu**, więc hybryda nigdy nie jest
słabsza niż samo ed25519. Narzędzie: `tools/eos-repo-sign` (host, nie trafia na Redoksa).

## Odrzucone warianty

- **Wymiana ed25519 na ML-DSA** — złamałaby starsze klienty i postawiłaby całe zaufanie na
  młodszej kryptografii.
- **Tylko ed25519** — nie adresuje ryzyka „zbierz teraz, odszyfruj później".
- **Podpisywanie każdego pakietu osobno postkwantowo** — koszt bez zysku: manifest już
  wiąże wszystkie hashe.

## Konsekwencje

- Rozmiary: ed25519 klucz 32 B / podpis 64 B; ML-DSA-65 klucz 1952 B / podpis 3309 B.
- Plik `.sig` jest płaskim, czytelnym tekstem w hex.
- **Klucz wciąż nie istnieje** — generowanie jest działaniem człowieka (§10.1), a bez niego
  klient ostrzega i kontynuuje zamiast odmawiać. To blokuje `R-008`, `R-701`, `R-702`,
  `R-703`.
- Lekcja z `U-164`: „zaimplementowane w forku" i „obecne w artefakcie" to **dwa różne
  twierdzenia** — kliencka połowa była gotowa miesiącami i nie trafiała do obrazu.
