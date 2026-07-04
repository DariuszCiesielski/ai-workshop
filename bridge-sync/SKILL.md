---
name: bridge-sync
description: Synchronizacja kontekstu portfolio między claude.ai, Claude Desktop i Claude Code. Użyj gdy użytkownik mówi "bridge sync", "zsynchronizuj bridge", "aktualizuj kontekst portfolio", "sprawdź instrukcje z mostu"
tags: [bridge, sync, portfolio, cross-platform]
---

# Bridge Sync — most między wersjami Claude

## Kiedy używać
- Po zakończeniu istotnej sesji pracy (nowa funkcja, naprawiony bug, zmiana architektury)
- Gdy użytkownik prosi o aktualizację kontekstu portfolio
- Gdy chcesz sprawdzić czy są nowe instrukcje z claude.ai lub Claude Desktop
- Triggery: "bridge sync", "zsynchronizuj bridge", "aktualizuj kontekst", "sprawdź instrukcje"

## Co robi
System Bridge łączy 3 wersje Claude:
1. **Claude Code** (terminal/Cursor) → publikuje stan portfolio na Google Drive i GitHub
2. **claude.ai** (przeglądarka) → czyta kontekst z Drive, pisze instrukcje do Google Docs
3. **Claude Desktop** → czyta kontekst z pliku lokalnego, pisze instrukcje do Supabase

## Komendy

### Pełna synchronizacja (eksport kontekstu)
```bash
bash ~/.claude/scripts/bridge-sync.sh --force
```
Generuje Bridge Context z API Project Master, pushuje do GitHub i uploaduje na Google Drive.

### Sprawdź nowe instrukcje
```bash
bash ~/.claude/scripts/bridge-read-instructions.sh
```
Czyta pending instrukcje z Google Docs "[PM] Bridge Instructions" i z Supabase.

### Oznacz instrukcję jako wykonaną
```bash
curl -X PATCH https://project-master-nine-omega.vercel.app/api/v1/bridge/instructions \
  -H "Content-Type: application/json" \
  -d '{"id": "UUID_INSTRUKCJI", "status": "done", "result": "Krótki opis wyniku"}'
```

## Automatyzacja
- **SessionEnd hook** → automatyczny sync (z debounce 30 min)
- **SessionStart hook** → automatyczne sprawdzenie instrukcji

## Format instrukcji dla claude.ai
Gdy claude.ai pisze instrukcje do Google Docs "[PM] Bridge Instructions", powinien używać formatu:
```
## Instrukcja: [tytuł] — [YYYY-MM-DD]
Projekt: [slug lub "ogólne"]
Priorytet: [wysoki/średni/niski]

[treść instrukcji]

---
Status: NOWA
```

Po wykonaniu, Claude Code zmienia status na:
```
Status: [DONE — YYYY-MM-DD — krótki opis wyniku]
```

## Pułapki
- GWS CLI wymaga aktywnej sesji Google — jeśli `gws drive files list` nie działa, uruchom `gws auth login`
- Debounce 30 min — użyj `--force` jeśli potrzebujesz natychmiastowego sync
- API endpoint wymaga deploy na Vercel — lokalnie użyj `--skip-drive` i `localhost:3000`
- Fallback: jeśli API PM jest niedostępne, skrypt generuje uproszczoną wersję z samych manifestów
