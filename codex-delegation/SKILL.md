---
name: codex-delegation
description: Lekka orkiestracja Claude→Codex CLI — delegowanie prostych zadań do GPT Codex z automatycznym uruchomieniem i weryfikacją. Używaj gdy użytkownik mówi "zlec Codexowi", "deleguj do GPT", "pamiętaj o zespole agentów", "pracuj z Codexem", lub gdy zadanie jest proste i izolowane (1-2 pliki). NIE używaj do złożonych zadań (4+ plików) — do tego jest AI Crew.
---

# Delegowanie zadań: Claude Code → Codex CLI

Lekki tryb orkiestracji dwóch modeli AI. Claude przygotowuje zadanie, uruchamia Codex CLI (`codex exec`), a potem weryfikuje wynik. Bez ręcznych komend — wszystko automatyczne.

## Na początku sesji

1. Przeczytaj `lessons-learned.md` — pamięć skilla z poprzednich sesji
2. Sprawdź `.codex/reports/` — nowe raporty z poprzednich delegacji
3. Gdy Codex fail → sprawdź sekcję "Pułapki" poniżej przed diagnozą

## Kiedy używać (zamiast robić sam lub AI Crew)

| Sygnał od użytkownika | Akcja |
|------------------------|-------|
| "zlec to Codexowi" / "deleguj do GPT" | Uruchom delegację |
| "pamiętaj o zespole agentów" / "pracuj z Codexem" | Włącz tryb delegacji dla bieżącej sesji |
| "możesz zlecać zadania GPT Codex" | Jak wyżej — przypomnienie o dostępności Codexa |
| Zadanie proste, izolowane (1-2 pliki) | Rozważ delegację proaktywnie |

### Trzy poziomy orkiestracji

1. **Sam** — bug fix, konfiguracja, 1-3 pliki → Claude robi bezpośrednio
2. **Claude + Codex** (ten skill) — średnie, izolowane zadania → Claude deleguje, Codex koduje, Claude weryfikuje
3. **AI Crew** (`crew autopilot`) — złożone (4+ plików, design + architektura + review) → pełny pipeline 9 ról

**Domyślnie preferuj poziom 2 nad poziom 3** — AI Crew jest drogi i rzadko potrzebny.

## Pułapki (realne problemy z produkcji)

### 1. Codex CLI nie znaleziony w PATH
**Objaw:** `command not found: codex`
**Przyczyna:** Codex zainstalowany przez npm ale nie w globalnym PATH.
**Fix:** Sprawdź `which codex` lub `npm list -g codex-cli`. Fallback na tryb ręczny.

### 2. Codex exit 0 ale brak outputu
**Objaw:** `codex exec` kończy się sukcesem ale `--output-last-message` nie tworzy pliku.
**Przyczyna:** Codex wykonał zadanie ale nie zwrócił wiadomości tekstowej (np. tylko edytował pliki).
**Fix:** Sprawdzaj `git diff` zamiast polegać na output-last-message. Jeśli diff pokazuje zmiany — Codex zadziałał.

### 3. Rate limit / quota exceeded
**Objaw:** Codex zwraca exit 1 z logiem `429` / `rate limit` / `quota exceeded`.
**Przyczyna:** Za dużo wywołań Codex CLI w krótkim czasie.
**Fix:** Poczekaj 60s i spróbuj ponownie, lub rób sam (Claude). Nie ponawiaj natychmiast.

### 4. Codex modyfikuje pliki spoza scope
**Objaw:** `git diff --name-only` pokazuje pliki, które nie były w liście "Pliki do zmiany".
**Przyczyna:** Prompt za ogólny, Codex "naprawia" też inne rzeczy.
**Fix:** W prompcie dodaj jawną sekcję "NIE ruszaj" z listą plików. Sprawdzaj `git diff --name-only` ZAWSZE po delegacji.

### 5. Timeout przy dużych zadaniach
**Objaw:** Bash tool timeout (120s domyślnie) zabija `codex exec` w trakcie pracy.
**Przyczyna:** Zadanie za duże dla lekkiej delegacji.
**Fix:** Użyj `run_in_background: true` i `timeout: 600000`. Jeśli zadanie >5 minut, prawdopodobnie powinno iść do AI Crew, nie do lekkiej delegacji.

### 6. Codex nie widzi kontekstu projektu
**Objaw:** Codex generuje kod niezgodny z konwencjami projektu (np. brak polskich znaków, złe importy).
**Przyczyna:** Prompt nie zawierał kontekstu projektu (stack, konwencje, ścieżki).
**Fix:** ZAWSZE dodawaj sekcję "Kontekst projektu" w prompcie. Nie zakładaj, że Codex "wie".

## Przepływ automatyczny

```
Użytkownik (głosem): "Dodaj przycisk eksportu CSV"
       │
       ▼
Claude: Ocena → proste, izolowane → delegacja do Codexa
       │
       ▼
Claude: Przygotowuje prompt z kontekstem projektu
       │
       ▼
Claude: Uruchamia `codex exec` (Bash tool, sandbox workspace-write)
       │
       ▼
Claude: Czyta output + sprawdza git diff
       │
       ▼
Claude: Weryfikuje jakość (kompilacja, linting, testy)
       │
       ▼
Claude: Raportuje użytkownikowi wynik
```

## Jak uruchomić Codex CLI

### Komenda bazowa

```bash
codex exec --sandbox workspace-write "TREŚĆ PROMPTU"
```

### Z promptem z pliku

```bash
codex exec --sandbox workspace-write "$(cat .codex/tasks/001-nazwa.md)"
```

### Z invoke-codex.sh (integracja z AI Crew)

```bash
~/.claude/skills/ai-crew/scripts/invoke-codex.sh prompt.md output.md 600
```

## Procedura delegacji (krok po kroku)

### 1. Oceń zadanie

Sprawdź kryteria delegacji:

**→ Codex (deleguj)**
- Zmiany w 1-2 plikach
- Nie wymaga znajomości architektury
- CSS/styling, tekst, placeholder, ikona, label
- Nowy izolowany komponent (z pełnym opisem)
- Testy do istniejącego kodu
- Poprawki literówek, polskich znaków
- Dodanie prostego pola do formularza

**→ Claude (rób sam)**
- Zmiany w 3+ plikach powiązanych
- Wymaga rozumienia przepływu danych
- Integracje z API, bazą danych, auth
- Decyzje architektoniczne

**Zasada nadrzędna:** Codex dostaje zadania, które nawet gdyby wykonał źle, łatwo naprawić.

### 2. Przygotuj prompt

Prompt dla Codexa MUSI zawierać:

```markdown
# Zadanie: [Tytuł]

## Kontekst projektu
- Stack: [np. React 19, Vite, TypeScript, Tailwind v4]
- Konwencje: polskie znaki (ą,ć,ę...) w tekstach UI
- Katalog projektu: [ścieżka]

## Pliki do zmiany
- [ścieżka/plik1.tsx] — [co zmienić]
- [ścieżka/plik2.ts] — [co zmienić]

## NIE ruszaj
- [pliki krytyczne, które Codex ma zostawić]

## Co zrobić
[Jasny, jednoznaczny opis. Bez wieloznaczności.]

## Kryteria akceptacji
- [ ] [Kryterium 1]
- [ ] [Kryterium 2]
- [ ] Kod kompiluje się bez błędów
- [ ] Polskie znaki poprawne
```

### 3. Uruchom Codexa

```bash
# Zapisz prompt do pliku tymczasowego
PROMPT_FILE=$(mktemp /tmp/codex-task-XXXX.md)
cat > "$PROMPT_FILE" << 'PROMPT'
[treść promptu]
PROMPT

# Uruchom Codex CLI
codex exec --sandbox workspace-write "$(cat $PROMPT_FILE)"

# Posprzątaj
rm -f "$PROMPT_FILE"
```

**WAŻNE:** Użyj `run_in_background: true` i `timeout: 600000` jeśli zadanie może trwać dłużej niż 2 minuty.

### 4. Zweryfikuj wynik

Po zakończeniu Codexa:

1. **Sprawdź co zmienił:** `git diff` — czy zmiany są w oczekiwanych plikach
2. **Sprawdź kompilację:** uruchom `npx tsc --noEmit` lub `npm run build`
3. **Sprawdź polskie znaki:** przeskanuj zmienione pliki
4. **Sprawdź czy nie ruszył plików spoza listy:** `git diff --name-only`
5. **Uruchom testy:** jeśli istnieją dla zmienionych modułów

### 5. Komunikaty statusowe (OBOWIĄZKOWE)

Użytkownik MUSI widzieć co się dzieje na każdym etapie. Nie pytaj o zgodę — po prostu informuj.

**Przed uruchomieniem Codexa:**
> Deleguję do Codexa: [krótki opis zadania]. Sandbox: workspace-write.

**Po zakończeniu Codexa:**
> Codex zakończył. Sprawdzam wynik...

**Po weryfikacji — sukces:**
> Codex: OK. [co zrobił]. Kompilacja OK, testy przechodzą. Kontynuuję.

**Po weryfikacji — częściowy sukces:**
> Codex: częściowo OK. [co zrobił], ale [problem]. Naprawiam [co] i kontynuuję.

**Po weryfikacji — porażka:**
> Codex: nie dał rady ([dlaczego]). Robię to sam.

Komunikaty mają być **krótkie, konkretne i bez pytań**. Użytkownik chce widzieć że skill działa — nie chce zatwierdzać każdego kroku.

## Archiwizacja zadań

Zapisuj wykonane zadania w `.codex/` dla historii:

```
.codex/
├── tasks/          # Oczekujące zadania (opcjonalnie — dla trybu ręcznego)
├── reports/        # Raporty z wykonania (automatyczne)
├── archived/       # Historia
└── PROTOCOL.md     # Zasady współpracy
```

Po każdym automatycznym uruchomieniu zapisz krótki raport:

```bash
# .codex/reports/NNN-opis.done.md
echo "# Raport: [tytuł]
Status: DONE | PROBLEM
Tryb: auto (codex exec)
Zmienione pliki: [lista z git diff --name-only]

## Co zrobiono
[Opis zmian]

## Weryfikacja Claude
- Kompilacja: OK/FAIL
- Testy: OK/FAIL/BRAK
- Polskie znaki: OK/POPRAWIONE
" > .codex/reports/NNN-opis.done.md
```

## Tryb ręczny (fallback)

Jeśli Codex CLI nie jest dostępny (`codex --version` fail) lub użytkownik preferuje ręczne zlecanie:

1. Claude tworzy plik zadania w `.codex/tasks/NNN-opis.md`
2. Informuje użytkownika: "Utworzyłem zadanie dla Codexa. Możesz je zlecić kiedy chcesz."
3. Na następnej sesji — Claude sprawdza `.codex/reports/` i weryfikuje

## Wymagania

- **Codex CLI** zainstalowany i w PATH (`codex --version`)
- Jeśli brak — fallback na tryb ręczny lub Claude robi sam
