local highlights = require "custom.utils.highlights"
local core = require "custom.utils.core"

---@type ChadrcConfig
return {
  ui = {
    theme = "catppuccin",
    theme_toggle = { "catppuccin", "gruvbox" },
    nvdash = core.nvdash,

    hl_override = highlights.override,
    hl_add = highlights.add,
    telescope = { style = "bordered" },
    extended_integrations = {
      "dap",
      -- "hop",
      -- "rainbowdelimiters",
      -- "codeactionmenu",
      "todo",
      "trouble",
      "notify",
    },
    cmp = {
      style = "default",
      border_color = "nord_blue",
      lspkind_text = false,
      selected_item_bg = "simple",
    },
    transparency = true,
    cheatsheet = {
      theme = "grid",
    },
    statusline = {
      theme = "minimal",
      separator_style = "round",
      overriden_modules = nil,
      lspprogress_len = 40,
    },
    lsp_semantic_tokens = true,
    tabufline = {
      enabled = true,
      show_numbers = false,
      lazyload = true,
    },
    lsp = {
      signature = {
        silent = true,
        disabled = false,
      },
    },
  },
  lazy_nvim = {
    checker = {
      enabled = true,
    },
    change_detection = {
      enabled = true,
      notify = true,
    },
    ui = {
      border = "rounded",
    },
  },
  plugins = "custom.plugins",
  mappings = require "custom.mappings",
}
