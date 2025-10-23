# Set the prompt
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

function parse_aws_profile {
  aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null | awk -F '/' '{print $3}'
}

setopt PROMPT_SUBST
PROMPT=$'\n%F{red}%B%n%b %F{green}%B%1~%b %F{blue}%B$(parse_git_branch)%b %F{yellow}%B$(parse_aws_profile)%b %F{magenta}%B%#%b %f'

# Set the language
export LANG="ja_JP.UTF-8"

# Set git
export PATH="/opt/homebrew/bin:$PATH"

# Set pipx
export PATH="$PATH:$HOME/.local/bin"

# Set brew
if [ "$(which brew)" = "" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set rancher desktop
if [ "$(which rdctl)" = "" ]; then
  export PATH="$HOME/.rd/bin:$PATH"
fi

# Set vscode
if [ "$(which code)" = "" ]; then
  export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"
fi

# Set mise
if [ "$(which mise)" != "" ]; then
  eval "$(mise activate zsh)"
fi

# Set Typescript Compiler
if [ "$(which tsc)" = "" ] && [ "$(which npm)" != "" ]; then
  export PATH="$(npm bin -g):$PATH"
fi

# Set zsh-completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit

  autoload -Uz +X bashcompinit
  bashcompinit
fi

# Set aws-completion
if [ "$(which aws_completer)" != "" ]; then
  complete -C aws_completer aws
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
