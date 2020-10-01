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
log "Cloning dotfiles to .temphome..."
git clone https://github.com/maple3142/dotfiles.git .temphome
log "Copying dotfiles to home..."
cp -a -rf -- .temphome/{.zshrc,.p10k.zsh,.vimrc,.prettierrc,.tmux.conf} .
log "Removing .temphome..."
rm -rf .temphome
log "Installing zinit..."
mkdir .zinit
git clone https://github.com/zdharma/zinit.git ~/.zinit/bin --depth=1
log "Changing shell to zsh..."
chsh -s "$(which zsh)"
log "All done! Restart your terminal or enter \`zsh\` to enjoy!"
log "If it doesn't work, use chsh to manually change shell."
