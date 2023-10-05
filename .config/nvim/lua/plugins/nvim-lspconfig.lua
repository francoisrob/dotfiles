return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "folke/neoconf.nvim", cmd = "Neoconf", config = false, dependencies = { "nvim-lspconfig" } },
    { "folke/neodev.nvim", opts = {} },
    "mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    { "hrsh7th/cmp-nvim-lsp" },
    "pmizio/typescript-tools.nvim",
  },
  ---@class PluginLspOpts
  opts = {
    -- options for vim.diagnostic.config()
    diagnostics = {
      signs = true,
      underline = true,
      update_in_insert = false,
      virtual_text = {
        spacing = 4,
        source = "always",
        prefix = "■",
        -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
        -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
        -- prefix = "icons",
      },
      float = {
        source = "always",
        border = "rounded",
      },
      virtual_lines = false,
      severity_sort = true,
    },
    -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
    -- Be aware that you also will need to properly configure your LSP server to
    -- provide the inlay hints.
    inlay_hints = {
      enabled = false,
    },
    -- add any global capabilities here
    capabilities = {},
    -- Automatically format on save
    autoformat = true,
    -- Enable this to show formatters used in a notification
    -- Useful for debugging formatter issues
    format_notify = false,
    -- options for vim.lsp.buf.format
    -- `bufnr` and `filter` is handled by the LazyVim formatter,
    -- but can be also overridden when specified
    format = {
      formatting_options = nil,
      timeout_ms = nil,
    },
    -- LSP Server Settings
    ---@type lspconfig.options
    servers = {
      lua_ls = {
        -- mason = false, -- set to false if you don't want this server to be installed with mason
        -- Use this to add any additional keymaps
        -- for specific lsp servers
        ---@type LazyKeys[]
        keys = {},
        settings = {
          Lua = {
            completion = {
              callSnippet = "Replace",
            },
            runtime = {
              version = "LuaJIT",
            },
            diagnostics = {
              globals = { "use", "vim" },
            },
            hint = {
              enable = true,
              setType = true,
            },
            telemetry = {
              enable = false,
            },
            workspace = {
              library = {
                [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
                [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
              },
              maxPreload = 100000,
              preloadFileSize = 10000,
              checkThirdParty = false,
            },
          },
        },
        pyright = {},
        ruff_lsp = {},
      },
      ---@type lspconfig.options.tsserver
      tsserver = {
        mason = false,
      },
      eslint = {
        settings = {
          -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
          workingDirectory = { mode = "auto" },
        },
      },
    },
    -- you can do any additional lsp server setup here
    -- return true if you don't want this server to be setup with lspconfig
    ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
    setup = {
      ruff_lsp = function()
        require("lazyvim.util").on_attach(function(client, _)
          if client.name == "ruff_lsp" then
            -- Disable hover in favor of Pyright
            client.server_capabilities.hoverProvider = false
          end
        end)
      end,

      eslint = function()
        vim.api.nvim_create_autocmd("BufWritePre", {
          callback = function(event)
            if not require("lazyvim.plugins.lsp.format").enabled() then
              -- exit early if autoformat is not enabled
              return
            end

            local client = vim.lsp.get_active_clients({ bufnr = event.buf, name = "eslint" })[1]
            if client then
              local diag = vim.diagnostic.get(event.buf, { namespace = vim.lsp.diagnostic.get_namespace(client.id) })
              if #diag > 0 then
                vim.cmd "EslintFixAll"
              end
            end
          end,
        })
      end,

      tsserver = function(_, opts)
        require("typescript-tools").setup {
          on_attach = opts.on_attach,
          handlers = opts.handlers,
          settings = {
            separate_diagnostic_server = true,
            -- "change"|"insert_leave" determine when the client asks the server about diagnostic
            publish_diagnostic_on = "insert_leave",
            -- array of strings("fix_all"|"add_missing_imports"|"remove_unused"|
            -- "remove_unused_imports"|"organize_imports") -- or string "all"
            -- to include all supported code actions
            -- specify commands exposed as code_actions
            expose_as_code_action = {},
            -- string|nil - specify a custom path to `tsserver.js` file, if this is nil or file under path
            -- not exists then standard path resolution strategy is applied
            tsserver_path = "/home/francois/.volta/tools/shared/typescript/lib/tsserver.js",
          },
        }
        return true
      end,

      ["*"] = function() end,
    },
  },
}
