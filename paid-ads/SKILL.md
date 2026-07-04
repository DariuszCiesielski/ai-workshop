---
name: paid-ads
description: >
  Kampanie reklamowe: Google Ads, Meta Ads, LinkedIn Ads. Copy, targeting, budżet, ROAS.
  Triggery: "kampania reklamowa", "Google Ads", "Facebook Ads", "Meta Ads", "LinkedIn Ads",
  "reklama", "paid media", "PPC", "CPC", "ROAS", "budżet reklamowy",
  "targetowanie", "remarketing", "retargeting", "kreacja reklamowa".
---

# Paid Ads — Kampanie reklamowe SaaS

Planuje i optymalizuje kampanie reklamowe na Google Ads, Meta Ads i LinkedIn Ads. Copy, targeting, struktura kampanii, budżety, ROAS tracking.

## Kiedy używać

- Planowanie nowej kampanii reklamowej
- Tworzenie copy do reklam (headlines, descriptions)
- Setup targetowania (audiences, keywords)
- Optymalizacja istniejących kampanii (ROAS, CPA)
- Strategia budżetowa per kanał
- Użytkownik mówi: "uruchom reklamy", "kampania Google Ads", "budżet na reklamy"

## Zależności

- **Wymagane:** `product-marketing-context` → `features.md`, `competitor-analysis.md`
- **Opcjonalne:** `copywriting` → formuły (PAS, AIDA) do copy reklam
- **Opcjonalne:** `analytics-tracking` → conversion tracking, UTM
- **Opcjonalne:** `page-cro` → optymalizacja landing page pod reklamy
- **Opcjonalne:** `ads-auditor` → audyt istniejących kampanii
- **Powiązane:** `sales-context` → ICP i value proposition do targetowania

## Google Ads

### Typy kampanii SaaS:

| Typ | Kiedy | Budget min. | CPC typowy |
|-----|-------|-------------|------------|
| **Search** | Intencja zakupowa | 2000 zł/mies | 2-15 zł |
| **Performance Max** | Skalowanie | 3000 zł/mies | 1-8 zł |
| **Display remarketing** | Retargeting | 500 zł/mies | 0.5-3 zł |
| **YouTube** | Awareness | 1500 zł/mies | 0.05-0.30 zł/view |

### Struktura kampanii Search:

```
Kampania: [Produkt] - Search - [Język]
├── Ad Group: Brand keywords
│   ├── Keywords: "NazwaProduktu", "NazwaProduktu cennik"
│   └── Ads: brand protection ads
├── Ad Group: Problem keywords  
│   ├── Keywords: "automatyzacja sprzedaży", "CRM dla małych firm"
│   └── Ads: problem → solution ads
├── Ad Group: Solution keywords
│   ├── Keywords: "narzędzie do leadów", "software do ofert"
│   └── Ads: feature-focused ads
└── Ad Group: Competitor keywords
    ├── Keywords: "alternatywa dla [Konkurent]", "[Konkurent] vs"
    └── Ads: comparison ads
```

### Copy Google Ads:

**Responsive Search Ad (RSA):**
- 15 nagłówków (max 30 znaków każdy)
- 4 opisy (max 90 znaków każdy)

#### Nagłówki — formuły:

| Pozycja | Formuła | Przykład |
|---------|---------|---------|
| H1 | Benefit główny | "Automatyzuj sprzedaż w 5 min" |
| H2 | Social proof | "2 500+ firm w Polsce" |
| H3 | CTA | "Zacznij za darmo" |
| H4 | Feature | "Bez kodowania" |
| H5 | Urgency | "14 dni free trial" |
| H6 | Price anchor | "Od 49 zł/mies" |
| H7 | Competitor | "Lepsza alternatywa dla X" |

#### Opisy:

```
D1: [Benefit] + [Feature] + [CTA]
"Zwiększ sprzedaż o 40% dzięki automatyzacji ofert. Bez karty kredytowej. Zacznij teraz."

D2: [Social proof] + [Feature] + [Differentiator]  
"Zaufało nam 2500+ firm. Integracja z CRM w 2 min. Jedyne narzędzie z AI w polskiej cenie."
```

### Keywords — match types:

| Match type | Syntax | Kiedy |
|------------|--------|-------|
| Exact | [automatyzacja sprzedaży] | High intent, kontrola |
| Phrase | "narzędzie do leadów" | Balanced |
| Broad | automatyzacja ofert | Discovery (z Smart Bidding) |

**Negative keywords (obowiązkowe):**
```
darmowy, za darmo, kurs, tutorial, co to jest, definicja,
praca, rekrutacja, staż, praktyki, pdf, książka, referat
```

## Meta Ads (Facebook + Instagram)

### Typy kampanii:

| Cel | Kiedy | Budget min. | CPM typowy |
|-----|-------|-------------|------------|
| **Conversions** | Lead gen, signup | 2000 zł/mies | 15-40 zł |
| **Traffic** | Blog, content | 500 zł/mies | 5-15 zł |
| **Engagement** | Social proof | 300 zł/mies | 3-10 zł |
| **Retargeting** | Warm audiences | 500 zł/mies | 10-25 zł |

### Struktura kampanii:

```
Kampania: [Produkt] - Conversions
├── Ad Set: Lookalike 1% (klienci)
│   ├── Budget: 60% budżetu
│   └── Ads: 3-4 warianty
├── Ad Set: Interest targeting
│   ├── Budget: 25% budżetu
│   └── Ads: 3-4 warianty
└── Ad Set: Retargeting (website visitors)
    ├── Budget: 15% budżetu
    └── Ads: 2-3 warianty (social proof focus)
```

### Copy Meta Ads:

#### Formuła PRIMARY TEXT (125 znaków above fold):

```
HOOK: [Ból odbiorcy — pytanie lub statement]

BODY: [Rozwiązanie — 2-3 zdania]

CTA: [Co zrobić — link lub instrukcja]

---

Przykład:
"Tracisz godziny na ręczne oferty? 

[Produkt] automatyzuje cały proces — od leada do podpisanej umowy. 
Bez kodowania, setup w 5 minut.

→ Zacznij 14-dniowy trial za darmo"
```

#### Kreacje reklamowe (ad creatives):

| Format | Rozmiar | CTR benchmark |
|--------|---------|---------------|
| Single image | 1080x1080 (1:1) | 1.5-3% |
| Karuzela | 1080x1080 per card | 2-4% |
| Video 15s | 1080x1920 (9:16) | 3-6% |
| Collection | mixed | 2-5% |

**Zasady kreacji:**
- Twarz > grafika (2x CTR)
- Tekst na obrazie < 20% powierzchni
- Pierwsze 3 sekundy = hook (video)
- Kontrastowy CTA button
- Mobile-first (85% ruchu Meta)

### Audiences:

| Typ | Opis | Zastosowanie |
|-----|------|-------------|
| Custom: Website visitors | Pixel + 30/60/180 dni | Retargeting |
| Custom: Customer list | Upload email list | Lookalike source |
| Lookalike 1% | Podobni do klientów | Prospecting |
| Lookalike 3-5% | Szersza grupa | Skalowanie |
| Interest | Zainteresowania (marketing, SaaS) | Cold traffic |
| Detailed targeting | Stanowisko + branża | B2B |

## LinkedIn Ads

### Typy kampanii:

| Typ | Kiedy | Budget min. | CPC typowy |
|-----|-------|-------------|------------|
| **Sponsored Content** | Lead gen B2B | 3000 zł/mies | 15-50 zł |
| **Message Ads** | Direct outreach | 2000 zł/mies | 30-80 zł/send |
| **Text Ads** | Brand awareness | 1000 zł/mies | 10-30 zł |
| **Document Ads** | Thought leadership | 2000 zł/mies | 10-40 zł |

### Targeting LinkedIn:

| Kryterium | Przykład | Precyzja |
|-----------|---------|----------|
| Job title | "Marketing Manager", "CEO" | ★★★★★ |
| Company size | 11-50, 51-200 | ★★★★ |
| Industry | SaaS, E-commerce | ★★★★ |
| Seniority | Director, VP, C-suite | ★★★★★ |
| Skills | "Marketing automation", "CRM" | ★★★ |
| Groups | Członkowie grup branżowych | ★★★ |

**Min. audience size:** 50 000 (mniejsze = droższe)

### Copy LinkedIn Ads:

```
INTRO TEXT (max 600 znaków):
[Hook — stat lub pytanie]
[Problem — 1 zdanie]
[Rozwiązanie — 1 zdanie]
[Social proof — opcjonalnie]
[CTA — jasna instrukcja]

HEADLINE (max 70 znaków):
[Benefit] + [Qualifier]
"Automatyzuj sprzedaż B2B — 14 dni za darmo"
```

## Budżet i ROAS

### Alokacja budżetu (starter):

| Kanał | % budżetu | Kiedy priorytet |
|-------|-----------|-----------------|
| Google Search | 40% | High intent keywords istnieją |
| Meta Ads | 35% | Visual product, B2C lub B2B2C |
| LinkedIn Ads | 15% | Enterprise B2B, high ACV |
| Retargeting (cross) | 10% | Zawsze |

### Metryki per kanał:

| Metryka | Google | Meta | LinkedIn |
|---------|--------|------|----------|
| CTR dobry | > 3% | > 1.5% | > 0.5% |
| CPC akceptowalny | < 10 zł | < 5 zł | < 30 zł |
| CPL (cost per lead) | < 50 zł | < 30 zł | < 100 zł |
| ROAS target | > 3x | > 2x | > 2x |

### Formuła ROAS:

```
ROAS = Revenue / Ad Spend

Przykład:
Spend: 5 000 zł/mies
Leads: 100 (CPL = 50 zł)
Conversion rate: 5%
Klienci: 5
ACV: 5 000 zł/rok
Revenue (roczny): 25 000 zł
ROAS: 25 000 / 5 000 = 5x ✅
```

## Checklist uruchomienia kampanii

- [ ] Pixel/tag zainstalowany i testowany
- [ ] Conversion events zdefiniowane w analytics
- [ ] Landing page gotowy (z `page-cro` checklist)
- [ ] UTM parametry w linkach reklam
- [ ] Negative keywords dodane (Google)
- [ ] A/B test: min. 2 warianty copy
- [ ] Budget dzienny ustawiony (nie lifetime na start)
- [ ] Retargeting audience utworzony
- [ ] Reguły automatyzacji (pause if CPA > X)

## Pułapki

1. **Brak landing page** → reklama → homepage = niska konwersja, reklama musi prowadzić do dedykowanej strony
2. **Za szeroki targeting** → "wszyscy 25-55" to nie targeting
3. **Jeden wariant reklamy** → zawsze min. 3 warianty do testów
4. **Optymalizacja za wcześnie** → potrzebujesz 50+ konwersji na learning phase (Meta)
5. **Budget too low** → za mały budżet = za mało danych = złe decyzje algorytmu
6. **Ignorowanie Quality Score** → Google: niski QS = wyższy CPC
7. **Brak negative keywords** → płacisz za "co to jest X" i "X kurs za darmo"
