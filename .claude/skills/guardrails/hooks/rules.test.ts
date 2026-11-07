import { describe, expect, test } from 'claude-code/testing'

import { addsEmDash, checkBash, dirsInCommand, guardAction, isStrayScratch, newSince, stripQuoted } from './rules'

const gate = (command: string) => {
  const verdict = checkBash(command)
  return verdict.kind === 'gated' ? verdict.gate : verdict.kind
}

describe('checkBash', () => {
  test('gates outward actions by kind', () => {
    expect(gate('git push origin dev')).toBe('push')
    expect(gate('git -C /home/u/projects/x push')).toBe('push')
    expect(gate('git -c core.x=1 push --force')).toBe('push')
    expect(gate('git push origin --delete feature/a')).toBe('push')
    expect(gate('gh pr create --base dev --title x')).toBe('github')
    expect(gate('gh pr merge 12')).toBe('github')
    expect(gate('gh api repos/a/b/git/refs/heads/x -X DELETE')).toBe('github')
    expect(gate('just deploy-job src/db/migrations/a.ts')).toBe('deploy')
    expect(gate('nix shell nixpkgs#opentofu --command just run-job expand APPLY=1')).toBe('deploy')
    expect(gate('bun run deploy:backend')).toBe('deploy')
    expect(gate('bash scripts/deploy/backend.sh')).toBe('deploy')
    expect(gate('bunx wrangler pages deploy dist')).toBe('deploy')
    expect(gate('tofu apply')).toBe('deploy')
    expect(gate('ansible-playbook -i inv.yml site.yml')).toBe('deploy')
    expect(gate('aws ec2 terminate-instances --instance-ids i-1')).toBe('deploy')
    expect(gate('bunx changeset publish')).toBe('publish')
    expect(gate('npm publish')).toBe('publish')
  })

  test('lets local and read-only work through', () => {
    expect(gate('git status && git log --oneline -5')).toBe('pass')
    expect(gate('git stash push -m wip')).toBe('pass')
    expect(gate('git commit -m "fix: x"')).toBe('pass')
    expect(gate('gh pr list')).toBe('pass')
    expect(gate('gh pr view 12')).toBe('pass')
    expect(gate('ansible-playbook -i inv.yml site.yml --check')).toBe('pass')
    expect(gate('aws ec2 describe-instances')).toBe('pass')
    expect(gate('just dev')).toBe('pass')
    expect(gate('cp .env.example .env')).toBe('pass')
  })

  test('ignores commands that are only mentioned in quotes or heredocs', () => {
    expect(gate('grep -rn "git push" ~/.claude/projects')).toBe('pass')
    expect(gate("rg 'just deploy' docs")).toBe('pass')
    expect(gate("cat > notes.md <<'EOF'\nthen run git push origin main\nEOF")).toBe('pass')
  })

  test('still checks commands handed to another shell', () => {
    expect(gate('bash -c "git push origin main"')).toBe('push')
    expect(gate("ssh basis 'sudo bash /srv/scripts/deploy/api.sh'")).toBe('deploy')
  })

  test('always blocks gate bypasses, env moves, main branch deletes and em dashes', () => {
    expect(gate('git commit --no-verify -m "x"')).toBe('hard')
    expect(gate('git merge feature --no-verify')).toBe('hard')
    expect(gate('git commit -n -m "x"')).toBe('hard')
    expect(gate('mv .env .dev.vars')).toBe('hard')
    expect(gate('mv packages/api/.env.production /tmp/x')).toBe('hard')
    expect(gate('git branch -D master')).toBe('hard')
    expect(gate('git branch --delete develop')).toBe('hard')
    expect(gate('git commit -m "fix: a — b"')).toBe('hard')
  })
})

describe('stripQuoted', () => {
  test('removes quoted text and heredoc bodies', () => {
    expect(stripQuoted('echo "a b" \'c\' d')).toBe('echo "" \'\' d')
    expect(stripQuoted("cat <<EOF\nsecret\nEOF")).not.toContain('secret')
  })
})

describe('addsEmDash', () => {
  test('refuses only new em dashes', () => {
    expect(addsEmDash('', 'a — b')).toBe(true)
    expect(addsEmDash('a — b', 'a — c')).toBe(false)
    expect(addsEmDash('plain', 'plain - dash')).toBe(false)
  })
})

describe('isStrayScratch', () => {
  test('allows hub scratch and /tmp, refuses project scratch dirs', () => {
    expect(isStrayScratch('/home/francois/hub/scratch/x.md')).toBe(false)
    expect(isStrayScratch('/tmp/claude-1000/s/scratchpad/x.md')).toBe(false)
    expect(isStrayScratch('/home/francois/projects/basis/scratch/reply.md')).toBe(true)
    expect(isStrayScratch('/home/francois/projects/basis/src/scratchpad.ts')).toBe(false)
  })
})

describe('dirsInCommand', () => {
  test('finds cd and git -C targets and expands ~', () => {
    expect(dirsInCommand('cd ~/projects/sto && git -C /home/u/b status', '/home/u')).toEqual([
      '/home/u/projects/sto',
      '/home/u/b',
    ])
    expect(dirsInCommand('ls -la', '/home/u')).toEqual([])
  })
})

describe('newSince', () => {
  test('reports only what was added', () => {
    const base = { worktrees: ['/r'], branches: ['main'], untracked: ['a'] }
    const now = { worktrees: ['/r', '/r/wt'], branches: ['main', 'x'], untracked: ['a'] }
    expect(newSince(base, now)).toEqual({ worktrees: ['/r/wt'], branches: ['x'], untracked: [] })
  })
})

describe('guardAction', () => {
  test('the person can allow and revoke one kind at a time', () => {
    expect(guardAction('allow push', true, [])).toEqual({ kind: 'set', allowed: ['push'] })
    expect(guardAction('allow push', true, ['push'])).toEqual({ kind: 'set', allowed: ['push'] })
    expect(guardAction('revoke push', true, ['push', 'deploy'])).toEqual({ kind: 'set', allowed: ['deploy'] })
    expect(guardAction('baseline', true, [])).toEqual({ kind: 'baseline' })
  })

  test('anyone else is refused, and bad kinds are refused', () => {
    expect(guardAction('allow push', false, []).kind).toBe('refuse')
    expect(guardAction('baseline', false, []).kind).toBe('refuse')
    expect(guardAction('allow everything', true, []).kind).toBe('refuse')
    expect(guardAction('allow', true, []).kind).toBe('refuse')
  })

  test('anything else shows the current state', () => {
    expect(guardAction('', false, [])).toEqual({ kind: 'show' })
    expect(guardAction('status', true, [])).toEqual({ kind: 'show' })
  })
})
