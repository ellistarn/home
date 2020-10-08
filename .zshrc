#!/bin/zsh

#### INITIALZE ZSH ####
ZSH_THEME="robbyrussell"
export ZSH=$HOME/.oh-my-zsh
source $ZSH/oh-my-zsh.sh

#### Plugins ####
plugins=(git kubectl)
source /usr/local/opt/kube-ps1/share/kube-ps1.sh

#### Keybindings ####
bindkey -e
bindkey '[C' forward-word
bindkey '[D' backward-word
bindkey '^[^?' backward-kill-word

#### Tab Completions ####
compdef _ssh colorssh=ssh

autoload bashcompinit && bashcompinit

source ~/.bashrc

