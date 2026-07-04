#!/bin/bash
# check-rls.sh — Skanuje pliki migracji Supabase w poszukiwaniu tabel bez RLS
# Użycie: bash scripts/check-rls.sh <ścieżka-projektu>
#
# Zwraca:
#   - Lista tabel z RLS enabled
#   - Lista tabel BEZ RLS (potencjalne ryzyko)
#   - Exit code 0 = OK, 1 = znaleziono tabele bez RLS

PROJECT_PATH="${1:-.}"
MIGRATIONS_DIR="$PROJECT_PATH/supabase/migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "SKIP: Brak katalogu migracji ($MIGRATIONS_DIR)"
  exit 0
fi

# Zbierz nazwy tabel z CREATE TABLE
TABLES=$(grep -rh "CREATE TABLE" "$MIGRATIONS_DIR"/*.sql 2>/dev/null \
  | grep -oP '(?:public\.)?\K\w+(?=\s*\()' \
  | sort -u)

if [ -z "$TABLES" ]; then
  echo "SKIP: Brak tabel w migracjach"
  exit 0
fi

# Zbierz tabele z RLS
RLS_TABLES=$(grep -rh "ENABLE ROW LEVEL SECURITY" "$MIGRATIONS_DIR"/*.sql 2>/dev/null \
  | grep -oP '(?:ON\s+(?:public\.)?)?\K\w+(?=\s*;)' \
  | sort -u)

# Znane tabele lookup (nie wymagają RLS)
LOOKUP_TABLES="countries categories regions statuses types"

HAS_ISSUES=0

echo "=== RLS Check: $PROJECT_PATH ==="
echo ""

for TABLE in $TABLES; do
  # Pomiń tabele lookup
  if echo "$LOOKUP_TABLES" | grep -qw "$TABLE"; then
    echo "INFO: $TABLE — lookup table (RLS opcjonalne)"
    continue
  fi

  if echo "$RLS_TABLES" | grep -qw "$TABLE"; then
    echo "OK:   $TABLE — RLS enabled"
  else
    echo "WARN: $TABLE — BRAK RLS"
    HAS_ISSUES=1
  fi
done

echo ""
if [ $HAS_ISSUES -eq 1 ]; then
  echo "RESULT: Znaleziono tabele bez RLS"
  exit 1
else
  echo "RESULT: Wszystkie tabele mają RLS"
  exit 0
fi
