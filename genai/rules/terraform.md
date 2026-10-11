---
paths:
  - "**/*.{tf,tfvars}"
---

# Terraform

- リンタ: `terraform validate` / `tflint --recursive`
- フォーマッタ: `terraform fmt -recursive`
- セキュリティ検査: `trivy config --severity HIGH,CRITICAL .`

`tflint` は `.tflint.hcl` がなくても組み込みの Terraform ルールセットを `recommended` プリセットで有効にする。`--fix` は未使用の宣言を削除するため、自動修正には使わない。
`trivy config` はファイル単体だと他ファイルの変数やモジュールを解決できないため、モジュールのディレクトリを指定する。
