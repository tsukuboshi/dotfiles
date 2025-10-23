# Set the prompt
function parse_git_branch {
  git branch --show-current 2>/dev/null
}

function parse_aws_profile {
  if [ -n "$AWS_PROFILE" ]; then
    echo "$AWS_PROFILE"
  elif [ -n "$AWS_DEFAULT_PROFILE" ]; then
    echo "$AWS_DEFAULT_PROFILE"
  fi
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
  eval "$(mise activate zsh)"
fi

# Set Typescript Compiler
if ! command -v tsc &>/dev/null && command -v npm &>/dev/null; then
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
if command -v aws_completer &>/dev/null; then
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
