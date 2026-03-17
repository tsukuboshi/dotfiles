#!/bin/bash
# PostToolUse hook: Run linter/formatter when supported files are edited

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

case "$FILE_PATH" in
  *.tf)
    cd "$(dirname "$FILE_PATH")" && terraform fmt -recursive
    ;;
  *.py)
    ruff check --fix "$FILE_PATH"
    ruff format "$FILE_PATH"
    ;;
  *.ts | *.tsx | *.js | *.jsx)
    biome check --fix "$FILE_PATH"
    ;;
  *.md)
    markdownlint --fix "$FILE_PATH"
    ;;
  *.sh)
    shellcheck "$FILE_PATH"
    ;;
esac

exit 0
