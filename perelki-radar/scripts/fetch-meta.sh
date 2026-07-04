#!/usr/bin/env bash
# perelki-radar — pobiera metadane repo GitHub + (opcjonalnie) skanuje konta właścicieli (§35.2).
# Użycie:
#   fetch-meta.sh repos owner/repo [owner/repo ...]      → metadane repo (JSON-lines)
#   fetch-meta.sh accounts owner [owner ...]             → skan kont (type, public_repos, top 8 repo)
#   fetch-meta.sh readme owner/repo                      → pierwsze 70 linii README
# Wymaga: gh (uwierzytelniony), base64, jq w gh.
set -uo pipefail

mode="${1:-}"; shift || true

case "$mode" in
  repos)
    for r in "$@"; do
      echo "=== $r ==="
      gh api "repos/$r" --jq '{owner: .owner.login, name: .name, stars: .stargazers_count, forks: .forks_count, lang: (.language // "n/a"), license: (.license.spdx_id // "none"), pushed: .pushed_at[0:10], created: .created_at[0:10], archived: .archived, openIssues: .open_issues_count, homepage: (.homepage // ""), topics: (.topics // []), desc: .description}' 2>/dev/null || echo "FETCH_FAIL $r"
    done
    ;;
  accounts)
    for o in "$@"; do
      echo "=== $o ==="
      gh api "users/$o" --jq '"\(.type) | public_repos=\(.public_repos)"' 2>/dev/null || { echo "FETCH_FAIL $o"; continue; }
      gh api "users/$o/repos?sort=stargazers&per_page=8" --jq 'sort_by(-.stargazers_count) | .[] | "  \(.stargazers_count)⭐ \(.name) — \((.description // "—")[0:65]) [\(.language // "n/a")] \(.pushed_at[0:7])"' 2>/dev/null | head -8
      echo ""
    done
    ;;
  readme)
    gh api "repos/$1/readme" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | head -70
    ;;
  *)
    echo "Użycie: fetch-meta.sh {repos|accounts|readme} <args>" >&2
    exit 1
    ;;
esac
