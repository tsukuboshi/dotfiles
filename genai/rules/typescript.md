---
paths:
  - "**/*.{ts,tsx,js,jsx,json}"
---

# TypeScript / JavaScript / JSON

- リンタ: `biome check --fix`
- フォーマッタ: `biome format`
- 型チェック: `bun check`

ツールの版は次の順で解決する。`package.json` の `devDependencies` / `scripts` に宣言があれば `pnpm exec <tool>` でプロジェクトの版を使い、なければ mise の版を使う。どちらにもなければ `npx <tool>` で一時取得する。
biome の設定（`biome.json` / `biome.jsonc`）を持つプロジェクトでは biome を、oxlint の設定（`.oxlintrc.json` / `.oxlintrc.jsonc` / `oxlint.config.ts` / `oxlint.config.mts`）を持つプロジェクトでは `oxlint --fix` を使い、両方を持つプロジェクトでは両方を実行する。どちらも持たないプロジェクトでは biome を既定の設定で使い、JSON は整形の対象外とする。
oxlint は設定を cwd からしか探さないため、設定のあるディレクトリで実行する。既定ルールの多くは warning で exit 0 になるため、指摘を拾うときは `--deny-warnings` を付ける。oxlint は JSON を検査しない。
型チェックには mise でグローバルに入れた bun の `bun check` を使う。typescript-go の移植で TypeScript 7 の `tsc --noEmit` と同じエラーを報告し、全 CPU コアで並列に検査する。`tsconfig.json` を持たないプロジェクトでは実行しない。
`bun check <ファイル>` は `tsconfig.json` を読んだまま、指定したファイルとその import 先だけを検査する。import 先のエラーも報告されるため、変更したファイルを渡しても触っていないファイルのエラーで exit 1 になることがある。
`files: []` と `references` だけを持つ solution-style の `tsconfig.json` は、引数なしの `bun check` が参照先を `tsc -b` と同様に辿って検査する。
TypeScript 7 は 6.0 で非推奨になった `baseUrl` や `moduleResolution: node10` などを削除しており、`bun check` も同じエラー（TS5102 など）を出す。プロジェクトの `typescript` が 6 以前で設定起因のエラーが出たときに限り `pnpm exec tsc --noEmit` でプロジェクトの版に戻す。
