# Global Rules

## Tool Priority

- Serena MCP for code exploration — not grep/cat/find
- context7 MCP for library docs — not training data
- If MCP tool fails, state the error before falling back

## Git Workflow

- Work in worktrees or feature branches — never main/master
- Push branch and stop — human merges via PR
- One logical change per commit: `<type>: <description>`

## When Stuck

- Same error 3 times = stop, write what you tried, ask the human
- Don't retry blindly — change approach or escalate
