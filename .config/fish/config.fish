# Fish Config
set fish_greeting ""
set fish_home ~/.config/fish

# Source
# source $fish_home/environment.fish
# source $fish_home/environment.private.fish
# source $fish_home/abbrs.fish

set DENO_INSTALL "/home/francois/.deno"
set PATH $HOME/.local/bin $HOME/bin $HOME/go/bin $DENO_INSTALL/bin $PATH

# if status is-interactive
#     # Commands to run in interactive sessions can go here
# end
starship init fish | source
