---
paths:
  - "**/*.py"
---

# Python

- リンタ: `ruff check --fix`
- フォーマッタ: `ruff format`
- 型チェック: `ty check --project <.venv のあるディレクトリ>`
- セキュリティ検査: `ruff check --extend-select S --extend-per-file-ignores '**/test_*.py:S101' --extend-per-file-ignores '**/*_test.py:S101' --extend-per-file-ignores '**/conftest.py:S101'`

ツールの版は次の順で解決する。`pyproject.toml` の `[dependency-groups]` / `[project.optional-dependencies]` に宣言があれば `uv run --no-sync <tool>` でプロジェクトの版を使い、なければ mise の版を使う。どちらにもなければ `uvx <tool>` で一時取得する。
`uv run` は実行前に lock と環境を自動同期するため、リンター実行がプロジェクトを書き換えないよう `--no-sync` を付ける（出典: <https://docs.astral.sh/uv/concepts/projects/sync>）。

`ty` はサードパーティのパッケージを仮想環境から解決するため、`.venv` のないプロジェクトでは `unresolved-import` が多発する。`.venv` を持つプロジェクトでだけ実行する。
`S` は Bandit を移植したルール群で、ハードコードされたパスワードや `shell=True` の `subprocess` 呼び出しなどを検出する。pytest は `assert` で検証するため、テストファイルでは `S101`（`assert` の使用）を除外する。
