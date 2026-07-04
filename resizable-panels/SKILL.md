---
name: resizable-panels
description: Layout z regulowanymi panelami (drag handles, localStorage, responsive) przy użyciu react-resizable-panels. Używaj gdy trzeba dodać regulowane panele, split pane, separator do zmiany rozmiaru, lub podzielić widok na regulowane kolumny.
---

# Resizable Panels — Skill

Dodaje regulowany layout z separatorami do przesuwania (drag handles), persystencją w localStorage i osobnym layoutem na mobile.

## Kiedy uzywac

- Podział widoku na kolumny/wiersze z mozliwoscia zmiany proporcji
- Chat + sidebar, editor + preview, lista + szczegoly
- Zagniezdzone podzialy (np. kolumny + wiersze wewnatrz kolumny)

## Zaleznosci

```bash
npm install react-resizable-panels
# wersja >= 4.0 (API: Group, Panel, Separator, useDefaultLayout)
```

## Architektura

### Kluczowe elementy

| Element | Rola |
|---------|------|
| `Group` | Kontener paneli (orientation: horizontal/vertical) |
| `Panel` | Pojedynczy panel (id, defaultSize, minSize, maxSize) |
| `Separator` | Uchwyt do przesuwania miedzy panelami |
| `useDefaultLayout` | Hook do persystencji proporcji w localStorage |

### Schemat zagniezdzonego layoutu

```
Group (horizontal) — kolumny lewo/prawo
├─ Panel (left)
│  └─ Group (vertical) — wiersze gora/dol
│     ├─ Panel (top)
│     ├─ Separator (vertical handle)
│     └─ Panel (bottom)
├─ Separator (horizontal handle)
└─ Panel (right)
```

## Implementacja krok po kroku

### 1. CSS dla uchwytow (resize handles)

Dodaj do globalnego CSS. Zamien `PREFIX` na nazwe komponentu (np. `discovery`, `editor`).

```css
/* Horizontal resize handle (kolumny lewo/prawo) */
.PREFIX-resize-handle-horizontal {
  width: 3px;
  background: var(--border-color, #2D3244);
  transition: background 0.15s ease;
  cursor: col-resize;
  position: relative;
}
.PREFIX-resize-handle-horizontal[data-separator="hover"],
.PREFIX-resize-handle-horizontal[data-separator="active"] {
  background: var(--accent-color, #FF6B2C);
}
.PREFIX-resize-handle-horizontal::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 3px;
  height: 24px;
  border-radius: 2px;
  background: var(--muted-color, #5C6478);
  opacity: 0;
  transition: opacity 0.15s ease;
}
.PREFIX-resize-handle-horizontal[data-separator="hover"]::after,
.PREFIX-resize-handle-horizontal[data-separator="active"]::after {
  opacity: 1;
  background: var(--accent-color, #FF6B2C);
}

/* Vertical resize handle (wiersze gora/dol) */
.PREFIX-resize-handle-vertical {
  height: 3px;
  background: var(--border-color, #2D3244);
  transition: background 0.15s ease;
  cursor: row-resize;
  position: relative;
}
.PREFIX-resize-handle-vertical[data-separator="hover"],
.PREFIX-resize-handle-vertical[data-separator="active"] {
  background: var(--accent-color, #FF6B2C);
}
.PREFIX-resize-handle-vertical::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 24px;
  height: 3px;
  border-radius: 2px;
  background: var(--muted-color, #5C6478);
  opacity: 0;
  transition: opacity 0.15s ease;
}
.PREFIX-resize-handle-vertical[data-separator="hover"]::after,
.PREFIX-resize-handle-vertical[data-separator="active"]::after {
  opacity: 1;
  background: var(--accent-color, #FF6B2C);
}
```

**Zachowanie uchwytow:**
- Domyslnie: cienka linia 3px w kolorze border
- Hover: podswietlenie accent + pojawienie sie wskaznika (24px linia)
- Active (drag): pelen kolor accent
- Atrybuty `data-separator` sa automatycznie ustawiane przez biblioteke

### 2. Komponent z panelami

```tsx
"use client";

import { useEffect, useState } from "react";
import { Group, Panel, Separator, useDefaultLayout } from "react-resizable-panels";

interface ResizableLayoutProps {
  leftContent: React.ReactNode;
  rightContent: React.ReactNode;
  /** Opcjonalny podzial lewego panelu na gora/dol */
  topContent?: React.ReactNode;
  bottomContent?: React.ReactNode;
  /** Klasa CSS prefix dla uchwytow (np. "editor") */
  handlePrefix?: string;
  /** Breakpoint dla desktop (px) */
  desktopBreakpoint?: number;
  /** Fallback na mobile */
  mobileContent: React.ReactNode;
}

export function ResizableLayout({
  leftContent,
  rightContent,
  topContent,
  bottomContent,
  handlePrefix = "app",
  desktopBreakpoint = 1024,
  mobileContent,
}: ResizableLayoutProps) {
  // Desktop detection — panele tylko na duzym ekranie
  const [isDesktop, setIsDesktop] = useState(false);

  useEffect(() => {
    const mql = window.matchMedia(`(min-width: ${desktopBreakpoint}px)`);
    setIsDesktop(mql.matches);
    const handler = (e: MediaQueryListEvent) => setIsDesktop(e.matches);
    mql.addEventListener("change", handler);
    return () => mql.removeEventListener("change", handler);
  }, [desktopBreakpoint]);

  // Persystencja proporcji w localStorage
  const { defaultLayout: columnsLayout, onLayoutChanged: onColumnsChanged } =
    useDefaultLayout({
      id: `${handlePrefix}-columns`,
      storage: typeof window !== "undefined" ? localStorage : undefined,
    });

  const { defaultLayout: rowsLayout, onLayoutChanged: onRowsChanged } =
    useDefaultLayout({
      id: `${handlePrefix}-rows`,
      storage: typeof window !== "undefined" ? localStorage : undefined,
    });

  if (!isDesktop) return <>{mobileContent}</>;

  return (
    <Group
      orientation="horizontal"
      defaultLayout={columnsLayout}
      onLayoutChanged={onColumnsChanged}
      className="h-full w-full"
    >
      <Panel id="left" defaultSize="75%" minSize="50%" maxSize="85%">
        {topContent && bottomContent ? (
          <Group
            orientation="vertical"
            defaultLayout={rowsLayout}
            onLayoutChanged={onRowsChanged}
          >
            <Panel id="top" defaultSize="85%" minSize="40%">
              {topContent}
            </Panel>
            <Separator className={`${handlePrefix}-resize-handle-vertical`} />
            <Panel id="bottom" defaultSize="15%" minSize="10%" maxSize="50%">
              {bottomContent}
            </Panel>
          </Group>
        ) : (
          leftContent
        )}
      </Panel>
      <Separator className={`${handlePrefix}-resize-handle-horizontal`} />
      <Panel id="right" defaultSize="25%" minSize="15%" maxSize="50%">
        {rightContent}
      </Panel>
    </Group>
  );
}
```

### 3. Uzycie w komponencie

```tsx
<div className="h-full flex">
  <ResizableLayout
    handlePrefix="discovery"
    topContent={
      <div className="h-full overflow-y-auto p-6">
        {/* Scrollowalna lista wiadomosci */}
      </div>
    }
    bottomContent={
      <ChatInput fillAvailable />
    }
    leftContent={null} {/* nie uzywane gdy top+bottom sa podane */}
    rightContent={<Sidebar />}
    mobileContent={
      <div className="flex flex-col h-full w-full">
        {/* Mobilny layout bez separatorow */}
        <div className="flex-1 overflow-y-auto min-h-0">{messages}</div>
        <ChatInput />
      </div>
    }
  />
</div>
```

## Wazne zasady

### Persystencja
- `useDefaultLayout` automatycznie zapisuje w localStorage pod kluczem `react-resizable-panels:{id}`
- Kazdy `Group` potrzebuje osobnego `useDefaultLayout` z unikalnym `id`
- Wartosci to procenty (np. `{"left":75,"right":25}`)

### Responsywnosc
- Panele resizable TYLKO na desktop (>= breakpoint)
- Na mobile: osobny layout (np. Sheet/Drawer dla sidebara, stacked layout)
- `isDesktop` via `matchMedia` z `addEventListener("change")` — reaguje na resize okna

### Panel sizing
- `defaultSize` — domyslny rozmiar w % (nadpisywany przez localStorage)
- `minSize` / `maxSize` — limity przeciagania
- Suma paneli w jednym Group musi dawac 100%

### CSS handles
- Uchwyt MUSI miec `position: relative` (dla pseudo-elementu `::after`)
- `data-separator` atrybuty: `inactive` | `hover` | `active` — ustawiane automatycznie
- `::after` pseudo-element tworzy wizualny wskaznik (linia 24px)

### fillAvailable na textarea w panelu
- Gdy textarea jest w panelu resizable, ustaw `resize: none` (natywny handle redundantny)
- Uzyj `h-full min-h-0` na kontenerze i `flex-1` na textarea, zeby wypelnila panel

## Checklist implementacji

1. [ ] `npm install react-resizable-panels`
2. [ ] Dodaj CSS handles do globalnego arkusza stylow (zamien PREFIX)
3. [ ] Dodaj `isDesktop` state z `matchMedia` w komponencie
4. [ ] Dodaj `useDefaultLayout` hook(i) dla kazdego `Group`
5. [ ] Zbuduj layout: `Group > Panel + Separator + Panel`
6. [ ] Ustaw `defaultSize`, `minSize`, `maxSize` na kazdym `Panel`
7. [ ] Dodaj mobilny layout jako fallback (`!isDesktop`)
8. [ ] Przetestuj: drag separatorow, persystencja po reload, mobile breakpoint
9. [ ] Usun `resize-vertical` z textarea jesli jest w panelu resizable
