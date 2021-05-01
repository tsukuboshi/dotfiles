# Do everything.
all: brew link default

# Install macOS applications.
brew:
	./brew.sh

# Link dotfiles.
link:
	./link.sh

# Set macOS system preferences.
default:
	./default.sh
