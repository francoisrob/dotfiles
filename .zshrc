
## The following lines were added by compinstall
####
zstyle ':completion:*' completer _complete _ignored _approximate
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' menu select=1
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle :compinstall filename '/home/francois/.zshrc'

autoload -Uz compinit
compinit
####

setopt HIST_IGNORE_ALL_DUPS
bindkey -e
WORDCHARS=${WORDCHARS//[\/]}
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

autoload -Uz compinit
compinit
HISTFILE=~/.bash_history
HISTSIZE=1000
SAVEHIST=1000
bindkey -v

## Custom
####
alias ls='ls --color=auto'
alias la='ls -a'
alias ll='ls -alFh'
alias l='ls'
alias l.="ls -A | egrep '^\.'"

## Colorize the grep command output for ease of use (good for log files)
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

## check vulnerabilities microcode
alias microcode='grep . /sys/devices/system/cpu/vulnerabilities/*'

## get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

## List which processes are using sound
alias  ls_sound="lsof /dev/snd/*" 
alias rmgitcache="rm -r ~/.cache/git"

## Miscelaneous Alias
alias gpustats="gpustat -f -i 2"
alias top=btop
alias vim=nvim
####

## Volta
####
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

## Load Angular CLI autocompletion.
####
source <(ng completion script)

export PATH="$PATH:/usr/bin/google-chrome:$HOME/.local/bin"
export PATH="$PATH:$HOME/bin"
export PATH="$PATH:$HOME/.local/share/gem/ruby/bin"
export PATH="$PATH:$HOME/go/bin"

