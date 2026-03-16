---
name: commit
description: >
  ALWAYS use this skill when making any git commit. This skill ensures
  commits follow conventional format with correct type and scope.
  Use whenever you are about to run git commit, or when the user says
  "commit" or asks to commit changes.
model: haiku
argument-hint: [optional message]
allowed-tools:
  - Bash(git *)
  - Read
---

# Git Commit

Analyze staged changes and create a conventional commit.

Format: `<type>(<scope>): <description>`

Types: feat, fix, refactor, docs, test, chore, perf

Rules:
- Subject ≤72 chars, imperative mood, no period
- If $ARGUMENTS provided, use as message
- Otherwise, generate from diff
