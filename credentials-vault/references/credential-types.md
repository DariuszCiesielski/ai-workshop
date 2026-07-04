# Rozpoznawane typy credentials

Referencja wzorców do automatycznego rozpoznawania i kategoryzowania credentials.

## Supabase (najczęstsze)

| Klucz | Wzorzec | Opis |
|-------|---------|------|
| `SUPABASE_URL` | `https://*.supabase.co` | URL projektu |
| `SUPABASE_ANON_KEY` | `eyJ...` (JWT, ~200 znaków) | Klucz anonimowy (publiczny) |
| `SUPABASE_SERVICE_ROLE_KEY` | `eyJ...` (JWT, ~200 znaków) | Klucz service role (NIGDY w kliencie!) |
| `SUPABASE_DB_PASSWORD` | dowolny string | Hasło do bazy Postgres |
| `SUPABASE_ACCESS_TOKEN` | `sbp_...` | Token CLI/API (Management API) |
| `SUPABASE_PROJECT_ID` | 20 znaków alfanumerycznych | ID projektu |
| `SUPABASE_JWT_SECRET` | base64 string | Secret do weryfikacji JWT |

## Klucze AI

| Klucz | Wzorzec | Uwagi |
|-------|---------|-------|
| `OPENAI_API_KEY` | `sk-proj-...` lub `sk-...` | Nowy format: `sk-proj-`, stary: `sk-` |
| `ANTHROPIC_API_KEY` | `sk-ant-...` | Klucz Anthropic |
| `GOOGLE_AI_KEY` | `AIza...` | Google AI / Gemini |
| `GOOGLE_AI_STUDIO_KEY` | `AIza...` | Google AI Studio |
| `XAI_API_KEY` | dowolny | xAI / Grok |
| `DEEPSEEK_API_KEY` | `sk-...` | DeepSeek |
| `MISTRAL_API_KEY` | dowolny | Mistral |
| `COHERE_API_KEY` | dowolny | Cohere |
| `PERPLEXITY_API_KEY` | `pplx-...` | Perplexity |

## Płatności

| Klucz | Wzorzec | Uwagi |
|-------|---------|-------|
| `STRIPE_SECRET_KEY` | `sk_live_...` / `sk_test_...` | Secret key (serwerowy) |
| `STRIPE_PUBLISHABLE_KEY` | `pk_live_...` / `pk_test_...` | Publishable (kliencki) |
| `STRIPE_WEBHOOK_SECRET` | `whsec_...` | Webhook signing secret |

## Email

| Klucz | Wzorzec |
|-------|---------|
| `RESEND_API_KEY` | `re_...` |
| `SENDGRID_API_KEY` | `SG.` + base64 |

## SEO / Dane

| Klucz | Wzorzec | Uwagi |
|-------|---------|-------|
| `DATAFORSEO_LOGIN` | email lub username | Login do DataForSEO API (nie klucz, lecz username) |
| `DATAFORSEO_PASSWORD` | dowolny string | Hasło do DataForSEO API |
| `TAVILY_API_KEY` | `tvly-...` | Tavily Search API |

## Automatyzacja / Scraping

| Klucz | Wzorzec |
|-------|---------|
| `APIFY_API_TOKEN` | `apify_api_...` |
| `FIRECRAWL_API_KEY` | `fc-...` |
| `BROWSERBASE_API_KEY` | dowolny |

## Audio / Voice

| Klucz | Wzorzec |
|-------|---------|
| `ELEVENLABS_API_KEY` | dowolny (32+ znaków hex) |

## CMS / Bazy danych

| Klucz | Wzorzec |
|-------|---------|
| `AIRTABLE_API_KEY` | `pat...` (Personal Access Token) |
| `SANITY_PROJECT_TOKEN` | `sk...` |
| `CONTENTFUL_ACCESS_TOKEN` | dowolny |
| `NEON_DATABASE_URL` | `postgresql://...@*.neon.tech/...` |

## Cloud / Hosting

| Klucz | Wzorzec |
|-------|---------|
| `CLOUDINARY_URL` | `cloudinary://API_KEY:API_SECRET@CLOUD_NAME` |
| `CLOUDINARY_API_KEY` | numeryczny string |
| `CLOUDINARY_API_SECRET` | alfanumeryczny string |
| `VERCEL_TOKEN` | dowolny |

## OAuth2 (pary)

| Klucz | Przykład |
|-------|---------|
| `FACEBOOK_APP_ID` + `FACEBOOK_APP_SECRET` | OAuth credentials |
| `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` | OAuth credentials |
| `LINKEDIN_CLIENT_ID` + `LINKEDIN_CLIENT_SECRET` | OAuth credentials |
| `GITHUB_CLIENT_ID` + `GITHUB_CLIENT_SECRET` | OAuth credentials |

## Social Media

| Klucz | Wzorzec |
|-------|---------|
| `POSTIZ_API_KEY` | dowolny |
| `TWITTER_API_KEY` | dowolny |
| `TWITTER_API_SECRET` | dowolny |
| `TWITTER_BEARER_TOKEN` | dowolny |
