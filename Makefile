.PHONY: all xcode link defaults brew editor llm runtime sleepwatcher

# Initialize macOS.
all: xcode link defaults brew

# Set Xcode preference.
xcode:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run xcode.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@common/xcode.sh

# Link common dotfiles.
link:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run link.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@common/link.sh

# Set macOS system preferences.
defaults:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run defaults.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@common/defaults.sh

# Install macOS applications.
brew:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run brew.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@common/brew.sh

# Setup editor settings.
editor:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run editor/sync.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@editor/sync.sh

# Setup LLM agent settings.
llm:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run llm/sync.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@llm/sync.sh

# Setup runtime environment.
runtime:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run runtime/sync.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@runtime/sync.sh

# Setup sleepwatcher scripts.
sleepwatcher:
	@printf "\n\033[1;34m========================================\033[0m\n"
	@printf "\033[1;34m  Run sleepwatcher/sync.sh\033[0m\n"
	@printf "\033[1;34m========================================\033[0m\n"
	@sleepwatcher/sync.sh
