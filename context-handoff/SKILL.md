---
name: handoff
description: Use when user says "handoff", "przekaż kontekst", "zapisz stan", "zakończ sesję", "kontynuuj w nowej sesji", or when context window is running low and work needs to be preserved for the next session
---

# Context Handoff

Zapisz stan bieżącej pracy i wygeneruj instrukcję handoff dla kolejnej sesji Claude.

## Kiedy używać

- Użytkownik mówi `/handoff`, "przekaż kontekst", "zapisz stan"
- Kończy się okno kontekstowe i trzeba przekazać pracę
- Użytkownik chce przerwać i kontynuować później

## Proces

### 1. Zbierz stan

Przeanalizuj bieżącą konwersację i zbierz:

| Element | Co zebrać |
|---------|-----------|
| **Zadanie** | Co było celem tej sesji |
| **Zrobione** | Co udało się ukończyć (konkretne pliki, commity) |
| **W trakcie** | Nad czym aktualnie pracowałeś |
| **Pozostało** | Co jeszcze trzeba zrobić |
| **Decyzje** | Kluczowe decyzje i ich uzasadnienia |
| **Blokery** | Problemy, errory, rzeczy do rozwiązania |
| **Zmienione pliki** | `git diff --name-only` + `git status` |
| **Następny krok** | Konkretna pierwsza akcja dla następnej sesji |

### 2. Zapisz do memory

Zaktualizuj plik `MEMORY.md` w katalogu auto-memory projektu:
- Sekcja `## Stan projektu` — zaktualizuj datę i status
- Sekcja `## Aktywne zadanie` — opisz bieżące zadanie i postęp
- Dodaj/zaktualizuj inne sekcje jeśli potrzeba

**NIE twórz nowych plików** — aktualizuj istniejący MEMORY.md.

### 3. Wygeneruj prompt handoff

Wyświetl użytkownikowi gotowy prompt do wklejenia w nowej sesji:

```
---HANDOFF START---

## Kontekst
[1-2 zdania: co to za projekt i nad czym pracowaliśmy]

## Co zrobiono
- [konkretne ukończone rzeczy]

## Co zostało do zrobienia
- [konkretne pozostałe zadania, od najpilniejszego]

## Bieżący stan
- Branch: [nazwa]
- Ostatni commit: [hash + message]
- Niezacommitowane zmiany: [tak/nie, jakie pliki]
- Build status: [przechodzi/nie przechodzi]

## Kluczowe decyzje
- [decyzja]: [dlaczego]

## Blokery / Uwagi
- [jeśli są]

## Rozpocznij od
[Konkretna pierwsza akcja — jedno zdanie]

---HANDOFF END---
```

### 4. Potwierdź

Powiedz użytkownikowi:
- Że MEMORY.md został zaktualizowany
- Że prompt handoff jest gotowy do skopiowania
- Że wystarczy go wkleić na początku nowej sesji

## Zasady

- **Bądź konkretny** — nazwy plików, numery linii, hashe commitów
- **Bądź zwięzły** — handoff to max 30 linii, nie esej
- **Priorytetyzuj** — najważniejsze rzeczy na górze
- **Nie zgaduj** — jeśli czegoś nie wiesz, pomiń lub zaznacz jako "do sprawdzenia"
- **Git status** — zawsze sprawdź `git status` i `git log -1` przed generowaniem handoffu

## Checklist pre-handoff

Zanim zaczniesz zbierać stan, uruchom:

1. `git status` — czy są niezacommitowane zmiany?
2. `git diff --stat` — jaki jest zakres zmian?
3. `git log --oneline -5` — ostatnie commity dla kontekstu

**Jeśli są niezacommitowane zmiany:**
- Sensowne samodzielnie → zacommituj z normalnym komunikatem
- Work-in-progress → zacommituj z prefixem: `[WIP] [handoff] Opis stanu`
- Eksperymentalne → opisz w handoffie bez commitowania

## Szablony wg typu pracy

### Feature development (domyślny)
Użyj standardowego szablonu z sekcji wyżej.

### Bug fix
```
## Kontekst
[Opis buga i jego efektu]

## Co zrobiono
- [Diagnoza: co było przyczyną]
- [Fix: co zmieniono i dlaczego]

## Co zostało
1. Testowanie: [jak zweryfikować fix]
2. Code review: [na co reviewer powinien zwrócić uwagę]

## Jak testować
[Konkretne kroki reprodukcji + weryfikacji]

## Rozpocznij od
[Następna akcja]
```

### Refactoring
```
## Kontekst
Refactoring: [główny obszar, np. "Wymiana AuthContext na Zustand"]

## Co zrobiono
- [Pliki/komponenty przerobione]

## Co zostało
- [Pliki do przerobienia]
- [Testy do aktualizacji]

## Bieżący stan
- Testy: [przechodzą / X failuje]
- Breaking changes: [tak/nie, jakie]

## Rozpocznij od
[Następny plik/komponent]
```

## Elementy warunkowe

Dodaj do handoffu jeśli:
- Są niezacommitowane zmiany → pokaż `git status` w "Bieżący stan"
- Nowa konfiguracja (env, tsconfig) → opisz co się zmieniło
- Build failuje → pokaż error log w "Blokery"
- Otwarte pytania → wymień je w "Uwagi"

## Zamykanie handoffów (cross-project)

Gdy w trakcie sesji **zamkniesz zadanie opisane w handoffie z innego projektu**, oznacz ten handoff jako zamknięty:

### Kiedy zamykać
- Zrobiłeś commit który realizuje zadanie z handoffu
- User potwierdził że zadanie zostało wykonane (np. "to już zrobione")
- Agent z innego projektu poinformował o zamknięciu

### Jak zamykać
Dopisz na końcu pliku handoffu:

```markdown

## Status: ZAMKNIĘTE
**Zamknięte:** YYYY-MM-DD
**Przez:** [agent/projekt/sesja]
**Commit/dowód:** [hash commitu lub krótki opis]
```

### Gdzie szukać handoffów do zamknięcia
- Katalog `.ai/handoffs/` w projekcie którego dotyczy zadanie
- Skan ekosystemu z hooka SessionStart (lista na początku sesji PM)

### WAŻNE
- NIE usuwaj handoffu — tylko dopisz sekcję Status
- NIE zamykaj handoffów o których nie masz pewności — w razie wątpliwości zapytaj usera
- Scanner ekosystemu (`scan-all-handoffs.sh`) automatycznie pomija handoffy z `## Status: ZAMKNIĘTE`
