return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    default_component_configs = {
      container = {
        enable_character_fade = false
      },
      indent = {
        indent_size = 2,
        padding = 1,           -- extra padding on left hand side
        with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
        expander_highlight = "NeoTreeExpander",
        indent_marker = "│",
        last_indent_marker = "╰",
        expander_collapsed = "",
        expander_expanded = "",
      },
    },
  }
}
