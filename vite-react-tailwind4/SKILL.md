---
name: vite-react-tailwind4
description: Inicjalizacja nowego projektu Vite + React 19 + TypeScript + Tailwind CSS v4. Konfiguracja @theme, dark mode, aliasy ścieżek. Używaj przy tworzeniu nowego projektu React lub migracji do Tailwind v4.
---

# Vite + React + Tailwind CSS v4 Project Setup

This skill guides you through setting up a modern React project with Vite, TypeScript, and Tailwind CSS v4.

## When to Use

- Starting a new React project
- Migrating from Tailwind v3 to v4
- Setting up Vite with proper TypeScript configuration
- Configuring path aliases (@/)

## Project Initialization

### 1. Create Vite Project

```bash
npm create vite@latest project-name -- --template react-ts
cd project-name
npm install
```

### 2. Install Tailwind CSS v4

```bash
npm install tailwindcss @tailwindcss/postcss postcss autoprefixer
```

### 3. Configure PostCSS

Create `postcss.config.js`:

```javascript
export default {
  plugins: {
    '@tailwindcss/postcss': {},
    autoprefixer: {},
  },
};
```

### 4. Configure Tailwind v4 (index.css)

Replace `src/index.css` with:

```css
@import "tailwindcss";

/* ===================================
   THEME CONFIGURATION (Tailwind v4)
   Uses @theme directive instead of tailwind.config.js
   =================================== */

@theme {
  /* Colors - Light mode defaults */
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.145 0 0);

  --color-card: oklch(1 0 0);
  --color-card-foreground: oklch(0.145 0 0);

  --color-popover: oklch(1 0 0);
  --color-popover-foreground: oklch(0.145 0 0);

  --color-primary: oklch(0.205 0 0);
  --color-primary-foreground: oklch(0.985 0 0);

  --color-secondary: oklch(0.97 0 0);
  --color-secondary-foreground: oklch(0.205 0 0);

  --color-muted: oklch(0.97 0 0);
  --color-muted-foreground: oklch(0.556 0 0);

  --color-accent: oklch(0.97 0 0);
  --color-accent-foreground: oklch(0.205 0 0);

  --color-destructive: oklch(0.577 0.245 27.325);
  --color-destructive-foreground: oklch(0.577 0.245 27.325);

  --color-border: oklch(0.922 0 0);
  --color-input: oklch(0.922 0 0);
  --color-ring: oklch(0.708 0 0);

  /* Border radius */
  --radius: 0.625rem;
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);
}

/* ===================================
   DARK MODE
   =================================== */

.dark {
  --color-background: oklch(0.145 0 0);
  --color-foreground: oklch(0.985 0 0);

  --color-card: oklch(0.205 0 0);
  --color-card-foreground: oklch(0.985 0 0);

  --color-popover: oklch(0.205 0 0);
  --color-popover-foreground: oklch(0.985 0 0);

  --color-primary: oklch(0.922 0 0);
  --color-primary-foreground: oklch(0.205 0 0);

  --color-secondary: oklch(0.269 0 0);
  --color-secondary-foreground: oklch(0.985 0 0);

  --color-muted: oklch(0.269 0 0);
  --color-muted-foreground: oklch(0.708 0 0);

  --color-accent: oklch(0.269 0 0);
  --color-accent-foreground: oklch(0.985 0 0);

  --color-destructive: oklch(0.396 0.141 25.723);
  --color-destructive-foreground: oklch(0.637 0.237 25.331);

  --color-border: oklch(0.269 0 0);
  --color-input: oklch(0.269 0 0);
  --color-ring: oklch(0.439 0 0);
}

/* ===================================
   BASE STYLES
   =================================== */

* {
  @apply border-border;
}

body {
  @apply bg-background text-foreground antialiased;
  font-feature-settings: "rlig" 1, "calt" 1;
}
```

### 5. Configure Path Aliases

Update `vite.config.ts`:

```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

Update `tsconfig.app.json`:

```json
{
  "compilerOptions": {
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.app.tsbuildinfo",
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"]
}
```

### 6. Utility Functions

Create `src/lib/utils.ts`:

```typescript
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

Install dependencies:

```bash
npm install clsx tailwind-merge
```

## Dark Mode Toggle

### Theme Toggle Component

```typescript
// components/ThemeToggle.tsx
import { Moon, Sun } from 'lucide-react';
import { useEffect, useState } from 'react';

export function ThemeToggle() {
  const [isDark, setIsDark] = useState(() => {
    if (typeof window !== 'undefined') {
      return document.documentElement.classList.contains('dark');
    }
    return false;
  });

  useEffect(() => {
    const root = document.documentElement;
    if (isDark) {
      root.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      root.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  }, [isDark]);

  // Initialize from localStorage
  useEffect(() => {
    const saved = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    setIsDark(saved === 'dark' || (!saved && prefersDark));
  }, []);

  return (
    <button
      onClick={() => setIsDark(!isDark)}
      className="p-2 rounded-lg hover:bg-accent transition-colors"
      aria-label="Toggle theme"
    >
      {isDark ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
    </button>
  );
}
```

Install icons:

```bash
npm install lucide-react
```

## Project Structure

```
src/
├── components/
│   ├── ui/           # Base UI components
│   └── layout/       # Layout components
├── lib/
│   └── utils.ts      # Utility functions (cn)
├── hooks/            # Custom React hooks
├── contexts/         # React Context providers
├── pages/            # Page components
├── App.tsx
├── main.tsx
└── index.css         # Tailwind v4 config
```

## Key Differences: Tailwind v4 vs v3

| Feature | v3 | v4 |
|---------|----|----|
| Config file | `tailwind.config.js` | `@theme` in CSS |
| Color format | HEX/RGB | OKLCH (recommended) |
| Import | `@tailwind base/components/utilities` | `@import "tailwindcss"` |
| PostCSS plugin | `tailwindcss` | `@tailwindcss/postcss` |

## Common Commands

```bash
npm run dev      # Start dev server (default: localhost:5173)
npm run build    # Production build
npm run preview  # Preview production build
npm run lint     # Run ESLint
```
