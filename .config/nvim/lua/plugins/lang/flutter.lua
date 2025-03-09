return {
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      debugger = {
        enabled = true,
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
