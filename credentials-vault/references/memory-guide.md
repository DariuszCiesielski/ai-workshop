# Pamięć skilla — credentials-vault

## Cel

Skill zbiera dane z uruchomień, żeby kolejne uruchomienie w tym samym projekcie było lepsze. Pamięć pozwala unikać powtarzania tych samych błędów i znać preferencje użytkownika.

## Gdzie zapisywać

```
~/.claude/skills/credentials-vault/logs/run-YYYY-MM-DD-HHMM.md
```

## Format logu

```markdown
# credentials-vault — log uruchomienia
Data: 2026-03-18 14:30
Projekt: Hotel Demo

## Operacje
- Załadowano: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
- Zapisano nowy: STRIPE_SECRET_KEY (test mode)
- Zaktualizowano: SUPABASE_DB_PASSWORD (zmiana na silniejsze)

## Problemy
- Hasło DB zawierało `$` — wymagało single quotes w psql

## Odkryte preferencje
- Użytkownik preferuje test keys Stripe z `sk_test_` prefix
```

## Kiedy zapisywać

- Po **każdym** użyciu skilla w projekcie (niezależnie czy były problemy)
- Log musi być **zwięzły** (max 15 linii)

## Jak czytać przed uruchomieniem

Przed operacjami na credentials:

1. `ls ~/.claude/skills/credentials-vault/logs/` — sprawdź czy są logi
2. Przeczytaj **ostatnie 3** logi (najnowsze) — szukaj:
   - Które klucze były problematyczne (znaki specjalne, wygasłe JWT)
   - Preferencje użytkownika (np. zawsze test mode)
   - Workaroundy zastosowane w przeszłości

## Automatyczne czyszczenie

Logi starsze niż 30 dni mogą być usunięte. Zachowaj log jeśli zawiera:
- Pułapkę nie opisaną w SKILL.md (→ dodaj do SKILL.md i usuń log)
- Trwałą preferencję użytkownika (→ dodaj do config.json i usuń log)
