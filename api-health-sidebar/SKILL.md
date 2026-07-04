# API Health Sidebar Indicator

## Opis
Zwijany wskaźnik statusu providerów AI w głównym (lewym) sidebarze nawigacyjnym. Pokazuje diodki health per provider z logiką fallback chain. Globalny wzorzec — identyczny w każdym projekcie ekosystemu.

## Triggery
- "dodaj status API do sidebara"
- "API health indicator"
- "diodki statusu providerów"
- "sprawdź status API w sidebarze"

## Architektura

```
src/
  config/api-providers.ts          — konfiguracja providerów (nazwa, envKey, fallback)
  app/api/health/providers/route.ts — endpoint GET: sprawdza każdego providera
  hooks/use-api-health.ts          — hook React: fetch + nasłuchiwanie CustomEvent
  components/sidebar/
    api-health-indicator.tsx        — główny komponent (collapsed/expanded)
    api-health-dot.tsx              — pojedyncza diodka (healthy/degraded/error/inactive)
```

## Umiejscowienie

**ZAWSZE w głównym sidebarze nawigacyjnym (lewy), na samym dole — nad przyciskiem "Zwiń menu".**
NIE w sidebarach kontekstowych (np. Discovery, Kanban detail panel).

Powód: status API jest globalny, nie zależy od kontekstu strony.

## Konfiguracja providerów (`src/config/api-providers.ts`)

```typescript
export interface ApiProviderConfig {
  name: string;
  envKey: string;        // nazwa env var z kluczem API
  required: boolean;     // true = error gdy brak klucza, false = inactive
  healthEndpoint: string;
  healthMethod: "GET" | "POST";
  fallback?: string;     // nazwa providera-backupu
  fallbackFor?: string[];
}

export const API_PROVIDERS: ApiProviderConfig[] = [
  // DOSTOSUJ per projekt — lista providerów używanych w danym narzędziu
];
```

### Przykład: Marketing Hub (3 providerów)
```typescript
{ name: "OpenAI", envKey: "OPENAI_API_KEY", required: true, fallback: "Anthropic" }
{ name: "Anthropic", envKey: "ANTHROPIC_API_KEY", required: true, fallback: "OpenAI" }
{ name: "Perplexity", envKey: "PERPLEXITY_API_KEY", required: false }
```

### Przykład: Content Marketing Hub (3 providerów)
```typescript
{ name: "OpenAI", envKey: "OPENAI_API_KEY", required: true, fallback: "Anthropic" }
{ name: "Anthropic", envKey: "ANTHROPIC_API_KEY", required: true, fallback: "OpenAI" }
{ name: "Google", envKey: "GOOGLE_AI_API_KEY", required: false }
```

## Stany diodek

| Stan | Kolor | Znaczenie |
|------|-------|-----------|
| `healthy` | Zielony | API OK |
| `degraded` | Żółty (pulsuje) | API nie działa, fallback aktywny |
| `error` | Czerwony (pulsuje) | API nie działa, brak fallbacku |
| `inactive` | Szary | Brak klucza, provider opcjonalny |

## Logika fallbacku (endpoint)

```
1. Sprawdź każdego providera równolegle (Promise.all)
2. Jeśli provider ma status "error" ALE jego fallback jest "healthy":
   → zmień status na "degraded" (żółty, nie czerwony)
3. Summary: count(healthy + inactive) / total
```

## Collapsed sidebar

W zwiniętym trybie: ikona Activity z kolorową kropką (zielona/żółta/czerwona).
Klik → odświeża status (nie rozwija szczegółów — brak miejsca).

## Kiedy sprawdzać

1. **Przy mount** (pełny check)
2. **Na żądanie** (klik "Odśwież")
3. **Przy błędzie API** (nasłuchuj `api-provider-error` CustomEvent)

**BEZ cyklicznego pollingu.**

## Integracja z sidebarem

Sidebar musi mieć layout `flex flex-col`:
- Logo (h-16, fixed)
- Nav (flex-1, overflow-y-auto)  
- Footer: ApiHealthIndicator + toggle button (border-t, mt-auto)

```tsx
// W komponencie Sidebar:
import { ApiHealthIndicator } from "@/components/sidebar/api-health-indicator";

// W JSX, na dole aside:
<div className="border-t border-[var(--mh-border)] mt-auto">
  <ApiHealthIndicator collapsed={collapsed} />
  <div className="flex justify-center py-2">
    <Button onClick={() => setCollapsed(!collapsed)} ...>
      {collapsed ? <ChevronRight /> : <ChevronLeft />}
    </Button>
  </div>
</div>
```

## Stylowanie (CSS variables)

Używa zmiennych projektu:
- `--mh-success` (zielony), `--mh-warning` (żółty), `--mh-error` (czerwony)
- `--mh-text-muted`, `--mh-text-secondary`
- `--mh-bg-tertiary` (hover), `--mh-border`

Dostosuj prefix (`--mh-*`, `--cmh-*`, `--pm-*`) do projektu.

## Health check per provider

| Provider | Method | Endpoint | Auth header |
|----------|--------|----------|-------------|
| OpenAI | GET | /v1/models | `Authorization: Bearer {key}` |
| Anthropic | POST | /v1/messages (max_tokens:1) | `x-api-key: {key}` |
| Perplexity | POST | /chat/completions (max_tokens:1) | `Authorization: Bearer {key}` |
| Google | GET | /v1beta/models | `x-goog-api-key: {key}` |

Timeout: 5s per provider. 429 (rate limit) = healthy (API działa).

## Zależności
- Brak dodatkowych pakietów npm
- Ikony: `Activity`, `ChevronDown`, `RefreshCw` z lucide-react (named imports!)
- shadcn/ui: nie wymaga dodatkowych komponentów
