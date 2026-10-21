---
name: "read-issue"
description: "Read a GitHub Issue and its comments via Claude in Chrome without gh CLI (Repo Default: git remote origin, No-arg Default: open issue list). Use this skill whenever the user wants to read, check, summarize, or catch up on a GitHub Issue — including 'issue を読んで', 'issue の内容を確認', 'issue をまとめて', 'read issue #N', 'what does this issue say', or when they paste a GitHub issue URL. This skill intentionally avoids gh CLI because its fine-grained PAT is scoped per resource owner and returns 404 for org-private repositories — instead it reads the GitHub Web UI through the already logged-in browser session."
argument-hint: "[Issue Number or URL]"
---

以下の手順でGitHub IssueをClaude in Chrome経由で読み取ってください。

gh CLIではなくブラウザを使うのは、fine-grained PATがリソースオーナー単位でスコープを持つため、権限外のorgプライベートリポジトリでは`gh issue view`が404になるからです。ブラウザは既にGitHubへログイン済みのセッションを持っているため、ユーザーが画面で見られるIssueはそのまま読み取れます。

# 引数の解決

`ARGUMENT`はIssue番号またはIssue URLを受け取ります。

- **Issue URL（`https://github.com/OWNER/REPO/issues/N`）**: そのまま`TARGET_URL`として使用
- **Issue番号（`123`・`#123`）**: リポジトリURLを構成して`REPO_URL/issues/番号`を`TARGET_URL`とする
- **未指定**: `REPO_URL/issues`を`TARGET_URL`とし、後述の「一覧からの選択」に進む

リポジトリURLは以下のコマンドで取得したリモートURLから構成してください。

```bash
git remote get-url origin
```

- SSH形式（`git@github.com:owner/repo.git`）: `git@github.com:` を `https://github.com/` に置換
- HTTPS形式（`https://github.com/owner/repo.git`）: そのまま使用

いずれの場合も末尾の `.git` は除去してください。

カレントディレクトリがgitリポジトリでない場合や、リモートがGitHub以外の場合は、ユーザーにIssue URLの指定を求めて中断してください。

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
→ ref_399: link "..." (href="/OWNER/REPO/issues/123")
```

URLを推測して404を踏むより確実です。

# Issueページの読み取り

「ページを開いて読む」の手順で`TARGET_URL`を読んでください。`get_page_text`はアクセシビリティツリーではなく記事本文を優先して返すため、Issueのような文章中心のページに適しています。

GitHubのページは本文が遅延レンダリングされるため、`get_page_text`がナビゲーションやフィルタ部分だけを返し、肝心の中身が空で返ることがあります。期待した内容が無い場合は、`wait`を挟んで読み直してください。2回試しても取れない場合のみ、ページが重い旨をユーザーに伝えて判断を仰いでください。

## 画像を読む

`get_page_text`は本文やコメントに貼られた画像をaltテキスト（`Screenshot from 2022-09-02 13-15-12`のようなファイル名）でしか返しません。バグ報告のスクリーンショットやエラーダイアログの画像は、Issueの論点そのものであることが多いので、画像があれば中身を見てください。

1. `find`で「本文・コメント内の画像」を探してrefを得る
2. `computer`の`scroll_to`でその画像を画面内へ移す
3. `screenshot`で画像を見る。エラーメッセージやバージョン番号など細かい文字は、`zoom`でその領域を拡大すると読める

画像から読み取った内容は、報告で「画像より」と出どころを添えてください。

ページが見つからない（404）場合、以下のいずれかが原因です。ユーザーに状況を伝えて中断してください。

- Issue番号が存在しない
- そのGitHubアカウントにリポジトリの参照権限がない
- ブラウザで別アカウントにログインしている

## コメントが省略されている場合

コメント数が多いIssueでは、GitHubが中間のコメントを折りたたんで「Load more」「N remaining items」のように表示します。折りたたまれたコメントは**DOMに存在しない**（クリック時にGraphQLで取得される）ため、クリックできないこのスキルでは取得できません。

ただし、**欠落区間の中にあるコメント**のパーマリンク（`#issuecomment-XXXXX`）を開くと、GitHubはそのコメントと前後数件を読み込んで表示します（105件の省略が59件と39件に分かれた例を確認済み）。本文や読めたコメントの中に、欠落区間に属するコメントへのリンク（`#issuecomment-数字`を含むURL）があれば、それを開いて欠落を縮めてください。

次の手段は検証済みで効果がありません。欠落区間の**外**にある、前後のコメントのパーマリンクで開き直しても折りたたみは展開されません。`read_page`でアクセシビリティツリーを読んでも、DOMに無いものは出てきません。「Load more」まで`scroll`しても自動では読み込まれません。

省略が検出された場合は、**読めた範囲を報告した上で、何件がどの期間で省略されているか**を明示してください（`find`で「Load more」ボタンを探すと、その前後のコメントの投稿日時とパーマリンクが得られるので、欠落区間を特定できます）。その上で、ユーザーに以下を案内してください。

- 欠落区間の内容が必要なら、ブラウザで「Load more」を押して該当コメントを貼ってもらう
- 特定のコメントのパーマリンクが分かっているなら、そのURLを指定してもらえば個別に読み取れる

# 一覧からの選択（引数未指定時）

`REPO_URL/issues`を読み取ると、Open状態のIssueが番号・タイトル・起票者・コメント数付きで一覧できます。これを表形式で提示し、`AskUserQuestion`またはテキストでどのIssueを読むか確認してください。

一覧は1ページあたり25件です。ユーザーが探しているIssueが見当たらない場合は、以下のURLで絞り込めることを案内してください。

- クローズ済み: `REPO_URL/issues?q=is%3Aissue+is%3Aclosed`
- キーワード検索: `REPO_URL/issues?q=is%3Aissue+検索語`
- 2ページ目以降: `REPO_URL/issues?page=2`

選択後、そのIssueのURLで「Issueページの読み取り」を実行してください。

# 報告

読み取った内容を以下の構成で報告してください。Issueは「何が問題か・何を実現したいか」を記録する場なので、議論の結論と未決事項が分かることを優先します。

- **タイトルと状態**: `#番号 タイトル`（Open / Closed、ラベル、マイルストーン、アサイニーがあれば併記）
- **本文の要約**: 背景・目的・完了条件を数行で
- **コメントの流れ**: 誰が何を述べたかを時系列で要約。同じ論点が繰り返されている場合はまとめる
- **結論と未決事項**: 合意済みの方針と、まだ決まっていない論点を分けて示す

本文やコメントをそのまま全文転記しないでください。ユーザーが求めているのは「読まずに済ませられる要約」です。ただし仕様の数値・コマンド・エラーメッセージなど、要約すると意味が失われる箇所は原文のまま引用してください。

# タブの後始末

読み取りが終わったら、このスキルで開いたタブを`tabs_close_mcp`で閉じてください。ユーザーが元から開いていたタブは閉じないでください。

ユーザーが続けて同じIssueを参照しそうな場合（「このIssueの実装を始めて」等）は、タブを開いたままにしてその旨を伝えても構いません。
