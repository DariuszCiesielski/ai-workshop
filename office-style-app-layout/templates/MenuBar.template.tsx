'use client';

// ──────────────────────────────────────────────────────────────────────────────
// MenuBar template — Office-Style App Layout
// Reference: PDFCraft Studio (~/projekty/Access Manager/tools-PDFCraftTool/
//   src/components/studio/StudioMenuBar.tsx)
//
// TODO ADAPT: zamień <Project>* na nazwę swojego projektu (np. JobHunterMenuBar)
// TODO ADAPT: TOOL_GROUPS — wstaw narzędzia swojego projektu
// TODO ADAPT: akcje Plik/Edycja — dostosuj do typu dokumentu (PDF / DOCX / CV / grafika)
// TODO ADAPT: i18n namespace — zmień 'studio' na swój (np. 'jobhunter')
// ──────────────────────────────────────────────────────────────────────────────

import { useRef, useEffect, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import Link from 'next/link';
import * as DropdownMenu from '@radix-ui/react-dropdown-menu';
import { Check, ChevronRight, Loader2 } from 'lucide-react';

// TODO ADAPT: zaimportuj swój store
// import { useAppStore, type AppToolId } from '@/lib/stores/appStore';

// TODO ADAPT: zaimportuj swoje akcje
// import { downloadBlob, printBlob } from '@/lib/utils/file-actions';

// Type stubs — agent adaptuje do swojego projektu
type Locale = 'pl' | 'en';
type ToolId = string;

interface MenuBarProps {
  locale: Locale;
  onFilesAdded: (files: File[]) => void;
}

// ──────────────────────────────────────────────────────────────────────────────
// TOOL_GROUPS — sekcje submenu w "Narzędzia"
// TODO ADAPT: dopasuj grupy + listę narzędzi do projektu
// Reguła: każde narzędzie z prawego panelu MUSI być tutaj (pitfall #6)
// ──────────────────────────────────────────────────────────────────────────────
const TOOL_GROUPS: Array<{ group: string; tools: ToolId[] }> = [
  // Przykład grup z PDFCraft (zamień na swoje):
  { group: 'pages', tools: ['split', 'merge', 'rotate', 'extract'] },
  { group: 'enhance', tools: ['page-numbers', 'watermark', 'ocr'] },
  { group: 'compress', tools: ['compress'] },
  { group: 'security', tools: ['encrypt', 'sanitize'] },
  { group: 'convert', tools: ['pdf-to-docx', 'word-to-pdf'] },
];

export function AppMenuBar({ locale, onFilesAdded }: MenuBarProps) {
  const t = useTranslations('studio'); // TODO ADAPT: namespace
  const fileInputRef = useRef<HTMLInputElement>(null);

  // TODO ADAPT: zbinduj do swojego store
  // const currentFile = useAppStore(selectCurrentFile);
  // const filesCount = useAppStore((s) => s.files.length);
  // const isProcessing = useAppStore((s) => s.isProcessing);
  // const zoomLevel = useAppStore((s) => s.zoomLevel);
  // const showLeftSidebar = useAppStore((s) => s.showLeftSidebar);
  // const showRightPanel = useAppStore((s) => s.showRightPanel);
  // const toggleLeftSidebar = useAppStore((s) => s.toggleLeftSidebar);
  // const toggleRightPanel = useAppStore((s) => s.toggleRightPanel);
  // const setZoom = useAppStore((s) => s.setZoom);
  // const reset = useAppStore((s) => s.reset);
  // const selectTool = useAppStore((s) => s.selectTool);

  // Stubs dla template (agent zamienia na real store calls)
  const currentFile = null as { id: string; name: string } | null;
  const filesCount = 0;
  const isProcessing = false;
  const zoomLevel = 1.0;
  const showLeftSidebar = true;
  const showRightPanel = true;
  const toggleLeftSidebar = () => {};
  const toggleRightPanel = () => {};
  const setZoom = (_z: number) => {};
  const reset = () => {};
  const selectTool = (_t: ToolId) => {};

  // ─────────────────────────────────────────────────────────────────────────
  // Akcje Plik — TODO ADAPT do typu dokumentu projektu
  // ─────────────────────────────────────────────────────────────────────────

  const exportCurrentFile = useCallback(async () => {
    if (!currentFile) return;
    // TODO ADAPT: pobierz current buffer + download
    // const data = await useAppStore.getState().getCurrentBuffer(currentFile.id);
    // downloadBlob(new Blob([data]), currentFile.name);
  }, [currentFile]);

  const saveAsCurrentFile = useCallback(async () => {
    if (!currentFile) return;
    // TODO ADAPT: prompt nazwy + download
  }, [currentFile]);

  const printCurrentFile = useCallback(async () => {
    if (!currentFile) return;
    // TODO ADAPT: print via printBlob
  }, [currentFile]);

  const handleOpenClick = () => fileInputRef.current?.click();

  const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const fileList = event.target.files;
    if (fileList) {
      onFilesAdded(Array.from(fileList));
      event.target.value = '';
    }
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Skróty klawiszowe — pitfall #2 (useRef pattern dla event listenerów)
  // ─────────────────────────────────────────────────────────────────────────

  // Ref dla aktualnych callbacków (deps stabilne)
  const actionsRef = useRef({ exportCurrentFile, saveAsCurrentFile, printCurrentFile, setZoom });
  actionsRef.current = { exportCurrentFile, saveAsCurrentFile, printCurrentFile, setZoom };

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      const isMod = event.metaKey || event.ctrlKey;
      if (!isMod) return;

      const a = actionsRef.current;
      if (event.key === 'o' || event.key === 'O') {
        event.preventDefault();
        handleOpenClick();
      } else if (event.key === 's' || event.key === 'S') {
        event.preventDefault();
        if (event.shiftKey) a.saveAsCurrentFile();
        else a.exportCurrentFile();
      } else if (event.key === 'p' || event.key === 'P') {
        event.preventDefault();
        a.printCurrentFile();
      } else if (event.key === '=' || event.key === '+') {
        event.preventDefault();
        a.setZoom(zoomLevel + 0.1);
      } else if (event.key === '-' || event.key === '_') {
        event.preventDefault();
        a.setZoom(zoomLevel - 0.1);
      } else if (event.key === '0') {
        event.preventDefault();
        a.setZoom(1.0);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [zoomLevel]); // tylko zoomLevel — reszta przez ref

  // ─────────────────────────────────────────────────────────────────────────
  // Render — pasek h-8 z 5 sekcjami dropdown
  // ─────────────────────────────────────────────────────────────────────────

  return (
    <nav
      className="h-8 border-b border-[hsl(var(--color-border))] bg-[hsl(var(--color-card))] flex items-center px-2 gap-1 text-sm select-none"
      aria-label={t('menubar.aria')}
    >
      {/* Plik */}
      <MenuRoot label={t('menubar.file.label')}>
        <MenuItem onSelect={handleOpenClick} shortcut="⌘O">
          {t('menubar.file.open')}
        </MenuItem>
        <MenuItem onSelect={reset} disabled={filesCount === 0}>
          {t('menubar.file.clearAll')}
        </MenuItem>
        <MenuSeparator />
        <MenuItem onSelect={exportCurrentFile} disabled={!currentFile} shortcut="⌘S">
          {t('menubar.file.save')}
        </MenuItem>
        <MenuItem onSelect={saveAsCurrentFile} disabled={!currentFile} shortcut="⇧⌘S">
          {t('menubar.file.saveAs')}
        </MenuItem>
        {/* TODO ADAPT: submenu Eksportuj dla różnych formatów */}
        <MenuSeparator />
        <MenuItem onSelect={printCurrentFile} disabled={!currentFile} shortcut="⌘P">
          {t('menubar.file.print')}
        </MenuItem>
        <MenuSeparator />
        <MenuItem asChild>
          <Link href={`/${locale}`} className="block w-full">
            {t('menubar.file.exit')}
          </Link>
        </MenuItem>
      </MenuRoot>

      {/* Edycja — TODO ADAPT: undo/redo jeśli aplikacja ma */}
      <MenuRoot label={t('menubar.edit.label')}>
        <MenuItem onSelect={() => {/* TODO: undo */}} shortcut="⌘Z">
          {t('menubar.edit.undo')}
        </MenuItem>
        <MenuItem onSelect={() => {/* TODO: redo */}} shortcut="⌘⇧Z">
          {t('menubar.edit.redo')}
        </MenuItem>
      </MenuRoot>

      {/* Widok */}
      <MenuRoot label={t('menubar.view.label')}>
        <MenuItem onSelect={() => setZoom(zoomLevel + 0.1)} shortcut="⌘+">
          {t('menubar.view.zoomIn')}
        </MenuItem>
        <MenuItem onSelect={() => setZoom(zoomLevel - 0.1)} shortcut="⌘−">
          {t('menubar.view.zoomOut')}
        </MenuItem>
        <MenuSeparator />
        <MenuItem onSelect={() => setZoom(1.0)} shortcut="⌘0">
          {t('menubar.view.actualSize')}
        </MenuItem>
        <MenuSeparator />
        <MenuItem onSelect={toggleLeftSidebar} checked={showLeftSidebar}>
          {t('menubar.view.toggleLeftSidebar')}
        </MenuItem>
        <MenuItem onSelect={toggleRightPanel} checked={showRightPanel}>
          {t('menubar.view.toggleRightPanel')}
        </MenuItem>
      </MenuRoot>

      {/* Narzędzia */}
      <MenuRoot label={t('menubar.tools.label')}>
        {TOOL_GROUPS.map(({ group, tools }) => (
          <SubMenu key={group} label={t(`tools.categories.${group}`)}>
            {tools.map((tool) => (
              <MenuItem
                key={tool}
                onSelect={() => selectTool(tool)}
                disabled={filesCount === 0}
              >
                {t(`tools.${tool}.name`)}
              </MenuItem>
            ))}
          </SubMenu>
        ))}
      </MenuRoot>

      {/* Pomoc */}
      <MenuRoot label={t('menubar.help.label')}>
        <MenuItem disabled>{t('menubar.help.about')}</MenuItem>
        <MenuItem disabled>{t('menubar.help.shortcuts')}</MenuItem>
        <MenuItem onSelect={() => {/* TODO: open settings modal */}}>
          {t('menubar.help.settings')}
        </MenuItem>
        <MenuSeparator />
        <MenuItem asChild>
          <Link href={`/${locale}`} className="block w-full">
            {t('menubar.help.home')}
          </Link>
        </MenuItem>
      </MenuRoot>

      {/* Spinner gdy operacja w toku */}
      {isProcessing && (
        <div
          className="ml-auto flex items-center gap-2 px-2 text-xs text-[hsl(var(--color-muted-foreground))]"
          aria-live="polite"
        >
          <Loader2 className="w-3.5 h-3.5 animate-spin" aria-hidden="true" />
          {t('menubar.processing')}
        </div>
      )}

      {/* TODO ADAPT: UserAvatarMenu w prawym górnym rogu (po prawej od isProcessing) */}
      {/* {!isProcessing && <UserAvatarMenu className="ml-auto" />} */}

      <input
        ref={fileInputRef}
        type="file"
        // TODO ADAPT: accept — dopasuj do typu pliku projektu
        accept="application/pdf,.pdf"
        multiple
        onChange={handleFileChange}
        className="hidden"
        aria-hidden="true"
      />
    </nav>
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper components — Radix Dropdown Menu wrappers
// ──────────────────────────────────────────────────────────────────────────────

const menuItemClasses =
  'flex items-center justify-between gap-6 px-3 py-1.5 text-sm rounded outline-none cursor-pointer ' +
  'data-[highlighted]:bg-[hsl(var(--color-primary))]/10 data-[highlighted]:text-[hsl(var(--color-primary))] ' +
  'data-[disabled]:opacity-50 data-[disabled]:cursor-not-allowed data-[disabled]:hover:bg-transparent';

function MenuRoot({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <DropdownMenu.Root>
      <DropdownMenu.Trigger asChild>
        <button
          className="px-3 h-7 rounded text-sm outline-none focus-visible:ring-2 focus-visible:ring-[hsl(var(--color-ring))] hover:bg-[hsl(var(--color-muted))] data-[state=open]:bg-[hsl(var(--color-muted))]"
          type="button"
        >
          {label}
        </button>
      </DropdownMenu.Trigger>
      <DropdownMenu.Portal>
        <DropdownMenu.Content
          className="min-w-[220px] rounded-md border border-[hsl(var(--color-border))] bg-[hsl(var(--color-card))] shadow-lg p-1 z-50"
          align="start"
          sideOffset={2}
        >
          {children}
        </DropdownMenu.Content>
      </DropdownMenu.Portal>
    </DropdownMenu.Root>
  );
}

interface MenuItemProps {
  onSelect?: () => void;
  shortcut?: string;
  disabled?: boolean;
  checked?: boolean;
  children: React.ReactNode;
  asChild?: boolean;
}

function MenuItem({ onSelect, shortcut, disabled, checked, children, asChild }: MenuItemProps) {
  return (
    <DropdownMenu.Item
      className={menuItemClasses}
      disabled={disabled}
      onSelect={onSelect ? () => onSelect() : undefined}
      asChild={asChild}
    >
      {asChild ? (
        children
      ) : (
        <>
          <span className="flex items-center gap-2">
            {checked !== undefined && (
              <Check
                className={`w-3.5 h-3.5 ${checked ? 'opacity-100' : 'opacity-0'}`}
                aria-hidden="true"
              />
            )}
            {children}
          </span>
          {shortcut && (
            <span className="text-xs text-[hsl(var(--color-muted-foreground))] tabular-nums">
              {shortcut}
            </span>
          )}
        </>
      )}
    </DropdownMenu.Item>
  );
}

function MenuSeparator() {
  return <DropdownMenu.Separator className="h-px my-1 bg-[hsl(var(--color-border))]" />;
}

function SubMenu({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <DropdownMenu.Sub>
      <DropdownMenu.SubTrigger className={menuItemClasses}>
        <span>{label}</span>
        <ChevronRight className="w-3.5 h-3.5 text-[hsl(var(--color-muted-foreground))]" aria-hidden="true" />
      </DropdownMenu.SubTrigger>
      <DropdownMenu.Portal>
        <DropdownMenu.SubContent
          className="min-w-[200px] rounded-md border border-[hsl(var(--color-border))] bg-[hsl(var(--color-card))] shadow-lg p-1 z-50"
          sideOffset={4}
        >
          {children}
        </DropdownMenu.SubContent>
      </DropdownMenu.Portal>
    </DropdownMenu.Sub>
  );
}
