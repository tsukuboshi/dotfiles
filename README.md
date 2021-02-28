dotfiles
====

## Description

Dotfiles for macOS.

&emsp;

## Install

Download installation materials.

```shell
$ git clone git@github.com:kuraboshi/dotfiles.git

$ cd $HOME/dotfiles
```

Install macOS applications.

```shell
$ ./brew.sh
```

Link dotfiles.

```shell
$ ./link.sh
```

Set macOS system preferences.

```shell
$ ./default.sh
```

Set alfred.


```
1. Click "Preferences" tab.
2. Click "Advanced" tab.
3. Click "Set preferences folder…" button.
4. Choose "$HOME/dotfiles/alfred/Alfred.alfredpreferences".
5. Click "Set folder and restart Alfred" button.
```

Set iterm2.


```
1. Click "Preferences" tab.
2. Click "General" tab.
3. Click "Preferences" tab.
4. Turn on "Load preference from a custom folder or URL."
5. Enter "$HOME/dotfiles/iterm/com.googlecode.iterm2.plist".
6. Execute "sudo killall cfprefsd" command.
```

Set visual studio code.

```shell
$ ./vscode/sync.sh
```

(Optional)Set virtual machine.
```shell
$ cd $HOME/dotfiles/vagrant

$ vagrant up
```
