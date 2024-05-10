#!/bin/bash

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi

# ====================
#
# Common
#
# ====================

# Disable the sound effects on boot
defaults write -g com.apple.trackpad.scaling 3

# Increase the mouse speed
defaults write -g com.apple.mouse.scaling 1.5

# Increase the keyboard repeat rate
defaults write -g KeyRepeat -int 1

# Increase the keyboard initial delay
defaults write -g InitialKeyRepeat -int 10

# Disable Spelling Correction
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# Disable make .DS_Store
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# ====================
#
# Finder
#
# ====================

# Show files with all extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Display the status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Display the path bar
defaults write com.apple.finder ShowPathbar -bool true

# ====================
#
# SystemUIServer
#
# ====================

# Display date, day, and time in the menu bar
defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'

# Display battery level in the menu bar
defaults write com.apple.menuextra.battery ShowPercent -string "YES"


for app in "Dock" \
	"Finder" \
	"SystemUIServer"; do
	killall "${app}" &> /dev/null
done
