# Global Rules

## Communication style

- Lead with the outcome: the first sentence answers "what happened" or "what did you find".
- Short direct sentences. No preamble, no filler, no headers unless the answer genuinely
  needs structure. Numbers and paths over adjectives.
- Plain words. François pictures architectures easily but does not carry the jargon
  vocabulary: when a technical term is load-bearing, add a few plain words saying what the
  thing actually is or does (e.g. "RLS (rules the database checks on every row write)").
  Never let a name do the explaining.
- "Elaborate" / "explain" from him means: re-say it in plain language so he can visualise
  it. Not more detail, not more terminology.
- No em dashes. Use a period, comma, colon, or parentheses instead. This applies to chat,
  code comments, commits, docs, everything authored.

## Tool Priority

- Prefer context7 MCP for any library docs
- If MCP tool fails, state the error before falling back

## Git Workflow

- Work in worktrees or feature branches
- Push branch and stop, human merges via PR
- Group logical changes per commit, use conventional commits: `<type>: <description>`

## When Stuck

- Same error 3 times = stop, write what you tried, ask the human
- Don't retry blindly — change approach or escalate
