##### OSX Override #####
source_mac_overrides() {
  if [[ $(uname) == 'Darwin' ]]; then
    echo Sourcing $1
    source $1;
  fi
}

##### Toolchain Setup #####
echo Sourcing $HOME/.bashrc_personal
source $HOME/.bashrc_personal

##### Work Setup #####
echo Sourcing $HOME/.bashrc_work
source $HOME/.bashrc_work
