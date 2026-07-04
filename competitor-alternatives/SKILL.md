---
name: competitor-alternatives
description: >
  Strony porównawcze i alternatywne: "X vs Y", "Alternative to X", comparison pages.
  Triggery: "strona porównawcza", "alternatywa", "X vs Y", "competitor comparison",
  "porównanie narzędzi", "alternative to", "comparison page", "versus",
  "jak wypadamy na tle konkurencji", "battle card", "switch page".
---

# Competitor Alternatives — Strony porównawcze i alternatywne

Tworzy strony "X vs Y" i "Alternatywa dla X" — format porównawczy o wysokim intencji zakupowej. Generuje ruch od ludzi aktywnie szukających rozwiązania.

## Kiedy używać

- Tworzenie strony "[Twój produkt] vs [Konkurent]"
- Tworzenie strony "Alternatywa dla [Konkurent]"
- Porównanie wielu narzędzi w jednym artykule
- Switch/migration pages ("Przejdź z X na [Twój produkt]")
- Użytkownik mówi: "strona porównawcza", "jak wypadamy na tle X"

## Zależności

- **Wymagane:** `product-marketing-context` → `competitor-analysis.md`, `features.md`
- **Wymagane:** `sales-context` → `objection-handling.md`, `battle-cards.md`
- **Opcjonalne:** `seo` → keyword research, on-page optimization
- **Opcjonalne:** `copywriting` → nagłówki, CTA
- **Opcjonalne:** `page-cro` → optymalizacja konwersji
- **Opcjonalne:** `schema-markup` → FAQ schema, comparison schema

## Typy stron porównawczych

| Typ | URL pattern | Intencja | CVR |
|-----|------------|---------|-----|
| **1:1 Comparison** | /vs/konkurent | "Który wybrać?" | 5-10% |
| **Alternative to** | /alternatywa-dla-konkurent | "Szukam czegoś innego" | 8-15% |
| **Multi-comparison** | /porownanie-narzedzi-crm | "Jaki jest najlepszy?" | 3-7% |
| **Switch page** | /przejdz-z-konkurent | "Chcę zmienić" | 10-20% |
| **Category page** | /najlepsze-narzedzia-do-X | "Co jest na rynku?" | 2-5% |

## Template: 1:1 Comparison (X vs Y)

### Struktura strony:

```markdown
# [Twój Produkt] vs [Konkurent]: Które narzędzie wybrać w [rok]?

## TL;DR — Szybkie porównanie

| Kryterium | [Twój] | [Konkurent] |
|-----------|--------|-------------|
| Cena od | X zł/mies | Y zł/mies |
| Darmowy plan | ✅/❌ | ✅/❌ |
| [Feature kluczowy 1] | ✅ | ❌ |
| [Feature kluczowy 2] | ✅ | ⚠️ częściowo |
| [Feature kluczowy 3] | ✅ | ✅ |
| Wsparcie PL | ✅ | ❌ |
| Integracje | X+ | Y+ |
| **Verdict** | **Lepszy dla [kto]** | **Lepszy dla [kto]** |

## [Twój Produkt] — Przegląd
[2-3 akapity: co robi, dla kogo, USP]
[Screenshot produktu]

## [Konkurent] — Przegląd
[2-3 akapity: co robi, dla kogo, USP]
[Screenshot konkurenta — fair & objective]

## Szczegółowe porównanie

### 1. [Kryterium — np. Łatwość użycia]
[Twój] — [opis + dowód]
[Konkurent] — [opis + dowód]
**Werdykt:** [Kto wygrywa i dlaczego]

### 2. [Kryterium — np. Cennik]
[tabela cenników obu]
**Werdykt:** [Kto wygrywa]

### 3. [Kryterium — np. Integracje]
...

### 4. [Kryterium — np. Wsparcie]
...

## Kiedy wybrać [Twój Produkt]
- ✅ Jeśli [warunek 1]
- ✅ Jeśli [warunek 2]
- ✅ Jeśli [warunek 3]

## Kiedy wybrać [Konkurent]
- ✅ Jeśli [warunek — bądź uczciwy]
- ✅ Jeśli [warunek]

## FAQ
[5-7 pytań z long-tail keywords]

## CTA
[Wypróbuj [Twój Produkt] za darmo →]
```

## Template: Alternative Page

```markdown
# Najlepsza alternatywa dla [Konkurent] w [rok]

## Dlaczego szukasz alternatywy?
[Wymień typowe powody odejścia — cena, brakujące ficzery, UX, wsparcie]

## [Twój Produkt] jako alternatywa
[USP — co robisz lepiej / inaczej]

## Porównanie kluczowych różnic

| Funkcja | [Konkurent] | [Twój Produkt] |
|---------|-------------|----------------|
| ... | ... | ... |

## Co mówią klienci, którzy przeszli z [Konkurent]
[Testimonial 1 — z imieniem i firmą]
[Testimonial 2]

## Jak przejść z [Konkurent] na [Twój Produkt]
1. Eksportuj dane z [Konkurent]
2. Załóż konto w [Twój Produkt] (2 min)
3. Zaimportuj dane (automatycznie / CSV)
4. Gotowe — przetestuj przez 14 dni za darmo

## FAQ
[Pytania typu: "Czy mogę zaimportować dane?", "Ile trwa migracja?"]

## CTA
[Przejdź na [Twój Produkt] — 14 dni za darmo →]
```

## SEO — keyword strategy

### Keywords do targetowania:

| Pattern | Przykład | Search intent |
|---------|---------|---------------|
| [twój] vs [konkurent] | "Asana vs Monday" | Comparison |
| [konkurent] alternatywa | "Mailchimp alternatywa" | Switching |
| [konkurent] alternative | "HubSpot alternative" | Switching (EN) |
| najlepsze [kategoria] | "najlepsze CRM dla małych firm" | Category |
| [konkurent] cennik | "Salesforce cennik" | Price comparison |
| [konkurent] opinie | "Pipedrive opinie" | Evaluation |
| przejście z [konkurent] | "migracja z Airtable" | Migration |

### On-page SEO:

- **Title:** "[Twój] vs [Konkurent]: Porównanie [rok] — Cennik, Funkcje, Opinie"
- **H1:** "[Twój] vs [Konkurent]: Które narzędzie wybrać?"
- **Meta description:** "Porównujemy [Twój] i [Konkurent] pod kątem funkcji, cennika i łatwości użycia. Sprawdź który lepiej pasuje do Twojej firmy."
- **FAQ schema:** Dodaj JSON-LD z pytaniami i odpowiedziami
- **Internal links:** Linkuj do pricing, features, case studies

## Zasady uczciwości

**KRYTYCZNE — nie rób tego:**

1. **Nie kłam o konkurencji** → łatwo to zweryfikować, stracisz zaufanie
2. **Nie ukrywaj przewag konkurenta** → przyznaj gdzie są lepsi
3. **Nie porównuj z outdated wersją** → sprawdź aktualny stan
4. **Nie używaj fałszywych testimoniali** → prawdziwe lub żadne
5. **Nie atakuj personalnie** → fakty, nie emocje

**TAK rób:**
- Bądź fair — pokaż gdzie konkurent wygrywa
- Aktualizuj co kwartał (ceny, ficzery się zmieniają)
- Linkuj do strony konkurenta (paradoksalnie buduje zaufanie)
- Dodaj sekcję "Kiedy wybrać konkurenta" (obiektywność)

## Dystrybucja

| Kanał | Jak |
|-------|-----|
| SEO | Dedykowana strona /vs/ + blog post |
| Google Ads | Targetuj brand keywords konkurenta |
| LinkedIn | Post "X vs Y — co wybraliśmy i dlaczego" |
| Email | Sekwencja do leads, którzy wspominają konkurenta |
| Sales | Battle card dla handlowców |

## Metryki

| Metryka | Target | Co mierzy |
|---------|--------|-----------|
| Organic traffic | 200+/mies (po 3 mies) | SEO effectiveness |
| Time on page | > 3 min | Engagement |
| CVR (visitor → signup) | 5-15% | Conversion |
| Bounce rate | < 60% | Relevance |

## Pułapki

1. **Zbyt stronniczy** → czytelnik wyczuje manipulację, straci zaufanie
2. **Brak aktualizacji** → porównanie sprzed roku z błędnymi cenami = utrata wiarygodności
3. **Za dużo konkurentów naraz** → max 1-2 per strona, reszta w osobnych artykułach
4. **Brak CTA** → porównanie bez call-to-action = czytelnik odchodzi do konkurenta
5. **Ignorowanie long-tail** → "[konkurent] cennik [rok]" ma często lepszy CTR niż generic
