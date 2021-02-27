#!/bin/bash

if [ "$(uname)" != "Darwin" ] ; then
	echo "Not macOS!"
	exit 1
fi

#----------------------------------------------------------
# Base
#----------------------------------------------------------

# 自動大文字の無効化
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

#----------------------------------------------------------
# Dock
#----------------------------------------------------------

# アプリケーション起動時のアニメーションを無効化
defaults write com.apple.dock launchanim -bool false

#----------------------------------------------------------
# Finder
#----------------------------------------------------------

# アニメーションを無効化
defaults write com.apple.finder DisableAllAnimations -bool true

# デフォルトで隠しファイルを表示
defaults write com.apple.finder AppleShowAllFiles -bool true

# 全ての拡張子のファイルを表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# ステータスバーを表示
defaults write com.apple.finder ShowStatusBar -bool true

# パスバーを表示
defaults write com.apple.finder ShowPathbar -bool true

#----------------------------------------------------------
# SystemUIServer
#----------------------------------------------------------

# メニューバーに日付、曜日、24時間、秒数を表示
defaults write com.apple.menuextra.clock DateFormat -string 'EEE d MMM HH:mm'

# メニューバーに割合 (%) を表示
defaults write com.apple.menuextra.battery ShowPercent -string "YES"


for app in "Dock" \
	"Finder" \
	"SystemUIServer"; do
	killall "${app}" &> /dev/null
done
