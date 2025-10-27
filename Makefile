# Do everything.
all: xcode link defaults brew

# Set Xcode preference.
xcode:
	@printf "\033[1;34mRun xcode.sh\033[0m\n"
	@common/xcode.sh

# Link common dotfiles.
link:
	@printf "\033[1;34mRun link.sh\033[0m\n"
	@common/link.sh

# Set macOS system preferences.
defaults:
	@printf "\033[1;34mRun defaults.sh\033[0m\n"
	@common/defaults.sh

# Install macOS applications.
brew:
	@printf "\033[1;34mRun brew.sh\033[0m\n"
	@common/brew.sh
