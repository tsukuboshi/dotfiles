---
name: "read-action"
description: "Read a GitHub Actions workflow run — job status and failure logs — via Claude in Chrome without gh CLI (Repo Default: git remote origin, No-arg Default: recent run list). Use this skill whenever the user wants to check CI status or find out why a build failed — including 'CI が落ちた', 'Actions のログを見て', 'ワークフローの失敗原因を調べて', 'why did the build fail', 'check the CI run', or when they paste a GitHub Actions run URL. This skill intentionally avoids gh CLI because its fine-grained PAT is scoped per resource owner and returns 404 for org-private repositories — instead it reads the GitHub Web UI through the already logged-in browser session."
argument-hint: "[Run URL or Run ID]"
---

以下の手順でGitHub Actionsのワークフロー実行結果をClaude in Chrome経由で読み取ってください。

gh CLIではなくブラウザを使うのは、fine-grained PATがリソースオーナー単位でスコープを持つため、権限外のorgプライベートリポジトリでは`gh run view`が404になるからです。ブラウザは既にGitHubへログイン済みのセッションを持っているため、ユーザーが画面で見られる実行結果はそのまま読み取れます。

# 引数の解決

`ARGUMENT`はrun URLまたはrun IDを受け取ります。

- **run URL（`https://github.com/OWNER/REPO/actions/runs/123456789`）**: そのまま`TARGET_URL`として使用。ジョブ単位のURL（`.../job/987654321`）が渡された場合もそのまま使用
- **run ID（`123456789`）**: リポジトリURLを構成して`REPO_URL/actions/runs/ID`を`TARGET_URL`とする
- **未指定**: `REPO_URL/actions`を`TARGET_URL`とし、後述の「一覧からの選択」に進む

リポジトリURLは以下のコマンドで取得したリモートURLから構成してください。

```bash
git remote get-url origin
```

- SSH形式（`git@github.com:owner/repo.git`）: `git@github.com:` を `https://github.com/` に置換
- HTTPS形式（`https://github.com/owner/repo.git`）: そのまま使用

いずれの場合も末尾の `.git` は除去してください。

カレントディレクトリがgitリポジトリでない場合や、リモートがGitHub以外の場合は、ユーザーにrun URLの指定を求めて中断してください。

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
→ ref_399: link "..." (href="/OWNER/REPO/actions/runs/34100026751")
```

URLを推測して404を踏むより確実です。

# run サマリページの読み取り

`navigate`で`TARGET_URL`を開き、`get_page_text`でページ本文を取得してください。ここからワークフロー名・トリガー（push / pull_request / workflow_dispatch等）・対象ブランチとコミット・全体のステータス・ジョブごとの成否と所要時間が読み取れます。

Actionsのページはレンダリングに時間がかかることがあります。ジョブ一覧が空だったり「Loading」のままの場合は、`get_page_text`をもう一度呼んでください。2回試しても内容が取れない場合は、ページが重い旨をユーザーに伝えて判断を仰いでください。

実行が進行中（in progress）の場合は、その時点のステータスを報告した上で、完了を待って再確認する必要があることを伝えてください。定期的に確認し続けたい場合は`loop`スキルの利用を提案してください。

# 失敗ジョブのログ読み取り

全ジョブが成功していれば、サマリの報告だけで完了です。失敗ジョブがある場合のみログに踏み込んでください。

失敗したジョブのURL（`REPO_URL/actions/runs/RUN_ID/job/JOB_ID`）を`navigate`で開き、`get_page_text`でログを取得してください。GitHubは**失敗したステップを自動的に展開して表示する**ため、クリックせずに失敗箇所のログが読み取れます。

成功したステップのログは折りたたまれたままで、このスキルは読み取り専用のツールのみを使うため展開できません。失敗の直前のセットアップ手順などを確認したい場合は、その旨を報告して判断を仰いでください。

ログが長い場合は`find`でエラー文字列（`Error`・`error:`・`FAILED`・`npm ERR!`・`Traceback`など、ワークフローの言語・ツールに応じたもの）を検索すると、該当箇所を素早く特定できます。

複数のジョブが失敗している場合、後続ジョブの失敗は先行ジョブの失敗に引きずられていることが多いため、**最初に失敗したジョブから調べてください**。

# 一覧からの選択（引数未指定時）

`REPO_URL/actions`を読み取ると、最近のワークフロー実行がワークフロー名・ステータス・ブランチ付きで一覧できます。これを表形式で提示し、`AskUserQuestion`またはテキストでどの実行を読むか確認してください。

ユーザーの意図が明らかな場合は、確認せずに以下のURLで直接絞り込んでも構いません。

- 失敗した実行のみ: `REPO_URL/actions?query=is%3Afailure`
- 特定ブランチ: `REPO_URL/actions?query=branch%3Aブランチ名`
- 現在のブランチのCI状況を知りたい場合は、`git branch --show-current`で取得したブランチ名で絞り込む

## ワークフローを指定して絞り込む

全体一覧は1ページ25件で、**全ワークフローの実行が混在します**。CI・デプロイ・Dependabotなどが頻繁に走るリポジトリでは、探している実行が1ページ目に載らないことが珍しくありません。

ユーザーが「デプロイの結果」「リリースの実行」のようにワークフローを特定できる言い方をしている場合は、全体一覧ではなく**ワークフロー単位のページ**を読んでください。左サイドバーにワークフロー名が並んでいるので、`find`でそのリンクの`href`（`/OWNER/REPO/actions/workflows/xxx.yaml`）を取得して`navigate`します。ワークフローファイル名は推測せず、必ず`find`で取得してください。

用途の似たワークフローが複数あるリポジトリでは、**目的の実行がどれに属するか一意に決まりません**。例えばデプロイ処理が別ワークフローへ分離された直後は、分離前後の両方に同種の実行履歴が残ります。実行名（`Deploy v1.1.8 (st)`のような命名）から目的のものを探す場合は、候補となるワークフローを順に読み、最も新しいものを選んでください。片方だけを見て「これが最新」と判断すると誤ります。

`get_page_text`は一覧の相対時刻（「3 days ago」等）を落とすことがあります。新しさの判断は実行番号（`#17`のような連番、ワークフローごとに単調増加）とバージョンタグを手がかりにしてください。ワークフローをまたいで番号を比較しても意味がない点に注意してください。

# 報告

共通して以下を報告してください。

- **実行の概要**: ワークフロー名 / トリガー（push・workflow_dispatch等と、その対象タグ・ブランチ・コミット） / 全体のステータスと所要時間

その先は、ユーザーが失敗原因を知りたいのか、何が行われたかを知りたいのかで書き分けます。

## 失敗した実行の場合

知りたいのは「なぜ落ちたか」と「次に何をすればいいか」です。

- **ジョブごとの結果**: 成否を一覧で
- **失敗の原因**: どのジョブのどのステップで、どんなエラーが出たか。エラーメッセージは原文のまま引用する（要約すると原因特定に必要な情報が失われます）
- **推定される原因と対処**: ログから読み取れる範囲で、何が起きているかの見立てと修正の方向性

失敗原因がコードの問題であれば、該当箇所をローカルで確認して具体的な修正案を提示してください。環境・シークレット・権限の問題であれば、ユーザーにしかできない操作が含まれるため、何を確認・設定すべきかを明示してください。

## 成功した実行の場合

「成功しました」だけでは情報になりません。知りたいのは**そのワークフローが何を行ったか**です。

- **ジョブの一覧と役割**: 各ジョブが何をしたかを対応付ける（例: Terraform適用 / S3アップロード / ECSデプロイ）。所要時間も添えると、どこに時間がかかったかが分かる
- **成果物**: runサマリページの Job Summary には、デプロイ先の環境名・イメージタグ・ECRのURI・カバレッジ率・Terraformの対象ディレクトリなど、ワークフローが自分で出力した情報が載ります。ここはログを開かずに読めるので必ず拾ってください
- **Annotations の警告**: 失敗していなくても、アクションの非推奨警告などが出ていれば報告する。放置すると将来壊れる予兆です

# タブの後始末

読み取りが終わったら、このスキルで開いたタブを`tabs_close_mcp`で閉じてください。ユーザーが元から開いていたタブは閉じないでください。
