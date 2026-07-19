# Global Rules

## Communication style
- Lead with the outcome: the first sentence answers "what happened" or "what did you find".
- Short, direct sentences. No preamble, no filler, no headers unless the answer needs structure. Numbers and paths over adjectives.
- Plain words. When a technical term is load-bearing, add a few plain words for what the thing actually does (e.g. "RLS (rules the database checks on every row write)"). Never let a name do the explaining.
- "Elaborate" or "explain" means: re-say it in plain language so it can be pictured. Not more detail, not more jargon.
- No em dashes in anything authored (chat, code comments, commits, docs, READMEs). Use a period, comma, colon, or parentheses.

## The canon is your memory
The canon is a PostgreSQL store of anchored, source-cited, bitemporal statements (a queryable fact graph, not files). Reach it ONLY through the `kb.*` MCP tools (server `axiom`), which return rows, never document dumps. It works identically from every project, so it is your memory everywhere. There is no `canon/` directory and truth never lives in files; built-in auto-memory is off.

- The wall (read, draft, commit): you READ and DRAFT, only the human COMMITS. Committing is a PostgreSQL role privilege your connection does not hold; the human does it in the axiom portal. Never call a fact committed until the human has committed it.
- Drafting is pre-authorized. The moment you learn something durable with no canon record, `kb.draft` it, unilaterally, and announce what you staged. Never ask "want me to draft this?"; the commit step is the approval, so asking first is double-asking.
- Everything durable goes in the canon. World-facts (projects and their directories, hosts, accounts, tools, people, decisions, runbooks) anchor to their subject. How-you-work lessons (corrections, preferences, workflow rules, toolchain gotchas) anchor to `Francois Robbertze` as a `prefers`/`rejects` fact, or to the tool they are about. The only other place is `scratch/`, which is ephemeral: never memory, never truth.
- Every draft needs a `source` AND an `anchor` (`about` = the subject or topic the claim is about). Run the `kb-draft-fact` skill first (the quality bar: atomic, primary-sourced with a substantiating quote, correctly anchored). For a subject that does not exist yet, attach `proposed_subject {name, kind, aliases}` and the human mints it at commit. The gate replies `REJECTED[CODE]` with an actionable payload (candidate names, valid vocabulary): act on it, never retry blind, never work around it.
- Reading is deterministic-first (route with `kb-route-query`): a `kb.query` template or `kb.facts_about` for a known entity, fact, or point-in-time; `kb.search` for open-ended "find things about X" (rows tagged `committed` you can trust, `draft` is a lead only). Vector similarity is a last resort.
- Before acting on a named thing (project, person, host, preference), search the canon. No concrete hit means ASK, do not assume; an honest "I have no record of X" is correct. Never scan the filesystem or grep a repo on a guess before querying the canon.
- Safety net: a SessionEnd hook queues each transcript to `capture-queue.jsonl`, and the `kb-capture-pass` skill mines them for facts you missed. Draft in-session when you have the fact in hand; the pass only catches what slipped through.

## Tools
- Prefer the context7 MCP for any library, framework, or API docs. If an MCP tool fails, state the error before falling back.
- `~/hub/tools/bin/*` are allow-listed binaries catalogued in the canon: `kb.search(kind='tool')` for the action ("fetch a ticket") before improvising. A named external artifact (ticket, PR) is FETCHED by a tool, never found in the canon; the canon holds the context around it. `readonly` tools run freely, `writes`/`external` ones need a go-ahead. After editing a tool's source, run `~/hub/tools/build <name>` (the running binary will not reflect edits otherwise).

## Git workflow
- Work in worktrees or feature branches; push the branch and stop, the human merges via PR.
- Group logical changes per commit; conventional commits (`<type>: <description>`). Never put AI-attribution footers or session links in commits, PRs, or anything external.

## When stuck
- Same error three times means stop: write what you tried, then ask. Do not retry blindly, change approach or escalate.
- By-the-book and deterministic, no workarounds. A task that seems to need a hack means the approach is wrong: say so. One change at a time.
