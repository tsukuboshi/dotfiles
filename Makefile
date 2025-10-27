# Do everything.
all: xcode link defaults brew

# Set Xcode preference.
xcode:
	@echo "\033[0;34mRun xcode.sh\033[0m"
	@common/xcode.sh
	@echo "\033[0;34mDone.\033[0m"

# Link common dotfiles.
link:
	@echo "\033[0;34mRun link.sh\033[0m"
	@common/link.sh
	@echo "\033[0;32mDone.\033[0m"

# Set macOS system preferences.
defaults:
	@echo "\033[0;34mRun defaults.sh\033[0m"
	@common/defaults.sh
	@echo "\033[0;32mDone.\033[0m"

# Install macOS applications.
brew:
	@echo "\033[0;34mRun brew.sh\033[0m"
	@common/brew.sh
	@echo "\033[0;32mDone.\033[0m"
