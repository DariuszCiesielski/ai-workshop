---
name: resume
description: Use when user says "resume", "wznów", "kontynuuj", "dalej", "gdzie skończyliśmy" — restore context and continue work from previous session
---

# Resume Work

Wznów pracę z pełnym kontekstem z poprzedniej sesji.

## Proces

### 1. Załaduj kontekst

Przeczytaj MEMORY.md z katalogu auto-memory projektu. To Twoje główne źródło informacji o stanie pracy.

### 2. Sprawdź repo

Wykonaj równolegle:
- `git status` — czy są niezacommitowane zmiany z poprzedniej sesji
- `git log --oneline -3` — ostatnie commity
- `git branch --show-current` — branch

### 2.5 Załaduj kontekst ekosystemu (KRYTYCZNE — dodane 2026-05-22)

**Cel:** ZANIM zaproponujesz next step lub zadasz pytanie o stack/narzędzia/integracje — wczytaj do kontekstu aktualny stan ekosystemu. Bez tego agent pyta usera o rzeczy które są w plikach.

**Wczytaj w kolejności (równolegle, Read tool):**

1. **`~/projekty/Project Master/.ai/ecosystem/STACK-SNAPSHOT.md`** — kompakt 1-strona, wszystkie aktywne narzędzia ekosystemu (email, cold mail, AI providers, lead gen, hosting, klucze vault). To jest **first stop** ZAWSZE przy każdym `wznów`.

2. **`~/projekty/Project Master/.ai/ecosystem/PRODUCTS.md`** — wykaz 60 projektów + klasyfikacja + duplikaty.

3. **Jeśli pracujesz w konkretnym projekcie** (nie w PM):
   - `<projekt>/CLAUDE.md` — instrukcje per-projekt
   - `<projekt>/.env.local.example` — shape konfiguracji
   - `<projekt>/docs/TOOLS_INVENTORY.md` jeśli istnieje (Lead Generator ma kompletny)

4. **Jeśli STACK-SNAPSHOT.md ma `Data:` starszą niż 7 dni** → komunikat do usera: "STACK-SNAPSHOT.md może być nieaktualny ({data}), sprawdzam realny stan przez grep envów."

**Antywzorzec:** zadawanie userowi pytania "jakiej platformy email/cold-mail/hosting używamy?" bez sprawdzenia tych plików. Wszystkie odpowiedzi są w STACK-SNAPSHOT.md.

**Cross-reference:** ta reguła operacyjnie realizuje zasadę **stack-first przed pytaniami** z `~/projekty/Project Master/CLAUDE.md` §2. To rozszerzenie §32 globalnego CLAUDE.md (sprawdź ekosystem przed propozycją instalacji narzędzia) o lookup istniejącego stacku.

---

### 3. Podsumuj i zaproponuj

Wyświetl krótkie podsumowanie:

```
🔄 Wznawiam pracę
━━━━━━━━━━━━━━━━━

Ostatnia sesja: [data z MEMORY.md]
Zadanie:        [aktywne zadanie z MEMORY.md]
Status:         [co zrobiono / co zostało]

Następny krok:  [konkretna akcja]
```

### 3.1 Forced challenge questions (§27 globalnego CLAUDE.md, dodane 2026-05-04)

**Przed prezentacją next step**, gdy aktywne zadanie jest **nietrywialne** (>15 min, dotyka >1 plik, decyzja architektoniczna, plan strategiczny), wygeneruj 2-3 pytania kwestionujące kierunek:

1. **Scope** — czy zakres jest minimalny do osiągnięcia celu, czy szerszy niż potrzeba?
2. **Alternatywy** — czy istnieje istniejące narzędzie / skill / wzorzec w ekosystemie który już rozwiązuje ten problem? (`ls ~/.claude/skills/ | grep -i <keyword>` przed nowym skillem)
3. **Duplikacja** — czy zadanie nie jest re-implementacją czegoś co już mamy (sprawdź MEMORY.md, BACKLOG.md, handoffy projektu)?

**Format prezentacji:**
```
Kontekst: [zrozumiałem aktywne zadanie X]
Zanim ruszę, 2-3 pytania kwestionujące:
1. [Scope question — konkretne, nie ogólne]
2. [Alternative question — z konkretnym kandydatem]
3. [Duplication question — z konkretnym potencjalnym duplikatem]

Twoja decyzja: idziemy mimo to, czy zmieniamy kierunek?
```

**Pomijaj** gdy:
- Aktywne zadanie <15 min (literówka, refactor 1 pliku, jasne polecenie "zmień X na Y")
- User explicite powiedział "działaj sam, bez pytań" (per §4 globalnego CLAUDE.md, tryb override)
- Brak aktywnego zadania (scenariusz "MEMORY.md istnieje, ale brak zadania" — patrz §3b)
- Resume z handoff'a który był ZAMKNIĘTY (status: ZAMKNIĘTE)

**Po odpowiedzi user'a:** kontynuuj normalnie. Nie powtarzaj challenge questions w trakcie pracy (anti-spam).

**Cel:** wymusić rolę partnera-architekta zamiast compliance-assistant. Per §3, §20, §27 CLAUDE.md — agent ma OBOWIĄZEK kwestionowania kierunku.

Po challenge questions zapytaj: "Kontynuuję od [następny krok], czy chcesz zmienić kierunek?"

### 4. Jeśli brak MEMORY.md

Powiedz: "Nie znalazłem zapisanego stanu pracy. Opisz czym się zajmowaliśmy, a pomogę kontynuować."

## Zasady

- **Nie zaczynaj od razu kodować** — najpierw potwierdź z userem kierunek
- **Użyj MEMORY.md** jako źródła prawdy, ale zweryfikuj z git log
- **Jeśli jest handoff prompt wklejony przez usera** — użyj go jako główne źródło kontekstu zamiast MEMORY.md
- **Stack-first przed pytaniami** (dodane 2026-05-22) — ZANIM zapytasz usera o jakikolwiek element stacku ekosystemu (email, cold mail, hosting, AI providers, payments, integracje), sprawdź `Project Master/.ai/ecosystem/STACK-SNAPSHOT.md` + `Lead Generator/docs/TOOLS_INVENTORY.md` (jeśli outbound) + per-projekt `.env.local.example`. Pytanie usera = ostateczność gdy 3 źródła nie odpowiadają. Reguła pełna w `Project Master/CLAUDE.md` §2.

### 3a. Weryfikacja spójności

Zanim zaproponujesz następny krok, sprawdź:
- Data ostatniej sesji w MEMORY.md vs `git log --date=short -3` — czy się zgadzają?
- "Aktywne zadanie" z MEMORY.md — czy ostatnie commity dotyczą tego obszaru?
- Gałąź z MEMORY.md — czy aktualna gałąź się zgadza?

Jeśli MEMORY.md **starsze niż 7 dni** → powiedz: "MEMORY.md jest stary, przeskanuję repo aby zaktualizować kontekst."

Jeśli brak spójności → zapytaj: "MEMORY.md mówi X, ale git log mówi Y — co jest prawidłowe?"

### 3b. Scenariusze problemowe

#### MEMORY.md istnieje, ale brak aktywnego zadania
Nie proponuj automatycznie. Zapytaj: "Nie ma zapisanego zadania. Czym chcesz się zająć?"

#### Nowy branch od ostatniej sesji
Powiedz: "Od ostatniej sesji pojawił się branch `[nazwa]`. Czy tam pracowaliśmy?"

#### Merge conflicty w repo
Ostrzeżenie: "UWAGA: W repo są merge conflicty. Rozwiąż je zanim wznowimy pracę." Nie proponuj następnego kroku.

#### Niezacommitowane zmiany z poprzedniej sesji
Pokaż: `git diff --stat` i zapytaj: "Te zmiany wyglądają na niedokończoną pracę. Kontynuować czy zacząć od nowa?"

### 4. Email Intelligence (w tle)

**Równolegle** z krokami 1-3 uruchom agenta email-intel w tle:

```
Agent({
  description: "Email Intelligence scan",
  subagent_type: "general-purpose",
  prompt: "Skanuj maile z ostatnich 48h używając Gmail MCP. Szukaj: 1) KRYTYCZNE: from:supabase subject:(paused OR vulnerability), from:vercel subject:failed, subject:'payment failed'. 2) FAKTURY: subject:faktura OR invoice OR payment. 3) INFO: is:unread is:important. Zapisz raport do .ai/email-intel/YYYY-MM-DD.md w katalogu projektu. Jeśli są KRYTYCZNE — zakończ odpowiedzią zaczynającą się od '⚠️ KRYTYCZNE:'. Jeśli brak — odpowiedz 'OK: brak krytycznych alertów'.",
  run_in_background: true
})
```

Po zakończeniu agenta — jeśli zwrócił KRYTYCZNE, wyświetl alert. Jeśli OK — milcz.

### 5. Dodatkowe źródła kontekstu

Oprócz MEMORY.md sprawdź też (jeśli istnieją):
- `.codex/reports/*.done.md` — raporty od Codexa
- `.ai/handoffs/` — pliki handoff z poprzednich sesji
- `TODO.md` / `.planning/` — plany i notatki projektowe
- `.ai/email-intel/` — raporty email intelligence z poprzednich sesji
- `.ai/BACKLOG.md` — globalny backlog otwartych tematów (jeśli istnieje, patrz sekcja 7)

### 7. Daily BACKLOG review (jeśli `.ai/BACKLOG.md` istnieje)

Jeśli aktualny projekt ma plik `.ai/BACKLOG.md`:

1. **Sprawdź flagę dnia** — istnieje plik `~/.claude/projects/<project-slug>/memory/.backlog-reviewed-{YYYY-MM-DD}` (dziś)?
2. **Flaga istnieje** → BACKLOG już sprawdzony dziś, użyj jako kontekst do `wznów` ale nie prezentuj review (drugi raz tego samego dnia)
3. **Flaga NIE istnieje** → pierwsza sesja dnia, **przeprowadź daily review:**
   - Przeczytaj BACKLOG.md
   - Pokaż TOP 5 P0/P1 items (priorytet > data dodania) — **prezentuj linią EFEKT** (co pozycja odblokowuje/chroni/umożliwia), NIE opisem technicznym zadania (per §37 globalnego CLAUDE.md). Jeśli stara pozycja nie ma linii EFEKT — sformułuj efekt ad-hoc przy prezentacji i przy okazji dopisz go do wpisu.
   - Jeśli są items dodane od ostatniego review (porównaj daty z poprzednią flagą) → pokaż je oddzielnie jako "nowe od ostatniego review"
   - Zapytaj: "Co dziś robimy? Wybierz z TOP 5 albo powiedz inny kierunek."
   - Po decyzji → utwórz flagę `.backlog-reviewed-{YYYY-MM-DD}` (pusty plik wystarczy)

**Zasady auto-capture w trakcie sesji** (dotyczy WSZYSTKICH sesji, nie tylko pierwszej):
- Każde "warto by" / "potem" / "kiedyś" / "pomysł" Dariusza → od razu Edit `.ai/BACKLOG.md` + potwierdzenie ("dopisane: [tytuł]")
- Nie pytaj przed dopisaniem
- Format wpisu (per §37 globalnego CLAUDE.md — linia EFEKT obowiązkowa):
  ```
  [YYYY-MM-DD][P0-P3][open] **Tytuł**
    EFEKT: co odblokowuje / jakie ryzyko zdejmuje / jaką decyzję umożliwia (1-2 zdania, język wartości)
    ZADANIE: szczegóły techniczne dla agenta
    (source: ...)
  ```
- **Filtr:** nie umiesz napisać EFEKT → dopytaj Dariusza zamiast zapisywać

**Zasady closure:**
- Zadanie wykonane → status `done-pending`, zapytaj "Wykreślić [tytuł]?"
- Po OK → przenieś do `BACKLOG-DONE-{YYYY-MM}.md`
- Częściowe → `partial` + notatka "zrobione: X / zostało: Y"

### 6.1. Weryfikacja handoffów z ekosystemu (anty-stale)

Hook SessionStart wyświetla handoffy z ostatnich 3 dni ze wszystkich projektów. **ZANIM przedstawisz je jako otwarte zadania:**

1. **Handoffy > 48h** — zweryfikuj: sprawdź `git log --oneline --since="DATA_HANDOFFU"` w tym projekcie, szukaj commitów pokrywających temat
2. **Handoffy oznaczone PILNE/URGENT** — zawsze zweryfikuj aktualność (agenty w innych sesjach mogły to zamknąć)
3. **Jeśli handoff jest zamknięty** (zawiera `## Status: ZAMKNIĘTE`) — scanner go pominie automatycznie, ale jeśli widzisz go w innym źródle — pomiń

**Przy prezentowaniu listy TODO rozdzielaj:**
- ✅ Potwierdzone otwarte (zweryfikowane z git/userem)
- ❓ Do weryfikacji (z handoffów, niezweryfikowane)

**Jeśli user informuje że zadanie z handoffu jest zrobione** — zamknij handoff:
dopisz na końcu pliku `## Status: ZAMKNIĘTE` + datę + dowód (patrz skill context-handoff)
