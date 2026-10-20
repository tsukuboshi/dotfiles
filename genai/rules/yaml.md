---
paths:
  - "**/*.{yml,yaml}"
---

# YAML

- リンタ: `ryl check --fix -d '{extends: default, rules: {line-length: {level: warning}}}'`
- 構文ルール: `ast-grep scan --config ~/dotfiles/genai/lint/ast-grep/sgconfig.yml <file>`
- Kubernetes マニフェスト: `kubeconform -strict -ignore-missing-schemas -schema-location default -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' <file>`

`ryl` は設定がないとルールを 1 つも有効にしないため、`-d` で yamllint の `default` プリセットを渡し、80 字の行長制限を warning に下げる。
プロジェクトに `.ryl.toml` / `ryl.toml` / `.config/.ryl.toml` / `.config/ryl.toml` / `.yamllint` / `.yamllint.yaml` / `.yamllint.yml` があれば、`-d` を付けずにその設定を使う。
`--fix` は warning の指摘も直すため、`---` のない文書には先頭に `---` が足される。
`ryl` は YAML 1.2 として解釈するため、`yes` / `no` / `on` / `off` は真偽値ではなく文字列として扱われる。
`apm.lock.yaml` や `pnpm-lock.yaml` などの lock ファイルは生成物のため対象外とする。
`ast-grep` は workflow の `run:` も含め、ホーム配下の絶対パスを検出する。GitHub Actions のランナーの `/home/runner/` は対象外とする。
`kubeconform` は行頭に `apiVersion:` と `kind:` があり、`{{` を含まないファイルだけを Kubernetes マニフェストとして検査する。Helm テンプレートは kubeconform が解釈できないため対象外とする。
`-strict` は存在しないフィールドを拒否し、フィールド名の typo を検出する。`-ignore-missing-schemas` により、Kubernetes 本体にも CRDs-catalog にもない kind（`Kustomization` や kind の `Cluster` など）は検査を飛ばす。
スキーマは `~/.cache/kubeconform` にキャッシュする。取得できないときはマニフェストの誤りではなく kubeconform を使えないものとして報告する。
