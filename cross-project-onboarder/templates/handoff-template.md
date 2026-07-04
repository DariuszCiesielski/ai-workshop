# Zadanie: Wdrożenie Cross-Project {{PROJECT_ROLE_LABEL}}

## Priorytet: WYSOKI
## Data: {{DATE}}
## Źródło: Project Master — Milestone 4 (Cross-Project Pipeline)

## Cel
{{GOAL_DESCRIPTION}}

## Dlaczego
{{WHY_DESCRIPTION}}

## Co zrobić

{{IF_TARGET}}
### {{PART_LABEL}} {{PROJECT_NAME}} jako TARGET

#### 1. Wygeneruj klucz {{AUTH_TYPE_UPPER}}
```bash
{{KEY_GENERATION_CMD}}
```
Zapisz — będzie potrzebny w 2 miejscach.

{{IF_SUPABASE_EF}}
#### 2. Ustaw secret w Supabase
```bash
supabase secrets set PM_HMAC_SECRET=<klucz> --project-ref {{SUPABASE_REF}}
```
{{/IF_SUPABASE_EF}}

{{IF_REST_API}}
#### 2. Dodaj secret do `.env.local`
```
CROSS_PROJECT_API_KEY=<wygenerowany klucz>
```
{{/IF_REST_API}}

{{IF_MIGRATION}}
#### 3. Migracja SQL
```sql
{{MIGRATION_SQL}}
```
{{/IF_MIGRATION}}

#### {{STEP_GATEWAY}}. Utwórz {{GATEWAY_LABEL}}

Pełny kod: `{{INSTRUCTION_PATH}}`

Gateway musi:
- Weryfikować {{AUTH_VERIFICATION_DESC}}
- Obsługiwać {{ACTIONS_COUNT}} akcj{{ACTIONS_SUFFIX}}:
{{ACTIONS_LIST}}
- Zwracać odpowiedzi w formacie Gateway v1 (patrz Kontrakt poniżej)

{{IF_SUPABASE_EF}}
#### {{STEP_DEPLOY}}. Deploy
```bash
supabase functions deploy cross-project-gateway --project-ref {{SUPABASE_REF}}
```
{{/IF_SUPABASE_EF}}

{{IF_REST_API}}
#### {{STEP_DEPLOY}}. Deploy
Git push — Vercel automatycznie wdroży nową API route.
{{/IF_REST_API}}

#### {{STEP_NOTIFY}}. Poinformuj użytkownika
Po wdrożeniu, użytkownik musi dodać do Project Master:
- `.env.local`: `{{AUTH_SECRET_NAME}}=<ten sam klucz>`
- SQL w Supabase PM (ref: `nbxsyfkpssjfsxnuinix`): INSERT do `project_registry`{{IF_REST_API}} z `gateway_type: 'rest-api'`{{/IF_REST_API}}
{{/IF_TARGET}}

{{IF_SOURCE}}
### {{PART_LABEL}} {{PROJECT_NAME}} jako SOURCE

#### 1. Dodaj secrets do `.env.local`
```
PROJECT_MASTER_API_URL={{PM_API_URL}}
PROJECT_MASTER_TRIGGER_SECRET=<klucz HMAC z CROSS_PROJECT_TRIGGER_SECRET w PM>
```

#### 2. Utwórz API route trigger
- Ścieżka: `/api/cross-project/trigger-pipeline/route.ts`
- Server-side HMAC signing requestu do Project Master
- Wywołuje `POST /api/cross-project/trigger` w PM
- Pełny kod w instrukcji

#### 3. Utwórz komponent UI (opcjonalny)
- Przycisk uruchamiający pipeline z poziomu tego projektu
- Loading state, feedback po wysłaniu
- Umieść w odpowiednim miejscu (np. dashboard, strona kampanii)
{{/IF_SOURCE}}

## Test

```bash
cd ~/projekty/Project\ Master/project-master
npm run orch:mock-gateway
```

Lub ręczny job w SQL:
```sql
INSERT INTO cross_project_jobs (source_project, target_project, target_action, payload, idempotency_key)
VALUES ('project-master', '{{PROJECT_SLUG}}', '{{FIRST_ACTION}}', '{{TEST_PAYLOAD}}', 'onboard-test-001');
```

Oczekiwany wynik: `status = 'completed'` (sync) lub `status = 'dispatched'` (async).

## Pełna instrukcja
`{{INSTRUCTION_PATH}}`

## Kontrakt Gateway v1
```
{{IF_TARGET}}
POST {{GATEWAY_ENDPOINT}}
Headers: {{AUTH_HEADERS}}
Body: { action, job_id, correlation_id?, payload }

Response sync:  { success: true, data: {...} }
Response async: { success: true, async_task_id: "uuid", estimated_seconds: N }
Response error: { success: false, error: "msg", retryable: bool }
{{/IF_TARGET}}

{{IF_SOURCE}}
POST /api/cross-project/trigger (Project Master API)
Headers: x-signature, x-timestamp, x-nonce (HMAC-SHA256)
Body: { job: { source_project, target_project, target_action, payload }, idempotency_key? }
{{/IF_SOURCE}}
```
