# Get the aliases and functions
if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi

# Set the prompt
function parse_git_branch {
  git symbolic-ref --short HEAD 2>/dev/null
}

function parse_aws_profile {
  if [ -n "$AWS_PROFILE" ]; then
    echo "$AWS_PROFILE"
  elif [ -n "$AWS_DEFAULT_PROFILE" ]; then
    echo "$AWS_DEFAULT_PROFILE"
  fi
}

export PS1="\n\[\e[1;31m\]\u \[\e[1;32m\]\W \[\e[1;34m\]\$(parse_git_branch) \[\e[1;33m\]$(parse_aws_profile) \[\e[1;35m\]\$ \[\e[0m\]"


# Set the language
export LANG="ja_JP.UTF-8"

# Set bracket mode off on vscode
bind 'set enable-bracketed-paste off'

# Set git
export PATH="/opt/homebrew/bin:$PATH"

# Set pipx
export PATH="$PATH:$HOME/.local/bin"

# Set brew
if ! command -v brew &>/dev/null; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set rancher desktop
if ! command -v rdctl &>/dev/null; then
  export PATH="$HOME/.rd/bin:$PATH"
fi

# Set vscode
if ! command -v code &>/dev/null; then
  export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
fi

# Set mise
if command -v mise &>/dev/null; then
  eval "$(mise activate bash)"
fi

# Set aws-completion
if command -v aws_completer &>/dev/null; then
  complete -C aws_completer aws
fi

# Set bash-completion
if [ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]; then
  source "/opt/homebrew/etc/profile.d/bash_completion.sh"
fi

# Set Typescript Compiler
if ! command -v tsc &>/dev/null && command -v npm &>/dev/null; then
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
