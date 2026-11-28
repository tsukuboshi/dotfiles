---
paths:
  - "**/{package.json,pyproject.toml,Cargo.toml,go.mod,mise.toml,.mise.toml,.tool-versions}"
  - "**/.github/workflows/*.{yml,yaml}"
---

# mise

パッケージやツールの最新版・公開日は、レジストリの API を curl で叩かずに mise で調べる。インストールも設定の変更もしない。

- 最新版: `mise latest <backend>:<name>`
- 公開日付きの一覧: `mise ls-remote --json <backend>:<name> | jq -c '[.[] | select(.prerelease | not)][-1]'`（`created_at` が公開日。GitHub はリリースの URL も付く）

| 調べる先 | backend の書き方 |
| --- | --- |
| GitHub Releases | `github:<owner>/<repo>` |
| npm | `npm:<package>` |
| PyPI | `pipx:<package>` |
| crates.io | `cargo:<crate>` |
| Go モジュール | `go:<module>` |
| aqua の登録ツール | `aqua:<owner>/<repo>` |

公開から日が浅い版を避けるときは `--minimum-release-age 7d` のように足す（`2024-06-01` のような日付も取る）。
