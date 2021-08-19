# GPG TTY
export GPG_TTY=$(tty)

# Keychain
if (( $+commands[keychain] )) then
	if [[ -a ~/.ssh/id_ed25519 ]] then
		eval `keychain --quiet --eval --agents ssh id_ed25519`
	fi
	if [[ -a ~/.ssh/id_rsa ]] then
		eval `keychain --quiet --eval --agents ssh id_rsa`
	fi
fi

# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set title
echo -ne "\033]0;$USER@$HOST\007"

# Zsh settings
ZSH_DISABLE_COMPFIX="true"
HIST_STAMPS="yyyy-mm-dd"
zstyle ":completion:*" menu select
setopt autocd
unsetopt beep
unsetopt nomatch

# ZInit
source ~/.zinit/bin/zinit.zsh

zinit snippet OMZL::history.zsh
zinit wait lucid for \
  OMZL::key-bindings.zsh \
  OMZP::sudo

zinit wait lucid light-mode for \
  zsh-users/zsh-history-substring-search \
  atinit"zicompinit; zicdreplay" \
      zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions
zinit wait lucid atload"zicompinit; zicdreplay" blockf for \
  zsh-users/zsh-completions \
  esc/conda-zsh-completion

zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit lucid from"gh-r" as"program" for \
  pick"jq-*" mv"jq-* -> jq" stedolan/jq \
  pick"ripgrep-*-linux-*" extract mv"*/rg -> rg" BurntSushi/ripgrep \
  pick"exa-linux-*" extract mv"*/exa -> exa" ogham/exa \
  pick"bat-linux-*" extract mv"*/bat -> bat" @sharkdp/bat \
  pick"fd-*-linux-gnu-*" extract mv"*/fd -> fd" @sharkdp/fd \
  pick"fzf-*amd64-*" extract mv"*/fzf -> fzf" @junegunn/fzf

zinit ice lucid wait multisrc'shell/{completion,key-bindings}.zsh' id-as'junegunn/fzf_completions' pick'/dev/null'
zinit light junegunn/fzf

zinit ice wait lucid
zinit light Aloxaf/fzf-tab

zinit ice wait lucid atload"__asdf_load"
zinit load asdf-vm/asdf

# asdf completion
__asdf_load(){
	source $HOME/.zinit/plugins/asdf-vm---asdf/completions/asdf.bash
}

# bashcompinit
autoload bashcompinit
bashcompinit

# Path
export PATH="$(echo $PATH | sed 's/\/usr\/sbin//')"
export PATH=$HOME/.local/bin:"$PATH"

# WSL specific
if [[ -v WSL_DISTRO_NAME ]] then
	export PATH=$(echo $PATH | tr ':' '\n' | grep -v '/mnt/c' | tr '\n' ':' | sed 's/.$//')
	alias ex=/mnt/c/Windows/explorer.exe
	alias clip=/mnt/c/Windows/System32/clip.exe
	alias code='"/mnt/c/Program Files/Microsoft VS Code/bin/code"'
	export DISPLAY=$(route -n | grep UG | head -n1 | awk '{print $2}'):0
	# Copy .ssh
	upd_ssh(){
		rm -rf ~/.ssh
		/bin/cp -rf "/mnt/c/Users/$(whoami)/.ssh" ~/.ssh
		chmod 600 ~/.ssh/*
	}
	# Start subsystemctl if exists
	if (( $+commands[subsystemctl] )); then
		if ! subsystemctl is-running; then
			sudo subsystemctl start
		fi
	fi
fi

# Fix ssh autocomplete
zstyle ":completion:*:ssh:argument-1:*" tag-order hosts
h=()
if [[ -r ~/.ssh/config ]]; then
  h=($h ${${${(@M)${(f)"$(cat ~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi
if [[ $#h -gt 0 ]]; then
  zstyle ":completion:*:ssh:*" hosts $h
  zstyle ":completion:*:slogin:*" hosts $h
fi

# Lang
export LANG=en_US.UTF-8

# Editor
export EDITOR=vim

# fzf
export FZF_DEFAULT_COMMAND='fd'

# Python (Poetry)
if [[ -d ~/.poetry ]] then
	export PATH="$HOME/.poetry/bin:$PATH"
fi

# Rust (uses rustup)
if [[ -d ~/.cargo/env ]] then
	source ~/.cargo/env
fi

# Golang
if [[ -d ~/.go ]] then
	export GOROOT="$HOME/.go"
	export PATH="$GOROOT/bin:$PATH"
fi
# Miniconda3
if [[ -d ~/miniconda3 ]] then
	source ~/miniconda3/etc/profile.d/conda.sh
fi

# CHROME_PATH
if (( $+commands[chromium] )) then
	export CHROME_PATH="$(which chromium)"
fi

# Aliases
alias ga="git add -A"
alias gcm="git commit -m"
alias gp="git push"
alias rg="rg --no-ignore-parent -M 200"
alias fd="fd"

if (( $+commands[exa] )) then
	alias ls="exa"
	alias ll="exa -l"
	alias la="exa -la"
fi
if (( $+commands[bat] )) then
	alias cat="bat -p"
fi

ssh(){
	/usr/bin/ssh "$@"
	echo -ne "\033]0;$USER@$HOST\007"
}

# P10k Initialize
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

