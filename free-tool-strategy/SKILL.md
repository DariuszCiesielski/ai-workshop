---
name: free-tool-strategy
description: >
  Engineering as marketing: darmowe narzędzia (kalkulatory, generatory, checklisty) jako lead magnets.
  Triggery: "darmowe narzędzie", "kalkulator", "generator", "lead magnet", "free tool",
  "engineering as marketing", "narzędzie marketingowe", "kalkulator ROI",
  "darmowy audyt", "interaktywne narzędzie", "widget", "embed".
---

# Free Tool Strategy — Darmowe narzędzia jako marketing SaaS

Strategia "Engineering as Marketing" — budowanie prostych, darmowych narzędzi online (kalkulatory, generatory, checklisty), które przyciągają ruch organiczny, zbierają leady i budują autorytet.

## Kiedy używać

- Planowanie lead magnet strategy
- Budowanie kalkulatora ROI, generatora, checklisty
- Wybór tematu na darmowe narzędzie
- Optymalizacja istniejącego narzędzia pod SEO i konwersje
- Użytkownik mówi: "zróbmy kalkulator", "potrzebuję lead magnet", "darmowe narzędzie na stronę"

## Zależności

- **Wymagane:** `product-marketing-context` → `features.md`, `target-keywords.md`
- **Opcjonalne:** `seo` → keyword research dla narzędzi
- **Opcjonalne:** `page-cro` → optymalizacja strony narzędzia
- **Opcjonalne:** `analytics-tracking` → mierzenie użycia i konwersji
- **Opcjonalne:** `schema-markup` → SoftwareApplication schema

## Typy darmowych narzędzi

| Typ | Przykład | Trudność | SEO potential | Lead capture |
|-----|---------|----------|---------------|-------------|
| **Kalkulator** | ROI calculator, cennik, oszczędności | Średnia | ★★★★★ | Email za wynik |
| **Generator** | Generator nagłówków, nazw firm, polityk | Łatwa | ★★★★ | Email za export |
| **Checker/Audytor** | SEO checker, speed test, accessibility | Trudna | ★★★★★ | Email za raport |
| **Porównywarka** | Porównanie planów, narzędzi, technologii | Średnia | ★★★★ | Inline CTA |
| **Template/Szablon** | Spreadsheet, dokument, Notion template | Łatwa | ★★★ | Email za download |
| **Interaktywny quiz** | "Które narzędzie dla Ciebie?", assessment | Średnia | ★★★ | Email za wynik |
| **Konwerter** | Format plików, jednostki, waluty | Łatwa | ★★★★★ | Ads / CTA |

## Framework wyboru narzędzia

### Krok 1: Zidentyfikuj problem bliski Twojemu produktowi

```
Twój produkt: [co robi]
↓
Jaki problem rozwiązujesz? [ból klienta]
↓
Jaką CZĘŚĆ tego problemu można rozwiązać prostym narzędziem?
↓
To jest Twoje darmowe narzędzie
```

**Przykłady:**

| Produkt | Problem klienta | Darmowe narzędzie |
|---------|----------------|-------------------|
| CRM | "Nie wiem ile tracę na brak follow-upów" | Kalkulator utraconych leadów |
| SEO tool | "Nie wiem jak moja strona wypada" | Darmowy mini-audyt SEO |
| Email marketing | "Nie wiem kiedy wysyłać" | Kalkulator najlepszej godziny |
| Automation | "Ile czasu marnuję na ręczną pracę?" | Kalkulator ROI automatyzacji |
| Invoicing | "Ile kosztuje mnie fakturowanie?" | Kalkulator kosztu fakturowania |

### Krok 2: Walidacja potencjału

Sprawdź przed budowaniem:

1. **Keyword volume:** czy ludzie szukają? (np. "kalkulator ROI" — ile wyszukiwań/mies)
2. **Konkurencja:** czy istnieje podobne narzędzie? Jeśli tak — czy możesz zrobić lepsze?
3. **Proximity:** czy narzędzie naturalnie prowadzi do Twojego produktu?
4. **Effort:** czy zbudujesz to w 1-3 dni? (nie w 3 miesiące)

### Krok 3: Budowa (MVP)

```
Faza 1 (dzień 1): Core functionality
- Formularz z 3-5 polami
- Obliczenie / generowanie wyniku
- Wyświetlenie wyniku na stronie

Faza 2 (dzień 2): Lead capture
- Gate wynik za email (lub pokaż basic, full za email)
- CTA do głównego produktu pod wynikiem
- Social sharing buttons

Faza 3 (dzień 3): SEO + polish
- Dedykowana strona /narzedzia/[nazwa]
- Meta tags, schema markup
- Content wokół narzędzia (jak używać, metodologia)
```

## Architektura techniczna

### Prosty kalkulator (React)

```tsx
// app/narzedzia/kalkulator-roi/page.tsx
'use client';

import { useState } from 'react';

interface Inputs {
  hoursPerWeek: number;
  hourlyRate: number;
  weeksPerYear: number;
  automationPercent: number;
}

export default function ROICalculator() {
  const [inputs, setInputs] = useState<Inputs>({
    hoursPerWeek: 10,
    hourlyRate: 150,
    weeksPerYear: 48,
    automationPercent: 60,
  });
  const [showResult, setShowResult] = useState(false);

  const annualCost = inputs.hoursPerWeek * inputs.hourlyRate * inputs.weeksPerYear;
  const savings = annualCost * (inputs.automationPercent / 100);

  return (
    <div className="max-w-2xl mx-auto p-8">
      <h1 className="text-3xl font-bold mb-2">
        Kalkulator ROI automatyzacji
      </h1>
      <p className="text-muted-foreground mb-8">
        Oblicz ile zaoszczędzisz automatyzując powtarzalne zadania.
      </p>

      <div className="space-y-6">
        {/* Pola formularza — slider + input */}
        <Field
          label="Godzin tygodniowo na ręczne zadania"
          value={inputs.hoursPerWeek}
          onChange={(v) => setInputs({ ...inputs, hoursPerWeek: v })}
          min={1} max={40} unit="h"
        />
        {/* ... kolejne pola ... */}

        <button onClick={() => setShowResult(true)}
          className="w-full py-3 bg-primary text-primary-foreground rounded-lg">
          Oblicz oszczędności →
        </button>
      </div>

      {showResult && (
        <div className="mt-8 p-6 bg-green-50 rounded-lg">
          <p className="text-lg">Roczna oszczędność:</p>
          <p className="text-4xl font-bold text-green-600">
            {savings.toLocaleString('pl-PL')} zł
          </p>
          <p className="mt-4 text-sm text-muted-foreground">
            To {Math.round(savings / inputs.hourlyRate)} godzin, które możesz
            przeznaczyć na rozwój firmy.
          </p>

          {/* CTA do produktu */}
          <div className="mt-6 p-4 border rounded-lg">
            <p className="font-medium">
              [Produkt] automatyzuje te zadania od 49 zł/mies.
            </p>
            <a href="/trial" className="mt-2 inline-block underline">
              Zacznij 14-dniowy trial →
            </a>
          </div>
        </div>
      )}
    </div>
  );
}
```

### Lead capture — wzorce

#### Wzorzec A: Gated result (wynik za email)
```
Użytkownik wypełnia formularz → "Podaj email, wyślemy pełny raport"
Pro: Wysoki capture rate (30-50%)
Con: Część odchodzi, gorszy UX
```

#### Wzorzec B: Partial reveal (basic free, full za email)
```
Pokaż wynik podstawowy → "Chcesz szczegółową analizę? Podaj email"
Pro: Lepszy UX, użytkownik widzi wartość
Con: Niższy capture rate (10-20%)
```

#### Wzorzec C: No gate (free + CTA)
```
Pełny wynik za darmo → CTA do produktu pod wynikiem
Pro: Najlepszy UX, SEO, sharing
Con: Brak emaili, ale najlepszy top-of-funnel
```

**Rekomendacja:** Zacznij od C (max SEO), dodaj B gdy masz ruch.

## SEO dla narzędzi

### URL structure:
```
/narzedzia/kalkulator-roi-automatyzacji
/narzedzia/generator-nagłówków
/narzedzia/audyt-seo-za-darmo
```

### Content wokół narzędzia:
```
1. Strona narzędzia (interactive) — target keyword: "kalkulator ROI"
2. Blog post "Jak obliczyć ROI automatyzacji" — long-tail
3. FAQ pod narzędziem — "ile kosztuje automatyzacja", "co automatyzować"
```

### Schema markup:
```json
{
  "@type": "SoftwareApplication",
  "name": "Kalkulator ROI automatyzacji",
  "applicationCategory": "BusinessApplication",
  "offers": { "@type": "Offer", "price": "0" },
  "operatingSystem": "Web"
}
```

## Dystrybucja narzędzia

| Kanał | Jak | Kiedy |
|-------|-----|-------|
| SEO | Dedykowana strona + content cluster | Od dnia 1 |
| Product Hunt | Launch jako "Free tool" | Po polish |
| LinkedIn | Post z case study użycia | Tydzień 2 |
| Reddit | Wartościowy post w r/[branża] | Ostrożnie |
| Directories | Free tools directories, listicles | Miesiąc 1 |
| Embeds | Widget do osadzenia na blogach | Jeśli sens ma |
| Partnerships | Cross-promo z komplementarnymi narzędziami | Miesiąc 2+ |

## Metryki sukcesu

| Metryka | Target | Narzędzie |
|---------|--------|-----------|
| Unique users/mies | 500+ (po 3 mies) | GA4 |
| Avg. time on page | > 2 min | GA4 |
| Completion rate | > 60% (rozpoczęte → wynik) | Custom event |
| Email capture rate | 10-30% (zależnie od gate) | Custom event |
| CTA click rate | > 5% | Custom event |
| Organic keywords | 20+ ranked | Search Console |

## Pułapki

1. **Za skomplikowane narzędzie** → MVP w 1-3 dni, nie 3 miesiące. Prostota = użycie.
2. **Brak CTA** → narzędzie bez linku do produktu = stracona okazja
3. **Hard gate na start** → bez ruchu nie masz co gate'ować. Zacznij free.
4. **Brak SEO** → narzędzie bez dedykowanej strony i contentu nie rankuje
5. **Oderwane od produktu** → kalkulator BMI dla CRM? Narzędzie musi być blisko produktu.
