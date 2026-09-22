#!/usr/bin/env bash
# open-code-review (`ocr`) jako CZWARTY głos cross-model-review — recenzja KODU z kotwicami plik:linia.
#
# Użycie:
#   ocr-review.sh <ścieżka-pliku-lub-katalogu> [-o wynik.md] [--dostawca ollama|openrouter] [--efekt low|medium|high]
#   ocr-review.sh --commit <sha> [--repo <katalog>] [-o wynik.md] [--dostawca ...]
#   ocr-review.sh --from <ref> --to <ref> [--repo <katalog>] [-o wynik.md]
#   ocr-review.sh --working [--repo <katalog>]            # niezacommitowane zmiany
#
# Domyślny dostawca: LOKALNA OLLAMA (0 zł, kod NIE opuszcza Maca). Model z roli `lokalny_tekst`
# w Project Master/config/routing-modeli.json — NIE na sztywno (lekcja 14.09).
# `--dostawca openrouter` = rola `kolo_zapasowe_1` (DeepInfra przypięty, rozumowanie wyłączone) —
# to CHMURA: zero kodu klientów, zero sekretów; skrypt skanuje wejście i odmawia przy trafieniu.
#
# Czego skrypt NIE robi (robi to PM): status „potwierdzone / podejrzenie", licznik fałszywych
# alarmów, druga metoda weryfikacji. `ocr` daje tylko `category` + `severity` (ADR-0011).
#
# BRAMKA NA ARTEFAKT (lekcje 31.08 / 10.09 + zgłoszenia #1027/#1196 „exit 0 przy porażce"):
#   kod wyjścia i pole `status` NIE są dowodem — sprawdzamy plik JSON, liczbę przejrzanych plików
#   policzoną PRZED biegiem, awarie narzędzi i ślady degradacji (429/timeout/budget) na stderr.

set -euo pipefail

PM_DIR="${PM_DIR:-$HOME/projekty/Project Master}"
OCR_DIR="$PM_DIR/scripts/open-code-review"
OCR_BIN="$OCR_DIR/bin/opencodereview-darwin-arm64"
ROUTING_SH="$PM_DIR/config/routing-modeli.sh"
PRAWDZIWY_HOME="$HOME"

DOSTAWCA="ollama"
WYNIK=""
SCIEZKA=""
COMMIT=""
FROM=""
TO=""
REPO=""
WORKING=0
EFEKT=""
TIMEOUT_MIN="${OCR_TIMEOUT_MIN:-20}"

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--output)    WYNIK="$2"; shift 2 ;;
    --dostawca)     DOSTAWCA="$2"; shift 2 ;;
    --commit)       COMMIT="$2"; shift 2 ;;
    --from)         FROM="$2"; shift 2 ;;
    --to)           TO="$2"; shift 2 ;;
    --repo)         REPO="$2"; shift 2 ;;
    --working)      WORKING=1; shift ;;
    --efekt)        EFEKT="$2"; shift 2 ;;
    -h|--help)      sed -n '2,25p' "$0"; exit 0 ;;
    -*)             echo "ERROR: nieznana opcja: $1" >&2; exit 1 ;;
    *)              SCIEZKA="$1"; shift ;;
  esac
done

[ -x "$OCR_BIN" ] || { echo "ERROR: brak binarki $OCR_BIN — uruchom $OCR_DIR/install.sh" >&2; exit 1; }
[ -f "$ROUTING_SH" ] || { echo "ERROR: brak loadera routingu $ROUTING_SH" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: brak jq" >&2; exit 1; }

# ── tryb: scan (ścieżka) albo review (diff) ──────────────────────────────────
TRYB=""
if [ -n "$COMMIT" ] || [ -n "$FROM" ] || [ "$WORKING" -eq 1 ]; then
  TRYB="review"
elif [ -n "$SCIEZKA" ]; then
  TRYB="scan"
else
  echo "ERROR: podaj ścieżkę do skanu albo --commit/--from…--to/--working. Pomoc: $0 --help" >&2
  exit 1
fi

if [ "$TRYB" = "scan" ]; then
  [ -e "$SCIEZKA" ] || { echo "ERROR: nie ma takiej ścieżki: $SCIEZKA" >&2; exit 1; }
  SCIEZKA_ABS="$(cd "$(dirname "$SCIEZKA")" && pwd)/$(basename "$SCIEZKA")"
  REPO="${REPO:-$(cd "$(dirname "$SCIEZKA_ABS")" && git rev-parse --show-toplevel 2>/dev/null || dirname "$SCIEZKA_ABS")}"
  REPO="$(cd "$REPO" && pwd)"
  # GOTCHA (16.09, złapana przez bramkę): `--path` ABSOLUTNY daje „No files changed" i `status: skipped`
  # BEZ żadnego błędu — ocr dopasowuje ścieżki względem korzenia repo. Zawsze ścieżka względna.
  SCIEZKA_REL="${SCIEZKA_ABS#"$REPO"/}"
  [ "$SCIEZKA_REL" != "$SCIEZKA_ABS" ] || { echo "ERROR: $SCIEZKA_ABS leży poza repo $REPO" >&2; exit 1; }
else
  REPO="${REPO:-$PWD}"
  REPO="$(cd "$REPO" && git rev-parse --show-toplevel)"
fi

# ── prawda policzona PRZED biegiem: wejście i oczekiwana liczba plików ───────
if [ "$TRYB" = "scan" ]; then
  if [ -d "$SCIEZKA_ABS" ]; then
    WEJSCIE_B=$(find "$SCIEZKA_ABS" -type f ! -path '*/.git/*' -exec cat {} + 2>/dev/null | wc -c | tr -d ' ')
  else
    WEJSCIE_B=$(wc -c < "$SCIEZKA_ABS" | tr -d ' ')
  fi
  OPIS_WEJSCIA="scan: $SCIEZKA_REL"
else
  if [ -n "$COMMIT" ]; then
    DIFF_TXT="$(git -C "$REPO" show --format= --unified=3 "$COMMIT")"
    OPIS_WEJSCIA="review: commit $COMMIT w $(basename "$REPO")"
  elif [ -n "$FROM" ]; then
    DIFF_TXT="$(git -C "$REPO" diff --unified=3 "$FROM...${TO:-HEAD}")"
    OPIS_WEJSCIA="review: $FROM…${TO:-HEAD} w $(basename "$REPO")"
  else
    DIFF_TXT="$(git -C "$REPO" diff --unified=3 HEAD)"
    OPIS_WEJSCIA="review: niezacommitowane zmiany w $(basename "$REPO")"
  fi
  WEJSCIE_B=$(printf '%s' "$DIFF_TXT" | wc -c | tr -d ' ')
  OCZEKIWANE_PLIKI=$(printf '%s' "$DIFF_TXT" | grep -c '^diff --git ' || true)
  [ "$WEJSCIE_B" -gt 0 ] || { echo "ERROR: pusty diff — nie ma czego recenzować" >&2; exit 1; }
fi

# ── dostawca: model z routingu, nigdy na sztywno ────────────────────────────
# shellcheck source=/dev/null
source "$ROUTING_SH"

PRACA="$(mktemp -d "${TMPDIR:-/tmp}/ocr-review-XXXXXX")"
trap 'rm -rf "$PRACA"' EXIT
FAKEHOME="$PRACA/home"
mkdir -p "$FAKEHOME/.opencodereview"

case "$DOSTAWCA" in
  ollama)
    MODEL="$(rola_model lokalny_tekst)" || exit 1
    ENDPOINT="$(rola_param lokalny_tekst endpoint)"
    [ -n "$ENDPOINT" ] || ENDPOINT="http://localhost:11434"
    curl -sS --max-time 3 "${ENDPOINT}/api/tags" >/dev/null 2>&1 \
      || { echo "ERROR: Ollama niedostępna pod ${ENDPOINT}. Uruchom: ollama serve" >&2; exit 1; }
    # Gotcha (pilot 16.09): bez PROTOCOL=openai `ocr` zakłada Anthropic i skleja URL+/v1/messages → /v1/v1/… 404
    export OCR_LLM_URL="${ENDPOINT}/v1"
    export OCR_LLM_PROTOCOL="openai"
    export OCR_LLM_TOKEN="ollama-local-no-auth"
    export OCR_LLM_MODEL="$MODEL"
    OPIS_SILNIKA="lokalna Ollama · $MODEL · 0 zł, kod nie opuszcza Maca"
    ;;
  openrouter)
    MODEL="$(rola_model kolo_zapasowe_1)" || exit 1
    EXTRA_BODY="$(jq -n --argjson prov "$(rola_param kolo_zapasowe_1 provider_order)" \
      '{provider: {only: $prov, allow_fallbacks: false}, reasoning: {enabled: false}}')"
    # Granica danych (§5): chmura → skan sekretów PRZED wysyłką
    if [ "$TRYB" = "scan" ]; then MATERIAL="$(cat "$SCIEZKA" 2>/dev/null || find "$SCIEZKA" -type f ! -path '*/.git/*' -exec cat {} + )"; else MATERIAL="$DIFF_TXT"; fi
    if printf '%s' "$MATERIAL" | grep -qE 'sk_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|sbp_[A-Za-z0-9]{20,}|service_role|eyJ[A-Za-z0-9_-]{30,}|PESEL|BEGIN (RSA|OPENSSH) PRIVATE'; then
      echo "ERROR: materiał wygląda na zawierający sekret/dane osobowe — NIE wysyłam do OpenRoutera (użyj domyślnej Ollamy)" >&2
      exit 2
    fi
    unset MATERIAL
    # Sekret NIE trafia do config.json: `ocr` pobiera go przez auth_token_cmd (§9)
    # auth_token_cmd idzie przez `sh -c` → ścieżka z SPACJAMI („Project Master") musi być w apostrofach,
    # inaczej `sh` dzieli ją na słowa i zwraca 127 (złapane 16.09 przy pierwszym biegu na OpenRouterze).
    jq -n --arg model "$MODEL" --arg cmd "'$OCR_DIR/token-openrouter.sh'" --argjson eb "$EXTRA_BODY" \
      '{llm: {url: "https://openrouter.ai/api/v1", protocol: "openai", model: $model,
              auth_token_cmd: $cmd, extra_body: $eb}}' > "$FAKEHOME/.opencodereview/config.json"
    chmod 600 "$FAKEHOME/.opencodereview/config.json"
    export OCR_VAULT="$PRAWDZIWY_HOME/.claude/shared-credentials.env"
    OPIS_SILNIKA="OpenRouter · $MODEL (dostawca przypięty) · CHMURA"
    ;;
  *) echo "ERROR: nieznany dostawca: $DOSTAWCA (ollama|openrouter)" >&2; exit 1 ;;
esac

# ── bieg ────────────────────────────────────────────────────────────────────
JSON="$PRACA/wynik.json"
LOG="$PRACA/stderr.log"
ARG=( "--format" "json" "--audience" "agent" "-o" "$JSON" "--timeout" "$TIMEOUT_MIN" )
[ -n "$EFEKT" ] && [ "$TRYB" = "review" ] && ARG+=( "--effort" "$EFEKT" )

if [ "$TRYB" = "scan" ]; then
  CEL=( "scan" "--path" "$SCIEZKA_REL" "--repo" "$REPO" )
else
  CEL=( "review" "--repo" "$REPO" )
  [ -n "$COMMIT" ] && CEL+=( "--commit" "$COMMIT" )
  [ -n "$FROM" ] && CEL+=( "--from" "$FROM" "--to" "${TO:-HEAD}" )
fi

# Prawda o liczbie plików policzona PRZED biegiem — `--preview` nie woła modelu.
# Zarazem szybka porażka: „No files changed" tu = `status: skipped` po 2 minutach mielenia.
PODGLAD="$(HOME="$FAKEHOME" "$OCR_BIN" "${CEL[@]}" --preview 2>&1 || true)"
OCZEKIWANE_PLIKI="$(printf '%s' "$PODGLAD" | sed -n 's/.*Will review (\([0-9]*\)).*/\1/p' | head -1)"
if [ -z "$OCZEKIWANE_PLIKI" ] || [ "$OCZEKIWANE_PLIKI" -eq 0 ] 2>/dev/null; then
  echo "ERROR: ocr nie widzi żadnego pliku do recenzji — nie uruchamiam modelu. Podgląd:" >&2
  printf '%s\n' "$PODGLAD" | head -5 >&2
  echo "Częsta przyczyna: ścieżka spoza repo albo objęta wykluczeniami (rule.json / --exclude)." >&2
  exit 1
fi

ARG=( "${CEL[@]}" "${ARG[@]}" )

echo "ocr $TRYB · $OPIS_WEJSCIA"
echo "silnik: $OPIS_SILNIKA · wejście: ${WEJSCIE_B} B · oczekiwane pliki: ${OCZEKIWANE_PLIKI}"

KOD=0
HOME="$FAKEHOME" "$OCR_BIN" "${ARG[@]}" 2> >(tee "$LOG" >&2) || KOD=$?

# ── BRAMKA NA ARTEFAKT (kod wyjścia to NIE dowód) ───────────────────────────
[ -s "$JSON" ] || { echo "ERROR: brak/pusty artefakt JSON (kod wyjścia $KOD) — recenzja SIĘ NIE ODBYŁA. Log:" >&2; tail -20 "$LOG" >&2; exit 1; }
jq -e . "$JSON" >/dev/null 2>&1 || { echo "ERROR: artefakt JSON nie parsuje się — recenzja niewiarygodna" >&2; exit 1; }

STATUS="$(jq -r '.status // "?"' "$JSON")"
PRZEJRZANE="$(jq -r '.summary.files_reviewed // 0' "$JSON")"
AWARIE="$(jq -r '.tool_calls.failure // 0' "$JSON")"
KOMENTARZE="$(jq -r '.comments | length' "$JSON")"

OSTRZEZENIA=()
# Statusy w kodzie narzędzia: success | skipped | completed_with_errors | completed_with_warnings
# + stan terminalny manifestu (`complete`, `partial`). `scan` kończy „success", `review` — „complete".
case "$STATUS" in
  success|complete) ;;
  *) OSTRZEZENIA+=("status narzędzia = \"$STATUS\" (oczekiwane \"success\" lub \"complete\")") ;;
esac
[ "$AWARIE" -eq 0 ] 2>/dev/null || OSTRZEZENIA+=("narzędzie zgłosiło $AWARIE nieudanych wywołań")
if [ "$PRZEJRZANE" -lt "$OCZEKIWANE_PLIKI" ]; then
  OSTRZEZENIA+=("przejrzano $PRZEJRZANE z $OCZEKIWANE_PLIKI plików policzonych PRZED biegiem")
fi
# Degradacja cichnie w statusie — widać ją tylko na stderr (pilot 16.09: 429 od DeepInfry, status: success)
if grep -qiE '429|rate.?limit|too many requests|timed out|timeout|failed|budget' "$LOG" 2>/dev/null; then
  SLAD="$(grep -iEm3 '429|rate.?limit|too many requests|timed out|timeout|failed|budget' "$LOG" | tr '\n' ' ' | cut -c1-300)"
  OSTRZEZENIA+=("ślad degradacji na stderr: $SLAD")
fi

# ── render markdown ─────────────────────────────────────────────────────────
WYNIK="${WYNIK:-$PWD/ocr-review-$(date +%Y%m%d-%H%M%S).md}"
mkdir -p "$(dirname "$WYNIK")"
printf '%s\n' "${OSTRZEZENIA[@]:-}" > "$PRACA/ostrzezenia.txt"

OCR_JSON="$JSON" OCR_OSTRZ="$PRACA/ostrzezenia.txt" OCR_OPIS="$OPIS_WEJSCIA" \
OCR_SILNIK="$OPIS_SILNIKA" OCR_WEJSCIE_B="$WEJSCIE_B" OCR_OCZEK="$OCZEKIWANE_PLIKI" \
OCR_KOD="$KOD" python3 - "$WYNIK" <<'PY'
import json, os, sys

d = json.load(open(os.environ["OCR_JSON"], encoding="utf-8"))
ostrz = [l for l in open(os.environ["OCR_OSTRZ"], encoding="utf-8").read().splitlines() if l.strip()]
s = d.get("summary", {})
out = []

out.append("# Recenzja open-code-review (`ocr`)\n")
out.append(f"**Wejście:** {os.environ['OCR_OPIS']} · {os.environ['OCR_WEJSCIE_B']} B · "
           f"oczekiwane pliki: {os.environ['OCR_OCZEK']}  ")
out.append(f"**Silnik:** {os.environ['OCR_SILNIK']}  ")
out.append(f"**Bieg:** status `{d.get('status','?')}` · przejrzane pliki {s.get('files_reviewed','?')} · "
           f"znaleziska {len(d.get('comments', []))} · tokeny {s.get('total_tokens','?')} · czas {s.get('elapsed','?')}\n")

if ostrz:
    out.append("> ⚠️ **OSTRZEŻENIE — bieg zdegradowany, wynik NIEPEŁNY.** Nie traktuj go jako recenzji kompletnej:\n>")
    for o in ostrz:
        out.append(f">- {o}")
    out.append("")
else:
    out.append("> ✅ Bramka artefaktu: bez śladów degradacji (status, liczba plików, awarie narzędzi, stderr).\n")

out.append("## Znaleziska\n")
com = d.get("comments", [])
if not com:
    out.append("_Brak znalezisk._\n")
else:
    out.append("| # | plik:linia | severity | kategoria | opis |")
    out.append("|---|---|---|---|---|")
    for i, c in enumerate(com, 1):
        sl, el = c.get("start_line", "?"), c.get("end_line", "?")
        linia = f"{sl}" if sl == el else f"{sl}–{el}"
        opis = " ".join(str(c.get("content", "")).split())
        if len(opis) > 400:
            opis = opis[:397] + "…"
        opis = opis.replace("|", "\\|")
        out.append(f"| {i} | `{c.get('path','?')}:{linia}` | {c.get('severity','?')} | "
                   f"{c.get('category','?')} | {opis} |")
    out.append("")
    out.append("### Kotwice (`existing_code` — fragment do sprawdzenia w pliku)\n")
    for i, c in enumerate(com, 1):
        sl, el = c.get("start_line", "?"), c.get("end_line", "?")
        linia = f"{sl}" if sl == el else f"{sl}–{el}"
        out.append(f"**{i}. `{c.get('path','?')}:{linia}`**\n")
        out.append("```\n" + str(c.get("existing_code", "")).rstrip() + "\n```\n")

ps = d.get("project_summary")
if ps:
    out.append("## Podsumowanie narzędzia\n")
    out.append(str(ps).strip() + "\n")

out.append("---")
out.append("_`ocr` daje `category` i `severity` — NIE daje statusu potwierdzone/podejrzenie "
           "ani licznika fałszywych alarmów (ADR-0011). Te dwie rzeczy dokłada PM, po sprawdzeniu kotwic._")

open(sys.argv[1], "w", encoding="utf-8").write("\n".join(out) + "\n")
PY

# ── bramka rozmiaru wyniku (lekcja 10.09: plik 194 B przy diffie 63 kB) ─────
WYJSCIE_B=$(wc -c < "$WYNIK" | tr -d ' ')
if [ "$WEJSCIE_B" -gt 2048 ] && [ "$WYJSCIE_B" -lt 300 ]; then
  echo "ERROR: wynik $WYJSCIE_B B przy wejściu $WEJSCIE_B B — to nie jest recenzja. Plik: $WYNIK" >&2
  exit 1
fi

if [ "${#OSTRZEZENIA[@]}" -gt 0 ] && [ -n "${OSTRZEZENIA[0]:-}" ]; then
  echo "UWAGA: bieg zdegradowany (${#OSTRZEZENIA[@]} ostrzeżeń) — szczegóły w nagłówku wyniku." >&2
fi
echo "OK: $KOMENTARZE znalezisk zapisanych do $WYNIK (${WYJSCIE_B} B)"
