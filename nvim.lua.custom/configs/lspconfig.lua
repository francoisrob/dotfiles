local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local lspconfig = require("lspconfig")

-- if you just want default config for the servers then put them in a table
local servers = {
	"html",
	"cssls",
	"clangd",
	"tsserver",
	-- "lua_ls",
}

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = on_attach,
		capabilities = capabilities,
	})
end

-- local plugin = "My Awesome Plugin"
-- vim.notify("This is an error message.\nSomething went wrong!", "error", {
-- 	title = plugin,
-- 	on_open = function()
-- 		vim.notify("Attempting recovery.", vim.log.levels.WARN, {
-- 			title = plugin,
-- 		})
-- 		local timer = vim.loop.new_timer()
-- 		timer:start(2000, 0, function()
-- 			vim.notify({ "Fixing problem.", "Please wait..." }, "info", {
-- 				title = plugin,
-- 				timeout = 3000,
-- 				on_close = function()
-- 					vim.notify("Problem solved", nil, { title = plugin })
-- 					vim.notify("Error code 0x0395AF", 1, { title = plugin })
-- 				end,
-- 			})
-- 		end)
-- 	end,
-- })

-- lspconfig.tsserver.setup({
-- on_attach = on_attach,
-- capabilities = capabilities,
-- init_options = {
-- preferences = {
-- disableSuggestions = true,
-- }
-- }
-- })

--
-- lspconfig.pyright.setup { blabla}
