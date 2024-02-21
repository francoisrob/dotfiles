-- add tsserver and setup with typescript.nvim instead of lspconfig
local util = require "lspconfig.util"
return {
  "neovim/nvim-lspconfig",
  dependencies = {
    {
      "pmizio/typescript-tools.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    }
  },
  ---@class PluginLspOpts
  opts = {
    ---@type lspconfig.options
    servers = {
      angularls = {
        filetypes = { "typescript", "html" },
        root_dir = util.root_pattern("angular.json", "tsconfig.json", ".git"),
      },
      tailwindcss = {
        filetypes_exclude = { "markdown" },
        filetypes = { "html", "css", "scss", "typescript" },
        root_dir = util.root_pattern("tailwind.config.js", "tailwind.config.cjs", "tailwind.config.ts"),
      },
      tsserver = {
        filetypes = { "typescript" },
        root_dir = util.root_pattern("tsconfig.json"),
      },
      lua_ls = {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            diagnostics = {
              disable = { "missing-fields" },
            }
          },
        },
      },
      cssls = {
        filetypes = { "css", "scss", "less", "sass" },
      },
      html = {
        filetypes = { "html" },
      },
      jsonls = {
        filetypes = { "json" },
      },
    },

    ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
    setup = {
      tsserver = function(_, opts)
        require("typescript-tools").setup({ server = opts })
        return true
      end,
      -- ["*"] = function(server, opts) end,
    },
  },
}
