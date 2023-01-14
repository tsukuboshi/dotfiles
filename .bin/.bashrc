# User specific aliases and functions
alias ll='ls -lF'
alias la='ls -lAF'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias relogin='exec $SHELL -l'

alias rmtrash='rm -rf ${HOME}/.Trash/*'

alias delds='find . -name ".DS_Store" -type f -ls -delete'

alias bd='brew update'
alias bg='brew upgrade'
alias bgn='brew upgrade --dry-run'
alias bgc='brew upgrade --cask --greedy'
alias bgcn='brew upgrade --cask --greedy --dry-run'
alias bo='brew outdated'
alias bl='brew list'
alias bd='brew doctor'
alias bbc='brew bundle check --global'
alias bbi='brew bundle install --global'

alias ell='exa -lF'
alias ela='exa -laF'
function etree (){
  local DEPTH=${1:-2}
  exa -TL "${DEPTH}"
}

alias gb='git branch'
alias gba='git branch --all'
alias gs='git status'
function gcl (){
  local URL=$1
  git clone "${URL}"
}
function gbd (){
  local LOCAL_BRANCH=$1
  git branch -d "${LOCAL_BRANCH}"
}
function gf (){
  local REMOTE_BRANCH=${1:-HEAD}
  git fetch origin "${REMOTE_BRANCH}"
}
alias gfa='git fetch --all'
function gm (){
  local TRAKING_BRANCH=${1:-HEAD}
  git merge origin/"${TRAKING_BRANCH}"
}
function gpl (){
  local REMOTE_BRANCH=${1:-HEAD}
  git pull origin "${REMOTE_BRANCH}"
}

function gch (){
  local LOCAL_BRANCH=${1:-main}
  git checkout "${LOCAL_BRANCH}"
}
function gcb (){
  local LOCAL_BRANCH=$1
  git checkout -b "${LOCAL_BRANCH}"
}
function gcbr (){
  local LOCAL_BRANCH=$1
  local REMOTE_BRANCH=$2
  git checkout -b "${LOCAL_BRANCH}" "${REMOTE_BRANCH}"
}
function ga (){
  local FILE=${1:-.}
  git add "${FILE}"
}
alias gax='git reset HEAD'
function gr (){
  local FILE=$1
  git rm "${FILE}"
}
function gcm (){
  local MESSAGE=${1:-fix}
  git commit -m "${MESSAGE}"
}
alias gca='git commit --amend'
alias gcx='git reset --hard HEAD^'
function gps (){
  local REMOTE_BRANCH=${1:-HEAD}
  git push origin "${REMOTE_BRANCH}"
}
alias gpla='git pull --all'
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

alias av='anyenv versions'
alias au='anyenv update'

alias nrb='npm run build'
alias nrw='npm run watch'
alias nrt='npm run test'

function eap (){
  local PROFILE=${1:-tsukuboshi}
  export AWS_PROFILE=${PROFILE}
}
alias enap='export -n AWS_PROFILE'
alias asg='aws sts get-caller-identity'
alias asl='aws sso login'
function ec2exec (){
  local INSTANCE_ID=$1
  aws ssm start-session --target ${INSTANCE_ID}
}
function ecsexec (){
  local CLUSTER_NAME=$1
  local TASK_ID=$2
  local CONTAINER_NAME=$3
  aws ecs execute-command --cluster ${CLUSTER_NAME} --task ${TASK_ID} --container ${CONTAINER_NAME} --interactive --command "/bin/sh"
}

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
function tdoc (){
  local MODULE_PATH=${1:-.}
  terraform-docs markdown table --output-file README.md --output-mode inject ${MODULE_PATH}
}

function otp (){
  local ITEMID=${1:-AWS}
  op item get ${ITEMID} --otp
}

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

alias gle="ls -l ${HOME}/Library/Application\ Support/Google/Chrome/Default/Extensions | awk '{print \$9}' | sed 's/^/https:\/\/chrome.google.com\/webstore\/detail\//g' | sed -e '1,2d'"

alias cle='code --list-extensions'
