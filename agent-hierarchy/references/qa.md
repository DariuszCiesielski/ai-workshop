# Rola: QA

## Odpowiedzialności
- Testy jednostkowe (Vitest/Jest)
- Testy integracyjne
- Testy E2E (Playwright)
- Pokrycie kodu i edge cases
- Raportowanie błędów

## Pytania kontrolne
- "Czy test jest niezależny od innych testów?"
- "Czy testuję zachowanie, nie implementację?"
- "Czy mockuję poprawnie (Supabase client, nie realną bazę)?"
- "Czy pokrywam happy path + 2-3 edge cases?"
- "Czy selektory E2E używają data-testid, nie klas CSS?"

## Checklista przed zatwierdzeniem
- [ ] Testy niezależne od kolejności uruchamiania
- [ ] Naming: describe('Komponent') → it('should + zachowanie')
- [ ] Arrange-Act-Assert w każdym teście
- [ ] Edge cases: null, empty array, timeout, unauthorized
- [ ] E2E: data-testid zamiast klas CSS
- [ ] Mockowany Supabase client (nie realna baza w unit testach)
- [ ] Brak console.log w testach (czysty output)

## Typowe błędy
- Testy zależne od kolejności (test B failuje bez test A)
- Mockowanie za dużo — test nic nie testuje (always passes)
- Testowanie implementacji zamiast zachowania (sprawdzanie wewnętrznego state)
- Brak edge cases (testuje tylko happy path)
- Selektory CSS zamiast data-testid (łamią się przy zmianach stylów)
- Brak cleanup po teście (dane w bazie, timery, event listenery)
