# Do everything.
all: brew link default

# Install macOS applications.
brew:
	~/dotfiles/brew.sh

# Link dotfiles.
link:
	~/dotfiles/link.sh

# Set macOS system preferences.
default:
	~/dotfiles/default.sh
