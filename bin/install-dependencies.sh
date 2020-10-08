#!/bin/bash -e
TEMP=$(mktemp -d)

function cleanup() {
    rm -rf $TEMP
}

trap cleanup exit

# Install https://github.com/ohmyzsh/ohmyzsh
KEEP_ZSHRC=yes
sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
