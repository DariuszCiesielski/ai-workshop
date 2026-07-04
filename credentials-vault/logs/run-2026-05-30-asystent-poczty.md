# credentials-vault run — 2026-05-30 — Asystent Poczty E-mail

## Zapisane
- Projekt credentials.env utworzony: SUPABASE_PROJECT_REF, URL, ANON_KEY, SERVICE_ROLE_KEY, ACCESS_TOKEN (sbp_***), DB_PASSWORD.
- chmod 600 OK. owner:personal (instancja SaaS Dariusza).

## Weryfikacja połączenia
- anon key: rest/v1/nonexistent -> HTTP 404 (auth OK, tabela nie istnieje). Root /rest/v1/ -> 401 (PostgREST OpenAPI root zablokowany — normalne).
- service_role: /rest/v1/ -> HTTP 200 (pełny dostęp). Klucze 100% poprawne.
- ANON JWT: ref=ewgbihtrajkmusgsivfa, ważny do 2036, iat 2026-05-30 (świeży projekt).

## GOTCHA (ważne dla następnych sesji)
- MCP Supabase (claude.ai) NIE ma uprawnień do projektu ewgbihtrajkmusgsivfa
  (get_project -> "You do not have permission"). Projekt poza OAuth claude.ai.
- => Migracje przez Supabase CLI (supabase link + PAT) lub psql (DB_PASSWORD), NIE przez MCP apply_migration.
- DB_PASSWORD zawiera `!` -> w shell ZAWSZE single quotes.
