---
name: gates
description: >
  ALWAYS run this skill before marking any task complete and before
  making any git commit. This is the mandatory quality gate. It runs
  build, test, lint, and type checks in order and must fully pass
  before work is considered done. Never skip this.
model: haiku
allowed-tools:
  - Bash(bun *)
  - Bash(npm *)
  - Bash(npx *)
  - Bash(pytest *)
  - Bash(ruff *)
  - Bash(mypy *)
  - Bash(go *)
  - Bash(cargo *)
  - Bash(golangci-lint *)
  - Read
  - Grep
---

# Quality Gates

Run in order, stop on first failure:

1. **Build** - Must compile/bundle without errors
2. **Test** - All tests must pass
3. **Lint** - No lint errors
4. **Types** - No type errors (if applicable)

Auto-detect stack and run appropriate commands:
- Node: `bun run build && bun test && bun run lint`
- Python: `pytest && ruff check .`
- Go: `go build ./... && go test ./...`
- Rust: `cargo build && cargo test && cargo clippy`

Report: PASS (all green) or BLOCKED (what failed)
