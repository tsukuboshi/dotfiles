---
paths:
  - "**/*.py"
---

# Python

- リンタ: `ruff check --fix`
- フォーマッタ: `ruff format`
- 型チェック: `ty check --project <.venv のあるディレクトリ>`

`ty` はサードパーティのパッケージを仮想環境から解決するため、`.venv` のないプロジェクトでは `unresolved-import` が多発する。`.venv` を持つプロジェクトでだけ実行する。
