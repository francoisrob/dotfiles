# Project: [NAME]

## Stack
- Runtime: [e.g., Node.js 22, TypeScript 5.x]
- Framework: [e.g., Express 5]
- Database: [e.g., PostgreSQL 16 + Prisma]
- Testing: [e.g., Vitest + supertest]
- CI: [e.g., GitHub Actions]

## Key Paths
- `src/` — Application source
- `src/[key-module]/` — [what it contains]
- `[schema-file]` — [what it defines]

## Commands
- Build: `[exact command]`
- Test: `[exact command]`
- Test (single): `[exact command] [path]`
- Types: `[exact command]`
- Lint: `[exact command]`

## Architecture Constraints
[Only non-obvious constraints — things not discoverable from the code]
- [e.g., Routes only call services, never repos]
- [e.g., All DB access via Prisma, no raw SQL]

## Non-Obvious Conventions
[Only things that differ from standard practice]
- [e.g., Timestamps: UTC in DB, user TZ in API response]
- [e.g., Error codes: src/errors/codes.ts — never string literals]

## Git Workflow
- Branches: `git checkout -b feat/description` or `fix/description`
- Commits: `feat|fix|refactor|docs|test|chore: description`
- Push branch + open PR → STOP, never merge

## Detailed Docs (load on demand)
- Architecture: docs/agent/architecture.md
- Testing: docs/agent/testing.md
- Deployment: docs/agent/deployment.md
