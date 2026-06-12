return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      servers = {
        -- Mason's marksman (.NET single-file binary) crashes on NixOS;
        -- use the nix-provided one from PATH (home-manager installs it)
        marksman = { mason = false },
      },
    },
  },
}
