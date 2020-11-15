# User specific aliases and functions
alias ls='ls -F'
alias la='ls -AF'
alias ll='ls -lF'
alias lla='ls -lAF'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias exa='exa -F'
alias el='exa -lF'
alias ea='exa -aF'
alias ela='exa -laF'
alias etree='exa -TL'

alias bat='bat -pp'

alias d='docker'
alias dc="docker container"
alias dce="docker container exec -it"
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

alias relogin='exec $SHELL -l'

alias delds='find . -name ".DS_Store" -type f -ls -delete'

alias yrm='yes | rm -r'
