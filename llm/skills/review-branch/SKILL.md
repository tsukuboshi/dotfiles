---
allowed-tools: Bash(git:*), Read(CLAUDE.md)
description: "Review branch diff without gh CLI (Default: main)"
argument-hint: [Review Branch]
---

以下の手順でブランチの差分をレビューしてください。

1. レビュー対象ブランチへの切り替え
2. ブランチ変更ファイル一覧の取得
3. ブランチ差分の取得
4. プロンプトファイルの内容確認
5. 差分内容のレビュー

# レビュー対象ブランチへの切り替え

`ARGUMENT`が指定されていない場合は、このステップをスキップして現在のブランチでレビューを行います。

`ARGUMENT`でレビュー対象のブランチ名が指定された場合、リモートからフェッチしてそのブランチに切り替えます。

```bash
git fetch origin ${ARGUMENT}
git branch --list ${ARGUMENT}
```

ローカルにブランチが存在しない場合：

```bash
git switch -c ${ARGUMENT} origin/${ARGUMENT}
```

ローカルにブランチが存在する場合：

```bash
git switch ${ARGUMENT}
```

# ブランチ変更ファイル一覧の取得

以下のコマンドを使用して、`main`ブランチと現在のブランチ間の変更ファイル一覧を取得します。

```bash
git diff --name-status main...HEAD
```

# ブランチ差分の取得

以下のコマンドを使用して、詳細な差分を取得します。

```bash
git diff main...HEAD
```

# プロンプトファイルの内容確認

プロンプトファイル`CLAUDE.md`の内容を確認します。

# 差分内容のレビュー

取得した差分についてレビューを実施し、必要に応じて修正計画を立ててください。
レビューの観点についてはプロンプトファイルの内容を踏まえて確認してください。
