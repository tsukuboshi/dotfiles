---
paths:
  - "**/*.py"
---

# Python

- リンタ: `ruff check --fix`
- フォーマッタ: `ruff format`
- 型チェック: `ty check <file>`（ファイルのディレクトリで実行する）
- セキュリティ検査: `ruff check --extend-select S --extend-per-file-ignores '**/test_*.py:S101' --extend-per-file-ignores '**/*_test.py:S101' --extend-per-file-ignores '**/conftest.py:S101'`
- 構文ルール: `ast-grep scan --config ~/dotfiles/genai/lint/ast-grep/sgconfig.yml <file>`

ツールの版は次の順で解決する。`pyproject.toml` の `[dependency-groups]` / `[project.optional-dependencies]` に宣言があれば `uv run --no-sync <tool>` でプロジェクトの版を使い、なければ mise の版を使う。どちらにもなければ `uvx <tool>` で一時取得する。
`uv run` は実行前に lock と環境を自動同期するため、リンター実行がプロジェクトを書き換えないよう `--no-sync` を付ける（出典: <https://docs.astral.sh/uv/concepts/projects/sync>）。

`ty` はカレントディレクトリから親へ `ty.toml` / `pyproject.toml` を辿ってプロジェクトのルートを決め、サードパーティのパッケージを、有効な仮想環境（`VIRTUAL_ENV`）、Conda 環境、そのルートの `.venv`、PATH 上の `python` の順に探した環境から解決する（出典: <https://docs.astral.sh/ty/modules/>）。そのためファイルのディレクトリで実行する。
`.venv` が無くても実行し、標準ライブラリだけのスクリプトも型を検査する。依存を入れていないプロジェクトではサードパーティの import が `unresolved-import` になるため、`uv sync` で `.venv` を作ってから直す。
`S` は Bandit を移植したルール群で、ハードコードされたパスワードや `shell=True` の `subprocess` 呼び出しなどを検出する。pytest は `assert` で検証するため、テストファイルでは `S101`（`assert` の使用）を除外する。
`ast-grep` は ruff が持たないルールだけを検査し、テスト以外のホーム配下の絶対パスを検出する。
プロジェクトに `sgconfig.yml` があれば、`--config` を付けずにその設定を使う。
