---
name: stitch-claude-workflow
description: Bridge workflow łączący Google Stitch 2.0 z Claude Code — design-first development z konwersją HTML→React/Next.js, integracja z unified-design-system i shadcn/ui. Orkiestruje oficjalne stitch-skills (stitch-design, design-md, react:components, stitch-loop) w spójny pipeline.
triggers:
  # Jawne — z nazwą narzędzia
  - "stitch"
  - "w Stitch"
  - "przez Stitch"
  - "w oparciu o Stitch"
  - "Stitch workflow"
  - "UI z Stitch"
  # Naturalne — design-first intencja
  - "zaprojektuj stronę"
  - "zaprojektuj landing"
  - "zbuduj landing page"
  - "design-first"
  - "nowy design"
  - "redesign"
  - "odśwież design"
  - "design do kodu"
dependencies:
  mcp: "@_davideast/stitch-mcp"
  skills:
    - stitch-design
    - design-md
    - react-components
    - stitch-loop
    - shadcn-ui
  optional_skills:
    - unified-design-system
    - frontend-design
---

# Stitch → Claude Code: Design-First Workflow

Bridge skill orkiestrujący workflow od designu w Google Stitch do produkcyjnego kodu React/Next.js z Tailwind CSS i shadcn/ui.

## Kiedy używać

- Projektujesz nową stronę/landing page i chcesz zacząć od designu
- Redesign istniejących komponentów z zachowaniem logiki biznesowej
- Tworzenie spójnego design systemu dla projektu
- Generowanie wielu stron z jednego designu (stitch-loop)

## Wymagania

### Jednorazowy setup (raz na maszynę)

1. **Stitch MCP Server**:
   ```bash
   npx @_davideast/stitch-mcp init
   ```
   Otwiera przeglądarkę do logowania OAuth Google. Po zalogowaniu dodaj do `~/.claude/settings.json`:
   ```json
   {
     "mcpServers": {
       "stitch": {
         "command": "npx",
         "args": ["@_davideast/stitch-mcp", "proxy"]
       }
     }
   }
   ```

2. **Konto Google Stitch**: https://stitch.withgoogle.com (darmowe, wymaga konta Google)

### Oficjalne skille (już zainstalowane globalnie)

```bash
npx skills add google-labs-code/stitch-skills --skill stitch-design --global -y
npx skills add google-labs-code/stitch-skills --skill design-md --global -y
npx skills add google-labs-code/stitch-skills --skill "react:components" --global -y
npx skills add google-labs-code/stitch-skills --skill stitch-loop --global -y
npx skills add google-labs-code/stitch-skills --skill shadcn-ui --global -y
```

---

## Workflow A: Pojedyncza strona (design → kod)

### Faza 1: Design w Stitch

**Opcja MCP** (jeśli stitch-mcp skonfigurowany):
1. Użyj skilla `stitch-design` → wzbogaci prompt, wygeneruje screen
2. Użyj skilla `design-md` → wygeneruje `.stitch/DESIGN.md`

**Opcja manualna** (clipboard):
1. Użytkownik otwiera https://stitch.withgoogle.com
2. Przełącza na tryb **Web** (nie App!)
3. Wybiera **Gemini Pro** jako model
4. Wrzuca screenshot referencyjny + opisuje stronę
5. Eksportuje: **DESIGN.md** (panel Design System) + **Code to Clipboard** (More → Export)
6. Wkleja eksportowany kod do pliku `.stitch/designs/{page}.html` w projekcie

### Faza 2: DESIGN.md → CSS Variables (bridge)

To jest kluczowy krok bridge'a — mapowanie Stitch design tokens na format projektu.

```
DESIGN.md (Stitch)          →  globals.css / theme (projekt)
─────────────────────────────────────────────────────────
Color Palette & Roles       →  CSS custom properties (--primary, --background, etc.)
Typography Rules            →  next/font konfiguracja + Tailwind v4 @theme
Component Stylings          →  shadcn/ui theme overrides
Layout Principles           →  Tailwind spacing/container config
```

**Instrukcja konwersji:**

1. Otwórz `.stitch/DESIGN.md` i wyodrębnij:
   - Kolory z hex kodami → zmapuj na role CSS: `--background`, `--foreground`, `--primary`, `--primary-foreground`, `--muted`, `--accent`, `--border`, `--ring`
   - Typografię → sprawdź czy font jest dostępny w `next/font/google` z `subsets: ["latin-ext"]`
   - Border radius → zmapuj na `--radius` w globals.css
   - Shadows/elevation → zmapuj na Tailwind shadow classes

2. Zaktualizuj `src/app/globals.css`:
   ```css
   @layer base {
     :root {
       --background: [z DESIGN.md - jasny wariant];
       --foreground: [z DESIGN.md - tekst];
       --primary: [z DESIGN.md - akcent główny];
       /* ... reszta tokenów */
     }
     .dark {
       --background: [z DESIGN.md - ciemny wariant];
       /* ... */
     }
   }
   ```

3. Jeśli projekt używa `unified-design-system` (6 motywów):
   - Stwórz nowy motyw na bazie DESIGN.md
   - Dodaj go do ThemeContext jako 7. opcję
   - Lub zastąp najbliższy istniejący motyw

### Faza 3: HTML → React/Next.js (konwersja)

Stitch eksportuje **HTML + Tailwind CSS**, nie React. Konwersja:

1. **Analiza HTML** — przeczytaj `.stitch/designs/{page}.html`
2. **Dekompozycja** — podziel na logiczne komponenty:
   - Header/Navbar → `src/components/layout/Navbar.tsx`
   - Hero Section → `src/components/sections/HeroSection.tsx`
   - Features Grid → `src/components/sections/FeaturesGrid.tsx`
   - etc.
3. **Konwersja per komponent**:
   - HTML tags → JSX (className, htmlFor, onClick)
   - Statyczne teksty → props lub stałe w `src/data/`
   - Hardcoded kolory (#hex) → Tailwind theme classes (bg-primary, text-foreground)
   - `<img>` → `next/image` z `Image` component
   - `<a>` → `next/link` z `Link` component
   - Inline styles → Tailwind classes
   - Powtarzające się elementy → `.map()` z danymi
4. **Dodaj interaktywność**:
   - `'use client'` tylko tam gdzie potrzebne (onClick, useState)
   - Framer Motion animacje (jeśli projekt używa)
   - shadcn/ui komponenty zamiast surowego HTML (Button, Card, Badge, etc.)

### Faza 4: Integracja i weryfikacja

1. Zamień istniejące komponenty lub dodaj nowe
2. Zachowaj istniejącą logikę biznesową (Stripe, Supabase, auth)
3. Uruchom `npm run dev` i zweryfikuj wizualnie
4. Sprawdź responsywność (375px, 768px, 1024px)
5. Porównaj z oryginalnym designem ze Stitch

---

## Workflow B: Multi-page site (stitch-loop)

Dla generowania wielu stron z zachowaniem spójności:

1. **Setup**: Użyj skilla `design-md` → `.stitch/DESIGN.md`
2. **SITE.md**: Stwórz `.stitch/SITE.md` z wizją i sitemap
3. **Loop**: Uruchom skill `stitch-loop` — autonomicznie generuje strony
4. **Konwersja**: Po każdej iteracji konwertuj HTML→React (Faza 3)

---

## Workflow C: Redesign istniejących komponentów

Gdy projekt ma już działający kod, ale chcesz poprawić design:

1. Zrób screenshot obecnego UI w przeglądarce
2. Wrzuć screenshot do Stitch jako reference
3. Poproś o "Redesign in [styl] style, keep the same layout structure"
4. Eksportuj DESIGN.md + Code
5. **Selektywna konwersja** — nie zamieniaj całego komponentu, tylko:
   - Kolory i typografia → globals.css
   - Spacing i layout → Tailwind classes
   - Nowe elementy wizualne (gradienty, blur, ikony)
   - **Zachowaj**: logikę, props, hooks, eventy, integracje

---

## Generacja asynchroniczna (krytyczne!)

Stitch MCP generuje ekrany **asynchronicznie**. To najważniejsza wiedza operacyjna:

### Pattern pollingu
```
1. Wywołaj generate_screen_from_text → zwróci "(completed with no output)" — to NORMALNE
2. Poczekaj 30-60 sekund
3. Wywołaj list_screens z projectId
4. Jeśli ekran pojawił się → pobierz HTML i screenshot
5. Jeśli puste → poczekaj jeszcze 30s → ponów list_screens
6. Jeśli puste po 2 minutach → ponów generację z uproszczonym promptem
```

### Pobieranie assetów
- **ZAWSZE użyj `curl -sL`** do pobierania HTML i screenshotów
- **`WebFetch` NIE działa** — przetwarza HTML przez AI zamiast zwracać surowy plik
- **Screenshot wymaga `=w{width}`** — dopisz do URL, np. `=w1440`, bo Google CDN domyślnie daje miniaturkę
```bash
curl -sL "<htmlCode.downloadUrl>" -o .stitch/designs/landing.html
curl -sL "<screenshot.downloadUrl>=w1440" -o .stitch/designs/landing.png
```

### Wybór modelu
- **`GEMINI_3_FLASH`** — domyślny, szybszy (~30s), tańszy, bardziej niezawodny
- **`GEMINI_3_1_PRO`** — wyższa jakość, ale wolniejszy (~60s+), czasem nie pojawia się od razu
- Rekomendacja: zacznij od Flash, przełącz na Pro tylko jeśli jakość nie wystarczy

---

## Pułapki

1. **Stitch eksportuje HTML, nie React** — ZAWSZE konwertuj, nigdy nie wklejaj surowego HTML do JSX
2. **Hardcoded kolory** — Stitch używa hex w HTML. Mapuj na CSS variables/Tailwind theme
3. **Brak `latin-ext`** — Stitch może zaproponować font bez polskich znaków. Zawsze dodaj `subsets: ["latin-ext"]`
4. **Web mode, nie App** — Stitch domyślnie otwiera App mode (mobile). Przełącz na Web!
5. **Limit generacji** — 350/miesiąc standard, 50 experimental. Planuj prompty
6. **DESIGN.md to semantyczny opis** — nie kopiuj go jako kod. To instrukcja dla agenta, nie stylesheet
7. **`generate_screen_from_text` zwraca "no output"** — to normalne! Generacja jest asynchroniczna. Czekaj i sprawdzaj `list_screens`
8. **`WebFetch` nie pobiera plików ze Stitch** — używaj `curl -sL`, WebFetch przetwarza przez AI
9. **`next/image` wymaga width/height** — przy konwersji `<img>` dodaj wymiary lub `fill`
10. **shadcn/ui zastępuje custom HTML** — jeśli Stitch wygenerował button, card, dialog — użyj shadcn odpowiednika
11. **Kompozycja obrazu musi pasować do layoutu** — jeśli tekst hero jest wycentrowany, obraz powinien mieć treść rozłożoną równomiernie (nie "negative space left")

---

## Integracja z ekosystemem skilli

| Skill | Rola w workflow |
|-------|----------------|
| `stitch-design` | Wzbogacanie promptów, generowanie screenów via MCP |
| `design-md` | Generowanie `.stitch/DESIGN.md` z projektu Stitch |
| `react-components` | Konwersja HTML→React (bazowa, Vite) |
| `stitch-loop` | Multi-page autonomiczna generacja |
| `shadcn-ui` | Mapowanie komponentów na shadcn/ui |
| `unified-design-system` | Mapowanie kolorów na 6 motywów ThemeContext |
| `frontend-design` | Jakość designu i kreatywność implementacji |
| `mobile-responsive-patterns` | Responsywność konwertowanych komponentów |
| `brand-elements` | Favicon, footer, elementy marki |

---

## Checklist per projekt

- [ ] Stitch MCP skonfigurowany (`npx @_davideast/stitch-mcp init`)
- [ ] Design wygenerowany w Stitch (Web mode, Gemini Pro)
- [ ] `.stitch/DESIGN.md` wygenerowany lub ściągnięty
- [ ] Kolory zmapowane na CSS variables w globals.css
- [ ] Font z `latin-ext` skonfigurowany w next/font
- [ ] HTML skonwertowany na komponenty React/JSX
- [ ] Hardcoded hex zamienione na Tailwind theme classes
- [ ] `<img>` → `next/image`, `<a>` → `next/link`
- [ ] shadcn/ui komponenty użyte zamiast surowego HTML
- [ ] Responsywność zweryfikowana (mobile, tablet, desktop)
- [ ] Logika biznesowa zachowana (auth, payments, API calls)
