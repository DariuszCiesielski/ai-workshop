---
name: cross-project-onboarder
description: Automatyczny onboarding nowego projektu do ekosystemu Project Master — analiza stacku, generowanie instrukcji gateway, opcjonalne wdrożenie i weryfikacja. Orkiestruje cały proces podłączania projektu do cross-project pipeline.
triggers:
  - "podłącz projekt do ekosystemu"
  - "onboarduj projekt"
  - "dodaj nowe narzędzie do orkiestratora"
  - "wygeneruj instrukcję cross-project"
  - "przygotuj gateway"
  - "zintegruj z Project Master"
  - "cross-project onboarding"
  - "podłącz do pipeline"
  - "onboarder"
  - "onboarding"
  - "podłącz projekt"
  - "nowy projekt w ekosystemie"
---

# Cross-Project Onboarder

Meta-skill orkiestrujący pełny proces podłączania nowego projektu do ekosystemu Project Master. Automatyzuje: analiza → instrukcja → wdrożenie → weryfikacja.

## Kiedy używać

- Użytkownik chce podłączyć nowy projekt do orkiestratora Project Master
- Nowy projekt ma udostępnić akcje dla cross-project pipeline'ów
- Trzeba wygenerować gateway (Supabase EF lub Next.js API route) z HMAC auth
- Użytkownik mówi "podłącz X do ekosystemu", "onboarduj X", "przygotuj gateway dla X"

## Zależności

- Template'y kodu gateway → `references/gateway-templates.md` (w tym skillu)
- Project Master z Milestone 4 (tabele `project_registry`, `cross_project_jobs`, `pipeline_runs`)
- Supabase ref PM: `nbxsyfkpssjfsxnuinix`
- Wzorcowe instrukcje: `~/projekty/Project Master/project-master/docs/cross-project-instructions/*.md`

## Konwencje

### Lokalizacje plików
- **Pełna instrukcja**: `~/projekty/Project Master/project-master/docs/cross-project-instructions/NN-<slug>.md`
- **Handoff w target projekcie**: `~/projekty/<Projekt>/.ai/handoffs/YYYY-MM-DD-HHMM-cross-project-gateway-instrukcja.md`
- **Numeracja instrukcji**: Sprawdź istniejące pliki i użyj kolejnego numeru (01, 02, 03...)

### Kontrakt Gateway v1 (zamrożony)
```
POST /functions/v1/cross-project-gateway  (Supabase EF)
POST /api/cross-project/gateway           (Next.js)

Headers:
  x-signature: HMAC-SHA256(timestamp.nonce.body, secret)
  x-timestamp: unix seconds
  x-nonce: random UUID

Body:
  { action, job_id, correlation_id?, payload }

Response sync:  { success: true, data: {...} }
Response async: { success: true, async_task_id: "uuid", estimated_seconds: N }
Response error: { success: false, error: "msg", retryable: true|false }
```

### Taksonomia błędów
| HTTP | Znaczenie | Retry? |
|------|-----------|--------|
| 2xx + `retryable: true` | Tymczasowy błąd | Tak |
| 2xx + `retryable: false` | Błąd logiki | Nie |
| 429 | Rate limited | Tak |
| 4xx | Błąd klienta | Nie |
| 5xx | Błąd serwera | Tak |
| Timeout / network error | Nieosiągalny | Tak |

---

## Proces (5 kroków)

### Krok 1: Analiza projektu docelowego

Przejdź do katalogu projektu i przeanalizuj:

```
Checklist analizy:
[ ] package.json → framework (Next.js / Vite+React / inne), wersja
[ ] supabase/ → obecność folderu, ref z .temp/project-ref
[ ] .env.local → SUPABASE_URL, SERVICE_ROLE_KEY, istniejące klucze API
[ ] supabase/functions/ → istniejące Edge Functions
[ ] src/app/api/ lub api/ → istniejące API routes, wzorce auth
[ ] schemat DB → tabele (migracje SQL), szczególnie tabele taskowe
[ ] logika biznesowa → co projekt "umie" (grep: eksport funkcji, serwisy)
```

**Zbierz dane:**
- `project_name`: Nazwa wyświetlana
- `project_slug`: ID w rejestrze (kebab-case)
- `project_path`: Ścieżka lokalna
- `stack`: Next.js / Vite+React / inne
- `supabase_ref`: Ref Supabase (jeśli ma)
- `gateway_type`: `supabase-ef` (preferowany) lub `rest-api` (Next.js)
- `existing_tables`: Lista tabel które mogą być wykorzystane
- `existing_ef`: Lista istniejących Edge Functions
- `existing_api`: Lista istniejących API routes
- `potential_actions`: Co projekt mógłby udostępnić (na podstawie analizy logiki)

**Reguła wyboru gateway_type:**
- Projekt ma Supabase → `supabase-ef` (preferowany — izolacja, osobny deploy)
- Projekt to Next.js bez Supabase → `rest-api` (API route w Next.js)
- Projekt to Vite+React → `supabase-ef` (dodaj EF do Supabase)

### Krok 2: Interaktywne doprecyzowanie

Przedstaw użytkownikowi wyniki analizy i zadaj pytania:

```
Analiza projektu [NAZWA]:
- Stack: [framework] + [DB]
- Supabase ref: [ref]
- Gateway: [supabase-ef / rest-api]
- Potencjalne akcje: [lista z analizy]

Pytania:
1. Które akcje chcesz udostępnić? [lista z checkboxami]
2. Dla każdej akcji: sync (wynik od razu) czy async (długotrwała)?
3. Czy projekt ma być też SOURCE (triggerowanie pipeline'ów z UI)?
4. ID w rejestrze: [propozycja slug] — OK?
```

**Dla każdej akcji zbierz:**
- `action_name`: Nazwa akcji (kebab-case)
- `description`: Co robi
- `execution_type`: `sync` lub `async`
- `avg_duration_s`: Średni czas wykonania
- `payload_params`: Parametry w payload

**Jeśli są akcje async, sprawdź:**
- Czy istnieje tabela taskowa? → Użyj istniejącej
- Brak tabeli? → Wygeneruj migrację SQL
- Wymagane kolumny: `id`, `type`, `params/payload`, `status`, `result`, `error_message`, `source_project`, `source_job_id`, `created_at`

### Krok 3: Generowanie instrukcji

Wygeneruj 2 pliki na podstawie template'ów:

**A) Pełna instrukcja** — użyj `templates/instruction-template.md`
- Zapisz: `~/projekty/Project Master/project-master/docs/cross-project-instructions/NN-<slug>.md`
- Numeracja: Sprawdź istniejące pliki, użyj kolejnego numeru

**B) Handoff** — użyj `templates/handoff-template.md`
- Zapisz: `~/projekty/<Projekt>/.ai/handoffs/YYYY-MM-DD-HHMM-cross-project-gateway-instrukcja.md`
- Timestamp: Aktualny czas

**Zmienne wspólne (oba template'y):**
```
{{PROJECT_NAME}}         — Nazwa wyświetlana
{{PROJECT_SLUG}}         — ID w rejestrze (kebab-case)
{{PROJECT_PATH}}         — Ścieżka lokalna (~/projekty/...)
{{SUPABASE_REF}}         — Ref Supabase
{{GATEWAY_TYPE}}         — supabase-ef | rest-api
{{GATEWAY_URL}}          — URL gateway (https://REF.supabase.co lub https://app.vercel.app)
{{AUTH_TYPE}}             — hmac | api-key
{{AUTH_SECRET_NAME}}     — Nazwa zmiennej (np. PROJECT_SLUG_HMAC_SECRET)
{{HMAC_SECRET}}          — Wygenerowany klucz (openssl rand -hex 32)
{{GATEWAY_CODE}}         — Pełny kod gateway (z skill cross-project-gateway)
{{MIGRATION_SQL}}        — Migracja SQL (jeśli potrzebna)
{{ACTIONS_JSON}}         — JSON array z akcjami dla project_registry
{{ACTIONS_SWITCH}}       — Switch cases w gateway (per akcja)
{{REGISTRY_NUMBER}}      — Numer instrukcji (NN)
{{DATE}}                 — Data YYYY-MM-DD
{{DATETIME}}             — Data+czas YYYY-MM-DD-HHMM
{{INSTRUCTION_PATH}}     — Ścieżka do pełnej instrukcji
{{CHECKLIST}}            — Lista zadań do wykonania
```

**Zmienne warunkowe (tylko handoff-template.md):**
```
{{PROJECT_ROLE_LABEL}}   — "Gateway" (target only) | "Integration" (target+source)
{{GOAL_DESCRIPTION}}     — 1-2 zdania: co i dlaczego (wygeneruj z kontekstu)
{{WHY_DESCRIPTION}}      — Kontekst biznesowy: dlaczego ten projekt w ekosystemie
{{PART_LABEL}}           — "Część A:" (jeśli target+source) | "" (jeśli tylko target)
{{AUTH_TYPE_UPPER}}      — "HMAC" | "API key"
{{KEY_GENERATION_CMD}}   — "openssl rand -hex 32" (zawsze)
{{AUTH_VERIFICATION_DESC}} — "HMAC-SHA256 (headery: x-signature, x-timestamp, x-nonce)" | "x-api-key header"
{{AUTH_HEADERS}}         — "x-signature, x-timestamp, x-nonce (HMAC-SHA256)" | "x-api-key"
{{GATEWAY_LABEL}}        — "Edge Function cross-project-gateway/index.ts" | "API route /api/cross-project/gateway/route.ts"
{{GATEWAY_ENDPOINT}}     — "/functions/v1/cross-project-gateway" | "/api/cross-project/gateway"
{{ACTIONS_COUNT}}        — Liczba akcji (np. "4")
{{ACTIONS_SUFFIX}}       — Poprawna odmiana ("e" dla 2-4, "i" dla 5+)
{{ACTIONS_LIST}}         — Lista akcji z typem (sync/async), po jednej na linię z "  - "
{{PM_API_URL}}           — URL Project Master API (np. https://project-master-nine-omega.vercel.app)
{{STEP_GATEWAY}}         — Numer kroku gateway (3 lub 4, zależnie od migracji)
{{STEP_DEPLOY}}          — Numer kroku deploy
{{STEP_NOTIFY}}          — Numer kroku "poinformuj użytkownika"
```

**Bloki warunkowe (handoff-template.md):**
- `{{IF_TARGET}}...{{/IF_TARGET}}` — Sekcja TARGET (prawie zawsze obecna)
- `{{IF_SOURCE}}...{{/IF_SOURCE}}` — Sekcja SOURCE (tylko gdy projekt triggeruje pipeline'y)
- `{{IF_SUPABASE_EF}}...{{/IF_SUPABASE_EF}}` — Wariant Supabase Edge Function
- `{{IF_REST_API}}...{{/IF_REST_API}}` — Wariant Next.js API route
- `{{IF_MIGRATION}}...{{/IF_MIGRATION}}` — Migracja SQL (jeśli nowa tabela/kolumny)

### Krok 4: Opcjonalne wdrożenie

Zapytaj: "Chcesz żebym od razu wdrożył, czy tylko instrukcję?"

**Tryb "tylko instrukcja"** (domyślny):
- Wygeneruj pliki z kroków 3A i 3B
- Poinformuj użytkownika o lokalizacjach

**Tryb "pełne wdrożenie"**:
1. `openssl rand -hex 32` → klucz HMAC
2. Utwórz pliki gateway w projekcie docelowym:
   - Supabase EF: `supabase/functions/cross-project-gateway/index.ts`
   - Next.js: `src/app/api/cross-project/gateway/route.ts`
3. Utwórz migrację SQL (jeśli nowa tabela)
4. Ustaw secret:
   - Supabase: `supabase secrets set PM_HMAC_SECRET=<klucz> --project-ref <REF>`
   - Next.js: Dodaj do `.env.local`
5. Deploy:
   - Supabase: `supabase functions deploy cross-project-gateway --project-ref <REF>`
   - Next.js: Poinformuj o konieczności deploy (git push)
6. Dodaj secret do `.env.local` w Project Master:
   - `<SLUG>_HMAC_SECRET=<klucz>` lub `<SLUG>_API_KEY=<klucz>`
7. Wykonaj SQL INSERT do `project_registry` w Supabase PM (ref: `nbxsyfkpssjfsxnuinix`)

### Krok 5: Weryfikacja

**Test manualny:**
```bash
cd ~/projekty/Project\ Master/project-master
npm run orch:mock-gateway
```

**Lub SQL INSERT:**
```sql
INSERT INTO cross_project_jobs (source_project, target_project, target_action, payload, idempotency_key)
VALUES ('project-master', '{{PROJECT_SLUG}}', '{{FIRST_ACTION}}', '{"test": true}', 'onboard-test-001');
```

**Sprawdź:**
- Job accepted (status: accepted/dispatched)
- Gateway odpowiada poprawnie (sync: data, async: async_task_id)
- Brak błędów auth (401/403)

**Po weryfikacji:**
- Potwierdź sukces użytkownikowi
- Zaktualizuj handoff z wynikiem testu

---

## Polecane skille dla nowo onboardowanego projektu

Po podstawowym onboardingu — przed pierwszą fazą implementacji **nietrywialnej** — przypomnij użytkownikowi o tych skillach:

| Skill | Kiedy uruchomić | Wartość |
|---|---|---|
| `adwokat-diabla --lateral` | Przed pierwszą decyzją architektoniczną dotykającą >1 plik (struktura tabel, schemat queue, kontrakty API) | Drugi model (Qwen lokalnie) zadaje 5 najtrudniejszych pytań w różnych aspektach. 5-10 min rozmowy oszczędza 5-10h debugowania (case ClientA) |
| `adwokat-diabla --root-cause` | Po pierwszym incydencie produkcyjnym (padł deploy, regresja, dziwny błąd) | 5 Why drąży root cause strukturalny zamiast zatrzymywać się na symptomie |
| `cross-model-review` | Po napisaniu nietrywialnego kodu / planu | Codex + Qwen recenzują GOTOWY artefakt — komplementarne do `adwokat-diabla` (pre-implementation) |
| `processize` | Gdy planujesz workflow który będzie wymagał kodu | Najpierw manualny proces (papier+excel), potem automatyzacja — rzadkie zadania nie wymagają kodu |
| `careful` | Przed pierwszą destructive op (drop kolumny, rm -rf, force push) | Safety guardrails — ostatnia szansa na przemyślenie |

**Wskazówka onboardera:** dodaj tę listę do CLAUDE.md projektu w sekcji "Polecane skille przy starcie", żeby agent wiedział o tym przy każdej kolejnej sesji.

---

## Podwójna rola: TARGET + SOURCE

Jeśli projekt ma być też SOURCE (triggerowanie pipeline'ów):

### Dodatkowe elementy SOURCE:
1. **Konfiguracja env vars w projekcie:**
   ```
   PROJECT_MASTER_API_URL=https://nbxsyfkpssjfsxnuinix.supabase.co/functions/v1/cross-project-trigger
   PROJECT_MASTER_TRIGGER_SECRET=<klucz HMAC od PM>
   ```

2. **Moduł HMAC signing** (w projekcie source):
   ```typescript
   // src/lib/cross-project/hmac-signer.ts
   import { createHmac, randomUUID } from "node:crypto";

   export function signRequest(body: string, secret: string) {
     const timestamp = Math.floor(Date.now() / 1000).toString();
     const nonce = randomUUID();
     const message = `${timestamp}.${nonce}.${body}`;
     const signature = createHmac("sha256", secret).update(message).digest("hex");
     return { "x-signature": signature, "x-timestamp": timestamp, "x-nonce": nonce };
   }
   ```

3. **Komponent UI** (jeśli trigger z dashboardu):
   ```typescript
   // Przycisk "Uruchom pipeline X" → POST /api/cross-project/trigger-pipeline
   ```

4. **API route trigger** (server-side):
   ```typescript
   // POST /api/cross-project/trigger-pipeline
   // Auth: session (własny user)
   // Body: { pipeline, params }
   // → HMAC sign → POST do PROJECT_MASTER_API_URL
   ```

---

## Istniejące projekty w ekosystemie

| # | Projekt | ID | Gateway | Akcje |
|---|---------|-----|---------|-------|
| 01 | Specjalista SEO | `seo-specialist` | Supabase EF | check-rankings, get-recommendations, analyze-content-gap, generate-seo-report |
| 02 | Content Marketing Hub | `content-hub` | Supabase EF | generate-seo-article, generate-article, get-task-status |
| 03 | Marketing Hub | `marketing-hub` | Next.js API | create-task |

---

## Checklist (podsumowanie procesu)

```
Onboarding projektu [NAZWA]:
- [ ] Krok 0: Klasyfikacja typu projektu (PRODUKT / TOOLING / KLIENT)
- [ ] Krok 1: Analiza projektu (stack, DB, API, logika)
- [ ] Krok 2: Doprecyzowanie z użytkownikiem (akcje, sync/async, rola)
- [ ] Krok 3A: Pełna instrukcja → docs/cross-project-instructions/NN-slug.md
- [ ] Krok 3B: Handoff → .ai/handoffs/YYYY-MM-DD-HHMM-cross-project-gateway-instrukcja.md
- [ ] Krok 4: Wdrożenie (opcjonalne)
  - [ ] Klucz HMAC wygenerowany
  - [ ] Gateway wdrożony (EF/API route)
  - [ ] Migracja SQL (jeśli potrzebna)
  - [ ] Secret ustawiony (Supabase/env)
  - [ ] Secret w .env.local PM
  - [ ] INSERT do project_registry
- [ ] Krok 5: Weryfikacja (test job → sprawdzenie statusu)
- [ ] Krok 6: Generacja dokumentu produktu (PRD / Brief / Spec) — patrz sekcja niżej
- [ ] Krok 7: Wpis do `PRODUCTS.md` ekosystemu (`~/projekty/Project Master/.ai/ecosystem/PRODUCTS.md`)
```

---

## Krok 0: Klasyfikacja typu projektu (dodane 2026-05-22)

**Cel:** auto-detect typu projektu PRZED onboardingiem technicznym żeby wybrać odpowiedni dokument (PRD vs Brief vs Spec) i poziom integracji z ekosystemem.

### Auto-detection heurystyki

Sprawdź następujące źródła informacji:

1. **Lokalizacja w `~/projekty/`** — nazwa katalogu (np. "Hotel Demo" = nazwa klienta = `KLIENT`)
2. **Istnienie PROJECT_CARD.md** — jeśli ma sekcję "Strony" + "Wynagrodzenie" → `KLIENT`
3. **Manifest centralny** — `~/projekty/Project Master/project-master-data/manifests/<slug>.json` (status, phase)
4. **Komenda startowa / cron / scheduled** — jeśli uruchamiany jako cron/CI = prawdopodobnie `TOOLING`
5. **Subskrypcja end-user** — czy projekt ma `subscriptions` table + Stripe webhook? → `PRODUKT`

### Pytanie do użytkownika (gdy heurystyki niepewne)

```
Czy to:
(A) PRODUKT RYNKOWY — sprzedawalny / planowany do sprzedaży klientom końcowym
(B) TOOLING WEWNĘTRZNY — narzędzie ekosystemu (Ty/agent/automatyzacja)
(C) PROJEKT KLIENCKI — custom deliverable dla konkretnego klienta
```

### Wybór dokumentu per typ

| Typ projektu | Dokument | Template | Sekcji |
|---|---|---|---|
| **PRODUKT RYNKOWY** | `<projekt>/.ai/products/<slug>-prd.md` | `~/.claude/skills/pm-prd/templates/prd-v2-template.md` | 10 sekcji |
| **TOOLING WEWNĘTRZNY** | `<projekt>/.ai/products/<slug>-brief.md` | `~/.claude/skills/pm-prd/templates/product-brief-lite-template.md` | 5 sekcji |
| **PROJEKT KLIENCKI** | `<projekt>/.ai/client-spec.md` + `<projekt>/PROJECT_CARD.md` | `~/.claude/skills/pm-prd/templates/client-spec-template.md` | 10 sekcji (+ żywy PROJECT_CARD) |

### Krok 6: Generacja dokumentu produktu

Po onboardingu technicznym (Kroki 1-5), uruchom skill `pm-prd` w odpowiednim trybie:

- **PRODUKT** → `pm-prd` retrofit (jeśli już istnieje kod) lub greenfield (jeśli nowy projekt)
- **TOOLING** → fill `product-brief-lite-template.md` (5 sekcji, ~30 min agentowej pracy)
- **KLIENT** → fill `client-spec-template.md` + utwórz `PROJECT_CARD.md` per §10 globalnego CLAUDE.md

### Krok 7: Wpis do PRODUCTS.md ekosystemu

Zarejestruj projekt w `~/projekty/Project Master/.ai/ecosystem/PRODUCTS.md` w odpowiedniej sekcji (Produkty rynkowe / Tooling / Klienci / Archiwum). Format wpisu zgodny z istniejącymi pozycjami (tabela: Lp / Nazwa / Status / Klient docelowy / Link do dokumentu / Priorytet).

---

## Standards reference workflow

Każdy nowy dokument (PRD / Brief / Spec) automatycznie linkuje do **Standardów ekosystemu** w sekcji "Reference Standards + Business Constraints":

```markdown
Produkt korzysta z [Standardów ekosystemu Project Master](../../../../Project%20Master/.ai/standards/README.md) v1.0:
- [Monetyzacja PL](../../../../Project%20Master/.ai/standards/monetization-and-payments-pl.md)
- [Design System](../../../../Project%20Master/.ai/standards/design-system.md)
- [Security i RODO](../../../../Project%20Master/.ai/standards/security-and-rodo.md)
- [Stack techniczny](../../../../Project%20Master/.ai/standards/tech-stack.md)
- [Compliance PL](../../../../Project%20Master/.ai/standards/compliance-pl.md)
- [Integration baseline](../../../../Project%20Master/.ai/standards/integration-baseline.md)
```

Plus **Deviation Table** dla odstępstw od standardów (per template). Bez wpisu = zgodność ze standardem.

---

## Lessons learned (z sesji 2026-05-22)

1. **Klasyfikacja projektu PRZED onboardingiem technicznym** — bez tego generujemy PRD dla narzędzia tooling = over-engineering, lub Brief dla flagship produkt = under-engineering.
2. **PRODUCTS.md jako single source of truth** — bez tego wykaz produktów rozproszony w 3 miejscach (manifesty, filesystem, PRD-y).
3. **3 templates pokrywają 95% przypadków** — PRD v2.0 (10 sekcji) / Product Brief lite (5 sekcji) / Client Spec (10 sekcji z innym focus). Pozostałe 5% to eksperymenty (brak dokumentacji = OK) i reference (README wystarcza).
