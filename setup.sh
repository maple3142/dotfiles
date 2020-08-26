#!/bin/bash
WHITE='\033[1;37m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
LOG_PREFIX="${LGREEN}Setup: ${WHITE}"
log(){
	msg="${LOG_PREFIX}${CYAN}$1${WHITE}\n"
	printf "%s" "$msg"
}
cd ~ || { echo "Unable to cd ~"; exit 1; }
log "Removing .oh-my-zsh .temphome..."
rm -rf .oh-my-zsh .temphome
log "Installing oh my zsh..."
curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
log "Cloning dotfiles to .temphome..."
git clone https://github.com/maple3142/dotfiles.git .temphome
rm -rf .temphome/.git .temphome/setup.sh
log "Copying dotfiles to home..."
cp -a -rf -- .temphome/. .
log "Removing .temphome..."
rm -rf .temphome
log "Cloning extra zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git .oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zdharma/fast-syntax-highlighting.git .oh-my-zsh/custom/plugins/fast-syntax-highlighting
log "Changing shell to zsh..."
sudo chsh -s "$(which zsh)"

