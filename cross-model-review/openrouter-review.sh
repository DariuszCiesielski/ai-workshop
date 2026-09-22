#!/usr/bin/env bash
# OpenRouter review helper — ten sam interfejs co qwen-review.sh, model z chmury OpenRouter.
#
# Usage:
#   openrouter-review.sh <context-file> <prompt-file-or-string> <output-file>
#
# Env vars:
#   OR_MODEL      (default: z-ai/glm-5.3-flash — promocyjny do 9.09.2026, potem 2× drożej; nadal grosze)
#   OR_PROVIDER   (opcjonalnie: przypięcie dostawcy, np. "DeepInfra" — lekcja 10.08: AUTO-routing losuje silnik)
#   OR_KEY_NAME   (default: OPENROUTER_API_KEY_PROMO; fallback automatyczny na OPENROUTER_API_KEY_STALY przy 401/402)
#   OR_TIMEOUT    (default: 600)
#   OR_MAX_TOKENS (default: 6000)
#
# GRANICA DANYCH (globalny CLAUDE.md §5, claude-ox): to chmura (OpenRouter/Z.ai) — ZERO danych klientów,
# sekretów, danych osobowych. Skrypt robi prosty skan sekretów kontekstu i odmawia przy trafieniu.
# GLM 5.3 Flash = model z obowiązkowym rozumowaniem (reasoning.enabled=false → HTTP 400) — nie wyłączamy.

set -euo pipefail

CONTEXT_FILE="${1:?Usage: openrouter-review.sh <context-file> <prompt-file-or-string> <output-file>}"
PROMPT_ARG="${2:?prompt required (file path or string)}"
OUTPUT_FILE="${3:?output file required}"

MODEL="${OR_MODEL:-z-ai/glm-5.3-flash}"
PROVIDER="${OR_PROVIDER:-}"
KEY_NAME="${OR_KEY_NAME:-OPENROUTER_API_KEY_PROMO}"
TIMEOUT="${OR_TIMEOUT:-600}"
MAX_TOKENS="${OR_MAX_TOKENS:-6000}"
VAULT="$HOME/.claude/shared-credentials.env"

[ -f "$CONTEXT_FILE" ] || { echo "ERROR: context file not found: $CONTEXT_FILE" >&2; exit 1; }

# Skan sekretów PRZED wysyłką do chmury (§5 granica danych) — wzorce, nie wartości
if grep -qE 'sk_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|service_role|eyJ[A-Za-z0-9_-]{30,}|PESEL|BEGIN (RSA|OPENSSH) PRIVATE' "$CONTEXT_FILE"; then
  echo "ERROR: kontekst wygląda na zawierający sekret/dane osobowe — NIE wysyłam do OpenRouter (recenzuj lokalnie: qwen-review.sh)" >&2
  exit 2
fi

wczytaj_klucz() {  # $1 = nazwa zmiennej; wartość NIGDY nie jest wypisywana
  grep -hE "^$1=" "$VAULT" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"' | tr -d "'" | tr -d '[:space:]'
}
KEY="$(wczytaj_klucz "$KEY_NAME")"
[ -n "$KEY" ] || { echo "ERROR: brak $KEY_NAME w $VAULT" >&2; exit 1; }

if [ -f "$PROMPT_ARG" ]; then PROMPT_TEXT="$(cat "$PROMPT_ARG")"; else PROMPT_TEXT="$PROMPT_ARG"; fi
CONTEXT_TEXT="$(cat "$CONTEXT_FILE")"

PREAMBLE_FILE="$(dirname "$0")/PREAMBLE.txt"
if [ -z "${CROSS_MODEL_NO_PREAMBLE:-}" ] && [ -f "$PREAMBLE_FILE" ]; then PREAMBLE_TEXT="$(cat "$PREAMBLE_FILE")"; else PREAMBLE_TEXT=""; fi

USER_CONTENT="${PREAMBLE_TEXT}

Kontekst do analizy:
<<<CONTEXT_BEGIN>>>
${CONTEXT_TEXT}
<<<CONTEXT_END>>>

${PROMPT_TEXT}"

if [ -n "$PROVIDER" ]; then
  PROVIDER_JSON="$(jq -n --arg p "$PROVIDER" '{only: [$p], allow_fallbacks: false}')"
else
  PROVIDER_JSON="null"
fi

PAYLOAD="$(jq -n --arg model "$MODEL" --arg content "$USER_CONTENT" --argjson maxt "$MAX_TOKENS" --argjson prov "$PROVIDER_JSON" \
  '{model: $model, messages: [{role: "user", content: $content}], max_tokens: $maxt, temperature: 0.3}
   + (if $prov == null then {} else {provider: $prov} end)')"

mkdir -p "$(dirname "$OUTPUT_FILE")"

wywolaj() {  # $1 = klucz
  curl -sS --max-time "$TIMEOUT" -X POST "https://openrouter.ai/api/v1/chat/completions" \
    -H "Authorization: Bearer $1" -H "Content-Type: application/json" \
    -H "HTTP-Referer: https://aiwbiznesie.pl" -H "X-Title: cross-model-review" \
    -d "$PAYLOAD" -w '\n__HTTP__%{http_code}'
}

RAW="$(wywolaj "$KEY")"
HTTP="${RAW##*__HTTP__}"; BODY="${RAW%$'\n'__HTTP__*}"
if [ "$HTTP" = "401" ] || [ "$HTTP" = "402" ]; then
  echo "WARN: $KEY_NAME → HTTP $HTTP, próbuję OPENROUTER_API_KEY_STALY" >&2
  KEY2="$(wczytaj_klucz OPENROUTER_API_KEY_STALY)"
  [ -n "$KEY2" ] || { echo "ERROR: brak klucza zapasowego" >&2; exit 1; }
  RAW="$(wywolaj "$KEY2")"; HTTP="${RAW##*__HTTP__}"; BODY="${RAW%$'\n'__HTTP__*}"
fi
[ "$HTTP" = "200" ] || { echo "ERROR: OpenRouter HTTP $HTTP: $(echo "$BODY" | head -c 400)" >&2; exit 1; }

CONTENT="$(echo "$BODY" | jq -r '.choices[0].message.content // .error.message // ""')"
[ -n "$CONTENT" ] || { echo "ERROR: pusta odpowiedź: $(echo "$BODY" | head -c 400)" >&2; exit 1; }

USED_MODEL="$(echo "$BODY" | jq -r '.model // "?"')"; USED_PROV="$(echo "$BODY" | jq -r '.provider // "?"')"
PT="$(echo "$BODY" | jq -r '.usage.prompt_tokens // 0')"; CT="$(echo "$BODY" | jq -r '.usage.completion_tokens // 0')"

{ echo "$CONTENT"; echo; echo "---"; echo "_model: $USED_MODEL · dostawca: $USED_PROV · tokeny: $PT wej. / $CT wyj._"; } > "$OUTPUT_FILE"
echo "OK: OpenRouter review ($USED_MODEL @ $USED_PROV, $PT/$CT tok.) zapisany do $OUTPUT_FILE"
