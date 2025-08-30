---
allowed-tools: Bash(gh:*), Bash(git:*), Read(CLAUDE.md), Edit(CLAUDE.md)
description: "Update Prompt Markdown based on PR review comments (PR Number Required)"
---

以下の手順でPull request(PR)のレビューコメントを確認し、対象のプロンプトファイル(CLAUDE.md)を更新してください。

1. PRコード外レビューコメントの内容確認
2. PRコード内レビューコメントの内容確認
3. プロンプトファイルの更新

# PRコード外レビューコメントの内容確認

以下コマンドでPRのコード外レビューコメントの内容を確認してください。`ARGUMENT`にはPRの番号を入力します。  

```bash
gh pr view $ARGUMENT --comments

```

# PRコード内レビューコメントの内容確認

以下コマンドでPRのコード内レビューコメントの内容を確認してください。`ARGUMENT`にはPRの番号を入力します。  

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

gh api "/repos/${GITHUB_OWNER}/${GITHUB_REPO}/pulls/$ARGUMENT/comments"
```

# プロンプトファイルの更新

確認したレビューコメントを踏まえて、プロンプトファイル`CLAUDE.md`の内容を更新してください。
