---
name: admin-panel-scaffold
description: Kompletny scaffold panelu administracyjnego z autentykacją, layoutem, routingiem i chronionymi stronami. Sidebar, dark mode, breadcrumby, separacja user/admin. Używaj przy tworzeniu nowego panelu admina lub dashboardu.
---

# Admin Panel Scaffold

This skill provides a complete scaffold for building admin panels with authentication, layouts, and protected routes.

## When to Use

- Starting a new admin dashboard project
- Building a panel with user/admin role separation
- Setting up protected routes with authentication
- Creating responsive layouts with sidebar navigation

## Project Structure

```
src/
├── components/
│   ├── auth/
│   │   ├── AdminRoute.tsx      # Admin-only route wrapper
│   │   ├── AuthForm.tsx        # Login form
│   │   └── ProtectedRoute.tsx  # Authenticated route wrapper
│   ├── layout/
│   │   ├── Breadcrumbs.tsx     # Navigation breadcrumbs
│   │   ├── Header.tsx          # Admin header with theme toggle
│   │   ├── MainLayout.tsx      # Admin layout with sidebar
│   │   ├── Sidebar.tsx         # Navigation sidebar
│   │   ├── UserHeader.tsx      # User panel header
│   │   └── UserLayout.tsx      # User panel layout
│   └── ui/                     # shadcn/ui components
├── contexts/
│   └── AuthContext.tsx         # Authentication state
├── pages/
│   ├── Auth.tsx                # Login page
│   ├── Dashboard.tsx           # Admin dashboard
│   ├── NoAccess.tsx            # Access denied page
│   ├── UserDashboard.tsx       # User panel
│   └── ...                     # Feature pages
├── hooks/
│   └── useAuth.ts              # Auth hook re-export
├── App.tsx                     # Routing setup
└── main.tsx                    # Entry point
```

## Core Components

### App.tsx (Routing)

```typescript
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from '@/contexts/AuthContext';

// Pages
import Auth from '@/pages/Auth';
import NoAccess from '@/pages/NoAccess';
import Dashboard from '@/pages/Dashboard';
import UserDashboard from '@/pages/UserDashboard';
import Users from '@/pages/Users';
import Applications from '@/pages/Applications';

// Components
import { AdminRoute } from '@/components/auth/AdminRoute';
import { ProtectedRoute } from '@/components/auth/ProtectedRoute';
import { MainLayout } from '@/components/layout/MainLayout';
import { UserLayout } from '@/components/layout/UserLayout';

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public routes */}
            <Route path="/auth" element={<Auth />} />
            <Route path="/no-access" element={<NoAccess />} />

            {/* User routes (authenticated) */}
            <Route
              path="/user"
              element={
                <ProtectedRoute>
                  <UserLayout />
                </ProtectedRoute>
              }
            >
              <Route index element={<UserDashboard />} />
            </Route>

            {/* Admin routes */}
            <Route
              path="/"
              element={
                <AdminRoute>
                  <MainLayout />
                </AdminRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="users" element={<Users />} />
              <Route path="applications" element={<Applications />} />
              {/* Add more admin routes */}
            </Route>

            {/* Fallback */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;
```

### AuthContext.tsx

```typescript
import { createContext, useContext, useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import type { User, Session } from '@supabase/supabase-js';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  isAdmin: boolean;
  isLoading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        checkAdminStatus();
      } else {
        setIsLoading(false);
      }
    });

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        setSession(session);
        setUser(session?.user ?? null);
        if (session?.user) {
          await checkAdminStatus();
        } else {
          setIsAdmin(false);
          setIsLoading(false);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  async function checkAdminStatus() {
    try {
      const { data, error } = await supabase.rpc('is_admin');
      setIsAdmin(error ? false : data === true);
    } catch {
      setIsAdmin(false);
    } finally {
      setIsLoading(false);
    }
  }

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setIsAdmin(false);
  };

  return (
    <AuthContext.Provider value={{ user, session, isAdmin, isLoading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
```

### AdminRoute.tsx

```typescript
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Skeleton } from '@/components/ui/skeleton';

interface AdminRouteProps {
  children: React.ReactNode;
}

export function AdminRoute({ children }: AdminRouteProps) {
  const { user, isAdmin, isLoading } = useAuth();

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <Skeleton className="h-12 w-48" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/auth" replace />;
  }

  if (!isAdmin) {
    return <Navigate to="/user" replace />;
  }

  return <>{children}</>;
}
```

### MainLayout.tsx (Admin)

```typescript
import { Outlet } from 'react-router-dom';
import { Header } from './Header';
import { Sidebar } from './Sidebar';
import { Breadcrumbs } from './Breadcrumbs';

export function MainLayout() {
  return (
    <div className="min-h-screen bg-background">
      <Header />
      <div className="flex">
        <Sidebar />
        <main className="flex-1 p-6">
          <Breadcrumbs />
          <Outlet />
        </main>
      </div>
    </div>
  );
}
```

### Sidebar.tsx

```typescript
import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  LayoutDashboard,
  Users,
  AppWindow,
  Shield,
  UserCog,
} from 'lucide-react';
import { cn } from '@/lib/utils';

const navItems = [
  { path: '/', icon: LayoutDashboard, labelKey: 'nav.dashboard' },
  { path: '/users', icon: Users, labelKey: 'nav.users' },
  { path: '/applications', icon: AppWindow, labelKey: 'nav.applications' },
  { path: '/permissions', icon: Shield, labelKey: 'nav.permissions' },
  { path: '/admins', icon: UserCog, labelKey: 'nav.admins' },
];

export function Sidebar() {
  const { t } = useTranslation();

  return (
    <aside className="w-64 border-r bg-card min-h-[calc(100vh-64px)]">
      <nav className="p-4 space-y-1">
        {navItems.map(({ path, icon: Icon, labelKey }) => (
          <NavLink
            key={path}
            to={path}
            end={path === '/'}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 px-3 py-2 rounded-lg transition-colors',
                isActive
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
              )
            }
          >
            <Icon className="h-5 w-5" />
            <span>{t(labelKey)}</span>
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
```

### Header.tsx

```typescript
import { useAuth } from '@/contexts/AuthContext';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { Moon, Sun, LogOut } from 'lucide-react';
import { useEffect, useState } from 'react';

export function Header() {
  const { user, signOut } = useAuth();
  const { t } = useTranslation();
  const [isDark, setIsDark] = useState(false);

  useEffect(() => {
    const saved = localStorage.getItem('theme');
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const dark = saved === 'dark' || (!saved && prefersDark);
    setIsDark(dark);
    document.documentElement.classList.toggle('dark', dark);
  }, []);

  const toggleTheme = () => {
    const newDark = !isDark;
    setIsDark(newDark);
    document.documentElement.classList.toggle('dark', newDark);
    localStorage.setItem('theme', newDark ? 'dark' : 'light');
  };

  return (
    <header className="h-16 border-b bg-card px-6 flex items-center justify-between">
      <h1 className="text-xl font-bold">{t('app.name')}</h1>

      <div className="flex items-center gap-4">
        <span className="text-sm text-muted-foreground">{user?.email}</span>

        <Button variant="ghost" size="icon" onClick={toggleTheme}>
          {isDark ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
        </Button>

        <Button variant="ghost" size="icon" onClick={signOut}>
          <LogOut className="h-5 w-5" />
        </Button>
      </div>
    </header>
  );
}
```

### Breadcrumbs.tsx

```typescript
import { Link, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { ChevronRight, Home } from 'lucide-react';

const routeLabels: Record<string, string> = {
  '': 'nav.dashboard',
  users: 'nav.users',
  applications: 'nav.applications',
  permissions: 'nav.permissions',
  admins: 'nav.admins',
};

export function Breadcrumbs() {
  const location = useLocation();
  const { t } = useTranslation();

  const pathnames = location.pathname.split('/').filter(Boolean);

  if (pathnames.length === 0) return null;

  return (
    <nav className="flex items-center gap-2 text-sm text-muted-foreground mb-6">
      <Link to="/" className="hover:text-foreground">
        <Home className="h-4 w-4" />
      </Link>

      {pathnames.map((segment, index) => {
        const path = `/${pathnames.slice(0, index + 1).join('/')}`;
        const isLast = index === pathnames.length - 1;
        const label = routeLabels[segment] || segment;

        return (
          <span key={path} className="flex items-center gap-2">
            <ChevronRight className="h-4 w-4" />
            {isLast ? (
              <span className="text-foreground">{t(label)}</span>
            ) : (
              <Link to={path} className="hover:text-foreground">
                {t(label)}
              </Link>
            )}
          </span>
        );
      })}
    </nav>
  );
}
```

### Auth.tsx (Login Page)

```typescript
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useTranslation } from 'react-i18next';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';

export default function Auth() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const { signIn } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await signIn(email, password);
      navigate('/');
    } catch (err) {
      setError(t('errors.unauthorized'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <Card className="w-[400px]">
        <CardHeader>
          <CardTitle>{t('auth.login')}</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            {error && (
              <div className="p-3 bg-destructive/10 text-destructive text-sm rounded">
                {error}
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="email">{t('auth.email')}</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">{t('auth.password')}</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>

            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? t('app.loading') : t('auth.login')}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
```

## Checklist

When using this scaffold:

- [ ] Install dependencies (react-router-dom, @tanstack/react-query, i18next)
- [ ] Set up Supabase client and types
- [ ] Create AuthContext with admin check
- [ ] Create route wrappers (AdminRoute, ProtectedRoute)
- [ ] Create layouts (MainLayout, UserLayout)
- [ ] Set up navigation (Sidebar, Header, Breadcrumbs)
- [ ] Create Auth page with login form
- [ ] Create NoAccess page for unauthorized users
- [ ] Add translation files
- [ ] Configure dark mode toggle

## Customization

- **Colors**: Edit `src/index.css` theme variables
- **Navigation**: Modify `navItems` in Sidebar.tsx
- **Routes**: Add routes in App.tsx
- **Translations**: Add keys to locales/pl/*.json

## Pułapki

### 1. isLoading nie zmienia się na false po błędzie auth
**Problem:** Jeśli `checkAdminStatus()` throwuje wyjątek, `isLoading` nigdy nie staje się `false` — spinner kręci się w nieskończoność.
**Rozwiązanie:** Zawsze umieść `setIsLoading(false)` w bloku `finally`, nie tylko w `then`.

### 2. Flash niezalogowanej strony
**Problem:** `isAdmin` startuje jako `false` — przez ułamek sekundy user widzi redirect do login zanim sprawdzenie się zakończy.
**Rozwiązanie:** Użyj trójstanowego typu: `isAdmin: boolean | undefined`. Dopóki `undefined` — pokazuj skeleton, nie redirect.

### 3. Memory leak w useEffect
**Problem:** Po unmount komponentu `setState` w async callback generuje warning „Can't perform a React state update on an unmounted component".
**Rozwiązanie:** Dodaj `let mounted = true` i sprawdzaj `if (!mounted) return` przed każdym `setX()`. W cleanup: `mounted = false`.

### 4. Sidebar pokazuje admin items dla non-admina
**Problem:** Sidebar renderowany poza `ProtectedRoute` — zawsze pokazuje pełne menu, nawet gdy user nie ma uprawnień.
**Rozwiązanie:** Sidebar z nawigacją admin WEWNĄTRZ `AdminLayout`, który jest renderowany tylko po weryfikacji roli.

### 5. Brak obsługi offline/timeout dla RPC
**Problem:** `checkAdminStatus()` wywołuje Supabase RPC — jeśli sieć jest wolna, user czeka bez feedbacku.
**Rozwiązanie:** Dodaj timeout (np. 5s) z fallbackiem: `Promise.race([rpcCall, timeout])` i komunikat „Sprawdzanie uprawnień...".

## Auto-feedback (samoanaliza po użyciu)

Po zakończeniu pracy ze skillem, agent MUSI wygenerować krótki raport i zapisać go w:
`~/projekty/Moje skille/feedback/admin-panel-scaffold-feedback-{{DATA}}.md`

### Format raportu

```markdown
# Feedback: admin-panel-scaffold
Data: {{DATA}}
Projekt: {{NAZWA_PROJEKTU}}
Agent: {{MODEL}}

## Co zadziałało dobrze
- [lista]

## Anomalie i problemy
- [opis problemu, kontekst, wpływ na wynik]

## Brakujące instrukcje
- [czego brakowało w skillu, co agent musiał improwizować]

## Sugestie usprawnień
- [konkretne propozycje zmian z uzasadnieniem]

## Metryki
- Czas wykonania: ~X min
- Liczba kroków/faz: X
- Wynik: sukces/częściowy/porażka
```

### Zasady
- Raport generuj TYLKO gdy jest coś wartościowego do zgłoszenia (anomalie, brakujące instrukcje, sugestie)
- Jeśli skill zadziałał bez problemów — NIE generuj raportu (brak raportu = wszystko OK)
- Nie raportuj ogólników ("testy mogłyby być lepsze") — tylko konkretne, actionable obserwacje
- Raport to MAX 20 linii — zwięźle i na temat
