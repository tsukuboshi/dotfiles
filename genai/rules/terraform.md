---
paths:
  - "**/*.{tf,tfvars}"
---

# Terraform

- リンタ: `terraform validate` / `tflint --recursive`
- フォーマッタ: `terraform fmt -recursive`

`tflint` は `.tflint.hcl` がなくても組み込みの Terraform ルールセットを `recommended` プリセットで有効にする。`--fix` は未使用の宣言を削除するため、自動修正には使わない。
