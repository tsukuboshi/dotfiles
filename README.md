# dotfiles

&emsp;
## Overview

This repository contains scripts to set macOS.

&emsp;

## Required

- [macOS](https://www.apple.com/jp/macos/big-sur/) - v11.4

&emsp;

## Install

Download installation materials.

```shell
$ cd ~ && git clone https://github.com/tsukuboshi/dotfiles
```

Set macOS.

```shell
$ cd ~/dotfiles && make
```

Set visual studio code.

```
1. Press "shift + command + P" on visual studio code.
2. Search and Click "Command: Install 'code' command in PATH command".
3. Restart visual studio code.
4. Execute "cd dotfiles && ./vscode/sync.sh".
5. If you want to output the current extensions, execute "code --list-extensions > ~/dotfiles/vscode/extensions".
```

Set google chrome.

```
1. Access each URL in "~/dotfiles/chrome/extensions" with Google Chrome.
2. Click "Add Chrome" button.
3. If you want to output the current extensions, execute "ls -l ${HOME}/Library/Application\ Support/Google/Chrome/Default/Extensions | awk '{print \$9}' | sed 's/^/https:\/\/chrome.google.com\/webstore\/detail\//g' | sed -e '1,2d' > ~/dotfiles/chrome/extensions".
```
