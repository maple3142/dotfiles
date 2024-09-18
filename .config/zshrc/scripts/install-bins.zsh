#!/usr/bin/env zsh
WHITE='\033[1;37m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
LOG_PREFIX="BinInstaller:"
log() {
	printf "%b%s%b %b%s%b\n" "$LGREEN" "$LOG_PREFIX" "$WHITE" "$CYAN" "$1" "$WHITE"
}
# ZInit, still used for downloading programs
ZINIT_DIR=${XDG_DATA_HOME:-${HOME}/.local/share}/zinit
ZINIT_HOME=$ZINIT_DIR/zinit.git
zinit() {
    [ ! -d $ZINIT_HOME ] && mkdir -p $ZINIT_DIR
    [ ! -d $ZINIT_HOME/.git ] && log "Cloning zinit for downloading programs" && git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME --depth=1
    source ${ZINIT_HOME}/zinit.zsh && zinit $@
}

LOCAL_BIN=$HOME/.local/bin
[[ -d $LOCAL_BIN ]] || mkdir -p $LOCAL_BIN
path=($LOCAL_BIN $path)

bins=()
(( $+commands[jq] )) || { zinit from'gh-r' as'program' for pick'jq-*' mv"**/jq-* -> $LOCAL_BIN/jq" jqlang/jq && bins+=jq }
(( $+commands[rg] )) || { zinit from'gh-r' as'program' for pick'ripgrep-*-linux-*' extract mv"**/rg -> $LOCAL_BIN/rg" BurntSushi/ripgrep && bins+=rg }
(( $+commands[eza] )) || { zinit from'gh-r' as'program' for pick'eza-linux-*' extract mv"**/eza -> $LOCAL_BIN/eza" eza-community/eza && bins+=eza }
(( $+commands[bat] )) || { zinit from'gh-r' as'program' for pick'bat-*-linux-*' extract mv"**/bat -> $LOCAL_BIN/bat" @sharkdp/bat && bins+=bat }
(( $+commands[fd] )) || { zinit from'gh-r' as'program' for pick'fd-*-linux-*' extract mv"**/fd -> $LOCAL_BIN/fd" pick'fd' @sharkdp/fd && bins+=fd }
(( $+commands[fzf] )) || { zinit from'gh-r' as'program' for pick'fzf-*-linux-*' extract mv"**/fzf -> $LOCAL_BIN/fzf" junegunn/fzf && bins+=fzf }
(( $+commands[zoxide] )) || { zinit from'gh-r' as'program' for pick'zoxide-*-linux-*' mv"**/zoxide -> $LOCAL_BIN/zoxide" extract ajeetdsouza/zoxide && bins+=zoxide }

[[ -d $ZINIT_DIR ]] && log "Cleaning up zinit" && rm -rf $ZINIT_DIR

if [[ $#bins -gt 0 ]]; then
    log "The following programs are installed:"
    print -l $bins
else
    log "No programs are installed"
    exit 1
fi
