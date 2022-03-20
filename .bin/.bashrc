# User specific aliases and functions
alias ll='ls -lF'
alias la='ls -lAF'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias relogin='exec $SHELL -l'

alias rmtrash='rm -rf ${HOME}/.Trash/*'

alias delds='find . -name ".DS_Store" -type f -ls -delete'

alias b='brew'
alias bd='brew update'
alias bg='brew upgrade'
alias bo='brew outdated'
alias bl='brew list'
alias bd='brew doctor'

alias ell='exa -lF'
alias ela='exa -laF'
function etree (){
  local DEPTH=${1:-2}
  exa -TL "${DEPTH}"
}

alias g='git'
alias gs='git status'
function ga (){
  local FILE=${1:-.}
  git add "${FILE}"
}
function gc (){
  local MESSAGE=$1
  git commit -m "${MESSAGE}"
}
alias gps='git push origin main'
alias gpl='git pull origin main'
alias gac='git reset HEAD .'
alias gcc='git reset --hard HEAD~'
function gss (){
  local MESSAGE=$1
  git stash save "${MESSAGE}"
}
alias gsl='git stash list'
function gsa (){
  local STASH_NAME=$1
  git stash apply "${STASH_NAME}"
}
function gsd (){
  local STASH_NAME=$1
  git stash drop "${STASH_NAME}"
}

function eap (){
  local PROFILE=${1:-tf-demo}
  export AWS_PROFILE=${PROFILE}
}
alias enap='export -n AWS_PROFILE'
alias a='aws'
alias asg='aws sts get-caller-identity'

alias t='terraform'
alias ti='aws-vault exec kuraboshi -- terraform init'
alias tf='aws-vault exec kuraboshi -- terraform fmt -recursive'
alias tv='aws-vault exec kuraboshi -- terraform validate'
alias tp='aws-vault exec kuraboshi -- terraform plan'
alias ta='aws-vault exec kuraboshi -- terraform apply'
alias td='aws-vault exec kuraboshi -- terraform destroy'

alias d='docker'
alias db='docker build .'
alias dil='docker image ls'
alias dcl='docker container ls -a'
function dce (){
  local CONTAINER=$1
  docker container exec -it ${CONTAINER} bash
}
alias dip='docker image prune'
alias dcp='docker container prune'
alias dsp='docker system prune --volumes'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

alias k='kubectl'

alias gle="ls -l ${HOME}/Library/Application\ Support/Google/Chrome/Default/Extensions | awk '{print \$9}' | sed 's/^/https:\/\/chrome.google.com\/webstore\/detail\//g' | sed -e '1,2d'"

alias c='code'
alias cle='code --list-extensions'
