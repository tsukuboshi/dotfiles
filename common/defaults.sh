#!/bin/bash

printf "\033[1;36m=== Checking OS ===\033[0m\n"
if [ "$(uname)" != "Darwin" ] ; then
	printf "\033[1;31m✗ Not macOS!\033[0m\n"
	exit 1
fi
printf "\033[1;32m✓ macOS detected\033[0m\n\n"

# Apply system defaults
printf "\033[1;36m=== Applying system defaults ===\033[0m\n"

# Show bluetooth in the menu bar
defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

# Automatically hide or show the Dock
defaults write com.apple.dock autohide -bool true

# Avoid creating `.DS_Store` files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Show the full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Show Tab bar in Finder
defaults write com.apple.finder ShowTabView -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable live conversion
defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false

# Display battery level in the menu bar
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Display date, day, and time in the menu bar
defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'


# Increase keyboard initial delay
defaults write -g InitialKeyRepeat -int 10

# Increase keyboard repeat rate
defaults write -g KeyRepeat -int 1

# Increase mouse speed
defaults write -g com.apple.mouse.scaling 1.5

# Use the Fn key as a standard function key
defaults write -g com.apple.keyboard.fnState -bool true

# Increase trackpad speed
defaults write -g com.apple.trackpad.scaling 3

# Show files with all extensions
defaults write -g AppleShowAllExtensions -bool true

printf "\033[1;32m✓ System defaults applied successfully\033[0m\n\n"

# Restart affected apps
printf "\033[1;36m=== Restarting affected applications ===\033[0m\n"
for app in "Dock" \
	"Finder" \
	"SystemUIServer"; do
	killall "${app}" &> /dev/null
done
printf "\033[1;32m✓ Applications restarted successfully\033[0m\n"
