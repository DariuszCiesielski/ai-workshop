---
name: content-width-toggle
description: Regulowana szerokość kontenera treści (Wąski/Standard/Szeroki/Pełny) z persystentnym segmented control i localStorage. Używaj w aplikacjach z treściami tekstowymi, CMS, dokumentacji, dashboardach.
---

# Content Width Toggle

## Opis
Regulowana szerokość kontenera treści z persystentnym segmented control. Użytkownik wybiera jedną z 4 opcji szerokości (Wąski/Standard/Szeroki/Pełny), a preferencja zapisuje się w localStorage i działa globalnie na wszystkich stronach.

## Triggery
- "dodaj regulowaną szerokość"
- "toggle szerokości"
- "rozszerzanie kontenera"
- "użytkownik zmienia szerokość"
- "content width toggle"
- "regulowany max-width"

## Kiedy używać
- Aplikacje z treściami tekstowymi (CMS, edukacja, dokumentacja, blogi)
- Gdy użytkownik potrzebuje kontroli nad szerokością widoku
- Strony z długimi tekstami, gdzie wąski widok poprawia czytelność
- Dashboardy, gdzie pełna szerokość wykorzystuje duże monitory

## Stack
- React 18/19 (hooks + client components)
- Tailwind CSS v3/v4 (`max-w-*`, `container`)
- Next.js App Router (server + client component pattern)
- Opcjonalnie: shadcn/ui (Button), ale nie wymagane

## Zależności
Brak dodatkowych - czysty React + Tailwind.

## Instrukcje

### Krok 1: Hook `useContentWidth`

Utwórz `src/hooks/use-content-width.ts`:

```typescript
'use client';

import { useState, useEffect } from 'react';

export type ContentWidth = 'narrow' | 'default' | 'wide' | 'full';

const STORAGE_KEY = 'app-content-width'; // zmień prefix na nazwę projektu

const WIDTH_CLASSES: Record<ContentWidth, string> = {
  narrow: 'max-w-2xl',   // 672px
  default: 'max-w-4xl',  // 896px
  wide: 'max-w-6xl',     // 1152px
  full: 'max-w-full',    // bez limitu
};

export function useContentWidth() {
  const [width, setWidth] = useState<ContentWidth>('default');

  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY) as ContentWidth | null;
    if (stored && stored in WIDTH_CLASSES) {
      setWidth(stored);
    }
  }, []);

  const setContentWidth = (newWidth: ContentWidth) => {
    setWidth(newWidth);
    localStorage.setItem(STORAGE_KEY, newWidth);
  };

  return {
    width,
    setContentWidth,
    widthClass: WIDTH_CLASSES[width],
  };
}
```

### Krok 2: Toggle UI (segmented control)

Utwórz `src/components/ui/content-width-toggle.tsx`:

```typescript
'use client';

import { cn } from '@/lib/utils'; // lub własna implementacja cn()
import type { ContentWidth } from '@/hooks/use-content-width';

interface ContentWidthToggleProps {
  width: ContentWidth;
  onChange: (width: ContentWidth) => void;
}

const options: { value: ContentWidth; label: string }[] = [
  { value: 'narrow', label: 'Wąski' },
  { value: 'default', label: 'Standard' },
  { value: 'wide', label: 'Szeroki' },
  { value: 'full', label: 'Pełny' },
];

export function ContentWidthToggle({ width, onChange }: ContentWidthToggleProps) {
  return (
    <div className="inline-flex items-center rounded-lg border bg-muted p-0.5 gap-0.5">
      {options.map(({ value, label }) => (
        <button
          key={value}
          onClick={() => onChange(value)}
          className={cn(
            'px-2.5 py-1 text-xs rounded-md transition-colors',
            width === value
              ? 'bg-background text-foreground shadow-sm'
              : 'text-muted-foreground hover:text-foreground'
          )}
        >
          {label}
        </button>
      ))}
    </div>
  );
}
```

### Krok 3: ContentContainer (wrapper)

Utwórz `src/components/layout/content-container.tsx`:

```typescript
'use client';

import { useContentWidth } from '@/hooks/use-content-width';
import { ContentWidthToggle } from '@/components/ui/content-width-toggle';
import { cn } from '@/lib/utils';

interface ContentContainerProps {
  children: React.ReactNode;
  className?: string;
}

export function ContentContainer({ children, className }: ContentContainerProps) {
  const { width, setContentWidth, widthClass } = useContentWidth();

  return (
    <div className={cn('container transition-all duration-300', widthClass, className)}>
      <div className="flex justify-end mb-4">
        <ContentWidthToggle width={width} onChange={setContentWidth} />
      </div>
      {children}
    </div>
  );
}
```

### Krok 4: Zastosowanie w stronach

**Server component (Next.js App Router):**
```tsx
import { ContentContainer } from '@/components/layout/content-container';

export default async function MyPage() {
  const data = await fetchData();

  return (
    <ContentContainer className="py-8">
      <h1>{data.title}</h1>
      {/* treść strony */}
    </ContentContainer>
  );
}
```

**Client component:**
```tsx
'use client';
import { ContentContainer } from '@/components/layout/content-container';

export function MyClientPage({ data }) {
  return (
    <ContentContainer className="py-8">
      {/* treść strony */}
    </ContentContainer>
  );
}
```

**Migracja z istniejącego kodu:**
```diff
- <div className="container max-w-4xl py-8">
+ <ContentContainer className="py-8">
    {/* treść */}
- </div>
+ </ContentContainer>
```

## Warianty i konfiguracja

### Mniej opcji (np. tylko 2)
```typescript
const options = [
  { value: 'default', label: 'Standard' },
  { value: 'full', label: 'Pełny' },
];
```

### Inne rozmiary
```typescript
const WIDTH_CLASSES = {
  narrow: 'max-w-xl',    // 576px - bardzo wąski
  default: 'max-w-3xl',  // 768px - dla quizów/formularzy
  wide: 'max-w-5xl',     // 1024px
  full: 'max-w-full',
};
```

### Angielskie etykiety
```typescript
const options = [
  { value: 'narrow', label: 'Narrow' },
  { value: 'default', label: 'Default' },
  { value: 'wide', label: 'Wide' },
  { value: 'full', label: 'Full' },
];
```

## Ważne uwagi

- `max-w-full` jest konieczne dla opcji "Pełny" - pusty string nie nadpisze `container`'s max-width
- Klasa `container` w Tailwind ustawia własny max-width - `max-w-full` ją nadpisuje
- Jedna preferencja w localStorage = zmiana na jednej stronie działa globalnie
- Segmented control z **tekstowymi etykietami** (NIE ikony - ikony typu AlignLeft/AlignCenter wyglądają jak formatowanie tekstu i są mylące)
- `transition-all duration-300` daje płynną animację zmiany szerokości
- Działa w Next.js App Router - client component wrapper w server component pages

## Checklist implementacji

- [ ] Hook `useContentWidth` z localStorage
- [ ] Toggle UI (segmented control, tekstowe etykiety)
- [ ] ContentContainer wrapper
- [ ] Zastąpienie `<div className="container max-w-*">` na `<ContentContainer>`
- [ ] Sprawdzenie że "Pełny" faktycznie rozciąga (max-w-full, nie pusty string)
- [ ] Test na mobile (toggle powinien być widoczny i użyteczny)
