#!/bin/bash

printf "\n\033[1;36m=== Applying system defaults ===\033[0m\n"

apply_default() {
	local description="$1"
	shift
	if defaults -currentHost write "$@" 2>/dev/null; then
		printf "\033[1;32m✓\033[0m %s\n" "$description"
	else
		printf "\033[1;31m✗\033[0m %s\n" "$description"
	fi
}

apply_default "Set menu bar to decrease item spacing" -globalDomain NSStatusItemSpacing -int 12

apply_default "Set menu bar to decrease item selection padding" -globalDomain NSStatusItemSelectionPadding -int 8

apply_default "Set menu bar to show battery percentage" com.apple.controlcenter BatteryShowPercentage -bool true

apply_default "Set menu bar to display date, day, and time" com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'

apply_default "Set Dock to automatically hide or show" com.apple.dock autohide -bool true

apply_default "Set Dock animation speed to fastest" com.apple.dock autohide-time-modifier -int 0

apply_default "Set Dock display delay to minimum" com.apple.dock autohide-delay -int 0

apply_default "Set Dock to use scale effect for window minimization" com.apple.dock mineffect -string "scale"

apply_default "Set Dock to disable launch animation" com.apple.dock launchanim -bool false

apply_default "Set Finder to show files with all extensions" -g AppleShowAllExtensions -bool true

apply_default "Set Finder to show the full POSIX path as window title" com.apple.finder _FXShowPosixPathInTitle -bool true

apply_default "Set Finder to show hidden files" com.apple.finder AppleShowAllFiles -bool true

apply_default "Set Finder to show path bar" com.apple.finder ShowPathbar -bool true

apply_default "Set Finder to show status bar" com.apple.finder ShowStatusBar -bool true

apply_default "Set Finder to show Tab bar" com.apple.finder ShowTabView -bool true

apply_default "Set screenshot to save location to ~/Pictures/ScreenShot" com.apple.screencapture location ~/Pictures/ScreenShot

apply_default "Set screenshot to disable shadow effect" com.apple.screencapture disable-shadow -bool true

apply_default "Set keyboard to decrease initial key repeat waiting time" -g InitialKeyRepeat -int 10

apply_default "Set keyboard to increase key repeat rate" -g KeyRepeat -int 1

apply_default "Set keyboard to use the Fn key as a standard function key" -g com.apple.keyboard.fnState -bool true

apply_default "Set mouse to increase speed" -g com.apple.mouse.scaling 1.5

apply_default "Set trackpad to increase speed" -g com.apple.trackpad.scaling 3

apply_default "Set LaunchServices to disable application open confirmation dialog" com.apple.LaunchServices LSQuarantine -bool false

apply_default "Set input method to disable live conversion" com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false

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
