# Architecture Decision Records

Krótkie zapisy decyzji, które trudno odtworzyć z samego kodu: **co** postanowiono,
**dlaczego**, i **co odrzucono**. Jeden plik na decyzję, numeracja rosnąca, nazwy
`NNNN-krotki-tytul.md`.

ADR jest **niezmienny**. Gdy decyzja przestaje obowiązywać, nie przepisuj starego wpisu —
dodaj nowy ze statusem *Zastępuje ADR-NNNN* i ustaw w starym *Zastąpiony przez ADR-MMMM*.
Ta sama zasada co w `CLAUDE.md` §2 reguła 4: poprawka ma być widoczna.

**Statusy:** `Proponowany` · `Przyjęty` · `Zastąpiony przez ADR-NNNN` · `Odrzucony`

Szablon: [`0000-szablon.md`](0000-szablon.md).

> Wiele decyzji w tym projekcie zostało do tej pory zapisanych **wyłącznie** we wpisach
> `U-NNN` w `CHANGELOG.md`. Poniższe ADR-y wyciągają z nich te, które są nadrzędne wobec
> pojedynczej zmiany. CHANGELOG pozostaje dowodem; ADR jest streszczeniem decyzji.
