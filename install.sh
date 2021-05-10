#!/usr/bin/env bash

echo "\$SPIN=$SPIN"

scriptdir=`dirname "$BASH_SOURCE"`
scriptdir=`realpath $scriptdir`
        
if [ "$SPIN" ]; then
        echo "detected spin environment"

        function spin_install {
            if type "$1" > /dev/null 2>&1
            then
                echo "$1 already installed"
            else
                echo "installing $1" 
                sudo apt-get install -y $1
            fi
        }

        spin_install "rg"

        tar xvfz $scriptdir/vim/fzf/bin/fzf-*-linux_amd64.tar.gz -C $scriptdir/vim/fzf/bin

        ln -sf $scriptdir/zshrc ~/.zshrc
        ln -sf $scriptdir/vim ~/.vim
        ln -sf $scriptdir/tmux.conf ~/.tmux.conf

        echo shopify_spin > ~/.myenv
fi
