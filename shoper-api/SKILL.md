---
name: shoper-api
description: Integracja z Shoper REST API — automatyzacja contentu (news, produkty, zamówienia). Używaj gdy projekt klienta jest na platformie Shoper lub pytanie dotyczy API Shoper.
---

# Shoper REST API — Integracja

Skill do automatyzacji contentu i zarządzania sklepem na platformie Shoper.

## Kiedy używać

- "dodaj artykuł do Shopera"
- "zintegruj z Shoper"
- "automatyzacja contentu Shoper"
- Klient ma sklep na Shoper i potrzebuje automatyzacji

## Autentykacja

Shoper używa OAuth 2.0 Bearer Token:

```typescript
// 1. Pobranie tokenu
const tokenRes = await fetch('https://SKLEP.myshopery.com/webapi/rest/auth', {
  method: 'POST',
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({
    client_id: process.env.SHOPER_CLIENT_ID!,
    client_secret: process.env.SHOPER_CLIENT_SECRET!,
  }),
});
const { access_token } = await tokenRes.json();

// 2. Użycie tokenu
const headers = {
  'Authorization': `Bearer ${access_token}`,
  'Content-Type': 'application/json',
};
```

## Kluczowe endpointy

### News (artykuły/wpisy blogowe)

```typescript
// Lista newsów
GET /webapi/rest/news

// Dodaj news
POST /webapi/rest/news
{
  "translations": {
    "pl_PL": {
      "active": "1",          // "0" = draft, "1" = opublikowany
      "title": "Tytuł artykułu",
      "short_description": "Krótki opis",
      "description": "Pełna treść HTML",
      "seo_title": "SEO title",
      "seo_description": "Meta description",
      "seo_url": "url-slug"
    }
  },
  "date": "2026-04-04"
}

// Aktualizuj news
PUT /webapi/rest/news/{id}
```

### Produkty

```typescript
GET /webapi/rest/products              // Lista produktów
GET /webapi/rest/products/{id}         // Szczegóły produktu
PUT /webapi/rest/products/{id}         // Aktualizacja
POST /webapi/rest/products             // Nowy produkt
```

### Zamówienia

```typescript
GET /webapi/rest/orders                // Lista zamówień
GET /webapi/rest/orders/{id}           // Szczegóły
PUT /webapi/rest/orders/{id}           // Aktualizacja statusu
```

## Flow: AI → automatyzacja → Shoper

Typowy pipeline (np. z Make.com lub Supabase Edge Function):

1. **AI generuje treść** (artykuł, opis produktu)
2. **Webhook/cron** wysyła do Shoper API
3. **News z `active: "0"`** = draft do zatwierdzenia przez klienta
4. Klient zatwierdza w panelu Shoper → zmiana na `active: "1"`

### Wzorzec Supabase Edge Function

```typescript
// supabase/functions/shoper-publish/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

serve(async (req) => {
  const { title, content, shopUrl, accessToken } = await req.json();

  const res = await fetch(`https://${shopUrl}/webapi/rest/news`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      translations: {
        pl_PL: {
          active: '0', // draft — klient zatwierdza
          title,
          description: content,
          seo_title: title,
          seo_url: title.toLowerCase().replace(/\s+/g, '-'),
        },
      },
      date: new Date().toISOString().split('T')[0],
    }),
  });

  return new Response(JSON.stringify(await res.json()), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

## Zmienne środowiskowe

```
SHOPER_CLIENT_ID=         # Z panelu Shoper → Integracje → Aplikacje
SHOPER_CLIENT_SECRET=
SHOPER_SHOP_URL=          # np. mojsklep.myshopery.com
```

## Uwagi

- Rate limit: ~100 req/min (zależy od planu Shoper)
- Pole `active` to STRING ("0"/"1"), nie boolean
- Tłumaczenia zawsze w `translations.pl_PL` dla polskich sklepów
- API docs: panel Shoper → Integracje → Dokumentacja REST API
