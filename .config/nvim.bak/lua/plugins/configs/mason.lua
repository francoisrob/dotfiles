require("mason").setup({
		auto_install = true,
		ensure_installed = {
			"lua-language-server",
			"stylua",

			"css-lsp",
			"html-lsp",
			-- "typescript-language-server",
			-- "deno",
			"prettier",
			"eslint-lsp",

			"clangd",
			"clang-format",

			-- "rust-analyzer",

			-- "nil",
		},
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    },
})
