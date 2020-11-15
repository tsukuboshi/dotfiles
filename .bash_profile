# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

# Set the prompt
export PS1='\n\[\e[1;31m\]\u \[\e[1;32m\]\W \[\e[1;33m\]\$ \[\e[0m\]'

# Set the language
export LANG="ja_JP.UTF-8"

# OS X or Linux
case $(uname -a) in
  Darwin* )
    # Stop the bash silence deprecation warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # Set the anyenv
    export PATH="$HOME/.anyenv/bin:$PATH"
    eval "$(anyenv init -)"

  ;;
esac
