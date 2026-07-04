# Adoption Checklist — Office-Style App Layout per projekt

Per-projekt checklista do uzupełniania w trakcie migracji UI do wzorca Office-Style. Agent w sesji danego projektu kopiuje tę checklistę do `.ai/handoffs/office-layout-adoption-<projekt>.md` i odznacza punkty na bieżąco.

---

## Metadata adopcji

- **Projekt:** ___________________________
- **Data startu:** YYYY-MM-DD
- **Agent:** Claude / Codex / inny
- **Wybrany poziom:** [ ] Basic (menubar + 3 kolumny)  [ ] Full MDI (z zakładkami + persistence)
- **Stack target:**
  - [ ] Next.js [ ] Vite [ ] inne (`______`)
  - [ ] React [ ] Vue [ ] Svelte [ ] inne
  - [ ] Tailwind [ ] CSS modules [ ] inne
  - [ ] Radix UI [ ] shadcn (`unified-design-system`) [ ] HeadlessUI [ ] custom
- **Liczba narzędzi do dodania do prawego panelu:** N = ___

---

## Faza 0 — Pre-adoption audit (1-2h)

- [ ] **Stack check** — `cat package.json` zinwentaryzowane (React/Vue, Tailwind, dropdown lib, state lib, i18n lib)
- [ ] **Audit separacji UI/logic** — `grep -rE "useState|useEffect" src/` lub equivalent — wynik: separacja [ ] dobra (logic w pure functions) [ ] zła (splątane z UI, estymata 2x)
- [ ] **Lista istniejących narzędzi/akcji** — `ls src/components/` + `grep -l "<.*Tool" src/`
- [ ] **Wybór poziomu adopcji** — Basic / Full MDI uzasadnione w handoffie
- [ ] **Estymata godzin podana userowi** (Basic 4-8h / Full MDI 10-16h, ×2 jeśli zła separacja)
- [ ] **User zaakceptował estymatę + poziom**

---

## Faza 1 — Layout fundament (1-2h)

- [ ] Utworzony `<Project>Layout.tsx` z root flex (h-screen, flex-col)
- [ ] Kolejność dzieci w środku: MenuBar → (opcjonalnie FileTabs) → main 3-column → Footer
- [ ] Theme provider + AuthProvider (jeśli auth) jako wrapper na top
- [ ] Dropzone do drag&drop multi-file na poziomie Layoutu (jeśli aplikacja konsumuje pliki)
- [ ] Build lokalny przechodzi (`pnpm build` / `npm run build`)

---

## Faza 2 — MenuBar (2-3h)

- [ ] `<Project>MenuBar.tsx` skopiowany z [templates/MenuBar.template.tsx](../templates/MenuBar.template.tsx) jako baseline
- [ ] 5 sekcji (Plik / Edycja / Widok / Narzędzia / Pomoc) — adaptowane do typu aplikacji
- [ ] Akcje Plik — open/save/saveAs/export/print/exit zaimplementowane (lub disabled gdy n/a)
- [ ] Akcje Edycja — undo/redo zbindowane do state (jeśli aplikacja ma undo/redo)
- [ ] Akcje Widok — zoom +/−/0, toggle paneli zbindowane do state
- [ ] Akcje Narzędzia — `TOOL_GROUPS` zawiera wszystkie narzędzia projektu (grouped logicznie)
- [ ] Akcje Pomoc — About / Skróty / Ustawienia / Strona główna
- [ ] **Skróty klawiszowe** — ⌘O, ⌘S, ⌘⇧S, ⌘P, ⌘+, ⌘−, ⌘0 (event.preventDefault!)
- [ ] **Pitfall #2 mitigated** — `useRef` pattern dla keydown handler, deps `[isOpen]` only
- [ ] Spinner / `isProcessing` indicator po prawej stronie menubar gdy operacja w toku
- [ ] Browser test: dropdown otwiera się + submenu rozwija + skróty działają

---

## Faza 3 — Main 3-column (1-3h)

- [ ] Flex row container: lewy (w-64 default) + main (flex-1) + prawy (w-80 default)
- [ ] `useResizable` hook dla obu paneli (z localStorage persistence)
- [ ] Toggle widoczności paneli przez MenuBar Widok
- [ ] Lewy panel — project-specific component (np. PagesPanel / LayersPanel / FileTree)
- [ ] Main viewer — project-specific (np. PdfViewer / ImageEditor / Transcript)
- [ ] Browser test: resize działa, toggle działa, panele renderują się poprawnie

---

## Faza 4 — ToolsPanel + ToolDrawer (2-4h)

- [ ] `<Project>ToolsPanel.tsx` — lista kart narzędzi z ikonami lucide-react + search input
- [ ] `<Project>ToolDrawer.tsx` — modal/overlay w prawym panelu, routing po `currentTool`
- [ ] Search filtruje karty narzędzi
- [ ] **5-fazowa integracja każdego narzędzia DONE** (per #6 pitfall):
  - [ ] (a) ToolId type w store dla każdego narzędzia
  - [ ] (b) ToolDrawer — imports + SUPPORTED + (OUTPUT_MIME jeśli różne formaty) + renderTool switch
  - [ ] (c) ToolsPanel `TOOLS` array z ikonami
  - [ ] (d) MenuBar `TOOL_GROUPS` array (cicha regresja UX prevention!)
  - [ ] (e) Translations dla każdego ToolId (`name`, `description`, error messages)
- [ ] Pre-commit check: `grep -c "tool-id" src/components/.../*.tsx messages/pl.json` = 5+ (każdy plik ref)
- [ ] **Pitfall #5 mitigated** — `OUTPUT_MIME_MAP` lub `PDF_OUTPUT_TOOLS` Set dla MIME compatibility (jeśli aplikacja produkuje różne formaty)
- [ ] Browser test: kliknięcie karty otwiera narzędzie, narzędzie wykonuje akcję, wynik widoczny w viewer / download

---

## Faza 5 (Poziom 2 only) — MDI + persistence (3-6h)

**Pomiń całą fazę jeśli Poziom 1 (Basic).**

- [ ] `<Project>FileTabs.tsx` — sortable tabs (dnd-kit) + close button + dirty indicator
- [ ] `<Project>SessionStore` (Zustand) — `tabs: Tab[]` + `activeTabId`
- [ ] Per-tab viewState — zoom, scroll, currentPage zachowane przy switch między tabs
- [ ] IndexedDB persistence — wrapper `idb-keyval` lub custom, klucz = tabId
- [ ] `RestoreSessionPrompt.tsx` — pokazywany jeśli IndexedDB ma dane ale store pusty
- [ ] `beforeunload` guard — ostrzeżenie przy zamykaniu z dirty tabs
- [ ] Cross-device sync metadata — przez Supabase (jeśli projekt ma user auth, `usePreferences()` hook-as-syncer pattern z pitfall #16)
- [ ] Browser test: 2+ pliki w tabs, switch zachowuje state per tab, refresh przywraca tabs

---

## Faza 6 — Build verify + browser test (1h)

- [ ] `pnpm build` / `npm run build` — exit code 0, brak warnings
- [ ] Lint passes na zmienionych plikach (`pnpm lint <pliki>`)
- [ ] TypeScript strict — brak `any`, brak unused imports
- [ ] **Browser test golden path** (skill `claude-in-chrome` lub manual):
  - [ ] Otwórz plik (drag&drop, ⌘O, menu Plik→Otwórz)
  - [ ] Menubar dropdowny otwierają się + submenu rozwija
  - [ ] Skróty klawiszowe działają (⌘S, ⌘P, ⌘+, ⌘−, ⌘0)
  - [ ] Lewy/prawy panel toggle (Widok menu)
  - [ ] Narzędzie z prawego panelu wykonuje akcję, wynik widoczny
  - [ ] (Poziom 2) — 2+ pliki w tabs, per-tab state zachowany
  - [ ] (Poziom 2) — refresh → RestoreSessionPrompt → kontynuacja
- [ ] **Responsive test** — 1024 / 1280 / 1920 px szerokość, panele nie pękają
- [ ] **Anti-slop audit** (skill `taste-skill`) — spójność hierarchii, spacing, hover states
- [ ] Console bez błędów po pełnym workflow

---

## Faza 7 — Deploy + dokumentacja

- [ ] Commit z conventional commit message (`feat(layout): adopt office-style — fazy 1-N`)
- [ ] **Po deploy:** `vercel inspect <alias-url>` (pitfall #13 — alias może wskazywać stary build)
- [ ] Smoke test production URL (golden path j.w.)
- [ ] **Update CLAUDE.md projektu** — sekcja "Architektura" zawiera odniesienie do Office-Style Layout
- [ ] **Update MEMORY.md projektu** — wpis o migracji + data + poziom
- [ ] **Dopisanie 1-3 lekcji** do [references/pitfalls.md](pitfalls.md) sekcja "Adoption-specific lessons" — co poszło inaczej niż w PDFCraft

---

## Sign-off

- [ ] User zweryfikował i zaakceptował migrację
- [ ] Wszystkie pułapki z [pitfalls.md](pitfalls.md) sprawdzone
- [ ] Adoption-specific lessons dopisane do globalnego skilla

**Data zakończenia:** YYYY-MM-DD
**Czas migracji rzeczywisty:** ___ h (vs estymata ___ h, delta ___ %)
**Następna adopcja:** [projekt] (planowana data)
