return {
  { "folke/tokyonight.nvim", enabled = false },
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      transparent_background = true,
      flavour = "mocha", -- latte, frappe, macchiato, mocha
    }
  },
  -- { "rose-pine/neovim", name = "rose-pine" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
