dotfiles
====

&emsp;
## Description

Dotfiles for macOS.

&emsp;

## Install

Download installation materials.

```shell
$ cd ~ && git clone git@github.com:kuraboshi/dotfiles.git
```

Set macOS.

```shell
$ cd ~/dotfiles && make
```

Set alfred.


```
1. Press "command + ," on alfred.
2. Click "Advanced" tab.
3. Click "Set preferences folder…" button.
4. Choose "~/dotfiles/alfred/Alfred.alfredpreferences".
5. Click "Set folder and restart Alfred" button.
```

Set iterm2.


```
1. Press "command + ," on iterm2.
2. Click "General" tab.
3. Click "Preferences" tab.
4. Turn on "Load preference from a custom folder or URL."
5. Enter "~/dotfiles/iterm/com.googlecode.iterm2.plist".
6. Execute "sudo killall cfprefsd".
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
```
