---
name: nextjs-build-verify
description: Weryfikacja poprawności kodu po zmianach — TypeScript, lint, build, runtime checks. Claude sam sprawdza czy zrobił dobrze. Używaj automatycznie po zakończeniu implementacji, lub na żądanie "sprawdź build", "verify", "zweryfikuj", "czy się buduje", "czy działa". Auto-aktywacja po edycji 3+ plików TSX/TS.
---

# Next.js Build Verify

Self-verification — Claude sprawdza własną pracę zanim oznaczy zadanie jako ukończone. Nie czekaj na feedback użytkownika — sam zweryfikuj.

## Kiedy używać

- **Automatycznie** po zakończeniu implementacji (edycja 3+ plików)
- Na żądanie: "sprawdź build", "verify", "czy się buduje", "zweryfikuj"
- Przed commitem / PR
- Po refaktoryzacji

## Kiedy NIE używać

- Zmiana w jednym pliku CSS/Tailwind (nie wymaga build)
- Zmiana w .md / dokumentacji
- Użytkownik mówi "bez weryfikacji", "szybko", "commit bez sprawdzania"

## Instrukcje

### Faza 1: Szybkie sprawdzenie (< 10 sekund)

Uruchom RÓWNOLEGLE — nie czekaj na wynik jednego przed startem drugiego:

```bash
# 1. TypeScript — czy kompiluje?
npx tsc --noEmit 2>&1 | tail -20

# 2. Lint — czy ESLint przechodzi?
npx next lint --quiet 2>&1 | tail -20

# 3. Szukaj zakazanych wzorców w zmienionych plikach
grep -rn "console\.log\|console\.warn\|debugger" --include="*.ts" --include="*.tsx" src/ app/ 2>/dev/null | grep -v node_modules | grep -v ".next"
```

**Jeśli TypeScript lub lint failuje → NAPRAW NATYCHMIAST, nie raportuj.**

### Faza 2: Statyczna analiza (opcjonalna, < 30 sekund)

Uruchom gdy Faza 1 przeszła:

```bash
# 4. Sprawdź unused imports (TypeScript strict mode)
npx tsc --noEmit --noUnusedLocals --noUnusedParameters 2>&1 | head -30

# 5. Sprawdź rozmiar bundla (jeśli ważne)
npx next build 2>&1 | grep -A 20 "Route.*Size"
```

### Faza 3: Runtime verification (opcjonalna)

Gdy dev server działa lub po uruchomieniu:

```bash
# 6. Sprawdź czy strona się ładuje
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000

# 7. Sprawdź błędy konsoli (jeśli Playwright MCP dostępny)
# → navigate → snapshot → console_messages
```

### Matryca decyzyjna — co uruchomić

| Zmiana | Faza 1 | Faza 2 | Faza 3 |
|--------|--------|--------|--------|
| Nowy komponent / strona | ✅ | ✅ | ✅ |
| Zmiana logiki (hook, util) | ✅ | ✅ | — |
| Zmiana stylów (Tailwind) | ✅ | — | ✅ (wizualna) |
| Zmiana API route / Server Action | ✅ | ✅ | ✅ |
| Zmiana migracji Supabase | — | — | ✅ (testuj zapytanie) |
| Refaktoryzacja (rename, move) | ✅ | ✅ | — |

### Krok 4: Raport

```markdown
## Weryfikacja — [data] [godzina]

| Check | Status | Szczegóły |
|-------|--------|-----------|
| TypeScript | ✅/❌ | [0 errors / X errors] |
| ESLint | ✅/❌ | [0 warnings / X warnings] |
| console.log | ✅/❌ | [0 / X wystąpień] |
| Build | ✅/❌/⏭️ | [success / error / pominięty] |
| Runtime | ✅/❌/⏭️ | [200 OK / error / pominięty] |

Pliki sprawdzone: [X]
Czas weryfikacji: [X]s
```

### Krok 5: Auto-fix loop

Jeśli weryfikacja failuje:
1. Napraw problem
2. Uruchom ponownie TYLKO failujący check
3. Powtarzaj max 3 razy
4. Jeśli po 3 próbach dalej failuje → raportuj użytkownikowi z opisem co próbowałeś

## Pułapki

### ❌ Build przechodzi, runtime failuje
**Objaw**: `next build` OK, ale strona pokazuje błąd 500
**Przyczyna**: Brak zmiennych środowiskowych (env vars), dynamiczny import z błędem, brak danych w bazie
**Rozwiązanie**: Po build ZAWSZE sprawdź runtime (Faza 3). Szczególnie po zmianach w API routes i Server Actions.

### ❌ TypeScript OK ale typy nieprawidłowe
**Objaw**: `tsc --noEmit` przechodzi, ale runtime rzuca `undefined is not a function`
**Przyczyna**: Użycie `as` type assertion lub `any` ukryło błąd typów
**Rozwiązanie**: Szukaj `as ` i `any` w zmienionych plikach — to bypass, nie fix.

### ❌ ESLint config nie istnieje
**Objaw**: `next lint` mówi "No ESLint configuration found"
**Przyczyna**: Nowy projekt bez `.eslintrc.json` lub `eslint.config.mjs`
**Rozwiązanie**: Pomiń lint check. Nie twórz configa bez pytania użytkownika.

### ❌ Nieskończony build loop
**Objaw**: Agent naprawia błąd → nowy błąd → naprawia → nowy → ...
**Przyczyna**: Każda poprawka psuje coś innego (efekt domina)
**Rozwiązanie**: Po 3 iteracjach STOP. Raportuj: "Naprawiłem X ale pojawiło się Y. Potrzebuję Twojej decyzji."

### ❌ False positive na console.log w bibliotekach
**Objaw**: grep znajduje console.log w node_modules lub .next
**Przyczyna**: Grep skanuje zbyt szeroko
**Rozwiązanie**: Ogranicz do `src/`, `app/`, `lib/`, `components/`. ZAWSZE `--exclude-dir=node_modules --exclude-dir=.next`.

### ❌ Pomijanie dynamic imports
**Objaw**: Build przechodzi ale strona crashuje przy lazy load
**Przyczyna**: `dynamic(() => import('./Component'))` — Component nie istnieje lub ma syntax error
**Rozwiązanie**: Sprawdź czy plik docelowy dynamic importu istnieje i eksportuje default.

### ❌ Brak env vars po deploy
**Objaw**: Lokalnie działa, na Vercel 500
**Przyczyna**: Env vars są w `.env.local` ale nie w Vercel Dashboard
**Rozwiązanie**: Po weryfikacji lokalnej przypomnij: "Upewnij się że env vars są skonfigurowane na Vercel (`vercel env ls`)."
