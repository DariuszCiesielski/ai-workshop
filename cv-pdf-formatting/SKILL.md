---
name: cv-pdf-formatting
description: Reguły formatowania CV i listów motywacyjnych w PDF (@react-pdf/renderer) — spacing, marginesy, typografia, ATS, layout 2-stronicowy
triggers:
  - generuj CV
  - generuj list motywacyjny
  - stwórz CV
  - CV PDF
  - cover letter PDF
  - formatowanie CV
  - resume PDF
metadata:
  filePattern: "**/pdf-templates/**,**/generate-*-pdfs*,**/cv-*,**/cover-letter*"
  bashPattern: "generate.*pdf|cv.*pdf|cover.*letter"
---

# Formatowanie CV i listów motywacyjnych w PDF

Skill zawiera wnioski z iteracyjnej pracy nad profesjonalnymi dokumentami rekrutacyjnymi w formacie PDF generowanym przez `@react-pdf/renderer` z fontem Montserrat.

## 1. Ogólne zasady layoutu

### CV — max 2 strony
- Dokument CV **MUSI** mieścić się na **maksymalnie 2 stronach A4**
- Po każdej generacji **weryfikuj liczbę stron** — otwórz PDF i sprawdź
- Jeśli wychodzi 3. strona (nawet z samym RODO) — ściskaj spacing, NIE usuwaj treści
- Klauzula RODO powinna być na dole ostatniej strony z treścią, nie na osobnej stronie

### List motywacyjny — 1 strona
- List motywacyjny **MUSI** zmieścić się na **1 stronie A4**
- 4 akapity: wstęp + osiągnięcia + umiejętności praktyczne + motywacja/zakończenie

## 2. Marginesy i padding

### Strona 1 (z headerem)
- `paddingTop` strony ustawiony na np. 36pt
- Header z ciemnym tłem: `marginTop: -36` (negatywny) — żeby header zaczynał się od krawędzi
- Content pod headerem: `paddingHorizontal: 40`, `paddingTop: 12`

### Strona 2+ (bez headera)
- **MUSI mieć margines górny** — `paddingTop` strony to zapewnia automatycznie
- Bez negatywnego marginu — header jest tylko na str. 1
- Treść zaczyna się z odpowiednim odstępem od góry (~36pt)

### Marginesy boczne
- Spójne `paddingHorizontal: 40` na całym dokumencie (content, RODO)

## 3. Header CV (ciemne tło z navy)

### Struktura
```
[Zdjęcie 58x58] [Imię i Nazwisko]
                 [Tytuł stanowiska]  ← ODDZIELONY od nazwiska (marginBottom: 8)
                 [email | telefon | miasto]
                 [LinkedIn]
```

### Krytyczne reguły
- **Imię i stanowisko NIE MOGĄ się nakładać** — `marginBottom: 8` na nazwisku
- Zdjęcie: `width: 58, height: 58, borderRadius: 29` — nie za duże
- `flexDirection: "row", alignItems: "center"` na headerze
- Stanowisko: lżejsza waga fontu (`fontWeight: 300`) i jaśniejszy kolor
- Dane kontaktowe: mały font (7.5-8pt), kolor `#cbd5e1`

### Spójność CV ↔ List motywacyjny
- **Identyczny styl nagłówka** (ten sam kolor, font, układ) — buduje markę osobistą
- List motywacyjny: nagłówek bez zdjęcia, tylko imię + dane kontaktowe

## 4. Typografia — rozmiary fontów

### Sprawdzone rozmiary (Montserrat)
| Element | Rozmiar | Waga |
|---------|---------|------|
| Imię (header) | 18pt | 700 |
| Stanowisko (header) | 9.5pt | 300 |
| Dane kontaktowe (header) | 7.5pt | 400 |
| Nagłówek sekcji (UPPERCASE) | 10pt | 700 |
| Podsumowanie zawodowe | 9pt | 400 |
| Nazwa stanowiska (doświadczenie) | 9.5pt | 700 |
| Nazwa firmy | 8.5pt | 500 |
| Okres zatrudnienia | 8.5pt | 600 (kolor accent) |
| Bullet pointy | 9pt | 400 |
| Wykształcenie — tytuł | 9pt | 700 |
| Wykształcenie — szczegóły | 8pt | 400 |
| Umiejętności — etykieta | 8.5pt | 700 |
| Umiejętności — wartości | 8.5pt | 400 |
| Języki/Certyfikaty | 9pt | 400/600 |
| Referencje | 8pt | 400 |
| RODO | 6pt | 400 |

### Zasada ogólna
- Jeśli na stronie 2 zostaje dużo pustej przestrzeni — **powiększ fonty** zamiast sztucznego rozciągania spacing
- Minimalny czytelny font: 8pt (RODO może być 6pt)

## 5. Spacing między elementami

### Sprawdzone wartości
| Element | marginBottom |
|---------|-------------|
| Sekcja (section) | 8 |
| Nagłówek sekcji → treść | 4 (paddingBottom: 2) |
| Pozycja doświadczenia (expItem) | 5 |
| Bullet point | 0.5 |
| Wykształcenie wpis | 2 |
| Języki/Certyfikaty blok | 4 |
| Referencje blok | 4 |
| RODO (marginTop) | 6 |

### Line height
- Body text: `1.4–1.45`
- Podsumowanie: `1.5`
- Bullet pointy: `1.4`
- RODO: `1.3`

## 6. Sekcja Umiejętności — format tabelaryczny

### NIE używaj tagów/badge'ów
- Tagi zajmują dużo miejsca i wyglądają jak "keyword soup"
- Zamiast tego: **format tabelaryczny** z etykietą kategorii + wartościami w jednej linii

### Sprawdzony format
```
Performance:    Google Ads, LinkedIn Campaign Manager, GA4, GTM, SEO/SEM, Remarketing
Marketing:      Content Marketing B2B, E-mail Marketing, Marketing Automation, Lead Generation
Zarządzanie:    Zarządzanie zespołem, budżetem i projektami, Wsparcie sprzedaży
Targi / Eventy: Organizacja targów i konferencji międzynarodowych, Treści B2B PL/EN
Narzędzia AI:   Claude, ChatGPT, Gemini, Midjourney, ElevenLabs, automatyzacje z AI
```

### Implementacja (@react-pdf/renderer)
```tsx
<View style={{ flexDirection: "row", marginBottom: 2 }}>
  <Text style={{ fontSize: 8.5, fontWeight: 700, width: 95 }}>{label}:</Text>
  <Text style={{ fontSize: 8.5, flex: 1, lineHeight: 1.4 }}>{items}</Text>
</View>
```

## 7. Sekcja Referencje — kompaktowa

### Format jednolinijkowy
- Referencje w jednej linii, oddzielone " | "
- Pod spodem: "Pisemne referencje dostępne na życzenie." (mniejszy font)
- Oszczędza ~3-4 linie vs. format listy

## 8. Zapobieganie rozrywaniu pozycji między stronami

### Problem
- Nazwa stanowiska na dole str. 1, a firma i bullet pointy na str. 2

### Rozwiązanie
```tsx
<View key={i} style={expItem} wrap={false}>
  {/* cała pozycja doświadczenia */}
</View>
```
- `wrap={false}` na elemencie doświadczenia — cała pozycja przenosi się na nową stronę jeśli się nie mieści

## 9. Doświadczenie zawodowe — styl narracyjny

### NIE rób
- Listy keywords zamiast opisów
- Ogólnikowe "zarządzanie kampaniami", "prowadzenie działań"
- Brak efektów/wyników

### RÓB
- Bullet pointy zaczynające się od **czasownika dokonanego** (zaprojektowałem, wdrożyłem, opracowałem)
- **Kontekst firmy** w nazwie: "TERMA Sp. z o.o. — producent urządzeń przemysłowych"
- **Efekty/korzyści** w każdym punkcie: "co przełożyło się na wzrost leadów", "osiągając X% wzrost sprzedaży"
- Wzmianka o referencjach przy firmach, które je wystawiły

## 10. ATS-compatibility

### Format pliku
- PDF text-based (nie skan) — `@react-pdf/renderer` generuje poprawny text-based PDF
- Jednokolumnowy layout (bez tabel, grafik, ikon w treści)
- Standardowe nagłówki sekcji: "Podsumowanie zawodowe", "Doświadczenie zawodowe", "Wykształcenie", "Umiejętności"

### Keywords
- 15-25 keywords z ogłoszenia naturalnie wplecionych w treść
- 60-80% pokrycia fraz z opisu stanowiska
- DOKŁADNE frazy z ogłoszenia (nie synonimy)
- Keyword stuffing (>4-5 powtórzeń) = odrzucenie przez ATS

### Scoring
- Cel: 70+ (akceptowalne), 80+ (doskonałe)
- CV = 80-90% score, list motywacyjny = 10-20%

## 11. Checklist przed wygenerowaniem

- [ ] CV zmieści się na 2 stronach?
- [ ] Header: imię oddzielone od stanowiska (marginBottom: 8)?
- [ ] Strona 2 ma margines górny?
- [ ] Pozycje doświadczenia nie rozrywają się między stronami (wrap={false})?
- [ ] Umiejętności w formacie tabelarycznym (nie tagi)?
- [ ] Referencje kompaktowe (jedna linia)?
- [ ] RODO na dole ostatniej strony z treścią?
- [ ] Bullet pointy z efektami/wynikami?
- [ ] Keywords z ogłoszenia wplecione naturalnie?
- [ ] Spójny nagłówek CV ↔ list motywacyjny?
- [ ] List motywacyjny na 1 stronie?
- [ ] Dane w CV spójne z listem (lata doświadczenia, tytuły)?

## 12. Kolory (design tokens)

```typescript
const C = {
  primary: "#1e293b",    // dark navy — nagłówki, imię
  accent: "#2563eb",     // blue — linie akcentowe, daty
  accentLight: "#dbeafe", // jasny blue — tło nagłówka
  text: "#334155",       // ciemny szary — body text
  textLight: "#64748b",  // szary — firmy, daty, meta
  textMuted: "#94a3b8",  // jasny szary — RODO
  white: "#ffffff",
};
```

## 13. Font Montserrat — rejestracja

```typescript
Font.register({
  family: "Montserrat",
  fonts: [
    { src: "...Montserrat...Cs16Ew...", fontWeight: 300 }, // Light
    { src: "...Montserrat...Ctr6Ew...", fontWeight: 400 }, // Regular
    { src: "...Montserrat...CtZ6Ew...", fontWeight: 500 }, // Medium
    { src: "...Montserrat...Cu170w...", fontWeight: 600 }, // SemiBold
    { src: "...Montserrat...CuM70w...", fontWeight: 700 }, // Bold
  ],
});
Font.registerHyphenationCallback((word) => [word]); // Wyłącz dzielenie (polskie znaki)
```

## Zależności
- `@react-pdf/renderer` — generacja PDF z React components
- Font: Montserrat (Google Fonts, wagi 300-700)
- Polskie znaki: `registerHyphenationCallback` wyłącza dzielenie wyrazów
