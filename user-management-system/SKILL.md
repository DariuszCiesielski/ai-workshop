# User Management System

## Opis

Ujednolicony system zarządzania użytkownikami z rolami (admin/user) oparty na Supabase Auth.
Sprawdzony wzorzec wdrożony w: Hotel Demo, ClientA, Access Manager, Konwerter Automatyzacji.

Zawiera:
- Panel administracyjny (CRUD użytkowników)
- System ról admin/user z per-tool permissions
- Edge Function do bezpiecznego tworzenia użytkowników (invite / password)
- Komponenty UI stylowane CSS variables (kompatybilne z dowolnym design system)
- RLS policies (Row Level Security)
- Ukryty super-admin pattern

## Triggery

- "dodaj zarządzanie użytkownikami"
- "user management"
- "panel admina użytkownicy"
- "system ról"
- "dodaj role admin/user"
- "zarządzanie uprawnieniami"
- "admin panel users"

## Zależności

```bash
npm install @supabase/supabase-js react-router-dom lucide-react
```

---

## Checklist wdrożenia

1. [ ] Utworzyć tabelę `{project}_allowed_users` w Supabase (SQL)
2. [ ] Dodać RLS policies (SQL)
3. [ ] Deploy Edge Function `create-{project}-user`
4. [ ] Dodać/rozszerzyć typy w `types/auth.ts`
5. [ ] Utworzyć `config/tools.ts` z listą narzędzi aplikacji
6. [ ] Utworzyć komponenty admin (AdminPanel, UserList, UserForm, ToolAccessSelector)
7. [ ] Dodać routing (react-router-dom) z route `/admin`
8. [ ] Dodać link "Zarządzanie użytkownikami" w UserMenu (warunkowo `isAdmin`)
9. [ ] Dodać super-admina ręcznie w tabeli (INSERT + utworzyć konto w Auth > Users)
10. [ ] Przetestować CRUD

---

## 1. Struktura plików

```
src/
├── types/auth.ts                  # UserRole, ToolId, {Project}User, etc.
├── config/tools.ts                # Lista narzędzi aplikacji (ToolConfig[])
├── contexts/AuthContext.tsx        # Auth + role + permissions
├── components/
│   ├── admin/
│   │   ├── AdminPanel.tsx         # Główny panel + logika CRUD
│   │   ├── UserList.tsx           # Tabela użytkowników
│   │   ├── UserForm.tsx           # Modal dodawania/edycji
│   │   └── ToolAccessSelector.tsx # Checkboxy wyboru narzędzi
│   └── layout/
│       └── UserMenu.tsx           # Link admin (warunkowo isAdmin)
supabase/
├── functions/
│   └── create-{project}-user/
│       └── index.ts               # Edge Function
└── migrations/
    ├── 001_allowed_users.sql      # Tabela + trigger + indeksy
    └── 002_rls_policies.sql       # Row Level Security
```

---

## 2. SQL: Tabela

Zamień `{project}` na prefix aplikacji (np. `konwerter`, `hotel`, `crm`).

```sql
CREATE TABLE IF NOT EXISTS {project}_allowed_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
  allowed_tools TEXT[] DEFAULT '{}',
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_{project}_users_email ON {project}_allowed_users(email);
CREATE INDEX IF NOT EXISTS idx_{project}_users_user_id ON {project}_allowed_users(user_id);

-- Trigger auto-update updated_at
CREATE OR REPLACE FUNCTION update_{project}_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_{project}_users_timestamp
  BEFORE UPDATE ON {project}_allowed_users
  FOR EACH ROW
  EXECUTE FUNCTION update_{project}_users_updated_at();

-- Seed super-admin
INSERT INTO {project}_allowed_users (email, role, allowed_tools)
VALUES ('admin@example.com', 'admin', '{}')
ON CONFLICT (email) DO NOTHING;
```

---

## 3. SQL: RLS Policies

```sql
ALTER TABLE {project}_allowed_users ENABLE ROW LEVEL SECURITY;

-- SELECT: zalogowani mogą czytać (potrzebne do sprawdzania uprawnień)
CREATE POLICY "Authenticated can read" ON {project}_allowed_users
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- INSERT/UPDATE/DELETE: tylko admini
CREATE POLICY "Admins can insert" ON {project}_allowed_users
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM {project}_allowed_users WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update" ON {project}_allowed_users
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM {project}_allowed_users WHERE user_id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can delete" ON {project}_allowed_users
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM {project}_allowed_users WHERE user_id = auth.uid() AND role = 'admin')
  );
```

---

## 4. Typy TypeScript

### types/auth.ts

```typescript
export type UserRole = 'admin' | 'user';
export type ToolId = string;
export type UserCreationMethod = 'invite' | 'password';

export interface UserPermissions {
  role: UserRole;
  allowedTools: ToolId[];
}

export interface AppUser {
  id: string;
  email: string;
  role: UserRole;
  allowedTools: ToolId[];
  displayName: string | null;
  createdAt: string;
  updatedAt: string;
}

export const HIDDEN_SUPER_ADMIN = 'admin@example.com';
```

### config/tools.ts

```typescript
import type { ToolId } from '../types/auth';

export interface ToolConfig {
  id: ToolId;
  name: string;
  description: string;
}

// Dostosuj do swojej aplikacji
export const TOOLS: ToolConfig[] = [
  { id: 'main-tool', name: 'Główne narzędzie', description: 'Opis funkcji' },
];
```

---

## 5. Edge Function: create-{project}-user

**Deploy:** `npx supabase functions deploy create-{project}-user --project-ref YOUR_REF`

Kluczowe elementy:
1. Weryfikacja JWT + sprawdzenie roli admin w tabeli
2. Synchronizacja `user_id` admina (jeśli puste)
3. Walidacja danych wejściowych
4. Sprawdzenie duplikatu w tabeli
5. Sprawdzenie czy user istnieje w auth.users
6. Tworzenie konta: invite (email z linkiem) lub password (hasło tymczasowe)
7. Insert do tabeli allowed_users
8. Rollback: usunięcie auth user przy błędzie insertu

```typescript
// Schemat request:
interface CreateUserRequest {
  email: string;
  displayName?: string;
  role: 'admin' | 'user';
  allowedTools: string[];
  method: 'invite' | 'password';
  password?: string;
}

// Schemat response:
interface CreateUserResponse {
  success: boolean;
  userId: string;
  inviteSent: boolean;
  existingAuthUser: boolean;
  message: string;
}
```

Pełny kod Edge Function - patrz implementacja w dowolnym projekcie:
- Hotel Demo: `supabase/functions/create-hotel-user/index.ts`
- ClientA: `supabase/functions/create-crm-user/index.ts`
- Konwerter: `supabase/functions/create-konwerter-user/index.ts`

---

## 6. Komponenty Admin

Wszystkie komponenty stylowane **CSS variables** (`var(--bg-primary)`, `var(--text-primary)`, etc.)
co zapewnia kompatybilność z dowolnym systemem motywów.

### AdminPanel.tsx - Główny panel

```typescript
// Kluczowe elementy:
const AdminPanel = () => {
  const { isAdmin, session } = useAuth();
  const navigate = useNavigate();

  // Guard: redirect jeśli nie admin
  if (!isAdmin) { navigate('/'); return null; }

  // fetchUsers() - pobierz z supabase.from(USERS_TABLE).select('*')
  // handleSaveUser() - nowy: fetch Edge Function, edycja: bezpośredni UPDATE
  // handleDeleteUser() - bezpośredni DELETE + confirm()

  return (
    <div>
      <button onClick={() => navigate('/')}>Powrót</button>
      <h1>Zarządzanie użytkownikami</h1>
      <button onClick={() => setShowForm(true)}>Dodaj użytkownika</button>
      <UserList users={users} onEdit={...} onDelete={...} />
      {showForm && <UserForm user={editingUser} onSave={...} onClose={...} />}
    </div>
  );
};
```

### UserForm.tsx - Formularz tworzenia/edycji

Pola:
- **Email** (disabled przy edycji)
- **Nazwa wyświetlana** (opcjonalna)
- **Metoda tworzenia** (tylko nowy): `password` (domyślna) / `invite`
- **Hasło tymczasowe** (widoczne gdy method=password, min 6 znaków)
- **Rola**: User / Admin (radio buttons)
- **ToolAccessSelector** (widoczny tylko dla roli user)

### UserList.tsx - Tabela użytkowników

- Filtruje `HIDDEN_SUPER_ADMIN`
- Kolumny: Użytkownik, Rola (badge), Narzędzia, Akcje (Edytuj/Usuń)
- Hover effects na wierszach

### ToolAccessSelector.tsx - Wybór narzędzi

- Pobiera listę z `config/tools.ts`
- Checkboxy z nazwą i opisem
- Przyciski "Zaznacz/Odznacz wszystkie"
- Licznik wybranych

---

## 7. Routing

W `main.tsx` dodaj:

```typescript
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import AdminPanel from './components/admin/AdminPanel';

// Wewnątrz providerów:
<BrowserRouter>
  <Routes>
    <Route path="/" element={<App />} />
    <Route path="/admin" element={<AdminPanel />} />
  </Routes>
</BrowserRouter>
```

---

## 8. Link admin w UserMenu

W `UserMenu.tsx` dodaj warunkowo:

```typescript
const { isAdmin } = useAuth();
const navigate = useNavigate();

// W dropdown menu, przed przyciskiem wylogowania:
{isAdmin && (
  <button onClick={() => navigate('/admin')}>
    <Settings /> Zarządzanie użytkownikami
  </button>
)}
```

---

## 9. AuthContext - wymagane elementy

AuthContext musi eksponować:

```typescript
interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  isAuthenticated: boolean;
  hasAccess: boolean;        // czy user jest w tabeli allowed_users
  accessDenied: boolean;     // zalogowany ale brak w tabeli
  isAdmin: boolean;          // role === 'admin'
  userRole: UserRole | null;
  allowedTools: ToolId[];
  canAccessTool: (toolId: string) => boolean;  // admin=true, user=sprawdza tablicę
  refreshPermissions: () => Promise<void>;
  signOut: () => Promise<void>;
}
```

Logika `fetchUserPermissions`:
```typescript
const { data } = await supabase
  .from('{project}_allowed_users')
  .select('role, allowed_tools')
  .eq('email', email)
  .single();
```

---

## 10. Workflow użytkownika

### Tworzenie:
1. Admin → UserForm (email, role, tools, method, password?)
2. AdminPanel → fetch Edge Function z payloadem
3. Edge Function: weryfikacja admin → sprawdź duplikat → utwórz auth user → insert do tabeli
4. Zwróć message → AdminPanel odśwież listę

### Edycja:
1. Admin → UserForm (wypełniony danymi, email disabled)
2. AdminPanel → bezpośredni UPDATE na tabeli (role, allowed_tools, display_name)

### Usuwanie:
1. Admin → confirm() → DELETE z tabeli
2. Konto auth.users zostaje (user_id → NULL przez ON DELETE SET NULL)

### Pierwsze logowanie admina:
1. Dodaj email w tabeli (SQL INSERT z role='admin')
2. Utwórz konto w Supabase Dashboard > Authentication > Users > Add user (Auto Confirm)
3. Zaloguj się → AuthContext pobierze uprawnienia z tabeli
