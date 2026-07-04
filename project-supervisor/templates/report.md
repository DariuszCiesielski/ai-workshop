# Raport Supervisora — {{DATA}}

> Tryb: {{TRYB}} | Projekty: {{ILOŚĆ}} | Czas: {{CZAS_WYKONANIA}}

---

## Podsumowanie

| Metryka | Wartość |
|---------|--------|
| Projekty sprawdzone | {{PROJEKTY_TOTAL}} |
| Deploye OK | {{DEPLOY_OK}} |
| Deploye FAILED | {{DEPLOY_FAILED}} |
| Deploye BUILDING | {{DEPLOY_BUILDING}} |
| Tabele bez RLS | {{TABELE_BEZ_RLS}} |
| Migracje niezsynchronizowane | {{MIGRACJE_NIESYNC}} |
| Otwarte PR | {{PR_OPEN}} |
| Otwarte Issues | {{ISSUES_OPEN}} |

### Ocena ogólna: {{OCENA}} (OK / UWAGA / KRYTYCZNE)

---

## Deploye Vercel

| Projekt | Status | URL | Ostatni deploy | Uwagi |
|---------|--------|-----|----------------|-------|
{{DEPLOY_TABLE}}

---

## Alerty (wymagają akcji)

{{#ALERTY}}

### {{ALERT_LEVEL}} — {{PROJEKT}} — {{OPIS}}

**Szczegóły:**
{{SZCZEGÓŁY}}

**Propozycja fix:**
{{FIX}}

**Deleguj do:** {{SKILL_REF}}

{{/ALERTY}}

{{#BRAK_ALERTÓW}}
Brak alertów — wszystkie projekty OK.
{{/BRAK_ALERTÓW}}

---

## Supabase Health

| Projekt | Migracje | RLS | Tabele bez RLS | Uwagi |
|---------|----------|-----|----------------|-------|
{{SUPABASE_TABLE}}

---

## GitHub

| Projekt | Otwarte PR | Otwarte Issues | Najstarszy PR |
|---------|-----------|----------------|---------------|
{{GITHUB_TABLE}}

---

## Rekomendacje na dziś

1. {{REKOMENDACJA_1}}
2. {{REKOMENDACJA_2}}
3. {{REKOMENDACJA_3}}

---

## Porównanie z poprzednim raportem

| Metryka | Poprzedni | Teraz | Trend |
|---------|-----------|-------|-------|
{{TREND_TABLE}}

---

*Raport wygenerowany: {{TIMESTAMP}} | Skill: project-supervisor | Tryb: {{TRYB}}*
