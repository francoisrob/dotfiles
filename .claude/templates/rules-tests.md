---
paths:
  - "**/*.test.ts"
  - "**/*.test.js"
  - "**/*.spec.ts"
  - "**/*.spec.js"
  - "**/tests/**"
  - "**/__tests__/**"
---
# Testing Conventions

## Structure
- Each test file covers one module
- Group with `describe` blocks
- Names: "should [expected behavior] when [condition]"

## What to Test
- Happy path with realistic inputs
- Error cases (invalid input, missing data, auth failures)
- Module-specific edge cases

## Fixtures
- User fixture: `tests/fixtures/user.ts`
- DB helpers: `tests/helpers/db.ts`
- HTTP client: `tests/helpers/client.ts`

## Isolation
- Each test cleans up its own data (afterEach)
- Never depend on execution order
- Never share mutable state

## What NOT to Test
- Implementation details
- Framework internals
- Third-party library behavior
