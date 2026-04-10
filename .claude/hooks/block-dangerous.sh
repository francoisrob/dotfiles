#!/usr/bin/env bash
set -euo pipefail

TOOL_INPUT=$(cat)

if command -v jq &>/dev/null; then
  COMMAND=$(printf '%s' "$TOOL_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
else
  COMMAND=$(printf '%s' "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
fi

[[ -z "$COMMAND" ]] && exit 0

block_if_matches() {
  local pattern="$1" reason="$2" fix="$3"
  if printf '%s' "$COMMAND" | grep -qiE "$pattern"; then
    jq -n --arg reason "BLOCKED: $reason. Fix: $fix" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
  fi
}

# Git safety
block_if_matches "(git\s+push\s+.*(-f|--force))" \
  "Force push is destructive" \
  "Use git push without --force"

block_if_matches "(git\s+push\s+.*\b(main|master)\b)" \
  "Direct push to main/master" \
  "Push to a feature branch and create a PR"

block_if_matches "(git\s+merge\s+.*\b(main|master)\b)" \
  "Merge to/from main/master" \
  "Human merges via PR"

block_if_matches "(git\s+checkout\s+(main|master)\s*$)" \
  "Checkout main/master" \
  "Work in feature branches or worktrees"

block_if_matches "(gh\s+pr\s+merge)" \
  "Auto-merging PRs" \
  "Human reviews and merges PRs"

# Destructive operations
block_if_matches "(rm\s+-rf\s+(/|~|\*|/\*))" \
  "Catastrophic rm" \
  "Be specific about what to remove"

block_if_matches "(DROP\s+TABLE|TRUNCATE\s+TABLE)" \
  "Destructive SQL" \
  "Use migrations for schema changes"

# Pipe to shell
block_if_matches "(curl|wget)\s+.*\|\s*(bash|sh)" \
  "Piping remote script to shell" \
  "Download first, review, then execute"

exit 0
