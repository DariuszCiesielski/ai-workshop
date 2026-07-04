# Pułapki adopcji Office-Style App Layout

16 lessons learned z migracji **PDFCraft Studio** (7-8.05.2026 — rebuild UX Acrobat-style nad 97 narzędziami).

Każda lekcja: kontekst + symptom + fix + reguła do zapamiętania.

---

## 1. Zustand selectors w useEffect deps = infinite loop

**Kontekst:** PdfViewer miał `useEffect` z deps `[currentFile]` gdzie `currentFile` był pobierany przez selektor `useStudioStore((s) => s.files.find((f) => f.id === activeId))`.

**Symptom:** infinite re-render loop. Każda mutacja store → nowa identity obiektu → useEffect re-fire → load → setPageCount → store update → loop.

**Fix:** deps to **primitives** (`currentFileId`, `fileVersion`), pobieranie obiektu przez `useStudioStore.getState()` w callback.

```typescript
// ❌ ŹLE
const currentFile = useStudioStore((s) => s.files.find((f) => f.id === activeId));
useEffect(() => {
  if (currentFile) loadPdf(currentFile.data);
}, [currentFile]); // object identity change = infinite loop

// ✅ DOBRZE
const currentFileId = useStudioStore((s) => s.activeFileId);
const fileVersion = useStudioStore((s) => s.files.find((f) => f.id === activeId)?.version);
useEffect(() => {
  const file = useStudioStore.getState().files.find((f) => f.id === currentFileId);
  if (file) loadPdf(file.data);
}, [currentFileId, fileVersion]); // primitives only
```

**Reguła:** NIGDY nie używaj selektora obiektu z Zustand jako useEffect dep. Tylko primitives (id, version, length).

---

## 2. Modal focus regression — useEffect re-fire przy keystroke

**Kontekst:** LoginModal z `useEffect` deps `[isOpen, handleKeyDown]` gdzie `handleKeyDown` był re-tworzony przy każdym render (bo deps zawierało `onClose` które było inline function w parent).

**Symptom:** Po wpisaniu litery w polu email focus przeskakiwał na X close button. UX nie do użycia.

**Fix:** `useRef` pattern dla handler, useEffect deps `[isOpen]` only.

```typescript
// ✅ DOBRZE
const handlerRef = useRef<(e: KeyboardEvent) => void>();
handlerRef.current = (e) => {
  if (e.key === 'Escape') onClose();
};

useEffect(() => {
  if (!isOpen) return;
  const handler = (e: KeyboardEvent) => handlerRef.current?.(e);
  window.addEventListener('keydown', handler);
  return () => window.removeEventListener('keydown', handler);
}, [isOpen]); // tylko isOpen, handler stable przez ref
```

**Reguła:** dla event listeners w useEffect używaj useRef żeby uniknąć re-fire przy zmianach handler.

---

## 3. AuthProvider context shared component crash

**Kontekst:** ThemeToggle używany w Studio (z AuthProvider) i klasycznych stronach `/tools/[tool]/` (output:export prerender = brak runtime, brak AuthProvider). Dodanie `useAuth()` w ThemeToggle wywaliło prerender 100% klasycznych narzędzi: `Error: useAuth must be used within AuthProvider`.

**Fix:** nowy hook `useAuthOptional()` zwracający `null` zamiast throw.

```typescript
// useAuth.ts
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

// useAuthOptional.ts — safe wrapper
export function useAuthOptional() {
  return useContext(AuthContext); // może być undefined, no throw
}

// usePreferences.ts (shared component)
const auth = useAuthOptional();
if (!auth) return localStorageOnly; // graceful fallback
```

**Reguła:** dla komponentów dzielonych między różne layouty (auth vs non-auth) używaj **safe optional context pattern** — `useContext()` bez throw. Sprawdź `grep -rn "AuthProvider" src/` PRZED dodaniem useAuth do dzielonego komponentu.

---

## 4. Pyodide / WASM pierwsze uruchomienie 30-60s

**Kontekst:** narzędzia pdf-to-docx/pptx/xlsx używały Pyodide (Python w przeglądarce). Pierwsze użycie ładuje ~10-20 MB Python interpreter.

**Symptom:** user klika "Konwertuj", UI freeze na 30-60s bez feedback, user zamyka tab.

**Fix:** `setProcessing(true)` natychmiast + spinner w menubar + tooltip "Pierwsza konwersja może potrwać dłużej (jednorazowy download narzędzia)". Po cache (drugi raz) — instant.

**Reguła:** każda async operacja >10s wymaga progress indicatora + informacji "pierwszy raz dłużej".

---

## 5. MIME compatibility output↔store routing

**Kontekst:** `studioStore.replaceFileData` zawsze tworzył `new File([blob], name, { type: 'application/pdf' })`. Wywołanie go z DOCX/XLSX/PPTX/ZIP blob'em wstawiało do viewera "PDF" który nie da się sparse'ować → wybuch w PdfViewer.

**Fix:** `PDF_OUTPUT_TOOLS` Set w ToolDrawer — `handleComplete` callback podawany TYLKO narzędziom produkującym PDF (compress/rotate/page-numbers/watermark/encrypt/sign/edit-metadata/ocr). Pozostałe (pdf-to-docx/excel/pptx, extract-images, word/excel/image-to-pdf) używają wbudowanego DownloadButton.

```typescript
const PDF_OUTPUT_TOOLS = new Set<StudioToolId>([
  'compress', 'rotate', 'page-numbers', 'watermark', 'encrypt', 'sign',
  'edit-metadata', 'ocr', /* ... */
]);

function renderTool(toolId: StudioToolId) {
  const handleComplete = PDF_OUTPUT_TOOLS.has(toolId)
    ? (blob: Blob) => studioStore.replaceFileData(activeFileId, blob)
    : undefined; // narzędzie samo handle download

  switch (toolId) { /* ... */ }
}
```

**Reguła:** gdy refactorujesz multi-tool drawer, sprawdź MIME compatibility output↔store PRZED routingiem callback'u.

---

## 6. 5-fazowa integracja każdego nowego narzędzia

**Kontekst:** Wave-1 i Wave-2 dodały narzędzia do drawer + ToolsPanel ale NIE do StudioMenuBar `TOOL_GROUPS` — cicha regresja UX (menu = "co aplikacja umie", user nie widzi nowych funkcji). Wykryte dopiero w Wave-3 przez Dariusza.

**Fix:** każde nowe narzędzie w drawer wymaga **5-fazowej integracji**:

1. **StudioToolId type** w `studioStore.ts` — dodaj literal type
2. **ToolDrawer.tsx** — imports + `SUPPORTED_TOOL_IDS` Set + `PDF_OUTPUT_TOOLS` (jeśli PDF output) + `RESULT_FILENAME_PREFIX` map + `renderTool` switch case
3. **ToolsPanel.tsx** — `STUDIO_TOOLS` array z ikoną lucide-react
4. **StudioMenuBar.tsx** — `TOOL_GROUPS` array (sub-menu w sekcji Narzędzia)
5. **Translations** — `messages/{locale}.json` — `tools.<tool-id>.name`, `.description`, error messages

**Pre-commit check:**
```bash
grep -c "tool-name" src/components/studio/StudioMenuBar.tsx src/components/studio/ToolsPanel.tsx src/components/studio/ToolDrawer.tsx src/lib/stores/studioStore.ts messages/pl.json
# Oczekiwane: 1 1 1 1 1 (każdy plik referuje narzędzie)
```

**Reguła:** sprawdź `grep TOOL_GROUPS StudioMenuBar.tsx` PRZED commit każdego nowego narzędzia.

---

## 7. Refactor batch script regex zawodzi na niejednolitym kodzie

**Kontekst:** Wave-2 refactor — skrypt `refactor-wave2.py` użył regex `(?:/\*\*[\s\S]*?\*/\s*)?className\?:\s*string;\s*}` ale FAILował na 4 z 9 narzędzi bo `}` w pliku to multi-line `\n}` bez whitespace między.

**Symptom:** 5 z 9 narzędzi po batch refactor miało invalid JSX, 30 min debugowania regex.

**Fix:** dla skryptów refactoru regex pattern testuj na 1-2 plikach PRZED full batch run. Jeśli regex zawodzi na >50% — manual edit jest szybszy niż debugowanie regex.

**Reguła:** estymata "X × N narzędzi" działa tylko gdy WSZYSTKIE N mają identyczny pattern. Sprawdź `grep -E "useState.*File|useState.*Blob" N×tools | head -5` przed estymatą i batch script.

---

## 8. Wave-3 DOUBLE-WRAP w batch refactor

**Kontekst:** Wave-3 refactor batch script robił DOUBLE-WRAP gdy oryginalny plik już miał `{!file && (...)}` wokół FileUploader. Idempotent check `if 'initialFile?:' in text` chronił przed re-refactor props, ale NIE przed wrap.

**Symptom:** 9 plików miało invalid JSX `{!file && ({!file && !hideUploader && (<FileUploader />)})}`.

**Fix:**
- (a) `grep '!file' tool.tsx` w 1-2 sample files PRZED batch
- (b) script powinien sprawdzać czy `!hideUploader` jest w pliku PRZED dodawaniem wrap

**Reguła:** każdy idempotent check w batch script musi sprawdzać KAŻDĄ wprowadzaną zmianę, nie tylko jedną.

---

## 9. Multi-file batch tools — keep self-uploader

**Kontekst:** narzędzia używające `useBatchProcessing` hook z `files` array (deskew, font-to-outline) + iframe wizards (edit-pdf, stamps) + multi-input (alternate-merge, grid-combine, linearize, repair) NIE mają `useState<File | null>`.

**Symptom:** próba forsowania `initialFile?: File` prop wywaliła kompilację 7 narzędzi.

**Fix:** keep self-uploader dla tych narzędzi. Drawer wire-up bez propsów: `case 'tool-name': return <XxxTool />;`. Audyt shape PRZED refactor:

```bash
grep -E "useState<File|useBatch|files\[\]" src/components/tools/**/*Tool.tsx
```

**Reguła:** nie forsuj jednolitego pattern dla wszystkich narzędzi. Audyt PRZED batch refactor — niektóre zostają jak są.

---

## 10. UploadedFile shape ≠ File shape

**Kontekst:** `UploadedFile` (z `src/types/pdf.ts`) wymaga `{ id: string, file: File, status: 'pending'|... }`. Niektóre narzędzia (pdf-to-greyscale) używały tej struktury, nie raw `File`.

**Fix:** refactor `setFile({ file: initialFile, id: crypto.randomUUID(), status: 'pending' })`. Plus onComplete użyje `file?.file` (nullable chain) zamiast lokalnego `file`.

**Reguła:** sprawdź **types** komponentu (`grep "useState<.*File" tool.tsx`) PRZED refactor — może to nie raw File.

---

## 11. Crop nested state — file w obiekcie nie standalone

**Kontekst:** Crop ma nested `state.file` w `useState<CropState>({...})` zamiast osobnego `useState<File | null>`. Refactor wymagał init `state` z `file: initialFile ?? null` ZAMIAST `setFile(initialFile)`.

**Fix:** plus useEffect który wywołuje `handleFilesSelected([initialFile])` (bo trzeba załadować PDF + wyrenderować pierwszą stronę przez `renderPage`). onComplete callback wymaga `state.file` zamiast lokalnego `file`.

**Reguła:** nested state z `file` w obiekcie wymaga delegacji ładowania (mount logic) do `handleFilesSelected` przez useEffect mount, nie prostego `setFile`.

---

## 12. Cloudflare 1010 dla Python urllib na Supabase Management API

**Kontekst:** PATCH `/v1/projects/.../database/query` Supabase Management API odpowiadał Cloudflare 1010 dla Python `urllib`.

**Fix:** użyj `curl` z `-H "User-Agent: ..."` zamiast Python urllib. Plus payload przez `-d @plik.json` żeby uniknąć escaping issues w shell.

**Reguła:** dla Supabase Management API zawsze przez curl, nie urllib.

---

## 13. Vercel default alias może być custom alias

**Kontekst:** Vercel default alias `<project-name>.vercel.app` może być **custom alias** ręcznie podpięty kiedyś — auto-promote do nowego production deploy NIE DZIAŁA.

**Symptom:** nowy deploy Ready, alias wskazuje stary deploy. Smoke test alias URL = stary kod.

**Diagnoza:** `vercel inspect <alias-url>` (pokazuje który deployment alias wskazuje).

**Fix:** `vercel alias set <new-direct-url> <alias-domain>`.

**Reguła:** po każdym production deploy sprawdzaj smoke test alias URL, nie tylko direct deploy URL — alias może wskazywać stary build.

---

## 14. Vercel CLI env add wymaga branch arg w nowej wersji

**Kontekst:** `vercel env add NAME preview` w nowej wersji wymaga argumentu `[git-branch]` (positional) — bez tego `branch_not_found undefined`.

**Fix:** `vercel env add NAME preview "feat/branch-name" --value "..." --yes`. Plus dla preview env vars trzeba dodawać per branch (nie ma wildcard "all preview").

**Reguła:** dla preview env vars używaj explicit branch name w trzecim arg pozycyjnym.

---

## 15. Handoff z Supabase project URL = BEZPIECZNE

**Kontekst:** podczas migracji często widoczne były `wvjoeyulugbpovhjboag.supabase.co` w handoffach + anon key.

**Fix:** te dane SĄ public info — `NEXT_PUBLIC_SUPABASE_URL` trafia do bundle Vercel po deploy. Anon key też jest "public by design" — RLS policies chronią dane (`auth.uid() = user_id`).

**Reguła:** w skanach security odróżniaj `NEXT_PUBLIC_*` (OK) od `SERVICE_ROLE`/`PAT`/`DB_PASSWORD` (NIGDY w repo).

---

## 16. Hook-as-syncer pattern — NIE przepisuj source of truth

**Kontekst:** dodanie cross-device sync (ThemeToggle/useResizable/studioStore → Supabase) mogło wymagać przepisania 3 modułów na cloud-aware. Alternatywa: jeden hook `usePreferences()` jako bridge.

**Fix:** hook `usePreferences()` bridge'uje cloud ↔ istniejące mechanizmy (localStorage keys + Zustand state). Mount w 1 miejscu (StudioLayout), zero zmian w `useResizable.ts` i `studioStore.ts`. Side effect: niewielki latency między user toggle sidebar i cloud upsert (debounce 400ms).

**Reguła:** gdy migrujesz local-only state do cloud, **nie przepisuj source of truth — bridge'uj**. Mniejsze ryzyko regresji, łatwiejszy rollback (usuń 1 hook, działa jak było).

---

## Adoption-specific lessons (auto-dopisywane)

Po każdej adopcji skilla w nowym projekcie ekosystemu — dopisz tu 1-3 lekcje specyficzne dla projektu. Format:

```
### [YYYY-MM-DD] [PROJEKT]: [tytuł lekcji]
KONTEKST: ...
SYMPTOM: ...
FIX: ...
REGUŁA: ...
```

(pusto — pierwsze adopcje wpiszą tu lekcje)
