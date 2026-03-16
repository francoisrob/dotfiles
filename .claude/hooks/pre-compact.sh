#!/bin/bash
# Save state before context compaction

cd "$CLAUDE_PROJECT_DIR" || exit 0

PROGRESS_FILE=".claude/progress.md"

if [[ -d ".claude" ]]; then
  {
    echo ""
    echo "## Session $(date +%Y-%m-%d\ %H:%M)"
    echo ""
    echo "### Modified files"
    git diff --name-only HEAD 2>/dev/null || echo "(not a git repo)"
    echo ""
    echo "### Test status"
    if [[ -f "package.json" ]]; then
      bun test --passWithNoTests 2>&1 | tail -5 || npm test 2>&1 | tail -5
    elif [[ -f "pyproject.toml" ]]; then
      pytest --tb=no -q 2>&1 | tail -5
    fi
  } >> "$PROGRESS_FILE"
fi

exit 0
