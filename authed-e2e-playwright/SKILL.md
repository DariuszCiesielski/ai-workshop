---
name: authed-e2e-playwright
description: Autonomiczne testy E2E w przeglądarce pod ZALOGOWANĄ sesją użytkownika dla własnych aplikacji Next.js+Supabase (i podobnych). Wzorzec Playwright + storageState + loginy z credentials-vault — login raz, reuse sesji, asercje przez API (deterministyczne) i UI. Używaj gdy trzeba przetestować funkcję za logowaniem na prod/preview, a Claude in Chrome jest niedostępny (np. w VS Code masz tylko Playwright MCP, który odpala czystą sesję i konfliktuje z otwartym Chrome). Triggery: "przetestuj E2E pod moją sesją", "test za logowaniem", "autonomiczny test prod", "sprawdź funkcję jako zalogowany", "playwright z moją sesją".
---

# Authed E2E Playwright (storageState)

Reużywalny wzorzec do testowania funkcji **za logowaniem** na własnych apkach, autonomicznie, bez Claude-in-Chrome. Wyrósł z sesji SOTA RAG 2026-06-15 (globalna baza wiedzy) na bazie wzorca z Job Hunter (`channel:'chrome'` + `storageState`).

## Kiedy ten wzorzec, a kiedy co innego

| Sytuacja | Narzędzie |
|---|---|
| Funkcja za logowaniem, Chrome usera otwarty, brak Claude-in-Chrome (np. VS Code) | **TEN skill** (Playwright + storageState, czysta sesja, login creds z vault) |
| Claude-in-Chrome dostępny (`/chrome` + rozszerzenie) | `claude-in-chrome` — realna sesja usera, zero loginu |
| Strona publiczna bez auth | Playwright MCP wprost |

**Dlaczego nie Playwright MCP do auth:** MCP odpala własny, świeży profil (brak loginu) i konfliktuje z otwartym Chrome usera ("Browser is already in use"). Standalone skrypt Playwright z własnym kontekstem + `storageState` to omija.

## Przepis (3 elementy)

### 1. Loginy z credentials-vault — NIGDY hardcode
Czytaj z `credentials.env` projektu (gitignored). Sprawdź wcześniej w bazie KTÓRE konto pokrywa role (np. superadmin + owner org testowej = jeden login zamiast kilku).

### 2. login.mjs — sesja raz, reuse przez storageState
```js
import { chromium } from 'playwright';
// loadCreds(): parsuj credentials.env (regex per klucz), zwróć {email,password}
// getContext(): jeśli .session/app.json istnieje → newContext({storageState}); waliduj wejściem na /dashboard;
//   jeśli niezalogowany → freshLogin: goto /login, fill #email/#password, submit, waitForURL !login,
//   context.storageState({path}). Czysty kontekst (NIE userDataDir profilu).
```
`.session/` i `out/` (screenshoty) → `.gitignore`.

### 3. Asercje: API deterministycznie, UI gdy trzeba
- **Deterministyczne** (preferuj): `context.request.get/post(endpoint)` z cookies sesji → sprawdzaj `status()` + JSON. Szybkie, stabilne (np. download API → 200+signedUrl; analizator POST → perspectives.length).
- **UI** gdy nie ma API (server actions, render): `setInputFiles`, `selectOption`, `getByRole('button')`, `keyboard.press('Enter')`, poll z `reload()` na async (ingestion/streaming), `screenshot({fullPage})`.
- **Warstwa danych** jako trzeci dowód: gdy UI/cytaty renderują się jako komponenty (nie tekst), potwierdź w DB/SQL (np. FTS/embedding match) zamiast scrapować DOM.

## GOTCHA (sprawdzone empirycznie)
1. **Ścieżka repo ze spacją** ("SOTA RAG"): guard `import.meta.url === pathToFileURL(process.argv[1]).href` — NIE `file://${argv[1]}` (spacja→%20 mismatch → main nie odpala, cisza + exit 0).
2. **Cytaty/źródła renderują się jako komponenty**, nie tekst `[N]` — asercje po treści (nazwa źródła), nie po markerach.
3. **Next 16 worktree build**: realny `node_modules` (npm install), nie symlink — Turbopack odrzuca symlink poza root.
4. **Async w UI** (ingestion, streaming odpowiedzi, przyciski gated na status='completed'): poll z `reload()` + cap czasowy, nie jednorazowy `waitForTimeout`.
5. **Sesja wygasła**: walidacja na starcie (wejście na /dashboard, sprawdź czy nie redirect na /login) → automatyczny re-login.

## Bezpieczeństwo
- Loginy tylko z vault/credentials.env (gitignored). Sesja (`storageState`) gitignored — zawiera cookies auth.
- Test na **organizacji testowej / bezpiecznym celu**, nigdy na żywym koncie klienta.
- Operacje mutujące (upload, approve) — sprzątaj po teście (usuń utworzone rekordy).

## Reference implementacja
`~/projekty/SOTA RAG/scripts/e2e/` — `login.mjs` (sesja) + `global-kb-e2e.mjs` (A/B/C/D: lista, download API, czat-retrieval, analizator) + `contribute-e2e.mjs` (upload→approve z pollem) + `README.md`.
Wzorzec źródłowy sesji: Job Hunter `src/lib/scraper/pracuj-pl.ts` (`channel:'chrome'` + `storageState`).
