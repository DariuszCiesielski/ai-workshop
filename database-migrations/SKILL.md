---
name: database-migrations
description: >
  Pisanie migracji SQL Supabase — schema changes, typy, rollback, seed data.
  Triggery: "migracja bazy", "database migration", "nowa tabela", "zmień schemat",
  "dodaj kolumnę", "ALTER TABLE", "RLS policy", "rollback migracji",
  "seed data", "supabase migration", "schema change", "typ danych".
---

# Database Migrations — Migracje SQL Supabase

Pisze migracje SQL dla Supabase: tworzenie tabel, modyfikacja schematu, RLS policies, indeksy, seed data. Standaryzuje proces zmian w bazie z rollback safety.

## Kiedy używać

- Tworzenie nowej tabeli
- Dodawanie/usuwanie kolumn
- Zmiana typów danych, constraints
- Tworzenie RLS policies
- Seed data dla developmentu/demo
- Użytkownik mówi: "nowa tabela", "dodaj kolumnę", "zmień schemat bazy"

## Zależności

- **Opcjonalne:** `supabase-auth-rls` → wzorce RLS policies
- **Opcjonalne:** `supabase-auth-multi-tenant` → multi-tenant schema
- **Opcjonalne:** `supabase-data-map` → mapa istniejącego schematu

## Setup — Supabase CLI

```bash
# Zainstaluj Supabase CLI (jeśli nie masz)
npm install -g supabase

# Połącz z projektem
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Ściągnij aktualny schemat
supabase db pull
```

## Tworzenie migracji

```bash
# Nowa migracja
supabase migration new create_projects_table
# → supabase/migrations/20260408120000_create_projects_table.sql
```

### Konwencja nazewnictwa

```
YYYYMMDDHHMMSS_opis_zmiany.sql

Przykłady:
20260408120000_create_projects_table.sql
20260408120100_add_status_to_projects.sql
20260408120200_create_rls_policies_projects.sql
20260408120300_add_index_projects_owner_id.sql
20260408120400_seed_initial_data.sql
```

## Wzorce migracji

### 1. Tworzenie tabeli

```sql
-- supabase/migrations/20260408120000_create_projects_table.sql

-- UP
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'archived', 'deleted')),
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Data API exposure (wymagane dla nowych tabel po 30.10.2026, patrz sekcja "Data API exposure" niżej)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.projects TO anon, authenticated;
-- Dla service_role grant jest implicit, ale explicit jest OK
-- GRANT ALL ON public.projects TO service_role;

-- Indeksy
CREATE INDEX idx_projects_owner_id ON public.projects(owner_id);
CREATE INDEX idx_projects_status ON public.projects(status);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- RLS
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own projects"
  ON public.projects FOR SELECT
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can create own projects"
  ON public.projects FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own projects"
  ON public.projects FOR UPDATE
  USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own projects"
  ON public.projects FOR DELETE
  USING (auth.uid() = owner_id);

COMMENT ON TABLE public.projects IS 'User projects';
```

### 2. Dodawanie kolumny

```sql
-- supabase/migrations/20260408120100_add_slug_to_projects.sql

-- UP: Dodaj kolumnę z domyślną wartością (bezpieczne na dużych tabelach)
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS slug TEXT;

-- Wypełnij istniejące rekordy
UPDATE public.projects
SET slug = lower(replace(name, ' ', '-'))
WHERE slug IS NULL;

-- Teraz ustaw NOT NULL (po wypełnieniu!)
ALTER TABLE public.projects
  ALTER COLUMN slug SET NOT NULL;

-- Unique constraint
ALTER TABLE public.projects
  ADD CONSTRAINT projects_slug_unique UNIQUE (slug);

-- Indeks dla wyszukiwania
CREATE INDEX idx_projects_slug ON public.projects(slug);
```

### 3. Zmiana typu kolumny

```sql
-- supabase/migrations/20260408120200_change_status_to_enum.sql

-- Utwórz enum
CREATE TYPE project_status AS ENUM ('active', 'archived', 'deleted');

-- Zmień typ kolumny (z konwersją danych)
ALTER TABLE public.projects
  ALTER COLUMN status TYPE project_status
  USING status::project_status;

-- Usuń stary CHECK constraint (jeśli był)
ALTER TABLE public.projects
  DROP CONSTRAINT IF EXISTS projects_status_check;
```

### 4. Tworzenie tabeli junction (many-to-many)

```sql
-- supabase/migrations/20260408120300_create_project_members.sql

CREATE TABLE IF NOT EXISTS public.project_members (
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member'
    CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (project_id, user_id)
);

CREATE INDEX idx_project_members_user ON public.project_members(user_id);

ALTER TABLE public.project_members ENABLE ROW LEVEL SECURITY;

-- Użytkownik widzi projekty, w których uczestniczy
CREATE POLICY "Members can view membership"
  ON public.project_members FOR SELECT
  USING (auth.uid() = user_id);

-- Właściciel/admin projektu może zarządzać członkami
CREATE POLICY "Admins can manage members"
  ON public.project_members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.project_members pm
      WHERE pm.project_id = project_members.project_id
        AND pm.user_id = auth.uid()
        AND pm.role IN ('owner', 'admin')
    )
  );
```

### 5. SECURITY DEFINER function (bezpieczny dostęp)

```sql
-- supabase/migrations/20260408120400_create_is_project_member.sql

-- Funkcja sprawdzająca członkostwo BEZ rekurencji RLS
CREATE OR REPLACE FUNCTION public.is_project_member(
  _project_id UUID,
  _user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM project_members
    WHERE project_id = _project_id
      AND user_id = _user_id
  );
$$;

-- Użycie w RLS policy:
-- CREATE POLICY "Members can view project"
--   ON public.projects FOR SELECT
--   USING (is_project_member(id));
```

### 6. Seed data

```sql
-- supabase/seed.sql (uruchamiany przez supabase db reset)

-- Użytkownik testowy (tylko development!)
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, role)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'test@example.com',
  crypt('TestPassword123!', gen_salt('bf')),
  now(),
  'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- Dane testowe
INSERT INTO public.projects (name, slug, owner_id) VALUES
  ('Projekt Demo', 'projekt-demo', '00000000-0000-0000-0000-000000000001'),
  ('Drugi Projekt', 'drugi-projekt', '00000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;
```

## Rollback

Supabase CLI nie ma wbudowanego rollbacku — musisz pisać go ręcznie.

### Wzorzec: komentarz z rollback SQL

```sql
-- supabase/migrations/20260408120500_add_priority_to_projects.sql

-- UP
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS priority INTEGER NOT NULL DEFAULT 0;

CREATE INDEX idx_projects_priority ON public.projects(priority);

-- ROLLBACK (wykonaj ręcznie jeśli potrzeba):
-- DROP INDEX IF EXISTS idx_projects_priority;
-- ALTER TABLE public.projects DROP COLUMN IF EXISTS priority;
```

### Wzorzec: osobny plik rollback

```
supabase/migrations/
├── 20260408120500_add_priority_to_projects.sql
└── rollbacks/
    └── 20260408120500_rollback.sql
```

## Bezpieczeństwo migracji

### Operacje BEZPIECZNE (zero downtime)

| Operacja | Bezpieczna? | Uwagi |
|----------|:-----------:|-------|
| CREATE TABLE | ✅ | Nowa tabela, zero ryzyka |
| ADD COLUMN (nullable) | ✅ | Nie blokuje tabeli |
| ADD COLUMN (NOT NULL + DEFAULT) | ✅ | PostgreSQL 11+ nie rewrituje |
| CREATE INDEX CONCURRENTLY | ✅ | Nie blokuje zapisów |
| ADD CONSTRAINT (CHECK) | ⚠️ | Skanuje tabelę, krótki lock |
| CREATE POLICY | ✅ | Nie blokuje |

### Operacje NIEBEZPIECZNE

| Operacja | Ryzyko | Rozwiązanie |
|----------|--------|-------------|
| DROP COLUMN | Dane utracone | Najpierw backup, potem soft-delete (rename → drop po tygodniu) |
| ALTER TYPE | Lock na tabeli | Utwórz nową kolumnę → kopiuj → drop starą |
| ADD NOT NULL (bez default) | Fail na istniejących NULL | Najpierw UPDATE SET DEFAULT, potem ADD NOT NULL |
| DROP TABLE | Dane utracone | Rename na `_deprecated_` → drop po 30 dniach |
| TRUNCATE | Dane utracone | Nigdy na produkcji |

### Wzorzec bezpiecznego usuwania kolumny

```sql
-- Krok 1: Rename (nie drop!)
ALTER TABLE public.projects
  RENAME COLUMN old_column TO _deprecated_old_column;

-- Krok 2: (po 7-30 dniach, gdy pewny że nic nie używa)
ALTER TABLE public.projects
  DROP COLUMN _deprecated_old_column;
```

## Generowanie typów TypeScript

```bash
# Po każdej migracji — wygeneruj typy
supabase gen types typescript --linked > src/types/database.ts
```

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from '@/types/database';

export const supabase = createClient<Database>(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);
```

## Workflow migracji

```
1. supabase migration new opis_zmiany
2. Napisz SQL w nowym pliku
3. supabase db reset (testuj lokalnie)
4. supabase gen types typescript --linked > src/types/database.ts
5. Sprawdź czy TypeScript kompiluje się z nowymi typami
6. git add + commit
7. supabase db push (aplikuj na remote)
```

## Checklist przed push na produkcję

- [ ] Migracja działa na `supabase db reset` (czysta baza)
- [ ] Migracja działa na istniejących danych (nie tylko pustej tabeli)
- [ ] RLS policies dodane dla nowych tabel
- [ ] **`GRANT SELECT, INSERT, UPDATE, DELETE TO anon, authenticated`** dla każdej `CREATE TABLE public.*` (wymóg Supabase od 30.10.2026, patrz "Data API exposure")
- [ ] Indeksy na kolumnach używanych w WHERE/JOIN
- [ ] Typy TypeScript wygenerowane i kompilują się
- [ ] Komentarz z rollback SQL w pliku migracji
- [ ] Brak DROP/TRUNCATE bez potwierdzenia
- [ ] Curl test `/rest/v1/<new_table>` zwraca 200 (NIE 401/permission denied)

## Data API exposure (zmiana 30.05.2026 / 30.10.2026)

Supabase zmienia domyślne zachowanie auto-eksponowania tabel do Data API (REST endpoint `/rest/v1/...` + GraphQL):

| Data | Co | Wpływ na nasze projekty |
|---|---|---|
| **30.05.2026** | Nowe projekty: nowe tabele NIE są auto-eksponowane do Data API | Tylko jeśli zakładasz NOWY projekt Supabase od 30.05 |
| **30.10.2026** | Istniejące projekty: nowe tabele utworzone PO tej dacie wymagają explicit GRANT | **WPŁYWA na każdą nową migrację w istniejących projektach LG/SOTA RAG/SEO/PM/Voicebot/itd.** |

**ŁADUJĄCE TABELE I APLIKACJE NIE SĄ DOTKNIĘTE** — zachowują dotychczasowe grants forever. Default row limit nadal 1000 (wbrew niektórym halucynowanym diagnozom — Supabase NIE zmienia row limit).

### Reguła obowiązkowa dla CREATE TABLE w schemacie `public` (od 30.10.2026)

```sql
CREATE TABLE public.X (
  ...
);

-- ZAWSZE dopisz po CREATE TABLE w schemacie public:
GRANT SELECT, INSERT, UPDATE, DELETE ON public.X TO anon, authenticated;
```

**Bez tego grantu** PostgREST zwróci **401/permission denied** dla `/rest/v1/X` mimo że tabela istnieje w bazie (RLS sprawdza CZY widzisz, grant decyduje CZY masz dostęp w ogóle).

### Kiedy ograniczać grant (zaawansowane)

| Use case | Grant pattern |
|---|---|
| Tabela read-only przez API (np. lookup, dictionary) | `GRANT SELECT ON public.X TO anon, authenticated` |
| Tabela tylko-server (write z Edge Function, RLS blokuje wszystko z anon) | **Pomiń grant** — RLS i tak by zablokowało |
| Tabela admin-only | `GRANT ALL ON public.X TO service_role` (nie `anon`/`authenticated`) |
| Multi-tenant z RLS per `org_id` | Standard: `GRANT SELECT, INSERT, UPDATE, DELETE TO anon, authenticated` + RLS policy `auth.uid()` |

### Schematy poza `public`

Tabele w `auth`, `storage`, `realtime` oraz **custom schemach niewyeksponowanych** w Project Settings → API → "Exposed schemas" — **NIE są dotknięte**. Zachowują własne grants.

### Verify po deploy migracji

```bash
# Czy PostgREST widzi tabelę?
curl -s "${SUPABASE_URL}/rest/v1/X?limit=1" \
  -H "apikey: ${SUPABASE_ANON_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}"
# Oczekiwane: 200 z [] (pusta tabela) lub rekordy, NIE 401/403/permission denied
```

Jeśli 401/403 mimo że migracja deployowała OK → brak GRANT. Naprawa:
```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON public.X TO anon, authenticated;
NOTIFY pgrst, 'reload schema';  -- PostgREST schema cache refresh
```

(Sources: [Supabase changelog 45329](https://supabase.com/changelog/45329-breaking-change-tables-not-exposed-to-data-and-graphql-api-automatically), [GitHub discussion](https://github.com/orgs/supabase/discussions/45329))

## Pułapki

1. **Edytowanie istniejących migracji** → NIGDY! Supabase trackuje które migracje były uruchomione. Edycja = desync. Zawsze twórz nową migrację.
2. **NOT NULL bez DEFAULT na istniejącej tabeli** → fail. Najpierw dodaj nullable, wypełnij dane, potem SET NOT NULL.
3. **CREATE INDEX (bez CONCURRENTLY)** → blokuje tabelę na czas budowy indeksu. Na dużych tabelach używaj CONCURRENTLY.
4. **Brak RLS na nowej tabeli** → domyślnie tabela jest publiczna! Zawsze dodaj `ENABLE ROW LEVEL SECURITY` + policies.
5. **Service role key w frontendzie** → NIGDY. Migracje i seed uruchamiaj przez CLI, nie z kodu frontendowego.
6. **Brak typów po migracji** → TypeScript nie wie o nowych kolumnach → runtime errory. Zawsze `gen types` po push.
