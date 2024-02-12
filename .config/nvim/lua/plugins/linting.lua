return {
  {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
      linters_by_ft = {
        javascript = { "eslint" },
        typescript = { "eslint" },
        -- ['*'] = { 'global linter' },
        -- ['_'] = { 'fallback linter' },
      },
    },
  },
}

