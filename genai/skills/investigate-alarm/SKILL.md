---
name: investigate-alarm
description: "Investigate AWS CloudWatch Alarm notifications. Use this skill when the user pastes a CloudWatch Alarm notification (from Slack, email, SNS, etc.) containing alarm name, account ID, region, and state information. Also trigger when the user asks to investigate or troubleshoot an AWS alarm, or mentions a specific alarm name they want to look into."
argument-hint: "<alarm-notification>"
---

## アラーム情報の抽出

ユーザーが貼り付けた通知から以下の情報を抽出する:

- `<ALARM_NAME>`: アラーム名
- `<ACCOUNT_ID>`: AWSアカウントID
- `<REGION>`: リージョン（デフォルト: `ap-northeast-1`）
- `<STATE>`: アラーム状態（ALARM, OK, INSUFFICIENT_DATA）
- `<REASON>`: 状態変更の理由（あれば）
- `<TIMESTAMP>`: アラーム発生時刻

## AWS認証

アラーム通知から抽出した `<ACCOUNT_ID>` を使い、`~/.aws/config` で `sso_account_id = <ACCOUNT_ID>` を含むプロファイルを検索する。

```bash
grep -B5 "sso_account_id\s*=\s*<ACCOUNT_ID>" ~/.aws/config | grep '\[profile ' | sed 's/\[profile //;s/\]//'
```

- プロファイルが1件見つかった場合: `<AWS_CMD> = aws --profile <PROFILE_NAME>`
- 複数見つかった場合: ユーザーに選択を促す

```bash
<AWS_CMD> sts get-caller-identity
```

失敗した場合、認証情報の期限切れまたは未設定の可能性をユーザーに伝え、AWS認証を促す。成功するまで調査に進まない。

## アラーム詳細の取得

以下の内容でアラーム詳細を取得する。

```bash
<AWS_CMD> cloudwatch describe-alarms --alarm-names "<ALARM_NAME>" --region <REGION>
```

以下を確認する:

- `MetricName` / `Namespace`: 監視対象のメトリクス
- `Threshold` / `ComparisonOperator` / `Period`: 閾値条件
- `AlarmActions`: 通知先のSNSトピック等
- `StateReason` / `StateReasonData`: 現在の状態と理由

## タイムスタンプの算出

`<TIMESTAMP>` からエポック秒を算出し、以降のステップで使用する変数を確定する。
手動計算は誤りの原因になるため、必ず `date` コマンドを使用すること。

```bash
EPOCH=$(date -j -u -f "%Y-%m-%dT%H:%M:%S+0000" "<TIMESTAMP>+0000" "+%s")
```

以降のステップでは以下の変数を使用する:

- メトリクス取得（前後30分）: `START_TIME` / `END_TIME`（ISO 8601形式）
- ログ取得（前後5分）: `START_MS` / `END_MS`（エポックミリ秒）

```bash
START_TIME=$(date -j -u -r $((EPOCH - 1800)) "+%Y-%m-%dT%H:%M:%SZ")
END_TIME=$(date -j -u -r $((EPOCH + 1800)) "+%Y-%m-%dT%H:%M:%SZ")
START_MS=$(( (EPOCH - 300) * 1000 ))
END_MS=$(( (EPOCH + 300) * 1000 ))
```

## アラーム種別の判定と分岐

取得した `Namespace` と `MetricName` からアラームの種別を判定し、調査フローを分岐する。

### リソースメトリクス系の場合

`Namespace` が `AWS/ECS`, `AWS/EC2`, `AWS/RDS`, `AWS/Lambda` 等のAWSサービス名前空間で、
`MetricName` が `CPUUtilization`, `MemoryUtilization`, `Duration`, `Throttles` 等のリソースメトリクスの場合。

→ **リソースメトリクスの調査** に進む

### エラーメトリクス系の場合

上記以外（カスタム名前空間、エラーカウント系メトリクス等）の場合。

→ **エラーメトリクスの発生源特定** に進む

## リソースメトリクスの調査

アラーム発生時刻の前後30分のメトリクスデータを取得し、推移を確認する。

```bash
<AWS_CMD> cloudwatch get-metric-statistics \
  --namespace "<Namespace>" \
  --metric-name "<MetricName>" \
  --dimensions <Dimensions> \
  --start-time $START_TIME \
  --end-time $END_TIME \
  --period 60 \
  --statistics Average Maximum \
  --region <REGION>
```

次に、対象リソースの現在の状態を確認する。`Dimensions` からリソースを特定し、該当するコマンドを実行する:

```bash
# ECSサービスの場合
<AWS_CMD> ecs describe-services --cluster "<cluster>" --services "<service>" --region <REGION>

# RDSの場合
<AWS_CMD> rds describe-db-instances --db-instance-identifier "<id>" --region <REGION> \
  --query "DBInstances[].{Status:DBInstanceStatus,Class:DBInstanceClass}"
```

直近のスケーリングイベントやデプロイがないかも確認する:

```bash
# ECSデプロイ履歴
<AWS_CMD> ecs describe-services --cluster "<cluster>" --services "<service>" --region <REGION> \
  --query "services[].deployments"

# Auto Scalingアクティビティ（対象リソースに絞る）
<AWS_CMD> application-autoscaling describe-scaling-activities \
  --service-namespace ecs \
  --resource-id "service/<cluster>/<service>" \
  --max-results 5 \
  --region <REGION>
```

→ **結果のサマリ** に進む

## エラーメトリクスの発生源特定

アラーム名やメトリクス名からリソースの種類を推定し、関連リソースを探索する。

### ログの特定と取得

発生源が判明したら、ログ出力先を特定する。

ECSタスクの場合:

```bash
# タスク定義からロググループを取得
<AWS_CMD> ecs describe-task-definition --task-definition "<task-def>" --region <REGION> \
  --query "taskDefinition.containerDefinitions[].{name:name,logConfig:logConfiguration}"
```

Lambda関数の場合: ロググループは `/aws/lambda/<function-name>`

ロググループが判明したら、アラーム発生時刻の前後5分のログを取得する。
CloudWatch Logs APIはスキャンしたデータ量に課金されるため、段階的に取得してコストを抑える。

### 第1段階: ERRORログのみ取得

```bash
<AWS_CMD> logs filter-log-events \
  --log-group-name "<log-group>" \
  --start-time $START_MS \
  --end-time $END_MS \
  --filter-pattern "ERROR" \
  --limit 50 \
  --region <REGION>
```

### 第2段階: ERRORが見つからない場合のみ

フィルタなしで再取得する。件数制限は必ず付ける。

```bash
<AWS_CMD> logs filter-log-events \
  --log-group-name "<log-group>" \
  --start-time $START_MS \
  --end-time $END_MS \
  --limit 50 \
  --region <REGION>
```

## 結果のサマリ

調査結果を以下の形式で表示する:

```text
## CloudWatch Alarm 調査結果

- **アラーム名**: <ALARM_NAME>
- **アカウント**: <ACCOUNT_ID>
- **リージョン**: <REGION>
- **発生時刻**: <TIMESTAMP>
- **アラーム種別**: リソースメトリクス系 / エラーメトリクス系

### 検出内容

<エラーメッセージ、またはメトリクス値の推移>

### 原因分析

<推定原因（エラーの場合はスタックトレースから、リソースの場合はスパイクの要因を分析）>

### 確認すべき点

<具体的な次のアクション>
```

# 補足

- 権限不足（AccessDenied）でコマンドが失敗した場合、その旨を記録して次のステップに進む。調査をブロックしない。
- ログが見つからない場合、ロググループ名のバリエーション（`/aws/ecs/...`, `/aws/lambda/...`, `/ecs/...`, カスタム名）を試す。
- アラームが `INSUFFICIENT_DATA` に戻っている場合でも、`<TIMESTAMP>` 周辺のログを調査する。
