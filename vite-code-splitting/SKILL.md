---
name: vite-code-splitting
description: Konfiguracja ręcznego podziału chunków w Vite — vendor chunks, dynamic imports, analiza bundli (rollup-plugin-visualizer). Używaj przy optymalizacji buildów produkcyjnych w projektach Vite.
---

# Vite Code Splitting Configuration

This skill provides patterns for optimizing Vite builds through manual chunk configuration and dynamic imports.

## When to Use

- Optimizing production bundle sizes
- Separating vendor code from application code
- Implementing lazy loading for routes
- Reducing initial load time

## Manual Chunks Configuration

### Basic Setup

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // React core
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],

          // State management & data fetching
          'query-vendor': ['@tanstack/react-query'],

          // Supabase
          'supabase-vendor': ['@supabase/supabase-js'],

          // UI components (Radix)
          'ui-vendor': [
            '@radix-ui/react-dialog',
            '@radix-ui/react-dropdown-menu',
            '@radix-ui/react-select',
            '@radix-ui/react-slot',
            '@radix-ui/react-tooltip',
            '@radix-ui/react-label',
            '@radix-ui/react-switch',
            '@radix-ui/react-alert-dialog',
            '@radix-ui/react-progress',
          ],

          // Utilities
          'utils-vendor': [
            'clsx',
            'tailwind-merge',
            'class-variance-authority',
            'lucide-react',
          ],

          // i18n
          'i18n-vendor': ['i18next', 'react-i18next'],
        },
      },
    },
    chunkSizeWarningLimit: 1000, // KB
  },
});
```

### Advanced Configuration with Dynamic Function

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          // React ecosystem
          if (id.includes('node_modules/react') ||
              id.includes('node_modules/react-dom') ||
              id.includes('node_modules/react-router')) {
            return 'react-vendor';
          }

          // Radix UI components
          if (id.includes('node_modules/@radix-ui')) {
            return 'radix-vendor';
          }

          // TanStack Query
          if (id.includes('node_modules/@tanstack')) {
            return 'tanstack-vendor';
          }

          // Supabase
          if (id.includes('node_modules/@supabase')) {
            return 'supabase-vendor';
          }

          // ElevenLabs
          if (id.includes('node_modules/@elevenlabs')) {
            return 'elevenlabs-vendor';
          }

          // i18n
          if (id.includes('node_modules/i18next') ||
              id.includes('node_modules/react-i18next')) {
            return 'i18n-vendor';
          }

          // All other node_modules go to common vendor
          if (id.includes('node_modules')) {
            return 'vendor';
          }
        },
      },
    },
  },
});
```

## Dynamic Imports for Route-Based Splitting

### Lazy Loading Pages

```typescript
// App.tsx
import { lazy, Suspense } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { LoadingSpinner } from '@/components/ui/loading-spinner';

// Lazy load pages
const Dashboard = lazy(() => import('@/pages/Dashboard'));
const Documents = lazy(() => import('@/pages/Documents'));
const Chat = lazy(() => import('@/pages/Chat'));
const Settings = lazy(() => import('@/pages/Settings'));

// Auth page is not lazy (needed immediately)
import { Auth } from '@/pages/Auth';

function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<LoadingSpinner />}>
        <Routes>
          <Route path="/auth" element={<Auth />} />
          <Route path="/" element={<Dashboard />} />
          <Route path="/documents" element={<Documents />} />
          <Route path="/chat" element={<Chat />} />
          <Route path="/settings" element={<Settings />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}
```

### Named Chunk Exports

```typescript
// For better debugging, name the chunks
const Dashboard = lazy(() =>
  import(/* webpackChunkName: "dashboard" */ '@/pages/Dashboard')
);

const Documents = lazy(() =>
  import(/* webpackChunkName: "documents" */ '@/pages/Documents')
);

// Vite/Rollup equivalent
const Chat = lazy(() =>
  import('@/pages/Chat').then(module => ({ default: module.Chat }))
);
```

### Loading Component

```typescript
// components/ui/loading-spinner.tsx
export function LoadingSpinner() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="flex flex-col items-center gap-4">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary" />
        <p className="text-muted-foreground">Ładowanie...</p>
      </div>
    </div>
  );
}
```

## Lazy Loading Components

### Dialog with Heavy Dependencies

```typescript
// Lazy load dialog that uses chart library
const StatsDialog = lazy(() => import('@/components/dialogs/StatsDialog'));

function Dashboard() {
  const [showStats, setShowStats] = useState(false);

  return (
    <div>
      <Button onClick={() => setShowStats(true)}>
        Zobacz statystyki
      </Button>

      {showStats && (
        <Suspense fallback={<DialogSkeleton />}>
          <StatsDialog open={showStats} onOpenChange={setShowStats} />
        </Suspense>
      )}
    </div>
  );
}
```

### Conditional Feature Loading

```typescript
// Load feature only when needed
const AdminPanel = lazy(() => import('@/components/admin/AdminPanel'));

function App() {
  const { isAdmin } = useAuth();

  return (
    <div>
      {isAdmin && (
        <Suspense fallback={<AdminPanelSkeleton />}>
          <AdminPanel />
        </Suspense>
      )}
    </div>
  );
}
```

## Bundle Analysis

### Install Visualizer

```bash
npm install -D rollup-plugin-visualizer
```

### Configure Visualizer

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig(({ mode }) => ({
  plugins: [
    react(),
    // Only in build mode
    mode === 'production' && visualizer({
      filename: 'dist/stats.html',
      open: true,
      gzipSize: true,
      brotliSize: true,
    }),
  ].filter(Boolean),
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          // ... chunks config
        },
      },
    },
  },
}));
```

### Analyze Build

```bash
npm run build
# Opens stats.html in browser
```

## Production Optimization Tips

### 1. Preload Critical Chunks

```html
<!-- index.html -->
<head>
  <link rel="modulepreload" href="/assets/react-vendor.js">
  <link rel="modulepreload" href="/assets/index.js">
</head>
```

### 2. Prefetch Non-Critical Routes

```typescript
// Prefetch on hover/focus
const DocumentsLink = () => {
  const prefetch = () => {
    import('@/pages/Documents');
  };

  return (
    <Link
      to="/documents"
      onMouseEnter={prefetch}
      onFocus={prefetch}
    >
      Dokumenty
    </Link>
  );
};
```

### 3. Split Large Libraries

```typescript
// Instead of importing entire library
import { format, parseISO } from 'date-fns';

// Or use tree-shakeable imports
import format from 'date-fns/format';
import parseISO from 'date-fns/parseISO';
```

### 4. Analyze and Remove Unused Dependencies

```bash
# Find unused dependencies
npx depcheck

# Check bundle size impact
npx bundlephobia <package-name>
```

## Complete Configuration Example

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react-swc';
import path from 'path';
import { visualizer } from 'rollup-plugin-visualizer';

export default defineConfig(({ mode }) => ({
  plugins: [
    react(),
    mode === 'production' && visualizer({
      filename: 'dist/stats.html',
      gzipSize: true,
    }),
  ].filter(Boolean),

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },

  server: {
    host: '0.0.0.0',
    port: 8080,
    strictPort: false,
  },

  build: {
    target: 'es2020',
    sourcemap: mode !== 'production',
    minify: 'esbuild',

    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          'query-vendor': ['@tanstack/react-query'],
          'supabase-vendor': ['@supabase/supabase-js'],
          'ui-vendor': [
            '@radix-ui/react-dialog',
            '@radix-ui/react-dropdown-menu',
            '@radix-ui/react-select',
            '@radix-ui/react-slot',
            '@radix-ui/react-tooltip',
          ],
          'utils-vendor': ['clsx', 'tailwind-merge', 'lucide-react'],
          'i18n-vendor': ['i18next', 'react-i18next'],
        },
      },
    },

    chunkSizeWarningLimit: 1000,
  },
}));
```

## Expected Build Output

After configuration, you should see chunks like:

```
dist/
├── index.html
├── assets/
│   ├── index-[hash].js          # App code (~50-100KB)
│   ├── react-vendor-[hash].js   # React (~140KB)
│   ├── query-vendor-[hash].js   # React Query (~40KB)
│   ├── supabase-vendor-[hash].js # Supabase (~60KB)
│   ├── ui-vendor-[hash].js      # Radix UI (~80KB)
│   ├── utils-vendor-[hash].js   # Utilities (~30KB)
│   ├── i18n-vendor-[hash].js    # i18next (~25KB)
│   └── index-[hash].css         # Styles
└── stats.html                   # Bundle visualization
```

## Best Practices

1. **Group related packages** in the same chunk
2. **Keep vendor chunks stable** - they change rarely and can be cached
3. **Lazy load heavy features** like charts, editors, admin panels
4. **Preload critical chunks** that are needed immediately
5. **Prefetch likely-needed chunks** on user interaction
6. **Analyze regularly** - check bundle sizes after adding dependencies
7. **Set reasonable chunk size limits** - aim for <500KB per chunk

## Pułapki

### 1. `manualChunks` z funkcją i zbyt ogólnym matchowaniem

Użycie `id.includes('node_modules/react')` łapie też `react-icons`, `react-pdf`, `react-markdown` i dziesiątki innych paczek, które nie należą do React core. Chunk "react-vendor" rośnie do setek KB.

❌ `if (id.includes('node_modules/react'))` — łapie react-icons (250KB+), react-pdf itd.
✅ `if (id.includes('node_modules/react/') || id.includes('node_modules/react-dom/') || id.includes('node_modules/react-router-dom/'))` — precyzyjne ścieżki z trailing slash

### 2. Catch-all `vendor` chunk pochłania wszystko

Dodanie fallbacka `if (id.includes('node_modules')) return 'vendor'` na końcu `manualChunks()` zbiera WSZYSTKIE zależności w jeden ogromny chunk. Tracisz korzyści z cache'owania — każda nowa paczka invaliduje cały vendor.

❌ Catch-all `return 'vendor'` na końcu funkcji
✅ Zostaw niezmatchowane moduły BEZ return — Rollup sam je optymalnie rozdzieli lub dołączy do chunków które ich używają

### 3. `webpackChunkName` nie działa w Vite

Komentarz `/* webpackChunkName: "dashboard" */` w dynamic import jest ignorowany przez Rollup/Vite. Chunki dostaną generyczne nazwy. Aby nadać nazwy chunkom w Vite, użyj `rollupOptions.output.chunkFileNames`.

❌ `import(/* webpackChunkName: "dashboard" */ '@/pages/Dashboard')` — komentarz ignorowany
✅ W `vite.config.ts`: `output: { chunkFileNames: 'assets/[name]-[hash].js' }` + Vite sam generuje nazwy z pliku źródłowego

### 4. `rollup-plugin-visualizer` jako `dependency` zamiast `devDependency`

Visualizer jest potrzebny TYLKO przy buildzie. Dodany jako `dependency` trafia do produkcyjnego `node_modules` i wydłuża `npm install` na CI.

❌ `npm install rollup-plugin-visualizer`
✅ `npm install -D rollup-plugin-visualizer`

### 5. Transitive dependencies puchną vendor chunks

Wrzucenie `@supabase/supabase-js` do `manualChunks` wciąga TYLKO ten pakiet. Ale Supabase zależy od `@supabase/node-fetch`, `@supabase/gotrue-js`, `@supabase/postgrest-js` itd. — te trafiają do osobnego (lub domyślnego) chunka. Efekt: chunk "supabase-vendor" jest mały, ale pojawia się kilka dodatkowych chunków z zależnościami.

❌ `'supabase-vendor': ['@supabase/supabase-js']` w trybie obiektowym — bez kontroli nad transitive deps
✅ Użyj trybu funkcyjnego: `if (id.includes('node_modules/@supabase/')) return 'supabase-vendor'` — złapie cały ekosystem

### 6. CSS code splitting wyłączone przez `cssCodeSplit: false`

Ustawienie `build.cssCodeSplit: false` (czasem kopiowane z tutoriali) łączy CAŁY CSS w jeden plik. Lazy-loaded strony ładują CSS innych stron. Domyślnie Vite dzieli CSS per chunk — nie wyłączaj tego.

❌ `build: { cssCodeSplit: false }` — jeden duży plik CSS
✅ Nie ustawiaj `cssCodeSplit` wcale (domyślnie `true`) — CSS dzieli się razem z JS chunkami

### 7. `lazy()` bez `Suspense` powoduje crash w renderze

Zapomnienie o `<Suspense>` wokół lazy-loaded komponentu nie daje błędu przy buildzie — aplikacja crashuje dopiero w runtime gdy użytkownik wejdzie na daną stronę. Każdy `lazy()` MUSI mieć `<Suspense>` jako rodzica.

❌ `<Route element={<LazyPage />} />` — bez Suspense, crash w runtime
✅ `<Suspense fallback={<Loading />}><Route element={<LazyPage />} /></Suspense>` — albo globalny Suspense wyżej w drzewie
