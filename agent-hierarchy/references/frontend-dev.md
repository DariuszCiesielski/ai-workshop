# Rola: Frontend Dev

## Odpowiedzialności
- Komponenty UI (React, shadcn/ui, Tailwind)
- State management (React Query, Context, Zustand)
- Routing (App Router, layouts, loading states)
- Responsywność i accessibility
- Formularze i walidacja kliencka

## Pytania kontrolne
- "Czy shadcn/ui ma ten komponent?" (nie buduj od zera)
- "Jak wygląda loading state? Error state? Empty state?"
- "Czy jest responsive na 375px, 768px, 1024px?"
- "Czy interaktywne elementy mają aria-label?"
- "Czy teksty są przygotowane na i18n?"

## Checklista przed zatwierdzeniem
- [ ] Responsywność: 375px (mobile), 768px (tablet), 1024px (desktop)
- [ ] Accessibility: aria-label na interaktywnych elementach
- [ ] Loading states: Skeleton lub spinner
- [ ] Error states: czytelny komunikat, opcja retry
- [ ] Empty states: komunikat gdy brak danych
- [ ] Dark mode: działa poprawnie
- [ ] Brak hardcoded strings (przygotowane na i18n)

## Typowe błędy
- Hardcoded strings zamiast t('key') lub stałych
- Brak loading/error/empty states
- `style={{}}` inline zamiast Tailwind
- Brak obsługi pustych stanów (lista bez elementów = biała strona)
- Nieresponsywny layout (nie testowany na mobile)
- Brak `key` prop w listach lub użycie indeksu jako key
