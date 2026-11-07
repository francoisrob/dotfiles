export const meta = {
  name: 'deep-audit-find',
  description: 'Deep audit phase 2: one reviewer per lens and package, then duplicate findings merged',
  whenToUse: 'Called by the deep-audit skill for one find round. Pass every earlier finding as seen; stop after 2 rounds add no new finding, 4 at most.',
  phases: [
    { title: 'Find', detail: 'lens reviewers, Opus for security, Sonnet for the rest' },
    { title: 'Merge', detail: 'group by nearby lines in code, a Sonnet judge decides which are the same claim' },
  ],
}

const { out, target, assignments, seen = [], round = 1, concurrency = 6 } = args
if (!out || !target || !Array.isArray(assignments) || !assignments.length) {
  throw new Error('deep-audit-find needs args.out, args.target and a non-empty args.assignments array')
}

const SONNET = 'claude-sonnet-5-5'
const OPUS = 'claude-opus-5-5'
const BRIEF = `Read ${out}/brief.md first and obey every rule in it. You are read-only in the repo.`
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

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          lens: { type: 'string' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          title: { type: 'string', description: 'one plain line' },
          where: { type: 'array', items: { type: 'string' }, description: 'every file:line, repo-relative' },
          what: { type: 'string', description: 'what is wrong and why it matters, in plain words' },
          proof: { type: 'string', description: 'path in $OUT of the saved command, test, query or measurement' },
          reproduce: { type: 'string', description: 'one line' },
          fix: { type: 'string', description: 'smallest correct fix and where it lives (this repo or upstream)' },
          effort: { type: 'string', enum: ['S', 'M', 'L'] },
          blast_radius: { type: 'string' },
        },
        required: ['lens', 'severity', 'title', 'where', 'what', 'proof', 'reproduce', 'fix', 'effort', 'blast_radius'],
      },
    },
    good_do_not_touch: { type: 'array', items: { type: 'string' } },
    files_read: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string', description: '10 lines or less' },
  },
  required: ['findings', 'good_do_not_touch', 'files_read', 'summary'],
}

phase('Find')
const reviews = await pool(assignments, concurrency, ({ lens, package: pkg, path }) => {
  const isSecurity = lens === 'F'
  return agent(
`${BRIEF}
${isSecurity ? 'This is a defensive review of the owner\'s own source code: find bugs and vulnerabilities so they can be fixed.' : SONNET_RULE}

Round ${round}. You are the lens ${lens} reviewer for package "${pkg}" at ${path} in ${target}.
Read in full: ${out}/lenses/${lens}.md (your checklist), ${out}/standards.md, ${out}/10-architecture.md, and the unit maps ${out}/1x-*-map.md for this package.
Open only the source files the maps point to for your lens, and list every one in files_read.
Runtime jobs (builds, test runs, browsers, profilers, explains) are never run by you: write each as a job spec to ${out}/jobs/ and cite the job file as the proof, unless its saved output already exists in ${out}.
Report everything you find, including low-confidence items; a judge filters later. Keep known-good parts in good_do_not_touch.
Write your full report to ${out}/2x-${lens}-${pkg}-r${round}.md and return the findings.`,
    { label: `find:${lens}:${pkg}`, phase: 'Find', model: isSecurity ? OPUS : SONNET, effort: isSecurity ? 'high' : 'medium', schema: FINDINGS_SCHEMA })
})

phase('Merge')
const RANK = { critical: 0, high: 1, medium: 2, low: 3 }
const spots = finding => finding.where.map(ref => {
  const [file, line = '0'] = ref.split(':')
  return { file, line: parseInt(line, 10) || 0 }
})
const near = (a, b) => spots(a).some(x => spots(b).some(y => x.file === y.file && Math.abs(x.line - y.line) <= 5))

const found = []
reviews.forEach((review, index) => {
  if (!review) return
  for (const finding of review.findings) found.push({ ...finding, package: assignments[index].package })
})
const good = reviews.flatMap((review, index) => review ? review.good_do_not_touch.map(item => `${assignments[index].package}: ${item}`) : [])

const parent = found.map((_, index) => index)
const root = index => (parent[index] === index ? index : (parent[index] = root(parent[index])))
found.forEach((a, i) => found.forEach((b, j) => { if (j > i && near(a, b)) parent[root(j)] = root(i) }))
const clusters = new Map()
found.forEach((_, index) => clusters.set(root(index), [...(clusters.get(root(index)) || []), index]))

const MERGE_SCHEMA = {
  type: 'object',
  properties: {
    groups: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          members: { type: 'array', items: { type: 'integer' }, description: 'numbers of the new findings that make the same claim' },
          same_as_earlier: { type: 'string', description: 'key of the earlier finding they repeat, or empty' },
        },
        required: ['members', 'same_as_earlier'],
      },
    },
  },
  required: ['groups'],
}
const describe = finding => `${finding.title} | where: ${finding.where.join(', ')} | ${finding.what}`
const judged = await pool([...clusters.values()], concurrency, async members => {
  const earlier = seen.filter(old => members.some(index => near(found[index], old)))
  if (members.length === 1 && !earlier.length) return [{ members, same_as_earlier: '' }]
  const answer = await agent(
`${SONNET_RULE}
Group these audit findings by the defect they describe. Two findings are the same only if fixing one fixes the other; the same file and lines are not enough. Every new finding number goes in exactly one group. Mark a group with an earlier key only if it repeats that earlier finding. Read the code in ${target} if the wording is not enough.

New findings:
${members.map(index => `${index}: ${describe(found[index])}`).join('\n')}
${earlier.length ? `\nEarlier findings:\n${earlier.map(old => `${old.key}: ${describe(old)}`).join('\n')}` : ''}`,
    { label: `merge:${found[members[0]].where[0]}`, phase: 'Merge', model: SONNET, effort: 'low', schema: MERGE_SCHEMA })
  const placed = new Set(answer ? answer.groups.flatMap(group => group.members) : [])
  const valid = answer ? answer.groups.filter(group => group.members.every(index => members.includes(index))) : []
  const loose = members.filter(index => !placed.has(index) || !valid.some(group => group.members.includes(index)))
  return [...valid, ...loose.map(index => ({ members: [index], same_as_earlier: '' }))]
})

const fresh = []
let repeats = 0
judged.flat().forEach(group => {
  if (!group) return
  if (group.same_as_earlier && seen.some(old => old.key === group.same_as_earlier)) { repeats++; return }
  const members = [...new Set(group.members)].map(index => found[index]).sort((a, b) => RANK[a.severity] - RANK[b.severity])
  if (!members.length) return
  const [lead] = members
  fresh.push({
    ...lead,
    key: `r${round}-${fresh.length + 1}`,
    lenses: [...new Set(members.map(member => member.lens))],
    where: [...new Set(members.flatMap(member => member.where))],
    also_reported_as: members.slice(1).map(member => member.title),
  })
})

const failed = assignments.filter((_, index) => !reviews[index])
log(`round ${round}: ${fresh.length} new findings (${found.length} raw, ${repeats} repeats of earlier rounds) from ${assignments.length - failed.length} reviewers; ${failed.length} reviewers failed`)

return {
  round,
  new_findings: fresh,
  good_do_not_touch: good,
  failed_assignments: failed,
  summaries: reviews.map((review, index) => ({ ...assignments[index], summary: review ? review.summary : 'failed' })),
}
