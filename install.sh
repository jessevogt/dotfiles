#!/usr/bin/env bash
set -uxe

scriptdir=`dirname "$BASH_SOURCE"`
scriptdir=`cd $scriptdir; pwd -P`
        
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    function safe_sudo {
        if type sudo > /dev/null 2>&1
        then
            sudo $@
        else
            $@
        fi
    }

    function linux_install {
        if type "$2" > /dev/null 2>&1
        then
            echo "$1 ($2) already installed"
        else
            echo "installing $1" 
            safe_sudo apt-get install -y $1
        fi
    }

    linux_install "ripgrep" "rg"

    tar xvfz $scriptdir/vim/fzf/bin/fzf-*-linux_amd64.tar.gz -C $scriptdir/vim/fzf/bin

    vscode_settings_dir="$HOME/.config/Code/User"

elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "detected macos environment"

    function mac_install {
        if type "$1" > /dev/null 2>&1
        then
            echo "$1 already installed"
        else
            echo "installing $1" 
            brew install $1
        fi
    }

    mac_install "rg"
    mac_install "fzf"

    ln -Ffsh $scriptdir/hammerspoon ~/.hammerspoon

    $scriptdir/karabiner/generate_karabiner_json.py $scriptdir/karabiner/karabiner.json
    mkdir -p ~/.config
    ln -Ffsh $scriptdir/karabiner/karabiner.json ~/.config/karabiner
    
    vscode_settings_dir="$HOME/Library/Application Support/Code/User"
fi

if [[ "${SPIN:=NOT_SPIN}" != "NOT_SPIN" ]]; then
    echo "detected spin environment"
    echo shopify_spin > ~/.myenv
fi

ln -sf $scriptdir/zshrc ~/.zshrc
rm -rf ~/.vim && ln -sf $scriptdir/vim/ ~/.vim
ln -sf $scriptdir/tmux.conf ~/.tmux.conf
mkdir -p "$vscode_settings_dir" && ln -sf "$scriptdir/vscode_settings.json" "$vscode_settings_dir/settings.json"
