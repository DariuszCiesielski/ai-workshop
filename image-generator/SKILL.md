---
name: image-generator
description: Generowanie obrazów AI z prompt engineeringiem (5-komponentowa formuła, tryby domenowe, presety brandowe). Używa AI Gateway + Gemini 3.1 Flash Image Preview + Vercel Blob. Triggery — "wygeneruj obraz", "zrób grafikę", "stwórz thumbnail", "hero image", "banner", "grafika social media", "logo", "ikona", "zdjęcie produktu", "image generation", "generate image", "zrób zdjęcie".
---

# Image Generator — AI Image Generation z Prompt Engineering

Generowanie obrazów AI z zaawansowanym prompt engineeringiem. Bazuje na 5-komponentowej formule promptu (Google Prompting Guide 2026), 7 trybów domenowych dopasowanych do polskiego rynku, presety brandowe per klient.

## Stack techniczny

- **Model:** `google/gemini-3.1-flash-image-preview` via AI Gateway (JEDYNY zalecany model)
- **API:** AI SDK v6 `generateText()` → `result.files` (NIE `experimental_generateImage`)
- **Storage:** Vercel Blob (`@vercel/blob`) — trwałe URL, CDN
- **Persystencja:** wzorzec `ai-generation-persistence` (ID + metadata + cost tracking)
- **Auth:** OIDC via `vercel env pull` (bez ręcznych kluczy API)

## Kiedy używać

- Generowanie grafik marketingowych (hero images, banery, thumbnails)
- Zdjęcia produktowe i packshoty
- Grafiki social media (Instagram, LinkedIn, Facebook)
- Ikony i elementy brandingowe
- Tła i ilustracje do aplikacji
- Batch generation wariantów do A/B testów
- Elementy wizualne do content pipeline

## Kiedy NIE używać

- Edycja istniejących zdjęć (→ dedykowany image editor)
- Generowanie UI/mockupów (→ Stitch 2.0 / `stitch-claude-workflow`)
- Proste ikony SVG (→ Lucide/Heroicons)

---

## Formuła 5-komponentowa (OBOWIĄZKOWA)

NIGDY nie przekazuj surowego tekstu użytkownika do modelu. ZAWSZE konstruuj prompt z 5 komponentów:

| # | Komponent | Waga | Co zawiera |
|---|-----------|------|-----------|
| 1 | **Subject** | 30% | Kto/co jest głównym obiektem. Fizyczne szczegóły: tekstura, materiał, wiek, wyraz twarzy. NIGDY "a person" — ZAWSZE "A weathered ceramicist in his 70s, deep sun-etched wrinkles..." |
| 2 | **Action** | 10% | Co robi, poza, gest, ruch. Silne czasowniki w present tense: "floats weightlessly", "holds a glowing lantern" |
| 3 | **Location/Context** | 15% | Gdzie + pora dnia + warunki atmosferyczne. "Inside a modern co-working space at golden hour", "on a rain-slicked Warsaw street at dusk" |
| 4 | **Composition** | 10% | Perspektywa kamery, kadrowanie, relacje przestrzenne. "Medium shot centered", "extreme low-angle looking up", "flat lay from directly above" |
| 5 | **Style** | 25% | Estetyka + oświetlenie + referencje. "Shot on Sony A7R IV, warm Rembrandt lighting, Vanity Fair editorial aesthetic" |

### Przykład transformacji

**Użytkownik mówi:** "Zrób zdjęcie kawy na biurku"

**Wygenerowany prompt:**
```
A steaming ceramic pour-over coffee in a handmade stoneware mug with
visible glaze drips, placed on a light oak desk with scattered notebooks
and a mechanical keyboard partially visible. Warm morning sunlight
streaming through floor-to-ceiling windows, casting long golden shadows
across the desk surface. Overhead flat-lay composition with shallow depth
of field, the coffee cup centered in the lower third. Shot on Fujifilm
X-T5 with 35mm f/1.4 lens, natural warm tones, Kinfolk magazine lifestyle
editorial aesthetic.
```

---

## 7 trybów domenowych

### 1. Marketing (hero images, banery, landing pages)
- **Kamery:** Canon EOS R5, Sony A7R IV
- **Oświetlenie:** bright diffused studio, dramatic rim light, golden hour
- **Kompozycja:** rule of thirds, negative space for text overlay, wide aspect ratio
- **Referencje:** "WIRED magazine feature", "Apple product launch aesthetic"
- **Tip:** Zostaw pustą przestrzeń na tekst — "with generous negative space in the upper third for headline overlay"

### 2. Product (packshoty, e-commerce)
- **Powierzchnie:** polished marble, brushed concrete, gradient sweep, raw linen
- **Oświetlenie:** softbox diffused, rim separation, tent lighting
- **Kąty:** 45-degree hero, flat lay, three-quarter, straight-on
- **Referencje:** "Apple product photography", "Aesop minimal aesthetic"
- **Tip:** Produkt "prominently displayed" — kluczowa fraza dla widoczności

### 3. Content (thumbnails blogów, newsletterów, artykułów)
- **Styl:** conceptual illustration, editorial photography, infographic-inspired
- **Kompozycja:** centered subject, clean background, strong focal point
- **Referencje:** "Medium article header", "Substack newsletter cover"
- **Tip:** Prostota > złożoność. Thumbnail musi działać w 100x100px

### 4. Social (Instagram, LinkedIn, Facebook, stories)
- **Formaty:** 1:1 (feed), 4:5 (portrait feed), 9:16 (stories/reels), 16:9 (LinkedIn cover)
- **Styl:** vibrant, scroll-stopping, high contrast
- **Referencje:** "Instagram lifestyle aesthetic", "LinkedIn professional photography"
- **Tip:** "iPhone 16 Pro Max front-facing portrait mode" dla autentycznego social vibe

### 5. Brand (logotypy, ikony, elementy identyfikacji)
- **Konstrukcja:** geometric primitives, golden ratio, negative space
- **Kolory:** max 2-3 kolory, działa w monochromatyce
- **Output:** "on solid white background" (post-process do transparent)
- **Tip:** "bold geometric sans-serif lettermark" dla nowoczesnych logotypów

### 6. Editorial (fashion, lifestyle, reportaż)
- **Kamery:** Fujifilm X-T4, Leica Q2, Hasselblad X2D
- **Obiektywy:** 85mm f/1.4, 50mm f/1.2, 135mm f/2
- **Referencje:** "Vogue Italia", "National Geographic", "GQ editorial spread"
- **Tip:** Pozy: "candid mid-gesture", "editorial lean", "movement blur"

### 7. SaaS (dashboard screenshoty, tech marketing, feature illustrations)
- **Style:** glassmorphism, flat vector, isometric 3D, gradient mesh
- **Kolory:** podawaj dokładne hex values: "cool blues #2563EB to #1E40AF"
- **Referencje:** "Stripe dashboard aesthetic", "Linear app design language"
- **Tip:** "frosted glass effect with 20% opacity, subtle grid lines" dla glassmorphism

---

## ZAKAZANE słowa (pogarszają jakość w Gemini)

NIGDY nie używaj tych terminów z ery Stable Diffusion/Midjourney:

| ZAKAZANE | UŻYJ ZAMIAST TEGO |
|----------|-------------------|
| "4K", "8K", "ultra HD" | Podaj konkretną rozdzielczość lub pomiń |
| "masterpiece" | "Pulitzer Prize-winning photograph" |
| "highly detailed", "ultra detailed" | Opisz KONKRETNE szczegóły: "visible pores", "individual hair strands" |
| "trending on artstation" | "Architectural Digest interior" |
| "hyperrealistic", "photorealistic" | Nazwij kamerę i obiektyw: "Shot on Canon EOS R5 at 85mm f/1.4" |
| "best quality" | "National Geographic cover story" |
| "award winning" | "Magnum Photos documentary aesthetic" |

### Prestigeous context anchors (zamienniki)

Zamiast pustych przymiotników, używaj prestiżowych kontekstów:
- **Fotografia:** "Vanity Fair editorial portrait", "WIRED magazine feature spread"
- **Wnętrza:** "Architectural Digest interior", "Dezeen architecture feature"
- **Jedzenie:** "Bon Appétit magazine cover", "Kinfolk lifestyle editorial"
- **Moda:** "Vogue Italia fashion editorial", "Harper's Bazaar cover shoot"
- **Tech:** "Apple keynote product reveal", "Stripe marketing visual"

---

## Positive framing (brak negative prompts w Gemini)

Gemini NIE obsługuje negative prompts. Przeformułuj negatywne instrukcje:

| Użytkownik mówi | Prompt |
|------------------|--------|
| "bez ludzi" | "empty, deserted, uninhabited space" |
| "bez tekstu" | "NEVER include any text, labels, or watermarks" |
| "nie rozmyte" | "tack-sharp detail, crisp focus throughout" |
| "bez tła" | "on solid bright green (#00FF00) chroma key background" |
| "nie ciemne" | "brightly lit, high-key lighting, airy atmosphere" |

**Wzmacnianie ograniczeń — ALL CAPS:**
- "MUST contain exactly three figures"
- "NEVER include any visible text or labels"
- "ONLY show the product, nothing else in frame"

---

## 10 taktyk jakości (quality boosters)

1. **Nazywaj prawdziwe kamery:** "Sony A7R IV", "Canon EOS R5", "iPhone 16 Pro Max"
2. **Podawaj dokładny obiektyw:** "85mm f/1.4", "35mm f/2.8", "24-70mm f/2.8"
3. **Specyficzne cechy fizyczne:** "24yo with olive skin, hazel eyes, freckles across nose bridge"
4. **Nazywaj marki dla stylizacji:** "Tom Ford suit", "Muji stoneware", "Herman Miller chair"
5. **Mikro-szczegóły:** "condensation droplets on glass", "individual eyelashes", "thread texture on fabric"
6. **Kontekst platformy:** "Instagram lifestyle aesthetic", "LinkedIn professional headshot"
7. **Opisuj tekstury:** "crinkle-textured", "metallic silver", "frosted glass", "raw concrete"
8. **Czasowniki czynnościowe:** "mid-stride", "pouring carefully", "captured mid-laugh"
9. **Prestigeous anchors** (zamiast "ultra-realistic"): "Vanity Fair editorial", "National Geographic cover"
10. **Dla produktów:** zawsze "prominently displayed" + nazwij powierzchnię

---

## Renderowanie tekstu w obrazach

- **Max 25 znaków** na niezawodne renderowanie
- **Max 2-3 oddzielne frazy** — więcej pogarsza jakość
- Tekst w **cudzysłowie:** `with the text "OPEN DAILY"`
- Opisuj cechy czcionki, nie nazwy: "bold geometric sans-serif in white"
- Określaj pozycję: "centered at the upper third"
- **Wysoki kontrast:** jasny tekst na ciemnym tle lub odwrotnie
- **Text-first hack:** jeśli tekst jest kluczowy, opisz go PRZED resztą sceny

---

## Presety brandowe

Presety zapisuj w projekcie (np. `lib/image-presets.ts` lub `config/brand-presets/`):

```typescript
interface ImagePreset {
  name: string;
  description: string;
  colors: string[];           // hex values
  style: string;              // bazowy styl wizualny
  lighting: string;           // domyślne oświetlenie
  mood: string;               // nastrój/ton
  defaultRatio: string;       // "16:9" | "1:1" | "4:5" | "9:16"
  typography?: string;        // styl tekstu (jeśli dotyczy)
}
```

### 3 gotowe presety startowe

```typescript
const presets: Record<string, ImagePreset> = {
  "tech-saas": {
    name: "Tech SaaS",
    description: "Czysty, nowoczesny styl dla produktów technologicznych",
    colors: ["#2563EB", "#1E40AF", "#F8FAFC"],
    style: "clean minimal tech illustration, flat vectors, soft shadows, glassmorphism accents",
    lighting: "bright diffused studio, no harsh shadows",
    mood: "professional, trustworthy, modern, innovative",
    defaultRatio: "16:9",
  },
  "luxury-brand": {
    name: "Luxury Brand",
    description: "Premium, ekskluzywny styl dla marek luksusowych",
    colors: ["#1A1A1A", "#C9A96E", "#FAF3E6"],
    style: "high-end product photography, dramatic lighting, rich textures, deep shadows",
    lighting: "dramatic chiaroscuro, warm golden accents, deep shadows",
    mood: "exclusive, sophisticated, aspirational, timeless",
    defaultRatio: "4:5",
  },
  "editorial-magazine": {
    name: "Editorial Magazine",
    description: "Odważny styl redakcyjny, fashion i lifestyle",
    colors: ["#000000", "#FFFFFF", "#E11D48"],
    style: "bold editorial photography, high contrast, statement compositions",
    lighting: "mixed — natural + studio fill, dramatic rim light",
    mood: "provocative, confident, artistic, bold",
    defaultRatio: "3:4",
  },
};
```

**Logika scalania presetu z promptem:**
1. `colors` → informują opisy palety w komponentach Context i Style
2. `style` → staje się bazą dla komponentu Style
3. `lighting` → wchodzi do komponentu Style (podsekcja oświetlenia)
4. `mood` → wpływa na Action i Location/Context
5. **Instrukcje użytkownika ZAWSZE nadpisują wartości presetu**

---

## Implementacja — kod generowania

### Generowanie pojedynczego obrazu

```typescript
import { generateText } from "ai";
import { put } from "@vercel/blob";
import { nanoid } from "nanoid";

interface GenerateImageOptions {
  prompt: string;              // Pełny 5-komponentowy prompt
  aspectRatio?: string;        // "16:9" | "1:1" | "4:5" | "9:16" | "3:4"
  generationId?: string;       // ID dla persystencji
}

async function generateImage({ prompt, aspectRatio = "16:9", generationId }: GenerateImageOptions) {
  const id = generationId ?? nanoid();

  // Dodaj aspect ratio do promptu (Gemini nie ma osobnego parametru)
  const fullPrompt = aspectRatio !== "1:1"
    ? `${prompt}\n\nAspect ratio: ${aspectRatio}`
    : prompt;

  const result = await generateText({
    model: "google/gemini-3.1-flash-image-preview",
    providerOptions: {
      google: { responseModalities: ["TEXT", "IMAGE"] },
    },
    prompt: fullPrompt,
  });

  const imageFiles = result.files?.filter(f => f.mediaType?.startsWith("image/")) ?? [];

  if (imageFiles.length === 0) {
    throw new Error("Model nie wygenerował obrazu. Spróbuj przeformułować prompt.");
  }

  // Zapisz do Vercel Blob
  const file = imageFiles[0];
  const ext = file.mediaType?.split("/")[1] || "png";
  const blob = await put(`generations/${id}.${ext}`, file.uint8Array, {
    access: "public",
    contentType: file.mediaType ?? "image/png",
  });

  return {
    id,
    url: blob.url,
    mediaType: file.mediaType,
    prompt: fullPrompt,
    model: "google/gemini-3.1-flash-image-preview",
    usage: result.usage,
  };
}
```

### Batch generation (warianty)

```typescript
async function generateVariants(
  basePrompt: string,
  variations: Array<{ component: string; value: string }>,
) {
  const results = await Promise.all(
    variations.map(async (v, i) => {
      // Podmień jeden komponent na wariant
      const variantPrompt = applyVariation(basePrompt, v.component, v.value);
      return generateImage({
        prompt: variantPrompt,
        generationId: `batch-${nanoid(6)}-${i}`,
      });
    })
  );
  return results;
}

// Przykład użycia:
// generateVariants(basePrompt, [
//   { component: "style", value: "warm golden hour, Kinfolk editorial" },
//   { component: "style", value: "cool blue hour, moody WIRED magazine" },
//   { component: "composition", value: "extreme close-up, macro detail" },
// ]);
```

### Green screen → transparent background

```typescript
// Gemini NIE generuje przezroczystych teł.
// Workaround: generuj na zielonym tle, potem usuń zielony.

// Krok 1: Dodaj do promptu
const transparentPrompt = `${prompt}, on a solid bright green (#00FF00) chroma key background with a thin white outline separating the subject from the background`;

// Krok 2: Post-process (wymaga ImageMagick na serwerze lub zewnętrznego serwisu)
// magick input.png -fuzz 20% -transparent "#00FF00" output.png
// magick output.png -channel A -blur 0x1 -level 50%,100% -trim +repage final.png
```

---

## Pipeline agenta (jak Claude powinien pracować)

Gdy użytkownik prosi o wygenerowanie obrazu:

```
1. PRZECZYTAJ ten skill (prompt engineering, tryby, zakazane słowa)
2. ANALIZUJ intencję:
   → Jaki tryb domenowy? (marketing/product/content/social/brand/editorial/saas)
   → Jaki format? (aspect ratio)
   → Czy jest preset brandowy?
   → Jeśli request jest niejasny → PYTAJ o szczegóły
3. ZBUDUJ prompt 5-komponentowy:
   → Subject (30%): co dokładnie, z fizycznymi szczegółami
   → Action (10%): co robi, jaki ruch/gest
   → Location (15%): gdzie + pora dnia + atmosfera
   → Composition (10%): kąt, kadrowanie, perspektywa
   → Style (25%): estetyka + oświetlenie + referencje
4. SPRAWDŹ prompt pod kątem:
   → Zakazane słowa (zamień na prestigeous anchors)
   → Negative framing (zamień na positive)
   → Tekst > 25 znaków (uprość lub podziel)
5. POKAŻ prompt użytkownikowi (opcjonalnie, przy złożonych zadaniach)
6. WYGENERUJ obraz via generateText()
7. ZAPISZ do Vercel Blob
8. POKAŻ wynik + podsumowanie (model, aspect ratio, URL)
```

---

## Gotowe szablony promptów

### SaaS / Tech Marketing
```
A floating glassmorphism UI card on a deep charcoal background showing
a content analytics dashboard with a rising line graph in teal (#14B8A6),
bar charts in coral (#F97316), and a circular progress indicator at 94%.
Subtle grid lines, frosted glass effect with 20% opacity, teal glow
bleeding from the card edges. Clean premium SaaS aesthetic, Stripe
marketing visual language.
```

### Product / E-commerce
```
[PRODUKT] with condensation/texture details, surrounded by complementary
props that tell a story. [POWIERZCHNIA] surface with [OŚWIETLENIE].
Commercial photography for advertising campaign, vibrant complementary
colors. Product prominently displayed. Bon Appétit / Apple product
photography aesthetic.
```

### Social Media / Lifestyle
```
A [WIEK]-year-old [OPIS FIZYCZNY] posing [POZA] in [LOKACJA] during
[PORA DNIA]. [DETALE UBIORU]. Captured with [KAMERA] at [OBIEKTYW],
shallow depth of field with [BOKEH]. [PLATFORM] lifestyle aesthetic.
```

### Content Thumbnail
```
A conceptual [STYL] illustration representing [TEMAT]. [GŁÓWNY ELEMENT
WIZUALNY] centered on a [TŁO]. Clean composition with strong focal
point, works at small sizes. [REFERENCJA] magazine header aesthetic.
```

### Hero Image / Landing Page
```
[SCENA] with generous negative space in the upper third for headline
overlay. [OŚWIETLENIE] creating [NASTRÓJ]. Wide 16:9 composition,
subject positioned at left third. [ESTETYKA] with [REFERENCJA
PRESTIŻOWA]. Shot on [KAMERA], [OBIEKTYW].
```

---

## Szacowanie kosztów

| Rozdzielczość | Koszt/obraz (USD) | Koszt/obraz (PLN ~4.0) |
|--------------|-------------------|------------------------|
| 512px | ~$0.02 | ~0.08 PLN |
| 1K | ~$0.04 | ~0.16 PLN |
| 2K (default) | ~$0.08 | ~0.32 PLN |

**Batch 10 wariantów w 2K ≈ $0.80 ≈ 3.20 PLN**

---

## Anti-patterny promptów (NIE rób tego)

- "A dark-themed Instagram ad showing..." — za meta, opisuje koncept, nie obraz
- "A sleek SaaS dashboard visualization..." — abstrakcyjne, brak kotwic wizualnych
- "Modern, clean, professional..." — niewyraźne przymiotniki bez substancji
- "A bold call to action with..." — opisuje cel marketingowy, nie zawartość
- Opisywanie co widz powinien czuć — zamiast tego opisz co TWORZY to uczucie

---

## Integracja z ekosystemem

- **Marketing Hub** → presety per klient, batch generation, content pipeline
- **Kreator Grafik** → generowane tła i elementy do szablonów
- **AIwBiznesie Launchpad** → hero images przy scaffoldingu
- **Content pipeline** → automatyczne thumbnails blogów/newsletterów
- **Stitch workflow** → generowane assety jako uzupełnienie designu UI
