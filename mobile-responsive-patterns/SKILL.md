---
name: mobile-responsive-patterns
description: 'Wzorce responsywności dla aplikacji React/Next.js — DWIE warstwy. Warstwa układu (sekcje 1-11) zapobiega overflow, błędom przy obrocie ekranu i usterkom WebView. Warstwa urządzenia (sekcja 12, iOS/Safari/PWA) pokrywa rzeczy, których emulator NIE odtwarza: samoczynne powiększanie strony przy polach < 16 px, safe-area na ekranie z wyspą, klawiaturę zasłaniającą pole, tabele rozpychające stronę, martwy SpeechRecognition w zainstalowanej PWA. Używaj przy nowych projektach, audycie mobilnym, zgłoszeniu „ekran się rozszerzył"/„za szerokie na iPhonie", oraz ZAWSZE gdy projektujesz funkcję głosową dla telefonu.'
triggers:
  - "dodaj mobile support"
  - "napraw mobile"
  - "responsive layout"
  - "orientation bug"
  - "WebView bug"
  - "karty overflow"
  - "mobile fix"
  - "audyt mobilny"
  - "sprawdź responsywność"
  - "ekran się rozszerzył"
  - "za szerokie na iPhonie"
  - "wersja na telefon"
  - "wersja na tablet"
  - "PWA"
  - "Add to Home Screen"
  - "safe area"
  - "głos w przeglądarce na telefonie"
  - creating a new React/Next.js project
  - adding card grids or responsive layouts
  - user reports overflow on mobile
---

# Mobile Responsive Patterns

Zestaw sprawdzonych wzorców zapewniających prawidłowe działanie aplikacji React/Next.js na urządzeniach mobilnych, w tym w WebView (Messenger, Instagram, TikTok itp.).

## Kiedy używać

- **Nowy projekt** — zastosuj wszystkie wzorce od początku (checklist na dole)
- **Istniejący projekt** — przeprowadź audyt (sekcja "Audyt mobilny")
- **Bug report** — użytkownik zgłasza overflow, rozjechany layout, problemy po obróceniu telefonu

---

## 1. Viewport Meta Tag (Next.js App Router)

**Problem:** WebView w aplikacjach społecznościowych (Messenger, Instagram) może ignorować domyślny viewport generowany przez Next.js.

**Rozwiązanie:** Explicit `viewport` export w root `layout.tsx`:

```typescript
// src/app/layout.tsx
import type { Metadata, Viewport } from "next";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover", // Obsługa notcha (safe area)
};
```

> `viewportFit: "cover"` pozwala na pełnoekranowy layout z obsługą safe-area-inset na iPhone'ach z notchem.

---

## 2. Card Constraints (shadcn/ui)

**Problem:** Karty (Card, CardHeader, CardTitle itp.) w CSS gridzie mogą rozszerzać się poza kontener i nie kurczyć się z powrotem po zmianie orientacji, bo grid/flex items zapamiętują intrinsic width.

**Rozwiązanie:** Dodaj `min-w-0 max-w-full overflow-hidden` na komponentach Card:

```typescript
// src/components/ui/card.tsx

// Card — dodaj: min-w-0 max-w-full overflow-hidden
"bg-card text-card-foreground flex min-w-0 max-w-full flex-col gap-6 overflow-hidden rounded-xl border py-6 shadow-sm"

// CardHeader — dodaj: min-w-0 max-w-full overflow-hidden + minmax(0,1fr)
"grid min-w-0 max-w-full auto-rows-min grid-rows-[auto_auto] items-start gap-2 overflow-hidden px-6 has-data-[slot=card-action]:grid-cols-[minmax(0,1fr)_auto] [.border-b]:pb-6"

// CardTitle — dodaj: min-w-0 max-w-full
"min-w-0 max-w-full leading-none font-semibold"

// CardDescription — dodaj: min-w-0 max-w-full
"text-muted-foreground min-w-0 max-w-full text-sm"

// CardContent — dodaj: min-w-0 max-w-full
"min-w-0 max-w-full px-6"

// CardFooter — dodaj: min-w-0 max-w-full
"flex min-w-0 max-w-full items-center px-6 [.border-t]:pt-6"
```

### Dlaczego `minmax(0, 1fr)` zamiast `1fr`?

`grid-cols-[1fr_auto]` pozwala pierwszej kolumnie rosnąć na podstawie zawartości (intrinsic minimum). `minmax(0, 1fr)` wymusza minimum 0, więc kolumna zawsze mieści się w kontenerze.

---

## 3. Flex Children — `min-w-0`

**Problem:** W kontenerze flex, child z tekstem (np. tytuł + opis) nie kurczy się poniżej intrinsic width tekstu.

**Rozwiązanie:** Dodaj `min-w-0` na każdym flex child, który zawiera tekst:

```tsx
{/* ZŁE — div z tekstem rozszerza flex parent */}
<div className="flex items-center gap-3">
  <Icon />
  <div>
    <h3>Długi tytuł karty</h3>
    <p>Opis</p>
  </div>
</div>

{/* DOBRE — min-w-0 na obu flex children */}
<div className="flex min-w-0 items-center gap-3">
  <Icon className="shrink-0" />
  <div className="min-w-0">
    <h3 className="truncate">Długi tytuł karty</h3>
    <p>Opis</p>
  </div>
</div>
```

**Reguła:** Jeśli element jest w `flex` i zawiera tekst → dodaj `min-w-0`. Jeśli element ma stałą szerokość (ikona) → dodaj `shrink-0`.

---

## 4. ResponsiveCardGrid — Force Reflow na Orientation Change

**Problem:** WebView w Messengerze/Instagramie nie triggeruje pełnego CSS reflow przy zmianie orientacji telefonu. Grid items zachowują szerokość z poprzedniej orientacji.

**Rozwiązanie:** Komponent wrappujący grid, który wymusza reflow:

```typescript
// src/components/layout/responsive-card-grid.tsx
"use client";

import { useEffect, useRef } from "react";
import { cn } from "@/lib/utils";

interface ResponsiveCardGridProps {
  children: React.ReactNode;
  className?: string;
}

export function ResponsiveCardGrid({
  children,
  className,
}: ResponsiveCardGridProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const forceReflow = () => {
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          el.style.display = "none";
          void el.offsetHeight; // Force synchronous reflow
          el.style.display = "";
        });
      });
    };

    window.addEventListener("orientationchange", forceReflow);
    window.visualViewport?.addEventListener("resize", forceReflow);

    return () => {
      window.removeEventListener("orientationchange", forceReflow);
      window.visualViewport?.removeEventListener("resize", forceReflow);
    };
  }, []);

  return (
    <div ref={ref} className={cn("grid min-w-0", className)}>
      {children}
    </div>
  );
}
```

**Użycie** — CSS breakpointy w className (SSR-safe, zero CLS):

```tsx
<ResponsiveCardGrid className="gap-4 sm:grid-cols-2 lg:grid-cols-3">
  <Card>...</Card>
  <Card>...</Card>
</ResponsiveCardGrid>
```

> WAŻNE: NIE przenoś logiki breakpointów do JS (powoduje CLS — layout shift przy hydration). CSS breakpointy działają od razu na serwerze, JS force-reflow to tylko backup dla WebView.

---

## 5. Dialog / AlertDialog — Overflow na Mobile

**Problem:** Dialogi z długim tekstem (np. email, URL) rozciągają się poza ekran na małych urządzeniach.

**Rozwiązanie:** Dodaj `max-w-[calc(100%-2rem)]` i `[overflow-wrap:anywhere]`:

```typescript
// Dialog Content
"fixed top-[50%] left-[50%] z-50 grid w-full max-w-[calc(100%-2rem)] translate-x-[-50%] translate-y-[-50%] ... sm:max-w-lg [overflow-wrap:anywhere]"

// AlertDialog Content — tak samo
"fixed top-[50%] left-[50%] z-50 grid w-full max-w-[calc(100%-2rem)] ... data-[size=default]:sm:max-w-lg [overflow-wrap:anywhere]"
```

---

## 6. DropdownMenu — Collision Padding

**Problem:** Dropdown menu może wystawać poza ekran na mobile (szczególnie przy prawej krawędzi).

**Rozwiązanie:** Dodaj `collisionPadding={8}` i `max-w-[calc(100vw-1rem)]`:

```typescript
// DropdownMenuContent
<DropdownMenuPrimitive.Content
  collisionPadding={8}
  className="... max-w-[calc(100vw-1rem)] ..."
/>

// DropdownMenuSubContent — tak samo
<DropdownMenuPrimitive.SubContent
  collisionPadding={8}
  className="... max-w-[calc(100vw-1rem)] ..."
/>
```

---

## 7. Header — Mobile Navigation

**Problem:** Sidebar jest ukryta na mobile (`lg:hidden`). Potrzebny jest MobileNav w headerze.

**Rozwiązanie:** MobileNav w flow headera (NIE fixed/absolute):

```tsx
// Header
<header className="sticky top-0 z-30 flex items-center justify-between border-b bg-background px-3 sm:px-4 lg:px-6 h-14 lg:h-16">
  {/* Lewa strona — MobileNav (tylko < lg) */}
  <div className="flex items-center gap-1.5 sm:gap-2">
    <div className="lg:hidden -ml-1">
      <MobileNav />
    </div>
    {/* inne elementy */}
  </div>

  {/* Prawa strona — UserMenu */}
  <UserMenu />
</header>
```

**Wzorce responsive spacing:**
- `px-3 sm:px-4 lg:px-6` — padding headera
- `gap-1.5 sm:gap-2` — gap między elementami
- `h-14 lg:h-16` — wysokość headera

---

## 8. useMediaQuery Hook (SSR-safe)

**Problem:** `window.matchMedia` nie istnieje na serwerze — hydration mismatch.

**Rozwiązanie:**

```typescript
// src/hooks/use-media-query.ts
'use client';

import { useEffect, useState } from 'react';

export function useMediaQuery(query: string): boolean {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    if (media.matches !== matches) {
      setMatches(media.matches);
    }
    const listener = () => setMatches(media.matches);
    media.addEventListener('change', listener);
    return () => media.removeEventListener('change', listener);
  }, [matches, query]);

  return matches;
}
```

**Użycie:**

```tsx
const isDesktop = useMediaQuery('(min-width: 1024px)');
// Desktop: sticky side panel
// Mobile: Sheet (bottom drawer)
```

---

## 9. Welcome Section — Responsive Layout

**Problem:** Nagłówek z przyciskiem akcji nie mieści się w jednej linii na mobile.

**Rozwiązanie:**

```tsx
<div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between sm:gap-4">
  <div className="min-w-0">
    <h1 className="text-2xl sm:text-3xl font-bold tracking-tight truncate">
      Witaj, {name}!
    </h1>
    <p className="text-muted-foreground mt-1 sm:mt-2">Opis</p>
  </div>
  <Button className="w-full sm:w-auto shrink-0">
    Akcja
  </Button>
</div>
```

**Kluczowe:** `flex-col` na mobile → `sm:flex-row`, `w-full sm:w-auto` na przycisku, `min-w-0` + `truncate` na tekście.

---

## 10. Grid Breakpoints — Konwencje

| Breakpoint | Kolumny | Viewport | Urządzenie |
|-----------|---------|----------|------------|
| default | 1 | < 640px | Telefon portrait |
| `sm:` | 2 | 640px+ | Telefon landscape / tablet |
| `lg:` | 3 | 1024px+ | Desktop |

```tsx
// Standardowy grid kart
<div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">

// Z responsive spacing
<div className="grid gap-4 sm:grid-cols-2 sm:gap-6 lg:grid-cols-3">

// Spacing pionowy
<div className="space-y-5 sm:space-y-8">
```

---

## 11. Focus Panel / Sheet — Mobile Height

**Problem:** Sheet (bottom drawer) z `h-[85vh]` jest za wysoki na mobile i trudno go zamknąć.

**Rozwiązanie:** Użyj `max-h-[80vh]` z `rounded-t-xl`:

```tsx
<SheetContent side="bottom" className="max-h-[80vh] rounded-t-xl overflow-y-auto">
  {/* zawartość */}
</SheetContent>
```

---

## 12. Warstwa urządzenia — iOS/Safari (empiria z fizycznego iPhone'a)

Sekcje 1–11 dotyczą **układu** (React/shadcn/grid). Ta sekcja dotyczy **zachowania urządzenia** — rzeczy, których emulator w Chromium NIE odtwarza i które wychodzą dopiero na prawdziwym telefonie. Wszystkie reguły poniżej pochodzą z usterek zgłoszonych przez Dariusza z iPhone'a (lipiec–sierpień 2026) i potwierdzonych na fizycznym urządzeniu.

### 12.1 🔴 Pola formularzy minimum 16 px na telefonie — reguła profilaktyczna

**Problem:** Safari na iOS **sam powiększa całą stronę** przy wejściu w kontrolkę z czcionką < 16 px. Po powiększeniu treść nie mieści się w szerokości i strona zaczyna przewijać się w bok. Człowiek zgłasza to jako **„ekran się rozszerzył"** i nie wskazuje na pole — dlatego regułę stosuje się profilaktycznie, nie po zgłoszeniu.

```css
@media (max-width: 640px) {
  input, textarea, select { font-size: 16px !important; }
}
```

- **`!important` jest konieczne** — rozmiary pól bywają zapisane stylem inline (np. 13 px w selektorach okresu), a inline bije klasę.
- ⚠️ **Selektory pisz szeroko: `input, textarea, select`** — NIE listą `input[type=...]`. Wyliczanie typów przepuszcza `textarea`, `search`, `tel`, `number`, `url` oraz `input` bez atrybutu `type`.
- ⚠️ **`user-scalable=no` / `maximum-scale=1` to ZŁA naprawa** — usuwa objaw, odbierając możliwość powiększenia strony (narusza WCAG 1.4.4).
- Dotyczy **całej** aplikacji, także ekranu logowania — samo pole hasła w apce „bez formularzy" wystarczy, żeby usterka wystąpiła.
- To reguła dostępnościowa dla jednego breakpointu, **nie element systemu tokenów** — na desktopie nie zmienia nic.

### 12.2 Safe-area — obowiązkowa w każdej aplikacji instalowalnej

Aplikacja ze `status-bar-style: black-translucent` + `viewport-fit=cover`, zainstalowana na ekranie głównym, rysuje górny pasek **pod** godziną/kamerą/wyspą systemową, a stopkę pod paskiem gestów.

```css
/* górny pasek */ padding-top: env(safe-area-inset-top);
/* stopka */      padding-bottom: calc(<własny padding> + env(safe-area-inset-bottom));
```

`env()` zwraca 0 w zwykłej przeglądarce i na desktopie — nakładka jest **neutralna poza telefonem**, więc dodawaj ją od razu, nie po zgłoszeniu. Testować na fizycznym iPhonie.

### 12.3 Klawiatura zasłania pole w arkuszach przyklejonych do dołu

iOS **nakłada** klawiaturę na stronę zamiast ją skrócić, więc aktywne pole chowa się pod klawiaturą. Lekarstwo: `--kb-inset` liczone z `VisualViewport` + `interactive-widget=resizes-content` w meta viewport (Android).

### 12.4 Każda tabela w karcie = owijka `overflow-x: auto` + `min-width: 0`

Tabele z `th` ustawionym na `nowrap` bez owijki **rozpychają całą stronę** — objaw zgłaszany jako „iPhone za szeroki". Dotyczy każdej tabeli w karcie, bez wyjątku.

### 12.5 Popovery kotwiczone z POMIARU, nigdy na stałe

Tooltipy i selektory kotwiczone stałą stroną (np. zawsze „w prawo") uciekają poza ekran, gdy górny pasek zawinie się na wąskim telefonie. Stronę kotwiczenia licz z pomiaru pozycji **w momencie otwarcia**.

### 12.6 Dotyk: cele ≥ 44 × 44 px, odstęp ≥ 8 px

Wymóg Apple HIG. Dotyczy także **hitboxów na wykresach** — punkt danych o średnicy 6 px jest nieklikalny palcem.

### 12.7 Telefon to monitoring, nie analiza — degradacja zamiast skalowania

- 3–4 wskaźniki w kolumnie, wykresy uproszczone, szczegóły w rozwijanych sekcjach.
- **Degraduj, nie skaluj:** wykres słupkowy → liczba + sparkline; tabela → stos kart. Ściśnięta wersja widoku desktopowego jest bezużyteczna, nie „mniejsza".

### 12.8 🔴 PWA na iOS — trzy pułapki, które zmieniają architekturę

- **`SpeechRecognition` NIE działa w zainstalowanej PWA na iOS.** Wykrywanie funkcji przechodzi (API jest widoczne), ale rozpoznawanie **milczy** — działa wyłącznie w karcie Safari. `getUserMedia` w trybie standalone **działa**, więc ścieżka to: nagranie przez `MediaRecorder` → wysyłka na backend → STT po stronie serwera. **Planować od początku architektury głosowej**, nie po odkryciu, że nie działa.
- **Push dopiero od iOS 16.4 i tylko po instalacji** na ekranie głównym.
- **Storage czyszczony po ~7 dniach nieużywania** (ITP) — nie trzymaj krytycznego stanu wyłącznie w `localStorage`.
- Instalacja na iOS jest **manualna** (Udostępnij → Do ekranu początkowego) — zrób własną podpowiedź: detekcja `navigator.standalone === false` + iOS w user agencie. Wymagane: `apple-touch-icon`, manifest z `display: standalone`, `theme-color`.

### Test, którego nie zastąpi emulator

Chromium w trybie urządzenia **nie odtwarza** żadnej z reguł 12.1–12.3 i 12.8. Jedyny wiarygodny sprawdzian to fizyczny telefon. Automat łapie sekcje 1–11; sekcja 12 wymaga człowieka z telefonem w ręku.

---

## Audyt mobilny — Checklist

Uruchom ten checklist na istniejącym projekcie, żeby znaleźć i naprawić problemy mobilne:

### 1. Viewport
- [ ] `layout.tsx` ma explicit `export const viewport: Viewport` z `viewportFit: "cover"`

### 2. Card Components (shadcn/ui)
- [ ] `Card` ma `min-w-0 max-w-full overflow-hidden`
- [ ] `CardHeader` ma `min-w-0 max-w-full overflow-hidden`
- [ ] `CardHeader` używa `minmax(0,1fr)` zamiast `1fr` w grid-cols
- [ ] `CardTitle`, `CardDescription`, `CardContent`, `CardFooter` mają `min-w-0 max-w-full`

### 3. Grid Layouts
- [ ] Gridy kart używają `ResponsiveCardGrid` (lub mają force-reflow workaround)
- [ ] CSS breakpointy: `sm:grid-cols-2 lg:grid-cols-3` (nie w JS)
- [ ] Grid container ma `min-w-0`

### 4. Flex Layouts
- [ ] Flex children z tekstem mają `min-w-0`
- [ ] Elementy stałej wielkości (ikony) mają `shrink-0`
- [ ] Długi tekst ma `truncate` lub `line-clamp-N`

### 5. Overlays (Dialog, Dropdown, Sheet)
- [ ] Dialog/AlertDialog: `max-w-[calc(100%-2rem)]` + `[overflow-wrap:anywhere]`
- [ ] DropdownMenu: `collisionPadding={8}` + `max-w-[calc(100vw-1rem)]`
- [ ] Sheet (bottom): `max-h-[80vh]` (nie `h-[85vh]`)

### 6. Header
- [ ] MobileNav w flow headera (nie fixed/absolute)
- [ ] Responsive padding: `px-3 sm:px-4 lg:px-6`
- [ ] Responsive height: `h-14 lg:h-16`

### 7. Welcome / Hero Section
- [ ] `flex-col` na mobile → `sm:flex-row`
- [ ] Button: `w-full sm:w-auto shrink-0`
- [ ] Tekst: `min-w-0` + `truncate`

### 8. Hooks
- [ ] `useMediaQuery` jest SSR-safe (useState(false) → useEffect)

### 9. Warstwa urządzenia — iOS/Safari (sekcja 12; emulator tego NIE łapie)
- [ ] `input, textarea, select` mają `font-size: 16px !important` poniżej 640 px — selektory SZEROKIE, nie listą typów (12.1)
- [ ] Brak `user-scalable=no` / `maximum-scale=1` w viewport (zła naprawa, łamie WCAG 1.4.4)
- [ ] Ekran logowania też objęty regułą 16 px (samo pole hasła wystarczy, żeby usterka wystąpiła)
- [ ] Górny pasek i stopka mają `env(safe-area-inset-*)` — jeśli aplikacja jest instalowalna (12.2)
- [ ] Każda tabela w karcie ma owijkę `overflow-x: auto` + `min-width: 0` (12.4)
- [ ] Popovery kotwiczone z pomiaru pozycji, nie stałą stroną (12.5)
- [ ] Cele dotykowe ≥ 44 × 44 px, w tym punkty na wykresach (12.6)
- [ ] Widok mobilny **degraduje** (liczba+sparkline, stos kart), nie skaluje desktopu (12.7)
- [ ] Jeśli aplikacja ma funkcje głosowe: NIE opiera się na `SpeechRecognition` w PWA (12.8)
- [ ] Krytyczny stan nie leży wyłącznie w `localStorage` (ITP czyści po ~7 dniach)
- [ ] **Sprawdzone na fizycznym telefonie**, nie tylko w trybie urządzenia w przeglądarce

---

## Znane problemy WebView

| WebView | Problem | Workaround |
|---------|---------|------------|
| Messenger (Facebook) | Brak pełnego reflow przy orientation change | ResponsiveCardGrid z force-reflow |
| Instagram | Viewport może nie aktualizować się po rotacji | Explicit viewport meta + force-reflow |
| TikTok | Safe area insets mogą być nieprawidłowe | `viewportFit: "cover"` + CSS `env(safe-area-inset-*)` |
| Ogólne | Cache przeglądarki trzyma stary layout | `vercel --prod --force` wymusza pełny rebuild |

---

## Quick Start — Nowy projekt

```bash
# 1. Skopiuj ResponsiveCardGrid
# src/components/layout/responsive-card-grid.tsx

# 2. Skopiuj useMediaQuery
# src/hooks/use-media-query.ts

# 3. Zastosuj Card constraints (sekcja 2)
# 4. Dodaj viewport export (sekcja 1)
# 5. Popraw Dialog/Dropdown (sekcje 5-6)
# 6. Uruchom audyt mobilny (checklist powyżej)
```
