#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MISE_SETTING_PATH="${HOME}/.config/mise/config.toml"

# Link .tool-versions
if [ -L "${MISE_SETTING_PATH}" ]; then
  echo "Linking config.toml to mise..."
  ln -fsvn "${SCRIPT_DIR}/config.toml" "${MISE_SETTING_PATH}"
fi

# Install mise plugins
if [ "$(which mise)" != "" ]; then
  echo "Installing mise plugins..."
  mise install
else
  echo "Install the mise command"
fi
