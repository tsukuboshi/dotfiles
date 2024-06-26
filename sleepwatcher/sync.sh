#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Link .sleep
if [ -L "${HOME}/.sleep" ]; then
  ln -fsvn "${SCRIPT_DIR}/.sleep" "${HOME}/.sleep"
fi

# Link .wakeup
if [ -L "${HOME}/.wakeup" ]; then
  ln -fsvn "${SCRIPT_DIR}/.wakeup" "${HOME}/.wakeup"
fi

# Restart sleepwatcher
if [ "$(which sleepwatcher)" != "" ]; then
  brew services restart sleepwatcher
else
  echo "Install sleepwatcher using brew to start the service."
fi
