export type Kind = 'push' | 'github' | 'deploy' | 'publish'

export type RepoSnapshot = { worktrees: string[]; branches: string[]; untracked: string[] }

declare module 'claude-code' {
  interface PluginState {
    guardrails: {
      allowed: Kind[]
      baselines: Record<string, RepoSnapshot>
    }
  }
}
