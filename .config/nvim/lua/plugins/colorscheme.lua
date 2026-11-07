return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = {
      contrast = "",
      transparent_mode = true,

      overrides = {
        IlluminatedWordText = { bg = "#504945" },
        IlluminatedWordRead = { bg = "#504945" },
        IlluminatedWordWrite = { bg = "#665c54", underline = true },

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
  { "catppuccin/nvim", enabled = false },
}
