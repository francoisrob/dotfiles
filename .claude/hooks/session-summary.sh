#!/bin/bash
# Log session summary (runs async)

cd "$CLAUDE_PROJECT_DIR" || exit 0

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

{
  echo "=== Session End: $(date) ==="
  echo "Project: $CLAUDE_PROJECT_DIR"
  echo "Git status:"
  git status --short 2>/dev/null || echo "(not a git repo)"
  echo ""
} >> "$LOG_DIR/sessions.log"

exit 0
