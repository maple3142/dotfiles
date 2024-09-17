#!/usr/bin/zsh
# Powerlevel10k Instant Prompt
_P10K_CACHE_SUFFIX="-$TERM-${TERM_PROGRAM:-unknown}"
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}${_P10K_CACHE_SUFFIX}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}${_P10K_CACHE_SUFFIX}.zsh"
fi

# XDG
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

export RLWRAP_HOME=$XDG_DATA_HOME/rlwrap

# Path
if [[ $UID != 0 ]]; then
    path=(${path:#*/sbin*})
fi
prepend_path() {
    # prepend path if not exist
    if ! (($path[(Ie)$1])); then
        path=($1 $path)
    fi
}
if [[ -d ~/.local/bin ]]; then
    prepend_path $HOME/.local/bin
fi

# WSL specific
if [[ -v WSL_DISTRO_NAME ]]; then
    winpath=(${(M)path:#/mnt/c*})
    path=(${path:#/mnt/c*})
    local wslnmfile=/tmp/wsl_networking_mode
    if [[ ! -f $wslnmfile ]]; then
        # cache wsl networking mode to avoid calling external process in zshrc
        wslinfo --networking-mode > $wslnmfile
    fi
    if [[ $(<$wslnmfile) == mirrored ]]; then
        # in mirrored, wsl connect connect to host services using 127.0.0.1
        export HOSTIP=127.0.0.1
    else
        # assumed to be nat mode, the host is the router
        () {
            arr=($(ip route show default))
            export HOSTIP=$arr[3]
        }
    fi
    ex() {
        local arg=${1:-.}
        /mnt/c/Windows/explorer.exe $(wslpath -w $arg)
    }
    win() {
        path=($winpath $path) $@
    }
    winpath() {
        path=($winpath $path) whence -p "$1"
    }
    clip() {
        iconv -f UTF-8 -t UTF-16LE | /mnt/c/Windows/System32/clip.exe
    }
    if (( ! $+commands[code] )); then
        # Recommended solution: sudo ln -s "$(winpath code)" /usr/local/bin/code
        () {
            # special vscode fast path, as win function is slow
            local codepath=$(winpath code)
            eval "code() { '$codepath' \$@ }"
        }
    fi
    PREFER_X11=${PREFER_X11:-0}
    if [[ ! -S /tmp/.X11-unix/X0 ]] || [[ $PREFER_X11 == 1 ]]; then
        export DISPLAY=$HOSTIP:0
    else
        export DISPLAY=:0
    fi
fi

# ZSHRC
ZSHRC_DIR=$XDG_CONFIG_HOME/zshrc
ZSHRC_SNIPPETS_DIR=$XDG_CONFIG_HOME/zshrc/snippets
ZSHRC_PLUGINS_DIR=$XDG_CONFIG_HOME/zshrc/plugins
ZSHRC_COMPLETIONS_DIR=$XDG_CONFIG_HOME/zshrc/completions
[[ ! -d $ZSHRC_SNIPPETS_DIR ]] && mkdir -p $ZSHRC_SNIPPETS_DIR
[[ ! -d $ZSHRC_PLUGINS_DIR ]] && mkdir -p $ZSHRC_PLUGINS_DIR
[[ ! -d $ZSHRC_COMPLETIONS_DIR ]] && mkdir -p $ZSHRC_COMPLETIONS_DIR

# ZInit
ZINIT_DIR=${XDG_DATA_HOME:-${HOME}/.local/share}/zinit
ZINIT_HOME=$ZINIT_DIR/zinit.git
[ ! -d $ZINIT_HOME ] && mkdir -p $ZINIT_DIR
# [ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
# source ${ZINIT_HOME}/zinit.zsh
# still used for downloading programs
zinit() {
    source ${ZINIT_HOME}/zinit.zsh && zinit $@
}

autoload compinit

source $ZSHRC_SNIPPETS_DIR/omzl-history.zsh  # this sets some history options, so it can't be deferred
source $ZSHRC_PLUGINS_DIR/powerlevel10k/powerlevel10k.zsh-theme  # theme, can't be deferred
source $ZSHRC_PLUGINS_DIR/zsh-defer/zsh-defer.plugin.zsh  # defer itself can't be deferred

zsh-defer source $ZSHRC_SNIPPETS_DIR/omzl-key-bindings.zsh
zsh-defer source $ZSHRC_SNIPPETS_DIR/omzp-sudo.zsh
zsh-defer source $ZSHRC_SNIPPETS_DIR/fzf-key-bindings.zsh

zsh-defer source $ZSHRC_PLUGINS_DIR/fzf-tab/fzf-tab.plugin.zsh
zsh-defer -c $'
    zstyle \':fzf-tab:complete:(cd|z|cat|bat|ls|eza|rg|fd|grep|vim|code):*\' fzf-preview \'if [[ -d $realpath ]]; then eza -1 --color=always $realpath; elif [[ -f $realpath ]]; then if $(file $realpath | grep -qe text); then head -c 1024 $realpath | bat -p -f --file-name $realpath; else file $realpath; fi; fi \'
    zstyle \':fzf-tab:complete:*:options\' fzf-preview
    zstyle \':fzf-tab:complete:*:argument-1\' fzf-preview
    zstyle \':completion:*\' menu select
'

zsh-defer source $ZSHRC_PLUGINS_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
zsh-defer -c 'FAST_HIGHLIGHT[chroma-man]='

ZSH_AUTOSUGGEST_MANUAL_REBIND=1
zsh-defer source $ZSHRC_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh

zsh-defer source $ZSHRC_PLUGINS_DIR/asdf/asdf.sh

USE_UPSTREAM_GIT_COMPLETION=${USE_UPSTREAM_GIT_COMPLETION:-0}
if [[ $USE_UPSTREAM_GIT_COMPLETION != 0 ]]; then
    () {
        local gitver="v${$(git version)##*version }"
        if [[ ! -f $ZSHRC_COMPLETIONS_DIR/git$gitver ]]; then
            curl -sS https://raw.githubusercontent.com/git/git/$gitver/contrib/completion/git-completion.bash > $ZSHRC_COMPLETIONS_DIR/git-completion.bash
            curl -sS https://raw.githubusercontent.com/git/git/$gitver/contrib/completion/git-completion.zsh > $ZSHRC_COMPLETIONS_DIR/_git
            zcompile $ZSHRC_COMPLETIONS_DIR/_git
            touch $ZSHRC_COMPLETIONS_DIR/git$gitver
        fi
        zstyle ':completion:*:*:git:*' script $ZSHRC_COMPLETIONS_DIR/git-completion.bash
    }
fi

fpath=($ZSHRC_COMPLETIONS_DIR $ZSHRC_PLUGINS_DIR/asdf/completions $ZSHRC_PLUGINS_DIR/zsh-completions/src $ZSHRC_PLUGINS_DIR/conda-zsh-completion $fpath)
zsh-defer -c compinit

(( $+commands[jq] )) || zinit from'gh-r' as'program' for pick'jq-*' mv'jq-* -> jq' jqlang/jq
(( $+commands[rg] )) || zinit from'gh-r' as'program' for pick'ripgrep-*-linux-*' extract mv'*/rg -> rg' BurntSushi/ripgrep
(( $+commands[eza] )) || zinit from'gh-r' as'program' for pick'eza-linux-*' extract eza-community/eza
(( $+commands[bat] )) || zinit from'gh-r' as'program' for pick'bat-*-linux-*' extract mv'*/bat -> bat' @sharkdp/bat
(( $+commands[fd] )) || zinit from'gh-r' as'program' for pick'fd-*-linux-*' extract mv'*/fd -> fd' pick'fd' @sharkdp/fd
(( $+commands[fzf] )) || zinit from'gh-r' as'program' for pick'fzf-*-linux-*' extract junegunn/fzf
(( $+commands[zoxide] )) || zinit from'gh-r' as'program' for pick'zoxide-*-linux-*' extract ajeetdsouza/zoxide

# GPG TTY
export GPG_TTY=$TTY

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
USER_NICK=${${(%):-%n}:/maple3142/🍁}
set_title() {
    local cwd=${PWD/#$HOME/'~'}
    # ~/.hidden/folder/apple/orange -> ~/.h/f/a/orange
    local parts=("${(@s|/|)cwd}")  # split by /, and keep empty parts
    for (( i = 1; i < ${#parts}; i++ )); do
        [[ ${parts[i]} =~ '(\.?.)' ]] && parts[i]=${match[1]}
    done
    printf "\033]0;$USER_NICK@$HOST: ${(j:/:)parts}\007"
}
add-zsh-hook precmd set_title

# Zsh settings
ZSH_DISABLE_COMPFIX=true
HIST_STAMPS=yyyy-mm-dd
HISTSIZE=500000
SAVEHIST=500000
WORDCHARS='*?_-.[]~&;!#$%^(){}<>|'  # removed = and / then add |
ZLE_SPACE_SUFFIX_CHARS='|&-'
READNULLCMD=cat
zstyle ':completion:*' menu select
setopt autocd
setopt histignorespace
unsetopt beep
unsetopt nomatch

# Home & End key
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line

# Fix ssh autocomplete
() {
    zstyle ':completion:*:ssh:argument-1:*' tag-order hosts
    local h=()
    if [[ -r ~/.ssh/config ]]; then
        h=($h ${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*[*?]*})
    fi
    if [[ $#h -gt 0 ]]; then
        zstyle ':completion:*:(ssh|scp|sftp|rsh|rsync):*' hosts $h
    fi
}

# Lang
export LANG=en_US.UTF-8

# Editor
export EDITOR=vim

# Colored Man Page
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT='-c'

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --exclude .git --exclude .cfg --ignore-file ~/.config/fzf_fdignore'
export FZF_CTRL_T_COMMAND='fd --exclude .git --exclude .cfg --ignore-file ~/.config/fzf_fdignore'
export FZF_ALT_C_COMMAND='fd --type d --exclude .git --exclude .cfg --ignore-file ~/.config/fzf_fdignore'

# Python (Poetry)
if [[ -d ~/.poetry ]]; then
    prepend_path $HOME/.poetry/bin
fi

# Rust (uses rustup)
if [[ -a ~/.cargo/bin ]]; then
    prepend_path $HOME/.cargo/bin
fi

# Golang
export GOPATH=$XDG_DATA_HOME/go
export GOMODCACHE=$XDG_CACHE_HOME/go/mod
if [[ -d $GOPATH ]]; then
    prepend_path $GOPATH/bin
fi
export ASDF_GOLANG_MOD_VERSION_ENABLED=false

# Miniconda3
if [[ -d ~/miniconda3 ]]; then
    zsh-defer source ~/miniconda3/etc/profile.d/conda.sh
fi

ctf() {
    # A fast but incomplete alternative to `conda activate ctf`
    local _ENV=ctf
    local _PREFIX=$HOME/miniconda3/envs/$_ENV
    local _BINDIR=$_PREFIX/bin
    if [[ -v SIMPLE_CONDA ]]; then
        path=(${path:#$_BINDIR})
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
            path=($_BINDIR $path)
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

if (( $+commands[zoxide] )) then
    ZOXIDE_DIR=$XDG_DATA_HOME/zoxide
    if [[ ! -d $ZOXIDE_DIR ]]; then
        mkdir -p $ZOXIDE_DIR
    fi
    if [[ ! -f $ZOXIDE_DIR/init.zsh ]]; then
        zoxide init zsh > $ZOXIDE_DIR/init.zsh
        zcompile $ZOXIDE_DIR/init.zsh
    fi
    alias zi >/dev/null && unalias zi
    source $ZOXIDE_DIR/init.zsh
    alias cd=z
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
        local CF_TUNNEL=ctf  # leave blank if you want to use *.trycloudflare.com
        local TUNNEL_CMD=$([[ $CF_TUNNEL = "" ]] && echo "" || echo "run $CF_TUNNEL")
        if [[ $# -eq 1 ]]; then
            local host=localhost
            local port=$1
        elif [[ $# -eq 2 ]]; then
            local host=$1
            local port=$2
        else
            echo "Syntax: $0 [port] or $0 [host] [port]"
            return 1
        fi
        local sess="tunnel-$host-$port"
        if tmux has-session -t $sess >/dev/null 2>&1; then
            tmux at -t $sess
            return 0
        fi
        local proxy_port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1])')
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
    local host=$1
    local port=$2
    ssh -R $port:0.0.0.0:$port $host -N &
    nc -lv $port
    kill -9 $!
}

copy() {
    # copy with OSC 52 escape sequence
    # idk why printing to terminal doesn't work with curl...
    # tmux and screen bypass from https://github.com/rumpelsepp/oscclip/
    local f=$(mktemp)
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
    local file=${1:-.env}
    [ -f "$file" ] && source "$file"
    set +a
}

myip () {
    local method=$1
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
