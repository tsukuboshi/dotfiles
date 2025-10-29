#!/bin/bash

printf "\n\033[1;36m=== Applying system defaults ===\033[0m\n"

print_result() {
	local description="$1"
	shift
	if "$@" 2>/dev/null; then
		printf "\033[1;32m✓\033[0m %s\n" "$description"
	else
		printf "\033[1;31m✗\033[0m %s\n" "$description"
	fi
}

print_result "Set menu bar to decrease item spacing" defaults write -globalDomain NSStatusItemSpacing -int 12

print_result "Set menu bar to decrease item selection padding" defaults write -globalDomain NSStatusItemSelectionPadding -int 8

print_result "Set menu bar to show battery percentage" defaults write com.apple.controlcenter BatteryShowPercentage -bool true

print_result "Set menu bar to display date, day, and time" defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'

print_result "Set Dock to automatically hide or show" defaults write com.apple.dock autohide -bool true

print_result "Set Dock animation speed to fastest" defaults write com.apple.dock autohide-time-modifier -int 0

print_result "Set Dock display delay to minimum" defaults write com.apple.dock autohide-delay -int 0

print_result "Set Dock to use scale effect for window minimization" defaults write com.apple.dock mineffect -string "scale"

print_result "Set Dock to disable launch animation" defaults write com.apple.dock launchanim -bool false

print_result "Set Finder to show files with all extensions" defaults write -g AppleShowAllExtensions -bool true

print_result "Set Finder to show the full POSIX path as window title" defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

print_result "Set Finder to show hidden files" defaults write com.apple.finder AppleShowAllFiles -bool true

print_result "Set Finder to show path bar" defaults write com.apple.finder ShowPathbar -bool true

print_result "Set Finder to show status bar" defaults write com.apple.finder ShowStatusBar -bool true

print_result "Set Finder to show Tab bar" defaults write com.apple.finder ShowTabView -bool true

print_result "Set screenshot to save location to ~/Pictures/ScreenShot" defaults write com.apple.screencapture location ~/Pictures/ScreenShot

print_result "Set screenshot to disable shadow effect" defaults write com.apple.screencapture disable-shadow -bool true

print_result "Set keyboard to decrease initial key repeat waiting time" defaults write -g InitialKeyRepeat -int 10

print_result "Set keyboard to increase key repeat rate" defaults write -g KeyRepeat -int 1

print_result "Set keyboard to use the Fn key as a standard function key" defaults write -g com.apple.keyboard.fnState -bool true

print_result "Set mouse to increase speed" defaults write -g com.apple.mouse.scaling 1.5

print_result "Set trackpad to increase speed" defaults write -g com.apple.trackpad.scaling 3

print_result "Set LaunchServices to disable application open confirmation dialog" defaults write com.apple.LaunchServices LSQuarantine -bool false

print_result "Set input method to disable live conversion" defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false

printf "\n\033[1;36m=== Restarting affected applications ===\033[0m\n"
for app in "Dock" \
	"Finder" \
	"SystemUIServer" \
	"ControlCenter"; do
	if killall "${app}" 2>/dev/null; then
		printf "\033[1;32m✓ %s restarted\033[0m\n" "${app}"
	else
		printf "\033[1;33m⚠ %s was not running or could not be restarted\033[0m\n" "${app}"
	fi
done
