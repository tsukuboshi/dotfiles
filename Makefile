# Do everything.
all: brew link default

# Install macOS applications.
brew:
	cd ~/dotfiles && ./brew.sh

# Link dotfiles.
link:
	cd ~/dotfiles && ./link.sh

# Set macOS system preferences.
default:
	cd ~/dotfiles && ./default.sh
