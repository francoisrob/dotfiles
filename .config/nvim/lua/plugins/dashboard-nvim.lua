return {
  'nvimdev/dashboard-nvim',
  dependencies = {
    { 'nvim-tree/nvim-web-devicons' }
  },
  event = 'VimEnter',
  opts = {
    theme = "hyper",
    hide = {
      statusline = false,
    },
    config = {
      week_header = {
        enable = true
      },
      packages = { enable = false },
      shortcut = {
        { desc = '󰊳 Update', group = '@property', action = 'Lazy update', key = 'u' },
      },
      footer = { "" }
    }
  }
}
