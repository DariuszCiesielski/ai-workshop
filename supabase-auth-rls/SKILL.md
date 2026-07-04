---
name: supabase-auth-rls
description: Hub konfiguracji Supabase Auth z Row Level Security — rozdzielony na 3 sub-skille per scenariusz (admin roles, multi-tenant, whitelist). Używaj przy ogólnych pytaniach o auth+RLS lub gdy nie wiesz którego sub-skilla użyć.
---

# Supabase Auth + RLS — Hub

Konfiguracja autentykacji z Row Level Security w Supabase. Rozdzielony na 3 wyspecjalizowane sub-skille.

## Sub-skille

| Skill | Scenariusz | Kiedy użyć |
|-------|-----------|------------|
| **supabase-auth-admin-roles** | Admin / User | Separacja ról, tabela admins, `is_admin()`, SECURITY DEFINER, debugging rekursji RLS |
| **supabase-auth-multi-tenant** | Organizacje | Multi-tenant, `organization_members`, `get_user_org_id()`, `is_org_admin()`, org-scoped RLS |
| **supabase-auth-whitelist** | Email whitelist | Lista dozwolonych emaili, `app_allowed_users`, `hasAccess`/`accessDenied`, Web Locks AbortError fix |

## Kluczowe zasady (wspólne)

### Problem rekursji RLS
Gdy polityka RLS sprawdza tę samą tabelę → nieskończona rekursja → 500 Internal Server Error.
**Zawsze** wynoś logikę sprawdzania do funkcji `SECURITY DEFINER`.

### Checklist nowej tabeli z RLS
1. `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`
2. Użyj `SECURITY DEFINER` helper functions (nie subqueries na tej samej tabeli)
3. `GRANT EXECUTE ON FUNCTION ... TO authenticated;` (+ `TO anon` jeśli potrzebne)
4. Testuj z symulacją JWT: `SET request.jwt.claims = '{"sub": "UUID"}'; SET role = 'authenticated';`
5. Nie ufaj SQL Editor — omija RLS

### Diagnostyka

```sql
-- Czy funkcje mają SECURITY DEFINER?
SELECT proname, prosecdef FROM pg_proc WHERE proname IN ('is_admin', 'get_user_org_id', 'is_org_admin');

-- Polityki RLS
SELECT policyname, tablename, cmd, qual FROM pg_policies WHERE schemaname = 'public';
```

| Symptom | Przyczyna | Fix |
|---------|-----------|-----|
| 500 na REST, OK w SQL Editor | Rekursja RLS | SECURITY DEFINER |
| Pusty wynik na REST | RLS blokuje | Sprawdź USING |
| 403 Forbidden | Brak GRANT | `GRANT EXECUTE ... TO authenticated` |
