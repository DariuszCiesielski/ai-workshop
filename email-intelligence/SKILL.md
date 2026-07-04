---
name: email-intelligence
description: Automatyczny skan maili na starcie sesji — wychwytuje krytyczne alerty (Supabase pausing, awarie, security), faktury i płatności. Generuje raport w .ai/email-intel/.
---

## Opis

Skill skanuje maile z ostatnich 48h za pomocą Gmail MCP, kategoryzuje je i generuje raport. Uruchamiany jako agent w tle na starcie sesji — nie blokuje głównej pracy.

## Triggery

- Start sesji (automatycznie przez hook — patrz sekcja Integracja)
- "sprawdź maile"
- "email intel"
- "raport maili"
- "co w mailach"

## Instrukcje

### 1. Skanuj maile (Gmail MCP)

Wykonaj 3 równoległe zapytania:

```
gmail_search_messages({ q: "from:supabase OR from:vercel OR from:github subject:(paused OR error OR vulnerability OR failed OR warning) after:YYYY/M/D", maxResults: 20 })
gmail_search_messages({ q: "subject:faktura OR subject:invoice OR subject:payment OR subject:płatność after:YYYY/M/D", maxResults: 15 })
gmail_search_messages({ q: "is:unread is:important after:YYYY/M/D", maxResults: 10 })
```

Gdzie `YYYY/M/D` = data 48h temu.

### 2. Kategoryzuj wyniki

**🔴 KRYTYCZNE** (wymaga ręcznego działania):
- Supabase: "has been paused", "going to be paused", "security vulnerabilities"
- Vercel: "deployment failed", "domain expired"
- Płatności: "payment failed", "subscription expired"
- GitHub: "security advisory", "access revoked"

**💰 FAKTURY**:
- Słowa: faktura, invoice, payment received, receipt
- Wyciągnij: nadawca, kwota (jeśli w snippecie), data

**ℹ️ INFO**:
- Ważne ale niekrytyczne: deploy status, changelog, welcome emails, OAuth approvals

### 3. Wygeneruj raport

Zapisz do `.ai/email-intel/YYYY-MM-DD.md` w katalogu aktywnego projektu:

```markdown
# Email Intelligence — YYYY-MM-DD

## 🔴 KRYTYCZNE (wymaga ręcznego działania)
[tabela z datą, nadawcą, tematem, wymaganą akcją]

## 💰 FAKTURY
[tabela z datą, nadawcą, kwotą, opisem]

## ℹ️ INFO
[krótka lista]
```

### 4. Wyświetl alert

Po zakończeniu skanu wyświetl **tylko jeśli są KRYTYCZNE**:

```
⚠️ EMAIL INTEL: [N] krytycznych alertów — szczegóły w .ai/email-intel/YYYY-MM-DD.md
```

Jeśli brak krytycznych — milcz (nie przerywaj pracy).

## Integracja z sesją startową

Ten skill jest uruchamiany jako subagent w tle na starcie sesji. W resume-work lub na początku rozmowy:

```
Agent({
  description: "Email Intelligence scan",
  subagent_type: "general-purpose",
  prompt: "Uruchom skill email-intelligence...",
  run_in_background: true
})
```

## Zależności

- Gmail MCP (mcp__claude_ai_Gmail)
- Dostęp do katalogu .ai/email-intel/ w projekcie

## Uwagi

- NIE wyświetlaj treści maili — tylko metadane (temat, nadawca, data)
- NIE czytaj pełnych wiadomości (gmail_read_message) — snippety wystarczą
- Raport generuj PO POLSKU z polskimi diakrytykami
- Jeśli Gmail MCP niedostępny — pomiń cicho, nie blokuj sesji
