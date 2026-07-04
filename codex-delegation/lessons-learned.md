# Codex Delegation — Lessons Learned

Pamięć skilla — lekcje z produkcyjnych delegacji. Aktualizuj po każdej sesji, w której
odkryto nowy problem lub wzorzec. Claude: czytaj ten plik na początku sesji z codex-delegation.

## Lekcje

- [2026-03-18] Skill utworzony. Brak lekcji produkcyjnych — skill jeszcze nie był testowany na żywo. Pierwsze lekcje pojawią się po pierwszych delegacjach.
- [2026-06-09] ZAWIS NA STDIN (codex-cli 0.125.0): `codex exec --sandbox workspace-write "$(cat prompt.md)"` uruchomiony w **background** (run_in_background) ZAWISA na "Reading additional input from stdin..." mimo że prompt jest w argumencie. Proces żyje, 0 progresu, git diff pusty (40 min stracone w KG). Przyczyna: bez TTY i bez EOF na stdin codex czeka na dodatkowy input w nieskończoność. FIX: ZAWSZE dopisuj `< /dev/null` na końcu wywołania → `codex exec --sandbox workspace-write "$PROMPT" < /dev/null`. Daje natychmiastowy EOF. Dotyczy każdego background/non-interactive wywołania codex exec.

## Wzorce sukcesu

- Codex najlepszy do: izolowane komponenty, CSS/styling, testy, literówki/polskie znaki.
- ZAWSZE dodawaj kontekst projektu w prompcie (stack, konwencje, ścieżki) — Codex nie "wie" co jest w projekcie.
- Sekcja "NIE ruszaj" w prompcie zapobiega modyfikacji plików spoza scope.
- Weryfikacja przez `git diff --name-only` + kompilacja = minimum po każdej delegacji.
