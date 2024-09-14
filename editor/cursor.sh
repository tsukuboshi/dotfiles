#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CURDOR_SETTING_PATH="${HOME}/Library/Application\ Support/Cursor/User/settings.json"

# Link settings.json to cursor
if [ -e "${CURDOR_SETTING_PATH}" ] || [ -L "${CURDOR_SETTING_PATH}" ]; then
  echo "Linking settings.json to cursor..."
  ln -fsvn "${SCRIPT_DIR}/settings.json" "${CURDOR_SETTING_PATH}"
else
  echo "Cursor settings.json is not found."
fi

# Install extensions to cursor
if [ "$(which "cursor")" != "" ]; then
  echo "Installing extensions to cursor..."
  cat < "${SCRIPT_DIR}/extensions" | while read -r line
  do
    cursor --install-extension "$line"
  done
else
  echo "Cursor command not found."
fi
