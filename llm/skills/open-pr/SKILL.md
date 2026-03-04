---
allowed-tools: Bash(git:*), Bash(open:*), Bash(printf:*), Bash(xxd:*), Bash(sed:*), Bash(tr:*), Glob(.github/*), Glob(${HOME}/dotfiles/.github/*), Read(.github/*), Read(${HOME}/dotfiles/.github/*)
description: "Create PR via GitHub Web UI without gh CLI (Compare Default: current branch, Base Default: main)"
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順で新しいPull Request(PR)をGitHub Web UI経由で作成してください。

1. 引数の解決
2. リモートへのプッシュ
3. コミット履歴の確認
4. ベースブランチとの差分確認
5. PRテンプレートファイルの内容確認
6. PRタイトルとボディの生成
7. PR作成ページをブラウザでオープン

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。未指定の場合はデフォルト値を使用します。

- 第一引数: Compare Branch名（未指定の場合は`git branch --show-current`で現在のブランチ名を取得して使用）
- 第二引数: Base Branch名（未指定の場合は`main`を使用）

# リモートへのプッシュ

以下のコマンドを使用して、Compare Branchをリモートにプッシュします。

```bash
git push -u origin ${Compare Branch}
```

# コミット履歴の確認

以下のコマンドを使用して、Base BranchからCompare Branchまでの全コミットを確認します。

```bash
git log --oneline ${Base Branch or main}...${Compare Branch}
```

# ベースブランチとの差分確認

以下のコマンドを使用して、Base BranchとCompare Branch間の差分を確認します。

```bash
git diff ${Base Branch or main}...${Compare Branch}
```

# PRテンプレートファイルの内容確認

以下の優先順位でGlobを使用してPRテンプレートファイルを検索します：

1. `.github/` 配下で `[Pp][Uu][Ll][Ll]_[Rr][Ee][Qq][Uu][Ee][Ss][Tt]_[Tt][Ee][Mm][Pp][Ll][Aa][Tt][Ee]*` に一致するファイル（優先）
2. `${HOME}/dotfiles/.github/` 配下で同パターンに一致するファイル（フォールバック）

優先度の高いパスでファイルが見つかった場合はそちらのみを使用し、見つからない場合のみフォールバックを確認してください。両方で見つからない場合は、このステップをスキップしてください。

# PRタイトルとボディの生成

コミット履歴、差分、PRテンプレートファイルの内容を元に、以下を生成してください：

- **PRタイトル**: 変更内容を簡潔に表すタイトル
- **PRボディ**: PRテンプレートがある場合はそれに従い、ない場合は変更内容の概要を記載

# PR作成ページをブラウザでオープン

以下のコマンドを使用して、リモートリポジトリのURLを取得します。

```bash
git remote get-url origin
```

取得したURLから、PR作成ページのURLを構築します。

- SSH形式 (`git@github.com:OWNER/REPO.git`) の場合: `https://github.com/OWNER/REPO/compare/${Base Branch or main}...${Compare Branch}?expand=1`
- HTTPS形式 (`https://github.com/OWNER/REPO.git`) の場合: `https://github.com/OWNER/REPO/compare/${Base Branch or main}...${Compare Branch}?expand=1`

生成したPRタイトルとボディをURLエンコードし、`git config user.name`でGitHubユーザー名を取得して、クエリパラメータとして追加します。

```bash
urlencode() { printf '%s' "$1" | xxd -p | tr -d '\n' | sed 's/\(..\)/%\1/g'; }
GITHUB_USER=$(git config user.name)
ENCODED_TITLE=$(urlencode "PRタイトル")
ENCODED_BODY=$(urlencode "PRボディ")
open "https://github.com/OWNER/REPO/compare/${Base Branch or main}...${Compare Branch}?expand=1&title=${ENCODED_TITLE}&body=${ENCODED_BODY}&assignees=${GITHUB_USER}"
```
