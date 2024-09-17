#!/usr/bin/env bash
shopt -s expand_aliases
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
cd ~ || { echo "Unable to cd ~"; exit 1; }
rm -rf "$HOME/.cfg"
log "Cloning dotfiles"
git init --bare "$HOME/.cfg"
alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
cfg config core.excludesfile .cfgignore
cfg config status.showUntrackedFiles no
cfg config pull.ff only
cfg remote add origin https://github.com/maple3142/dotfiles.git
cfg fetch origin
cfg checkout -f -b master --track origin/master
cfg submodule update --init --recursive
log "Remember to use \`chsh -s $(command -v zsh)\` to change default shell"
log "Done! Please manually launch \`zsh\` to enjoy!"

