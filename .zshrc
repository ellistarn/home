##### Antigen #####
source $HOME/.antigen.zsh
antigen init $HOME/.antigenrc

##### Powerlevel10k #####
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source ~/.p10k.zsh

##### Paths #####
PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH" # GNU Sed for compatibility
path+=/usr/local/go/bin
path+=($HOME/go/bin)
path+=($HOME/.cargo/bin)
path+=($HOME/bin)

##### Aliases #####
for file in $(ls -a $HOME | grep \.aliases | sort); do
  . $HOME/$file
done

##### System Settings #####
EDITOR="code -w"

##### ZSH Settings #####
echo '\e[5 q' # Use a vertical line for cursor

HYPHEN_INSENSITIVE="true"
ENABLE_CORRECTION="true"
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
SAVEHIST=5000
HISTSIZE=2000

setopt NO_CASE_GLOB # Globbing and tab-completion to be case-insensitive.
setopt GLOB_COMPLETE

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
[[ -r "/usr/local/bin/aws_completer" ]] && complete -C "/usr/local/bin/aws_completer" aws 
[[ -r "/apollo/env/AmazonAwsCli/bin/aws_completer" ]] && complete -C "/apollo/env/AmazonAwsCli/bin/aws_completer" aws 

##### Github #####
export GITHUB_USER=ellistarn
# export GITHUB_TOKEN=$(cat $HOME/.git/token)

##### Kubernetes #####
export CLOUD_PROVIDER="aws"
export KO_DOCKER_REPO="767520670908.dkr.ecr.us-west-2.amazonaws.com/dev"
export KUBE_EDITOR="code -w"
#export GOPATH=/Users/etarn/workspaces/go

##### AWS #####
export AWS_PROFILE=default
export AWS_ACCOUNT_ID=767520670908
export AWS_DEFAULT_REGION=us-west-2
export AWS_PAGER=
export AWS_DEFAULT_OUTPUT=json
export AWS_SDK_LOAD_CONFIG=true

function ssmnode() {
  aws ssm start-session --target $(k get node $1 -ojson | jq -r ".spec.providerID" | cut -f5 -d'/')
}

function aws_account() {
  aws sts get-caller-identity | jq -r ".Account"
}
function ecr_login() {
  aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(aws_account).dkr.ecr.us-west-2.amazonaws.com
}

##### Amazon #####
source $HOME/.amazonrc
