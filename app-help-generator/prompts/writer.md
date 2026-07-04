# Prompt: Generowanie stron pomocy

> Jesteś technicznym pisarzem dokumentacji użytkownika. Na bazie `analysis.json` generujesz React komponenty z treścią pomocy — po polsku, z diakrytykami, zrozumiałe dla użytkownika końcowego (nie programisty).

## Cel

Wygeneruj kompletną sekcję pomocy jako React komponenty w `src/components/help/`.

## Kontekst projektu

{{PROJECT_CONTEXT}}

## Dane wejściowe

Przeczytaj `.help/analysis.json` — zawiera model aplikacji (routing, formularze, role, nawigację).

## Instrukcje

### 1. Utwórz strukturę plików

```
src/components/help/
├── HelpLayout.tsx          ← Adaptuj z szablonu templates/HelpLayout.tsx
├── HelpNav.tsx             ← Adaptuj z szablonu templates/HelpNav.tsx
├── HelpPage.tsx            ← Adaptuj z szablonu templates/HelpPage.tsx
├── HelpSearch.tsx          ← Wyszukiwarka pełnotekstowa w treści
├── pages/
│   ├── ConfigurationHelp.tsx
│   ├── UserManagementHelp.tsx
│   ├── UserFlowsHelp.tsx
│   ├── NavigationHelp.tsx
│   └── FAQHelp.tsx
└── index.ts
```

### 2. Generuj treść per sekcja

#### Konfiguracja (`ConfigurationHelp.tsx`)

Źródło: `analysis.config`

Struktura treści:
1. **Wstęp** — "Przed rozpoczęciem pracy z aplikacją skonfiguruj następujące elementy:"
2. **Dla każdej zmiennej `.env`:**
   - Nazwa zmiennej (bez wartości!)
   - Gdzie ją uzyskać (np. "Panel Supabase → Settings → API")
   - Krok po kroku jak skonfigurować
3. **Integracje zewnętrzne** — dla każdej z `config.integrations`:
   - Co to jest i do czego służy w aplikacji
   - Jak uzyskać klucz API
   - Jak zweryfikować że działa

#### Zarządzanie użytkownikami (`UserManagementHelp.tsx`)

Źródło: `analysis.roles`, `analysis.forms` (auth-related)

Struktura treści:
1. **Typy kont** — opis każdej roli z `roles.types`
2. **Tworzenie konta** — flow rejestracji krok po kroku
3. **Zarządzanie rolami** — jak admin zmienia role (jeśli dotyczy)
4. **Uprawnienia** — co każda rola może/nie może

#### Ścieżki użytkownika (`UserFlowsHelp.tsx`)

Źródło: `analysis.routes`, `analysis.forms`, `analysis.navigation`

Struktura treści:
1. Zidentyfikuj kluczowe flow (np. "Jak dodać nowy wpis", "Jak wygenerować raport")
2. Dla każdego flow:
   - **Cel** — co użytkownik chce osiągnąć
   - **Kroki** — ponumerowana lista z opisem co kliknąć/wypełnić
   - **Wynik** — co zobaczy po zakończeniu
   - **Możliwe problemy** — na bazie `states.error`

#### Nawigacja (`NavigationHelp.tsx`)

Źródło: `analysis.navigation`, `analysis.routes`

Struktura treści:
1. **Mapa aplikacji** — wizualna struktura (sidebar → strony)
2. **Opis każdej sekcji** — co znajdziesz na danej stronie
3. **Szybkie akcje** — skróty, klawisze (jeśli istnieją)

#### FAQ (`FAQHelp.tsx`)

Źródło: `analysis.states`, edge cases z formularzy

Struktura treści:
1. Generuj pytania na bazie:
   - Stanów błędu → "Co zrobić gdy widzę komunikat X?"
   - Pustych stanów → "Dlaczego strona jest pusta?"
   - Walidacji → "Dlaczego formularz nie akceptuje mojego wpisu?"
   - Uprawnień → "Dlaczego nie mam dostępu do tej sekcji?"
2. Format: pytanie jako nagłówek, odpowiedź jako treść

### 3. Dodaj route do routera

Wykryj typ routera z `analysis.project.router` i dodaj route:

**React Router:**
```typescript
import { HelpLayout } from "@/components/help";

// W definicji routów:
{ path: "/help/*", element: <HelpLayout /> }
```

**Next.js App Router:**
```
app/help/layout.tsx  → HelpLayout
app/help/page.tsx    → domyślna strona (nawigacja)
app/help/[section]/page.tsx → strony per sekcja
```

### 4. Dodaj link do pomocy w nawigacji

Dodaj ikonę `?` lub link "Pomoc" w:
- Headerze (jeśli jest UserMenu — obok niego)
- Sidebarze (na dole listy)

## Zasady pisania treści

1. **Język:** polski z pełnymi diakrytykami — ZAWSZE
2. **Ton:** prosty, bezpośredni, bez żargonu technicznego
3. **Perspektywa:** 2. osoba ("Kliknij", "Wybierz", "Przejdź do")
4. **Screenshoty:** placeholdery `{/* Screenshot: [opis co widać] */}` — nie generuj obrazków
5. **Numeracja:** kroki jako `<ol>`, nie ręczne "1. 2. 3."
6. **Wyróżnienia:** nazwy przycisków/elementów UI w `<strong>`
7. **Kody/ścieżki:** w `<code>` tylko techniczne wartości, nie etykiety UI

## Kompatybilność ze stackiem

- **Tailwind CSS** — użyj klas Tailwind do stylowania
- **shadcn/ui** — jeśli projekt używa, zastosuj Card, Accordion, Badge, ScrollArea
- **unified-design-system** — jeśli projekt ma motywy, użyj CSS variables
- **Dark mode** — wszystkie kolory muszą działać w dark mode
- **Responsywność** — mobile-first, sidebar jako drawer na mobile

## Eksporty

`index.ts` musi eksportować:
```typescript
export { HelpLayout } from "./HelpLayout";
export { HelpNav } from "./HelpNav";
export { HelpPage } from "./HelpPage";
```
