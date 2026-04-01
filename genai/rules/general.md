# 公式ドキュメントの事前確認

命令の中に公式ドキュメントが存在するツール・技術の名前が含まれる場合、コードや設定を書く前に必ず以下の手順を実行すること：

1. context7 MCP を使って該当ツール・技術の公式ドキュメントを取得する
   - `resolve-library-id` でライブラリを特定する
   - `query-docs` でベストプラクティス・推奨パターン・APIリファレンスを確認する
2. 取得した公式ドキュメントの内容に基づいてコードや設定を書く
   - 非推奨（deprecated）なAPIや古いパターンを避ける
   - 公式が推奨する書き方・設定・構成に従う

対象はライブラリやフレームワークに限らず、公式ドキュメントがあるもの全てを含む：

- 言語ランタイム（Node.js, Python, Go など）
- フレームワーク（React, Next.js, FastAPI, Django, Gin など）
- ライブラリ（Prisma, Drizzle, Pydantic, Zod など）
- リンター / フォーマッター（ESLint, Biome, Ruff, Prettier, ShellCheck, shfmt など）
- ビルドツール / バンドラー（Vite, Webpack, Turbopack, esbuild など）
- パッケージマネージャー（npm, pnpm, Poetry, uv など）
- IaC / クラウドサービス（Terraform, AWS CDK, CloudFormation など）
- テストフレームワーク（Vitest, Pytest, testing-library など）
- CI/CD（GitHub Actions, CircleCI など）
- その他 CLI ツール・開発ツール全般

上記は例示であり、公式ドキュメントが存在するツール・技術であれば同様に対応すること。
