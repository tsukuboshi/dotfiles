---
paths:
  - "**/*.md"
---

# Markdown

- リンタ: `rumdl check --disable MD034,MD013,MD025`
- フォーマッタ: `rumdl check --fix --disable MD034,MD013,MD025`

MD034 は bare URL を書き換えるため、MD013 と MD025 は日本語の一文一行と Step ごとの h1 構造に合わないため無効化している。
