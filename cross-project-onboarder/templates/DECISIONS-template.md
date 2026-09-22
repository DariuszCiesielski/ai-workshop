# DECISIONS — rejestr decyzji (ADR, format MADR-lite)

> **Po co:** po roku odpowiada na „dlaczego kod / proces wygląda tak, a nie inaczej". PROJECT_CARD mówi CO i CZY SPEŁNIONE; ten plik mówi DLACZEGO.
> **Zasady:** jeden wpis = jedna decyzja, < 200 linii. `Accepted` jest **niezmienne** — zmiana zdania = nowy ADR + stary dostaje `Superseded by ADR-N` (nie kasujemy, nie edytujemy treści). Każdy ADR ze statusem Accepted **musi** mieć odbicie jako zdanie MUST / MUST NOT w `CLAUDE.md` projektu (sekcja „Reguły z decyzji") — inaczej agenci go nie znają. Wpis, którego nie da się sprowadzić do MUST/MUST NOT, jest zwykle notatką, nie decyzją.
> **Czego NIE wpisywać:** rutyny („kontynuujemy"), wyborów bez alternatywy, rzeczy odwracalnych w 5 minut. Filtr: *czy ktoś za pół roku zapyta „czemu tak?”* — tak → ADR.
> **Numeracja:** ADR-0000 = wprowadzenie ADR w tym projekcie. Commity/handoffy: `Refs: ADR-3`.

---

## ADR-0000 — Wprowadzamy rejestr decyzji (ADR) w tym projekcie
- **Status:** Accepted — YYYY-MM-DD
- **Kontekst:** decyzje projektowe żyły w handoffach i pamięci sesji; po tygodniach nie dało się odtworzyć, dlaczego coś zbudowano tak, a nie inaczej (precedens ekosystemu: zdublowany LaunchAgent Gmaila biegł 2 miesiące niezauważony; porty idei z cudzych repo bez śladu licencji).
- **Decyzja:** każda decyzja o trwałych konsekwencjach (architektura, dostawca, licencja, kryterium odbioru, rezygnacja z funkcji) dostaje wpis tutaj w formacie MADR-lite; Accepted niezmienne; każdy ADR → reguła MUST/MUST NOT w CLAUDE.md projektu.
- **Alternatywy odrzucone:** (a) tylko handoffy — efemeryczne, nieprzeszukiwalne po temacie; (b) pełny MADR z YAML + narzędzia (adr-tools, log4brains) — przerost dla 1 osoby + agentów; (c) Diátaxis/C4/RFC — 2 czytelników (Dariusz + agent), nie zespół.
- **Konsekwencje:** + historia „dlaczego" w jednym pliku, + agenci dostają reguły zamiast ogólników; − koszt ~5 min na decyzję; ryzyko boilerplate → kwartalny audyt 5 losowych wpisów (Faza C).
- **Reguła dla agentów (→ CLAUDE.md):** MUST: decyzja o trwałych konsekwencjach = wpis ADR w tej samej sesji + `Refs:` w commicie. MUST NOT: edytować treść ADR ze statusem Accepted.
- **Weryfikacja:** `grep -c "^## ADR-" docs/DECISIONS.md` rośnie przy decyzjach; `grep "Reguły z decyzji" CLAUDE.md`.

---

## ADR-NNNN — <tytuł w trybie oznajmującym: „Cytujemy tezy po numerze zdania”, nie „Cytowanie”>
- **Status:** Proposed | Accepted — YYYY-MM-DD | Superseded by ADR-M — YYYY-MM-DD | Rejected
- **Kontekst:** <2–5 zdań: jaki problem, jakie ograniczenia, co zmierzyliśmy (liczby z datą i źródłem)>
- **Decyzja:** <1–3 zdania, czas teraźniejszy: „Robimy X.”>
- **Alternatywy odrzucone:** <każda z jednym powodem — to najcenniejsza część wpisu>
- **Konsekwencje:** <+ zyski / − koszty i ryzyka; co trzeba teraz pilnować>
- **Pochodzenie / licencja:** <repo/URL + licencja z pliku LICENSE | własne> — WYMAGANE, gdy pomysł lub kod przyszedł z zewnątrz
- **Reguła dla agentów (→ CLAUDE.md):** MUST: … / MUST NOT: …
- **Weryfikacja:** <jedna komenda lub test, który pokaże, że decyzja jest respektowana — `grep`, test, zapytanie SQL>
- **Refs:** KRYT-x.y, commit, handoff
