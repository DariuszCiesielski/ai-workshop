#!/bin/bash
# check-deploys.sh — Sprawdza status deployów Vercel dla listy projektów
# Użycie: bash scripts/check-deploys.sh [katalog-projektów]
#
# Skanuje podkatalogi w poszukiwaniu .vercel/project.json
# i sprawdza status ostatniego deployu per projekt.
#
# Wymagania: vercel CLI zalogowany (vercel login)

PROJECTS_DIR="${1:-$HOME/projekty}"
ERRORS=0
TOTAL=0

echo "=== Vercel Deploy Check: $(date '+%Y-%m-%d %H:%M') ==="
echo ""

# Sprawdź czy vercel CLI jest dostępne
if ! command -v vercel &> /dev/null; then
  echo "ERROR: vercel CLI nie znalezione. Zainstaluj: npm i -g vercel@latest"
  exit 2
fi

# Znajdź projekty z .vercel/project.json
for PROJECT_DIR in "$PROJECTS_DIR"/*/; do
  if [ ! -f "$PROJECT_DIR/.vercel/project.json" ]; then
    continue
  fi

  PROJECT_NAME=$(basename "$PROJECT_DIR")
  TOTAL=$((TOTAL + 1))

  # Pobierz ostatni deploy
  DEPLOY_INFO=$(cd "$PROJECT_DIR" && vercel ls --limit 1 2>/dev/null | tail -1)

  if [ -z "$DEPLOY_INFO" ]; then
    echo "WARN: $PROJECT_NAME — nie udało się pobrać statusu"
    continue
  fi

  # Parsuj status (kolumna State w output vercel ls)
  if echo "$DEPLOY_INFO" | grep -qi "ready"; then
    echo "OK:    $PROJECT_NAME — READY"
  elif echo "$DEPLOY_INFO" | grep -qi "error\|failed"; then
    echo "ERROR: $PROJECT_NAME — FAILED"
    ERRORS=$((ERRORS + 1))
  elif echo "$DEPLOY_INFO" | grep -qi "building"; then
    echo "BUILD: $PROJECT_NAME — BUILDING"
  elif echo "$DEPLOY_INFO" | grep -qi "canceled"; then
    echo "SKIP:  $PROJECT_NAME — CANCELED"
  else
    echo "INFO:  $PROJECT_NAME — $DEPLOY_INFO"
  fi

  # Rate limit protection
  sleep 0.5
done

echo ""
echo "=== Podsumowanie ==="
echo "Projekty sprawdzone: $TOTAL"
echo "Błędy: $ERRORS"

if [ $ERRORS -gt 0 ]; then
  exit 1
else
  exit 0
fi
