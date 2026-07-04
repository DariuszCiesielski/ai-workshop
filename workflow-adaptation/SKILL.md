---
name: workflow-adaptation
description: Systematyczna adaptacja workflow'ów (N8N, Make.com, Airtable) do nowej implementacji (Supabase Edge Functions, Next.js API Routes itp.). Używaj gdy agent ma przenieść istniejący workflow do kodu, zaadaptować automatyzację, lub zaimplementować logikę na podstawie źródłowego workflow. Triggery głosowe — "adaptuj", "przepisz workflow", "przenieś automatyzację", "wzoruj się na workflow", "porównaj z oryginałem". Aliasy głosowe: "adaptacja", "adaptator", "konwerter workflow". Auto-aktywacja gdy w kontekście pojawia się Konwerter Automatyzacji lub analiza nodów N8N/Make.com.
---

# Workflow Adaptation

Skill prowadzi agenta przez proces adaptacji istniejącego workflow (N8N, Make.com, Airtable) do nowej implementacji. **NIE implementuje zmian** — prowadzi przez analizę, porównanie i planowanie. Implementacja jest osobnym krokiem.

## Kiedy używać

- **Krótkie aliasy:** "adaptuj", "adaptacja", "adaptator", "konwerter workflow"
- **Pełne frazy:** "zaadaptuj workflow", "przenieś workflow", "przepisz workflow"
- **Kontekstowe:** "na podstawie workflow", "wzoruj się na workflow", "porównaj z oryginałem", "przenieś automatyzację"
- **Platformy:** "z workflow N8N/Make", "wzorcowy workflow", "źródłowy workflow"
- Gdy w kontekście pojawia się Konwerter Automatyzacji
- Gdy zadanie polega na przeniesieniu logiki z platformy no-code do kodu

## Kiedy NIE używać

- Pisanie workflow od zera (brak źródła do adaptacji)
- Proste integracje API bez wzorcowego workflow
- Modyfikacja istniejącego kodu który nie pochodzi z workflow

---

## Proces — 4 kroki

### KROK 1: Pobranie i analiza źródłowego workflow

**OBOWIĄZKOWE przed jakimkolwiek kodowaniem.** Żaden plik nie może być edytowany ani tworzony bez ukończenia tego kroku.

1. **Pobierz workflow** z Konwertera Automatyzacji (lub innego źródła):
   - Konwerter API: `POST` z `{"action": "get-workflow", "params": {"id": "UUID"}}` lub `{"action": "search-workflows", "params": {"q": "fraza"}}`
   - Credentials do Konwertera: sprawdź project memory (`reference-konwerter-api`) lub credentials-vault
   - Jeśli brak dostępu do API: poproś użytkownika o eksport workflow (JSON)

2. **Wylistuj WSZYSTKIE nody/kroki** workflow w kolejności wykonania

3. **Dla KAŻDEGO noda AI** (LLM call) wyciągnij:
   - Model (np. GPT-4o, Claude Sonnet, GPT-5.2)
   - Ilość wiadomości (system, assistant, user) — ile i jakie role
   - **Pełna treść KAŻDEJ wiadomości** — nie skrót, nie streszczenie, pełny tekst
   - Zmienne/templaty (np. `{{ company_name }}`, `{{ keywords }}`)
   - Parametry: temperature, max_tokens, format wyjścia (plain text vs JSON)
   - Retry/fallback logika (jeśli istnieje)

4. **Dla KAŻDEGO noda Code** wyciągnij:
   - Pełny kod
   - Dane wejściowe (skąd bierze dane) i wyjściowe (co zwraca)
   - Transformacje danych

5. **Zidentyfikuj flow danych** między nodami:
   - Co node A przekazuje do node B?
   - Czy są rozgałęzienia warunkowe?
   - Czy są pętle/retry?

**Output:** Zapisz dokument analizy do `.ai/workflow-analysis/[nazwa-workflow].md`

Format dokumentu:
```markdown
# Analiza: [Nazwa Workflow]
Data: [YYYY-MM-DD]
Źródło: [N8N/Make.com/Airtable]

## Nody w kolejności wykonania

### 1. [Nazwa noda] — [Typ: AI/Code/HTTP/Trigger]
- **Model:** [jeśli AI]
- **Wiadomości:** [ilość x role]
- **Prompt system:** [pełna treść]
- **Prompt user:** [pełna treść]
- **Zmienne:** [lista]
- **Parametry:** temperature=[X], max_tokens=[Y], format=[plain/JSON]
- **Input:** [skąd dane]
- **Output:** [co zwraca, do kogo]

### 2. [...]

## Flow danych
[Diagram: Node A → dane X → Node B → dane Y → Node C]

## Uwagi
[Nietypowe elementy, hardcoded wartości, workaroundy]
```

---

### KROK 2: Mapowanie na istniejącą implementację

1. **Dla KAŻDEGO noda źródłowego** → znajdź odpowiadający plik/funkcję w naszym kodzie
2. **Porównaj każdy element** w tabeli:

| Element | Workflow (oryginał) | Nasza implementacja | Różnica | Ocena |
|---------|--------------------|--------------------|---------|-------|
| Prompt system (node X) | [treść] | [treść] | [diff] | OK / Przeoczenie / Ulepszenie |
| Model (node X) | GPT-4o | GPT-5.2 | Inny model | Wyjaśnij dlaczego |
| Format wyjścia (node X) | Plain text, 4 msg | JSON schema, 1 msg | Inna architektura | Ryzyko! |
| Temperature (node X) | 0.7 | 0.45 | Niższa | Uzasadnij |
| Zmienne kontekstowe | company, keywords | tylko keywords | Brak company | Przeoczenie |

3. **Oceń każdą różnicę:**
   - **OK** — świadoma zmiana, uzasadniona
   - **Przeoczenie** — brak elementu, trzeba dodać
   - **Ulepszenie** — lepsza niż oryginał (wymaga uzasadnienia)
   - **Ryzyko** — fundamentalna zmiana architektury (np. plain text → JSON schema)

**Output:** Tabela różnic dopisana do dokumentu analizy

---

### KROK 3: Plan adaptacji

Dla KAŻDEJ różnicy oznaczonej jako "Przeoczenie" lub "Ryzyko":

1. **Przeoczenie** → zaplanuj naprawę (dodaj brakujący element)
2. **Ryzyko** → zaproponuj użytkownikowi:
   - Opcja A: Wrócić do architektury oryginału (bezpieczniejsze)
   - Opcja B: Zachować naszą wersję (wyjaśnij trade-off)
3. **Ulepszenie** → uzasadnij DLACZEGO jest lepsze niż oryginał

**ZASADA DOMYŚLNA:** Jeśli oryginał działa dobrze (np. daje score 99 w NeuronWriter, generuje poprawne artykuły) — **ADAPTUJ wiernie, NIE ulepszaj**. Ulepszenia TYLKO za zgodą użytkownika.

**Output:** Lista zmian do wdrożenia, po jednej na raz, z priorytetem:
1. Krytyczne (brakujące elementy blokujące działanie)
2. Ważne (elementy wpływające na jakość)
3. Kosmetyczne (drobne różnice)

Przedstaw plan użytkownikowi do zatwierdzenia przed przejściem do kroku 4.

---

### KROK 4: Implementacja (po zatwierdzeniu planu)

1. **Jedna zmiana na raz** — nie łącz wielu zmian w jednym deploy
2. **Po każdej zmianie:** deploy → test → weryfikacja wyniku
3. **Jeśli test failuje:**
   - PRZEANALIZUJ przyczynę (logi, output modelu, error message)
   - Zidentyfikuj CO konkretnie nie działa
   - DOPIERO POTEM próbuj naprawić
4. **Limit prób:** Max 2 deploy bez zrozumienia problemu. Po 2 failach → STOP, pokaż użytkownikowi logi i analizę
5. **Nie cofaj się** do wcześniejszych kroków bez powodu — jeśli krok A działa, nie zmieniaj go naprawiając krok B

---

## Zasady bezwzględne

### 1. Źródło najpierw
NIGDY nie pisz kodu przed pełną analizą workflow (Krok 1). Nawet "drobna poprawka" wymaga sprawdzenia oryginału.

### 2. Adaptuj, nie wymyślaj
Jeśli oryginał ma prompt — **przepisz go wiernie**, zmieniając TYLKO:
- Nazwy zmiennych (dostosuj do naszego kontekstu)
- Format (np. Mustache `{{ var }}` → template literal `${var}`)
- Elementy specyficzne dla platformy (N8N expressions → JS/TS)

**NIE zmieniaj:** treści promptu, struktury wiadomości, instrukcji dla modelu.

### 3. Jeden problem na raz
Nie skakaj między elementami. Napraw A → potwierdź że działa → przejdź do B.

### 4. Respektuj architekturę oryginału
- Oryginał używa **plain text output** → NIE forsuj JSON schema
- Oryginał ma **4 wiadomości** (system, assistant, user, user) → NIE scalaj w 1
- Oryginał ma **retry z fallback modelem** → zaimplementuj retry, nie ignoruj
- Oryginał **dzieli zadanie na etapy** → NIE łącz w jedno wywołanie

### 5. Model ≈ model
GPT-4o ≠ GPT-5.2 ≠ Claude Sonnet. Jeśli oryginał działa na GPT-4o:
- Zacznij od porównywalnego modelu (ten sam provider, zbliżona klasa)
- Zmiana modelu = zmiana zachowania promptu — testuj po każdej zmianie
- Dokumentuj dlaczego zmieniono model (koszt, szybkość, dostępność)

### 6. Nie debuguj na ślepo
Po 2 nieudanych próbach:
1. ZATRZYMAJ SIĘ
2. Przeanalizuj logi (co model zwraca? jaki error?)
3. Pokaż użytkownikowi analizę
4. Zaproponuj plan naprawy LUB zmianę podejścia

---

## Pułapki

### 1. Agent pisze własne prompty zamiast adaptować
Najczęstszy i najkosztowniejszy błąd. Agent "wie lepiej" i pisze prompt od zera — wynik jest gorszy niż oryginał przetestowany na setkach uruchomień.

**Rozwiązanie:** Krok 1 wymusza pełne wyciągnięcie promptów. Krok 2 wymusza porównanie 1:1.

### 2. Forsowanie JSON schema gdy oryginał używa plain text
Structured output (Zod schema, JSON mode) wymusza inny styl generowania. Model może nie generować treści tak dobrze jak w plain text mode. Jeśli oryginał używa plain text + parser — **użyj plain text + parser**.

### 3. Scalanie wielu wiadomości w jedną
Oryginał z 4 wiadomościami (system, assistant prefill, user context, user instruction) ma to z powodu — każda rola wpływa na zachowanie modelu. Scalenie w 1 wiadomość zmienia dynamikę.

### 4. Deploy-test-fail w pętli
Agent deploy'uje → czeka 30s → fail → zmienia coś → deploy → czeka → fail... bez analizy przyczyny. Po 5+ takich cyklach użytkownik traci cierpliwość i czas.

**Rozwiązanie:** Limit 2 prób. Po 2. failu → analiza logów.

### 5. Ignorowanie zmiennych kontekstowych
Oryginał wstrzykuje `{{ company_name }}`, `{{ target_audience }}`, `{{ brand_voice }}` do promptu. Agent pomija te zmienne bo "nie są wymagane" — wynik jest generyczny.

### 6. Zmiana temperature bez uzasadnienia
Temperature wpływa na kreatywność/powtarzalność. Oryginał z `temperature: 0.7` daje zróżnicowane treści. Zmiana na `0.3` daje powtarzalne, sztywne wyniki.

### 7. Nadpisywanie działających kroków
Naprawiając krok C, agent "przy okazji" zmienia krok A który działał. Wynik: krok C nadal nie działa, a krok A przestał.

### 8. Brak checkpointu między krokami
Workflow z 10 krokami — jeśli krok 7 failuje, agent re-runuje od kroku 1. Implementuj checkpointy: zapisuj wynik każdego kroku, wznów od ostatniego sukcesu.

---

## Integracja z innymi narzędziami

### Konwerter Automatyzacji
Źródło danych o workflow'ach N8N/Make.com. Credentials w project memory (`reference-konwerter-api`) lub credentials-vault.

### Codex delegation
Po analizie (Kroki 1-3) — proste adaptacje (1-2 pliki) można zlecić Codexowi jako task w `.codex/tasks/`.

### AI Crew
Złożone adaptacje (4+ plików, wiele kroków) — użyj `crew run "Brief: Adaptacja workflow [nazwa]"`.

### Pipeline Control Panel
Testowanie adaptacji w trybie supervised (step-by-step approval) — idealne do weryfikacji każdego kroku po adaptacji.
