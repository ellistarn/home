
export DEV_DESKTOP_HOST=etarn.corp.amazon.com
export BRAZIL_WORKSPACE=workspaces/brazil
export WS=$HOME/workspaces/brazil

export AWS_ACCOUNT_ID=767520670908

export SAM_ACCOUNT=$AWS_ACCOUNT_ID
export SAM_ISENGARD_ROLE_NAME=Admin
export SAM_REGION=us-west-2
export SAM_AWS_PARTITION=aws

export WESLEY_DEV_STACK_DNS="etarn.us-west-2.dev.holograph.space"
export WESLEY_DEV_FRONTEND_API_GATEWAY_URL=https://z15tesp5re.execute-api.us-west-2.amazonaws.com/Stage/

scp_dev() {
    scp -r $DEV_DESKTOP_HOST:$@
}

dev_tunnel() {
  ssh -L "$1":localhost:"$1" $DEV_DESKTOP_HOST -f -N
}

aws_login() {
  ACCOUNT=${1:-$AWS_ACCOUNT_ID}
  ROLE=${2:-Admin}
  open "https://isengard.amazon.com/federate?account=$ACCOUNT&role=$ROLE"
}

alias bb="brazil-build"
alias bbr="brazil-build release"
alias bbt="brazil-build test"
alias bbc="brazil-build clean"
alias bup="brazil ws --use --package"
alias brp="yes | brazil ws --remove --package"
alias bws="brazil ws --sync --metadata"
alias bba="brazil-recursive-cmd brazil-build --allPackages"
alias sam="brazil-build-tool-exec sam"
alias deveks="aws eks --endpoint $WESLEY_DEV_FRONTEND_API_GATEWAY_URL"

export PATH=$HOME/.toolbox/bin:$PATH
export PATH=$HOME/workspaces/brazil/EksAdm/src/EksAdm/build/bin:$PATH
export PATH=/usr/local/go/bin:$PATH

export AUTH_HOST=$DEV_DESKTOP_HOST
