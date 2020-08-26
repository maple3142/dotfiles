#!/bin/bash
cd ~
echo "Removing .oh-my-zsh .temphome..."
rm -rf .oh-my-zsh .temphome
echo "Installing oh my zsh..."
curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
echo "Cloning dotfiles to .temphome..."
git clone https://github.com/maple3142/dotfiles.git .temphome
rm -rf .temphome/.git .temphome/setup.sh
echo "Copying dotfiles to home..."
cp -a -rf -- .temphome/. .
echo "Removing .temphome..."
rm -rf .temphome
echo "Cloning extra zsh plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zdharma/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
echo "Changing shell to zsh..."
sudo chsh -s $(which zsh)

