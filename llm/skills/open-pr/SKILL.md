---
allowed-tools: Bash(git:*), Bash(open:*), Bash(printf:*), Bash(xxd:*), Bash(sed:*), Bash(tr:*), Bash(find:*), Read(.github/*), Read(${HOME}/dotfiles/.github/*)
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

- 第一引数: Compare Branch名（未指定の場合は現在のブランチ名を使用）
- 第二引数: Base Branch名（未指定の場合は`main`を使用）

以降のステップで使用する環境変数を設定します。

```bash
BASE_BRANCH="${第二引数:-main}"
if [[ -n "${第一引数}" ]]; then
  COMPARE_BRANCH="${第一引数}"
else
  COMPARE_BRANCH="$(git branch --show-current)"
fi
```

# リモートへのプッシュ

以下のコマンドを使用して、Compare Branchをリモートにプッシュします。

```bash
git push -u origin "${COMPARE_BRANCH}"
```

# コミット履歴の確認

以下のコマンドを使用して、Base BranchからCompare Branchまでの全コミットを確認します。

```bash
git log --oneline "${BASE_BRANCH}...${COMPARE_BRANCH}"
```

# ベースブランチとの差分確認

以下のコマンドを使用して、Base BranchとCompare Branch間の差分を確認します。

```bash
git diff "${BASE_BRANCH}...${COMPARE_BRANCH}"
```

# PRテンプレートファイルの内容確認

以下のコマンドでPRテンプレートファイルを検索し、見つかったファイルをReadで読み取ります。見つからない場合はこのステップをスキップしてください。

```bash
TEMPLATE=$(find .github/ -maxdepth 1 -iname 'pull_request_template*' 2>/dev/null | head -1)
TEMPLATE=${TEMPLATE:-$(find "${HOME}/dotfiles/.github/" -maxdepth 1 -iname 'pull_request_template*' 2>/dev/null | head -1)}
echo "${TEMPLATE}"
```

# PRタイトルとボディの生成

コミット履歴、差分、PRテンプレートファイルの内容を元に、以下を生成してください：

- **PRタイトル**: 変更内容を簡潔に表すタイトル
- **PRボディ**: PRテンプレートがある場合はそれに従い、ない場合は変更内容の概要を記載

# PR作成ページをブラウザでオープン

以下のコマンドでPR作成ページをブラウザで開きます。PRタイトルとボディは前ステップで生成した内容をURLエンコードして埋め込みます。

```bash
REMOTE_URL=$(git remote get-url origin)
REPO_URL="${REMOTE_URL/#git@github.com:/https://github.com/}"
REPO_URL="${REPO_URL%.git}"
urlencode() { printf '%s' "$1" | xxd -p | tr -d '\n' | sed 's/\(..\)/%\1/g'; }
GITHUB_USER=$(git config user.name)
ENCODED_TITLE=$(urlencode "PRタイトル")
ENCODED_BODY=$(urlencode "PRボディ")
open "${REPO_URL}/compare/${BASE_BRANCH}...${COMPARE_BRANCH}?expand=1&title=${ENCODED_TITLE}&body=${ENCODED_BODY}&assignees=${GITHUB_USER}"
```
