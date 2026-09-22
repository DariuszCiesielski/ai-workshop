# Mechanika motywów szklanych (Szkło / Szkło jasne) — wzorce produkcyjne

Destylacja wiedzy bojowej z wdrożeń glassmorphism w portfelu aplikacji (07-08.2026,
recenzje Qwen+Codex 2× GO_WITH_CHANGES + lekcje z produkcji). Wartości kolorów w snippetach
to wartości NASZYCH motywów `szklo`/`szklo-light` — mechanizmy są uniwersalne.
Adopcja do ekosystemu: 16.08.2026 (decyzja Dariusza).

## 1. Tokeny rozmycia + fallback zerowego kosztu

Rozmycie sterowane JEDNĄ zmienną, którą definiują wyłącznie motywy szklane:

```css
[data-theme='szklo'] {
  --glass-backdrop: blur(16px) saturate(165%);
  --glass-backdrop-heavy: blur(24px) saturate(175%);
}
[data-theme='szklo-light'] {
  --glass-backdrop: blur(16px) saturate(150%);
  --glass-backdrop-heavy: blur(24px) saturate(160%);
}

/* powierzchnie czytają zmienną; poza motywami szklanymi var() nie istnieje
   → fallback none = ZERO kosztu GPU w dark/light */
.card, .kpi { backdrop-filter: var(--glass-backdrop, none); }
.topbar, .modal, .drawer { backdrop-filter: var(--glass-backdrop-heavy, none); }
```

**Pułapka:** NIE dodawaj `--glass-backdrop: none` do `:root` „dla porządku" —
niektóre silniki traktują jawne `none` jako aktywną warstwę kompozycji.

**Mapowanie klas jest OBOWIĄZKOWE per aplikacja** — tokeny (półprzezroczyste tła)
zadziałają same, ale bez dopisania selektorów powierzchni TWOJEJ aplikacji nie będzie
rozmycia — efekt „brudnej szyby". Alternatywa: klasa-szyna `glass-surface`/`glass-heavy`.

## 2. Prefiks -webkit- — dwa sprzeczne reżimy (sprawdź pipeline!)

- **Pipeline Tailwind 4 / Lightning CSS:** ręczna para `-webkit-` + standard z `var()`
  → minifikator emituje do bundla TYLKO `-webkit-` → **Chromium bez rozmycia**
  (potwierdzone w 2 projektach, 16-17.07). REGUŁA: w źródle wyłącznie forma standardowa
  (autoprefixer dorobi parę), po buildzie **grep w dist: OBIE formy muszą być**.
- **Pipeline BEZ autoprefixera:** para ręczna KONIECZNA (Safari ≤17 rozumie tylko
  `-webkit-backdrop-filter`; bez niej „brudna szyba" na starszych iPhone'ach).

Strażnik: test E2E na `getComputedStyle(el).backdropFilter !== 'none'` w motywie szklanym.

## 3. Fallbacki obowiązkowe (dostępność) — usuwanie ich to regresja

```css
/* @supports: warunek ZAWSZE łączony — sam standard daje w Safari ≤17 fałszywy negatyw */
@supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
  [data-theme='szklo'] {
    /* powierzchnie wracają do wartości NIEPRZEZROCZYSTYCH (quasi-dark) */
    --bg-secondary: #141B29; --bg-tertiary: #10131C; /* itd. — pełne krycie */
  }
  [data-theme='szklo-light'] { /* analogicznie: pełna biel */ }
}

/* preferencja systemowa (dziś tylko Chromium — progressive enhancement) */
@media (prefers-reduced-transparency: reduce) {
  [data-theme='szklo'], [data-theme='szklo-light'] {
    --glass-backdrop: none; --glass-backdrop-heavy: none;
    /* + te same nieprzezroczyste powierzchnie co w @supports */
  }
}

/* telefon: lżejsze rozmycie (koszt GPU) */
@media (max-width: 640px) {
  [data-theme='szklo'], [data-theme='szklo-light'] {
    --glass-backdrop: blur(10px) saturate(150%);
    --glass-backdrop-heavy: blur(14px) saturate(155%);
  }
}

/* druk: szkło nigdy */
@media print {
  [data-theme='szklo'] .card, [data-theme='szklo'] .topbar,
  [data-theme='szklo-light'] .card, [data-theme='szklo-light'] .topbar {
    backdrop-filter: none; -webkit-backdrop-filter: none;
  }
}
```

## 4. Drobiazgi, które giną (z produkcji)

- **Scrollbar:** thumb dziedziczący półprzezroczysty border GINIE na poświacie —
  jawny kolor per tonacja (ciemna: chłodna biel ~0.3 alpha; jasna: chłodny szary ~0.42).
- **Ambient jest warunkiem efektu:** szkło bez poświat pod spodem = szara/biała karta.
  Jeśli aplikacja nadpisała body jednolitym tłem — najpierw przywróć glow, dopiero
  potem oceniaj motyw. Na jasnej tonacji baza tła lekko PRZYGASZONA (nie czysta biel),
  inaczej panele się nie odcinają.
- **Utility Tailwinda wygrywa z motywem:** `backdrop-blur-*` / inline `backdropFilter`
  w JSX bije selektor motywu i maskuje problem (jest JAKIEŚ rozmycie). Kontrola:
  grep `backdrop-blur|backdropFilter` w `src/**/*.tsx` → zero trafień.
- **theme-transition NIE animuje blur** — animuj tylko kolory; przejście `backdrop-filter`
  potrafi zamrozić klatkę na telefonie.
- **Glow edytuj wyłącznie w blokach motywów szklanych** — „poprawię tylko glow" w `:root`
  zmienia zaakceptowany wygląd WSZYSTKICH motywów (regresja dark/light).
- **Żadnych globalnych selektorów `input/textarea/select` w pliku motywu** — nadpisują
  style aplikacji; zmiana chirurgiczna ważniejsza (rozstrzygnięcie recenzji 16.07).

## 5. Stacking context / portale (najczęstsza realna usterka)

`backdrop-filter` czyni element containing blockiem dla `position: fixed` potomków —
panel/tooltip „przybity do viewportu" pozycjonuje się względem KARTY i się obcina.
**Dotyczy kart, nie tylko topbara** (lekcja z produkcji 3.08: panel z wnętrza `.card`
wyjeżdżał 80 px poza ekran; 40 zielonych checków tego nie łapało, bo usterka widoczna
tylko w motywach szklanych). Wszystko, co wyskakuje z karty → `createPortal` do `body`.
Tooltips bibliotek wykresów: `appendTo`/portal + nieprzezroczysty overlay.
Test: mierz POŁOŻENIE otwartego panelu w każdym motywie.

## 6. Czytelność (twarde)

1. Tekst ciągły / tabele / formularze — na powierzchni o WYŻSZYM kryciu (`-strong`,
   0.6-0.8), nigdy na najlżejszym szkle. Lekkie szkło = karty KPI/podsumowania.
2. Kontrast liczony na **WORST-CASE tła** (najjaśniejszy punkt poświaty pod kartą,
   próbnikiem ze screenshotu), nie na kolorze bazowym — AA „na papierze" ≠ na ekranie.
   WCAG nie ma algorytmu dla tła alpha+blur — worst-case to interpretacja zgodna
   z techniką G18. Na jasnej tonacji ta sama zasada odwrotnie: ciemny tekst na
   najjaśniejszym glow. Tekst wyciszony (muted) TYLKO do etykiet ≥ 11 px uppercase.
3. Szkło jasne: tekst CIEMNY (kopia tokenów light). CSS nie dziedziczy selektorowo —
   to DUPLIKACJA, po zmianie motywu light zsynchronizuj ręcznie (objaw rozjazdu:
   light i szkło jasne różnią się odcieniem tekstu).
4. Żadnego tekstu wprost na tle strony w strefach glow bez powierzchni pod spodem.

## 7. Wydajność (twarde)

1. Blur TYLKO na kontenerach (karta, KPI, bar, modal, drawer) — NIGDY na wierszach
   tabel, chipach, badge'ach (N× koszt GPU; 50 wierszy = 50 warstw = jank na iPhonie).
2. **≤ 8 powierzchni z blur na ekranie** (reguła domowa; WebKit: „use only where most
   necessary"). Grid wielu kart → blur na sekcji, nie per karta.
3. `will-change` to NIE dopalacz szkła — nie dodawać profilaktycznie (MDN: last resort).

## 8. Anty-FOUC i przełącznik

Inline script anty-FOUC waliduje motyw LISTĄ — stara wersja znająca tylko dark/light
wrzuci `szklo` w gałąź „nieznane → dark" i motyw nie przeżyje reloadu. Aktualizuj inline
script razem z hookiem. Meta `theme-color` osobno per motyw (w tym jasna wartość dla
szkła jasnego). Przy 4 motywach przełącznik = segmented/radio w UserMenu, nie cykl.
Canvas-owe wykresy czytają kolory raz — dependency na `theme` musi wymuszać re-render
(SVG z `var()` przełącza się samo).

## 9. Checklista odbioru (binarna, skrót)

- [ ] Motyw przeżywa reload (localStorage + anty-FOUC z listą zawierającą oba szkła)
- [ ] Ambient WIDOCZNY pod panelami w obu tonacjach (nie szara/biała karta)
- [ ] Safari/iPhone: rozmycie działa (obie formy w dist), scroll bez janku
- [ ] Wszystkie widoki przejrzane w OBU tonacjach: zero nieczytelnych zestawień
- [ ] Kontrast body ≥ 4.5:1 na worst-case poświaty (obie tonacje)
- [ ] Panele/modale/tooltips przez portal — zmierz położenie w każdym motywie
- [ ] `prefers-reduced-transparency` → powierzchnie lite (DevTools: Rendering → emulate)
- [ ] Druk = czytelny jasny dokument; scrollbar widoczny; zero nowych hexów w komponentach
