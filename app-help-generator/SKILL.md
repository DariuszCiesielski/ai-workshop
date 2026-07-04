---
name: app-help-generator
description: Automatyczne generowanie sekcji pomocy użytkownika w aplikacjach React/Vite/Next.js. Analizuje routing, formularze, role i generuje React komponenty z nawigacją na route /help. Przyrostowa aktualizacja po zmianach. Używaj gdy użytkownik mówi "dodaj pomoc do aplikacji", "wygeneruj sekcję pomocy", "help section", "zaktualizuj pomoc", "przeanalizuj aplikację pod kątem pomocy".
---

# App Help Generator

Skill do automatycznego generowania sekcji pomocy użytkownika jako React komponenty wbudowane w aplikację (route `/help`).

## Kiedy używać

- Dodawanie sekcji pomocy do istniejącej aplikacji React/Vite/Next.js
- Aktualizacja pomocy po zmianach w aplikacji
- Analiza aplikacji pod kątem dokumentacji użytkownika

## Triggery

- "dodaj pomoc do aplikacji" / "wygeneruj sekcję pomocy" / "help section"
- "zaktualizuj pomoc" / "update help"
- "przeanalizuj aplikację pod kątem pomocy"

## Tryby pracy

| Komenda | Opis |
|---------|------|
| `help-gen analyze` | Skanuje aplikację, buduje `.help/analysis.json` |
| `help-gen generate` | Generuje strony pomocy (React komponenty) |
| `help-gen update` | Przyrostowa aktualizacja po zmianach |
| `help-gen` | Pełny pipeline: analyze → generate |

## Pipeline

```
Faza 1: ANALIZA ──→ Faza 2: GENEROWANIE ──→ [Faza 3: AKTUALIZACJA]
  (skan aplikacji)    (React komponenty)      (po zmianach, przyrostowo)
```

---

## Faza 1: Analiza aplikacji (`help-gen analyze`)

Skanuj projekt i zbuduj model wiedzy. Przeczytaj prompt [prompts/analyzer.md](prompts/analyzer.md).

### Co analizować

| Element | Gdzie szukać | Co wyciągnąć |
|---------|-------------|--------------|
| **Routing** | `App.tsx`, `router.tsx`, `pages/` | Ścieżki, parametry, zagnieżdżenia |
| **Nawigacja** | Sidebar, Menu, Breadcrumbs | Struktura menu, etykiety, ikony |
| **Formularze** | Komponenty z `<form>`, `useForm`, `zod` | Pola, walidacja, flow zapisu |
| **Role** | `ProtectedRoute`, RLS, `useAuth` | Admin vs user, chronione ścieżki |
| **Konfiguracja** | `.env.example`, `config.ts` | Klucze API, integracje zewnętrzne |
| **Stany** | Loading, Error, Empty states | Co użytkownik zobaczy w edge cases |
| **GSD kontekst** | `.planning/`, `PROJECT.md`, `ROADMAP.md` | Cel projektu, fazy, features (jeśli istnieje) |

### Proces analizy

1. **Routing** — znajdź router (React Router, Next.js pages, TanStack Router):
   ```bash
   # Szukaj definicji routingu
   grep -r "createBrowserRouter\|Routes\|Route path\|pages/" src/
   ```

2. **Nawigacja** — znajdź sidebar/menu i wyciągnij strukturę:
   ```bash
   grep -r "Sidebar\|NavLink\|NavigationMenu" src/
   ```

3. **Formularze** — znajdź formularze i ich pola:
   ```bash
   grep -r "useForm\|<form\|onSubmit\|zodResolver" src/
   ```

4. **Role i uprawnienia** — znajdź kontrolę dostępu:
   ```bash
   grep -r "ProtectedRoute\|useAuth\|role\|isAdmin" src/
   ```

5. **Konfiguracja** — przeczytaj `.env.example` i znajdź integracje:
   ```bash
   cat .env.example 2>/dev/null
   grep -r "process.env\|import.meta.env" src/
   ```

6. **Stany UI** — znajdź loading/error/empty states:
   ```bash
   grep -r "isLoading\|isError\|isEmpty\|Skeleton\|Spinner" src/
   ```

### Output: `.help/analysis.json`

Zapisz wynik analizy w `.help/analysis.json`:

```json
{
  "version": "1.0.0",
  "analyzedAt": "{{ISO_DATE}}",
  "project": {
    "name": "{{PROJECT_NAME}}",
    "stack": "{{STACK}}",
    "router": "react-router|next|tanstack"
  },
  "routes": [
    {
      "path": "/dashboard",
      "component": "Dashboard",
      "protected": true,
      "role": "user",
      "description": "Panel główny z podsumowaniem"
    }
  ],
  "navigation": {
    "sidebar": [
      { "label": "Dashboard", "path": "/dashboard", "icon": "LayoutDashboard" }
    ],
    "userMenu": ["Profil", "Ustawienia", "Wyloguj"]
  },
  "forms": [
    {
      "component": "LoginForm",
      "path": "/login",
      "fields": ["email", "password"],
      "validation": "zod",
      "submitAction": "signIn"
    }
  ],
  "roles": {
    "types": ["admin", "user"],
    "protectedRoutes": ["/admin/*"],
    "mechanism": "ProtectedRoute + RLS"
  },
  "config": {
    "envVars": ["VITE_SUPABASE_URL", "VITE_SUPABASE_ANON_KEY"],
    "integrations": ["supabase", "stripe"]
  },
  "states": {
    "loading": ["Skeleton", "Spinner"],
    "error": ["ErrorBoundary", "toast.error"],
    "empty": ["EmptyState"]
  }
}
```

---

## Faza 2: Generowanie React komponentów (`help-gen generate`)

Na bazie `analysis.json` generuj React komponenty. Przeczytaj prompt [prompts/writer.md](prompts/writer.md).

### Struktura generowanych plików

```
src/components/help/
├── HelpLayout.tsx          ← Layout z nawigacją boczną i wyszukiwarką
├── HelpNav.tsx             ← Nawigacja z kategoriami
├── HelpPage.tsx            ← Wrapper pojedynczej strony
├── HelpSearch.tsx          ← Wyszukiwarka w treści pomocy
├── pages/
│   ├── ConfigurationHelp.tsx    ← Konfiguracja: credentials, API keys
│   ├── UserManagementHelp.tsx   ← Zarządzanie użytkownikami
│   ├── UserFlowsHelp.tsx        ← Ścieżki użytkownika
│   ├── NavigationHelp.tsx       ← Mapa aplikacji
│   └── FAQHelp.tsx              ← FAQ
└── index.ts                ← Eksporty
```

### Sekcje pomocy do wygenerowania

| Sekcja | Co zawiera | Źródło z `analysis.json` |
|--------|-----------|--------------------------|
| **Konfiguracja** | Krok po kroku: credentials, API keys, integracje | `config.envVars`, `config.integrations` |
| **Zarządzanie użytkownikami** | Admin: tworzenie kont, role, uprawnienia | `roles`, `forms` z auth |
| **Ścieżki użytkownika** | Jak realizować kluczowe funkcje aplikacji | `routes`, `forms`, `navigation` |
| **Nawigacja** | Mapa aplikacji — co gdzie znaleźć | `navigation`, `routes` |
| **FAQ** | Najczęstsze pytania i rozwiązania | `states`, edge cases, walidacja |

### Integracja z routerem

Dodaj route `/help` do routera aplikacji:

```typescript
// React Router
{ path: "/help/*", element: <HelpLayout /> }

// Next.js
// app/help/layout.tsx + app/help/page.tsx

// TanStack Router
// routes/help/route.tsx
```

### Wymagania treści

- **Język:** polski z pełnymi diakrytykami (ą, ć, ę, ł, ń, ó, ś, ź, ż)
- **Styl:** prosty, nietechniczny — pisz dla użytkownika końcowego, nie programisty
- **Screenshoty:** placeholdery z opisem: `{/* Screenshot: Widok panelu głównego */}`
- **Responsywność:** mobile-first, działa na wszystkich urządzeniach

### Szablony komponentów

Użyj szablonów z katalogu [templates/](templates/) jako bazę:
- [HelpLayout.tsx](templates/HelpLayout.tsx) — layout z sidebar + mobile drawer
- [HelpPage.tsx](templates/HelpPage.tsx) — wrapper strony z breadcrumbs
- [HelpNav.tsx](templates/HelpNav.tsx) — nawigacja z kategoriami i ikonami

Dostosuj szablony do stacku projektu (Tailwind, shadcn/ui, CSS modules).

---

## Faza 3: Aktualizacja przyrostowa (`help-gen update`)

Po zmianach w aplikacji — nie regeneruj całości, aktualizuj tylko zmienione strony. Przeczytaj prompt [prompts/updater.md](prompts/updater.md).

### Proces aktualizacji

1. **Ponów analizę** — uruchom Fazę 1, wygeneruj nowy `analysis.json`
2. **Porównaj** — diff starego i nowego `analysis.json`:
   - Nowe routes → nowe strony pomocy
   - Usunięte routes → oznacz jako archived lub usuń
   - Zmienione formularze → zaktualizuj opis pól
   - Nowe role → zaktualizuj sekcję uprawnień
3. **Zaktualizuj** — zmień TYLKO dotknięte strony w `src/components/help/pages/`
4. **Zaproponuj** — jeśli pojawił się nowy feature, zaproponuj nową stronę pomocy

### Zasada przyrostowości

> **KRYTYCZNE:** Nigdy nie regeneruj wszystkich stron. Aktualizuj tylko te, które dotyczą zmienionych elementów. Sprawdź diff `analysis.json` przed jakąkolwiek edycją.

---

## Konfiguracja per projekt

Opcjonalnie utwórz `.help/config.json` do customizacji:

```json
{
  "language": "pl",
  "sections": ["configuration", "user-management", "user-flows", "navigation", "faq"],
  "style": {
    "useProjectDesignSystem": true,
    "showScreenshotPlaceholders": true,
    "searchEnabled": true
  },
  "exclude": {
    "routes": ["/dev/*", "/test/*"],
    "components": ["DevTools", "TestPage"]
  }
}
```

---

## Integracja z GSD (opcjonalna)

Jeśli projekt używa wtyczki GSD, skill może wykorzystać dodatkowy kontekst:

| Plik GSD | Co daje pomocy |
|----------|---------------|
| `PROJECT.md` | Cel projektu, opis dla użytkownika — wstęp do sekcji pomocy |
| `ROADMAP.md` | Lista features i faz — pomaga zidentyfikować kluczowe flow |
| `.planning/codebase/` | Mapa architektury — szybsze zrozumienie struktury |
| `.planning/phases/*/PLAN.md` | Szczegóły implementacji — precyzyjniejsze opisy flow |
| `VERIFICATION.md` | Wyniki weryfikacji — gotowe scenariusze do FAQ |

### Jak wykorzystać

W Fazie 1 (analiza) sprawdź czy istnieje katalog `.planning/`:
- Jeśli tak — przeczytaj `PROJECT.md` i `ROADMAP.md` i użyj jako kontekstu do generowania lepszych opisów
- Opisy features z roadmapy to gotowy materiał na sekcję "Ścieżki użytkownika"
- Wyniki weryfikacji (`VERIFICATION.md`) to gotowe scenariusze do FAQ

### Automatyczna aktualizacja po GSD

Po zakończeniu fazy GSD (`/gsd:verify-work` → PASS), można uruchomić `help-gen update` żeby zaktualizować pomoc o nowe features.

---

## Integracja z AI Crew (opcjonalna)

Po runie AI Crew z nowym feature, można dodać post-step:

```
crew run "Dodaj feature X" → po ACCEPTED → help-gen update
```

Skill działa niezależnie — AI Crew i GSD nie są wymagane.

---

## Kompatybilność

- **Stack:** React + TypeScript + Tailwind CSS (kompatybilny z `unified-design-system`)
- **Routery:** React Router v6+, Next.js App/Pages Router, TanStack Router
- **Język:** polski z diakrytykami (kompatybilny z globalnym CLAUDE.md)
- **Motywy:** obsługuje dark mode jeśli projekt go używa

---

## Checklist weryfikacji

Po wygenerowaniu sekcji pomocy sprawdź:

- [ ] `.help/analysis.json` poprawnie wykrył routing, formularze, role
- [ ] `src/components/help/` zawiera wszystkie wymagane komponenty
- [ ] Route `/help` jest dodany do routera aplikacji
- [ ] Nawigacja pomocy zawiera wszystkie sekcje
- [ ] Treść jest po polsku z pełnymi diakrytykami
- [ ] Strony są responsywne (mobile)
- [ ] Wyszukiwarka działa
- [ ] Link do pomocy jest widoczny w nawigacji aplikacji (np. `?` w headerze)

---

## Dodatkowe zasoby

- Prompty: [prompts/analyzer.md](prompts/analyzer.md), [prompts/writer.md](prompts/writer.md), [prompts/updater.md](prompts/updater.md)
- Szablony: [templates/](templates/)

## Auto-feedback (samoanaliza po użyciu)

Po zakończeniu pracy ze skillem, agent MUSI wygenerować krótki raport i zapisać go w:
`~/projekty/Moje skille/feedback/app-help-generator-feedback-{{DATA}}.md`

### Format raportu

```markdown
# Feedback: app-help-generator
Data: {{DATA}}
Projekt: {{NAZWA_PROJEKTU}}
Agent: {{MODEL}}

## Co zadziałało dobrze
- [lista]

## Anomalie i problemy
- [opis problemu, kontekst, wpływ na wynik]

## Brakujące instrukcje
- [czego brakowało w skillu, co agent musiał improwizować]

## Sugestie usprawnień
- [konkretne propozycje zmian z uzasadnieniem]

## Metryki
- Czas wykonania: ~X min
- Liczba kroków/faz: X
- Wynik: sukces/częściowy/porażka
```

### Zasady
- Raport generuj TYLKO gdy jest coś wartościowego do zgłoszenia (anomalie, brakujące instrukcje, sugestie)
- Jeśli skill zadziałał bez problemów — NIE generuj raportu (brak raportu = wszystko OK)
- Nie raportuj ogólników ("testy mogłyby być lepsze") — tylko konkretne, actionable obserwacje
- Raport to MAX 20 linii — zwięźle i na temat
