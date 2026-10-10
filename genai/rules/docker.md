---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.dockerfile"
  - "**/Containerfile"
---

# Dockerfile

- リンタ: `hadolint --failure-threshold warning`
- セキュリティ検査: `trivy config --severity HIGH,CRITICAL <Dockerfile>` / `checkov -f <Dockerfile>`

`hadolint` の `info` レベルの指摘はスタイル上の助言のため、修正の対象を `warning` 以上に絞る。
`checkov` は 1 回の実行に 10 秒以上かかるため編集のたびには走らせず、変更をまとめ終えたときにかける。
