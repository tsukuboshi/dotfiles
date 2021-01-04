#!/bin/bash

# Install package maneger

if [ "$(uname)" == 'Darwin' ]; then
  xcode-select --install > /dev/null
  if ! builtin command -v brew > /dev/null; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  brew bundle
fi
