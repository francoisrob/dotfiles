return {
	general = {
		n = {
			[";"] = { ":", "enter command mode", opts = { nowait = true } },
		},
	},

	dap = {
		n = {
			["<leader>db"] = {
				"<cmd> DapToggleBreakpoint <CR>",
				"Toggle breakpoint",
			},
		},
	},
}
