#!/bin/bash

printf "\n\033[1;36m=== Checking Homebrew ===\033[0m\n"
if command -v brew >/dev/null 2>&1; then
	printf "\033[1;33m⚠ Homebrew is already installed\033[0m\n"
else
	printf "\033[1;36mInstalling Homebrew...\033[0m\n"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
		printf "\033[1;31m✗ Homebrew installation failed. Exiting...\033[0m\n"
		exit 1
	}
fi

printf "\n\033[1;36m=== Installing packages via brew bundle ===\033[0m\n"
brew bundle --global
