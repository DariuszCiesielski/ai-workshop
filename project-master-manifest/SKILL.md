---
name: project-master-manifest
description: Zarządzanie manifestami projektów (project-meta.json) — śledzenie statusu, features, skilli i zależności. Używaj przy inicjalizacji nowego projektu, po zakończeniu zadania, lub gdy użytkownik prosi o aktualizację manifestu/stanu projektu.
---

# Skill: Project Master — Manifest Management

## Cel
Zarządzanie manifestami projektów w ekosystemie Project Master. Ten skill zapewnia spójność danych między projektami i centralnym repozytorium.

## Kiedy używać

### Automatycznie (zawsze)
- **Nowy projekt**: Przy inicjalizacji nowego projektu ZAWSZE utwórz `project-meta.json` w katalogu głównym
- **Po zakończeniu zadania**: Zaktualizuj manifest jeśli dodałeś/usunąłeś feature, wdrożyłeś skill lub ukończyłeś task z `next_steps`

### Na żądanie użytkownika
- "Zaktualizuj manifest" / "Odśwież project-meta"
- "Jaki jest stan projektu?" — przeczytaj manifest i podsumuj
- "Dodaj X do next_steps" — zaktualizuj sekcję manual

## Lokalizacja manifestu
- **W projekcie (lokalny cache)**: `./project-meta.json` w katalogu głównym projektu
- **Centralne repo**: `project-master-data/manifests/{slug}.json`

Przy pracy nad projektem operuj na lokalnym `project-meta.json`. Synchronizacja z centralnym repo odbywa się automatycznie przez GitHub Actions przy każdym pushu.

## Zasady aktualizacji

### Sekcja `auto` — aktualizuj swobodnie
Pola wypełniane automatycznie na podstawie analizy kodu. Przy istotnych zmianach zaktualizuj:
- `detected_features` — jeśli dodałeś auth, payments, landing page itp.
- `routes_count`, `components_count` — jeśli znacząco się zmieniły
- `env_vars` — jeśli dodałeś nowe zmienne środowiskowe

### Sekcja `manual` — pytaj przed zmianą
**Nigdy nie nadpisuj sekcji manual bez potwierdzenia użytkownika**, z wyjątkiem:
- Przenoszenie skilla z `skills_needed` do `skills_active` po wdrożeniu
- Usuwanie ukończonego taska z `next_steps`
- Aktualizacja `last_review` na dzisiejszą datę

Przed zmianą `status`, `phase`, `priority` lub dodaniem nowych `next_steps` — ZAWSZE zapytaj użytkownika.

## Tworzenie manifestu dla nowego projektu

```json
{
  "slug": "nazwa-projektu",
  "name": "Nazwa Projektu",
  "description": "",
  "repo": "USERNAME/nazwa-projektu",
  "url_production": null,
  "url_staging": null,
  "auto": {
    "last_push": "2026-01-01T00:00:00Z",
    "last_push_message": "initial commit",
    "branch_default": "main",
    "tech_stack": {
      "framework": "next.js",
      "language": "typescript",
      "database": "supabase",
      "styling": "tailwind",
      "deployment": "vercel"
    },
    "dependencies_count": 0,
    "detected_features": {
      "auth": { "detected": false, "evidence": [] },
      "payments": { "detected": false, "evidence": [] },
      "landing_page": { "detected": false, "evidence": [] },
      "multi_tenant": { "detected": false, "evidence": [] },
      "i18n": { "detected": false, "evidence": [] },
      "onboarding": { "detected": false, "evidence": [] },
      "analytics": { "detected": false, "evidence": [] },
      "testing": { "detected": false, "evidence": [] },
      "seo": { "detected": false, "evidence": [] },
      "ci_cd": { "detected": false, "evidence": [] }
    },
    "routes_count": 0,
    "components_count": 0,
    "env_vars": []
  },
  "manual": {
    "status": "planning",
    "phase": "idea",
    "priority": "medium",
    "category": "product",
    "target_audience": "",
    "revenue_model": "none",
    "skills_active": [],
    "skills_needed": [],
    "blocked_by": [],
    "depends_on": [],
    "next_steps": [],
    "notes": "",
    "last_review": null
  }
}
```

Po utworzeniu pliku ZAPYTAJ użytkownika o wypełnienie sekcji manual:
1. Jaki jest status i faza projektu?
2. Jaki priorytet?
3. Kategoria (product/tool/client/learning/experiment)?
4. Jakie są następne kroki?

## Po zakończeniu zadania — checklist

1. ✅ Czy dodałem nowy feature? → Zaktualizuj `detected_features`
2. ✅ Czy wdrożyłem skill? → Przenieś z `skills_needed` do `skills_active`
3. ✅ Czy ukończyłem task z `next_steps`? → Usuń go z listy
4. ✅ Czy dodałem nowe env vars? → Dodaj do `env_vars` i `.env.example`
5. ✅ Czy zmieniłem routing? → Zaktualizuj `routes_count`

## Wdrażanie skilla globalnego

Gdy użytkownik prosi o wdrożenie skilla (np. "dodaj płatności", "dodaj auth"):

1. Sprawdź w manifeście, czy skill jest w `skills_needed`
2. Wczytaj szablon instrukcji z `project-master-data/skills/{skill}/instruction-template.md`
3. Dostosuj szablon do kontekstu projektu (tech stack, istniejące features)
4. Wdróż skill zgodnie z instrukcją
5. Zaktualizuj manifest:
   - `skills_needed` → usuń skill
   - `skills_active` → dodaj skill
   - `detected_features.{skill}.detected` → `true`
   - `next_steps` → usuń powiązane taski

## Generowanie instrukcji

Gdy użytkownik prosi o wygenerowanie instrukcji dla Claude Code / Cursor:

```markdown
# Instrukcja: [TYTUŁ]

## Projekt
- Nazwa: [z manifestu]
- Repo: [z manifestu]  
- Tech: [z manifestu.auto.tech_stack]
- Stan: [z manifestu.manual.status / phase]

## Kontekst
[Co już jest zrobione — z detected_features]
[Co blokuje — z blocked_by]

## Zadania
[Z wybranych next_steps]

## Wymagania techniczne
[Z szablonu skilla jeśli dotyczy]

## Definicja ukończenia
- [ ] Feature działa
- [ ] Manifest zaktualizowany
- [ ] Przetestowane manualnie
```

## Walidacja kontekstu z użytkownikiem

Przed pierwszą sesją pracy w projekcie (lub po długiej przerwie) wykonaj checkpoint walidacji kontekstu:

1. **Zbierz kontekst** — przeczytaj manifest, PRD (jeśli istnieje), ostatnie commity
2. **Skompiluj podsumowanie** — przedstaw użytkownikowi:

```
📋 Kontekst projektu — potwierdź aktualność:

**Cel projektu:** [z manifestu / PRD]
**Aktywne integracje:** [lista z detected_features]
**Planowane funkcje (z PRD):** [lista — WERYFIKUJ czy nadal aktualne]
**Wyłączone / porzucone:** [co wiesz że NIE wchodzi w scope]
**Następne kroki:** [z next_steps]

Czy to nadal aktualne? Coś do usunięcia lub dodania?
```

3. **Czekaj na odpowiedź** — dopiero po potwierdzeniu / korekcie użytkownika zacznij pracę

### Dlaczego to ważne

PRD może zawierać przestarzałe założenia (np. integracje, z których zrezygnowano). Bez checkpoint'u AI realizuje stare wymagania, produkując martwy kod. Checkpoint kosztuje 30 sekund i zapobiega godzinom czyszczenia.

### Kiedy pomijać checkpoint

- Krótkie, jasno określone zadanie ("popraw bug w X") — nie potrzeba
- Użytkownik sam dał wystarczający kontekst w wiadomości — nie potrzeba
- Kontynuacja pracy z tej samej sesji — nie potrzeba

## Ważne zasady
- Manifest to **source of truth** — traktuj go poważnie
- Nie zgaduj statusów — jeśli nie wiesz, zapytaj użytkownika
- Nie usuwaj danych z sekcji manual bez potwierdzenia
- Przy konflikcie między kodem a manifestem — zaktualizuj manifest
- Zawsze dodawaj `evidence` do `detected_features` (ścieżki plików)
- PRD może być przestarzały — zawsze weryfikuj z użytkownikiem przy nowej sesji
