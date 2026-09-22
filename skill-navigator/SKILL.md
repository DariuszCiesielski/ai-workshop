---
name: skill-navigator
description: >
  Katalog wszystkich skilli z opisami, instrukcjami użycia i gotowymi ścieżkami workflow.
  Używaj gdy użytkownik pyta "jakie mam skille", "co mogę zrobić", "lista skilli",
  "który skill do X", "pokaż workflow", "jak zacząć nowy projekt",
  "jakie skille użyć do", "navigator", "mapa skilli", "skill catalog".
  Triggeruj też gdy użytkownik jest zagubiony i nie wie od czego zacząć.
  NIE używaj gdy użytkownik już wie którego skilla potrzebuje — wtedy użyj go bezpośrednio.
---

# Katalog skilli — 277 narzędzi w 18 kategoriach

## Jak używać tego katalogu

1. **Szukasz skilla?** → Znajdź kategorię poniżej lub powiedz "który skill do [problem]"
2. **Zaczynasz nowy projekt?** → Idź do sekcji "Ścieżki workflow" → Scenariusz 1
3. **Dodajesz feature?** → Ścieżka 2
4. **Chcesz instrukcję dla CLAUDE.md?** → Sekcja "Instrukcja dla agenta"

**Zestawy skilli (bundle):** Jeśli istnieje bundle w `~/.claude/bundles/*.yaml` pokrywający intencję
użytkownika (np. pełny audyt GEO, audyt bezpieczeństwa), zaproponuj uruchomienie `/nazwa-bundla`
zamiast wymieniać pojedyncze skille — bundle ładuje cały zestaw jednym poleceniem. Dostępne dziś:
`/geo-full` (8 skilli GEO/SEO), `/cybersec-audit` (5 skilli bezpieczeństwa, audyt zgodności).

---

## 1. Tworzenie projektów i scaffold

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `vite-react-tailwind4` | Nowy projekt Vite + React 19 + TypeScript + Tailwind v4 | "Nowy projekt React", "stwórz aplikację" |
| `admin-panel-scaffold` | Panel admina z auth, sidebar, routing, dark mode | "Panel administracyjny", "dashboard" |
| `unified-design-system` | 6 motywów, ThemeContext, UserMenu, CSS variables | "Dodaj motywy", "design system", "dark mode" |
| `kanban-dnd-board` | Tablica Kanban z drag & drop (@dnd-kit) | "Tablica zadań", "Kanban board" |
| `user-management-system` | CRUD użytkowników z rolami | "Zarządzanie użytkownikami" |

**Jak użyć:** Powiedz np. *"Stwórz nowy projekt React z panelem admina"* → agent użyje `vite-react-tailwind4` + `admin-panel-scaffold`.

## 2. UI i komponenty

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `shadcn-manual` | Ręczne dodawanie komponentów shadcn/ui | "Dodaj komponent", "button", "dialog", "table" |
| `brand-elements` | Favicon, Footer, elementy marki | "Dodaj favicon", "stopka", "branding" |
| `content-width-toggle` | Regulowana szerokość treści | "Szerokość kontentu", "narrow/wide toggle" |
| `resizable-panels` | Panele z regulowanym rozmiarem | "Split pane", "regulowane kolumny" |
| `react-skeleton-loaders` | Skeleton loadery per komponent | "Loading state", "skeleton" |
| `toast-notifications` | System powiadomień toast | "Notyfikacje", "toast", "komunikaty" |
| `mobile-responsive-patterns` | Wzorce responsywności | "Responsywność", "mobile", "overflow" |

## 3. Dane i integracje

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `react-query-hooks` | TanStack Query — fetching, mutacje, cache | "Data fetching", "React Query", "pobieranie danych" |
| `excel-import-export` | Import/eksport Excel (xlsx-js-style) | "Excel", "import pliku", "eksport do xlsx" |
| `cloudinary-upload` | Upload plików na Cloudinary | "Upload obrazów", "drag & drop", "Cloudinary" |
| `airtable-service` | Serwis TypeScript do Airtable API | "Airtable", "backend Airtable" |
| `i18next-pl` | Tłumaczenia polskie w React | "Tłumaczenia", "i18n", "polski język" |

## 4. Auth i bezpieczeństwo

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `supabase-auth-rls` | Auth + Row Level Security w Supabase | "Autoryzacja", "RLS", "kto widzi jakie dane" |
| `protected-routes-react` | Chronione ścieżki z AuthContext | "Chronione strony", "ProtectedRoute", "login guard" |
| `credentials-vault` | Bezpieczne przechowywanie kluczy API | "Zapisz klucze", "credentials", "API key" |
| `supabase-vault-keys` | Klucze w Supabase Vault | "Vault", "przechowywanie sekretów w DB" |

## 5. Baza danych (Supabase)

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `supabase-data-map` | Mapa tabel, relacji, RLS policies | "Schemat bazy", "data map", "jakie tabele mam" |
| `supabase-project-migration` | Migracja między projektami Supabase | "Przenieś bazę", "wydziel projekt" |
| `supabase-web-locks-fix` | Fix zawieszania na Web Locks API | "Spinner ładowania", "getSession() wisi" |

## 6. Deploy i DevOps

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `vercel-deploy` | Deploy na Vercel (routing SPA, env vars) | "Wdróż", "deploy", "404 po deployu" |
| `github-init` | Nowe repo GitHub + push | "Stwórz repo", "GitHub", "pierwszy push" |
| `nextjs-build-verify` | TypeScript + lint + build check | "Sprawdź build", "czy się buduje" |
| `vite-code-splitting` | Optymalizacja bundli Vite | "Bundle size", "chunk splitting" |
| `vercel-supabase-debugger` | Debug problemów Vercel+Supabase | "500 error", "nie działa po deployu" |

## 7. Jakość kodu i review

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `stack-code-review` | Review kodu pod standardy stacku | "Code review", "sprawdź kod", "przejrzyj" |
| `vercel-react-best-practices` | 45 reguł React/Next.js od Vercel | "Best practices", "optymalizacja React" |
| `path-scoped-rules` | Reguły per folder (.claude/rules/) | "Standardy kodowania", "dodaj reguły" |
| `agent-hierarchy` | Role agentów (Architect/Frontend/Backend/DevOps/QA) | "Review jako architect", "sprawdź backend" |
| `ux-flow-analyzer` | Audyt UX — 12 heurystyk | "Analiza UX", "audit nawigacji" |
| `web-design-guidelines` | Compliance z Web Interface Guidelines | "Sprawdź UI", "accessibility audit" |

## 8. AI, voice i generowanie obrazów

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `image-generator` | Generowanie obrazów AI (5-komponentowa formuła, 7 trybów, presety) | "Wygeneruj obraz", "hero image", "thumbnail", "grafika", "zdjęcie produktu" |
| `elevenlabs-conversation` | Integracja voice chat z ElevenLabs | "Voice chat", "rozmowy głosowe" |
| `elevenlabs-conversational-ai` | Zarządzanie agentami ElevenLabs (KB, RAG, config) | "Upload KB", "RAG nie działa", "konfiguracja bota" |
| `ai-models-reference` | Porównanie modeli AI z cenami | "Który model", "porównaj ceny", "GPT vs Claude" |

## 9. Workflow i automatyzacja

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `ai-crew` | Pipeline 6-8 ról (Designer→Coder→Reviewer) | "Crew", "złożone zadanie", "4+ plików" |
| `codex-delegation` | Delegowanie do GPT Codex | "Zlec Codexowi", "deleguj do GPT" |
| `dual-agent-review` | Claude + Codex niezależny review | "Dual review", "druga opinia" |
| `cross-model-review` | Codex + Qwen review GOTOWEGO kodu/planu (post) | "Recenzja", "review przed merge", "co myślą inne modele" |
| `adwokat-diabla` | Qwen przesłuchuje plan PRZED kodowaniem (--lateral) lub drąży root cause incydentu (--root-cause / 5 Why) | "Adwokat diabła", "przesłuchaj plan", "5 najtrudniejszych pytań", "5 why", "dlaczego padł", "root cause" |
| `workflow-adaptation` | Adaptacja N8N/Make.com do kodu | "Przepisz workflow", "adaptuj automatyzację" |
| `marketing-strategy-methodology` | Strategia marketingowa 7-fazowa | "Strategia marketingowa", "plan contentowy" |

## 10. Zarządzanie projektami

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `project-master-manifest` | Manifest projektu (project-meta.json) | "Aktualizuj manifest", "stan projektu" |
| `project-supervisor` | Monitoring deployów i health check | "Status projektów", "co się zepsuło" |
| `project-status` | Szybki przegląd projektu | "Status", "gdzie jestem" |
| `cross-project-gateway` | Gateway cross-project z HMAC | "Komunikacja między projektami" |
| `cross-project-onboarder` | Onboarding projektu do ekosystemu | "Podłącz nowy projekt" |
| `ecosystem-api` | Wzorce API cross-project | "Dodaj API", "typed SDK" |

## 11. Sesja i kontekst

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `context-handoff` | Zapis kontekstu na koniec sesji | "Handoff", "zapisz stan", "kontynuuj później" |
| `resume-work` | Wznowienie pracy z poprzedniej sesji | "Wznów", "kontynuuj", "gdzie skończyliśmy" |
| `session-hooks` | Hooki: auto-kontekst, pre-commit, session save | "Skonfiguruj hooki", "pamiętaj kontekst" |
| `demo-version` | Wersja demo/prezentacyjna aplikacji | "Wersja demo", "przygotuj prezentację" |
| `app-help-generator` | Sekcja pomocy użytkownika | "Dodaj pomoc do aplikacji", "help section" |

## 12. Meta (zarządzanie skillami)

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `create-skill` | Tworzenie nowych skilli + auto-wykrywanie | "Stwórz skill", "nowy skill" |
| `find-skills` | Wyszukiwanie i instalacja skilli | "Czy jest skill do X" |
| `skill-navigator` | Ten katalog — mapa wszystkich skilli | "Lista skilli", "workflow" |

## 13. Marketing i strategia

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `product-marketing-context` | 8 plików kontekstowych per projekt SaaS (FUNDAMENT) | "Kontekst marketingowy", "brand voice", "nowy projekt SaaS" |
| `marketing-strategy-methodology` | 7-fazowa strategia marketingowa | "Strategia marketingowa", "plan marketingu" |
| `marketing-psychology` | 70+ technik perswazji (social proof, scarcity...) | "Psychologia marketingu", "techniki perswazji" |
| `marketing-ideas` | 139+ taktyk SaaS w 12 kategoriach | "Pomysły na marketing", "growth hacks" |
| `growth-lead` | Senior growth advisor, AARRR, OKR, quarterly planning | "Strategia wzrostu", "co robić dalej", "priorytety" |
| `pricing-strategy` | Ustalanie cen metodą Minimalist Entrepreneur | "Jaka cena", "cennik", "pricing" |
| `validate-idea` | Walidacja pomysłu biznesowego | "Walidacja pomysłu", "czy warto budować" |

## 14. SEO i analityka

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `seo` | Kompleksowy audyt SEO (technical + content + on-page) | "Audyt SEO", "optymalizacja strony" |
| `schema-markup` | JSON-LD structured data per typ strony | "Rich snippets", "schema", "structured data" |
| `programmatic-seo` | SEO at scale — template pages per keyword | "Strony [usługa] + [miasto]", "SEO programatyczne" |
| `internal-linker` | Audyt linków wewnętrznych, topic clusters | "Linki wewnętrzne", "orphan pages" |
| `analytics-tracking` | GA4, GTM, event tracking, UTM | "Dodaj analitykę", "Google Analytics", "tracking" |

## 15. Content i copywriting

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `content` | Pipeline contentowy — artykuły SEO, briefy, kalendarze | "Napisz artykuł", "blog post", "brief" |
| `content-strategy` | Topic clusters, content calendar, gap analysis | "Strategia contentu", "plan treści" |
| `copywriting` | Copy SaaS: homepage, landing, pricing (PAS, AIDA, BAB) | "Napisz copy", "landing page tekst", "CTA" |
| `content-repurpose` | 1 materiał → wiele formatów (waterfall) | "Przeróbka treści", "repurpose", "z artykułu na posty" |
| `youtube-scripts` | Skrypty video: hook, 3-aktowy model, retention | "Skrypt na YouTube", "video script" |
| `reporter-pipeline` | 4-fazowy pipeline raportów marketingowych | "Raport marketingowy", "pipeline raportu" |

## 16. Sprzedaż i outreach

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `sales-context` | Fundament sprzedaży: ICP, value prop, objections | "Kontekst sprzedażowy", "ICP", "value proposition" |
| `cold-email` | Cold outreach: sekwencje, personalizacja, follow-up | "Cold email", "outreach", "prospecting" |
| `discovery-call` | SPIN/MEDDIC/Gap Selling — rozmowy discovery | "Discovery call", "rozmowa z klientem" |
| `email-sequence` | Onboarding, nurture, win-back, trial expiring | "Sekwencja emailowa", "onboarding emails" |
| `lead-generator` | Pipeline leadów — scraping, kwalifikacja | "Generowanie leadów", "prospecting" |
| `product-value-extractor` | Ekstrakcja wartości SaaS → komunikacja sprzedażowa | "Wartość produktu", "komunikacja sprzedażowa" |

## 17. Reklamy i social media

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `paid-ads` | Google/Meta/LinkedIn Ads — copy, targeting, ROAS | "Kampania reklamowa", "Google Ads", "Facebook Ads" |
| `ads-auditor` | Audyt kampanii reklamowych (100+ punktów) | "Audyt reklam", "dlaczego reklamy nie działają" |
| `social-content` | LinkedIn, X, Instagram — formaty, hooks, harmonogramy | "Post na LinkedIn", "social media plan" |
| `page-cro` | Optymalizacja konwersji: CTA, ATF, social proof | "Popraw konwersję", "CRO", "landing page nie konwertuje" |
| `free-tool-strategy` | Kalkulatory/generatory jako lead magnets | "Darmowe narzędzie", "kalkulator", "lead magnet" |
| `competitor-alternatives` | Strony "X vs Y", "Alternative to X" | "Strona porównawcza", "alternatywa dla X" |

## 18. Programowanie (language-specific)

| Skill | Co robi | Kiedy użyć |
|-------|---------|------------|
| `vercel:react-best-practices` | React — wzorce, hooki, wydajność (plugin Vercel) | "React", "komponenty", "hooki" |
| `vercel:nextjs` | Next.js App Router, RSC, streaming (plugin Vercel) | "Next.js", "app router" |

Dla TypeScript / JavaScript / Python nie ma dedykowanego skilla (pakiet Jeffallan zarchiwizowany 10.09.2026) — odpowiadaj bez skilla.

---

## Pominięte kategorie (dostępne, ale rzadziej używane)

- **Google Workspace (gws-*)** — 25 skilli do Gmail, Calendar, Docs, Sheets, Drive, Chat
- **Recipes (recipe-*)** — 30 przepisów cross-service (np. "zapisz załączniki z Gmail na Drive")
- **Personas (persona-*)** — 10 ról biznesowych (PM, HR, Sales, IT Admin)
- **Ralph TUI** — 3 skille do konwersji PRD na zadania (ralph-tui-prd, create-beads, create-json)

Powiedz "pokaż skille Google Workspace" lub "pokaż recipes" żeby zobaczyć szczegóły.

---

# Ścieżki workflow

## Scenariusz 1: Nowy projekt SaaS od zera

```
FAZA 1 — Scaffold (5 min)
├── vite-react-tailwind4          → Projekt + Tailwind v4 + aliasy
├── unified-design-system         → 6 motywów, ThemeContext, UserMenu
└── i18next-pl                    → Polski język od startu

FAZA 2 — Auth i baza (15 min)
├── credentials-vault             → Zapisz klucze Supabase
├── supabase-auth-rls             → Auth + RLS policies
├── protected-routes-react        → Chronione ścieżki
└── admin-panel-scaffold          → Panel admina z sidebar

FAZA 3 — Jakość (5 min)
├── path-scoped-rules             → Reguły per folder
├── session-hooks                 → Hooki sesji + pre-commit
└── github-init                   → Repo GitHub + push

FAZA 4 — Deploy (5 min)
├── vercel-deploy                 → Deploy na Vercel
└── nextjs-build-verify           → Sprawdź build
```

**Użycie:** Powiedz *"Stwórz nowy projekt SaaS"* → agent przejdzie przez fazy 1-4.

## Scenariusz 2: Nowy feature w istniejącym projekcie

```
ANALIZA
├── agent-hierarchy (Architect)   → Oceń wpływ, zaplanuj
├── supabase-data-map             → Sprawdź schemat bazy (jeśli potrzeba)
└── react-query-hooks             → Wzorce data fetching

IMPLEMENTACJA
├── shadcn-manual                 → Komponenty UI
├── react-skeleton-loaders        → Loading states
├── toast-notifications           → Feedback użytkownika
└── [specyficzny skill]           → np. excel-import-export, cloudinary-upload

REVIEW
├── stack-code-review             → Review kodu
├── nextjs-build-verify           → Build check
└── claude-in-chrome              → Test w przeglądarce
```

## Scenariusz 3: Optymalizacja voice bota

```
DIAGNOSTYKA
├── elevenlabs-conversational-ai  → Sprawdź config agenta, KB, RAG
├── supabase-data-map             → Czy baza wiedzy jest kompletna?
└── ai-models-reference           → Czy model jest optymalny?

OPTYMALIZACJA
├── AutoLoop (Domena B)           → Automatyczna optymalizacja promptu
│   └── evaluate.sh               → Testy konwersacyjne
│   └── runner.sh                 → Pętla: zmień prompt → zmierz → zachowaj/cofnij
└── elevenlabs-conversation       → Integracja zmian w aplikacji

WERYFIKACJA
├── claude-in-chrome              → Test rozmowy w przeglądarce
└── dual-agent-review             → Niezależna ocena zmian
```

## Scenariusz 4: Audyt istniejącego projektu

```
├── project-status                → Szybki przegląd stanu
├── supabase-data-map             → Mapa bazy danych
├── ux-flow-analyzer              → Audit UX (12 heurystyk)
├── stack-code-review             → Review kodu pod standardy
├── vercel-react-best-practices   → 45 reguł wydajności
└── path-scoped-rules             → Wdróż reguły jeśli brakuje
```

## Scenariusz 5: Przygotowanie demo/prezentacji

```
├── demo-version                  → Wersja demo z seed data
├── brand-elements                → Favicon, footer, branding
├── app-help-generator            → Sekcja pomocy
├── vercel-deploy                 → Deploy preview URL
└── claude-in-chrome              → Nagranie/test flow
```

## Scenariusz 6: Debug "coś nie działa"

```
TRIAGE (od ogółu do szczegółu)
├── project-status                → Co się zmieniło ostatnio?
├── vercel-supabase-debugger      → 500, CORS, auth, timeout
├── supabase-web-locks-fix        → Spinner ładowania / freeze
├── react-flicker-fix             → Miganie / re-render loop
└── claude-in-chrome              → Sprawdź w przeglądarce
```

---

# Instrukcja dla CLAUDE.md

Wklej poniższy blok do `CLAUDE.md` projektu — agent będzie automatycznie sugerował skille:

```markdown
## Sugestie skilli

Przy zadaniach sprawdzaj czy pasujący skill istnieje:

### Nowy komponent UI → `shadcn-manual` + `react-skeleton-loaders`
### Nowy endpoint API → `supabase-auth-rls` (RLS check) + `react-query-hooks` (frontend hook)
### Deploy → `vercel-deploy` + `nextjs-build-verify`
### Bug → `vercel-supabase-debugger` lub `react-flicker-fix`
### Code review → `stack-code-review` + `agent-hierarchy`
### Nowa tabela Supabase → `supabase-auth-rls` (RLS!) + `supabase-data-map`
### Upload plików → `cloudinary-upload`
### Excel → `excel-import-export`
### Voice bot → `elevenlabs-conversation` + `elevenlabs-conversational-ai`
### Strategia → `marketing-strategy-methodology`
### Generowanie obrazów → `image-generator`
### Złożone zadanie (4+ pliki) → `ai-crew`
### Proste zlecenie → `codex-delegation`
### Plan przed kodowaniem (krytyczna decyzja) → `adwokat-diabla --lateral`
### Post-incident analysis (padł deploy/cron) → `adwokat-diabla --root-cause`
### Koniec sesji → `context-handoff`
### Start sesji → `resume-work`
```

---

# Inne scenariusze

## Scenariusz 7: Migracja / refaktor bazy danych

```
├── supabase-data-map             → Mapa obecnego schematu
├── supabase-project-migration    → Plan migracji (jeśli nowy projekt Supabase)
├── supabase-auth-rls             → Przepisz RLS policies
├── stack-code-review             → Review nowych queries
└── vercel-supabase-debugger      → Jeśli po migracji coś nie działa
```

## Scenariusz 8: Strategia marketingowa / content (FULL PIPELINE)

```
FUNDAMENT
├── product-marketing-context     → 8 plików kontekstowych (brand voice, ICP, keywords)
├── sales-context                 → ICP, value prop, objections, battle cards
└── marketing-strategy-methodology → 7-fazowa strategia

CONTENT PIPELINE
├── content-strategy              → Topic clusters, calendar, gap analysis
├── content (/content write)      → Artykuły SEO z quality gates
├── seo (/seo page)               → Audyt SEO per artykuł
├── copywriting                   → Landing page, pricing, CTA copy
└── content-repurpose             → 1 artykuł → social + newsletter + thread

DYSTRYBUCJA
├── social-content                → Posty LinkedIn, X, Instagram
├── email-sequence                → Nurture, onboarding, win-back
├── paid-ads                      → Google/Meta/LinkedIn Ads
└── analytics-tracking            → Mierzenie wyników (GA4, GTM)

OPTYMALIZACJA
├── page-cro                      → CRO: CTA, social proof, formularze
├── growth-lead                   → Priorytety, OKR, quarterly review
└── competitor-alternatives       → Strony "X vs Y", "Alternative to X"
```

## Scenariusz 9: Import/eksport danych

```
├── excel-import-export           → Parsowanie Excel ↔ JSON
├── cloudinary-upload             → Upload mediów (obrazy, PDF)
├── airtable-service              → Integracja z Airtable jako źródło
├── react-query-hooks             → Hooki do pobierania danych
└── react-skeleton-loaders        → Loading states podczas importu
```

## Scenariusz 10: Komunikacja zespołowa (Google Workspace)

```
├── gws-gmail-triage              → Przegląd skrzynki
├── gws-calendar-agenda           → Dzisiejsze spotkania
├── gws-workflow-standup-report   → Raport poranny (spotkania + taski)
├── gws-chat-send                 → Wiadomość do zespołu
├── recipe-send-team-announcement → Ogłoszenie mail + Chat
└── gws-workflow-meeting-prep     → Przygotowanie do spotkania
```

## Scenariusz 11: Onboarding nowego projektu do ekosystemu

```
├── cross-project-onboarder       → Automatyczny onboarding
├── cross-project-gateway         → Gateway z HMAC auth
├── ecosystem-api                 → Wzorce API cross-project
├── project-master-manifest       → Manifest projektu
└── credentials-vault             → Klucze dostępowe
```

## Scenariusz 12: Planowanie i orkiestracja zadań (Ralph TUI / GSD)

```
OPCJA A — Ralph TUI
├── ralph-tui-prd                 → PRD z user stories
├── ralph-tui-create-beads        → Konwersja PRD → beads
└── ralph-tui-create-json         → Konwersja PRD → prd.json

OPCJA B — GSD (Get Stuff Done)
├── /gsd:new-project              → Inicjalizacja z PROJECT.md
├── /gsd:plan-phase               → Plan fazy z PLAN.md
├── /gsd:execute-phase            → Wykonanie z atomic commits
└── /gsd:verify-work              → UAT konwersacyjny
```

## Scenariusz 13: Adaptacja istniejącego workflow (N8N / Make.com)

```
├── workflow-adaptation           → Analiza źródłowego workflow
├── ecosystem-api                 → Wzorce endpointów docelowych
├── supabase-auth-rls             → Jeśli workflow dotyka bazy
├── vercel-deploy                 → Deploy nowej implementacji
└── dual-agent-review             → Porównanie oryginał vs implementacja
```

## Scenariusz 14: Tworzenie nowego skilla

```
├── create-skill                  → Przewodnik + auto-wykrywanie kandydatów
├── skill-navigator               → Sprawdź czy podobny skill istnieje
├── find-skills                   → Szukaj w marketplace
└── AutoLoop (Domena A)           → Optymalizacja triggera i jakości
```

## Scenariusz 15: Design-first development (Stitch → kod)

Gdy chcesz zacząć od designu, a nie od kodu. Google Stitch generuje UI, Claude Code implementuje.

```
├── stitch-claude-workflow        → Bridge skill — orkiestruje cały pipeline
│   ├── Faza 1: Design
│   │   ├── stitch-design         → Wzbogacanie promptów, generowanie screenów (MCP)
│   │   └── design-md             → Generowanie .stitch/DESIGN.md z projektu Stitch
│   ├── Faza 2: Konwersja
│   │   ├── react-components      → HTML→React (bazowa konwersja Vite)
│   │   └── shadcn-ui             → Mapowanie na shadcn/ui komponenty
│   ├── Faza 3: Integracja
│   │   ├── unified-design-system → Mapowanie kolorów Stitch na motywy ThemeContext
│   │   ├── frontend-design       → Jakość i kreatywność implementacji
│   │   └── mobile-responsive-patterns → Responsywność
│   └── Opcjonalnie
│       └── stitch-loop           → Multi-page autonomiczna generacja (baton system)
```

**Kiedy użyć:**
- "Zaprojektuj landing page" → `stitch-claude-workflow` Workflow A
- "Redesign dashboardu" → `stitch-claude-workflow` Workflow C
- "Wygeneruj 5 stron" → `stitch-loop` + `stitch-claude-workflow`

**Wymagania:** Konto Google + `npx @_davideast/stitch-mcp init` (jednorazowo)

## Scenariusz 16: Generowanie obrazów AI (marketing, content, branding)

Generowanie grafik z zaawansowanym prompt engineeringiem — od pojedynczych obrazów po batch wariantów.

```
SINGLE IMAGE (1 min)
├── image-generator               → 5-komponentowy prompt + tryb domenowy
│   ├── Tryby: Marketing | Product | Content | Social | Brand | Editorial | SaaS
│   └── Generacja via AI Gateway + Gemini 3.1 Flash Image Preview
└── Persystencja: Vercel Blob (trwałe URL)

BATCH / A-B TESTING (5 min)
├── image-generator               → Bazowy prompt
├── Warianty: Style / Composition / Lighting rotation
└── Porównanie wyników → wybór najlepszego

CONTENT PIPELINE (integracja z innymi skillami)
├── marketing-strategy-methodology → Brief kampanii → visual guidelines
├── image-generator               → Hero images, thumbnails, social graphics
├── stitch-claude-workflow         → Design UI (jeśli potrzeba)
├── brand-elements                 → Favicon, footer z wygenerowanymi elementami
└── vercel-deploy                  → Publikacja

BRANDING (presety per klient)
├── image-generator               → Preset: tech-saas / luxury-brand / editorial
├── Rozszerzenie: własny preset z kolorami i stylem klienta
└── Batch: warianty z presetem → spójna identyfikacja wizualna
```

**Kiedy użyć:**
- "Wygeneruj hero image" → `image-generator` (tryb Marketing)
- "Zrób thumbnail do artykułu" → `image-generator` (tryb Content)
- "Grafiki social media" → `image-generator` (tryb Social, aspect ratio 1:1 lub 9:16)
- "Zdjęcie produktu" → `image-generator` (tryb Product)
- "Logo dla projektu" → `image-generator` (tryb Brand)
- "Batch 5 wariantów" → `image-generator` (batch generation)

**Wymagania:** AI Gateway + OIDC (vercel link → vercel env pull), Vercel Blob

---

## Scenariusz 17: Content Marketing Pipeline (Workflow A v2)

Zamknięta pętla content z 5 approval gates i Quality Gate J (127+ zakazanych słów, Flesch PL 70-80).

```
PIPELINE (end-to-end)
├── marketing-strategy-methodology → Strategia + keywords
├── content (/content write)       → Artykuł PL z answer-first, citation capsules
│   └── Quality Gate J (auto)      → 127+ zakazanych słów, Flesch PL, naturalność
├── [GATE 3: MANUAL]               → Klient zatwierdza artykuł
├── seo (/seo page)                → Audyt SEO + auto-fix
├── image-generator                → Hero image + social cards
└── Publikacja: WordPress + Social Media (Workflow I)
```

**Kiedy użyć:** "Zamknięta pętla content", "pipeline artykułów", "content od A do Z"
**Wymagane:** skill content + seo + image-generator + Workflow A v2

---

## Scenariusz 18: Recurring Revenue (Workflow G v2)

Model recurring revenue z per-org promptami i Prompt Studio UI.

```
ONBOARDING KLIENTA
├── project-scaffolder              → Nowy projekt klienta
├── credentials-vault               → Klucze Supabase/Stripe
├── Per-org prompts z DB            → Klient dostosowuje ton/styl w UI
└── Stripe subscription             → Miesięczna subskrypcja

MIESIĘCZNA PĘTLA
├── content (/content calendar)     → Kalendarz na miesiąc
├── content (/content write × N)    → Generacja artykułów z per-org promptami
├── Quality Gate J (auto)           → Walidacja jakości
├── seo (/seo page × N)            → Audyt SEO każdego artykułu
└── Raport miesięczny dla klienta
```

**Kiedy użyć:** "Recurring revenue", "model subskrypcyjny content", "per-org prompty"
**Wymagane:** skill content + seo + project-scaffolder + Stripe

---

## Scenariusz 19: Social Publishing Pipeline (Workflow I)

Publikacja na 6 platformach z kalendarzem DnD i social previews.

```
PRZYGOTOWANIE
├── content (artykuł gotowy)        → Źródło treści
├── Social adaptation               → Posty per platforma (FB, IG, LI, X, TT)
├── Social Previews                  → Podgląd na 6 platformach
└── [APPROVAL GATE]                 → Klient zatwierdza posty

PUBLIKACJA
├── Kalendarz z ghost slots          → Harmonogram: wt 10:00 LinkedIn, czw 14:00 FB
├── kanban-dnd-board                 → Drag & drop zarządzanie postami
├── Postiz API / natywne API         → Automatyczna publikacja
└── Goals Dashboard                  → "5 postów/tydzień" z progress bar
```

**Kiedy użyć:** "Social publishing", "publikacja na social media", "kalendarz postów"
**Wymagane:** skill content + kanban-dnd-board + postiz-account-setup

---

# Statystyki ekosystemu

| Kategoria | Liczba skilli |
|-----------|:------------:|
| Tworzenie projektów | 5 |
| UI i komponenty | 7 |
| Dane i integracje | 5 |
| Auth i bezpieczeństwo | 4 |
| Baza danych | 3 |
| Deploy i DevOps | 5 |
| Jakość i review | 6 |
| AI, voice i generowanie obrazów | 4 |
| Workflow i automatyzacja | 5 |
| Zarządzanie projektami | 6 |
| Sesja i kontekst | 5 |
| Meta | 3 |
| **Marketing i strategia** | **7** |
| **SEO i analityka** | **5** |
| **Content i copywriting** | **6** |
| **Sprzedaż i outreach** | **6** |
| **Reklamy i social media** | **6** |
| Programowanie (language-specific) | 5+ |
| Google Workspace | ~25 |
| Recipes | ~30 |
| Personas | ~10 |
| Design i UI generation (Stitch) | 6 |
| Inne (Ralph TUI, Postiz, itp.) | ~8 |
| **ŁĄCZNIE** | **~277** |
| **RAZEM** | **~170** |
