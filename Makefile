# Do everything.
all: default link brew

# Set macOS system preferences.
default:
	.bin/default.sh

# Link dotfiles.
link:
	.bin/link.sh

# Install macOS applications.
brew:
	.bin/brew.sh
