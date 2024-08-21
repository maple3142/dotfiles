#!/usr/bin/zsh
# Start genie in WSL if exists
if [[ -v WSL_DISTRO_NAME ]]; then
	if [[ -S /mnt/wslg/.X11-unix/X0 ]]; then
		WSLG_EXIST=0  # prefer wslg if it exists
        if [[ ! -S /tmp/.X11-unix/X0 ]]; then
            ln -sf /mnt/wslg/.X11-unix/X0 /tmp/.X11-unix/X0  # It isn't mounted correctly in WSL 2.0.14.0 for me ¯\_(ツ)_/¯
        fi
	fi
fi

# GPG TTY
export GPG_TTY=$(tty)

# Setup ssh agent
if (( $+commands[ssh-add] )) && (( !${+SSH_AUTH_SOCK} )); then
  [ ! -d $HOME/.ssh ] && mkdir -m 700 $HOME/.ssh
  export SSH_AUTH_SOCK=$HOME/.ssh/ssh-agent.sock
  ssh-add -l 2>/dev/null >/dev/null
  if [[ $? -ge 2 ]]; then
    if [[ -a $SSH_AUTH_SOCK ]]; then
      rm $SSH_AUTH_SOCK
    fi
    ssh-agent -a $SSH_AUTH_SOCK >/dev/null
  fi
  add_key_if_not_exist(){
	  ssh-add -l | grep "$(ssh-keygen -lf $1 | head -c 20)" -q || ssh-add $1 2>/dev/null
  }
  if [[ -a ~/.ssh/id_ed25519 ]]; then
	  add_key_if_not_exist ~/.ssh/id_ed25519
  elif [[ -a ~/.ssh/id_rsa ]]; then
	  add_key_if_not_exist ~/.ssh/id_rsa
  fi
fi

# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set title
__reset_title() {
    echo -ne "\033]0;$USER@$HOST\007"
}
__reset_title

# Zsh settings
ZSH_DISABLE_COMPFIX="true"
HIST_STAMPS="yyyy-mm-dd"
HISTSIZE=500000
SAVEHIST=500000
WORDCHARS='*?_-.[]~&;!#$%^(){}<>|'  # removed = and / then add |
ZLE_SPACE_SUFFIX_CHARS=$'|&-'
zstyle ":completion:*" menu select
setopt autocd
setopt histignorespace
unsetopt beep
unsetopt nomatch

# ZInit
ZINIT_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
ZINIT_HOME="$ZINIT_DIR/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit lucid light-mode for \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZP::sudo/sudo.plugin.zsh

zinit ice wait lucid multisrc'shell/{completion,key-bindings}.zsh' id-as'junegunn/fzf_completions' pick'/dev/null'
zinit light junegunn/fzf

zinit ice wait light-mode lucid blockf compile'lib/*f*~*.zwc'
zinit light Aloxaf/fzf-tab

zinit wait lucid light-mode for \
    atload'bindkey "^[[A" history-substring-search-up; bindkey "^[[B" history-substring-search-down' \
        zsh-users/zsh-history-substring-search \
    atinit'zicompinit; zicdreplay' atload'FAST_HIGHLIGHT[chroma-man]=' \
    atclone'(){local f;cd -q →*;for f (*~*.zwc){zcompile -Uz -- ${f}};}' \
    compile'.*fast*~*.zwc' nocompletions atpull'%atclone' \
        zdharma-continuum/fast-syntax-highlighting \
    atload'_zsh_autosuggest_start' \
        zsh-users/zsh-autosuggestions

zinit wait lucid light-mode as'completion' atpull'zinit cclear' blockf for \
    zsh-users/zsh-completions \
    esc/conda-zsh-completion

zinit ice depth=1
zinit light romkatv/powerlevel10k

zinit lucid from"gh-r" as"program" for \
    pick"jq-*" mv"jq-* -> jq" jqlang/jq \
    pick"ripgrep-*-linux-*" extract mv"*/rg -> rg" BurntSushi/ripgrep \
    pick"eza-linux-*" extract mv"*/eza -> eza" eza-community/eza \
    pick"bat-linux-*" extract mv"*/bat -> bat" @sharkdp/bat \
    pick"fd-*-linux-gnu-*" extract mv"*/fd -> fd" @sharkdp/fd \
    pick"fzf-*linux_amd64-*" extract mv"fzf -> fzf" @junegunn/fzf

zinit ice wait lucid
zinit light asdf-vm/asdf

# bashcompinit
autoload bashcompinit
bashcompinit

# Path
export PATH="$(echo $PATH | sed 's/\/usr\/sbin://')"
export PATH=$HOME/.local/bin:"$PATH"

# WSL specific
if [[ -v WSL_DISTRO_NAME ]]; then
	export PATH=$(echo $PATH | tr ':' '\n' | grep -v '/mnt/c' | tr '\n' ':' | sed 's/.$//')
    export HOSTIP=$(ip route show default | awk '{print $3}')
	# alias ex=/mnt/c/Windows/explorer.exe
    ex(){
        /mnt/c/Windows/explorer.exe ${1//\//\\}  # replace / to \
    }
	alias clip=/mnt/c/Windows/System32/clip.exe
    alias wt="/mnt/c/Users/$USER/AppData/Local/Microsoft/WindowsApps/wt.exe"
	alias code="'/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin/code'"
	if [[ "1" != "$WSLG_EXIST" ]]; then
		export DISPLAY=$HOSTIP:0
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
  h=($h ${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
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
if [[ -d ~/.poetry ]]; then
	export PATH="$HOME/.poetry/bin:$PATH"
fi

# Rust (uses rustup)
if [[ -d ~/.cargo/env ]]; then
	source ~/.cargo/env
fi
if [[ -d ~/.cargo/bin ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Golang
if [[ -d ~/.go ]]; then
	export GOROOT="$HOME/.go"
	export PATH="$GOROOT/bin:$PATH"
fi

# Ruby bins
if [[ -d ~/.gem/ruby/3.0.0/bin ]]; then
	export PATH="$HOME/.gem/ruby/3.0.0/bin:$PATH"
fi

# Miniconda3
if [[ -d ~/miniconda3 ]]; then
	source ~/miniconda3/etc/profile.d/conda.sh
fi
ctf() {
    # A fast but incomplete alternative to `conda activate ctf`
    _ENV="ctf"
    _PREFIX="$HOME/miniconda3/envs/$_ENV"
    _BINDIR="$_PREFIX/bin"
    if [[ -v SIMPLE_CONDA ]]; then
        export PATH=$(echo $PATH | sed "s|$_BINDIR||g")
        unset CONDA_PREFIX
        unset CONDA_DEFAULT_ENV
        unset CONDA_PROMPT_MODIFIER
        unset SIMPLE_CONDA
        functions[conda]=$functions[orig_conda]
        unset -f orig_conda
    else
        if [[ -v CONDA_PREFIX ]]; then
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
    kubectl completion zsh > $ZINIT_DIR/completions/_kubectl
fi

# Aliases
alias ga="git add -A"
alias gcm="git commit -m"
alias gp="git push"
alias rg="rg --no-ignore-parent -M 200"
alias fd="fd"

if (( $+commands[eza] )) then
	alias ls="eza"
	alias ll="eza -l"
	alias la="eza -la"
fi
if (( $+commands[bat] )) then
	alias cat="bat -p"
fi

__fix_cmds=(ssh tmux)
for cmd in $__fix_cmds; do
    eval "$cmd() {
        /usr/bin/$cmd \"\$@\"
        __reset_title
    }"
done
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
    tunnel() {
        CF_TUNNEL=ctf  # leave blank if you want to use *.trycloudflare.com
        TUNNEL_CMD=$([[ $CF_TUNNEL = "" ]] && echo "" || echo "run $CF_TUNNEL")
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
        sess="tunnel-$host-$port"
        if ! (tmux has-session -t $sess 2>&1 | grep -q "can't find"); then
            tmux at -t $sess
            return 0
        fi
        proxy_port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1])')
        tmux new -s "$sess" \
            "mitmweb --mode reverse:http://$host:$port -p $proxy_port --no-web-open-browser --web-port 4040"\; \
            split-window -v \
            "cloudflared tunnel --url http://localhost:$proxy_port $TUNNEL_CMD"\; \
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

copy() {
    # copy with OSC 52 escape sequence
    # idk why printing to terminal doesn't work with curl...
    # tmux and screen bypass from https://github.com/rumpelsepp/oscclip/
    f=$(mktemp)
    if [[ ! -z $TMUX ]]; then
        printf "\033Ptmux;\033" >> $f
    elif [[ $TERM =~ ^screen ]]; then
        printf "\033P" >> $f
    fi
    printf "\e]52;c;" >> $f
    base64 -w 0 >> $f
    printf "\a" >> $f
    if [[ ! -z $TMUX ]]; then
        printf "\033\\" >> $f
    elif [[ $TERM =~ ^screen ]]; then
        printf "\033\\" >> $f
    fi
    \cat $f
    rm $f
}

msgpackd() {
    python -c '__import__("pprint").pprint(__import__("msgpack").load(__import__("sys").stdin.buffer))'
}

dotenv () {
    set -a
    file=${1:-.env}
    [ -f "$file" ] && source "$file"
    set +a
}

myip () {
    method=$1
    if [[ ! $# -eq 1 ]]; then
        if (( $+commands[curl] )) then
            method="ipinfo"
        elif (( $+commands[bash] )) then
            method="cf1"
        elif (( $+commands[nc] )) then
            method="cf2"
        fi
    fi
    if [[ $method == "cf1" ]]; then
        printf 'GET /cdn-cgi/trace HTTP/1.0\r\nHost: cloudflare.com\r\n\r\n' | nc 1.1.1.1 80 | sed -nE 's/ip=(.*)/\1/p'
    elif [[ $method == "cf2" ]]; then
        bash << EOF
exec 3<>/dev/tcp/1.1.1.1/80
printf 'GET /cdn-cgi/trace HTTP/1.0\r\nHost: cloudflare.com\r\n\r\n' >&3
cat <&3 | sed -nE 's/ip=(.*)/\1/p'
EOF
    elif [[ $method == "ipinfo" ]]; then
        curl -s 'https://ipinfo.io/ip'
        printf '\n'
    else
        printf "Unknown ip query method: $method\n"
        printf "Please choose one from cf1, cf2, ipinfo\n"
        return 1
    fi
}

# P10k Initialize
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

