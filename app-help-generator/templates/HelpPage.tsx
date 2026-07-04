/**
 * Szablon HelpPage — wrapper pojedynczej strony pomocy z breadcrumbs.
 *
 * Użycie:
 * <HelpPage
 *   title="Konfiguracja"
 *   description="Jak skonfigurować aplikację krok po kroku"
 *   breadcrumb={[{ label: "Pomoc", href: "/help" }, { label: "Konfiguracja" }]}
 * >
 *   <p>Treść strony pomocy...</p>
 * </HelpPage>
 */

import type { ReactNode } from "react";

interface BreadcrumbItem {
  label: string;
  href?: string;
}

interface HelpPageProps {
  title: string;
  description?: string;
  breadcrumb?: BreadcrumbItem[];
  children: ReactNode;
}

export function HelpPage({ title, description, breadcrumb, children }: HelpPageProps) {
  return (
    <article>
      {/* Breadcrumbs */}
      {breadcrumb && breadcrumb.length > 0 && (
        <nav aria-label="Ścieżka nawigacji" className="mb-4">
          <ol className="flex items-center gap-1.5 text-sm text-muted-foreground">
            {breadcrumb.map((item, index) => (
              <li key={index} className="flex items-center gap-1.5">
                {index > 0 && (
                  <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                )}
                {item.href ? (
                  <a href={item.href} className="hover:text-foreground transition-colors">
                    {item.label}
                  </a>
                ) : (
                  <span className="text-foreground font-medium">{item.label}</span>
                )}
              </li>
            ))}
          </ol>
        </nav>
      )}

      {/* Nagłówek strony */}
      <header className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight">{title}</h1>
        {description && (
          <p className="mt-2 text-lg text-muted-foreground">{description}</p>
        )}
      </header>

      {/* Treść */}
      <div className="prose prose-neutral dark:prose-invert max-w-none">
        {children}
      </div>
    </article>
  );
}
