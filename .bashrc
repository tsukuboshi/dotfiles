# prompt
export PS1='\n\[\e[1;31m\]\u \[\e[1;32m\]\W \[\e[1;33m\]\$ \[\e[0m\]'

# language
export LANG="ja_JP.UTF-8"

# alias for ls
alias ls='ls -FG'
alias la='ls -aFG'
alias ll='ls -lFG'
alias lla='ls -laFG'

# alias for cd
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# alias for docker
alias d='docker'
alias dc="docker container"
alias dce="docker container exec -it"
alias di="docker image"
alias dn="docker network"
alias ds="docker system"
alias dv="docker volume"
alias d-c='docker-compose'

# alias for git
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

# alias for vagrant
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

# relogin this shell
alias relogin='exec $SHELL -l'

# delete DS_Store
alias delds='find . -name ".DS_Store" -type f -ls -delete'

# delete all files and directories
alias yrm='yes | rm -r'

# OS X or Linux
case `uname -a` in
    Darwin* )

    # stop warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

    #anyenv
    eval "$(anyenv init -)"

    ;;
esac
