return {
  { import = "plugins/lang" },
  {
    "folke/snacks.nvim",
    opts = {
      image = {},
      dashboard = {
        preset = {
          header = [[
      ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
      ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
      ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
      ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
      ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
      ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
      },
      picker = {
        sources = {
          explorer = {
            auto_close = false,
            ignored = true,
            hidden = true,
          },
        },
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    enabled = false,
  },
}
