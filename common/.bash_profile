# Get the aliases and functions
if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi

# Set the prompt
_colorize_text() {
  local color=$1
  local text=$2
  echo "\[\e[${color}\]${text}\[\e[0m\]"
}

_parse_username() {
  _colorize_text "1;31" "\u"
}

_parse_current_dir() {
  _colorize_text "1;32" "\W"
}

_parse_git_branch() {
  local branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    _colorize_text "1;34" "${branch}"
  fi
}

_parse_aws_profile() {
  local profile=""
  if [ -n "$AWS_PROFILE" ]; then
    profile="$AWS_PROFILE"
  elif [ -n "$AWS_DEFAULT_PROFILE" ]; then
    profile="$AWS_DEFAULT_PROFILE"
  fi

  if [ -n "$profile" ]; then
    _colorize_text "1;35" "${profile}"
  fi
}

_parse_git_status() {
  local git_status
  git_status=$(git status --porcelain 2>/dev/null)
  local git_exit_code=$?

  if [ $git_exit_code -ne 0 ]; then
    _colorize_text "1;30" "#"  # not a git repo
    return
  fi

  if [ -z "$git_status" ]; then
    _colorize_text "1;37" "✓"  # clean
    return
  fi

  local status_symbols=""

  # Staged files (M, A, D, R, C in first column)
  if echo "$git_status" | grep -q '^[MADRC]'; then
    status_symbols="${status_symbols}$(_colorize_text "1;32" "●")"
  fi

  # Modified files (M in second column)
  if echo "$git_status" | grep -q '^.M'; then
    status_symbols="${status_symbols}$(_colorize_text "0;33" "+")"
  fi

  # Deleted files (D in either column)
  if echo "$git_status" | grep -q '^.D\|^D'; then
    status_symbols="${status_symbols}$(_colorize_text "0;31" "✖")"
  fi

  # Untracked files (?? at start)
  if echo "$git_status" | grep -q '^??'; then
    status_symbols="${status_symbols}$(_colorize_text "0;36" "…")"
  fi

  echo "${status_symbols}"
}

export PS1="\n\$(_parse_username) \$(_parse_current_dir) \$(_parse_git_branch) \$(_parse_aws_profile) \$(_parse_git_status) "


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
