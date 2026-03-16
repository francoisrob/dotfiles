#!/usr/bin/env bash
# ~/.claude/hooks/notify.sh
# Fires on Claude Notification events. Async, non-blocking.

set -euo pipefail

TOOL_INPUT=$(cat)

if command -v jq &>/dev/null; then
  MESSAGE=$(printf '%s' "$TOOL_INPUT" \
    | jq -r '.message // .title // "Claude notification"' 2>/dev/null \
    || echo "Claude notification")
else
  MESSAGE="Claude notification"
fi

MESSAGE="${MESSAGE:0:120}"

# Desktop notification (NixOS/Linux with libnotify)
if command -v notify-send &>/dev/null; then
  notify-send --urgency=normal --expire-time=8000 "Claude Code" "$MESSAGE" 2>/dev/null || true
fi

# Log regardless
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
printf '[%s] NOTIFY: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$MESSAGE" \
  >> "$LOG_DIR/notifications.log"

exit 0
