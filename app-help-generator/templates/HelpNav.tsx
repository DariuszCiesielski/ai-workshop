/**
 * Szablon HelpNav — nawigacja sekcji pomocy z kategoriami i ikonami.
 *
 * Dostosuj:
 * - Ikony — zamień SVG na ikony z projektu (lucide-react, heroicons)
 * - Sekcje — dodaj/usuń na bazie analysis.json
 * - Active state — użyj useLocation() / usePathname() z routera projektu
 *
 * Placeholdery:
 * - {{HELP_SECTIONS}} — lista sekcji wygenerowana z analysis.json
 */

import { useLocation, Link } from "react-router-dom"; // dostosuj do routera

interface HelpNavProps {
  onNavigate?: () => void; // callback do zamknięcia mobile drawer
}

// Sekcje pomocy — wygeneruj na bazie analysis.json
const helpSections = [
  {
    category: "Rozpoczęcie pracy",
    items: [
      {
        label: "Konfiguracja",
        href: "/help/configuration",
        icon: "settings", // zamień na komponent ikony
        description: "Klucze API, integracje, zmienne środowiskowe",
      },
    ],
  },
  {
    category: "Administracja",
    items: [
      {
        label: "Zarządzanie użytkownikami",
        href: "/help/users",
        icon: "users",
        description: "Konta, role, uprawnienia",
      },
    ],
  },
  {
    category: "Użytkowanie",
    items: [
      {
        label: "Ścieżki użytkownika",
        href: "/help/flows",
        icon: "route",
        description: "Jak realizować kluczowe funkcje",
      },
      {
        label: "Nawigacja",
        href: "/help/navigation",
        icon: "map",
        description: "Mapa aplikacji — co gdzie znaleźć",
      },
    ],
  },
  {
    category: "Wsparcie",
    items: [
      {
        label: "FAQ",
        href: "/help/faq",
        icon: "help-circle",
        description: "Najczęstsze pytania i odpowiedzi",
      },
    ],
  },
];

export function HelpNav({ onNavigate }: HelpNavProps) {
  const location = useLocation(); // dostosuj do routera

  return (
    <div className="space-y-6">
      {helpSections.map((section) => (
        <div key={section.category}>
          <h3 className="mb-2 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            {section.category}
          </h3>
          <ul className="space-y-1">
            {section.items.map((item) => {
              const isActive = location.pathname === item.href;
              return (
                <li key={item.href}>
                  <Link
                    to={item.href}
                    onClick={onNavigate}
                    className={`
                      flex flex-col gap-0.5 rounded-md px-3 py-2 text-sm transition-colors
                      ${isActive
                        ? "bg-primary/10 text-primary font-medium"
                        : "text-muted-foreground hover:bg-muted hover:text-foreground"
                      }
                    `}
                  >
                    <span>{item.label}</span>
                    <span className="text-xs opacity-70">{item.description}</span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </div>
      ))}
    </div>
  );
}
