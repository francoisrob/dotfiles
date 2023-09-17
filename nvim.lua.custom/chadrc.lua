local highlights = require("custom.utils.highlights")
local core = require("custom.utils.core")

---@type ChadrcConfig
local M = {
	ui = {
		theme = "catppuccin",
		theme_toggle = { "catppuccin", "mountain" },
		nvdash = core.nvdash,

		hl_override = highlights.override,
		hl_add = highlights.add,
	},
	-- plugins = "custom.plugins",
	plugins = "custom.plugins",
	mappings = require("custom.mappings"),
}

-- Path to overriding theme and highlights files

-- check core.mappings for table structure

return M
