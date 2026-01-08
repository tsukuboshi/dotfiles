# Set the prompt
_colorize_prompt() {
  local color=$1
  local text=$2
  echo "%F{${color}}%B${text}%b%f"
}

_parse_username() {
  _colorize_prompt "red" "%n"
}

_parse_current_dir() {
  _colorize_prompt "green" "%1~"
}

_parse_git_branch() {
  local branch=$(git branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    _colorize_prompt "blue" "${branch}"
  fi
}

_parse_aws_profile() {
  local profile=""
  if [ -n "$AWS_PROFILE" ]; then
    profile="$AWS_PROFILE"
  # elif [ -n "$AWSUME_PROFILE" ]; then
  #   profile="$AWSUME_PROFILE"
  fi

  if [ -n "$profile" ]; then
    _colorize_prompt "magenta" "${profile}"
  fi
}

_parse_git_status() {
  local git_status
  git_status=$(git status --porcelain 2>/dev/null)
  local git_exit_code=$?

  if [ $git_exit_code -ne 0 ]; then
    _colorize_prompt "black" "%#"  # not a git repo
    return
  fi

  if [ -z "$git_status" ]; then
    _colorize_prompt "white" "✓"  # clean
    return
  fi

  local status_symbols=""

  # Staged files (M, A, D, R, C in first column)
  if echo "$git_status" | grep -q '^[MADRC]'; then
    status_symbols="${status_symbols}$(_colorize_prompt "cyan" "●")"
  fi

  # Modified files (M in second column)
  if echo "$git_status" | grep -q '^.M'; then
    status_symbols="${status_symbols}$(_colorize_prompt "yellow" "+")"
  fi

  # Deleted files (D in either column)
  if echo "$git_status" | grep -q '^.D\|^D'; then
    status_symbols="${status_symbols}$(_colorize_prompt "red" "✖")"
  fi

  # Untracked files (?? at start)
  if echo "$git_status" | grep -q '^??'; then
    status_symbols="${status_symbols}$(_colorize_prompt "green" "…")"
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
  export PATH="$(npm prefix -g):$PATH"
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

# Show aliases by category
function aliases() {
  local ZLOGIN_FILE="${HOME}/.zlogin"
  [ ! -f "${ZLOGIN_FILE}" ] && echo "Error: ${ZLOGIN_FILE} not found" && return 1

  _list_categories() { grep "^# [A-Z]" "${ZLOGIN_FILE}" | grep -v "^# ====" | sed 's/^# /  - /'; }

  if [[ "$1" =~ ^(-h|--help|help)$ ]]; then
    echo "\nAvailable categories:"; _list_categories
    echo "\nUsage: aliases [keyword] ...\nExample: aliases (show all) | aliases system git"
    return 0
  fi

  # Get categories to show
  local -a categories_to_show
  if [ $# -eq 0 ]; then
    while IFS= read -r line; do
      [[ "$line" =~ ^#\ [A-Z] ]] && [[ ! "$line" =~ ^#\ ====.*====$ ]] && categories_to_show+=("${line#\# }")
    done < "${ZLOGIN_FILE}"
  else
    categories_to_show=("$@")
  fi

  # Show each category
  local exact_match=$([ $# -eq 0 ] && echo 1 || echo 0)
  for category in "${categories_to_show[@]}"; do
    local in_category=0 found=0
    while IFS= read -r line; do
      [[ "$line" =~ ^#\ ====.*====$ ]] && continue

      if [[ "$line" =~ ^#\ [A-Z] ]]; then
        [ $in_category -eq 1 ] && break
        local cat_name="${line#\# }"
        if ([ $exact_match -eq 1 ] && [[ "${cat_name}" == "${category}" ]]) || ([ $exact_match -eq 0 ] && echo "${cat_name}" | grep -qi "${category}"); then
          found=1
          in_category=1
          echo "\n\033[1;34m=== ${cat_name} ===\033[0m"
        fi
      elif [ $in_category -eq 1 ] && [ -n "$line" ]; then
        echo "$line"
      fi
    done < "${ZLOGIN_FILE}"

    [ $found -eq 0 ] && [ $# -gt 0 ] && echo "\nCategory not found: ${category}"
  done

  # Show help if nothing found
  if [ $# -gt 0 ]; then
    for cat in "$@"; do
      _list_categories | grep -qi "${cat}" && echo "" && return 0
    done
    echo "\nAvailable categories:"
    _list_categories
  fi
  echo ""
}
