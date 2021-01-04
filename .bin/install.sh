#!/bin/bash

# Set environment variables
DOTFILES_DIR="$HOME/Documents/dotfiles"
IGNORE_PATTERN="^\.(bin|etc|git)/"

# Change dotfiles directory
cd "$DOTFILES_DIR" || { echo "Failure"; exit 1; }

# Deploy dotfiles
for dotfile in .??*; do
    # Ignore dotdirectories
    [[ $dotfile =~ $IGNORE_PATTERN ]] && continue

    # Link dotfiles
    ln -fnsv "$DOTFILES_DIR/$dotfile" "$HOME/$dotfile"
done
echo "Success"
