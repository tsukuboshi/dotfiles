#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VSCODE_SETTING_PATH="${HOME}/Library/Application\ Support/Code/User/settings.json"

# Link settings.json to vscode
if [ -e "${VSCODE_SETTING_PATH}" ] || [ -L "${VSCODE_SETTING_PATH}" ]; then
  echo "Linking settings.json to vscode..."
  ln -fsvn "${SCRIPT_DIR}/settings.json" "${VSCODE_SETTING_PATH}"
else
  echo "VSCode settings.json is not found."
fi

# Install extensions to vscode
if [ "$(which "code")" != "" ]; then
  echo "Installing extensions to vscode..."
  cat < "${SCRIPT_DIR}/extensions" | while read -r line
  do
    code --install-extension "$line"
  done
else
  echo "Code command not found."
fi
