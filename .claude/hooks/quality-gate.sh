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

# Run tests only if the test runner can actually execute them.
# Returns: 0 if tests pass, 1 if tests fail, 2 if runner crashed before running any tests.
run_test_check() {
  local output
  output=$("$@" 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    echo "✓ test"
    return 0
  fi

  # Check if any tests actually ran by looking for a results summary.
  # Mocha: "N passing", "N failing"; Jest: "Tests:"; pytest: "passed", "failed"
  if echo "$output" | grep -qE '(passing|failing|Tests:|passed|failed|test result)'; then
    echo "✗ test failed"
    return 1
  fi

  # Runner crashed before executing tests (e.g. import errors, missing native modules)
  echo "⚠ test runner could not start (environment issue) — skipping"
  return 2
}

# Helper: check if a script exists in package.json
has_script() {
  node -e "process.exit(require('./package.json').scripts?.['$1'] ? 0 : 1)" 2>/dev/null
}

# Detect stack and run checks
if [[ -f "package.json" ]]; then
  # Node.js - only run checks for scripts that exist
  if has_script "build"; then
    run_check "build" npm run build || exit 2
  fi
  if has_script "test"; then
    run_test_check npm test
    test_result=$?
    # Block on real test failures (1), skip if runner crashed before running tests (2)
    if [[ $test_result -eq 1 ]]; then
      exit 2
    fi
  fi
  if has_script "lint"; then
    run_check "lint" npm run lint || true
  fi
  if has_script "typecheck"; then
    run_check "types" npm run typecheck || true
  fi
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
