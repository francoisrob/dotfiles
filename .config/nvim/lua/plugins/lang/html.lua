return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        html = {
          filetypes = { "html", "typescript", "htmlangular" },
        },
      },
    },
  },
}
