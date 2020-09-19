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
cd ~ || { echo "Unable to cd ~"; exit 1; }
log "Removing .oh-my-zsh .temphome..."
rm -rf .oh-my-zsh .temphome
log "Installing oh my zsh..."
curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
log "Cloning dotfiles to .temphome..."
git clone https://github.com/maple3142/dotfiles.git .temphome
log "Copying dotfiles to home..."
cp -a -rf -- .temphome/{.zshrc,.vimrc,.prettierrc} .
log "Removing .temphome..."
rm -rf .temphome
log "Cloning extra zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git .oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zdharma/fast-syntax-highlighting.git .oh-my-zsh/custom/plugins/fast-syntax-highlighting
log "Changing shell to zsh..."
chsh -s "$(which zsh)"
log "All done! Restart your terminal or enter \`zsh\` to enjoy!"
log "If it doesn't work, use chsh to manually change shell."
