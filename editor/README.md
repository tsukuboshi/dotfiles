## Required

- [Visual Studio Code](https://code.visualstudio.com/)
- [Cursor]([Cursor](https://www.cursor.com/))

## Install Visual Studio Code

1. Press "shift + command + P" on Visual Studio Code.
2. Search and Click "Command: Install 'code' command in PATH command".
3. Restart visual studio code.
4. Execute vscode sync script.

```bash
 ./editor/vscode.sh
```

5. If you want to output the current extensions, execute code list extensions command.

```bash
code --list-extensions > ~/dotfiles/editor/extensions`.
```

## Install Cursor

1. Press "shift + command + P" on Cursor.
2. Search and Click "Command: Install 'cursor' command in PATH command".
3. Restart Cursor.
4. Execute cursor sync script.

```bash
./editor/cursor.sh
```

6. If you want to output the current extensions, execute code list extensions command.

```bash
cursor --list-extensions > ~/dotfiles/editor/extensions`
```
