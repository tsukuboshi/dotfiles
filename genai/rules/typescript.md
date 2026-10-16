---
paths:
  - "**/*.{ts,tsx,js,jsx,json}"
---

# TypeScript / JavaScript / JSON

- リンタ: `biome check --fix`
- フォーマッタ: `biome format`
- 型チェック: `bun check`

biome はプロジェクトの `node_modules/.bin` にあればそれを使い（`pnpm exec biome`）、なければ mise でグローバルに入れた版を使う。`biome.json` を持たないプロジェクトでは整形の対象外とする。
型チェックには mise でグローバルに入れた bun の `bun check` を使う。typescript-go の移植で TypeScript 7 の `tsc --noEmit` と同じエラーを報告し、全 CPU コアで並列に検査する。`tsconfig.json` を持たないプロジェクトでは実行しない。
`bun check <ファイル>` は `tsconfig.json` を読んだまま、指定したファイルとその import 先だけを検査する。import 先のエラーも報告されるため、変更したファイルを渡しても触っていないファイルのエラーで exit 1 になることがある。
`files: []` と `references` だけを持つ solution-style の `tsconfig.json` は、引数なしの `bun check` が参照先を `tsc -b` と同様に辿って検査する。
TypeScript 7 は 6.0 で非推奨になった `baseUrl` や `moduleResolution: node10` などを削除しており、`bun check` も同じエラー（TS5102 など）を出す。プロジェクトの `typescript` が 6 以前で設定起因のエラーが出たときに限り `pnpm exec tsc --noEmit` でプロジェクトの版に戻す。
