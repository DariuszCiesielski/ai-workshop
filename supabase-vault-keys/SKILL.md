# Supabase Vault — Bezpieczne przechowywanie kluczy API

## Opis
Skill do bezpiecznego przechowywania i odczytu kluczy API (lub innych sekretów) przez Supabase Vault w Edge Functions. Pokrywa pełny flow: migracje SQL, RPC functions, Edge Function, hook frontendowy.

## Triggery
- "dodaj vault", "przechowuj klucze API", "zapisz sekrety w vault"
- "manage-api-keys", "bezpieczne klucze", "szyfrowane klucze"
- Każdy nowy projekt z Edge Functions operującymi na sekretach użytkowników

## Kluczowe zasady (PUŁAPKI!)

### 1. NIGDY bezpośredni INSERT do vault.secrets
```sql
-- ❌ BŁĄD — wymaga pgsodium, którego postgres na hosted nie ma
INSERT INTO vault.secrets (secret, name, description) VALUES (...);

-- ✅ POPRAWNIE — wbudowane API Vault
SELECT vault.create_secret(secret_value, secret_name, secret_description);
```

### 2. verify_jwt = false dla EF z wewnętrzną autoryzacją
Jeśli Edge Function sama weryfikuje JWT (przez `getUser()`), relay NIE powinien tego robić podwójnie.

```toml
# supabase/config.toml
[functions.manage-api-keys]
verify_jwt = false
```

Deploy z CLI:
```bash
npx supabase functions deploy manage-api-keys --no-verify-jwt
```

### 3. NIE przekazuj ręcznie Authorization header
```typescript
// ❌ BŁĄD — ręczne zarządzanie tokenem, ryzyko starego JWT
const response = await supabase.functions.invoke('manage-api-keys', {
  headers: { Authorization: `Bearer ${session.access_token}` },
  body: { ... },
})

// ✅ POPRAWNIE — klient Supabase zarządza tokenem automatycznie
const response = await supabase.functions.invoke('manage-api-keys', {
  body: { ... },
})
```

### 4. search_path musi zawierać vault i extensions
```sql
CREATE OR REPLACE FUNCTION public.store_api_key(...)
SECURITY DEFINER
SET search_path = public, vault, extensions  -- ← vault + extensions
AS $$ ... $$;
```

## Migracja SQL — szablon

```sql
-- 1. Rozszerzenie Vault (jednorazowo)
CREATE EXTENSION IF NOT EXISTS vault WITH SCHEMA vault;

-- 2. Tabela rejestrowa (referencje do sekretów Vault)
CREATE TABLE public.{{TABLE_NAME}} (
  id uuid PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ({{PROVIDERS}})),
  vault_secret_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  last_validated_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, provider)
);

-- 3. Funkcja zapisu (SECURITY DEFINER + vault.create_secret)
CREATE OR REPLACE FUNCTION public.store_{{NAME}}(
  p_user_id uuid,
  p_provider text,
  p_api_key text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, extensions
AS $$
DECLARE
  v_secret_id uuid;
BEGIN
  SELECT vault.create_secret(
    p_api_key,
    '{{PREFIX}}_' || p_provider || '_' || p_user_id,
    'Klucz API ' || p_provider || ' dla uzytkownika ' || p_user_id
  ) INTO v_secret_id;

  INSERT INTO public.{{TABLE_NAME}} (user_id, provider, vault_secret_id, is_active, last_validated_at)
  VALUES (p_user_id, p_provider, v_secret_id, true, now())
  ON CONFLICT (user_id, provider)
  DO UPDATE SET
    vault_secret_id = v_secret_id,
    is_active = true,
    last_validated_at = now();

  RETURN v_secret_id;
END;
$$;

-- 4. Funkcja odczytu (vault.decrypted_secrets)
CREATE OR REPLACE FUNCTION public.read_{{NAME}}(
  p_user_id uuid,
  p_provider text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, extensions
AS $$
DECLARE
  v_secret_id uuid;
  v_api_key text;
BEGIN
  SELECT vault_secret_id INTO v_secret_id
  FROM public.{{TABLE_NAME}}
  WHERE user_id = p_user_id AND provider = p_provider AND is_active = true;

  IF v_secret_id IS NULL THEN RETURN NULL; END IF;

  SELECT decrypted_secret INTO v_api_key
  FROM vault.decrypted_secrets WHERE id = v_secret_id;

  RETURN v_api_key;
END;
$$;

-- 5. Granty — TYLKO service_role
REVOKE ALL ON FUNCTION public.store_{{NAME}}(uuid, text, text) FROM public;
REVOKE ALL ON FUNCTION public.store_{{NAME}}(uuid, text, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.store_{{NAME}}(uuid, text, text) TO service_role;

REVOKE ALL ON FUNCTION public.read_{{NAME}}(uuid, text) FROM public;
REVOKE ALL ON FUNCTION public.read_{{NAME}}(uuid, text) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.read_{{NAME}}(uuid, text) TO service_role;
```

## Edge Function — szablon

```typescript
// Wzorzec dwóch klientów: user (weryfikacja) + admin (operacje Vault)
const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!

// 1. Weryfikacja użytkownika
const authHeader = req.headers.get('Authorization')
const userClient = createClient(supabaseUrl, anonKey, {
  global: { headers: { Authorization: authHeader } },
})
const { data: { user }, error } = await userClient.auth.getUser()

// 2. Operacje na Vault przez service_role
const adminClient = createClient(supabaseUrl, serviceRoleKey)
const { data: secretId } = await adminClient.rpc('store_api_key', {
  p_user_id: user.id,
  p_provider: provider,
  p_api_key: keyToStore,
})
```

## Hook frontendowy — szablon

```typescript
async function callManageApiKeys(action: string, provider: string, extra = {}) {
  // Sprawdź sesję (ale NIE przekazuj tokenu ręcznie!)
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) throw new Error('Brak sesji')

  const response = await supabase.functions.invoke('manage-api-keys', {
    body: { action, provider, ...extra },
  })
  // ... error handling
}

export function useApiKeys() {
  const { user, loading } = useAuth()
  return useQuery({
    queryKey: ['api_keys'],
    queryFn: () => fetchKeys(),
    enabled: !!user && !loading,  // ← czekaj na auth
    retry: 1,
    retryDelay: 5000,  // ← łagodzi timing issues
  })
}
```

### 5. Usuwanie sekretów — ZAWSZE sprzątaj Vault!
```sql
-- ❌ BŁĄD — usuwasz referencję, ale sekret w Vault zostaje (duplicate key przy re-create)
UPDATE seo_api_key_registry SET vault_secret_id = null, is_active = false;

-- ✅ POPRAWNIE — najpierw usuń sekret z Vault, potem dezaktywuj rejestr
DELETE FROM vault.secrets WHERE id = p_secret_id;
UPDATE seo_api_key_registry SET vault_secret_id = null, is_active = false;
```

### 6. store_* musi obsługiwać „osierocone" sekrety
Jeśli ktoś usunął referencję bez usunięcia sekretu z Vault, `store_*` musi
szukać i usuwać stary sekret **po nazwie** przed `vault.create_secret()`:
```sql
-- Fallback: usun stary sekret po nazwie
SELECT id INTO v_old_secret_id FROM vault.secrets WHERE name = v_secret_name;
IF v_old_secret_id IS NOT NULL THEN
  DELETE FROM vault.secrets WHERE id = v_old_secret_id;
END IF;
-- Dopiero teraz twórz nowy
SELECT vault.create_secret(...) INTO v_secret_id;
```

## Checklist wdrożenia
1. [ ] `CREATE EXTENSION IF NOT EXISTS vault WITH SCHEMA vault`
2. [ ] Tabela rejestrowa z kolumną `vault_secret_id uuid`
3. [ ] RPC `store_*` z `vault.create_secret()` (NIE INSERT) + fallback usuwania po nazwie
4. [ ] RPC `read_*` z `vault.decrypted_secrets`
5. [ ] RPC `delete_*_secret` do usuwania sekretu z Vault (`DELETE FROM vault.secrets`)
6. [ ] Granty: REVOKE public/authenticated, GRANT service_role
7. [ ] Edge Function: akcja `delete` MUSI usuwać sekret z Vault przed dezaktywacją rejestru
8. [ ] Edge Function z wzorcem dwóch klientów (user + admin)
9. [ ] `verify_jwt = false` w config.toml + deploy z `--no-verify-jwt`
10. [ ] Frontend: `supabase.functions.invoke` BEZ ręcznego Authorization header
11. [ ] Hook: `enabled: !!user && !loading` + `retry: 1`

## Zależności
- Supabase hosted (Vault extension)
- Edge Functions (Deno runtime)
- supabase-js v2+
