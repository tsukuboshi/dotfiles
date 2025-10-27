#!/bin/bash

printf "\033[1;36m=== Checking OS ===\033[0m\n"
if [ "$(uname)" != "Darwin" ] ; then
	printf "\033[1;31m✗ Not macOS!\033[0m\n"
	exit 1
fi
printf "\033[1;32m✓ macOS detected\033[0m\n\n"

printf "\033[1;36m=== Checking Xcode Command Line Tools ===\033[0m\n"
if xcode-select -p &>/dev/null; then
	printf "\033[1;33m⚠ Xcode Command Line Tools is already installed\033[0m\n"
else
	printf "\033[1;36mInstalling Xcode Command Line Tools...\033[0m\n"
	xcode-select --install

	printf "\033[1;36mWaiting for installation to complete...\033[0m\n"
	until xcode-select -p &>/dev/null; do
		sleep 5
	done
	printf "\033[1;32m✓ Xcode Command Line Tools installed successfully\033[0m\n"
fi
