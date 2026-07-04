# Prompt: Aktualizacja przyrostowa

> Jesteś odpowiedzialny za aktualizację sekcji pomocy po zmianach w aplikacji. Aktualizujesz TYLKO dotknięte strony — nie regenerujesz całości.

## Cel

Porównaj obecny stan aplikacji z cachem w `.help/analysis.json` i zaktualizuj tylko zmienione strony pomocy.

## Kontekst projektu

{{PROJECT_CONTEXT}}

## Proces aktualizacji

### Krok 1: Ponów analizę

Uruchom pełną analizę aplikacji (patrz [analyzer.md](analyzer.md)) i wygeneruj nowy `analysis.json` w pamięci (nie nadpisuj jeszcze pliku).

### Krok 2: Porównaj z cachem

Przeczytaj istniejący `.help/analysis.json` i porównaj z nową analizą:

| Typ zmiany | Jak wykryć | Akcja |
|------------|-----------|-------|
| **Nowa ścieżka** | path w nowym, brak w starym `routes` | Dodaj do odpowiedniej strony pomocy |
| **Usunięta ścieżka** | path w starym, brak w nowym | Usuń z pomocy lub oznacz jako archiwalna |
| **Zmieniony formularz** | inne pola, walidacja, akcja submit | Zaktualizuj opis pól i flow |
| **Nowa rola** | nowy typ w `roles.types` | Zaktualizuj sekcję uprawnień |
| **Nowa integracja** | nowy wpis w `config.integrations` | Dodaj konfigurację |
| **Zmieniona nawigacja** | inne etykiety, kolejność, grupy | Zaktualizuj mapę nawigacji |
| **Nowy stan UI** | nowy komponent error/empty/loading | Dodaj do FAQ |

### Krok 3: Zidentyfikuj dotknięte strony

Mapowanie zmian na strony pomocy:

| Zmiana dotyczy | Strona do aktualizacji |
|---------------|----------------------|
| `config.envVars`, `config.integrations` | `ConfigurationHelp.tsx` |
| `roles`, formularze auth | `UserManagementHelp.tsx` |
| `routes`, `forms`, `navigation` | `UserFlowsHelp.tsx` |
| `navigation` | `NavigationHelp.tsx` |
| `states`, edge cases | `FAQHelp.tsx` |

### Krok 4: Zaktualizuj dotknięte strony

Dla każdej dotkniętej strony:

1. **Przeczytaj** istniejący komponent
2. **Edytuj** — zmień tylko sekcje dotyczące zmienionych elementów
3. **Zachowaj** — nie ruszaj sekcji których zmiana nie dotyczy
4. **Dodaj** — nowe sekcje dla nowych elementów

### Krok 5: Zaproponuj nowe strony

Jeśli pojawiły się nowe, duże features (≥3 nowe ścieżki z formularzami):

1. Zaproponuj użytkownikowi nową stronę pomocy
2. Podaj sugerowaną nazwę i zakres
3. Czekaj na potwierdzenie przed generowaniem

### Krok 6: Zaktualizuj cache

Po zakończeniu aktualizacji nadpisz `.help/analysis.json` nową wersją.

### Krok 7: Zaktualizuj nawigację

Jeśli dodano/usunięto strony:
- Zaktualizuj `HelpNav.tsx` — dodaj/usuń linki
- Zaktualizuj routing (jeśli nowe strony)

## Zasady

> **KRYTYCZNE:** Przyrostowość jest kluczowa. Nigdy nie regeneruj strony od zera jeśli zmiana dotyczy jednej sekcji. Użyj Edit tool, nie Write tool.

1. **Minimum zmian** — edytuj tylko to co się zmieniło
2. **Zachowaj styl** — nowe treści w tym samym tonie i formacie co istniejące
3. **Nie usuwaj bez pytania** — jeśli ścieżka zniknęła, zapytaj użytkownika czy usunąć z pomocy
4. **Loguj zmiany** — na końcu wylistuj co zostało zmienione i dlaczego

## Format raportu zmian

Po aktualizacji wyświetl:

```
Zaktualizowano sekcję pomocy:
  ✓ ConfigurationHelp.tsx — dodano konfigurację Cloudinary
  ✓ UserFlowsHelp.tsx — zaktualizowano flow "Dodawanie zdjęć"
  ✓ HelpNav.tsx — dodano link do nowej sekcji
  ○ FAQHelp.tsx — bez zmian
  ○ UserManagementHelp.tsx — bez zmian
  ○ NavigationHelp.tsx — bez zmian

Nowy analysis.json zapisany.
```
