# Instrukcja: Cross-Project Gateway — {{PROJECT_NAME}}

## Cel

Podłączenie projektu **{{PROJECT_NAME}}** do ekosystemu Project Master jako {{PROJECT_ROLE_LABEL}}.
Gateway umożliwia orkiestratorowi zlecanie zadań do tego projektu przez standardowy kontrakt Gateway v1.

## Projekt

| Pole | Wartość |
|------|---------|
| Nazwa | {{PROJECT_NAME}} |
| Ścieżka | `{{PROJECT_PATH}}` |
| Stack | {{STACK_DESCRIPTION}} |
| Supabase ref | `{{SUPABASE_REF}}` |
| Gateway type | `{{GATEWAY_TYPE}}` |
| ID w rejestrze | `{{PROJECT_SLUG}}` |

## Akcje

| Akcja | Opis | Typ | Avg czas |
|-------|------|-----|----------|
{{ACTIONS_TABLE}}

---

## Kroki

### 1. Wygeneruj klucz HMAC

```bash
openssl rand -hex 32
```

Zapisz wygenerowany klucz — będzie potrzebny w 2 miejscach:
- W projekcie {{PROJECT_NAME}} jako `PM_HMAC_SECRET`
- W Project Master jako `{{AUTH_SECRET_NAME}}`

{{MIGRATION_SECTION}}

### {{STEP_GATEWAY}}. Utwórz gateway

{{GATEWAY_CODE_SECTION}}

### {{STEP_DEPLOY}}. Deploy

{{DEPLOY_SECTION}}

### {{STEP_REGISTER_PM}}. Konfiguracja Project Master

#### A) Dodaj secret do `.env.local` w Project Master

```bash
# ~/projekty/Project Master/project-master/.env.local
{{AUTH_SECRET_NAME}}=<wygenerowany klucz z kroku 1>
```

#### B) Zarejestruj projekt w `project_registry`

```sql
-- Wykonaj w Supabase Dashboard (ref: nbxsyfkpssjfsxnuinix)
INSERT INTO project_registry (id, name, gateway_type, gateway_url, auth_type, auth_secret_name, available_actions)
VALUES (
  '{{PROJECT_SLUG}}',
  '{{PROJECT_NAME}}',
  '{{GATEWAY_TYPE}}',
  '{{GATEWAY_URL}}',
  '{{AUTH_TYPE}}',
  '{{AUTH_SECRET_NAME}}',
  '{{ACTIONS_JSON}}'
) ON CONFLICT (id) DO UPDATE SET
  gateway_url = EXCLUDED.gateway_url,
  available_actions = EXCLUDED.available_actions;
```

### {{STEP_TEST}}. Test

#### A) Ręczny test z CLI

```bash
cd ~/projekty/Project\ Master/project-master
npm run orch:mock-gateway
```

#### B) Lub manual job w SQL

```sql
INSERT INTO cross_project_jobs (source_project, target_project, target_action, payload, idempotency_key)
VALUES ('project-master', '{{PROJECT_SLUG}}', '{{FIRST_ACTION}}', '{{TEST_PAYLOAD}}', 'onboard-test-001');
```

#### C) Sprawdź wynik

```sql
SELECT status, result, error_message
FROM cross_project_jobs
WHERE idempotency_key = 'onboard-test-001';
```

Oczekiwany wynik: `status = 'completed'` (sync) lub `status = 'dispatched'` (async).

{{SOURCE_SECTION}}

---

## Checklist

```
Onboarding {{PROJECT_NAME}}:
- [ ] Klucz HMAC wygenerowany (krok 1)
{{CHECKLIST_MIGRATION}}
- [ ] Gateway wdrożony (krok {{STEP_GATEWAY}})
- [ ] Deploy wykonany (krok {{STEP_DEPLOY}})
- [ ] Secret w .env.local Project Master (krok {{STEP_REGISTER_PM}}A)
- [ ] INSERT do project_registry (krok {{STEP_REGISTER_PM}}B)
- [ ] Test przeszedł (krok {{STEP_TEST}})
{{CHECKLIST_SOURCE}}
```

---

## Kontrakt Gateway v1

### Request

```
POST {{GATEWAY_ENDPOINT}}

Headers:
  x-signature: HMAC-SHA256(timestamp.nonce.body, secret)
  x-timestamp: unix seconds
  x-nonce: random UUID

Body:
  {
    "action": "{{EXAMPLE_ACTION}}",
    "job_id": "uuid",
    "correlation_id": "uuid (opcjonalny)",
    "payload": { ... }
  }
```

### Response (sync)
```json
{ "success": true, "data": { "..." } }
```

### Response (async)
```json
{ "success": true, "async_task_id": "uuid", "estimated_seconds": 60 }
```

### Response (error)
```json
{ "success": false, "error": "opis błędu", "retryable": false }
```

### Taksonomia błędów

| HTTP | Znaczenie | Retry? |
|------|-----------|--------|
| 2xx + `retryable: true` | Tymczasowy błąd | Tak |
| 2xx + `retryable: false` | Błąd logiki | Nie |
| 429 | Rate limited | Tak |
| 4xx | Błąd klienta | Nie |
| 5xx | Błąd serwera | Tak |
