---
name: deep-audit
description: >
  Full team audit of one project: map the architecture, find flaws through 13 lenses,
  prove every finding with independent refuters, plan fixes, and implement only what the
  owner approves. Use when asked to deep-audit, fully review or map a whole project.
argument-hint: "what to audit, in plain words, e.g. basis, mostly security, skip the admin app, stop at 3M tokens"
---

# Deep audit

You are the lead. `prompt.md` in this folder is your full brief: read all of it before you act, then follow it exactly.

The person names the project, not a path. Sessions start in ~/hub, so the working directory says nothing about the target. Fill the PARAMETERS block from the canon, routed with the kb-route-query skill:
- PROJECT: resolve the name with `kb.search` (subjects match by name or alias), then read the subject with `kb.facts_about`. Use its canonical name, lowercased, for the folder.
- TARGET_PATH: the committed fact that says where the project is checked out. Confirm the directory exists and is a git repo before using it.
- RELATED_PATHS: the canon's facts about the repos it depends on or feeds (for example the shared library and its other consumers), each confirmed on disk the same way.
- DEPLOYED_WHERE: the canon's facts about its hosts, servers, databases and cloud accounts. Never guess these.
- FOCUS, BUDGET, OUT_OF_SCOPE: read them from what the person wrote, in their own words ("mostly security" is lenses F and K first, "skip the admin app" puts that package out of scope, "stop at 3M tokens" is the budget). The budget is always a token count: you can measure tokens, but you cannot see the person's plan allowance or what a token costs them, so a money figure is not a budget; say so and ask for tokens. When they say nothing, the defaults are all lenses, no token ceiling and nothing out of scope. Write your reading of each into STATE.md, so a misreading is easy to spot.
- OUT: `/home/francois/hub/scratch/<PROJECT>-audit`.

Committed facts are truth; drafts are leads to confirm against the disk. If the name matches more than one subject, or there is no committed fact for where it is checked out, stop and ask, naming what you found. Never scan the filesystem for a likely folder. A path given instead of a name is used as TARGET_PATH directly, and the canon still supplies the rest. Write into STATE.md which canon statement each parameter came from.

The lead must be Opus 5.5. If the session model is something else, say so and stop.

Phases 1 to 3 run through the saved workflows `deep-audit-map`, `deep-audit-find` and `deep-audit-prove` (in `~/.claude/workflows/`). `prompt.md` says when and with which args. Every workflow agent reads `$OUT/brief.md` and `$OUT/standards.md` first (written in Phase 0), and each lens reviewer reads `$OUT/lenses/<letter>.md` (written at the start of Phase 2), so those files must exist before the matching workflow runs.
