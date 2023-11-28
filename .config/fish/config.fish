# Fish Config
set fish_greeting ""
set fish_home ~/.config/fish

# Source
# source $fish_home/environment.fish
# source $fish_home/environment.private.fish
# source $fish_home/abbrs.fish


# if status is-interactive
#     # Commands to run in interactive sessions can go here
# end
starship init fish | source
set -gx VOLTA_HOME "$HOME/.volta"
set -gx PATH "$VOLTA_HOME/bin" $PATH
