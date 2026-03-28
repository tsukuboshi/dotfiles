---
name: aws-logs
description: "Investigate error logs from a specified CloudWatch Logs log group using filter-log-events"
argument-hint: "<profile|env-vars> <log-group-name> [hours|YYYY-MM-DD] [filter-pattern]"
---

# 引数の解決

`ARGUMENT`は以下の形式で指定されます。認証方式は引数の内容から自動判別してください。

## 方式A: aws-vault プロファイル

引数が `export AWS_` を含まない場合、先頭をaws-vaultプロファイル名として扱います。

```
# profile (必須): aws-vaultのプロファイル名
# log-group-name (必須): CloudWatch Logsのロググループ名
# hours|YYYY-MM-DD (任意): 遡る時間数 or 開始日（省略時: 1h）
# filter-pattern (任意): フィルタパターン（省略時: ERROR）
```

例:

- `tsukuboshi /aws/lambda/my-func` → 直近1時間の"ERROR"ログ
- `tsukuboshi /aws/lambda/my-func 24h` → 直近24時間の"ERROR"ログ
- `tsukuboshi /aws/lambda/my-func 2026-03-01` → 2026-03-01〜現在の"ERROR"ログ
- `tsukuboshi /aws/lambda/my-func 6h "TIMEOUT"` → 直近6時間の"TIMEOUT"ログ

## 方式B: 環境変数（export文）

引数が `export AWS_ACCESS_KEY_ID=...` 等の環境変数を含む場合、それらを使って直接認証します。
環境変数の後にロググループ名等をスペース区切りで指定してください。

例:

```
export AWS_ACCESS_KEY_ID=ASIA...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
export AWS_REGION=ap-northeast-1
export AWS_DEFAULT_REGION=ap-northeast-1
/aws/lambda/my-func 24h
```

引数に `export PS1=...` などAWS認証に無関係な行が含まれる場合は無視してください。

環境変数から以下の値を抽出してください:

- `AWS_ACCESS_KEY_ID`（必須）
- `AWS_SECRET_ACCESS_KEY`（必須）
- `AWS_SESSION_TOKEN`（任意）
- `AWS_REGION` または `AWS_DEFAULT_REGION`（任意、デフォルト: ap-northeast-1）

## 期間の指定

期間は以下のいずれかの形式で指定できます:

- **Nh（時間）**: `1h`, `6h`, `24h`, `72h` など → 現在からN時間前を開始時刻とする
- **Nd（日）**: `1d`, `7d`, `30d` など → 現在からN日前を開始時刻とする
- **YYYY-MM-DD**: 指定日の00:00:00 UTCを開始時刻、現在を終了時刻とする
- **省略時**: `1h`（直近1時間）

# 前提条件

- `aws` CLI がインストールされていること
- 方式Aの場合: `aws-vault` がインストールされていること
- CloudWatch Logs (`logs:FilterLogEvents`) へのアクセス権限があること

# AWS CLIコマンドの実行方法

認証方式によりコマンドのプレフィックスが異なります。以降のステップでは `<AWS_CMD>` と記載します。

**方式A（aws-vault）:**

```bash
<AWS_CMD> = aws-vault exec <profile> -- aws
```

**方式B（環境変数）:**

各コマンド実行前に環境変数をexportしてからawsコマンドを実行してください。

```bash
<AWS_CMD> = export AWS_ACCESS_KEY_ID=... && export AWS_SECRET_ACCESS_KEY=... && export AWS_SESSION_TOKEN=... && export AWS_REGION=... && aws
```

# Step 1: 認証の確認

認証が有効か確認してください。

```bash
<AWS_CMD> sts get-caller-identity
```

このコマンドが失敗した場合:

- 方式A: ユーザーにプロファイル名の確認や認証情報の設定を促してください
- 方式B: 認証情報の有効期限切れの可能性を伝え、新しい認証情報の取得を促してください

# Step 2: ロググループの存在確認

指定されたロググループが存在するか確認してください。

```bash
<AWS_CMD> logs describe-log-groups \
  --log-group-name-prefix "<log-group-name>" \
  --query "logGroups[?logGroupName=='<log-group-name>'].logGroupName" \
  --output text
```

存在しない場合は、プレフィックスに一致するロググループの候補を表示してください。

# Step 3: 期間の算出

macOS環境を前提にミリ秒のエポックタイムを算出してください。

- **開始時刻**: 引数に応じて算出（macOSでは `date -v-Nh +%s` 等を使用し、`000` を末尾に付与してミリ秒に変換）
- **終了時刻**: 現在時刻（`date +%s` に `000` を末尾に付与）

```bash
# 例: 直近24時間
START_TIME=$(( $(date -v-24H +%s) * 1000 ))
END_TIME=$(( $(date +%s) * 1000 ))
```

# Step 4: エラーログの取得

`filter-log-events` でエラーログを取得してください。結果が多い場合はページネーションで全件取得してください（ただし最大1000件まで）。

```bash
<AWS_CMD> logs filter-log-events \
  --log-group-name "<log-group-name>" \
  --start-time <start-time> \
  --end-time <end-time> \
  --filter-pattern "<filter-pattern>" \
  --max-items 1000 \
  --output json
```

**注意**: `--filter-pattern` はデフォルトで `ERROR` を使用します。ユーザーが明示的に指定した場合はその値を使用してください。

# Step 5: 分析結果の表示

取得したデータを以下のフォーマットで表示してください。

## 出力フォーマット

```
## CloudWatch Logs エラーログ調査レポート

**アカウント**: <account-id> / **プロファイル**: <profile>
**ロググループ**: <log-group-name>
**対象期間**: YYYY-MM-DD HH:MM 〜 YYYY-MM-DD HH:MM (JST)
**フィルタパターン**: <filter-pattern>
**ヒット件数**: XX件

### エラーサマリー

エラーメッセージをパターン分類し、出現頻度の多い順に表示してください。
類似のエラーメッセージはグルーピングしてください（スタックトレースやリクエストID等の動的部分を除外して判定）。

| # | エラーパターン | 件数 | 初回発生 (JST) | 最終発生 (JST) |
|---|--------------|------|---------------|---------------|
| 1 | TimeoutError: Task timed out after ... | XX | MM/DD HH:MM | MM/DD HH:MM |
| 2 | RuntimeError: Cannot connect to ... | XX | MM/DD HH:MM | MM/DD HH:MM |
| ... | ... | ... | ... | ... |

### 時間帯別エラー分布

エラーの発生を時間帯ごとに集計し、スパイクがある時間帯を特定してください。

| 時間帯 (JST) | 件数 | 備考 |
|-------------|------|------|
| MM/DD HH:00 | XX | |
| MM/DD HH:00 | XX | ⚠ スパイク |
| ... | ... | ... |

### エラーログ詳細（直近10件）

直近のエラーログを最大10件、新しい順に表示してください。

| # | 時刻 (JST) | ログストリーム | メッセージ（先頭200文字） |
|---|-----------|-------------|----------------------|
| 1 | MM/DD HH:MM:SS | <stream> | <message> |
| ... | ... | ... | ... |

### 分析コメント

以下の観点で簡潔にコメントしてください：
- 最も多いエラーパターンとその推定原因
- エラー発生に時間的な傾向があるか（特定時間帯に集中しているか）
- 即座に対応が必要そうなエラーがあるか
- 追加調査の提案（必要な場合のみ）
```

## 補足事項

- タイムスタンプはエポックミリ秒からJSTに変換して表示する
- エラーログが0件の場合は「指定期間内にフィルタパターンに一致するログは見つかりませんでした」と表示する
- エラーメッセージのグルーピングはベストエフォートで行い、完全な一致ではなくパターンの類似性で判断する
- 1000件を超えるエラーがある場合は、最新の1000件を取得した旨を明記し、期間を短くするよう提案する
