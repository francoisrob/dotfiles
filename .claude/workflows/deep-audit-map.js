export const meta = {
  name: 'deep-audit-map',
  description: 'Deep audit phase 1: map each coverage unit, enforce file coverage in code, stitch the architecture, check sampled call-chain hops',
  whenToUse: 'Called by the deep-audit skill with units from COVERAGE.md. Pass one unit and stitch:false for the pilot.',
  phases: [
    { title: 'Map', detail: 'one Sonnet mapper per unit' },
    { title: 'Coverage', detail: 'units whose owned files were not all read are re-run once' },
    { title: 'Stitch', detail: 'Opus stitches per package, then across packages' },
    { title: 'Hop check', detail: 'a fresh Opus agent checks the sampled call-chain hops' },
  ],
}

const { out, target, units, stitch = true, hops = [], concurrency = 6 } = args
if (!out || !target || !Array.isArray(units) || !units.length) {
  throw new Error('deep-audit-map needs args.out, args.target and a non-empty args.units array')
}

const SONNET = 'claude-sonnet-5-5'
const OPUS = 'claude-opus-5-5'
const BRIEF = `Read ${out}/brief.md first and obey every rule in it. You are read-only: never edit the repo, never run a server, never install anything.`
const SONNET_RULE = 'Do not launch subagents. Run a real check before reporting done. A check that failed to start does not count.'

async function pool(items, limit, fn) {
  const results = new Array(items.length)
  let next = 0
  const worker = async () => {
    while (next < items.length) {
      const index = next++
      results[index] = await fn(items[index], index).catch(() => null)
    }
  }
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker))
  return results
}

const MAP_SCHEMA = {
  type: 'object',
  properties: {
    files_owned_read: { type: 'array', items: { type: 'string' } },
    files_consulted: { type: 'array', items: { type: 'string' } },
    files_skipped: { type: 'array', items: { type: 'object', properties: { file: { type: 'string' }, reason: { type: 'string' } }, required: ['file', 'reason'] } },
    summary: { type: 'string', description: '10 lines or less' },
  },
  required: ['files_owned_read', 'files_consulted', 'files_skipped', 'summary'],
}

function mapPrompt(unit, onlyFiles) {
  const files = onlyFiles || unit.files
  const resume = onlyFiles
    ? `This is a second pass: an earlier pass missed these files. Read them and ADD what you learn to the existing ${out}/1x-${unit.id}-map.md without removing anything.`
    : `Write ${out}/1x-${unit.id}-map.md.`
  return `${BRIEF}
${SONNET_RULE}

You map one unit of the repo at ${target} (package: ${unit.package}). No flaws are reported in this phase: describe, never judge.
Read EVERY one of these files in full (paths relative to the repo root):
${files.map(file => `- ${file}`).join('\n')}

${resume} It must cover:
- the entry points and the call chain from each one down to storage and back, with file:line for every hop;
- each export: who calls it and what it calls; zero-caller items listed separately;
- data: collections and tables, fields, indexes, who reads and writes each field;
- loops, caches, retries, queues, schedulers, bots, mailers and render loops, with cost in plain words at a realistic input size;
- shared-library imports, by subpath and symbol;
- design decisions, with the reason quoted from code, docs or commits, or "rationale not recorded";
- every env var: who reads it, its default, and whether anything reads it at all.
Mark anything that looks deliberate but odd as INTENTIONAL? with the evidence.
Use the tool outputs already in ${out} (graph.json, calls.json, routes.json, knip and jscpd output) where they exist.

Return files_owned_read (exact repo-relative paths from the list above that you read in full), files_consulted (other files you opened to follow a call one hop), files_skipped with reasons, and a summary of 10 lines or less.`
}

phase('Map')
const firstPass = await pool(units, concurrency, unit =>
  agent(mapPrompt(unit), { label: `map:${unit.id}`, phase: 'Map', model: SONNET, effort: 'medium', schema: MAP_SCHEMA }))

phase('Coverage')
const missingOf = (unit, result) => {
  const read = new Set(result ? result.files_owned_read : [])
  return unit.files.filter(file => !read.has(file))
}
const coverage = await pool(units, concurrency, async (unit, index) => {
  const first = firstPass[index]
  const missing = missingOf(unit, first)
  if (!missing.length) return { id: unit.id, files: unit.files.length, missing: [], rerun: false, summary: first.summary }
  const second = await agent(mapPrompt(unit, missing), { label: `remap:${unit.id}`, phase: 'Coverage', model: SONNET, effort: 'medium', schema: MAP_SCHEMA })
  const stillMissing = missing.filter(file => !(second ? second.files_owned_read : []).includes(file))
  return { id: unit.id, files: unit.files.length, missing: stillMissing, rerun: true, summary: second ? second.summary : first ? first.summary : 'mapper failed' }
})
const gaps = coverage.filter(unit => unit && unit.missing.length)
log(`coverage: ${units.length - gaps.length} of ${units.length} units fully read; ${coverage.filter(unit => unit && unit.rerun).length} re-run`)

let stitched = null
if (stitch) {
  phase('Stitch')
  const packages = [...new Set(units.map(unit => unit.package))]
  const single = packages.length === 1
  const STITCH_RULES = `The architecture page is plain English for a non-specialist: how the system fits together on one page, a C4 context and container view in Mermaid (boxes for the system, its users and outside services, then the apps and databases inside it; every edge cites a file), the main user flows end to end, hidden couplings, and the questions the maps could not answer. Return a summary of 10 lines or less.`
  const perPackage = await pool(packages, concurrency, pkg => agent(
`${BRIEF}

Stitch the unit maps of package "${pkg}" into one architecture page. Read these map files in full:
${units.filter(unit => unit.package === pkg).map(unit => `- ${out}/1x-${unit.id}-map.md`).join('\n')}
Write ${single ? `${out}/10-architecture.md` : `${out}/10-${pkg}-architecture.md`}. Join call chains that cross unit boundaries. ${STITCH_RULES}`,
    { label: `stitch:${pkg}`, phase: 'Stitch', model: OPUS, effort: 'high' }))
  stitched = perPackage
  if (!single) {
    const across = await agent(
`${BRIEF}

Stitch the package architecture pages into one page for the whole system. Read in full:
${packages.map(pkg => `- ${out}/10-${pkg}-architecture.md`).join('\n')}
Write ${out}/10-architecture.md. Focus on how the packages talk to each other and to outside services. ${STITCH_RULES}`,
      { label: 'stitch:system', phase: 'Stitch', model: OPUS, effort: 'high' })
    stitched = [...perPackage, across]
  }
}

let hopResults = []
if (hops.length) {
  phase('Hop check')
  const HOP_SCHEMA = {
    type: 'object',
    properties: { hops: { type: 'array', items: { type: 'object', properties: { id: { type: 'string' }, correct: { type: 'boolean' }, evidence: { type: 'string' } }, required: ['id', 'correct', 'evidence'] } } },
    required: ['hops'],
  }
  const checked = await agent(
`${BRIEF}

You wrote none of the maps. Check each call-chain hop below against the code in ${target}. A hop is correct only if the cited file:line exists and makes that call. Give the evidence (the line you read) for every verdict.
${hops.map(hop => `- ${hop.id}: ${hop.claim}`).join('\n')}`,
    { label: 'hop-check', phase: 'Hop check', model: OPUS, effort: 'high', schema: HOP_SCHEMA })
  hopResults = checked ? checked.hops : []
  log(`hop check: ${hopResults.filter(hop => !hop.correct).length} of ${hops.length} hops wrong`)
}

return { coverage, gaps, stitched, hops: hopResults }
