local util = require "lspconfig.util"

---@type LazyPluginSpec[]
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {},
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        biome = {
          root_dir = util.root_pattern "",
        },
        angularls = {
          filetypes = {
            "htmlangular",
            "typescript",
            "html",
            "typescriptreact",
            "typescript.tsx",
          },
          root_dir = util.root_pattern "angular.json",
        },
        tailwindcss = {
          filetypes_exclude = { "markdown" },
          filetypes = { "html", "css", "scss", "typescript" },
          root_dir = util.root_pattern(
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.mjs",
            "tailwind.config.ts",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.mjs",
            "postcss.config.ts"
          ),
        },
        -- tsserver = {
        --   filetypes = { "typescript", "html" },
        --   root_dir = util.root_pattern("tsconfig.json"),
        -- },
        eslint = {
          filetypes = { "typescript", "html" },
          root_dir = util.root_pattern ".eslintrc.json",
        },
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
              diagnostics = {
                disable = { "missing-fields" },
              },
            },
          },
        },
        cssls = {
          filetypes = { "css", "scss", "less", "sass" },
        },
        html = {
          filetypes = { "html", "typescript", "htmlangular" },
        },
        jsonls = {
          filetypes = { "json" },
        },
      },

      ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
      -- setup = {
      --   tsserver = function(_, opts)
      --     require("typescript-tools").setup({ server = opts })
      --     return true
      --   end,
      --   -- ["*"] = function(server, opts) end,
      -- },
    },
  },
}
