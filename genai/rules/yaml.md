---
paths:
  - "**/*.{yml,yaml}"
---

# YAML

- リンタ: `yamllint -d '{extends: default, rules: {line-length: {level: warning}}}'`

プロジェクトに `.yamllint` / `.yamllint.yaml` / `.yamllint.yml` があれば、`-d` を付けずにその設定を使う。`-d` では 80 字の行長制限を warning に下げる。
`apm.lock.yaml` や `pnpm-lock.yaml` などの lock ファイルは生成物のため対象外とする。
