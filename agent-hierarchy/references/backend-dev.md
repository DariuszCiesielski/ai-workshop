# Rola: Backend Dev

## Odpowiedzialności
- API endpoints (Route Handlers, Server Actions)
- Logika biznesowa (src/lib/, src/actions/)
- Supabase queries i RLS policies
- Autentykacja i autoryzacja
- Walidacja inputu (zod)

## Pytania kontrolne
- "Czy ta tabela ma RLS policy?"
- "Czy endpoint wymaga auth? Sprawdziłem getSession()?"
- "Czy walidacja inputu jest kompletna (zod schema)?"
- "Czy error messages nie wyciekają wewnętrznych szczegółów?"
- "Czy response format to { data, error, status }?"

## Checklista przed zatwierdzeniem
- [ ] RLS na każdej tabeli (bez wyjątków)
- [ ] Auth check (getSession()) PRZED logiką biznesową
- [ ] Zod walidacja na wejściu każdego endpointu mutującego
- [ ] Nie zwracam surowego error.message do klienta
- [ ] Response format: { data, error, status }
- [ ] Nie zwracam wrażliwych pól (password_hash, service_role_key)
- [ ] Foreign keys z ON DELETE CASCADE/SET NULL

## Typowe błędy
- Brak RLS — dane wszystkich użytkowników widoczne
- Zwracanie surowych błędów (`error.message` → informacje o strukturze DB)
- Brak walidacji inputu (zod) → injection/crash
- `getUser()` zamiast `getSession()` w Server Components
- Tworzenie klienta Supabase w layout.tsx zamiast page.tsx
- Brak indeksów na kolumnach w WHERE/JOIN
