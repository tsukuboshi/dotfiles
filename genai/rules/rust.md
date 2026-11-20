---
paths:
  - "**/*.rs"
---

# Rust

- リンタ: `cargo clippy --all-targets`
- フォーマッタ: `cargo fmt`

`cargo fmt` は `Cargo.toml` の `edition` を rustfmt に渡す。`rustfmt` を直接実行すると edition 2015 として構文解析し、`async` などを含むファイルでエラーになるため、`--edition` に crate の edition を指定する。
`rustfmt` は渡したファイルが `mod` で宣言した別ファイルのモジュールも整形する。止める `skip_children` は nightly 専用のため、1 ファイルだけ整形するときは stdin から渡す（例: `rustfmt --edition 2021 < src/lib.rs`）。
`cargo clippy` は crate 全体をビルドして検査する。`--all-targets` を付けないとテストや examples はビルドされず、検査もされない。
clippy の lint の設定は `Cargo.toml` の `[lints.clippy]`（ワークスペースでは `[workspace.lints.clippy]`）に書き、フック・CI・IDE のどこで動かす clippy にも同じ設定が効くようにする。
