---
# Frontmatter — jedyne YAML w projekcie; z niego generowany jest INDEX portfela (Faza C).
project: "<nazwa katalogu w ~/projekty>"
status: aktywny            # aktywny | wstrzymany | archiwum
kind: klient               # klient | produkt | narzędzie-wewnętrzne | eksperyment | rekrutacja
owner_client: "<firma / osoba | brak>"
card_version: "1.0"
card_kind: kontrakt        # kontrakt (pisany PRZED pracą) | rekonstrukcja (odtworzony po fakcie — wynik nie jest dowodem dotrzymania umowy)
created: YYYY-MM-DD
last_touched: YYYY-MM-DD   # data ostatniej zmiany KTÓREJKOLWIEK sekcji; >45 dni przy status=aktywny → „niespójny" w indeksie
outcome: w-toku            # w-toku | spełnione | częściowo | niespełnione | porzucone — wypełnia się z sekcji 4 (kryteria)
outcome_date:              # kiedy postawiono werdykt (puste = w toku)
decisions: docs/DECISIONS.md
---

# PROJECT_CARD — <Nazwa projektu>

## 0. Jedna strona dla człowieka (WYMAGANA — pisz ją NAJPIERW, prostym językiem)

> Po co ta sekcja: Dariusz po 60 sekundach ma umieć ocenić projekt. Zero żargonu (§30 — test: „czy ktoś
> bez tła technicznego zrozumie po jednym czytaniu?"). Bez skrótów, bez ID kryteriów, bez nazw technologii —
> chyba że z tłumaczeniem w nawiasie. Geneza: karta CMH z 24.08 była w 100% zgodna z szablonem i mimo to
> ODRZUCONA („nie wynika z niej nic, co pozwoliłoby mi ocenić projekt") — wadą był wzorzec, nie wykonanie.

**Po co ten projekt jest** (1–2 zdania, biznesowo): …
**Co ma robić** (3–6 punktów, językiem użytkownika, nie technologii): …
**Jak się z niego korzysta** (kto siada i co klika/mówi — 2–3 zdania): …
**Jaka jest wartość dla klienta / dla nas** (1–2 zdania): …
**Po czym poznać, że zrealizowano go poprawnie** (2–4 „ludzkie" sprawdzenia, np. „klientka klika link
z telefonu i widzi swój cennik" — NIE „KRYT-1.1 ≥ 4,75"): …

Reguły: (a) sekcja 0 to streszczenie sekcji 2–4 — zmieniasz kryteria w 4 → aktualizujesz „po czym poznać"
tutaj; (b) wersja karty do CZYTANIA przez Dariusza = docx w `~/Downloads/!Analizy/` (§34), generowany
z tego pliku po każdej istotnej zmianie; (c) sekcje techniczne (1–11) zostają dla agentów — sekcja 0 ich
nie zastępuje, tylko tłumaczy.

> Warstwa kontraktowa (sekcje 1–7) zamyka się przy podpisie / starcie prac — zmiana = aneks w sekcji 9.
> Warstwa operacyjna (8–11) żyje co sesję. **Kryteria (4) i wynik (11) to to, co po roku odpowie: „czy projekt spełnił oczekiwania".**

## 1. Strony
- **Wykonawca:** Dariusz Ciesielski
- **Odbiorca:** <firma, osoba kontaktowa, e-mail> | brak (projekt własny)
- **Charakter:** <umowa komercyjna / pilot / produkt własny / narzędzie wewnętrzne>

## 2. Cel projektu
<2–4 zdania językiem odbiorcy: jaki problem znika, po czym poznamy, że znikł. Bez techniki.>

## 3. Zakres prac (deliverables)
1. <deliverable — rzeczownik, nie czynność>
2. …

**Poza zakresem (wprost):** <co NIE wchodzi — to zdanie ratuje przed scope creep>

## 4. Kryteria odbioru — mierzalne, z ID
Każde kryterium ma **ID** (`KRYT-<etap>.<nr>`), **cel liczbowy lub binarny**, **jak mierzymy** i — gdy zmierzone — **wynik z datą i źródłem dowodu**. Kryterium, którego nie da się zmierzyć w chwili pisania, jest wadliwe — przeformułuj albo oznacz `(do doprecyzowania do: data)`.

| ID | Kryterium | Cel | Jak mierzymy | Zmierzone | Data | Źródło dowodu |
|---|---|---|---|---|---|---|
| KRYT-1.1 | <np. średnia ocen na zestawie testowym> | ≥ 4,75/5 | panel testowy, 50 pytań | — | — | — |
| KRYT-1.2 | <np. zero halucynacji (warunek blokujący)> | 0 | sędzia + przegląd ręczny | — | — | — |

Commity/handoffy odwołują się do ID: `Refs: KRYT-1.2`.

## 5. Harmonogram
| Etap | Termin dla odbiorcy | Realna praca (§17) |
|---|---|---|
| 1. <…> | YYYY-MM-DD | ~X h |

## 6. Wynagrodzenie
<kwota / model / warunki płatności | brak (projekt własny — koszt: czas + usługi ~X zł/mc)>

## 7. Pochodzenie i licencje (WYMAGANE — także „brak")
Skąd wzięliśmy pomysł/kod/dane. Bez tego pola po roku nie wiadomo, czy wolno to sprzedać.

| Co | Źródło (repo/URL/osoba) | Licencja (z pliku LICENSE, nie z API) | Co wzięliśmy | Ograniczenia |
|---|---|---|---|---|
| <mechanizm / biblioteka / dane> | <owner/repo> | MIT / Apache-2.0 / AGPL / własne | idea / kod 1:1 / fork / dane | <np. AGPL → tylko wewnętrznie> |
| — | brak źródeł zewnętrznych | — | — | — |

---

## 8. Stan realizacji (żywa sekcja, najnowsze na górze)
- YYYY-MM-DD: <co zrobiono, z dowodem: commit / handoff / URL>. `Refs: KRYT-x.y ADR-n`

## 9. Rejestr zmian i aneksów
Co pojawiło się po starcie i **nie** rozszerza automatycznie sekcji 3–4. Zmiana kryteriów = świadoma decyzja → wpis tutaj + (jeśli istotna) ADR.

| Data | Zmiana | Kto zdecydował | Aneks nr / ADR |
|---|---|---|---|

## 10. Co ten projekt uruchamia (inwentarz środowiska)
Rzeczy, które **działają bez sesji agenta** i przeżyją zapomnienie o projekcie. Puste = „nic” (napisz to wprost). Incydent-wzorzec: zdublowany LaunchAgent Gmaila biegł 2 miesiące, bo nie był nigdzie spisany.

| Typ | Identyfikator | Gdzie | Co robi | Jak wyłączyć |
|---|---|---|---|---|
| LaunchAgent / cron | `pl.aiwbiznesie.<…>` | `~/Library/LaunchAgents/` | … | `launchctl bootout gui/$UID/<label>` |
| Deploy | `<alias>.vercel.app` | Vercel / cyber_Folks | … | … |
| Webhook / integracja | … | n8n / Stripe / Buffer | … | … |
| Klucze i konta | `<NAZWA_ENV>` (nazwa, NIE wartość) | skarbiec / Vercel env | … | rotacja: … |
| Baza | Supabase `<ref>` | … | … | pause |

## 11. Wynik (wypełniane przy zamknięciu etapu / projektu)
**Werdykt:** spełnione / częściowo / niespełnione / porzucone — **data** — na podstawie tabeli w sekcji 4.
**Dlaczego tak wyszło (3–5 zdań):** <co zadziałało, co nie, czego nie przewidzieliśmy — to jest post-mortem; bez tego wpis jest boilerplate>
**Co z tego bierzemy do innych projektów:** <1–3 punkty lub „nic”>
