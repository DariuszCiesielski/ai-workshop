---
name: claude-in-chrome
description: Strategia testowania aplikacji webowych — Claude in Chrome vs Playwright MCP. Matryca decyzyjna kiedy używać którego narzędzia + protokół automatycznego testowania bez angażowania użytkownika. Aliasy głosowe: "tester w przeglądarce", "testy w przeglądarce", "sprawdzarka". Używaj gdy trzeba testować w przeglądarce, debugować w Chrome, automatyzować przeglądarkę, sprawdzić stronę, scraping, otworzyć stronę, lub po zakończeniu zmian w UI.
---
  - "przetestuj UI"
  - "sprawdź czy działa"
  - "zweryfikuj stronę"
  - "testuj formularz"
  - "sprawdź wygląd"
  - "przetestuj automatycznie"
  - "sprawdź w przeglądarce"
  - "tester w przeglądarce"
  - "testy w przeglądarce"
  - "przeprowadź testy w przeglądarce"
  - "odpal testy w przeglądarce"
  - "sprawdzarka"
---

# Testowanie aplikacji webowych — Strategia narzędzi

## Dwa narzędzia, różne zastosowania

W sesjach Claude Code masz dostęp do dwóch sposobów sterowania przeglądarką:

| | **Playwright MCP** | **Claude in Chrome** |
|---|---|---|
| **Jak działa** | Headless/headed Chromium sterowany programowo | Twoja prawdziwa przeglądarka Chrome z rozszerzeniem |
| **Sesje/ciasteczka** | Czysta sesja (brak zalogowań) | Twoje prawdziwe sesje (zalogowany wszędzie) |
| **Szybkość** | Szybki — bezpośrednie API | Wolniejszy — wizualne sterowanie |
| **Stabilność** | Wysoka — deterministyczne selektory | Średnia — beta, service worker idle |
| **Kontekst** | Niski koszt kontekstu | Wysoki koszt kontekstu (narzędzia zawsze załadowane) |
| **Screenshoty** | Tak (snapshot + screenshot) | Tak + nagrywanie GIF |
| **Konsola JS** | Tak (evaluate + console_messages) | Tak (logi konsoli) |
| **Multi-tab** | Tak (browser_tabs) | Tak (tab groups) |

## ZASADA NADRZĘDNA: Chrome otwarty = nie testuj UI sam

Playwright MCP **nie działa gdy Chrome użytkownika jest otwarty** — próba uruchomienia nowej instancji kończy się błędem "Otwieram w istniejącej sesji przeglądarki" → process exit. To NAJCZĘSTSZY scenariusz.

**Gdy Chrome jest otwarty (domyślne założenie):**
1. **Weryfikuj dane przez API** — `curl` na endpointy, sprawdź strukturę odpowiedzi
2. **Sprawdź kompilację** — `npx tsc --noEmit` potwierdza brak błędów TypeScript
3. **Poproś użytkownika** — "Otwórz localhost:3000/[ścieżka] w przeglądarce i sprawdź"
4. **NIE próbuj Playwright MCP** — nie marnuj czasu na wielokrotne próby
5. **NIE próbuj obejść** — curl na strony za auth, headless z innym profilem, etc.

**Playwright MCP używaj TYLKO gdy:**
- Użytkownik potwierdził, że Chrome jest zamknięty
- Użytkownik wprost poprosił o test w przeglądarce
- Testujesz stronę BEZ auth (publiczna strona, landing page)

---

## Kiedy używać czego — matryca decyzyjna

### Playwright MCP → domyślne narzędzie do testowania (GDY CHROME ZAMKNIĘTY)

Używaj **gdy testujesz swoją aplikację** (localhost) i **Chrome nie jest otwarty**:

- **Weryfikacja UI po zmianach** — otwórz stronę, sprawdź czy elementy się renderują
- **Testowanie formularzy** — wypełnij, wyślij, sprawdź walidację i komunikaty błędów
- **Sprawdzanie responsywności** — `browser_resize` na różne breakpointy
- **Debugowanie JS** — `browser_console_messages` + `browser_evaluate`
- **Testowanie nawigacji** — klikaj linki, sprawdzaj routing
- **Regresje wizualne** — screenshoty przed/po zmianach
- **Automatyczne flow** — np. rejestracja → logowanie → dashboard

**Przykładowy workflow z Playwright:**
```
1. browser_navigate → http://localhost:5173
2. browser_snapshot → sprawdź strukturę strony
3. browser_fill_form → wypełnij formularz logowania
4. browser_click → kliknij "Zaloguj się"
5. browser_snapshot → zweryfikuj czy dashboard się załadował
6. browser_console_messages → sprawdź czy nie ma błędów JS
7. browser_take_screenshot → zrób zrzut ekranu
```

### Claude in Chrome → gdy potrzebujesz prawdziwej sesji użytkownika

Używaj **gdy musisz być zalogowany** w zewnętrznych serwisach:

- **OAuth flows** — testowanie logowania przez Facebook/Google/LinkedIn (wymaga prawdziwej sesji)
- **Zewnętrzne dashboardy** — sprawdzanie danych w Stripe, Vercel, Grafana
- **Google Docs/Sheets** — tworzenie dokumentacji, eksport danych
- **Testowanie integracji** — weryfikacja że webhook dotarł do Slacka, email wysłany w Gmailu
- **Multi-site workflows** — koordynacja między wieloma serwisami
- **Nagrywanie demo GIF** — do dokumentacji, README, PR

**Przykładowy workflow z Claude in Chrome:**
```
Zaloguj się na Stripe Dashboard, sprawdź czy webhook endpoint
dla naszej aplikacji jest aktywny, potem otwórz naszą aplikację
na localhost:5173 i przetestuj flow subskrypcji od początku do końca.
```

## Matryca decyzyjna — szybki wybór

```
Czy Chrome użytkownika jest OTWARTY?
├── TAK (domyślne założenie) → NIE próbuj Playwright MCP
│   ├── Weryfikuj dane przez API (curl)
│   ├── Sprawdź kompilację (tsc --noEmit)
│   └── Poproś użytkownika: "Otwórz [URL] i sprawdź"
└── NIE (użytkownik potwierdził) →
    Czy testujesz SWOJĄ aplikację na localhost?
    ├── TAK → Czy potrzebujesz zalogowanej sesji w ZEWNĘTRZNYM serwisie?
    │   ├── TAK → Claude in Chrome (np. OAuth, Stripe, Gmail)
    │   └── NIE → Playwright MCP ✅ (domyślny wybór)
    └── NIE → Czy interagujesz z zewnętrzną stroną?
        ├── TAK → Claude in Chrome (masz tam sesje)
        └── NIE → Playwright MCP (szybszy, stabilniejszy)
```

## Konfiguracja

### Playwright MCP (już dostępny)
Playwright jest załadowany jako MCP server (`plugin:playwright`). Dostępne narzędzia:
- `browser_navigate`, `browser_click`, `browser_fill_form`, `browser_type`
- `browser_snapshot`, `browser_take_screenshot`
- `browser_evaluate`, `browser_console_messages`
- `browser_resize`, `browser_tabs`, `browser_wait_for`
- `browser_press_key`, `browser_select_option`, `browser_hover`, `browser_drag`
- `browser_file_upload`, `browser_handle_dialog`

Nie wymaga dodatkowej konfiguracji — działa od razu.

### Claude in Chrome (wymaga setup)

**Wymagania:**
- Google Chrome lub Microsoft Edge
- [Rozszerzenie Claude in Chrome](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn) >= 1.0.36
- Claude Code >= 2.0.73
- Plan: Pro, Max, Teams lub Enterprise (bezpośredni Anthropic — nie Bedrock/Vertex)

**Uruchamianie:**
```bash
# Jednorazowo
claude --chrome

# W trakcie sesji
/chrome

# Włącz domyślnie (uwaga: zwiększa zużycie kontekstu!)
/chrome → "Enabled by default"
```

**W VS Code:** Chrome dostępny automatycznie po zainstalowaniu rozszerzenia.

## Łączenie obu narzędzi w jednym workflow

Najlepsze rezultaty daje **łączenie obu podejść**:

```
Scenariusz: Testowanie integracji z Facebook Ads API

1. [Playwright] Otwórz localhost:5173, zaloguj się do aplikacji
2. [Playwright] Przejdź do strony "Połączone konta"
3. [Playwright] Kliknij "Połącz Facebook" → sprawdź czy redirect działa
4. [Chrome] Zaloguj się na Facebook → autoryzuj aplikację
5. [Playwright] Wróć do aplikacji → zweryfikuj że token został zapisany
6. [Playwright] Sprawdź konsolę pod kątem błędów
7. [Playwright] Zrób screenshot strony z połączonym kontem
```

## Zarządzanie sesjami Playwright

### Problem: blokowanie przez istniejącą sesję
Playwright MCP utrzymuje jedną instancję przeglądarki. Gdy próbujesz otworzyć nową sesję, a poprzednia wciąż żyje (np. z wcześniejszego testu lub z innego projektu), nowa sesja zostanie zablokowana.

### OBOWIĄZKOWY protokół przed każdym testem

**Krok 1 — Sprawdź istniejące taby:**
```
browser_tabs → lista otwartych tabów z URL-ami
```

**Krok 2 — Oceń sytuację:**

| Stan | Akcja |
|------|-------|
| Brak tabów / pusta przeglądarka | Normalnie otwórz stronę |
| Tab z URL tego samego projektu (np. localhost:5173) | **Użyj go** — `browser_navigate` do potrzebnej podstrony |
| Tab z URL innego projektu (np. localhost:3000) | **Nie zamykaj** — otwórz nowy tab lub nawiguj w istniejącym pustym tabie |
| Przeglądarka nie odpowiada / timeout | `browser_close` → poczekaj 2s → zacznij od nowa |

**Krok 3 — Nawiguj świadomie:**
- Jeśli projekt już ma otwarty tab → nawiguj w nim (nie otwieraj nowego)
- Jeśli pracujesz z wieloma projektami → każdy projekt powinien mieć swój tab
- Po zakończeniu testów → **NIE zamykaj** przeglądarki, może być potrzebna ponownie

### Typowe scenariusze wieloprojektowe

```
Scenariusz: Pracujesz nad projektem A (port 5173) i projektem B (port 3000)

1. browser_tabs → widzisz: [Tab 1: localhost:5173/dashboard, Tab 2: localhost:3000/admin]
2. Chcesz testować projekt A → nawiguj w Tab 1
3. Chcesz testować projekt B → nawiguj w Tab 2
4. NIE zamykaj tabów innych projektów
```

### Gdy sesja jest zablokowana (nie odpowiada)

```
1. browser_close → zamknij zablokowaną przeglądarkę
2. Odczekaj 2 sekundy
3. browser_navigate → otwórz stronę od nowa
4. Jeśli nadal nie działa → sprawdź czy port jest zajęty:
   lsof -i :5173  (lub inny port)
```

## Rozwiązywanie problemów

### Playwright MCP
| Problem | Rozwiązanie |
|---------|-------------|
| Strona nie ładuje się | Sprawdź czy dev server działa (`npm run dev`) |
| Element nie znaleziony | Użyj `browser_snapshot` żeby zobaczyć aktualny DOM |
| Timeout | Użyj `browser_wait_for` przed interakcją |
| Sesja zablokowana przez poprzedni test | `browser_tabs` → reuse tab lub `browser_close` → restart |
| Inny projekt blokuje port | `lsof -i :<port>` → zidentyfikuj proces |

### Claude in Chrome
| Problem | Rozwiązanie |
|---------|-------------|
| "Extension not detected" | Zainstaluj/włącz w `chrome://extensions`, restart Chrome |
| "Browser extension is not connected" | Restart Chrome + Claude Code → `/chrome` → Reconnect |
| "Receiving end does not exist" | `/chrome` → "Reconnect extension" (service worker idle) |
| Dialog JS blokuje | Zamknij ręcznie alert/confirm/prompt |

### Plik konfiguracyjny Native Messaging Host (macOS)
```
~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.claude_code_browser_extension.json
```

## Ograniczenia Claude in Chrome
- Beta — niestabilne przy długich sesjach
- Tylko Chrome/Edge (nie Brave, Arc)
- Nie działa na mobile ani WSL
- CAPTCHA/logowanie wymagają ręcznej obsługi
- Zwiększa zużycie kontekstu gdy włączone domyślnie

## Protokół automatycznego testowania

### Zasada główna
Po zakończeniu zmian w UI lub logice frontendowej — **testuj automatycznie bez pytania użytkownika**. Nie czekaj na polecenie "przetestuj". Reguła behawioralna jest zapisana w globalnym CLAUDE.md.

### Kiedy testować automatycznie

| Sytuacja | Testuj? | Co sprawdzić |
|----------|---------|-------------|
| Zmieniłeś komponent React/Vue/Svelte | TAK | Renderowanie, interakcje |
| Zmieniłeś routing/nawigację | TAK | Przejścia między stronami |
| Zmieniłeś formularz | TAK | Walidacja, submit, komunikaty błędów |
| Zmieniłeś logikę API/fetch | TAK | Czy dane się ładują, błędy konsoli |
| Zmieniłeś style/layout | TAK (lekko) | Snapshot + sprawdź czy się renderuje |
| Zmieniłeś tylko backend bez UI | NIE | Testy jednostkowe wystarczą |
| Zmieniłeś konfigurację (eslint, tsconfig) | NIE | Build/lint wystarczy |

### Automatyczny checklist po zmianach UI

```
1. Sprawdź czy dev server działa (jeśli nie — uruchom)
2. browser_navigate → strona ze zmianami
3. browser_snapshot → czy kluczowe elementy się renderują?
4. browser_console_messages → czy są błędy JS?
5. [Jeśli formularz] browser_fill_form → browser_click submit → sprawdź wynik
6. [Jeśli nawigacja] browser_click linki → sprawdź routing
7. [Jeśli layout] browser_resize 375px → snapshot → resize 1024px → snapshot
```

### Co robisz SAM (bez pytania):
- Weryfikacja że strona się ładuje i elementy są widoczne
- Wypełnianie formularzy danymi testowymi i sprawdzanie walidacji
- Klikanie przycisków i linków — sprawdzanie nawigacji
- Sprawdzanie konsoli JS pod kątem błędów i ostrzeżeń
- Testowanie responsywności (375px mobile, 768px tablet, 1024px desktop)
- Pełne flow end-to-end (np. rejestracja → logowanie → dashboard)
- Naprawienie znalezionych problemów i ponowne testowanie

### O co PYTASZ użytkownika:
- **Akceptacja wizualna** — "Wygląd strony się zmienił, oto screenshot. Czy to odpowiada Twoim oczekiwaniom?"
- **Subiektywne decyzje UX** — kolejność elementów, dobór słów, estetyka
- **Prawdziwe dane logowania** — OAuth, płatności produkcyjne, konta zewnętrzne
- **Niejednoznaczne wymagania** — gdy nie wiesz co powinno się stać po kliknięciu

### Raportowanie wyników

**Gdy OK:**
> "Przetestowano w przeglądarce: [co sprawdziłeś] — bez błędów."

**Gdy błąd:**
> "Test w przeglądarce wykrył problem: [opis]. Naprawiam..."
> *(napraw → przetestuj ponownie → raportuj)*

**Gdy potrzebna decyzja wizualna:**
> "Zmiany wpływają na wygląd strony. Oto screenshot: [screenshot]. Czy akceptujesz?"

### Automatyczne uruchamianie dev servera

Jeśli dev server nie działa, a potrzebujesz testować:
1. Sprawdź `package.json` → znajdź skrypt `dev` / `start`
2. Uruchom w tle: `npm run dev` (lub `pnpm dev`, `yarn dev`)
3. Poczekaj na gotowość (port 3000/5173/8080)
4. Kontynuuj testowanie

### Aktualizacja wiedzy o narzędziach

Gdy napotkasz problem z Playwright MCP lub Claude in Chrome, który nie jest opisany w tym skillu:
1. Sprawdź aktualną dokumentację (linki w sekcji Źródła)
2. Jeśli znajdziesz nowe rozwiązanie — **zaproponuj użytkownikowi aktualizację tego skilla**
3. Format: "Odkryłem nowe rozwiązanie na [problem]. Chcesz, żebym zaktualizował skill `claude-in-chrome`?"

## Znane komunikaty — IGNORUJ

### "Użyto nieobsługiwanej flagi wiersza polecenia: --no-sandbox"
Pojawia się w pasku Chrome przy starcie Playwright MCP. To **normalne** — Playwright dodaje `--no-sandbox` automatycznie dla kompatybilności. Komunikat jest informacyjny, NIE jest błędem. Nie próbuj go naprawiać, nie raportuj użytkownikowi jako problem.

### "Chrome is being controlled by automated test software"
Standardowy komunikat Chromium DevTools Protocol. Ignoruj.

## Źródła
- [Claude Code + Chrome docs](https://code.claude.com/docs/en/chrome)
- [Claude in Chrome Help Center](https://support.claude.com/en/articles/12012173-get-started-with-claude-in-chrome)
- [Chrome Web Store](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn)
- [Playwright MCP](https://github.com/anthropics/claude-code/blob/main/docs/mcp.md) — dokumentacja MCP w Claude Code
