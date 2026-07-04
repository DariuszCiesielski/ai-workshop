#!/bin/bash
# session-context.sh — zapisz kontekst bieżącej sesji
# Wywoływany ręcznie lub przed kompresją kontekstu

CONTEXT_FILE="production/session-state/last-session.md"
mkdir -p "$(dirname "$CONTEXT_FILE")"

BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
RECENT_COMMITS=$(git log --oneline -10 --since="6 hours ago" 2>/dev/null || echo "brak")
UNCOMMITTED=$(git status --short 2>/dev/null || echo "brak")

cat > "$CONTEXT_FILE" << CTXEOF
# Ostatnia sesja: $(date '+%Y-%m-%d %H:%M')

## Branch
$BRANCH

## Ostatnie commity tej sesji
$RECENT_COMMITS

## Niezakonczone zmiany
$UNCOMMITTED

## Notatki
<!-- Agent: wpisz tu co zostalo do zrobienia -->

CTXEOF

echo "Kontekst sesji zapisany do $CONTEXT_FILE"
