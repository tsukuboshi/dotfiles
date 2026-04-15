---
name: "plan-issue"
description: "Create GitHub Issue from current plan and exit plan mode. ALWAYS invoke this skill automatically when a plan is finalized in plan mode, before exiting plan mode or starting implementation. Also use when the user says 'issue にする', 'issue に登録', 'issue 作成', or wants to capture their plan as a GitHub Issue."
---

以下の手順で、現在のPlan内容からGitHub Issueを作成し、実装フェーズに移行してください。

# Plan内容の取得

現在の会話にあるPlan（計画）の内容を取得してください。
Planが存在しない場合は、ユーザーに「先にPlanを作成してください」と伝えて終了してください。

# Issueテンプレートファイルの内容確認

以下のパスをGlobで検索し、見つかったファイルをReadで読み取ってください。どこにもない場合はスキップ。

1. `.github/ISSUE_TEMPLATE/*`
2. `${HOME}/dotfiles/.github/ISSUE_TEMPLATE/*`

複数テンプレートがある場合は、Plan内容に最も適したものを選択してください。

# Issueタイトルとボディの生成

Plan内容とIssueテンプレートを元に、以下を生成してください：

- **Issueタイトル**: Planが解決しようとしている課題・タスクを簡潔に表すタイトル
- **Issueボディ**: Issueテンプレートがある場合はそのセクション構成に従い、Plan内容から目的・完了条件・補足情報を記載する。テンプレートがない場合はPlan内容の概要を記載

Issueは「何を・なぜ」（問題定義）を中心に書き、「どうやって」（実装手順）は含めない。GitHub公式ドキュメントでも、Issueは解決に役立つ情報（目的・背景・完了条件）を記述する場であり、実装の詳細手順はPlanやPRに残すべきとされている。

# Issue作成ページをブラウザでオープン

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
