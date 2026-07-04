---
name: gemini-delegation
description: >
  Automatyczna delegacja zadań do Gemini 3.1 Pro API. Używaj do recenzji planów,
  review kodu, cross-walidacji decyzji, tłumaczeń, podsumowań. Agent wywołuje
  Gemini bez udziału użytkownika i odbiera odpowiedź synchronicznie.
  Triggery: "zrecenzuj", "wyślij do Gemini", "cross-walidacja", "druga opinia",
  "review planu", "przetłumacz", "podsumuj dokument".
---

# Gemini Delegation — automatyczna delegacja zadań

## Kiedy używać (automatycznie)

Deleguj do Gemini **ZAWSZE** gdy:
1. **Cross-walidacja planu** — masz gotowy plan implementacji → wyślij do Gemini na recenzję PRZED realizacją
2. **Code review** — zakończyłeś implementację → wyślij diff/pliki do review
3. **Decyzja architektoniczna** — wybierasz między podejściami → poproś Gemini o opinię
4. **Tłumaczenie** — treść PL→EN lub EN→PL (README, opisy repo, posty)
5. **Podsumowanie długiego dokumentu** — handoff, raport, transkrypcja

NIE deleguj gdy:
- Zadanie wymaga modyfikacji plików (Gemini API nie ma dostępu do repo)
- Potrzebujesz uruchomić kod/testy
- Odpowiedź jest trywialna (nie marnuj API callów)

## Jak wywoływać

### Skrypt globalny

```bash
python3 ~/.claude/skills/gemini-delegation/delegate.py "TREŚĆ ZADANIA"
```

### Z plikiem kontekstu

```bash
python3 ~/.claude/skills/gemini-delegation/delegate.py \
  --context-file /ścieżka/do/planu.md \
  "Zrecenzuj ten plan. Wskaż ryzyka i brakujące elementy."
```

### Z wieloma plikami + zapis wyniku

```bash
python3 ~/.claude/skills/gemini-delegation/delegate.py \
  --context-file plan.md \
  --context-file code.ts \
  --output .ai/reports/gemini-review-YYYY-MM-DD.md \
  "Zrecenzuj plan i implementację. Czy kod realizuje plan?"
```

### Z JSON (pełne metadane — tokeny, czas)

```bash
python3 ~/.claude/skills/gemini-delegation/delegate.py \
  --json \
  "Pytanie do Gemini"
```

## Gotowe prompty per use case

### Recenzja planu implementacji
```
Jesteś recenzentem technicznym. Przeczytaj plan i oceń:
1) Czy plan jest realistyczny?
2) Jakie są największe ryzyka?
3) Co pominięto?
4) Jakie zmiany rekomendujesz?
Bądź krytyczny. Podaj konkretne, actionable uwagi.
```

### Code review
```
Jesteś senior developerem. Przejrzyj ten kod i oceń:
1) Bugi i potencjalne problemy
2) Bezpieczeństwo (injection, wycieki danych)
3) Jakość kodu (czytelność, nazewnictwo, DRY)
4) Sugestie ulepszeń
Skup się na problemach, nie na pochwałach.
```

### Cross-walidacja decyzji architektonicznej
```
Rozważam dwa podejścia:
OPCJA A: [opis]
OPCJA B: [opis]
Kontekst: [co budujemy, jakie ograniczenia]
Które podejście rekomendujesz i dlaczego? Jakie trade-offy pominąłem?
```

### Tłumaczenie PL→EN (README, posty)
```
Przetłumacz poniższy tekst z polskiego na angielski.
Zachowaj formatowanie Markdown. Używaj naturalnego, profesjonalnego
języka technicznego. Nie tłumacz dosłownie — zaadaptuj do anglojęzycznego
czytelnika.
```

### Podsumowanie dokumentu
```
Podsumuj ten dokument w max 10 bullet pointach.
Skup się na: decyzjach, ryzykach, następnych krokach i otwartych pytaniach.
Pomiń oczywistości i kontekst, który czytelnik zna.
```

## Automatyczna integracja w workflow agenta

### Po napisaniu planu → recenzja
```bash
# Agent automatycznie po zakończeniu planowania:
python3 ~/.claude/skills/gemini-delegation/delegate.py \
  --context-file .planning/PLAN.md \
  --output .ai/reports/gemini-plan-review-$(date +%Y-%m-%d).md \
  "Zrecenzuj ten plan implementacji. Wskaż ryzyka, brakujące elementy, nierealistyczne założenia."
```

### Po implementacji → code review
```bash
# Agent automatycznie po zakończeniu kodowania:
git diff HEAD~1 > /tmp/last-diff.txt
python3 ~/.claude/skills/gemini-delegation/delegate.py \
  --context-file /tmp/last-diff.txt \
  --output .ai/reports/gemini-code-review-$(date +%Y-%m-%d).md \
  "Zrób code review tego diffa. Szukaj bugów, security issues, i problemów z jakością."
```

### Przed commitem strategicznym → cross-walidacja
```bash
python3 ~/.claude/skills/gemini-delegation/delegate.py \
  --context-file ARCHITECTURE.md \
  --context-file src/new-feature.ts \
  --output .ai/reports/gemini-arch-review.md \
  "Czy ta implementacja jest spójna z architekturą projektu? Co zmienić?"
```

## Parametry

| Parametr | Domyślnie | Opis |
|----------|-----------|------|
| `--temperature` | 0.3 | Niższe = bardziej deterministyczne |
| `--max-tokens` | 8192 | Max tokenów odpowiedzi |
| `--output` | stdout | Plik wyjściowy |
| `--context-file` | brak | Plik(i) dołączone do promptu |
| `--json` | false | Zwróć JSON z metadanymi |

## Konfiguracja

- **API Key:** `GOOGLE_GEMINI_API_KEY` w `~/.claude/projects/-Users-dariuszciesielski-projekty-Project-Master/credentials.env`
- **Model:** `gemini-3.1-pro-preview` (darmowy, Google AI Studio)
- **Limity:** 60 req/min, ~2M tokenów/dzień (darmowy tier)
- **Szybkość:** ~15-20s na recenzję planu (~4K tokenów)

## Benchmark (2026-04-09)

| Test | Czas | Tokeny | Jakość |
|------|------|--------|--------|
| Recenzja planu YouTube pipeline | 16.6s | 4112 | Dobra — trafne uwagi o OOM i kosztach |
