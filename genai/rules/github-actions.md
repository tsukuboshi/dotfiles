---
paths:
  - "**/.github/workflows/*.{yml,yaml}"
  - "**/action.{yml,yaml}"
---

# GitHub Actions

- リンタ: `actionlint`
- セキュリティ検査: `zizmor`

`actionlint` は workflow ファイルだけを引数に取る。`action.yml` は直接指定できず、workflow から参照されたときに検査されるため、`action.yml` には `zizmor` だけをかける。
`zizmor` は `GH_TOKEN` がないと offline モードで動き、`impostor-commit` などのオンライン audit を省略する。
