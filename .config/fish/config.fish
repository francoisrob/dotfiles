set -g fish_greeting ""

set fish_home ~/.config/fish

# Path additions - consolidated for better performance
fish_add_path --move --prepend --path "$HOME/.local/bin" "$HOME/.local/share/bin" "$HOME/.bun/bin" "$HOME/.pub-cache/bin" "$HOME/.cache/.bun/bin" "$HOME/.cargo/bin"

# Load secrets if they exist
if test -f ~/.secrets.fish
    source ~/.secrets.fish
end

function dev-api -d "npm run dev-api in current directory"
    npm run dev-api
end

function nd -d "run 'nix develop -c $SHELL'"
    nix develop -c $SHELL
end

function please -d "Run the last command with sudo"
    eval sudo (history --max=1)
end

function gitclean -d "Remove stale branches (deleted at origin but stil local) + Garbage Collection"
    git remote prune origin
    git gc --auto
    echo "Stale branches removed and garbage collection performed."
end

function reload-fish -d "Reload the fish configuration"
    source $fish_home/config.fish
end

alias cat="bat"
