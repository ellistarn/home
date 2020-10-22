##### Homerolled #####
export PATH=$HOME/bin:${PATH}

##### Completion #####
# https://github.com/scop/bash-completion
[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

export GITHUB_USER=ellistarn
export KUBECONFIG=$HOME/.kube/config

export GOPATH=$HOME/workspaces/go
export PATH=$PATH:$GOPATH/bin

alias python=python3

# AWS Setup
export AWS_PROFILE=dev
export AWS_ACCOUNT_ID=767520670908
export AWS_DEFAULT_REGION=us-west-2
export AWS_PAGER=
export AWS_DEFAULT_OUTPUT=json
export AWS_SDK_LOAD_CONFIG=true

# Kubernetes Setup
export KO_DOCKER_REPO="767520670908.dkr.ecr.us-west-2.amazonaws.com"
export REGISTRY=$KO_DOCKER_REPO
export EDITOR="code -w"
export KUBE_EDITOR="code -w"

alias k='kubectl'
alias kctx="kubectx"
alias kns="kubens"

source <(curl -s https://raw.githubusercontent.com/ellistarn/images/main/debug/aliases)
