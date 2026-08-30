# Architektura — diagramy i specyfikacje

Ten katalog trzyma dwa rodzaje dokumentów. **Diagramy** opisują stan, który da się sprawdzić
w drzewie. **Specyfikacje** opisują to, co ma powstać — i wtedy każda zamówiona zdolność nosi
jawny znacznik (JEST / DO ZBUDOWANIA / NOWY PODSYSTEM / NIEREALNE DZIŚ), żeby projekt nie dał
się pomylić z pomiarem. Specyfikacja zaczyna się nagłówkiem `Status: Propozycja`.

## Diagramy

Mermaid, renderowany przez `mdbook-mermaid` (wpięty w zadania `pages` i `docs-pdf`). Trzymamy je
**blisko faktów**: każdy diagram opisuje stan, który da się sprawdzić w drzewie, a nie zamiar.

- [Topologia repozytoriów](topologia-repozytoriow.md) — 30 repo, cztery typy, kierunek luster
- [Ścieżka budowania](sciezka-budowania.md) — od przepisu do obrazu, z rozwidleniem `REPO_BINARY`

## Specyfikacje

- [Instalator na nośniku USB](installer.md) — nośnik instalacyjny i instalacja na dysk
  wewnętrzny: stan faktyczny wobec zamówienia, rozruch (odwołanie do `ADR-0005`/`ADR-0006`),
  partycjonowanie, transakcja instalacji, odzyskiwanie, macierz testów na metalu
- [Kreator instalacji](installer-wizard.md) — semantyka i UX kreatora: maszyna stanów, wybór
  dysku i bariery przy destrukcji, szyfrowanie, profile Gamer/Business/Ghost, plik odpowiedzi
- [Model danych profili i funkcji](installer-profiles.md) — format danych, z których kreator,
  dokumentacja i tryb nienadzorowany czytają ten sam zestaw decyzji
- [System aktualizacji](system-updates.md) — wybór mechanizmu (analiza stojąca za `ADR-0009`),
  staging i pobieranie, weryfikacja kryptograficzna, atomowa aktywacja przy restarcie, styk
  z FDE i Secure Bootem, kanały i polityki, zanik zasilania, ścieżka migracji `E0`–`E8`

Szerszy opis systemu: [`../architecture.md`](../architecture.md).
