# dotfiles

## Overview

This repository contains scripts to set macOS.

## Required

- [macOS](https://www.apple.com/jp/macos/)

## Install

1. Download installation materials.

```shell
git clone https://github.com/tsukuboshi/dotfiles
```

2. Move to target repository.

```shell
cd dotfiles
```

3. Build macOS from Makefile.

```shell
make
```

4. Additional setup required:

- AI Agent: Follow instructions in `llm/README.md`
- Editor: Follow instructions in `editor/README.md`
- Launcher: Follow instructions in `launcher/README.md`
- Runtime Management: Follow instructions in `runtime/README.md`
- SleepWatcher: Follow instructions in `sleepwatcher/README.md`

## Repository Structure

- `common/`: Setup scripts
- `llm/`: AI agent configurations
- `editor/`: Editor configurations
- `launcher/`: Launcher configurations
- `runtime/`: Runtime Management configurations (Python, Node.js, etc.)
- `sleepwatcher/`: Sleep mode configurations

## References

- [Macの環境をdotfilesでセットアップしてみた改](https://zenn.dev/tsukuboshi/articles/6e82aef942d9af)
- [Macの環境をdotfilesでセットアップしてみた \| DevelopersIO](https://dev.classmethod.jp/articles/joined-mac-dotfiles-customize/)
