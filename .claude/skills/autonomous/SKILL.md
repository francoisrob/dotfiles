---
name: autonomous
description: >
  Use this skill at the start of every autonomous coding session and when
  given a task list to work through. This skill defines the mandatory loop
  structure: startup verification, task assessment, subagent strategy,
  implementation loop, and session handoff. Required whenever working
  autonomously on multiple tasks.
---

# Autonomous Loop

## Startup Sequence

1. Confirm worktree: `pwd` must show worktree path, NOT main repo
2. If in main repo: STOP and ask human for worktree path
3. Confirm branch: `git branch --show-current` must NOT be main/master
4. If on main/master: `git checkout -b auto/session-$(date +%s)`

## Task Assessment (BEFORE each task)

Ask yourself:

1. Do I need to research an API/library? → Use context7 first
2. Can this task be split into 2+ independent pieces? → Spawn subagents via Task tool
3. Is this visual work? → Must screenshot with Chrome DevTools after

## Subagent Strategy

Spawn subagents when:

- Tests and implementation can run parallel
- Multiple independent files/components
- Research while implementing

Each subagent gets own worktree:

```
Task: "Create worktree .claude/worktrees/sub-<name>, implement <specific task>, push branch, report back"
```

## Main Loop

1. Read `.claude/tasks.md`, pick first `- [ ]`
2. **Research** via context7 if unfamiliar territory
3. **Navigate** via Serena (find_symbol, get_symbols_overview)
4. **Implement** the change
5. **Verify**: if visual → screenshot via Chrome DevTools
6. **Run gates**: build → test → lint → types
7. Pass → commit, mark `[x]`, continue
8. Fail → fix, retry (max 3 attempts)
9. All tasks done → generate more tasks, continue
10. Stuck after 3 retries → `<promise>BLOCKED</promise>`

## State Files

- `tasks.md` — work queue (update after each task)
- `progress.md` — learnings, handoff notes (update before compaction)
- `blocked.md` — current blocker details (write when stuck)

## End of Session

1. Push current branch: `git push -u origin HEAD`
2. Write summary to progress.md
3. Output: `<promise>SESSION_END</promise>`
4. Do NOT merge. Human reviews and merges.

## Anti-Patterns (NEVER DO)

- grep/cat when Serena available
- Guessing APIs when context7 can confirm
- Blind commits on visual changes
- Serial work when parallel is possible
- Working on main/master branch
- Merging to main/master
