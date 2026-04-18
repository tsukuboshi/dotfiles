---
name: iam-auth
description: "Authenticate to AWS using aws-vault profile. Use this skill when the user mentions an aws-vault profile name or wants to switch AWS accounts via aws-vault."
argument-hint: "<profile>"
---

# 引数の解決

`ARGUMENT` をaws-vaultプロファイル名として扱います。

例:

- `tsukuboshi`

# 前提条件

- `aws` CLI がインストールされていること
- `aws-vault` がインストールされていること

# Step 1: 認証の確認

aws-vaultプロファイルで認証が有効か確認します。

```bash
aws-vault exec <profile> -- aws sts get-caller-identity
```

このコマンドが失敗した場合、ユーザーにプロファイル名の確認やaws-vaultの認証情報の設定を促してください。

成功した場合、リージョンも取得してください。

```bash
aws-vault exec <profile> -- aws configure get region
```

リージョンが取得できない場合はデフォルト `ap-northeast-1` を使用してください。

# Step 2: AWS_CMD プレフィックスの確定

以降のAWSコマンドで使用するプレフィックス `<AWS_CMD>` を確定してください。

Bashツールはコマンド間でシェル状態（環境変数）が永続しないため、毎回のコマンド実行時にプレフィックスとしてaws-vaultを使用します。`<AWS_CMD>` はシェル変数ではなく、以降のAWSコマンド実行時に毎回先頭に付与するプレフィックスパターンです。

```bash
<AWS_CMD> = aws-vault exec <profile> -- aws
```

# Step 3: 結果の表示

認証成功時、以下の情報を表示してください。

```text
AWS認証が完了しました。

- **プロファイル**: <profile>
- **アカウント**: <account-id>
- **ARN**: <arn>
- **リージョン**: <region>

以降のAWSコマンドでは確定した `<AWS_CMD>` プレフィックスを使用します。
```
