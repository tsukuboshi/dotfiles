---
name: "read-pr"
description: "Read a GitHub Pull Request — description, comments, reviews, and diff — via Claude in Chrome without gh CLI (Repo Default: git remote origin, No-arg Default: open PR list). Use this skill whenever the user wants to read, check, summarize, or review a GitHub PR — including 'PR を読んで', 'PR の内容を確認', 'レビューコメントを見て', 'read PR #N', 'what changed in this PR', or when they paste a GitHub pull request URL. This skill intentionally avoids gh CLI because its fine-grained PAT is scoped per resource owner and returns 404 for org-private repositories — instead it reads the GitHub Web UI through the already logged-in browser session. For reviewing a local branch diff you have checked out, use review-branch instead."
argument-hint: "[PR Number or URL]"
---

以下の手順でGitHub Pull Request(PR)をClaude in Chrome経由で読み取ってください。

gh CLIではなくブラウザを使うのは、fine-grained PATがリソースオーナー単位でスコープを持つため、権限外のorgプライベートリポジトリでは`gh pr view`が404になるからです。ブラウザは既にGitHubへログイン済みのセッションを持っているため、ユーザーが画面で見られるPRはそのまま読み取れます。

手元にチェックアウト済みのブランチの差分をレビューしたいだけなら、ブラウザを使わずに済む`review-branch`スキルの方が高速です。このスキルはリモートにしか存在しないPRや、レビューコメントを含めて読みたい場合に使ってください。

# 引数の解決

`ARGUMENT`はPR番号またはPR URLを受け取ります。

- **PR URL（`https://github.com/OWNER/REPO/pull/N`）**: そのまま`TARGET_URL`として使用
- **PR番号（`123`・`#123`）**: リポジトリURLを構成して`REPO_URL/pull/番号`を`TARGET_URL`とする
- **未指定**: `REPO_URL/pulls`を`TARGET_URL`とし、後述の「一覧からの選択」に進む

リポジトリURLは以下のコマンドで取得したリモートURLから構成してください。

```bash
git remote get-url origin
```

- SSH形式（`git@github.com:owner/repo.git`）: `git@github.com:` を `https://github.com/` に置換
- HTTPS形式（`https://github.com/owner/repo.git`）: そのまま使用

いずれの場合も末尾の `.git` は除去してください。

カレントディレクトリがgitリポジトリでない場合や、リモートがGitHub以外の場合は、ユーザーにPR URLの指定を求めて中断してください。

# ブラウザツールの準備

Claude in ChromeのMCPツールが未ロードの場合、**1回のToolSearch呼び出しでまとめてロード**してください。ツールごとに個別のToolSearchを呼ぶとラウンドトリップを無駄にします。

```text
ToolSearch query: "select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__find,mcp__claude-in-chrome__tabs_close_mcp"
```

次に`tabs_context_mcp`を`createIfEmpty: true`で呼び、使用するタブのIDを取得してください。他のブラウザツールを使う前に最低1回はこの呼び出しが必要です。

**拡張機能が未接続の場合**、`Browser extension is not connected`というエラーが返ります。このときは以下をユーザーに案内して中断してください。リトライを繰り返しても接続はされません。

1. https://claude.ai/chrome からClaude拡張機能をインストールする（インストール直後ならChromeの再起動が必要）
2. ChromeでClaude Codeと同じアカウントでclaude.aiにログインしているか確認する
3. 準備ができたら再度スキルを起動してもらう

## リンクを辿る手段

このスキルはクリック操作を行わないため、ページ内リンクは`navigate`でURLを直接開いて辿ります。目的のリンクのURLが分からない場合は、`find`に自然言語でリンクを説明すると`href`付きで返ってくるので、それを`navigate`に渡してください。

```text
find query: "◯◯へのリンク"
→ ref_399: link "..." (href="/OWNER/REPO/pull/123")
```

URLを推測して404を踏むより確実です。

# Conversationタブの読み取り

`navigate`で`TARGET_URL`を開き、`get_page_text`でページ本文を取得してください。このページからPR本文・通常コメント・レビューの要約・CIチェックの状態が読み取れます。

GitHubのページは本文が遅延レンダリングされるため、`get_page_text`が1回目でナビゲーションやフィルタ部分だけを返し、肝心の中身が空で返ることがあります。期待した内容が無い場合は、まず`get_page_text`をもう一度呼んでください。2回試しても取れない場合のみ、ページが重い旨をユーザーに伝えて判断を仰いでください。

ページが見つからない（404）場合、以下のいずれかが原因です。ユーザーに状況を伝えて中断してください。

- PR番号が存在しない（Issue番号と取り違えている可能性もあります。同じ番号で`REPO_URL/issues/番号`を試す価値があります）
- そのGitHubアカウントにリポジトリの参照権限がない
- ブラウザで別アカウントにログインしている

コメント数が多いPRでは、GitHubが中間のコメントを折りたたんで「Load more」「N remaining items」のように表示します。折りたたまれたコメントはDOMに存在しない（クリック時にGraphQLで取得される）ため、このスキルの読み取り専用ツールでは取得できません。前後のコメントのパーマリンクを付けて開き直しても展開されないことは検証済みなので、試さないでください。

省略が検出された場合は、読めた範囲を報告した上で、何件がどの期間で省略されているかを明示してください。`find`で「Load more」ボタンを探すと前後のコメントの投稿日時が得られるので、欠落区間を特定できます。内容が必要な場合は、ブラウザで展開して貼ってもらうようユーザーに案内してください。

# 差分の読み取り

差分は`REPO_URL/pull/番号.diff`を`navigate`で開き、`get_page_text`で取得してください。プレーンテキストのunified diffがそのまま返ります。

Files changedタブ（`/pull/番号/files`）は使わないでください。仮想スクロールでレンダリングされるため、`get_page_text`ではファイルツリーしか取れず、差分本体がDOMに存在しません。大きな差分の「Load diff」も、このスキルはクリックできないため展開できません。`.diff`はこれらの制約をまとめて回避できます（プライベートリポジトリでもブラウザのログインセッションで読めます）。

差分が非常に大きく`.diff`の取得自体が重い場合は、ローカルにブランチがあれば`git fetch origin PRのブランチ名`した上で`git diff BASE...HEAD`で読む方が速いです。PRページから読み取ったブランチ名を使ってください。

差分が500行を超える場合は、ファイル単位で要点を要約してください。全行を報告に転記しないでください。

# レビューコメントの扱い

Conversationタブにはレビューの要約（Approved / Changes requested とその本文）が出ますが、コード行に紐づくインラインコメントは差分ページ側に表示されます。レビュー指摘が議論の中心になっている場合は、差分ページの読み取り結果からインラインコメントを拾い、どのファイルのどの箇所への指摘かを対応付けて報告してください。

# 一覧からの選択（引数未指定時）

`REPO_URL/pulls`を読み取ると、Open状態のPRが番号・タイトル・作成者・レビュー状態付きで一覧できます。これを表形式で提示し、`AskUserQuestion`またはテキストでどのPRを読むか確認してください。

一覧は1ページあたり25件です。ユーザーが探しているPRが見当たらない場合は、以下のURLで絞り込めることを案内してください。

- マージ済み: `REPO_URL/pulls?q=is%3Apr+is%3Amerged`
- 自分にレビュー依頼が来ているもの: `REPO_URL/pulls?q=is%3Apr+is%3Aopen+review-requested%3A%40me`
- 2ページ目以降: `REPO_URL/pulls?page=2`

選択後、そのPRのURLで「Conversationタブの読み取り」から実行してください。

# 報告

読み取った内容を以下の構成で報告してください。ユーザーが差分を自分で開かなくても、変更の輪郭と意図、レビューの状況が掴めることがゴールです。

- **タイトルと状態**: `#番号 タイトル`（Open / Merged / Closed、Draft かどうか、`ベースブランチ ← コンペアブランチ`）
- **変更の要旨**: PR本文から読み取れる「何をなぜ変えたか」を数行で
- **変更内容**: 変更ファイルと、それぞれで何が起きたかの要点。差分行数も添える
- **レビューとコメント**: 承認状況、指摘事項、未解決の議論
- **CIの状態**: チェックが失敗している場合はどのワークフローか（詳細は`read-action`スキルで追える旨を添えてよい）

レビュー依頼の文脈（「これレビューして」等）であれば、上記に加えて`review-branch`スキルのレビュー観点（正確性・セキュリティ・パフォーマンス・可読性・意図との整合性）で気づいた点を報告してください。単に「内容を確認したい」文脈なら要約に留めてください。

# タブの後始末

読み取りが終わったら、このスキルで開いたタブを`tabs_close_mcp`で閉じてください。ユーザーが元から開いていたタブは閉じないでください。
