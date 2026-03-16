# Global Rules

## Tool Enforcement (NOT OPTIONAL)

- NEVER use grep/cat/find for code exploration
- ALWAYS use Serena MCP: find_symbol, get_symbols_overview, replace_symbol_body
- ALWAYS use context7 MCP for library/API documentation
- If MCP tool fails, state the error before falling back to bash

## Git Safety (ENFORCED)

- NEVER commit directly to main/master
- NEVER merge to main/master
- NEVER use --force without explicit human approval
- ALWAYS work in worktrees or feature branches
- ALWAYS push branch and stop — human merges via PR

## Code Standards

- Types required (no implicit any, no untyped functions)
- Error handling required (no silent catches)
- No console.log in committed code
- No hardcoded secrets or API keys

## Commits

- Format: `<type>: <description>`
- Types: feat, fix, refactor, docs, test, chore
- One logical change per commit
- Run tests + lint + types before committing

## Before Deleting

- NEVER delete files without listing them first and getting confirmation
- NEVER rm -rf anything outside the current project
