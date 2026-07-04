---
name: office-style-app-layout
description: Wzorzec UX aplikacji biurowej (Office/Acrobat): pasek menu z dropdownami, 3-kolumnowy layout, opcjonalnie MDI z zakładkami. Reference: PDFCraft Studio. Triggery: 'interfejs jak w PDFCraft', 'Office-style', 'Acrobat-style', 'menubar z dropdownami', 'MDI', 'rebuild UX biurowy'.
---

# Office-Style App Layout

Wzorzec UX dla **narzędzi typu edytor dokumentów / multi-file workspace** w ekosystemie SaaS Dariusza. Reference: **PDFCraft Studio** (zbudowany 7-8.05.2026, fork chuanqisun/PDFCraft, AGPL-3.0 — pattern, NIE kod, kopiujemy).

## Kiedy używać

**Triggery głosowe:**
- "zrób interfejs jak w PDFCraft" / "interfejs biurowy" / "Office-style" / "Adobe-style" / "Acrobat-style"
- "menubar z dropdownami" / "menu w górnej listwie" / "rozwijane menu w dół"
- "MDI" / "zakładki dokumentów" / "multi-file workspace"
- "rebuild UX na biurowy" / "przebudowa designu jak w narzędziach biurowych"

**Triggery sytuacyjne:**
- Agent dostaje handoff PM z zadaniem migracji UI do "Office-style" w którymkolwiek projekcie ekosystemu
- Refactor istniejącego layoutu narzędzia manipulującego dokumenty/pliki (PDF, CV, grafika, voice→DOCX, etc.)

**Kontekst negatywny — NIE używaj:**
- Dashboard SaaS (analytics, CRM, lead pipeline, monitoring) → sidebar+main pasuje lepiej
- Landing page, marketing site → toolbar nawigacji wystarczy
- Mobile-first app → dropdown menu desktopowe nie skaluje się na touch (chyba że adaptive UI)

## Co to jest

Layout aplikacji desktopowej (Word/Excel/Adobe/Figma) przeniesiony do webu. Charakterystyka:

1. **Górny pasek menu** — 5 sekcji (Plik / Edycja / Widok / Narzędzia / Pomoc) z dropdownami w dół + submenu (ChevronRight) + skróty klawiszowe (⌘O, ⌘S, ⌘P, ⌘+, ⌘−, ⌘0)
2. **Opcjonalnie zakładki MDI** — wiele otwartych dokumentów w zakładkach, każdy z własnym viewState (zoom, scroll, currentPage)
3. **3-kolumnowy main:**
   - **Lewy panel** — nawigacja w obrębie dokumentu (np. thumbnails stron PDF, lista warstw, struktura)
   - **Main viewer** — renderowanie aktualnego dokumentu + toolbar (zoom, nav)
   - **Prawy panel** — narzędzia / akcje / properties
4. **Footer** — metadata aktywnego dokumentu (rozmiar, strony, format)
5. **Opcjonalnie persistence** — IndexedDB (large file storage) + Recovery UX (`RestoreSessionPrompt`) + `beforeunload` guard

## Dwa poziomy adopcji

User (Dariusz) wybiera poziom **per projekt**, case-by-case. Skill ma pasować do obu ścieżek.

### Poziom 1 — Basic (menubar + 3 kolumny)

**Czas migracji:** 4-8h (zależnie od stanu separacji UI/logic w target projekcie)

**Komponenty:**
- `<Project>Layout.tsx` — root flex container (h-screen, flex-col)
- `<Project>MenuBar.tsx` — górny pasek menu (5 sekcji, dropdownami)
- Lewy panel — project-specific (np. `PagesPanel` dla PDF, `LayersPanel` dla grafiki, `FileTree` dla edytora kodu)
- Main viewer — project-specific (np. `PdfViewer`, `ImageEditor`, `VoiceTranscriptViewer`)
- `<Project>ToolsPanel.tsx` — prawy panel narzędzi
- `<Project>Footer.tsx` — metadata footer

**Bez:** FileTabs (MDI), IndexedDB persistence, cross-device sync.

**Dla:** narzędzi single-document, prostych edytorów (Job Hunter CV preview, Bronisław W3 transcript).

### Poziom 2 — Full MDI (wszystko z PDFCraft)

**Czas migracji:** 10-16h

**Dodatkowo do Poziomu 1:**
- `<Project>FileTabs.tsx` — zakładki na otwarte dokumenty
- Per-tab viewState w session store (Zustand) — każda zakładka ma własny zoom, scroll, currentPage
- IndexedDB persistence (`idb-keyval` lub własna wrapper) dla dużych plików
- `RestoreSessionPrompt.tsx` — Recovery UX gdy session padła
- `beforeunload` guard — ostrzeżenie przy zamykaniu z niezapisanymi zmianami
- Cross-device sync metadata przez Supabase (jeśli projekt ma user auth)

**Dla:** narzędzi multi-document gdzie user pracuje równolegle nad kilkoma plikami (PDFCraft, Kreator Grafik, edytory).

## Stack assumptions

Skill zakłada **React + Tailwind + Radix UI** (jak PDFCraft). Dostosowanie dla innych stacków:

| Element | React (default) | Vue 3 | Plain HTML |
|---|---|---|---|
| Dropdown menu | `@radix-ui/react-dropdown-menu` | `radix-vue` lub `@headlessui/vue` | Custom JS + CSS `details/summary` |
| State management | Zustand 5 | Pinia | localStorage + custom events |
| Routing skrótów | `useEffect` + `keydown` | `onMounted` + `keydown` | `addEventListener` |
| i18n | `next-intl` | `vue-i18n` | data-i18n attributes |

Reference komponenty (templates) są w React+Tailwind+Radix — agent w projekcie z innym stackiem porting do swojego (struktura komponentów + role pasków + state hierarchy się nie zmienia, tylko bindings).

## Workflow adopcji (per projekt)

### Faza 0 — Pre-adoption audit (1-2h)

**Cel:** ustalić feasibility i poziom adopcji.

1. **Stack check** — `package.json` projektu. Co jest:
   - React vs Vue vs plain? Tailwind? Radix vs shadcn vs custom CSS?
   - Czy `output: 'export'` (static SSG) czy SSR? (wpływa na auth/session strategy)
2. **Audit separacji UI/logic** — `grep -rE "useState|useEffect" src/` w komponentach narzędzi. Jeśli logika biznesowa jest splątana z UI → estymata 2x. Jeśli pure functions w `src/lib/<domain>/` → standard estymata. **Reguła z PDFCraft 7.05:** ZAWSZE audyt architektury PRZED estymatą rebuildu.
3. **Wybór poziomu** — Basic vs Full MDI. Jeśli niepewne → zacznij Basic, dodaj MDI później.
4. **Lista narzędzi do migracji** — `grep -rE "<.*Tool" src/components/` lub equivalent. Liczba narzędzi = liczba kart do dodania w `ToolsPanel` + dropdown Narzędzia w menubar.

**Output Fazy 0:** estymata godzin + plan plików do utworzenia + identyfikacja gotchy.

### Faza 1 — Layout fundament (1-2h)

1. Utwórz `<Project>Layout.tsx` jako root flex (h-screen, flex-col).
2. W tej kolejności w środku: MenuBar (h-8) → opcjonalnie FileTabs → main 3-column (flex-1) → Footer (h-6).
3. Theme provider + AuthProvider (jeśli auth) jako wrapper na top.
4. Dropzone do drag&drop multi-file na poziomie Layoutu (jeśli narzędzie konsumuje pliki).

### Faza 2 — MenuBar (2-3h)

1. Skopiuj strukturę z `templates/MenuBar.template.tsx` (5 sekcji).
2. Adaptuj `TOOL_GROUPS` do listy narzędzi target projektu.
3. Implementuj akcje Plik (open/save/saveAs/export/print/exit) — adaptuj do typu dokumentu projektu.
4. Implementuj akcje Widok (zoom, toggle sidebars) — zbinduj do state store.
5. Skróty klawiszowe — `useEffect` + `keydown` z preventDefault (⌘O, ⌘S, ⌘⇧S, ⌘P, ⌘+, ⌘−, ⌘0).
6. **Pitfall:** dla event listeners używaj `useRef` pattern dla handlera, deps `[isOpen]` only — inaczej re-fire przy keystrokes (lekcja PDFCraft 7.05).

### Faza 3 — Main 3-column (1-3h)

1. Flex row: lewy panel (w-64 default, resizable) → main viewer (flex-1) → prawy panel (w-80 default, resizable).
2. `useResizable` hook (z localStorage persistence). NIE refactor `useResizable.ts` do cloud direct — bridge przez `usePreferences()` (lekcja PDFCraft 7.05 hook-as-syncer).
3. Toggle widoczności paneli przez MenuBar Widok → bind do state.
4. Lewy panel + prawy panel = project-specific komponenty (np. PagesPanel z thumbnails dla PDF, lub LayersPanel dla grafiki).

### Faza 4 — ToolsPanel + ToolDrawer (2-4h)

1. Prawy panel = lista kart narzędzi z ikonami lucide-react + search.
2. Kliknięcie karty → otwiera ToolDrawer (modal w prawym panelu lub full overlay).
3. ToolDrawer routing: switch po `currentTool` → render `<ToolComponent />`.
4. **5-fazowa integracja każdego nowego narzędzia (lekcja PDFCraft Wave-1+2+3):**
   - (a) Dodaj typ `ToolId` do store
   - (b) ToolDrawer — imports + `SUPPORTED_TOOL_IDS` + `OUTPUT_MIME_MAP` (jeśli różne formaty output) + renderTool switch case
   - (c) ToolsPanel `TOOLS` array z ikoną lucide
   - (d) MenuBar `TOOL_GROUPS` array (inaczej cicha regresja UX — narzędzie istnieje w drawer, nie ma w menu)
   - (e) Translations (`messages/{locale}.json` lub equivalent)
5. **Pitfall MIME compatibility:** jeśli prawy panel ma narzędzia produkujące różne MIME (PDF/DOCX/PNG), routing callback `handleComplete` TYLKO dla compatible MIME (PDF do PDF viewera). Pozostałe użyj wbudowanego DownloadButton (lekcja PDFCraft 7.05).

### Faza 5 (opcjonalna, tylko Poziom 2) — MDI + persistence (3-6h)

1. `FileTabs.tsx` — sortable tabs (dnd-kit) + close button + dirty indicator (kropka).
2. Per-tab viewState — osobny `useStudioSessionStore` (Zustand) z `tabs: Tab[]` + `activeTabId`.
3. IndexedDB persistence — wrapper na `idb-keyval` lub własny. Klucz: tabId.
4. `RestoreSessionPrompt.tsx` — pokazywany jeśli IndexedDB ma tabs ale store jest pusty (np. po refresh).
5. `beforeunload` guard — `window.addEventListener('beforeunload', e => { if (hasDirty) { e.preventDefault(); e.returnValue = ''; } })`.

### Faza 6 — Build verify + browser test

1. `pnpm build` / `npm run build` — typecheck + brak warnings.
2. Lint passes na zmienionych plikach.
3. Browser test (skill `claude-in-chrome` lub manual) — golden path każdej fazy:
   - Otwórz plik (drag&drop, ⌘O, menu Plik→Otwórz)
   - Menubar dropdowny otwierają się + submenu rozwija
   - Skróty klawiszowe działają (⌘S download pliku)
   - Lewy/prawy panel toggle (Widok menu)
   - Narzędzie z prawego panelu wykonuje akcję
   - (Poziom 2) — otwórz drugi plik → nowa zakładka, switch między → state per-tab zachowany
4. Anti-slop audit (skill `taste-skill`) — spójność hierarchii, spacing, hover states.

## Pułapki

Krytyczna sekcja — **16 lessons learned z migracji PDFCraft (7-8.05.2026)**. Pełne w [references/pitfalls.md](references/pitfalls.md).

**TL;DR top 5:**

1. **Zustand selectors w useEffect deps** — NIGDY object selektor (`useStore(s => s.currentFile)`) jako dep. Każda mutacja store = nowa identity = infinite loop. Używaj primitives (`currentFileId`, `fileVersion`), object pobieraj przez `useStore.getState()` w callback.

2. **Modal focus regression** — `useEffect` z `[isOpen, handleKeyDown]` re-fire przy keystroke (handler re-tworzony przez inline `onClose`). Fix: `useRef` pattern dla handler, deps `[isOpen]` only.

3. **AuthProvider context shared component** — komponent dzielony między layouty z/bez auth (np. ThemeToggle w Studio z AuthProvider + klasyczne strony bez) wybucha `useAuth must be used within AuthProvider`. Fix: `useAuthOptional()` zwracający null zamiast throw.

4. **5-fazowa integracja narzędzia w drawer** — pominięcie którejkolwiek = cicha regresja UX. ZAWSZE `grep TOOL_GROUPS MenuBar.tsx` PRZED commit żeby nowe narzędzie było widoczne w menu.

5. **Niejednolitość ToolComponents** — refactor batch script regex testuj na 1-2 plikach PRZED full batch. Jeśli >50% failuje, manual edit szybszy niż debugowanie regex. Estymata "X × N narzędzi" działa tylko gdy wszystkie N mają identyczny pattern.

## Adoption checklist

Per-projekt checklist do uzupełniania w trakcie migracji: [references/adoption-checklist.md](references/adoption-checklist.md).

## Cross-references

- **[unified-design-system](../unified-design-system/)** — jeśli projekt jest na shadcn (PM design system 6 motywów), użyj komponentów z `unified-design-system` DLA paneli/przycisków/dropdownów; **strukturę layoutu (3 kolumny, role pasków, state hierarchy)** bierz z office-style-app-layout. Cross-skill = dwa różne źródła prawdy.
- **[claude-in-chrome](../claude-in-chrome/)** — testowanie UI w przeglądarce po refactor (obowiązkowe per §8 globalnego CLAUDE.md punkt 6).
- **[taste-skill](../taste-skill/)** — anti-slop audit gotowego UI po migracji (premium quality check).
- **[unified-design-system](../unified-design-system/)** sekcja `UserMenu` — UserAvatarMenu w prawym górnym rogu MenuBar (justify-between: menu sections po lewej, UserAvatarMenu po prawej).

## Templates

Gotowe szablony w [templates/](templates/):
- `MenuBar.template.tsx` — kompletny menubar 5 sekcji + dropdownami + skróty
- `Layout.template.tsx` — root flex container z 3 kolumnami

Kopiuj jako baseline, dostosuj nazwy plików/state/translations do target projektu. NIE kopiuj bezmyślnie — czytaj komentarze `// TODO ADAPT:` w templates.

## Reference implementation deep-dive

Pełna analiza kodu PDFCraft jako wzorca: [references/reference-implementation.md](references/reference-implementation.md).

Zawiera mapę plików (18 komponentów Studio), state hierarchy (2 stores: `studioStore` + `studioSessionStore`), flow danych (load → IndexedDB → restore → mutation → version bump → re-render), i18n strategy (top-level `studio` namespace), bundling considerations (lazy import Pyodide-style operations).

## Lessons learned z adopcji (auto-aktualizowane)

Każdy projekt który adoptuje skill **dopisuje 1-3 lekcje na końcu [references/pitfalls.md](references/pitfalls.md)** sekcja "Adoption-specific lessons" — z datą + projektem + co poszło inaczej. Po każdej 3. adopcji rewizja pulpitu czy skill nie potrzebuje update głównej treści.
