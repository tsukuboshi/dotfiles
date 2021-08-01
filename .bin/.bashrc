# User specific aliases and functions
alias ll='ls -lF'
alias la='ls -lAF'

alias e='export'
alias en='export -n'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias relogin='exec $SHELL -l'

alias rmtrash='rm -rf ${HOME}/.Trash/*'

alias delds='find . -name ".DS_Store" -type f -ls -delete'

alias b="brew"

alias ell='exa -lF'
alias ela='exa -laF'
alias etree='exa -TL'

alias g='git'

alias a='aws'
alias asg='aws sts get-caller-identity'

alias t='terraform'

alias d='docker'
alias dc='docker-compose'

alias k='kubectl'

alias gle="ls -l ${HOME}/Library/Application\ Support/Google/Chrome/Default/Extensions | awk '{print \$9}' | sed 's/^/https:\/\/chrome.google.com\/webstore\/detail\//g' | sed -e '1,2d'"

alias c='code'
alias cle='code --list-extensions'
