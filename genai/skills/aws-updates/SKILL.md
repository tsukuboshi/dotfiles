---
name: aws-updates
description: "Fetch AWS What's New updates from the past month and highlight those covered by the AWS Japan official blog"
argument-hint: "[YYYY-MM-DD]"
---

# 引数の解決

`ARGUMENT`は以下の引数を受け取ります。

```
# YYYY-MM-DD: 取得開始日（この日付以降のアップデートを取得する）
# 省略時: 1ヶ月前の日付をデフォルトとする
```

AWSの公式アップデート(What's New)から指定された開始日以降のアップデートを取得し、AWS公式ブログに対応する記事があるものを「注目アップデート」としてピックアップして紹介してください。

# Step 1: AWS内部APIからアップデート一覧を取得

以下のAWS内部APIを使って、指定された開始日以降のアップデートをページネーションしながら全件取得してください。

## APIの仕様

- **ベースURL**: `https://aws.amazon.com/api/dirs/items/search`
- **必須パラメータ**:
  - `item.directoryId=whats-new-v2`
  - `sort_by=item.additionalFields.postDateTime`
  - `sort_order=desc`
  - `size=25`（1ページあたりの件数）
  - `item.locale=en_US`
  - `page=0`（ページ番号、0始まり）

リクエストURL例：

```
https://aws.amazon.com/api/dirs/items/search?item.directoryId=whats-new-v2&sort_by=item.additionalFields.postDateTime&sort_order=desc&size=25&item.locale=en_US&page=0
```

## レスポンス構造

```json
{
  "metadata": { "count": 25, "totalHits": 18265 },
  "items": [
    {
      "item": {
        "id": "...",
        "additionalFields": {
          "headline": "タイトル",
          "headlineUrl": "URL",
          "postDateTime": "2026-03-27T16:00:00Z",
          "postBody": "本文(HTML)"
        }
      },
      "tags": [{ "id": "...", "name": "カテゴリ名" }]
    }
  ]
}
```

## 取得手順

WebFetchで各ページを取得し、以下のプロンプトでデータを抽出してください：

> 各アイテムの headline, headlineUrl, postDateTime を抽出してJSON配列で出力してください。全件出力してください。

`page=0` から開始し、取得したアイテムの `postDateTime` が開始日より古くなったらページネーションを終了してください。

**注意**: 効率のため、独立したページのリクエストは可能な限り並列で実行してください。目安として1ヶ月分は約7〜8ページ（175〜200件）程度です。

# Step 2: AWS Japan公式ブログの記事一覧を取得

同じAWS内部APIを使って、AWS Japan公式ブログ（`/jp/blogs/news/`）の指定された開始日以降の記事を取得してください。

## APIの仕様

- **ベースURL**: `https://aws.amazon.com/api/dirs/items/search`
- **必須パラメータ**:
  - `item.directoryId=blog-posts`
  - `sort_by=item.additionalFields.createdDate`
  - `sort_order=desc`
  - `size=25`（1ページあたりの件数）
  - `item.locale=ja_JP`
  - `tags.id=blog-posts%23category%23news`
  - `page=0`（ページ番号、0始まり）

リクエストURL例：

```
https://aws.amazon.com/api/dirs/items/search?item.directoryId=blog-posts&sort_by=item.additionalFields.createdDate&sort_order=desc&size=25&item.locale=ja_JP&tags.id=blog-posts%23category%23news&page=0
```

## レスポンス構造

```json
{
  "metadata": { "count": 25, "totalHits": 1508 },
  "items": [
    {
      "item": {
        "id": "...",
        "additionalFields": {
          "title": "ブログ記事タイトル",
          "link": "記事URL",
          "createdDate": "2026-03-27T00:00:00Z",
          "postExcerpt": "抜粋"
        }
      }
    }
  ]
}
```

## 取得手順

Step 1と同様にページネーションで開始日以降の記事を取得してください。WebFetchのプロンプト：

> 各アイテムの title, link, createdDate を抽出してJSON配列で出力してください。全件出力してください。

**注意**: Step 1とStep 2のAPI取得は互いに独立しているため、並列で実行してください。

# Step 3: アップデートとブログ記事のマッチング

Step 1で取得したアップデートとStep 2で取得したブログ記事を照合し、対応関係を特定してください。

## 除外するブログ記事

以下のようなまとめ記事はマッチング対象から**除外**してください：

- 「週刊AWS」シリーズ（タイトルに「週刊AWS」を含む記事）
- 「AWS Weekly Roundup」シリーズ（タイトルに「AWS Weekly Roundup」を含む記事）
- その他、複数アップデートをまとめた週次・月次のダイジェスト記事

これらは個別のアップデートに対する深掘り記事ではないため、マッチングの価値がありません。

## マッチング基準

個別のブログ記事のtitleのみを使って、以下の方法でアップデートとの対応を判定してください：

- アップデートのheadlineとブログ記事のtitleに含まれる**AWSサービス名**（例: "Amazon S3", "AWS Lambda", "Amazon Bedrock"）が一致するか
- **機能名やキーワード**が共通しているか（例: "サーバーレス", "Graviton", "リージョン拡張"）
- 1つのブログ記事が複数のアップデートに対応する場合がある
- 1つのアップデートに複数のブログ記事が対応する場合もある

# Step 4: ピックアップの作成と表示

ブログ記事が存在するアップデートを「注目アップデート」として、日付の新しい順に表示してください。

## 出力フォーマット

以下の形式で表示してください：

```
## AWS 注目アップデート ピックアップ（YYYY/MM/DD 〜 YYYY/MM/DD）

対象期間のアップデート全N件のうち、AWS Japan公式ブログで取り上げられたN件をピックアップしました。

### ピックアップ一覧

| # | アップデート | 日付 | 関連ブログ |
|---|-------------|------|-----------|
| 1 | [アップデートタイトル](URL) | YYYY/MM/DD | [ブログタイトル](URL) |
| 2 | [アップデートタイトル](URL) | YYYY/MM/DD | [ブログタイトル](URL) |
| ... | ... | ... | ... |

### 注目アップデートの概要

ピックアップした各アップデートについて、それぞれ2〜3文で概要を説明してください。
```

## 補足事項

- ブログ記事にマッチしなかったアップデートは一覧に含めない
- 1つのアップデートに複数のブログ記事がマッチした場合は、関連ブログ列にカンマ区切りで全て記載する
- 最後に集計対象期間と総アップデート数、ピックアップ数を表示する
