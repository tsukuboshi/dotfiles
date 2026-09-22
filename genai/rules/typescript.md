---
paths:
  - "**/*.{ts,tsx,js,jsx,json}"
---

# TypeScript / JavaScript / JSON

- リンタ: `pnpm exec biome check --fix`
- フォーマッタ: `pnpm exec biome format`

biome はプロジェクトの `node_modules/.bin` から解決する。`biome.json` を持たないプロジェクトでは整形の対象外とする。
