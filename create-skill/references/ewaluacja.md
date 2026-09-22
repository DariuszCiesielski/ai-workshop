# Ewaluacja skilla — instrukcja operacyjna

Adaptacja metodyki z oficjalnego `skill-creator` Anthropic ([anthropics/skills](https://github.com/anthropics/skills), licencja Apache 2.0) na nasze realia: subagenty przez **Agent tool** (nie harness Anthropic), bez przeglądarki eval-viewer, wyniki w plikach + prezentacja Dariuszowi w rozmowie.

---

## 1. Struktura katalogów

```
~/.claude/skills/<skill>/
└── evals/
    └── evals.json              # test cases (źródło prawdy)

<scratchpad>/<skill>-workspace/  # workspace POZA katalogiem skilla
├── skill-snapshot/              # kopia starej wersji (gdy ulepszamy istniejący)
└── iteration-1/
    ├── eval-0-<opisowa-nazwa>/
    │   ├── eval_metadata.json
    │   ├── with_skill/
    │   │   ├── outputs/         # artefakty run-u
    │   │   └── grading.json
    │   └── without_skill/       # lub old_skill/ przy ulepszaniu
    │       ├── outputs/
    │       └── grading.json
    └── benchmark.md             # zbiorcze porównanie
```

Workspace w scratchpadzie sesji (per §39 — katalog roboczy, nie dorobek). Po zakończeniu: `evals/evals.json` zostaje w skillu (to dorobek — kolejne iteracje skilla go reużyją), workspace do kasacji po akceptacji Dariusza.

---

## 2. Jak napisać test case

### Format `evals/evals.json`

```json
{
  "skill_name": "nazwa-skilla",
  "evals": [
    {
      "id": 0,
      "name": "opisowa-nazwa-co-testuje",
      "prompt": "Realistyczny prompt użytkownika",
      "expected_output": "Opis oczekiwanego rezultatu (dla człowieka)",
      "files": ["ścieżki do plików wejściowych, jeśli są"],
      "assertions": [
        "Obiektywnie sprawdzalne oczekiwanie 1",
        "Obiektywnie sprawdzalne oczekiwanie 2"
      ]
    }
  ]
}
```

### Zasady dobrego test case'a

1. **Prompt jak od prawdziwego użytkownika** — z kontekstem, ścieżkami, nazwami kolumn, odrobiną backstory; czasem małe litery, skróty, literówka. NIE sterylne polecenie.
   - Źle: `"Sformatuj te dane"`
   - Dobrze: `"szef podesłał mi excela (w Downloads, chyba 'Q4 sprzedaz final FINAL v2.xlsx') i chce kolumnę z marżą w procentach. przychód jest w C, koszty w D"`
2. **Zadanie na tyle treściwe, żeby skill pomagał** — jednokrokowe zapytania nie aktywują skilli i niczego nie mierzą.
3. **3-5 case'ów, stratyfikowane** (per §22): przypadek typowy, edge case, przypadek krytyczny. Nie 5 wariacji tego samego.
4. **Asercje dyskryminujące** — asercja ma przechodzić, gdy skill faktycznie zadziałał, i padać, gdy nie. „Plik istnieje" to zła asercja (przejdzie też dla pustego pliku); „plik zawiera kolumnę Marża z wartościami = (C-D)/C dla wszystkich wierszy" — dobra.
5. **Nazwy opisowe** — `eval-2-polskie-znaki-w-docx`, nie `eval-2`. Wynik ma być czytelny bez zaglądania do promptu.
6. Skille subiektywne (styl, estetyka) — nie wymuszaj asercji; tam ocenia Dariusz jakościowo.

---

## 3. Uruchamianie run-ów (Agent tool)

Dla każdego test case'a — **dwa subagenty w tej samej turze** (żeby skończyły o podobnej porze):

**Run z-skillem** (prompt subagenta):

```
Wykonaj zadanie użytkownika. NAJPIERW przeczytaj skill:
<pełna ścieżka do SKILL.md testowanej wersji>
i stosuj się do jego instrukcji.

Zadanie: <prompt z evals.json>
Pliki wejściowe: <ścieżki lub "brak">
Wszystkie artefakty zapisz do: <workspace>/iteration-N/eval-<id>-<nazwa>/with_skill/outputs/
Na końcu zapisz tam też user_notes.md: czego nie byłeś pewien, co nie zadziałało, jakie obejścia zastosowałeś.
```

**Run baseline** — ten sam prompt, ale:
- **nowy skill**: bez wzmianki o skillu w ogóle → `without_skill/outputs/`
- **ulepszanie istniejącego**: przed edycją zrób `cp -r <skill> <workspace>/skill-snapshot/`, baseline czyta snapshot → `old_skill/outputs/`

Zasady:
- Subagent baseline **nie może wiedzieć**, że to porównanie — dostaje po prostu zadanie.
- Po zakończeniu każdego run-u notyfikacja taska zawiera `total_tokens` i `duration_ms` — zapisz od razu do `timing.json` w katalogu run-u (potem tych danych nie ma skąd wziąć).
- Weryfikuj, że artefakty FIZYCZNIE są w `outputs/` (`ls`, `wc -l`) — deklaracja subagenta „zrobione" to nie dowód (§27.5, lekcja PM 2026-06-01).

---

## 4. Grader — prompt i format wyniku

Osobny subagent per run (albo ocena inline dla prostych przypadków). Asercje sprawdzalne programistycznie (liczba wierszy, obecność kolumny, poprawność JSON) — **skryptem, nie na oko**: skrypt jest szybszy, powtarzalny między iteracjami.

### Prompt gradera (szablon)

```
Jesteś graderem ewaluacji skilla. Oceń KAŻDĄ asercję na podstawie dowodów.

Asercje:
<lista asercji z evals.json>

Katalog z artefaktami: <ścieżka do outputs/>
(przeczytaj też user_notes.md, jeśli istnieje)

Dla każdej asercji:
1. Poszukaj dowodu w artefaktach (czytaj pliki, nie zgaduj z nazw).
2. Werdykt PASS tylko gdy dowód pokazuje FAKTYCZNE wykonanie zadania,
   nie powierzchowną zgodność (właściwa nazwa pliku + zła zawartość = FAIL).
3. Zacytuj dowód (fragment pliku / co znalazłeś).
Przy wątpliwości: FAIL — ciężar dowodu leży po stronie asercji.
Bez ocen częściowych: każda asercja to pass albo fail.

Dodatkowo SKRYTYKUJ same asercje: wskaż (a) asercje, które przeszłyby też
dla ewidentnie złego wyniku, (b) istotne zaobserwowane skutki, których
żadna asercja nie sprawdza, (c) asercje niesprawdzalne z dostępnych artefaktów.
Poprzeczka wysoko — tylko uwagi, o których autor powiedziałby "dobra uwaga".

Zapisz wynik do <ścieżka>/grading.json w formacie:
{
  "expectations": [
    {"text": "<asercja>", "passed": true, "evidence": "<cytat/dowód>"}
  ],
  "summary": {"passed": N, "failed": M, "total": T, "pass_rate": 0.0-1.0},
  "eval_feedback": {"suggestions": [...], "overall": "..."}
}
```

Pola `text` / `passed` / `evidence` — trzymaj się dokładnie tych nazw (spójność między iteracjami i skryptami zbiorczymi).

---

## 5. Porównanie wyników i próg akceptacji

Po ocenie wszystkich run-ów złóż `benchmark.md` (ręcznie albo krótkim skryptem Pythona czytającym grading.json + timing.json):

```markdown
# Benchmark: <skill> — iteration N

| Konfiguracja  | Pass rate | Śr. czas | Śr. tokeny |
|---------------|-----------|----------|------------|
| with_skill    | 12/15 (80%) | 145 s  | 92k        |
| without_skill | 6/15 (40%)  | 210 s  | 130k       |

## Per eval
| Eval | with_skill | baseline | Uwagi |
|------|-----------|----------|-------|
| 0-typowy-przypadek | 5/5 | 3/5 | baseline pominął polskie znaki |
...
```

**Próg akceptacji (brama „gotowy"):**
- with_skill ≥ **80%** asercji łącznie, ORAZ
- with_skill **wyraźnie** > baseline (różnica widoczna per eval, nie tylko w agregacie).

**Analiza wzorców** (nie tylko agregat):
- Asercja przechodzi w OBU konfiguracjach na wszystkich evalach → niedyskryminująca, wymień ją.
- Baseline ≈ with_skill → skill nie wnosi wartości: uprość, zawęź albo skasuj (szczerze powiedz to Dariuszowi).
- with_skill wolniejszy/droższy przy tym samym pass rate → skill każe robić coś zbędnego; czytaj transkrypty i tnij.
- Duża wariancja tego samego evala między iteracjami → eval niestabilny (flaky), popraw prompt lub asercje.

**Prezentacja Dariuszowi:** nie surowy JSON (§29) — tabela benchmarku + linki do 2-3 artefaktów do obejrzenia + Twoja rekomendacja (przechodzi / iterujemy / skill zbędny). Decyzja o „gotowy" należy do Dariusza.

---

## 6. Iteracja

1. Popraw skill na podstawie porażek i feedbacku (zasady: generalizuj, odchudzaj, wyjaśniaj „dlaczego" zamiast MUSISZ; powtarzalny kod z run-ów → `scripts/` skilla).
2. Przerun WSZYSTKIE case'y (z baseline'ami) do `iteration-N+1/` — nowe pary subagentów.
3. Porównaj benchmarki iteracji N vs N+1 — regresja na którymkolwiek evalu = STOP i diagnoza (analogia §21 baseline checkpoint).
4. Stop: próg osiągnięty / Dariusz zadowolony / brak postępu przez 2 iteracje.

---

## 7. Ślepe porównanie A/B (opcjonalne, wysoka stawka)

Gdy pytanie brzmi „czy nowa wersja jest NAPRAWDĘ lepsza" (np. przed propagacją skilla na ekosystem):

1. Subagent-sędzia dostaje dwa komplety artefaktów jako **„Wynik A" i „Wynik B" bez informacji, który jest którą wersją** (losuj kolejność, nie zdradzaj nazw katalogów).
2. Prompt: „Oceń, który wynik lepiej realizuje zadanie <prompt>. Werdykt: A / B / remis + uzasadnienie z konkretami."
3. Powtórz dla każdego evala; dopiero po werdyktach odkryj mapowanie i przeanalizuj, DLACZEGO wygrany wygrał.

Zwykle niepotrzebne — pętla grader + przegląd Dariusza wystarcza.

---

## 8. Ewaluacja triggeringu (description)

Bez harnessu `run_loop.py` robimy wersję ręczną:

1. **Zestaw zapytań**: 10-20 pozycji `{"query": "...", "should_trigger": true/false}` — realistyczne (jak w §2), połowa pozytywnych (różne sformułowania, bez nazwy skilla), połowa negatywnych **near-miss** (wspólne keywords, inna potrzeba — np. dla skilla PDF-owego negatywem jest „scal dwa obrazy PNG w jeden plik", nie „napisz fibonacciego").
2. **Pomiar**: subagent dostaje listę ~10 opisów skilli (testowany + sąsiednie z `~/.claude/skills/`) i zapytanie: „Którego skilla użyłbyś do tego zadania? Odpowiedz nazwą albo 'żaden'." Jedno zapytanie = jeden pomiar; przy niestabilnych wynikach powtórz 3× i bierz większość.
3. **Poprawa**: dla porażek przeredaguj description — dopisz brakujące konteksty aktywacji (pozytywne porażki) i anty-triggery „NIE używaj do X → skill Y" (fałszywe aktywacje). Max 1024 znaki.
4. **Anty-overfitting**: odłóż ~40% zapytań na bok i nie patrz na nie podczas redagowania; finalną wersję sprawdź na odłożonych. Wybieraj wersję po wyniku na odłożonych, nie na tych, pod które pisałeś.
5. Iteruj max 5 rund — potem malejące zwroty.

---

## Pułapki

1. **Grader zbyt łaskawy** — grader, który wszystko przepuszcza, jest gorszy niż brak gradera (fałszywa pewność). Dlatego: ciężar dowodu na asercji + obowiązkowa krytyka asercji w prompcie.
2. **Ocenianie deklaracji zamiast artefaktów** — subagent pisze „zrobione", plik pusty. Zawsze `ls` + zawartość (§27.5).
3. **Overfitting do 3 promptów** — skill ma działać na tysiącach promptów. Jeśli poprawka pomaga tylko na jednym evalu i pachnie regułą-łatką, poszukaj ogólniejszego sformułowania.
4. **Baseline odpalony później / w innych warunkach** — pary run-ów zawsze w tej samej turze, ten sam model subagentów.
5. **Zapomniane timing/tokens** — dane z notyfikacji taska przepadają, jeśli nie zapiszesz od razu.
6. **Workspace w katalogu skilla** — zaśmieca skill i trafia do dystrybucji. Workspace w scratchpadzie, w skillu zostaje tylko `evals/evals.json`.
7. **RTK a weryfikacja plików** — liczenie/membership na dużych plikach wyników rób Pythonem, nie `grep`/`wc` (§23.1).

---

*Atrybucja: metodyka i schematy (evals.json, grading.json, pętla iteracyjna, optymalizacja triggeringu) zaadaptowane z [anthropics/skills → skill-creator](https://github.com/anthropics/skills) (Apache License 2.0, Copyright Anthropic). Adaptacja: polska wersja, subagenty przez Agent tool, bez eval-viewer/run_loop.py, progi i prezentacja pod reguły ekosystemu Dariusza (§21, §22, §27.5, §29, §39).*
