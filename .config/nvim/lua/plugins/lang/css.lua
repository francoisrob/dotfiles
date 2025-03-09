return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {
          filetypes = { "css", "scss", "less", "sass" },
        },
      },
    },
  },
}
