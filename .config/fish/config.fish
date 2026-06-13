set -g fish_greeting ""

set fish_home ~/.config/fish

# Path additions - consolidated for better performance
fish_add_path --move --prepend --path "$HOME/.local/bin" "$HOME/.local/share/bin" "$HOME/.bun/bin" "$HOME/.pub-cache/bin" "$HOME/.cache/.bun/bin" "$HOME/.cargo/bin"

# Load secrets if they exist
if test -f ~/.secrets.fish
    source ~/.secrets.fish
end

if status is-interactive
    if type -q starship
        starship init fish | source
    end

    if type -q zoxide
        zoxide init fish | source
    end

    if type -q fzf
        fzf --fish | source
    end

    if type -q mise
        mise activate fish | source
    end
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

alias cat="bat -p"
alias ssh="kitten ssh"
alias cc="claude"
# alias cd="z"

# MongoDB management
function mongo-toggle -d "Toggle MongoDB service"
    if systemctl is-active --quiet mongodb
        sudo systemctl stop mongodb
        echo "MongoDB stopped"
    else
        sudo systemctl start mongodb
        echo "MongoDB started"
    end
end

function mongo-start -d "Start MongoDB service"
    sudo systemctl start mongodb
    echo "MongoDB started"
end

function mongo-stop -d "Stop MongoDB service"
    sudo systemctl stop mongodb
    echo "MongoDB stopped"
end

# TeamViewer management (requires teamviewerd daemon)
function teamviewer-start -d "Start TeamViewer daemon and app"
    sudo systemctl start teamviewerd
    echo "TeamViewer daemon started"
    teamviewer &
    disown
end

function teamviewer-stop -d "Stop TeamViewer daemon"
    sudo systemctl stop teamviewerd
    echo "TeamViewer daemon stopped"
end

# Port management
function port-open -d "Open a TCP port in nftables (runtime)"
    if test (count $argv) -ne 1
        echo "Usage: port-open <port>"
        return 1
    end
    sudo nft add element inet nixos-fw temp-ports "{ tcp . $argv[1] }"
    echo "Port $argv[1] opened"
end

function port-close -d "Close a TCP port in nftables (runtime)"
    if test (count $argv) -ne 1
        echo "Usage: port-close <port>"
        return 1
    end
    sudo nft delete element inet nixos-fw temp-ports "{ tcp . $argv[1] }"
    if test $status -eq 0
        echo "Port $argv[1] closed"
    else
        echo "No rule found for port $argv[1]"
    end
end

function port-list -d "Show listening ports and custom-opened ports"
    echo "=== Listening ports ==="
    ss -tlnp
    if test -f ~/.config/open-ports
        echo ""
        echo "=== Persistent custom ports ==="
        command cat ~/.config/open-ports
    end
end
