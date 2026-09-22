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

### Opcjonalny trzeci głos lokalny — `gpt-oss:20b` ($0, dodane 2026-08-20)

Gdy recenzowany plan/dokument opiera się na **faktach** (polskie identyfikatory, prawo, finanse,
liczby, daty) — dołóż trzeciego recenzenta lokalnego: `gpt-oss:20b` przez Ollamę.
Pilot 20.08 (zadania ze znaną prawdą): gpt-oss 5/5, qwen3.6 3/5 (m.in. znów „NIP = 11 cyfr").
Raport: `PM/.ai/research/piloty-perelki-2026-08-20.md`.

- Wywołanie jak Qwen (Ollama HTTP `localhost:11434`), model `gpt-oss:20b`.
- **Gotcha:** `think:false` NIE wyłącza rozumowania; przy małym `num_predict` thinking zjada
  budżet i wraca PUSTA odpowiedź → zawsze `num_predict ≥ 8000`. Pytania otwarte bywają wolne (20-90 s).
- To nadal NIE jest źródło faktów (§ reguła 11.08 — żaden model nie jest) — to trzecia
  perspektywa, która częściej łapie cudze błędy faktograficzne.
- NIE dokładaj przy recenzjach czysto architektonicznych/kodowych — tam Codex+Qwen wystarczą.
- Wariant chmurowy (dane NIEwrażliwe, dopóki promo żyje): `gpt-oss:120b` / `minimax-m3` przez **Ollama Cloud** (klucz `OLLAMA_PROMO` w skarbcu; odpowiedzi 0,6–1,6 s — pomiar 16.08). Przy 403 → promo wygasło, wróć na lokalny 20b.

### Stały trzeci recenzent — DeepSeek V4 Flash przez OpenRouter (~$0,002/recenzję; decyzja Dariusza 2026-08-27)

Przy recenzjach **strategicznych, planów i decyzji o realnych konsekwencjach** dokładaj domyślnie trzeci głos:
`deepseek/deepseek-v4-flash` przez OpenRouter. Podstawa: pomiar 20.08 (11/11 obiektywne + 14/15 pamięć faktów —
bije wszystkie lokalne) + próba w roli recenzenta 16.08 (jakość ≈ qwen3.8 + sam dodaje sekcję „czego plan nie mierzy").

- **Klucz:** `OPENROUTER_API_KEY_PROMO` ze skarbca (`~/.claude/shared-credentials.env`); przy 401/402 → klucz `_STALY` (koszt groszowy także na stałym). Gotcha: wartość w skarbcu bywa w cudzysłowach — strip, inaczej 401 „Missing Authentication header".
- **ZAWSZE przypnij dostawcę** (lekcja 10.08 — AUTO-routing losuje silnik, pierwszy bieg trafił na fp4):
  `"provider": {"only": ["DeepInfra"], "allow_fallbacks": false}` (fp8; zapasowe fp8: CoreWeave, Novita, Parasail).
  Oficjalny DeepSeek jako dostawca ZABLOKOWANY polityką konta (trenuje na danych) — nie próbować.
- **Granica danych:** DeepInfra = chmura US → dane wrażliwe klientów / sekrety NIE idą tą drogą (recenzje takich materiałów = tylko Codex + lokalne).
- **NIE dokładaj** przy drobnych recenzjach kodu/1 pliku (Codex+Qwen wystarczą — trzeci głos to szum) ani jako SĘDZIEGO ze scoringiem (ta rola wymaga biegu kontrolnego na znanym zestawie — lekcja 12.08; recenzent ≠ sędzia).
- Preflight: `Uruchamiam review: Codex + Qwen + DeepSeek V4 Flash (~$0,002). — START.`

### Recenzja DOKUMENTÓW PROJEKTOWYCH — Qwen + GLM 5.3 Flash przez OpenRouter (rutyna od 2026-09-02, polecenie Dariusza; globalny CLAUDE.md §25.2)

Karta projektu (nowa/aneks), spec w `.ai/specs/`, nowe ADR, plan wdrożenia → **recenzja ZANIM dokument trafi do Dariusza**. Kontekst = cały zestaw dokumentów naraz (sprzeczności między nimi = główny łup).

```bash
S=~/.claude/skills/cross-model-review
cat PROJECT_CARD.md .ai/specs/<spec>.md docs/DECISIONS.md > /tmp/kontekst.md   # bez danych klientów!
bash $S/qwen-review.sh /tmp/kontekst.md <prompt> .ai/reviews/<data>-<temat>-qwen.md          # 0 zł, think:false
OR_PROVIDER=DeepInfra bash $S/openrouter-review.sh /tmp/kontekst.md <prompt> .ai/reviews/<data>-<temat>-glm.md   # ~0,003 zł
```
- `openrouter-review.sh`: ten sam interfejs co `qwen-review.sh`; model `OR_MODEL` (default `z-ai/glm-5.3-flash`, promo do 9.09.2026, potem 2× — nadal grosze), klucz `OPENROUTER_API_KEY_PROMO` ze skarbca (fallback `_STALY` przy 401/402), **przypnij dostawcę** `OR_PROVIDER=DeepInfra` (fp8, cena promo; Z.AI = oficjalny, polityka danych nieznana → nie używać). Skrypt sam odmawia (exit 2), gdy kontekst zawiera wzorce sekretów/PESEL.
- Prompt dokumentowy: `STATUS` + sprzeczności między dokumentami + luki w KRYT (co da się „zaliczyć" bez wartości) + ryzyka przepływu + czego nie mierzy + YAGNI + max 3 rekomendacje. Wzorzec: PM scratch 2.09 (`prompt-recenzja-dokumentow.md`) — skopiować do skilla przy następnym użyciu.
- Wynik: PM pisze **syntezę** (`.ai/reviews/<data>-<temat>-synteza.md`: przyjęte / odrzucone z powodem), nanosi zmiany, dopiero wtedy prezentuje Dariuszowi. Pierwszy bieg: Asystent Faktur etap 2 (2.09) — oba GO_WITH_CHANGES, 11 zmian przyjętych, 4 odrzucone.
- Pomiar 2.09: GLM 5.3 Flash 12 780/2 599 tokenów, ~4 min, odpowiedź czysta i konkretna (złapał zaniżoną estymatę i brak precyzji w kryterium); Qwen złapał sprzeczność filtra Gmail. Komplementarne, nie redundantne.

### Czwarty głos: `open-code-review` (`ocr`) — recenzja KODU z kotwicami plik:linia (adopt 2026-09-16)

**Kiedy:** recenzujesz **kod albo diff** — tryb `code`, przegląd przed merge, pierwszy przebieg pod ADR-0011.
**Kiedy NIE:** plany, dokumenty projektowe, decyzje strategiczne (to proza — `ocr` czyta repozytorium, nie zamysł).

**Co daje, czego nie dają pozostali:** twardą **kotwicę `plik:linia` + dosłowny fragment `existing_code`**,
który da się sprawdzić w pliku. Pomiar tym samym przyrządem co benchmark 6.09 (`test-podlozone-bledy.py`):
ten sam Qwen 3.6 **w uprzęży `ocr` trafił 4/4 numery linii, bez uprzęży 0/4** (liczył od ogrodzenia bloku kodu).
Domyślnie biegnie na lokalnej Ollamie: **0 zł, kod nie opuszcza Maca** — inaczej niż Codex i OpenRouter.

**Czego NIE daje (dokłada PM, wymóg ADR-0011):** statusu „potwierdzone / podejrzenie", licznika fałszywych
alarmów i drugiej metody weryfikacji. `ocr` zna tylko `category` i `severity`. Odniesienie fałszywych alarmów
na pliku BEZ wad: **3 (Ollama) / 6 (DeepSeek)** — wszystkie typu „dołóż obronne sprawdzenie", żaden to nie wada.

```bash
# plik lub katalog (ścieżka WZGLĘDEM korzenia repo)
~/.claude/skills/cross-model-review/ocr-review.sh src/lib/auth.ts -o /tmp/ocr.md

# diff
~/.claude/skills/cross-model-review/ocr-review.sh --commit <sha> --repo <katalog> -o /tmp/ocr.md
~/.claude/skills/cross-model-review/ocr-review.sh --from main --to HEAD -o /tmp/ocr.md
~/.claude/skills/cross-model-review/ocr-review.sh --working -o /tmp/ocr.md

# drugi silnik (CHMURA, ~1,4 gr za plik) — świadomie; skrypt odmawia przy wzorcach sekretów/PESEL
~/.claude/skills/cross-model-review/ocr-review.sh <ścieżka> --dostawca openrouter -o /tmp/ocr.md
```

Model NIE jest w skrypcie na sztywno — role `lokalny_tekst` / `kolo_zapasowe_1` z `Project Master/config/routing-modeli.json`.

**Gotchy (wszystkie złapane empirycznie 16.09):**
- **`status: "success"` NIE jest dowodem wykonania.** Zgłoszenia #1027/#1196 i nasz bieg z 429: narzędzie
  kończy kodem 0, statusem `success`, i oddaje niepełny wynik — degradację widać **tylko na stderr**.
  Wrapper sprawdza artefakt (JSON istnieje i parsuje się, `files_reviewed` ≥ liczba plików z `--preview`,
  `tool_calls.failure`, ślady `429/timeout/failed/budget`) i wypisuje **OSTRZEŻENIE w nagłówku wyniku**.
  **Wynik z ostrzeżeniem nie jest recenzją — nie wolno na nim opierać werdyktu „czysto".**
- `scan` kończy statusem `success`, `review` — `complete`. Inne (`skipped`, `partial`, `completed_with_*`) = ostrzeżenie.
- **Ścieżka absolutna w `--path` daje `status: skipped` i zero znalezisk, bez błędu.** Wrapper zamienia na względną i robi `--preview` przed biegiem.
- `--max-tokens-budget` bywa nieegzekwowany (#1247) → **nie wpinać do automatów bez limitu po naszej stronie**.
- Komentarze wychodzą po angielsku (`review-language` konfigurowalne, niesprawdzone).
- W trybie `review` model bywa ślepy na pliki spoza commita (`file_read failed`) — wtedy powtórz jako `scan`.

Runbook (instalacja, błędy, bieg kontrolny): `Project Master/runbooks/open-code-review.md`.
Pilot i werdykt T1: `Project Master/.ai/research/pilot-open-code-review-2026-09-16.md`.

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

### Wzorzec D — `--peer-review` wzajemna recenzja (dodane 2026-08-09)

**Problem, który to naprawia.** Wzorce A-C pytają Codeksa i Qwena **osobno**. Modele nigdy nie widzą swoich odpowiedzi, więc dostajesz dwie równoległe monologi i to Claude sklejał je w raport — czyli rozbieżność rozstrzygał ten, kto ma najmniej powodów, żeby ją dostrzec (autor recenzowanego planu). Gdy jeden model podnosi ryzyko, którego drugi nie zauważył, nie ma etapu, w którym drugi mógłby powiedzieć „masz rację, wycofuję swój GO" albo „nie, i oto dlaczego się mylisz".

Źródło pomysłu: `aiwithremy/claude-skills-llm-council` (1 478⭐, audyt 9.08), oparte na metodzie LLM Council Andreja Karpathyego. Kodu nie kopiujemy — repo nie ma licencji. Bierzemy sam etap.

**Kiedy włączać:** decyzje nieodwracalne, architektura, plany strategiczne — czyli tam, gdzie i tak używasz `--iterate`. **Nie** dla zwykłego review kodu (koszt rośnie dwukrotnie, zysk mały).

```
RUNDA 1 (jak Wzorzec A): Codex i Qwen odpowiadają niezależnie, każdy zwraca STATUS.
   ↓
RUNDA 2 (nowa): każdy dostaje ODPOWIEDŹ DRUGIEGO i jedno zadanie —
   znajdź w niej to, co jest błędne albo pominięte, i powiedz, czy zmieniasz swój werdykt.
   ↓
Claude składa raport z DWÓCH rund, nie z jednej.
```

**Uruchomienie — jedną komendą, nie z ręki:**

```bash
~/.claude/skills/cross-model-review/peer-review.sh <plik-do-recenzji> [katalog-wyjściowy] [pytania-dodatkowe]
```

Skrypt robi obie rundy, pilnuje `--skip-git-repo-check` i `</dev/null` przy Codeksie, sprawdza
ISTNIENIE plików wynikowych (nie kod wyjścia) i na końcu wypisuje cztery werdykty obok siebie
plus ściągę, jak je czytać. Wynik: `r1-codex.md`, `r1-qwen.md`, `r2-codex.md`, `r2-qwen.md`.

Prompt rundy 2 (ten sam dla obu, podmieniasz plik z cudzą odpowiedzią):

```text
Oto recenzja tego samego planu napisana przez INNY model.
Twoje zadanie NIE polega na streszczeniu jej ani na uprzejmości.

1) Wskaż konkretnie, co ta recenzja przeoczyła — punkty, których w niej nie ma, a powinny być.
2) Wskaż, co jest w niej BŁĘDNE — twierdzenia faktycznie nieprawdziwe lub oparte na złym założeniu.
3) Czy któryś jej argument zmienia TWÓJ werdykt? Jeśli tak, powiedz wprost, który i dlaczego.
4) ZAKOŃCZ LINIĄ: STATUS_PO_PEER_REVIEW: [BEZ_ZMIAN | ZMIENIONY_NA_<verdict>] + jedno zdanie uzasadnienia.

Nie zgadzaj się dla świętego spokoju. Zgoda bez uzasadnienia jest bezwartościowa —
jeśli druga recenzja ma rację, napisz KTÓRY konkretnie jej argument Cię przekonał.
```

**Co czytać w wyniku (to jest właściwy sygnał, nie sam werdykt):**

| Wynik rundy 2 | Co to znaczy |
|---|---|
| Obaj `BEZ_ZMIAN` + wzajemnie potwierdzają te same ryzyka | Najmocniejszy sygnał w całym skillu — dwa niezależne modele przetrwały konfrontację |
| Któryś `ZMIENIONY_NA_` | Przeczytaj argument, który go przekonał — to zwykle najcenniejsze zdanie z całego review |
| Obaj `BEZ_ZMIAN`, ale każdy podważa drugiego | Realna rozbieżność, nie szum → tu włącz Gemini jako trzeci głos (powód 4 z §25: rozstrzygnięcie sporu) |
| Obaj nagle się zgadzają, porzucając własne zastrzeżenia | Podejrzane — modele bywają ustępliwe. Sprawdź, czy podali KTÓRY argument ich przekonał; brak konkretu = zgoda pusta |

**Zweryfikowane w pierwszym biegu (9.08.2026, decyzja o warstwie dowodowej w CRM).** Runda 1: Codex `NO_GO`, Qwen `NO_GO` — pozornie zgoda, więc bez rundy 2 raport brzmiałby „oba modele zgodne, nie robimy". Runda 2 pokazała, że pod tą zgodą leżały **dwie sprzeczne architektury**: Codex chciał osobnej warstwy lokalnie w CRM, Qwen rozszerzenia wspólnej tabeli z Project Mastera. Qwen po przeczytaniu argumentu Codeksa **zmienił zdanie w tym punkcie** (`ZMIENIONY_NA_`), Codex swój werdykt utrzymał. Do tego Codex wyłapał w recenzji Qwena błąd rzeczowy, którego sam bym nie zauważył: **`logprob` mierzy pewność modelu co do wygenerowanych tokenów, nie prawdziwość faktu** — więc próg „logprob > 0,95 = dowód mocny" jest dokładnie tym samo-utwierdzaniem, przed którym miała chronić recenzowana zasada.

Dwie pułapki, które ten sam bieg ujawnił — sprawdzaj je za każdym razem:
- **Dryf werdyktu.** Qwen w rundzie 1 napisał „zablokuj tę pozycję w backlogu", a w rundzie 2 — „mój werdykt pozostaje GO". To nie było ustępstwo wobec Codeksa (tam akurat się bronił), tylko niespójność z samym sobą. **Zawsze porównaj werdykt z rundy 2 z treścią rundy 1 tego samego modelu**, nie tylko z werdyktem drugiego.
- **Zgoda pusta.** Jeśli model pisze „zgadzam się" bez wskazania KTÓREGO argumentu dotyczy, traktuj to jak brak odpowiedzi. Punkt 3 promptu wymaga konkretu właśnie po to.

Dryf potwierdził się od razu w drugim biegu tego samego dnia (decyzja o skanie 219 domen jednym wsadem): Qwen dał w rundzie 1 `GO_WITH_CHANGES`, a w rundzie 2 zadeklarował `BEZ_ZMIAN` i w tym samym zdaniu napisał „werdykt pozostaje NO_GO". **Etykieta werdyktu bywa niezgodna z treścią — czytaj zdanie uzasadnienia, nie samą etykietę.**

**Uwaga wykonawcza:** `codex exec` uruchamiany z katalogu, który nie jest repozytorium git, przerywa CICHO (kod wyjścia 0, brak pliku wynikowego, powód dopiero w logu). Zawsze dokładaj `--skip-git-repo-check` i `</dev/null`, a po biegu sprawdzaj ISTNIENIE pliku, nie kod wyjścia (Lessons PM 22.06).

**Codex CLI 0.150.1 (zweryfikowane 2026-09-06):** (1) flaga `--full-auto` NIE ISTNIEJE — bieg z nią kończy się kodem 0 bez pliku wynikowego; recenzja = `-s read-only`. (2) Na koncie ChatGPT model `gpt-5.4` jest odrzucany (HTTP 400 „not supported when using Codex with a ChatGPT account"); działa `gpt-5.5` — `~/.codex/config.toml` przestawiony 6.09. Objaw starego configu: `ERROR ... 400` w logu, plik `-o` nie powstaje.

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
  -s read-only --skip-git-repo-check \
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
