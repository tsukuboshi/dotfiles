#!/bin/bash

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi

if xcode-select -p &>/dev/null; then
	echo "Xcode Command Line Tools is already installed."

	echo "Checking for updates..."
	XCODE_UPDATE=$(softwareupdate --list 2>&1 | grep -i "Command Line Tools")

	if [ -n "$XCODE_UPDATE" ]; then
		echo "Update available. Installing updates..."
		softwareupdate --install --all
	else
		echo "Xcode Command Line Tools is up to date."
	fi
else
	echo "Xcode Command Line Tools is not installed. Installing..."
	xcode-select --install

	echo "Waiting for installation to complete..."
	until xcode-select -p &>/dev/null; do
		sleep 5
	done
	echo "Installation completed."
fi
