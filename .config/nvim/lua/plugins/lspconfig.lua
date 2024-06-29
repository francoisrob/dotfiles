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
        -- angularls = {
        --   filetypes = { "typescript", "html" },
        --   root_dir = util.root_pattern("angular.json"),
        -- },
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
          filetypes = { "html", "typescript" },
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
  -- {
  --   "pmizio/typescript-tools.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  --   event = { "BufReadPost *.ts,*.tsx,*.js,*.jsx", "BufNewFile *.ts,*.tsx,*.js,*.jsx" },
  --   opts = {
  --     settings = {
  --       tsserver_file_preferences = {
  --         includeInlayParameterNameHints = "literals",
  --         includeInlayVariableTypeHints = true,
  --         includeInlayFunctionLikeReturnTypeHints = true,
  --       },
  --     },
  --   },
  --   keys = {
  --     {
  --       "<leader>cto",
  --       ":TSToolsOrganizeImports<cr>",
  --       mode = "n",
  --       desc = "Sorts and removes unused imports"
  --     },
  --     {
  --       "<leader>ctf",
  --       ":TSToolsFileReferences<cr>",
  --       mode = "n",
  --       desc = "Find files that reference the current file"
  --     },
  --     {
  --       "<leader>cta",
  --       ":TSToolsFixAll<cr>",
  --       mode = "n",
  --       desc = "Fixes all fixable errors"
  --     },
  --     {
  --       "<leader>cti",
  --       ":TSToolsAddMissingImports<cr>",
  --       mode = "n",
  --       desc = "Adds imports for all statements that lack one and can be imported"
  --     },
  --   },
  --
  -- },
}
