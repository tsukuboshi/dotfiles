# Amazon Q pre block. Keep at the top of this file.
[[ -f "${HOME}/Library/Application Support/amazon-q/shell/bash_profile.pre.bash" ]] && builtin source "${HOME}/Library/Application Support/amazon-q/shell/bash_profile.pre.bash"

# Get the aliases and functions
if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi

# Set the prompt
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

function parse_aws_profile {
  aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | awk -F '/' '{print $3}'
}

export PS1="\n\[\e[1;31m\]\u \[\e[1;32m\]\W \[\e[1;34m\]\$(parse_git_branch) \[\e[1;33m\]$(parse_aws_profile) \[\e[1;35m\]\$ \[\e[0m\]"


# Set the language
export LANG="ja_JP.UTF-8"

# Set brew
if [ "$(which brew)" == "" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set rancher desktop
if [ "$(which rdctl)" == "" ]; then
  export PATH="$HOME/.rd/bin:$PATH"
fi

# Set vscode
if [ "$(which code)" == "" ]; then
  export PATH="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin:$PATH"
fi

# Set mise
if [ "$(which mise)" != "" ]; then
  eval "$(mise activate bash)"
fi

# Set aws-completion
if [ "$(which aws_completer)" != "" ]; then
  complete -C aws_completer aws
fi

# Set git-completion
if [ -r "/usr/local/etc/bash_completion.d/git-completion.sh" ]; then
  source /usr/local/etc/bash_completion.d/git-completion.sh
fi

# Set git-prompt
if [ -r "/usr/local/etc/bash_completion.d/git-prompt.sh" ]; then
  source /usr/local/etc/bash_completion.d/git-prompt.sh
fi

# Set bash-completion
if [ -r "/usr/local/etc/profile.d/bash_completion.sh" ]; then
  source /usr/local/etc/profile.d/bash_completion.sh
fi

# Set Typescript Compiler
if [ "$(which tsc)" == "" ] && [ "$(which npm)" != "" ]; then
  export PATH="$(npm bin -g):$PATH"
fi

#Auto-Complete function for awsume
_awsume() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(awsume-autocomplete)
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}
complete -F _awsume awsume

# OS X or Linux
case $(uname -a) in
  Darwin* )
    # Stop the bash silence deprecation warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

  ;;
esac
