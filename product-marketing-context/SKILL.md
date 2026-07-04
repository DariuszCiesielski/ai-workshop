---
name: product-marketing-context
description: >
  Generuje 8 plików kontekstowych marketingowo-SEO per projekt SaaS.
  Fundament dla skilli content, seo, copywriting, marketing-strategy-methodology.
  Triggery: "wygeneruj kontekst marketingowy", "marketing context", "przygotuj kontekst SEO",
  "brand voice", "target keywords", "analiza konkurencji", "styl komunikacji",
  "przygotuj fundamenty marketingowe", "marketing foundation".
---

# Product Marketing Context Generator

Generuje zestaw 8 plików kontekstowych, które stanowią fundament dla wszelkich działań marketingowych, SEO i contentowych w projekcie SaaS. Każdy plik to żywy dokument — aktualizowany w miarę rozwoju produktu.

## Kiedy używać

- Na początku projektu SaaS — zanim zaczniesz pisać content, robić SEO, tworzyć landing page
- Gdy brakuje spójnego kontekstu marketingowego (każdy artykuł brzmi inaczej)
- Przed uruchomieniem kampanii content marketing
- Gdy inny skill (seo, content, copywriting) zgłasza brak kontekstu
- Użytkownik mówi: "przygotuj kontekst marketingowy", "brand voice", "fundamenty marketingowe"

## Zależności

- Folder `/docs/` w projekcie (PRODUCT.md, ICP.md — jeśli istnieją, uzupełnij zamiast duplikować)
- Opcjonalnie: `product-value-extractor` — do ekstrakcji wartości z kodu
- Opcjonalnie: `seo` — do keyword research i analizy konkurencji

## Proces

### Krok 0: Orientacja

1. Sprawdź czy folder `docs/marketing/` istnieje w projekcie
2. Przeczytaj istniejące pliki kontekstowe (jeśli są) — uzupełnij, nie nadpisuj
3. Przeczytaj `/docs/PRODUCT.md` i `/docs/ICP.md` (jeśli istnieją) — wyciągnij kontekst
4. Jeśli nic nie istnieje — zbierz kontekst z kodu: `package.json`, README, komponenty UI, schemat DB

### Krok 1: Zbierz dane od użytkownika

Zapytaj (z rekomendowaną odpowiedzią bazując na tym co znalazłeś w kodzie):

1. **Nazwa produktu** i domena
2. **Jednozdaniowy opis** — co robi i dla kogo
3. **3 główne bolączki** klienta, które produkt rozwiązuje
4. **Główni konkurenci** (3-5 nazw lub URL)
5. **Ton komunikacji** — formalny / konwersacyjny / techniczny / przyjazny
6. **Język docelowy** — PL / EN / oba

### Krok 2: Wygeneruj 8 plików

Zapisz w `docs/marketing/` (lub `docs/` jeśli projekt mały):

#### 1. `brand-voice.md` — Głos marki
```markdown
# Brand Voice — [Produkt]

## Ton
[formalny/konwersacyjny/techniczny/przyjazny] — [1 zdanie uzasadnienia]

## Zasady komunikacji
- Pisz w 2. osobie ("Ty", "Twój")
- [3-5 zasad specyficznych dla marki]

## Słowa-klucze marki (brand keywords)
Używaj: [lista 10-15 słów które definiują markę]
Unikaj: [lista 5-10 słów/fraz zakazanych]

## Przykłady
### Dobrze ✓
- [3 przykłady nagłówków/opisów w głosie marki]

### Źle ✗
- [3 przykłady tego samego przekazu w złym tonie]
```

#### 2. `style-guide.md` — Styl treści
```markdown
# Style Guide — [Produkt]

## Format treści
- Nagłówki: [case: sentence/title], max [X] słów
- Paragrafy: max [X] zdań, [X] słów
- Listy: preferuj bullety nad numerowane (chyba że kolejność ma znaczenie)

## Formatowanie
- Bold: kluczowe koncepty przy pierwszym użyciu
- Kursywa: cytaty, nazwy narzędzi
- Code: nazwy techniczne, komendy

## Struktura artykułu
1. Hook (1-2 zdania — ból lub zaskakujący fakt)
2. Kontekst (dlaczego to ważne teraz)
3. Rozwiązanie (główna treść)
4. Dowody (dane, przykłady, case study)
5. CTA (co czytelnik powinien zrobić dalej)

## Długość wg typu
| Typ | Słowa | Czas czytania |
|-----|-------|---------------|
| Blog post | 1200-2000 | 5-8 min |
| Landing page | 300-800 | 2-3 min |
| Email | 150-300 | 1-2 min |
| Social post | 50-150 | <1 min |
```

#### 3. `seo-guidelines.md` — Wytyczne SEO
```markdown
# SEO Guidelines — [Produkt]

## On-Page
- Title: [keyword] — [wartość] | [Marka] (≤55 znaków PL)
- Meta description: [ból] + [rozwiązanie] + CTA (≤155 znaków PL)
- H1: dokładnie 1 per strona, zawiera primary keyword
- URL: /[kategoria]/[slug-bez-polskich-znakow]

## Keyword density
- Primary: 1-2% (naturalnie, nie sztucznie)
- Secondary: 0.5-1%
- LSI: rozsiane w treści

## Schema markup
- Strona główna: Organization + WebSite
- Blog: Article + BreadcrumbList
- Cennik: Product + Offer
- FAQ: TYLKO strony informacyjne (nie biznesowe — ograniczenie Google 2023)

## Linki wewnętrzne
- Min. 3 linki wewnętrzne per artykuł
- Anchor text: opisowy (nie "kliknij tutaj")
- Linkuj do: /features, /pricing, powiązane artykuły

## Polskie SEO
- Slugi: transliteracja (ą→a, ł→l, ś→s)
- hreflang: dodaj jeśli EN wersja istnieje
- Źródła danych: Senuto, Semstorm + Ahrefs/SEMrush
```

#### 4. `target-keywords.md` — Słowa kluczowe
```markdown
# Target Keywords — [Produkt]

## Primary keywords (strona główna + główne LP)
| Keyword | Volume/mies. | Difficulty | Intent | Docelowa strona |
|---------|-------------|------------|--------|-----------------|
| [keyword 1] | [est.] | [low/med/high] | [info/comm/trans] | / |
| [keyword 2] | [est.] | ... | ... | /features |

## Secondary keywords (blog, podstrony)
[Tabela jak wyżej — 10-20 keywordów]

## Long-tail keywords (artykuły)
[Lista 20-30 fraz — pogrupowane w topic clusters]

## Topic clusters
| Cluster | Pillar page | Supporting articles |
|---------|------------|---------------------|
| [Temat 1] | /blog/[slug] | [3-5 artykułów] |
| [Temat 2] | ... | ... |

## Negatywne keywords (unikaj)
[Frazy które przyciągają zły ruch — np. "darmowy" jeśli product jest płatny]
```

#### 5. `competitor-analysis.md` — Analiza konkurencji
```markdown
# Competitor Analysis — [Produkt]

## Bezpośredni konkurenci
| Konkurent | URL | Cennik | Mocne strony | Słabe strony | Nasz wyróżnik |
|-----------|-----|--------|-------------|-------------|----------------|
| [Nazwa 1] | ... | ... | ... | ... | ... |

## Pośredni konkurenci / alternatywy
[Narzędzia które klient mógłby użyć zamiast — np. Excel, manual process]

## Analiza contentu konkurencji
| Konkurent | Blog? | Częstotliwość | Tematy | Luki (gdzie my możemy wygrać) |
|-----------|-------|--------------|--------|-------------------------------|

## Messaging comparison
| Aspekt | Konkurent A | Konkurent B | My |
|--------|------------|------------|-----|
| Nagłówek LP | "..." | "..." | "..." |
| Główna obietnica | ... | ... | ... |
| Social proof | ... | ... | ... |
| Pricing model | ... | ... | ... |
```

#### 6. `features.md` — Mapa funkcji → wartości
```markdown
# Features → Benefits → Outcomes — [Produkt]

Framework: Feature (co) → Benefit (dlaczego to ważne) → Outcome (mierzalny rezultat)

| Feature | Benefit | Outcome | Keyword |
|---------|---------|---------|---------|
| [Funkcja 1] | [Dlaczego ważne] | [Mierzalny efekt] | [SEO keyword] |
| [Funkcja 2] | ... | ... | ... |

## Unique Selling Points (USP)
1. **[USP 1]** — [1 zdanie dlaczego tego nie ma konkurencja]
2. **[USP 2]** — ...
3. **[USP 3]** — ...

## Messaging hierarchy
1. [Główna obietnica — nagłówek LP]
2. [Supporting message 1 — podstrona features]
3. [Supporting message 2]
4. [Technical differentiator — dla developer audience]
```

#### 7. `internal-links-map.md` — Mapa linków wewnętrznych
```markdown
# Internal Links Map — [Produkt]

## Struktura strony (hub & spoke)
```
/ (home)
├── /features
│   ├── /features/[feature-1]
│   └── /features/[feature-2]
├── /pricing
├── /blog
│   ├── /blog/[cluster-1-pillar]
│   │   ├── /blog/[supporting-1a]
│   │   └── /blog/[supporting-1b]
│   └── /blog/[cluster-2-pillar]
├── /about
├── /contact
└── /docs (jeśli SaaS z dokumentacją)
```

## Reguły linkowania
- Każda podstrona linkuje do: /, /features, /pricing (footer lub CTA)
- Blog posts linkują do: pillar page + 2 supporting articles + /features
- Pillar pages linkują do: wszystkich supporting articles w clusterze
- Strony features linkują do: case studies + blog posts o danej funkcji

## Anchor text patterns
| Cel | Anchor text |
|-----|------------|
| /pricing | "cennik", "sprawdź ceny", "plany i ceny" |
| /features | "funkcje", "możliwości [Produktu]" |
| /blog/[slug] | [tytuł artykułu] lub [keyword artykułu] |
```

#### 8. `cro-best-practices.md` — Konwersja
```markdown
# CRO Best Practices — [Produkt]

## Ścieżki konwersji
| Ścieżka | Źródło ruchu | Landing | CTA | Cel |
|---------|-------------|---------|-----|-----|
| Organic blog | Google | /blog/[slug] | "Wypróbuj za darmo" | Signup |
| Direct | Polecenie | / | "Zacznij teraz" | Signup |
| Paid | Google Ads | /lp/[kampania] | "Testuj 14 dni" | Trial |

## CTA hierarchy
1. **Primary:** [tekst] — kolor: [accent], pozycja: hero + sticky header
2. **Secondary:** [tekst] — kolor: outline, pozycja: pod sekcjami
3. **Tertiary:** [tekst] — link tekstowy, pozycja: footer

## Trust elements (priorytet)
1. [Najsilniejszy social proof — np. "500+ firm", konkretna liczba]
2. [Testimonial / case study]
3. [Badge / certyfikat / integracje]

## Optymalizacja formularzy
- Signup: email + hasło (minimum!) → reszta w onboardingu
- Lead magnet: imię + email
- Kontakt: imię + email + wiadomość
- NIGDY: telefon jako wymagane pole (chyba że B2B enterprise)
```

### Krok 3: Weryfikacja

Po wygenerowaniu:
1. Sprawdź spójność między plikami (brand voice ↔ style guide ↔ CTA hierarchy)
2. Upewnij się że keywords w `target-keywords.md` są użyte w `features.md` i `seo-guidelines.md`
3. Sprawdź czy internal links map pokrywa się ze strukturą projektu

### Krok 4: Integracja

Poinformuj użytkownika:
> "Wygenerowałem 8 plików kontekstowych w `docs/marketing/`. Teraz inne skille (seo, content, copywriting) mogą z nich korzystać automatycznie. Przy pisaniu artykułu → czytam brand-voice + target-keywords + style-guide. Przy audycie SEO → czytam seo-guidelines + internal-links-map."

## Cross-references

- `product-value-extractor` — generuje Features → Benefits → Outcomes (input do `features.md`)
- `seo` — korzysta z `seo-guidelines.md`, `target-keywords.md`
- `content` — korzysta z `brand-voice.md`, `style-guide.md`, `target-keywords.md`
- `marketing-strategy-methodology` — korzysta z `competitor-analysis.md`, `features.md`
- `image-generator` — korzysta z `brand-voice.md` (presety brandowe)

## Pułapki

- **Nie generuj keywords "z głowy"** — jeśli nie masz danych z Senuto/Ahrefs, oznacz kolumnę volume jako "est." i zaznacz że wymaga weryfikacji
- **Nie kopiuj competitor analysis dosłownie** — analizuj publicznie dostępne informacje
- **Aktualizuj pliki** — kontekst marketingowy starzeje się szybko. Co kwartał przejrzyj i odśwież
- **Nie nadpisuj ustaleń użytkownika** — jeśli brand voice został już ustalony, uzupełnij a nie zastąp
