export DOTFILES_PATH=$(dirname $(readlink $HOME/.zshrc))

autoload -Uz vcs_info
precmd_functions+=( vcs_info )

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '%F{200}[%b%u%c]%f'
zstyle ':vcs_info:*' enable git

setopt PROMPT_SUBST

case $(hostname) in
    carrot*|jesse-sh-*|circleup*)
        host_prompt=''
        ;;
    spin)
        host_prompt=" $(cat /etc/spin/machine/fqdn | cut -d"." -f1) 🌪 "
        ;;
    *)
        host_prompt=' %m'
        ;;
esac

export PROMPT='%(?.%F{green}√.%F{red}?%?)%f'$host_prompt' %B%~%b ${vcs_info_msg_0_} $ '

if [[ "$OSTYPE" == "darwin"* ]]; then
    alias ls="ls -G"

    export PATH="$PATH:/Applications/MacVim.app/Contents/bin/"

    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval $(/opt/homebrew/bin/brew shellenv)
    elif [[ -f /usr/local/bin/brew ]]; then
        eval $(/usr/local/bin/brew shellenv)
    else
        echo "HOMEBREW NOT FOUND"
    fi
else
    alias ls="ls --color=auto"
fi

alias gpf="git push --force-with-lease"
alias gp="git push"
alias greset='git reset --hard origin/$(git name-rev --name-only HEAD)'
alias killrails="pkill -fi -9 rails"

export EDITOR=vim
bindkey -e # still use emacs at prompt even though default editor is vim

setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS
export HISTTIMEFORMAT="[%F %T] "
export HISTFILE=~/.zsh_history
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000

export PATH="$PATH:$DOTFILES_PATH/scripts"

function setup_shopify() {
    echo "setting up shopify common"
    
    alias style="dev style --include-branch-commits"
    
    function watch-and-test() {
        local test_args="${@[-1]}"
        shift -p
        echo "watching: $@"
        echo "running: bin/rails test $test_args"
        watchman-make -p $@ --run "bin/rails test $test_args"
    }
}

function setup_shopify_mac() {
    echo "setting up shopify mac"

    export PATH=$PATH:/Users/jessevogt/src/github.com/Shopify/jessevogt/scripts

    if [[ -f /opt/dev/dev.sh ]]; then
        . /opt/dev/dev.sh
    fi

    if [[ -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
        . ~/.nix-profile/etc/profile.d/nix.sh
    fi

    [[ -f /opt/dev/sh/chruby/chruby.sh ]] && type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; }
}

function is_env() {
    if [[ -f ~/.myenv ]]; then
        grep -e "^$1$" -- ~/.myenv > /dev/null 2>&1
    else
        return 1
    fi
}

is_env "shopify_.*" && setup_shopify
is_env "shopify_mac" && setup_shopify_mac

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jesse/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/jesse/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jesse/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/jesse/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

true

[[ -x /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv)
