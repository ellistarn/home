#!/bin/zsh

##### Antigen #####
source $HOME/.antigen.zsh
antigen init $HOME/.antigenrc

##### Powerlevel10k #####
source ~/.p10k.zsh

##### Paths #####
path+=(/usr/local/opt/gnu-sed/libexec/gnubin) # GNU Sed for compatibility
path+=($HOME/go/bin)
path+=($HOME/bin)

##### Aliases #####
for file in $(ls -a $HOME | grep \.aliases | sort); do
  . $HOME/$file
done

##### System Settings #####
EDITOR="code -w"

##### ZSH Settings #####
MAGIC_ENTER_GIT_COMMAND="git status -u ."
MAGIC_ENTER_OTHER_COMMAND="ls -lh ."

HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=5000
HISTSIZE=2000

setopt NO_CASE_GLOB # Globbing and tab-completion to be case-insensitive.
setopt GLOB_COMPLETE
setopt AUTO_CD # Enable changing to directories without typing cd first.
setopt CORRECT # enable command auto-correction
setopt CORRECT_ALL

setopt EXTENDED_HISTORY   # enable more detailed history (time, command, etc.)
setopt SHARE_HISTORY      # share history across multiple zsh sessions
setopt APPEND_HISTORY     # append to history
setopt INC_APPEND_HISTORY # adds commands as they are typed, not at shell exit
setopt HIST_VERIFY        # let you edit !$, !! and !* before executing the command
setopt HIST_IGNORE_DUPS   # do not store duplications
setopt HIST_REDUCE_BLANKS # removes blank lines from history

##### Completion #####
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' insert-tab pending                                       # pasting with tabs doesn't perform completion
zstyle ':completion:*' completer _expand _complete _files _correct _approximate # default to file completion

autoload -Uz compinit && compinit
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"
source <(kubectl completion zsh)
complete -C '/usr/local/aws-cli/aws_completer' aws

##### Keybindings #####
# https://github.com/jeffreytse/zsh-vi-mode#execute-extra-commands
function zvm_after_init() {
  bindkey '\e\e[C' forward-word
  bindkey '\e\e[D' backward-word
  bindkey '^[[A' history-beginning-search-backward
  bindkey '^[[B' history-beginning-search-forward
}
function zvm_after_lazy_keybindings() {
  #bindkey -M vicmd 'k' history-beginning-search-backward
  #bindkey -M vicmd 'j' history-beginning-search-forward
  bindkey -M vicmd '^[[A' history-beginning-search-backward
  bindkey -M vicmd '^[[B' history-beginning-search-forward
}

##### Github #####
export GITHUB_USER=ellistarn
# export GITHUB_TOKEN=$(cat $HOME/.git/token)

##### Kubernetes #####
export CLOUD_PROVIDER="aws"
export KO_DOCKER_REPO="767520670908.dkr.ecr.us-west-2.amazonaws.com/karpenter"
export KUBE_EDITOR="code -w"

##### AWS #####
export AWS_PROFILE=dev
export AWS_ACCOUNT_ID=767520670908
export AWS_DEFAULT_REGION=us-west-2
export AWS_PAGER=
export AWS_DEFAULT_OUTPUT=json
export AWS_SDK_LOAD_CONFIG=true
function aws_account() {
  aws sts get-caller-identity | jq -r ".Account"
}
function ecr_login() {
  aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(aws_account).dkr.ecr.us-west-2.amazonaws.com
}

##### Amazon #####
source $HOME/.amazonrc
