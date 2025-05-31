return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        angularls = {
          filetypes = {
            "htmlangular",
            "typescript",
            "html",
            "typescriptreact",
            "typescript.tsx",
          },
        },
      },
    },
  },
}
