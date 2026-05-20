---
name: "plan-issue"
description: "Create GitHub Issue from the current plan file so the plan is captured before implementation begins. ALWAYS invoke this skill automatically right after a plan in plan mode is approved (i.e., after ExitPlanMode), before any code is written. Also use when the user says 'issue にする', 'issue に登録', 'issue 作成', 'make this an issue', 'file an issue', 'create an issue from this plan', 'turn this plan into an issue', or otherwise wants to capture their plan as a GitHub Issue."
---

以下の手順で、現在のPlan内容からGitHub Issueを作成し、実装フェーズに移行してください。

# Plan内容の取得

Plan ファイルを Read で読み込んでください。

- **plan mode 終了直後の場合**: 直前のシステムリマインダで提示されたパス（例: `${HOME}/.claude/plans/<workspace>.md`）をそのまま読む
- **それ以外の場合**: `${HOME}/.claude/plans/` 内で最終更新時刻が最も新しいファイルを読む（`ls -t ${HOME}/.claude/plans/*.md | head -1`）

Plan ファイルが存在しない、または空の場合は、ユーザーに「先にPlanを作成してください」と伝えて終了してください。

# Issueテンプレートファイルの内容確認

以下のパスをGlobで検索し、見つかったファイルをReadで読み取ってください。どこにもない場合はスキップ。

1. `.github/ISSUE_TEMPLATE/*`
2. `${HOME}/dotfiles/.github/ISSUE_TEMPLATE/*`

複数テンプレートがある場合は、Plan内容に最も適したものを選択してください。

# Issueタイトルとボディの生成

Plan内容とIssueテンプレートを元に、以下を生成してください。

## Issueタイトル

課題・目的の視点で書く。
「何が問題か」「何を実現したいか」を簡潔に表す自然な文にする。
Conventional Commitsプレフィックス（feat/fix等）は付けない
（例: 「ログイン時にセッションが切れる」「ユーザー招待機能を追加したい」）

## Issueボディ

Issueは「何を・なぜ」（問題定義）を中心に書き、「どうやって」（実装手順）は含めない。GitHub公式ドキュメントでも、Issueは解決に役立つ情報（目的・背景・完了条件）を記述する場であり、実装の詳細手順はPlanやPRに残すべきとされている。

### 必ず含める項目

- **背景**: 何が問題か / 何を実現したいか（2〜4文）
- **完了条件**: 箇条書きで3〜6項目
- **補足**: 関連PR / 参考リンク（任意）

Issueテンプレートがある場合はそのセクション構成に従いつつ、各セクションは上記の粒度で要約する。

### 含めないもの

GitHub の Issue 作成エンドポイントは URL 全体で約 8KB が上限（超過すると `Whoa there! Your request URL is too long.` エラーになる）。日本語は URL エンコード後に 1 文字 = 9 バイトに膨らむため、本文は最初から簡潔に保つ。以下は Issue ではなく Plan / PR / リンク先ドキュメントに残す。

- コードブロックの長大な貼り付け（差分・スタックトレース全文・ログ全文など）
- Plan の章立てをそのまま転記すること
- 設計の詳細手順（ファイル単位の修正内容、関数シグネチャ、実装ステップなど）

### 文字数の目安

- 日本語本文: **600文字以内**を目標
- 英語主体の本文: 2000文字以内を目標

生成後に本文が上記を超えていたら要約し直す。詳細が必要な情報は Plan ファイルや関連ドキュメントへのリンクで参照させる。

# Issue作成ページをブラウザでオープン

`eval`内でのヒアドキュメントやインライン複数行文字列はパースエラーの原因になるため使用しないでください。

まず、リポジトリURLと GitHub ログイン名を取得してください。

```bash
git remote get-url origin
```

```bash
git config github.user
```

`git config github.user` は GitHub ログイン名を保持する慣例的な git config キー。設定済みなら assignees に使う。`git config user.name` は表示名（フルネーム等）が入っていて GitHub ログインと一致しないケースが多いため使わない。`github.user` が未設定の場合は assignees を省略し、Issue 作成ページで手動アサインしてもらう。

取得したリモートURLからリポジトリURLを構成してください。

- SSH形式（`git@github.com:owner/repo.git`）: `git@github.com:` を `https://github.com/` に置換
- HTTPS形式（`https://github.com/owner/repo.git`）: そのまま使用

いずれの場合も末尾の `.git` は除去してください。

最後に、Issue作成ページを開いてください。ブラウザ起動コマンドはサンドボックス内では実行できないため、必ず`dangerouslyDisableSandbox: true`を指定して実行してください。IssueタイトルとIssueボディは`urlencode`関数でURLエンコードしてください。

`opener`関数は実行環境を判定し、適切なブラウザ起動コマンドにディスパッチします。

- macOS: `open`
- WSL: `explorer.exe`（`/proc/version`に`microsoft`が含まれるかで判定）
- その他Linux: `xdg-open`（存在する場合）
- フォールバック: URLを標準出力に表示

```bash
urlencode(){ printf '%s' "$1" | od -An -tx1 | tr -d ' \n' | sed 's/\(..\)/%\1/g'; }; opener(){ case "$(uname -s)" in Darwin) open "$1";; Linux) if grep -qi microsoft /proc/version 2>/dev/null; then explorer.exe "$1"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1"; else printf 'Open this URL: %s\n' "$1"; fi;; *) printf 'Open this URL: %s\n' "$1";; esac; }; GH_USER=$(git config github.user 2>/dev/null); QS_ASSIGNEES=""; [ -n "$GH_USER" ] && QS_ASSIGNEES="&assignees=$GH_USER"; opener "REPO_URL/issues/new?title=$(urlencode "Issueタイトル")&body=$(urlencode "Issueボディ")${QS_ASSIGNEES}"
```
