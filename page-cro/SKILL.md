---
name: page-cro
description: >
  Optymalizacja konwersji stron (CRO): CTA, above the fold, social proof, formularze, A/B testy.
  Triggery: "optymalizacja konwersji", "CRO", "popraw konwersję", "CTA", "above the fold",
  "social proof", "formularz konwersji", "landing page optymalizacja", "bounce rate",
  "więcej leadów", "więcej rejestracji", "conversion rate".
---

# Page CRO — Optymalizacja konwersji stron

Audytuje i optymalizuje strony pod kątem konwersji: CTA, above the fold, social proof, formularze, mikro-interakcje. Cel: więcej rejestracji, leadów, zakupów przy tym samym ruchu.

## Kiedy używać

- Audyt landing page pod kątem konwersji
- Poprawa bounce rate na kluczowych stronach
- Projektowanie formularzy konwersji (signup, contact, trial)
- Dodawanie social proof (testimoniale, liczniki, logo klientów)
- Optymalizacja CTA (tekst, kolor, placement)
- Użytkownik mówi: "popraw konwersję", "więcej leadów", "landing page nie konwertuje"

## Zależności

- **Wymagane:** `product-marketing-context` → `cro-best-practices.md`, `features.md`
- **Opcjonalne:** `copywriting` → teksty CTA i nagłówków
- **Opcjonalne:** `analytics-tracking` → mierzenie wyników optymalizacji
- **Opcjonalne:** `unified-design-system` → spójność wizualna

## Framework CRO: 5 filarów

### 1. Above the Fold (pierwsze 600px)

Użytkownik decyduje w 3-5 sekund. ATF musi odpowiedzieć na 3 pytania:
1. **Co to jest?** → nagłówek (benefit, nie feature)
2. **Dlaczego mnie to obchodzi?** → podnagłówek (konkretna wartość)
3. **Co mam zrobić?** → CTA (jedno, jasne, kontrastowe)

```
✅ Dobrze:
[Nagłówek] Automatyzuj sprzedaż w 5 minut
[Podnagłówek] Więcej leadów, mniej ręcznej roboty. Bez kodowania.
[CTA] Zacznij za darmo →

❌ Źle:
[Nagłówek] Witamy w naszej platformie
[Podnagłówek] Innowacyjne rozwiązanie AI dla biznesu
[CTA] Dowiedz się więcej | Zarejestruj się | Kontakt
```

#### Checklist ATF:
- [ ] Nagłówek mówi o WYNIKU (nie o produkcie)
- [ ] Podnagłówek zawiera konkret (liczba, czas, porównanie)
- [ ] Jeden główny CTA (nie 2-3 konkurujące)
- [ ] CTA ma kolor kontrastowy do tła
- [ ] Obrazek/screenshot pokazuje produkt w akcji
- [ ] Brak menu hamburgera na desktop (pełna nawigacja)

### 2. Social Proof

Ludzie robią to, co robią inni. Hierarchia skuteczności:

| Typ | Siła | Przykład |
|-----|------|---------|
| **Case study z liczbami** | ★★★★★ | "Firma X zwiększyła sprzedaż o 340% w 3 miesiące" |
| **Testimonial ze zdjęciem** | ★★★★ | Cytat + imię + firma + zdjęcie twarzy |
| **Logo klientów** | ★★★ | Pas logotypów znanych marek |
| **Liczniki** | ★★★ | "2,500+ firm", "50,000+ wysłanych ofert" |
| **Oceny/gwiazdki** | ★★ | "4.8/5 na G2", "Rated #1 on Product Hunt" |
| **Testimonial bez zdjęcia** | ★ | Cytat + inicjały (niskie zaufanie) |

```tsx
// Wzorzec: testimonial card
<figure className="border rounded-lg p-6">
  <blockquote className="text-lg mb-4">
    "Od kiedy używamy [Produkt], nasz czas odpowiedzi spadł z 24h do 2h."
  </blockquote>
  <figcaption className="flex items-center gap-3">
    <img src="/avatars/jan.jpg" alt="Jan Kowalski" className="w-10 h-10 rounded-full" />
    <div>
      <div className="font-medium">Jan Kowalski</div>
      <div className="text-sm text-muted-foreground">CEO, Acme sp. z o.o.</div>
    </div>
  </figcaption>
</figure>
```

#### Placement social proof:
- **Blisko CTA** — tuż pod/nad przyciskiem rejestracji
- **Po sekcji features** — "nie wierz nam, posłuchaj klientów"
- **W hero** — mały pasek z logo lub "zaufało nam 2500+ firm"
- **Na pricing** — testimonial pod każdym planem

### 3. CTA (Call to Action)

#### Zasady skutecznego CTA:
1. **Tekst = akcja + wartość**: "Zacznij za darmo" > "Zarejestruj się" > "Submit"
2. **Kolor kontrastowy** do reszty strony (ale spójny z brand)
3. **Jeden główny CTA** per viewport (secondary CTA = ghost button)
4. **Powtarzaj CTA** co 2-3 sekcje na long-form pages
5. **Micro-copy pod CTA** redukuje friction: "Bez karty kredytowej · Darmowy plan na zawsze"

```tsx
// Wzorzec: CTA z micro-copy
<div className="flex flex-col items-center gap-2">
  <Button size="lg" className="text-lg px-8 py-6">
    Zacznij za darmo →
  </Button>
  <p className="text-sm text-muted-foreground">
    Bez karty kredytowej · Setup w 2 minuty
  </p>
</div>
```

#### Tekst CTA — formuły:

| Formuła | Przykład |
|---------|---------|
| Akcja + Benefit | "Zwiększ sprzedaż teraz" |
| Zacznij + Modifier | "Zacznij za darmo", "Zacznij 14-dniowy trial" |
| Zdobądź + Obiekt | "Pobierz darmowy raport", "Zdobądź demo" |
| Dołącz + Social | "Dołącz do 2500+ firm" |

### 4. Formularze

Każde dodatkowe pole = -10% konwersji (benchmark).

| Cel formularza | Pola minimum | Konwersja benchmark |
|---------------|-------------|-------------------|
| Newsletter | Email | 3-8% |
| Free trial | Email + hasło | 5-15% |
| Lead gen (B2B) | Email + imię + firma | 2-5% |
| Kontakt | Email + wiadomość | 1-3% |
| Zakup | Email + płatność | 1-4% |

#### Optymalizacja formularzy:

```
✅ TAK:
- Inline validation (błąd przy polu, nie na górze)
- Autofocus na pierwszym polu
- Placeholder jako hint, nie jako label
- Submit button z opisem akcji ("Wyślij wiadomość" nie "Submit")
- Progress bar dla multi-step forms
- Ukryj opcjonalne pola za "Pokaż więcej"

❌ NIE:
- Captcha na first-touch forms (zabija konwersję)
- Wymaganie telefonu na etapie awareness
- Reset button obok Submit
- Podwójne potwierdzenie email
- Dropdown zamiast radio dla 2-4 opcji
```

### 5. Redukcja friction

Friction = wszystko co stoi między użytkownikiem a konwersją.

| Friction | Rozwiązanie |
|----------|-------------|
| "Nie wiem ile to kosztuje" | Pokaż ceny na stronie (nie "skontaktuj się") |
| "Muszę podać kartę" | "Bez karty kredytowej" pod CTA |
| "Za dużo opcji" | Wyróżnij recommended plan |
| "Nie wiem co się stanie" | "Kliknij → dostajesz X w 2 minuty" |
| "A co jeśli mi się nie spodoba?" | "30-dniowa gwarancja zwrotu" |
| "Nie ufam tej firmie" | Social proof, logo klientów, certyfikaty |
| "Strona wolno się ładuje" | Optymalizuj LCP < 2.5s |
| "Na telefonie nie mogę" | Responsywny formularz, duże touch targets |

## Audyt CRO — checklist

Przy audycie strony przejdź przez te punkty:

### Above the Fold
- [ ] Nagłówek komunikuje benefit (nie feature)
- [ ] Podnagłówek ma konkret (liczba/czas/porównanie)
- [ ] Jeden główny CTA widoczny bez scrollowania
- [ ] Screenshot/demo produktu
- [ ] Micro-copy pod CTA redukuje friction

### Social Proof
- [ ] Minimum 1 forma social proof na stronie
- [ ] Testimoniale mają zdjęcia i pełne dane
- [ ] Social proof blisko CTA
- [ ] Liczby są konkretne ("2,547 firm" nie "tysiące")

### CTA
- [ ] Tekst CTA = akcja + wartość
- [ ] Kolor kontrastowy
- [ ] CTA powtórzony co 2-3 sekcje
- [ ] Secondary CTA nie konkuruje wizualnie

### Formularze
- [ ] Minimum pól (tylko niezbędne)
- [ ] Inline validation
- [ ] Submit z opisem akcji
- [ ] Brak captcha na first-touch

### Ogólne
- [ ] Strona ładuje się < 3s (LCP < 2.5s)
- [ ] Mobilna wersja jest pełnoprawna (nie okrojona)
- [ ] Brak pop-upów w pierwszych 30 sekundach
- [ ] Exit intent popup (opcjonalnie, nie agresywny)
- [ ] Sticky CTA na mobile (bottom bar)

## Pułapki CRO

1. **Optymalizacja bez danych** → zawsze mierz baseline przed zmianami
2. **A/B test przy niskim ruchu** → potrzebujesz ~1000 konwersji na wariant
3. **Kopiowanie konkurencji** → ich kontekst jest inny (brand, trust, ruch)
4. **Dark patterns** → ukryte koszty, wymuszony signup — krótkoterminowy wzrost, długoterminowa utrata zaufania
5. **Za dużo zmian naraz** → nie wiesz co zadziałało, testuj jedną rzecz
