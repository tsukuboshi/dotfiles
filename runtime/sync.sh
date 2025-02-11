#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Link .tool-versions
if [ -L "${HOME}/mise.toml" ]; then
  ln -fsvn "${SCRIPT_DIR}/mise.toml" "${HOME}/mise.toml"
fi

# Install asdf plugins
if [ "$(which mise)" != "" ]; then
  mise install
else
  echo "Install the mise command"
fi
