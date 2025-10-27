#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

printf "\033[1;36m=== Creating symbolic links ===\033[0m\n"
for dotfile in "${SCRIPT_DIR}"/.??* ; do
    [[ "$dotfile" == "${SCRIPT_DIR}/.git" ]] && continue
    [[ "$dotfile" == "${SCRIPT_DIR}/.github" ]] && continue
    [[ "$dotfile" == "${SCRIPT_DIR}/.DS_Store" ]] && continue

    ln -fnsv "$dotfile" "$HOME"
done
printf "\033[1;32m✓ Dotfiles linked successfully\033[0m\n"
