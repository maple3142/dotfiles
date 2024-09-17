#!/usr/bin/env zsh
if [ -z "$ZSH_VERSION" ]; then
	echo "Please run this script with zsh"
	exit 1
fi
# shopt -s expand_aliases
setopt aliases
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
require git || exit $?
cd ~ || { echo "Unable to cd ~"; exit 1; }
rm -rf "$HOME/.cfg"
# ZInit, still used for downloading programs
ZINIT_DIR=${XDG_DATA_HOME:-${HOME}/.local/share}/zinit
ZINIT_HOME=$ZINIT_DIR/zinit.git
zinit() {
    [ ! -d $ZINIT_HOME ] && mkdir -p $ZINIT_DIR
    [ ! -d $ZINIT_HOME/.git ] && log "Cloning zinit for downloading programs" && git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
    source ${ZINIT_HOME}/zinit.zsh && zinit $@
}

log "Try getting required binaries"
LOCAL_BIN=$HOME/.local/bin
[[ -d $LOCAL_BIN ]] || mkdir -p $LOCAL_BIN
(( $+commands[jq] )) || zinit from'gh-r' as'program' for pick'jq-*' mv"jq-* -> $LOCAL_BIN/jq" jqlang/jq
(( $+commands[rg] )) || zinit from'gh-r' as'program' for pick'ripgrep-*-linux-*' extract mv"*/rg -> $LOCAL_BIN/rg" BurntSushi/ripgrep
(( $+commands[eza] )) || zinit from'gh-r' as'program' for pick'eza-linux-*' extract mv"eza -> $LOCAL_BIN/eza" eza-community/eza
(( $+commands[bat] )) || zinit from'gh-r' as'program' for pick'bat-*-linux-*' extract mv"*/bat -> $LOCAL_BIN/bat" @sharkdp/bat
(( $+commands[fd] )) || zinit from'gh-r' as'program' for pick'fd-*-linux-*' extract mv"*/fd -> $LOCAL_BIN/fd" pick'fd' @sharkdp/fd
(( $+commands[fzf] )) || zinit from'gh-r' as'program' for pick'fzf-*-linux-*' extract mv"fzf -> $LOCAL_BIN/fzf" junegunn/fzf
(( $+commands[zoxide] )) || zinit from'gh-r' as'program' for pick'zoxide-*-linux-*' mv"zoxide -> $LOCAL_BIN/zoxide" extract ajeetdsouza/zoxide

[[ -d $ZINIT_DIR ]] && log "Cleaning up zinit" && rm -rf $ZINIT_DIR

log "Cloning dotfiles"
git init -b master --bare "$HOME/.cfg"
cfg() {
	git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
cfg config core.excludesfile .cfgignore
cfg config status.showUntrackedFiles no
cfg config pull.ff only
cfg remote add origin https://github.com/maple3142/dotfiles.git
cfg fetch origin
cfg checkout -f -b master --track origin/master
cfg submodule update --init --recursive --depth 1
log "Remember to use \`chsh -s $(command -v zsh)\` to change default shell"
log "Done! Please manually launch \`zsh\` to enjoy!"
