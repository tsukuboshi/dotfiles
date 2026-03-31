---
name: aws-auth
description: "Authenticate to AWS and configure a named profile for the session (aws-vault or environment variables)"
argument-hint: "<profile|env-vars>"
---

# 引数の解決

`ARGUMENT`は以下の2つの認証方式に対応します。引数の内容から認証方式を自動判別してください。

## 方式A: aws-vault プロファイル

引数が `export AWS_` を含まない場合、aws-vaultプロファイル名として扱います。

例:

- `tsukuboshi`

## 方式B: 環境変数（export文）

引数が `export AWS_ACCESS_KEY_ID=...` 等の環境変数を含む場合、それらを使って認証します。

例:

```
export AWS_ACCESS_KEY_ID=ASIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
export AWS_REGION=ap-northeast-1
export AWS_DEFAULT_REGION=ap-northeast-1
```

引数に `export PS1=...` などAWS認証に無関係な行が含まれる場合は無視してください。

環境変数から以下の値を抽出してください:

- `AWS_ACCESS_KEY_ID`（必須）
- `AWS_SECRET_ACCESS_KEY`（必須）
- `AWS_SESSION_TOKEN`（任意）
- `AWS_REGION` または `AWS_DEFAULT_REGION`（任意、デフォルト: ap-northeast-1）

# 前提条件

- `aws` CLI がインストールされていること
- 方式Aの場合: `aws-vault` がインストールされていること

# Step 1: 一時クレデンシャルの取得

## 方式A（aws-vault）

aws-vaultから一時クレデンシャルを取得します。

```bash
aws-vault exec <profile> -- env | grep '^AWS_'
```

出力から以下の環境変数を抽出してください:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`
- `AWS_REGION` または `AWS_DEFAULT_REGION`

## 方式B（環境変数）

引数から直接抽出済みの値をそのまま使用します。

# Step 2: 認証の確認

取得したクレデンシャルで認証が有効か確認します。

```bash
export AWS_ACCESS_KEY_ID=<value> AWS_SECRET_ACCESS_KEY=<value> AWS_SESSION_TOKEN=<value> AWS_REGION=<region> && aws sts get-caller-identity
```

このコマンドが失敗した場合:

- 方式A: ユーザーにプロファイル名の確認やaws-vaultの認証情報の設定を促してください
- 方式B: 認証情報の有効期限切れの可能性を伝え、新しい認証情報の取得を促してください

# Step 3: AWS_CMD プレフィックスの確定

認証成功後、以降のAWSコマンドで使用するプレフィックス `<AWS_CMD>` を確定してください。

```bash
<AWS_CMD> = export AWS_ACCESS_KEY_ID=<value> && export AWS_SECRET_ACCESS_KEY=<value> && export AWS_SESSION_TOKEN=<value> && export AWS_REGION=<region> && aws
```

# Step 4: 結果の表示

認証成功時、以下の情報を表示してください。

```
AWS認証が完了しました。

- **アカウント**: <account-id>
- **ARN**: <arn>
- **リージョン**: <region>

以降のAWSコマンドでは確定した `<AWS_CMD>` プレフィックスを使用します。
```
