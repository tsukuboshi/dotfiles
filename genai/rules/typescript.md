---
paths:
  - "**/*.{ts,tsx,js,jsx,json}"
---

# TypeScript / JavaScript / JSON

- リンタ: `biome check --fix`
- フォーマッタ: `biome format`
- 型チェック: `tsc --noEmit`

biome はプロジェクトの `node_modules/.bin` にあればそれを使い（`pnpm exec biome`）、なければ mise でグローバルに入れた版を使う。`biome.json` を持たないプロジェクトでは整形の対象外とする。
型チェックには Go 製の TypeScript 7 以降の `tsc` を使う。プロジェクトの `typescript` が 7 以降なら `pnpm exec tsc --noEmit` でプロジェクトの版を使い、6 以前か未導入なら mise でグローバルに入れた版（`tsc -v` で確認できる）を使う。`tsconfig.json` を持たないプロジェクトでは実行しない。
TypeScript 7 は 6.0 で非推奨になった `baseUrl` や `moduleResolution: node10` などを削除しているため、6 以前のプロジェクトで設定起因のエラーが出たときに限り `pnpm exec tsc --noEmit` でプロジェクトの版に戻す。
`files: []` と `references` だけを持つ solution-style の `tsconfig.json` は自身では何も検査しないため、参照先ごとに `tsc --noEmit -p <参照先の tsconfig>` で実行する。
