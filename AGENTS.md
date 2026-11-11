# dotfiles

## トランクベース開発

このリポジトリは 1 人で保守するため、変更は `main` へ直接、小さな単位でコミットする。

- `create-commit` はコミット先ブランチの確認を省き、`main` にコミットする。
- CI は `main` への push と週 1 回の定期実行で走る。`pull_request` でも走るが、`main` へ直接コミットするため、通常は push 後の検査になる。
- push 前に手元で確かめるときは `.github/scripts/` の `test-*.sh` と `lint-tracked-files.sh` を実行する。
