'use client';

// ──────────────────────────────────────────────────────────────────────────────
// Layout template — Office-Style App Layout
// Reference: PDFCraft Studio (~/projekty/Access Manager/tools-PDFCraftTool/
//   src/components/studio/StudioLayout.tsx)
//
// Struktura:
// ┌─────────────────────────────────────────────────────────────────┐
// │ MenuBar (h-8)                                                   │
// ├─────────────────────────────────────────────────────────────────┤
// │ FileTabs (h-9) — opcjonalnie, tylko Poziom 2 MDI                │
// ├──────────────┬──────────────────────────────────┬───────────────┤
// │ LeftPanel    │ MainViewer + ViewerToolbar       │ RightPanel    │
// │ (w-64,       │ (flex-1)                         │ (w-80,        │
// │  resizable)  │                                  │  resizable)   │
// │              │                                  │               │
// ├──────────────┴──────────────────────────────────┴───────────────┤
// │ Footer (h-6) — metadata                                         │
// └─────────────────────────────────────────────────────────────────┘
//
// TODO ADAPT: zamień <Project>* na nazwę projektu
// TODO ADAPT: LeftPanel + MainViewer + RightPanel — project-specific komponenty
// TODO ADAPT: FileTabs — usuń jeśli Poziom 1 (Basic)
// ──────────────────────────────────────────────────────────────────────────────

import { useState, useCallback } from 'react';
import { useTranslations } from 'next-intl';

// TODO ADAPT: zaimportuj swoje komponenty
import { AppMenuBar } from './MenuBar';
// import { AppFileTabs } from './FileTabs';                    // tylko Poziom 2
// import { AppLeftPanel } from './LeftPanel';                  // project-specific (np. PagesPanel)
// import { AppMainViewer } from './MainViewer';                // project-specific (np. PdfViewer)
// import { AppViewerToolbar } from './ViewerToolbar';
// import { AppRightPanel } from './RightPanel';                // project-specific
// import { AppToolDrawer } from './ToolDrawer';
// import { AppFooter } from './Footer';
// import { AppDropZone } from './DropZone';
// import { LoginModal } from './LoginModal';
// import { RestoreSessionPrompt } from './RestoreSessionPrompt'; // tylko Poziom 2
// import { usePreferences } from '@/lib/hooks/usePreferences';   // hook-as-syncer (pitfall #16)
// import { useResizable } from '@/lib/hooks/useResizable';
// import { useAppStore } from '@/lib/stores/appStore';
// import { useAppSessionStore } from '@/lib/stores/appSessionStore'; // tylko Poziom 2

// Type stub
type Locale = 'pl' | 'en';

interface LayoutProps {
  locale: Locale;
  children?: React.ReactNode;
}

export function AppLayout({ locale }: LayoutProps) {
  const t = useTranslations('studio'); // TODO ADAPT: namespace

  // ─────────────────────────────────────────────────────────────────────────
  // State — adaptuj do swojego store
  // ─────────────────────────────────────────────────────────────────────────

  // TODO ADAPT: real store calls
  // const showLeftSidebar = useAppStore((s) => s.showLeftSidebar);
  // const showRightPanel = useAppStore((s) => s.showRightPanel);
  // const filesCount = useAppStore((s) => s.files.length);
  // const currentTool = useAppStore((s) => s.currentTool);

  const showLeftSidebar = true;
  const showRightPanel = true;
  const filesCount = 0;
  const currentTool = null;

  // Hook-as-syncer dla cross-device sync (pitfall #16) — opcjonalnie
  // usePreferences();

  // Resizable hooks dla paneli (z localStorage persistence)
  // const { width: leftWidth, dragHandle: leftDragHandle } = useResizable({
  //   storageKey: 'app:leftPanelWidth',
  //   defaultWidth: 256,
  //   minWidth: 180,
  //   maxWidth: 480,
  // });
  // const { width: rightWidth, dragHandle: rightDragHandle } = useResizable({
  //   storageKey: 'app:rightPanelWidth',
  //   defaultWidth: 320,
  //   minWidth: 240,
  //   maxWidth: 560,
  // });

  const leftWidth = 256;
  const rightWidth = 320;

  // ─────────────────────────────────────────────────────────────────────────
  // File upload handler — multi-file drag&drop + manual open
  // ─────────────────────────────────────────────────────────────────────────

  const handleFilesAdded = useCallback((files: File[]) => {
    if (files.length === 0) return;
    // TODO ADAPT: add files do store + persist IndexedDB
    // for (const file of files) {
    //   useAppStore.getState().addFile(file);
    // }
  }, []);

  // ─────────────────────────────────────────────────────────────────────────
  // Render
  // ─────────────────────────────────────────────────────────────────────────

  return (
    <div className="h-screen flex flex-col bg-[hsl(var(--color-background))] text-[hsl(var(--color-foreground))]">

      {/* MenuBar (h-8) */}
      <AppMenuBar locale={locale} onFilesAdded={handleFilesAdded} />

      {/* FileTabs (h-9) — tylko Poziom 2 MDI */}
      {/* <AppFileTabs /> */}

      {/* Main 3-column (flex-1) */}
      <div className="flex-1 flex overflow-hidden">

        {/* Left Panel — project-specific (np. PagesPanel z thumbnails) */}
        {showLeftSidebar && (
          <aside
            className="border-r border-[hsl(var(--color-border))] bg-[hsl(var(--color-card))] flex-shrink-0 relative overflow-hidden"
            style={{ width: leftWidth }}
            aria-label={t('panels.left.aria')}
          >
            {/* TODO ADAPT: project-specific LeftPanel */}
            {/* <AppLeftPanel /> */}
            <div className="p-4 text-sm text-[hsl(var(--color-muted-foreground))]">
              Left Panel — TODO: replace with project-specific component<br />
              (np. PagesPanel for PDF, LayersPanel for graphics, FileTree for IDE)
            </div>

            {/* Drag handle */}
            {/* {leftDragHandle} */}
          </aside>
        )}

        {/* Main Viewer + ViewerToolbar */}
        <main className="flex-1 flex flex-col overflow-hidden bg-[hsl(var(--color-background))]">
          {/* ViewerToolbar */}
          {/* <AppViewerToolbar /> */}

          {/* Viewer (scrollable area) */}
          <div className="flex-1 overflow-auto relative">
            {filesCount === 0 ? (
              <EmptyState locale={locale} onFilesAdded={handleFilesAdded} />
            ) : (
              <div className="p-4 text-sm text-[hsl(var(--color-muted-foreground))]">
                Main Viewer — TODO: replace with project-specific component<br />
                (np. PdfViewer, ImageEditor, VoiceTranscriptViewer)
              </div>
              // <AppMainViewer />
            )}
          </div>
        </main>

        {/* Right Panel — project-specific (ToolsPanel/ToolDrawer) */}
        {showRightPanel && (
          <aside
            className="border-l border-[hsl(var(--color-border))] bg-[hsl(var(--color-card))] flex-shrink-0 relative overflow-hidden"
            style={{ width: rightWidth }}
            aria-label={t('panels.right.aria')}
          >
            {/* TODO ADAPT: ToolsPanel (lista kart) i ToolDrawer (active tool) */}
            {/* {currentTool ? <AppToolDrawer /> : <AppRightPanel />} */}
            <div className="p-4 text-sm text-[hsl(var(--color-muted-foreground))]">
              Right Panel — TODO: replace with project-specific component<br />
              (ToolsPanel + ToolDrawer)
            </div>

            {/* Drag handle */}
            {/* {rightDragHandle} */}
          </aside>
        )}

      </div>

      {/* Footer (h-6) */}
      {/* <AppFooter /> */}
      <footer className="h-6 border-t border-[hsl(var(--color-border))] bg-[hsl(var(--color-card))] px-3 flex items-center text-xs text-[hsl(var(--color-muted-foreground))]">
        <span>TODO: AppFooter — file metadata (size, pages, format)</span>
      </footer>

      {/* DropZone (overlay, opacity:0 when inactive) */}
      {/* <AppDropZone onFilesAdded={handleFilesAdded} /> */}

      {/* Modals */}
      {/* <LoginModal /> */}
      {/* <RestoreSessionPrompt /> — tylko Poziom 2 MDI */}

    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// EmptyState — gdy brak otwartych plików
// ──────────────────────────────────────────────────────────────────────────────

function EmptyState({
  locale,
  onFilesAdded,
}: {
  locale: Locale;
  onFilesAdded: (files: File[]) => void;
}) {
  const t = useTranslations('studio');
  const inputRef = useState<HTMLInputElement | null>(null);

  return (
    <div className="h-full flex flex-col items-center justify-center gap-6 p-8 text-center">
      <div className="text-6xl text-[hsl(var(--color-muted-foreground))]">📄</div>
      <div>
        <h2 className="text-xl font-semibold mb-2">{t('emptyState.title')}</h2>
        <p className="text-sm text-[hsl(var(--color-muted-foreground))] max-w-md">
          {t('emptyState.description')}
        </p>
      </div>
      <button
        type="button"
        onClick={() => {
          const input = document.createElement('input');
          input.type = 'file';
          input.accept = 'application/pdf,.pdf'; // TODO ADAPT
          input.multiple = true;
          input.onchange = (e) => {
            const files = (e.target as HTMLInputElement).files;
            if (files) onFilesAdded(Array.from(files));
          };
          input.click();
        }}
        className="px-4 py-2 rounded-md bg-[hsl(var(--color-primary))] text-[hsl(var(--color-primary-foreground))] text-sm font-medium hover:bg-[hsl(var(--color-primary))]/90"
      >
        {t('emptyState.openButton')}
      </button>
      <p className="text-xs text-[hsl(var(--color-muted-foreground))]">
        {t('emptyState.orDragDrop')}
      </p>
    </div>
  );
}
