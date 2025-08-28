---
allowed-tools: Bash(gh:*), Bash(git:*), Read(.github/PULL_REQUEST_TEMPLATE.md)
description: "Push a Pull Request Draft (PR Number Optional)"
---

以下の手順で新しいPull request(PR)を作成してください。

1. リモートリポジトリの状態確認
2. 直前コミットの内容確認
3. 手本PRの内容確認
4. 新規PRの作成
5. 新規PRのブラウザ確認

# リモートリポジトリの状態確認

以下のコマンドを使用して、現在のブランチとリモートリポジトリのブランチの状態を確認します。もしリモートリポジトリのHEADが現在のブランチに存在しない場合は、作業を中止します。

```bash
if ! git ls-remote --exit-code origin HEAD &>/dev/null; then
  echo "現在のブランチはリモートリポジトリに存在しないため、作業を中止します。"
  exit 1
else
  echo "現在のブランチは既にリモートリポジトリに存在するため、作業を続行します。"
fi
```

# 直前コミットの内容確認

以下のコマンドを使用して、現在のブランチにおける直前のコミットの内容を確認します。

```bash
git show HEAD
```

# 手本PRの内容確認

以下のコマンドを使用して、手本PRの内容を確認します。`ARGUMENT`にはPRの番号を入力します。

```bash
gh pr view $ARGUMENT
```

もし`ARGUMENT`が空の場合は、このステップはスキップしてください。

# 新規PRの作成

直前コミット及び手本PRの内容を元に、以下のコマンドを使用して新規PRを作成します。

```bash
# 変数の設定
PR_BASE_BRANCH="main"
PR_TEMPLATE=".github/PULL_REQUEST_TEMPLATE.md"
PR_TITLE="<直前コミット/手本PRを参考にPRタイトルを作成してください>"
PR_BODY="<直前コミット/手本PRを参考にPR内容を作成してください>"

# PR作成
if [ -f "$PR_TEMPLATE" ]; then
  gh pr create --draft --assignee @me --base "$PR_BASE_BRANCH" --template "$PR_TEMPLATE" --title "$PR_TITLE" --body "$PR_BODY"
else
  gh pr create --draft --assignee @me --base "$PR_BASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY"
fi
```

## 新規PRのブラウザ確認

以下のコマンドを使用して、作成した新規PRをブラウザで開きます。

```bash
gh pr view --web
```
