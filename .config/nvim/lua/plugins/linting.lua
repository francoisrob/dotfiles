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
    },
  },
}
