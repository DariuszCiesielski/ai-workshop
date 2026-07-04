---
name: analytics-tracking
description: >
  Web analytics configuration: GA4, GTM, event tracking, UTM, conversion tracking.
  Triggers: "add analytics", "configure GA4", "tracking", "GTM", "event tracking",
  "UTM parameters", "conversion tracking", "analytics", "Google Analytics",
  "tags", "pixels", "measurement", "KPI tracking", "cookie consent", "RODO",
  "ePrivacy", "gtag undefined", "GA4 not tracking", "no hits in GA4",
  "Next.js GA4", "warunkowy GA4", "GA4 po zgodzie".
---

# Analytics Tracking — Web Analytics for SaaS

Configures a complete analytics stack: GA4, Google Tag Manager, event tracking, UTM, conversion tracking. Ensures measurability of marketing and product activities.

## When to Use

- GA4 + GTM setup in a new project
- Adding event tracking to an existing application
- Configuring conversion tracking (registration, purchase, trial)
- Creating a UTM system for campaigns
- Debugging missing events
- User says: "add analytics", "configure tracking", "conversion measurement"

## Dependencies

- **Optional:** `programmatic-seo` — keyword tracking, organic traffic analysis

## Tech Stack

### GA4 (Google Analytics 4)
- Event-based model (not session-based like UA)
- Enhanced Measurement: page_view, scroll, click, file_download, video_engagement
- Custom events: signup, purchase, trial_start, feature_used

### GTM (Google Tag Manager)
- Central tag management point
- Zero code changes after initial setup
- Preview mode for debugging

## Implementation Instructions

### Step 1: GTM Container Setup

```html
<!-- HEAD — as high as possible -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-XXXXXX');</script>

<!-- BODY — right after <body> -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-XXXXXX"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
```

#### Next.js App Router

```tsx
// app/layout.tsx
import Script from 'next/script';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <Script id="gtm" strategy="afterInteractive">
          {`(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
          new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
          j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
          'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
          })(window,document,'script','dataLayer','${process.env.NEXT_PUBLIC_GTM_ID}');`}
        </Script>
      </head>
      <body>{children}</body>
    </html>
  );
}
```

#### Vite / React SPA

```tsx
// src/lib/gtm.ts
export function initGTM(gtmId: string) {
  if (typeof window === 'undefined') return;
  
  window.dataLayer = window.dataLayer || [];
  window.dataLayer.push({ 'gtm.start': new Date().getTime(), event: 'gtm.js' });
  
  const script = document.createElement('script');
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtm.js?id=${gtmId}`;
  document.head.appendChild(script);
}

// src/main.tsx
initGTM(import.meta.env.VITE_GTM_ID);
```

#### Next.js + Cookie Consent — gotchas (verified 2026-04-12)

When loading GA4/GTM **conditionally after user consent** (RODO/ePrivacy compliant), the pattern from "Next.js App Router" above (Step 1) **DOES NOT WORK**. Three subtle bugs will silently break GA4 — `window.gtag` stays `undefined`, no hits sent, dataLayer empty:

**❌ Bug 1: Conditional `<Script>` with inline children breaks after hydration**

```tsx
// THIS IS BROKEN when rendered conditionally after state change
{consent === "all" && (
  <Script id="ga4-init" strategy="afterInteractive">
    {`
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('config', '${GA_ID}');
    `}
  </Script>
)}
```

**Symptom:** Console error `SyntaxError: Failed to execute 'appendChild' on 'Node': Invalid or unexpected token`. The external `gtag/js` script loads (200 OK), but the inline init script never runs, so `window.gtag` is undefined.

**Why:** Next.js `<Script>` with children dynamically mounted post-hydration corrupts the inline content during `appendChild`. Works fine when rendered on first load, breaks when toggled by state.

**✅ Fix:** Imperative injection in `useEffect`, NOT JSX `<Script>`:

```tsx
"use client";
import { useState, useEffect, useRef } from "react";

const GA_ID = process.env.NEXT_PUBLIC_GA_ID?.trim(); // ← .trim() — bug 3 below

declare global {
  interface Window {
    dataLayer?: unknown[];
  }
}

function loadGA4(id: string) {
  // Idempotent guard
  if (document.querySelector(`script[src*="gtag/js?id=${id}"]`)) return;

  // 1. External GTM script
  const script = document.createElement("script");
  script.src = `https://www.googletagmanager.com/gtag/js?id=${id}`;
  script.async = true;
  document.head.appendChild(script);

  // 2. gtag init — MUST use `arguments`, NOT rest params (bug 2 below)
  window.dataLayer = window.dataLayer || [];
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const gtag: (...args: any[]) => void = function () {
    // eslint-disable-next-line prefer-rest-params
    window.dataLayer!.push(arguments);
  };
  gtag("js", new Date());
  gtag("config", id, { anonymize_ip: true });

  (window as unknown as Record<string, unknown>).gtag = gtag;
}

export function CookieBanner() {
  const [consent, setConsent] = useState<"all" | "essential" | null>(null);
  const ga4Loaded = useRef(false);

  useEffect(() => {
    if (consent === "all" && GA_ID && !ga4Loaded.current) {
      loadGA4(GA_ID);
      ga4Loaded.current = true;
    }
  }, [consent]);

  // ... banner UI
}
```

**❌ Bug 2: `function gtag(...args)` instead of `function gtag()` with `arguments`**

```ts
// BROKEN — pushes plain Array, GA4 cannot parse it, NO hits sent
function gtag(...args: unknown[]) { dataLayer.push(args); }

// CORRECT — pushes Arguments object (array-like), GA4 parses it
function gtag() { dataLayer.push(arguments); }
```

**Why:** Google's gtag.js engine reads `dataLayer` entries expecting `Arguments` objects (array-like with special prototype). Plain arrays from rest params are silently ignored — `dataLayer` will look correct in DevTools but no `/g/collect` requests will fire. This is enforced by Google's parser, not negotiable.

**Detection:** `window.gtag` exists, `dataLayer` has entries, but **zero requests** to `region1.google-analytics.com/g/collect`. ESLint will yell about `prefer-rest-params` — disable the rule for this one function, it's intentional.

**❌ Bug 3: `process.env.NEXT_PUBLIC_*` may have trailing whitespace**

Next.js inlines `NEXT_PUBLIC_*` env vars at build time. Trailing newlines or spaces from `.env.local` end up in the bundle, breaking `querySelector(\`script[src*="...${id}"]\`)` and URL construction.

```ts
// ❌ may have hidden \n or whitespace
const GA_ID = process.env.NEXT_PUBLIC_GA_ID;

// ✅ always trim env vars used in selectors/URLs
const GA_ID = process.env.NEXT_PUBLIC_GA_ID?.trim();
```

#### Verification checklist (run in DevTools after accepting cookies)

```js
// 1. gtag must be a function
typeof window.gtag                              // → "function"

// 2. dataLayer must contain config + js entries (not just gtm.dom/gtm.load)
window.dataLayer.length                         // → 4+
JSON.stringify(window.dataLayer.slice(0, 5))    // → contains "config" and your G-ID

// 3. /g/collect request must fire to region1.google-analytics.com
performance.getEntriesByType("resource")
  .filter(e => e.name.includes("google-analytics"))
  .map(e => e.name)
// → at least one URL with tid=G-XXXXXXXXXX&en=page_view
```

If `gtag` is `function` but **no `/g/collect`** request → bug 2 (rest params instead of arguments).
If `gtag` is `undefined` and console shows `appendChild ... Invalid token` → bug 1 (conditional `<Script>`).
If everything looks right but `dl=` URL is mangled → bug 3 (untrimmed env var).

**Reference implementation:** `landing/src/components/cookie-banner.tsx` in project AI w Biznesie.

### Step 2: DataLayer Events

```typescript
// src/lib/analytics.ts

// Typed dataLayer
declare global {
  interface Window {
    dataLayer: Record<string, unknown>[];
  }
}

export function trackEvent(event: string, params?: Record<string, unknown>) {
  window.dataLayer?.push({ event, ...params });
}

// Predefined SaaS events
export const analytics = {
  // Registration and onboarding
  signup: (method: 'email' | 'google' | 'github') =>
    trackEvent('signup', { method }),
  
  onboardingStep: (step: number, stepName: string) =>
    trackEvent('onboarding_step', { step, step_name: stepName }),
  
  onboardingComplete: () =>
    trackEvent('onboarding_complete'),
  
  // Trial and payments
  trialStart: (plan: string) =>
    trackEvent('trial_start', { plan }),
  
  purchase: (plan: string, value: number, currency = 'USD') =>
    trackEvent('purchase', { plan, value, currency }),
  
  // Engagement
  featureUsed: (feature: string) =>
    trackEvent('feature_used', { feature_name: feature }),
  
  pageView: (pagePath: string, pageTitle: string) =>
    trackEvent('page_view', { page_path: pagePath, page_title: pageTitle }),
  
  // CTA and conversions
  ctaClick: (ctaId: string, ctaText: string, location: string) =>
    trackEvent('cta_click', { cta_id: ctaId, cta_text: ctaText, location }),
  
  formSubmit: (formName: string, success: boolean) =>
    trackEvent('form_submit', { form_name: formName, success }),
};
```

### Step 3: UTM Tracking

```typescript
// src/lib/utm.ts

interface UTMParams {
  utm_source: string;
  utm_medium: string;
  utm_campaign: string;
  utm_term?: string;
  utm_content?: string;
}

export function captureUTM(): UTMParams | null {
  const params = new URLSearchParams(window.location.search);
  const utm: Partial<UTMParams> = {};
  
  for (const key of ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content']) {
    const value = params.get(key);
    if (value) utm[key as keyof UTMParams] = value;
  }
  
  if (!utm.utm_source) return null;
  
  // Store in sessionStorage (survives navigation, doesn't survive tab close)
  sessionStorage.setItem('utm_params', JSON.stringify(utm));
  return utm as UTMParams;
}

export function getStoredUTM(): UTMParams | null {
  const stored = sessionStorage.getItem('utm_params');
  return stored ? JSON.parse(stored) : null;
}
```

#### UTM Naming Convention

| Parameter | Format | Examples |
|-----------|--------|----------|
| `utm_source` | platform | `google`, `linkedin`, `newsletter`, `facebook` |
| `utm_medium` | channel type | `cpc`, `social`, `email`, `organic`, `referral` |
| `utm_campaign` | campaign name | `launch-2026`, `black-friday`, `webinar-ai` |
| `utm_term` | keyword (ads) | `saas-crm`, `sales-automation` |
| `utm_content` | variant (A/B) | `hero-v1`, `cta-green`, `testimonial-short` |

### Step 4: Conversion Tracking in GTM

#### Events to configure in GTM:

| Event | Trigger | GA4 Tag | Conversion Type |
|-------|---------|---------|-----------------|
| `signup` | Custom Event: signup | GA4 Event | Key |
| `trial_start` | Custom Event: trial_start | GA4 Event | Key |
| `purchase` | Custom Event: purchase | GA4 Event + value | Key |
| `cta_click` | Custom Event: cta_click | GA4 Event | Supporting |
| `form_submit` | Custom Event: form_submit | GA4 Event | Supporting |
| `feature_used` | Custom Event: feature_used | GA4 Event | Engagement |

### Step 5: Debugging

```bash
# GTM Preview Mode
# 1. Open GTM → Preview → enter page URL
# 2. Check that tags fire on the correct triggers

# GA4 DebugView
# 1. GA4 → Admin → DebugView
# 2. Install the "Google Analytics Debugger" extension
# 3. Events will appear in real-time

# Browser console
window.dataLayer  # check what's in the dataLayer
```

## KPI Dashboard — SaaS Metrics

| Metric | GA4 Event | Description |
|--------|-----------|-------------|
| **Registrations** | `signup` | New users |
| **Activation** | `onboarding_complete` | Completed onboarding |
| **Trial → Paid** | `purchase` after `trial_start` | Trial conversion |
| **Feature Adoption** | `feature_used` | Which features are used |
| **Retention** | `session_start` (returning) | Are they coming back |
| **Revenue** | `purchase` with `value` | Revenue per plan |

## Implementation Checklist

- [ ] GTM container installed (HEAD + BODY)
- [ ] GA4 property connected to GTM
- [ ] DataLayer helper (`analytics.ts`) added to the project
- [ ] Key events implemented (signup, trial, purchase)
- [ ] UTM capture works on landing pages
- [ ] Conversions marked in GA4
- [ ] DebugView confirms event correctness
- [ ] `.env` contains `GTM_ID` (not hardcoded)

## Pitfalls

1. **GTM in `<body>` instead of `<head>`** → delayed pageview, data loss
2. **Missing `async`** on GTM script → blocks rendering
3. **Hardcoded GTM ID** → different environments = different containers
4. **No consent mode** → GDPR/ePrivacy violation in the EU
5. **Too many custom events** → GA4 limit of 500 distinct event names
6. **UTM in internal links** → overwrites source, breaks attribution
7. **Conditional `<Script>` post-hydration in Next.js** → silent breakage, `window.gtag` undefined. See "Next.js + Cookie Consent — gotchas" section.
8. **`function gtag(...args)` instead of `function gtag()` with `arguments`** → dataLayer fills, but no `/g/collect` requests. Google's parser requires the `Arguments` object.
9. **Untrimmed `process.env.NEXT_PUBLIC_*`** → trailing whitespace from `.env.local` breaks selectors and URLs. Always `?.trim()`.
