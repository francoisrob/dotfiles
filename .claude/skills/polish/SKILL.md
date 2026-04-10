---
name: polish
description: >
  Autonomous full-application polish agent. Discovers the project structure
  dynamically, then loops over every applicable layer — data, API, services,
  components, styles, tests, security, performance, accessibility, types, and
  consistency — finding and making provably-better changes. Each full pass ends
  with a verification gate and a commit. Continues until explicitly stopped.
---

# Autonomous Polish Agent

Loop over this application pass by pass, improving code quality, type safety,
test coverage, security, performance, accessibility, and consistency.
Stop when the human tells you to. Commit at the end of each full pass.

## Improvement Standard

Every change must satisfy at least one criterion. If you cannot state which, skip it.

- **Correctness** — bug, edge case, or type error fixed
- **Completeness** — missing loading/error/empty state or a11y attribute added
- **Consistency** — divergence from established pattern aligned
- **Clarity** — ambiguous name or signature made precise
- **Security** — vulnerability closed without breaking the contract
- **Performance** — redundant call, missing index, or recomputation eliminated
- **Accessibility** — WCAG AA violation fixed

Never make sideways changes that don't satisfy any criterion above.

---

## Tool Rules

- **Serena MCP** for all code navigation — not grep/cat/find
- **context7 MCP** before any library API change — not training data
- **Screenshot** after every UI change (light + dark + responsive if applicable)
- **Bash** only for build/test/lint and read-only shell operations
- Never `git push` — the human pushes
- Never commit on `main` or `master`

---

## Startup Sequence

1. `git branch --show-current` — must not be main/master. If it is, stop.
2. Discover project: config files, language, framework, test runner, linter
3. Establish full verification command (build + test + lint + types)
4. Run baseline verification — fix failures before polishing
5. Record baseline metrics (test count, type errors, lint warnings)

---

## Sweep Layers

Skip layers that don't exist in this project.

### Layer 1: Data & Schema
*If: ORM models, migrations, or schema files exist.*
Check: required/nullable correctness, indexes matching query patterns, enum
exhaustiveness, validation completeness, referential integrity, migration sync.

### Layer 2: API & Backend
*If: HTTP routes, controllers, or RPC handlers exist.*
Check: auth middleware on protected routes, input validation with allowlists,
strict response types, safe error messages (no stack traces), consistent
pagination format, no console.log in committed code, rate limiting on
auth/write/expensive endpoints.

### Layer 3: Core Services & State
*If: shared services, auth, or state management exist.*
Check: session expiry + token refresh edge cases, reconnection respects auth,
no stale data from race conditions, consistent error propagation pattern.

### Layer 4: Shared Components
*If: component library or design system exists.*
Check: all props typed, aria-labels on interactive elements, loading/disabled/error
states, design-system components used instead of raw HTML, meaningful tests
(not just "it renders").

### Layer 5: Feature Components
*If: page-level components or views exist.*
Check: loading skeleton, error state with retry, empty state with CTA, response
types match backend, optimistic mutations where possible, no full-reload-on-mutation.

### Layer 6: Styling & Theming
*If: CSS, design tokens, or theme files exist.*
Check: all colours from tokens (no hardcoded hex), light/dark mode correct,
responsive at 375px, consistent elevation/z-index hierarchy.

### Layer 7: Tests
*Always applies.*
For untested business logic: write tests covering happy path, null/empty input,
boundaries, error paths. Audit existing tests: do they test behaviour (not
implementation)? Tautological test check — would it pass with implementation
deleted? If yes, rewrite.

### Layer 8: Security
*Always applies.*
Priority order: injection (SQL/NoSQL), broken auth, sensitive data exposure,
broken access control (horizontal escalation), XSS, path traversal, CSRF.
Each security fix: own commit, includes regression test, never batched with features.

### Layer 9: Performance
*If: measurable characteristics exist.*
Check: N+1 queries, redundant HTTP calls, missing memoisation, unnecessary
re-renders, bundle size, unindexed queries, large lists without virtualisation,
memory leaks (unsubscribed listeners).

### Layer 10: Accessibility
*If: any UI exists.*
Check: keyboard navigation + tab order, focus trap in modals, colour contrast
(4.5:1 normal, 3:1 large), alt text, form labels, icon-only button aria-labels,
aria-live for dynamic changes, 44x44px touch targets.

### Layer 11: Types & Contracts
*If: typed language.*
Check: no `any` without justification, no `as any` casts, explicit return types,
API types match actual payloads, exhaustive union/enum handling, explicit
null/undefined handling (no implicit truthiness on 0 or "").

### Layer 12: Entropy & Consistency
*Always applies.*
Check: dead code (unused imports, orphaned files), naming convention drift,
stale comments, debug prints, stale TODOs, duplicate logic, misplaced files,
unused dependencies.

---

## Protocols

### Context Management
Compact at **70%** capacity. After compacting, re-read `progress.txt`.
Write important state to `progress.txt` or commit it — conversation memory
does not survive compaction.

### Stuck Detection
Same error 3 times → stop current approach → try ONE alternative → if still
stuck: write to `progress.txt`, note in `blocked.md`, move to next layer.
Never loop on the same failure.

### Gate Protocol
Run full verification after each pass. If a check fails: fix (max 3 attempts),
re-run all checks. If still failing: write to `blocked.md`, move on.
Compare metrics against baseline after clean pass.

### State Management
Maintain `progress.txt` with entries after each layer:
```
[YYYY-MM-DD HH:MM] PASS N — LAYER: <name>
FOUND: <what> | CHANGED: <what and why> | VERIFY: <result>
```

### Commit Protocol
After each clean pass: `polish: <summary>`
One commit per pass. Security fixes get own commit. Never `git push`.

### Continuation
After committing, start next pass at Layer 1. Continue until human stops.
