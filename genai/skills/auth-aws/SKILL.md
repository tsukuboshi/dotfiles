---
name: auth-aws
description: "Authenticate to AWS using exported environment variables (e.g. from AWS SSO portal), or using an AWS CLI profile name (the default profile when no arguments are given) resolved by the current aws command (e.g. via 1Password CLI plugin). Use this skill when the user pastes export AWS_ACCESS_KEY_ID=... environment variables or AWS SSO credentials, names an AWS profile to use, or whenever the user asks to log in / authenticate to AWS (e.g. 「AWS認証して」「org_readでawsにログインして」), even without pasting credentials."
argument-hint: "[env-vars | profile-name]"
---

# 全体の流れ

`ARGUMENT` の内容で認証情報の取得元だけを切り替え、それ以外の手順は共通です。上から順に実行してください。

1. プロファイルパスの確定
2. 認証情報の取得（`ARGUMENT` が `export` 形式の環境変数なら A、それ以外はプロファイル名として B）
3. 認証の確認
4. 表示名の決定
5. ポリシーの取得と判定
6. 結果の表示

# プロファイルパスの確定

Bashツールで以下を実行し、出力をプロファイルファイルの絶対パス `<PROFILE_PATH>` として使用してください。

```bash
if [ -n "$SSO_PROFILE" ]; then
  echo "$SSO_PROFILE"
else
  tmp="${TMPDIR:-/tmp}"
  echo "${tmp%/}/sso_profile"
fi
```

フォールバックのパスは `common/.zshrc` の `SSO_PROFILE` 定義と一致させてください。zshプロンプトが同じファイルを読んでプロファイル名を表示するためです（書き込みから1時間で表示対象外になります）。

# 認証情報の取得

## A: `export` 形式の環境変数の場合

`ARGUMENT` が `export AWS_ACCESS_KEY_ID=...` 等の環境変数を含む場合、それらを使って認証します。

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

抽出した値を使い、Writeツールで `<PROFILE_PATH>` に以下の内容を書き込んでください。

```bash
export AWS_ACCESS_KEY_ID=<value>
export AWS_SECRET_ACCESS_KEY=<value>
export AWS_SESSION_TOKEN=<value>
export AWS_REGION=<region>
```

書き込み後、Bashツールで `chmod 600 <PROFILE_PATH>` を実行し、パーミッションを所有者のみに絞ってください。

## B: プロファイル名の場合

`ARGUMENT` を AWS CLI のプロファイル名 `<AWS_PROFILE_NAME>` として扱います。前後が `"` で囲まれていれば取り除いてください。`ARGUMENT` が空の場合は `default` とします。

Bashツールで `command aws configure list-profiles` を実行し、`<AWS_PROFILE_NAME>` が一覧にあるか確認してください。ない場合は一覧を示してユーザーにプロファイル名を質問し直してください。存在しないプロファイルを渡すと、1Password の認証を通った後でエラーになるためです。

`<AWS_PROFILE_NAME>` で `aws` コマンドが解決する認証情報を `aws configure export-credentials` で書き出し、`<PROFILE_PATH>` を作成します。認証情報をコンテキストに出さないため、出力はファイルへ直接リダイレクトし、内容を表示・Read しないでください。

まずBashツールで `command -v op` を実行し、1Password CLI の有無で実行するコマンドを切り替えます。

### `op` がある場合

`aws` が `op plugin run -- aws` のシェル関数になっている前提です。Claude Code の Bashツールには TTY がないため、`op plugin run` は認証情報の選択プロンプトで `interactive IO not available` となり失敗します。`expect` で疑似端末を与え、選択プロンプトに Enter を送って先頭の候補を選びます（`log_user 0` で `expect` の画面出力も抑止します）。

```bash
expect -c '
set timeout 60
log_user 0
spawn bash -c {umask 077; op plugin run -- aws configure export-credentials --profile <AWS_PROFILE_NAME> --format env > <PROFILE_PATH>}
expect {
  {Locate your AWS Access Key} { sleep 0.5; send "\r"; exp_continue }
  timeout { puts "timeout"; exit 2 }
  eof
}
lassign [wait] pid spawnid os_error value
exit $value
' && echo "export AWS_REGION=$(command aws configure get region --profile <AWS_PROFILE_NAME> || echo ap-northeast-1)" >> <PROFILE_PATH>
```

- `spawn` 先の bash には zsh の `aws` 関数が引き継がれないため、`op plugin run -- aws` を明示します
- 1Password プラグインは `--profile` で指定したプロファイルの `role_arn` を読み、ロールの引き受けまで行います
- リージョン取得は認証不要なので `command aws` で 1Password を経由させません

### `op` がない場合

`aws` が `<AWS_PROFILE_NAME>` に対して解決する認証情報（SSO、`credential_process` 等）をそのまま書き出します。

```bash
(
  umask 077
  aws configure export-credentials --profile <AWS_PROFILE_NAME> --format env > <PROFILE_PATH> &&
    echo "export AWS_REGION=$(aws configure get region --profile <AWS_PROFILE_NAME> || echo ap-northeast-1)" >> <PROFILE_PATH>
)
```

### 失敗した場合

どちらのコマンドも `umask 077` によりファイルを所有者のみ読み書き可能な状態で作成します。

コマンドが失敗またはタイムアウトした場合、MFA 入力など想定外のプロンプトが出ている可能性があります。ユーザーに以下を `!` プレフィックス付きでプロンプトに入力して実行するよう依頼し、完了を待ってから次に進んでください。

```bash
! (umask 077; aws configure export-credentials --profile <AWS_PROFILE_NAME> --format env > <PROFILE_PATH> && echo "export AWS_REGION=$(command aws configure get region --profile <AWS_PROFILE_NAME> || echo ap-northeast-1)" >> <PROFILE_PATH>)
```

# 認証の確認

書き込んだプロファイルファイルで認証が有効か確認します。

```bash
source <PROFILE_PATH> && aws sts get-caller-identity
```

このコマンドが失敗した場合、認証情報の有効期限切れの可能性を伝え、新しい認証情報の取得を促してください。

成功した場合、出力の `Account` と `Arn` を以降の手順で使います。ARN からプリンシパル名を以下のように抽出してください。

- `assumed-role/` を含む場合: `assumed-role/` と次の `/` の間をロール名 `<ROLE_NAME>` とする
  - 例: `arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_AdministratorAccess_abc123/user` → `AWSReservedSSO_AdministratorAccess_abc123`
- `:user/` を含む場合: 最後の `/` 以降を IAM ユーザー名 `<USER_NAME>` とする
  - 例: `arn:aws:iam::123456789012:user/dev/my-user` → `my-user`
- どちらも含まない場合（ルートユーザー等）: プリンシパル名なし

# 表示名の決定

zshプロンプトに表示する `AWS_PROFILE_DISPLAY` を、取得経路ごとに以下の優先順で決定してください。ユーザーへの質問は、候補がすべて得られない場合に限ります。

A（`export` 形式の環境変数）の場合:

1. 引数に `export PS1=...` が含まれる場合、PS1内の `(アカウントID プロファイル名)` 形式の括弧からプロファイル名を抽出する
   - 例: `export PS1="\n(123456789012 my-profile-name)\n[\t \u@\h \W]$ "` → `my-profile-name`
2. 抽出できない場合、ユーザーに質問して回答を得る

B（プロファイル名）の場合:

1. `<AWS_PROFILE_NAME>` が `default` 以外なら、その値を使う
2. `default` の場合、「認証の確認」で抽出した `<ROLE_NAME>` または `<USER_NAME>` を使う。`default` のままではどのアカウントか見分けられないため
3. プリンシパル名もない場合、ユーザーに質問して回答を得る

決定した値を以下のように整えてから使ってください。

- 前後が `"` で囲まれている場合（例: `"my-profile-name"`）、前後の `"` を取り除く
- 英数字と `-` `_` `.` 以外の文字を含む場合、使える文字だけの名前をユーザーに質問し直す。値はクォートせずに書き込み、`.zshrc` はその値をそのままプロンプトに表示するため、空白や `$` 等が含まれると `source` が壊れたり表示が崩れたりする

決定した値をBashツールで追記してください。

```bash
echo "export AWS_PROFILE_DISPLAY=<profile_name>" >> <PROFILE_PATH>
```

# ポリシーの取得と判定

`<ROLE_NAME>` がない場合（IAM ユーザーやルートユーザー）、このセクションをスキップし、`<POLICY_TYPE>` を `対象外（ロールではありません）` として「結果の表示」に進んでください。

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
