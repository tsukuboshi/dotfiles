---
name: aws-cost
description: "Analyze AWS costs using Cost Explorer API"
argument-hint: "[YYYY-MM-DD]"
---

# 前提条件

- `/aws-auth` スキルで認証済みであること（未認証の場合は先に実行を促してください）
- Cost Explorer API (`ce:GetCostAndUsage`) へのアクセス権限があること

# 引数の解決

```
# YYYY-MM-DD (任意): 分析開始日（省略時: 当月1日）
```

例:

- （引数なし） → 当月1日〜今日のコスト分析
- `2026-02-15` → 2026-02-15〜今日のコスト分析

# Step 1: 期間の算出

以下のように期間を決定してください。

- **開始日（Start）**: 引数の `YYYY-MM-DD`（省略時: 当月1日）
- **終了日（End）**: 今日の日付（Cost Explorer APIのEndは排他的なので、今日のコストを含めるには翌日を指定）
- **比較期間**: 同じ日数分だけ開始日から遡った期間（例: 3/10〜3/28 = 18日間なら、比較期間は 2/20〜3/10）

# Step 2: サービス別コストの取得

```bash
<AWS_CMD> ce get-cost-and-usage \
  --time-period Start=<開始日>,End=<終了日の翌日> \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json
```

# Step 3: 日別コストの推移取得

```bash
<AWS_CMD> ce get-cost-and-usage \
  --time-period Start=<開始日>,End=<終了日の翌日> \
  --granularity DAILY \
  --metrics BlendedCost \
  --output json
```

# Step 4: 前期間比較データの取得

同じ日数分の直前期間のサービス別コストを取得してください。

```bash
<AWS_CMD> ce get-cost-and-usage \
  --time-period Start=<比較期間の開始日>,End=<開始日> \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json
```

**注意**: Step 2・3・4のAPIコールは互いに独立しているため、並列で実行してください。

# Step 5: 分析結果の表示

取得したデータを以下のフォーマットで表示してください。

## 出力フォーマット

```
## AWS コスト分析レポート

**アカウント**: <account-id>
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
