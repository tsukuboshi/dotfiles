---
paths:
  - "**/*.py"
---

# Python

- リンタ: `ruff check --fix`
- フォーマッタ: `ruff format`
- 型チェック: `ty check --project <.venv のあるディレクトリ>`
- セキュリティ検査: `ruff check --extend-select S --extend-per-file-ignores '**/test_*.py:S101' --extend-per-file-ignores '**/*_test.py:S101' --extend-per-file-ignores '**/conftest.py:S101'`

`ty` はサードパーティのパッケージを仮想環境から解決するため、`.venv` のないプロジェクトでは `unresolved-import` が多発する。`.venv` を持つプロジェクトでだけ実行する。
`S` は Bandit を移植したルール群で、ハードコードされたパスワードや `shell=True` の `subprocess` 呼び出しなどを検出する。pytest は `assert` で検証するため、テストファイルでは `S101`（`assert` の使用）を除外する。
