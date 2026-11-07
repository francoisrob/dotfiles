import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Kind, RepoSnapshot } from '../types'
import {
  KINDS,
  KIND_LABELS,
  addsEmDash,
  checkBash,
  describeLeftovers,
  guardAction,
  dirsInCommand,
  isStrayScratch,
  newSince,
} from './rules'

const allowed = atom({ plugin: 'guardrails', key: 'allowed' } as const, [])
const baselines = atom({ plugin: 'guardrails', key: 'baselines' } as const, {})

const EM_DASH_REASON = 'No em dashes in anything you write. Use a period, comma, colon or parentheses.'
const SCRATCH_REASON = 'Scratch files and hand-off docs go in ~/hub/scratch, never in a scratch folder inside a project.'

async function git($: EngineInterface, dir: string, args: string[]): Promise<string | undefined> {
  const ran = await $.process.run(['git', '-C', dir, ...args]).catch(() => undefined)
  return ran && ran.exitCode === 0 ? ran.stdout.trim() : undefined
}

async function repoRoot($: EngineInterface, dir: string): Promise<string | undefined> {
  return git($, dir, ['rev-parse', '--show-toplevel'])
}

async function snapshot($: EngineInterface, repo: string): Promise<RepoSnapshot> {
  const lines = (text: string | undefined) => (text ? text.split('\n').filter(Boolean) : [])
  const worktrees = lines(await git($, repo, ['worktree', 'list', '--porcelain']))
    .filter(line => line.startsWith('worktree '))
    .map(line => line.slice('worktree '.length))
  const branches = lines(await git($, repo, ['for-each-ref', '--format=%(refname:short)', 'refs/heads']))
  const untracked = lines(await git($, repo, ['ls-files', '--others', '--exclude-standard']))
  return { worktrees, branches, untracked }
}

// The first time a repo is touched, record what was already there, so only
// what this session adds is reported as a leftover.
async function watch($: EngineInterface, dirs: string[]): Promise<void> {
  for (const dir of dirs) {
    const repo = await repoRoot($, dir)
    if (!repo) continue
    const known = await read($, baselines)
    if (known[repo]) continue
    const base = await snapshot($, repo)
    await update($, baselines, all => ({ ...all, [repo]: base }))
  }
}

function parentDir(path: string): string {
  return path.slice(0, Math.max(1, path.lastIndexOf('/')))
}

function guardHelp(open: Kind[]): string {
  const rows = KINDS.map(kind => `  ${open.includes(kind) ? 'ALLOWED' : 'blocked'}  ${kind.padEnd(8)} ${KIND_LABELS[kind]}`)
  return [
    'Guardrails for this session:',
    ...rows,
    'Always blocked: --no-verify, moving env files, deleting main/master/dev/develop, new em dashes, scratch dirs inside projects.',
    'Use: /guard allow <kind>, /guard revoke <kind>, /guard baseline (accept current leftovers), /guard status',
  ].join('\n')
}

export const register: Register = on => {
  let home = ''

  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'guard',
      description: 'Show or change which outward actions this session may take',
      argumentHint: 'allow|revoke <push|github|deploy|publish> | baseline | status',
    })
    const ran = await $.process.run(['printenv', 'HOME']).catch(() => undefined)
    home = ran?.stdout.trim() ?? ''
    const cwd = await $.session.cwd().catch(() => undefined)
    if (cwd) await watch($, [cwd])
    return next(e)
  })

  on('command.run', { command: 'guard' }, async ($, e) => {
    // An unknown origin is treated as not the person, so the model can never
    // grant itself an outward action.
    const origin = e.origin?.kind
    const action = guardAction(e.args, origin === 'composer' || origin === 'bridge', await read($, allowed))

    if (action.kind === 'refuse') return { text: action.text }
    if (action.kind === 'set') await update($, allowed, () => action.allowed)
    if (action.kind === 'baseline') {
      const repos = Object.keys(await read($, baselines))
      for (const repo of repos) {
        const now = await snapshot($, repo)
        await update($, baselines, all => ({ ...all, [repo]: now }))
      }
      $.ui.status(undefined)
      return { text: `Baseline reset for ${repos.length} repo(s).` }
    }
    return { text: guardHelp(await read($, allowed)) }
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const verdict = checkBash(e.command)
    if (verdict.kind === 'hard') return { deny: `guardrails: ${verdict.reason}` }
    if (verdict.kind === 'gated' && !(await read($, allowed)).includes(verdict.gate)) {
      return {
        deny: `guardrails: ${verdict.reason} Blocked until Francois types "/guard allow ${verdict.gate}". Do not try another route; tell him what you want to run and why.`,
      }
    }
    await watch($, dirsInCommand(e.command, home))
    return next(e)
  })

  on('tool.call', { tool: 'Write' }, async ($, e, next) => {
    if (isStrayScratch(e.file_path)) return { deny: `guardrails: ${SCRATCH_REASON}` }
    if (addsEmDash('', e.content)) return { deny: `guardrails: ${EM_DASH_REASON}` }
    await watch($, [parentDir(e.file_path)])
    return next(e)
  })

  on('tool.call', { tool: 'Edit' }, async ($, e, next) => {
    if (isStrayScratch(e.file_path)) return { deny: `guardrails: ${SCRATCH_REASON}` }
    if (addsEmDash(e.old_string, e.new_string)) return { deny: `guardrails: ${EM_DASH_REASON}` }
    await watch($, [parentDir(e.file_path)])
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.agentId) return done
    const known = await read($, baselines)
    const notes: string[] = []
    for (const [repo, base] of Object.entries(known)) {
      const note = describeLeftovers(repo, newSince(base, await snapshot($, repo)))
      if (note) notes.push(note)
    }
    if (notes.length) {
      $.ui.status(`new since session start: ${notes.join('; ')}`)
      $.ui.toast(`New since this session started: ${notes.join('; ')}`, { timeoutMs: 8000 })
    } else {
      $.ui.status(undefined)
    }
    return done
  })
}
