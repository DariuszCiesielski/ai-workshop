---
name: toast-notifications
description: Lekki system powiadomień toast na czystym React (useState) z auto-dismiss, wariantami success/error i Tailwind CSS. Bez zewnętrznych zależności. Używaj przy dodawaniu prostych notyfikacji do aplikacji React.
---

# Toast Notifications Pattern

This skill provides a lightweight toast notification system using only React useState and Tailwind CSS. No external libraries required.

## When to Use

- Need simple success/error notifications
- Want to avoid installing toast libraries (react-toastify, sonner, etc.)
- Building lightweight React applications
- Replacing native `alert()` with styled notifications

## Triggers

- "dodaj toast notifications"
- "powiadomienia toast"
- "zastąp alert toastem"
- "dodaj powiadomienia"

## Implementation

### 1. State Setup

Add toast state to your component:

```typescript
const [toast, setToast] = useState<{
  message: string;
  type: 'success' | 'error';
} | null>(null);
```

### 2. Auto-dismiss Effect

Add useEffect for automatic dismissal:

```typescript
// Auto-hide toast after 4 seconds
useEffect(() => {
  if (toast) {
    const timer = setTimeout(() => setToast(null), 4000);
    return () => clearTimeout(timer);
  }
}, [toast]);
```

### 3. Toast Component JSX

Add this at the end of your component's return statement:

```tsx
{/* Toast Notification */}
{toast && (
  <div
    className={`fixed top-4 right-4 z-[100] px-6 py-4 rounded-lg shadow-xl border flex items-center gap-3 animate-in slide-in-from-top-2 duration-300 ${
      toast.type === 'success'
        ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
        : 'bg-rose-50 border-rose-200 text-rose-800'
    }`}
  >
    {toast.type === 'success' ? (
      <CheckCircle className="w-5 h-5 text-emerald-600 flex-shrink-0" />
    ) : (
      <AlertCircle className="w-5 h-5 text-rose-600 flex-shrink-0" />
    )}
    <span className="font-medium whitespace-pre-line">{toast.message}</span>
    <button
      onClick={() => setToast(null)}
      className="ml-2 text-current opacity-60 hover:opacity-100 transition-opacity"
    >
      <X className="w-4 h-4" />
    </button>
  </div>
)}
```

### 4. Usage

```typescript
// Success toast
setToast({ message: 'Record saved successfully!', type: 'success' });

// Error toast
setToast({ message: 'Failed to save record.', type: 'error' });

// Multi-line message
setToast({
  message: `Export completed!\nPrepared ${count} records.`,
  type: 'success'
});
```

## Complete Example

```typescript
import React, { useState, useEffect } from 'react';
import { CheckCircle, AlertCircle, X } from 'lucide-react';

function App() {
  const [toast, setToast] = useState<{
    message: string;
    type: 'success' | 'error';
  } | null>(null);

  // Auto-hide toast after 4 seconds
  useEffect(() => {
    if (toast) {
      const timer = setTimeout(() => setToast(null), 4000);
      return () => clearTimeout(timer);
    }
  }, [toast]);

  const handleSave = async () => {
    try {
      // ... save logic
      setToast({ message: 'Saved successfully!', type: 'success' });
    } catch (error) {
      setToast({
        message: error instanceof Error ? error.message : 'An error occurred',
        type: 'error'
      });
    }
  };

  return (
    <div>
      <button onClick={handleSave}>Save</button>

      {/* Toast Notification */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-[100] px-6 py-4 rounded-lg shadow-xl border flex items-center gap-3 animate-in slide-in-from-top-2 duration-300 ${
            toast.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
              : 'bg-rose-50 border-rose-200 text-rose-800'
          }`}
        >
          {toast.type === 'success' ? (
            <CheckCircle className="w-5 h-5 text-emerald-600 flex-shrink-0" />
          ) : (
            <AlertCircle className="w-5 h-5 text-rose-600 flex-shrink-0" />
          )}
          <span className="font-medium whitespace-pre-line">{toast.message}</span>
          <button
            onClick={() => setToast(null)}
            className="ml-2 text-current opacity-60 hover:opacity-100 transition-opacity"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );
}
```

## Variants

### Warning Toast

```tsx
const [toast, setToast] = useState<{
  message: string;
  type: 'success' | 'error' | 'warning';
} | null>(null);

// In JSX, add warning variant:
toast.type === 'warning'
  ? 'bg-amber-50 border-amber-200 text-amber-800'

// Icon for warning:
<AlertTriangle className="w-5 h-5 text-amber-600 flex-shrink-0" />
```

### Info Toast

```tsx
toast.type === 'info'
  ? 'bg-blue-50 border-blue-200 text-blue-800'

// Icon for info:
<Info className="w-5 h-5 text-blue-600 flex-shrink-0" />
```

## Custom Hook (Optional)

For reusable toast logic across components:

```typescript
// hooks/useToast.ts
import { useState, useEffect, useCallback } from 'react';

type ToastType = 'success' | 'error' | 'warning' | 'info';

interface Toast {
  message: string;
  type: ToastType;
}

export function useToast(duration = 4000) {
  const [toast, setToast] = useState<Toast | null>(null);

  useEffect(() => {
    if (toast) {
      const timer = setTimeout(() => setToast(null), duration);
      return () => clearTimeout(timer);
    }
  }, [toast, duration]);

  const showToast = useCallback((message: string, type: ToastType = 'success') => {
    setToast({ message, type });
  }, []);

  const hideToast = useCallback(() => {
    setToast(null);
  }, []);

  return {
    toast,
    showToast,
    hideToast,
    success: (message: string) => showToast(message, 'success'),
    error: (message: string) => showToast(message, 'error'),
    warning: (message: string) => showToast(message, 'warning'),
    info: (message: string) => showToast(message, 'info'),
  };
}

// Usage:
const { toast, success, error, hideToast } = useToast();

success('Record saved!');
error('Failed to save.');
```

## Confirm Dialog Pattern

For replacing `window.confirm()`:

```typescript
const [confirmDialog, setConfirmDialog] = useState<{
  message: string;
  onConfirm: () => void;
  onCancel: () => void;
} | null>(null);

// Usage:
setConfirmDialog({
  message: 'Are you sure you want to delete this item?',
  onConfirm: () => {
    // delete logic
    setConfirmDialog(null);
  },
  onCancel: () => setConfirmDialog(null)
});

// JSX:
{confirmDialog && (
  <div className="fixed inset-0 z-[100] bg-black/50 flex items-center justify-center p-4">
    <div className="bg-white rounded-xl shadow-xl max-w-md w-full p-6">
      <h3 className="text-lg font-semibold mb-2">Confirm</h3>
      <p className="text-slate-600 whitespace-pre-line mb-6">
        {confirmDialog.message}
      </p>
      <div className="flex justify-end gap-3">
        <button
          onClick={() => {
            confirmDialog.onCancel();
            setConfirmDialog(null);
          }}
          className="px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg"
        >
          Cancel
        </button>
        <button
          onClick={() => {
            confirmDialog.onConfirm();
            setConfirmDialog(null);
          }}
          className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg"
        >
          Confirm
        </button>
      </div>
    </div>
  </div>
)}
```

## Styling Notes

- `z-[100]` ensures toast appears above modals (typically z-50)
- `animate-in slide-in-from-top-2` provides entry animation (requires tailwindcss-animate)
- `whitespace-pre-line` supports multi-line messages with `\n`
- `flex-shrink-0` on icon prevents it from shrinking on long messages

## Dependencies

- **Icons**: Lucide React (`lucide-react`) or any icon library
- **Styling**: Tailwind CSS (or adapt classes to your styling solution)
- **Animation** (optional): `tailwindcss-animate` for entry animations

If not using tailwindcss-animate, remove `animate-in slide-in-from-top-2 duration-300` classes.

## Best Practices

1. **Keep messages concise** - Toast should be readable in 4 seconds
2. **Use appropriate types** - success for confirmations, error for failures
3. **Don't stack toasts** - New toast replaces the previous one
4. **Allow dismissal** - Always include close button
5. **Avoid blocking actions** - Toasts shouldn't prevent user interaction

## Pułapki

### 1. Brak ARIA live region
**Problem:** Screen reader nie ogłasza toastów — osoby niewidome nie widzą powiadomień. Accessibility score = 0.
**Rozwiązanie:** Dodaj `role="status" aria-live="polite" aria-atomic="true"` na kontenerze toastów.

### 2. Stały timeout dla wszystkich typów
**Problem:** Error toast z dłuższą wiadomością znika po 4 sekundach — za szybko, żeby przeczytać.
**Rozwiązanie:** Dynamiczny timeout: `duration: type === 'error' ? 6000 : 4000`. Dla długich tekstów dodaj +2000ms.

### 3. Brak limitu ilości toastów
**Problem:** Gdy wiele eventów fires naraz (np. batch import), ekran zasypuje się powiadomieniami.
**Rozwiązanie:** Nowy toast powinien zastępować poprzedni (nie stackować). Alternatywnie: max 3 jednocześnie z kolejką.

### 4. Brak zamykania klawiaturą
**Problem:** Użytkownik bez myszy (keyboard-only) nie może zamknąć toasta — brak obsługi klawisza Escape.
**Rozwiązanie:** Dodaj `onKeyDown={(e) => e.key === 'Escape' && dismiss()}` na toast div z `tabIndex={0}`.

### 5. Animacje bez tailwindcss-animate
**Problem:** Klasy `animate-in slide-in-from-top-2` nie działają bez zainstalowanego pakietu `tailwindcss-animate`.
**Rozwiązanie:** Zainstaluj `npm install -D tailwindcss-animate` lub zastąp custom CSS transition (`opacity`, `transform`).
