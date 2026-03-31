---
name: "review-branch"
description: "Review branch diff without gh CLI (Compare Default: current branch, Base Default: main). Use this skill whenever the user wants to review changes, check a diff, see what changed on a branch, or asks 'what did I change'. This skill intentionally avoids gh CLI because its OAuth token requires broader permissions than necessary."
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順でブランチの差分をレビューしてください。

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。

- 第一引数: Compare Branch名（未指定時は現在のブランチ）
- 第二引数: Base Branch名（未指定時は`main`）

第一引数が未指定の場合、以下のコマンドで現在のブランチ名を取得してください。

```bash
git branch --show-current
```

第一引数が指定された場合は`COMPARE_BRANCH`を`origin/第一引数`、未指定時は上記の出力をそのまま使用してください。
`BASE_BRANCH`は`origin/第二引数`（デフォルト: `origin/main`）としてください。

以降の手順では`${COMPARE_BRANCH}`と`${BASE_BRANCH}`を解決した値に置き換えて実行してください。

# ブランチのフェッチ

`COMPARE_BRANCH`がリモートブランチ（`origin/`始まり）の場合は両方を、ローカルブランチの場合はBase Branchのみフェッチします。失敗時はユーザーにブランチ名の確認を求めてください。

`COMPARE_BRANCH`が`origin/`始まりの場合:

```bash
git fetch origin BASE_BRANCHのブランチ名 COMPARE_BRANCHのブランチ名
```

`COMPARE_BRANCH`がローカルブランチの場合:

```bash
git fetch origin BASE_BRANCHのブランチ名
```

# コミットログと変更概要の取得

以下の3つのコマンドは依存関係がないため、並列で実行してください。

```bash
git log --oneline BASE_BRANCH...COMPARE_BRANCH
```

```bash
git diff --stat BASE_BRANCH...COMPARE_BRANCH
```

```bash
git diff BASE_BRANCH...COMPARE_BRANCH
```

# 差分内容のレビュー

`git diff --stat` の結果を確認し、変更ファイル数や差分行数が大きい場合（目安: 500行以上）は、ファイル単位で段階的にレビューしてください。その場合、`git diff BASE_BRANCH...COMPARE_BRANCH -- <file>` で個別にファイルを読み取ってください。

以下の観点でレビューを実施し、問題点や改善提案があれば報告してください。

- **正確性**: ロジックのバグ、エッジケースの見落とし、off-by-oneエラー等
- **セキュリティ**: インジェクション、認証情報の漏洩、入力検証の不足等
- **パフォーマンス**: 不要なループ、N+1クエリ、大量データの非効率な処理等
- **可読性・保守性**: 命名、複雑度、重複コード等
- **意図との整合性**: コミットメッセージや変更概要と実際の差分が一致しているか

問題がなければその旨を伝え、必要に応じて修正計画を立ててください。
