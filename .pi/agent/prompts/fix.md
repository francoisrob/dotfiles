---
description: Apply the minimal fix from the preceding /diagnose, prove it with the repro, stage only changed files.
argument-hint: "[extra constraints]"
---
Apply the minimal diff from your diagnosis. $ARGUMENTS

Follow the "Bug investigation" rules from your global instructions. On top of them:

- Keep the reproduction as a regression test in the existing suite, next to similar tests.
- Do not commit. Stage only the files you changed, never `git add -A`.
