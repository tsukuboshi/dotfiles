---
paths:
  - "**/*.{yml,yaml}"
---

# YAML

- リンタ: `ryl check --fix -d '{extends: default, rules: {line-length: {level: warning}}}'`
- 構文ルール: `ast-grep scan --config ~/dotfiles/genai/lint/ast-grep/sgconfig.yml <file>`

`ryl` は設定がないとルールを 1 つも有効にしないため、`-d` で yamllint の `default` プリセットを渡し、80 字の行長制限を warning に下げる。
プロジェクトに `.ryl.toml` / `ryl.toml` / `.config/.ryl.toml` / `.config/ryl.toml` / `.yamllint` / `.yamllint.yaml` / `.yamllint.yml` があれば、`-d` を付けずにその設定を使う。
`--fix` は warning の指摘も直すため、`---` のない文書には先頭に `---` が足される。
`ryl` は YAML 1.2 として解釈するため、`yes` / `no` / `on` / `off` は真偽値ではなく文字列として扱われる。
`apm.lock.yaml` や `pnpm-lock.yaml` などの lock ファイルは生成物のため対象外とする。
`ast-grep` は workflow の `run:` も含め、ホーム配下の絶対パスを検出する。GitHub Actions のランナーの `/home/runner/` は対象外とする。
