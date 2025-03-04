set fish_greeting ""
set fish_home ~/.config/fish

set -gx PATH "$HOME/.local/share/bin/" $PATH
set -gx PATH "$HOME/.local/bin/" $PATH

# Volta
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

# Rust
set -gx PATH "$HOME/.cargo/bin" $PATH

# Bun
set -gx PATH "$HOME/.bun/bin" $PATH

set -gx FZF_DEFAULT_COMMAND 'fd --type file'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

starship init fish | source
zoxide init fish | source

source "$HOME/.local/state/nix/profiles/home-manager/home-path/share/asdf-vm/asdf.fish"

function dev-api -d "npm run dev-api in current directory"
    npm run dev-api
end

function fish_user_key_bindings
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert
end

source ~/.secrets.fish
