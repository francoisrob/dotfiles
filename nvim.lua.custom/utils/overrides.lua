local hl_list = {}
for i, color in pairs({ "#414559", "#51576D", "#626880", "#737994", "#838BA7" }) do
	local name = "IndentBlanklineIndent" .. i
	vim.api.nvim_set_hl(0, name, { fg = color })
	table.insert(hl_list, name)
end

return {
	mason = {
		auto_install = true,
		ensure_installed = {
			"lua-language-server",
			"stylua",

			"css-lsp",
			"html-lsp",
			"typescript-language-server",
			"deno",
			"prettier",
			"eslint-lsp",

			"clangd",
			"clang-format",

			"rust-analyzer",

			"nil",
		},
	},

	treesitter = {
		auto_install = true,
		ensure_installed = {
			"vim",
			"lua",
			"html",
			"css",
			"javascript",
			"typescript",
			"rust",
			"tsx",
			"c",
			"markdown",
			"markdown_inline",
			"nix",
		},
		indent = {
			enable = true,
		},
	},

	nvimtree = {
		git = {
			enable = true,
		},

		renderer = {
			highlight_git = true,
			icons = {
				show = {
					git = true,
				},
			},
		},
	},

	devicons = {
		override_by_filename = {
			["makefile"] = {
				icon = "",
				color = "#f1502f",
				name = "Makefile",
			},
			["mod"] = {
				icon = "󰟓",
				color = "#519aba",
				name = "Mod",
			},
			["sum"] = {
				icon = "󰟓",
				color = "#cbcb40",
				cterm_color = "185",
				name = "Sum",
			},
			[".gitignore"] = {
				icon = "",
				color = "#e24329",
				cterm_color = "196",
				name = "GitIgnore",
			},
			["js"] = {
				icon = "",
				color = "#cbcb41",
				cterm_color = "185",
				name = "Js",
			},
			["lock"] = {
				icon = "",
				color = "#bbbbbb",
				cterm_color = "250",
				name = "Lock",
			},
			["package.json"] = {
				icon = "",
				color = "#e8274b",
				name = "PackageJson",
			},
			[".eslintignore"] = {
				icon = "󰱺",
				color = "#e8274b",
				name = "EslintIgnore",
			},
			["tags"] = {
				icon = "",
				color = "#bbbbbb",
				cterm_color = "250",
				name = "Tags",
			},
			["http"] = {
				icon = "󰖟",
				color = "#519aba",
				name = "Http",
			},
		},
	},

	nvterm = {
		terminals = {
			shell = "fish",
			list = {},
			type_opts = {
				float = {
					relative = "editor",
					row = 0.1,
					col = 0.1,
					width = 0.8,
					height = 0.7,
					border = "single",
				},
				horizontal = { location = "rightbelow", split_ratio = 0.3 },
				vertical = { location = "rightbelow", split_ratio = 0.25 },
			},
		},
		behavior = {
			autoclose_on_quit = {
				enabled = false,
				confirm = true,
			},
			close_on_exit = true,
			auto_insert = true,
		},
	},

	telescope = {
		defaults = {
			file_ignore_patterns = {
				"node_modules",
				".docker",
				".git",
				"yarn.lock",
				"go.sum",
				"go.mod",
				"tags",
				"mocks",
				"refactoring",
			},
			layout_config = {
				horizontal = {
					prompt_position = "bottom",
				},
			},
		},
		extensions_list = {
			"themes",
			"terms",
			"notify",
			-- "frecency",
			"undo",
			"vim_bookmarks",
			"ast_grep",
			"ctags_plus",
			"luasnip",
			"import",
			"dap",
		},
		extensions = {
			fzf = {
				override_generic_sorter = true,
				override_file_sorter = true,
				case_mode = "smart_case",
				fuzzy = true,
			},
			ast_grep = {
				command = {
					"sg",
					"--json=stream",
					"-p",
				},
				grep_open_files = false,
				lang = nil,
			},
			import = {
				insert_at_top = true,
			},
		},
	},

	blankline = {
		filetype_exclude = {
			"help",
			"terminal",
			"lspinfo",
			"TelescopePrompt",
			"TelescopeResults",
			"nvcheatsheet",
			"lsp-installer",
			"norg",
			"Empty",
			"",
		},
		buftype_exclude = { "terminal", "nofile" },
		show_end_of_line = true,
		show_foldtext = true,
		show_trailing_blankline_indent = false,
		show_first_indent_level = true,
		show_current_context = true,
		show_current_context_start = true,
		-- char_highlight_list = hl_list,
	},

	colorizer = {
		filetypes = {
			"*",
			cmp_docs = { always_update = true },
			cmp_menu = { always_update = true },
		},
		user_default_options = {
			names = false,
			RRGGBBAA = true,
			rgb_fn = true,
			tailwind = true,
			RGB = true,
			RRGGBB = true,
			AARRGGBB = true,
			hsl_fn = true,
			css = true,
			css_fn = true,
			sass = { enable = true, parsers = { "css" } },
			mode = "background", -- Available methods are false / true / "normal" / "lsp" / "both"
			virtualtext = "■",
			always_update = true,
		},
	},
}
