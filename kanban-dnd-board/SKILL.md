---
name: kanban-dnd-board
description: Creates a Kanban board with drag & drop using @dnd-kit in React. Includes column layout, sortable cards, collision detection for empty columns, and persistence. Use when building Kanban boards, task boards, project management dashboards, or any drag & drop column interface.
---

# Kanban Board z Drag & Drop (@dnd-kit)

## Kiedy używać
- "dodaj kanban board"
- "zrób tablicę kanban z drag and drop"
- "przeciąganie kart między kolumnami"
- "dashboard z kolumnami drag & drop"

## Stack
- `@dnd-kit/core` — DndContext, sensory, collision detection
- `@dnd-kit/sortable` — sortowanie kart wewnątrz kolumn
- `@dnd-kit/utilities` — CSS transform helpers
- React (App Router lub Vite), Tailwind CSS

## Instalacja

```bash
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
```

## Architektura komponentów

```
KanbanBoard          — DndContext, sensory, handlery drag
├── KanbanColumn     — useDroppable, SortableContext
│   └── Card         — useSortable, transform, listeners
└── DragOverlay      — kopia karty widoczna podczas drag
```

## Pułapki do unikania

| Pułapka | Skutek | Rozwiązanie |
|---------|--------|-------------|
| `closestCorners` | Puste kolumny niedostępne | `pointerWithin` + `rectIntersection` |
| Dynamiczne `useSensors(0↔1)` | Drag nie działa po F5 | Sensor stały, guard w handlerach |
| Brak `min-h` na droppable | Drop do pustej kolumny niemożliwy | `min-h-[200px]` |
| Brak `stopPropagation` na linkach | Kliknięcie linku blokuje drag | `onClick={e => e.stopPropagation()}` |
| Statystyki z server props | Liczniki nie aktualizują się po drag | Callback `onItemsChange` |
| Testowanie Playwright | `setPointerCapture` nie działa | Testy manualne lub @testing-library |

## Kluczowe wzorce

### 1. Sensor — zawsze zarejestrowany, guard w handlerach

**NIGDY** nie zmieniaj dynamicznie liczby sensorów w `useSensors`.
Po hydration/F5 `useSensors` może nie zaktualizować się poprawnie.

```tsx
// ✅ DOBRZE
const pointerSensor = useSensor(PointerSensor, {
  activationConstraint: { distance: 8 },
});
const sensors = useSensors(pointerSensor);

function handleDragStart(event: DragStartEvent) {
  if (!canDrag) return; // guard tutaj, nie w useSensors
  setActiveItem(items.find(i => i.id === event.active.id) || null);
}

// ❌ ŹLE — psuje się po F5/hydration
const sensors = useSensors(...(canDrag ? [pointerSensor] : []));
```

### 2. Collision detection — pointerWithin + fallback

`closestCorners` preferuje dużą kolumnę (np. Backlog z 27 kartami)
nad pustą kolumnę obok — kursor jest "bliżej" rogów dużej kolumny.

```tsx
import { pointerWithin, rectIntersection, type CollisionDetection } from "@dnd-kit/core";

const collisionDetection: CollisionDetection = useCallback((args) => {
  const pointerCollisions = pointerWithin(args);
  if (pointerCollisions.length > 0) return pointerCollisions;
  return rectIntersection(args);
}, []);
```

### 3. Droppable area — min-height na pustych kolumnach

Bez `min-h` pusta kolumna ma droppable area ~0px (tylko padding).

```tsx
const { setNodeRef, isOver } = useDroppable({ id: columnId });

<div ref={setNodeRef} className="min-h-[200px] flex-1 space-y-2 px-2 pb-2">
  <SortableContext items={items.map(i => i.id)} strategy={verticalListSortingStrategy}>
    {items.map(item => <Card key={item.id} item={item} />)}
  </SortableContext>
</div>
```

### 4. Sortable Card

```tsx
function Card({ item }: { item: Item }) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } =
    useSortable({ id: item.id });

  return (
    <div
      ref={setNodeRef}
      style={{ transform: CSS.Transform.toString(transform), transition }}
      {...attributes}
      {...listeners}
      className={cn(
        "rounded-lg border bg-card p-3 cursor-grab active:cursor-grabbing",
        isDragging && "opacity-50 ring-2 ring-primary/20"
      )}
    >
      {/* Linki wewnątrz: stopPropagation żeby nie blokować drag */}
      <a href={item.url} onClick={e => e.stopPropagation()}>{item.title}</a>
    </div>
  );
}
```

### 5. Handlery drag — pełny flow

```tsx
function handleDragStart(event: DragStartEvent) {
  if (!canDrag) return;
  setActiveItem(items.find(i => i.id === event.active.id) || null);
}

function handleDragOver(event: DragOverEvent) {
  if (!canDrag) return;
  const { active, over } = event;
  if (!over) return;
  const overId = over.id as string;

  // Drop na kolumnę (pusta kolumna)
  const overColumn = COLUMNS.find(c => c.id === overId);
  if (overColumn) {
    setItems(prev => prev.map(i =>
      i.id === active.id ? { ...i, status: overColumn.id } : i
    ));
    return;
  }

  // Drop na kartę w innej kolumnie
  const overItem = items.find(i => i.id === overId);
  const activeItem = items.find(i => i.id === active.id);
  if (activeItem && overItem && activeItem.status !== overItem.status) {
    setItems(prev => prev.map(i =>
      i.id === active.id ? { ...i, status: overItem.status } : i
    ));
  }
}

async function handleDragEnd(event: DragEndEvent) {
  setActiveItem(null);
  if (!canDrag) return;
  const { active, over } = event;
  if (!over) return;

  // Sortowanie wewnątrz kolumny (arrayMove)
  // ...

  // Persist do bazy danych
  await saveToDatabase(active.id, updatedItem);
}
```

### 6. DndContext + DragOverlay

```tsx
<DndContext
  id="kanban-dnd"
  sensors={sensors}
  collisionDetection={collisionDetection}
  onDragStart={handleDragStart}
  onDragOver={handleDragOver}
  onDragEnd={handleDragEnd}
>
  <div className="flex gap-4 overflow-x-auto items-stretch min-h-[70vh]">
    {COLUMNS.map(col => (
      <KanbanColumn key={col.id} {...col} items={itemsByStatus(col.id)} />
    ))}
  </div>
  <DragOverlay>
    {activeItem && <Card item={activeItem} />}
  </DragOverlay>
</DndContext>
```

### 7. Synchronizacja statystyk z parent komponentem

KanbanBoard zarządza własnym `useState`. Parent potrzebuje live statystyk:

```tsx
// KanbanBoard
useEffect(() => {
  onItemsChange?.(items);
}, [items, onItemsChange]);

// Parent
const [liveItems, setLiveItems] = useState(serverItems);
const inProgressCount = liveItems.filter(i => i.status === "in-progress").length;

<KanbanBoard initialItems={filtered} onItemsChange={setLiveItems} />
```

## Kolumna — pełny komponent

```tsx
"use client";
import { useDroppable } from "@dnd-kit/core";
import { SortableContext, verticalListSortingStrategy } from "@dnd-kit/sortable";
import { cn } from "@/lib/utils";

export function KanbanColumn({ id, label, items }: ColumnProps) {
  const { setNodeRef, isOver } = useDroppable({ id });

  return (
    <div className={cn(
      "flex w-72 shrink-0 flex-col rounded-lg bg-muted/30",
      isOver && "ring-2 ring-primary/30"
    )}>
      <div className="flex items-center gap-2 px-3 py-2.5">
        <h3 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          {label}
        </h3>
        <span className="rounded-full bg-muted px-1.5 text-[10px] font-medium">
          {items.length}
        </span>
      </div>
      <div ref={setNodeRef} className="min-h-[200px] flex-1 space-y-2 px-2 pb-2">
        <SortableContext items={items.map(i => i.id)} strategy={verticalListSortingStrategy}>
          {items.map(item => <Card key={item.id} item={item} />)}
        </SortableContext>
      </div>
    </div>
  );
}
```
