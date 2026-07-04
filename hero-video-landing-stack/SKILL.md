---
name: hero-video-landing-stack
description: Workflow budowy landing page z cinematic AI hero video. Używaj dla PoC/MVP stron produktowych z efektownym wideo w hero. NIE używaj dla finalnych stron komercyjnych wymagających i18n, CMS, A/B testów ani gdy klient nie akceptuje ryzyka prawnego AI video.
harness_level: planner-generator-evaluator
---

# Hero Video Landing Stack

## Kiedy używać
- PoC landing page w <2h (pitch/demo dla prospecta)
- Launch page produktu, gdzie hero video robi 80% impact
- Wewnętrzne eksperymenty (portfolio, AI w Biznesie, showcase)
- Feature w Kreatorze stron www / Starter Pack (template "Landing z hero video")

## Kiedy NIE używać
- Finalne strony komercyjne klientów (patrz ryzyka prawne niżej)
- Projekty wymagające CMS, i18n PL/EN, A/B testów, analytics stacku
- Klienci z branż regulowanych (medyczna, finansowa, dziecięca)
- Gdy klient nie akceptuje ryzyka pochodzenia danych treningowych AI video

## Stack (zweryfikowany, stan kwiecień 2026)

### Warstwa wideo (wybierz jedną, NIE Seedance dla klientów komercyjnych)
1. **Veo 3.1 (Google)** — rekomendowany default. Czystsze pochodzenie danych.
2. **Kling 2.5 Turbo** — backup, dobry stosunek jakość/cena.
3. **Seedance 2.0 (Higgsfield)** — TYLKO do wewnętrznych eksperymentów/demo. Ryzyko: cease&desist Disney/Paramount z lutego 2026.

### Warstwa obrazów referencyjnych
- **Nano Banana (Gemini 2.5 Flash Image)** — reference images, moodboardy, ikony
- Fallback: lokalny ComfyUI (setup dla e-com product shots)

### Warstwa kodu
- **Claude Code** jako primary builder
- Next.js 16 + Tailwind + shadcn/ui
- Opcjonalnie: react-konva jeśli trzeba editable hero (integracja z Kreator Grafik)

### Warstwa hosting wideo
- **Cloudinary** — CDN, adaptive streaming, transformacje, poster image
- NIE surowy `<video>` tag z pliku — zawsze przez Cloudinary (skill: `cloudinary-upload`)

### Warstwa deploy
- GitHub → Vercel preview URL
- Custom domain tylko na prośbę klienta

### Warstwa audio (opcjonalna)
- **ElevenLabs** — voiceover do wideo lub embedded voice agent (synergia z voicebotem)
- Użyj tylko gdy klient chce interaktywny element głosowy

## Pipeline (Planner → Generator → Evaluator)

### Planner
Input: brief (branża, produkt, target, ton)
Output:
- 3 warianty hero concept (różne kąty narracyjne)
- Spec wideo: prompt, długość (5-10s), kamera, mood, audio tak/nie
- Wireframe sekcji: hero, value prop, social proof, CTA
- Checklista ryzyk prawnych (logo brand, postaci, muzyka, głosy)

### Generator
1. Wygeneruj 3 reference images w Nano Banana (hero moodboard)
2. Wygeneruj 2 warianty wideo w Veo 3.1 (porównaj, nie pierwszy lepszy)
3. Upload wideo do Cloudinary (adaptive streaming + poster)
4. Claude Code buduje stronę z Cloudinary video URL w hero
5. Auto-commit do GitHub, Vercel preview deploy

### Evaluator
Checklist przed pokazaniem:
- [ ] Wideo ładuje się <3s na mobile (Cloudinary adaptive)
- [ ] Fallback poster image dla wolnych łącz
- [ ] Brak rozpoznawalnych twarzy/logotypów/postaci chronionych prawem
- [ ] CTA jasne w pierwszych 2s wideo
- [ ] Accessibility: `prefers-reduced-motion` respektowane, alt text
- [ ] Core Web Vitals: LCP <2.5s, CLS <0.1
- [ ] Polski tekst z pełnymi diakrytykami

## Wariant hotelarski (synergia z voicebotem)
Pattern: "cinematic hero video + embedded voice agent"
- Hero: 5-10s wideo pokoi/lobby/widoków
- Pod hero: widget ElevenLabs voice agent (rezerwacja, pytania)
- Case study: Hotel Demo (2 leady dzień 1)
- Ten wariant łączy 2 unikalne kompetencje

## Red flags z marketingowych postów
- Realny czas dobrego PoC: 1-3h (nie "10 minut bez kodu")
- "Bez kodu" = Claude Code pisze kod, ale musisz umieć debugować
- "$10K design" = efekt wow w demie; produkcja wymaga CMS, testów, iteracji

## Koszty (orientacyjnie, kwiecień 2026)
- Veo 3.1: ~$0.50-2 / 5s clip
- Nano Banana: ~$0.05 / obraz
- Cloudinary: free tier wystarcza na PoC
- Claude Code: w ramach planu
- Vercel preview: free tier
- **Total PoC**: $3-15 w credits + czas (~1-3h)
