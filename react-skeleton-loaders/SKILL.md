---
name: react-skeleton-loaders
description: Wzorce skeleton loaderów dopasowanych do layoutów komponentów — karty, listy, tabele, strony. Używaj przy implementacji stanów ładowania w aplikacjach React.
---

# React Skeleton Loaders

This skill provides patterns for creating skeleton loaders that perfectly match your component layouts for a seamless loading experience.

## When to Use

- Implementing loading states for data fetching
- Creating skeleton placeholders for cards, lists, tables
- Improving perceived performance
- Handling async content loading

## Prerequisites

### Skeleton Component (shadcn/ui style)

```typescript
// components/ui/skeleton.tsx
import { cn } from '@/lib/utils';

function Skeleton({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('animate-pulse rounded-md bg-primary/10', className)}
      {...props}
    />
  );
}

export { Skeleton };
```

## Skeleton Patterns

### 1. Card Skeleton

Match your Card component layout exactly:

```typescript
// components/skeletons/DocumentCardSkeleton.tsx
import { Card, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

export function DocumentCardSkeleton() {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-start gap-4">
          {/* Icon placeholder */}
          <Skeleton className="h-9 w-9 rounded-lg flex-shrink-0" />

          <div className="flex-1 min-w-0 space-y-2">
            {/* Title row */}
            <div className="flex items-center gap-2">
              <Skeleton className="h-5 w-48" />
              <Skeleton className="h-4 w-4 rounded-full" />
            </div>

            {/* Type badge */}
            <Skeleton className="h-5 w-16 rounded-full" />

            {/* Metadata row */}
            <div className="flex items-center gap-4">
              <Skeleton className="h-4 w-24" />
              <Skeleton className="h-4 w-20" />
            </div>
          </div>

          {/* Action button */}
          <Skeleton className="h-8 w-8 rounded-md flex-shrink-0" />
        </div>
      </CardContent>
    </Card>
  );
}
```

### 2. List Skeleton

Render multiple skeleton items:

```typescript
// components/skeletons/DocumentsListSkeleton.tsx
import { DocumentCardSkeleton } from './DocumentCardSkeleton';

interface DocumentsListSkeletonProps {
  count?: number;
}

export function DocumentsListSkeleton({ count = 5 }: DocumentsListSkeletonProps) {
  return (
    <div className="space-y-3">
      {Array.from({ length: count }).map((_, index) => (
        <DocumentCardSkeleton key={index} />
      ))}
    </div>
  );
}
```

### 3. Stats Card Skeleton

```typescript
// components/skeletons/StatsCardSkeleton.tsx
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

export function StatsCardSkeleton() {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <Skeleton className="h-4 w-24" />
        <Skeleton className="h-4 w-4" />
      </CardHeader>
      <CardContent>
        <Skeleton className="h-8 w-16 mb-1" />
        <Skeleton className="h-3 w-32" />
      </CardContent>
    </Card>
  );
}

// Grid of stats
export function StatsGridSkeleton() {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      {Array.from({ length: 4 }).map((_, index) => (
        <StatsCardSkeleton key={index} />
      ))}
    </div>
  );
}
```

### 4. Table Skeleton

```typescript
// components/skeletons/TableSkeleton.tsx
import { Skeleton } from '@/components/ui/skeleton';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';

interface TableSkeletonProps {
  columns: number;
  rows?: number;
}

export function TableSkeleton({ columns, rows = 5 }: TableSkeletonProps) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          {Array.from({ length: columns }).map((_, index) => (
            <TableHead key={index}>
              <Skeleton className="h-4 w-20" />
            </TableHead>
          ))}
        </TableRow>
      </TableHeader>
      <TableBody>
        {Array.from({ length: rows }).map((_, rowIndex) => (
          <TableRow key={rowIndex}>
            {Array.from({ length: columns }).map((_, colIndex) => (
              <TableCell key={colIndex}>
                <Skeleton
                  className={cn(
                    'h-4',
                    colIndex === 0 ? 'w-32' : 'w-24'
                  )}
                />
              </TableCell>
            ))}
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
```

### 5. Page Header Skeleton

```typescript
// components/skeletons/PageHeaderSkeleton.tsx
import { Skeleton } from '@/components/ui/skeleton';

export function PageHeaderSkeleton() {
  return (
    <div className="flex items-center justify-between mb-6">
      <div className="space-y-2">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-4 w-64" />
      </div>
      <Skeleton className="h-10 w-32" />
    </div>
  );
}
```

### 6. Full Page Skeleton

```typescript
// components/skeletons/DocumentsPageSkeleton.tsx
import { PageHeaderSkeleton } from './PageHeaderSkeleton';
import { StatsGridSkeleton } from './StatsCardSkeleton';
import { DocumentsListSkeleton } from './DocumentsListSkeleton';

export function DocumentsPageSkeleton() {
  return (
    <div className="space-y-6">
      <PageHeaderSkeleton />
      <StatsGridSkeleton />
      <DocumentsListSkeleton count={5} />
    </div>
  );
}
```

## Conditional Rendering Pattern

Always render in this order: **Loading → Error → Empty → Content**

```typescript
// pages/Documents.tsx
import { useDocuments } from '@/hooks/useDocuments';
import { DocumentsListSkeleton } from '@/components/skeletons/DocumentsListSkeleton';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Button } from '@/components/ui/button';
import { AlertCircle, FileText, RefreshCw } from 'lucide-react';

export function Documents() {
  const { documents, isLoading, isError, error, refetch } = useDocuments();

  // 1. Loading state
  if (isLoading) {
    return <DocumentsListSkeleton count={5} />;
  }

  // 2. Error state
  if (isError) {
    return (
      <Alert variant="destructive">
        <AlertCircle className="h-4 w-4" />
        <AlertDescription className="flex items-center justify-between">
          <span>{error?.message || 'Wystąpił błąd podczas ładowania'}</span>
          <Button variant="outline" size="sm" onClick={() => refetch()}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Spróbuj ponownie
          </Button>
        </AlertDescription>
      </Alert>
    );
  }

  // 3. Empty state
  if (!documents || documents.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <FileText className="h-12 w-12 text-muted-foreground mb-4" />
        <p className="font-medium text-lg">Brak dokumentów</p>
        <p className="text-muted-foreground mt-1">
          Dodaj pierwszy dokument, aby rozpocząć
        </p>
      </div>
    );
  }

  // 4. Content
  return (
    <div className="space-y-3">
      {documents.map((doc) => (
        <DocumentCard key={doc.id} document={doc} />
      ))}
    </div>
  );
}
```

## Alternative: Inline Conditional Rendering

For simpler cases where states are rendered together:

```typescript
function DocumentsList() {
  const { documents, isLoading, isError, refetch } = useDocuments();

  return (
    <div className="space-y-4">
      {/* Loading */}
      {isLoading && <DocumentsListSkeleton count={5} />}

      {/* Error */}
      {isError && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            Błąd ładowania dokumentów
            <Button variant="link" onClick={() => refetch()}>
              Spróbuj ponownie
            </Button>
          </AlertDescription>
        </Alert>
      )}

      {/* Empty */}
      {!isLoading && !isError && documents?.length === 0 && (
        <EmptyState icon={FileText} message="Brak dokumentów" />
      )}

      {/* Content */}
      {!isLoading && !isError && documents && documents.length > 0 && (
        <div className="space-y-3">
          {documents.map((doc) => (
            <DocumentCard key={doc.id} document={doc} />
          ))}
        </div>
      )}
    </div>
  );
}
```

## Skeleton Tips

### 1. Match Real Layout Exactly

The skeleton should have the same dimensions and spacing as the actual component:

```typescript
// Real component
<div className="flex items-center gap-4">
  <Avatar className="h-10 w-10" />
  <div>
    <h3 className="font-semibold">John Doe</h3>
    <p className="text-sm text-muted-foreground">john@example.com</p>
  </div>
</div>

// Matching skeleton
<div className="flex items-center gap-4">
  <Skeleton className="h-10 w-10 rounded-full" />
  <div className="space-y-1">
    <Skeleton className="h-5 w-24" />
    <Skeleton className="h-4 w-32" />
  </div>
</div>
```

### 2. Use Realistic Widths

Don't make all skeletons the same width - vary them to look natural:

```typescript
// Good - varied widths
<div className="space-y-2">
  <Skeleton className="h-4 w-48" />
  <Skeleton className="h-4 w-32" />
  <Skeleton className="h-4 w-40" />
</div>

// Bad - uniform widths look artificial
<div className="space-y-2">
  <Skeleton className="h-4 w-full" />
  <Skeleton className="h-4 w-full" />
  <Skeleton className="h-4 w-full" />
</div>
```

### 3. Animate Subtly

The default `animate-pulse` is usually sufficient. Avoid complex animations that distract users.

### 4. Consider Dark Mode

Ensure skeleton colors work in both light and dark modes:

```css
/* Good - uses opacity */
.skeleton {
  background-color: hsl(var(--primary) / 0.1);
}

/* Alternative for dark mode */
.dark .skeleton {
  background-color: hsl(var(--muted));
}
```

## File Structure

```
src/components/skeletons/
├── DocumentCardSkeleton.tsx
├── DocumentsListSkeleton.tsx
├── PageHeaderSkeleton.tsx
├── StatsCardSkeleton.tsx
├── TableSkeleton.tsx
└── index.ts

// index.ts - re-exports
export * from './DocumentCardSkeleton';
export * from './DocumentsListSkeleton';
export * from './PageHeaderSkeleton';
export * from './StatsCardSkeleton';
export * from './TableSkeleton';
```

## Best Practices

1. **Create skeleton for each complex component** - Match dimensions exactly
2. **Use consistent animation** - `animate-pulse` works well
3. **Render loading first** - Always check `isLoading` before other states
4. **Provide retry option** - Error states should allow refetching
5. **Show meaningful empty states** - Include icon, message, and action
6. **Keep skeletons simple** - Don't over-engineer with too many elements
