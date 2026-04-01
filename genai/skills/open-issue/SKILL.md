---
name: "open-issue"
description: "Create GitHub Issue from branch diff against main. Use this skill when the user wants to create an issue based on current branch changes, infer issue content from diff, or open an issue reflecting work done on the branch. This skill opens the GitHub Web UI directly instead of using gh CLI."
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順で、現在のブランチの変更内容からGitHub Issueを推測・作成してください。

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。

- 第一引数: Compare Branch名（未指定時は現在のブランチ）
- 第二引数: Base Branch名（未指定時は`main`）

第一引数が未指定の場合、以下のコマンドで現在のブランチ名を取得してください。

```bash
git branch --show-current
```

引数の解決後、`COMPARE_BRANCH`と`BASE_BRANCH`をユーザーに表示してください。

以降の手順では`${COMPARE_BRANCH}`と`${BASE_BRANCH}`を解決した値に置き換えて実行してください。

# コミット履歴とベースブランチとの差分確認

以下の2つのコマンドは依存関係がないため、並列で実行してください。

```bash
git log --oneline BASE_BRANCH...COMPARE_BRANCH
```

```bash
git diff BASE_BRANCH...COMPARE_BRANCH
```

# Issueテンプレートファイルの内容確認

以下のパスをGlobで検索し、見つかったファイルをReadで読み取ってください。どこにもない場合はスキップ。

1. `.github/ISSUE_TEMPLATE/*`
2. `${HOME}/dotfiles/.github/ISSUE_TEMPLATE/*`

複数テンプレートがある場合は、変更内容に最も適したものを選択してください。

# Issueタイトルとボディの生成

コミット履歴、差分、Issueテンプレートの内容を元に、以下を生成してください：

- **Issueタイトル**: ブランチの変更内容から推測されるタスクや課題を簡潔に表すタイトル
- **Issueボディ**: Issueテンプレートがある場合はそのセクション構成に従い、差分から読み取れる目的・完了条件・補足情報を記載する。テンプレートがない場合は変更内容の概要を記載

生成のポイント：

- コミットメッセージやdiffの内容から「何を実現しようとしているか」を推測する
- 差分が示す変更の意図・背景をIssueの目的として記述する
- 完了条件は差分に含まれる変更が達成していることを基に記述する

# Issue作成ページをブラウザでオープン

Issueタイトルとボディをブラウザで開きます。

`eval`内でのヒアドキュメントやインライン複数行文字列はパースエラーの原因になるため使用しないでください。

まず、リポジトリURLとユーザー名を取得してください。

```bash
git remote get-url origin
```

```bash
git config user.name
```

取得したリモートURLからリポジトリURLを構成してください。

- SSH形式（`git@github.com:owner/repo.git`）: `git@github.com:` を `https://github.com/` に置換
- HTTPS形式（`https://github.com/owner/repo.git`）: そのまま使用

いずれの場合も末尾の `.git` は除去してください。

次に、IssueタイトルとIssueボディをURLエンコードしてください。

```bash
printf '%s' "Issueタイトル" | od -An -tx1 | tr -d ' \n' | sed 's/\(..\)/%\1/g'
```

```bash
printf '%s' "Issueボディ" | od -An -tx1 | tr -d ' \n' | sed 's/\(..\)/%\1/g'
```

最後に、Issue作成ページを開いてください。`open`コマンドはサンドボックス内ではブラウザを起動できないため、必ず`dangerouslyDisableSandbox: true`を指定して実行してください。

```bash
open "REPO_URL/issues/new?title=ENCODED_TITLE&body=ENCODED_BODY&assignees=GITHUB_USER"
```
