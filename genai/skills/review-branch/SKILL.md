---
description: "Review branch diff without gh CLI (Compare Default: current branch, Base Default: main)"
argument-hint: "[Compare Branch] [Base Branch]"
---

以下の手順でブランチの差分をレビューしてください。

# 引数の解決

`ARGUMENT`はスペース区切りで2つの引数を受け取ります。

```bash
# 第一引数: Compare Branch名（未指定時は現在のブランチ）
# 第二引数: Base Branch名（未指定時はmain）
BASE_BRANCH="origin/${第二引数:-main}"
if [[ -n "${第一引数}" ]]; then
  COMPARE_BRANCH="origin/${第一引数}"
else
  COMPARE_BRANCH="$(git branch --show-current)"
fi
```

# ブランチのフェッチ

`COMPARE_BRANCH`がリモートブランチ（`origin/`始まり）の場合は両方を、ローカルブランチの場合はBase Branchのみフェッチします。失敗時はユーザーにブランチ名の確認を求めてください。

```bash
if [[ "${COMPARE_BRANCH}" == origin/* ]]; then
  git fetch origin "${BASE_BRANCH}" "${COMPARE_BRANCH}"
else
  git fetch origin "${BASE_BRANCH}"
fi
```

# コミットログの取得

```bash
git log --oneline ${BASE_BRANCH}...${COMPARE_BRANCH}
```

# ブランチ変更概要の取得

```bash
git diff --stat ${BASE_BRANCH}...${COMPARE_BRANCH}
```

# ブランチ差分の取得

```bash
git diff ${BASE_BRANCH}...${COMPARE_BRANCH}
```

# 差分内容のレビュー

取得した差分についてレビューを実施し、必要に応じて修正計画を立ててください。
