---
name: ai-models-reference
description: Baza wiedzy o aktualnych modelach AI (OpenAI, Anthropic, Google, xAI) z cenami, oknami kontekstowymi i rekomendacjami. Używaj gdy trzeba wybrać model do projektu, porównać koszty, zaktualizować integrację na nowszy model, lub sprawdzić aktualne ceny API.
---

# AI Models Reference — Globalny skill

## Opis
Baza wiedzy o aktualnych modelach AI od głównych dostawców. Używaj tego skilla przy:
- Wyborze modelu do projektu (API, chat, embeddingi)
- Aktualizacji istniejących integracji na nowsze modele
- Porównywaniu kosztów i możliwości modeli
- Planowaniu architektury AI w projektach

## Triggery
- "jaki model użyć"
- "zaktualizuj modele AI"
- "aktualne modele"
- "porównaj modele"
- "który model jest najlepszy"

## Ostatnia aktualizacja: 2026-06-07 (zweryfikowane WebSearch/WebFetch — dodano GPT-5.4 mini/nano)

---

## 1. OpenAI

### Modele flagowe (GPT-5 series) — Input / Output per 1M tokens (USD)
| Model | ID API | Kontekst | Input | Output | Zastosowanie |
|-------|--------|----------|-------|--------|-------------|
| **GPT-5.5 Pro** | `gpt-5.5-pro` | 1.05M | **$30.00** | **$180.00** | 🔝 **Najdroższy.** Maksymalna wydajność, tylko najtrudniejsze zadania. |
| **GPT-5.4 Pro** | `gpt-5.4-pro` | 1.05M | $30.00 | $180.00 | Tak samo drogi jak 5.5 Pro — migruj na 5.5 Pro. |
| **GPT-5.5** (standard) | `gpt-5.5` | 1.05M, max output 128K | **$5.00** | **$30.00** | Live API od **24.04.2026**. Inteligentniejszy + token-efficient — *często taniej w praktyce* niż 5.4 mimo wyższej stawki/token (mniej tokenów na ten sam wynik). |
| **GPT-5.4** | `gpt-5.4` | 1.05M | $2.50 | $15.00 | Stabilny od 05.03.2026. Coding, reasoning, computer-use. **Połowa stawki 5.5**. |
| **GPT-5.3** | `gpt-5.3` | ? | ~$1.75 | ~$14.00 | ⚠️ Status niepewny — migruj na 5.5. |
| **GPT-5.2** | `gpt-5.2` | ? | $1.25 | $10.00 | Stabilny, sprawdzony, tańszy fallback. |
| **GPT-5.1** | `gpt-5.1` | ? | ? | ? | ⚠️ Wycofywany — nie używać w nowych projektach. |

### Modele Codex (dedykowane do kodu, tańsze niż flagowe)
| Model | ID API | Input/1M | Output/1M | Zastosowanie |
|-------|--------|----------|-----------|-------------|
| **GPT-5.3-Codex** | `gpt-5.3-codex` | $1.75 | $14.00 | Najnowszy Codex, lepszy reasoning |
| **GPT-5-Codex** | `gpt-5-codex` | **$1.25** | **$10.00** | Solidny i najtańszy z premium-class. Default w `codex exec`. |

### Tryby billing (uniwersalne dla GPT-5.x)
- **Standard** — base price (jak wyżej)
- **Batch** — 50% taniej (queue, <24h turnaround) → np. GPT-5.5 Batch = $2.50/$15 = identyczne ze stawką GPT-5.4 standard
- **Flex** — 50% taniej (low priority)
- **Priority** — 2.5× droższy (gwarancja low latency)
- **Regional (data residency)** — +10% uplift

### Modele ekonomiczne (mini/nano) — current-gen = rodzina 5.4
| Model | ID API | Kontekst | Cennik (per 1M tokens) | Zastosowanie |
|-------|--------|----------|----------------------|-------------|
| **GPT-5.4 mini** ⭐ | `gpt-5.4-mini` | 400K | **$0.75 / $4.50** | **Current-gen mini (snapshot 2026-03-17).** Pod wysoki wolumen, structured outputs ✓. Domyślny wybór dla klasyfikacji/oceny z JSON-schema. Następca gpt-5-mini. |
| **GPT-5.4 nano** | `gpt-5.4-nano` | 400K | $0.20 / $1.25 | Najtańszy current-gen — klasyfikacja, sumaryzacja, ekstrakcja masowa. |
| **GPT-5 mini** | `gpt-5-mini` | ? | $0.25 / $2.00 | Poprzednia generacja mini (tańszy/token, słabszy) — migruj na 5.4 mini gdy liczy się jakość. |
| **GPT-5 nano** | `gpt-5-nano` | 400K | $0.05 / $0.40 | Poprzednia generacja nano, najtańszy absolutnie. |

> ⚠️ NIE ma „gpt-5.5 mini" ani „gpt-5.5 nano" (stan 06.2026) — warianty mini/nano są w rodzinie 5.4.
> Empiria 2026-06-07 (Asystent Poczty Email): gpt-4o-mini KONFABULOWAŁ przy ocenie maili (mylił case study cold-maila z własnym projektem); gpt-5.4-mini przy tym samym promptcie cytuje realne liczby i poprawnie rozpoznaje brak zadania dla nas. Do ocen/ekstrakcji z grounding-em wybieraj 5.4 mini.

### Modele legacy (wciąż dostępne w API, NIE używać w nowych projektach)
| Model | ID API | Status | Zastępca |
|-------|--------|--------|----------|
| **GPT-4.1** | `gpt-4.1` | Wycofany z ChatGPT (luty 2026), API dostępne | GPT-5.2 |
| **GPT-4.1 mini** | `gpt-4.1-mini` | Wycofany z ChatGPT (luty 2026), API dostępne | GPT-5 mini |
| **GPT-4.1 nano** | `gpt-4.1-nano` | Legacy | GPT-5 nano |
| **GPT-4o** | `gpt-4o` | Wycofany | GPT-5.2 |
| **GPT-4o-mini** | `gpt-4o-mini` | Wycofany | **GPT-5.4 mini** (do ocen/grounding) lub GPT-5.4 nano (masowo) |

### Modele reasoning (o-series)
| Model | ID API | Zastosowanie |
|-------|--------|-------------|
| **o3** | `o3` | Zaawansowane rozumowanie, matematyka, kodowanie |
| **o4-mini** | `o4-mini` | Szybki reasoning — dobry stosunek cena/jakość |

### Embeddingi
| Model | Wymiary | Zastosowanie |
|-------|---------|-------------|
| **text-embedding-3-large** | 3072 | Najlepsza jakość embeddings |
| **text-embedding-3-small** | 1536 | Ekonomiczny, dobra jakość |

### Uwagi OpenAI
- GPT-5.4 ma 1.05M context window; prompty >272K input tokens = 2x cena input, 1.5x output
- Cached input: 90% taniej (np. GPT-5.2: $0.175, GPT-5 nano: $0.005)
- GPT-5.4 Thinking = wersja z reasoning, GPT-5.4 Pro = maksymalna wydajność

---

## 2. Anthropic (Claude)

### Modele
| Model | ID API | Kontekst | Cennik (per 1M tokens) | Zastosowanie |
|-------|--------|----------|----------------------|-------------|
| **Claude Opus 4.6** | `claude-opus-4-6` | 200K | $15 / $75 | Najzdolniejszy — złożone zadania, coding |
| **Claude Sonnet 4.6** | `claude-sonnet-4-6` | 200K | $3 / $15 | Balans jakość/szybkość — produkcja |
| **Claude Haiku 4.5** | `claude-haiku-4-5-20251001` | 200K | $0.80 / $4 | Szybki, ekonomiczny — proste zadania |

### Uwagi
- Wszystkie modele obsługują narzędzia (tool use), wizję, extended thinking
- Max output: 64K tokenów (Opus/Sonnet), 8K (Haiku)
- Batching API: 50% taniej

---

## 3. Google (Gemini)

### Modele
| Model | ID API | Kontekst | Cennik (per 1M tokens) | Zastosowanie |
|-------|--------|----------|----------------------|-------------|
| **Gemini 3.1 Pro** | `gemini-3.1-pro` | 2M | ~$7 / ~$21 | Najnowszy, najzdolniejszy |
| **Gemini 3 Flash** | `gemini-3-flash` | 1M | ~$0.15 / ~$0.60 | Szybki, multimodal |
| **Gemini 2.5 Pro** | `gemini-2.5-pro` | 1M | ~$2.50 / ~$10 | Stabilny, sprawdzony |
| **Gemini 2.5 Flash** | `gemini-2.5-flash` | 1M | ~$0.075 / ~$0.30 | Ekonomiczny, szybki |

### Uwagi
- Ogromne okno kontekstowe (do 2M tokenów)
- Darmowy tier w Google AI Studio
- Grounding z Google Search

---

## 4. xAI (Grok)

### Modele
| Model | ID API | Kontekst | Cennik (per 1M tokens) | Zastosowanie |
|-------|--------|----------|----------------------|-------------|
| **Grok 4.20** | `grok-4-20` | 256K | ~$10 / ~$30 | Najnowszy, reasoning |
| **Grok 4.1** | `grok-4.1` | 128K | ? | Poprzednia generacja |
| **Grok 3** | `grok-3` | 131K | ~$3 / ~$15 | Stabilny |

---

## 5. Rekomendacje dla projektów

### Kiedy który model wybrać

| Zastosowanie | Rekomendacja | Alternatywa | Koszt (input/output per 1M) |
|-------------|-------------|-------------|----------------------------|
| **Chat AI / asystent** | GPT-5.2 | Claude Sonnet 4.6 | $1.25/$10 vs $3/$15 |
| **Złożona analiza / reasoning** | GPT-5.5 (token-efficient) | Claude Opus 4.6 | $5/$30 vs $15/$75 |
| **Najtrudniejsze problemy (rzadko)** | GPT-5.5 Pro | GPT-5.4 Pro | $30/$180 vs $30/$180 |
| **Coding via Codex CLI (default)** | **GPT-5-Codex** | GPT-5.3-Codex | **$1.25/$10** vs $1.75/$14 |
| **Coding via Codex CLI (trudne)** | GPT-5.3-Codex | GPT-5.4 (xhigh) | $1.75/$14 vs $2.50/$15 |
| **Generowanie treści (SEO, metadane)** | GPT-5.2 | Claude Sonnet 4.6 | $1.25/$10 vs $3/$15 |
| **Proste zadania / klasyfikacja** | GPT-5 mini | Haiku 4.5 | $0.25/$2 vs $0.80/$4 |
| **Ekstrakcja danych / parsing** | GPT-5 nano | Gemini 2.5 Flash | $0.05/$0.40 vs $0.075/$0.30 |
| **Długi kontekst (>200K)** | GPT-5.5 (1.05M, token-efficient) | Gemini 3.1 Pro (2M) | $5/$30 vs $7/$21 |
| **Embeddingi** | text-embedding-3-small | - | - |
| **Real-time / streaming** | GPT-5 mini | Gemini 3 Flash | $0.25/$2 vs $0.15/$0.60 |

### Wzorzec migracji ze starych modeli
```
gpt-4o          → gpt-5.2
gpt-4o-mini     → gpt-5.4-mini (jakość/grounding) lub gpt-5.4-nano (masowo)
gpt-4.1         → gpt-5.2
gpt-4.1-mini    → gpt-5.4-mini
gpt-4.1-nano    → gpt-5.4-nano
gpt-5-mini      → gpt-5.4-mini
gpt-5-nano      → gpt-5.4-nano
gpt-3.5-turbo   → gpt-5-nano
gpt-5.1         → gpt-5.2 (lub 5.5 dla wymagających)
gpt-5.3         → gpt-5.5 (5.3 status niepewny)
gpt-5.4-pro     → gpt-5.5-pro (ta sama cena, lepszy model)
claude-3-opus   → claude-opus-4-6
claude-3-sonnet → claude-sonnet-4-6
claude-3-haiku  → claude-haiku-4-5-20251001
```

### Reguła dla Codex CLI w trybie oszczędnym
- **Default = `gpt-5-codex` z `medium` reasoning** ($1.25/$10) — pokrywa 80% zadań
- **Eskalacja do `gpt-5.4` (xhigh)** ($2.50/$15) tylko gdy: cross-model review krytycznej decyzji, reasoning >5 kroków, problem już 1× nie rozwiązany
- **NIE używać `gpt-5.5` w Codex CLI** — Codex ma własne dedykowane modele (5-Codex / 5.3-Codex) tańsze i specjalizowane do kodu
- **Limit per sesja:** 1 sesja xhigh dziennie. >1 → przed kolejną cross-model review czy potrzeba premium
- **Anti-pattern z 01.05.2026:** 8 sesji Codex w jednym dniu × głównie `gpt-5.4 xhigh` × Marketing Hub kontekst (~3 MB JSONL) = ~$40 (2× auto-recharge $20). Lekcja: dla `gpt-5.4` xhigh ustal twardy limit 2-3 sesji/dzień, reszta na `gpt-5-codex medium`.

---

## 6. Checklist przy aktualizacji tego skilla

1. Sprawdź oficjalne strony: openai.com/api/pricing, anthropic.com, ai.google.dev, x.ai
2. Zweryfikuj przez web search (nie polegaj na pamięci!)
3. Zaktualizuj tabelki modeli i cen
4. Zmień datę "Ostatnia aktualizacja" na górze
5. Sprawdź czy rekomendacje w sekcji 5 są nadal aktualne
6. Przenieś wycofane modele do sekcji "legacy"
