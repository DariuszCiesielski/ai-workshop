---
name: gemma4-vision
description: >
  Lokalny model Gemma 4 12B przez Ollama do zadań wizualnych: OCR dokumentów,
  analiza screenshotów UI, generowanie promptów ComfyUI/Stable Diffusion.
  Używaj gdy zadanie wymaga rozumienia obrazu. NIE używaj do kodowania ani
  analizy tekstu — do tego Qwen 2.5 Coder 32B jest lepszy.
---

# Gemma 4 Vision — Skill użycia lokalnego modelu

## Kiedy używać

| Zadanie | Użyj Gemma 4 | Użyj Qwen Coder |
|---------|--------------|-----------------|
| OCR dokumentu (faktura, umowa, skan) | ✅ | ❌ |
| Analiza screenshota UI | ✅ | ❌ |
| Opis zdjęcia produktu | ✅ | ❌ |
| Generowanie promptu do ComfyUI/SD | ✅ | ❌ |
| Kodowanie TypeScript/Python | ❌ | ✅ |
| Klasyfikacja/destylacja tekstu | ❌ | ✅ |
| Analiza kodu, debugowanie | ❌ | ✅ |

## Wywoływanie

### Tekst + obraz (vision)

```bash
IMAGE_B64=$(base64 -i /path/to/image.png)
curl -s -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"gemma4\",
    \"prompt\": \"<TWÓJ PROMPT>\",
    \"images\": [\"$IMAGE_B64\"],
    \"stream\": false,
    \"options\": { \"temperature\": 0.2, \"num_predict\": 2048 }
  }" | jq -r '.response'
```

### Z Pythona

```python
import requests, base64

def gemma4_vision(image_path: str, prompt: str, temperature: float = 0.2) -> str:
    with open(image_path, "rb") as f:
        image_b64 = base64.b64encode(f.read()).decode()
    
    resp = requests.post("http://localhost:11434/api/generate", json={
        "model": "gemma4",
        "prompt": prompt,
        "images": [image_b64],
        "stream": False,
        "options": {"temperature": temperature, "num_predict": 2048},
    }, timeout=120)
    return resp.json()["response"]
```

### Z TypeScript (server-side)

```typescript
async function gemma4Vision(imagePath: string, prompt: string): Promise<string> {
  const imageB64 = readFileSync(imagePath).toString("base64");
  const resp = await fetch("http://localhost:11434/api/generate", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: "gemma4",
      prompt,
      images: [imageB64],
      stream: false,
      options: { temperature: 0.2, num_predict: 2048 },
    }),
  });
  const data = await resp.json();
  return data.response;
}
```

## Optymalne parametry

| Zadanie | temperature | num_predict | num_ctx |
|---------|------------|-------------|---------|
| OCR (faktura, umowa) | 0.1 | 2048 | 8192 |
| Analiza UI | 0.2 | 1024 | 8192 |
| ComfyUI prompt | 0.5 | 1024 | 8192 |
| Opis produktu | 0.3 | 1024 | 8192 |

## Prompty gotowe do użycia

### OCR faktury/dokumentu
```
This is a document/invoice. Extract ALL information in structured format:
1) Document type and number
2) Date
3) Parties (names, addresses, tax IDs)
4) Line items (description, quantity, price, total)
5) Total amount
6) Payment terms
7) Any other visible text
Be precise — this is for accounting/legal purposes.
```

### Analiza screenshota UI
```
You are a UX consultant. Analyze this UI screenshot:
1) What type of application is this?
2) Main user actions available
3) List 3 UX issues or improvements
4) Read all visible text (OCR)
Be concise and actionable.
```

### Prompt do ComfyUI/Stable Diffusion
```
You are a prompt engineer for Stable Diffusion / ComfyUI.
Analyze this image and generate:
1) Positive prompt (max 100 words): lighting, background, composition, style
2) Negative prompt (max 30 words)
3) Settings as JSON: {steps, cfg_scale, resolution}
Output as JSON only.
```

### Opis produktu ze zdjęcia
```
Describe this product image for an e-commerce listing:
1) Product name and type
2) Key features visible
3) Materials/textures
4) Colors (specific names or hex)
5) Suggested marketing headline (max 10 words)
Write in Polish.
```

## Benchmark (2026-04-09, Mac Studio M4 Max 64GB)

| Test | Wynik | Tokens/s |
|------|-------|----------|
| OCR strony logowania (PL) | Doskonały — wszystkie teksty PL | 88 t/s |
| OCR faktury PDF (Cursor) | Doskonały — NIP, kwoty, adresy | 88 t/s |
| ComfyUI prompt generation | Doskonały — poprawny JSON | 87 t/s |
| Analiza UI (error page) | Trafna identyfikacja | 88 t/s |
| Tekst baseline | 90 t/s | 90 t/s |

## Ograniczenia

- **Nie do kodowania** — Qwen 2.5 Coder 32B jest znacznie lepszy
- **Nie do długich tekstów** — context 8K, nie 128K jak Qwen
- **OCR literówki** — może mylić I/1/l, O/0 w małych fontach (typowe dla OCR)
- **Nie jednocześnie z Qwen** — Ollama ładuje/wyładowuje (kilka sekund przełączania)
- **Tylko localhost** — model lokalny, nie dostępny z Vercel
