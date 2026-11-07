export const meta = {
  name: 'deep-audit-prove',
  description: 'Deep audit phase 3: fresh refuters try to disprove each finding; 3 votes for serious ones, 1 for the rest',
  whenToUse: 'Called by the deep-audit skill after the find rounds, with every merged finding.',
  phases: [
    { title: 'Prove', detail: 'Opus refuters, at most 8 findings each, grouped by file' },
    { title: 'Tally', detail: 'majority vote in code' },
  ],
}

const { out, target, findings, concurrency = 3 } = args
if (!out || !target || !Array.isArray(findings) || !findings.length) {
  throw new Error('deep-audit-prove needs args.out, args.target and a non-empty args.findings array')
}
const missingKey = findings.filter(finding => !finding.key)
if (missingKey.length) throw new Error(`${missingKey.length} findings have no key`)

const OPUS = 'claude-opus-5-5'
const BATCH = 8
const VOTES = 3

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

const fileOf = finding => (finding.where[0] || 'unknown').split(':')[0]
const byFile = new Map()
for (const finding of findings) {
  const file = fileOf(finding)
  byFile.set(file, [...(byFile.get(file) || []), finding])
}
const batches = []
let current = []
for (const group of byFile.values()) {
  for (const finding of group) {
    if (current.length === BATCH) {
      batches.push(current)
      current = []
    }
    current.push(finding)
  }
}
if (current.length) batches.push(current)

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          key: { type: 'string' },
          outcome: { type: 'string', enum: ['CONFIRMED', 'CONFIRMED_WITH_CORRECTION', 'REJECTED', 'UNVERIFIED'] },
          evidence: { type: 'string', description: 'the exact lines read or command output that decided it' },
          correction: { type: 'string', description: 'what the finding got wrong, if anything' },
          ran_proof_command: { type: 'boolean' },
        },
        required: ['key', 'outcome', 'evidence', 'correction', 'ran_proof_command'],
      },
    },
  },
  required: ['verdicts'],
}

const refutePrompt = (batch, voter) => `Read ${out}/brief.md first and obey every rule in it. You are read-only in the repo at ${target}.
This is a defensive review of the owner's own code. You found none of these findings. Your job is to try to DISPROVE each one.
For each finding: open every cited file:line yourself, read the surrounding code and its callers, and re-run the saved proof if it is a command that needs no server, browser or database (one at a time, never a write to anything outside ${out}). For a proof that needs one of those, read its saved output in ${out}/jobs/; if there is none, the finding is UNVERIFIED. Look for a guard, caller, config or test that makes the claim false.
- CONFIRMED: the code does what the finding says, and the impact is real.
- CONFIRMED_WITH_CORRECTION: real, but a detail (line, cause, severity, fix) is wrong; say what.
- REJECTED: false, already handled, or not reachable; quote the line that shows it.
- UNVERIFIED: you could not check it (the proof needs a runtime you cannot reach); say what is missing.
When unsure between CONFIRMED and REJECTED, choose UNVERIFIED. Return one verdict per key, using the key exactly as given.
Refuter ${voter + 1}.

${batch.map(finding => `--- key: ${finding.key}
title: ${finding.title} (${finding.severity}, lens ${(finding.lenses || [finding.lens]).join('+')})
where: ${finding.where.join(', ')}
what: ${finding.what}
proof: ${finding.proof}
reproduce: ${finding.reproduce}`).join('\n\n')}`

phase('Prove')
const jobs = []
batches.forEach((batch, index) => {
  const votes = batch.some(finding => finding.needs_three) ? VOTES : 1
  for (let voter = 0; voter < votes; voter++) {
    const scope = voter === 0 ? batch : batch.filter(finding => finding.needs_three)
    jobs.push({ batch: index, voter, scope })
  }
})
const answers = await pool(jobs, concurrency, job => agent(refutePrompt(job.scope, job.voter), {
  label: `refute:b${job.batch}:v${job.voter + 1}`, phase: 'Prove', model: OPUS, effort: 'high', schema: VERDICT_SCHEMA,
}))

phase('Tally')
const votesByKey = new Map(findings.map(finding => [finding.key, []]))
answers.forEach(answer => {
  if (!answer) return
  for (const verdict of answer.verdicts) {
    if (votesByKey.has(verdict.key)) votesByKey.get(verdict.key).push(verdict)
  }
})

const decide = finding => {
  const votes = votesByKey.get(finding.key)
  const asked = finding.needs_three ? VOTES : 1
  const need = Math.floor(asked / 2) + 1
  const count = outcome => votes.filter(vote => vote.outcome === outcome).length
  const real = count('CONFIRMED') + count('CONFIRMED_WITH_CORRECTION')
  if (real >= need) return count('CONFIRMED_WITH_CORRECTION') ? 'CONFIRMED_WITH_CORRECTION' : 'CONFIRMED'
  if (count('REJECTED') >= need) return 'REJECTED'
  return 'UNVERIFIED'
}

const results = findings.map(finding => ({ ...finding, outcome: decide(finding), votes: votesByKey.get(finding.key) }))
const tally = outcome => results.filter(result => result.outcome === outcome)
const lostVotes = jobs.filter((_, index) => !answers[index]).length
log(`confirmed ${tally('CONFIRMED').length + tally('CONFIRMED_WITH_CORRECTION').length}, rejected ${tally('REJECTED').length}, unverified ${tally('UNVERIFIED').length}; ${lostVotes} of ${jobs.length} refuters failed`)

return {
  confirmed: [...tally('CONFIRMED'), ...tally('CONFIRMED_WITH_CORRECTION')],
  rejected: tally('REJECTED'),
  unverified: tally('UNVERIFIED'),
  refuters: jobs.length,
  failed_refuters: lostVotes,
}
