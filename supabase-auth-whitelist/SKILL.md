---
name: supabase-auth-whitelist
description: Wzorzec białej listy użytkowników (email whitelist) w Supabase — tabela app_allowed_users, AuthContext z hasAccess/accessDenied, ekran AccessDenied, Web Locks API AbortError fix, custom lock function. Używaj przy ograniczaniu dostępu do aplikacji do listy zatwierdzonych emaili.
---

# Supabase Auth — Email Whitelist Pattern

Skill do ograniczania dostępu do aplikacji na podstawie białej listy emaili. Alternatywa dla systemu ról — prosty wzorzec "jesteś na liście albo nie".

## Triggery

- "whitelist"
- "biała lista"
- "allowed users"
- "dostęp email"
- "AbortError"
- "Web Locks"
- "ograniczenie dostępu"

## When to Use

- Ograniczanie dostępu do aplikacji do listy zatwierdzonych emaili
- Tworzenie prostego gatekeepingu bez skomplikowanego systemu ról
- Naprawianie AbortError z Web Locks API w Supabase Auth
- Konfiguracja custom lock function w kliencie Supabase

---

## 1. Tworzenie tabeli app_allowed_users

```sql
CREATE TABLE public.app_allowed_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Włącz RLS
ALTER TABLE public.app_allowed_users ENABLE ROW LEVEL SECURITY;

-- Każdy może czytać (potrzebne do sprawdzenia dostępu przed/po zalogowaniu)
CREATE POLICY "Anyone can read allowed users" ON public.app_allowed_users
    FOR SELECT USING (true);

-- Dodaj użytkowników do białej listy
INSERT INTO public.app_allowed_users (email) VALUES
  ('admin@example.com'),
  ('user1@example.com'),
  ('user2@example.com');
```

---

## 2. AuthContext z checkAppAccess

Kompletny AuthContext z obsługą białej listy, AbortError i stanami `hasAccess`/`accessDenied`.

```typescript
// contexts/AuthContext.tsx
import React, { createContext, useContext, useEffect, useState, ReactNode } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '../integrations/supabase/client';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  error: string | null;
  isAuthenticated: boolean;
  hasAccess: boolean;      // Użytkownik jest na białej liście
  accessDenied: boolean;   // Użytkownik zalogowany, ale NIE na białej liście
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hasAccess, setHasAccess] = useState(false);
  const [accessDenied, setAccessDenied] = useState(false);

  // Sprawdź czy email użytkownika jest na białej liście
  const checkAppAccess = async (email: string): Promise<boolean> => {
    try {
      const { data, error } = await supabase
        .from('app_allowed_users')
        .select('email')
        .eq('email', email)
        .single();

      if (error) {
        // PGRST116 = brak wierszy (użytkownik nie jest na liście)
        if (error.code !== 'PGRST116') {
          console.error('Unexpected Supabase error:', error);
        }
        return false;
      }

      return !!data;
    } catch (err) {
      console.error('Access check error:', err);
      return false;
    }
  };

  // Aktualizuj stan autentykacji i sprawdź dostęp
  const updateAuthState = async (newSession: Session | null) => {
    setSession(newSession);
    setUser(newSession?.user ?? null);

    if (newSession?.user?.email) {
      const access = await checkAppAccess(newSession.user.email);
      setHasAccess(access);
      setAccessDenied(!access);
    } else {
      setHasAccess(false);
      setAccessDenied(false);
    }

    if (newSession && error) {
      setError(null);
    }
  };

  // Wyczyść cały stan autentykacji
  const clearAuthState = () => {
    setSession(null);
    setUser(null);
    setError(null);
    setHasAccess(false);
    setAccessDenied(false);
  };

  const signOut = async () => {
    try {
      clearAuthState(); // Natychmiastowy feedback
      const { error } = await supabase.auth.signOut();

      if (error) {
        // Stale session — wyloguj lokalnie
        if (error.message.includes('session_not_found') || error.status === 403) {
          return;
        }
        await supabase.auth.signOut({ scope: 'local' });
      }
    } catch (err) {
      console.error('Signout error:', err);
      await supabase.auth.signOut({ scope: 'local' });
    }
  };

  useEffect(() => {
    let mounted = true;

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, newSession) => {
        if (!mounted) return;

        if (event === 'SIGNED_OUT') {
          clearAuthState();
          setLoading(false);
          return;
        }

        if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
          await updateAuthState(newSession);
          setLoading(false);
        }
      }
    );

    // Inicjalizacja sesji z obsługą AbortError
    const initializeAuth = async () => {
      try {
        const { data: { session: initialSession }, error: sessionError } =
          await supabase.auth.getSession();

        if (sessionError) {
          if (sessionError.message.includes('session_not_found')) {
            await supabase.auth.signOut({ scope: 'local' });
            if (mounted) {
              clearAuthState();
              setLoading(false);
            }
            return;
          }
          if (mounted) {
            setError(sessionError.message);
            setLoading(false);
          }
          return;
        }

        if (mounted) {
          await updateAuthState(initialSession);
          setLoading(false);
        }
      } catch (err) {
        // === AbortError Fix ===
        // Web Locks API rzuca AbortError w niektórych przeglądarkach/kontekstach
        if (err instanceof Error && err.name === 'AbortError') {
          console.log('AbortError detected, clearing session...');
          try {
            await supabase.auth.signOut({ scope: 'local' });
          } catch (signOutErr) {
            console.error('Signout error:', signOutErr);
          }
          if (mounted) {
            clearAuthState();
            setLoading(false);
          }
          return;
        }

        if (mounted) {
          setError(err instanceof Error ? err.message : 'Auth error');
          setLoading(false);
        }
      }
    };

    initializeAuth();

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const value: AuthContextType = {
    user,
    session,
    loading,
    error,
    isAuthenticated: !!user && !!session,
    hasAccess,
    accessDenied,
    signOut,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
```

---

## 3. Kluczowe fragmenty AuthContext

### updateAuthState
Aktualizuje sesję, użytkownika i sprawdza dostęp do białej listy. Wywoływany przy `SIGNED_IN`, `TOKEN_REFRESHED` i inicjalizacji.

### clearAuthState
Resetuje wszystkie stany — wywoływany przy `signOut` i `SIGNED_OUT`.

### initializeAuth z AbortError handling
Inicjalizacja sesji przy montowaniu komponentu. Kluczowy fragment — obsługa `AbortError`:

```typescript
} catch (err) {
  if (err instanceof Error && err.name === 'AbortError') {
    console.log('AbortError detected, clearing session...');
    try {
      await supabase.auth.signOut({ scope: 'local' });
    } catch (signOutErr) {
      console.error('Signout error:', signOutErr);
    }
    if (mounted) {
      clearAuthState();
      setLoading(false);
    }
    return;
  }
  // ... obsługa innych błędów
}
```

---

## 4. AbortError Fix — szczegóły

Supabase Auth używa Web Locks API do zarządzania sesjami. Niektóre przeglądarki/konteksty (incognito, WebView, starsze Safari) rzucają `AbortError` gdy lock nie może być pozyskany.

**Symptomy:**
- Pusta strona, ładowanie w nieskończoność
- `AbortError: The operation was aborted` w konsoli
- Sesja "zamrożona" — ani zalogowany, ani wylogowany

**Rozwiązanie w AuthContext** (patrz sekcja 2 — blok `catch` w `initializeAuth`):
1. Złap `AbortError` po nazwie: `err.name === 'AbortError'`
2. Wyloguj lokalnie: `signOut({ scope: 'local' })`
3. Wyczyść stan: `clearAuthState()`

---

## 5. AccessDenied Screen Component

```typescript
// components/auth/AccessDenied.tsx
import { AlertCircle } from 'lucide-react';

interface AccessDeniedProps {
  email: string;
  onLogout: () => void;
}

export function AccessDenied({ email, onLogout }: AccessDeniedProps) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50">
      <div className="bg-white p-8 rounded-xl shadow-lg max-w-md text-center">
        <div className="w-16 h-16 bg-rose-100 rounded-full flex items-center justify-center mx-auto mb-4">
          <AlertCircle className="w-8 h-8 text-rose-600" />
        </div>
        <h2 className="text-xl font-semibold text-slate-800 mb-2">
          Brak dostępu
        </h2>
        <p className="text-slate-600 mb-4">
          Konto <span className="font-medium">{email}</span> nie ma dostępu do tej aplikacji.
        </p>
        <p className="text-sm text-slate-500 mb-6">
          Skontaktuj się z administratorem, aby uzyskać dostęp.
        </p>
        <button
          onClick={onLogout}
          className="w-full px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-lg transition-colors"
        >
          Wyloguj się
        </button>
      </div>
    </div>
  );
}
```

---

## 6. Usage in App

```typescript
// App.tsx
import { useAuth } from '@/contexts/AuthContext';
import { AccessDenied } from '@/components/auth/AccessDenied';
import { LoginPage } from '@/pages/LoginPage';
import { Dashboard } from '@/pages/Dashboard';
import { LoadingSpinner } from '@/components/LoadingSpinner';

function App() {
  const { isAuthenticated, hasAccess, accessDenied, user, signOut, loading } = useAuth();

  // 1. Ładowanie
  if (loading) {
    return <LoadingSpinner />;
  }

  // 2. Zalogowany, ale NIE na białej liście
  if (accessDenied) {
    return <AccessDenied email={user?.email || ''} onLogout={signOut} />;
  }

  // 3. Niezalogowany
  if (!isAuthenticated) {
    return <LoginPage />;
  }

  // 4. Zalogowany I ma dostęp
  return <Dashboard />;
}
```

**Kolejność warunków jest ważna:**
1. `loading` — pokaż spinner
2. `accessDenied` — pokaż ekran braku dostępu (użytkownik jest zalogowany!)
3. `!isAuthenticated` — pokaż login
4. domyślnie — pokaż aplikację

---

## 7. Custom Lock Function (bypass Web Locks)

Jeśli AbortError pojawia się regularnie, możesz wyłączyć Web Locks w kliencie Supabase:

```typescript
// integrations/supabase/client.ts
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Custom lock function — omija Web Locks API
const customLockFunction = async <T>(
  _name: string,
  _acquireTimeout: number,
  fn: () => Promise<T>
): Promise<T> => {
  return fn();
};

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    lock: customLockFunction,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});
```

---

## Pulapki

### 1. Wyłączenie Web Locks usuwa ochronę przed race conditions
**Problem:** Custom lock function (sekcja 7) omija Web Locks API całkowicie, co usuwa wbudowaną ochronę Supabase przed race conditions przy odświeżaniu tokenu.
**Rozwiązanie:** Używaj custom lock function TYLKO jeśli AbortError jest trwały i nie do naprawienia innymi metodami. Preferuj obsługę AbortError w catch (sekcja 4) zamiast wyłączania locków.

### 2. PGRST116 to nie błąd
**Problem:** Gdy użytkownik nie jest na białej liście, Supabase zwraca błąd z kodem `PGRST116` (no rows returned). Logowanie tego jako error zaśmieca konsolę.
**Rozwiązanie:** Sprawdzaj `error.code !== 'PGRST116'` przed logowaniem — ten kod oznacza normalną sytuację "brak na liście".

### 3. Publiczny SELECT na białej liście
**Problem:** Polityka `FOR SELECT USING (true)` na `app_allowed_users` oznacza, że KAŻDY (nawet niezalogowany) może odczytać listę emaili.
**Rozwiązanie:** Jeśli lista emaili jest wrażliwa, zmień politykę na:
```sql
-- Zamiast USING (true), sprawdzaj czy email należy do zalogowanego:
CREATE POLICY "Users check own access" ON public.app_allowed_users
    FOR SELECT USING (email = (SELECT email FROM auth.users WHERE id = auth.uid()));
```
Lub przenieś logikę do SECURITY DEFINER function i nie dawaj bezpośredniego SELECT.

### 4. Stale session po signOut
**Problem:** `session_not_found` error przy wylogowywaniu gdy sesja wygasła po stronie serwera.
**Rozwiązanie:** W `signOut` łap ten błąd i rób fallback na `signOut({ scope: 'local' })`:
```typescript
if (error.message.includes('session_not_found') || error.status === 403) {
  return; // Sesja już nie istnieje — ignoruj
}
await supabase.auth.signOut({ scope: 'local' });
```

### 5. Kolejność warunków w App
**Problem:** Sprawdzanie `!isAuthenticated` przed `accessDenied` powoduje, że użytkownik bez dostępu widzi stronę logowania zamiast ekranu "Brak dostępu".
**Rozwiązanie:** Zawsze sprawdzaj `accessDenied` PRZED `!isAuthenticated` — użytkownik z odmówionym dostępem jest zalogowany, ale nie powinien widzieć aplikacji ani strony logowania.
