---
allowed-tools: Bash(gh:*), Bash(git:*), Read(CLAUDE.md), Edit(CLAUDE.md)
description: "Update Prompt Markdown based on PR review comments (PR Number Required)"
---

以下の手順でPull request(PR)のレビューコメントを確認し、対象のプロンプトファイル(CLAUDE.md)を更新してください。

1. PRレビューコメントの確認
2. プロンプトファイルの更新

# PRレビューコメントの内容確認

以下コマンドでPRのレビューコメントの内容を確認してください。`ARGUMENT`にはPRの番号を入力します。

```bash
REPO_URL=$(git config --get remote.origin.url)
if [[ $REPO_URL == git@github.com:* ]]; then
  # SSH形式: git@github.com:owner/repo.git
  GITHUB_PATH=${REPO_URL#git@github.com:}
  GITHUB_PATH=${GITHUB_PATH%.git}
else
  # HTTPS形式: https://github.com/owner/repo.git
  GITHUB_PATH=${REPO_URL#https://github.com/}
  GITHUB_PATH=${GITHUB_PATH%.git}
fi
GITHUB_OWNER=$(echo $GITHUB_PATH | cut -d'/' -f1)
GITHUB_REPO=$(echo $GITHUB_PATH | cut -d'/' -f2)

gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/${GITHUB_OWNER}/${GITHUB_REPO}/pulls/$ARGUMENT/comments
```

# プロンプトファイルの更新

確認したレビューコメントを踏まえて、プロンプトファイル`CLAUDE.md`の内容を更新してください。
