#!/bin/bash

printf "\033[1;36m=== Applying system defaults ===\033[0m\n"

_apply_default() {
	local description="$1"
	shift
	if defaults write "$@" 2>/dev/null; then
		printf "\033[1;32m✓\033[0m %s\n" "$description"
	else
		printf "\033[1;31m✗\033[0m %s\n" "$description"
	fi
}

_apply_default "Show bluetooth in the menu bar" com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

_apply_default "Automatically hide or show the Dock" com.apple.dock autohide -bool true

_apply_default "Avoid creating .DS_Store files on network volumes" com.apple.desktopservices DSDontWriteNetworkStores -bool true

_apply_default "Show the full POSIX path as Finder window title" com.apple.finder _FXShowPosixPathInTitle -bool true

_apply_default "Show hidden files in Finder" com.apple.finder AppleShowAllFiles -bool true

_apply_default "Show path bar in Finder" com.apple.finder ShowPathbar -bool true

_apply_default "Show status bar in Finder" com.apple.finder ShowStatusBar -bool true

_apply_default "Show Tab bar in Finder" com.apple.finder ShowTabView -bool true

_apply_default "Disable application open confirmation dialog" com.apple.LaunchServices LSQuarantine -bool false

_apply_default "Disable live conversion" com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false

_apply_default "Display battery level in the menu bar" com.apple.menuextra.battery ShowPercent -string "YES"

_apply_default "Display date, day, and time in the menu bar" com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'

_apply_default "Increase keyboard initial delay" -g InitialKeyRepeat -int 10

_apply_default "Increase keyboard repeat rate" -g KeyRepeat -int 1

_apply_default "Increase mouse speed" -g com.apple.mouse.scaling 1.5

_apply_default "Use the Fn key as a standard function key" -g com.apple.keyboard.fnState -bool true

_apply_default "Increase trackpad speed" -g com.apple.trackpad.scaling 3

_apply_default "Show files with all extensions" -g AppleShowAllExtensions -bool true

printf "\033[1;36m=== Restarting affected applications ===\033[0m\n"
for app in "Dock" \
	"Finder" \
	"SystemUIServer"; do
	if killall "${app}" 2>/dev/null; then
		printf "\033[1;32m✓ %s restarted\033[0m\n" "${app}"
	else
		printf "\033[1;33m⚠ %s was not running or could not be restarted\033[0m\n" "${app}"
	fi
done
