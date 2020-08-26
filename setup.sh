#!/bin/bash
cd ~
rm -rf .oh-my-zsh
curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
git clone https://github.com/maple3142/dotfiles.git .temphome
rm -rf .temphome/.git .temphome/setup.sh
cp -a -rf -- .temphome/. .
git clone https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zdharma/fast-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting

