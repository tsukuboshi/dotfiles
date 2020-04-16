# プロンプト設定
export PS1='\e[1;32m\W \t \e[1;31m\u \e[1;32m$ \e[0m'

# 日本語設定
export LANG="ja_JP.UTF-8"

# エイリアス設定
alias ls='ls -F'
alias la='ls -aF'
alias ll='ls -lF'
alias lla='ls -laF'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

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
