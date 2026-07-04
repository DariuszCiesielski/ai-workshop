---
name: react-flicker-fix
description: Diagnoza i naprawa migania strony (flicker) oraz nieskończonych pętli renderowania w React + Vite. Używaj gdy strona miga, przeładowuje się w kółko, lub AuthContext powoduje re-render loop.
---

# React Flicker/Re-render Fix

## Opis
Skill do diagnozowania i naprawiania problemów z miganiem strony (flicker) i nieskończonymi pętlami renderowania w aplikacjach React + Vite.

## Triggery
- "strona miga"
- "miganie strony"
- "nieskończona pętla renderowania"
- "strona się przeładowuje"
- "flicker"
- "re-render loop"

## Najczęstsze przyczyny i rozwiązania

### 1. Vite HMR - hardcoded clientPort

**Objawy:** Strona przeładowuje się całkowicie zamiast hot reload, szczególnie gdy serwer działa na innym porcie niż skonfigurowany.

**Przyczyna:** W `vite.config.ts` jest ustawiony `hmr.clientPort` na sztywno:
```typescript
server: {
  port: 8080,
  hmr: {
    clientPort: 8080,  // PROBLEM!
  },
}
```

**Rozwiązanie:** Usuń `hmr.clientPort` - Vite automatycznie wykryje właściwy port:
```typescript
server: {
  port: 8080,
  // bez hmr.clientPort
}
```

**Ważne:** Po zmianie vite.config.ts wymagany jest restart serwera!

### 2. AuthContext - wielokrotne aktualizacje stanu

**Objawy:** Strona miga przy ładowaniu, szczególnie na stronach z autoryzacją.

**Przyczyna:** Supabase `onAuthStateChange` może emitować wielokrotne eventy z tym samym tokenem, powodując niepotrzebne re-rendery.

**Rozwiązanie:** Dodaj `useRef` do śledzenia ostatniego tokena:
```typescript
const lastTokenRef = useRef<string | null>(null);

const updateAuthState = (newSession: Session | null) => {
  const newToken = newSession?.access_token || null;

  // Skip update if token hasn't changed
  if (lastTokenRef.current === newToken) {
    return;
  }

  lastTokenRef.current = newToken;
  setSession(newSession);
  setUser(newSession?.user ?? null);
};
```

### 3. useEffect z brakującymi/nieprawidłowymi dependencies

**Objawy:** Komponent renderuje się w pętli.

**Przyczyna:** useEffect bez tablicy zależności lub z obiektem/funkcją w dependencies.

**Rozwiązanie:**
- Dodaj pustą tablicę `[]` jeśli efekt ma się wykonać tylko raz
- Użyj `useCallback`/`useMemo` dla funkcji/obiektów w dependencies
- Sprawdź czy nie aktualizujesz stanu który jest w dependencies

### 4. Stan React aktualizowany przed renderem

**Objawy:** Komponent miga między stanami (np. loader -> content -> loader).

**Przyczyna:** Asynchroniczne aktualizacje stanu wywoływane w złej kolejności.

**Rozwiązanie:**
- Użyj pojedynczego stanu loading zamiast wielu
- Sprawdzaj `loading` przed renderowaniem contentu
- Rozważ `return null` podczas ładowania zamiast renderowania loadera

## Diagnostyka

1. Otwórz konsolę przeglądarki (F12 -> Console)
2. Szukaj logów typu "AuthContext:", "Updating state:", itp.
3. Jeśli widzisz wielokrotne identyczne logi - problem jest w re-renderach
4. Sprawdź zakładkę Network - czy są wielokrotne requesty?

## Pliki do sprawdzenia

1. `vite.config.ts` - konfiguracja HMR
2. `src/contexts/AuthContext.tsx` - autoryzacja
3. Komponenty z useEffect bez dependencies
4. Komponenty używające React Query z refetchInterval

## Komendy diagnostyczne

```bash
# Sprawdź logi Vite
# Szukaj "hmr update" vs "page reload"

# Sprawdź czy HMR działa
# W konsoli przeglądarki: import.meta.hot
```
