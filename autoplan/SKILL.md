---
name: autoplan
description: Sekwencyjny review planu przez 4 perspektywy (growth / design / architektura / DX) PRZED wdrożeniem. Surfacuje tylko taste decisions wymagające zgody, automatyczne sugestie scalają w jeden raport OK/CHANGE/QUESTION. Trigger: "review planu", "audyt planu", "/autoplan", po `gsd:plan-phase`, przed dużymi zmianami architektonicznymi. Implementuje §3 CLAUDE.md (zakwestionuj kierunek + pytania z rekomendacją) systemowo.
---

# Autoplan — Multi-perspective Plan Review

Automatyzacja 4-perspektywowego review planu PRZED kodem. Friction-removal — wszystkie skille review już są w ekosystemie, ale odpalanie ich osobno = często pomijam któryś. Jeden punkt wejścia, jeden raport.

## Kiedy używać

- **Przed implementacją** dużej zmiany (4+ pliki, multi-warstwa, architektura)
- Po `gsd:plan-phase` — pre-execution gate
- Na żądanie: "review planu", "audyt planu", "/autoplan", "co o tym myślisz"
- Gdy user pisze nowy plan strategiczny w `.planning/`
- **Auto-trigger** (rekomendacja): zanim Claude napisze plan dłuższy niż 50 linii, sam puścić plan przez `autoplan`

## Kiedy NIE używać

- Pojedynczy bugfix / drobna zmiana (§3 CLAUDE.md "nie kwestionuj drobnych")
- Plan czysto operacyjny (cron, infra setup, deploy) bez decyzji architektonicznych
- User mówi "działaj sam, bez review"
- Plan to lista TODO / handoff (nie wymaga 4 perspektyw)

## Wejście

**Plan jako input** — jedna z opcji:
1. Ścieżka do pliku `.md` (np. `.planning/PLAN-feature-X.md`)
2. Treść inline w wiadomości
3. Output `gsd:plan-phase` (PHASE_PLAN.md)

Skill pyta **raz** jeśli wejście niejasne ("Czy review dotyczy planu w [ścieżka]?").

## 4 Perspektywy — chain reviewerów

### Perspektywa 1 — Growth (skill: `growth-lead`)
**Pytania:**
- Czy ten plan rozwiązuje **realny problem** (priority/painfulness vs alternatywy)?
- Czy scope jest minimalny (najkrótsza droga do walidacji), czy "fajne by było"?
- Czy istnieje **istniejące narzędzie** w stacku które rozwiązuje to bez nowej budowy?
- Czy success metrics są mierzalne (nie "lepszy UX", a "TTFB <500ms" / "konwersja +X%")?

**Verdict:** OK / CHANGE (z konkretną sugestią) / QUESTION (jeśli nie wiadomo dlaczego)

### Perspektywa 2 — Design (skill: `web-design-guidelines`)
**Tylko jeśli plan dotyczy UI / UX / frontend.** Pomiń dla backend-only.

**Pytania:**
- Mobile responsiveness uwzględniony (375/768/1024)?
- Spójność z istniejącym design systemem (`unified-design-system` 6 motywów)?
- Polskie znaki (latin-ext, zgodnie z §13 CLAUDE.md)?
- Accessibility (WCAG 2.2): kontrast, focus states, keyboard navigation?
- Skeleton loaders / loading states zaplanowane?

### Perspektywa 3 — Architektura (skill: `architecture-designer`)
**Pytania:**
- Stack zgodny z ekosystemem (Next.js App Router + Supabase + Tailwind v4)?
- Edge runtime jako default (lesson [2026-04-27]) — chyba że Node deps niezbędne?
- RLS na każdej nowej tabeli? service_role tylko server-side?
- Cron endpointy mają `export const GET = POST` (lesson [2026-04-17])?
- Webhook routes mają `dynamic = "force-dynamic"` + `fetchCache = "force-no-store"` (lesson [2026-04-02])?
- Migracje Supabase przez MCP **MUSZĄ** być wyeksportowane do `supabase/migrations/` (lesson [2026-04-27])?
- Atomic transactions dla operacji multi-row (insert documents + insert evidence + update status)?

### Perspektywa 4 — DX (warunkowo, gdy plan dotyczy SDK / API / CLI / public skill)
**Pomiń dla internal feature.** Aktywuj gdy:
- Plan zakłada eksport API endpoint dla zewnętrznych klientów
- Plan zakłada nowe narzędzie CLI / skill publikowany do `polish-agent-skills`
- Plan zakłada dokumentację user-facing

**Pytania:**
- Onboarding < 5 minut?
- Konkretny use-case + persona w README (lesson z gstack: viral booster)?
- Przykłady end-to-end (nie tylko reference)?
- Error messages actionable (mówią CO zrobić, nie tylko CO się zepsuło)?

## Faza implementacyjna — orchestracja

### Krok 1: Klasyfikacja planu (~30s)
Przeczytaj plan, zaklasyfikuj **typ** (Backend / Frontend / Fullstack / Infrastructure / Skill+Doc). Decyduje które perspektywy aktywować.

| Typ | Growth | Design | Architektura | DX |
|---|---|---|---|---|
| Backend | ✅ | — | ✅ | conditional |
| Frontend | ✅ | ✅ | ✅ | — |
| Fullstack | ✅ | ✅ | ✅ | conditional |
| Infrastructure | ✅ (priority/cost) | — | ✅ | — |
| Skill+Doc | ✅ | — | conditional | ✅ |

### Krok 2: Spawn reviewers (równolegle)
Użyj **Agent tool** z `general-purpose` lub odpowiedni `subagent_type`. Dla każdej aktywnej perspektywy:

```
Agent({
  description: "Plan review — [Perspective name]",
  subagent_type: "general-purpose",
  prompt: "Jesteś [perspektywa]. Przeczytaj plan w [ścieżka]. Oceń wg pytań z [skill SKILL.md sekcja]. Zwróć JSON: {verdict: 'OK'|'CHANGE'|'QUESTION', findings: [{issue, severity: 'critical'|'high'|'low', suggestion?}], confidence: 0-1}. Max 200 słów per finding.",
  run_in_background: true
})
```

**Dlaczego równolegle:** każdy reviewer niezależny, brak shared state. Wyjście pojawia się szybciej.

### Krok 3: Aggregate (~30s po powrocie wszystkich)
Czekaj na wszystkie powiadomienia o zakończeniu. Następnie:

**Klasyfikacja per finding:**
- 4× OK → **Plan zatwierdzony** (raport: "All clear")
- 1+ CHANGE z severity=critical → **Plan wymaga rewrite** (raport pokazuje CO i KTO sugeruje)
- ≥2 perspektywy wzajemnie sprzeczne → **TASTE DECISION** (raport pyta usera o decyzję)
- 1+ QUESTION → włącz w sekcję "Questions for human"

**Detect konsensusu vs sprzeczność:**
- Konsensus: 2+ perspektyw flaguje to samo issue (severity zgodna)
- Sprzeczność: perspektywa A mówi "rozszerz scope o X", perspektywa B mówi "ogranicz scope, X jest premature"

### Krok 4: Cross-model deep review (opcjonalnie)
Gdy stakes są wysokie (plan strategiczny / "fundament biznesowy") — wywołaj `cross-model-review` skill jako 5-tą perspektywę: Codex+Qwen niezależne. To dodaje 5-8 min, ale lesson [2026-04-26] mówi że jest **OBOWIĄZKOWY** dla planów strategicznych.

User decyzja `deep` mode w wywołaniu: "/autoplan deep [plan]" — aktywuje tę fazę.

### Krok 5: Surface raport

```markdown
# Autoplan Report — [plan-name] @ [ISO timestamp]

**Plan:** [path] ([X linii])
**Typ:** [Backend/Frontend/Fullstack/Infrastructure/Skill+Doc]
**Perspektywy aktywne:** [Growth, Architektura, ...]

## Verdict: [GO / GO_WITH_CHANGES / NO_GO / DECISION_NEEDED]

### ✅ Konsensus (czego wszyscy zgadzają się)
- [bullet]

### 🔴 Critical findings (wymaga fix przed kodem)
| Perspektywa | Finding | Sugestia |
|---|---|---|
| Architektura | Brak Edge runtime default | Dodaj `export const runtime = 'edge'` |

### 🟡 Suggestions (do rozważenia, niesblokujące)
| Perspektywa | Finding | Sugestia |
|---|---|---|

### ❓ Questions for human (taste decisions)
1. **[Topic]:** Growth mówi A, Architektura mówi B. Decyzja zależy od [factor X którego nie znam].
   - Opcja A: ...
   - Opcja B: ...
   - Rekomendacja autoplan: [opcja Y, bo ...]

### Confidence breakdown
- Growth: 0.85 (high)
- Architektura: 0.70 (medium — niejasne X)
- Design: skipped (backend-only)
```

## Decyzja „GO/NO_GO"

| Sytuacja | Verdict |
|---|---|
| 4× OK lub 3× OK + 1× CHANGE z low severity | **GO** |
| Wszystkie OK ale ≥1 CHANGE z high severity | **GO_WITH_CHANGES** (pokaż diff sugerowany do planu) |
| 1+ CHANGE z critical severity | **NO_GO** (rewrite plan, re-run autoplan) |
| Sprzeczność między perspektywami | **DECISION_NEEDED** (user decyzja, nie auto-merge) |

## Pułapki

### ❌ Auto-zatwierdzanie przy konsensusie 4×OK
**Objaw:** plan przeszedł 4× OK ale realnie ma ukryty bug
**Przyczyna:** każda perspektywa ma blind spot — Growth nie sprawdza migracji DB, Architektura nie sprawdza copywritingu
**Rozwiązanie:** GO ≠ "implementuj bez myślenia". Raport pokazuje CONFIDENCE per perspektywa. <0.7 → user widzi flag "low confidence".

### ❌ Spam reviewerów dla drobiazgów
**Objaw:** plan na 1 plik z 20 liniami przeszedł przez 4 perspektywy = overkill
**Przyczyna:** brak short-circuit
**Rozwiązanie:** **plan <50 linii i <3 plików** → pomiń autoplan, użyj prostego `code-reviewer` skilla. Auto-decyzja w Krok 1.

### ❌ Reviewer halucynuje znajomość codebasu
**Objaw:** Architektura mówi "twoja istniejąca tabela X powinna mieć kolumnę Y" — ale tabela X nie ma takiego użycia
**Przyczyna:** subagent nie ma kontekstu codebasu, halucynuje na podstawie patternów
**Rozwiązanie:** w prompcie subagenta WYMUŚ `Read` istniejących plików przed verdict. Jeśli reviewer cytuje plik bez `file_path:line_number` → flag halucynacji.

### ❌ Sprzeczność jako "QUESTION" zamiast wymuszenia rozstrzygnięcia
**Objaw:** plan utknął bo Growth+Architektura mówią różne rzeczy, user musi decydować, decyzja odkładana
**Przyczyna:** brak meta-rozstrzygnięcia
**Rozwiązanie:** dla każdej sprzeczności pokaż **Rekomendację autoplanu** (jaką decyzję BY podjął gdyby musiał). User akceptuje 1 słowem ("OK A" / "OK B") zamiast pisać esej.

### ❌ Pomija CLAUDE.md ekosystemu
**Objaw:** review nie sprawdza czy plan zgodny z §3 (zakwestionuj kierunek), §16 (prostota w kodzie), §18 (port 1:1 przed optymalizacją)
**Przyczyna:** subagenci nie czytają CLAUDE.md projektu
**Rozwiązanie:** w każdy reviewer prompt wstrzyknij relevant §§ z CLAUDE.md global + projektu. Format: "Twoje review MUSI sprawdzić zgodność z: [§16 prostota, §18 port 1:1, §22 próbka przed batchem]".

### ❌ Lesson learned nie propagują się do planu
**Objaw:** plan zakłada `runtime='nodejs'` mimo że lesson [2026-04-27] mówi "Edge default"
**Przyczyna:** plan napisany bez przeczytania CLAUDE.md Lessons Learned
**Rozwiązanie:** Architektura reviewer ZAWSZE skanuje plan pod kątem Lessons Learned (regex po lesson IDs lub kluczowych frazach). Każda kolizja = critical finding.

## Integration z innymi skillami

| Skill | Relacja |
|---|---|
| `gsd:plan-phase` | **Po** plan-phase, **przed** execute-phase. autoplan = pre-execution gate. |
| `cross-model-review` | autoplan deep mode wywołuje cross-model jako 5-tą perspektywę. |
| `dual-agent-review` | Subset autoplanu (Codex+Claude). autoplan szerszy (4 perspektyw). |
| `the-fool` | Adversarial mode — można dodać jako 6-tą perspektywę dla planów wysokiego ryzyka. |
| `code-reviewer` | Po implementacji, NIE przed (autoplan=pre-code, code-reviewer=post-code). |
| `superpowers:writing-plans` | Możesz wywołać autoplan w trakcie pisania planu (iteracja przed komitem). |

## Decyzje projektowe

- **Równolegle, nie sekwencyjnie** — żaden reviewer nie zależy od drugiego, równoległe = 4× szybciej
- **Subagenci, nie inline** — każda perspektywa ma własny kontekst, brak cross-contamination
- **JSON jako interchange format** — łatwy aggregate, łatwy regex po severity
- **Surface tylko QUESTIONs + critical CHANGEs** — user nie chce czytać 4 raportów, chce decyzji
- **Confidence per perspective** — gdy 0.5, raport mówi "Architektura niska pewność, sprawdź sam"
- **Deep mode opcjonalny** — domyślnie 4 perspektywy ($0 marginal w Claude Code), Codex+Qwen tylko gdy user explicitly poprosi
