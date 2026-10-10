---
paths:
  - "**/*.sql"
---

# SQL

- リンタ: `sqruff lint`
- フォーマッタ: `sqruff fix`

プロジェクトに `.sqruff` があればその設定を使う。無ければ `core` ルールと `ansi` 方言で検査するため、PostgreSQL や BigQuery など方言固有の構文を使うプロジェクトでは `.sqruff` に `dialect` を指定する。
