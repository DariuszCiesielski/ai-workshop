---
name: dual-agent-review
description: Dwuagentowa weryfikacja (Claude Code + Codex) — niezależna analiza designu, szarych stref, kodu, PRD lub schematu DB z automatycznym porównaniem wyników i rekomendacją. Używaj gdy potrzebna druga opinia, dual review, weryfikacja przez Codexa, niezależna recenzja lub porównanie opinii agentów.
---

# Dual-Agent Review: Claude Code + Codex

## Kiedy używać

- Ważne decyzje architektoniczne przed implementacją
- Szare strefy UX/biznesowe wymagające konkretnych rozwiązań
- Review designu, PRD, schematu DB
- Code review krytycznych zmian
- Gdy chcesz drugą, niezależną opinię

## Przepływ

```
1. Rozpoznaj TYP review (auto lub z kontekstu)
2. Claude Code przeprowadza WŁASNĄ analizę
3. Równolegle: stwórz zadanie dla Codexa (.codex/tasks/)
4. Użytkownik uruchamia Codexa w Cursor
5. Codex dostarcza raport (.codex/reports/)
6. Claude Code porównuje oba review (tabela zbieżności/rozbieżności)
7. Użytkownik zatwierdza rekomendacje
8. Archiwizuj raport Codexa (.codex/archived/)
```

## Typy review

### 1. Design Review (`design`)

**Kiedy:** nowy design doc, plan architektury, diagram przepływów
**Format zadania:** "Oto design [X]. Oceń go krytycznie."

Sekcje zadania:
- Kontekst projektu (stack, architektura, istniejące wzorce)
- Kluczowe decyzje projektowe z uzasadnieniem
- Schemat DB / przepływy danych
- Pytanie: krytyczna analiza, alternatywy, braki, priorytety

Format raportu Codexa:
- Ocena ogólna (1-10)
- Mocne strony
- Słabości i ryzyka
- Alternatywne propozycje
- Brakujące elementy
- Sugerowana kolejność implementacji

### 2. Gray Areas (`gray-areas`)

**Kiedy:** zidentyfikowane szare strefy wymagające konkretnych rozwiązań
**Format zadania:** "Oto [N] szarych stref. Zaproponuj JEDNO spójne rozwiązanie per strefa."

Sekcje zadania:
- Kontekst projektu (stack, architektura)
- Istniejące wzorce w projekcie (reuse!)
- Schemat DB (jeśli istnieje)
- Lista szarych stref z pytaniami szczegółowymi
- Pytanie: konkretna propozycja + uzasadnienie + wzorzec z projektu + edge cases

Format raportu Codexa:
- Per szara strefa: Propozycja → Uzasadnienie → Wzorzec → Edge cases

### 3. Code Review (`code`)

**Kiedy:** krytyczne zmiany w kodzie, nowy moduł, refactoring
**Format zadania:** "Oto kod [X]. Znajdź problemy."

Sekcje zadania:
- Kontekst modułu (co robi, jak się integruje)
- Kod do review (pliki + diff)
- Konwencje projektu (z CLAUDE.md)
- Pytanie: bugi, bezpieczeństwo, edge cases, uproszczenia

Format raportu Codexa:
- Krytyczne problemy (bugi, bezpieczeństwo)
- Ostrzeżenia (edge cases, kruche elementy)
- Sugestie (uproszczenia, lepsze wzorce)
- Ocena jakości (1-10)

### 4. PRD / Requirements Review (`prd`)

**Kiedy:** nowy dokument wymagań, roadmapa
**Format zadania:** "Oto PRD [X]. Czy jest kompletny i spójny?"

Sekcje zadania:
- PRD / wymagania
- Kontekst biznesowy
- Istniejąca architektura
- Pytanie: luki, sprzeczności, brakujące scenariusze, priorytety

Format raportu Codexa:
- Kompletność (co brakuje)
- Spójność (co się kłóci)
- Wykonalność (co jest ryzykowne technicznie)
- Priorytety (co najpierw)

### 5. Schema Review (`schema`)

**Kiedy:** nowa migracja DB, zmiana schematu
**Format zadania:** "Oto schemat [X]. Czy jest poprawny i rozszerzalny?"

Sekcje zadania:
- SQL migracji
- Istniejące tabele (relacje, RLS)
- Planowane rozszerzenia (co może się zmienić)
- Pytanie: normalizacja, indeksy, RLS, rozszerzalność, edge cases

Format raportu Codexa:
- Poprawność (typy, constrainty, relacje)
- Bezpieczeństwo (RLS, auth chain)
- Rozszerzalność (przyszłe zmiany bez breaking)
- Wydajność (indeksy, query patterns)

## Budowanie zadania — zasady

### ZAWSZE dołączaj (niezależnie od typu):

1. **Pełny kontekst projektu** — stack, architektura, konwencje. Codex NIE zna kontekstu sesji.
2. **Istniejące wzorce** — co już jest w projekcie i można reuse'ować. Codex musi wiedzieć co działa.
3. **Schemat DB** (jeśli dotyczy) — tabele, relacje, RLS.
4. **Oczekiwany format raportu** — dokładna struktura, żeby porównanie było łatwe.

### NIGDY nie rób:

1. **Nie sugeruj odpowiedzi** — nie pisz "moim zdaniem X" w zadaniu. Codex ma myśleć niezależnie.
2. **Nie skracaj kontekstu** — lepiej za dużo niż za mało. Codex nie może dopytać.
3. **Nie łącz typów** — jedno zadanie = jeden typ review. Przy potrzebie wielu → osobne zadania.

### Numeracja

Ciągła z innymi zadaniami Codexa: `.codex/tasks/NNN-review-[nazwa].md`
Raport: `.codex/reports/NNN-[nazwa].done.md`

## Własna analiza Claude Code

Równolegle z zadaniem dla Codexa, Claude Code przeprowadza WŁASNĄ analizę tego samego materiału.

### Checklist (dopasuj do typu review):

| # | Aspekt | Design | Gray Areas | Code | PRD | Schema |
|---|--------|--------|------------|------|-----|--------|
| 1 | Bezpieczeństwo (RLS, auth, injection) | ✓ | — | ✓ | — | ✓ |
| 2 | Skalowalność (10x/100x) | ✓ | — | ✓ | — | ✓ |
| 3 | Koszty (AI calls, rate limiting) | ✓ | ✓ | — | ✓ | — |
| 4 | UX (irytacja, opt-in/out) | ✓ | ✓ | — | ✓ | — |
| 5 | Spójność z istniejącą architekturą | ✓ | ✓ | ✓ | ✓ | ✓ |
| 6 | YAGNI (co usunąć) | ✓ | — | ✓ | ✓ | ✓ |
| 7 | Kruche elementy | ✓ | ✓ | ✓ | — | — |
| 8 | Rozszerzalność DB | ✓ | — | — | — | ✓ |
| 9 | Separacja domen | ✓ | — | ✓ | ✓ | ✓ |
| 10 | Edge cases (AI śmieci, timeout, pusty wynik) | ✓ | ✓ | ✓ | — | — |

## Porównanie wyników

Po otrzymaniu raportu Codexa, ZAWSZE przedstaw porównanie w tym formacie:

```markdown
## Porównanie review: Claude Code vs Codex

### Zgodność (oba agenty się zgadzają)
- [punkt — zwięźle, 1 linia]

### Rozbieżności (różne opinie)
| Temat | Claude Code | Codex | Rekomendacja |
|-------|-------------|-------|--------------|
| ...   | ...         | ...   | [kto ma rację i dlaczego] |

### Unikalne spostrzeżenia
- **Tylko Claude Code:** [punkt]
- **Tylko Codex:** [punkt]

### Finalna rekomendacja
[Połączony zestaw decyzji — tabela lub lista]
```

### Zasady porównania

- **Obiektywnie** — jeśli Codex ma rację, przyznaj to wprost
- **Bez ego** — nie faworyzuj swojej analizy
- **Konkretnie** — "Rekomendacja: podejście Codexa, bo [powód]", nie "oba podejścia mają zalety"
- **Użytkownik decyduje** — przedstaw rekomendację, ale nie implementuj bez zatwierdzenia

## Po zatwierdzeniu

1. Archiwizuj raport: `mv .codex/reports/NNN-*.done.md .codex/archived/`
2. Zapisz decyzje w odpowiednim miejscu (CONTEXT.md, design doc, CLAUDE.md)
3. NIE implementuj zmian bez jawnego polecenia użytkownika

## Zastępuje

Ten skill zastępuje `codex-design-review`. Cały przepływ delegowania zadań (tworzenie, numeracja, statusy) korzysta z konwencji `codex-delegation`.
