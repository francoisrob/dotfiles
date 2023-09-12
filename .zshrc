setopt HIST_IGNORE_ALL_DUPS
bindkey -e
WORDCHARS=${WORDCHARS//[\/]}
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

zstyle ':completion:*' completer _complete _ignored
zstyle :compinstall filename '/home/francois/.zshrc'

autoload -Uz compinit
HISTFILE=~/.bash_history
HISTSIZE=1000
SAVEHIST=1000
bindkey -v

# Custom
#list
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -alFh'
alias l='ls'
alias l.="ls -A | egrep '^\.'"

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

#check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

#get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

#remove
#List which processes are using sound
alias  ls_sound="lsof /dev/snd/*" 
alias rmgitcache="rm -r ~/.cache/git"

#Miscelaneous Alias
alias gpustats="gpustat -f -i 2"
alias top=btop
alias vim=nvim

# Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Load Angular CLI autocompletion.
source <(ng completion script)

export PATH="$PATH:/usr/bin/google-chrome:$HOME/.local/bin"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.local/share/gem/ruby/bin"
