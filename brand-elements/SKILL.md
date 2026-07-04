---
name: brand-elements
description: Globalne elementy marki — favicon (wieloformatowy), komponent Footer (3 warianty), wzorce brandingu. Używaj przy dodawaniu faviconu, stopki, praw autorskich lub elementów marki do aplikacji webowych.
---

# Brand Elements

## Opis

Globalne elementy marki do stosowania we wszystkich aplikacjach webowych. Zawiera:
- Konfigurację favicon (ikona w zakładce przeglądarki)
- Komponent Footer (stopka z prawami autorskimi)
- Wzorce dla spójnego brandingu

## Triggery

- "dodaj favicon"
- "dodaj stopkę"
- "brand elements"
- "elementy marki"
- "footer"
- "prawa autorskie"
- "ikona strony"

## Zależności

Brak - czysty React + Tailwind CSS

---

## 1. Favicon - konfiguracja

### Pliki favicon

Umieść pliki w folderze `public/`:

```
public/
├── favicon.ico          # 32x32 lub 16x16, klasyczny format
├── favicon-32x32.png    # 32x32 PNG
├── favicon-16x16.png    # 16x16 PNG
├── apple-touch-icon.png # 180x180 dla iOS
├── android-chrome-192x192.png  # 192x192 dla Android
├── android-chrome-512x512.png  # 512x512 dla Android
└── site.webmanifest     # Manifest PWA
```

### index.html

```html
<!DOCTYPE html>
<html lang="pl">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <!-- Favicon -->
    <link rel="icon" type="image/x-icon" href="/favicon.ico" />
    <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
    <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
    <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
    <link rel="manifest" href="/site.webmanifest" />

    <!-- Meta tagi marki -->
    <meta name="theme-color" content="#0f172a" />
    <meta name="msapplication-TileColor" content="#0f172a" />

    <title>Nazwa Aplikacji</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### site.webmanifest

```json
{
  "name": "Nazwa Aplikacji",
  "short_name": "App",
  "icons": [
    {
      "src": "/android-chrome-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/android-chrome-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "theme_color": "#0f172a",
  "background_color": "#0f172a",
  "display": "standalone"
}
```

### Generowanie favicon

Użyj narzędzia online do wygenerowania wszystkich rozmiarów:
- **realfavicongenerator.net** - generuje wszystkie formaty
- **favicon.io** - prosty generator z PNG/SVG

---

## 2. Komponent Footer

### components/Footer.tsx

```typescript
import React from 'react';

interface FooterProps {
  companyName?: string;
  year?: number;
  className?: string;
}

const Footer: React.FC<FooterProps> = ({
  companyName = 'Dariusz Ciesielski - Marketing Ekspercki',
  year = new Date().getFullYear(),
  className = ''
}) => {
  return (
    <footer
      className={`py-2 text-center text-xs flex-shrink-0 border-t ${className}`}
      style={{
        backgroundColor: 'var(--bg-primary)',
        borderColor: 'var(--border-primary)',
        color: 'var(--text-muted)',
      }}
    >
      Wszystkie prawa zastrzeżone: {companyName}, {year}.
    </footer>
  );
};

export default Footer;
```

### Użycie

```tsx
import Footer from './components/Footer';

function App() {
  return (
    <div className="min-h-screen flex flex-col">
      <main className="flex-1">
        {/* Treść aplikacji */}
      </main>
      <Footer />
    </div>
  );
}
```

### Warianty stopki

#### Minimalna (tylko rok)

```tsx
<Footer companyName="Nazwa Firmy" />
// Wynik: "Wszystkie prawa zastrzeżone: Nazwa Firmy, 2026."
```

#### Z linkami

```typescript
import React from 'react';

interface FooterLink {
  label: string;
  href: string;
}

interface FooterWithLinksProps {
  companyName?: string;
  year?: number;
  links?: FooterLink[];
}

const FooterWithLinks: React.FC<FooterWithLinksProps> = ({
  companyName = 'Dariusz Ciesielski - Marketing Ekspercki',
  year = new Date().getFullYear(),
  links = []
}) => {
  return (
    <footer
      className="py-4 text-center text-xs flex-shrink-0 border-t"
      style={{
        backgroundColor: 'var(--bg-primary)',
        borderColor: 'var(--border-primary)',
        color: 'var(--text-muted)',
      }}
    >
      <div className="flex flex-col sm:flex-row items-center justify-center gap-2 sm:gap-4">
        <span>© {year} {companyName}</span>
        {links.length > 0 && (
          <div className="flex gap-4">
            {links.map((link, i) => (
              <a
                key={i}
                href={link.href}
                className="hover:underline"
                style={{ color: 'var(--text-secondary)' }}
              >
                {link.label}
              </a>
            ))}
          </div>
        )}
      </div>
    </footer>
  );
};

export default FooterWithLinks;
```

Użycie z linkami:

```tsx
<FooterWithLinks
  links={[
    { label: 'Polityka prywatności', href: '/privacy' },
    { label: 'Regulamin', href: '/terms' },
    { label: 'Kontakt', href: '/contact' },
  ]}
/>
```

#### Z logo

```typescript
import React from 'react';

interface FooterWithLogoProps {
  companyName?: string;
  year?: number;
  logoSrc?: string;
  logoAlt?: string;
}

const FooterWithLogo: React.FC<FooterWithLogoProps> = ({
  companyName = 'Dariusz Ciesielski - Marketing Ekspercki',
  year = new Date().getFullYear(),
  logoSrc,
  logoAlt = 'Logo'
}) => {
  return (
    <footer
      className="py-4 border-t"
      style={{
        backgroundColor: 'var(--bg-primary)',
        borderColor: 'var(--border-primary)',
        color: 'var(--text-muted)',
      }}
    >
      <div className="flex flex-col items-center gap-3">
        {logoSrc && (
          <img
            src={logoSrc}
            alt={logoAlt}
            className="h-8 w-auto opacity-70"
          />
        )}
        <p className="text-xs">
          © {year} {companyName}. Wszelkie prawa zastrzeżone.
        </p>
      </div>
    </footer>
  );
};

export default FooterWithLogo;
```

---

## 3. Layout z Footer

### Wzorzec sticky footer

Footer zawsze na dole strony, nawet gdy treść jest krótka:

```tsx
function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="flex-shrink-0">
        {/* ... */}
      </header>

      {/* Main content - rośnie, wypychając footer na dół */}
      <main className="flex-1">
        {children}
      </main>

      {/* Footer - zawsze na dole */}
      <Footer />
    </div>
  );
}
```

### Wzorzec z sidebar

```tsx
function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex">
      {/* Sidebar */}
      <aside className="w-64 flex-shrink-0">
        {/* ... */}
      </aside>

      {/* Główna część z footer */}
      <div className="flex-1 flex flex-col">
        <header>{/* ... */}</header>
        <main className="flex-1 p-6">{children}</main>
        <Footer />
      </div>
    </div>
  );
}
```

---

## 4. CSS Variables dla brandingu

Jeśli używasz systemu motywów (`unified-design-system`), Footer automatycznie używa CSS custom properties:

```css
/* Zmienne używane przez Footer */
--bg-primary      /* tło stopki */
--border-primary  /* kolor obramowania górnego */
--text-muted      /* kolor tekstu */
--text-secondary  /* kolor linków */
```

Bez systemu motywów - ustaw zmienne globalnie lub użyj Tailwind:

```tsx
// Bez CSS variables - Tailwind
<footer className="py-2 text-center text-xs bg-slate-50 border-t border-slate-200 text-slate-500">
  © {year} {companyName}
</footer>
```

---

## Pułapki

### 1. Favicon w `/src/` zamiast `/public/`

Vite/CRA nie kopiują plików z `src/` do roota builda. Favicon musi leżeć w `public/`.

❌ `src/assets/favicon.ico` → plik nie trafia do roota, przeglądarka go nie znajdzie
✅ `public/favicon.ico` → dostępny jako `/favicon.ico` po buildzie

### 2. Brak `apple-touch-icon` — Safari/iOS ignoruje zwykły favicon

Safari na iOS nie czyta `<link rel="icon">`. Bez dedykowanego `apple-touch-icon` użytkownik zobaczy generyczny screenshot strony po dodaniu do ekranu głównego.

❌ Tylko `<link rel="icon" href="/favicon.ico" />`
✅ Dodaj osobno: `<link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />`

### 3. SVG favicon bez fallbacka ICO

SVG favicon (`<link rel="icon" type="image/svg+xml">`) nie działa w Safari < 15.4 i starszych przeglądarkach. Zawsze dodawaj fallback `.ico` PRZED deklaracją SVG — przeglądarka użyje pierwszego obsługiwanego formatu.

### 4. `position: fixed` na Footer przykrywa treść na krótkich stronach

Nigdy nie dawaj Footerowi `position: fixed/sticky` na dole ekranu. Zamiast tego użyj wzorca flexbox z `min-h-screen flex flex-col` na kontenerze i `flex-1` na `<main>` — footer naturalnie spada na dół bez przykrywania treści.

❌ `<footer className="fixed bottom-0 w-full">` → przykrywa ostatnie elementy main
✅ Kontener `min-h-screen flex flex-col` + main `flex-1` + footer bez fixed

### 5. Rok w copyright hardcoded

Hardcoded rok (`© 2026`) staje się nieaktualny 1 stycznia. Zawsze generuj dynamicznie.

❌ `<footer>© 2026 Firma</footer>`
✅ `<footer>© {new Date().getFullYear()} Firma</footer>`

### 6. Ścieżki w `site.webmanifest` bez leadingu `/`

Względne ścieżki w manifeście (`"src": "android-chrome-192x192.png"`) łamią się gdy manifest jest serwowany z innej ścieżki lub przez CDN. Zawsze używaj ścieżek bezwzględnych.

❌ `"src": "android-chrome-192x192.png"`
✅ `"src": "/android-chrome-192x192.png"`

### 7. Brak `aria-label` na linkach social media w footerze

Ikony social media (SVG/emoji) bez tekstu nie mają dostępnej nazwy. Screen readery odczytają sam URL lub nic.

❌ `<a href="https://twitter.com/x"><TwitterIcon /></a>`
✅ `<a href="https://twitter.com/x" aria-label="Twitter"><TwitterIcon /></a>`

### 8. Next.js: favicon w `public/` zamiast App Router `app/icon.*`

W Next.js 13+ z App Routerem zalecane jest umieszczenie `favicon.ico` w `app/favicon.ico` (a `apple-icon.png` w `app/apple-icon.png`). Next automatycznie generuje tagi `<link>`. Ręczne dodawanie w `layout.tsx` przez `<Head>` jest niepotrzebne i może powodować duplikaty.

❌ Plik w `public/favicon.ico` + ręczne `<link>` w layout
✅ `app/favicon.ico` + `app/apple-icon.png` → Next generuje tagi automatycznie

---

## 5. Checklist implementacji

### Favicon

1. [ ] Wygeneruj favicon w różnych rozmiarach (realfavicongenerator.net)
2. [ ] Umieść pliki w folderze `public/`
3. [ ] Dodaj tagi `<link>` do `index.html`
4. [ ] Utwórz `site.webmanifest` dla PWA
5. [ ] Ustaw `theme-color` na kolor marki
6. [ ] Przetestuj w różnych przeglądarkach

### Footer

1. [ ] Utwórz `components/Footer.tsx`
2. [ ] Dodaj do głównego layoutu aplikacji
3. [ ] Upewnij się że używa CSS variables z systemu motywów
4. [ ] Przetestuj sticky footer (krótka treść)
5. [ ] Zaktualizuj rok i nazwę firmy

---

## 6. Dane marki (dostosuj do projektu)

```typescript
// config/brand.ts
export const BRAND = {
  companyName: 'Dariusz Ciesielski - Marketing Ekspercki',
  shortName: 'Marketing Ekspercki',
  year: new Date().getFullYear(),
  themeColor: '#0f172a',  // slate-900
  email: 'kontakt@example.com',
  website: 'https://example.com',
} as const;
```

Użycie:

```tsx
import { BRAND } from '../config/brand';

<Footer companyName={BRAND.companyName} year={BRAND.year} />
```
