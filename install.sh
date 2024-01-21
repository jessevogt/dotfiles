#!/usr/bin/env bash
set -uxe

scriptdir=`dirname "$BASH_SOURCE"`
scriptdir=`cd $scriptdir; pwd -P`

ln -sf $scriptdir/zshrc ~/.zshrc
ln -sf $scriptdir/tmux.conf ~/.tmux.conf
rm -rf ~/.vim && ln -sf $scriptdir/vim/ ~/.vim
