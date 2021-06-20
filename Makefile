# Do everything.
all: brew link default

# Install macOS applications.
brew:
	.bin/brew.sh

# Link dotfiles.
link:
	.bin/link.sh

# Set macOS system preferences.
default:
	.bin/default.sh
