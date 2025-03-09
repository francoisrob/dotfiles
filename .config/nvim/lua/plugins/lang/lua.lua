return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              telemetry = { enable = false },
            },
          },
        },
      },
    },
  },
}
