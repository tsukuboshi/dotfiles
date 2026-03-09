---
allowed-tools: Bash(git:*)
description: "Review branch diff without gh CLI (Compare Default: current branch, Base Default: main)"
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順でブランチの差分をレビューしてください。

1. 引数の解決
2. ブランチのフェッチ
3. コミットログの取得
4. ブランチ変更概要の取得
5. ブランチ差分の取得
6. 差分内容のレビュー

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。未指定の場合はデフォルト値を使用します。

- 第一引数: Compare Branch名（未指定の場合は現在のブランチ名を使用）
- 第二引数: Base Branch名（未指定の場合は`main`を使用）

以降のステップで使用する環境変数を設定します。

```bash
BASE_BRANCH="origin/${第二引数:-main}"
if [[ -n "${第一引数}" ]]; then
  COMPARE_BRANCH="origin/${第一引数}"
else
  COMPARE_BRANCH="$(git branch --show-current)"
fi
```

# ブランチのフェッチ

`COMPARE_BRANCH`がリモートブランチ（`origin/`始まり）の場合はBase BranchとCompare Branchの両方を、ローカルブランチの場合はBase Branchのみをリモートからフェッチします。

```bash
if [[ "${COMPARE_BRANCH}" == origin/* ]]; then
  git fetch origin "${BASE_BRANCH}" "${COMPARE_BRANCH}"
else
  git fetch origin "${BASE_BRANCH}"
fi
```

フェッチに失敗した場合は、リモートにブランチが存在しない可能性があるため、ユーザーにブランチ名の確認を求めてください。

# コミットログの取得

以下のコマンドを使用して、コミット履歴を取得します。

```bash
git log --oneline ${BASE_BRANCH}...${COMPARE_BRANCH}
```

# ブランチ変更概要の取得

以下のコマンドを使用して、Base BranchとCompare Branch間の変更概要を取得します。

```bash
git diff --stat ${BASE_BRANCH}...${COMPARE_BRANCH}
```

# ブランチ差分の取得

以下のコマンドを使用して、詳細な差分を取得します。

```bash
git diff ${BASE_BRANCH}...${COMPARE_BRANCH}
```

# 差分内容のレビュー

取得した差分についてレビューを実施し、必要に応じて修正計画を立ててください。
