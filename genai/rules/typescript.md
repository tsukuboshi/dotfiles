---
paths:
  - "**/*.{ts,tsx,js,jsx,json}"
---

# TypeScript / JavaScript / JSON

- リンタ: `biome check --fix`
- フォーマッタ: `biome format`

biome はプロジェクトの `node_modules/.bin` にあればそれを使い（`pnpm exec biome`）、なければ mise でグローバルに入れた版を使う。`biome.json` を持たないプロジェクトでは整形の対象外とする。
