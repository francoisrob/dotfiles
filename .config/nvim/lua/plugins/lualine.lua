return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local theme = require("lualine.themes.gruvbox")
      theme.normal.a.bg = "#8ec07c"

      opts.options = opts.options or {}
      opts.options.theme = theme
      return opts
    end,
  },
}
