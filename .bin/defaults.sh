#!/bin/bash

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi

# Automatically hide or show the Dock
defaults write com.apple.dock autohide -bool true

# Avoid creating `.DS_Store` files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Display battery level in the menu bar
defaults write com.apple.menuextra.battery ShowPercent -string "YES"

# Display date, day, and time in the menu bar
defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'

# Set `${HOME}` as the default location for new Finder windows
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

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

# Increase keyboard initial delay
defaults write -g InitialKeyRepeat -int 10

# Increase keyboard repeat rate
defaults write -g KeyRepeat -int 1

# Increase mouse speed
defaults write -g com.apple.mouse.scaling 1.5

# Disable Spelling Correction
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false

# Show files with all extensions
defaults write -g AppleShowAllExtensions -bool true

# Increase trackpad speed
defaults write -g com.apple.trackpad.scaling 3

# Wipe all app icons from the Dock
defaults write com.apple.dock persistent-apps -array

for app in "Dock" \
	"Finder" \
	"SystemUIServer"; do
	killall "${app}" &> /dev/null
done

# References:
# 1. https://qiita.com/djmonta/items/17531dde1e82d9786816
# 2. https://qiita.com/keitean/items/bf82da152fd587fa29ef
# 3. https://qiita.com/dodonki1223/items/2bb296111e561c93035e
