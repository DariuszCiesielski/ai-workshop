---
name: github-repo-polish
description: >
  Wzorzec Trabzady: przerabianie publicznych repo GitHub na lead magnety.
  README z wartością biznesową, install.sh, CTA do płatnych produktów.
  Trigger: "wypoleruj repo", "wzorzec Trabzady", "dodaj install.sh", "repo lead magnet".
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# GitHub Repo Polish — wzorzec Trabzady

> Zamień publiczne repo w lead magnet: README z wartością biznesową, install.sh, CTA do SaaS-ów.

## Kiedy używać
- Publiczne repo ma 0 gwiazdek i techniczny README
- Chcesz przekształcić repo w narzędzie marketingowe
- Tworzysz nowe publiczne repo

## Dwa typy repo

### Typ A: Skill Pack (instalowalne)
Repo zawiera skille/narzędzia, które użytkownik instaluje i używa.
Przykłady: polish-agent-skills, claude-code-saas-skills, geo-seo-claude

### Typ B: Knowledge Base (dokumentacja)
Repo zawiera wiedzę, wzorce, przewodniki — użytkownik czyta, nie instaluje.
Przykłady: ai-automatyzacja-biznesu, claude-code-kompendium, supabase-wzorce

---

## Szablon README — Typ A (Skill Pack)

```markdown
<p align="center">
  <strong>[NAZWA] — [TAGLINE PO POLSKU]</strong><br/>
  [1 zdanie: co to robi i dla kogo]
</p>

<p align="center">
  <img src="https://img.shields.io/badge/skilli-N-blue" alt="N skills"/>
  <img src="https://img.shields.io/badge/język-PL-red" alt="Polski"/>
  <img src="https://img.shields.io/badge/licencja-MIT-green" alt="MIT"/>
  <img src="https://img.shields.io/badge/Claude_Code-✓-blueviolet" alt="Claude Code"/>
</p>

---

## Dlaczego to ważne (2026)

| Metryka | Wartość |
|---------|---------|
| [stat 1] | [wartość + źródło] |
| [stat 2] | [wartość + źródło] |
| [stat 3] | [wartość + źródło] |

---

## Szybki start — 1 komenda

```bash
curl -fsSL https://raw.githubusercontent.com/DariuszCiesielski/[REPO]/main/install.sh | bash
```

### Instalacja ręczna
```bash
git clone https://github.com/DariuszCiesielski/[REPO].git
cd [REPO]
./install.sh
```

---

## Co dostajesz

| # | Skill / Narzędzie | Co robi | Zastosowanie |
|---|-------------------|---------|--------------|
| 1 | [nazwa] | [opis] | [use case] |
| ... | ... | ... | ... |

---

## Komendy

| Komenda | Co robi |
|---------|---------|
| `/[cmd1]` | [opis] |
| `/[cmd2]` | [opis] |

---

## Chcesz więcej?

🔧 **[Specjalista SEO](https://link)** — pełny SaaS z dashboardem, raportami PDF i trackingiem
📊 **[Marketing Hub](https://link)** — automatyzacja marketingu z AI
📬 **[Kontakt](https://aiwbiznesie.online/kontakt/)** — wdrożenia AI dla firm

---

## Licencja

MIT — używaj komercyjnie, modyfikuj, dystrybuuj.

---

<p align="center">
  <sub>Zbudowane przez <a href="https://aiwbiznesie.online">AI w Biznesie</a> — automatyzacja i wdrożenia AI dla polskich firm</sub>
</p>
```

---

## Szablon README — Typ B (Knowledge Base)

```markdown
<p align="center">
  <strong>[NAZWA] — [TAGLINE PO POLSKU]</strong><br/>
  [1 zdanie: co to jest i dla kogo]
</p>

<p align="center">
  <img src="https://img.shields.io/badge/język-PL-red" alt="Polski"/>
  <img src="https://img.shields.io/badge/licencja-MIT-green" alt="MIT"/>
  <img src="https://img.shields.io/badge/rozdziałów-N-blue" alt="N rozdziałów"/>
</p>

---

## Dlaczego to ważne

[2-3 zdania z danymi: problem, skala, okno szansy]

---

## Spis treści

1. [Rozdział 1](docs/01-xxx.md) — [opis]
2. [Rozdział 2](docs/02-xxx.md) — [opis]
...

---

## Dla kogo

- ✅ [persona 1 — CEO/właściciel firmy]
- ✅ [persona 2 — marketer/specjalista]
- ✅ [persona 3 — developer/technik]

---

## Chcesz to wdrożyć?

Wiedza jest darmowa. Wdrożenie wymaga narzędzi.

🔧 **[Nazwa SaaS-a](link)** — [co robi, 1 zdanie]
📊 **[Nazwa SaaS-a](link)** — [co robi, 1 zdanie]
📬 **[Kontakt](https://aiwbiznesie.online/kontakt/)** — wdrożenia AI dla firm

---

## Licencja

MIT

---

<p align="center">
  <sub>Zbudowane przez <a href="https://aiwbiznesie.online">AI w Biznesie</a></sub>
</p>
```

---

## install.sh — szablon (tylko Typ A)

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/DariuszCiesielski/[REPO].git"
SKILLS_DIR="${HOME}/.claude/skills"
TEMP_DIR=$(mktemp -d)

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

echo -e "${BLUE}[NAZWA] — instalacja...${NC}"

# Prereqs
command -v git &>/dev/null || { echo -e "${RED}Git wymagany.${NC}"; exit 1; }

# Clone
git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null || {
    echo -e "${RED}Błąd klonowania. Sprawdź połączenie.${NC}"; exit 1
}

# Install skills
mkdir -p "$SKILLS_DIR"
COUNT=0
for skill_dir in "$TEMP_DIR/repo/skills/"*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    # Szukaj SKILL.md na różnych głębokościach
    if [ -f "$skill_dir/SKILL.md" ]; then
        cp -r "$skill_dir" "$SKILLS_DIR/$skill_name"
        COUNT=$((COUNT + 1))
    else
        for sub in "$skill_dir"*/; do
            [ -f "$sub/SKILL.md" ] || continue
            sub_name=$(basename "$sub")
            cp -r "$sub" "$SKILLS_DIR/$sub_name"
            COUNT=$((COUNT + 1))
        done
    fi
done

echo -e "${GREEN}✓ Zainstalowano $COUNT skilli do $SKILLS_DIR${NC}"
echo ""
echo -e "${BLUE}Otwórz Claude Code i użyj nowych skilli.${NC}"
echo -e "Dokumentacja: https://github.com/DariuszCiesielski/[REPO]"
```

---

## Checklist polerowania repo

- [ ] README przepisany wg szablonu (Typ A lub B)
- [ ] install.sh (tylko Typ A) — przetestowany lokalnie
- [ ] Badge'e w nagłówku (skills count, język, licencja)
- [ ] Sekcja "Dlaczego to ważne" z danymi rynkowymi
- [ ] Sekcja "Chcesz więcej?" z CTA do SaaS-ów
- [ ] Stopka z linkiem do aiwbiznesie.online
- [ ] README.en.md — wersja angielska (opcjonalnie, po PL)
- [ ] LICENSE plik (MIT)
- [ ] .gitignore aktualny
