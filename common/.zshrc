# Set the prompt
_colorize_text() {
  local color=$1
  local text=$2
  echo "%F{${color}}%B${text}%b%f"
}

_parse_username() {
  _colorize_text "red" "%n"
}

_parse_current_dir() {
  _colorize_text "green" "%1~"
}

_parse_git_branch() {
  local branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    _colorize_text "blue" "${branch}"
  fi
}

_parse_aws_profile() {
  local profile=""
  if [ -n "$AWS_PROFILE" ]; then
    profile="$AWS_PROFILE"
  elif [ -n "$AWSUME_PROFILE" ]; then
    profile="$AWSUME_PROFILE"
  fi

  if [ -n "$profile" ]; then
    _colorize_text "magenta" "${profile}"
  fi
}

_parse_git_status() {
  local git_status
  git_status=$(git status --porcelain 2>/dev/null)
  local git_exit_code=$?

  if [ $git_exit_code -ne 0 ]; then
    _colorize_text "black" "%#"  # not a git repo
    return
  fi

  if [ -z "$git_status" ]; then
    _colorize_text "white" "✓"  # clean
    return
  fi

  local status_symbols=""

  # Staged files (M, A, D, R, C in first column)
  if echo "$git_status" | grep -q '^[MADRC]'; then
    status_symbols="${status_symbols}$(_colorize_text "cyan" "●")"
  fi

  # Modified files (M in second column)
  if echo "$git_status" | grep -q '^.M'; then
    status_symbols="${status_symbols}$(_colorize_text "yellow" "+")"
  fi

  # Deleted files (D in either column)
  if echo "$git_status" | grep -q '^.D\|^D'; then
    status_symbols="${status_symbols}$(_colorize_text "red" "✖")"
  fi

  # Untracked files (?? at start)
  if echo "$git_status" | grep -q '^??'; then
    status_symbols="${status_symbols}$(_colorize_text "green" "…")"
  fi

  echo "${status_symbols}"
}

setopt PROMPT_SUBST

_build_prompt() {
  local result=""
  for func in "$@"; do
    local output=$($func)
    [ -n "$output" ] && result+="${result:+ }${output}"
  done
  echo "\n$result "
}

PROMPT_PARTS=(_parse_username _parse_current_dir _parse_git_branch _parse_aws_profile _parse_git_status)
PROMPT='$(_build_prompt "${PROMPT_PARTS[@]}")'

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

#Auto-Complete function for AWSume
fpath=(~/.awsume/zsh-autocomplete/ $fpath)
