---
name: aws-cost
description: "Analyze AWS costs using Cost Explorer API (aws-vault or environment variables)"
argument-hint: "<profile|env-vars> [YYYY-MM-DD]"
---

# 引数の解決

`ARGUMENT`は以下の2つの認証方式に対応します。引数の内容から認証方式を自動判別してください。

## 方式A: aws-vault プロファイル

引数が `export AWS_` を含まない場合、aws-vaultプロファイル名として扱います。

```
# profile (必須): aws-vaultのプロファイル名
# YYYY-MM-DD (任意): 分析開始日（省略時: 当月1日）
```

例:

- `tsukuboshi` → tsukuboshiプロファイルで当月1日〜今日のコスト分析
- `tsukuboshi 2026-02-15` → 2026-02-15〜今日のコスト分析

## 方式B: 環境変数（export文）

引数が `export AWS_ACCESS_KEY_ID=...` 等の環境変数を含む場合、それらを使って直接認証します。
`YYYY-MM-DD` は環境変数の後にスペース区切りで指定できます。

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
- Cost Explorer API (`ce:GetCostAndUsage`) へのアクセス権限があること

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

# Step 2: 期間の算出

以下のように期間を決定してください。

- **開始日（Start）**: 引数の `YYYY-MM-DD`（省略時: 当月1日）
- **終了日（End）**: 今日の日付（Cost Explorer APIのEndは排他的なので、今日のコストを含めるには翌日を指定）
- **比較期間**: 同じ日数分だけ開始日から遡った期間（例: 3/10〜3/28 = 18日間なら、比較期間は 2/20〜3/10）

# Step 3: サービス別コストの取得

```bash
<AWS_CMD> ce get-cost-and-usage \
  --time-period Start=<開始日>,End=<終了日の翌日> \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json
```

# Step 4: 日別コストの推移取得

```bash
<AWS_CMD> ce get-cost-and-usage \
  --time-period Start=<開始日>,End=<終了日の翌日> \
  --granularity DAILY \
  --metrics BlendedCost \
  --output json
```

# Step 5: 前期間比較データの取得

同じ日数分の直前期間のサービス別コストを取得してください。

```bash
<AWS_CMD> ce get-cost-and-usage \
  --time-period Start=<比較期間の開始日>,End=<開始日> \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json
```

**注意**: Step 3・4・5のAPIコールは互いに独立しているため、並列で実行してください。

# Step 6: 分析結果の表示

取得したデータを以下のフォーマットで表示してください。

## 出力フォーマット

```
## AWS コスト分析レポート

**アカウント**: <account-id> / **プロファイル**: <profile>
**対象期間**: YYYY-MM-DD 〜 YYYY-MM-DD（XX日間）
**比較期間**: YYYY-MM-DD 〜 YYYY-MM-DD（同日数）

### サービス別コストサマリー

| # | サービス | コスト (USD) | 前期間比 | 構成比 |
|---|---------|-------------|---------|-------|
| 1 | Amazon EC2 | $XX.XX | +XX% | XX.X% |
| 2 | Amazon S3 | $XX.XX | -XX% | XX.X% |
| ... | ... | ... | ... | ... |
| | **合計** | **$XXX.XX** | **+XX%** | **100%** |

### 日別コスト推移

日別コストを表形式で表示してください。
急激な増加がある日はその日を強調し、原因として考えられるサービスを注記してください。

| 日付 | コスト (USD) | 備考 |
|------|-------------|------|
| MM/DD | $XX.XX | |
| MM/DD | $XX.XX | ⚠ 前日比+50%: EC2スパイク |
| ... | ... | ... |

### 分析コメント

以下の観点で簡潔にコメントしてください：
- コストの上位3サービスとその傾向
- 前期間比で大きく変動したサービス（±20%以上）
- 日別推移で異常値がある場合の指摘
- コスト最適化の提案（明らかな無駄がある場合のみ）
```

## 補足事項

- コストが$0.01未満のサービスは「その他」としてまとめる
- コストの降順でソートする
- 比較期間データが取得できない場合（新規アカウント等）は前期間比を「-」と表示する
