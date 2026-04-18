---
name: sso-auth
description: "Authenticate to AWS using exported environment variables (e.g. from AWS SSO portal). Use this skill when the user pastes export AWS_ACCESS_KEY_ID=... environment variables or AWS SSO credentials."
argument-hint: "<env-vars>"
---

# 引数の解決

`ARGUMENT` が `export AWS_ACCESS_KEY_ID=...` 等の環境変数を含むため、それらを使って認証します。

例:

```bash
export AWS_ACCESS_KEY_ID=ASIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
export AWS_REGION=ap-northeast-1
export AWS_DEFAULT_REGION=ap-northeast-1
```

環境変数から以下の値を抽出してください:

- `AWS_ACCESS_KEY_ID`（必須）
- `AWS_SECRET_ACCESS_KEY`（必須）
- `AWS_SESSION_TOKEN`（必須）
- `AWS_REGION` または `AWS_DEFAULT_REGION`（任意、デフォルト: `ap-northeast-1`）
- `AWS_PROFILE_DISPLAY`（必須）

`AWS_PROFILE_DISPLAY` は以下の優先順で取得してください:

1. 引数に `export PS1=...` が含まれる場合、PS1内の `(アカウントID プロファイル名)` 形式の括弧からプロファイル名を抽出する
  - 例: `export PS1="\n(123456789012 my-profile-name)\n[\t \u@\h \W]$ "` → `my-profile-name`
2. PS1が含まれない、または抽出できない場合、ユーザーに質問して回答を得てから次のステップに進む

# プロファイルファイルの書き込み

まずBashツールで `echo $SSO_PROFILE` を実行し、書き込み先の絶対パスを取得してください。
抽出（および必要に応じて質問で取得）した値を使い、Writeツールでその絶対パスに以下の内容を書き込んでください。

```bash
export AWS_ACCESS_KEY_ID=<value>
export AWS_SECRET_ACCESS_KEY=<value>
export AWS_SESSION_TOKEN=<value>
export AWS_REGION=<region>
export AWS_PROFILE_DISPLAY=<profile_name>
```

このファイルはzshrcのプロンプト関数 `_parse_aws_profile()` が参照し、ステータスラインにプロファイル名を表示します。
ファイルの更新時刻が12時間を超えると自動的に無視されます。

# 認証の確認

書き込んだプロファイルファイルで認証が有効か確認します。

```bash
source $SSO_PROFILE && aws sts get-caller-identity
```

このコマンドが失敗した場合、認証情報の有効期限切れの可能性を伝え、新しい認証情報の取得を促してください。

# 結果の表示

認証成功時、以下の情報を表示してください。

以降のAWSコマンドで使用するプレフィックス `<AWS_CMD>` を確定してください。
Bashツールはコマンド間でシェル状態（環境変数）が永続しないため、毎回のコマンド実行時にプレフィックスとして環境変数を設定します。`<AWS_CMD>` はシェル変数ではなく、以降のAWSコマンド実行時に毎回先頭に付与するプレフィックスパターンです。

```bash
<AWS_CMD> = source $SSO_PROFILE && aws
```

```text
AWS認証が完了しました。

- **プロファイル**: <profile_name>
- **アカウント**: <account-id>
- **ARN**: <arn>
- **リージョン**: <region>

以降のAWSコマンドでは確定した `<AWS_CMD>` プレフィックスを使用します。
```
