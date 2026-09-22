---
name: perelki-radar
description: Analiza paczki repozytoriów / kont GitHub pod kątem perełek dla ekosystemu i zapis do bazy `perelki` (Supabase) + ślad w PM BACKLOG. Używaj gdy Dariusz wkleja listę linków github.com (często z fbclid z Facebooka), mówi "przeanalizuj te repo", "perełki", "analiza repo", "co z tych repo", "dodaj do perełek", "oceń te narzędzia z GitHub". Realizuje §35 (nigdy nie SKIP, scoring tools/eco/product, T1-T7) w LEKKIM trybie (gh api + README + ocena, NIE workflow/Opus). NIE używaj do polerowania własnego repo (→ github-repo-polish) ani analizy jednego projektu we własnym kodzie (→ Analizator repozytoriów).
---

# perełki-radar

Powtarzalny workflow: paczka linków GitHub → ocena cross-project fit → zapis do bazy `perelki` + BACKLOG. Robione regularnie (18.05, 25.05, 31.05, 05.06, 08.06…). Ten skill kodyfikuje kroki, schemat bazy i pułapki, żeby nie składać tego od nowa co raz.

## Kiedy używać
Dariusz wkleja listę URL-i `github.com/owner/repo` (zwykle z `?fbclid=...` — linki z Facebooka). Cel: ocenić każde repo pod kątem ekosystemu ~60 projektów i **zapisać wszystkie** do bazy `perelki` (nic nie ginie — §35).

## Tryb: LEKKI (krytyczne — Lessons PM 2026-05-29)
Ja (`gh api` + README + ocena z kontekstem ekosystemu) + Qwen lokalny tylko jako dodatkowy głos scoringu jeśli potrzeba.
- ❌ **NIE** Workflow tool + Opus + StructuredOutput schema — schema-enforced agenty gubią finalny tool call przy długiej prozie (3 padły 29.05, 1.49M tokenów spalonych). "tryb max" ≠ najcięższy mechanizm; znaczy najdokładniejsza ocena merytoryczna.
- Eskalacja do Workflow równoległego TYLKO gdy partia >20 repo I Dariusz świadomie akceptuje koszt tokenów.
- Słowo "workflow" w cytowanym opisie repo ≠ opt-in do Workflow tool.

## Pipeline

### 1. Metadane (równolegle, gotowy skrypt)
```bash
bash ~/.claude/skills/perelki-radar/scripts/fetch-meta.sh repos owner1/repo1 owner2/repo2 ...
```
Zwraca per repo: owner, name, stars, forks, lang, license (SPDX), pushed, created, archived, openIssues, homepage, topics, desc.
Pomijaj nie-repo (np. `github.com/trending`, `/search`) i deduplikuj linki.

### 2. Dedup vs baza (ZANIM ocenisz — nie duplikuj)
```sql
SELECT repo_owner||'/'||repo_name AS slug, status, tier FROM perelki
WHERE (repo_owner, repo_name) IN (('o1','r1'),('o2','r2'), ...);
```
Trafienie → planuj **UPDATE** (odśwież metadane+scoring+last_verified), nie INSERT.

### 3. README top kandydatów
Czytaj README tylko dla niejasnych / obiecujących (reszta = czytelna z desc, zwłaszcza listy zasobów):
```bash
bash ~/.claude/skills/perelki-radar/scripts/fetch-meta.sh readme owner/repo
```

### 4. Skan kont właścicieli (§35.2 — OBOWIĄZKOWO przy >3 public repos)
```bash
bash ~/.claude/skills/perelki-radar/scripts/fetch-meta.sh accounts owner1 owner2 ...
```
Każde konto z `public_repos > 3` → przejrzyj top 8, wyłów dodatkowe perełki (często autor dobrego repo ma drugie). Zgłoś je razem z głównymi. Konta ≤3 repo: wymień, nie drąż.

**ZANIM nazwiesz konto „kopalnią do skanu" / „świeżym odkryciem" — sprawdź czy owner już jest w bazie** (dedup w kroku 2 łapie tylko konkretne slugi z paczki, NIE ownerów):
```sql
SELECT repo_owner, count(*), min(discovered_date) FROM perelki
WHERE repo_owner ILIKE ANY (ARRAY['owner1','owner2',...]) GROUP BY repo_owner;
```
Owner z wpisami sprzed dziś = **konto ZNANE** (dokładasz repo), nie kopalnia do odkrycia. Rozdziel w raporcie/BACKLOG: „nowe konta" vs „już znane". (Lekcja 02.07: AgriciDaniel/cporter202 zgłoszone jako świeże, były w bazie od maja/czerwca — Dariusz wyłapał.)

### 5. Scoring + tier (§35 — robię JA z kontekstem ekosystemu)
Trzy osie 1-10 (null jeśli n/a):
- **score_tools** — wzbogaci nasz workflow dev (skille, CLI, automatyzacje wewnętrzne)?
- **score_ecosystem** — doda funkcję do istniejących SaaS (voiceboty, SOTA RAG, CRM, Lead Generator, CYBERSEC, Daily Machine)?
- **score_product** — standalone produkt/SaaS do sprzedaży?

`tier` z `max(3 osie)` + meta (Signal/Effort/Risk/Freshness/per-projekt):

| Tier | tier (DB) | Próg max | Kiedy |
|---|---|---|---|
| T1 | `adopt` | ≥8 | Pilot natychmiast. Signal=high + Effort≤M + Risk=low + Fresh + ≥2 projekty |
| T2 | `pilot` | ≥7 | Kandydat na pilot (T1 z 1 negatywem) |
| T3 | `watch` | ≥5 | Brak triggera teraz, czekamy na warunek |
| T4 | `inspiration` | ≥6 | Wartościowa IDEA, problem z implementacją (lic/bugs/abandoned/prawne) |
| T5 | `reference` | n/a | Awesome-list / docs / lab — bookmark + materiał |
| T6 | `inspiration`+nota | ≥6 | Archived + MIT/Apache → fork-candidate (zapisz w decyzja_powod) |
| T7 | `inspiration`+nota | n/a | Prawne ryzyko AS-IS → ZAWSZE paruj z legal angle w product_angle_pl |

### 5.1 ZAPORA: T1/T2 bez warunku powrotu NIE WCHODZI do bazy (dodane 2026-07-31)

**Każdy wpis z `tier` = `adopt` albo `pilot` MUSI mieć wypełnione `trigger_reopen`** — konkretny, sprawdzalny warunek („kiedy do tego wracamy"). Bez niego nie zapisuj: dopisz warunek albo zdegraduj do `watch`.

**Dlaczego to twarda reguła, nie zalecenie.** Pomiar z 29-31.07: w bazie leżało **495 pozycji T1/T2 „do-zbadania", z czego 361 bez warunku powrotu, a 319 czekało dłużej niż dwa miesiące**. Samych T1 „adopt" — 165, w tym `open-webui` (136 tys. ⭐) i `anthropics/skills` (130 tys. ⭐) od 8 maja. Kolumna `trigger_reopen` istniała od początku; nikt jej nie wypełniał, bo nic tego nie wymuszało. To ta sama choroba, którą w backlogu wyleczyła obowiązkowa linia EFEKT (§37): **etykieta bez warunku wyjścia to odłożenie decyzji, nie decyzja.**

Warunek ma być sprawdzalny, nie życzeniowy:
- ❌ „gdy będzie potrzeba", „przy okazji", „kiedy znajdziemy czas"
- ✅ „przy następnym audycie SEO klienta", „gdy padnie transkrypcja w Daily Intel", „gdy klient poprosi o obsługę WhatsAppem"

**Kontrola przed zapisem partii:** jeśli którykolwiek wiersz ma `tier in ('adopt','pilot')` i pusty `trigger_reopen` — popraw PRZED wykonaniem INSERT-a. Po zapisie zweryfikuj:
```sql
select repo_owner||'/'||repo_name from perelki
where discovered_date = '<dziś>' and tier in ('adopt','pilot') and coalesce(trigger_reopen,'')='';
-- oczekiwane: 0 wierszy
```

**Odpływ jest po drugiej stronie:** stare T1 wracają po 2 dziennie w porannym przeglądzie (skill `resume-work` §7.1). Ta zapora pilnuje, żeby stos nie narastał szybciej, niż topnieje.

**Nigdy SKIP.** "nie pasuje do stacku"→watch. "brak licencji"→inspiration (zbuduj własne, nie kopiuj kodu). "archived+bugs"→inspiration/fork-candidate. "awesome-list"→reference. "prawne ryzyko"→inspiration+legal angle. Gdy max=null/niepewny → **zapytaj Dariusza case-by-case**, nie zgaduj.

### 6. Zapis do `perelki` (schemat niżej) — partiami ≤6 wierszy
INSERT nowych + UPDATE istniejących. `discovered_date` = dziś (uruchom `date +%F`).

### 7. Ślad w PM BACKLOG
`~/projekty/Project Master/.ai/BACKLOG.md` — nowa sekcja `## 🔍 Repo audyt YYYY-MM-DD` na górze (przed poprzednią). Wzorzec: nagłówek + 1 zdanie podsumowania (ile insert/update, klastry) + wpisy T1/T2 jako pozycje `[data][P?][T?-tier]`, reszta zbiorczo. Pełne treści żyją w `perelki`, BACKLOG = widoczność w daily review.

### 8. Raport dla Dariusza
Tabela: # | repo | ⭐ | lic | tier | tools/eco/prod | dlaczego (1 zdanie). Plus wnioski strategiczne (które do akcji teraz, które linie zasilone). §30: żargon z wyjaśnieniem. §29: tabela OK, nie surowy markdown do oceny.

## Schemat tabeli `perelki` (Supabase PM `wqxbnkxzeitgmgcafxjc`)
Kolumny do wypełnienia przy INSERT:
`repo_owner`(NOT NULL), `repo_name`(NOT NULL), `stars`, `license_spdx`, `primary_language`, `pushed_at`(date), `created_at_gh`(date), `archived`(bool), `description_en`, `status`(NOT NULL), `tier`, `kategoria_adopcji`, `koszt_kategoria`, `score_tools`, `score_ecosystem`, `score_product`, `score`, `related_project`, `co_robi_pl`, `wartosc_pl`, `product_angle_pl`, `decyzja_powod`, `trigger_reopen`, `use_cases_pl`(jsonb), `discovered_date`, `last_verified`, `decision_date`.

Wartości enum (trzymaj się ich):
- `tier`: adopt | pilot | watch | reference | inspiration
- `status`: do-zbadania (adopt/pilot) | watching (watch) | reference | inspiracja (inspiration) | dormant (T3-dormant) | zainstalowany/skill-skopiowany/mcp-skonfigurowany (gdy realnie wdrożone)
- `kategoria_adopcji`: nowy-produkt | upgrade-produktu | wewnetrzne-narzedzie | reference-only | mieszane | publiczne-repo
- `koszt_kategoria`: low | med | high

`score` = `max(score_tools, score_ecosystem, score_product)`.

## Kontekst ekosystemu do oceny fit (linie aktywne)
- **CYBERSEC** — lead magnet (pasywny skaner + szkolenie live), upsell "Przegląd Praktyk Bezpieczeństwa" (NIE "pentest"/"audyt" bez certów CISSP/OSCP = liability, Lessons 27.05). Silnik: Strix (T2-pilot).
- **SOTA RAG legal** (ClientB) — anty-halucynacja, weryfikowalne cytowania, lokalny/RODO, długie akta. Powiązane: PageIndex, Nemotron, Cohere.
- **Daily Machine** — fabryka narzędzi-dowodów (`narzedzia-ai.vercel.app`).
- **Dev tools / workflow Claude Code** — skille, onboarding do ~60 projektów, Analizator repozytoriów.
- **Voiceboty / agenci AIWB** — pamięć, ElevenLabs. **Lead Generator / CRM** — outbound, enrichment.
- **Shared Org Context Layer** — pamięć org z conflict detection/provenance (porównuj memory-repo do niego).

## Pułapki

### 1. `repo_url` to kolumna GENERATED — nie wstawiaj
INSERT z `repo_url` → `ERROR: cannot insert a non-DEFAULT value into column "repo_url"`. Pomiń ją; baza złoży URL z owner/name.

### 2. `use_cases_pl` wymaga `::jsonb`
Tablica stringów rzutowana: `'["a","b","c"]'::jsonb`. Bez rzutowania = błąd typu.

### 3. MCP `execute_sql` multi-statement zwraca TYLKO ostatni wynik
Dedup + sprawdzenie enumów w jednym query z kilkoma `SELECT` → zobaczysz tylko ostatni. Rób osobne wywołania albo łącz w jeden SELECT (podzapytania `string_agg`).

### 4. Apostrofy w PL/EN tekście psują SQL
"Omar Santos's" / "don't" → podwój apostrof (`''`) albo przeredaguj. Najczęstszy błąd w długich `co_robi_pl`/`wartosc_pl`.

### 5. Batch >6 wierszy = ryzyko stream idle timeout
Pola PL są długie. Dziel INSERT na partie ≤6 (globalny CLAUDE.md §5). Generujesz dużo tekstu SQL naraz → tnij.

### 6. `created_at` z gh w pierwszym podejściu bywa skrócone do `YYYY-MM`
Kolumna `created_at_gh` to `date` — `YYYY-MM` wstawi się jako pierwszy dzień miesiąca przez `-01`? NIE, `date` wymaga pełnej daty. Skrypt `fetch-meta.sh repos` zwraca `created` jako `[0:10]` (pełna data) — używaj jej. Jeśli masz tylko `YYYY-MM`, dopisz `-01`.

### 7. Nie pytaj "czy dodać do perełek?"
To CEL analizy — Dariusz zniecierpliwiony gdy pytasz (08.06). Dodawanie do bazy jest domyślne. Pytaj tylko o niejednoznaczny scoring (max=null) albo czy któryś T1/T2 pilotować od razu.

### 8. Skan kont (§35.2) to nie opcja — to część zadania
Pominięcie skanu kont = niekompletna analiza (08.06: 4 z 13 perełek pochodziły dopiero ze skanu kont). Zawsze krok 4.

### 9. Kolumna `forks` NIE istnieje w `perelki`
`fetch-meta.sh` zwraca `forks`, ale tabela go nie ma → INSERT/UPDATE z `forks=` rzuca `ERROR: column "forks" does not exist` (14.06). Pomiń forks przy zapisie (to metryka tylko do oceny, nie do bazy).

### 10. Repo ze skanu kont (krok 4) NIE są zdedupowane w kroku 2 → duplicate key wywala partię
Dedup w kroku 2 obejmuje tylko slugi z paczki. Repo wyłowione w kroku 4 (skan kont) mogą już być w bazie z wcześniejszego audytu → INSERT rzuci `duplicate key value violates unique constraint "perelki_repo_owner_repo_name_key"` i cofnie CAŁĄ partię (transakcja). **Po skanie kont zrób DRUGI dedup** dla wyłowionych repo PRZED zapisem; trafienia → UPDATE. (Lekcja 07.07: calesthio/Crucix ze skanu był w bazie od 08.05, wywalił partię D.)

## Powiązane
- §35 globalnego CLAUDE.md (pełna definicja T1-T7, scoring) · `feedback_skanuj_pelne_konto_autora.md` · `feedback_low_stars_not_low_value.md`
- `github-repo-polish` (inne: polerowanie WŁASNEGO repo) · `Analizator repozytoriów` (produkt: analiza jednego projektu)
