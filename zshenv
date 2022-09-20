function update_path {
    if [[ -d "$1" ]]; then
        export PATH="$PATH:$1"
    fi
}

update_path "/opt/homebrew/bin"
. "$HOME/.cargo/env"
