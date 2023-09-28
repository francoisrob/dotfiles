local overrides = require("custom.utils.overrides")

---@type NvPluginSpec[]
return {
	------------------------Override Plugins------------------------
	-- {
	--   "neovim/nvim-lspconfig",
	--   dependencies = {
	--     {
	--       "nvimtools/none-ls.nvim",
	--       config = function()
	--         require "custom.configs.null-ls"
	--       end,
	--     },
	--     {
	--       "williamboman/mason.nvim",
	--       opts = overrides.mason,
	--     },
	--     "williamboman/mason-lspconfig.nvim",
	--     {
	--       "folke/neodev.nvim",
	--     },
	--     "pmizio/typescript-tools.nvim",
	--   },

	--   config = function()
	--     require "plugins.configs.lspconfig"
	--     require "custom.configs.lspconfig"
	--   end,
	-- },
	{
		"jose-elias-alvarez/null-ls.nvim",
		enabled = false,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{
				"folke/neodev.nvim",
				config = function()
					require("neodev").setup({})
				end,
			},
			"pmizio/typescript-tools.nvim",
			{
				"nvimtools/none-ls.nvim",
				config = function()
					require("custom.configs.null-ls")
				end,
			},
		},

		config = function()
			require("plugins.configs.lspconfig")
			require("custom.configs.lspconfig")
		end,
	},

	{
		"stevearc/conform.nvim",
		config = function()
			require("custom.configs.conform")
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"windwp/nvim-ts-autotag",
			"chrisgrieser/nvim-various-textobjs",
			"filNaj/tree-setter",
			"echasnovski/mini.ai",
			"piersolenski/telescope-import.nvim",
			"LiadOz/nvim-dap-repl-highlights",
			"RRethy/nvim-treesitter-textsubjects",
			{
				"JoosepAlviste/nvim-ts-context-commentstring",
				config = function()
					require("Comment").setup({
						pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
					})
				end,
			},
		},
		opts = overrides.treesitter,
	},
	{
		"williamboman/mason.nvim",
		opts = overrides.mason,
	},
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = { "antosha417/nvim-lsp-file-operations" },
		opts = overrides.nvimtree,
	},
	{
		"nvim-tree/nvim-web-devicons",
		opts = overrides.devicons,
	},
	{
		"NvChad/nvterm",
		opts = overrides.nvterm,
	},
	{
		"nvim-telescope/telescope.nvim",
		opts = overrides.telescope,
		dependencies = {
			"debugloop/telescope-undo.nvim",
			"gnfisher/nvim-telescope-ctags-plus",
			"tom-anders/telescope-vim-bookmarks.nvim",
			"benfowler/telescope-luasnip.nvim",
			"nvim-telescope/telescope-dap.nvim",
			"Marskey/telescope-sg",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
			},
			-- Disabled because of a sqlite3 dependency issue
			-- {
			-- 	"nvim-telescope/telescope-frecency.nvim",
			-- 	dependencies = { "kkharji/sqlite.lua" },
			-- },
		},
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		opts = overrides.blankline,
	},
	{
		"NvChad/nvim-colorizer.lua",
		opts = overrides.colorizer,
	},
	{
		"folke/which-key.nvim",
		enabled = true,
	},
	------------------------Quality Plugins------------------------
	{
		"hrsh7th/nvim-cmp",
		opts = require("custom.configs.cmp"),
		dependencies = {
			"delphinus/cmp-ctags",
			"hrsh7th/cmp-nvim-lsp-document-symbol",
			"ray-x/cmp-treesitter",
			"js-everts/cmp-tailwind-colors",
			{
				"L3MON4D3/LuaSnip",
				config = function(_, opts)
					require("plugins.configs.others").luasnip(opts)
					local luasnip = require("luasnip")
					luasnip.filetype_extend("javascriptreact", { "html" })
					luasnip.filetype_extend("typescriptreact", { "html" })
					require("luasnip/loaders/from_vscode").lazy_load()
				end,
			},
		},
		config = function(_, opts)
			require("custom.configs.nvim-cmp")(opts)
		end,
	},
	{
		"numToStr/Comment.nvim",
		opts = {
			ignore = "^$",
		},
	},
	{
		"karb94/neoscroll.nvim",
		keys = { "<C-d>", "<C-u>" },
		config = function()
			require("neoscroll").setup()
		end,
	},
	{
		"code-biscuits/nvim-biscuits",
		event = "LspAttach",
		config = function()
			require("custom.configs.biscuits")
		end,
	},
	{
		"rainbowhxch/accelerated-jk.nvim",
		event = "CursorMoved",
		config = function()
			require("custom.configs.accelerated")
		end,
	},
	{
		"m-demare/hlargs.nvim",
		event = "BufWinEnter",
		config = function()
			require("hlargs").setup({
				hl_priority = 200,
			})
		end,
	},
	{
		"mfussenegger/nvim-dap",
		cmd = { "DapContinue", "DapStepOver", "DapStepInto", "DapStepOut", "DapToggleBreakpoint" },
		dependencies = {
			-- {
			-- 	"theHamsta/nvim-dap-virtual-text",
			-- 	config = function()
			-- 		require("custom.configs.virtual-text")
			-- 	end,
			-- },
			-- {
			-- 	"rcarriga/nvim-dap-ui",
			-- 	config = function()
			-- 		require("custom.configs.dapui")
			-- 	end,
			-- },
		},
	},
	{
		"yorickpeterse/nvim-dd",
		event = "LspAttach",
		opts = {
			timeout = 1000,
		},
	},
	{
		"Wansmer/treesj",
		cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
		config = function()
			require("treesj").setup({
				use_default_keymaps = true,
			})
		end,
	},
	{
		"nvim-lua/plenary.nvim",
	},
	{
		"echasnovski/mini.nvim",
		event = "VeryLazy",
		-- config = function()
		-- 	-- require("mini.animate").setup({
		-- 	-- 	scroll = {
		-- 	-- 		enable = false,
		-- 	-- 	},
		-- 	-- })
		-- end,
	},
	------------------------UI Plugins------------------------
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			{
				"rcarriga/nvim-notify",
				event = "VeryLazy",
				config = function()
					require("custom.configs.notify")
				end,
			},
		},
		config = function()
			require("custom.configs.noice")
		end,
	},
	{
		"folke/todo-comments.nvim",
		event = "BufReadPost",
		-- config = function()
		--   require "custom.configs.todo"
		--   dofile(vim.g.base46_cache .. "todo")
		-- end,
	},
	-- {
	--   "folke/trouble.nvim",
	--   cmd = { "TroubleToggle", "Trouble" },
	--   config = function()
	--     -- require "custom.configs.trouble"
	--     dofile(vim.g.base46_cache .. "trouble")
	--   end,
	-- },
	{
		"folke/trouble.nvim",
		cmd = { "TroubleToggle", "Trouble" },
		config = function()
			require("trouble").setup()
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		event = "VeryLazy",
		-- config = function()
		-- 	require("telescope").load_extension("ui-select")
		-- end,
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = "LazyGit",
	},
	{
		"smjonas/inc-rename.nvim",
		cmd = "IncRename",
		config = function()
			require("inc_rename").setup()
		end,
	},
	{
		"f-person/git-blame.nvim",
		cmd = "GitBlameToggle",
	},
	{
		"FabijanZulj/blame.nvim",
		cmd = "ToggleBlame",
	},
	{
		"VonHeikemen/searchbox.nvim",
		cmd = { "SearchBoxMatchAll", "SearchBoxReplace", "SearchBoxIncSearch" },
		dependencies = { "MunifTanjim/nui.nvim" },
		config = true,
	},
	{
		"Fildo7525/pretty_hover",
		event = "LspAttach",
		opts = {},
	},
	{
		"VidocqH/lsp-lens.nvim",
		config = function()
			require("lsp-lens").setup()
		end,
	},
	-- {
	--   "dnlhc/glance.nvim",
	--   cmd = "Glance",
	--   config = function()
	--     require("glance").setup {}
	--   end,
	-- },

	------------------------Language Plugins------------------------
	{
		"vuki656/package-info.nvim",
		event = "BufEnter package.json",
		opts = {
			icons = {
				enable = true,
				style = {
					up_to_date = "  ",
					outdated = "  ",
				},
			},
			autostart = true,
			hide_up_to_date = true,
			hide_unstable_versions = true,
			package_manager = "npm",
		},
	},
	-- {
	-- 	"toppair/peek.nvim",
	-- 	build = "deno task --quiet build:fast",
	-- 	ft = { "markdown", "vimwiki" },
	-- 	config = function()
	-- 		require("peek").setup({
	-- 			autoload = true,
	-- 			close_on_bdelete = true,
	-- 			app = "webview",
	-- 			theme = "dark",
	-- 			filetype = { "markdown" },
	-- 		})
	-- 	end,
	-- },
	{
		"dmmulroy/tsc.nvim",
		cmd = { "TSC" },
		opts = {},
	},
	{
		"axelvc/template-string.nvim",
		event = "InsertEnter",
		ft = {
			"javascript",
			"typescript",
			"javascriptreact",
			"typescriptreact",
		},
		opts = {},
	},
	{
		"antosha417/nvim-lsp-file-operations",
		event = "LspAttach",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-tree.lua" },
		config = function()
			require("lsp-file-operations").setup()
		end,
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("refactoring").setup()
		end,
	},
	-- {
	-- 	"rust-lang/rust.vim",
	-- 	ft = "rust",
	-- 	init = function()
	-- 		vim.g.rustfmt_autosave = 1
	-- 	end,
	-- },
	-- {
	-- 	"simrat39/rust-tools.nvim",
	-- 	ft = "rust",
	-- 	dependencies = "neovim/nvim-lspconfig",
	-- 	opts = function()
	-- 		require("custom.configs.rust-tools")
	-- 	end,
	-- 	config = function(_, opts)
	-- 		require("rust-tools").setup(opts)
	-- 	end,
	-- },

	------------------------WIP------------------------
	-- {
	-- 	"rmagatti/auto-session",
	-- 	event = "VimEnter",
	-- 	config = function()
	-- 		require("custom.configs.session")
	-- 	end,
	-- },
	-- {
	-- 	"ThePrimeagen/harpoon",
	-- 	cmd = "Harpoon",
	-- },
	-- {
	--   "shellRaining/hlchunk.nvim",
	--   event = "BufReadPost",
	--   config = function()
	--     require "custom.configs.hlchunk"
	--   end,
	-- },
	-- {
	--   "utilyre/sentiment.nvim",
	--   event = "LspAttach",
	--   opts = {},
	--   init = function()
	--     vim.g.loaded_matchparen = 1
	--   end,
	-- },
	--	{
	-- "FeiyouG/commander.nvim",
	-- dependencies = { "nvim-telescope/telescope.nvim" },
	-- },
	--  	{
	-- 	"max397574/colortils.nvim",
	-- 	cmd = "Colortils",
	-- 	config = function()
	-- 		require("colortils").setup()
	-- 	end,
	-- },
	-- {
	--   "Zeioth/compiler.nvim",
	--   cmd = { "CompilerOpen", "CompilerToggleResults" },
	--   dependencies = {
	--     {
	--       "stevearc/overseer.nvim",
	--       commit = "3047ede61cc1308069ad1184c0d447ebee92d749",
	--       opts = {
	--         task_list = {
	--           direction = "bottom",
	--           min_height = 25,
	--           max_height = 25,
	--           default_detail = 1,
	--           bindings = {
	--             ["q"] = function()
	--               vim.cmd "OverseerClose"
	--             end,
	--           },
	--         },
	--       },
	--     },
	--   },
	--   config = function(_, opts)
	--     require("compiler").setup(opts)
	--   end,
	-- },
}
