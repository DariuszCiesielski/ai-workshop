---
name: schema-markup
description: >
  JSON-LD structured data per typ strony — generowanie, walidacja, rich snippets.
  Organization, Product, Article, BreadcrumbList, FAQ (ograniczone), VideoObject.
  Triggery: "schema markup", "JSON-LD", "structured data", "dane strukturalne",
  "rich snippets", "schema", "dodaj schema", "structured data audit".
---

# Schema Markup — JSON-LD Generator & Validator

Generuje i waliduje schema markup (JSON-LD) dla stron SaaS. Pokrywa wszystkie aktywne typy rich results w Google (2026).

## Kiedy używać

- Dodajesz structured data do strony
- Audyt istniejącego schema markup
- Generowanie JSON-LD per typ strony
- Walidacja przed wdrożeniem
- Użytkownik mówi: "dodaj schema", "JSON-LD", "rich snippets"

## Typy schema wg strony

### Homepage
- **Organization** — name, url, logo, sameAs (social profiles), contactPoint
- **WebSite** — name, url, potentialAction (SearchAction jeśli strona ma wyszukiwarkę)

### Pricing Page
- **Product** — name, description, brand
- **Offer** (per plan) — name, price, priceCurrency (PLN), priceValidUntil, availability

### Blog Post
- **Article** — headline, description, image, author (Person), publisher (Organization), datePublished, dateModified

### Każda podstrona
- **BreadcrumbList** — hierarchia nawigacji (position 1: Home → position 2: Sekcja → position 3: Strona)

### Video (jeśli embed)
- **VideoObject** — name, description, thumbnailUrl, uploadDate, duration (format PT), contentUrl, embedUrl

### SaaS (opcjonalnie)
- **SoftwareApplication** — name, applicationCategory, operatingSystem, offers, aggregateRating (TYLKO jeśli masz recenzje)

## Deprecated / ograniczone (NIE generuj)

| Typ | Status | Od kiedy |
|-----|--------|----------|
| **FAQPage** | Ograniczone do rządowych/medycznych | Sierpień 2023 |
| **HowTo** | Wyłączone | Wrzesień 2023 |
| **Speakable** | Beta, niestabilne | — |

## Implementacja

### Next.js App Router
Umieść JSON-LD w `<script type="application/ld+json">` w komponencie strony. Użyj `JSON.stringify()` do serializacji obiektu. Ważne: schema w initial HTML (SSR) > schema dodane przez JS client-side.

### Statyczny HTML
Dodaj `<script type="application/ld+json">` w `<head>` lub na początku `<body>`.

## Walidacja

Po wygenerowaniu:
1. Sprawdź wymagane pola per typ (patrz schema.org)
2. Waliduj JSON syntax
3. Sprawdź URL-e (czy istnieją, czy https)
4. Zaproponuj test w Google Rich Results Test

## Checklist per strona

| Strona | Schema wymagane | Schema opcjonalne |
|--------|----------------|-------------------|
| Homepage | Organization, WebSite | SoftwareApplication |
| Blog post | Article, BreadcrumbList | — |
| Pricing | Product + Offer, BreadcrumbList | AggregateRating |
| Feature page | BreadcrumbList | — |
| About | Organization, BreadcrumbList | Person (founder) |
| Docs | BreadcrumbList | — |
| Video page | VideoObject, BreadcrumbList | — |

## Cross-references

- `seo` → `references/schema-types.md` (pełna lista typów)
- `product-marketing-context` → dane do wypełnienia schema (nazwa, opis, ceny)
- `seo` → `/seo schema <url>` komenda do audytu schema

## Pułapki

- **NIE dodawaj FAQ schema** do stron biznesowych — Google ignoruje od 2023
- **NIE używaj HowTo** — deprecated
- **Zawsze testuj** w Rich Results Test przed wdrożeniem
- **Schema w `<head>`** lub na początku `<body>` — nie na końcu strony
- **Nie duplikuj** — 1 Organization per stronę, nie na każdej podstronie
- **aggregateRating** — TYLKO jeśli masz prawdziwe recenzje na stronie
