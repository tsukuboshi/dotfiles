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

引数に `export PS1=...` が含まれる場合、PS1の値からAWSプロファイル名を抽出してください。
プロファイル名はPS1内の `(アカウントID プロファイル名)` 形式の括弧内にあります。

例: `export PS1="\n(123456789012 my-profile-name)\n[\t \u@\h \W]$ "` → プロファイル名は `my-profile-name`

それ以外のAWS認証に無関係な行は無視してください。

環境変数から以下の値を抽出してください:

- `AWS_ACCESS_KEY_ID`（必須）
- `AWS_SECRET_ACCESS_KEY`（必須）
- `AWS_SESSION_TOKEN`（任意）
- `AWS_REGION` または `AWS_DEFAULT_REGION`（任意、デフォルト: `ap-northeast-1`）
- PS1から抽出したプロファイル名（任意）

抽出後、Writeツールを使って `/tmp/aws_profile` に以下の内容を書き込んでください。

```bash
export AWS_ACCESS_KEY_ID=<value>
export AWS_SECRET_ACCESS_KEY=<value>
export AWS_SESSION_TOKEN=<value>
export AWS_REGION=<region>
export AWS_PROFILE_DISPLAY=<profile_name>
```

PS1からプロファイル名を抽出できなかった場合は、ユーザーにプロファイル名を質問してください。
回答を得たらその値を `AWS_PROFILE_DISPLAY` に設定してください。

このファイルはzshrcのプロンプト関数 `_parse_aws_profile()` が参照し、ステータスラインにプロファイル名を表示します。
ファイルの更新時刻が12時間を超えると自動的に無視されます。

# 前提条件

- `aws` CLI がインストールされていること

# Step 1: 認証の確認

書き込んだプロファイルファイルで認証が有効か確認します。

```bash
source /tmp/aws_profile && aws sts get-caller-identity
```

このコマンドが失敗した場合、認証情報の有効期限切れの可能性を伝え、新しい認証情報の取得を促してください。

# Step 2: AWS_CMD プレフィックスの確定

以降のAWSコマンドで使用するプレフィックス `<AWS_CMD>` を確定してください。

Bashツールはコマンド間でシェル状態（環境変数）が永続しないため、毎回のコマンド実行時にプレフィックスとして環境変数を設定します。`<AWS_CMD>` はシェル変数ではなく、以降のAWSコマンド実行時に毎回先頭に付与するプレフィックスパターンです。

```bash
<AWS_CMD> = source /tmp/aws_profile && aws
```

# Step 3: 結果の表示

認証成功時、以下の情報を表示してください。

```text
AWS認証が完了しました。

- **プロファイル**: <profile_name>
- **アカウント**: <account-id>
- **ARN**: <arn>
- **リージョン**: <region>

以降のAWSコマンドでは確定した `<AWS_CMD>` プレフィックスを使用します。
```

プロファイル名は必ず表示してください（PS1から抽出、またはユーザーへの質問で取得済み）。
