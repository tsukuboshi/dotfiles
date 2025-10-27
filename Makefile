.PHONY: all xcode link defaults brew editor llm runtime sleepwatcher

# Initialize macOS.
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

# Setup editor settings.
editor:
	@printf "\033[1;34mRun editor/sync.sh\033[0m\n"
	@editor/sync.sh

# Setup LLM agent settings.
llm:
	@printf "\033[1;34mRun llm/sync.sh\033[0m\n"
	@llm/sync.sh

# Setup runtime environment.
runtime:
	@printf "\033[1;34mRun runtime/sync.sh\033[0m\n"
	@runtime/sync.sh

# Setup sleepwatcher scripts.
sleepwatcher:
	@printf "\033[1;34mRun sleepwatcher/sync.sh\033[0m\n"
	@sleepwatcher/sync.sh
