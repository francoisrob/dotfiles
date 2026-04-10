---
name: autonomous
description: >
  Use this skill at the start of every autonomous coding session and when
  given a task list to work through. Defines the mandatory loop structure:
  startup, task assessment, subagent strategy, implementation loop, and
  session handoff. Required whenever working autonomously on multiple tasks.
---

# Autonomous Loop

## Startup

1. `git branch --show-current` — must NOT be main/master
2. If on main/master: `git checkout -b auto/session-$(date +%s)`
3. Read `progress.txt` if it exists — resume where last session left off
4. `git log --oneline -5` and `git status` to orient

## Task Assessment (before each task)

1. Unfamiliar API/library? → context7 first
2. Can this split into 2+ independent pieces? → Spawn subagents via Agent tool
3. Visual work? → Screenshot after with Chrome DevTools MCP

## Subagent Strategy

Spawn subagents when:
- Tests and implementation can run in parallel
- Multiple independent files/components
- Research needed while implementing

## Main Loop

1. Pick next pending task
2. **Research** via context7 if unfamiliar territory
3. **Navigate** via Serena MCP (find_symbol, get_symbols_overview)
4. **Implement** the change
5. **Verify**: if visual → screenshot; run gates (build → test → lint → types)
6. Pass → commit, mark complete, continue
7. Fail → fix, retry (max 3 attempts)
8. Stuck after 3 retries → write to `progress.txt`, report BLOCKED

## State Files

- `progress.txt` — session state, learnings, handoff notes (auto-saved by PreCompact hook)
- `blocked.md` — current blocker details with reproduction steps

## End of Session

1. Push current branch: `git push -u origin HEAD`
2. Write summary to `progress.txt`
3. Report: SESSION_END
4. Do NOT merge — human reviews and merges via PR
