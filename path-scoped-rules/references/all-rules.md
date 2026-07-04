# Path-scoped rules — pełna referencja

## Format pliku reguł

Każdy plik w `.claude/rules/` musi mieć YAML frontmatter z `path_glob`:

```yaml
---
path_glob: "src/components/**"
---
```

### Składnia path_glob

| Wzorzec | Dopasowanie |
|---------|-------------|
| `src/components/**` | Wszystkie pliki w components/ i podkatalogach |
| `**/*.css` | Wszystkie pliki CSS w projekcie |
| `src/app/api/**` | Wszystkie API routes |
| `{src/__tests__/**,**/*.test.*}` | Testy (folder + pliki .test.) |
| `*.config.*` | Pliki konfiguracyjne w rootcie |

### Reguły bez path_glob

Plik bez frontmatter lub bez `path_glob` jest ładowany ZAWSZE (jak CLAUDE.md). Używaj tego ostrożnie.

## Drzewo decyzyjne — co gdzie umieścić

```
Reguła dotyczy KONKRETNEGO katalogu?
├── TAK → .claude/rules/{katalog}.md z path_glob
└── NIE → Reguła jest globalna?
    ├── TAK → CLAUDE.md (konwencje nazewnictwa, język, workflow)
    └── NIE → Reguła jest złożona (wymaga kodu, przykładów)?
        ├── TAK → Skill w ~/.claude/skills/
        └── NIE → .claude/rules/ bez path_glob
```

## Przykład wdrożenia w projekcie Marketing Hub

```bash
# Analiza struktury
$ ls -d src/*/
src/app/   src/components/   src/lib/   src/styles/

$ ls -d supabase/ e2e/ prototypes/ 2>/dev/null
supabase/

# Decyzja: 4 pliki reguł (components, api-routes, supabase, styles)
# Bez: tests.md (brak testów), prototypes.md (brak katalogu)

$ mkdir -p .claude/rules
# Stwórz 4 pliki...
```

## Migracja z CLAUDE.md

Typowe reguły do przeniesienia:

| Reguła w CLAUDE.md | Przenieś do |
|---------------------|-------------|
| "Używaj shadcn/ui" | components.md |
| "Waliduj inputy zod" | api-routes.md |
| "Każda tabela ma RLS" | supabase.md |
| "Tailwind, nie inline style" | components.md |
| "Conventional commits" | Zostaw w CLAUDE.md (globalna) |
| "Język polski" | Zostaw w CLAUDE.md (globalna) |

## Weryfikacja

Po wdrożeniu reguł, sprawdź działanie:

```bash
# Otwórz Claude Code w projekcie
cd ~/projekty/MojProjekt
claude

# Edytuj komponent — agent powinien stosować reguły z components.md
# Edytuj API route — agent powinien stosować reguły z api-routes.md
# Sprawdź w logach czy reguły są ładowane (--debug mode)
```
