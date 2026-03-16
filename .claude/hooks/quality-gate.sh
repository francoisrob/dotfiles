#!/bin/bash
# Quality gate hook - exit 2 blocks task completion

cd "$CLAUDE_PROJECT_DIR" || exit 0

run_check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "✓ $name"
    return 0
  else
    echo "✗ $name failed"
    return 1
  fi
}

# Detect stack and run checks
if [[ -f "package.json" ]]; then
  # Node.js
  run_check "build" bun run build || npm run build || exit 2
  run_check "test" bun test || npm test || exit 2
  run_check "lint" bun run lint || npm run lint || true
  run_check "types" bun run typecheck || npm run typecheck || true
elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
  # Python
  run_check "test" pytest || exit 2
  run_check "lint" ruff check . || true
  run_check "types" mypy . || true
elif [[ -f "go.mod" ]]; then
  # Go
  run_check "build" go build ./... || exit 2
  run_check "test" go test ./... || exit 2
  run_check "lint" golangci-lint run || true
elif [[ -f "Cargo.toml" ]]; then
  # Rust
  run_check "build" cargo build || exit 2
  run_check "test" cargo test || exit 2
  run_check "lint" cargo clippy -- -D warnings || true
fi

exit 0
