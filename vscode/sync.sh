#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VSCODE_SETTING_DIR=~/Library/Application\ Support/Code/User

if [ -L "${VSCODE_SETTING_DIR}/settings.json" ]; then
  ln -fsvn "${SCRIPT_DIR}/settings.json" "${VSCODE_SETTING_DIR}/settings.json"
fi

cat < "${SCRIPT_DIR}/extensions" | while read -r line
do
  code --install-extension "$line"
done
