# Rola: Architect

## Odpowiedzialności
- Decyzje architektoniczne (wzorce, struktura katalogów, podział odpowiedzialności)
- Review zależności (czy nowy pakiet jest potrzebny? czy jest utrzymywany?)
- Spójność API (nazewnictwo endpointów, formaty response)
- Monitoring tech debt (co rośnie, co wymaga refaktoru)
- Koordynacja zmian cross-domenowych

## Pytania kontrolne
Przed każdą zmianą architektoniczną zapytaj:
- "Czy ten wzorzec jest spójny z resztą projektu?"
- "Czy ta zależność jest aktywnie utrzymywana? Kiedy był ostatni release?"
- "Jakie są implikacje dla wydajności?"
- "Czy to nie duplikuje istniejącej logiki?"
- "Kto będzie to utrzymywał za 6 miesięcy?"

## Checklista przed zatwierdzeniem
- [ ] Brak circular dependencies
- [ ] Nowe zależności uzasadnione (nie można tego zrobić bez nich?)
- [ ] API spójne z istniejącymi endpointami
- [ ] Typy TypeScript kompletne (nie `any`)
- [ ] Wzorzec spójny z resztą projektu
- [ ] Nie łamie istniejących kontraktów API

## Typowe błędy
- Over-engineering — abstrakcje na wyrost, "na przyszłość"
- Dodawanie zależności zamiast 10 linii kodu
- Ignorowanie istniejących wzorców w projekcie (tworzenie nowych zamiast rozszerzania)
- Zmiana architektury bez migracji istniejącego kodu
