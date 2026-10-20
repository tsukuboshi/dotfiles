---
paths:
  - "**/*.go"
---

# Go

- リンタ: `golangci-lint run ./...`
- フォーマッタ: `golangci-lint fmt`
- 脆弱性検査: `govulncheck ./...`

ツールの版は次の順で解決する。`go.mod` の `tool` ディレクティブに宣言があれば `go tool <tool>` でプロジェクトの版を使い、なければ mise の版を使う。

`golangci-lint` はプロジェクトに `.golangci.yml` がなければ `standard` プリセット（`errcheck` / `govet` / `ineffassign` / `staticcheck` / `unused`）で検査し、`fmt` は `gofmt` で整形する。
`golangci-lint run` はパッケージ単位で型を解決するため、ファイル単体ではなくパッケージのディレクトリを渡す。ファイルを渡すと同じパッケージの他ファイルの宣言を解決できず、`typecheck` のエラーになる。
`govulncheck` はコールグラフを辿り、依存モジュールと標準ライブラリの既知の脆弱性のうち、実際に呼び出している関数に影響するものだけを報告する。脆弱性データベースを `vuln.go.dev` から取得するため、`go.mod` を変更したときに手動で実行する。
