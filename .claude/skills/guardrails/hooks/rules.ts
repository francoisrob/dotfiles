import type { Kind, RepoSnapshot } from '../types'

export const KINDS: readonly Kind[] = ['push', 'github', 'deploy', 'publish']

export const KIND_LABELS: Record<Kind, string> = {
  push: 'git push, including remote branch deletes',
  github: 'GitHub writes: PRs, releases, gh api writes',
  deploy: 'deploys, prod jobs, infra apply, cloud writes',
  publish: 'package publishes',
}

export type BashVerdict =
  | { kind: 'pass' }
  | { kind: 'hard'; reason: string }
  | { kind: 'gated'; gate: Kind; reason: string }

const EM_DASH = '\u2014'

export function stripQuoted(command: string): string {
  return command
    .replace(/<<-?\s*(['"]?)(\w+)\1[^\n]*\n[\s\S]*?\n\s*\2(?=\s|$)/g, ' ')
    .replace(/'[^']*'/g, "''")
    .replace(/"(?:\\.|[^"\\])*"/g, '""')
}

const SEP = '[^;&|\\n]*'

const HARD: readonly [RegExp, string][] = [
  [
    new RegExp(`\\bgit\\b${SEP}\\s--no-verify\\b`),
    'Skipping git hooks (--no-verify) is not allowed. Fix what the hook reports.',
  ],
  [
    new RegExp(`\\bgit\\b${SEP}\\bcommit\\b${SEP}\\s-n\\b`),
    'git commit -n skips git hooks and is not allowed. Fix what the hook reports.',
  ],
  [
    new RegExp(`\\b(?:mv|ln|rename)\\b${SEP}(?:^|[\\s/])\\.env\\b`),
    'Moving, renaming or linking env files is not allowed. Leave env files where they are.',
  ],
  [
    new RegExp(`\\bgit\\b${SEP}\\bbranch\\s+(?:-[a-zA-Z]*[dD][a-zA-Z]*|--delete)\\b${SEP}\\b(?:main|master|dev|develop)\\b`),
    'Deleting main, master, dev or develop is not allowed.',
  ],
]

const GATED: readonly [RegExp, Kind][] = [
  [/\bgit(?:\s+-[cC]\s+\S+|\s+--[\w-]+(?:=\S+)?)*\s+push\b/, 'push'],
  [/\bgh\s+pr\s+(?:create|merge|close|reopen|edit|ready)\b/, 'github'],
  [/\bgh\s+release\s+(?:create|delete|edit|upload)\b/, 'github'],
  [new RegExp(`\\bgh\\s+api\\b${SEP}(?:-X|--method)\\s*(?:POST|PUT|PATCH|DELETE)\\b`), 'github'],
  [/\b(?:just|make|bun\s+run|npm\s+run|pnpm(?:\s+run)?|yarn)\s+[\w:.-]*(?:deploy|run-job)[\w:.-]*/, 'deploy'],
  [/\bscripts\/deploy\//, 'deploy'],
  [/\bwrangler\s+(?:pages\s+)?deploy\b/, 'deploy'],
  [/\bwrangler\s+secret\s+(?:put|delete|bulk)\b/, 'deploy'],
  [/\b(?:tofu|terraform)\s+(?:apply|destroy|import)\b/, 'deploy'],
  [new RegExp(`\\bansible-playbook\\b(?!${SEP}--check)`), 'deploy'],
  [/\baws\s+\S+\s+(?:create|delete|put|update|terminate|modify|run|send|attach|detach|associate|disassociate|authorize|revoke|start|stop|reboot)-[\w-]+/, 'deploy'],
  [/\b(?:changesets?|npm|bun|pnpm|yarn)\s+publish\b/, 'publish'],
]

const WRAPPER = /\b(?:bash|sh|zsh|fish|eval|ssh|xargs|watch|timeout|sudo)\b/

export function checkBash(command: string): BashVerdict {
  if (command.includes(EM_DASH) && /\b(?:git\s+commit|gh\s+(?:pr|release))\b/.test(command)) {
    return { kind: 'hard', reason: 'No em dashes in commit messages, PRs or releases. Use a period, comma, colon or parentheses.' }
  }

  const bare = stripQuoted(command)
  const texts = WRAPPER.test(bare) ? [bare, command] : [bare]
  for (const text of texts) {
    for (const [pattern, reason] of HARD) {
      if (pattern.test(text)) return { kind: 'hard', reason }
    }
  }
  for (const text of texts) {
    for (const [pattern, gate] of GATED) {
      if (pattern.test(text)) {
        return { kind: 'gated', gate, reason: `This reaches outside this machine (${KIND_LABELS[gate]}).` }
      }
    }
  }
  return { kind: 'pass' }
}

function count(text: string, needle: string): number {
  return text.split(needle).length - 1
}

export function addsEmDash(before: string, after: string): boolean {
  return count(after, EM_DASH) > count(before, EM_DASH)
}

export function isStrayScratch(path: string): boolean {
  if (!/(?:^|\/)scratch(?:\/|$)/.test(path)) return false
  if (path.startsWith('/tmp/')) return false
  return !/^\/home\/[^/]+\/hub\/scratch(?:\/|$)/.test(path)
}

export function dirsInCommand(command: string, home: string): string[] {
  const dirs = new Set<string>()
  for (const match of command.matchAll(/(?:\bcd|\bgit\s+-C)\s+(['"]?)([~/][^\s'";&|]*)\1/g)) {
    const raw = match[2] ?? ''
    dirs.add(raw.startsWith('~') ? home + raw.slice(1) : raw)
  }
  return [...dirs]
}

export function newSince(base: RepoSnapshot, now: RepoSnapshot): RepoSnapshot {
  const fresh = (before: string[], after: string[]) => after.filter(item => !before.includes(item))
  return {
    worktrees: fresh(base.worktrees, now.worktrees),
    branches: fresh(base.branches, now.branches),
    untracked: fresh(base.untracked, now.untracked),
  }
}

export function describeLeftovers(repo: string, extra: RepoSnapshot): string | undefined {
  const parts = [
    extra.worktrees.length && `${extra.worktrees.length} worktree(s)`,
    extra.branches.length && `${extra.branches.length} branch(es)`,
    extra.untracked.length && `${extra.untracked.length} untracked file(s)`,
  ].filter(Boolean)
  return parts.length ? `${repo.split('/').slice(-2).join('/')}: ${parts.join(', ')}` : undefined
}

export type GuardAction =
  | { kind: 'show' }
  | { kind: 'set'; allowed: Kind[] }
  | { kind: 'baseline' }
  | { kind: 'refuse'; text: string }

export function guardAction(args: string, isPerson: boolean, allowed: readonly Kind[]): GuardAction {
  const [verb = 'status', target] = args.trim().split(/\s+/).filter(Boolean)
  if (verb !== 'allow' && verb !== 'revoke' && verb !== 'baseline') return { kind: 'show' }
  if (!isPerson) return { kind: 'refuse', text: 'Only the person at the keyboard can change guardrails.' }
  if (verb === 'baseline') return { kind: 'baseline' }
  if (!KINDS.includes(target as Kind)) {
    return { kind: 'refuse', text: `Unknown kind "${target ?? ''}". Kinds: ${KINDS.join(', ')}` }
  }
  const kind = target as Kind
  return {
    kind: 'set',
    allowed: verb === 'allow' ? [...new Set([...allowed, kind])] : allowed.filter(item => item !== kind),
  }
}
