---
paths:
  - "**/*.{sh,bash,zsh}"
  - "**/.{zshrc,zshenv,zprofile,zlogin,zlogout}"
---

# Shell Script

- リンタ: `shellcheck`
- フォーマッタ: `shfmt -w`
- 構文ルール: `ast-grep scan --config ~/dotfiles/genai/lint/ast-grep/sgconfig.yml <file>`
- zsh の構文チェック: `zsh -n <file>`

`shellcheck` と `shfmt` は sh / bash / dash / ksh のみ対応するため、zsh スクリプト（`.zsh`、および `#!/bin/zsh` の `.sh`）は対象外とする。
zsh スクリプトと `.zshrc` などの zsh の設定ファイルは、検査するリンタがないため `zsh -n` で構文エラーだけを検出する。
`ast-grep` は再帰的な `rm`、`git checkout` などの破壊的な git 操作、ホーム配下の絶対パスを検出する。`settings.json` の `deny` はエージェントが直接実行するコマンドにだけ効き、スクリプトに書いたコマンドには効かないため、ast-grep で補う。Bash の文法で zsh も読めるため、zsh スクリプトも対象にする。
`.zshrc` などの zsh の起動ファイルは `ast-grep` の対象外とする。対話シェルのショートカットとして破壊的な git 操作を意図して包むことがあるうえ、Rancher Desktop などのツールがホーム配下の絶対パスを書き込むため。
プロジェクトに `sgconfig.yml` があれば、`--config` を付けずにその設定を使う。
