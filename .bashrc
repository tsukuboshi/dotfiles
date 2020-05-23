# prompt
export PS1='\n\[\e[1;31m\]\u \[\e[1;32m\]\W \[\e[1;33m\]\$ \[\e[0m\]'

# japanese
export LANG="ja_JP.UTF-8"

# alias
alias ls='ls -FG'
alias la='ls -aFG'
alias ll='ls -lFG'
alias lla='ls -laFG'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

alias relogin='exec $SHELL -l'

alias d='docker'
alias dc="docker container"
alias di="docker image"
alias dn="docker network"
alias ds="docker system"
alias dv="docker volume"
alias d-c='docker-compose'

alias g='git'
alias ga='git add'
alias gd='git diff'
alias gs='git status'
alias gp='git push'
alias gb='git branch'
alias gst='git status'
alias gco='git checkout'
alias gf='git fetch'
alias gc='git commit'

alias v='vagrant'
alias vu='vagrant up'
alias vh='vagrant halt'
alias vsp='vagrant suspend'
alias vrs='vagrant resume'
alias vr='vagrant reload'
alias vp='vagrant provision'
alias vd='vagrant destroy'
alias vsn='vagrant snapshot'
alias vs='vagrant status'
alias vgs='vagrant global-status'
alias vssh='vagrant ssh'
alias vsshc='vagrant ssh-config'

case `uname -a` in
    Darwin* )

    # stop warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # nodebrew
    export PATH=$HOME/.nodebrew/current/bin:$PATH

    # rbenv
    export PATH="~/.rbenv/shims:/usr/local/bin:$PATH"
    eval "$(rbenv init -)"

    ;;
esac
