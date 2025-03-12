return {
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = { "dart" },
    -- cond = function()
    --   -- Check for pubspec.yaml or other Flutter project indicators
    --   local flutter_files = vim.fn.findfile("pubspec.yaml")
    --   print("check", flutter_files)
    --   return flutter_files ~= ""
    -- end,
    -- lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
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
      },
    },
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
