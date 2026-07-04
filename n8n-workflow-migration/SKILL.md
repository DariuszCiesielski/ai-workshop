---
name: n8n-workflow-migration
description: Migracja workflow N8N z Airtable na Supabase — zamiana nodów, mapowanie pól, naprawa wyrażeń, testowanie przez API. Zarządzanie workflow N8N (import, update, aktywacja, monitoring executions). Triggery — "przepnij workflow na Supabase", "zamień Airtable na Supabase w N8N", "zaimportuj workflow do N8N", "przetestuj workflow N8N", "migracja N8N". Aliasy — "n8n migration", "n8n Supabase", "przepięcie workflow".
---

# N8N Workflow Migration: Airtable → Supabase

Skill prowadzi agenta przez migrację workflow N8N z backendu Airtable na Supabase. Obejmuje zamianę nodów, mapowanie pól, naprawę wyrażeń i testowanie. Bazuje na praktycznym doświadczeniu z migracji produkcyjnego workflow Content Writer 4.3 (66 nodów).

## Kiedy używać

- "przepnij workflow na Supabase", "zamień Airtable na Supabase"
- "zaimportuj workflow do N8N", "zaktualizuj workflow w N8N"
- "przetestuj workflow N8N", "uruchom workflow"
- "migracja N8N", "n8n migration"
- Gdy zadanie polega na zamianie nodów Airtable → Supabase w istniejącym workflow N8N
- Gdy trzeba zarządzać workflow przez N8N API (import, update, execute)

## Kiedy NIE używać

- Pisanie workflow N8N od zera
- Adaptacja workflow do kodu (Edge Functions) → użyj `workflow-adaptation`
- Praca z Make.com, Zapier (inny format)

---

## N8N API — podstawy

### Dane dostępowe

Szukaj w memory projektu (`reference_n8n_instance.md`) lub credentials-vault:
- **URL:** `https://n8n.example.com`
- **API Key:** JWT token
- **Header:** `X-N8N-API-KEY`

### Endpointy

```bash
# Lista workflow
GET /api/v1/workflows?limit=50

# Pobierz workflow
GET /api/v1/workflows/{id}

# Utwórz nowy workflow (NIE wysyłaj pola "active" — jest read-only)
POST /api/v1/workflows
Body: { "name": "...", "nodes": [...], "connections": {...}, "settings": {...} }

# Aktualizuj workflow (wymaga PEŁNEGO payloadu — name, nodes, connections, settings)
PUT /api/v1/workflows/{id}

# Aktywuj workflow
POST /api/v1/workflows/{id}/activate

# Dezaktywuj
POST /api/v1/workflows/{id}/deactivate

# Lista executions
GET /api/v1/executions?workflowId={id}&limit=5
GET /api/v1/executions?status=running,waiting
GET /api/v1/executions?status=error

# Szczegóły execution (z danymi nodów)
GET /api/v1/executions/{id}?includeData=true

# Lista credentials
GET /api/v1/credentials
```

### Ważne ograniczenia API

- **POST /workflows** — nie wysyłaj pola `active` (błąd "active is read-only")
- **PUT /workflows** — wymaga pełnego payloadu (name + nodes + connections + settings), nie obsługuje partial update
- **PATCH** — nie jest obsługiwany
- **Uruchamianie workflow** — API nie obsługuje bezpośredniego execute. Użyj webhook trigger
- **Webhook conflict** — dwa workflow nie mogą mieć tego samego webhook path. Zmień path na unikalny (UUID)

---

## Proces migracji — 7 kroków

### KROK 1: Analiza oryginalnego workflow

1. **Pobierz schemat tabeli z Airtable Meta API:**
```bash
curl "https://api.airtable.com/v0/meta/bases/{baseId}/tables" \
  -H "Authorization: Bearer {token}"
```
Daje DOKŁADNE nazwy pól (case-sensitive!) — krytyczne dla mapowania.

2. **Wylistuj wszystkie nody Airtable** w workflow JSON:
```python
at_nodes = [n for n in wf['nodes'] if n['type'] == 'n8n-nodes-base.airtable']
```

3. **Dla każdego noda Airtable** zapisz:
   - Operację (search, update, read/get)
   - Pola które czyta/zapisuje (z expressions)
   - matchingColumns (zawsze `["id"]`)
   - Co podaje na wejście, co odbiera na wyjściu (connections)

4. **Zidentyfikuj nody NIE-Airtable** które odwołują się do danych Airtable:
   - Code nodes z `.fields['X']`
   - AI/LLM nodes z promptami zawierającymi `$json.fields.X`
   - Set nodes (Global settings) z wyrażeniami Airtable field names

### KROK 2: Przygotowanie tabeli Supabase

1. **Sprawdź istniejące kolumny** vs pola Airtable:
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'nazwa_tabeli' ORDER BY ordinal_position;
```

2. **Dodaj brakujące kolumny** (ALTER TABLE ADD COLUMN IF NOT EXISTS)

3. **Stwórz mapowanie nazw** Airtable → Supabase:
   - Airtable: Title Case ze spacjami ("Słowo Kluczowe", "SEO Główne INFO")
   - Supabase: snake_case ("slowo_kluczowe", "seo_glowne_info")
   - Pola company_* zwykle mają identyczne nazwy w obu
   - **WAŻNE:** Zweryfikuj mapowanie z Meta API — literówka = błąd runtime

### KROK 3: Konwersja nodów Airtable → Supabase

#### Struktura noda Supabase:
```json
{
  "type": "n8n-nodes-base.supabase",
  "typeVersion": 1,
  "credentials": {
    "supabaseApi": {
      "id": "CREDENTIAL_ID",
      "name": "Nazwa Credential"
    }
  },
  "parameters": {
    "operation": "getAll|update|insert|delete",
    "tableId": "nazwa_tabeli_supabase"
  }
}
```

#### Konwersja operacji:

**SEARCH (Airtable) → getAll (Supabase):**
```json
// AIRTABLE
{ "operation": "search", "options": { "filterByFormula": "{Status} = 'Wartość'" } }

// SUPABASE
{ "operation": "getAll", "tableId": "tabela", "returnAll": false, "limit": 1,
  "filters": { "conditions": [{ "keyName": "status", "condition": "eq", "keyValue": "Wartość" }] } }
```

**READ by ID (Airtable) → getAll + filter (Supabase):**
```json
// AIRTABLE (operation null/read, z parametrem "id")
{ "id": "={{ $('Node').item.json.record_id }}" }

// SUPABASE
{ "operation": "getAll", "tableId": "tabela", "returnAll": false, "limit": 1,
  "filters": { "conditions": [{ "keyName": "id", "condition": "eq", "keyValue": "={{ $('Node').item.json.record_id }}" }] } }
```

**UPDATE (Airtable) → update (Supabase):**
```json
// AIRTABLE
{ "operation": "update", "columns": { "mappingMode": "defineBelow",
    "value": { "Pole Airtable": "={{ wyrażenie }}", "id": "={{ id }}" },
    "matchingColumns": ["id"] } }

// SUPABASE
{ "operation": "update", "tableId": "tabela",
  "filters": { "conditions": [{ "keyName": "id", "condition": "eq", "keyValue": "={{ id }}" }] },
  "fieldsUi": { "fieldValues": [
    { "fieldId": "pole_supabase", "fieldValue": "={{ wyrażenie }}" }
  ] } }
```

**Kluczowe różnice:**
- Airtable: `matchingColumns: ["id"]` + `id` w `value` → Supabase: `filters.conditions` z `keyName: "id"`
- Airtable: `columns.value` (obiekt) → Supabase: `fieldsUi.fieldValues` (tablica)
- Supabase nie potrzeba `base` i `table` ID → tylko `tableId` (nazwa tabeli)

### KROK 4: Naprawa wyrażeń — KRYTYCZNE

#### Problem: Format danych wyjściowych

**Airtable node output (spłaszczony):**
```json
{ "id": "recXXX", "Słowo Kluczowe": "wartość", "Title": "tytuł" }
```
Ale UPDATE node zwraca z wrapperem:
```json
{ "id": "recXXX", "fields": { "Title": "tytuł" } }
```

**Supabase node output (zawsze płaski):**
```json
{ "id": "uuid", "slowo_kluczowe": "wartość", "title": "tytuł" }
```

#### Co trzeba zmienić:

1. **Global settings / Set nodes** — nazwy pól:
```
$json['Słowo Kluczowe']  →  $json.slowo_kluczowe
$json['Opis Strony']     →  $json.opis_strony
$json.Lokalizacja         →  $json.lokalizacja
$json['Język']            →  $json.jezyk
```

2. **Wrapper `.fields`** — usunąć we WSZYSTKICH nodach:
```
$('Node').item.json.fields['Outline']     →  $('Node').item.json.outline
$('Node').item.json.fields.Title          →  $('Node').item.json.title
$json.fields['AI Overview Summary']       →  $json.ai_overview_summary
$json.fields.target_audience              →  $json.target_audience
```

3. **Code nodes (JavaScript)** — ręczna zamiana:
```javascript
// BYŁO
const x = $('Node').item.json.fields['Outline'] || "";
// JEST
const x = $('Node').item.json.outline || "";
```

#### Jak znaleźć WSZYSTKIE odwołania do naprawienia:

```python
import re
full_text = json.dumps(wf, ensure_ascii=False)

# Szukaj .fields pattern
refs = re.findall(r'\.fields[\[\.][A-Za-z]', full_text)

# Szukaj Airtable field names (Title Case ze spacjami)
for field in ["Słowo Kluczowe", "Opis Strony", "Ton W Jakim Pisać", ...]:
    if field in full_text:
        # Znajdź w którym nodzie
```

**UWAGA:** Skrypt musi przeszukiwać WSZYSTKIE nody, nie tylko Airtable/Supabase. Odwołania `.fields` najczęściej są w:
- Code nodes (JavaScript)
- AI/LLM nodes (prompty z wyrażeniami N8N)
- Set nodes (Global settings)

### KROK 5: Mechanizm kolejki (opcjonalny)

Jeśli oryginalny workflow używa **N8N DataTable** do kolejkowania (lockowania):

**Opcja A (rekomendowana): Supabase jako kolejka**
- Usuń nody DataTable (Get row(s), Update row(s), If)
- Podłącz trigger bezpośrednio do noda Supabase getAll
- Na końcu: Wait → loop z powrotem do getAll
- Brak rekordu = workflow się zatrzymuje naturalnie

**Opcja B: Odtworzenie DataTable**
- Stwórz nową DataTable w N8N ręcznie
- Zaktualizuj ID w nodach

### KROK 6: Credential setup

1. **Pobierz listę credentials z N8N:**
```bash
GET /api/v1/credentials
```

2. **Znajdź credential typu `supabaseApi`** lub utwórz nowy w N8N UI:
   - Host: URL projektu Supabase
   - Service Role Key: z Supabase Dashboard → Settings → API
   - **WAŻNE:** Service Role Key omija RLS

3. **Podłącz credential do nodów** — zaktualizuj workflow z prawdziwym credential ID:
```json
"credentials": {
  "supabaseApi": {
    "id": "PRAWDZIWY_ID_Z_API",
    "name": "Nazwa Credential"
  }
}
```

### KROK 7: Testowanie

#### Webhook:
- Zmień webhook path na unikalny (UUID) — unikaj konfliktu z oryginalnym workflow
- Aktywuj workflow: `POST /api/v1/workflows/{id}/activate`
- Trigger: `GET https://n8n.example.com/webhook/{path}` (domyślnie GET, nie POST!)

#### Monitoring execution:
```bash
# Sprawdź running
GET /api/v1/executions?status=running,waiting

# Sprawdź wynik
GET /api/v1/executions/{id}?includeData=true
```

#### Weryfikacja danych w Supabase:
```sql
SELECT id, status, LEFT(title, 60), LEFT(article, 60), ...
FROM tabela WHERE id = 'uuid';
```

---

## Częste pułapki (Lessons Learned)

### 1. `.fields` wrapper — NAJWIĘKSZY problem
Airtable UPDATE node zwraca `{ fields: { ... } }`. Supabase zwraca płaski obiekt. Odwołania `.fields['X']` i `.fields.X` MUSZĄ być usunięte ze WSZYSTKICH nodów (nie tylko Airtable → Supabase, ale też Code, AI, Set).

**Skrypt wykrywający:**
```python
remaining = re.findall(r'\.fields[\[\.][A-Za-z]', json.dumps(wf))
assert len(remaining) == 0, f"Pozostałe .fields: {remaining}"
```

### 2. PUT wymaga pełnego payloadu
N8N API PUT `/workflows/{id}` wymaga name + nodes + connections + settings. Wysłanie samego `{"name": "..."}` zwróci błąd "must have required property 'nodes'".

### 3. Webhook path conflict
Dwa aktywne workflow nie mogą mieć tego samego webhook path. Błąd: "There is a conflict with one of the webhooks." Rozwiązanie: zmień path na nowy UUID.

### 4. Webhook domyślnie GET, nie POST
N8N webhook node v1 domyślnie nasłuchuje na GET. `POST` zwróci 404 "Did you mean to make a GET request?".

### 5. Pole `active` jest read-only w POST
Przy tworzeniu workflow nie wysyłaj `"active": true/false`. Aktywuj osobnym endpointem.

### 6. Nazwa workflow z Unicode
N8N używa Unicode cudzysłowów w nazwach nodów (`'` = U+2018, `'` = U+2019). Connections muszą używać DOKŁADNIE tych samych znaków.

### 7. Code nodes — nie skanowane automatycznie
Skrypt zamieniający wyrażenia w parametrach może nie trafić do `jsCode` w Code nodach. ZAWSZE skanuj osobno:
```python
for node in wf['nodes']:
    if node['type'] == 'n8n-nodes-base.code':
        js = node['parameters'].get('jsCode', '')
        if '.fields' in js:
            # NAPRAW
```

### 8. Execution nie pojawia się od razu
Po webhook trigger, execution może nie być widoczna przez kilka sekund. Długie workflow (NeuronWriter, DataForSEO) mogą trwać 10-30 minut.

### 9. DataTable nodes to NIE Airtable
Nody `n8n-nodes-base.dataTable` (Get row(s), Update row(s)) to wewnętrzna tabela N8N, nie Airtable. Nie zamieniaj ich na Supabase — służą do lockowania/kolejkowania.

---

## Walidacja workflow — checklist

```python
# Po transformacji uruchom:
assert len([n for n in nodes if n['type'] == 'n8n-nodes-base.airtable']) == 0  # Zero Airtable
assert len([n for n in nodes if n['type'] == 'n8n-nodes-base.supabase']) == N  # N nodów SB
assert '.fields' not in json.dumps(wf)  # Brak .fields wrapper
assert all connections source/target exist in nodes  # Integralność connections
assert all Supabase nodes have credentials  # Credentials podpięte
assert all $('NodeName') references exist  # Referencje nodów
```

---

## Przykład: Skrypt transformacji (Python)

```python
import json, re, uuid

def migrate_workflow(input_path, output_path, table_id, credential_id, credential_name, field_map):
    """
    Migruje workflow N8N z Airtable na Supabase.

    field_map: dict {'Airtable Field Name': 'supabase_column'}
    """
    with open(input_path) as f:
        wf = json.load(f)

    SB_CREDS = {"supabaseApi": {"id": credential_id, "name": credential_name}}

    for node in wf['nodes']:
        if node['type'] != 'n8n-nodes-base.airtable':
            continue

        op = node['parameters'].get('operation')
        old_fields = node['parameters'].get('columns', {}).get('value', {})

        node['type'] = 'n8n-nodes-base.supabase'
        node['typeVersion'] = 1
        node['credentials'] = SB_CREDS

        if op == 'search':
            # Konwertuj na getAll
            filter_formula = node['parameters'].get('options', {}).get('filterByFormula', '')
            # Parse simple {Field} = 'Value'
            node['parameters'] = {
                "operation": "getAll", "tableId": table_id,
                "returnAll": False, "limit": 1,
                "filters": {"conditions": [/* parse filter */]}
            }
        elif op == 'update':
            # Konwertuj na update
            id_expr = old_fields.pop('id', '')
            field_values = []
            for at_name, expr in old_fields.items():
                sb_name = field_map.get(at_name, at_name.lower().replace(' ', '_'))
                field_values.append({"fieldId": sb_name, "fieldValue": expr})
            node['parameters'] = {
                "operation": "update", "tableId": table_id,
                "filters": {"conditions": [{"keyName": "id", "condition": "eq", "keyValue": id_expr}]},
                "fieldsUi": {"fieldValues": field_values}
            }
        elif op is None:  # READ by ID
            id_expr = node['parameters'].get('id', '')
            node['parameters'] = {
                "operation": "getAll", "tableId": table_id,
                "returnAll": False, "limit": 1,
                "filters": {"conditions": [{"keyName": "id", "condition": "eq", "keyValue": id_expr}]}
            }

    # Fix expressions — .fields wrapper
    def fix_fields(obj):
        if isinstance(obj, str):
            for at_name, sb_name in field_map.items():
                obj = obj.replace(f".fields['{at_name}']", f".{sb_name}")
                obj = obj.replace(f".fields.{at_name}", f".{sb_name}")
            return obj
        elif isinstance(obj, dict):
            return {k: fix_fields(v) for k, v in obj.items()}
        elif isinstance(obj, list):
            return [fix_fields(i) for i in obj]
        return obj

    for node in wf['nodes']:
        node['parameters'] = fix_fields(node.get('parameters', {}))

    # Webhook — nowy path
    for node in wf['nodes']:
        if 'webhook' in node.get('type', ''):
            node['parameters']['path'] = str(uuid.uuid4())

    with open(output_path, 'w') as f:
        json.dump(wf, f, ensure_ascii=False, indent=2)
```
