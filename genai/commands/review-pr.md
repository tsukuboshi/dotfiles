---
allowed-tools: Bash(gh:*), Bash(git:*), Read(CLAUDE.md)
description: "Review a Pull Request (PR Number Required)"
argument-hint: [PR Number]
---

以下の手順でPull request(PR)をレビューしてください。

1. 対象PRの内容確認
2. プロンプトファイルの内容確認
3. コミット内容のレビュー

# 対象PRの内容確認

以下のコマンドを使用して、対象PRの内容を確認します。`ARGUMENT`にはPRの番号を入力します。

```bash
gh pr diff $ARGUMENT
```

# プロンプトファイルの内容確認

プロンプトファイル`CLAUDE.md`の内容を確認します。

# コミット内容のレビュー

対象PRの内容についてレビューを実施し、必要に応じて修正計画を立ててください。
レビューの観点についてはプロンプトファイルの内容を踏まえて確認してください。
