---
title: ADR-0006: Ścieżka do weryfikacji Microsoftu — przygotowanie bez zobowiązania
status: accepted
last-reviewed: 2026-08-30
owner: Gh0s777tt
---

# ADR-0006: Ścieżka do weryfikacji Microsoftu — przygotowanie bez zobowiązania

- **Status:** Przyjęty. **Uzupełnia [ADR-0005](0005-secure-boot-without-microsoft.md), nie zastępuje go.**
- **Kontekst:** `V2-MS01`–`V2-MS11`, `R-F27`, ROADMAP.md §5.1
- **Data:** 2026-08-29 (`U-211`)

## Problem

`ADR-0005` zdecydował, że E-OS **świadomie nie wybiera** ścieżki shima podpisanego przez
Microsoft. Właściciel projektu postawił jednak cel wprost: *żeby system działał na każdym
sprzęcie tak, jak powinien*, i poprosił o audyt wobec `rhboot/shim-review`. To jest pytanie
o **zmianę decyzji z ADR-0005**, więc wymaga własnego zapisu.

## Ustalenia

Repozytorium `rhboot/shim-review` zostało sklonowane i przeczytane w całości (README z 39 blokami
pytań, `docs/submitting.md`, `docs/reviewer-guidelines.md`). Stan certyfikatów odczytany
bezpośrednio z `microsoft/secureboot_objects`. Stan E-OS zmierzony w binarce i w drzewie.

**Trzy fakty zmieniają rachunek w porównaniu z tym, co obowiązywało przy ADR-0005:**

1. **Okno podwójnego podpisu zamknęło się 27 czerwca 2026.** Shim wydany dziś jest podpisany
   **wyłącznie** przez `Microsoft UEFI CA 2023`. Maszyna, która ma w `db` tylko `Microsoft
   Corporation UEFI CA 2011` (wygasł 2026-06-27), **takiego shima nie uruchomi**. Ścieżka shim
   daje dziś pokrycie sprzętu **węższe** niż dwa lata temu — czyli działa *przeciw* postawionemu
   celowi, dopóki park maszyn się nie wymieni.

2. **Blokady są pozatechniczne.** Wymagane są: wpis do rejestru osoby prawnej, certyfikat EV,
   **dwa** kontakty bezpieczeństwa z kluczami PGP zweryfikowanymi zaszyfrowaną korespondencją,
   klucz w module sprzętowym **FIPS 140-2 Level 2**, oraz wiarygodność długoterminowa —
   wytyczne recenzentów mówią wprost: *„A tiny 1-man outfit may just go away without warning"*.
   Żadnej z tych rzeczy nie zdejmie praca programistyczna.

3. **Nasz drugi stopień jest nietypowy.** shim-review deklaruje kompetencje wyłącznie w GRUB2
   i systemd-boot; własny bootloader w Ruście dostaje etykietę `custom second-stage` i wymaga
   dodatkowej, pełnej recenzji. Zmierzony czas przejścia recenzji **przy komplecie dokumentów**:
   od ~5,5 tygodnia do ~7 miesięcy, przy trzech niezależnych recenzjach, w tym jednej akredytowanej.

**Co natomiast okazało się już zrobione** (zmierzone, nie deklarowane): nagłówek PE naszego
bootloadera spełnia **trzy twarde wymogi Microsoftu** — `SectionAlignment=4096`, brak sekcji
łączącej zapis z wykonaniem, oraz ustawiony bit `NX_COMPAT` (`DllCharacteristics=0x8160`,
z `DYNAMIC_BASE` i `HIGH_ENTROPY_VA`). Nikt tego wcześniej nie sprawdzał.

## Decyzja

**ADR-0005 pozostaje w mocy jako tor domyślny.** Własny klucz i zaufanie kontrolowane przez
właściciela **działa dziś i jest udowodnione** na obu nośnikach kluczem operatora (`U-210`).

Dodatkowo przyjmujemy **tor B: przygotowanie bez zobowiązania.** Robimy te elementy wymagane
przez shim-review, **które mają wartość same w sobie**, niezależnie od tego, czy zgłoszenie do
Microsoftu kiedykolwiek nastąpi:

| zadanie | wartość niezależna od Microsoftu |
|---|---|
| `V2-MS02` weryfikacja jądra i initfs | **zamyka realną dziurę** — dziś bootloader sprawdza wyłącznie bajty magiczne, więc podmiana `usr/lib/boot/kernel` przechodzi bez szmeru |
| `V2-MS01` sekcja `.sbat` | własny mechanizm unieważniania wersji, bez czekania na DBX |
| `V2-MS03` naprawa trzech dokumentów | dziś `threat-model.md`, `hardening.md` i `plan-do-sprzetu.md` **zaprzeczają kodowi** |
| `V2-MS04` bramka Secure Boot w CI | dowód przestaje zależeć od jednego laptopa |
| `V2-MS05` hermetyczne podpisywanie | wersja `sbsigntool` przestaje być pobierana z sieci w czasie builda |
| `V2-MS06` klucz na tokenie | klucz podpisujący rozruch przestaje być plikiem bez hasła |
| `V2-MS07` reprodukowalność bajtowa | i tak wymagana przez `R-303` |
| `V2-MS08` SBOM przy każdym buildzie | dziś SBOM jest statyczny dla 0.1.0 i cicho się starzeje |

**Czego świadomie NIE robimy teraz:** `V2-MS11` (chainload przez shim) jest bezcelowy przed
`V2-MS10` (decyzja o osobie prawnej i certyfikacie EV), a `V2-MS10` **nie jest decyzją
techniczną** — należy do właściciela projektu.

## Konsekwencje

- **Cel „działa na każdym sprzęcie" nie zostaje osiągnięty tą drogą w tym roku** i dokumentacja
  ma to mówić wprost, zamiast obiecywać. Na obcym x86_64 zostaje jeden krok właściciela.
- **Bezpieczeństwo E-OS rośnie mimo to** — tor B to osiem realnych ulepszeń, z których
  `V2-MS02` jest poprawką bezpieczeństwa o priorytecie P0, niezależną od jakiejkolwiek recenzji.
- **Decyzja jest odwracalna w jedną stronę:** gdy `V2-MS10` zostanie kiedyś podjęte, tor B
  zostawia projekt o krok od zgłoszenia zamiast o rok.
- Gdyby E-OS miał kiedyś trafić na sprzęt wydawany przez projekt, **pre-enroll klucza** z
  ADR-0005 pozostaje ścieżką lepszą niż shim: pełna automatyka, zero zależności.
