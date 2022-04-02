# Get the aliases and functions
if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi

# Set the prompt
export PS1='\n\[\e[1;31m\]\u \[\e[1;32m\]\W \[\e[1;33m\]\$ \[\e[0m\]'

# Set the language
export LANG="ja_JP.UTF-8"

# Set brew
if [ "$(which brew)" == "" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set vscode
if [ "$(which code)" == "" ]; then
  export PATH="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin:$PATH"
fi

# Set Typescript Compiler
if [ "$(which tsc)" == "" ]; then
  export PATH="$(npm bin -g):$PATH"
fi

# Set anyenv
if [ "$(which anyenv)" != "" ]; then
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
fi
# Set aws-completion
if [ "$(which aws_completer)" != "" ]; then
  complete -C aws_completer aws
fi

# Set terraform-completion
if [ "$(which terraform)" != "" ]; then
  complete -C $HOME/.anyenv/envs/tfenv/versions/1.0.0/terraform terraform
fi

# Set bash-completion
if [ -r "/usr/local/etc/profile.d/bash_completion.sh" ]; then
  source /usr/local/etc/profile.d/bash_completion.sh
fi

# Set git-completion
if [ -r "/usr/local/etc/bash_completion.d/git-completion.sh" ]; then
  source /usr/local/etc/bash_completion.d/git-completion.sh
fi

# Set git-prompt
if [ -r "/usr/local/etc/bash_completion.d/git-prompt.sh" ]; then
  source /usr/local/etc/bash_completion.d/git-prompt.sh
fi

# OS X or Linux
case $(uname -a) in
  Darwin* )
    # Stop the bash silence deprecation warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

  ;;
esac
