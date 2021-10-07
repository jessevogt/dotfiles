autoload -Uz vcs_info
precmd_functions+=( vcs_info )

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:git:*' formats '%F{200}[%b%u%c]%f'
zstyle ':vcs_info:*' enable git

setopt prompt_subst
PROMPT='%(?.%F{green}√.%F{red}?%?)%f %B%~%b ${vcs_info_msg_0_} $ '

alias ls="ls -G"
alias gpf="git push --force-with-lease"
alias gp="git push"

function is_env() {
    if [[ -f ~/.myenv ]]; then
        grep -e "^$1$" -- ~/.myenv > /dev/null 2>&1
    else
        return 1
    fi
}

if is_env "shopify_.*"
then
    echo "shopify"

    alias style="dev style --include-branch-commits"
    
    function watch-and-test() {
        local test_args="${@[-1]}"
        shift -p
        echo "watching: $@"
        echo "running: bin/rails test $test_args"
        watchman-make -p $@ --run "bin/rails test $test_args"
    }

    if is_env "shopify_mac"
    then
        echo "shopify_mac"
        PATH=$PATH:/Users/jessevogt/src/github.com/Shopify/jessevogt/scripts

        if [[ -f /opt/dev/dev.sh ]]; then
            . /opt/dev/dev.sh
        fi

        if [[ -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
            . ~/.nix-profile/etc/profile.d/nix.sh
        fi

        [[ -f /opt/dev/sh/chruby/chruby.sh ]] && type chruby >/dev/null 2>&1 || chruby () { source /opt/dev/sh/chruby/chruby.sh; chruby "$@"; }
    fi
fi


