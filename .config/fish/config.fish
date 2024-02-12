set fish_greeting ""
set fish_home ~/.config/fish

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" "$HOME/.local/share/bin/" $PATH
set -gx PROJECTS "$HOME/Projects"
set -gx PATH "$HOME/.cargo/bin" $PATH

starship init fish | source

function dev-api -d "npm run dev-api in current directory"
    npm run dev-api
end
