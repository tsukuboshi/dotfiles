#!/bin/bash

# Change dotfiles directory
cd "$(dirname "$0")" || exit

# Deploy dotfiles
for dotfile in .??*; do
    # Ignore unnecessary dotfiles
    [[ "$dotfile" == ".etc" ]] && continue
    [[ "$dotfile" == ".git" ]] && continue
    [[ "$dotfile" == ".github" ]] && continue
    [[ "$dotfile" == ".DS_Store" ]] && continue

    # Link dotfiles
    ln -fnsv "${PWD}/$dotfile" "$HOME/$dotfile"
done
