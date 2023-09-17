local highlights = require("custom.utils.highlights")
local core = require("custom.utils.core")

---@type ChadrcConfig
return {
	ui = {
		theme = "catppuccin",
		theme_toggle = { "catppuccin", "gruvbox" },
		nvdash = core.nvdash,

		hl_override = highlights.override,
		hl_add = highlights.add,
		telescope = { style = "bordered" },
		extended_integrations = { "notify", "dap" },
		cmp = {
			style = "default",
			border_color = "nord_blue",
			lspkind_text = false,
			selected_item_bg = "simple",
		},
		transparency = false,
		cheatsheet = {
			theme = "grid",
		},
		statusline = {
			theme = "minimal",
			separator_style = "round",
			overriden_modules = nil,
		},
		lsp_semantic_tokens = true,
		tabufline = {
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
	},
	plugins = "custom.plugins",
	mappings = require("custom.mappings"),
}
