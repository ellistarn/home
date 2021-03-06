if [[ $(uname) != 'Darwin' ]]; then
	exit 0
fi

#### Paths ####
export PATH=$PATH:/Users/$USER/Library/Python/3.7/bin

#### Environment Variables ####
# GNU Sed for compatibility
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"

# Setup ncurses for OSX. Required for `watch` command
export PATH="/usr/local/opt/ncurses/bin:$PATH"

#### Language Support ####
export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh" > /dev/null # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm" > /dev/null # This loads nvm bash_completion

#### Autocomplete #### 
# Sed required to remove extra space from kubectl apply -f completion
source <(kubectl completion zsh | sed '/"-f"/d')
complete -C '/usr/local/aws-cli/aws_completer' aws

#### SSH Color ####
function setItermProfile() {
    PROFILE=$1

    if [[ $(hostname) == $DEV_LAPTOP_HOST ]]; then
        PROFILE=Default
        trap - EXIT INT
    fi

    echo -e "\033]50;SetProfile=$1\a"
}

function colorssh() {
    if [[ -n "$ITERM_SESSION_ID" ]]; then
        trap "setItermProfile Default" INT EXIT
        setItermProfile SSH
    fi
    ssh $*
}

alias ssh="colorssh"

setItermProfile

