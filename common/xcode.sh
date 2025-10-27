#!/bin/bash

printf "\n\033[1;36m=== Checking Xcode Command Line Tools ===\033[0m\n"
if xcode-select -p &>/dev/null; then
	printf "\033[1;33m⚠ Xcode Command Line Tools is already installed\033[0m\n"
else
	printf "\033[1;36mInstalling Xcode Command Line Tools...\033[0m\n"
	xcode-select --install

	printf "\033[1;36mWaiting for installation to complete...\033[0m\n"
	until xcode-select -p &>/dev/null; do
		sleep 5
	done
fi
