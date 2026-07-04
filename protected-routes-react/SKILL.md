---
name: protected-routes-react
description: Chronione ścieżki z AuthContext i Supabase Auth — komponent ProtectedRoute, stany ładowania, fallback. Używaj przy konfiguracji flow autentykacji z React Router.
---

# Protected Routes with React Router + Supabase Auth

This skill provides patterns for implementing protected routes with proper authentication context.

## When to Use

- Setting up authentication-protected pages
- Creating AuthContext with Supabase Auth
- Implementing loading states during auth initialization
- Handling redirect to login page

## Prerequisites

```bash
npm install react-router-dom @supabase/supabase-js
```

## Implementation

### 1. AuthContext

```typescript
// contexts/AuthContext.tsx
import {
  createContext,
  useContext,
  useEffect,
  useState,
  ReactNode,
} from 'react';
import { supabase } from '@/integrations/supabase/client';
import type { User, Session, AuthChangeEvent } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  error: string | null;
  isAuthenticated: boolean;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let mounted = true;

    // Setup auth state listener FIRST
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (event: AuthChangeEvent, newSession: Session | null) => {
        if (!mounted) return;

        if (event === 'SIGNED_OUT') {
          setUser(null);
          setSession(null);
          setLoading(false);
          return;
        }

        if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
          setSession(newSession);
          setUser(newSession?.user ?? null);
          setError(null);
          setLoading(false);
          return;
        }
      }
    );

    // Get initial session
    const initializeAuth = async () => {
      try {
        const { data: { session: initialSession }, error: sessionError } =
          await supabase.auth.getSession();

        if (mounted) {
          if (sessionError) {
            console.error('Session error:', sessionError);
            setError(sessionError.message);
            setUser(null);
            setSession(null);
          } else if (initialSession) {
            setSession(initialSession);
            setUser(initialSession.user);
          }
          setLoading(false);
        }
      } catch (err) {
        if (mounted) {
          console.error('Auth initialization error:', err);
          setError(err instanceof Error ? err.message : 'Unknown error');
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

  const signOut = async () => {
    // Clear state immediately for instant feedback
    setUser(null);
    setSession(null);
    // Then sign out from Supabase
    await supabase.auth.signOut();
  };

  const value: AuthContextType = {
    user,
    session,
    loading,
    error,
    isAuthenticated: !!user,
    signOut,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}
```

### 2. ProtectedRoute Component

```typescript
// components/auth/ProtectedRoute.tsx
import { ReactNode } from 'react';
import { useAuth } from '@/contexts/AuthContext';

interface ProtectedRouteProps {
  children: ReactNode;
  fallback: ReactNode;
}

export function ProtectedRoute({ children, fallback }: ProtectedRouteProps) {
  const { isAuthenticated, loading } = useAuth();

  // Show loading spinner during auth initialization
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          <p className="text-muted-foreground">Ładowanie...</p>
        </div>
      </div>
    );
  }

  // Return children if authenticated, fallback otherwise
  return isAuthenticated ? <>{children}</> : <>{fallback}</>;
}
```

### 3. Router Setup

```typescript
// App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/contexts/AuthContext';
import { ProtectedRoute } from '@/components/auth/ProtectedRoute';
import { MainLayout } from '@/components/layout/MainLayout';

// Pages
import { Auth } from '@/pages/Auth';
import { Dashboard } from '@/pages/Dashboard';
import { Documents } from '@/pages/Documents';
import { NotFound } from '@/pages/NotFound';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public route */}
            <Route path="/auth" element={<Auth />} />

            {/* Protected routes */}
            <Route
              path="/"
              element={
                <ProtectedRoute fallback={<Auth />}>
                  <MainLayout>
                    <Dashboard />
                  </MainLayout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/documents"
              element={
                <ProtectedRoute fallback={<Auth />}>
                  <MainLayout>
                    <Documents />
                  </MainLayout>
                </ProtectedRoute>
              }
            />

            {/* 404 */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
```

### 4. MainLayout Component

```typescript
// components/layout/MainLayout.tsx
import { ReactNode } from 'react';
import { Header } from './Header';

interface MainLayoutProps {
  children: ReactNode;
}

export function MainLayout({ children }: MainLayoutProps) {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <main className="container mx-auto py-6 px-4">
        {children}
      </main>
    </div>
  );
}
```

### 5. Header with User Info

```typescript
// components/layout/Header.tsx
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { LogOut, Home, FileText } from 'lucide-react';

export function Header() {
  const { t } = useTranslation();
  const { user, signOut } = useAuth();
  const navigate = useNavigate();

  const handleSignOut = async () => {
    await signOut();
    navigate('/auth');
  };

  return (
    <header className="border-b bg-card">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        {/* Navigation */}
        <nav className="flex items-center gap-6">
          <Link to="/" className="flex items-center gap-2 font-semibold">
            <Home className="h-5 w-5" />
            Dashboard
          </Link>
          <Link
            to="/documents"
            className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors"
          >
            <FileText className="h-4 w-4" />
            {t('nav.documents')}
          </Link>
        </nav>

        {/* User info + Logout */}
        <div className="flex items-center gap-4">
          {user && (
            <span className="text-sm text-muted-foreground">
              {user.email}
            </span>
          )}
          <Button variant="ghost" size="sm" onClick={handleSignOut}>
            <LogOut className="h-4 w-4 mr-2" />
            {t('auth.logout')}
          </Button>
        </div>
      </div>
    </header>
  );
}
```

### 6. Auth Page

```typescript
// pages/Auth.tsx
import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { AuthForm } from '@/components/auth/AuthForm';

export function Auth() {
  const { isAuthenticated, loading } = useAuth();
  const navigate = useNavigate();

  // Redirect if already authenticated
  useEffect(() => {
    if (!loading && isAuthenticated) {
      navigate('/', { replace: true });
    }
  }, [isAuthenticated, loading, navigate]);

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <AuthForm />
    </div>
  );
}
```

### 7. AuthForm Component

```typescript
// components/auth/AuthForm.tsx
import { useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { AlertCircle, Loader2 } from 'lucide-react';

type AuthMode = 'login' | 'register' | 'forgot';

export function AuthForm() {
  const [mode, setMode] = useState<AuthMode>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);
    setLoading(true);

    try {
      if (mode === 'login') {
        const { error } = await supabase.auth.signInWithPassword({
          email,
          password,
        });
        if (error) throw error;
      } else if (mode === 'register') {
        const { error } = await supabase.auth.signUp({
          email,
          password,
        });
        if (error) throw error;
        setMessage('Sprawdź swoją skrzynkę email, aby potwierdzić konto.');
      } else if (mode === 'forgot') {
        const { error } = await supabase.auth.resetPasswordForEmail(email);
        if (error) throw error;
        setMessage('Link do resetowania hasła został wysłany na podany adres email.');
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Wystąpił błąd');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card className="w-[400px]">
      <CardHeader>
        <CardTitle>
          {mode === 'login' && 'Logowanie'}
          {mode === 'register' && 'Rejestracja'}
          {mode === 'forgot' && 'Reset hasła'}
        </CardTitle>
        <CardDescription>
          {mode === 'login' && 'Zaloguj się do swojego konta'}
          {mode === 'register' && 'Utwórz nowe konto'}
          {mode === 'forgot' && 'Podaj adres email, aby zresetować hasło'}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {message && (
            <Alert>
              <AlertDescription>{message}</AlertDescription>
            </Alert>
          )}

          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="email@example.com"
              required
              disabled={loading}
            />
          </div>

          {mode !== 'forgot' && (
            <div className="space-y-2">
              <Label htmlFor="password">Hasło</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="********"
                required
                disabled={loading}
              />
            </div>
          )}

          <Button type="submit" className="w-full" disabled={loading}>
            {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
            {mode === 'login' && 'Zaloguj się'}
            {mode === 'register' && 'Zarejestruj się'}
            {mode === 'forgot' && 'Wyślij link'}
          </Button>

          <div className="text-center text-sm space-y-2">
            {mode === 'login' && (
              <>
                <button
                  type="button"
                  onClick={() => setMode('forgot')}
                  className="text-muted-foreground hover:text-primary transition-colors"
                >
                  Zapomniałeś hasła?
                </button>
                <div>
                  Nie masz konta?{' '}
                  <button
                    type="button"
                    onClick={() => setMode('register')}
                    className="text-primary hover:underline"
                  >
                    Zarejestruj się
                  </button>
                </div>
              </>
            )}

            {mode === 'register' && (
              <div>
                Masz już konto?{' '}
                <button
                  type="button"
                  onClick={() => setMode('login')}
                  className="text-primary hover:underline"
                >
                  Zaloguj się
                </button>
              </div>
            )}

            {mode === 'forgot' && (
              <button
                type="button"
                onClick={() => setMode('login')}
                className="text-primary hover:underline"
              >
                Wróć do logowania
              </button>
            )}
          </div>
        </form>
      </CardContent>
    </Card>
  );
}
```

## File Structure

```
src/
├── contexts/
│   └── AuthContext.tsx     # Auth state management
├── components/
│   ├── auth/
│   │   ├── AuthForm.tsx    # Login/Register form
│   │   └── ProtectedRoute.tsx
│   └── layout/
│       ├── Header.tsx
│       └── MainLayout.tsx
├── pages/
│   ├── Auth.tsx            # Public auth page
│   ├── Dashboard.tsx       # Protected
│   └── Documents.tsx       # Protected
└── App.tsx                 # Router configuration
```

## Best Practices

1. **Always check loading state** before rendering protected content
2. **Use mounted flag** in useEffect to prevent state updates after unmount
3. **Setup listener first** - `onAuthStateChange` before `getSession()`
4. **Clear state immediately** on signOut for instant feedback
5. **Redirect authenticated users** away from auth page
6. **Use consistent loading UI** across all protected routes

## Pułapki

### 1. Flash of unauthorized content
**Problem:** Chroniona strona renderuje się na ułamek sekundy zanim `loading` zmieni się na `false` — user widzi treść, potem redirect.
**Rozwiązanie:** Sprawdzaj `loading` PRZED routingiem. Dopóki `isAuthenticated === undefined` — pokaż skeleton, nie stronę.

### 2. Dwa wywołania getSession()
**Problem:** Ustawienie listenera `onAuthStateChange` PO `getSession()` — jeśli sesja się zmieni między nimi, stan jest niespójny.
**Rozwiązanie:** Ustaw listener PRZED `getSession()`. Listener obsłuży wszystkie eventy, w tym inicjalny.

### 3. Redirect loop na stronie auth
**Problem:** Auth page sprawdza `isAuthenticated` gdy `loading` jest jeszcze `true` — przekierowuje na `/` zanim sprawdzenie się zakończy.
**Rozwiązanie:** W Auth page: `if (!loading && isAuthenticated) navigate('/')` — zawsze czekaj na koniec ładowania.

### 4. signOut() race condition
**Problem:** `supabase.auth.signOut()` jest async — UI dalej pokazuje dane zalogowanego usera przez chwilę po kliknięciu „Wyloguj".
**Rozwiązanie:** Ustaw `setUser(null)` PRZED `signOut()` — daj natychmiastowy feedback UI, potem czyść sesję.

### 5. Brak fallback prop w ProtectedRoute
**Problem:** ProtectedRoute bez `fallback` pokazuje pusty ekran lub loader zamiast formularza logowania gdy user nie jest zalogowany.
**Rozwiązanie:** ZAWSZE przekazuj `fallback={<Auth />}` do ProtectedRoute — nigdy nie pomijaj tego propa.

### 6. ProtectedRoute nie opakowuje `<Outlet />` przy nested routes
**Problem:** Przy zagnieżdżonych trasach (`<Route>` wewnątrz `<Route>`) ProtectedRoute opakowuje tylko rodzica, a dzieci renderują się bez ochrony.
```tsx
// ❌ Źle — /dashboard/settings renderuje się bez ochrony
<Route path="/dashboard" element={<ProtectedRoute fallback={<Auth />}><Dashboard /></ProtectedRoute>}>
  <Route path="settings" element={<Settings />} />
</Route>

// ✅ Dobrze — ProtectedRoute opakowuje Outlet, chroni wszystkie dzieci
<Route path="/dashboard" element={<ProtectedRoute fallback={<Auth />}><MainLayout><Outlet /></MainLayout></ProtectedRoute>}>
  <Route index element={<Dashboard />} />
  <Route path="settings" element={<Settings />} />
</Route>
```

### 7. Wygasła sesja nie wyrzuca usera z chronionej strony
**Problem:** Token wygasa po czasie (domyślnie 1h w Supabase). Jeśli user ma otwartą kartę, `onAuthStateChange` nie wyemituje `SIGNED_OUT` — user widzi chronioną treść z niedziałającymi zapytaniami API.
**Rozwiązanie:** Dodaj obsługę `TOKEN_REFRESHED` i błędu odświeżania w listenerze. Jeśli refresh się nie powiedzie, wymuś wylogowanie:
```tsx
// W onAuthStateChange callback:
if (event === 'TOKEN_REFRESHED' && !newSession) {
  // Refresh się nie powiódł — wymuś wylogowanie
  setUser(null);
  setSession(null);
}
```

### 8. Użycie `Navigate` zamiast fallback powoduje utratę URL-a powrotnego
**Problem:** `<Navigate to="/auth" />` w ProtectedRoute traci informację skąd user przyszedł. Po zalogowaniu wraca na `/` zamiast na oryginalną stronę.
```tsx
// ❌ Źle — po zalogowaniu user trafi na /, nie na /documents
<Navigate to="/auth" replace />

// ✅ Dobrze — zapisz oryginalny URL w state
<Navigate to="/auth" replace state={{ from: location.pathname }} />

// W Auth page po zalogowaniu:
const location = useLocation();
const from = location.state?.from || '/';
navigate(from, { replace: true });
```

### 9. AuthProvider poza BrowserRouter blokuje useNavigate w kontekście auth
**Problem:** Gdy `AuthProvider` jest nad `BrowserRouter`, nie można użyć `useNavigate()` wewnątrz kontekstu auth (np. do automatycznego redirectu po wylogowaniu). React Router rzuca błąd.
```tsx
// ❌ Źle — useNavigate niedostępne w AuthProvider
<AuthProvider>
  <BrowserRouter>
    <Routes>...</Routes>
  </BrowserRouter>
</AuthProvider>

// ✅ Dobrze — AuthProvider WEWNĄTRZ BrowserRouter
<BrowserRouter>
  <AuthProvider>
    <Routes>...</Routes>
  </AuthProvider>
</BrowserRouter>
```
**Uwaga:** Skill celowo trzyma AuthProvider nad BrowserRouter (sekcja Router Setup), bo signOut obsługuje komponent Header. Jeśli potrzebujesz nawigacji w samym AuthContext — odwróć kolejność.

### 10. Race condition: onAuthStateChange odpala się przed getSession
**Problem:** Listener `onAuthStateChange` może odpalić `INITIAL_SESSION` zanim `getSession()` się zakończy. Oba ustawiają `setLoading(false)` — w najgorszym wypadku `loading` zmieni się na `false` z `user: null`, a sekundę później `getSession` ustawi usera = flash niezalogowanego stanu.
**Rozwiązanie:** Traktuj `onAuthStateChange` jako jedyne źródło prawdy. W Supabase v2.39+ listener emituje `INITIAL_SESSION` — można usunąć `getSession()` lub użyć go tylko jako fallback z guardem:
```tsx
if (event === 'INITIAL_SESSION') {
  setSession(newSession);
  setUser(newSession?.user ?? null);
  setLoading(false);
  return; // getSession() staje się zbędne
}
```
