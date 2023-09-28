return function(opts)
	dofile(vim.g.base46_cache .. "cmp")
	local format_kinds = opts.formatting.format
	opts.formatting.format = function(entry, item)
		if item.kind == "Color" then
			item = require("cmp-tailwind-colors").format(entry, item)
			if item.kind == "Color" then
				return format_kinds(entry, item)
			end
			return item
		end
		return format_kinds(entry, item)
	end
	require("cmp").setup(opts)
end
