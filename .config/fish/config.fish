set fish_greeting ""
set fish_home ~/.config/fish

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" "$HOME/.local/share/bin/" $PATH
set -gx PATH "$HOME/.cargo/bin" $PATH
set -gx PROJECTS "$HOME/Projects"

set -gx EDITOR "nvim"
set -gx VISUAL "nvim"

starship init fish | source
zoxide init fish | source

function dev-api -d "npm run dev-api in current directory"
    npm run dev-api
end
