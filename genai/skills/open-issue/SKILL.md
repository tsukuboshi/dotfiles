---
name: "open-issue"
description: "Create GitHub Issue via GitHub Web UI without gh CLI (Source Default: current plan file). ALWAYS invoke this skill automatically right after a plan in plan mode is approved (i.e., after ExitPlanMode), before any code is written. Also use when the user says 'issue にする', 'issue に登録', 'issue 作成', 'make this an issue', 'file an issue', 'create an issue from this plan', 'turn this plan into an issue', or otherwise wants to capture something — a plan, a bug report, a discussion in the conversation, or a file — as a GitHub Issue. This skill intentionally avoids gh CLI because its OAuth token requires broader permissions than necessary — instead it opens the GitHub Web UI directly."
argument-hint: "[Issue Source]"
---

以下の手順で、指定されたソース内容からGitHub Issueを作成し、次のフェーズに移行してください。

# Issueソースの取得

Issue の元ネタとなる内容（以下「ソース内容」）を、次の優先順で確定してください。

## 1. ユーザーがソースを指定した場合

指定されたものをそのままソース内容として扱います。指定の形は次のいずれかです。

- **インラインの内容**: スキル引数やメッセージ本文に直接書かれた要望・バグ報告など
- **ファイルパス**: Read で読み込む（プランファイル以外の設計メモ・調査結果なども可）
- **会話中の話題**: 「さっきの件を issue にして」のように直近の会話を指す場合、該当するやり取りを要約してソース内容とする。どのやり取りを指すか曖昧なときはユーザーに確認する

## 2. 指定がない場合（デフォルト）

Plan ファイルを Read で読み込んでください。

- **plan mode 終了直後の場合**: 直前のシステムリマインダで提示されたパス（例: `${HOME}/.claude/plans/<workspace>.md`）をそのまま読む
- **それ以外の場合**: `${HOME}/.claude/plans/` 内で最終更新時刻が最も新しいファイルを読む（`ls -t ${HOME}/.claude/plans/*.md | head -1`）

ユーザー指定のソースがなく、Plan ファイルも存在しないか空の場合は、ユーザーに「Issue にする内容を指定するか、先にPlanを作成してください」と伝えて終了してください。

# Issueテンプレートファイルの内容確認

以下のパスをGlobで検索し、見つかったファイルをReadで読み取ってください。どこにもない場合はスキップ。

1. `.github/ISSUE_TEMPLATE/*`
2. `${HOME}/dotfiles/.github/ISSUE_TEMPLATE/*`

複数テンプレートがある場合は、ソース内容に最も適したものを選択してください。

# Issueタイトルとボディの生成

ソース内容とIssueテンプレートを元に、以下を生成してください。

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
- ソース文書の章立てをそのまま転記すること
- 設計の詳細手順（ファイル単位の修正内容、関数シグネチャ、実装ステップなど）

### 文字数の目安

- 日本語本文: **600文字以内**を目標
- 英語主体の本文: 2000文字以内を目標

生成後に本文が上記を超えていたら要約し直す。詳細が必要な情報は Plan ファイルや関連ドキュメントへのリンクで参照させる。

# ラベルの選択

ソース内容に最も適したラベルを以下から選んでください。通常は1つ、明確に複数該当する場合のみ複数選びます。どれにも当てはまらない場合はラベルを省略してください。

| ラベル | 選ぶ基準 |
|---|---|
| `bug` | 予期しない問題・意図しない挙動の報告 |
| `enhancement` | 新機能・改善の要望 |
| `documentation` | ドキュメントの改善・追加 |
| `question` | 情報や議論を必要とする問い |
| `dependencies` | 依存パッケージの更新・追加・削除 |

`bug` / `documentation` / `enhancement` / `question` はGitHubが全新規リポジトリに用意するデフォルトラベルのため、publicでもprivateでも利用できる。`dependencies` はDependabotが作成する慣例ラベルで、Dependabotを有効化したリポジトリに存在する。

残りのデフォルトラベル（`accessibility` / `duplicate` / `invalid` / `wontfix` / `good first issue` / `help wanted`）は、トリアージ後やメンテナ判断で付与する性質のものなので、作成時の選択肢からは外している。

リポジトリに存在しないラベルを指定した場合は、そのラベルが無視されるだけでIssue作成自体は成功する。

選んだラベルは、後述のコマンドの `--labels` に渡してください。複数選んだ場合はカンマ区切りの1つの文字列にし、省略する場合は `--labels` ごと外します。

# Issue作成ページをブラウザでオープン

まず、リポジトリURLを取得してください。

```bash
git remote get-url origin
```

取得したリモートURLからリポジトリURLを構成してください。

- SSH形式（`git@github.com:owner/repo.git`）: `git@github.com:` を `https://github.com/` に置換
- HTTPS形式（`https://github.com/owner/repo.git`）: そのまま使用

いずれの場合も末尾の `.git` は除去してください。

次に、Issueボディをスクラッチパッドなどの一時ファイルに Write で書き出してください。

最後に、`open_form.sh` で Issueボディを検査し、通ったときだけ Issue 作成ページを開いてください。ブラウザ起動コマンドはサンドボックス内では実行できないため、必ず`dangerouslyDisableSandbox: true`を指定して実行してください。

```bash
bash ~/.claude/skills/open-issue/scripts/open_form.sh issue --repo-url REPO_URL --title "Issueタイトル" --body-file ボディのファイル --template テンプレートのパス --labels "選択したラベル"
```

- `--template`: 選んだ Issue テンプレートのパス。テンプレートが無ければ外す
- `--allow-missing 見出し`: 任意の項目（補足など）で書く内容がなく、テンプレートの見出しごと削除したもの。複数あれば繰り返す

スクリプトは以下を検査し、1 つでも引っかかると exit 2 で指摘を出し、ページを開きません。
指摘に沿ってボディのファイルを Edit で直し、同じコマンドを再実行してください。
gitleaks・rumdl・typos のいずれかが入っていないと、その検査を飛ばして `warning:` を出します。そのときは、どの検査を飛ばしたかをユーザーに伝えてください。

- タイトルとボディに秘密情報が含まれていないか（gitleaks）
- ボディの Markdown の書式（rumdl）と、タイトル・ボディの typo（typos）
- テンプレートの `<!-- -->` コメントの消し残し、空のセクション、テンプレートの見出しの欠落
- URL が GitHub の上限（8000 バイト）を超えていないか

assignees は、GitHub ログイン名を保持する慣例的な git config キー `github.user` が設定済みならスクリプトが付けます。`user.name` は表示名（フルネーム等）が入っていて GitHub ログインと一致しないケースが多いため使いません。未設定なら assignees は省略されるので、Issue 作成ページで手動アサインしてもらってください。
