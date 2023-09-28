local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local lspconfig = require("lspconfig")

local servers = {
	"html",
	"cssls",
	"clangd",
	-- "tsserver",
	-- "lua_ls",
}

local custom_on_attach = function(client, bufnr)
	on_attach(client, bufnr)

	if client.server_capabilities.inlayHintProvider then
		vim.lsp.inlay_hint(bufnr, true)
	end
end

for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		on_attach = custom_on_attach,
		capabilities = capabilities,
	})
end

-- typescript
require("typescript-tools").setup({
	on_attach = custom_on_attach,

	settings = {
		tsserver_path = "/home/francois/.volta/tools/shared/typescript/lib/tsserver.js",
	},
})

vim.lsp.handlers["textDocument/hover"] = require("noice").hover
vim.lsp.handlers["textDocument/signatureHelp"] = require("noice").signature

-- require("mason-lspconfig").setup_handlers {
--   function(server_name)
--     lspconfig[server_name].setup {
--       on_attach = function(client, bufnr)
--         on_attach(client, bufnr)
--       end,
--       capabilities = capabilities,
--     }
--   end,

-- require("lua_ls").setup {
--   on_attach = custom_on_attach,
--   capabilities = capabilities,
--   settings = {
--     Lua = {
--       -- runtime = {
--       --   version = "LuaJIT",
--       -- },
--       diagnostics = {
--         globals = { "use", "vim" },
--       },
--       hint = {
--         enable = true,
--         setType = true,
--       },
--       -- telemetry = {
--       --   enable = false,
--       -- },
--       completion = {
--         callSnipper = "Replace",
--       },
--       workspace = {
--         -- checkThirdParty: false,
--         library = {
--           [vim.fn.expand "$VIMRUNTIME/lua"] = true,
--           [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
--           [vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types"] = true,
--           [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
--         },
--         maxPreload = 100000,
--         preloadFileSize = 10000,
--       },
--     },
--   },
-- }

-- vim.lsp.handlers["textDocument/hover"] = require("noice").hover
-- vim.lsp.handlers["textDocument/signatureHelp"] = require("noice").signature

-- vim.diagnostic.config {
--   virtual_lines = false,
--   virtual_text = {
--     source = "always",
--     prefix = "■",
--   },
--   -- virtual_text = false,
--   float = {
--     source = "always",
--     border = "rounded",
--   },
--   signs = true,
--   underline = false,
--   update_in_insert = false,
--   severity_sort = true,
-- }
