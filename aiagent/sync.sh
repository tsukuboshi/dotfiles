#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SETTING_PATH="${HOME}/.claude"

# Link setting files
if [ "$(which claude)" != "" ]; then
  echo "Linking to claude..."
  ln -fsvn "${SCRIPT_DIR}/CLAUDE.md" "${CLAUDE_SETTING_PATH}/CLAUDE.md"
  ln -fsvn "${SCRIPT_DIR}/settings.json" "${CLAUDE_SETTING_PATH}/settings.json"
  for file in "${SCRIPT_DIR}"/commands/*; do
    ln -fsvn "$file" "${CLAUDE_SETTING_PATH}/commands/"
  done
fi
