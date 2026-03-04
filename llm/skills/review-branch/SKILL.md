---
allowed-tools: Bash(git:*)
description: "Review branch diff without gh CLI (Compare Default: current branch, Base Default: main)"
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順でブランチの差分をレビューしてください。

1. 引数の解決
2. ブランチのフェッチ
3. ブランチ変更ファイル一覧の取得
4. ブランチ差分の取得
5. 差分内容のレビュー

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。未指定の場合はデフォルト値を使用します。

- 第一引数: Compare Branch名（未指定の場合は`git branch --show-current`で現在のブランチ名を取得して使用）
- 第二引数: Base Branch名（未指定の場合は`main`を使用）

# ブランチのフェッチ

Base BranchとCompare Branchをリモートからフェッチして最新の状態にします。
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
