#!/bin/bash
# pre-commit.sh — walidacja przed commitem
# BLOKUJE: tylko sekrety (exit 1)
# OSTRZEGA: console.log, brakujące env vars (exit 0)

ERRORS=0

# 1. Sprawdź hardcoded secrets (BLOKUJĄCE)
SECRETS=$(git diff --cached --diff-filter=ACMR -U0 2>/dev/null | grep -E '^\+' | grep -v '^\+\+\+' | \
    grep -iE '(sk-[a-zA-Z0-9]{20,}|pk_[a-zA-Z0-9]{20,}|password\s*=\s*["'"'"'][^\s]+|SUPABASE_SERVICE_ROLE_KEY\s*=\s*["'"'"']eyJ)' || true)
if [ -n "$SECRETS" ]; then
    echo "BLAD: Wykryto potencjalne sekrety w kodzie:"
    echo "$SECRETS" | head -5
    ERRORS=$((ERRORS + 1))
fi

# 2. Sprawdź console.log w production code (OSTRZEŻENIE)
CONSOLE_LOGS=$(git diff --cached --diff-filter=ACMR --name-only 2>/dev/null | \
    grep -E '\.(ts|tsx)$' | \
    grep -v -E '(__tests__|\.test\.|\.spec\.|prototypes/)' | \
    xargs grep -l 'console\.log' 2>/dev/null || true)
if [ -n "$CONSOLE_LOGS" ]; then
    echo "UWAGA: console.log w production code:"
    echo "$CONSOLE_LOGS" | sed 's/^/  /'
    echo "  (Rozwaz usuniecie lub zamiane na logger)"
fi

# 3. Sprawdź czy nowe env vars są w .env.example (OSTRZEŻENIE)
if [ -f ".env.example" ]; then
    NEW_ENV=$(git diff --cached --diff-filter=ACMR -U0 -- '.env*' '!.env.example' 2>/dev/null | \
        grep -E '^\+[A-Z_]+=' | sed 's/^\+//' | cut -d= -f1 || true)
    if [ -n "$NEW_ENV" ]; then
        for VAR in $NEW_ENV; do
            if ! grep -q "^${VAR}=" .env.example 2>/dev/null; then
                echo "UWAGA: Nowa zmienna $VAR nie jest w .env.example"
            fi
        done
    fi
fi

# Wynik
if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "Commit zablokowany — popraw bledy powyzej."
    exit 1
fi

exit 0
