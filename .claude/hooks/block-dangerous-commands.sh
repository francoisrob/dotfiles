#!/usr/bin/env bash
# ~/.claude/hooks/block-dangerous-commands.sh
#
# PreToolUse hook: deterministic safety gate for Bash tool calls.
# Blocks catastrophic operations regardless of agent intent or context rot.
#
# Exit 2 = block the tool call (stderr is fed back to agent as context).
# Exit 0 = allow the tool call.

set -euo pipefail

# Read JSON payload from stdin
TOOL_INPUT=$(cat)

# Extract command field — jq preferred, python3 fallback
if command -v jq &>/dev/null; then
  COMMAND=$(printf '%s' "$TOOL_INPUT" | jq -r '.command // ""' 2>/dev/null || echo "")
else
  COMMAND=$(printf '%s' "$TOOL_INPUT" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('command',''))" \
    2>/dev/null || echo "")
fi

# Nothing to inspect
[[ -z "$COMMAND" ]] && exit 0

block_if_matches() {
  local pattern="$1" reason="$2" fix="$3"
  if printf '%s' "$COMMAND" | grep -qiE "$pattern"; then
    printf 'BLOCKED [safety-hook]: %s\n' "$reason" >&2
    printf 'Command: %s\n' "$COMMAND" >&2
    printf 'Fix: %s\n' "$fix" >&2
    exit 2
  fi
}

# Push to main/master (catches: -u, --set-upstream, extra flags, whitespace variants)
block_if_matches \
  'git\s+push\b.*\s(main|master)(\s|$)' \
  "Refusing push to main/master." \
  "Use: git push origin <feature-branch>"

# Merge to main/master
block_if_matches \
  'git\s+merge\b.*\s(main|master)(\s|$)' \
  "Refusing merge into main/master." \
  "Open a PR: gh pr create --base main"

# Checkout main/master directly (switching off a feature branch)
block_if_matches \
  'git\s+checkout\s+(main|master)\s*$' \
  "Refusing checkout of main/master." \
  "Stay on your feature branch."

# gh pr merge (bypasses human review)
block_if_matches \
  'gh\s+pr\s+merge\b' \
  "Refusing auto-merge. Human review required." \
  "Wait for a human to merge the PR."

# Force push
block_if_matches \
  'git\s+push\b.*(--force|-f)\b' \
  "Refusing force push." \
  "Push without --force to your feature branch."

# rm -rf on root or home
block_if_matches \
  'rm\s+-[a-zA-Z]*rf[a-zA-Z]*\s+(/\s*$|~\s*$|/\*|~/)' \
  "Refusing recursive deletion of root or home." \
  "Use explicit file paths only."

# Database destruction
block_if_matches \
  '(DROP\s+TABLE|TRUNCATE\s+TABLE)\b' \
  "Refusing database table destruction." \
  "Use migration rollbacks."

# Pipe remote content to shell
block_if_matches \
  '(curl|wget)\s+.+\|\s*(bash|sh|zsh|fish)\b' \
  "Refusing to pipe remote content into a shell." \
  "Download, inspect, then run explicitly."

exit 0
