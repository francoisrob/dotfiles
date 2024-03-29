return {
  "stevearc/conform.nvim",
  optional = true,
  opts = {
    lsp_fallback = true,
    formatters_by_ft = {
      ["javascript"] = { "prettier" },
      ["typescript"] = { "prettier" },
      ["css"] = { "prettier" },
      ["scss"] = { "prettier" },
      ["less"] = { "prettier" },
      ["html"] = { "prettier" },
      ["json"] = { "prettier" },
      ["jsonc"] = { "prettier" },
      ["yaml"] = { "prettier" },
      ["markdown"] = { "prettier" },
    },
  },
}
