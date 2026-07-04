---
name: supabase-project-migration
description: Migracja aplikacji z jednego projektu Supabase do drugiego — audyt zasobów, konsolidacja SQL, przeniesienie schematu i danych. Używaj gdy trzeba wydzielić bazę danych, rozdzielić projekty Supabase lub przenieść aplikację do osobnego projektu.
---

# Skill: Migracja aplikacji do odrębnego projektu Supabase

## Opis

Przewodnik migracji aplikacji Next.js/React z jednego projektu Supabase do drugiego (nowego lub istniejącego). Obejmuje audyt zasobów, konsolidację SQL, przeniesienie schematu, opcjonalną migrację danych i weryfikację. Idealny gdy projekt współdzieli bazę z innymi aplikacjami i wymaga separacji.

## Triggery

- "migracja supabase", "przenieś do osobnego supabase", "nowy projekt supabase"
- "migrate supabase", "separate supabase project", "supabase migration"
- "wydziel bazę danych", "rozdziel projekty supabase"

## Instrukcje

### Faza 1: Audyt zasobów Supabase

Przeskanuj cały projekt i zidentyfikuj WSZYSTKIE zasoby Supabase:

**1.1 Tabele i schemat:**
```bash
# Szukaj plików migracji
find supabase/ -name "*.sql" -type f
# Szukaj odwołań do tabel w kodzie
grep -r "\.from(" src/lib/dal/ --include="*.ts"
```

**1.2 Storage buckets:**
```bash
# Szukaj użycia storage w kodzie
grep -r "\.storage\.from(" src/ --include="*.ts" --include="*.tsx"
```

**1.3 RPC Functions:**
```bash
grep -r "\.rpc(" src/ --include="*.ts"
```

**1.4 Extensions:**
```bash
grep -r "CREATE EXTENSION" supabase/ --include="*.sql"
```

**1.5 Zmienne środowiskowe:**
```bash
grep -r "SUPABASE" .env.example .env.local
```

**1.6 Klient Supabase:**
```bash
# Sprawdź jak tworzony jest klient
find src/ -path "*/supabase/*" -name "*.ts"
```

**Checklist audytu:**
- [ ] Lista wszystkich tabel z FK dependencies
- [ ] Lista storage buckets (public vs private)
- [ ] Lista RPC functions
- [ ] Lista extensions (pgvector, pg_trgm, etc.)
- [ ] Lista RLS policies (per tabela)
- [ ] Lista triggerów i funkcji triggerowych
- [ ] Lista indeksów (zwłaszcza HNSW, GIN)
- [ ] Zidentyfikowane env vars

### Faza 2: Konsolidacja SQL

Stwórz jeden plik `supabase/combined_migration.sql` zawierający WSZYSTKO w kolejności zależności:

**Kolejność:**
1. Extensions (`CREATE EXTENSION IF NOT EXISTS ...`)
2. Tabele bazowe (bez FK do innych tabel)
3. Tabele z FK (w kolejności zależności)
4. RLS policies (per tabela, zaraz po tabeli)
5. Indeksy
6. Funkcje triggerowe
7. Triggery
8. RPC Functions
9. Storage buckets
10. Storage policies

**Wzorzec sekcji:**
```sql
-- ############################################################################
-- N/M: NAZWA SEKCJI (opis)
-- ############################################################################

CREATE TABLE ... ;
ALTER TABLE ... ENABLE ROW LEVEL SECURITY;
CREATE POLICY ... ;
CREATE INDEX ... ;
```

**Ważne:**
- NIE używaj `IF NOT EXISTS` na nowym czystym projekcie (lepiej widzieć błędy)
- Używaj `ON CONFLICT DO NOTHING` dla storage buckets (idempotentne)
- Upewnij się że `update_updated_at_column()` i inne shared functions są zdefiniowane PRZED triggerami

### Faza 3: Storage audit

**Częsty problem:** Storage buckets są tworzone ręcznie w Dashboard, ale brakuje ich w migracjach SQL!

Dla każdego bucketa zidentyfikowanego w Fazie 1:

1. **Sprawdź czy jest w SQL** - szukaj `INSERT INTO storage.buckets`
2. **Sprawdź pattern uploadowania:**
   - Folder pattern: `{userId}/{filename}` -> użyj `storage.foldername(name)[1]`
   - Flat pattern: `{userId}-{filename}` -> użyj `name LIKE auth.uid()::text || '-%'`
   - Nested: `{userId}/{sessionId}/{filename}` -> użyj `storage.foldername(name)[1]`
3. **Sprawdź public vs private:**
   - `getPublicUrl()` -> bucket MUSI być `public: true`
   - `createSignedUrl()` -> bucket może być `public: false`
4. **Policies:**
   - INSERT (upload) - WITH CHECK na ownership
   - SELECT (read) - USING na ownership lub publiczny
   - DELETE - USING na ownership
   - UPDATE (upsert) - USING na ownership

**Template bucketa publicznego (flat naming):**
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('BUCKET_NAME', 'BUCKET_NAME', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users upload own BUCKET_NAME"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'BUCKET_NAME' AND name LIKE auth.uid()::text || '-%');

CREATE POLICY "Anyone can view BUCKET_NAME"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'BUCKET_NAME');

CREATE POLICY "Users delete own BUCKET_NAME"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'BUCKET_NAME' AND name LIKE auth.uid()::text || '-%');
```

**Template bucketa prywatnego (folder naming):**
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('BUCKET_NAME', 'BUCKET_NAME', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users upload own BUCKET_NAME"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'BUCKET_NAME' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users read own BUCKET_NAME"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'BUCKET_NAME' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users delete own BUCKET_NAME"
  ON storage.objects FOR DELETE
  USING (bucket_id = 'BUCKET_NAME' AND (storage.foldername(name))[1] = auth.uid()::text);
```

### Faza 4: Nowy projekt Supabase

**Checklist tworzenia projektu:**

1. Zaloguj się na [supabase.com/dashboard](https://supabase.com/dashboard)
2. "New Project":
   - **Nazwa:** opisowa (np. `app-name-prod`, `app-name-dev`)
   - **Region:** EU Central (Frankfurt) dla polskich użytkowników
   - **Hasło bazy:** silne, zapisać w menedżerze haseł
3. Poczekaj na setup (~2 min)
4. **Włącz extensions:**
   - Dashboard > Database > Extensions
   - Szukaj i włącz wymagane (np. `vector` dla pgvector)
5. **Zapisz credentials:**
   - Settings > API > Project URL (`NEXT_PUBLIC_SUPABASE_URL`)
   - Settings > API > anon public key (`NEXT_PUBLIC_SUPABASE_ANON_KEY`)
   - Settings > API > service_role key (jeśli potrzebny)
6. **Auth settings (opcjonalnie):**
   - Authentication > Providers - włącz potrzebne (Google, GitHub, etc.)
   - Authentication > URL Configuration - ustaw redirect URLs
   - Authentication > Email Templates - dostosuj (język, branding)

### Faza 5: Migracja schematu

1. Otwórz Dashboard > SQL Editor > New query
2. Wklej zawartość `combined_migration.sql`
3. Kliknij "Run" / Execute
4. **Weryfikuj:**
   - Database > Tables - sprawdź czy wszystkie tabele istnieją
   - Database > Functions - sprawdź RPC functions
   - Storage > Buckets - sprawdź buckety
   - Authentication > Policies - sprawdź RLS

**Troubleshooting:**
- `function update_updated_at_column() does not exist` -> funkcja musi być zdefiniowana PRZED triggerami
- `extension "vector" is not available` -> włącz w Database > Extensions
- `relation "X" does not exist` -> zła kolejność tabel (FK dependency)
- `policy "X" already exists` -> uruchomiłeś migrację dwukrotnie

### Faza 6: Migracja danych (opcjonalna)

Jeśli potrzebujesz przenieść istniejące dane ze starego projektu:

**Opcja A: pg_dump/restore (najlepsza dla dużych baz)**

```bash
# Eksport ze starego projektu (connection string z Dashboard > Settings > Database)
pg_dump "postgresql://postgres:[HASLO]@db.[STARY_PROJECT_REF].supabase.co:5432/postgres" \
  --data-only \
  --no-owner \
  --no-privileges \
  -t public.TABLE_1 \
  -t public.TABLE_2 \
  > data_export.sql

# Import do nowego projektu
psql "postgresql://postgres:[HASLO]@db.[NOWY_PROJECT_REF].supabase.co:5432/postgres" \
  < data_export.sql
```

**Ważne flagi pg_dump:**
- `--data-only` - tylko dane, bez schematu (schemat już zaaplikowany)
- `--no-owner` - pomija ownership (różne role między projektami)
- `--no-privileges` - pomija GRANT/REVOKE
- `-t public.TABLE` - wybierz konkretne tabele (nie eksportuj tabel z innych aplikacji!)

**Opcja B: CSV export (mniejsze tabele)**

1. Dashboard > Table Editor > wybierz tabelę
2. Export as CSV
3. Na nowym projekcie: Table Editor > Import CSV

**Opcja C: Supabase CLI (jeśli masz local setup)**

```bash
# Eksport
supabase db dump --data-only -f data.sql --db-url "postgresql://..."
# Import
psql "postgresql://..." < data.sql
```

**Migracja Storage files:**

```bash
# Potrzebujesz service_role key dla obu projektów
# Skrypt Node.js do przeniesienia plików:

import { createClient } from '@supabase/supabase-js'

const oldClient = createClient(OLD_URL, OLD_SERVICE_ROLE_KEY)
const newClient = createClient(NEW_URL, NEW_SERVICE_ROLE_KEY)

async function migrateStorage(bucketName: string) {
  const { data: files } = await oldClient.storage.from(bucketName).list('', { limit: 1000 })
  for (const file of files || []) {
    const { data } = await oldClient.storage.from(bucketName).download(file.name)
    if (data) {
      await newClient.storage.from(bucketName).upload(file.name, data, { upsert: true })
    }
  }
}
```

**Migracja Auth users:**

Supabase nie oferuje prostego exportu użytkowników z hasłami. Opcje:
- Poproś użytkowników o ponowną rejestrację (najprostsze)
- Użyj Supabase Management API do eksportu/importu (bez haseł - wymaga password reset)
- Kontakt z Supabase Support dla dużych migracji

### Faza 7: Konfiguracja i weryfikacja

**7.1 Aktualizacja env vars:**

```bash
# .env.local
NEXT_PUBLIC_SUPABASE_URL=https://NOWY_REF.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...nowy_klucz
```

**7.2 Aktualizacja hostingu (Vercel/inne):**
- Vercel: Dashboard > Project > Settings > Environment Variables
- Netlify: Site Settings > Environment Variables
- Inne: odpowiedni panel konfiguracji

**7.3 Checklist testowy:**
- [ ] `npm run dev` startuje bez błędów
- [ ] Rejestracja nowego użytkownika działa
- [ ] Logowanie działa
- [ ] CRUD na głównych tabelach działa
- [ ] Upload plików do Storage działa
- [ ] RLS blokuje dostęp do cudzych danych
- [ ] Signout + ponowne logowanie działa
- [ ] RPC functions działają (np. vector search)
- [ ] Triggery działają (np. updated_at auto-update)
- [ ] `npm run build` przechodzi bez błędów

**7.4 Cleanup starego projektu (po pełnej weryfikacji):**
- Usuń tabele należące do tej aplikacji ze starego projektu
- Usuń storage buckets
- Usuń RLS policies
- Usuń niepotrzebne extensions

## Zależności

- Supabase account (darmowy plan wystarcza dla wielu projektów)
- `psql` CLI (opcjonalnie, dla pg_dump/restore)
- `supabase` CLI (opcjonalnie)

## Częste błędy

1. **Brak bucketa w migracji** - Storage buckets często tworzone ręcznie, a potem brakuje w SQL
2. **Zła kolejność tabel** - FK dependencies wymagają tworzenia tabel w kolejności
3. **Brak extensions** - pgvector/pg_trgm muszą być włączone PRZED tworzeniem tabel
4. **Storage policy mismatch** - foldername() vs flat naming - policy musi pasować do kodu
5. **Public vs private bucket** - getPublicUrl() wymaga public=true
6. **Brak shared functions** - update_updated_at_column() musi istnieć przed triggerami
7. **Auth users nie są przenoszone** - użytkownicy muszą się ponownie zarejestrować
