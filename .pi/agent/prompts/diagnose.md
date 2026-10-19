---
description: Find the root cause of a bug. Reproduce first, propose a fix, change nothing until told.
argument-hint: "<symptom, error text, or issue ref> [paths]"
---
Diagnose: $ARGUMENTS

Follow the "Bug investigation" rules from your global instructions, in this order:

1. Reproduce.
2. Read the history.
3. Trace to the origin.

End with the root cause (file:line, one paragraph), the reproduction, the minimal diff you would make, and anything unrelated you noticed. Change no code outside tests. Wait for /fix.
