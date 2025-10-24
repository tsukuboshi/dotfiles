# Set the prompt
function parse_git_branch {
  local branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    echo "%F{blue}%B${branch}%b%f"
  fi
}

function parse_aws_profile {
  local profile=""
  if [ -n "$AWS_PROFILE" ]; then
    profile="$AWS_PROFILE"
  elif [ -n "$AWS_DEFAULT_PROFILE" ]; then
    profile="$AWS_DEFAULT_PROFILE"
  fi

  if [ -n "$profile" ]; then
    echo "%F{magenta}%B${profile}%b%f"
  fi
}

function parse_git_status {
  local git_status
  git_status=$(git status --porcelain 2>/dev/null)
  local git_exit_code=$?

  if [ $git_exit_code -ne 0 ]; then
    echo "%F{black}%B%#%b%f"  # not a git repo
    return
  fi

  if [ -z "$git_status" ]; then
    echo "%F{green}%B✓%b%f"  # clean
    return
  fi

  local status_symbols=""

  # Staged files (M, A, D, R, C in first column)
  if echo "$git_status" | grep -q '^[MADRC]'; then
    status_symbols="${status_symbols}%F{white}●%f"
  fi

  # Modified files (M in second column)
  if echo "$git_status" | grep -q '^.M'; then
    status_symbols="${status_symbols}%F{yellow}+%f"
  fi

  # Deleted files (D in either column)
  if echo "$git_status" | grep -q '^.D\|^D'; then
    status_symbols="${status_symbols}%F{red}✖%f"
  fi

  # Untracked files (?? at start)
  if echo "$git_status" | grep -q '^??'; then
    status_symbols="${status_symbols}%F{cyan}…%f"
  fi

  echo "%B${status_symbols}%b"
}

setopt PROMPT_SUBST
PROMPT=$'\n%F{red}%B%n%b%f %F{green}%B%1~%b%f $(parse_git_branch) $(parse_aws_profile) $(parse_git_status) '

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
