#!/bin/bash -e
TEMP=$(mktemp -d)

function cleanup() {
    rm -rf $TEMP
}

trap cleanup exit

# Install https://github.com/ohmyzsh/ohmyzsh
sh -c "$(wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

wget --directory-prefix=$HOME/.oh-my-zsh/themes https://raw.githubusercontent.com/wesbos/Cobalt2-iterm/master/cobalt2.zsh-theme

# Install https://github.com/powerline/fonts
FONTS_DIR=$TEMP/fonts
mkdir $FONTS_DIR
git clone https://github.com/powerline/fonts --depth=1 $FONTS_DIR
$FONTS_DIR/install.sh
