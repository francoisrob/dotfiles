---
name: gates
description: >
  ALWAYS run this skill before marking any task complete and before
  making any git commit. This is the mandatory quality gate. It runs
  build, test, lint, and type checks in order and must fully pass
  before work is considered done. Never skip this.
model: haiku
allowed-tools:
  - Bash(npm *)
  - Bash(bun *)
  - Bash(bunx *)
  - Bash(npx *)
  - Bash(pytest *)
  - Bash(ruff *)
  - Bash(mypy *)
  - Bash(go *)
  - Bash(cargo *)
  - Bash(golangci-lint *)
  - Bash(make *)
  - Read
  - Grep
---

# Quality Gates

Run in order, stop on first failure:

1. **Build** — must compile/bundle without errors
2. **Test** — full suite, not just the file you changed
3. **Lint** — no lint errors
4. **Types** — no type errors (if applicable)

Auto-detect stack from project files:

- **Node (package.json):** prefer `bun run` if bun.lockb exists, else `npm run`. Run: build > test > lint
- **Python (pyproject.toml):** `pytest && ruff check .`
- **Go (go.mod):** `go build ./... && go test ./... && golangci-lint run`
- **Rust (Cargo.toml):** `cargo build && cargo test && cargo clippy`
- **Make (Makefile):** `make check` or `make test`

If multiple stacks detected, run all applicable.

## Tautological Test Detection

Before committing new or modified tests, check:
- Would the test pass with the implementation deleted or returning a constant?
- Does a mock return exactly what the assertion expects (circular)?
- Any `expect(true).toBe(true)` or equivalent no-op assertions?

If yes: the test proves nothing. Rewrite it.

## Failure Protocol

- Fix the issue, then re-run ALL checks from step 1
- Max 3 fix attempts per check. If still failing: stop, write what you tried, move on
- NEVER commit with known failing checks

Report: `PASS` (all green) or `BLOCKED: [what failed]`
