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
①Click "Preferences" Tab.
②Click "Advanced" Tab.
③Click "Set preferences folder…" button.
④Choose "$HOME/dotfiles/alfred/Alfred.alfredpreferences".
⑤Click "Set folder and restart Alfred" button.
```

Set iterm2.


```
①Click "Preferences" Tab.
②Click "General" Tab.
③Click "Preferences" Tab.
④Turn on "Load preference from a custom folder or URL."
⑤Enter "$HOME/dotfiles/iterm/com.googlecode.iterm2.plist".
⑥Execute "sudo killall cfprefsd" command.
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
