#!/usr/bin/env python3
"""
Deleguje zadanie do Gemini 3.1 Pro API i zapisuje wynik.
Wywoływany z Claude Code bez udziału użytkownika.

Użycie:
    # Proste pytanie
    python delegate-to-gemini.py "Zrecenzuj ten plan: ..."

    # Z plikiem kontekstu
    python delegate-to-gemini.py --context-file plan.md "Zrecenzuj ten plan"

    # Z plikiem kontekstu i zapisem do pliku
    python delegate-to-gemini.py --context-file plan.md --output review.md "Zrecenzuj ten plan"

    # Z wieloma plikami kontekstu
    python delegate-to-gemini.py --context-file plan.md --context-file code.ts "Zrecenzuj plan i kod"
"""

import argparse
import json
import os
import sys
import time
import requests
from pathlib import Path
from datetime import datetime


GEMINI_MODEL = "gemini-2.5-flash"  # 2026-06-24: gemini-3.5-flash zwraca 503 "high demand" (znany problem Google po premierze, dotyka też paid). 2.5-flash stabilny. Wróć do 3.5-flash gdy odetka.
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent"
DEFAULT_MAX_TOKENS = 8192
DEFAULT_TEMPERATURE = 0.3
# Thinking budget: 0 = off (default, dla streszczeń/tłumaczeń/ekstrakcji — 2x szybciej, 8x taniej)
# >0 = włączone thinking (dla strategic review / cross-model review / analizy architektonicznej)
# Empirycznie 2026-05-21: thinking=0 dla "stolica Polski" = 0.8s vs 1.7s, 27 tokens vs 220.
DEFAULT_THINKING_BUDGET = 0


def get_api_key() -> str:
    """Pobiera Google API key z env lub credentials vault."""
    key = os.environ.get("GOOGLE_GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if key:
        return key

    # Szukaj w credentials vault
    vault_paths = [
        Path.home() / ".claude/projects/-Users-dariuszciesielski-projekty-Project-Master/credentials.env",
    ]
    for vault in vault_paths:
        if vault.exists():
            with open(vault) as f:
                for line in f:
                    line = line.strip()
                    if line.startswith("GOOGLE_GEMINI_API_KEY="):
                        return line.split("=", 1)[1].strip('"').strip("'")

    print("[BŁĄD] Brak GOOGLE_GEMINI_API_KEY w env lub credentials vault")
    sys.exit(1)


def call_gemini(prompt: str, api_key: str, temperature: float = DEFAULT_TEMPERATURE,
                max_tokens: int = DEFAULT_MAX_TOKENS,
                thinking_budget: int = DEFAULT_THINKING_BUDGET,
                grounding: bool = False) -> dict:
    """Wywołuje Gemini API i zwraca odpowiedź."""
    start = time.time()

    generation_config = {
        "temperature": temperature,
        "maxOutputTokens": max_tokens,
        "thinkingConfig": {"thinkingBudget": thinking_budget},
    }

    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": generation_config,
    }
    if grounding:
        # Google Search grounding — research online z aktualnymi źródłami (§25 CLAUDE.md)
        payload["tools"] = [{"google_search": {}}]

    resp = requests.post(
        GEMINI_API_URL,
        headers={
            "x-goog-api-key": api_key,
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=450,
    )

    elapsed = time.time() - start

    if resp.status_code != 200:
        return {
            "error": f"HTTP {resp.status_code}: {resp.text[:500]}",
            "elapsed": elapsed,
        }

    data = resp.json()
    candidates = data.get("candidates", [])
    if not candidates:
        return {
            "error": f"Brak candidates w odpowiedzi: {json.dumps(data)[:500]}",
            "elapsed": elapsed,
        }

    text = candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
    usage = data.get("usageMetadata", {})

    return {
        "text": text,
        "input_tokens": usage.get("promptTokenCount", 0),
        "output_tokens": usage.get("candidatesTokenCount", 0),
        "thinking_tokens": usage.get("thoughtsTokenCount", 0),
        "total_tokens": usage.get("totalTokenCount", 0),
        "elapsed": elapsed,
        "model": GEMINI_MODEL,
    }


def main():
    parser = argparse.ArgumentParser(description=f"Deleguj zadanie do {GEMINI_MODEL}")
    parser.add_argument("prompt", help="Treść zadania/pytania")
    parser.add_argument("--context-file", action="append", default=[], help="Plik z kontekstem (można podać wielokrotnie)")
    parser.add_argument("--output", help="Plik wyjściowy (domyślnie: stdout)")
    parser.add_argument("--temperature", type=float, default=DEFAULT_TEMPERATURE)
    parser.add_argument("--max-tokens", type=int, default=DEFAULT_MAX_TOKENS)
    parser.add_argument(
        "--thinking-budget",
        type=int,
        default=DEFAULT_THINKING_BUDGET,
        help="Budżet thinking tokens (0=off default — dla streszczeń/tłumaczeń; >0 dla strategic review)",
    )
    parser.add_argument("--json", action="store_true", help="Zwróć pełny JSON z metadanymi")
    parser.add_argument("--grounding", action="store_true", help="Włącz Google Search grounding (research online z aktualnymi źródłami, §25 CLAUDE.md)")

    args = parser.parse_args()

    api_key = get_api_key()

    # Zbuduj prompt z kontekstem
    full_prompt = args.prompt
    for cf in args.context_file:
        path = Path(cf)
        if path.exists():
            content = path.read_text()
            full_prompt += f"\n\n--- Plik: {path.name} ---\n{content}\n--- Koniec pliku ---"
        else:
            print(f"[UWAGA] Plik nie istnieje: {cf}", file=sys.stderr)

    # Wywołaj Gemini
    result = call_gemini(full_prompt, api_key, args.temperature, args.max_tokens, args.thinking_budget, args.grounding)

    if "error" in result:
        print(f"[BŁĄD] {result['error']}", file=sys.stderr)
        sys.exit(1)

    # Output
    if args.json:
        output_text = json.dumps(result, ensure_ascii=False, indent=2)
    else:
        output_text = result["text"]

    think = result.get("thinking_tokens", 0)
    think_label = f", thinking={think}" if think else ""

    if args.output:
        Path(args.output).parent.mkdir(parents=True, exist_ok=True)
        with open(args.output, "w") as f:
            f.write(output_text)
        print(
            f"[OK] Zapisano do {args.output} ({result['elapsed']:.1f}s, {result['total_tokens']} tokens{think_label})",
            file=sys.stderr,
        )
    else:
        print(output_text)
        if not args.json:
            print(
                f"\n--- {GEMINI_MODEL} | {result['elapsed']:.1f}s | {result['total_tokens']} tokens{think_label} ---",
                file=sys.stderr,
            )


if __name__ == "__main__":
    main()
