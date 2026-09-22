#!/usr/bin/env bash
# Wzajemna recenzja (Wzorzec D) — dwie rundy, dwa modele, jeden przebieg.
#
# Runda 1: Codex i Qwen recenzują dokument niezależnie, każdy zwraca STATUS.
# Runda 2: każdy dostaje odpowiedź drugiego i ma wskazać, co tamten przeoczył,
#          co jest błędne, i czy zmienia własny werdykt.
#
# Po co: bez rundy 2 dwa modele piszą równoległe monologi, a rozbieżność między nimi
# rozstrzyga autor recenzowanego planu — czyli ten, kto ma najmniej powodów, by ją dostrzec.
# Pierwszy bieg (9.08.2026) pokazał, że pod pozorną zgodą "oba NO_GO" leżały dwie
# sprzeczne architektury, a jeden z modeli po argumencie drugiego zmienił zdanie.
#
# Użycie:
#   peer-review.sh <plik-do-recenzji> [katalog-wyjściowy] [pytania-dodatkowe]
#
# Wynik: r1-codex.md, r1-qwen.md, r2-codex.md, r2-qwen.md + podsumowanie werdyktów.

set -uo pipefail

PLIK="${1:?Podaj plik do recenzji, np. PLAN.md}"
KAT="${2:-.}"
DODATKOWE="${3:-}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ -f "$PLIK" ]] || { echo "BŁĄD: nie ma pliku $PLIK"; exit 1; }
mkdir -p "$KAT"
KAT_ABS="$(cd "$KAT" && pwd)"
PLIK_ABS="$(cd "$(dirname "$PLIK")" && pwd)/$(basename "$PLIK")"

# IZOLACJA (dodane 2026-08-31 po incydencie): Codex dostaje wlasny, PUSTY katalog
# roboczy z KOPIA wylacznie recenzowanego pliku. Bez tego widzi cala zawartosc $KAT
# i przy rownoleglych biegach potrafi zrecenzowac CUDZY plik — 31.08 recenzja SOTA RAG
# zaciagnela diff.txt rownoleglej sesji CRM i oceniala nie ten kod.
IZOLKA="$(mktemp -d -t cross-review)"
cp "$PLIK_ABS" "$IZOLKA/"
trap 'rm -rf "$IZOLKA"' EXIT

PREAMBLE="$(cat "$SKILL_DIR/PREAMBLE.txt" 2>/dev/null || true)"
NAZWA="$(basename "$PLIK")"

R1_PROMPT="Przeczytaj plik $NAZWA i zrecenzuj go jako niezależny recenzent.
ZACZNIJ ODPOWIEDŹ OD LINII: STATUS: [GO_NO_BLOCKING_ISSUES | GO_WITH_CHANGES | NO_GO]
Następnie: realizm, ryzyka, pominięcia, kolejność kroków, rekomendacje.
Bądź krytyczny. Nie chwal — szukaj problemów. Odpowiadaj po polsku.
$DODATKOWE"

r2_prompt() {  # $1 = nazwa pliku z cudzą recenzją
  cat <<EOF
Oto recenzja tego samego dokumentu napisana przez INNY model — plik $1.
Twoje zadanie NIE polega na streszczeniu jej ani na uprzejmości.

1) Wskaż konkretnie, co ta recenzja PRZEOCZYŁA — punkty, których w niej nie ma, a powinny być.
2) Wskaż, co jest w niej BŁĘDNE — twierdzenia nieprawdziwe lub oparte na złym założeniu.
3) Czy któryś jej argument zmienia TWÓJ werdykt? Jeśli tak, powiedz wprost który i dlaczego.
4) ZAKOŃCZ LINIĄ: STATUS_PO_PEER_REVIEW: [BEZ_ZMIAN | ZMIENIONY_NA_<verdict>] + jedno zdanie uzasadnienia.

Nie zgadzaj się dla świętego spokoju. Zgoda bez wskazania KTÓREGO argumentu dotyczy
jest bezwartościowa i będzie potraktowana jak brak odpowiedzi. Odpowiadaj po polsku.
EOF
}

# --skip-git-repo-check + </dev/null — bez nich codex przerywa CICHO (kod 0, brak pliku)
# 2026-08-31: `--full-auto` USUNIETE w codex-cli 0.150.1 (objaw: kod 0, brak pliku wynikowego —
# ta sama cicha awaria co przy braku --skip-git-repo-check). Recenzja niczego nie zapisuje,
# wiec wlasciwy nastepca to `--sandbox read-only`, nie `--approve-for-me` (workspace-write).
codex_bieg() {  # $1 = prompt, $2 = plik wyjściowy
  # -c mcp_servers='{}' — bez tego nieudany start serwera MCP zabija bieg CICHO
  # (kod 0, brak pliku -o) przy `approval: never`. Recenzja nie potrzebuje MCP.
  codex exec -c model_reasoning_effort='"high"' -c mcp_servers='{}' \
    --sandbox read-only --skip-git-repo-check \
    -o "$2" "$PREAMBLE

$1" </dev/null > "${2%.md}.log" 2>&1
  if [ ! -s "$2" ]; then
    echo "BLAD: codex nie utworzyl $2 (kod wyjscia $?) — ogon logu:" >&2
    tail -5 "${2%.md}.log" >&2
    return 1
  fi
}

echo "== RUNDA 1: niezależne recenzje =="
( cd "$IZOLKA" && codex_bieg "$R1_PROMPT" "$KAT_ABS/r1-codex.md" ) &
C1=$!
"$SKILL_DIR/qwen-review.sh" "$PLIK_ABS" "Jesteś niezależnym recenzentem. $R1_PROMPT" \
  "$KAT/r1-qwen.md" > "$KAT/r1-qwen.log" 2>&1 &
Q1=$!
wait $C1 $Q1

for f in r1-codex.md r1-qwen.md; do
  # Kod wyjścia nie jest dowodem — sprawdzamy ARTEFAKT (lekcja PM 22.06)
  [[ -s "$KAT/$f" ]] || { echo "BŁĄD: runda 1 nie wyprodukowała $f — zajrzyj do ${f%.md}.log"; exit 2; }
done
echo "   runda 1 gotowa"

echo "== RUNDA 2: wzajemna recenzja =="
cp "$KAT/r1-codex.md" "$KAT/peer-dla-qwena.md"
# Do izolatki dokladamy WYLACZNIE obie recenzje z rundy 1 — Codex ma je porownac,
# a nadal nie moze zobaczyc niczego z cudzego biegu w $KAT.
cp "$KAT/r1-codex.md" "$KAT/r1-qwen.md" "$IZOLKA/"
( cd "$IZOLKA" && codex_bieg "Napisałeś recenzję dokumentu $NAZWA (twoja: r1-codex.md).
$(r2_prompt r1-qwen.md)
Przeczytaj oba pliki w tym katalogu." "$KAT_ABS/r2-codex.md" ) &
C2=$!
"$SKILL_DIR/qwen-review.sh" "$KAT/peer-dla-qwena.md" \
  "To recenzja dokumentu napisana przez INNY model. Ty napisałeś własną recenzję tego samego dokumentu.
$(r2_prompt 'powyższy')" "$KAT/r2-qwen.md" > "$KAT/r2-qwen.log" 2>&1 &
Q2=$!
wait $C2 $Q2

echo
echo "=========== WERDYKTY ==========="
for f in r1-codex r1-qwen r2-codex r2-qwen; do
  if [[ -s "$KAT/$f.md" ]]; then
    W="$(grep -m1 -E '^STATUS(_PO_PEER_REVIEW)?:' "$KAT/$f.md" 2>/dev/null \
        || tail -3 "$KAT/$f.md" | tr '\n' ' ')"
    printf '  %-10s %s\n' "$f" "${W:0:150}"
  else
    printf '  %-10s BRAK PLIKU — sprawdź %s.log\n' "$f" "$f"
  fi
done
cat <<'EOF'

Jak to czytać (pełna tabela w SKILL.md, Wzorzec D):
  - oba BEZ_ZMIAN + te same ryzyka   -> najmocniejszy sygnał, jaki daje ten skill
  - któryś ZMIENIONY_NA_             -> przeczytaj argument, który go przekonał
  - oba BEZ_ZMIAN, ale podważają się -> realna rozbieżność, tu dopiero Gemini jako trzeci głos
  - nagła zgoda bez wskazania argumentu -> zgoda pusta, traktuj jak brak odpowiedzi

Sprawdź też DRYF: porównaj werdykt z rundy 2 z treścią rundy 1 TEGO SAMEGO modelu,
nie tylko z drugim modelem. Model potrafi zaprzeczyć sam sobie między rundami.
EOF
