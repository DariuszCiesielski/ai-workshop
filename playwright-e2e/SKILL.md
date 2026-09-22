---
name: playwright-e2e
description: >
  Pisanie testów E2E Playwright dla aplikacji SaaS (Next.js/Vite + Supabase).
  Setup, page objects, fixtures, auth helpers, CI/CD integracja.
  Triggery: "napisz test E2E", "playwright test", "test end-to-end",
  "test rejestracji", "test logowania", "testy automatyczne", "CI testy",
  "pokrycie testami", "test flow", "smoke test", "regression test".
---

# Playwright E2E — Testy end-to-end dla SaaS

Pisze testy E2E Playwright dla aplikacji SaaS na stacku Next.js/Vite + Supabase + Vercel. Setup projektu, page objects, fixtures, auth helpers, integracja z CI/CD.

## Kiedy używać

- Setup Playwright w nowym/istniejącym projekcie
- Pisanie testów dla krytycznych flow (rejestracja, logowanie, zakup)
- Tworzenie page objects i fixtures
- Integracja testów z GitHub Actions / Vercel CI
- Użytkownik mówi: "napisz test E2E", "przetestuj flow rejestracji", "dodaj testy automatyczne"

## Zależności

- **Opcjonalne:** `supabase-auth-rls` → wzorce auth do testowania
- **Opcjonalne:** `analytics-tracking` → weryfikacja eventów w testach
- **Opcjonalne:** plugin `playwright` (narzędzia MCP `browser_*`) → ręczne sprawdzenie strony w przeglądarce przed spisaniem testu

## Setup projektu

### Instalacja

```bash
npm init playwright@latest
# Wybierz: TypeScript, tests/ folder, GitHub Actions workflow
```

### Konfiguracja

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { open: 'never' }],
    ['list'],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    // Auth setup — uruchamia się raz, zapisuje stan sesji
    { name: 'setup', testMatch: /.*\.setup\.ts/ },
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
        storageState: 'tests/.auth/user.json',
      },
      dependencies: ['setup'],
    },
    {
      name: 'mobile',
      use: {
        ...devices['iPhone 14'],
        storageState: 'tests/.auth/user.json',
      },
      dependencies: ['setup'],
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

### Struktura katalogów

```
tests/
├── e2e/
│   ├── auth/
│   │   ├── login.spec.ts
│   │   ├── register.spec.ts
│   │   └── logout.spec.ts
│   ├── dashboard/
│   │   └── dashboard.spec.ts
│   ├── onboarding/
│   │   └── onboarding.spec.ts
│   └── smoke.spec.ts          ← Szybki smoke test (5-10 asercji)
├── fixtures/
│   ├── auth.fixture.ts        ← Zalogowany użytkownik
│   ├── db.fixture.ts          ← Seed/cleanup danych testowych
│   └── index.ts               ← Re-export wszystkich fixtures
├── pages/
│   ├── login.page.ts          ← Page Object: strona logowania
│   ├── dashboard.page.ts
│   └── base.page.ts           ← Bazowy page object
├── .auth/
│   └── user.json              ← Zapisany stan auth (gitignore!)
└── helpers/
    ├── supabase.ts             ← Klient Supabase do seed/cleanup
    └── test-data.ts            ← Fabryki danych testowych
```

## Page Objects

```typescript
// tests/pages/base.page.ts
import { Page, Locator } from '@playwright/test';

export class BasePage {
  constructor(protected page: Page) {}

  async waitForPageLoad() {
    await this.page.waitForLoadState('networkidle');
  }

  async getToastMessage(): Promise<string> {
    const toast = this.page.locator('[data-testid="toast"]');
    await toast.waitFor({ state: 'visible' });
    return toast.textContent() ?? '';
  }
}

// tests/pages/login.page.ts
import { Page } from '@playwright/test';
import { BasePage } from './base.page';

export class LoginPage extends BasePage {
  readonly emailInput: Locator;
  readonly passwordInput: Locator;
  readonly submitButton: Locator;
  readonly errorMessage: Locator;

  constructor(page: Page) {
    super(page);
    this.emailInput = page.getByLabel('Email');
    this.passwordInput = page.getByLabel('Hasło');
    this.submitButton = page.getByRole('button', { name: 'Zaloguj się' });
    this.errorMessage = page.locator('[data-testid="auth-error"]');
  }

  async goto() {
    await this.page.goto('/login');
    await this.waitForPageLoad();
  }

  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }
}

// tests/pages/dashboard.page.ts
import { Page, Locator } from '@playwright/test';
import { BasePage } from './base.page';

export class DashboardPage extends BasePage {
  readonly heading: Locator;
  readonly userMenu: Locator;
  readonly logoutButton: Locator;

  constructor(page: Page) {
    super(page);
    this.heading = page.getByRole('heading', { level: 1 });
    this.userMenu = page.getByTestId('user-menu');
    this.logoutButton = page.getByRole('menuitem', { name: 'Wyloguj' });
  }

  async goto() {
    await this.page.goto('/dashboard');
    await this.waitForPageLoad();
  }

  async logout() {
    await this.userMenu.click();
    await this.logoutButton.click();
  }
}
```

## Auth Fixture (Supabase)

```typescript
// tests/e2e/auth.setup.ts
import { test as setup, expect } from '@playwright/test';

const TEST_USER = {
  email: process.env.TEST_USER_EMAIL || 'test@example.com',
  password: process.env.TEST_USER_PASSWORD || 'TestPassword123!',
};

setup('authenticate', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email').fill(TEST_USER.email);
  await page.getByLabel('Hasło').fill(TEST_USER.password);
  await page.getByRole('button', { name: 'Zaloguj się' }).click();

  // Czekaj na redirect do dashboard
  await page.waitForURL('/dashboard');
  await expect(page.getByRole('heading', { level: 1 })).toBeVisible();

  // Zapisz stan sesji
  await page.context().storageState({ path: 'tests/.auth/user.json' });
});
```

```typescript
// tests/helpers/supabase.ts
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY! // Service role — tylko w testach!
);

export async function createTestUser(email: string, password: string) {
  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (error) throw error;
  return data.user;
}

export async function deleteTestUser(userId: string) {
  await supabase.auth.admin.deleteUser(userId);
}

export async function seedTestData(userId: string) {
  // Wstaw dane testowe
  await supabase.from('projects').insert({
    name: 'Test Project',
    owner_id: userId,
  });
}

export async function cleanupTestData(userId: string) {
  await supabase.from('projects').delete().eq('owner_id', userId);
}
```

## Wzorce testów

### Smoke test (uruchamiaj na każdym deployu)

```typescript
// tests/e2e/smoke.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Smoke tests', () => {
  test('strona główna się ładuje', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/./); // Jakikolwiek tytuł
    await expect(page.locator('body')).toBeVisible();
  });

  test('strona logowania jest dostępna', async ({ page }) => {
    await page.goto('/login');
    await expect(page.getByLabel('Email')).toBeVisible();
  });

  test('dashboard wymaga auth', async ({ browser }) => {
    const context = await browser.newContext(); // Czysta sesja, bez auth
    const page = await context.newPage();
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/login/); // Redirect do logowania
    await context.close();
  });

  test('API health check', async ({ request }) => {
    const response = await request.get('/api/health');
    expect(response.ok()).toBeTruthy();
  });
});
```

### Flow rejestracji

```typescript
// tests/e2e/auth/register.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Rejestracja', () => {
  const uniqueEmail = `test+${Date.now()}@example.com`;

  test('pomyślna rejestracja', async ({ page }) => {
    await page.goto('/register');

    await page.getByLabel('Email').fill(uniqueEmail);
    await page.getByLabel('Hasło').fill('SecurePass123!');
    await page.getByRole('button', { name: /zarejestruj/i }).click();

    // Oczekuj komunikat o weryfikacji lub redirect
    await expect(
      page.getByText(/sprawdź.*email|potwierdź/i)
    ).toBeVisible({ timeout: 10_000 });
  });

  test('walidacja — krótkie hasło', async ({ page }) => {
    await page.goto('/register');

    await page.getByLabel('Email').fill('test@example.com');
    await page.getByLabel('Hasło').fill('123');
    await page.getByRole('button', { name: /zarejestruj/i }).click();

    await expect(page.getByText(/minimum|za krótkie/i)).toBeVisible();
  });

  test('walidacja — istniejący email', async ({ page }) => {
    await page.goto('/register');

    await page.getByLabel('Email').fill('existing@example.com');
    await page.getByLabel('Hasło').fill('SecurePass123!');
    await page.getByRole('button', { name: /zarejestruj/i }).click();

    await expect(page.getByText(/istnieje|already/i)).toBeVisible();
  });
});
```

### Flow CRUD z auth

```typescript
// tests/e2e/dashboard/dashboard.spec.ts
import { test, expect } from '@playwright/test';
import { DashboardPage } from '../../pages/dashboard.page';

test.describe('Dashboard (zalogowany)', () => {
  let dashboard: DashboardPage;

  test.beforeEach(async ({ page }) => {
    dashboard = new DashboardPage(page);
    await dashboard.goto();
  });

  test('wyświetla listę projektów', async ({ page }) => {
    await expect(dashboard.heading).toContainText(/dashboard|projekty/i);
  });

  test('tworzenie nowego projektu', async ({ page }) => {
    await page.getByRole('button', { name: /nowy|dodaj/i }).click();
    await page.getByLabel('Nazwa').fill('Projekt testowy');
    await page.getByRole('button', { name: /zapisz|utwórz/i }).click();

    await expect(page.getByText('Projekt testowy')).toBeVisible();
  });

  test('usuwanie projektu', async ({ page }) => {
    // Kliknij menu kontekstowe na pierwszym projekcie
    await page.getByTestId('project-menu').first().click();
    await page.getByRole('menuitem', { name: /usuń/i }).click();
    await page.getByRole('button', { name: /potwierdź/i }).click();

    // Oczekuj toast potwierdzenia
    await expect(page.getByText(/usunięto/i)).toBeVisible();
  });
});
```

## Integracja z CI/CD

### GitHub Actions

```yaml
# .github/workflows/e2e.yml
name: E2E Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  e2e:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 24
      - run: npm ci
      - run: npx playwright install --with-deps chromium

      - name: Run E2E tests
        run: npx playwright test
        env:
          BASE_URL: ${{ secrets.PREVIEW_URL || 'http://localhost:3000' }}
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_SERVICE_ROLE_KEY: ${{ secrets.SUPABASE_SERVICE_ROLE_KEY }}
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 7
```

### Skrypty w package.json

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:smoke": "playwright test tests/e2e/smoke.spec.ts",
    "test:e2e:debug": "playwright test --debug",
    "test:e2e:report": "playwright show-report"
  }
}
```

## Konwencje

### data-testid

Dodawaj `data-testid` do elementów, które testujesz:

```tsx
<button data-testid="submit-form">Zapisz</button>
<div data-testid="toast">{message}</div>
<div data-testid="project-menu">...</div>
```

Nie testuj po klasach CSS ani tagach — zmieniają się. `data-testid` jest stabilne.

### Selekcja elementów — priorytet

1. `getByRole()` — najlepszy (accessibility)
2. `getByLabel()` — formularze
3. `getByText()` — treść
4. `getByTestId()` — gdy powyższe nie działają

### Zmienne środowiskowe testowe

```env
# .env.test (NIE commituj!)
BASE_URL=http://localhost:3000
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...
TEST_USER_EMAIL=test@example.com
TEST_USER_PASSWORD=TestPassword123!
```

Dodaj do `.gitignore`:
```
tests/.auth/
.env.test
```

## Pułapki

1. **Service role key w frontendzie** → NIGDY! Używaj go tylko w helpers testowych (server-side)
2. **Hardcoded waits** → `await page.waitForTimeout(3000)` → ZŁE. Używaj `waitForSelector`, `waitForURL`, `expect().toBeVisible()`
3. **Brak cleanup** → testy tworzą dane i ich nie usuwają → śmieciowa baza → flaky testy
4. **Testowanie szczegółów implementacji** → testuj zachowanie użytkownika, nie wewnętrzny stan
5. **Za dużo testów E2E** → piramida testów: dużo unit, trochę integration, mało E2E. E2E tylko na krytyczne flow
6. **Brak izolacji** → testy zależą od siebie (test B wymaga danych z testu A) → flaky w parallel mode
