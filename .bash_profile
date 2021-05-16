# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# Set the prompt
export PS1='\n\[\e[1;31m\]\u \[\e[1;32m\]\W \[\e[1;33m\]\$ \[\e[0m\]'

# Set the language
export LANG="ja_JP.UTF-8"

# Set anyenv
if [ "$(which anyenv)" != "" ]; then
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
fi

# Set aws-completion
if [ "$(which aws_completer)" != "" ]; then
  complete -C aws_completer aws
fi

# Set bash-completion
[ -f "/usr/local/etc/profile.d/bash_completion.sh" ] && . "/usr/local/etc/profile.d/bash_completion.sh"

# Set git-completion
[ -f "/usr/local/etc/bash_completion.d/git-completion.sh" ] && . "/usr/local/etc/bash_completion.d/git-completion.sh"

# Set git-prompt
[ -f "/usr/local/etc/bash_completion.d/git-prompt.sh" ] && . "/usr/local/etc/bash_completion.d/git-prompt.sh"

# OS X or Linux
case $(uname -a) in
  Darwin* )
    # Stop the bash silence deprecation warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

  ;;
esac
