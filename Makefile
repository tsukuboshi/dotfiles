# Do everything.
all: link default brew

# Link dotfiles.
link:
	.bin/link.sh

# Set macOS system preferences.
default:
	.bin/default.sh

# Install macOS applications.
brew:
	.bin/brew.sh
