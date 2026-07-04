#!/bin/bash
# validate.sh — Walidacja credentials.env
# Użycie: bash scripts/validate.sh <ścieżka-do-credentials.env>
# Zwraca: "OK" lub lista problemów

FILE="${1:-credentials.env}"

if [ ! -f "$FILE" ]; then
  echo "BŁĄD: Plik $FILE nie istnieje"
  exit 1
fi

ERRORS=0
WARNINGS=0

# 1. Sprawdź uprawnienia
PERMS=$(stat -f "%A" "$FILE" 2>/dev/null || stat -c "%a" "$FILE" 2>/dev/null)
if [ "$PERMS" != "600" ]; then
  echo "BŁĄD: Uprawnienia to $PERMS, powinny być 600"
  ERRORS=$((ERRORS + 1))
fi

# 2. Sprawdź format — każda niepusta, niekomentarzowa linia powinna być KEY="VALUE"
LINE_NUM=0
while IFS= read -r line; do
  LINE_NUM=$((LINE_NUM + 1))
  # Pomiń puste linie i komentarze
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

  # Sprawdź format KEY="VALUE" lub KEY='VALUE'
  if ! echo "$line" | grep -qE '^[A-Z_][A-Z0-9_]*=["'"'"'].*["'"'"']$'; then
    echo "BŁĄD linia $LINE_NUM: Nieprawidłowy format — $line"
    ERRORS=$((ERRORS + 1))
  fi
done < "$FILE"

# 3. Sprawdź duplikaty kluczy
DUPES=$(grep -oE '^[A-Z_][A-Z0-9_]*=' "$FILE" | sort | uniq -d)
if [ -n "$DUPES" ]; then
  echo "BŁĄD: Zduplikowane klucze: $DUPES"
  ERRORS=$((ERRORS + 1))
fi

# 4. Sprawdź puste wartości
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  KEY=$(echo "$line" | cut -d= -f1)
  VALUE=$(echo "$line" | cut -d= -f2-)
  if [ "$VALUE" = '""' ] || [ "$VALUE" = "''" ]; then
    echo "OSTRZEŻENIE: $KEY ma pustą wartość"
    WARNINGS=$((WARNINGS + 1))
  fi
done < "$FILE"

# 5. Sprawdź nieescapowane $ w podwójnych cudzysłowach
while IFS= read -r line; do
  [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
  # Tylko linie z podwójnymi cudzysłowami
  if echo "$line" | grep -qE '=".*\$[^\\]'; then
    KEY=$(echo "$line" | cut -d= -f1)
    echo "OSTRZEŻENIE: $KEY może mieć nieescapowany \$ — sprawdź ręcznie"
    WARNINGS=$((WARNINGS + 1))
  fi
done < "$FILE"

# Podsumowanie
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "OK"
  exit 0
elif [ $ERRORS -eq 0 ]; then
  echo "---"
  echo "Wynik: $WARNINGS ostrzeżeń, 0 błędów"
  exit 0
else
  echo "---"
  echo "Wynik: $ERRORS błędów, $WARNINGS ostrzeżeń"
  exit 1
fi
