# Prompt template — tryb `--root-cause`

Metoda **5 Why** (Sakichi Toyoda, Toyota Production System). Cel: drążenie jednej ścieżki przyczyna→skutek aż do root cause. Inny mechanizm niż `--lateral` — TUTAJ pogłębiamy jedną gałąź, nie szerokość.

## Kiedy używać

- Padł deploy, klient zgłasza dziwny błąd
- System zachowuje się nieoczekiwanie
- Regresja po zmianie
- Post-mortem incydentu

## Initial prompt (do Qwen)

```
Jestem inżynierem analizującym problem. Będziesz mi zadawał 5 razy pytanie
"dlaczego" — każde pogłębiające poprzedni answer, drążąc JEDNĄ ścieżkę
przyczyna→skutek aż do root cause. To metoda 5 Why z Toyota Production
System (Sakichi Toyoda).

ZASADY:
- Po opisie problemu, zadaj PIERWSZE "dlaczego" odnoszące się do najbardziej
  prawdopodobnej bezpośredniej przyczyny (NIE wszystkich możliwych — wybierz jedną).
- Po każdej mojej odpowiedzi, zadaj kolejne "dlaczego" CELUJĄCE w głębszy poziom:
  mechanizm → decyzję → brakujący proces → kulturę/architekturę.
- Drążenie idzie WGŁĄB jednej ścieżki, NIE wszerz różnych. Jeśli widzisz że
  poszliśmy w ślepy zaułek → po 3. iteracji zaproponuj "wracamy do iteracji N
  i pójdziemy inną gałęzią?".
- Po 5. iteracji zsumuj root cause + zaproponuj SYSTEMOWĄ korektę
  (nie tylko fix tego symptomu).
- Pytania krótkie, 1 zdanie. Bez "może", "ewentualnie", "być może".

PROBLEM:
{{INPUT}}
```

## Iteracja (po każdej odpowiedzi usera)

Skill po każdej odpowiedzi wysyła do Qwen:

```
Iteracja N (z 5). Inżynier właśnie odpowiedział na poprzednie "dlaczego".

Twoje zadanie: zadać kolejne "dlaczego" CELUJĄCE w głębszy poziom przyczyny.
Jeden krok wgłąb, nie wszerz.

ZASADY:
- Jeśli odpowiedź wskazuje na konkretny mechanizm → drążymy mechanizm.
- Jeśli odpowiedź wskazuje na decyzję → pytamy "dlaczego taka decyzja".
- Jeśli odpowiedź wskazuje na brakujący proces → pytamy "dlaczego nie było procesu".
- Jeśli odpowiedź jest niepełna ("nie wiem", "tak po prostu") → zatrzymaj
  pętlę i napisz: "STOP: poprzednia odpowiedź nie pozwala drążyć dalej.
  Sugestia: wróćmy do iteracji {N-1} i wybierzmy inną gałąź."

POPRZEDNIE PYTANIA I ODPOWIEDZI:
{{TRANSCRIPT}}

NOWE PYTANIE (1 zdanie):
```

## Final report prompt (po 5. iteracji)

```
Inżynier ukończył 5 Why. Przedstaw raport.

Format dokładnie taki:

# Raport: 5 Why dla [nazwa problemu]

## Łańcuch przyczyn
1. **Dlaczego X?** → Bo A
2. **Dlaczego A?** → Bo B
3. **Dlaczego B?** → Bo C
4. **Dlaczego C?** → Bo D
5. **Dlaczego D?** → ROOT CAUSE: [root cause 1 zdanie]

## Systemowa korekta
[Co zmienić w PROCESIE/architekturze/konwencji żeby ta KLASA problemów nie
powracała — nie tylko fix tego konkretnego case'u. Powinna być actionable —
konkretny task, nie "lepiej testować".]

## Otwarte pytania
[Jeśli któreś "dlaczego" nie miało jednoznacznej odpowiedzi LUB pętla została
przerwana wcześniej — wymień co wymaga dalszego śledztwa.]

ZASADY:
- ROOT CAUSE = nie symptom, nie najbliższa przyczyna techniczna, ale powód
  STRUKTURALNY (np. "brak idempotency key w schemacie queue", nie "deploy padł").
- Systemowa korekta = zmienia szansę na powtórkę dla CAŁEJ klasy problemów.
- Jeśli ROOT CAUSE = "human error" → drąż dalej, to nigdy nie jest root cause.

LISTA WSZYSTKICH 5 PYTAŃ I ODPOWIEDZI:
{{TRANSCRIPT}}
```

## Reset transkryptu po wybraniu nowej gałęzi (po STOP)

LLM jest stateless — bez explicit reset, kontynuacja innej gałęzi po "STOP" zawiera szum z odrzuconej ścieżki, co zniszczy spójność analizy przyczynowej.

### Workflow Claude'a-orchestratora (po STOP w iteracji N)

1. **Zaprezentuj userowi opcje:** "Q_N nie pozwala drążyć dalej. Wybierz: (a) wracamy do iter. N-1 i drążymy inną gałąź, (b) zatrzymujemy analizę i sumujemy co mamy"
2. **Jeśli (a):** OBETNIJ transkrypt do iteracji N-1 (zachowaj tylko Q1..Q_{N-1} i A1..A_{N-1}, USUŃ Q_N i A_N)
3. **Wyślij do Qwen branch-rejection prompt** (poniżej)
4. **Qwen zwróci NOWE pytanie N** drążące inną gałąź po A_{N-1}

### Branch-rejection prompt (gdy user wybiera nową gałąź)

```
Iteracja N (z 5). Inżynier zatrzymał poprzednią ścieżkę drążenia po Q_{N-1}/A_{N-1}.

POPRZEDNIA GAŁĄŹ ZACZYNAJĄCA SIĘ OD A_{N-1} → "{{REJECTED_QUESTION}}" → "{{REJECTED_ANSWER}}"
ZOSTAŁA ODRZUCONA. Zignoruj ją kompletnie.

Twoje zadanie: zadać NOWE "dlaczego" drążące INNĄ ścieżkę po A_{N-1}.
- Nie wracaj do tematu odrzuconej gałęzi.
- Nie powtarzaj tego samego pytania innymi słowami.
- Wybierz inny mechanizm/decyzję/proces wynikający z A_{N-1}.

POPRZEDNIE PYTANIA I ODPOWIEDZI (do iteracji N-1):
{{TRUNCATED_TRANSCRIPT}}

NOWE PYTANIE (1 zdanie, INNA gałąź niż odrzucona):
```

### Co użytkownik widzi

```
[Iteracja N] Qwen: STOP — odpowiedź A_N nie pozwala drążyć dalej.

Opcje:
  a) Wracamy do iteracji N-1 (A: "...") i drążymy INNĄ gałąź
  b) Zatrzymujemy analizę i sumujemy co mamy (raport z N-1 iteracji)

Wybór:
```

Po wyborze (a) Claude internalnie obcina transkrypt, woła Qwen z branch-rejection promptem, dostaje nowe Q_N.

## Anti-patterns (dla skilla — co NIE robić)

- **Nie zadawaj 5 pytań naraz** — to nie `--lateral`. Tryb 5 Why jest sekwencyjny: pytanie → odpowiedź → następne pytanie.
- **Nie zmieniaj gałęzi w środku** — jak już drążysz "dlaczego deploy padł" przez timeout, to nie skacz w iteracji 4 na "dlaczego nie było monitoringu". Skończ jedną ścieżkę.
- **Nie akceptuj "nie wiem" jako root cause** — wtedy zatrzymaj pętlę i zaproponuj inną gałąź (z explicit reset transkryptu, sekcja wyżej).
- **Nie wysyłaj odrzuconej gałęzi do Qwen jako kontekst** — zawsze obcinaj transkrypt do iteracji N-1 i używaj branch-rejection promptu. Inaczej Qwen wraca do śmierdzącego tematu.
- **Root cause ≠ "human error"** — drąż dlaczego człowiek mógł popełnić ten błąd (brak procesu? brak narzędzia? brak czasu na review?).
