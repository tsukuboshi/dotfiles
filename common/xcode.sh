#!/bin/bash

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi

if xcode-select -p &>/dev/null; then
	echo "Xcode Command Line Tools is already installed."
else
	echo "Xcode Command Line Tools is not installed. Installing..."
	xcode-select --install

	echo "Waiting for installation to complete..."
	until xcode-select -p &>/dev/null; do
		sleep 5
	done
	echo "Installation completed."
fi
