# Path
export PATH=$HOME/.local/bin:/usr/local/bin:$PATH

# WSL specific
if [[ $(uname -a) =~ "microsoft" ]] then
	alias ex=/mnt/c/Windows/explorer.exe
	# Copy .ssh
	rm -rf ~/.ssh
	/bin/cp -rf /mnt/c/Users/maple3142/.ssh ~/.ssh
	chmod 600 ~/.ssh/*
fi

# Zsh settings
ZSH_DISABLE_COMPFIX="true"
HIST_STAMPS="yyyy-mm-dd"

# Oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="ys"
plugins=(
	docker # docker autocomplete
	sudo # press ESC two times to prepend `sudo`
	zsh-autosuggestions # suggest command from history
	fast-syntax-highlighting # zsh syntax highlighting
	zsh_reload # `src` to reload and recompile .zshrc
)
source $ZSH/oh-my-zsh.sh

# Lang
export LANG=en_US.UTF-8

# Editor
export EDITOR=vim

# Keychain
eval `keychain --quiet --eval --agents ssh id_rsa`

# Node.js (uses tj/n)
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"

# Rust (uses rustup)
source $HOME/.cargo/env

# Golang
export GOROOT=/home/maple3142/.go
export PATH=$GOROOT/bin:$PATH

