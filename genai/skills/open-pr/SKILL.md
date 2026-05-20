---
name: "open-pr"
description: "Create PR via GitHub Web UI without gh CLI (Compare Default: current branch, Base Default: reflog origin). Use this skill whenever the user wants to create a pull request, open a PR, or submit changes for review. This skill intentionally avoids gh CLI because its OAuth token requires broader permissions than necessary — instead it opens the GitHub Web UI directly."
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

# コミット履歴とベースブランチとの差分確認

以下の2つのコマンドは依存関係がないため、並列で実行してください。

```bash
git log --oneline BASE_BRANCH...COMPARE_BRANCH
```

```bash
git diff BASE_BRANCH...COMPARE_BRANCH
```

# PRテンプレートファイルの内容確認

以下の優先順でGlobで検索し、最初に見つかったファイルをReadで読み取ってください。ファイル名`pull_request_template`は大文字小文字不問。どちらにもない場合はスキップ。

1. `.github/pull_request_template*`
2. `${HOME}/dotfiles/.github/pull_request_template*`

# PRタイトルとボディの生成

コミット履歴、差分、PRテンプレートファイルの内容を元に、以下を生成してください。

## PRタイトル

変更内容の視点で書く。
「何をどう変更したか」を簡潔に表し、
Conventional Commits形式のプレフィックス（feat/fix/refactor等）を付ける。
create-commitスキルのtype選択基準に従うこと
（例: 「fix: セッション管理のタイムアウト処理を修正」「feat: ユーザー招待APIとUIを実装」）

## PRボディ

PRボディは「何をどう変えたか」「なぜその実装にしたか」「どう確認したか」を中心に書く。レビュアーが差分を読まなくても変更の輪郭と意図が掴めることがゴール。

### 必ず含める項目

- **概要**: 何を変更したかの1〜2行サマリ
- **実装方針**: 設計判断の理由や採用した方針（3〜5項目）
- **動作確認**: 確認手順 / テスト結果 / スクリーンショット参照（3〜6項目）
- **関連 Issue**: `Closes #N` / `Refs #N`（任意）

### PRテンプレートがある場合の扱い

PRテンプレートのセクション構成には従う。ただし以下のルールで運用する：

- 「必ず含める項目」（概要・実装方針・動作確認・関連 Issue）に相当するセクションは必ず埋める。テンプレートに該当セクションが無ければ、テンプレートに合わせた見出し名で追記してよい
- それ以外の任意セクション（例: レビュー観点、補足事項など）は、書くべき内容があるときだけ短く記載し、無ければ削除する（空セクションは残さない）
- いずれの場合も、各セクションは上記の粒度で要約する

### 含めないもの

GitHub の PR 作成エンドポイントは URL 全体で約 8KB が上限（超過すると `Whoa there! Your request URL is too long.` エラーになる）。日本語は URL エンコード後に 1 文字 = 9 バイトに膨らむため、本文は最初から簡潔に保つ。以下は PR 本文ではなく関連 Issue / コミットメッセージ / コード内コメント / リンク先ドキュメントに残す。

- コードブロックの長大な貼り付け（差分全文・ログ全文・スタックトレース全文など）
- コミットメッセージそのものの再掲（履歴から参照可能）
- 関数シグネチャやファイル単位の修正内容の詳細列挙

### 文字数の目安

- 日本語本文: **600文字以内**を目標
- 英語主体の本文: 2000文字以内を目標

生成後に本文が上記を超えていたら要約し直す。詳細が必要な情報は関連 Issue / コミットメッセージ / リンク先ドキュメントで参照させる。

# PR作成ページをブラウザでオープン

PRタイトルとPRボディをURLエンコードしてPR作成ページを開きます。

`eval`内でのヒアドキュメントやインライン複数行文字列はパースエラーの原因になるため使用しないでください。

まず、リポジトリURLと GitHub ログイン名を取得してください。

```bash
git remote get-url origin
```

```bash
git config github.user
```

`git config github.user` は GitHub ログイン名を保持する慣例的な git config キー（`gh` CLI に依存しない）。設定済みなら assignees に使う。`git config user.name` は表示名（フルネーム等）が入っていて GitHub ログインと一致しないケースが多いため使わない。`github.user` が未設定の場合は assignees を省略し、PR 作成ページで手動アサインしてもらう。

取得したリモートURLからリポジトリURLを構成してください。

- SSH形式（`git@github.com:owner/repo.git`）: `git@github.com:` を `https://github.com/` に置換
- HTTPS形式（`https://github.com/owner/repo.git`）: そのまま使用

いずれの場合も末尾の `.git` は除去してください。

最後に、PR作成ページを開いてください。ブラウザ起動コマンドはサンドボックス内では実行できないため、必ず`dangerouslyDisableSandbox: true`を指定して実行してください。PRタイトルとPRボディは`urlencode`関数でURLエンコードしてください。

`opener`関数は実行環境を判定し、適切なブラウザ起動コマンドにディスパッチします。

- macOS: `open`
- WSL: `explorer.exe`（`/proc/version`に`microsoft`が含まれるかで判定）
- その他Linux: `xdg-open`（存在する場合）
- フォールバック: URLを標準出力に表示

```bash
urlencode(){ printf '%s' "$1" | od -An -tx1 | tr -d ' \n' | sed 's/\(..\)/%\1/g'; }; opener(){ case "$(uname -s)" in Darwin) open "$1";; Linux) if grep -qi microsoft /proc/version 2>/dev/null; then explorer.exe "$1"; elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1"; else printf 'Open this URL: %s\n' "$1"; fi;; *) printf 'Open this URL: %s\n' "$1";; esac; }; GH_USER=$(git config github.user 2>/dev/null); QS_ASSIGNEES=""; [ -n "$GH_USER" ] && QS_ASSIGNEES="&assignees=$GH_USER"; opener "REPO_URL/compare/BASE_BRANCH...COMPARE_BRANCH?quick_pull=1&title=$(urlencode "PRタイトル")&body=$(urlencode "PRボディ")${QS_ASSIGNEES}"
```
