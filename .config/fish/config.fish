set fish_greeting ""
set fish_home ~/.config/fish


# Paths (prepend to ensure priority)
fish_add_path "$HOME/.local/share/bin"
fish_add_path "$HOME/.local/bin"

# Rust
fish_add_path "$HOME/.cargo/bin"
# Bun
fish_add_path "$HOME/.bun/bin"

fish_add_path "$HOME/.volta/bin"

# Volta
set -gx VOLTA_HOME "$HOME/.volta"

set -gx FZF_DEFAULT_COMMAND 'fd --type file'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

# ASDF
source "$HOME/.local/state/nix/profiles/home-manager/home-path/share/asdf-vm/asdf.fish"

source ~/.secrets.fish

function dev-api -d "npm run dev-api in current directory"
    npm run dev-api
end

function nd -d "run 'nix develop'"
    nix develop --command fish
end

# function fish_user_key_bindings
#     fish_default_key_bindings -M insert
#     fish_vi_key_bindings --no-erase insert
# end
