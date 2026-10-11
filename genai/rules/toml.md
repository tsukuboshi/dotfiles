---
paths:
  - "**/*.toml"
---

# TOML

- リンタ: `taplo check`
- フォーマッタ: `taplo fmt`

`taplo check` は既定では構文だけを検査し、値の型やキー名は検証しない。
taplo 0.10.0 は SchemaStore のカタログを読み込めず、`--default-schema-catalogs` は失敗しても exit 0 で終わる。`pyproject.toml` などをスキーマで検証するときは `--schema https://json.schemastore.org/pyproject.json` のように URL を直接渡す。
プロジェクトに `.taplo.toml` / `taplo.toml` があれば、`taplo fmt` はその `[formatting]` 設定に従う。
taplo は対象ファイルごとに INFO ログを出すため、`RUST_LOG=error` を付けて実行する。
