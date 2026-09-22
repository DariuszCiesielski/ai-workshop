#!/usr/bin/env bash
# Qwen3.6 review helper — HTTP call do lokalnego Ollama
#
# Usage:
#   qwen-review.sh <context-file> <prompt-file-or-string> <output-file>
#
# Env vars:
#   QWEN_MODEL    (default: qwen3.6:35b-a3b)
#   OLLAMA_URL    (default: http://localhost:11434)
#   QWEN_TIMEOUT  (default: 600 — 10 min, długie reviews)
#
# Notes:
#   - Dodaje /no_think do promptu ORAZ think:false w body (2.09.2026: samo /no_think w tekście NIE gasi
#     rozumowania w qwen3.6 — cały tok myślenia wylądował w odpowiedzi jako zwykły tekst)
#   - Strip-uje <think>...</think> z odpowiedzi (defensywnie, gdyby /no_think nie zadziałało)
#   - Zwraca exit 1 gdy Ollama niedostępne lub pusty wynik

set -euo pipefail

CONTEXT_FILE="${1:?Usage: qwen-review.sh <context-file> <prompt-file-or-string> <output-file>}"
PROMPT_ARG="${2:?prompt required (file path or string)}"
OUTPUT_FILE="${3:?output file required}"

MODEL="${QWEN_MODEL:-qwen3.6:35b-a3b}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
TIMEOUT="${QWEN_TIMEOUT:-600}"

# Walidacja: context file istnieje
if [ ! -f "$CONTEXT_FILE" ]; then
  echo "ERROR: context file not found: $CONTEXT_FILE" >&2
  exit 1
fi

# Prompt: jeśli ścieżka istnieje to czytaj plik, inaczej traktuj jako string
if [ -f "$PROMPT_ARG" ]; then
  PROMPT_TEXT=$(cat "$PROMPT_ARG")
else
  PROMPT_TEXT="$PROMPT_ARG"
fi

CONTEXT_TEXT=$(cat "$CONTEXT_FILE")

# Auto-inject Universal Preamble (estymaty w godzinach, nie dniach)
# Lekcja 2026-05-04: AI reviewerzy domyślnie zwracają "developer days" co jest 5-10× nadmiarem
# Opt-out: CROSS_MODEL_NO_PREAMBLE=1
PREAMBLE_FILE="$(dirname "$0")/PREAMBLE.txt"
if [ -z "${CROSS_MODEL_NO_PREAMBLE:-}" ] && [ -f "$PREAMBLE_FILE" ]; then
  PREAMBLE_TEXT=$(cat "$PREAMBLE_FILE")
else
  PREAMBLE_TEXT=""
fi

# Pełny prompt: /no_think gasi thinking mode, preamble + kontekst + user prompt
FULL_PROMPT="/no_think

${PREAMBLE_TEXT}

Kontekst do analizy:
<<<CONTEXT_BEGIN>>>
${CONTEXT_TEXT}
<<<CONTEXT_END>>>

${PROMPT_TEXT}"

# JSON-escape przez jq
PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$FULL_PROMPT" \
  '{model: $model, prompt: $prompt, stream: false, think: false, options: {temperature: 0.3, num_ctx: 32768}}')

mkdir -p "$(dirname "$OUTPUT_FILE")"

# Sprawdź czy Ollama wstaje — szybki health check
if ! curl -sS --max-time 3 "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
  echo "ERROR: Ollama niedostępne pod ${OLLAMA_URL}. Uruchom: ollama serve" >&2
  exit 1
fi

# Properly call Ollama
RESPONSE=$(curl -sS --max-time "$TIMEOUT" -X POST "${OLLAMA_URL}/api/generate" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

# Wyciągnij .response (lub .error gdy fail)
RAW_OUTPUT=$(echo "$RESPONSE" | jq -r '.response // .error // ""')

if [ -z "$RAW_OUTPUT" ]; then
  echo "ERROR: Qwen zwrócił pusty wynik" >&2
  echo "$RESPONSE" | head -c 500 >&2
  exit 1
fi

# Strip <think>...</think> bloków (defensywnie, gdyby /no_think nie zadziałało)
CLEAN_OUTPUT=$(echo "$RAW_OUTPUT" | perl -0777 -pe 's{<think>.*?</think>}{}gs')

echo "$CLEAN_OUTPUT" > "$OUTPUT_FILE"

# Sanity check: plik nie pusty
if [ ! -s "$OUTPUT_FILE" ]; then
  echo "ERROR: po strip <think> wyjście jest puste" >&2
  exit 1
fi

LINES=$(wc -l < "$OUTPUT_FILE" | tr -d ' ')
SIZE=$(wc -c < "$OUTPUT_FILE" | tr -d ' ')
echo "OK: Qwen review zapisany do $OUTPUT_FILE (${LINES} linii, ${SIZE} bajtów)"
