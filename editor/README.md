## Required

- [Visual Studio Code](https://code.visualstudio.com/)
- [Cursor]([Cursor](https://www.cursor.com/))

## Setup Visual Studio Code

1. Press "shift + command + P" on Visual Studio Code.
2. Search and Click "Command: Install 'code' command in PATH command".
3. Restart visual studio code.
4. Execute editor setup script with the editor option set to vscode.

```bash
 ./editor/setup.sh -e vscode
```

5. If you want to output the current extensions, execute code list extensions command.

```bash
code --list-extensions > ~/dotfiles/editor/extensions`.
```

## Set up Cursor

1. Press "shift + command + P" on Cursor.
2. Search and Click "Command: Install 'cursor' command in PATH command".
3. Restart Cursor.
4. Execute editor setup script with the editor option set to cursor.

```bash
./editor/setup.sh -e cursor
```

5. If you want to output the current extensions, execute code list extensions command.

```bash
cursor --list-extensions > ~/dotfiles/editor/extensions`
```
