set fish_greeting ""
set fish_home ~/.config/fish

# Volta
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH

set -gx PATH "$HOME/.local/share/bin/" $PATH
set -gx PATH "$HOME/.local/bin/" $PATH
set -gx PATH "/usr/local/go/bin" $PATH

# Go
# set -gx PATH /usr/local/go/bin $PATH

# Rust
set -gx PATH "$HOME/.cargo/bin" $PATH
set -gx PATH "$HOME/programs/platform-tools" $PATH

# Bun
set -gx PATH "$HOME/.bun/bin" $PATH

set -gx PROJECTS "$HOME/Projects"

set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx FZF_DEFAULT_COMMAND 'fd --type file'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

starship init fish | source
zoxide init fish | source
source ~/.asdf/asdf.fish

function dev-api -d "npm run dev-api in current directory"
    npm run dev-api
end
