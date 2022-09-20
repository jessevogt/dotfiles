function update_path {
    if [[ -d "$1" ]]; then
        export PATH="$PATH:$1"
    fi
}

update_path "/opt/homebrew/bin"

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
