return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "nix" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {
          filetypes = { "nix" },
          cmd = { "nixd" },
          settings = {
            nixd = {
              nixpkgs = {
                expr = "import <nixpkgs> {}",
              },
              formatting = {
                command = { "alejandra" },
              },
              options = {
                nixos = {
                  expr = string.format(
                    '(builtins.getFlake "path:%s/dotfiles").nixosConfigurations.inspiron-7400.options',
                    os.getenv "HOME"
                  ),
                },
                -- home_manager = {
                --   expr = '(builtins.getFlake ("git+file://" + toString ./.)).homeConfigurations."ruixi@k-on".options  fran.outputs.nixosConfigurations.inspiron-7400.config.home-manager',
                -- },
              },
            },
          },
        },

      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        nix = { "alejandra" },
      },
    },
  },
}
