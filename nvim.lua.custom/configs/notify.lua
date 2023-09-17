---@type NvPluginSpec
return {
	"rcarriga/nvim-notify",
	event = "VeryLazy",
	config = function()
		-- dofile(vim.g.base46_cache .. "notify")
		local notify = require("notify")
		vim.notify = notify
		print = function(...)
			local print_safe_args = {}
			local _ = { ... }
			for i = 1, #_ do
				table.insert(print_safe_args, tostring(_[i]))
			end
			notify(table.concat(print_safe_args, " "), "info")
		end
		notify.setup({
			level = 2,
			minimum_width = 15,
			render = "minimal",
			stages = "fade",
			timeout = 2000,
			-- top_down = true,
			animate = true,
		})
	end,
}
