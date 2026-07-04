---
name: canary
description: Post-deploy monitoring — smoke test krytycznych URL, console errors, baseline comparison, regression alerting po deployu na Vercel. Trigger automatyczny po `vercel deploy --prod` / `git push main` (gdy dotyczy Vercel projektu) lub manual: "monitoruj deploy", "canary check", "sprawdź deploy", "post-deploy verify", "/canary".
---

# Canary — Post-deploy Monitoring

Automatyczne wykrywanie regresji po deploy. Reaguje **szybko** (minuty po pushu, nie dni przy telefonie od klienta). Pokrywa 22 SaaS-y na Vercel + Supabase.

## Kiedy używać

- **Automatycznie** po `git push main` w projekcie powiązanym z Vercel deploy
- **Automatycznie** po `vercel deploy --prod`
- Na żądanie: "canary check", "sprawdź deploy", "monitoruj deploy", "post-deploy verify"
- Po krytycznych zmianach infrastruktury (Edge Function, migracja Supabase, env vars rebuild)

## Kiedy NIE używać

- Preview deploy / branch preview (oczekiwany inny URL, fałszywe alerty regression)
- Push do gałęzi innej niż main (preview, nie prod)
- Zmiany wyłącznie w `.md` / docs / handoffs (brak runtime impact)
- User mówi "pomiń canary", "skip verify", "tylko commit"

## Wymagania wejściowe

Per projekt potrzebne (skill sam to wykryje, brakujące prosi raz):
- **prod_url** — np. `https://project-master-nine-omega.vercel.app` (alias produkcyjny, NIE direct deploy URL → maskowane przez Vercel SSO challenge, lesson [2026-04-27])
- **critical_urls** — lista 3-7 URL pod `prod_url` (homepage, dashboard, jeden API endpoint, jedna chroniona ścieżka)
- Opcjonalnie: **vercel_project_id** dla `vercel ls` filtrowanego
- Opcjonalnie: **TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID** w `~/.claude/.credentials-global.env` (alert zewnętrzny)

Konfiguracja per-projekt: `.canary/config.json` w katalogu projektu:
```json
{
  "prod_url": "https://project-master-nine-omega.vercel.app",
  "critical_urls": [
    {"path": "/", "expect_status": 200, "expect_text": "Project Master"},
    {"path": "/dashboard", "expect_status": [200, 302], "auth_required": true},
    {"path": "/api/v1/cron/keepalive", "expect_status": 401, "auth_header_check": true}
  ],
  "vercel_project_id": "prj_...",
  "baseline_path": "~/.claude/canary-baselines/project-master.json"
}
```

Jeśli `.canary/config.json` brak — wygeneruj na podstawie `vercel ls` + 3 najbardziej oczywiste URL (`/`, `/dashboard`, jeden cron) i zapytaj użytkownika o akceptację przed pierwszym uruchomieniem.

## Faza 1 — Vercel deploy status (~10s)

```bash
vercel ls --json 2>&1 | jq '.[0] | {state, url, createdAt, target}'
```

**Decyzja:**
- `state: "READY"` + `target: "production"` → przejdź do Fazy 2
- `state: "BUILDING"` → poczekaj 30s, retry max 3× (build trwa)
- `state: "ERROR"` → STOP, fail fast: `vercel logs <deploy_id> --output raw 2>&1 | tail -50`, raport, exit
- `state: "QUEUED"` → poczekaj 60s, retry

Brak Vercel CLI lub brak projektu na Vercel → pomiń Fazę 1, idź do Fazy 2 (curl mimo wszystko).

## Faza 2 — HTTP smoke test (~30s)

Per każdy URL z `critical_urls`:
```bash
curl -s -o /dev/null -w "%{http_code} %{size_download} %{time_total}\n" \
  --max-time 15 \
  "https://prod_url/path"
```

**Walidacja:**
- HTTP code zgodny z `expect_status` (number lub array)
- Size_download > 100 bajtów (chroni przed pustą odpowiedzią z error edge'a)
- `expect_text` — pobierz body (`curl -s "url"`), grep czy fragment występuje (zabezpieczenie przed "200 OK ale strona biała")

**Detect anomalii:**
- HTTP 200 ale rozmiar 50% mniejszy niż baseline → flag (możliwe że LCP element zniknął)
- HTTP 401 + cookie `_vercel_sso_nonce` → to **Vercel SSO challenge**, nie auth aplikacji. Sprawdzasz **direct deploy URL** zamiast aliasu produkcyjnego (lesson [2026-04-27]). Przełącz na alias z `vercel ls`.
- HTTP 5xx → **regression**, eskalacja do Fazy 5

## Faza 3 — Browser smoke test (~60s, opcjonalnie)

Tylko jeśli Playwright MCP dostępne (`mcp__plugin_playwright_playwright__*`). Pomiń jeśli brak — Faza 2 wystarcza w 80% przypadków.

Per URL z `critical_urls` gdzie `auth_required=false`:
1. `browser_navigate` na URL
2. `browser_wait_for` (text "loaded" / 3s timeout)
3. `browser_console_messages` — filter `level == "error"` (warnings ignoruj)
4. `browser_network_requests` — filter `status >= 400` z domeny aplikacji (zewnętrzne CDN ignoruj)

**Alarmy:**
- Console errors > 0 (ignoruj `Failed to load resource: ...favicon.ico`, `extensionState.js`)
- Failed network requests do `/api/*` aplikacji
- `browser_take_screenshot` przy fail dla diagnostyki (zapisz do `.ai/canary/screenshots/<timestamp>-<path>.png`)

Auth-protected URL — pomiń (kanary bez session cookie tylko mierzy czy 302 do logina dochodzi, NIE czy dashboard się renderuje).

## Faza 4 — Baseline comparison (~10s)

Read baseline z `~/.claude/canary-baselines/<project_name>.json` (last successful canary):
```json
{
  "last_run": "2026-04-27T16:30:00Z",
  "deploy_id": "dpl_xyz",
  "urls": [
    {"path": "/", "status": 200, "size": 45230, "first_byte_ms": 180}
  ]
}
```

**Compare:**
- Status code drift (było 200, teraz 500) → regression
- Size drift > 50% → flag (możliwa zmiana CSS/JS bundle zauważalnie)
- First byte > 2× baseline → flag (cold start lub regression Edge Function)

**Update baseline TYLKO gdy CAŁY canary przeszedł** (wszystkie URL OK, brak console errors). Inaczej baseline nie odzwierciedla "ostatniego dobrego stanu".

Brak baseline (pierwszy run) → utwórz, pomiń compare, mark "baseline initialized".

## Faza 5 — Alert na regression

Jeśli **jakikolwiek** check failuje:

### A) Telegram (jeśli credentials dostępne)
```bash
TG_TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" ~/.claude/.credentials-global.env | cut -d= -f2-)
TG_CHAT=$(grep "^TELEGRAM_CHAT_ID=" ~/.claude/.credentials-global.env | cut -d= -f2-)

if [[ -n "$TG_TOKEN" && -n "$TG_CHAT" ]]; then
  curl -s "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT}" \
    -d "parse_mode=Markdown" \
    -d "text=🚨 *CANARY FAIL* — \`${PROJECT}\`%0A%0AURL: ${FAILED_URL}%0AStatus: ${STATUS}%0AExpected: ${EXPECTED}%0A%0ADeploy: ${DEPLOY_URL}"
fi
```

### B) Brak Telegram → ostrzeżenie w stdout
Wyświetl w odpowiedzi do user:
```
🚨 CANARY REGRESSION (alert Telegram nieskonfigurowany — dodaj TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID do ~/.claude/.credentials-global.env)

Project: <name>
URL: <failed_url>
Status: <actual> (expected <expected>)
Deploy: <deploy_url>
Detail: <error_snippet>
```

### C) Auto-rollback?
**NIE.** `/canary` raportuje, NIE rolluje samo. Decyzja rollback należy do użytkownika (może być świadoma zmiana, np. obniżenie API surface). Skill zaproponuje komendę `vercel rollback <previous_deploy_id>` ale jej nie odpala.

## Raport (zawsze, success i fail)

Na końcu wygeneruj raport markdown w stdout:

```markdown
## Canary Report — <project> @ <ISO timestamp>

**Deploy:** <deploy_id> (<state>) — <prod_url>
**Build time:** <Xs> | **Canary time:** <Ys>

### URL checks
| Path | Status | Size | TTFB | vs Baseline |
|---|---|---|---|---|
| / | ✅ 200 | 45 KB | 180ms | OK |
| /dashboard | ✅ 302 | 0 B | 90ms | OK |
| /api/v1/cron/keepalive | ✅ 401 | 70 B | 120ms | OK |

### Browser console (4 URL sprawdzonych)
| Path | Errors | Failed requests |
|---|---|---|
| / | 0 | 0 |
| /pricing | 0 | 0 |

### Verdict
✅ **PASS** — baseline updated to deploy `<deploy_id>`
❌ **FAIL** — alerts sent, baseline NOT updated, ostatni dobry deploy: `<previous>`
```

Opcjonalnie zapis do `.ai/canary/<YYYY-MM-DD-HHMM>.md` w katalogu projektu (audit trail dla weekly review).

## Pułapki

### ❌ Direct deploy URL zamiast production alias
**Objaw:** wszystko zwraca 401 + nagłówek `set-cookie: _vercel_sso_nonce` mimo że apka jest publiczna
**Przyczyna:** Vercel deployment protection (SSO) na URL `<project>-<hash>.vercel.app`
**Rozwiązanie:** ZAWSZE używaj production alias (`<project>.vercel.app` lub custom domain). Jeśli `.canary/config.json` ma direct URL → flag i poproś o korektę. Lesson [2026-04-27].

### ❌ Vercel Cron z 405 Method Not Allowed
**Objaw:** `/api/v1/cron/*` zwraca 405, nie 200/401
**Przyczyna:** Endpoint obsługuje tylko POST a Vercel Cron wysyła GET (lesson [2026-04-17])
**Rozwiązanie:** Cron endpointy muszą mieć `export const GET = POST` lub osobny GET handler. Canary flag: `expect_status: 401` (z auth) lub `200` (open).

### ❌ ESM/CJS crash maskowany przez SSO
**Objaw:** `vercel ls` mówi READY, ale `/api/v1/*` rzuca 500 ERR_REQUIRE_ESM
**Przyczyna:** Build OK, runtime crash. SSO challenge na direct URL ukrywa to (lesson [2026-04-27])
**Rozwiązanie:** Faza 2 ZAWSZE na production alias. Faza 3 (browser) wykryje napewno.

### ❌ False positive na console.error w 3rd-party
**Objaw:** Hotjar/GA/Stripe loguje błędy autoload do console
**Przyczyna:** Domyślny filter `level=error` łapie ich preflight CSP/cookie warnings
**Rozwiązanie:** Whitelist patterns w `.canary/config.json`:
```json
"ignore_console_patterns": ["hotjar.com", "googletagmanager", "stripe.com/v3"]
```

### ❌ Baseline drift przy świadomych zmianach
**Objaw:** Po feature wdrażającym CSS dark mode `size` rośnie o 60% → flag regression
**Przyczyna:** Baseline jest "ostatnim dobrym" ale rzeczywiste wartości się ZMIENIŁY
**Rozwiązanie:** Po świadomej zmianie scope: `rm ~/.claude/canary-baselines/<project>.json` przed canary → reset baseline pierwszym successful run.

### ❌ Cold start Edge / Lambda po dłuższej przerwie
**Objaw:** TTFB 5s+ na pierwszym hicie, baseline mówił 200ms
**Przyczyna:** Vercel uśpił funkcję, pierwsze odpalenie po deployu = cold
**Rozwiązanie:** Faza 2 — pre-warm: pierwsze 2 sekundy curli ignoruj (warmup), mierz dopiero 3 i 4.

### ❌ Smoke test passuje ale apka popsuta dla zalogowanych
**Objaw:** `/` zwraca 200, ale po zalogowaniu dashboard rzuca 500
**Przyczyna:** Faza 2 testuje bez session, Faza 3 (Playwright) testuje też bez session
**Rozwiązanie:** Dla apki z auth-locked dashboard, dodaj scenariusz z `APP_LOGIN_EMAIL/PASSWORD` z `~/.claude/.credentials-global.env`. Skill zaloguje się + zweryfikuje render dashboardu. To opcjonalne (Faza 3+ "authed walkthrough").

## Decyzje projektowe

- **Brak alertu jeśli wszystko OK** — szum vs sygnał. Tylko regressions powiadamiamy.
- **Telegram > email** — Dariusz operuje na Telegram dla automation alerts (lesson MEMORY 17.04).
- **Baseline w `~/.claude/canary-baselines/`** (per użytkownik, nie per repo) — żeby nie zaśmiecać projektu, plus żeby dwa różne klony repo dzieliły baseline.
- **NIE auto-rollback** — decyzja człowieka, zwłaszcza dla zmian deliberatecnie zmieniających shape API/UI.
- **NIE pisz do CI/CD** — to skill agentowy, nie GitHub Action. Jeśli kiedyś chcemy CI variant, osobne narzędzie.
