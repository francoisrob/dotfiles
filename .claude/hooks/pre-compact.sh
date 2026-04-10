#!/usr/bin/env bash
set -euo pipefail

cd "$CLAUDE_PROJECT_DIR" || exit 0

PROGRESS_FILE=".claude/progress.md"

[[ -d ".claude" ]] || exit 0

{
  echo ""
  echo "## Session $(date +%Y-%m-%d\ %H:%M)"
  echo ""
  echo "### Modified files"
  git diff --name-only HEAD 2>/dev/null || echo "(not a git repo)"
  echo ""
  echo "### Staged files"
  git diff --name-only --cached 2>/dev/null || true
  echo ""
  echo "### Test status"
  if [[ -f "package.json" ]]; then
    npm test 2>&1 | tail -5 || true
  elif [[ -f "pyproject.toml" ]]; then
    pytest --tb=no -q 2>&1 | tail -5 || true
  elif [[ -f "go.mod" ]]; then
    go test ./... 2>&1 | tail -5 || true
  elif [[ -f "Cargo.toml" ]]; then
    cargo test 2>&1 | tail -5 || true
  else
    echo "(no test runner detected)"
  fi
} >> "$PROGRESS_FILE"
