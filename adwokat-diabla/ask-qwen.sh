#!/usr/bin/env bash
# Adwokat-diabla: helper do wywołań Qwen3.6 lokalnego przez Ollama HTTP API
#
# Usage:
#   ask-qwen.sh <prompt-file-or-string> <output-file>
#
# Env vars:
#   QWEN_MODEL    (default: qwen3.6:35b-a3b)
#   OLLAMA_URL    (default: http://localhost:11434)
#   QWEN_TIMEOUT  (default: 180 — 3 min, krótsze niż review bo interaktywne)
#   QWEN_TEMP     (default: 0.4 — wyższa temperatura dla różnorodności pytań)
#
# Notes:
#   - /no_think w prompcie + strip <think>...</think> defensywnie (CLAUDE.md gotcha)
#   - Wyjście do stdout w trybie OK + zapis do pliku
#   - Exit 1 gdy Ollama niedostępne lub pusty wynik

set -euo pipefail

PROMPT_ARG="${1:?Usage: ask-qwen.sh <prompt-file-or-string> <output-file>}"
OUTPUT_FILE="${2:?output file required}"

MODEL="${QWEN_MODEL:-qwen3.6:35b-a3b}"
OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434}"
TIMEOUT="${QWEN_TIMEOUT:-180}"
TEMP="${QWEN_TEMP:-0.4}"

if [ -f "$PROMPT_ARG" ]; then
  PROMPT_TEXT=$(cat "$PROMPT_ARG")
else
  PROMPT_TEXT="$PROMPT_ARG"
fi

FULL_PROMPT="/no_think

${PROMPT_TEXT}"

PAYLOAD=$(jq -n \
  --arg model "$MODEL" \
  --arg prompt "$FULL_PROMPT" \
  --argjson temp "$TEMP" \
  '{model: $model, prompt: $prompt, stream: false, options: {temperature: $temp, num_ctx: 32768}}')

mkdir -p "$(dirname "$OUTPUT_FILE")"

if ! curl -sS --max-time 3 "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
  echo "ERROR: Ollama niedostępne pod ${OLLAMA_URL}. Uruchom: ollama serve" >&2
  exit 1
fi

# Watchdog: hard kill całego curl po TIMEOUT+10s. Defensywnie ponad curl --max-time
# bo curl może utknąć przy slow stream / 200 OK z pustym body bez EOF.
WATCHDOG=$((TIMEOUT + 10))
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD="timeout ${WATCHDOG}s"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD="gtimeout ${WATCHDOG}s"
else
  echo "WARN: brak 'timeout'/'gtimeout' (zainstaluj: brew install coreutils) — używam tylko curl --max-time" >&2
  TIMEOUT_CMD=""
fi

set +e
RESPONSE=$($TIMEOUT_CMD curl -sS --max-time "$TIMEOUT" -X POST "${OLLAMA_URL}/api/generate" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")
CURL_EXIT=$?
set -e

if [ "$CURL_EXIT" = "124" ]; then
  echo "ERROR: watchdog timeout (${WATCHDOG}s) — Ollama zawiesiło się lub stream był zbyt wolny. Spróbuj: ollama stop && ollama serve" >&2
  exit 1
fi
if [ "$CURL_EXIT" != "0" ]; then
  echo "ERROR: curl exit $CURL_EXIT (Ollama prawdopodobnie nieosiągalne)" >&2
  exit 1
fi

RAW_OUTPUT=$(echo "$RESPONSE" | jq -r '.response // .error // ""')

if [ -z "$RAW_OUTPUT" ]; then
  echo "ERROR: Qwen zwrócił pusty wynik" >&2
  echo "$RESPONSE" | head -c 500 >&2
  exit 1
fi

CLEAN_OUTPUT=$(echo "$RAW_OUTPUT" | perl -0777 -pe 's{<think>.*?</think>}{}gs')

echo "$CLEAN_OUTPUT" > "$OUTPUT_FILE"

if [ ! -s "$OUTPUT_FILE" ]; then
  echo "ERROR: po strip <think> wyjście jest puste" >&2
  exit 1
fi

cat "$OUTPUT_FILE"
