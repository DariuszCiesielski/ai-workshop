---
name: cross-model-review
description: >
  Automatyczna recenzja planów, kodu i decyzji architektonicznych przez Codex (GPT)
  + Qwen3.6 lokalny jako default ($0 marginal koszt). Gemini 3.1 Pro tylko jako opt-in
  eskalacja (4 powody §5 CLAUDE.md). Tryby: plan/code/strategic/adversarial. Wsparcie
  dla iterate-until-clean (max 3 cykle) i fire-and-forget background.
  Triggery: "zrecenzuj plan", "review kodu", "cross-review", "druga opinia",
  "sprawdź przed merge", "co myślą inne modele", "recenzja strategiczna",
  "wyślij do recenzji", "review przed implementacją", "adversarial review",
  "devil's advocate".
---

# Cross-Model Review — automatyczna recenzja wielomodelowa

## Kiedy używać

### RECENZUJ (warto wydać tokeny — głównie czas, marginalny koszt $0)
- Nowy feature z logiką biznesową (nie CRUD)
- Zmiana dotyka auth, RLS, płatności, kluczy API
- Migracja bazy danych
- Plan implementacji przed rozpoczęciem pracy
- Zmiana w 4+ plikach naraz
- Decyzja architektoniczna
- Integracja z zewnętrznym API
- Plan strategiczny ("conditio sine qua non", "fundament biznesowy") — **OBOWIĄZKOWO**
  z `--iterate` i ewentualnie `--with-gemini` (powód §5)

### NIE RECENZUJ (szkoda czasu)
- Fix literówki, kopiowanie, tłumaczenie
- Zmiana stylów CSS / Tailwind
- Dodanie/usunięcie importu, aktualizacja zależności
- Poprawka jednej linii w jednym pliku
- Zmiana copy/tekstu UI

### SZARA STREFA
Poinformuj użytkownika: "Zamierzam wysłać to do recenzji bo [powód]." Użytkownik może powiedzieć "daruj sobie".

## Ekonomika i routing modeli

### Default — Codex + Qwen3.6 lokalny ($0 marginal)
Każdy review uruchamia DOMYŚLNIE oba:
- **Codex CLI** (GPT przez `codex exec`) — opłacone abonamentem ChatGPT $20
- **Qwen3.6 lokalny** (Ollama HTTP `localhost:11434`) — $0, szybki (44-51 t/s)

Dwa modele = 2 niezależne perspektywy, wystarcza w 80%+ przypadków.

### Eskalacja — `--with-gemini` (opt-in, ~$0.05-0.15 per review)

Dorzuć Gemini **tylko** gdy spełniony przynajmniej JEDEN z 4 powodów (§5 CLAUDE.md):

1. **Online research wymagany** — plan referencyjny do zewnętrznych źródeł, świeże standardy, dokumentacja Google/Workspace. Qwen offline, Codex bez realnej web search. Tylko Gemini Grounding.
2. **Long-context >128k tokenów** — Qwen ma 128k, Codex zazwyczaj 200k, Gemini 1M. Konieczne dla wielkich dokumentów.
3. **Deliverable dla klienta** gdzie jakość PL językowa krytyczna — oferta, raport, email, propozycja umowy.
4. **Stawka wysoka** — decyzja nieodwracalna, koszt duży, "fundament biznesowy". Wtedy 3-model warto.

Brak żadnego z 4 → **NIE pytaj usera "czy Gemini?"**, lec bez. Pytanie samo w sobie obciąża.

### Komunikacja kosztu PRZED uruchomieniem (preflight)

**ZAWSZE** podaj koszt 1 zdaniem zanim uruchomisz review. Format:

- Domyślnie: `Uruchamiam review: Codex + Qwen lokalny ($0 marginal). — START.`
- Z Gemini: `Uruchamiam review: Codex + Qwen + Gemini (powód: [konkretny]). Szac. ~$0.10. — START.`
- Z iterate: `Uruchamiam review iteracyjny (max 3 cykle): Codex + Qwen lokalny. — START.`

User może powiedzieć "stop" zanim wystartujesz.

## Tryby review

### 1. Plan Review (`plan`)
Standardowa neutralna recenzja przed implementacją.

### 2. Code Review (`code`)
Recenzja diff przed merge.

### 3. Strategic Review (`strategic`)
Duże decyzje architektoniczne, nowe projekty, "conditio sine qua non".

### 4. Adversarial Plan Review (`adversarial`) — devil's advocate
Ostrzejsza wersja `plan`. Inny prompt: "wymyśl 5-7 sposobów w jaki ten plan zawiedzie".
Skupiony na: race conditions, edge cases skali, security holes, time zone bugs,
hidden dependencies, halucynacje o zewnętrznych projektach. Bez chwalenia.

## Wzorce wykonania

### Wzorzec A — Single cycle (default)

```
1. Preflight (komunikacja kosztu) → user może zatrzymać
2. Bash run_in_background:true dla Codex (codex exec)
3. Bash run_in_background:true dla Qwen (qwen-review.sh)
4. Czekaj na oba → Read oba pliki → porównaj → raport
```

### Wzorzec B — `--iterate` iterate-until-clean (max 3 cykle)

Dla strategic/adversarial gdy plan musi być "domknięty":

```
iter = 0
while iter < 3:
  1. Run Codex + Qwen review na plan_v_n
  2. Parse structured verdict (header w odpowiedzi):
     STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]
  3. Jeśli oba modele = GO_NO_BLOCKING_ISSUES → stop, DOMKNIĘTE
  4. Jeśli któryś NO_GO lub GO_WITH_CHANGES → Claude rewrites plan z uwagami → iter++

if iter == 3 and not domknięte:
  Sygnał: "Plan po 3 cyklach nie domknął się. Może być fundamentalnie zły.
  Decyzja użytkownika: continue / abandon / radykalnie przepisz."
```

Wymóg dla recenzentów: **zacząć odpowiedź od linii** `STATUS: <verdict>`. Format wymuszony w promptcie.

### Wzorzec C — Fire-and-forget background

Skill emituje `review_id` (timestamp + temat) i zwraca natychmiast. Agent kontynuuje implementację innych kroków. Notyfikacja przez task hook gdy pliki istnieją.

```
1. Preflight + fire bash background dla każdego modelu
2. Zwróć agentowi:
   - review_id
   - lista output_files: [.ai/reviews/<id>-codex.md, ...-qwen.md]
   - estimated wait: ~5-8 min
3. Agent kontynuuje inne todos
4. Sprawdzaj okresowo czy wszystkie output_files istnieją (lub agent dostaje notyfikację)
5. Po complete: Read + porównaj + raport
```

Używaj gdy: implementacja innego kroku jest możliwa równolegle z review.
Nie używaj gdy: review blokuje wszystko (`--iterate` żywo decyduje plan).

## Universal Prompt Preamble (OBOWIĄZKOWO wstaw do KAŻDEGO promptu review)

**Dodano 2026-05-04** po lekcji: AI reviewerzy domyślnie estymują w "developer days" (~5 dni/sprint), co jest 5-10× nadmiarem dla workflow operatora (LLM + batch tools + zrównoleglenie). Bez tego preamble każdy review zwraca timeline który jest fundamentalnie błędny — operator dostaje rekomendację "wydłuż timeline o 30%" gdy realnie powinien skrócić o 80%.

**Wstawiaj jako PIERWSZE linie promptu, PRZED instrukcjami review** (Plan/Code/Strategic/Adversarial — wszystkie tryby).

```text
KONTEKST OPERATORA (estymaty):
- Pracujemy z LLM (Claude Code, Codex CLI, lokalne Qwen3.6/Mistral) + batch tools (Firecrawl, Inngest, MCP servers).
- Tempo realnej pracy 5-10× szybsze niż klasyczne "developer days".
- ESTYMUJ W GODZINACH (h) realnej pracy AI+człowiek, NIE w dniach roboczych ani sprintach.
- Klasyczny "3 dni dev" = ~2-4h naszej pracy. "1 sprint" = ~4-8h.
- NIE zaokrąglaj w górę "z bezpieczeństwa" — zaufaj że LLM+narzędzia robią to szybciej.
- Faza/etap > 8h realnej pracy = sygnał do podziału na sub-fazy.
- Jeśli spec używa dni — SKORYGUJ jego estymaty na godziny w swojej rekomendacji explicite.
- Jeśli istniejący kod (np. SOTA RAG OCR pipeline, hybrid_search) jest do reuse — szacuj 0h dla tej części, nawet jeśli "klasyczny dev" by ją budował od zera.
```

`qwen-review.sh` automatycznie wstrzykuje ten preamble (od commitu 2026-05-04) — opt-out przez `CROSS_MODEL_NO_PREAMBLE=1`.

Dla `codex exec` i `delegate.py gemini` — Claude jako operator skilla MUSI ręcznie skleić preamble + user prompt. Wzorzec: `"$(cat ~/.claude/skills/cross-model-review/PREAMBLE.txt)\n\n${USER_PROMPT}"`.

## Konkretne komendy

### Plan Review (Codex + Qwen, default)

```bash
# Codex (background)
codex exec \
  -c model_reasoning_effort='"high"' \
  --full-auto \
  -o .ai/reviews/YYYY-MM-DD-<temat>-codex.md \
  "Przeczytaj plik PLAN.md w tym repozytorium i zrecenzuj go jako niezależny recenzent.
ZACZNIJ ODPOWIEDŹ OD LINII: STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]
Następnie:
1) Czy plan jest realistyczny i kompletny?
2) Jakie są największe ryzyka?
3) Co pominięto?
4) Czy kolejność kroków ma sens?
5) Jakie zmiany rekomendujesz?
Bądź krytyczny. Nie chwal — szukaj problemów."

# Qwen lokalny (background)
~/.claude/skills/cross-model-review/qwen-review.sh \
  PLAN.md \
  "Jesteś niezależnym recenzentem. ZACZNIJ ODPOWIEDŹ OD LINII: STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]
Następnie odpowiedz: realizm, ryzyka, pominięcia, kolejność, rekomendacje. Bądź krytyczny." \
  .ai/reviews/YYYY-MM-DD-<temat>-qwen.md
```

### Plan Review + `--with-gemini` (eskalacja)

Dorzuć tylko gdy spełniony 1 z 4 powodów. Komunikuj powód w preflight.

```bash
python3 ~/.claude/skills/gemini-delegation/delegate.py \
  --context-file PLAN.md \
  --output .ai/reviews/YYYY-MM-DD-<temat>-gemini.md \
  "Jesteś niezależnym recenzentem. ZACZNIJ ODPOWIEDŹ OD LINII: STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]
Następnie odpowiedz: realizm, ryzyka, pominięcia, kolejność, rekomendacje. Bądź krytyczny."
```

### Adversarial Review (`adversarial` mode)

Inny prompt — ostrzejszy:

```
"ZACZNIJ ODPOWIEDŹ OD LINII: STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]

Jesteś devil's advocate. Wymyśl 5-7 konkretnych sposobów w jaki ten plan ZAWIEDZIE.
Skup się na:
- race conditions, concurrent access bugs
- edge cases skali (10× więcej danych, 100× więcej userów)
- security holes (injection, RLS bypass, secret leakage)
- time zone bugs, daylight saving, leap years
- hidden dependencies (zewnętrzne projekty, ich licencje, ich downtime)
- halucynacje o zewnętrznych projektach (czy 'X' faktycznie istnieje?)
- assumptions ukryte za 'oczywistym' krokiem

Każdy scenariusz: nazwa + 1-2 zdania jak doprowadza do failure + co konkretnie zmienić.
NIE chwal. NIE łagodź. Zakwestionuj każde założenie."
```

### Code Review (`code` mode)

```bash
git diff main...HEAD > /tmp/review-diff.txt

# Codex (natywny review mode)
codex review \
  -c model_reasoning_effort='"high"' \
  --base main \
  -o .ai/reviews/YYYY-MM-DD-<temat>-codex.md

# Qwen lokalny
~/.claude/skills/cross-model-review/qwen-review.sh \
  /tmp/review-diff.txt \
  "Przejrzyj diff i oceń: bugi, security, edge cases, jakość kodu.
ZACZNIJ ODPOWIEDŹ OD LINII: STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]
Skup się na problemach, nie pochwałach." \
  .ai/reviews/YYYY-MM-DD-<temat>-qwen.md
```

## Obsługa błędów

| Sytuacja | Akcja |
|---|---|
| Codex limit/timeout | "Codex niedostępny (limit). Kontynuuję z Qwen." |
| Qwen offline (Ollama down) | "Qwen lokalny niedostępny — uruchom `ollama serve`. Kontynuuję z Codex." |
| Gemini error/limit | "Gemini niedostępny. Lec bez (był opt-in)." |
| Wszyscy down | "Brak zewnętrznych recenzentów. Recenzja tylko po stronie Claude." |

NIE retry w pętli. NIE eskalacja na Gemini gdy Qwen padł — uruchom `ollama serve` zamiast tego.

## Format raportu końcowego

Zapisz do `.ai/reviews/YYYY-MM-DD-<temat>-summary.md`:

```markdown
## Recenzja: <temat>
Data: YYYY-MM-DD | Tryb: plan/code/strategic/adversarial
Iteracja: 1/1 (lub n/3 dla --iterate)

### Recenzenci
- Codex (GPT): ✅ STATUS=GO_WITH_CHANGES (Xs) | ❌ niedostępny (powód)
- Qwen3.6 lokalny: ✅ STATUS=NO_GO (Xs, Xt/s) | ❌ niedostępny (powód)
- Gemini 3.1 Pro: ⏸ pominięty (brak powodu §5) | ✅ STATUS=GO_NO_BLOCKING_ISSUES (powód: [konkretny])

### Werdykt zbiorczy
[Najgorszy ze STATUS-ów. NO_GO > GO_WITH_CHANGES > GO_NO_BLOCKING_ISSUES]

### Zgodność (oba/wszyscy się zgadzają)
- [punkt — zwięźle, 1 linia]

### Rozbieżności
| Temat | Codex | Qwen | (Gemini) | Rekomendacja |
|-------|-------|------|----------|--------------|
| ...   | ...   | ...  | ...      | [kto ma rację i dlaczego] |

### Unikalne spostrzeżenia
- **Tylko Codex:** [punkt]
- **Tylko Qwen:** [punkt]
- **Tylko Gemini** (jeśli był): [punkt]

### Decyzja
[Co naprawić, co OK, co wymaga decyzji użytkownika]
```

### Zasady porównania
- **Obiektywnie** — jeśli któryś recenzent ma rację, przyznaj wprost
- **Bez ego** — nie faworyzuj swojej (Claude) perspektywy
- **Konkretnie** — "Rekomendacja: podejście Qwen, bo [powód]", nie "oba mają zalety"
- **Użytkownik decyduje** — przedstaw rekomendację, nie implementuj bez zatwierdzenia

## Relacja do innych skilli

- **Zastępuje:** `dual-agent-review` (manualne pośrednictwo)
- **Komplementarne:** `/codex:adversarial-review` (plugin OpenAI, single-model, ad-hoc) — używaj dla małych decyzji bez wagi strategicznej
- **Używa:** `delegate.py` z `gemini-delegation` (gdy `--with-gemini`)
- **Używa:** `qwen-review.sh` w tym samym katalogu (Ollama HTTP)

## Konfiguracja

- **Codex CLI:** `/opt/homebrew/bin/codex` (v0.111.0+), reasoning override `high` przy review
- **Qwen3.6:** Ollama HTTP `localhost:11434`, model `qwen3.6:35b-a3b` (override env: `QWEN_MODEL`)
- **Gemini API Key:** `GOOGLE_GEMINI_API_KEY` w credentials vault — używaj **tylko** przy spełnieniu 1 z 4 powodów
- **Wyniki:** `.ai/reviews/` w katalogu projektu (gitignore'd)

## Lessons Learned

### Z F1 Fact Checker (2026-04-26)

- **Cross-model review wykrywa unikalne bugi per model:** w F1 Codex znalazł ELI format bug, Gemini Schrems II nuance, Qwen async architecture. Każdy unikalnie. Pominięcie któregokolwiek = utrata ~33% wykrytych issues.
- **Empiryczny smoke test obowiązkowy obok review:** review łapie strategiczne błędy, ale integracyjne (np. SAOS %2F encoding) tylko `curl` to wykryje.
- **Strukturyzowany STATUS w nagłówku odpowiedzi ułatwia parsowanie:** wymóg `STATUS: GO|NO_GO` na pierwszej linii pozwala na automatyczne iterate-until-clean bez NLP.

### Z Przetargi AI rework (2026-05-04) — ESTYMATY W GODZINACH

**Problem:** Qwen3.6 review specu Przetargi AI zwrócił "skoryguj timeline z 12-16 dni na 18-22 dni" (= +30%). Operator pracuje w workflow LLM+batch tools gdzie realne tempo jest 5-10× szybsze niż klasyczne developer days. Faktyczna realna estymata to ~6-10 godzin pracy AI+human, nie ~20 dni. Naruszenie §17 globalnego CLAUDE.md przez AI reviewera (który nie czyta operator preferences).

**Rozwiązanie wdrożone:** `PREAMBLE.txt` + auto-injection w `qwen-review.sh` + sekcja `## Universal Prompt Preamble` w SKILL.md. Każdy review od 2026-05-04 dostaje explicit context o tempie pracy LLM+batch tools i wymóg estymowania w godzinach.

**Anti-pattern do uniknięcia:** "Plan musi być realistyczny dla typowego developera" → zignoruj, my NIE jesteśmy typowym developerem. Reviewer który zwraca estymaty w "developer days/sprintach" wymaga korekty.

**Sygnał ostrzegawczy w wyniku review:** jeśli widzisz "X dni/sprintów" w rekomendacji — przelicz: 1 sprint = ~4-8h naszej pracy, 1 dzień = ~1-2h. Korekta inline w syntezie.
