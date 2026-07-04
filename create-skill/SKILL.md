---
name: create-skill
description: Przewodnik tworzenia Agent Skills + auto-wykrywanie kandydatów na nowe skille. Używaj gdy użytkownik chce utworzyć, napisać lub zmodyfikować skill, pyta o strukturę skilla, lub mówi "zaproponuj nowe skille", "jakie skille brakują", "skanuj projekty pod kątem skilli", "skill gap analysis". Auto-aktywacja po zakończeniu sesji z powtarzającym się wzorcem (>3 razy ten sam typ operacji).
---

# Tworzenie skilli

Skill to folder z instrukcjami, które uczą agenta wykonywać konkretne zadania. Ten przewodnik zawiera best practices z Anthropic Engineering (marzec 2026).

## Kluczowa zasada

Agent ma ogromną wiedzę o kodowaniu i zna projekt. **Pisz TYLKO to, czego agent NIE wie** — specyficzne wzorce, nietypowe rozwiązania, pułapki. Nie powtarzaj wiedzy ogólnej.

## Przed rozpoczęciem — zbierz wymagania

1. **Cel i scope**: Jakie zadanie/workflow ma obsługiwać skill?
2. **Lokalizacja**: Osobisty (`~/.claude/skills/`) czy projektowy (`.claude/skills/`)?
3. **Triggery**: Kiedy agent ma automatycznie użyć skilla?
4. **Wiedza domenowa**: Co agent musi wiedzieć, czego NIE wie z kontekstu?
5. **Format wyjścia**: Szablony, formaty, style?
6. **Istniejące wzorce**: Konwencje do naśladowania?

Jeśli masz kontekst z rozmowy — wyciągnij skill z tego, co było omawiane.

---

## Struktura skilla

### Pełna struktura (zalecana dla złożonych skilli)

```
skill-name/
├── SKILL.md              # Wymagany — główne instrukcje (max 500 linii)
├── config.json           # Opcjonalny — konfiguracja środowiskowa
├── references/           # Opcjonalny — szczegółowa dokumentacja
│   ├── api.md
│   └── patterns.md
├── prompts/              # Opcjonalny — szablony promptów dla sub-agentów
│   └── reviewer.md
├── scripts/              # Opcjonalny — gotowe skrypty do wykonania
│   ├── validate.py
│   └── setup.sh
├── templates/            # Opcjonalny — szablony plików do wygenerowania
│   └── component.tsx
└── logs/                 # Auto-tworzony — pamięć skilla (historia uruchomień)
    └── run-2026-03-18.md
```

### Minimalna struktura (dla prostych skilli)

```
skill-name/
└── SKILL.md
```

### Lokalizacje

| Typ | Ścieżka | Zakres |
|-----|---------|--------|
| Osobisty | `~/.claude/skills/skill-name/` | Wszystkie projekty użytkownika |
| Projektowy | `.claude/skills/skill-name/` | Współdzielony z repo |

---

## SKILL.md — struktura

```markdown
---
name: your-skill-name
description: Opis KIEDY użyć (nie CO robi). Triggery sytuacyjne. Max 1024 znaków.
---

# Nazwa skilla

## Kiedy używać
Triggery aktywujące skill — frazy, sytuacje, auto-aktywacja.

## Instrukcje
Krok po kroku — co agent ma zrobić.

## Pułapki
Znane problemy, edge cases, błędy które Claude popełnia.

## Dodatkowe zasoby
- Szczegóły API: [references/api.md](references/api.md)
- Przykłady: [references/examples.md](references/examples.md)
```

### Wymagane pola metadanych

| Pole | Wymagania | Cel |
|------|-----------|-----|
| `name` | Max 64 znaków, lowercase, litery/cyfry/myślniki | Unikalny identyfikator |
| `description` | Max 1024 znaków | Agent używa do decyzji KIEDY zastosować skill |

---

## 9 zasad tworzenia skilli (Anthropic Engineering)

### 1. Pisz to, czego Claude NIE wie

Agent zna framework, język, wzorce. **Nie tłumacz mu czym jest React.**

Zamiast tego pisz:
- Specyficzne konwencje projektu/firmy
- Nietypowe workaroundy na znane bugi
- Decyzje architektoniczne i DLACZEGO tak, nie inaczej
- Wzorce które wyglądają standardowo ale mają twist

```markdown
# ❌ Marnowanie tokenów
React to biblioteka do budowania UI. Komponenty mogą mieć props i state...

# ✅ Wartościowa wiedza
W tym projekcie ZAWSZE używaj `useOptimistic` zamiast `useState` dla form mutations.
Powód: serwer jest wolny (~800ms) i UX bez optimistic update jest zły.
```

### 2. Sekcja "Pułapki" — najcenniejsza część skilla

**Obowiązkowa** w każdym niebanalnym skillu. Zbieraj tu:
- Błędy które Claude regularnie popełnia przy tym zadaniu
- Edge cases które wyglądają trywialnie ale nie są
- Ciche błędy (kod kompiluje się, ale działa źle)
- Znane bugi w bibliotekach/narzędziach

```markdown
## Pułapki

### 1. Shell interpretuje `!` w podwójnych cudzysłowach
\`\`\`bash
# ❌ bash interpretuje ! jako history expansion
echo "haslo123!"

# ✅ single quotes wyłączają interpretację
echo 'haslo123!'
\`\`\`

### 2. Nadpisanie pliku zamiast dopisania
NIGDY nie nadpisuj pliku przez `>`. Czytaj → modyfikuj → zapisz.
```

**Aktualizuj pułapki na bieżąco** po każdym feedbacku lub wykryciu nowego problemu.

### 3. Skill to folder, nie plik

Nie ograniczaj się do jednego SKILL.md. Używaj podfolderów:
- `references/` — dokumentacja API, wzorce, specyfikacje
- `prompts/` — szablony promptów dla sub-agentów/faz
- `scripts/` — gotowe skrypty do wykonania
- `templates/` — szablony plików do wygenerowania
- `assets/` — obrazy, schematy, diagramy

Agent sam sięga po pliki gdy ich potrzebuje. Linkuj z SKILL.md:
```markdown
## Dodatkowe zasoby
- Pełna dokumentacja API: [references/api.md](references/api.md)
```

**Trzymaj referencje na jednym poziomie** — linkuj bezpośrednio z SKILL.md. Głęboko zagnieżdżone referencje mogą nie zostać odczytane.

### 4. Nie mikro-zarządzaj — zostaw elastyczność

Dopasuj sztywność do kruchości zadania:

| Poziom | Kiedy | Przykład |
|--------|-------|---------|
| **Wysoki** (tekstowe wytyczne) | Wiele prawidłowych podejść | Code review |
| **Średni** (pseudokod/szablony) | Preferowany wzorzec z wariacjami | Generowanie raportów |
| **Niski** (konkretne skrypty) | Kruche operacje, spójność krytyczna | Migracje bazy |

Zbyt sztywne instrukcje = skill działa w jednym scenariuszu i łamie się przy zmianach.

### 5. Description pod Claude, nie pod człowieka

Pole `description` jest wczytywane na starcie sesji. Agent na jego podstawie decyduje czy użyć skilla.

**Pisz KIEDY użyć, nie CO robi:**

```yaml
# ❌ Opisuje CO
description: Narzędzie do zarządzania credentials w projektach

# ✅ Opisuje KIEDY
description: Bezpieczne przechowywanie danych dostępowych per projekt.
  Używaj gdy agent potrzebuje klucza API, hasła, tokenu — lub gdy
  użytkownik mówi "zapisz credentials", "zapamiętaj klucze".
```

Uwzględnij:
- **Triggery sytuacyjne** (auto-aktywacja przy błędzie 401)
- **Triggery głosowe** (użytkownik mówi "podaję dane dostępowe")
- **Kontekst negatywny** (NIE używaj do X)

### 6. Config.json — konfiguracja środowiskowa

Skill który potrzebuje kontekstu środowiska powinien mieć `config.json`:

```json
{
  "project_id": "",
  "region": "eu-central-1",
  "default_model": "claude-sonnet-4.6",
  "api_base_url": ""
}
```

**Zasady:**
- Wartości puste = agent zapyta przy pierwszym uruchomieniu
- Wartości domyślne = agent użyje bez pytania
- Skill MUSI sprawdzić config przed operacjami które go wymagają
- Nie trzymaj tu sekretów — od tego jest credentials-vault

### 7. Wbudowana pamięć — skill się uczy

Skill może zbierać dane z poprzednich uruchomień w folderze `logs/`:

```markdown
## Pamięć skilla

Po każdym uruchomieniu zapisz krótki log w `logs/`:
- `logs/run-YYYY-MM-DD-HHMM.md` — co zrobiono, co zadziałało, co nie

Przed uruchomieniem sprawdź `logs/` — ucz się z poprzednich sesji:
- Które podejścia działały w tym projekcie
- Jakie pułapki już napotkano
- Preferencje użytkownika odkryte w trakcie pracy
```

**Kiedy stosować pamięć:**
- Skill uruchamiany wielokrotnie w projekcie (deploy, audit, review)
- Wynik zależy od kontekstu który zmienia się w czasie
- Feedback z poprzednich uruchomień poprawia jakość

**Kiedy NIE stosować:**
- Jednorazowe skille (scaffolding, migracja)
- Proste skille bez stanu

### 8. Gotowe skrypty — oszczędzaj tokeny

Powtarzalne operacje = gotowy kod w `scripts/`. Bez niego agent wymyśla rozwiązanie od zera przy każdym uruchomieniu.

```markdown
## Skrypty

**validate.py** — walidacja outputu
\`\`\`bash
python scripts/validate.py output/
# Returns: "OK" lub lista błędów
\`\`\`
```

Zalety gotowych skryptów:
- Bardziej niezawodne niż generowany kod
- Oszczędzają tokeny (nie trzeba generować kodu)
- Oszczędzają czas
- Gwarantują spójność między uruchomieniami

**Jasno oznacz** czy agent ma skrypt **wykonać** czy **odczytać** jako referencję.

### 9. Hooki na żądanie

Skill może włączyć własne hooki tylko gdy go wywołasz:

```markdown
## Hooki (opcjonalne)

Ten skill instaluje tymczasowe hooki na czas działania:

### PreToolUse: blokada edycji poza folderem
Blokuje Edit/Write poza `src/components/` gdy skill jest aktywny.

### PostToolUse: auto-walidacja
Po każdym Edit uruchamia `scripts/validate.py` na zmienionym pliku.
```

**Zastosowania hooków:**
- `/careful` — blokuje `rm -rf`, `DROP TABLE`, force push
- `/freeze` — blokuje edycję poza wybranym folderem
- Auto-walidacja po każdej zmianie
- Logowanie użycia skilla (mierzenie skuteczności)

---

## Wzorce skilli

### Wzorzec: Workflow wielofazowy

```markdown
## Pipeline

### Faza 1: Skanowanie
Przeszukaj projekt pod kątem [X]. Zapisz wyniki w `output/scan.json`.

### Faza 2: Ewaluacja
Oceń wyniki skanu wg kryteriów [Y]. Użyj `prompts/evaluator.md`.

### Faza 3: Raport
Wygeneruj raport w `output/report.md`. Użyj `templates/report.md`.
```

### Wzorzec: Feedback loop

```markdown
## Proces

1. Wykonaj zmiany
2. **Waliduj natychmiast**: `python scripts/validate.py output/`
3. Jeśli walidacja nie przechodzi:
   - Przeczytaj komunikat błędu
   - Napraw problem
   - Waliduj ponownie
4. **Kontynuuj TYLKO gdy walidacja przechodzi**
```

### Wzorzec: Chain of Skills

Skill może wywoływać inne skille:

```markdown
## Zależności od innych skilli

Po wygenerowaniu CSV wywołaj skill `cloudinary-upload` do uploadu pliku.
Po zakończeniu audytu wywołaj skill `ai-crew` z briefem do code review.
```

### Wzorzec: Warunkowy routing

```markdown
## Routing

1. Oceń typ zadania:

   **Nowa funkcja?** → Faza "Scaffolding" poniżej
   **Bug fix?** → Faza "Diagnostyka" poniżej
   **Refaktor?** → Faza "Analiza" poniżej
```

---

## Anti-patterns

### 1. Powtarzanie wiedzy ogólnej
```markdown
# ❌ Agent to wie
React to biblioteka JavaScript do budowania interfejsów...

# ✅ Agent tego NIE wie
W tym projekcie wszystkie komponenty MUSZĄ eksportować displayName.
```

### 2. Brak sekcji pułapek
Najczęstszy błąd. **Każdy nietrivialny skill musi mieć `## Pułapki`.**

### 3. Zbyt dużo opcji
```markdown
# ❌ Zagmatwane
Możesz użyć pypdf, pdfplumber, PyMuPDF, pdfminer...

# ✅ Jasna domyślna z escape hatch
Używaj pdfplumber. Dla skanów z OCR: pdf2image + pytesseract.
```

### 4. Flat SKILL.md na 800+ linii
Duży skill bez podfolderów = wolne ładowanie, duplikacje, trudna nawigacja.
**Rozbij na folder**: SKILL.md (max 500 linii) + references/ + prompts/.

### 5. Informacje wrażliwe na czas
```markdown
# ❌ Szybko się zestarzeje
Jeśli robisz to przed sierpniem 2025, użyj starego API.

# ✅ Wersjonowanie
## Aktualna metoda (v2 API)
...
## Stara metoda (deprecated)
<details><summary>Legacy v1 API</summary>...</details>
```

### 6. Niespójne nazewnictwo
Wybierz jeden termin i trzymaj się go: zawsze "endpoint" (nie mieszaj z "URL", "route", "path").

### 7. Brak pułapek = brak uczenia się
Skill bez pułapek popełnia te same błędy wielokrotnie. Po każdym feedbacku DOPISZ pułapkę.

---

## Workflow tworzenia skilla

### Faza 1: Discovery
1. Zbierz wymagania (cel, lokalizacja, triggery)
2. Sprawdź `~/.claude/skills/` czy podobny skill już istnieje
3. Jeśli istnieje — uzupełnij go zamiast tworzyć nowy

### Faza 2: Design
1. Nazwa: lowercase, myślniki, max 64 znaków
2. Description: KIEDY użyć, triggery, kontekst negatywny
3. Zdecyduj: flat (SKILL.md) czy folder (references/, scripts/)
4. Zdecyduj: potrzebny config.json? pamięć? skrypty?

### Faza 3: Implementacja
1. Utwórz folder i SKILL.md z frontmatter
2. Napisz sekcje: Kiedy używać → Instrukcje → Pułapki
3. Dodaj pliki referencyjne jeśli potrzebne
4. Dodaj gotowe skrypty jeśli operacje są powtarzalne

### Faza 4: Security Scan (OBOWIĄZKOWY)

Przed zapisaniem skilla do ~/.claude/skills/ przeskanuj treść. Wzorzec z NousResearch/hermes-agent.

**Uruchom skrypt:** `bash ~/.claude/skills/create-skill/scripts/scan-skill.sh <folder-skilla>`

Skrypt sprawdza 5 kategorii: prompt injection, exfiltracja danych, niebezpieczne komendy, supply chain, zakodowane payloady.

**Reakcje na wyniki:**
- BLOCKED (critical) → nie instaluj, poinformuj użytkownika
- WARNINGS (high/medium) → ostrzeż, poproś o potwierdzenie
- CLEAN → kontynuuj

**Dla skilli z zewnętrznych źródeł (GitHub, community):**
- ZAWSZE uruchom scan przed instalacją
- Sprawdź licencję (AGPL = ograniczenia przy dystrybucji, MIT/Apache = OK)
- Sprawdź profil autora (stars, historia, inne repo)

### Faza 5: Weryfikacja jakości

Checklista jakości:

**Core:**
- [ ] Description opisuje KIEDY, nie CO
- [ ] SKILL.md ≤ 500 linii
- [ ] Pisze to, czego Claude NIE wie (nie powtarza wiedzy ogólnej)
- [ ] Spójne nazewnictwo w całym skillu

**Struktura (wg potrzeb):**
- [ ] `## Pułapki` — znane problemy i edge cases
- [ ] `config.json` — jeśli skill potrzebuje kontekstu środowiskowego
- [ ] `references/` — jeśli SKILL.md > 300 linii i ma dużo szczegółów
- [ ] `scripts/` — jeśli operacje są powtarzalne
- [ ] `logs/` instrukcja — jeśli skill uruchamiany wielokrotnie

**Anti-patterns:**
- [ ] Brak wiedzy ogólnej (agent to wie)
- [ ] Brak zbyt wielu opcji (jasna domyślna)
- [ ] Brak informacji wrażliwych na czas
- [ ] Referencje na jednym poziomie (nie zagnieżdżone)

---

## Mierzenie skuteczności skilli

Dodaj hook `PreToolUse` logujący które skille są aktywowane:

```json
{
  "event": "PreToolUse",
  "hooks": [{
    "type": "command",
    "command": "echo \"$(date -Iseconds) skill=$SKILL_NAME\" >> ~/.claude/skill-usage.log"
  }]
}
```

Analizuj log periodycznie:
- Które skille są używane najczęściej → inwestuj w ich jakość
- Które nigdy → rozważ usunięcie
- Które generują feedback → priorytetyzuj poprawki

---

## Auto-wykrywanie kandydatów na nowe skille

Wzorzec z Ubera (500+ skilli, livestream Thariq Shihipar 19.03.2026):
- Nigdy nie piszą skilli ręcznie — skanują wzorce i proponują automatycznie
- **skill-that-creates-skills** — pipeline w jednym skillu: plan→build→test→check→deploy
- **Auto-nadzorca zadań** — agent monitoruje powtarzające się wzorce i sam proponuje nowe skille
- **Marketplace** — skille tworzone przez jednego agenta, konsumowane przez innych

### Wzorzec auto-nadzorcy (inspiracja Uber)

Po zakończeniu sesji, agent powinien:
1. Sprawdzić czy wykonywał tę samą operację >3 razy
2. Jeśli tak → wygenerować draft SKILL.md z wzorca
3. Zaproponować użytkownikowi: "Zauważyłem powtarzający się wzorzec X. Stworzyć skill?"
4. Po zatwierdzeniu → pipeline: create → test (dry run) → deploy do ~/.claude/skills/

### Kiedy uruchomić auto-wykrywanie

- Na żądanie: "zaproponuj nowe skille", "skill gap analysis", "jakie skille brakują"
- Proaktywnie: po zakończeniu sesji z powtarzającym się wzorcem
- Okresowo: przy audycie ekosystemu skilli

### Źródło 1: Manifesty projektów

Skanuj `~/projekty/Project Master/project-master-data/manifests/*.json`:

```bash
# Znajdź skille potrzebne w 3+ projektach (wysoki priorytet)
cat manifests/*.json | jq -r '.manual.skills_needed[]?' | sort | uniq -c | sort -rn | head -20
```

**Reguła:** Skill potrzebny w >3 projektach = wysoki priorytet do stworzenia.

### Źródło 2: Wzorce w kodzie projektów

Skanuj repozytoria pod kątem powtarzających się wzorców technicznych:

```bash
# Per projekt: jakie technologie są używane
for dir in ~/projekty/*/; do
  echo "=== $(basename "$dir") ==="
  [ -f "$dir/package.json" ] && jq -r '.dependencies // {} | keys[]' "$dir/package.json" 2>/dev/null
done
```

**Szukaj wzorców:**
- Ta sama biblioteka w 3+ projektach BEZ dedykowanego skilla → kandydat
- Ten sam typ pliku (np. `supabase/migrations/*.sql`) w wielu projektach → kandydat na skill Data & Monitoring
- Powtarzający się pattern w `CLAUDE.md` wielu projektów → kandydat na unifikację

### Źródło 3: Historia sesji i feedback

Przeanalizuj pamięć agenta:

```
~/.claude/projects/*/memory/MEMORY.md
~/.claude/projects/*/memory/feedback_*.md
```

**Szukaj:**
- Powtarzające się poprawki (ten sam błąd naprawiany wielokrotnie) → kandydat na Gotcha w istniejącym skillu lub nowy skill Debugging
- Wzorce "zawsze robię X po Y" → kandydat na Workflow Automation skill
- Powtarzające się pytania użytkownika → kandydat na skill z gotowym szablonem

### Źródło 4: Kategorie Anthropic — gap analysis

Porównaj istniejące skille z 9 kategoriami:

| # | Kategoria | Cel pokrycia | Akcja przy braku |
|---|-----------|-------------|------------------|
| 1 | Library & SDK | Każda kluczowa biblioteka w stacku | Stwórz skill z API patterns + gotchas |
| 2 | Verification | Min. 3 skille | Priorytet: build verify, API contract, visual |
| 3 | Data & Monitoring | Min. 3 skille | Priorytet: schema map, cost monitor, metrics |
| 4 | Workflow Automation | Pokrycie powtarzalnych zadań | Identyfikuj z historii sesji |
| 5 | Scaffold & Boilerplate | Każdy typ projektu | Stwórz starter per framework |
| 6 | Code Review | Min. 2 skille | Priorytet: stack-specific, security |
| 7 | DevOps | Min. 3 skille | Priorytet: CI/CD, deploy health, rollback |
| 8 | Debugging | Min. 3 skille | Priorytet: per stack (Vercel, Supabase, React) |
| 9 | Operational | Pokrycie maintenance | Priorytet: deps check, cleanup, cost monitor |

### Format propozycji

```markdown
## Propozycja nowego skilla

**Nazwa**: [slug]
**Kategoria**: [1-9] — [nazwa kategorii]
**Priorytet**: high / medium / low
**Powód**: [dlaczego — dane z analizy]
**Źródło wykrycia**: manifesty / kod / historia / gap analysis

### SKILL.md (draft)

[Pełna treść SKILL.md gotowa do review]

### Gotchas (wstępne)

[Lista znanych pułapek — min. 3]
```

### Po zatwierdzeniu — automatyczne tworzenie

1. `mkdir -p ~/.claude/skills/[slug]/`
2. Zapisz `SKILL.md` z frontmatter
3. Dodaj `references/` i `scripts/` jeśli potrzebne
4. Zaktualizuj `project-master-data/skills/[slug]/skill.json`
5. Zaktualizuj `project-master-data/skills/registry.json`
6. Zaktualizuj `docs/CHEAT-SHEET.md` w "Moje skille"

### Pułapki auto-wykrywania

### 1. Za dużo propozycji → paraliż wyboru
**Rozwiązanie**: Max 5 propozycji na sesję. Sortuj wg ROI (ilość projektów × krytyczność kategorii).

### 2. Duplikaty — skill już istnieje pod inną nazwą
**Rozwiązanie**: Przed propozycją przeszukaj `~/.claude/skills/*/SKILL.md` pod kątem overlapping triggerów.

### 3. Zbyt niszowy skill — używany w 1 projekcie
**Rozwiązanie**: Skill globalny = min. 2 projekty. Dla jednego projektu → `.claude/skills/` w projekcie.

### 4. Manifesty nieaktualne
**Rozwiązanie**: Sprawdź datę `last_updated` w manifeście. Stary manifest (>30 dni) → przebuduj na podstawie kodu.
