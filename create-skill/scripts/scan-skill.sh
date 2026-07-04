#!/usr/bin/env bash
# Security scan for Claude Code skills
# Usage: scan-skill.sh <path-to-skill-folder>
# Returns: exit 0 (clean) or exit 1 (issues found)

set -euo pipefail

SKILL_DIR="${1:-.}"
ISSUES=0
CRITICAL=0

echo "=== Skill Security Scan ==="
echo "Target: $SKILL_DIR"
echo ""

# 1. Prompt injection patterns
echo "--- Checking prompt injection ---"
if grep -rniE "(ignore previous|you are now|act as a|pretend to be|disregard|forget your)" "$SKILL_DIR" --include="*.md" 2>/dev/null; then
  echo "  WARNING: Potential prompt injection patterns found"
  ((ISSUES++))
fi

# 2. Exfiltration patterns
echo "--- Checking exfiltration ---"
if grep -rniE "(curl|wget|fetch)\s+.*(env|secret|token|credential|password|key)" "$SKILL_DIR" 2>/dev/null; then
  echo "  CRITICAL: Potential data exfiltration pattern"
  ((CRITICAL++))
  ((ISSUES++))
fi

# 3. Dangerous commands
echo "--- Checking dangerous commands ---"
if grep -rniE "rm\s+-rf\s+[/~]|DROP\s+TABLE|DELETE\s+FROM\s+\w+\s*$|chmod\s+777|--no-verify|eval\(|exec\(" "$SKILL_DIR" 2>/dev/null; then
  echo "  HIGH: Dangerous command patterns found"
  ((ISSUES++))
fi

# 4. Supply chain risks
echo "--- Checking supply chain ---"
if grep -rniE "npx\s+[a-z]|pip install\s+https?://|curl.*\|\s*bash|curl.*\|\s*sh" "$SKILL_DIR" --include="*.md" --include="*.sh" 2>/dev/null; then
  echo "  MEDIUM: Supply chain risk patterns found"
  ((ISSUES++))
fi

# 5. Base64 encoded strings (>100 chars)
echo "--- Checking encoded payloads ---"
if grep -rPoE "[A-Za-z0-9+/=]{100,}" "$SKILL_DIR" 2>/dev/null | head -1 | grep -q .; then
  echo "  WARNING: Long base64 encoded string found"
  ((ISSUES++))
fi

echo ""
echo "=== Results ==="
if [ "$CRITICAL" -gt 0 ]; then
  echo "BLOCKED: $CRITICAL critical issue(s). Do NOT install this skill."
  exit 1
elif [ "$ISSUES" -gt 0 ]; then
  echo "WARNINGS: $ISSUES issue(s) found. Review before installing."
  exit 0
else
  echo "CLEAN: No security issues detected."
  exit 0
fi
