#!/bin/bash

printf "\033[1;36m=== Checking OS ===\033[0m\n"
if [ "$(uname)" != "Darwin" ] ; then
	printf "\033[1;31m✗ Not macOS!\033[0m\n"
	exit 1
fi
printf "\033[1;32m✓ macOS detected\033[0m\n\n"

printf "\033[1;36m=== Installing Homebrew ===\033[0m\n"
if command -v brew >/dev/null 2>&1; then
	printf "\033[1;33m✓ Homebrew is already installed\033[0m\n\n"
else
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	printf "\033[1;32m✓ Homebrew installed successfully\033[0m\n\n"
fi

printf "\033[1;36m=== Installing packages via brew bundle ===\033[0m\n"
brew bundle --global
printf "\033[1;32m✓ Packages installed successfully\033[0m\n"
