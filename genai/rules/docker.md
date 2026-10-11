---
paths:
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/*.dockerfile"
  - "**/Containerfile"
---

# Dockerfile

- リンタ: `hadolint --failure-threshold warning`
- セキュリティ検査: `trivy config --severity HIGH,CRITICAL <Dockerfile>`

`hadolint` の `info` レベルの指摘はスタイル上の助言のため、修正の対象を `warning` 以上に絞る。
