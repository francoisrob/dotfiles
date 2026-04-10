#!/usr/bin/env bash
set -euo pipefail

TOOL_INPUT=$(cat)

if command -v jq &>/dev/null; then
  COMMAND=$(printf '%s' "$TOOL_INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null || echo "")
else
  COMMAND=$(printf '%s' "$TOOL_INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
fi

[[ -z "$COMMAND" ]] && exit 0

redirect_to_mcp() {
  local pattern="$1" tool="$2" reason="$3"
  if printf '%s' "$COMMAND" | grep -qiE "$pattern"; then
    jq -n --arg reason "Use $tool instead. $reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
  fi
}

redirect_to_mcp "^(cat|head|tail)\s+" \
  "Read tool or Serena MCP (find_symbol, get_symbols_overview)" \
  "Bash file reading is denied globally."

redirect_to_mcp "^(grep|rg)\s+" \
  "Grep tool or Serena MCP (search_for_pattern, find_symbol)" \
  "Bash search is denied globally."

redirect_to_mcp "^find\s+" \
  "Glob tool or Serena MCP (find_file, list_dir)" \
  "Bash find is denied globally."

redirect_to_mcp "^(sed|awk)\s+" \
  "Edit tool or Serena MCP (replace_symbol_body)" \
  "Bash stream editors are denied globally."

exit 0
