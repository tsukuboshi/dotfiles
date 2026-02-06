---
allowed-tools: Bash(git:*), Bash(open:*), Bash(printf:*), Bash(xxd:*), Bash(sed:*), Read(.github/*), Read(${HOME}/dotfiles/.github/*)
description: "Create PR via GitHub Web UI without gh CLI (Base Branch Optional)"
argument-hint: [Base Branch]
---

以下の手順で新しいPull Request(PR)をGitHub Web UI経由で作成してください。

1. 現在のブランチ確認
2. リモートへのプッシュ
3. 直前コミットの内容確認
4. ベースブランチとの差分確認
5. PRテンプレートファイルの内容確認
6. PRタイトルとボディの生成
7. PR作成ページをブラウザでオープン

# 現在のブランチ確認

以下のコマンドを使用して、現在のブランチを確認します。

```bash
git branch --show-current
```

# リモートへのプッシュ

以下のコマンドを使用して、現在のブランチをリモートにプッシュします。

```bash
git push -u origin HEAD
```

# 直前コミットの内容確認

以下のコマンドを使用して、現在のブランチにおける直前のコミットの内容を確認します。

```bash
git show HEAD
```

# ベースブランチとの差分確認

以下のコマンドを使用して、ベースブランチと現在のブランチ間の差分を確認します。`ARGUMENT`にはベースブランチ名を入力します。指定がない場合は`main`を使用します。

```bash
git diff ${ARGUMENT:-main}...HEAD
```

# PRテンプレートファイルの内容確認

以下の優先順位でPRテンプレートファイルを確認します：

1. `.github/PULL_REQUEST_TEMPLATE.md`（優先）
2. `${HOME}/dotfiles/.github/PULL_REQUEST_TEMPLATE.md`（フォールバック）

優先度の高いファイルが存在する場合はそちらのみを使用し、存在しない場合のみフォールバックを確認してください。両方存在しない場合は、このステップをスキップしてください。

# PRタイトルとボディの生成

直前コミット、差分、PRテンプレートファイルの内容を元に、以下を生成してください：

- **PRタイトル**: 変更内容を簡潔に表すタイトル
- **PRボディ**: PRテンプレートがある場合はそれに従い、ない場合は変更内容の概要を記載

# PR作成ページをブラウザでオープン

以下のコマンドを使用して、リモートリポジトリのURLを取得します。

```bash
git remote get-url origin
```

取得したURLから、PR作成ページのURLを構築します。`ARGUMENT`にはベースブランチ名を入力します。指定がない場合は`main`を使用します。

- SSH形式 (`git@github.com:OWNER/REPO.git`) の場合: `https://github.com/OWNER/REPO/compare/${ARGUMENT:-main}...BRANCH?expand=1`
- HTTPS形式 (`https://github.com/OWNER/REPO.git`) の場合: `https://github.com/OWNER/REPO/compare/${ARGUMENT:-main}...BRANCH?expand=1`

生成したPRタイトルとボディをURLエンコードして、クエリパラメータとして追加します。

```bash
urlencode() { printf '%s' "$1" | xxd -p | tr -d '\n' | sed 's/\(..\)/%\1/g'; }
ENCODED_TITLE=$(urlencode "PRタイトル")
ENCODED_BODY=$(urlencode "PRボディ")
open "https://github.com/OWNER/REPO/compare/${ARGUMENT:-main}...BRANCH?expand=1&title=${ENCODED_TITLE}&body=${ENCODED_BODY}"
```
