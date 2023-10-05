return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
        if require("lazyvim.util").has("noice.nvim") then
          opts.defaults["<leader>sn"] = { name = "+noice" }
        end
      end,
    config = function(_, opts)
        local wk = require("which-key")
        wk.setup(opts)
        wk.register(opts.defaults)
    end,
}
