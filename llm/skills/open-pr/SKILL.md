---
description: "Create PR via GitHub Web UI without gh CLI (Compare Default: current branch, Base Default: main)"
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順で新しいPull Request(PR)をGitHub Web UI経由で作成してください。

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。

```bash
# 第一引数: Compare Branch名（未指定時は現在のブランチ）
# 第二引数: Base Branch名（未指定時はmain）
BASE_BRANCH="${第二引数:-main}"
if [[ -n "${第一引数}" ]]; then
  COMPARE_BRANCH="${第一引数}"
else
  COMPARE_BRANCH="$(git branch --show-current)"
fi
```

# リモートへのプッシュ

```bash
git push -u origin "${COMPARE_BRANCH}"
```

# コミット履歴の確認

```bash
git log --oneline "${BASE_BRANCH}...${COMPARE_BRANCH}"
```

# ベースブランチとの差分確認

```bash
git diff "${BASE_BRANCH}...${COMPARE_BRANCH}"
```

# PRテンプレートファイルの内容確認

以下の優先順でGlobで検索し、最初に見つかったファイルをReadで読み取ってください。ファイル名`pull_request_template`は大文字小文字不問。どちらにもない場合はスキップ。

1. `.github/pull_request_template*`
2. `${HOME}/dotfiles/.github/pull_request_template*`

# PRタイトルとボディの生成

コミット履歴、差分、PRテンプレートファイルの内容を元に、以下を生成してください：

- **PRタイトル**: 変更内容を簡潔に表すタイトル
- **PRボディ**: PRテンプレートがある場合はそれに従い、ない場合は変更内容の概要を記載

# PR作成ページをブラウザでオープン

PRタイトルとPRボディをURLエンコードしてPR作成ページを開きます。

PRタイトルとPRボディは変数に格納してからエンコードしてください。
`eval`内でのヒアドキュメントやインライン複数行文字列はパースエラーの原因になるため使用しないでください。

```bash
REMOTE_URL=$(git remote get-url origin)
REPO_URL="${REMOTE_URL/#git@github.com:/https://github.com/}"
REPO_URL="${REPO_URL%.git}"
GITHUB_USER=$(git config user.name)

PR_TITLE="PRタイトル"
PR_BODY="PRボディ"

ENCODED_TITLE=$(printf '%s' "${PR_TITLE}" | xxd -p | tr -d '\n' | sed 's/\(..\)/%\1/g')
ENCODED_BODY=$(printf '%s' "${PR_BODY}" | xxd -p | tr -d '\n' | sed 's/\(..\)/%\1/g')

open "${REPO_URL}/compare/${BASE_BRANCH}...${COMPARE_BRANCH}?expand=1&title=${ENCODED_TITLE}&body=${ENCODED_BODY}&assignees=${GITHUB_USER}"
```
