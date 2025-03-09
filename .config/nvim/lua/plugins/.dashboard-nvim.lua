return {
  "nvimdev/dashboard-nvim",
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
  },
  event = "VimEnter",
  opts = {
    theme = "hyper",
    hide = {
      statusline = false,
    },
    config = {
      project = {
        enable = true,
        limit = 8,
        icon = "󰏓 ",
        label = "Recent Projects",
        action = "Telescope find_files cwd=",
      },
      mru = {
        limit = 10,
        icon = " ",
        label = "Most Recent Files",
        cwd_only = false,
      },
      week_header = {
        enable = true,
      },
      disable_move = true,
      packages = { enable = false },
      shortcut = {
        { action = "Telescope find_files", desc = "Find file", icon = " ", group = "Number", key = "f" },
        { action = "ene | startinsert", desc = "New file", icon = " ", group = "String", key = "n" },
        { action = "Lazy update", desc = "Update", icon = "󰊳 ", group = "Statement", key = "u" },
        { action = "qa", desc = "Quit", icon = " ", group = "Error", key = "q" },
      },
      footer = { "" },
    },
  },
}
