---
name: project-scaffolder
description: Scaffolding nowych projektów z AIwBiznesie Launchpad — klonowanie, konfiguracja .env, setup Supabase/Stripe, generowanie motywu z referencji wizualnych, rejestracja w Project Master. Używaj przy "nowy projekt", "stwórz projekt", "scaffold", "projekt dla klienta", "nowa aplikacja", "zainicjuj projekt", "setup projektu". Auto-aktywacja gdy użytkownik chce stworzyć nowy projekt SaaS. NIE używaj do istniejących projektów — do tego jest cross-project-onboarder.
---

# Project Scaffolder

Automatyzacja tworzenia nowych projektów na bazie AIwBiznesie Launchpad. Od klonowania szablonu po rejestrację w Project Master w jednym workflow.

## Kiedy używać

- Tworzenie nowego projektu dla klienta
- Scaffold nowej aplikacji SaaS/landing page
- Konfiguracja nowego projektu z szablonu Launchpad
- Generowanie motywu z referencji wizualnych (screenshoty)
- Rejestracja nowego projektu w ekosystemie Project Master

## Komendy

```
/projekt nowy <nazwa>              — scaffold z Launchpad + interaktywna konfiguracja
/projekt theme <screenshot_urls>   — generuj motyw z referencji wizualnych
/projekt config                    — konfiguracja .env (Supabase, Stripe, domena)
/projekt register                  — rejestruj w Project Master
/projekt status                    — sprawdź kompletność konfiguracji
```

## Instrukcje

### /projekt nowy <nazwa> — Pełny scaffold

1. **Walidacja nazwy**
   - Konwertuj na slug (lowercase, myślniki): "Hotel Demo" → `hotel-demo`
   - Sprawdź czy `~/projekty/<nazwa>` nie istnieje
   - Sprawdź czy repo `<slug>` nie istnieje na GitHub

2. **Klonowanie Launchpad**
   ```bash
   # Klonuj szablon
   cp -r ~/projekty/Starter\ Kit/aiwbiznesie-launchpad ~/projekty/<Nazwa>
   cd ~/projekty/<Nazwa>

   # Resetuj git
   rm -rf .git
   git init
   ```

3. **Interaktywna konfiguracja** — zapytaj użytkownika:
   - Nazwa firmy/projektu (display name)
   - Opis (1 zdanie)
   - Typ: `saas` | `landing` | `dashboard` | `marketplace`
   - Supabase project ID (lub "stwórz nowy")
   - Stripe account (lub "pomiń")
   - Domena docelowa
   - Czy generować motyw z screenshotów?

4. **Konfiguracja plików**
   - `.env.local` — uzupełnij Supabase URL/keys, Stripe keys
   - `package.json` — zaktualizuj `name`, `description`
   - `index.html` — zaktualizuj `<title>`, `<meta description>`, `lang="pl"`
   - `src/` — zaktualizuj brandowanie (logo placeholder, nazwa)
   - CLAUDE.md — dodaj sekcję z kontekstem projektu

5. **Setup Supabase** (jeśli podano ID)
   - Zweryfikuj połączenie: `supabase status`
   - Sprawdź czy podstawowe tabele istnieją
   - Jeśli nie → uruchom migracje Launchpad

6. **Inicjalizacja repo**
   ```bash
   git add -A
   git commit -m "Initial scaffold from AIwBiznesie Launchpad"
   ```

7. **Zaproponuj:** "Utworzyć repo na GitHub i zarejestrować w Project Master?"

### /projekt theme <screenshots> — Generowanie motywu

1. **Zbierz referencje wizualne** — screenshoty stron konkurencji lub inspiracji
2. **Analizuj** za pomocą Stitch lub wizualnie:
   - Kolory dominujące → wyciągnij paletę (primary, secondary, accent)
   - Typografia → zidentyfikuj fonty (serif/sans-serif, weight)
   - Layout patterns → grid, spacing, border-radius
   - Dark/light mode
3. **Generuj JSON motywu** kompatybilny z `unified-design-system`:
   ```json
   {
     "name": "Nazwa motywu",
     "colors": {
       "primary": "#...",
       "secondary": "#...",
       "accent": "#...",
       "background": "#...",
       "foreground": "#..."
     },
     "typography": {
       "fontFamily": "...",
       "headingFamily": "..."
     },
     "borderRadius": "0.5rem",
     "mode": "dark"
   }
   ```
4. **Wdrożyć** do CSS variables projektu

### /projekt config — Konfiguracja .env

Interaktywny wizard:

1. **Supabase**
   - `VITE_SUPABASE_URL` — URL projektu
   - `VITE_SUPABASE_ANON_KEY` — klucz publiczny
   - `SUPABASE_SERVICE_ROLE_KEY` — klucz serwisowy (tylko backend)

2. **Stripe** (opcjonalny)
   - `VITE_STRIPE_PUBLISHABLE_KEY`
   - `STRIPE_SECRET_KEY`
   - `STRIPE_WEBHOOK_SECRET`

3. **Aplikacja**
   - `VITE_APP_NAME` — nazwa widoczna w UI
   - `VITE_APP_URL` — URL produkcyjny

4. **AI** (opcjonalny)
   - `OPENAI_API_KEY` lub `VERCEL_OIDC_TOKEN` (jeśli Vercel)

**UWAGA:** Użyj skilla `credentials-vault` do bezpiecznego przechowywania kluczy.

### /projekt register — Rejestracja w Project Master

1. **Generuj manifest** `project-meta.json`:
   ```json
   {
     "slug": "<slug>",
     "name": "<Nazwa>",
     "type": "<typ>",
     "status": "scaffolded",
     "stack": ["vite", "react", "typescript", "tailwind", "supabase"],
     "created": "<ISO date>",
     "repository": "github.com/...",
     "manual": {
       "skills_active": [],
       "skills_needed": []
     }
   }
   ```
2. **Push manifest** do `project-master-data/manifests/<slug>.json`
3. **Zaktualizuj** `project-master-data/manifests/registry.json`

### /projekt status — Sprawdź kompletność

Checklist:

- [ ] `.env.local` istnieje z wymaganymi kluczami
- [ ] `package.json` ma unikalne `name`
- [ ] `CLAUDE.md` ma kontekst projektu
- [ ] Git zainicjalizowany z initial commit
- [ ] Supabase połączone (jeśli dotyczy)
- [ ] Stripe skonfigurowany (jeśli dotyczy)
- [ ] Motyw wygenerowany (jeśli dotyczy)
- [ ] Repo na GitHub (opcjonalne)
- [ ] Manifest w Project Master (opcjonalne)

## Pułapki

### 1. Supabase shared vs dedicated
Launchpad domyślnie używa shared Supabase. Dla produkcji klienta → zawsze dedykowany projekt.

### 2. .env.local z Launchpadu
Launchpad ma `.env.local` z przykładowymi kluczami. ZAWSZE nadpisz prawdziwymi — stare klucze mogą pasować do innego projektu.

### 3. CLAUDE.md z Launchpadu
Launchpad ma swoje CLAUDE.md. Nie usuwaj — dostosuj do nowego projektu (dodaj kontekst klienta, stack decyzje).

### 4. Git history
Po `cp -r` Launchpadu folder ma historię oryginalnego repo. ZAWSZE `rm -rf .git && git init` — czysta historia.

### 5. Stripe test vs live keys
Przy scaffoldzie ZAWSZE użyj test keys (`pk_test_`, `sk_test_`). Live keys dopiero przy deploy na produkcję.

### 6. Tailwind v4 migracja
Launchpad jest na Tailwind v4. Jeśli dodajesz biblioteki — sprawdź kompatybilność z v4 (`@theme` syntax, nie `tailwind.config.js`).

### 7. Supabase RLS
Nowy projekt = puste tabele bez RLS. Zawsze dodaj RLS policies PRZED insertem danych. Użyj skilla `supabase-auth-rls`.

## Aliasy komend (PL + EN)

| PL | EN |
|----|-----|
| `/projekt nowy <nazwa>` | `/project new <name>` |
| `/projekt motyw <screeny>` | `/project theme <screenshots>` |
| `/projekt konfiguracja` | `/project config` |
| `/projekt rejestruj` | `/project register` |
| `/projekt status` | `/project status` |

## Chain of Skills

Po scaffoldzie sugeruj:
- `credentials-vault` — zapisz klucze API
- `supabase-auth-rls` — konfiguracja auth
- `path-scoped-rules` — standardy kodowania
- `session-hooks` — ciągłość sesji
- `github-init` — repo na GitHub
- `project-master-manifest` — rejestracja w PM
