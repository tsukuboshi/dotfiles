---
description: "Create PR via GitHub Web UI without gh CLI (Compare Default: current branch, Base Default: reflog origin)"
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順で新しいPull Request(PR)をGitHub Web UI経由で作成してください。

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。

- 第一引数: Compare Branch名（未指定時は現在のブランチ）
- 第二引数: Base Branch名（未指定時はreflogから自動検出）

第一引数が未指定の場合、以下のコマンドで現在のブランチ名を取得してください。

```bash
git branch --show-current
```

第二引数が未指定の場合、以下のコマンドでベースブランチを検出してください。

```bash
git reflog show COMPARE_BRANCH --format='%H' | tail -1
```

```bash
git branch --contains 上記で取得したハッシュ
```

出力から`COMPARE_BRANCH`自身を除いた最初のブランチ名を`BASE_BRANCH`としてください。

`BASE_BRANCH`が空、またはローカル・リモートに存在しないブランチ名だった場合は、ユーザーにベースブランチを確認してから続行してください。

引数の解決後、`COMPARE_BRANCH`と`BASE_BRANCH`をユーザーに表示してください。

以降の手順では`${COMPARE_BRANCH}`と`${BASE_BRANCH}`を解決した値に置き換えて実行してください。

# リモートへのプッシュ確認

`COMPARE_BRANCH`がリモートにプッシュ済みかつ最新であることを確認してください。

```bash
git fetch origin COMPARE_BRANCH 2>/dev/null
```

```bash
git rev-parse COMPARE_BRANCH
```

```bash
git rev-parse origin/COMPARE_BRANCH 2>/dev/null
```

- リモートブランチが存在しない場合: ユーザーに `git push -u origin COMPARE_BRANCH` の実行を促して中断
- LOCAL ≠ REMOTE の場合: ローカルに未プッシュのコミットがある旨を伝え、`git push` の実行を促して中断
- LOCAL = REMOTE の場合: そのまま続行

# コミット履歴の確認

```bash
git log --oneline BASE_BRANCH...COMPARE_BRANCH
```

# ベースブランチとの差分確認

```bash
git diff BASE_BRANCH...COMPARE_BRANCH
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

`eval`内でのヒアドキュメントやインライン複数行文字列はパースエラーの原因になるため使用しないでください。

まず、リポジトリURLとユーザー名を取得してください。

```bash
git remote get-url origin
```

```bash
git config user.name
```

取得したリモートURLから`git@github.com:`を`https://github.com/`に、末尾の`.git`を除去してリポジトリURLを構成してください。

次に、PRタイトルとPRボディをURLエンコードしてください。

```bash
printf '%s' "PRタイトル" | od -An -tx1 | tr -d ' \n' | sed 's/\(..\)/%\1/g'
```

```bash
printf '%s' "PRボディ" | od -An -tx1 | tr -d ' \n' | sed 's/\(..\)/%\1/g'
```

最後に、PR作成ページを開いてください。`open`コマンドはサンドボックス内ではブラウザを起動できないため、必ず`dangerouslyDisableSandbox: true`を指定して実行してください。

```bash
open "REPO_URL/compare/BASE_BRANCH...COMPARE_BRANCH?quick_pull=1&title=ENCODED_TITLE&body=ENCODED_BODY&assignees=GITHUB_USER"
```
