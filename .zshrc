# Homebrew
export PATH=/opt/homebrew/bin:$PATH

# https://github.com/romkatv/gitstatus
# git clone --depth=1 https://github.com/romkatv/gitstatus.git ~/gitstatus
source ~/gitstatus/gitstatus.prompt.zsh

PROMPT='%39F%1~%f ${GITSTATUS_PROMPT:+ $GITSTATUS_PROMPT} %F{%(?.76.196)}%#%f '
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=5000
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt incappendhistory
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

setopt HIST_EXPIRE_DUPS_FIRST
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

# case sensitive completion
autoload -U compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"

# Syntax highlighting
# brew install zsh-syntax-highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Preferred editor for local and remote sessions
export EDITOR='nano'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Custom aliases
alias kcn='kubectl config set-context --current --namespace'
# alias knp= copy value from the documentation
# alias kpr=copy value from the documentation
alias scr='shippy login --silent && shippy get secret http-preproduction-credentials --common'

# Docker
export DOCKER_HOST=unix://${HOME}/.colima/default/docker.sock

__sh_proxy() {

    PROXY_HOST="198.161.14.25"
    PROXY_PORT="8080"
    VPN_INTF="utun1"

    local proxy_url="http://${PROXY_HOST}:${PROXY_PORT}"
    case "$1" in
        on)
            echo "Enabling proxy ${proxy_url} for command line tools"
            export HTTP_PROXY=$proxy_url
            export HTTPS_PROXY="${proxy_url}"
            export http_proxy=$proxy_url
            export https_proxy="${proxy_url}"
            export no_proxy="localhost,127.0.0.0,127.0.1.1,apigw-st.telus.com,apigw-kidc-st.telus.com,local.telus.com,api.preprd.teluslabs.net"
            export GIT_SSH_COMMAND="ssh -o ProxyCommand=\"socat - PROXY:${PROXY_HOST}:%h:%p,proxyport=${PROXY_PORT}\" -o hostname=ssh.github.com -o port=443"
	    npm config set proxy $proxy_url	
	    npm config set https-proxy $proxy_url 
        ;;
        off) 
            echo "Disabling proxy for command line tools"
            unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY GIT_SSH_COMMAND
	    npm config delete http-proxy
	    npm config delete https-proxy
	    npm config delete proxy
        ;;
        prompt)
            if [ -n "${http_proxy}" ]; then
                shift
                echo $@
            fi
        ;;
        *)
            if [ -z "${http_proxy}" ]; then
                echo "Proxy is not set\nUsage: tproxy [on|off]"
            else
                echo "Proxy configured to ${http_proxy}"
            fi
    esac
}

tproxy() {
    which socat >/dev/null || echo "Warning: socat not found, git won't work when VPN is on!"
    __sh_proxy $@
}