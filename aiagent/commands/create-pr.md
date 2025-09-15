---
allowed-tools: Bash(gh:*), Bash(git:*), Read(.github/*)
description: "Push a Pull Request Draft (PR Number Optional)"
---

以下の手順で新しいPull request(PR)を作成してください。

1. 直前コミットの内容確認
2. 手本PRの内容確認
3. 新規PRの作成
4. 新規PRのブラウザ確認

# 直前コミットの内容確認

以下のコマンドを使用して、現在のブランチにおける直前のコミットの内容を確認します。

```bash
git show HEAD
```

# 手本PRの内容確認

以下のコマンドを使用して、手本PRの内容を確認します。`ARGUMENT`にはPRの番号を入力します。

```bash
gh pr view $ARGUMENT
```

もし`ARGUMENT`が空の場合は、このステップはスキップしてください。

# PRテンプレートファイルの内容確認

`.github/PULL_REQUEST_TEMPLATE.md`または`${HOME}/dotfiles/.github/PULL_REQUEST_TEMPLATE.md`が存在する場合のみファイルを読み取り、PRテンプレートファイルの内容を確認します。

もし両方のファイルが存在しない場合は、このステップはスキップしてください。

# 新規PRの作成

直前コミット、手本PR、PRテンプレートファイルの内容を元に、以下のコマンドを使用して新規PRを作成します。

```bash
gh pr create --draft --assignee @me --base main --title "<直前コミット/手本PRを参考にPRタイトルを作成してください>" --body "<直前コミット/手本PR/PRテンプレートファイルを参考にPR内容を作成してください>"
```

## 新規PRのブラウザ確認

以下のコマンドを使用して、作成した新規PRをブラウザで開きます。

```bash
gh pr view --web
```
