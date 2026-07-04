---
name: task-decomposer
description: >
  Rozbija złożone zadania na hierarchię Epic→Story→Task→Subtask z analizą zależności
  i strategią wykonania (sequential/parallel). Lekka alternatywa dla GSD — bez ceremoniału,
  wynik trafia do TodoWrite. Używaj gdy zadanie jest za duże na flat listę,
  ale za małe na pełny framework GSD.
  Triggery: "rozbij na mniejsze", "dekompozycja", "breakdown", "plan zadań",
  "rozłóż to na kroki", "jak to podzielić", "epic", "story", "rozbij task".
  NIE używaj do prostych zadań (1-3 kroki) — TodoWrite wystarczy.
  NIE używaj do projektów z wieloma fazami — od tego jest GSD.
---

# Task Decomposer — hierarchiczna dekompozycja zadań

## Kiedy używać

| Złożoność | Narzędzie |
|-----------|-----------|
| 1-3 kroki, oczywiste | TodoWrite bezpośrednio |
| **4-15 kroków, wiele domen** | **Task Decomposer** |
| 15+ kroków, fazy, milestones | GSD framework |

## Komenda

```
/decompose <opis zadania> [--strategy sequential|parallel|adaptive] [--depth shallow|normal|deep]
```

Domyślnie: `--strategy adaptive --depth normal`

## Procedura

### 1. Analiza scope (30s)

Przeczytaj zadanie i odpowiedz sobie:
- Ile **domen** jest zaangażowanych? (DB, API, UI, auth, deploy, zewnętrzne API...)
- Czy są **zależności** między krokami? (X musi być przed Y)
- Czy coś można robić **równolegle**?

### 2. Dekompozycja 4 poziomów

```
EPIC: [Cel biznesowy — 1 zdanie]
├── STORY 1: [Funkcjonalność użytkownika]
│   ├── TASK 1.1: [Konkretna zmiana w kodzie]
│   │   ├── subtask: Plik/komponent do stworzenia
│   │   └── subtask: Test do napisania
│   └── TASK 1.2: [...]
├── STORY 2: [...]
│   └── ...
└── STORY N: [Weryfikacja + deploy]
```

**Reguły:**
- **Epic** = 1 per zadanie (cel biznesowy, nie techniczny)
- **Story** = wartość dostarczana użytkownikowi (2-5 stories per epic)
- **Task** = atomowa zmiana w kodzie, 15-60 min pracy (2-4 taski per story)
- **Subtask** = opcjonalnie, tylko przy `--depth deep`

### 3. Analiza zależności

Przy każdym Story oznacz:
- `[SEQ]` — wymaga ukończenia poprzedniego Story
- `[PAR]` — niezależne, można robić równolegle
- `[BLOCKED: Story X]` — zablokowane przez konkretne Story

### 4. Strategia wykonania

| Strategia | Kiedy |
|-----------|-------|
| `sequential` | Silne zależności, 1 domena, krytyczna kolejność |
| `parallel` | Niezależne Story, wiele domen, szybkość |
| `adaptive` | Mix — niektóre SEQ, niektóre PAR (domyślne) |

### 5. Output → TodoWrite

Przekształć hierarchię w flat listę TodoWrite z prefiksami:

```
[S1] Story: Schemat bazy danych                    → in_progress
[S1.T1] Tabela users z RLS                         → pending
[S1.T2] Tabela orders z FK                          → pending
[S2 PAR] Story: API endpoints                       → pending
[S2.T1] POST /api/orders                            → pending
[S3 SEQ] Story: Frontend + testy                    → pending
```

Prefiks `[S1.T2]` pozwala agentowi nawigować hierarchię w flat liście.

## Pułapki

1. **Over-decomposition** — nie rozbijaj 30-minutowego taska na 10 subtasków. Jeśli task jest jasny, zostaw go atomowym.
2. **Brak weryfikacji w hierarchii** — ZAWSZE dodaj ostatnie Story: "Weryfikacja + testy E2E". Bez tego agent zapomni przetestować.
3. **Ignorowanie zależności** — oznaczaj SEQ/PAR explicite. Agent bez oznaczeń zacznie od najłatwiejszego, nie od zablokowanego.
