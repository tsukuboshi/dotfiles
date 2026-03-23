---
description: "Review branch diff without gh CLI (Compare Default: current branch, Base Default: main)"
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

# コミットログの取得

```bash
git log --oneline BASE_BRANCH...COMPARE_BRANCH
```

# ブランチ変更概要の取得

```bash
git diff --stat BASE_BRANCH...COMPARE_BRANCH
```

# ブランチ差分の取得

```bash
git diff BASE_BRANCH...COMPARE_BRANCH
```

# 差分内容のレビュー

取得した差分についてレビューを実施し、必要に応じて修正計画を立ててください。
