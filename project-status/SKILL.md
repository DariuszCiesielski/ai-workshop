---
name: status
description: Use when user says "status", "stan projektu", "co się dzieje", "gdzie jestem" — quick project status overview
---

# Project Status

Szybki przegląd stanu projektu w jednym widoku.

## Proces

### 1. Zbierz dane

Wykonaj równolegle:
- `git status` — niezacommitowane zmiany
- `git log --oneline -5` — ostatnie commity
- `git branch --show-current` — aktualny branch
- Przeczytaj MEMORY.md z katalogu auto-memory projektu

### 2. Wyświetl podsumowanie

```
📍 Status: [nazwa projektu]
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branch:     [nazwa]
Commit:     [hash] [message]
Zmiany:     [X plików zmodyfikowanych / czyste repo]

Aktywne zadanie: [z MEMORY.md lub "brak"]
Następny krok:   [z MEMORY.md lub "nie określono"]

Blokery: [z MEMORY.md lub "brak"]
```

### 3. Jeśli są niezacommitowane zmiany

Dołącz listę zmienionych plików (max 10, jeśli więcej — pokaż liczbę).

## Zasady

- **Maksymalnie zwięźle** — cały output to max 15 linii
- **Bez sugestii** — tylko fakty, żadnych rekomendacji (chyba że user pyta)
- **Jeśli brak MEMORY.md** — pomiń sekcje "Aktywne zadanie" i "Następny krok"

### Warianty wyświetlania

#### Czyste repo (brak zmian)
Pomiń sekcję "Zmiany", pokaż:
```
Zmiany:     ✓ Repo czyste
```

#### Staged changes (gotowe do commitu)
Dodaj ostrzeżenie:
```
⚠️ Staged:  [X plików gotowych do commitu]
```

#### Brak upstream tracking
```
⚠️ Branch nie ma remote tracking. Aby ustawić: git push -u origin [branch]
```

### Ostrzeżenia

Automatycznie dodaj ostrzeżenie jeśli niezacommitowane zmiany dotyczą:
- `.env`, `.env.local` — `⚠️ Wrażliwe pliki zmodyfikowane`
- `package.json` bez `package-lock.json` — `⚠️ Zależności zmienione, brak lock file`
- Więcej niż 20 plików — `⚠️ Dużo zmian ([X] plików) — rozważ commit częściowy`

### Rozszerzony format (opcjonalny)

Jeśli użytkownik pyta "szczegółowy status" lub "pełny status", pokaż dodatkowo:
```
📍 Status: [nazwa projektu] (rozszerzony)
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Branch:      [nazwa] → [remote/branch]
Commit:      [hash] [message] ([czas temu])
Zmiany:      [X staged / Y unstaged / Z untracked]
Upstream:    [ahead X / behind Y / up to date]

Aktywne zadanie: [z MEMORY.md]
Następny krok:   [z MEMORY.md]
Blokery:         [z MEMORY.md]

Ostatnie 3 commity:
  • [hash] [message] ([czas])
  • [hash] [message] ([czas])
  • [hash] [message] ([czas])
```
