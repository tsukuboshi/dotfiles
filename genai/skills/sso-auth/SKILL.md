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

# プロファイルパスの確定

プロファイルファイルの絶対パス `<PROFILE_PATH>` を以下の優先順で決定してください。

1. 現在のシェル環境に `SSO_PROFILE` が設定されている場合: その値を使用
2. 未設定の場合: Bashツールで `echo "${TMPDIR%/}/sso_profile"` を実行し、出力をパスとして使用

以降のステップではこの確定パスを `<PROFILE_PATH>` として参照します。

# プロファイルファイルの書き込み

抽出（および必要に応じて質問で取得）した値を使い、Writeツールで `<PROFILE_PATH>` に以下の内容を書き込んでください。

```bash
export AWS_ACCESS_KEY_ID=<value>
export AWS_SECRET_ACCESS_KEY=<value>
export AWS_SESSION_TOKEN=<value>
export AWS_REGION=<region>
export AWS_PROFILE_DISPLAY=<profile_name>
```

# 認証の確認とロールの取得

書き込んだプロファイルファイルで認証が有効か確認します。

```bash
source <PROFILE_PATH> && aws sts get-caller-identity
```

このコマンドが失敗した場合、認証情報の有効期限切れの可能性を伝え、新しい認証情報の取得を促してください。

ARN が `assumed-role/` を含む場合、`assumed-role/` と次の `/` の間の文字列をロール名 `<ROLE_NAME>` として抽出してください。

- 例: `arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_AdministratorAccess_abc123/user` → `AWSReservedSSO_AdministratorAccess_abc123`

ARN に `assumed-role/` が含まれない場合、このセクション全体をスキップし、`<POLICY_TYPE>` を `対象外（ロールではありません）` として「結果の表示」に進んでください。

# ポリシーの取得と判定

以下のコマンドを実行してください:

```bash
source <PROFILE_PATH> && aws iam list-attached-role-policies --role-name <ROLE_NAME>
```

出力の `AttachedPolicies[].PolicyArn` を確認し、`<POLICY_TYPE>` を以下のルールで決定してください:

- いずれかの PolicyArn に `AdministratorAccess` を含む → `AdministratorAccess`
- いずれかの PolicyArn に `ReadOnlyAccess` を含む → `ReadOnlyAccess`
- 上記のいずれにも該当しない → `その他`（実際のポリシー名をカンマ区切りでリスト）

このコマンドが失敗した場合（AccessDenied等）、認証フローをブロックしないでください。`<POLICY_TYPE>` を `不明（IAM権限不足のため取得できませんでした）` として「結果の表示」に進んでください。

# 結果の表示

認証成功時、以下の情報を表示してください。

以降のAWSコマンドで使用するプレフィックス `<AWS_CMD>` を確定してください。
Bashツールはコマンド間でシェル状態（環境変数）が永続しないため、毎回のコマンド実行時にプレフィックスとして環境変数を設定します。`<AWS_CMD>` はシェル変数ではなく、以降のAWSコマンド実行時に毎回先頭に付与するプレフィックスパターンです。

```bash
<AWS_CMD> = source <PROFILE_PATH> && aws
```

```text
AWS認証が完了しました。

- **プロファイル**: <profile_name>
- **アカウント**: <account-id>
- **ARN**: <arn>
- **リージョン**: <region>
- **ポリシータイプ**: <POLICY_TYPE>

以降のAWSコマンドでは確定した `<AWS_CMD>` プレフィックスを使用します。
```
