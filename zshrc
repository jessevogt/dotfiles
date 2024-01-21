autoload -Uz promptinit
promptinit

autoload -Uz vcs_info
precmd() {
  vcs_info
  if [[ ! -z "$vcs_info_msg_0_" ]]; then
    vcs_info_msg_0_=" ($vcs_info_msg_0_)"
  fi
}

zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats '%b'

setopt PROMPT_SUBST
PROMPT='%m %~${vcs_info_msg_0_}> '

autoload -Uz compinit
compinit

# zstyle ':completion:*' auto-description 'specify: %d'
# zstyle ':completion:*' completer _expand _complete _correct _approximate
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' menu select=2
# eval "$(dircolors -b)"
# zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# zstyle ':completion:*' menu select=long
# zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
# zstyle ':completion:*' use-compctl false
# zstyle ':completion:*' verbose true
# 
# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
# zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

setopt histignorealldups sharehistory

HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

bindkey -e

alias tmi="tmux -CC attach || tmux -CC"
alias ls="ls --color=auto"


# sudo snap alias microk8s.kubectl mk
if type mk > /dev/null; then
  source <(mk completion zsh | sed "s/kubectl/mk/g")
fi

if type direnv > /dev/null; then
  eval "$(direnv hook zsh)"
fi


