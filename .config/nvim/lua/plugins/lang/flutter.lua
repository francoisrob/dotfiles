return {

  -- {
  --   "neovim/nvim-lspconfig",
  --   config = function()
  --     local lspconfig = require("lspconfig")
  --
  --     local function should_attach(client, bufnr)
  --       local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  --       local bufname = vim.api.nvim_buf_get_name(bufnr)
  --       if filetype == "qf" or filetype == "lspinfo" or bufname:match("definitions") or bufname:match("errors") then
  --         return false
  --       end
  --       return true
  --     end
  --
  --     lspconfig.dartls.setup({
  --       on_attach = function(client, bufnr)
  --         if not should_attach(client, bufnr) then
  --           client.stop()
  --           return
  --         end
  --       end,
  --       filetypes = { "dart" },
  --       init_options = {
  --         onlyAnalyzeProjectsWithOpenFiles = false,
  --         suggestFromUnimportedLibraries = true,
  --         closingLabels = true,
  --         outline = false,
  --         flutterOutline = false,
  --       },
  --     })
  --   end,
  -- },

  {
    "nvim-flutter/flutter-tools.nvim",
    ft = { "dart" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = function()
      local lspconfig = require("lspconfig")

      local function should_attach(client, bufnr)
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if filetype == "qf" or filetype == "lspinfo" or bufname:match("definitions") or bufname:match("errors") then
          return false
        end
        return true
      end

      -- lspconfig.dartls.setup({
      --   on_attach = function(client, bufnr)
      --     if not should_attach(client, bufnr) then
      --       client.stop()
      --       return
      --     end
      --   end,
      --   filetypes = { "dart" },
      --   init_options = {
      --     onlyAnalyzeProjectsWithOpenFiles = false,
      --     suggestFromUnimportedLibraries = true,
      --     closingLabels = true,
      --     outline = false,
      --     flutterOutline = false,
      --   },
      -- })

      require("flutter-tools").setup({
        debugger = {
          enabled = true,
        },
        dev_log = {
          enabled = false,
        },
        decorations = {
          statusline = {
            app_version = true,
            device = true,
            project_config = true,
          },
        },
        widget_guides = {
          enabled = true,
        },
        lsp = {
          color = {
            background = true,
          },
          on_attach = function(client, bufnr)
            if not should_attach(client, bufnr) then
              client.stop()
              return
            end
          end,
        },
      })
    end,
  },

  {
    "nvim-treesitter",
    -- HACK
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "dart" })
      end

      local select = vim.tbl_get(opts, "textobjects", "select")
      if select then
        select.disable = select.disable or {}
        if not vim.tbl_contains(select.disable, "dart") then
          table.insert(select.disable, "dart")
        end
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        dart = { "dart_format" },
      },
      formatters = {
        dart_format = {
          command = "dart format",
          args = { "--output", "show", "$FILENAME" },
        },
      },
    },
  },
}
