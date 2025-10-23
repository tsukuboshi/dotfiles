# User specific aliases and functions
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ll='ls -lF'
alias la='ls -lAF'

alias sudo='sudo '

function relogin (){
  local SHELL_TYPE=${1:-/bin/bash}
  exec "${SHELL_TYPE}" -l
}

alias myip='curl inet-ip.info'

alias mysh='echo $0'

alias rmtr='rm -rf ${HOME}/.Trash/*'

alias rmds='find . -name ".DS_Store" -type f -ls -delete'

alias bl='brew list --formula'
alias bo='brew upgrade --dry-run'
alias bg='brew upgrade'
alias bc='brew cleanup'

alias cl='brew list --cask'
alias co='brew upgrade --cask --greedy --dry-run'
alias cg='brew upgrade --cask --greedy'

alias ml='mas list'
alias mo='mas outdated'
alias mg='mas upgrade'

alias al='printf "\n\033[1;36m=== Homebrew Formulae List ===\033[0m\n"; brew list --formula; printf "\n\033[1;36m=== Homebrew Casks List ===\033[0m\n"; brew list --cask; printf "\n\033[1;36m=== App Store Apps List ===\033[0m\n"; mas list'

alias ao='printf "\n\033[1;33m=== Homebrew Formulae Outdated===\033[0m\n"; brew upgrade --dry-run; printf "\n\033[1;33m=== Homebrew Casks Outdated ===\033[0m\n"; brew upgrade --cask --greedy --dry-run; printf "\n\033[1;33m=== App Store Apps Outdated ===\033[0m\n"; mas outdated'

alias ag='printf "\n\033[1;32m=== Homebrew Formulae Upgrade ===\033[0m\n"; brew upgrade; printf "\n\033[1;32m=== Homebrew Casks Upgrade ===\033[0m\n"; brew upgrade --cask --greedy; printf "\n\033[1;32m=== App Store Apps Upgrade ===\033[0m\n"; mas upgrade; printf "\n\033[1;32m=== Homebrew Cleanup ===\033[0m\n"; brew cleanup'

alias as='brew autoupdate start --upgrade --greedy --cleanup --sudo'
alias ad='brew autoupdate delete'

alias bbl='brew bundle list --global --all'
alias bbc='brew bundle check --global --formula'
alias bbi='brew bundle install --global'

function otp (){
  local ITEMID=${1:-AWS}
  op item get ${ITEMID} --otp
}

alias gb='git branch --all'
alias gbl='git branch'
alias gbr='git branch --remote'
function gbd (){
  local LOCAL_BRANCH=$1
  git branch -D "${LOCAL_BRANCH}"
}
alias gst='git status'
alias gfe='git fetch origin'
alias gfea='git fetch --all'
alias gme='git merge origin'
function gpl (){
  local CURRENT_BRANCH=${1:-$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')}
  git pull origin "${CURRENT_BRANCH}"
}
alias gpla='git pull --all'
function gsw (){
  local BRANCH=${1:--}
  git switch "${BRANCH}"
}
function gswc (){
  local CURRENT_BRANCH="${1:-$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')_$(date +%Y%m%d)}"
  git switch -c "${CURRENT_BRANCH}"
}
function grb (){
  local FROM_BRANCH=${1:-main}
  git rebase -i origin/${FROM_BRANCH}
}
function gcpcm (){
  local FROM_BRANCH=${1:-main}
  local TO_BRANCH=${2:-$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')}
  echo "Git pull from ${FROM_BRANCH}..."
  git checkout ${FROM_BRANCH}
  git pull origin ${FROM_BRANCH}
  echo "Git merge to ${TO_BRANCH}..."
  git checkout ${TO_BRANCH}
  git merge ${FROM_BRANCH}
}
function guis (){
  local FILE=${1:-CLAUDE.md}
  git update-index --skip-worktree "${FILE}"
}
function guin (){
  local FILE=${1:-CLAUDE.md}
  git update-index --no-skip-worktree "${FILE}"
}
function gad (){
  local FILE=${1:-.}
  git add "${FILE}"
}
alias gax='git reset HEAD'
function grm (){
  local FILE=$1
  git rm "${FILE}"
}
function gcom (){
  local MESSAGE=${1:-fix}
  git commit -m "${MESSAGE}"
}
function gcoma (){
  local MESSAGE=${1:-fix}
  git commit -m --amend "${MESSAGE}"
}
function gch () {
  local FILE_NAME=${1:-.}
  git checkout "${FILE_NAME}"
}
function gcl () {
  local FILE_NAME=${1:-.}
  git clean -df "${FILE_NAME}"
}
function grs (){
  local FILE_NAME=${1:-.}
  git reset HEAD "${FILE_NAME}"
}
alias gps='git push origin HEAD'
alias gpsf='git push --force-with-lease --force-if-includes origin HEAD'
function gss (){
  local MESSAGE=$1
  git stash save "${MESSAGE}"
}
alias gsu='git stash save -u'
alias gsl='git stash list'
alias gsc='git stash clear'

alias ghc='gh repo create $(basename $(pwd)) --private --push --source .'
alias ghv='gh repo view'
alias ghvw='gh repo view --web'
alias ghpv='gh pr view'
alias ghpvw='gh pr view --web'
alias ghpl='gh pr list --search "involves:@me"'
alias ghplw='gh pr list --search "involves:@me" --web'
alias ghrv='gh run view $(gh run list --branch $(git branch --show-current) --limit 1 --json databaseId --jq ".[0].databaseId")'
alias ghrvw='gh run view $(gh run list --branch $(git branch --show-current) --limit 1 --json databaseId --jq ".[0].databaseId") --web'
function ghch (){
  local PR_NUMBER=$1
  gh pr checkout "${PR_NUMBER}"
}

alias pci='pre-commit install'
alias pcr='pre-commit run -a'
alias pcu='pre-commit autoupdate'

alias mil='mise list'
alias miu='mise upgrade'

alias nrb='npm run build'
alias nrw='npm run watch'
alias nrt='npm run test'
alias nig='npm install -g'
alias nid='npm install -D'
alias ncu='npx -p npm-check-updates  -c "ncu"'
alias ncuu='npx -p npm-check-updates  -c "ncu -u"'

function eap (){
  local PROFILE=${1:-tsukuboshi}
  export AWS_PROFILE=${PROFILE}
}
alias enap='export -n AWS_PROFILE'

function aup (){
  local PROFILE=${1:-tsukuboshi}
  source awsume ${PROFILE}
  exec /bin/bash -l
}

function aupo (){
  local PROFILE=${1:-tsukuboshi}
  source awsume ${PROFILE} --mfa-token `otp`
  exec /bin/bash -l
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

function dib (){
  local IMAGE=${1:-itest}
  docker image build --platform linux/x86_64 -t ${IMAGE} .
}
alias dil='docker image ls -a'
alias dip='docker image prune'
function dcr (){
  local PORT=${1:-80}
  local IMAGE=${2:-itest}
  local CONTAINER=${3:-ctest}
  docker container run --platform linux/x86_64 --name ${CONTAINER} -d -p ${PORT}:80 ${IMAGE}
}
function dce (){
  local CONTAINER=${1:-ctest}
  docker container exec -it ${CONTAINER} bash
}
function dcs () {
  local CONTAINER=${1:-ctest}
  docker container stop $(docker container ls -a --filter="name=${CONTAINER}" --format="{{.ID}}")
}
function dcrm () {
  local CONTAINER=${1:-ctest}
  docker container rm $(docker container ls -a --filter="name=${CONTAINER}" --format="{{.ID}}")
}
alias dcl='docker container ls -a'
alias dcp='docker container prune'
alias dbp='docker builder prune'
alias dsd='docker system df'
alias dsp='docker system prune'
alias dcu='docker compose up -d'
alias dcd='docker compose down'

alias lvsj='ln -fsvn ${HOME}/dotfiles/vscode/settings.json ${HOME}/Library/Application\ Support/Code/User/settings.json'
alias lcsj='ln -fsvn ${HOME}/dotfiles/vscode/settings.json ${HOME}/Library/Application\ Support/Cursor/User/settings.json'
alias vle='code --list-extensions'
alias cle='cursor --list-extensions'
