return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- LazyVim runs lualine with theme = "auto", which resolves to gruvbox's
      -- own theme and paints normal mode beige (#a89984). Normal mode is the
      -- resting state and the most-looked-at chrome in nvim, so it takes the
      -- aqua accent (#8ec07c) used across the system.
      --
      -- Only normal mode changes. Insert/visual/replace keep their own colours
      -- on purpose: there they are a signal telling you which mode you are in,
      -- not decoration, and flattening them to one accent would throw that away.
      local theme = require("lualine.themes.gruvbox")
      theme.normal.a.bg = "#8ec07c"

      opts.options = opts.options or {}
      opts.options.theme = theme
      return opts
    end,
  },
}
