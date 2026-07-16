return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = {
      -- "" is medium contrast (bg0 #282828); the alternatives are "hard" and "soft"
      contrast = "",
      transparent_mode = true,

      -- Accent nvim's chrome with the same aqua (#8ec07c) as the rest of the
      -- system. Chrome only: syntax highlighting stays multi-coloured, because
      -- telling a string from a number is the whole job of a colourscheme.
      --
      -- The dashboard needs stating explicitly because snacks links it to
      -- general-purpose groups (Header and Footer -> Title -> green-bold, Icon
      -- and Desc -> Special -> orange, Key -> Number -> purple), so every
      -- element inherited a different colour and it read as a rainbow. snacks
      -- re-applies these on each colourscheme change but with `default = true`,
      -- which never overwrites an existing definition, so these win.
      overrides = {
        SnacksDashboardHeader = { link = "GruvboxAquaBold" },
        SnacksDashboardIcon = { link = "GruvboxAqua" },
        SnacksDashboardKey = { link = "GruvboxAquaBold" },
        SnacksDashboardTitle = { link = "GruvboxAqua" },
        SnacksDashboardSpecial = { link = "GruvboxAqua" },
        SnacksDashboardDesc = { link = "GruvboxFg1" },
        SnacksDashboardFile = { link = "GruvboxFg1" },
        SnacksDashboardFooter = { link = "GruvboxGray" },
        SnacksDashboardDir = { link = "GruvboxGray" },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
  -- LazyVim's core spec pulls catppuccin in as the default colorscheme; nothing
  -- loads it now, so stop installing it.
  { "catppuccin/nvim", enabled = false },
}
