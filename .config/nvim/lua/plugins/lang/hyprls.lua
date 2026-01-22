return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        hyprls = {
          settings = {
            hyprls = {
              preferIgnoreFile = false,
              ignore = { "hyprlock.conf", "hypridle.conf" },
            },
          },
        },
      },
    },
  },
}
