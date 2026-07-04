---
name: i18next-pl
description: Konfiguracja i18next dla polskojęzycznych aplikacji React. Setup, struktura plików tłumaczeń, wzorce użycia z hookiem useTranslation. Używaj przy dodawaniu polskich tłumaczeń do aplikacji React.
---

# i18next Polish Configuration

This skill guides you through setting up i18next for Polish-only React applications.

## When to Use

- Adding Polish translations to a React application
- Setting up i18next without complex multi-language config
- Creating translation file structure
- Using translations in components

## Setup

### Installation

```bash
npm install i18next react-i18next
```

### Configuration

Create `src/lib/i18n.ts`:

```typescript
import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';

// Import translation files
import commonPL from '@/locales/pl/common.json';
import usersPL from '@/locales/pl/users.json';
import applicationsPL from '@/locales/pl/applications.json';
import permissionsPL from '@/locales/pl/permissions.json';
import adminsPL from '@/locales/pl/admins.json';

i18n.use(initReactI18next).init({
  resources: {
    pl: {
      common: commonPL,
      users: usersPL,
      applications: applicationsPL,
      permissions: permissionsPL,
      admins: adminsPL,
    },
  },
  lng: 'pl', // Default language
  fallbackLng: 'pl',
  defaultNS: 'common', // Default namespace
  interpolation: {
    escapeValue: false, // React already escapes
  },
});

export default i18n;
```

### Import in main.tsx

```typescript
// main.tsx
import './lib/i18n'; // Import i18n configuration

import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
```

## Translation Files

### Directory Structure

```
src/locales/
└── pl/
    ├── common.json      # Shared translations (nav, buttons, errors)
    ├── users.json       # User management page
    ├── applications.json # Applications page
    ├── permissions.json  # Permissions page
    └── admins.json      # Admins page
```

### common.json

```json
{
  "app": {
    "name": "Access Manager",
    "loading": "Ładowanie...",
    "error": "Wystąpił błąd"
  },
  "nav": {
    "dashboard": "Dashboard",
    "users": "Użytkownicy",
    "applications": "Aplikacje",
    "permissions": "Uprawnienia",
    "admins": "Administratorzy"
  },
  "actions": {
    "save": "Zapisz",
    "cancel": "Anuluj",
    "delete": "Usuń",
    "edit": "Edytuj",
    "add": "Dodaj",
    "search": "Szukaj",
    "filter": "Filtruj",
    "refresh": "Odśwież",
    "confirm": "Potwierdź",
    "back": "Wstecz",
    "close": "Zamknij"
  },
  "auth": {
    "login": "Zaloguj się",
    "logout": "Wyloguj się",
    "email": "Adres e-mail",
    "password": "Hasło",
    "forgotPassword": "Zapomniałeś hasła?",
    "noAccess": "Brak dostępu",
    "noAccessDescription": "Nie masz uprawnień do tego zasobu."
  },
  "errors": {
    "required": "To pole jest wymagane",
    "invalidEmail": "Nieprawidłowy adres e-mail",
    "networkError": "Błąd połączenia z serwerem",
    "unauthorized": "Sesja wygasła, zaloguj się ponownie",
    "notFound": "Nie znaleziono",
    "serverError": "Błąd serwera"
  },
  "confirmations": {
    "delete": "Czy na pewno chcesz usunąć?",
    "unsavedChanges": "Masz niezapisane zmiany. Czy na pewno chcesz wyjść?"
  },
  "empty": {
    "noData": "Brak danych",
    "noResults": "Brak wyników wyszukiwania"
  },
  "pagination": {
    "showing": "Pokazano",
    "of": "z",
    "results": "wyników",
    "previous": "Poprzednia",
    "next": "Następna"
  },
  "dashboard": {
    "title": "Dashboard",
    "stats": {
      "users": "Użytkownicy",
      "applications": "Aplikacje",
      "activeAccess": "Aktywne dostępy",
      "admins": "Administratorzy"
    },
    "recentActivity": "Ostatnia aktywność",
    "noActivity": "Brak ostatniej aktywności"
  },
  "theme": {
    "light": "Jasny motyw",
    "dark": "Ciemny motyw",
    "toggle": "Przełącz motyw"
  }
}
```

### users.json

```json
{
  "title": "Użytkownicy",
  "description": "Zarządzaj użytkownikami systemu",
  "table": {
    "email": "Email",
    "name": "Imię i nazwisko",
    "createdAt": "Data rejestracji",
    "lastLogin": "Ostatnie logowanie",
    "status": "Status",
    "actions": "Akcje"
  },
  "filters": {
    "all": "Wszyscy",
    "admins": "Administratorzy",
    "regular": "Zwykli użytkownicy"
  },
  "details": {
    "title": "Szczegóły użytkownika",
    "applications": "Przypisane aplikacje",
    "noApplications": "Brak przypisanych aplikacji"
  },
  "badge": {
    "admin": "Admin"
  }
}
```

### applications.json

```json
{
  "title": "Aplikacje",
  "description": "Zarządzaj aplikacjami w ekosystemie",
  "add": "Dodaj aplikację",
  "table": {
    "name": "Nazwa",
    "slug": "Slug",
    "url": "URL",
    "status": "Status",
    "users": "Użytkownicy",
    "actions": "Akcje"
  },
  "form": {
    "name": "Nazwa aplikacji",
    "namePlaceholder": "np. Hotel Demo",
    "slug": "Slug (identyfikator)",
    "slugPlaceholder": "np. hotel-demo",
    "slugHint": "Używany w URL i API",
    "url": "Adres URL",
    "urlPlaceholder": "https://example.com",
    "description": "Opis",
    "descriptionPlaceholder": "Krótki opis aplikacji...",
    "icon": "Ikona"
  },
  "status": {
    "active": "Aktywna",
    "inactive": "Nieaktywna"
  },
  "actions": {
    "activate": "Aktywuj",
    "deactivate": "Dezaktywuj",
    "edit": "Edytuj",
    "delete": "Usuń"
  },
  "confirmations": {
    "delete": "Czy na pewno chcesz usunąć tę aplikację? Wszystkie powiązane dostępy zostaną również usunięte.",
    "deactivate": "Dezaktywacja aplikacji spowoduje utratę dostępu przez wszystkich użytkowników."
  },
  "empty": "Brak aplikacji. Dodaj pierwszą aplikację.",
  "success": {
    "created": "Aplikacja została utworzona",
    "updated": "Aplikacja została zaktualizowana",
    "deleted": "Aplikacja została usunięta",
    "activated": "Aplikacja została aktywowana",
    "deactivated": "Aplikacja została dezaktywowana"
  }
}
```

### permissions.json

```json
{
  "title": "Uprawnienia",
  "description": "Zarządzaj dostępami użytkowników do aplikacji",
  "matrix": {
    "title": "Matryca uprawnień",
    "description": "Kliknij checkbox aby nadać lub odebrać dostęp"
  },
  "grant": {
    "title": "Nadaj dostęp",
    "selectUser": "Wybierz użytkownika",
    "selectApp": "Wybierz aplikację",
    "expiresAt": "Data wygaśnięcia (opcjonalnie)",
    "success": "Dostęp został nadany",
    "error": "Błąd podczas nadawania dostępu"
  },
  "revoke": {
    "title": "Odbierz dostęp",
    "confirm": "Czy na pewno chcesz odebrać dostęp?",
    "success": "Dostęp został odebrany",
    "error": "Błąd podczas odbierania dostępu"
  },
  "bulk": {
    "selected": "Zaznaczono",
    "grantSelected": "Nadaj dostęp zaznaczonym",
    "revokeSelected": "Odbierz dostęp zaznaczonym"
  },
  "filters": {
    "allUsers": "Wszyscy użytkownicy",
    "allApps": "Wszystkie aplikacje",
    "withAccess": "Z dostępem",
    "withoutAccess": "Bez dostępu"
  }
}
```

### admins.json

```json
{
  "title": "Administratorzy",
  "description": "Zarządzaj administratorami panelu",
  "add": "Dodaj administratora",
  "table": {
    "email": "Email",
    "name": "Imię i nazwisko",
    "addedAt": "Data dodania",
    "actions": "Akcje"
  },
  "you": "Ty",
  "form": {
    "selectUser": "Wybierz użytkownika",
    "searchPlaceholder": "Szukaj po emailu..."
  },
  "confirmations": {
    "add": "Czy na pewno chcesz nadać uprawnienia administratora?",
    "remove": "Czy na pewno chcesz odebrać uprawnienia administratora?",
    "cannotRemoveSelf": "Nie możesz usunąć samego siebie"
  },
  "success": {
    "added": "Administrator został dodany",
    "removed": "Administrator został usunięty"
  },
  "errors": {
    "alreadyAdmin": "Ten użytkownik jest już administratorem"
  }
}
```

## Usage in Components

### Basic Usage

```typescript
import { useTranslation } from 'react-i18next';

function MyComponent() {
  const { t } = useTranslation(); // Uses 'common' namespace by default

  return (
    <div>
      <h1>{t('app.name')}</h1>
      <button>{t('actions.save')}</button>
    </div>
  );
}
```

### Specific Namespace

```typescript
import { useTranslation } from 'react-i18next';

function UsersPage() {
  const { t } = useTranslation('users');
  const { t: tCommon } = useTranslation('common');

  return (
    <div>
      <h1>{t('title')}</h1>
      <p>{t('description')}</p>
      <button>{tCommon('actions.add')}</button>
    </div>
  );
}
```

### Multiple Namespaces

```typescript
import { useTranslation } from 'react-i18next';

function PermissionsPage() {
  const { t } = useTranslation(['permissions', 'common']);

  return (
    <div>
      <h1>{t('permissions:title')}</h1>
      <button>{t('common:actions.save')}</button>
    </div>
  );
}
```

### With Variables

```typescript
// In JSON:
// "showing": "Pokazano {{count}} z {{total}} wyników"

const { t } = useTranslation();
t('pagination.showing', { count: 10, total: 100 });
// Output: "Pokazano 10 z 100 wyników"
```

### Pluralization

```typescript
// In JSON:
// "users_one": "{{count}} użytkownik"
// "users_few": "{{count}} użytkowników"
// "users_many": "{{count}} użytkowników"

t('users', { count: 1 });  // "1 użytkownik"
t('users', { count: 3 });  // "3 użytkowników"
t('users', { count: 10 }); // "10 użytkowników"
```

## Best Practices

1. **Use namespaces** to organize translations by feature/page
2. **Keep common translations** in `common.json` for reusability
3. **Use dot notation** for nested keys (`app.name`, `actions.save`)
4. **Avoid hardcoded Polish text** in components
5. **Use variables** for dynamic content instead of string concatenation
6. **Document translation keys** in complex components

## Pułapki

### 1. Polski ma 3 formy liczby mnogiej, nie 2

Polski wymaga trzech kluczy pluralizacji: `_one`, `_few`, `_many`. Klucz `_other` nie wystarczy. Bez `_few` i18next zwróci złą formę dla liczb 2-4, 22-24 itd.

```
❌ "items_one": "{{count}} element", "items_other": "{{count}} elementów"
✅ "items_one": "{{count}} element", "items_few": "{{count}} elementy", "items_many": "{{count}} elementów"
```

Reguły: `_one` = 1, `_few` = 2-4, 22-24, 32-34..., `_many` = 0, 5-21, 25-31, 35-99...

### 2. Brak `latin-ext` w czcionkach — polskie znaki nie renderują się poprawnie

Tłumaczenia w JSON są poprawne, ale czcionka Google Fonts bez `latin-ext` wyświetla kwadraty lub fallback zamiast ą, ć, ę, ł, ń, ó, ś, ź, ż.

```
❌ subsets: ["latin"]
✅ subsets: ["latin-ext"]
```

Dotyczy `next/font/google`, tagów `<link>` i importów Tailwind v4.

### 3. Komponent `Trans` z HTML użytkownika = XSS

Skill ustawia `escapeValue: false` bo React escapuje JSX. Ale wstawianie danych użytkownika przez `Trans` z tagami HTML lub do `innerHTML` omija ochronę Reacta.

```typescript
✅ <Trans i18nKey="welcome" values={{ name: userInput }} components={{ bold: <strong /> }} />
```

Nigdy nie łącz interpolacji i18next z `dangerouslySetInnerHTML` ani surowym HTML.

### 4. Namespace niezaładowany przy lazy loading — cichy fallback na klucz

Przy `i18next-http-backend` lub dynamicznych importach namespace może nie być gotowy w momencie renderowania. Komponent wyświetla surowy klucz (`users:title`) zamiast tłumaczenia.

```typescript
❌ const { t } = useTranslation('users'); // Może zwrócić klucz zanim JSON się załaduje

✅ const { t, ready } = useTranslation('users');
   if (!ready) return <Skeleton />;
```

### 5. Konkatenacja stringów zamiast interpolacji łamie szyk zdania

Po polsku szyk zdania jest elastyczny i różni się od angielskiego. Sklejanie fragmentów uniemożliwia zmianę kolejności słów.

```
❌ t('user') + ' ' + name + ' ' + t('hasItems') + ' ' + count
✅ t('userItems', { name, count })  →  "{{name}} posiada {{count}} elementów"
```

### 6. `useTranslation` w Server Components (Next.js) — nie działa

Hook `useTranslation` wymaga kontekstu React (`I18nextProvider`), który istnieje tylko w Client Components. W Server Components hook zawiedzie po cichu lub rzuci błąd.

```
❌ // app/page.tsx (Server Component) — brak providera, hook nie zadziała
✅ // Oznacz komponent 'use client' ALBO użyj next-intl / przekaż tłumaczenia jako props
```

### 7. Brak `_few` nie zgłasza błędu — cichy błąd gramatyczny

Jeśli zapomnisz klucza `_few`, i18next użyje `_many` bez ostrzeżenia. Efekt: "2 elementów" zamiast "2 elementy". Włącz wykrywanie brakujących kluczy w dev:

```typescript
i18n.init({
  saveMissing: true,
  missingKeyHandler: (lngs, ns, key) => console.warn(`Brak klucza: ${ns}:${key}`),
});
```

### 8. Pliki JSON z tłumaczeniami muszą być UTF-8

Jeśli edytor lub pipeline CI zmieni kodowanie (np. na ISO-8859-2), polskie znaki w wartościach się zepsują. Dodaj `.editorconfig` z `charset = utf-8` i weryfikuj encoding w CI.
