---
name: project-supervisor
description: Proaktywny monitoring ekosystemu — status deployów Vercel, health Supabase (migracje, RLS), raport poranny ze wszystkich projektów. Używaj gdy użytkownik mówi "status projektów", "sprawdź deploye", "raport poranny", "co się zepsuło", "health check", "monitoring". Auto-aktywacja przy /gsd:progress jeśli dotyczy wielu projektów.
---

# Project Supervisor — Proaktywny Monitoring Ekosystemu

Nadzorca automatyczny: sprawdza deploye, bazę danych i generuje raporty z rekomendacjami.

## Kiedy używać

- **Na żądanie**: "status projektów", "sprawdź deploye", "raport poranny", "health check"
- **Proaktywnie**: Na początku dnia pracy (rano, po przerwie)
- **Po deploy**: Weryfikacja czy wszystkie projekty działają
- **Po incydencie**: Szybka diagnoza co jest broken
- **Okresowo**: Cotygodniowy przegląd zdrowia ekosystemu
- **Zdalnie**: Z telefonu przez Channels (Telegram/Discord) — Tryb 4

## Kiedy NIE używać

- Debugowanie jednego konkretnego projektu → `vercel-supabase-debugger`
- Deploy jednego projektu → `vercel-deploy`
- Sprawdzanie credentiali → `credentials-vault`
- Planowanie pracy → `/gsd:progress`

## Wymagania

- Vercel CLI (`vercel`) zalogowany
- Supabase CLI (`supabase`) zalogowany (opcjonalnie — fallback na migracje w repo)
- Dostęp do repozytoriów projektów (ścieżki z manifestów)

---

## Pipeline

### Faza 1: Skan deployów Vercel

Dla każdego projektu z manifestu (lub listy podanej przez użytkownika):

```bash
# Lista projektów z manifestów
ls ~/projekty/Project\ Master/project-master-data/manifests/*.json 2>/dev/null

# Status ostatniego deployu per projekt
vercel ls --limit 1 2>/dev/null
```

**Wynik per projekt:**

| Status | Akcja |
|--------|-------|
| READY | OK — zapisz czas deployu |
| ERROR / BUILD_ERROR | ALERT — przejdź do diagnostyki (Faza 1a) |
| BUILDING | W toku — zanotuj |
| QUEUED | W kolejce — zanotuj |
| CANCELED | Anulowany — sprawdź dlaczego |

#### Faza 1a: Diagnostyka failed deploy

Jeśli deploy failed:

1. Pobierz build log: `vercel logs <deployment-url> 2>&1 | tail -50`
2. Szukaj wzorców błędów:
   - `Type error` → TypeScript
   - `Module not found` → brakująca zależność
   - `NEXT_PUBLIC_` → brak env var w build time
   - `ERR_MODULE_NOT_FOUND` → import z nieistniejącego pakietu
   - `error Command failed` → błąd w build script
3. Wygeneruj propozycję fix w raporcie

### Faza 2: Health check Supabase

Dla każdego projektu z bazą Supabase:

#### 2a: Migracje — zsynchronizowane?

```bash
# Sprawdź lokalne migracje vs remote
cd <project-path>
ls supabase/migrations/ 2>/dev/null | wc -l
supabase migration list 2>/dev/null
```

**Flagi:**
- Lokalne migracje bez `supabase db push` → WARN
- Pliki migracji zmodyfikowane po utworzeniu → DANGER

#### 2b: RLS — aktywne na wszystkich tabelach?

Sprawdź w plikach migracji:

```bash
# Szukaj tabel BEZ RLS
grep -l "CREATE TABLE" supabase/migrations/*.sql | while read f; do
  table=$(grep "CREATE TABLE" "$f" | head -1)
  if ! grep -q "ENABLE ROW LEVEL SECURITY" "$f"; then
    echo "WARN: $f → $table — BRAK RLS"
  fi
done
```

**Opcjonalnie** (jeśli Supabase CLI dostępny):
```sql
-- Tabele bez RLS
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public'
AND tablename NOT IN (
  SELECT tablename FROM pg_tables t
  JOIN pg_class c ON c.relname = t.tablename
  WHERE c.relrowsecurity = true
);
```

#### 2c: Rozmiar bazy i usage

```bash
# Jeśli Supabase Management API dostępne
# GET https://api.supabase.com/v1/projects/{ref}/database/size
```

Fallback: sprawdź dashboard manualnie, zanotuj w raporcie.

### Faza 3: GitHub — otwarte PR i issues

```bash
# Per projekt (jeśli GitHub CLI dostępne)
cd <project-path>
gh pr list --state open --limit 5 2>/dev/null
gh issue list --state open --limit 5 2>/dev/null
```

### Faza 4: Raport

Wygeneruj raport w formacie z szablonu: [templates/report.md](templates/report.md)

**Lokalizacja raportu:**
```
~/projekty/Moje skille/reports/supervisor-YYYY-MM-DD.md
```

---

## Tryby pracy

### Tryb 1: Quick Check (domyślny)
Tylko Faza 1 (deploye) + Faza 2b (RLS). Szybki przegląd w 1-2 minuty.

Trigger: "status", "szybki check", "co jest broken"

### Tryb 2: Full Report
Wszystkie 4 fazy. Pełny raport z rekomendacjami.

Trigger: "raport poranny", "pełny przegląd", "health check"

### Tryb 3: Focus (jeden projekt)
Pełna diagnostyka jednego projektu — deploy + Supabase + GitHub.

Trigger: "sprawdź [nazwa projektu]", "status [projektu]"

### Tryb 4: Remote (Channels — Telegram/Discord)

Monitoring z telefonu przez Claude Code Channels. Sesja Claude Code działa na Mac Studio,
Ty piszesz polecenia z Telegrama i dostajesz odpowiedzi na telefon.

**Wymagania:**
- Claude Code v2.1.80+ z pluginem Telegram
- Sesja: `claude --channels plugin:telegram@claude-plugins-official --dangerously-skip-permissions`
- Mac Studio (lub desktop) nie może iść w uśpienie

**Trigger z Telegrama:** "status projektów", "sprawdź [projekt]", "co się zepsuło?"

**Co dostajesz na Telegram:**
```
📊 Raport Supervisora — 2026-03-24

✅ Hotel Demo — READY (2h temu)
✅ Content Hub — READY (4h temu)
❌ Marketing Hub — BUILD_ERROR
   → Type error: Property 'slug' does not exist
   → Fix: Dodaj slug do interfejsu Post
⚠️ Kreator Grafik — 12h od ostatniego deployu

Alerty: 1 | Deploye OK: 2/3
```

**Zastosowania:**
- Poranny check z telefonu — "raport poranny" z Telegrama
- Szybka diagnoza po incydencie — "co jest broken?" w drodze do biura
- Monitoring po deploy — "sprawdź Marketing Hub" po pushu z laptopa

**Ograniczenia:**
- Brak interaktywnego feedbacku (nie klikniesz "napraw" z Telegrama)
- Jeśli fix wymaga zatwierdzenia → agent pyta, ale musisz podejść do terminala
- Sesja musi działać — jeśli komputer uśnie, Channels się rozłączą

---

## Źródła danych

| Źródło | Jak uzyskać | Fallback |
|--------|-------------|----------|
| Lista projektów | `project-master-data/manifests/*.json` | Ręczna lista katalogów w `~/projekty/` |
| Deploy status | `vercel ls` per projekt | `gh api` + Vercel integration |
| Build logs | `vercel logs <url>` | Dashboard Vercel |
| Supabase RLS | Pliki migracji w repo | `supabase` CLI |
| GitHub PRs/Issues | `gh pr list` / `gh issue list` | GitHub API |
| Credentials | `credentials-vault` skill | `.env.local` pliki |

---

## Raport — format wyjścia

```markdown
# Raport Supervisora — [DATA]

## Podsumowanie
- Projekty sprawdzone: X
- Deploye OK: X | Failed: X | Building: X
- Tabele bez RLS: X
- Otwarte PR: X | Otwarte Issues: X

## Deploye

| Projekt | Status | URL | Czas | Uwagi |
|---------|--------|-----|------|-------|
| Hotel Demo | READY | xxx.vercel.app | 2h temu | OK |
| Content Hub | ERROR | xxx.vercel.app | 5h temu | TypeScript error |

## Alerty (wymagają akcji)

### [PROJEKT] — Deploy failed
**Błąd:** [treść błędu z logów]
**Propozycja fix:** [co zrobić]

### [PROJEKT] — Tabela bez RLS
**Tabele:** tasks, comments
**Ryzyko:** Dane dostępne bez autentykacji
**Fix:** Dodaj migrację z `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`

## Rekomendacje na dziś
1. [Najwyższy priorytet — napraw failed deploy]
2. [RLS na tabelach bez zabezpieczeń]
3. [PR do review]
```

Pełny szablon: [templates/report.md](templates/report.md)

---

## Chain of Skills

| Sytuacja | Wywołaj skill |
|----------|--------------|
| Deploy failed — potrzebna diagnoza | `vercel-supabase-debugger` |
| Brak env vars na Vercel | `credentials-vault` → `vercel-deploy` |
| Tabele bez RLS | `supabase-data-map` → dodaj migrację |
| Outdated deps (przyszły skill) | `dependency-health-check` |

---

## Pamięć skilla

Po każdym uruchomieniu zapisz krótki log w `logs/`:
- `logs/run-YYYY-MM-DD.md` — które projekty sprawdzono, co znaleziono
- Porównuj z poprzednimi logami — czy problem jest nowy czy powtarzający się

Przed uruchomieniem sprawdź `logs/` — jeśli projekt miał problem wczoraj, sprawdź go jako pierwszy.

---

## Pułapki

### 1. Vercel CLI nie zalogowany lub nieaktualny
**Objaw**: `vercel ls` zwraca "Error: Not authenticated" lub "command not found"
**Przyczyna**: CLI nie zalogowane, token wygasł, lub stara wersja
**Rozwiązanie**: `vercel login` lub `npm i -g vercel@latest`. Sprawdź wersję: `vercel --version`.

### 2. Wiele projektów Vercel na jednym repozytorium
**Objaw**: `vercel ls` pokazuje deploye innego projektu niż oczekiwany
**Przyczyna**: Repo powiązane z wieloma projektami (np. monorepo)
**Rozwiązanie**: Użyj `vercel --scope <team> --project <name>` lub `cd` do katalogu z `.vercel/project.json`.

### 3. Supabase CLI bez aktywnego projektu
**Objaw**: `supabase migration list` zwraca "no project linked"
**Przyczyna**: Brak `supabase link` w tym katalogu
**Rozwiązanie**: Fallback na analizę plików migracji w `supabase/migrations/` zamiast CLI.

### 4. RLS false positive — tabele lookup
**Objaw**: Raport flaguje tabele systemowe lub lookup tables bez RLS
**Przyczyna**: Nie każda tabela potrzebuje RLS (np. `countries`, `categories` — public read)
**Rozwiązanie**: Wyklucz znane tabele lookup z alertów. Oznacz w raporcie jako "INFO" nie "WARN".

### 5. Deploy "READY" ale strona nie działa
**Objaw**: Vercel shows READY, ale strona zwraca 500 lub blank
**Przyczyna**: Build przeszedł, ale runtime error (brak env var, Supabase down, itp.)
**Rozwiązanie**: Supervisor sprawdza status deployu, nie runtime. Jeśli user zgłasza problem mimo READY → deleguj do `vercel-supabase-debugger`.

### 6. Rate limiting Vercel API
**Objaw**: Po sprawdzeniu 10+ projektów CLI zwraca 429
**Przyczyna**: Vercel API ma rate limit na tokenie
**Rozwiązanie**: Dodaj `sleep 1` między requestami lub grupuj projekty (5 per batch).

### 7. Stare manifesty — projekty usunięte lub przeniesione
**Objaw**: Manifest wskazuje na ścieżkę projektu, ale folder nie istnieje
**Przyczyna**: Projekt przeniesiony, usunięty, lub zmieniona nazwa
**Rozwiązanie**: Sprawdź `test -d <path>` przed skanowaniem. Oznacz nieistniejące projekty w raporcie.
