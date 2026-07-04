---
name: path-scoped-rules
description: Generuje path-scoped rules (.claude/rules/) dla Next.js + Supabase — małe pliki reguł aktywowane per katalog (YAML path_glob) zamiast monolitycznego CLAUDE.md. Triggery: 'dodaj reguły do projektu', 'setup rules', 'reguły per folder', 'pilnuj standardów', nowy projekt.
---

## Czym są path-scoped rules

Claude Code natywnie ładuje pliki z `.claude/rules/` gdy agent edytuje pliki pasujące do `path_glob` w frontmatterze. Reguły są kontekstowe — agent widzi TYLKO reguły dla katalogu w którym pracuje.

### Korzyści vs monolityczny CLAUDE.md
- Agent nie jest zalewany 200+ regułami naraz
- Reguły dla komponentów React nie mieszają się z regułami Supabase
- Łatwiej utrzymywać i aktualizować per-domena
- Nowy developer widzi reguły w kontekście plików które edytuje

## Procedura wdrożenia

### Krok 1: Analiza projektu
```bash
# Sprawdź strukturę projektu
ls -d src/components/ src/app/api/ supabase/ src/__tests__/ e2e/ src/styles/ 2>/dev/null
# Sprawdź czy .claude/rules/ istnieje
ls .claude/rules/ 2>/dev/null || echo "Brak — tworzę"
```

### Krok 2: Stwórz .claude/rules/
```bash
mkdir -p .claude/rules
```

### Krok 3: Stwórz pliki reguł
Wybierz TYLKO pliki pasujące do struktury projektu. Nie twórz reguł dla katalogów które nie istnieją.

### Krok 4: Odchudź CLAUDE.md
Przenieś reguły z CLAUDE.md do path-scoped. Unikaj duplikacji. W CLAUDE.md zostaw tylko:
- Globalne zasady projektu (język, konwencje nazewnictwa)
- Lessons Learned
- Instrukcje specyficzne dla workflow

### Krok 5: Pokaż użytkownikowi
Wylistuj stworzone pliki i zapytaj czy chce dostosować.

---

## Szablony reguł

### 1. components.md — Komponenty React/UI

```markdown
---
path_glob: "src/components/**"
---

## Reguły komponentów

- Każdy komponent = osobny folder: `ComponentName/index.tsx` + opcjonalnie `ComponentName.test.tsx`
- Używaj shadcn/ui jako bazy — nie buduj od zera tego co shadcn oferuje
- Każdy komponent MUSI obsługiwać 3 stany: loading (Skeleton), error, empty
- Tailwind classes w porządku: layout → spacing → sizing → typography → colors → effects
- NIE używaj `style={{}}` inline — wyłącznie Tailwind
- NIE hardcoduj tekstów — używaj `t('key')` lub stałych (przygotuj na i18n)
- Accessibility: każdy interaktywny element ma `aria-label` lub widoczny label
- Eksportuj komponenty przez named export, nie default
- Props: interfejs z sufiksem `Props` (np. `ButtonProps`), nie `any`
```

### 2. api-routes.md — Endpointy API

```markdown
---
path_glob: "src/app/api/**"
---

## Reguły API routes

- Walidacja inputu na początku każdego endpointu (zod schema)
- Każdy endpoint mutujący: sprawdź auth (`getSession()`) PRZED logiką biznesową
- NIGDY nie zwracaj surowego `error.message` do klienta — loguj do console, zwróć generic message
- Response format ZAWSZE: `{ data, error, status }` — nigdy gołe obiekty
- Rate limiting: rozważ dla endpointów publicznych
- NIE zwracaj wrażliwych pól (password_hash, internal_id) — zdefiniuj DTO/select
- HTTP metody: GET (odczyt), POST (tworzenie), PATCH (aktualizacja), DELETE (usuwanie)
- Status codes: 200 (OK), 201 (created), 400 (bad request), 401 (unauthorized), 404 (not found), 500 (server error)
```

### 3. supabase.md — Baza danych i auth

```markdown
---
path_glob: "supabase/**"
---

## Reguły Supabase

- KAŻDA nowa tabela MUSI mieć RLS policy — bez wyjątków
- Migracje: nazwy opisowe `YYYYMMDD_HHMMSS_opis_zmiany.sql`
- NIE używaj `supabase.auth.getUser()` w Server Components — używaj `getSession()`
- NIE twórz klienta Supabase w `layout.tsx` — twórz w `page.tsx` lub `actions.ts`
- Foreign keys: ZAWSZE z `ON DELETE CASCADE` lub `ON DELETE SET NULL` — nigdy bez
- Indeksy: dodaj na każdą kolumnę używaną w WHERE/JOIN
- Seedy: umieszczaj w `supabase/seed.sql`, nie w migracji
- Typy: generuj przez `supabase gen types typescript` po każdej migracji
- SECURITY DEFINER: używaj TYLKO gdy RLS musi być ominięty (np. trigger systemowy)
```

### 4. tests.md — Testy

```markdown
---
path_glob: "{src/__tests__/**,e2e/**,**/*.test.*,**/*.spec.*}"
---

## Reguły testów

- Naming: `describe('NazwaKomponentu')` → `it('should + opis zachowania')`
- Testuj zachowanie, NIE implementację (co komponent renderuje, co API zwraca)
- Mockuj Supabase clienta, nie realną bazę (chyba że e2e)
- Każdy test MUSI być niezależny — nie polegaj na kolejności uruchamiania
- E2E (Playwright): używaj `data-testid` do selektorów, nie klas CSS
- Arrange-Act-Assert: 3 sekcje w każdym teście
- NIE testuj detali implementacji (prywatne metody, wewnętrzny state)
- Coverage: testuj happy path + 2-3 edge cases (null, empty, error)
```

### 5. styles.md — Style CSS/Tailwind

```markdown
---
path_glob: "{src/styles/**,**/*.css}"
---

## Reguły stylów

- NIE używaj `@apply` w Tailwind v4 w CSS modules
- Zmienne kolorów definiuj w `globals.css` jako CSS custom properties
- Dark mode: używaj `class` strategy, nie `media`
- Unikaj magicznych wartości — jeśli kolor/spacing się powtarza, wyciągnij do zmiennej
- Z-index: używaj skali (10, 20, 30...), nie losowych wartości
- Animacje: preferuj CSS transitions nad JavaScript animacje
- Mobile-first: style bazowe dla mobile, media queries dla większych breakpointów
```

### 6. prototypes.md — Prototypy (luźniejsze reguły)

```markdown
---
path_glob: "prototypes/**"
---

## Reguły prototypów

- Prototypy to kod jednorazowy — NIE muszą spełniać standardów produkcyjnych
- ALE: każdy prototyp MUSI mieć README.md z: cel, hipoteza, wynik, decyzja (kontynuować/porzucić)
- NIE importuj z prototypes/ do src/ — jeśli prototyp się sprawdził, przepisz go porządnie
- console.log dozwolone
- Hardcoded dane dozwolone (ale nie sekrety)
```

---

### 7. design-tokens-enforcer.md — Wymuszanie design system (wzorzec: tailwind-system-enforcer)

```markdown
---
path_glob: "{src/components/**,src/app/**/*.tsx}"
---

## Design Tokens Enforcer

Jesteś Frontend Consistency Architect. NIE projektujesz kreatywnie — EGZEKWUJESZ istniejący design system.

### Źródło prawdy: CSS Variables

Używaj WYŁĄCZNIE semantycznych nazw z design systemu projektu. NIGDY hex/rgb/hsl/oklch bezpośrednio.

**Tła:** `bg-background` (strona), `bg-card` (kontenery), `bg-muted` (sekcje drugorzędne)
**Tekst:** `text-foreground` (główny), `text-muted-foreground` (etykiety), `text-primary` (akcent)
**Bordy:** `border-border`, `border-input`
**Interaktywne:** `bg-primary` + `text-primary-foreground` (przyciski główne), `hover:bg-accent` (elementy interaktywne)
**Radius:** `rounded-lg` (mapuje na `var(--radius)`)

### Protokół "Master Reference"

Gdy budujesz NOWY komponent, NAJPIERW przeanalizuj istniejący komponent tego samego typu w projekcie:

1. **Card Anatomy** — znajdź dokładny class string kontenera (`bg-card`, `border`, `shadow-sm`, `rounded-lg`, `hover:` klasy)
2. **Typography Scale** — sprawdź klasy nagłówków vs body (np. `text-2xl font-bold` → użyj identycznych)
3. **Spacing DNA** — sprawdź `gap-`, `p-`, `m-` wartości. Jeśli istniejący komponent używa `gap-6`, nowy też musi

### Checklist (HARD RULES)

- [ ] NIGDY arbitrary values (`text-[17px]`, `p-[13px]`) — używaj skali Tailwind (`text-sm`, `p-4`)
- [ ] NIGDY nowych kolorów — wyłącznie `bg-primary`, `bg-card`, `text-foreground` itp.
- [ ] NIGDY `style={{}}` inline — wyłącznie Tailwind utilities
- [ ] ZAWSZE dark mode support (automatyczny przez CSS variables — trzymaj się utility classes)
- [ ] Hover states identyczne jak w Master Reference
- [ ] Font sizes identyczne jak w Master Reference
- [ ] Nowy komponent obok starego = nie odróżnisz że pisane w różnym czasie
```

## Dostosowanie do projektu

NIE kopiuj wszystkich 6 plików ślepo. Sprawdź co istnieje:

| Katalog | Plik reguł | Twórz gdy |
|---------|-----------|-----------|
| `src/components/` | components.md | Zawsze (każdy projekt React) |
| `src/app/api/` | api-routes.md | Projekt ma API routes |
| `supabase/` | supabase.md | Projekt używa Supabase |
| `src/__tests__/` lub `e2e/` | tests.md | Projekt ma testy |
| `src/styles/` | styles.md | Projekt ma custom CSS |
| `prototypes/` | prototypes.md | Rzadko — tylko gdy folder istnieje |
| `src/components/` + `src/app/` | design-tokens-enforcer.md | Projekt używa unified-design-system lub shadcn/ui |

## Pułapki

- NIE twórz rules dla katalogów które nie istnieją w projekcie — Claude Code je zignoruje, a Ty stracisz czas
- NIE duplikuj reguł — jeśli przenosisz regułę z CLAUDE.md do path-scoped, USUŃ ją z CLAUDE.md
- NIE twórz zbyt wielu reguł na start — 4-6 plików to optimum. Dodawaj kolejne gdy pojawią się problemy
- Path glob MUSI być relative do roota projektu — nie absolutny
- Każdy plik max 20-30 reguł — jeśli więcej, podziel na sub-pliki
- Po stworzeniu rules, uruchom `claude` w projekcie i edytuj plik w danym katalogu — sprawdź czy agent stosuje reguły
- Reguły w `.claude/rules/` mają WYŻSZY priorytet niż CLAUDE.md gdy dotyczą tego samego tematu
