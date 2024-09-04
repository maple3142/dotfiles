#!/bin/bash
WHITE='\033[1;37m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
LOG_PREFIX="Setup:"
log(){
	printf "%b%s%b %b%s%b\n" "$LGREEN" "$LOG_PREFIX" "$WHITE" "$CYAN" "$1" "$WHITE"
}
require(){
	if ! [ -x "$(command -v "$1")" ]; then
		log "$1 is required, please install it."
		exit 1
	fi
}
require zsh || exit $?
require git || exit $?
require unzip || exit $?
cd ~ || { echo "Unable to cd ~"; exit 1; }
rm -rf .git
log "Cloning dotfiles"
git init
git remote add origin https://github.com/maple3142/dotfiles.git
git fetch origin
git checkout -f -b master --track origin/master
log "Remember to use \`chsh -s $(which zsh)\` to change default shell"
log "Done! Please manually launch \`zsh\` to enjoy!"

