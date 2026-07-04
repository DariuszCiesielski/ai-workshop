---
name: session-hooks
description: >
  Instaluje i konfiguruje session hooks dla projektów Next.js + Supabase.
  Zapewnia ciągłość między sesjami (auto-ładowanie kontekstu),
  jakość commitów (pre-commit walidacja) i logowanie postępu.
  Używaj gdy użytkownik mówi "skonfiguruj hooki", "chcę żebyś
  pamiętał kontekst", "setup session hooks", "dodaj pre-commit",
  lub gdy tworzysz nowy projekt. Triggeruj też gdy użytkownik
  narzeka na utratę kontekstu między sesjami.
  NIE używaj gdy projekt nie korzysta z git.
---

## 3 hooki do zainstalowania

### 1. session-start.sh — kontekst na starcie

Automatycznie ładuje kontekst na początku sesji:
- Ostatnie 5 commitów
- Aktualny branch + niezacommitowane zmiany
- Cele sprintu (jeśli `production/current-sprint.md` istnieje)
- Następne kroki z manifestu projektu
- Liczba TODO/FIXME w kodzie

**Plik:** `scripts/session-start.sh` w tym skillu (gotowy do skopiowania).

### 2. pre-commit.sh — walidacja jakości

Sprawdza przed każdym commitem:
- **BLOKUJE** (exit 1): hardcodowane sekrety (`sk-`, `pk_`, `SUPABASE_SERVICE_ROLE_KEY=eyJ...`)
- **OSTRZEGA** (exit 0): `console.log` w production code, brak nowych env vars w `.env.example`

**WAŻNE:** Blokuj TYLKO sekrety. Reszta to ostrzeżenia — nie spowalniaj workflow.

### 3. session-context.sh — zapis kontekstu

Zapisuje stan sesji do `production/session-state/last-session.md`:
- Branch, ostatnie commity (6h), niezakończone zmiany
- Wywoływany ręcznie lub przed kompresją kontekstu

## Procedura instalacji

### Krok 1: Skopiuj skrypty
```bash
mkdir -p .claude/hooks
cp ~/.claude/skills/session-hooks/scripts/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
```

### Krok 2: Skonfiguruj settings.json
Dodaj do `.claude/settings.json` projektu:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [{
          "type": "command",
          "command": "bash .claude/hooks/session-start.sh",
          "timeout": 5000
        }]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "bash .claude/hooks/pre-commit.sh",
          "timeout": 10000
        }]
      }
    ]
  }
}
```

### Krok 3: Przygotuj katalog sesji
```bash
mkdir -p production/session-state
echo "production/session-state/" >> .gitignore
```

### Krok 4: Przetestuj
```bash
bash .claude/hooks/session-start.sh
# Powinien wyświetlić kontekst sesji
```

## Pułapki

- NIE blokuj commitów na warnings — TYLKO na errors (sekrety). Użytkownik znienawidzi hooki które go blokują za console.log
- NIE loguj wrażliwych danych w session-context (env vars, klucze, tokeny)
- Hook session-start max 3 sekundy — jeśli projekt duży, ogranicz grep do src/ i max 2 poziomów
- Skrypty POSIX-compatible (bash, nie zsh-specific) — żeby działały w CI i na różnych maszynach
- Każdy hook MUSI fail gracefully — brak jq/git/grep = warning, nie crash
- chmod +x po instalacji — bez tego hook nie zadziała
- Nie duplikuj logiki z context-handoff skill — session-context.sh to lekka wersja, handoff to pełny raport
