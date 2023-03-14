#!/usr/bin/zsh
# Start genie in WSL if exists
if [[ -f ~/.subsystemctl_env ]] then
	source ~/.subsystemctl_env
	rm ~/.subsystemctl_env
	stty -echoprt # fix backspace
fi
if [[ -v WSL_DISTRO_NAME ]] then
	if [[ -S /mnt/wslg/.X11-unix/X0 ]] then
		WSLG_EXIST=1  # prefer wslg if it exists
		if [[ ! -S /tmp/.X11-unix/X0 ]] then
			# fix wslg not working in subsystemctl namespace
			# https://github.com/arkane-systems/genie/issues/175#issuecomment-922526126
			ln -s /mnt/wslg/.X11-unix /tmp/.X11-unix
		fi
	fi
	if [[ "$(ps --no-headers -o comm 1)" != "systemd" ]] && (( $+commands[subsystemctl] )); then
		if ! subsystemctl is-running; then
			sudo subsystemctl start
		fi
		if ! subsystemctl is-inside; then
			cat > ~/.subsystemctl_env << EOF
export PATH="$PATH"
export WSL_DISTRO_NAME="$WSL_DISTRO_NAME"
export WSL_INTEROP="$WSL_INTEROP"
export WSLENV="$WSLENV"
export DISPLAY="$DISPLAY"
export WAYLAND_DISPLAY="$WAYLAND_DISPLAY"
export PULSE_SERVER="$PULSE_SERVER"
cd "$PWD"
EOF
			exec subsystemctl shell --quiet
			rm ~/.subsystemctl_env # should never reach here, but it is convenient for testing...
		fi
	fi
fi

# GPG TTY
export GPG_TTY=$(tty)

# Setup ssh agent
if (( $+commands[ssh-add] )) && (( !${+SSH_AUTH_SOCK} )); then
  export SSH_AUTH_SOCK=$HOME/.ssh/ssh-agent.sock
  ssh-add -l 2>/dev/null >/dev/null
  if [[ $? -ge 2 ]]; then
    if [[ -a $SSH_AUTH_SOCK ]] then
      rm $SSH_AUTH_SOCK
    fi
    ssh-agent -a $SSH_AUTH_SOCK >/dev/null
  fi
  add_key_if_not_exist(){
	  ssh-add -l | grep "$(ssh-keygen -lf $1 | head -c 20)" -q || ssh-add $1 2>/dev/null
  }
  if [[ -a ~/.ssh/id_ed25519 ]] then
	  add_key_if_not_exist ~/.ssh/id_ed25519
  elif [[ -a ~/.ssh/id_rsa ]] then
	  add_key_if_not_exist ~/.ssh/id_rsa
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
HISTSIZE=500000
SAVEHIST=500000
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'  # removed = and /
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

zinit ice wait lucid
zinit light Aloxaf/fzf-tab

zinit wait lucid light-mode for \
  zsh-users/zsh-history-substring-search \
  atinit"zicompinit; zicdreplay" \
      zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions
zinit wait lucid atload"zicompinit; zicdreplay" for \
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
  pick"fzf-*linux_amd64-*" extract mv"fzf -> fzf" @junegunn/fzf

zinit ice lucid wait multisrc'shell/{completion,key-bindings}.zsh' id-as'junegunn/fzf_completions' pick'/dev/null'
zinit light junegunn/fzf

zinit ice wait lucid  # atload"__asdf_load"
zinit load asdf-vm/asdf

# asdf completion
__asdf_load(){
	source $HOME/.zinit/plugins/asdf-vm---asdf/completions/asdf.bash
}

# bashcompinit
autoload bashcompinit
bashcompinit

# Path
export PATH="$(echo $PATH | sed 's/\/usr\/sbin://')"
export PATH=$HOME/.local/bin:"$PATH"

# WSL specific
if [[ -v WSL_DISTRO_NAME ]] then
	export PATH=$(echo $PATH | tr ':' '\n' | grep -v '/mnt/c' | tr '\n' ':' | sed 's/.$//')
	alias ex=/mnt/c/Windows/explorer.exe
	alias clip=/mnt/c/Windows/System32/clip.exe
	alias code='"/mnt/c/Users/maple3142/AppData/Local/Programs/Microsoft VS Code/bin/code"'
	if [[ "1" != "$WSLG_EXIST" ]] then
        host_ip=$(ip route show default | awk '{print $3}')
		export DISPLAY=$host_ip:0
	fi
	# Copy .ssh
	upd_ssh(){
		rm -rf ~/.ssh
		/bin/cp -rf "/mnt/c/Users/$(whoami)/.ssh" ~/.ssh
		chmod 600 ~/.ssh/*
	}
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

# Colored Man Page
export MANPAGER="less -R --use-color -Dd+r -Du+b"

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
if [[ -d ~/.cargo/bin ]] then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Golang
if [[ -d ~/.go ]] then
	export GOROOT="$HOME/.go"
	export PATH="$GOROOT/bin:$PATH"
fi

# Ruby bins
if [[ -d ~/.gem/ruby/3.0.0/bin ]] then
	export PATH="$HOME/.gem/ruby/3.0.0/bin:$PATH"
fi

# Miniconda3
if [[ -d ~/miniconda3 ]] then
	source ~/miniconda3/etc/profile.d/conda.sh
fi
ctf() {
    # A fast but incomplete alternative to `conda activate ctf`
    _ENV="ctf"
    _PREFIX="$HOME/miniconda3/envs/$_ENV"
    _BINDIR="$_PREFIX/bin"
    if [[ -v SIMPLE_CONDA ]] then
        export PATH=$(echo $PATH | sed "s|$_BINDIR||g")
        unset CONDA_PREFIX
        unset CONDA_DEFAULT_ENV
        unset CONDA_PROMPT_MODIFIER
        unset SIMPLE_CONDA
        functions[conda]=$functions[orig_conda]
        unset -f orig_conda
    else
        if [[ -v CONDA_PREFIX ]] then
            echo "Please deactivate official conda first"
        else
            export PATH="$_BINDIR:$PATH"
            export CONDA_PREFIX=$_PREFIX
            export CONDA_DEFAULT_ENV=$_ENV
            export CONDA_PROMPT_MODIFIER="($_ENV)"
            export SIMPLE_CONDA=1
            functions[orig_conda]=$functions[conda]
            conda() { echo "Please deactivate custom conda first" }
        fi
    fi
}

# CHROME_PATH
if (( $+commands[chromium] )) then
	export CHROME_PATH="$(which chromium)"
fi

# kubectl
if (( $+commands[kubectl] )) then
    kubectl completion zsh > ~/.zinit/completions/_kubectl
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
dl(){
    curl -LJO "$1"
}
if (( $+commands[rclone] )) then
    rclone(){
        if [ -z "${RCLONE_CONFIG_PASS}" ]; then
            echo -n 'Enter Rclone config password: '
            read -s RCLONE_CONFIG_PASS && export RCLONE_CONFIG_PASS=$RCLONE_CONFIG_PASS
            echo
        fi
        command rclone "$@"
    }
fi

# Poor mans ngrok
if (( $+commands[python3] && $+commands[tmux] && $+commands[cloudflared] && $+commands[mitmweb] )) then
    CF_TUNNEL=ctf
    tunnel() {
        if [[ $# -eq 1 ]]; then
            host='localhost'
            port=$1
        elif [[ $# -eq 2 ]]; then
            host=$1
            port=$2
        else
            echo "Syntax: $0 [port] or $0 [host] [port]"
            return 1
        fi
        proxy_port=`python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1])'`
        sess="tunnel-$proxy_port"
        tmux new -s "$sess" \
            "mitmweb --mode reverse:http://$host:$port -p $proxy_port --no-web-open-browser --web-port 4040"\; \
            split-window -v \
            "cloudflared tunnel --url http://localhost:$proxy_port run $CF_TUNNEL"\; \
            split-window -v \
            "zsh -c 'echo Press enter to stop; read; tmux kill-session'"\; \
            select-layout even-vertical
    }
fi

# Better `nc -lv` using ssh port forwarding
ncl() {
    if [[ ! $# -eq 2 ]]; then
        echo "Syntax: $0 [host] [port]"
        return 1
    fi
    # need to enable GatewayPorts in remote sshd_config
    host=$1
    port=$2
    ssh -R $port:0.0.0.0:$port $host -N &
    nc -lv $port
    kill -9 $!
}

# P10k Initialize
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

