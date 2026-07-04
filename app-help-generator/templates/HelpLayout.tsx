/**
 * Szablon HelpLayout — layout sekcji pomocy z nawigacją boczną.
 *
 * Dostosuj do stacku projektu:
 * - Zamień klasy Tailwind na CSS modules jeśli projekt nie używa Tailwind
 * - Dodaj komponenty shadcn/ui (Sheet, ScrollArea) jeśli dostępne
 * - Użyj CSS variables z unified-design-system jeśli projekt ma motywy
 *
 * Placeholdery do zastąpienia:
 * - {{HELP_SECTIONS}} — lista sekcji nawigacji z HelpNav
 * - {{ROUTER_OUTLET}} — React Router <Outlet /> lub {children}
 */

import { useState } from "react";
import { Outlet } from "react-router-dom"; // lub {children} dla Next.js
import { HelpNav } from "./HelpNav";
import { HelpSearch } from "./HelpSearch";

export function HelpLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  return (
    <div className="min-h-screen bg-background">
      {/* Header pomocy */}
      <header className="sticky top-0 z-10 border-b bg-background/95 backdrop-blur">
        <div className="flex h-14 items-center gap-4 px-4 lg:px-6">
          {/* Mobile toggle */}
          <button
            className="lg:hidden"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            aria-label="Otwórz nawigację pomocy"
          >
            {/* Ikona menu — zastąp ikoną z projektu */}
            <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>

          <h1 className="text-lg font-semibold">Pomoc</h1>

          {/* Wyszukiwarka */}
          <div className="ml-auto w-full max-w-sm">
            <HelpSearch query={searchQuery} onQueryChange={setSearchQuery} />
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar — desktop */}
        <aside className="hidden w-64 shrink-0 border-r lg:block">
          <nav className="sticky top-14 h-[calc(100vh-3.5rem)] overflow-y-auto p-4">
            <HelpNav />
          </nav>
        </aside>

        {/* Sidebar — mobile drawer */}
        {sidebarOpen && (
          <>
            <div
              className="fixed inset-0 z-20 bg-black/50 lg:hidden"
              onClick={() => setSidebarOpen(false)}
            />
            <aside className="fixed inset-y-0 left-0 z-30 w-64 border-r bg-background lg:hidden">
              <div className="flex h-14 items-center border-b px-4">
                <h2 className="font-semibold">Nawigacja</h2>
                <button
                  className="ml-auto"
                  onClick={() => setSidebarOpen(false)}
                  aria-label="Zamknij nawigację"
                >
                  <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <nav className="overflow-y-auto p-4">
                <HelpNav onNavigate={() => setSidebarOpen(false)} />
              </nav>
            </aside>
          </>
        )}

        {/* Treść */}
        <main className="flex-1 px-4 py-6 lg:px-8 lg:py-8">
          <div className="mx-auto max-w-3xl">
            <Outlet /> {/* Zamień na {children} dla Next.js */}
          </div>
        </main>
      </div>
    </div>
  );
}
