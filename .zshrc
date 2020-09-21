# Keychain
if (( $+commands[keychain] )) && [[ -a ~/.ssh/id_rsa ]] then
	eval `keychain --quiet --eval --agents ssh id_rsa`
fi

# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ZInit
source ~/.zinit/bin/zinit.zsh

setopt promptsubst

zinit snippet OMZL::history.zsh
zinit wait lucid for \
  OMZL::theme-and-appearance.zsh \
  OMZL::key-bindings.zsh \
  OMZP::sudo

zinit wait lucid light-mode for \
  zsh-users/zsh-history-substring-search \
  atinit"zicompinit; zicdreplay" \
      zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions

zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit wait lucid for \
  as"program" pick"bin/n" tj/n

zinit wait lucid from"gh-r" as"program" for \
  pick"jq-*" mv"jq-* -> jq" stedolan/jq \
  pick"ripgrep-*-linux-*" extract mv"*/rg -> rg" BurntSushi/ripgrep \
  pick"exa-linux-*" extract mv"exa-* -> exa" ogham/exa \
  pick"bat-linux-*" extract mv"*/bat -> bat" @sharkdp/bat
  
# Path
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH

# WSL specific
uname="$(uname -a)"
if [[ ${uname:l} =~ "microsoft" ]] then
	alias ex=/mnt/c/Windows/explorer.exe
	# Copy .ssh
	upd_ssh(){
		rm -rf ~/.ssh
		/bin/cp -rf /mnt/c/Users/maple3142/.ssh ~/.ssh
		chmod 600 ~/.ssh/*
	}
fi

# Zsh settings
ZSH_DISABLE_COMPFIX="true"
HIST_STAMPS="yyyy-mm-dd"

# Lang
export LANG=en_US.UTF-8

# Editor
export EDITOR=vim

# Less
export LESS="-R --mouse"

# Node.js (uses tj/n)
if (( $+commands[n] )) then
	export N_PREFIX="$HOME/.n"
	export PATH="$N_PREFIX/bin:$PATH"
fi
if (( $+commands[yarn] )) then
	export PATH="$HOME/.yarn/bin:$PATH"
fi

# Python (Poetry)
if [[ -d ~/.poetry ]] then
	export PATH="$HOME/.poetry/bin:$PATH"
fi

# Rust (uses rustup)
if [[ -d ~/.cargo ]] then
	source ~/.cargo/env
fi

# Golang
if [[ -d ~/.go ]] then
	export GOROOT="$HOME/.go"
	export PATH="$GOROOT/bin:$PATH"
fi

# CHROME_PATH
if (( $+commands[chromium] )) then
	export CHROME_PATH="$(which chromium)"
fi

# Aliases
alias ga="git add -A"
alias gcm="git commit -m"
alias gp="git push"
if (( $+commands[exa] )) then
	alias ls=exa
fi
if (( $+commands[bat] )) then
	alias cat=bat
fi

# P10k Initialize
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

