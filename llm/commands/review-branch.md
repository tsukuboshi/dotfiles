---
allowed-tools: Bash(git:*), Read(CLAUDE.md)
description: "Review branch diff without gh CLI (Default: main)"
argument-hint: [Base Branch]
---

以下の手順でブランチの差分をレビューしてください。

1. 現在のブランチ確認
2. ブランチ変更ファイル一覧の取得
3. ブランチ差分の取得
4. プロンプトファイルの内容確認
5. 差分内容のレビュー

# 現在のブランチ確認

以下のコマンドを使用して、現在のブランチを確認します。

```bash
git branch --show-current
```

# ブランチ変更ファイル一覧の取得

以下のコマンドを使用して、ベースブランチと現在のブランチ間の変更ファイル一覧を取得します。`ARGUMENT`にはベースブランチ名を入力します。指定がない場合は`main`を使用します。

```bash
git diff --name-status ${ARGUMENT:-main}...HEAD
```

# ブランチ差分の取得

以下のコマンドを使用して、詳細な差分を取得します。`ARGUMENT`にはベースブランチ名を入力します。指定がない場合は`main`を使用します。

```bash
git diff ${ARGUMENT:-main}...HEAD
```

# プロンプトファイルの内容確認

プロンプトファイル`CLAUDE.md`の内容を確認します。

# 差分内容のレビュー

取得した差分についてレビューを実施し、必要に応じて修正計画を立ててください。
レビューの観点についてはプロンプトファイルの内容を踏まえて確認してください。
