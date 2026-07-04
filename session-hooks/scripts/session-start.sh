#!/bin/bash
# session-start.sh — ładuje kontekst na starcie sesji Claude Code
# Timeout: max 3 sekundy. Fail gracefully.

echo "=== KONTEKST SESJI ==="
echo ""

# Ostatnia aktywność
echo "Ostatnie commity:"
git log --oneline -5 2>/dev/null || echo "  (brak historii git)"
echo ""

# Aktualny stan
BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
CHANGES=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
echo "Branch: $BRANCH"
echo "Niezacommitowane zmiany: $CHANGES"
echo ""

# Sprint (jeśli istnieje)
if [ -f "production/current-sprint.md" ]; then
    echo "Aktualny sprint:"
    head -20 production/current-sprint.md
    echo ""
fi

# Manifest (jeśli istnieje)
MANIFEST=$(find . -maxdepth 2 -name "manifest.json" -o -name "project-meta.json" 2>/dev/null | grep -v node_modules | head -1)
if [ -n "$MANIFEST" ] && command -v jq >/dev/null 2>&1; then
    NEXT_STEPS=$(jq -r '.manual.next_steps[]? // empty' "$MANIFEST" 2>/dev/null | head -5)
    BLOCKED=$(jq -r '.manual.blocked_by[]? // empty' "$MANIFEST" 2>/dev/null)
    if [ -n "$NEXT_STEPS" ]; then
        echo "Nastepne kroki (z manifestu):"
        echo "$NEXT_STEPS" | sed 's/^/  - /'
        echo ""
    fi
    if [ -n "$BLOCKED" ]; then
        echo "Blokady:"
        echo "$BLOCKED" | sed 's/^/  - /'
        echo ""
    fi
fi

# Handoffy (jeśli istnieją)
HANDOFF_DIR=".ai/handoffs"
if [ -d "$HANDOFF_DIR" ]; then
    LATEST=$(ls -t "$HANDOFF_DIR"/*.md 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        echo "Ostatni handoff: $(basename "$LATEST")"
        echo ""
    fi
fi

# TODO/FIXME
if [ -d "src" ]; then
    TODO_COUNT=$(grep -r "TODO\|FIXME\|HACK\|XXX" src/ --include="*.ts" --include="*.tsx" -c 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
    echo "TODO/FIXME w kodzie: $TODO_COUNT"
    echo ""
fi

echo "=== GOTOWY DO PRACY ==="
