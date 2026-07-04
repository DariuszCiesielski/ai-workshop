# Przewodnik instalacji session hooks

## Wymagania
- Git (do session-start.sh i pre-commit.sh)
- jq (opcjonalny — do odczytu manifestu w session-start.sh)
- bash (skrypty POSIX-compatible)

## Szybka instalacja (3 komendy)

```bash
# 1. Skopiuj skrypty
mkdir -p .claude/hooks && cp ~/.claude/skills/session-hooks/scripts/*.sh .claude/hooks/ && chmod +x .claude/hooks/*.sh

# 2. Stwórz katalog sesji
mkdir -p production/session-state && echo "production/session-state/" >> .gitignore

# 3. Przetestuj
bash .claude/hooks/session-start.sh
```

## Konfiguracja settings.json

Dodaj do `.claude/settings.json` (lub `.claude/settings.local.json` dla ustawień lokalnych):

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
    ]
  }
}
```

Pre-commit hook lepiej zainstalować jako git hook:
```bash
# Dodaj do .git/hooks/pre-commit (lub husky)
cp .claude/hooks/pre-commit.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Dostosowanie per projekt

### Projekt bez Supabase
- session-start.sh: usuń sekcję manifest (lub zmień ścieżkę)
- pre-commit.sh: usuń sprawdzanie SUPABASE_SERVICE_ROLE_KEY

### Projekt z monorepo
- session-start.sh: zmień `src/` na odpowiedni katalog (`apps/`, `packages/`)
- pre-commit.sh: dostosuj path do excludes

### Projekt bez sprintu
- session-start.sh: sekcja sprint jest warunkowa (if -f), nie wymaga zmian

## Rozwiązywanie problemów

| Problem | Przyczyna | Rozwiązanie |
|---------|-----------|-------------|
| Hook nie działa | Brak chmod +x | `chmod +x .claude/hooks/*.sh` |
| "jq: command not found" | Brak jq | `brew install jq` lub hook pomija sekcję manifest |
| Hook trwa >5s | Duży projekt, grep przeszukuje node_modules | Dodaj `--exclude-dir=node_modules` do grep |
| Pre-commit blokuje za dużo | False positive na sekrety | Dostosuj regex w pre-commit.sh |
