return {
  {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
      linters_by_ft = {
        typescript = { "eslint_d" },
        -- ['*'] = { 'global linter' },
        -- ['_'] = { 'fallback linter' },
      },
      linters = {
        eslint_d = {
          args = {
            "--no-warn-ignored",
            "--format",
            "json",
            "--stdin",
            "--stdin-filename",
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
          },
        },
      },
    },
  },
}
