# ADR-0003 — Vendorowany kod zostaje na formie upstreamu

- **Status:** Przyjęty
- **Data:** 2026-08-23
- **Dowód:** `CLAUDE.md` §3, §11 typ B; `scripts/ci-integrity.sh` kontrole 1/4/5; `U-159`

## Kontekst

Repo zawiera trzy rodzaje kodu: własny E-OS (`tools/eos-repo-sign`, aplikacje `eos-*`),
vendorowany silnik budowania (`src/`, skrzynka `redox_cookbook`) i odziedziczone skrypty
(`build.sh`, `*_bootstrap.sh`, `recipes/wip/`, `upstream/`).

Pierwszy przebieg shellchecka dał **188 uwag**: **47 w `scripts/`** (kod E-OS) i
**141 w kodzie odziedziczonym**. Pokrycie testami: `tools/eos-repo-sign` **38,84%**,
vendorowany cookbook **2,92%**.

## Decyzja

Bramki jakości obejmują **wyłącznie kod należący do E-OS**. Vendorowany i odziedziczony
kod jest budowany i używany, ale nie podlega naszym standardom stylu, pokrycia ani
adnotacji `SAFETY:`.

Konkretnie: shellcheck gatuje `scripts/`; kontrola `unsafe` wyłącza `src/`; bramka pokrycia
obejmuje `tools/eos-repo-sign`, a vendorowany manifest jest **raportowany, nie gatowany**;
`cargo-deny` sprawdza `advisories` na obu manifestach, ale **nie** licencje i źródła.

## Odrzucone warianty

- **Gatować wszystko** — oznaczałoby przepisywanie cudzego kodu i utrzymywanie dywergencji
  przy każdej synchronizacji, bez zysku dla bezpieczeństwa.
- **Nie gatować niczego** — 3 realne błędy shellchecka w `scripts/` (niecytowane `$@`/`$*`,
  tablica w napisie) były prawdziwymi wadami na hoście ze spacją w ścieżce.
- **Fork z poprawkami stylu** — najgorszy wariant: koszt przy każdym syncu, zero wartości.

## Konsekwencje

- Liczby w bramkach są **małe i prawdziwe**, więc czerwone CI coś znaczy.
- `cargo-deny check advisories` na vendorowanym manifeście **wykrył realne CVE**
  (`RUSTSEC-2026-0204`, `crossbeam-epoch 0.9.18`) — bezpieczeństwo gatujemy nawet tam,
  gdzie stylu nie gatujemy.
- Dług: jeśli kiedyś zaczniemy realnie rozwijać vendorowany cookbook, ten ADR wymaga
  zastąpienia.
