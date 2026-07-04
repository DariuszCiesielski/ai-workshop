# Źródła danych — Project Supervisor

## Manifesty projektów

Główne źródło prawdy o projektach w ekosystemie:

```
~/projekty/Project Master/project-master-data/manifests/*.json
```

Każdy manifest zawiera:
- `slug` — unikalna nazwa projektu
- `manual.repo_path` — ścieżka do repozytorium
- `manual.vercel_project` — nazwa projektu w Vercel (opcjonalnie)
- `manual.supabase_project` — ref projektu Supabase (opcjonalnie)
- `manual.skills_active` — aktywne skille
- `manual.skills_needed` — potrzebne skille

## Vercel CLI — komendy diagnostyczne

```bash
# Zaloguj się
vercel login

# Lista projektów
vercel projects ls

# Ostatni deploy (w kontekście projektu)
cd <project-path> && vercel ls --limit 1

# Logi deployu
vercel logs <deployment-url> 2>&1 | tail -50

# Env vars
vercel env ls

# Szczegóły deployu
vercel inspect <deployment-url>
```

## Supabase CLI — komendy diagnostyczne

```bash
# Status migracji
cd <project-path> && supabase migration list

# Link do projektu
supabase link --project-ref <ref>

# Status DB
supabase db status
```

## GitHub CLI — komendy

```bash
# PR otwarte
cd <project-path> && gh pr list --state open --limit 5

# Issues otwarte
cd <project-path> && gh issue list --state open --limit 5

# Ostatnie commity
git log --oneline -5
```

## Fallbacki

Gdy CLI nie jest dostępne:

| Narzędzie | Fallback |
|-----------|----------|
| Vercel CLI | Sprawdź `.vercel/project.json` + `vercel.json` w repo |
| Supabase CLI | Analizuj pliki `supabase/migrations/*.sql` |
| GitHub CLI | `git log`, `git remote -v` |
| Manifesty | Skanuj `~/projekty/*/` po plikach konfiguracyjnych |
