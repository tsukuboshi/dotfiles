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
ToolSearch query: "select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__get_page_text,mcp__claude-in-chrome__find,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__tabs_close_mcp"
```

次に`tabs_context_mcp`を`createIfEmpty: true`で呼び、使用するタブのIDを取得してください。他のブラウザツールを使う前に最低1回はこの呼び出しが必要です。

**拡張機能が未接続の場合**、`Browser extension is not connected`というエラーが返ります。このときは以下をユーザーに案内して中断してください。リトライを繰り返しても接続はされません。

1. https://claude.ai/chrome からClaude拡張機能をインストールする（インストール直後ならChromeの再起動が必要）
2. ChromeでClaude Codeと同じアカウントでclaude.aiにログインしているか確認する
3. 準備ができたら再度スキルを起動してもらう

## 使える操作

`computer`はPreToolUseフック（`~/dotfiles/genai/hooks/chrome-tool-guard.sh`）で絞ってあり、ページを変えない操作（`scroll`・`scroll_to`・`screenshot`・`zoom`・`hover`・`wait`）だけが通ります。これらは必要に応じて自由に使ってください。クリック・キー入力はフックで拒否されるので、展開やボタン押下が必要な場面ではユーザーに手動操作を依頼してください。

## ページを開いて読む

`navigate`の直後に`get_page_text`を呼ぶと、読み込み前のエラーになるか、**遷移前のページの本文**が返ることがあります。前のページの本文は一見正常に見えるため、空振りより気付きにくい失敗です。ページを開くたびに次の順で読んでください。

1. `navigate`でURLを開く
2. `navigate`の結果が返ってから、`computer`の`wait`で2〜3秒待つ。`navigate`と同じバッチで並列に呼ぶと、遷移前に実行されて失敗する
3. `get_page_text`を呼び、結果の`URL:`と`Title:`が開いたページのものか確かめる。違っていたり本文が空だったりしたら、もう一度`wait`してから読み直す

## リンクを辿る手段

ページ内リンクはクリックせず、`navigate`でURLを直接開いて辿ります。目的のリンクのURLが分からない場合は、`find`に自然言語でリンクを説明すると`href`付きで返ってくるので、それを`navigate`に渡してください。

```text
find query: "◯◯へのリンク"
→ ref_399: link "..." (href="/OWNER/REPO/actions/runs/34100026751")
```

URLを推測して404を踏むより確実です。

# run サマリページの読み取り

「ページを開いて読む」の手順で`TARGET_URL`を読んでください。ここからワークフロー名・トリガー（push / pull_request / workflow_dispatch等）・対象ブランチとコミット・全体のステータス・ジョブごとの成否と所要時間・Annotationsが読み取れます。

Actionsのページはレンダリングに時間がかかることがあります。ジョブ一覧が空だったり「Loading」のままの場合は、`wait`を挟んで読み直してください。2回試しても内容が取れない場合は、ページが重い旨をユーザーに伝えて判断を仰いでください。

ジョブが多くneeds で依存し合うワークフローでは、`screenshot`でジョブのグラフを見ると、どのジョブの失敗で後続がスキップされたかがテキストより早く掴めます。

実行が進行中（in progress）の場合は、その時点のステータスを報告した上で、完了を待って再確認する必要があることを伝えてください。定期的に確認し続けたい場合は`loop`スキルの利用を提案してください。

# 失敗ジョブのログ読み取り

全ジョブが成功していれば、サマリの報告だけで完了です。失敗ジョブがある場合のみログに踏み込んでください。

ログは**raw ログ**で読んでください。ジョブページのログビューアは表示範囲の約50行しかDOMに描画しないため、`get_page_text`では失敗ステップの一部しか取れず、成功したステップや折りたたまれたグループ（`▶`の行）の中身も読めません。

1. 失敗したジョブのページ（`REPO_URL/actions/runs/RUN_ID/job/JOB_ID`）を開く
2. `find`で「View raw logs」リンクの`href`（`/OWNER/REPO/commit/SHA/checks/JOB_ID/logs`）を取得する。歯車メニューの中にありますが、メニューを開かなくても`find`で取れます
3. そのURLを「ページを開いて読む」の手順で読む。Azure Blob Storageの署名付きURLへリダイレクトされるので、`wait`は3秒取る

raw ログはジョブ全体（全ステップ・全グループ）がタイムスタンプ付きのプレーンテキストで1回で返ります。失敗箇所は`##[error]`の行が目印で、その直前の数十行に原因が出ていることが多いです。ANSIのカラーコード（`[1;34m`等）が混ざりますが、読み飛ばして構いません。

リダイレクト先のURLには一時的な署名（`sig=`）が含まれます。報告にはこのURLを載せず、`/commit/.../checks/JOB_ID/logs`の方を示してください。

実行中のジョブなどでraw ログが取れない場合は、ジョブページを読みます。GitHubは失敗したステップを自動で展開し、末尾（エラー行）付近を描画した状態で開くので、まず`get_page_text`でエラー行を拾ってください。それより前の行が必要なら、ログ上で`scroll`（上方向）してから`get_page_text`を読み直します。スクロールすると描画範囲が入れ替わり、末尾の行は取れなくなります。

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

`get_page_text`は一覧の実行日時を落とします。新しさの判断は実行番号（`#17`のような連番、ワークフローごとに単調増加）とバージョンタグを手がかりにしてください。ワークフローをまたいで番号を比較しても意味がないので、その場合は`screenshot`で一覧を撮ると各実行の日時（`Oct 10, 22:58 GMT+9`等）が読めます。

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
