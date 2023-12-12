# Fish Config
set fish_greeting ""
set fish_home ~/.config/fish

set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH
set -gx XDG_DATA_HOME "$HOME/.local/share"

# source $fish_home/environment.fish
# source $fish_home/environment.private.fish
# source $fish_home/abbrs.fish

# if status is-interactive
#     # Commands to run in interactive sessions can go here
# end

# if status is-login
# if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY"
#  Hyprland
# end
# end

starship init fish | source
