set -g fish_greeting ""

set fish_home ~/.config/fish

# Path additions - consolidated for better performance
fish_add_path --move --prepend --path "$HOME/.local/bin" "$HOME/.local/share/bin" "$HOME/.bun/bin" "$HOME/.volta/bin" "$HOME/.pub-cache/bin" "$HOME/.cache/.bun/bin" "$HOME/.cargo/bin"

# Volta
set -gx VOLTA_HOME "$HOME/.volta"
set -gx FZF_DEFAULT_COMMAND 'fd --type file --follow --hidden --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_ALT_C_COMMAND 'fd --type directory --follow --hidden --exclude .git'

# Load ASDF only if it exists
if test -f "$HOME/.local/state/nix/profiles/home-manager/home-path/share/asdf-vm/asdf.fish"
    source "$HOME/.local/state/nix/profiles/home-manager/home-path/share/asdf-vm/asdf.fish"
end

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

    if type -q direnv
        direnv hook fish | source
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
