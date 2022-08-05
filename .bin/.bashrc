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
function gcl (){
  local URL=$1
  git clone "${URL}"
}
function gcb (){
  local BRANCH=$1
  git checkout -b "${BRANCH}"
}
function ga (){
  local FILE=${1:-.}
  git add "${FILE}"
}
function gc (){
  local MESSAGE=$1
  git commit -m "${MESSAGE}"
}
alias gps='git push origin HEAD'
alias gpl='git pull origin HEAD'
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

alias nrb='npm run build'
alias nrw='npm run watch'
alias nrt='npm run test'

function eap (){
  local PROFILE=${1:-tsukuboshi}
  export AWS_PROFILE=${PROFILE}
}
alias enap='export -n AWS_PROFILE'
alias a='aws'
alias asg='aws sts get-caller-identity'
alias asl='aws sso login'

function cit (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- cdk init --language typescript
}

function cs (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- cdk synth
}
function cb (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- cdk bootstrap
}
function cdf (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- cdk diff
}
function cdp (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- cdk deploy
}
function cds (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- cdk destroy
}

function tin (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform init
}
function tf (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform fmt -recursive
}
function tg (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform get
}
function tc (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform console
}
function tim (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform import
}
function tv (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform validate
}
function tp (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform plan
}
function ta (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform apply
}
function ts (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform state
}
function td (){
  local PROFILE=${1:-tsukuboshi}
  aws-vault exec ${PROFILE} -- terraform destroy
}

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
