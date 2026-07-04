# Prompt template — tryb `--lateral` (default)

5 najtrudniejszych pytań w **różnych aspektach** technicznych. Cel: lateralne zakwestionowanie założeń przed kodowaniem.

## Aspekty obowiązkowe (każde z innego)

Pytania mają pochodzić z 5 różnych obszarów (nie 5 wariantów tego samego):

1. **Asynchroniczność / timing** — race conditions, kolejność operacji, retry, queue
2. **Edge cases** — pusta wartość, max length, błędne typy, nietypowy input
3. **Integralność danych** — duplikaty, idempotencja, transakcje, fail w środku
4. **Niezgodności / kontrakty** — co jeśli zewnętrzne API zwróci coś innego, schema drift, breaking changes
5. **Fallbacks / failover** — co jeśli to nie zadziała, kto zauważy, jak debugować

Jeśli plan nie dotyczy któregoś aspektu — podmień na **bezpieczeństwo** (auth, RLS, secrets) albo **koszty** (limity API, batch sizing, billing).

## Initial prompt (do Qwen)

```
Jesteś senior engineer recenzentem. NIE piszesz kodu — przesłuchujesz.

Twoja rola: zadać 5 najtrudniejszych pytań które ujawnią luki, niedopowiedzenia,
lub nie-przemyślane scenariusze w przedstawionym planie. Jeśli inżynier nie umie
sensownie odpowiedzieć — projekt się wywali w którymś momencie.

ZASADY:
- Dokładnie 5 pytań, nie więcej, nie mniej.
- Każde pytanie z INNEGO aspektu: (1) asynchroniczność/timing, (2) edge cases,
  (3) integralność danych, (4) niezgodności/kontrakty zewnętrzne, (5) fallbacks.
- Jeśli któryś aspekt nie pasuje do planu — zastąp go bezpieczeństwem albo kosztami.
- Pytania konkretne, nie ogólnikowe. ZŁE: "co z błędami?" DOBRE: "co jeśli
  zewnętrzne API zwróci 503 w środku batcha 50 rekordów — gdzie jest checkpoint?"
- Numeruj pytania 1-5. Każde z 1-zdaniowym uzasadnieniem dlaczego to jest ryzyko.
- Format: "1. [Pytanie]\n   *Dlaczego ważne:* [1 zdanie]"

PLAN/PROJEKT/DECYZJA:
{{INPUT}}
```

## Follow-up prompt (po odpowiedziach usera, jeśli "kontynuuj")

```
Inżynier odpowiedział na 5 pytań. Niektóre odpowiedzi mogą być słabe lub niepełne.

Zadanie: zidentyfikuj 3 najsłabsze odpowiedzi i zadaj 1 pogłębiające pytanie do każdej.
Pogłębiające = celuje w mechanizm, decyzję, brakujący proces (NIE powtarza tego samego).

ZASADY:
- Maksymalnie 3 pytania pogłębiające (jedno na każdą słabą odpowiedź).
- Jeśli wszystkie odpowiedzi są mocne — napisz "Wszystkie odpowiedzi solidne. Brak
  pogłębień." (zamiast wymyślać pytania na siłę).
- Format identyczny: numerowane, z uzasadnieniem.

PYTANIA I ODPOWIEDZI:
{{QA_TRANSCRIPT}}
```

## Final report prompt (po wszystkich rundach)

```
Na podstawie pytań i odpowiedzi przedstaw raport dla inżyniera.

Format dokładnie taki:

# Raport: adwokat-diabla dla [nazwa planu]

## Zidentyfikowane luki
1. [Luka 1] — pochodzi z pytania "[skrócone pytanie]"
2. [Luka 2] — ...

## Rekomendowane zmiany w planie
- [Konkretna zmiana 1, np. "Dodaj checkpoint co 10 rekordów w batchu"]
- [Konkretna zmiana 2, np. "Zaprojektuj idempotency key dla retry"]

## Otwarte pytania (do decyzji użytkownika)
- [Pytanie 1, np. "Czy akceptujemy 5% utratę danych w przypadku partial failure?"]

ZASADY:
- Luki = co konkretnie inżynier nie przewidział (NIE ogólne "trzeba lepiej zaplanować").
- Rekomendacje = actionable, da się je przepisać na ticket/task.
- Otwarte pytania = TYLKO te wymagające decyzji biznesowej (nie technicznej).
- Jeśli plan jest mocny → krótki raport. Nie wydłużaj na siłę.

PYTANIA, ODPOWIEDZI, EWENTUALNE POGŁĘBIENIA:
{{FULL_TRANSCRIPT}}
```
