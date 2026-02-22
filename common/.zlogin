# ============================================================================
# System
# ============================================================================

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ll='ls -lF'
alias la='ls -lAF'

alias rmtr='rm -rf ${HOME}/.Trash/*'
alias rmds='find . -name ".DS_Store" -type f -ls -delete'

function relogin (){
  local SHELL_TYPE=${1:-/bin/zsh}
  exec "${SHELL_TYPE}" -l
}
alias myip='curl inet-ip.info'
alias mysh='echo $0'

alias sudo='sudo '

_BREW_ASKPASS="${XDG_DATA_HOME:-$HOME/.local/share}/homebrew/brew_askpass"

_ensure_askpass() {
  [[ -x "$_BREW_ASKPASS" ]] && return 0
  if ! command -v pinentry-mac &>/dev/null; then
    print -P "%F{red}pinentry-mac not found.%f" >&2
    return 1
  fi
  mkdir -p "${_BREW_ASKPASS:h}"
  cat > "$_BREW_ASKPASS" <<'ASKPASS'
#!/bin/sh
printf "%s\n" \
  "OPTION allow-external-cache" \
  "SETOK OK" "SETCANCEL Cancel" \
  "SETDESC Homebrew needs your admin password to complete the upgrade" \
  "SETPROMPT Enter Password:" \
  "SETTITLE Homebrew Password Request" \
  "GETPIN" | pinentry-mac --no-global-grab --timeout 60 \
  | /usr/bin/awk '/^D / {print substr($0, index($0, $2))}'
ASKPASS
  chmod 0555 "$_BREW_ASKPASS"
}

_with_sudo_gui() {
  if _ensure_askpass; then
    SUDO_ASKPASS="$_BREW_ASKPASS" "$@"
  else
    "$@"
  fi
}

function otp (){
  local ITEMID=${1:-AWS}
  op item get ${ITEMID} --otp
}

_claude_with_mcp (){
  local MCP_CONFIG="${HOME}/.claude/mcps/${1}.json"
  shift
  if [[ -f "${MCP_CONFIG}" ]]; then
    command claude --mcp-config="${MCP_CONFIG}" "$@"
  else
    command claude "$@"
  fi
}

alias claudeb='_claude_with_mcp browser'
alias claudei='_claude_with_mcp infra'

# ============================================================================
# Brew
# ============================================================================

_pkg_header() { print -P "\n%F{$1}%B=== $2 ===%b%f" }

_brew_list()     { _pkg_header cyan "Homebrew Formulae List"; brew list --formula }
_cask_list()     { _pkg_header cyan "Homebrew Casks List"; brew list --cask }
_mas_list()      { _pkg_header cyan "App Store Apps List"; mas list }

_brew_outdated() { _pkg_header yellow "Homebrew Formulae Outdated"; brew upgrade --dry-run }
_cask_outdated() { _pkg_header yellow "Homebrew Casks Outdated"; brew upgrade --cask --greedy --dry-run }
_mas_outdated()  { _pkg_header yellow "App Store Apps Outdated"; mas outdated }

_brew_upgrade()  { _pkg_header green "Homebrew Formulae Upgrade"; brew upgrade }
_cask_upgrade()  { _pkg_header green "Homebrew Casks Upgrade"; brew upgrade --cask --greedy }
_mas_upgrade()   { _pkg_header green "App Store Apps Upgrade"; mas upgrade }

_brew_cleanup()  { _pkg_header green "Homebrew Cleanup"; brew cleanup }

alias bl='_brew_list'
alias bo='_brew_outdated'
alias bg='_brew_upgrade'
alias bc='_brew_cleanup'

alias cl='_cask_list'
alias co='_cask_outdated'
alias cg='_cask_upgrade'

alias ml='_mas_list'
alias mo='_mas_outdated'
alias mg='_mas_upgrade'

alias bcl='_brew_list; _cask_list'
alias bco='_brew_outdated; _cask_outdated'
alias bcg='_with_sudo_gui sudo -A -v; _brew_upgrade; _cask_upgrade; _brew_cleanup; sudo -k'

alias bcml='_brew_list; _cask_list; _mas_list'
alias bcmo='_brew_outdated; _cask_outdated; _mas_outdated'
alias bcmg='_with_sudo_gui sudo -A -v; _brew_upgrade; _cask_upgrade; _mas_upgrade; _brew_cleanup; sudo -k'

alias as='brew autoupdate start --upgrade --greedy --cleanup --sudo'
alias ad='brew autoupdate delete'

alias bbl='brew bundle list --global --all'
alias bbc='brew bundle check --global --formula'
alias bbi='brew bundle install --global'

# ============================================================================
# Git
# ============================================================================

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
function gop (){
  local WEB_URL=$(git remote get-url origin)
  WEB_URL="${WEB_URL%.git}"
  WEB_URL="${WEB_URL/git@github.com:/https://github.com/}"
  local BRANCH=$(git branch --show-current)
  open "${WEB_URL}/tree/${BRANCH}"
}

# ============================================================================
# GitHub
# ============================================================================

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

# ============================================================================
# Mise
# ============================================================================

alias mil='mise list'
alias miu='mise upgrade'

# ============================================================================
# AWS
# ============================================================================

function aps (){
  local PROFILE=${1:-tsukuboshi}
  export AWS_PROFILE=${PROFILE}
}
alias apu='unset AWS_PROFILE'

# function aup() {
#   local PROFILE="tsukuboshi"
#   local USE_MFA=false
#   while getopts "p:m" opt; do
#     case $opt in
#       p) PROFILE="$OPTARG" ;;
#       m) USE_MFA=true ;;
#     esac
#   done
#   shift $((OPTIND - 1))
#   if $USE_MFA; then
#     source awsume ${PROFILE} --mfa-token `otp`
#   else
#     source awsume ${PROFILE}
#   fi
#   exec /bin/zsh -l
# }

function ave() {
  local PROFILE="${AWS_PROFILE}"
  while getopts "p:" opt; do
    case $opt in
      p) PROFILE="$OPTARG" ;;
    esac
  done
  shift $((OPTIND - 1))

  local cmd=$1
  shift 2>/dev/null
  if [[ -n "${aliases[$cmd]}" ]]; then
    aws-vault exec ${PROFILE} -- ${=aliases[$cmd]} "$@"
  else
    aws-vault exec ${PROFILE} -- $cmd "$@"
  fi
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

# ============================================================================
# SAM
# ============================================================================

alias samv='sam validate'
alias samb='sam build'
alias samp='sam deploy'
alias samd='sam destroy'

# ============================================================================
# CDK
# ============================================================================

function cdkin (){
  local LANGUAGE=${1:-typescript}
  cdk init --language ${LANGUAGE}
}
alias cdks='cdk synthesize'
alias cdki='cdk diff'
alias cdkp='cdk deploy'
alias cdkl='cdk list'
alias cdkd='cdk destroy'

# ============================================================================
# Terraform
# ============================================================================

alias tin='terraform init'
alias tf='terraform fmt -recursive'
alias tv='terraform validate'
alias tp='terraform plan'
alias ta='terraform apply'
alias ts='terraform state'
alias td='terraform destroy'

function tdoc (){
  local MODULE_PATH=${1:-.}
  terraform-docs markdown table --output-file README.md --output-mode inject ${MODULE_PATH}
}

# ============================================================================
# Docker
# ============================================================================

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

# ============================================================================
# Code
# ============================================================================

alias lvsj='ln -fsvn ${HOME}/dotfiles/vscode/settings.json ${HOME}/Library/Application\ Support/Code/User/settings.json'
alias vle='code --list-extensions'
alias lcsj='ln -fsvn ${HOME}/dotfiles/vscode/settings.json ${HOME}/Library/Application\ Support/Cursor/User/settings.json'
alias cle='cursor --list-extensions'

function npx (){
  sudo -v && command npx "$@"
}
function npm (){
  sudo -v && command npm "$@"
}
