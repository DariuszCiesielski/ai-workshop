---
name: stack-code-review
description: Code review kodu pod standardy stacku (Next.js App Router, Supabase, TypeScript strict, Tailwind, shadcn/ui). Używaj po zakończeniu implementacji, przed commitem, lub gdy użytkownik mówi "sprawdź kod", "review", "przejrzyj", "code review". Auto-aktywacja po zakończeniu logicznego bloku zmian.
---

# Stack Code Review

Review kodu pod standardy stacku właściciela. Nie ogólny linting — konkretne wzorce, anti-patterns i pułapki specyficzne dla Next.js App Router + Supabase + TypeScript.

## Kiedy używać

- Po zakończeniu implementacji (przed commitem)
- Na żądanie: "sprawdź kod", "review", "przejrzyj", "code review", "audyt kodu"
- Auto: po napisaniu 3+ plików w jednej sesji
- Przed PR / deploy

## Anty-wzorce kodu UI (explicit deny list)

Podczas review — flaguj jako problem:

- ❌ `any` w typach propsów komponentów — precyzyjne typy lub generic
- ❌ `console.log` w kodzie produkcyjnym — usuń lub zamień na proper logging
- ❌ Inline styles zamiast Tailwind klas — utrzymuj spójność
- ❌ Hardcoded kolory (#hex) w TSX zamiast `var(--)` lub tokenów Tailwind
- ❌ Brak `key` prop w listach lub `key={index}` na dynamicznych listach
- ❌ `useEffect` z pustym deps array do data fetching — użyj React Query/SWR
- ❌ Obrazki bez `width`/`height` lub `next/image` — powodują layout shift (CLS)
- ❌ Tekst w UI bez polskich znaków diakrytycznych — "Zaloguj sie" → "Zaloguj się"

## Kiedy NIE używać

- Dla pojedynczej poprawki stylistycznej (1 linia)
- Dla plików konfiguracyjnych (package.json, tsconfig)
- Gdy użytkownik wyraźnie mówi "bez review"

## Instrukcje

### Krok 1: Zbierz zmienione pliki

```bash
# Jeśli git — sprawdź co się zmieniło
git diff --name-only HEAD~1  # lub git diff --staged --name-only
```

Jeśli nie git — przejrzyj pliki edytowane w tej sesji.

### Krok 2: Review wg checklisty (8 kategorii)

Przejdź KAŻDY zmieniony plik przez te kategorie. Raportuj TYLKO znalezione problemy — nie powtarzaj "OK" dla każdego punktu.

#### A. Server vs Client Components (Next.js App Router)

| Reguła | Sprawdź |
|--------|---------|
| Domyślnie Server Component | Czy `'use client'` jest dodane TYLKO gdy potrzebne (useState, useEffect, onClick, browser API)? |
| Granica `'use client'` jak najniżej | Czy cały page/layout nie jest klientem tylko dlatego, że jeden przycisk ma onClick? |
| Nie importuj Server Component w Client | Czy Client Component nie importuje bezpośrednio Server Component? (Przekaż jako children) |
| Async request APIs | `cookies()`, `headers()`, `params`, `searchParams` — czy mają `await`? (Next.js 16) |
| Server Actions | Czy mutacje używają `'use server'` zamiast Route Handlers (chyba że to publiczne API)? |

#### B. TypeScript Strict

| Reguła | Sprawdź |
|--------|---------|
| Brak `any` | Szukaj `any` — każde wystąpienie to czerwona flaga |
| Brak `as` type assertion | `as SomeType` ukrywa błędy — preferuj type guards lub generics |
| Precyzyjne typy | `string` zamiast unii literałów? `object` zamiast interface? |
| Nullable handling | `?.` i `??` zamiast `!` (non-null assertion) |
| Return types | Funkcje publiczne/eksportowane powinny mieć explicit return type |

#### C. Supabase & RLS

| Reguła | Sprawdź |
|--------|---------|
| RLS na KAŻDEJ tabeli | Każdy `CREATE TABLE` musi mieć `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` |
| Nie mieszaj klientów | `createBrowserClient` w kliencie, `createServerClient` na serwerze, `createClient(url, SERVICE_ROLE)` w admin |
| Service role TYLKO server-side | Nigdy nie wysyłaj service_role key do klienta |
| Auth guard przed danymi | `const { data: { user } } = await supabase.auth.getUser()` przed zapytaniami |
| Typy z Supabase | `Database['public']['Tables']['nazwa']['Row']` — nie ręczne interface'y |

#### D. Bezpieczeństwo

| Reguła | Sprawdź |
|--------|---------|
| Brak sekretów w kodzie | Szukaj: `sk_`, `SERVICE_ROLE`, `API_KEY`, `secret`, `password` w stringach |
| Walidacja inputu | Dane od użytkownika → walidacja (zod, z.string().email()) przed bazą |
| SQL injection | Nie ma template literals w zapytaniach SQL? Używaj parametryzacji |
| XSS — raw HTML rendering | Czy surowy HTML jest renderowany bez sanityzacji? (np. DOMPurify) |
| CORS | Route Handlers — czy nagłówki CORS są skonfigurowane poprawnie? |

#### E. Wydajność

| Reguła | Sprawdź |
|--------|---------|
| Brak N+1 | Pętla z zapytaniem do bazy w środku? → jeden zapytanie z `.in()` lub join |
| Obrazy przez next/image | `<img>` zamiast `<Image>`? → brak optymalizacji |
| Czcionki przez next/font | Link do Google Fonts w `<head>`? → użyj `next/font` |
| Duże importy | `import _ from 'lodash'` → `import debounce from 'lodash/debounce'` |
| Key w listach | `.map()` bez `key` lub z `index` jako key (dla list z reorder/delete) |

#### F. Tailwind & shadcn/ui

| Reguła | Sprawdź |
|--------|---------|
| Spójność z design system | Użycie surowego CSS zamiast Tailwind classes? |
| cn() utility | Warunkowe klasy — czy używa `cn()` (clsx + tailwind-merge)? |
| Kolory z theme | Hardcoded `#hex` zamiast `text-primary`, `bg-background`? |
| Responsywność | Mobile-first? Czy jest `sm:`, `md:`, `lg:` gdzie potrzeba? |

#### G. Obsługa błędów

| Reguła | Sprawdź |
|--------|---------|
| try/catch na fetch/baza | Czy operacje async mają obsługę błędów? |
| Error boundary | Strona z danymi — czy jest `error.tsx`? |
| Loading state | Async operacja — czy jest `loading.tsx` lub Suspense? |
| Empty state | Lista — co się wyświetla gdy jest pusta? |
| User-friendly error | Komunikat błędu — czy jest zrozumiały? (nie "Internal Server Error") |

#### H. Porządek

| Reguła | Sprawdź |
|--------|---------|
| Brak console.log | Szukaj `console.log`, `console.warn`, `debugger` |
| Brak unused imports | Importy na górze pliku — czy wszystkie są używane? |
| Brak zakomentowanego kodu | Duże bloki `// old code` — albo usuń, albo uzasadnij |
| Nazewnictwo | Spójne z resztą projektu? PascalCase dla komponentów, camelCase dla funkcji? |
| Polskie znaki | User-facing tekst ma diakrytyki? ("Zaloguj się" nie "Zaloguj sie") |

### Krok 3: Raport

Format raportu — TYLKO znalezione problemy:

```markdown
## Code Review — [data]

### Krytyczne (blokują deploy)
- **[plik:linia]** — [opis problemu] → [jak naprawić]

### Ważne (napraw przed merge)
- **[plik:linia]** — [opis problemu] → [jak naprawić]

### Sugestie (opcjonalne ulepszenia)
- **[plik:linia]** — [opis problemu] → [jak naprawić]

### Podsumowanie
- Przejrzano: X plików
- Znaleziono: X krytycznych, X ważnych, X sugestii
```

Jeśli brak problemów: "Review OK — X plików, 0 problemów."

### Krok 4: Auto-fix (opcjonalnie)

Jeśli użytkownik potwierdzi, napraw znalezione problemy automatycznie. Zacznij od krytycznych.

## Pułapki

### ❌ Review bez przeczytania kodu
**Objaw**: Agent raportuje "nie znalazłem problemów" bez faktycznego przeczytania plików
**Przyczyna**: Agent leniwie przeskakuje pliki zamiast je czytać
**Rozwiązanie**: ZAWSZE użyj Read na każdym zmienionym pliku. Grep `any`, `console.log`, `as ` w zmienionych plikach.

### ❌ False positives na Server Components
**Objaw**: Agent sugeruje dodanie `'use client'` do Server Components
**Przyczyna**: Agent nie rozumie że async components, `await fetch()`, database queries to Server Component features
**Rozwiązanie**: Jeśli komponent używa async/await, bazy danych, cookies() — to Server Component. NIE dodawaj `'use client'`.

### ❌ Ignorowanie kontekstu projektu
**Objaw**: Agent sugeruje zmiany sprzeczne z konwencjami projektu
**Przyczyna**: Agent nie sprawdził CLAUDE.md ani istniejących wzorców
**Rozwiązanie**: Przed review przeczytaj CLAUDE.md projektu i sprawdź konwencje w 2-3 istniejących plikach.

### ❌ Raportowanie `any` w plikach generowanych
**Objaw**: Agent reportuje `any` w node_modules, .next, supabase/functions/_shared
**Przyczyna**: Review objął pliki poza kontrolą
**Rozwiązanie**: Ogranicz review do plików w `src/`, `app/`, `lib/`, `components/` — pomiń generowane.

### ❌ Zalecanie RLS na tabelach lookup
**Objaw**: Agent wymaga RLS na tabeli `categories` lub `settings` która jest publiczna
**Przyczyna**: Nie każda tabela wymaga RLS — publiczne dane read-only mogą mieć policy `SELECT FOR ALL`
**Rozwiązanie**: Sprawdź czy tabela zawiera dane użytkownika. Jeśli nie — wystarczy `SELECT` policy dla all.

### ❌ Over-engineering error handling
**Objaw**: Agent dodaje try/catch do każdej linii
**Przyczyna**: Zbyt dosłowne stosowanie reguły "obsługa błędów"
**Rozwiązanie**: try/catch na granicach (API route, Server Action, fetch). Wewnętrzna logika — niech propaguje.
