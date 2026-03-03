---
allowed-tools: Bash(git:*)
description: "Review branch diff without gh CLI (Default: main)"
argument-hint: "<Compare Branch> [Base Branch]"
---

以下の手順でブランチの差分をレビューしてください。

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。
- 第一引数: Compare Branch名（比較対象ブランチ、必須）
- 第二引数: Base Branch名（未指定の場合は`main`をデフォルトとして使用）

1. ブランチのフェッチ
2. ブランチ変更ファイル一覧の取得
3. ブランチ差分の取得
4. 差分内容のレビュー

# ブランチのフェッチ

`ARGUMENT`の第一引数（Compare Branch）が指定されていない場合は、エラーとしてユーザーにCompare Branchの指定を求めてください。

Base Branch（第二引数、未指定の場合は`main`）とCompare Branch（第一引数）をリモートからフェッチして最新の状態にします。
フェッチに失敗した場合は、リモートにブランチが存在しない可能性があるため、ユーザーにブランチ名の確認を求めてください。

```bash
git fetch origin ${Base Branch or main} ${Compare Branch}
```

# ブランチ変更ファイル一覧の取得

以下のコマンドを使用して、Base BranchとCompare Branch間の変更ファイル一覧を取得します。

```bash
git diff --name-status origin/${Base Branch or main}...origin/${Compare Branch}
```

# ブランチ差分の取得

以下のコマンドを使用して、詳細な差分を取得します。

```bash
git diff origin/${Base Branch or main}...origin/${Compare Branch}
```

# 差分内容のレビュー

取得した差分についてレビューを実施し、必要に応じて修正計画を立ててください。
