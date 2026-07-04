# Prompt: Analiza aplikacji

> Jesteś ekspertem od analizy aplikacji React/Vite/Next.js. Twoje zadanie to przeskanowanie projektu i zbudowanie strukturalnego modelu wiedzy o aplikacji, który posłuży do wygenerowania sekcji pomocy użytkownika.

## Cel

Stwórz plik `.help/analysis.json` zawierający kompletny model aplikacji: routing, nawigację, formularze, role, konfigurację i stany UI.

## Kontekst projektu

{{PROJECT_CONTEXT}}

## Instrukcje krok po kroku

### 1. Zidentyfikuj router

Sprawdź jaki router używa projekt:

| Router | Szukaj | Pliki |
|--------|--------|-------|
| React Router v6+ | `createBrowserRouter`, `RouterProvider`, `<Routes>` | `App.tsx`, `router.tsx`, `main.tsx` |
| Next.js App Router | `app/` directory, `layout.tsx`, `page.tsx` | `app/**/*.tsx` |
| Next.js Pages Router | `pages/` directory, `_app.tsx` | `pages/**/*.tsx` |
| TanStack Router | `createRouter`, `createRoute`, `routeTree` | `routes/`, `routeTree.gen.ts` |

Wyciągnij:
- Pełną listę ścieżek (path)
- Komponent przypisany do każdej ścieżki
- Czy ścieżka jest chroniona (ProtectedRoute, middleware, auth guard)
- Wymagana rola (admin, user, public)
- Opis na bazie nazwy komponentu i kontekstu

### 2. Zmapuj nawigację

Znajdź komponenty nawigacyjne:

- **Sidebar** — `Sidebar.tsx`, `SideNav.tsx`, `AppSidebar.tsx`
- **Header/Topbar** — `Header.tsx`, `Navbar.tsx`, `TopBar.tsx`
- **Menu mobilne** — `MobileNav.tsx`, drawer, sheet
- **Breadcrumbs** — `Breadcrumbs.tsx`, `Breadcrumb`
- **UserMenu** — `UserMenu.tsx`, dropdown z profilem

Wyciągnij:
- Etykiety menu (po polsku — to co widzi użytkownik)
- Ścieżki docelowe
- Ikony (nazwa komponentu ikony)
- Grupowanie/kategorie
- Elementy widoczne per rola (admin vs user)

### 3. Przeanalizuj formularze

Znajdź formularze i ich pola:

```
Szukaj: useForm, zodResolver, <form, onSubmit, handleSubmit
Pliki: src/**/*.tsx
```

Dla każdego formularza wyciągnij:
- Nazwa komponentu (np. `LoginForm`, `CreateUserForm`)
- Ścieżka/widok gdzie się pojawia
- Lista pól (name, type, label, required)
- Schemat walidacji (zod, yup — jakie reguły)
- Akcja submit (co się dzieje po wysłaniu)
- Komunikaty błędów

### 4. Zidentyfikuj role i uprawnienia

Szukaj wzorców kontroli dostępu:

- `ProtectedRoute` — jakie role wymagane
- `useAuth()`, `useUser()` — co zwracają
- `role`, `isAdmin`, `permissions` — jak sprawdzane
- RLS policies (jeśli Supabase) — jakie tabele chronione
- Widoczność elementów per rola (`{isAdmin && <AdminPanel />}`)

### 5. Zmapuj konfigurację

Przeczytaj:
- `.env.example` — lista zmiennych środowiskowych z opisami
- `package.json` — integracje zewnętrzne (supabase, stripe, sendgrid, cloudinary)
- Pliki konfiguracyjne — `config.ts`, `constants.ts`
- Komentarze w `.env.example` (często opisują do czego klucz)

### 6. Znajdź stany UI

Szukaj wzorców stanów:

| Stan | Szukaj | Znaczenie dla pomocy |
|------|--------|---------------------|
| Loading | `isLoading`, `Skeleton`, `Spinner`, `isPending` | "Co widzisz podczas ładowania" |
| Error | `isError`, `ErrorBoundary`, `toast.error` | "Co zrobić gdy pojawi się błąd" |
| Empty | `EmptyState`, "Brak danych", "Nie znaleziono" | "Dlaczego strona jest pusta" |
| Success | `toast.success`, redirect po akcji | "Potwierdzenie operacji" |

### 7. Kontekst z GSD (jeśli dostępny)

Sprawdź czy projekt używa wtyczki GSD:

```
ls .planning/ PROJECT.md ROADMAP.md 2>/dev/null
```

Jeśli tak, przeczytaj:
- **`PROJECT.md`** — cel projektu, opis, kontekst biznesowy → użyj jako wstęp do sekcji pomocy
- **`ROADMAP.md`** — lista faz i features → zidentyfikuj kluczowe flow użytkownika
- **`.planning/codebase/`** — mapa architektury → szybsze zrozumienie struktury kodu
- **`.planning/phases/*/PLAN.md`** — szczegóły implementacji features → precyzyjniejsze opisy
- **`VERIFICATION.md`** — scenariusze testowe → gotowy materiał do FAQ

Dodaj do `analysis.json` opcjonalne pole:
```json
"gsd": {
  "projectDescription": "Opis z PROJECT.md",
  "features": ["feature z ROADMAP"],
  "verificationScenarios": ["scenariusz z VERIFICATION.md"]
}
```

## Format wyjścia

Zapisz wynik w `.help/analysis.json` zgodnie ze schematem z SKILL.md.

### Zasady

1. **Kompletność** — każda publiczna ścieżka musi być w `routes`
2. **Dokładność** — opisy muszą odzwierciedlać rzeczywisty kod, nie domysły
3. **Czytelność** — opisy po polsku, zrozumiałe dla nietechnicznego użytkownika
4. **Bez duplikatów** — każdy element raz, nawet jeśli pojawia się w wielu plikach
5. **Ścieżki chronione** — wyraźnie oznaczone z wymaganą rolą

## Pułapki

- Nie zakładaj struktury — czytaj faktyczny kod, nie zgaduj
- Dynamiczne route (`:id`, `[slug]`) — opisz co jest parametrem
- Lazy-loaded routes — sprawdź `React.lazy()`, `import()` — mogą ukrywać strony
- Zagnieżdżone layouty — sprawdź `<Outlet />` i nested routes
- Conditional rendering — `{condition && <Component />}` może ukrywać sekcje per rola
