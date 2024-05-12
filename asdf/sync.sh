#!/bin/bash

# Link .tool-versions
if [ -L "${HOME}/.tool-versions" ]; then
  ln -fsvn "${SCRIPT_DIR}/.tool-versions" "${HOME}/.tool-versions"
fi

# Install asdf plugins
if [ "$(which asdf)" != "" ]; then
  asdf install
else
  echo "Install the asdf command"
fi
