---
name: careful
description: Safety guardrails dla destructive operations (rm -rf, DROP TABLE, git push --force, kubectl delete, dd to /dev/, mkfs). Zarządza stanem hooka PreToolUse Bash w `~/.claude/.careful-state.json`. Trigger: "/careful", "careful on/off", "careful strict", "włącz tryb ostrożny", "wyłącz careful". Implementuje §9 CLAUDE.md (destructive ops zawsze pytaj) systemowo, na poziomie hooka harness.
---

# Careful — Destructive Operation Guardrails

Hook PreToolUse Bash blokuje (`level=block`) lub ostrzega (`level=warn`) przed niebezpiecznymi komendami. Wymusza świadomą decyzję zamiast egzekucji w pędzie.

## Kiedy używać

- Przed prod work (Hotel Demo, Marketing Hub klient płatny, ClientA voicebot)
- Przed batch ops na DB (drop kolumn, truncate, mass update)
- Sesja debugowa z pętlą "fix → push → test" gdzie zmęczenie zwiększa risk
- Onboarding nowego projektu — zanim user pozna co jest "OK do zniszczenia"

## Kiedy NIE używać

- Sesje development greenfield — destructive ops na test data są normalne, blokowanie spowalnia
- Ad-hoc scripting — oczekiwane usuwanie temp files, repeat sync, etc.

## Stany

State plik: `~/.claude/.careful-state.json`
```json
{
  "active": true | false,    // Hook reaguje czy nie
  "level": "warn" | "block"  // Warn = stderr message + allow; Block = exit 2 = stop
}
```

Domyślnie state file nie istnieje → hook NIE działa. Aby aktywować — utwórz plik z `active=true`.

## Komendy / triggers

### "careful on" / "włącz careful" / "/careful"
Default: `warn` mode (komunikaty, brak blokady). Daje świadomość bez friction.

```bash
echo '{"active": true, "level": "warn"}' > ~/.claude/.careful-state.json
```

### "careful strict" / "careful block" / "careful enforce"
Tryb hard-block. Hook zwraca exit 2 = command nie wykona się. Tylko `CAREFUL_OVERRIDE=1` lub manual disable obchodzi.

```bash
echo '{"active": true, "level": "block"}' > ~/.claude/.careful-state.json
```

### "careful off" / "wyłącz careful" / "unfreeze careful"
Hook nieaktywny — wszystkie commendy przechodzą bez sprawdzenia.

```bash
echo '{"active": false, "level": "warn"}' > ~/.claude/.careful-state.json
```

### "careful status"
Pokaż aktualny stan:
```bash
cat ~/.claude/.careful-state.json 2>/dev/null || echo "Hook nieaktywny (brak state file)"
```

## Co wykrywa hook

Pattern matching word-boundary (regex), nie podstring (chroni przed false positives jak `rm -rf node_modules` w cwd):

| Pattern | Przykład |
|---|---|
| `rm -rf /<absolute-path>` | `rm -rf /Users/data` (NIE `rm -rf node_modules`) |
| `rm -rf $HOME` lub `~/` | `rm -rf ~/Downloads` |
| `DROP TABLE` / `DROP DATABASE` / `TRUNCATE TABLE` | SQL destructive |
| `git push --force` / `git push -f` | Force push |
| `git reset --hard` | Lokalna utrata zmian |
| `git clean -f` | Usuwa untracked |
| `git branch -D` | Hard branch delete |
| `kubectl delete` | k8s resource delete |
| `docker system prune` | Docker cleanup |
| `mkfs.*` | Format dysku |
| `dd ... of=/dev/...` | Direct device write |
| `shutdown` / `reboot` / `killall -9` | System ops |

## Jak omijać hook (gdy świadomie)

### Single-op bypass
Prepend `CAREFUL_OVERRIDE=1 ` do komendy:
```bash
CAREFUL_OVERRIDE=1 git push --force origin feature/test
```
Hook nadal pokaże warning na stderr, ale przepuści (exit 0).

### Persistent disable
```bash
echo '{"active": false}' > ~/.claude/.careful-state.json
```

## Pułapki

### ❌ False positive na `rm -rf node_modules`
**Objaw:** hook blokuje legalne czyszczenie `node_modules/` w projekcie
**Przyczyna:** wzorzec `rm -rf /[^[:space:]]` matchuje absolute paths, NIE relative
**Rozwiązanie:** pattern jest word-boundary'd na `/` — `rm -rf node_modules` przechodzi (relative path), `rm -rf /Users/...` blokuje. Jeśli mimo to false positive — dodaj wyjątek w hook script.

### ❌ Block w środku batch script
**Objaw:** wieloliniowy bash script z `git push --force` w 5. linii — hook odrzuca CAŁY script (exit 2 = całość blocked)
**Przyczyna:** hook widzi cały command string, nie pojedyncze linie
**Rozwiązanie:** wydziel destructive ops do osobnego Bash call, lub użyj `CAREFUL_OVERRIDE=1` na początku.

### ❌ State file korumpacja
**Objaw:** hook crashuje (exit z error), wszystkie Bash blokowane
**Przyczyna:** `~/.claude/.careful-state.json` ma broken JSON
**Rozwiązanie:** `rm ~/.claude/.careful-state.json` przywraca default OFF.

### ❌ Sound similar bypass attempt
**Objaw:** Claude pisze `rm -rf /Users/data` udając że "to nie jest prawdziwa operacja"
**Przyczyna:** hook nie rozróżnia kontekstu, tylko match pattern
**Rozwiązanie:** pattern matching jest świadomie konserwatywny — to feature, nie bug. Lepiej blokować false positive niż wpuścić destructive.

## Decyzje projektowe

- **OFF by default** — hook nie aktywuje się dopóki user świadomie nie utworzy state file. Brak surprise factor.
- **Warn jako default po włączeniu** — łagodniejsza reguła; user widzi co hook by blokował, decyduje czy upgradować na `block`
- **Bypass przez env var, nie flag** — `CAREFUL_OVERRIDE=1 cmd` jest jawny w transcript, łatwo audytowalne. Flaga (`--force-yes`) byłaby per-tool i nie generic
- **Word-boundary regex, nie substring** — `node_modules` ≠ `/`, ergo `rm -rf node_modules` = OK
- **Ekstensywna lista wzorców** — łatwiej dodać niż usuwać; false positive ma niski cost (CAREFUL_OVERRIDE), false negative wysoki (zniszczona produkcja)

## Pokrewne

- `freeze` (planowane) — edit boundary do katalogu, blokuje Edit/Write poza scope
- `guard` (planowane) — `careful` + `freeze` razem (full safety mode)
- `unfreeze` (planowane) — clear boundary

## Hook implementation

Skrypt: `~/.claude/hooks/careful-check.sh`
Rejestracja: `~/.claude/settings.json` PreToolUse z matcher `Bash`
