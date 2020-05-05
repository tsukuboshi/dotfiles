# prompt
export PS1='\e[1;32m\W \t \e[1;31m\u \e[1;32m$ \e[0m'

# japanese
export LANG="ja_JP.UTF-8"

# nodebrew
export PATH=$HOME/.nodebrew/current/bin:$PATH

# rbenv
export PATH="~/.rbenv/shims:/usr/local/bin:$PATH"
eval "$(rbenv init -)"

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

alias vi='vim'

alias vu='vagrant up'
alias vh='vagrant halt'
alias vsp='vagrant suspend'
alias vrs='vagrant resume'
alias vr='vagrant reload'
alias vp='vagrant provision'
alias vd='vagrant destroy'
alias vs='vagrant status'
alias vgs='vagrant global-status'
alias vssh='vagrant ssh'
alias vsshc='vagrant ssh-config'

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
