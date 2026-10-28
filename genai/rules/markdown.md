---
paths:
  - "**/*.md"
---

# Markdown

- リンタ: `rumdl check --disable MD034,MD013,MD025,MD041`
- フォーマッタ: `rumdl check --fix --disable MD034,MD013,MD025,MD041`

MD034 は bare URL を書き換えるため、MD013 と MD025 は日本語の一文一行と Step ごとの h1 構造に合わないため無効化している。
MD041 は、frontmatter と指示文から始まる SKILL.md や、h2 から始まる PR テンプレート・サブディレクトリの README に合わないため無効化している。
