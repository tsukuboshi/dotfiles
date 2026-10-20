---
paths:
  - "**/*.{sh,bash}"
---

# Shell Script

- リンタ: `shellcheck`
- フォーマッタ: `shfmt -w`
- 構文ルール: `ast-grep scan --config ~/dotfiles/genai/ast-grep/sgconfig.yml <file>`

`shellcheck` と `shfmt` は sh / bash / dash / ksh のみ対応するため、zsh スクリプト（`.zsh`、および `#!/bin/zsh` の `.sh`）は対象外とする。
`ast-grep` は再帰的な `rm`、`git checkout` などの破壊的な git 操作、ホーム配下の絶対パスを検出する。`settings.json` の `deny` はエージェントが直接実行するコマンドにだけ効き、スクリプトに書いたコマンドには効かないため、ast-grep で補う。Bash の文法で zsh も読めるため、zsh スクリプトも対象にする。
プロジェクトに `sgconfig.yml` があれば、`--config` を付けずにその設定を使う。
