#!/usr/bin/env bash
set -euo pipefail

TOOL_INPUT=$(cat)

if command -v jq &>/dev/null; then
  COMMAND=$(printf '%s' "$TOOL_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
  HOOK_CWD=$(printf '%s' "$TOOL_INPUT" | jq -r '.cwd // ""' 2>/dev/null || echo "")
else
  COMMAND=$(printf '%s' "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
  HOOK_CWD=$(printf '%s' "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))" 2>/dev/null || echo "")
fi

[[ -z "$COMMAND" ]] && exit 0

# A repo opts into trunk-based development (agent pushes main directly) with:
#   git config claude.trunkBased true
# Scoped per repo: everywhere else the branch-and-PR discipline still holds.
# Only the push-to-main block honours it; force push and the destructive
# blocks below apply regardless.
# The repo the command targets decides. A `cd /path && ...` or `git -C /path`
# names the target explicitly and WINS over the session cwd, so sitting in a
# trunk-based repo grants nothing to commands aimed at another repo.
TRUNK_BASED=false
TARGET_DIR=$(printf '%s' "$COMMAND" | grep -oE '(cd|git -C) [^ ;&|]+' | head -1 | awk '{print $NF}' || echo "")
if [[ -n "$TARGET_DIR" && -d "$TARGET_DIR" ]]; then
  TRUNK_BASED=$(git -C "$TARGET_DIR" config --bool claude.trunkBased 2>/dev/null || echo false)
elif [[ -n "$HOOK_CWD" ]]; then
  TRUNK_BASED=$(git -C "$HOOK_CWD" config --bool claude.trunkBased 2>/dev/null || echo false)
fi

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

# Git safety. `git -C <path>` is part of the match so it cannot slip past.
block_if_matches "(git\s+(-C\s+\S+\s+)?push\s+(.*\s)?(-f|--force|--force-with-lease)(\s|$))" \
  "Force push is destructive" \
  "Use git push without --force"

if [[ "$TRUNK_BASED" != "true" ]]; then
  block_if_matches "(git\s+(-C\s+\S+\s+)?push\s+.*\b(main|master)\b)" \
    "Direct push to main/master" \
    "Push to a feature branch and create a PR, or opt the repo into trunk-based work: git config claude.trunkBased true"
fi

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
