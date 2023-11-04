# User specific aliases and functions
alias ll='ls -lF'
alias la='ls -lAF'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias relogin='exec $SHELL -l'

alias rmtrash='rm -rf ${HOME}/.Trash/*'

alias delds='find . -name ".DS_Store" -type f -ls -delete'

alias bl='brew list --formula'
alias bo='brew upgrade --dry-run'
alias bg='brew upgrade'

alias cl='brew list --cask'
alias co='brew upgrade --cask --greedy --dry-run'
alias cg='brew upgrade --cask --greedy'

alias ml='mas list'
alias mo='mas outdated'
alias mg='mas upgrade'

alias bbl='brew bundle list --global --all'
alias bbc='brew bundle check --global --formula'
alias bbi='brew bundle install --global'

alias ell='exa -lF'
alias ela='exa -laF'
function etree (){
  local DEPTH=${1:-2}
  exa -TL "${DEPTH}"
}

alias gb='git branch --all'
alias gbl='git branch'
alias gbr='git branch --remote'
function gbd (){
  local LOCAL_BRANCH=$1
  git branch -D "${LOCAL_BRANCH}"
}

alias gs='git status'
function gf (){
  local REMOTE_BRANCH=${1:-HEAD}
  git fetch origin "${REMOTE_BRANCH}"
}
alias gfa='git fetch --all'
function gm (){
  local TRAKING_BRANCH=${1:-HEAD}
  git merge origin "${TRAKING_BRANCH}"
}
function gpl (){
  local REMOTE_BRANCH=${1:-`git branch --contains | cut -d " " -f 2`}
  git pull origin "${REMOTE_BRANCH}"
}
alias gpla='git pull --all'
alias gch="git checkout"
alias gcb="git checkout -b"
function gcbo (){
  local BRANCH=${1}
  git checkout -b ${BRANCH} origin/${BRANCH}
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
function gcma (){
  local MESSAGE=${1:-fix}
  git commit -m --amend "${MESSAGE}"
}
alias gcx='git reset --hard HEAD^'
function gps (){
  local REMOTE_BRANCH=${1:-HEAD}
  git push origin "${REMOTE_BRANCH}"
}
function gss (){
  local MESSAGE=$1
  git stash save "${MESSAGE}"
}
alias gsu='git stash save -u'
alias gsl='git stash list'
alias gsc='git stash clear'

alias pci='pre-commit install'
alias pcr='pre-commit run -a'
alias pcu='pre-commit autoupdate'

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

function awsume (){
  local PROFILE=${1:-tsukuboshi}
  source $(pyenv which awsume) ${PROFILE}
}

alias asg='aws sts get-caller-identity'
alias asl='aws sso login'
function asl (){
  local PROFILE=$1
  aws sso login --profile ${PROFILE}
}
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

alias samv='sam validate'
alias samb='sam build'
alias samp='sam deploy'
alias samd='sam destroy'

function cdkin (){
  local LANGUAGE=${1:-typescript}
  cdk init --language ${LANGUAGE}
}
alias cdks='cdk synthesize'
alias cdki='cdk diff'
alias cdkp='cdk deploy'
alias cdkl='cdk list'
alias cdkd='cdk destroy'

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

function otp (){
  local ITEMID=${1:-AWS}
  if [ "$(which op)" != "" ]; then
    op item get ${ITEMID} --otp
  elif [ "$(which bw)" != "" ]; then
    bw get totp ${ITEMID}
  else
    echo  "Install the password manager command to get your totp."
  fi
}
