import { expect, test } from 'claude-code/testing'

const ran = { result: 'ok', text: 'ok' }

test('blocks a push until it is allowed, and lets local commands run', async ($, on) => {
  on('tool.call', () => ran)

  const pushed = await $.tool.call({ tool: 'Bash', command: 'git push origin dev' })
  expect(pushed.deny).toContain('/guard allow push')

  const local = await $.tool.call({ tool: 'Bash', command: 'git status' })
  expect(local.deny).toBeUndefined()
})

test('always blocks --no-verify', async ($, on) => {
  on('tool.call', () => ran)
  const out = await $.tool.call({ tool: 'Bash', command: 'git commit --no-verify -m x' })
  expect(out.deny).toContain('--no-verify')
})

test('blocks new em dashes and project scratch dirs in Write and Edit', async ($, on) => {
  on('tool.call', () => ran)

  const dash = await $.tool.call({ tool: 'Write', file_path: '/tmp/x.md', content: 'a — b' })
  expect(dash.deny).toContain('em dash')

  const kept = await $.tool.call({
    tool: 'Edit',
    file_path: '/tmp/x.md',
    old_string: 'a — b',
    new_string: 'a — c',
  })
  expect(kept.deny).toBeUndefined()

  const stray = await $.tool.call({ tool: 'Write', file_path: '/home/u/projects/p/scratch/n.md', content: 'x' })
  expect(stray.deny).toContain('~/hub/scratch')
})

test('/guard refuses changes that come from a plugin instead of the person', async $ => {
  const out = await $.command.run({
    command: 'guard',
    args: 'allow push',
    origin: { kind: 'plugin', name: 'other' },
    presentation: { isFullscreen: false, columns: 80 },
  })
  expect(out.text).toContain('Only the person')
})
