#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VSCODE_SET_DIR="${HOME}/Library/Application Support/Code/User"

# Link settings.json
if [ -L "${VSCODE_SET_DIR}/settings.json" ]; then
  ln -fsvn "${SCRIPT_DIR}/settings.json" "${VSCODE_SET_DIR}/settings.json"
fi

# Install extensions using the code command
if [ "$(which code)" != "" ]; then
  cat < "${SCRIPT_DIR}/extensions" | while read -r line
  do
    code --install-extension "$line"
  done
else
  echo "Install the code command from the command palette to add your extensions."
fi
