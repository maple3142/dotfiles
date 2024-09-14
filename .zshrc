#!/usr/bin/zsh
# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# XDG
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

export RLWRAP_HOME=$XDG_DATA_HOME/rlwrap

# ZInit
ZINIT_DIR=${XDG_DATA_HOME:-${HOME}/.local/share}/zinit
ZINIT_HOME=$ZINIT_DIR/zinit.git
[ ! -d $ZINIT_HOME ] && mkdir -p $ZINIT_DIR
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
source ${ZINIT_HOME}/zinit.zsh

zinit snippet OMZL::history.zsh  # turbo mode would make auto-auggestions not work at start

zinit wait lucid light-mode for \
    OMZL::key-bindings.zsh \
    OMZP::sudo/sudo.plugin.zsh

zinit ice depth=1  # powerlevel10k does not support turbo mode
zinit light romkatv/powerlevel10k

zinit ice wait lucid multisrc'shell/{completion,key-bindings}.zsh' id-as'junegunn/fzf_completions' pick'/dev/null'
zinit light junegunn/fzf

zinit ice wait lucid blockf atload$'
    zstyle \':fzf-tab:complete:(cd|z|cat|bat|ls|eza|rg|fd|grep|vim|code):*\' fzf-preview \'if [[ -d $realpath ]]; then eza -1 --color=always $realpath; elif [[ -f $realpath ]]; then if $(file $realpath | grep -qe text); then head -c 1024 $realpath | bat -p -f --file-name $realpath; else file $realpath; fi; fi \'
    zstyle \':fzf-tab:complete:*:options\' fzf-preview
    zstyle \':fzf-tab:complete:*:argument-1\' fzf-preview
    zstyle \':completion:*\' menu select
'
zinit light Aloxaf/fzf-tab

# use git completion from upstream
gitver="v${$(git version)##*version }"
zinit wait silent lucid atclone"zstyle ':completion:*:*:git:*' script git-completion.bash" atpull'%atclone' for \
    "https://github.com/git/git/raw/$gitver/contrib/completion/git-completion.bash"
zinit wait lucid as'completion' mv'git-completion.zsh -> _git' for \
    "https://github.com/git/git/raw/$gitver/contrib/completion/git-completion.zsh"
unset gitver

zinit from'gh-r' as'program' for \
    pick'jq-*' mv'jq-* -> jq' jqlang/jq \
    pick'ripgrep-*-linux-*' extract mv'*/rg -> rg' BurntSushi/ripgrep \
    pick'eza-linux-*' extract eza-community/eza \
    pick'bat-*-linux-*' extract mv'*/bat -> bat' @sharkdp/bat \
    pick'fd-*-linux-*' extract mv'*/fd -> fd' pick'fd' @sharkdp/fd \
    pick'fzf-*-linux-*' extract mv'*/fzf -> fzf' junegunn/fzf \
    pick'zoxide-*-linux-*' extract atclone'./zoxide init zsh > .zoxide.zsh' atpull'%atclone' src'.zoxide.zsh' atload'alias cd=z' compile'.zoxide.zsh' atload'unalias zi' ajeetdsouza/zoxide \

zinit ice wait lucid
zinit light asdf-vm/asdf

zinit wait lucid light-mode for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" atload'FAST_HIGHLIGHT[chroma-man]=' \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    as'completion' blockf \
        zsh-users/zsh-completions \
        esc/conda-zsh-completion

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
    # need to have `AddKeysToAgent yes` in ~/.ssh/config
    add_key_if_not_exist() {
        ssh-add -l | grep "$(ssh-keygen -lf $1 | head -c 20)" -q || ssh-add $1 2>/dev/null
    }
fi

# Set title
precmd() {
    cwd=${PWD/#$HOME/'~'}
    c=$(printf $cwd | sed -E -e 's|/(\.?)([^/])[^/]*|/\1\2|g' -e 's|~$||' -e 's|/[^/]*$|/|')  # ~/.hidden/folder/apple/orange -> ~/.h/f/a/o -> ~/.h/f/a
    c=$c${cwd##*/}  # concat with basename
    u=${USER//maple3142/🍁}
    printf "\033]0;$u@$HOST: $c\007"
}

# Zsh settings
ZSH_DISABLE_COMPFIX=true
HIST_STAMPS=yyyy-mm-dd
HISTSIZE=500000
SAVEHIST=500000
WORDCHARS='*?_-.[]~&;!#$%^(){}<>|'  # removed = and / then add |
ZLE_SPACE_SUFFIX_CHARS='|&-'
zstyle ':completion:*' menu select
setopt autocd
setopt histignorespace
unsetopt beep
unsetopt nomatch

# Path
export PATH=$HOME/.local/bin:$PATH

# WSL specific
if [[ -v WSL_DISTRO_NAME ]]; then
    # if wslg exists
    if [[ -S /mnt/wslg/.X11-unix/X0 ]]; then
        WSLG_EXIST=0  # 1 means prefer wslg if it exists
    fi
    export WINPATH=$(echo $PATH | tr ':' '\n' | grep '/mnt/c' | tr '\n' ':' | sed 's/.$//')
    export PATH=$(echo $PATH | tr ':' '\n' | grep -v '/mnt/c' | tr '\n' ':' | sed 's/.$//')
    if [[ $(wslinfo --networking-mode) == mirrored ]]; then
        # in mirrored, wsl connect connect to host services using 127.0.0.1
        export HOSTIP=127.0.0.1
    else
        # assumed to be nat mode, the host is the router
        arr=($(ip route show default))
        export HOSTIP=$arr[3]
        unset arr
    fi
    ex() {
        /mnt/c/Windows/explorer.exe $(wslpath -w $1)
    }
    win() {
        [[ $# -ge 1 ]] && PATH=$WINPATH:$PATH $@
    }
    winpath() {
        PATH=$WINPATH:$PATH whence -p "$1"
    }
    clip() {
        iconv -f UTF-8 -t UTF-16LE | /mnt/c/Windows/System32/clip.exe
    }
    __codepath=$(winpath code)
    code() {
        $__codepath $@
    }
    if [[ $WSLG_EXIST != 1 ]]; then
        export DISPLAY=$HOSTIP:0
    fi
fi

# Fix ssh autocomplete
zstyle ':completion:*:ssh:argument-1:*' tag-order hosts
h=()
if [[ -r ~/.ssh/config ]]; then
    h=($h ${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
fi
if [[ $#h -gt 0 ]]; then
    zstyle ':completion:*:(ssh|scp|sftp|rsh|rsync):*' hosts $h
fi
unset h

# Lang
export LANG=en_US.UTF-8

# Editor
export EDITOR=vim

# Colored Man Page
export MANPAGER='less -R --use-color -Dd+r -Du+b'

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --exclude .git --exclude .cfg --ignore-file ~/.config/fzf_fdignore'
export FZF_CTRL_T_COMMAND='fd --exclude .git --exclude .cfg --ignore-file ~/.config/fzf_fdignore'
export FZF_ALT_C_COMMAND='fd --type d --exclude .git --exclude .cfg --ignore-file ~/.config/fzf_fdignore'

# Python (Poetry)
if [[ -d ~/.poetry ]]; then
    export PATH=$HOME/.poetry/bin:$PATH
fi

# Rust (uses rustup)
if [[ -a ~/.cargo/env ]]; then
    source ~/.cargo/env
fi

# Golang
export GOPATH=$XDG_DATA_HOME/go
export GOMODCACHE=$XDG_CACHE_HOME/go/mod
if [[ -d $GOPATH ]]; then
    export PATH=$GOPATH/bin:$PATH
fi
export ASDF_GOLANG_MOD_VERSION_ENABLED=false

# Miniconda3
if [[ -d ~/miniconda3 ]]; then
    source ~/miniconda3/etc/profile.d/conda.sh
fi
ctf() {
    # A fast but incomplete alternative to `conda activate ctf`
    _ENV=ctf
    _PREFIX=$HOME/miniconda3/envs/$_ENV
    _BINDIR=$_PREFIX/bin
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
            echo 'Please deactivate official conda first'
        else
            export PATH=$_BINDIR:$PATH
            export CONDA_PREFIX=$_PREFIX
            export CONDA_DEFAULT_ENV=$_ENV
            export CONDA_PROMPT_MODIFIER="($_ENV)"
            export SIMPLE_CONDA=1
            functions[orig_conda]=$functions[conda]
            conda() { echo 'Please deactivate custom conda first' }
        fi
    fi
}

# CHROME_PATH
if (( $+commands[chromium] )) then
    export CHROME_PATH=$(whence -p chromium)
fi

# Aliases
alias ga='git add'
alias gcm='git commit -m'
alias gp='git push'
alias gs='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias rg='rg --no-ignore-vcs -M 200'
alias fd='fd --no-ignore-vcs'
alias dl='curl -LJO'

# Home git management
alias cfg='git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias cfga='cfg add'
alias cfgcm='cfg commit -m'
alias cfgp='cfg push'
alias cfgs='cfg status'
alias cfgd='cfg diff'
alias cfgds='cfg diff --staged'

if (( $+commands[eza] )) then
    alias ls='eza'
    alias ll='eza -l'
    alias la='eza -la'
fi
if (( $+commands[bat] )) then
    alias cat='bat -p'
fi

# Rclone remember password
if (( $+commands[rclone] )) then
    rclone() {
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
            host=localhost
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
        printf '\033Ptmux;\033' >> $f
    elif [[ $TERM =~ ^screen ]]; then
        printf '\033P' >> $f
    fi
    printf '\e]52;c;' >> $f
    base64 -w 0 >> $f
    printf '\a' >> $f
    if [[ ! -z $TMUX ]]; then
        printf '\033\' >> $f
    elif [[ $TERM =~ ^screen ]]; then
        printf '\033\' >> $f
    fi
    <$f
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
            method=ipinfo
        elif (( $+commands[bash] )) then
            method=cf1
        elif (( $+commands[nc] )) then
            method=cf2
        fi
    fi
    if [[ $method == cf1 ]]; then
        printf 'GET /cdn-cgi/trace HTTP/1.0\r\nHost: cloudflare.com\r\n\r\n' | nc 1.1.1.1 80 | sed -nE 's/ip=(.*)/\1/p'
    elif [[ $method == cf2 ]]; then
        bash << EOF
exec 3<>/dev/tcp/1.1.1.1/80
printf 'GET /cdn-cgi/trace HTTP/1.0\r\nHost: cloudflare.com\r\n\r\n' >&3
cat <&3 | sed -nE 's/ip=(.*)/\1/p'
EOF
    elif [[ $method == ipinfo ]]; then
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
