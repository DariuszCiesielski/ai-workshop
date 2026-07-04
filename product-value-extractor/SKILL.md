---
name: product-value-extractor
description: Ekstrakcja wartości biznesowej z produktu SaaS (kod, dokumentacja, features) → komunikacja sprzedażowa w wielu formatach (landing page, artykuł, video script, social media, email sequence). Używaj przy "przygotuj treści na landing page", "ekstrakcja wartości produktu", "komunikacja sprzedażowa", "copy na stronę", "opisz wartość produktu", "LP copy", "strona sprzedażowa", "value proposition", "przygotuj materiały marketingowe", "co ten produkt robi dla klienta". Auto-aktywacja przy pracy z plikami w /docs/PRODUCT.md, /docs/ICP.md lub gdy kontekst dotyczy komunikacji wartości produktu SaaS.
---

# Product Value Extractor

Skill do ekstrakcji wartości biznesowej z produktu SaaS i generowania komunikacji sprzedażowej w wielu formatach. Czyta kod źródłowy, dokumentację i feature'y — wyciąga z tego realną wartość dla klienta.

## Kiedy używać

- Przygotowanie treści na landing page / stronę sprzedażową
- Generowanie komunikacji marketingowej dla produktu SaaS
- Analiza wartości biznesowej produktu na podstawie kodu i dokumentacji
- Tworzenie materiałów sprzedażowych w wielu formatach (LP, artykuł, video, social, email)
- Budowanie fundamentu komunikacyjnego przed kampanią marketingową
- Zasilanie Marketing Hub danymi o wartości produktu

## Kiedy NIE używać

- Audyt SEO istniejącej strony → skill `seo`
- Pisanie artykułu SEO od zera (bez kontekstu produktu) → skill `content`
- Tworzenie pełnej strategii marketingowej → skill `marketing-strategy-methodology`
- Generowanie grafik → skill `image-generator`

## Komendy

```
/product-value extract              — ekstrakcja wartości → PRODUCT_VALUE.md
/product-value landing-page         — copy na landing page (wymaga PRODUCT_VALUE.md)
/product-value article [typ]        — artykuł ekspercki lub SEO (wymaga PRODUCT_VALUE.md)
/product-value video-script [typ]   — scenariusz video: explainer|demo|short (wymaga PRODUCT_VALUE.md)
/product-value social-series [N]    — seria N postów social media (domyślnie 7)
/product-value email-sequence [N]   — sekwencja N maili nurturingowych (domyślnie 5)
/product-value full                 — extract + wszystkie formaty naraz
/product-value research [url...]    — opcjonalny research konkurencji
```

## Aliasy (PL)

```
/product-value wyciągnij            → extract
/product-value strona               → landing-page
/product-value artykuł              → article
/product-value scenariusz           → video-script
/product-value posty                → social-series
/product-value maile                → email-sequence
/product-value pełny                → full
/product-value badanie              → research
```

---

## FAZA 1: Ekstrakcja wartości (ZAWSZE jako pierwsza)

Ta faza jest fundamentem — bez niej żaden format wyjściowy nie ma sensu.

### Krok 1: Skanowanie projektu

Przeszukaj projekt w następującej kolejności:

1. **Dokumentacja produktowa** (priorytet najwyższy):
   - `/docs/PRODUCT.md` — opis produktu, wartość, USP, model biznesowy
   - `/docs/ICP.md` — Ideal Customer Profile, persony, rynek docelowy
   - `/docs/ARCHITECTURE.md` — decyzje technologiczne
   - `README.md` — opis projektu
   - Pliki planistyczne: `TASKS.md`, `PROJECT_PLAN.md`, `.planning/`

2. **Kod źródłowy** (realne feature'y):
   - `package.json` / `pyproject.toml` — nazwa, opis, zależności
   - Routing (`app/` lub `pages/`) — jakie ekrany/strony ma aplikacja
   - Komponenty UI — jakie interakcje są dostępne
   - API endpoints — jakie operacje obsługuje backend
   - Modele danych / schemat bazy — jakie encje istnieją

3. **Historia projektu**:
   - `git log --oneline -20` — co było budowane ostatnio
   - `CHANGELOG.md` — ewolucja produktu

### Krok 2: Analiza wartości biznesowej

Na podstawie zebranych danych zidentyfikuj:

| Element | Pytanie | Źródło |
|---------|---------|--------|
| **Problemy klienta** | Jakie 3-5 bólów rozwiązuje ten produkt? | ICP.md, PRODUCT.md, feature'y |
| **Rozwiązania** | Jak konkretnie produkt adresuje każdy ból? | Kod, API, UI flows |
| **USP** | Co wyróżnia od alternatyw? (1-2 zdania) | PRODUCT.md, architektura |
| **Wartość mierzalna** | Jaki ROI / oszczędność czasu / wzrost? | Dane, case studies |
| **Persona docelowa** | Kto kupuje? (rola, wielkość firmy, branża) | ICP.md |
| **Obiekcje** | Dlaczego klient mógłby NIE kupić? | Analiza produktu |
| **Social proof** | Liczby, referencje, case studies | Dane w projekcie |
| **Model biznesowy** | Jak produkt zarabia? (SaaS/freemium/one-time) | PRODUCT.md |

### Krok 3: Framework transformacji wartości

Dla każdego feature'u zastosuj transformację **Feature → Benefit → Outcome**:

```
Feature:  "Automatyczna analiza fraz kluczowych"
Benefit:  "Nie musisz ręcznie szukać fraz — system robi to za Ciebie"
Outcome:  "Oszczędzasz 4h tygodniowo na research, które możesz przeznaczyć na tworzenie treści"
```

Zasady:
- Feature = CO robi (techniczny opis)
- Benefit = DLACZEGO to ważne (eliminacja bólu)
- Outcome = JAKI REZULTAT (mierzalny efekt dla klienta)

**NIGDY nie zostawiaj komunikacji na poziomie feature'ów.** Klient nie kupuje feature'ów — kupuje outcomes.

### Krok 4: Generowanie PRODUCT_VALUE.md

Zapisz wynik w `/docs/PRODUCT_VALUE.md` (lub wskazanej lokalizacji):

```markdown
# Wartość produktu: [Nazwa]

Data ekstrakcji: [YYYY-MM-DD]
Źródła: [lista przeskanowanych plików]

## 1. Elevator Pitch
[2-3 zdania: co to jest, dla kogo, jaka wartość]

## 2. Problemy klienta (Pain Points)
### Problem 1: [Nazwa]
- **Ból:** [Opis sytuacji klienta BEZ produktu]
- **Konsekwencja:** [Co się dzieje gdy problem nie jest rozwiązany]
- **Rozwiązanie:** [Jak produkt to adresuje]
- **Rezultat:** [Mierzalny outcome]

### Problem 2: ...
[powtórz dla 3-5 problemów]

## 3. USP (Unique Selling Proposition)
[1-2 zdania: dlaczego TEN produkt, a nie alternatywa]

### Przewagi konkurencyjne
1. [Przewaga] — [Dlaczego ma znaczenie]
2. ...

## 4. Feature → Benefit → Outcome Map
| Feature | Benefit | Outcome |
|---------|---------|---------|
| [nazwa] | [co daje klientowi] | [mierzalny rezultat] |
| ... | ... | ... |

## 5. Persona docelowa
- **Rola:** [stanowisko, odpowiedzialności]
- **Firma:** [wielkość, branża]
- **Ból główny:** [największy problem do rozwiązania]
- **Język:** [jak mówi o swoim problemie — cytaty, frazy]
- **Kanał dotarcia:** [gdzie szuka rozwiązań]
- **Obiekcje:** [dlaczego może nie kupić]

## 6. Social Proof
- [Liczby, metryki, referencje, case studies — jeśli dostępne]
- [Jeśli brak — oznacz: "DO UZUPEŁNIENIA po zdobyciu pierwszych klientów"]

## 7. Model biznesowy
- **Typ:** [SaaS / freemium / one-time / marketplace]
- **Cennik:** [jeśli znany]
- **Wartość vs. cena:** [uzasadnienie ceny w kontekście ROI klienta]

## 8. Obiekcje i odpowiedzi
| Obiekcja | Odpowiedź |
|----------|-----------|
| "Za drogo" | [odpowiedź z ROI] |
| "Już mam narzędzie X" | [odpowiedź z porównaniem] |
| ... | ... |
```

**Zasady PRODUCT_VALUE.md:**
- Oznacz wyraźnie co jest faktem (z kodu/docs), a co interpretacją
- Jeśli brakuje danych (np. social proof) — oznacz "DO UZUPEŁNIENIA", nie wymyślaj
- Plik jest żywym dokumentem — aktualizuj przy zmianach produktu

---

## FAZA 2: Formaty wyjściowe

Każdy format czyta PRODUCT_VALUE.md jako input. Jeśli plik nie istnieje — najpierw uruchom Fazę 1.

### 2.1 Landing Page Copy

Generuj strukturę sekcji gotową do implementacji (Starter Kit, kreator stron, lub ręcznie):

```markdown
# Landing Page: [Nazwa produktu]

## HERO
- **Nagłówek:** [Max 8 słów — wartość, nie feature]
- **Podnagłówek:** [1-2 zdania — rozwinięcie z konkretnym outcome]
- **CTA główny:** [Tekst przycisku — akcja + wartość, np. "Zacznij oszczędzać 4h tygodniowo"]
- **CTA dodatkowy:** [Tekst linku — mniejsze zobowiązanie, np. "Zobacz demo"]
- **Social proof pod CTA:** [np. "Używa 120+ firm", "14-dniowy trial bez karty"]

## PROBLEMY (sekcja "Znasz to?")
[3-4 bullet pointy opisujące bóle klienta w jego języku — bez nazwy produktu]

## ROZWIĄZANIE (sekcja "Jak to rozwiązujemy")
[Kontrast PRZED/PO — tabela lub dwie kolumny]

| Bez [Produkt] | Z [Produkt] |
|----------------|-------------|
| [ból 1] | [rozwiązanie 1] |
| [ból 2] | [rozwiązanie 2] |

## FEATURES / BENEFITS (3-6 kart)
Dla każdej karty:
- **Ikona:** [sugestia ikony z Lucide]
- **Tytuł:** [Benefit, nie feature — max 5 słów]
- **Opis:** [2-3 zdania z outcome]

## JAK TO DZIAŁA (3 kroki)
1. [Krok] — [Opis w 1 zdaniu]
2. [Krok] — [Opis]
3. [Krok] — [Opis]

## SOCIAL PROOF
- Testimoniale (jeśli dostępne)
- Loga firm (jeśli dostępne)
- Metryki (jeśli dostępne)
- [Jeśli brak — zaproponuj CTA typu "Bądź jednym z pierwszych"]

## CENNIK (jeśli dotyczy)
[Tabela planów z wyróżnionym recommended plan]

## FAQ (5-7 pytań)
[Pytania mapowane na obiekcje z PRODUCT_VALUE.md]

## KOŃCOWY CTA
- **Nagłówek:** [Pytanie lub stwierdzenie motywujące]
- **CTA:** [Ten sam co hero — spójność]
```

**Zasady copy na LP:**
- Nagłówek hero: wartość, nie feature. "Podwój liczbę leadów" > "Narzędzie do lead generation"
- Każda sekcja ma JEDEN cel — nie mieszaj problemów z rozwiązaniami
- CTA musi mieć wartość, nie akcję. "Zacznij oszczędzać czas" > "Zarejestruj się"
- Język klienta, nie twórcy. "Zarządzaj projektami bez chaosu" > "Kompleksowa platforma PM"
- Brak żargonu technicznego (chyba że ICP to deweloperzy)

### 2.2 Artykuł

Dwa tryby:

**A) Artykuł ekspercki** — pozycjonuje produkt jako autorytet:
- Temat: problem klienta (nie produkt)
- Struktura: Problem → Kontekst rynkowy → Rozwiązania (w tym nasz produkt jako jedno z nich) → Poradnik
- Ton: edukacyjny, merytoryczny, bez sprzedaży
- CTA na końcu: delikatny, typu "Jeśli szukasz narzędzia, które..."
- Długość: 1500-2500 słów

**B) Artykuł SEO** — zoptymalizowany pod frazy kluczowe:
- Deleguj do skilla `content` z kontekstem z PRODUCT_VALUE.md
- Przekaż: keyword, persona, tone, must-include points
- Skill `content` zajmie się strukturą SEO, scoring, quality gates

### 2.3 Scenariusz video

Trzy formaty do wyboru:

**A) Explainer (2-3 min):**
```
[0:00-0:15] HOOK — Pytanie/statystyka trafiająca w ból klienta
[0:15-0:45] PROBLEM — Opis sytuacji "bez rozwiązania" (empatia)
[0:45-1:30] ROZWIĄZANIE — Prezentacja produktu (co robi, jak działa)
[1:30-2:15] DEMO — 3 kluczowe ekrany/akcje (screen recording notes)
[2:15-2:45] SOCIAL PROOF — Liczby, cytaty, wyniki
[2:45-3:00] CTA — Konkretna akcja + link
```

**B) Demo walkthrough (5-10 min):**
```
[0:00-0:30] KONTEKST — Dla kogo, jaki problem rozwiązujemy
[0:30-1:00] SETUP — Co potrzebne na start
[1:00-7:00] WALKTHROUGH — Krok po kroku przez główny flow
            Dla każdego kroku: CO robię → DLACZEGO → JAKI EFEKT
[7:00-8:00] PODSUMOWANIE — 3 kluczowe takeaway
[8:00-8:30] CTA — Gdzie zacząć + oferta
```

**C) Short / Reel (30-60s):**
```
[0:00-0:03] HOOK — Mocne pytanie lub kontrowersyjne stwierdzenie
[0:03-0:15] PROBLEM — Szybki opis bólu (max 3 zdania)
[0:15-0:45] ROZWIĄZANIE — Quick demo lub before/after
[0:45-0:55] REZULTAT — Jedna mocna liczba/outcome
[0:55-1:00] CTA — "Link w bio" / "Sprawdź [url]"
```

### 2.4 Seria social media

Generuj serię z **łukiem narracyjnym**, nie oddzielne posty:

```
Post 1/N: HOOK — Szokująca statystyka lub kontrowersja z branży
Post 2/N: PROBLEM — Rozwinięcie bólu klienta (storytelling)
Post 3/N: INSIGHT — Nieoczywista obserwacja / zmiana perspektywy
Post 4/N: ROZWIĄZANIE — Jak to rozwiązać (ogólnie, nie sprzedażowo)
Post 5/N: CASE STUDY — Konkretny przykład / before-after
Post 6/N: HOW-TO — Praktyczny poradnik (wartość za darmo)
Post 7/N: CTA — Bezpośrednie zaproszenie do produktu
```

Dla każdego posta:
- **Platforma:** LinkedIn / Instagram / X (dostosuj format)
- **Tekst:** Gotowy do publikacji (z emoji tam gdzie pasują)
- **Sugestia grafiki:** Opis do generowania przez skill `image-generator`
- **Hashtagi:** 3-5 relevantnych

**Zasady serii:**
- Posty 1-6 dają wartość BEZ sprzedaży — budują autorytet
- Tylko post 7 jest sprzedażowy — i nawet on daje wartość
- Spójny ton przez całą serię
- Każdy post działa samodzielnie (nie wymaga przeczytania poprzednich)

### 2.5 Email sequence

Sekwencja nurturingowa (po zapisie na newsletter / pobraniu lead magnetu):

```
Email 1 (dzień 0): POWITANIE + WARTOŚĆ
  Subject: [Benefit — nie "Witamy"]
  Body: Kim jesteśmy, co dostaniesz, jeden quick win od razu

Email 2 (dzień 2): PROBLEM
  Subject: [Pytanie trafiające w ból]
  Body: Opis problemu z perspektywy klienta, empatia, hint na rozwiązanie

Email 3 (dzień 5): EDUKACJA
  Subject: [How-to / poradnik]
  Body: Konkretna wartość — poradnik, checklist, framework (bez sprzedaży)

Email 4 (dzień 8): SOCIAL PROOF
  Subject: [Wynik klienta / case study]
  Body: Historia transformacji: sytuacja przed → co zrobili → wynik

Email 5 (dzień 12): OFERTA
  Subject: [Wartość + urgency]
  Body: Pełna prezentacja produktu, FAQ, CTA z ograniczeniem czasowym
```

Dla każdego maila:
- **Subject line:** 2 warianty (A/B test)
- **Preview text:** Max 90 znaków
- **Body:** Gotowy tekst (plain text — bez HTML)
- **CTA:** Jeden jasny, konkretny
- **PS:** Dodatkowy hook lub wartość

---

## FAZA 3: Research konkurencji (opcjonalna)

Uruchamiana TYLKO gdy user poprosi (`/product-value research [url...]`) lub powie "sprawdź konkurencję".

### Krok 1: Identyfikacja konkurentów

Jeśli user nie podał URL-i:
1. Na podstawie PRODUCT_VALUE.md zidentyfikuj kategorię produktu
2. Wyszukaj (WebSearch): "[kategoria] + narzędzie/tool/software + [język rynku]"
3. Znajdź 3-5 najbliższych konkurentów

### Krok 2: Analiza komunikacji konkurentów

Dla każdego konkurenta (WebFetch/Firecrawl):
- Hero headline + subheadline
- Value proposition (jak komunikują wartość)
- Główne benefits (jak formułują korzyści)
- CTA (co proponują)
- Social proof (jakie dowody pokazują)
- Cennik (jeśli publiczny)
- Ton komunikacji (formalny/casual/tech)

### Krok 3: Synteza

```markdown
# Research konkurencji: [Kategoria]

## Wzorce komunikacji w branży
- [Co wszyscy robią podobnie — konwencje branżowe]

## Luki komunikacyjne (nasze szanse)
- [Czego nikt nie komunikuje, a my możemy]

## Najlepsze praktyki do zaadaptowania
- [Od kogo] → [Co] → [Jak zaadaptować dla nas]

## Rekomendacje dla naszej komunikacji
1. [Konkretna rekomendacja z uzasadnieniem]
2. ...
```

---

## Integracja z ekosystemem

### Ze skillami
| Skill | Kiedy | Jak |
|-------|-------|-----|
| `content` | Artykuł SEO | Przekaż keyword + kontekst z PRODUCT_VALUE.md |
| `seo` | Research fraz | Użyj do identyfikacji fraz kluczowych dla artykułów |
| `image-generator` | Grafiki do postów/LP | Przekaż opis z sugestii grafiki |
| `marketing-strategy-methodology` | Pełna strategia | PRODUCT_VALUE.md jako input do Fazy 1 strategii |
| `brand-elements` | Spójność wizualna | Favicon, footer, kolory marki |

### Z narzędziami w ekosystemie
| Narzędzie | Rola |
|-----------|------|
| **Marketing Hub** | Moduł "Komunikacja produktowa" — importuje PRODUCT_VALUE.md, śledzi status materiałów |
| **Starter Kit** | Implementacja LP — wklej sekcje z formatu landing-page |
| **Kreator stron** | Alternatywna implementacja LP |
| **Postiz** | Publikacja serii social media wg kalendarza |
| **Kreator grafik** | Generowanie grafik do postów i artykułów |

### Z Marketing Managerem (przyszła integracja)
Skill może być wywoływany przez Marketing Manager jako krok pipeline'u:
```
Marketing Manager → analiza produktu → product-value extract
                  → strategia → marketing-strategy-methodology
                  → treści → content / product-value [format]
                  → SEO → seo
                  → grafiki → image-generator
                  → publikacja → Postiz
                  → kampania → ads-auditor
```

---

## Anty-wzorce (czego NIE robić)

- **Feature dump** — nie wymieniaj feature'ów bez transformacji na benefits/outcomes
- **Generyczny copy** — "innowacyjne rozwiązanie", "kompleksowa platforma" = ZAKAZANE
- **Brak kontrastu** — zawsze pokazuj PRZED/PO, nie tylko "nasze zalety"
- **Klient jako obiekt** — pisz DO klienta ("Ty"), nie O kliencie ("użytkownik")
- **Jeden CTA fits all** — dopasuj CTA do etapu lejka (awareness ≠ decision)
- **Wymyślone social proof** — jeśli nie masz danych, napisz "DO UZUPEŁNIENIA", nie "setki zadowolonych klientów"
- **Copy-paste między formatami** — każdy format ma inną strukturę i cel. Post na LinkedIn ≠ skrócony artykuł

---

## Quality Gate

Po wygenerowaniu każdego formatu sprawdź:

| Kryterium | Warunek PASS |
|-----------|-------------|
| Feature → Benefit → Outcome | Każdy feature przetransformowany |
| Język klienta | Brak żargonu (chyba że ICP = tech) |
| Kontrast wartości | Sekcja PRZED/PO istnieje |
| CTA z wartością | Każdy CTA zawiera benefit, nie tylko akcję |
| Spójność z PRODUCT_VALUE.md | Treści zgodne z ekstrakcją |
| Brak wymysłów | Social proof oznaczony lub realny |
| Polskie diakrytyki | Wszystkie teksty z ą, ć, ę, ł, ń, ó, ś, ź, ż |

---

## Auto-feedback

Po zakończeniu pracy ze skillem, wygeneruj raport TYLKO gdy wystąpiły anomalie:
`~/projekty/Moje skille/feedback/product-value-extractor-feedback-{{DATA}}.md`

Format jak w skill `marketing-strategy-methodology`.
