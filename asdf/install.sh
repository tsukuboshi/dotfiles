#!/bin/bash

# Install asdf plugins
if [ "$(which asdf)" != "" ]; then
  asdf install
else
  echo "Install the asdf command"
fi
