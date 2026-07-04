---
name: adwokat-diabla
description: >
  Drugi model (Qwen3.6 lokalnie) przesłuchuje plan/decyzję/incydent zanim zaczniesz
  kodować. DWA TRYBY: --lateral (default, 5 najtrudniejszych pytań w różnych
  aspektach — pre-implementation review) lub --root-cause (5 Why Toyoty,
  drążenie jednej ścieżki — post-incident analysis). Aktywne pytania, nie pasywny
  review. Komplementarny do cross-model-review (review po kodzie).
  Triggery: "adwokat diabła", "przesłuchaj plan", "5 najtrudniejszych pytań",
  "zakwestionuj założenia", "stress test pomysłu", "drugi model niech zapyta",
  "sprawdź ten plan zanim zacznę", "zanim zakoduję", "5 why", "dlaczego padł",
  "root cause", "co poszło nie tak", "drąż przyczynę", "post-mortem".
license: MIT
metadata:
  version: "1.0.0"
  domain: workflow
  role: expert
  scope: review
  output-format: report
  related-skills: cross-model-review, dual-agent-review, gemini-delegation, the-fool, autoplan
---

# Adwokat diabła

Drugi model krytycznie przesłuchuje twój plan/decyzję/incydent zanim zaczniesz kodować lub propagować naprawę. Wzorzec wypracowany w projekcie ClientA (~100h pracy, 04-05.2026).

**Wartość**: anecdotal — 1 case (ClientA, 3.05.2026) gdzie Qwen wykrył 3 luki w klasyfikatorze OPZ przed implementacją. Claim "5-10 min oszczędza 5-10h debugowania" pochodzi z tego pojedynczego use case'a — wartość do potwierdzenia w kolejnych projektach. **Empirycznie (test 2026-05-04)**: precision skilla zależy od trudności planu (patrz sekcja "Znane ograniczenia").

**Po co dwa modele a nie sam Claude?** Claude pisząc plan ma wbudowany confirmation bias — kwestionując własne założenia tylko częściowo go obchodzi. Drugi model (Qwen lokalnie) nie ma tego ograniczenia, bo nie inwestował w żadną wcześniejszą decyzję.

## Kiedy używać

### `--lateral` (default) — pre-implementation review

5 najtrudniejszych pytań w **różnych aspektach** technicznych. Każde z innej kategorii (asynchroniczność, edge cases, integralność, kontrakty, fallbacks).

**Triggery:**
- Decyzja architektoniczna (struktura tabel, kontrakty API, schemat queue)
- Plan migracji (N8N → Edge Functions, Airtable → Supabase)
- Przed kosztownym batchem AI (>$10 lub >50 rekordów)
- Onboarding klienta — przesłuchać własny pomysł przed propozycją
- Plan implementacji nietrywialnej funkcji w istniejącym projekcie

### `--root-cause` — post-incident analysis (5 Why)

Inny mechanizm: drąży **jedną ścieżkę** przyczyna→skutek aż do root cause. 5 razy "dlaczego", każde pogłębiające poprzednie answer.

**Triggery:**
- Padł deploy, klient zgłasza dziwny błąd
- Regresja po zmianie
- System zachowuje się nieoczekiwanie
- Post-mortem incydentu

## Detekcja trybu

1. **Explicit flag:** `--lateral` lub `--root-cause`
2. **Auto-detekcja po keywords w prompcie usera:**
   - `--root-cause` keywords (PL): "dlaczego padł", "padł deploy", "padł cron", "regresja", "co poszło nie tak", "post-mortem", "5 why", "root cause", "drąż przyczynę", "po incydencie"
   - Jeśli żaden keyword z root-cause nie wystąpi → default `--lateral`
3. **Niejednoznaczność:** jeśli prompt zawiera oba sygnały (np. "plan napraw + dlaczego padło") → zapytaj usera explicite którego trybu chce. Nie zgaduj.

## Workflow — tryb `--lateral`

1. **Input:** użytkownik podaje plan / decyzję architektoniczną / opis problemu (przez argument, plik lub paste w rozmowie).
2. **Wywołanie modela:** Claude buduje prompt z `references/prompt-lateral.md` (sekcja "Initial prompt"), podstawia `{{INPUT}}`, woła `ask-qwen.sh` (Qwen3.6 lokalny).
3. **Prezentacja pytań userowi:** Claude pokazuje 5 pytań **wszystkie naraz** (nie po jednym — chcemy żeby user widział całość lateralnego rozkładu). Format:
   ```
   Adwokat diabła — 5 pytań (Qwen3.6):

   1. [Pytanie] *(asynchroniczność)*
      Dlaczego ważne: [1 zdanie]

   2. [Pytanie] *(edge cases)*
      ...
   ```
4. **Zbieranie odpowiedzi:** user odpowiada w rozmowie. Claude wyłącznie pośredniczy — NIE odpowiada za usera, NIE sugeruje odpowiedzi.
5. **Tura 2 (opcjonalna):** jeśli user mówi "kontynuuj" / "pogłębiamy" → Claude buduje "Follow-up prompt" z transkryptem QA, wywołuje Qwen ponownie. Max 3 pytania pogłębiające.
6. **Raport końcowy:** Claude woła Qwen z "Final report prompt" — zwraca markdown z sekcjami "Zidentyfikowane luki / Rekomendowane zmiany / Otwarte pytania". Zapisuje do `.ai/adwokat-diabla/YYYY-MM-DD-<slug>.md` (utwórz katalog jeśli nie istnieje) i wyświetla userowi.

**Maksymalnie 3 tury** (initial + 2 follow-up) — potem sumujemy.

## Workflow — tryb `--root-cause`

1. **Input:** opis incydentu (1-3 zdania: co się stało, kiedy, gdzie).
2. **Pytanie 1:** Claude wywołuje Qwen z "Initial prompt" z `references/prompt-root-cause.md`. Qwen zwraca PIERWSZE "dlaczego" — odnoszące się do najbardziej prawdopodobnej bezpośredniej przyczyny.
3. **User odpowiada** — Claude prezentuje pytanie po jednym (sekwencyjnie, nie naraz — to różni tryb 2 od trybu 1).
4. **Pytania 2-5:** Claude akumuluje transkrypt, w każdej iteracji woła Qwen z "Iteracja N" prompt, dostaje kolejne "dlaczego". Cel: pogłębianie jednej ścieżki, nie zmiana gałęzi.
5. **Stop guard + reset transkryptu:** jeśli Qwen zwróci "STOP: poprzednia odpowiedź nie pozwala drążyć dalej" → Claude prezentuje opcje (a/b) i jeśli user wybiera **inną gałąź**, Claude **OBCINA** transkrypt do iteracji N-1 (USUWA Q_N i A_N) i woła Qwen z **branch-rejection promptem** żeby zignorował odrzuconą ścieżkę. Szczegóły: `references/prompt-root-cause.md` sekcja "Reset transkryptu po wybraniu nowej gałęzi". Bez resetu Qwen wraca do śmierdzącego kontekstu.
6. **Raport końcowy** (po 5. iteracji LUB stop): Claude woła Qwen z "Final report prompt", dostaje raport z łańcuchem "1→2→3→4→5→ROOT CAUSE", systemową korektą i otwartymi pytaniami. Zapis do `.ai/adwokat-diabla/YYYY-MM-DD-postmortem-<slug>.md`.

## Backend — wybór modela

### Default: Qwen3.6 lokalnie ($0)

```bash
~/.claude/skills/adwokat-diabla/ask-qwen.sh <prompt-file-or-string> <output-file>
```

- Model: `qwen3.6:35b-a3b` (override przez `QWEN_MODEL` env var)
- Endpoint: `http://localhost:11434` (override przez `OLLAMA_URL`)
- Timeout: 180s default (override przez `QWEN_TIMEOUT`) + watchdog `TIMEOUT+10s` (wymaga `timeout` lub `gtimeout` z coreutils — `brew install coreutils` na Mac; bez nich script używa fallback `curl --max-time`)
- Temperature: 0.4 (wyższa niż review — chcemy różnorodności pytań, nie deterministycznego streszczenia)
- **Gotcha** (z globalnego CLAUDE.md): `/no_think` w prompcie + strip `<think>...</think>` defensywnie. Skrypt obsługuje to automatycznie.

### Fallback: Codex CLI

Gdy Ollama padnie (`ask-qwen.sh` zwróci exit 1 z komunikatem "Ollama niedostępne"):

```bash
codex exec "<prompt z /no_think wyrzucony, reszta bez zmian>"
```

Claude robi to automatycznie — nie pyta usera o pozwolenie. ALE musi zwalidować format — Codex (GPT) może zwrócić inną strukturę niż Qwen.

#### Walidacja formatu Codex (obowiązkowa po fallbacku)

Claude (orchestrator) MUSI zwalidować output Codex'a zanim przekaże go userowi:

**Tryb `--lateral`** — oczekiwany schemat:
- Dokładnie 5 numerowanych pytań (regex: co najmniej 5 wystąpień `^[1-9]\.`)
- Każde z linią uzasadnienia (`*Dlaczego ważne:*` lub równoważnik)

**Tryb `--root-cause`** — oczekiwany schemat:
- Dokładnie jedno pytanie (krótki tekst, kończy się `?`, max 200 znaków)
- Bez prefiksów typu "Oto pytanie:" / "Jak myślisz:"

**Procedura walidacji:**
1. Po fallbacku Claude parsuje output Codex'a regexem
2. Jeśli format niepoprawny → **re-prompt Codex** z dokładnym formatem:
   ```
   Twoja poprzednia odpowiedź nie pasuje do wymaganego formatu. Zwróć DOKŁADNIE
   w tym formacie: [...szczegółowy schemat...]. Bez dodatkowych komentarzy.
   ```
3. Jeśli po **2 próbach** nadal nie pasuje → poinformuj usera:
   > "⚠️ Fallback Codex zwrócił niespójny format po 2 próbach. Opcje: (a) eskalacja do Gemini API (~$0.05), (b) restart Ollama i powrót do Qwen, (c) anulujemy adwokat-diabla na ten problem."

**Dlaczego to ważne:** parsowanie outputu po stronie Claude (przy budowaniu raportu, follow-up promptu) zakłada strukturę Qwen. Bez normalizacji → albo silent garbage przekazany userowi, albo crash przy parsowaniu raportu końcowego.

### Eskalacja: Gemini API (opt-in, kosztowne)

**Tylko** jeśli spełniony jeden z 4 powodów (§25 globalnego CLAUDE.md):
1. Qwen + Codex dają sprzeczne odpowiedzi (oba niepewne)
2. Decyzja strategiczna nieodwracalna
3. Long-context >128k tokenów (Qwen nie udźwignie)
4. Research online z Google Grounding

Wywołanie: skill `gemini-delegation` z parametrem prompt + `--reason "<powód>"`. Claude **informuje usera krótko** dlaczego sięga po Gemini ("używam Gemini bo problem strategiczny — wybór schematu plan_versions wpływa na cały dispatcher").

Gdy nie ma jednoznacznego powodu → **NIE używaj** Gemini. Default: Qwen + ewentualnie Codex.

## Format outputu (tryb `--lateral`)

```markdown
# Raport: adwokat-diabla dla [nazwa planu]
**Data:** YYYY-MM-DD HH:MM
**Tryb:** --lateral
**Model:** qwen3.6:35b-a3b

## Zidentyfikowane luki
1. [Luka 1] — pochodzi z pytania "[skrócone pytanie]"
2. [Luka 2] — ...

## Rekomendowane zmiany w planie
- [Konkretna zmiana 1, np. "Dodaj checkpoint co 10 rekordów w batchu"]
- [Konkretna zmiana 2, np. "Zaprojektuj idempotency key dla retry"]

## Otwarte pytania (do decyzji użytkownika)
- [Pytanie 1, np. "Czy akceptujemy 5% utratę danych w przypadku partial failure?"]
```

## Format outputu (tryb `--root-cause`)

```markdown
# Raport: 5 Why dla [nazwa problemu]
**Data:** YYYY-MM-DD HH:MM
**Tryb:** --root-cause
**Model:** qwen3.6:35b-a3b

## Łańcuch przyczyn
1. **Dlaczego X?** → Bo A
2. **Dlaczego A?** → Bo B
3. **Dlaczego B?** → Bo C
4. **Dlaczego C?** → Bo D
5. **Dlaczego D?** → ROOT CAUSE: [root cause 1 zdanie]

## Systemowa korekta
[Co zmienić w PROCESIE/architekturze/konwencji żeby ta KLASA problemów nie powracała]

## Otwarte pytania
[Jeśli któreś "dlaczego" nie miało jednoznacznej odpowiedzi]
```

## Integracja z ekosystemem

| Skill | Relacja |
|---|---|
| `cross-model-review` | Komplementarny — `cross-model-review` to **post-code review** (Codex + Qwen recenzują GOTOWY kod), `adwokat-diabla` to **pre-implementation interrogation** (przed kodem) |
| `the-fool` | `the-fool` używa Claude'a do kwestionowania własnych pomysłów (5 modes) — confirmation bias. `adwokat-diabla` używa **drugiego modela** (Qwen) — bias-free |
| `dual-agent-review` | Skupia się na **kodzie** przez Claude+Codex. `adwokat-diabla` skupia się na **planach** przez Claude+Qwen |
| `autoplan` | 4 strukturalne perspektywy (growth/design/...). `adwokat-diabla` — 1 perspektywa "senior engineer" z 5 lateralnych pytań technicznych |
| `gemini-delegation` | Używany jako eskalacja (powód §25) gdy Qwen+Codex nie wystarczają |
| `cross-project-onboarder` | W nowych projektach onboarder wzmiankuje ten skill — szczególnie przed pierwszą fazą implementacji nietrywialnej |

## Znane ograniczenia (test empiryczny 2026-05-04)

Skill został przetestowany na 3 planach o różnej trudności. Wyniki:

| Plan | Charakter | Trafne pytania (rubric) | Precision |
|---|---|---|---|
| **A — solidny** | Trywialny refactor (`<Spinner>` w istniejącym komponencie, z testami RTL) | 1/5 (tylko aria-label conflict) | **20%** |
| **B — wadliwy** | Security disaster (passwords plain text w localStorage, API key w frontendzie) | 5/5 (wszystkie krytyczne) | **100%** |
| **C — pośredni** | Realistic Stripe webhook (idempotency, signature, race conditions) | 3-4/5 | **60-80%** |

**Wnioski:**

1. **Fixed-size output**: skill ZAWSZE generuje dokładnie 5 pytań, nawet na trywialnych planach. To **nie noise generator** (1 trafne na trywialnym = wartość), ale też **nie honest signal** proporcjonalny do jakości planu. Na PLAN A Qwen powinien był powiedzieć "plan solidny, 1 luka: aria-label" zamiast generować 4 spekulacyjne pytania.

2. **Precision rośnie z trudnością planu**: wartość biznesowa rośnie proporcjonalnie do złożoności i ryzyka. Trywialny code change → niska precision (20%) → overhead wątpliwy. Strategiczna decyzja → wysoka precision (60-100%) → wartość wysoka.

3. **Anecdotal value claim**: "5-10 min oszczędza 5-10h debugowania" pochodzi z 1 use case'a (ClientA klasyfikator OPZ). Generalizacja wymaga większej próbki — A/B test na 5+ realnych projektach.

4. **Recall bias**: Qwen prawdopodobnie zawsze znajdzie "coś" do skrytykowania, nawet w plain text + brak HTTPS (PLAN B z 100% trafień to nie dowód świetności skilla — to dowód że plan był ekstremalnie wadliwy).

**Implikacje praktyczne:**
- Używaj na **realnych production planach** (nietrywialnych)
- **NIE używaj** na trywialnych refactorach z testami (precision <30%, overhead nie wart)
- **Traktuj wynik jako lista hipotez do oceny**, nie jako autoritative ground truth
- **Sprawdź każde pytanie pod kątem rubric**: czy trafne (realne ryzyko nieadresowane) vs spekulacyjne (teoretyczne) vs duplikat — agent może to zrobić sam

## Anti-patterns (czego NIE robić)

- **Nie używaj `the-fool` zamiast tego** — to inny problem. `the-fool` = Claude kwestionuje siebie. `adwokat-diabla` = drugi model kwestionuje Claude'a/usera. Jeśli wartością jest brak confirmation bias → musi być `adwokat-diabla`.
- **Nie wywołuj na trywialnych zadaniach** — refactor 1 pliku z testami, literówka, jasne polecenie "zmień X na Y". Test 2026-05-04: na PLAN A precision 20%, overhead 5 min konsultacji nie wart 1 trafnego pytania.
- **Nie wywołuj automatycznie po każdym planie** — to dodatkowa runda dialogu z userem. Wywołaj gdy: (a) user prosi explicite, (b) plan dotyka §25 globalnego CLAUDE.md (krytyczna logika biznesowa, decyzja architektoniczna >1 plik), (c) Claude sam jest niepewny i sygnalizuje "warto przesłuchać".
- **Nie odpowiadaj za usera** — jeśli pytanie Qwen jest trudne, NIE wymyślaj sensownej odpowiedzi z głowy. Daj userowi czas na rzeczywistą refleksję. Wartość skilla = user musi zmierzyć się z pytaniem.
- **Nie zmieniaj gałęzi w trybie root-cause** — to nie lateral. Iteracja 4 to NIE moment na "dlaczego nie było monitoringu" gdy drążymy "dlaczego deploy padł przez timeout". Skończ jedną ścieżkę.
- **Nie akceptuj "human error" jako root cause** — drąż dlaczego człowiek mógł popełnić ten błąd (brak procesu? narzędzia? czasu na review?). Human error to symptom, nie root cause.

## Test E2E

### Tryb 1 (`--lateral`)
**Test reference:** dzisiejsza analiza "czy cron Marketing Hub potrzebny" (sesja PM 04.05 wieczór). Wnioski powinny zgodzić się z agentem PM:
- Cron jest potrzebny dla poison pill recovery
- Cron jest potrzebny dla retry timeoutowanych jobów
- Cron jest potrzebny dla initial dispatch po cold start

Jeśli skill wygeneruje 5 pytań które poprowadzą do tych samych wniosków → ✅ pass.

### Tryb 2 (`--root-cause`)
**Test case:** "Padł cron daily-digest. Ostatnio działał 7 dni temu. Logi puste."

Oczekiwany przebieg:
1. Pierwsze "dlaczego" pyta o przyczynę bezpośrednią (timeout? padło Vercel? kod się zwiesił?)
2. Iteracje 2-4 drążą jedną wybraną ścieżkę
3. Iteracja 5 powinna zakończyć się root cause typu strukturalnego ("brak alertingu na missing cron run", "brak idempotency key dla long-running jobs", etc.)

Jeśli root cause = "padło Vercel" → ❌ fail (to symptom, nie root cause). Jeśli root cause = "brak monitoringu cron health w setupie" → ✅ pass.

## Use cases (z praktyki ClientA + Marketing Hub)

1. **Pre-implementation Pipeline klasyfikatora OPZ** (3.05.2026) — Qwen wykrył: brak progu pewności, brak failover dla low-confidence, brak logiki dla "sugerowany produkt: X". Bez tej rozmowy bug złapany dopiero w batchu.
2. **Decyzja "czy cron MH potrzebny"** (4.05.2026) — Qwen wykrył poison pill recovery, retry timeoutowanych jobów, initial dispatch. Pierwotna hipoteza ("cron niepotrzebny") była błędna.
3. **Post-incident scrapy padły z timeoutem** (potencjalne) — 5 Why drąży: timeout → brak retry → brak idempotency → brak schematu queue → root cause = brak fundamentów reliability w pierwszej fazie projektu. Systemowa korekta = checklist reliability w project-scaffolder.

## Notatka od Dariusza (intencja)

> "Inny model zadaje ci dociekliwe pytania. Dzięki temu możesz wyłapywać błędy podstawowe. (...) Będzie nam jeszcze wielokrotnie potrzebny."

To zapisane jako Lekcja 4 w artykule "Sto godzin, 400 dolarów i 5 lekcji" (2026-05-04). Skill formalizuje wzorzec używany ad-hoc w sesjach ClientA.
