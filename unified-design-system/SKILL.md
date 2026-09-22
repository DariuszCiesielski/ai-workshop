---
name: unified-design-system
description: Hub globalnego systemu designu — 8 motywów (w tym Szkło glass), ThemeContext, UserMenu, shadcn mapping, checklisty. Rozdzielony na 3 sub-skille. Używaj przy pytaniach ogólnych o design system lub gdy nie wiesz którego sub-skilla użyć.
---

# Unified Design System — Hub

Globalny system designu do ujednolicania wyglądu aplikacji React/Next.js. Zawiera 6 motywów, ThemeContext z CSS custom properties, UserMenu z wyborem motywu i mapowanie na shadcn/ui.

## Triggery

- "dodaj system motywów", "ujednolić design", "unified design"
- "dodaj motywy", "skonfiguruj theming", "dodaj dark mode"
- "dodaj przełącznik motywów"

## Sub-skille

| Skill | Kiedy użyć |
|-------|-----------|
| **design-system-themes** | Tworzenie/edycja motywów, palety kolorów, CSS variables, kontrast WCAG, zasady spójności var(--) vs hardcoded |
| **design-system-components** | ThemeContext, UserMenu, mapowanie shadcn/ui, integracja z aplikacją, kolory w formularzach |
| **design-system-checklist** | Checklist implementacji, testowanie motywów, lista projektów, auto-feedback |

## Szybki start (nowy projekt)

1. Użyj skill `design-system-themes` → utwórz folder `themes/` z definicjami
2. Użyj skill `design-system-components` → utwórz ThemeContext + UserMenu
3. Opakuj aplikację w `<ThemeProvider>`, dodaj UserMenu do headera
4. Użyj skill `design-system-checklist` → przetestuj na 3 motywach

## Odtworzenie systemu z istniejącej strony (dembrandt)

Gdy klient ma już stronę / markę pod URL i nowy projekt ma trzymać ten język wizualny —
**wyciągnij tokeny z żywej strony zamiast zgadywać**: `npx dembrandt <url> --design-md --tailwind --wcag`
(pilot 2026-08-16, `perelki` tier=adopt). Zwraca kolory, typografię, odstępy, pary kontrastu
WCAG (AA/AAA) i `DESIGN.md` w ~40 s. **RTK przepisuje `npx`→`npm run`** — uruchamiaj lokalną
binarkę: `npm i dembrandt` + jednorazowo `./node_modules/.bin/dembrandt install-browser`, potem
`./node_modules/.bin/dembrandt <url> ...`. **Wynik to SZKIC do weryfikacji, nie źródło prawdy**:
rozmiary czcionek wychodzą zawyżone (łapie maksima `clamp()`/skalowanie), a „primary" kolor
wymaga sprawdzenia okiem. Świetny punkt startowy + gotowy audyt WCAG do raportu klienta.

## Kluczowe zasady

- **UserMenu** zawsze w prawym górnym rogu headera (nie w sidebarze)
- **Sidebar** = tylko nawigacja
- **Domyślny motyw**: Szkło (glass)
- **THEME_STORAGE_KEY**: unikalny prefix per aplikacja (np. `HOTEL_DEMO_THEME`)
- **Konsystencja**: jeden wzorzec per kontener — albo `var(--)`, albo hardcoded Tailwind
- **shadcn/ui**: dodaj `mapToShadcnVariables()` do `applyThemeToDOM()` i usuń `className="dark"` z `<html>`

## Anty-wzorce UI (explicit deny list)

Generując lub modyfikując interfejsy użytkownika — **NIGDY** nie stosuj:

### Typografia
- ❌ Font Inter/Arial/system-ui jako jedyny — użyj Geist Sans lub fontu z brand kitu projektu
- ❌ Jednolity rozmiar tekstu (wszystko 14-16px) — buduj hierarchię (12/14/18/24/32+)
- ❌ Szary tekst (#9CA3AF) na kolorowym tle — zawsze sprawdź kontrast WCAG 4.5:1

### Layout i kompozycja
- ❌ Karty w kartach (nested cards) — jeśli karta jest w karcie, zamień wewnętrzną na sekcję
- ❌ Siatka identycznych kart (3-4 kolumny, identyczny spacing, identyczna wysokość) bez wizualnego akcentu — dodaj hero/wyróżnioną kartę lub asymetrię
- ❌ Generyczne bordered divs zamiast komponentów shadcn (Card, Alert, Badge)
- ❌ Brak stanów empty/loading/error — każdy widok danych MUSI mieć skeleton/empty state

### Kolory i efekty
- ❌ Fioletowy gradient na białym tle (generyczny "AI look")
- ❌ Rainbow akcenty (5+ kolorów w jednym widoku) — max 1 kolor akcentowy + neutralne
- ❌ Glassmorphism wszędzie — używaj selektywnie (1-2 elementy, nie każda karta)
- ❌ Niepotrzebne cienie (shadow-lg na każdym elemencie) — cień = elevation = hierarchia

### Animacje i interakcje
- ❌ Bounce/elastic easing (infantylne) — użyj ease-out lub cubic-bezier(0.4, 0, 0.2, 1)
- ❌ Brak hover/focus states — każdy interaktywny element MUSI reagować wizualnie
- ❌ Animacje >300ms na elementach UI (przyciski, karty) — max 200ms dla micro-interactions
- ❌ Fade-in na całej stronie przy mount — animuj poszczególne sekcje, nie container

### Landing pages (szczególnie Starter Kit, AI w Biznesie)
- ❌ "Lorem ipsum" lub generyczny placeholder copy — ZAWSZE z prawdziwą treścią
- ❌ Stock-photo hero bez overlay — dodaj gradient overlay lub blur dla czytelności tekstu
- ❌ CTA "Dowiedz się więcej" / "Sprawdź ofertę" — konkretny benefit w CTA
- ❌ Hero section bez kontrastu wartości (co dostanę vs. bez tego) — storytelling, nie opis
- ❌ Footer z samym © — dodaj nawigację, social links, kontakt

## Zależności

```bash
npm install lucide-react
# Tailwind CSS (CDN lub npm)
```

## Projekty (15)

13 projektów na Unified Design System + 2 na alternatywnym theme-registry.
Pełna lista → skill `design-system-checklist`, sekcja 4.
