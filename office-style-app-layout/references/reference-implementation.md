# Reference Implementation — PDFCraft Studio Deep-Dive

Pełna analiza kodu **PDFCraft Studio** (`~/projekty/Access Manager/tools-PDFCraftTool/`) jako wzorca do propagacji. Produkcja: `https://access-manager-tools-pdfcraft.vercel.app/pl/studio`.

Zbudowany 7-8.05.2026 jako rebuild UX nad 97 istniejącymi narzędziami PDF (chuanqisun/PDFCraft fork). **Estymata oryginalna 33-67h, rzeczywista 8-12h** dzięki czystej separacji UI/logic (logic w `src/lib/pdf/processors/<tool>.ts` jako pure functions).

---

## Mapa plików (18 komponentów Studio)

Lokalizacja: `src/components/studio/`

| Plik | Rozmiar | Rola |
|---|---|---|
| `StudioLayout.tsx` | 12.3 KB | Root flex container, providers, dropzone, layout 3-col |
| `StudioMenuBar.tsx` | 16.5 KB | Górny pasek 5 sekcji (Plik/Edycja/Widok/Narzędzia/Pomoc) z Radix dropdownami |
| `StudioHeader.tsx` | 2.4 KB | open/clear/export/theme/avatar (TODO P0 — niedokończony) |
| `StudioFooter.tsx` | 1.6 KB | File metadata footer (rozmiar, strony, format) |
| `FileTabs.tsx` | 6.7 KB | MDI tabs sortable (dnd-kit) + close + dirty indicator |
| `PagesPanel.tsx` | 11.7 KB | Lewy panel — thumbnails stron PDF + DnD reorder + delete |
| `PageThumbnails.tsx` | 5.3 KB | Single thumbnail (memo, lazy render) |
| `PdfViewer.tsx` | 5.9 KB | Main viewer — pdfjs render + page nav + zoom |
| `ViewerToolbar.tsx` | 3.9 KB | Toolbar w viewer (zoom controls, page input, prev/next) |
| `ToolsPanel.tsx` | 11.2 KB | Prawy panel — search + lista kart narzędzi (lucide ikony) |
| `ToolDrawer.tsx` | 24.6 KB | Modal w prawym panelu — routing po currentTool, render `<XxxTool />` |
| `CombineFilesWizard.tsx` | 16.2 KB | Pełnoekranowy wizard merge/combine wielu plików |
| `StudioDropZone.tsx` | 3.3 KB | Drag&drop multi-file na poziomie Layoutu |
| `LoginForm.tsx` | 7.9 KB | Form signin/signup/forgot-password z eye toggle |
| `LoginModal.tsx` | 0.7 KB | Wrapper modal dla LoginForm |
| `SettingsModal.tsx` | 3.3 KB | Modal ustawień (theme, language, account) |
| `RestoreSessionPrompt.tsx` | 2.9 KB | Recovery UX — przywróć sesję z IndexedDB po refresh |
| `UserAvatarMenu.tsx` | 3.3 KB | Avatar dropdown w prawym górnym rogu (TODO niedokończony) |

**Total:** ~138 KB komponentów Studio. Aktywne dla `/[locale]/studio` route. Klasyczne strony `/[locale]/tools/[tool]/` (97 stron SSG) NIE używają Studio.

---

## State hierarchy

**Dwa Zustand stores** — świadoma separacja długoterminowego state od session state:

### 1. `useStudioStore` (`src/lib/stores/studioStore.ts`)

Persistent state aplikacji:

```typescript
interface StudioState {
  files: StudioFile[];              // wszystkie otwarte pliki (z data: Uint8Array | null lazy)
  activeFileId: string | null;      // currently focused tab
  currentTool: StudioToolId | null; // active tool w drawer
  currentPage: number;
  zoomLevel: number;
  showLeftSidebar: boolean;
  showRightPanel: boolean;
  leftSidebarWidth: number;
  rightPanelWidth: number;
  recent: RecentDocument[];         // ostatnie pliki (localStorage)
  isProcessing: boolean;            // global spinner
  // ... + actions: addFile, removeFile, selectTool, setZoom, replaceFileData, etc.
}
```

**Klucz:** `data: Uint8Array | null` jest lazy-populated (po pierwszym viewer load) + `version: number` inkrementowany przy każdej mutacji → trigger re-render w PdfViewer/PagesPanel.

### 2. `useStudioSessionStore` (`src/lib/stores/studioSessionStore.ts`)

Session-only state (nie persistent):

```typescript
interface StudioSessionState {
  activeTabId: string | null;       // aktywna zakładka (zsynchronizowane z activeFileId)
  tabs: Tab[];                       // [{ id, fileId, viewState: { zoom, scrollPos, page } }]
  modalState: { login: boolean; settings: boolean };
  // ... + actions: openTab, closeTab, switchTab, openSettingsModal
}
```

**Separacja:** session store NIE persistowany, gubi się przy refresh. Recovery przez IndexedDB osobno (per-tab viewState).

---

## Flow danych — load → IndexedDB → restore → mutation → re-render

```
1. User drag&drop plik na StudioDropZone
   ↓
2. StudioLayout.onFilesAdded(files)
   → addFile() w studioStore: { id, name, data: null, version: 0 }
   → openTab() w studioSessionStore
   → IndexedDB persist: idb.set(`pdf-${id}`, blob)
   ↓
3. PdfViewer useEffect [currentFileId, fileVersion]:
   → if data === null: load from IndexedDB → setData
   → pdfjs.getDocument(data).promise → render
   ↓
4. User klika narzędzie w ToolsPanel
   → selectTool(toolId)
   → ToolDrawer otwiera się, renderTool(toolId) → <CompressTool initialFile={...} />
   ↓
5. CompressTool wykonuje operację, wywołuje onComplete(blob)
   → studioStore.replaceFileData(fileId, blob)
   → version++ → re-render PdfViewer + PagesPanel
   → IndexedDB upsert: idb.set(`pdf-${id}`, blob)
   ↓
6. User zamyka tab:
   → closeTab() + removeFile()
   → IndexedDB delete: idb.del(`pdf-${id}`)
```

**Krytyczne:** krok 3 i 5 muszą używać **primitives** w useEffect deps (`currentFileId`, `fileVersion`), nie object selektor (pitfall #1).

---

## i18n strategy

- **Top-level namespace `studio`** w `messages/{pl,en,...}.json` (14 języków, primary: pl)
- `useTranslations('studio')` w komponentach
- Klucze: `menubar.file.open`, `menubar.tools.label`, `tools.compress.name`, `tools.compress.description`, `panels.left.title`, `errors.unsupportedFormat` itd.
- Fallback do `en` gdy klucz nie istnieje w innych locale
- Pełna lista kluczy: ~1858 stringów w `messages/pl.json`

**Reguła:** dla każdego nowego narzędzia w Studio — minimum 3 nowe klucze (`name`, `description`, `errorMessage`). Test: `cat messages/pl.json | jq 'paths(scalars) | select(.[0]=="studio")' | wc -l` — wzrost po każdej Wave.

---

## Bundling considerations

### Lazy import dla ciężkich operacji

```typescript
// ❌ ŹLE — Pyodide ~20 MB w main bundle
import { pdfToDocx } from '@/lib/pdf/processors/pdf-to-docx';

// ✅ DOBRZE — lazy import per-request
async function exportDocx() {
  const { pdfToDocx } = await import('@/lib/pdf/processors/pdf-to-docx');
  return pdfToDocx(file);
}
```

PDFCraft tak robi dla wszystkich Pyodide-based narzędzi (`pdf-to-docx`, `pdf-to-pptx`, `pdf-to-excel`). Plus dla `pdfjs-dist` worker, `pdf-lib`.

### `output: 'export'` (static SSG)

PDFCraft używa Next.js `output: 'export'`:
- Brak server runtime — wszystko static + WASM
- Auth: Supabase browser-only client (`src/lib/supabase/client.ts`), NIE `@supabase/ssr`
- Build prerenderuje 1589 stron (`/[locale]/tools/[tool]/` × 14 języków × 97 narzędzi + Studio + landing)
- Implikacja: `AuthContext` musi być **safe optional** dla komponentów dzielonych z klasycznymi tool pages (pitfall #3)

**Decyzja per projekt:** zachowaj `output: 'export'` jeśli możesz (CDN-friendly, szybkość). Zmień na SSR gdy potrzebujesz server actions / dynamic routing — wtedy uważaj na hydration mismatch.

---

## Skróty klawiszowe (pełna lista PDFCraft)

| Skrót | Akcja | Implementacja |
|---|---|---|
| `⌘O / Ctrl+O` | Otwórz pliki | `fileInputRef.current?.click()` |
| `⌘S / Ctrl+S` | Zapisz (download bieżący) | `exportCurrentFile()` |
| `⇧⌘S / Shift+Ctrl+S` | Zapisz jako (prompt nazwy) | `saveAsCurrentFile()` |
| `⌘P / Ctrl+P` | Drukuj | `printBlob(blob)` |
| `⌘+ / Ctrl++` | Powiększ | `setZoom(z + 0.1)` |
| `⌘− / Ctrl+−` | Pomniejsz | `setZoom(z - 0.1)` |
| `⌘0 / Ctrl+0` | Reset zoom 100% | `setZoom(1.0)` |
| `Mouse wheel` | Zoom (bez modyfikatora) | `onWheel` w PdfViewer |
| `Drag&drop` | Multi-file upload | `StudioDropZone` |
| `⌘Z / Ctrl+Z` | Cofnij (replay-based) | `documentActions.undo(tabId)` |
| `⌘⇧Z / Ctrl+Shift+Z` | Ponów | `documentActions.redo(tabId)` |

**Implementacja:** wszystko w `useEffect` w `StudioMenuBar.tsx` + osobne `useEffect` w `PdfViewer.tsx` dla wheel.

---

## Tech stack — pełna lista

Z `package.json` PDFCraft (highlights):

```json
{
  "next": "15.x",
  "react": "19.x",
  "react-dom": "19.x",
  "@radix-ui/react-dropdown-menu": "^2.x",
  "@dnd-kit/core": "^6.x",
  "@dnd-kit/sortable": "^7.x",
  "zustand": "^5.x",
  "next-intl": "^3.x",
  "pdfjs-dist": "^4.8.x",
  "pdf-lib": "^1.17.x",
  "@supabase/supabase-js": "^2.105.x",
  "lucide-react": "^0.x",
  "idb-keyval": "^6.x",
  "tailwindcss": "^4.x"
}
```

**Świadome wykluczenia (z CLAUDE.md PDFCraft):**
- ❌ `shadcn/ui` — PDFCraft używa custom UI components na HSL CSS variables (NIE shadcn semantic classes)
- ❌ `@supabase/ssr` — output:export wyklucza SSR
- ❌ React Server Components — output:export tylko client components

---

## Hook-as-syncer pattern (pitfall #16 deep-dive)

PDFCraft 7.05 wieczór dodał cross-device sync (theme, sidebar widths, recent docs) **bez przepisywania** istniejących source-of-truth:

```typescript
// usePreferences.ts — bridge cloud ↔ existing mechanisms
export function usePreferences() {
  const auth = useAuthOptional(); // pitfall #3
  const supabase = getSupabaseClient();

  // 1. Load from cloud → write to localStorage + Zustand
  useEffect(() => {
    if (!auth?.user) return;
    supabase.from('user_preferences').select('*').single().then(({ data }) => {
      if (data) {
        localStorage.setItem('theme', data.theme);
        useStudioStore.setState({
          showLeftSidebar: data.show_left_sidebar,
          leftSidebarWidth: data.left_sidebar_width,
          // ...
        });
      }
    });
  }, [auth?.user]);

  // 2. Subscribe to Zustand + localStorage → upsert cloud (debounced 400ms)
  useEffect(() => {
    if (!auth?.user) return;
    const unsub = useStudioStore.subscribe(
      (s) => ({ showLeftSidebar: s.showLeftSidebar, /* ... */ }),
      debounce((next) => {
        supabase.from('user_preferences').upsert({ user_id: auth.user.id, ...next });
      }, 400),
    );
    return unsub;
  }, [auth?.user]);
}
```

Mount tylko w `StudioLayout.tsx` — wszystkie inne komponenty (`useResizable`, `ThemeToggle`) pozostają unchanged. Mniejszy ryzyko regresji, łatwiejszy rollback.

---

## Reference Supabase schema

Project: `wvjoeyulugbpovhjboag` (eu-central-1 Frankfurt).

3 tabele + RLS:

```sql
-- user_preferences — theme, sidebar widths, language
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  theme TEXT DEFAULT 'light',
  language TEXT DEFAULT 'pl',
  show_left_sidebar BOOLEAN DEFAULT true,
  left_sidebar_width INTEGER DEFAULT 256,
  show_right_panel BOOLEAN DEFAULT true,
  right_panel_width INTEGER DEFAULT 320,
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own preferences" ON user_preferences
  USING (auth.uid() = user_id);

-- recent_documents — ostatnio otwierane pliki (metadata, NIE content)
CREATE TABLE recent_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  size_bytes BIGINT,
  last_opened TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE recent_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own recent" ON recent_documents
  USING (auth.uid() = user_id);

-- _keepalive — anti-pause table (Supabase auto-pause workaround)
CREATE TABLE _keepalive (id INTEGER PRIMARY KEY, ping TIMESTAMPTZ);

-- Trigger auto-create user_preferences on auth.users insert
CREATE FUNCTION handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_preferences (user_id) VALUES (NEW.id);
  RETURN NEW;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

**Adoption note:** projekt który adoptuje Office-Style i ma auth — kopiuje ten schema + RLS + trigger. Site URL config wymaga PATCH przez Management API (production + preview wildcards + localhost).

---

## Co PDFCraft NIE robi (świadome ograniczenia)

1. **Brak Server Actions** — output:export wyklucza. Wszystkie mutacje przez Supabase client lub IndexedDB.
2. **Brak cloud-side processing** — Pyodide WASM = client-side. Plus: privacy-first (pliki user'a nie opuszczają przeglądarki).
3. **Brak płatności w aplikacji** — strategia lead magnet, nie SaaS. Stripe nie potrzebny.
4. **Brak mobile-first responsive** — desktop primary (Office-style nie skaluje na touch). Mobile = "use desktop" message.
5. **Brak email automation** — Supabase confirm email default, klient powiadamia przez Dariusza zewnętrznie.

**Adoption note:** projekt który adoptuje Office-Style decyduje per item czy zachować to ograniczenie, czy poszerzyć (np. Job Hunter MUSI mieć Server Actions dla LLM API calls — wtedy zmiana na SSR + adaptacja AuthProvider).
