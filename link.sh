#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

for dotfile in .??*; do
    [[ "$dotfile" == ".git" ]] && continue
    [[ "$dotfile" == ".github" ]] && continue
    [[ "$dotfile" == ".DS_Store" ]] && continue

    ln -fnsv "${SCRIPT_DIR}/$dotfile" "$HOME/$dotfile"
done
