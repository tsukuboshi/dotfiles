---
allowed-tools: Bash(gh:*), Bash(git:*), Read(.github/*)
description: "Check a GitHub Actions Failed Job"
---

以下の手順で直近のGitHub Actionsで失敗したJobのエラーログの失敗理由を分析してください。

1. 最新のGitHub Actions 失敗ジョブエラーのログの確認
2. プロンプトファイルの内容確認
3. エラーログのレビュー

# 最新のGitHub Actions 失敗ジョブエラーログの確認

以下のコマンドを使用して、最新のGitHub Actionsジョブのエラーログを確認します。  

```bash
gh run list --limit 1 --json databaseId --jq ".[0].databaseId" | xargs gh run view --log-failed | grep -A1 -B1 -i "error\|fail\|✘\|×"
```

# プロンプトファイルの内容確認

プロンプトファイル`CLAUDE.md`の内容を確認します。

# エラーログのレビュー

エラーログについて原因分析を実施し、必要に応じて修正計画を立ててください。
修正計画の観点についてはプロンプトファイルの内容を踏まえて確認してください。  
