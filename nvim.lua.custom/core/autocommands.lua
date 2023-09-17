local autocmd = vim.api.nvim_create_autocmd
local create_cmd = vim.api.nvim_create_user_command
local g = vim.g
local cmd = vim.cmd

g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
g.autosave = true

autocmd({ "InsertLeave" }, {
	group = vim.api.nvim_create_augroup("Autosave", {}),
	callback = function()
		if g.autosave and #vim.api.nvim_buf_get_name(0) ~= 0 and vim.bo.buflisted then
			vim.notify(string.format(" File autosaved at %s", os.date("%I:%M:%S %p")), 2, {
				title = "Autosave",
				on_open = function()
					cmd("silent w")
				end,
			})
		end
	end,
})

create_cmd("AutosaveToggle", function()
	-- vim.notify("Autosave is " .. (g.autosave and "OFF" or "ON"), "info", {
	vim.notify("Autosave is " .. (g.autosave and "OFF" or "ON"), 2, {
		title = "Autosave",
		icon = "",
		on_open = function()
			g.autosave = not g.autosave
		end,
	})
end, {})
