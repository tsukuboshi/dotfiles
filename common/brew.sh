#!/bin/bash

printf "\n\033[1;36m=== Checking Homebrew ===\033[0m\n"
if command -v brew >/dev/null 2>&1; then
	printf "\033[1;33m✓ Homebrew is already installed\033[0m\n"
else
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

printf "\n\033[1;36m=== Installing packages via brew bundle ===\033[0m\n"
brew bundle --global
