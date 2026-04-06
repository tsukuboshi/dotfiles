---
name: "clean-branches"
description: "Delete local branches that have been merged into the base branch and prune stale remote tracking references. Use this skill when the user wants to clean up old branches, remove merged branches, tidy up their local git state, or prune remote references — even casually like 'clean up branches' or 'delete merged branches'."
argument-hint: "[Base Branch]"
---

以下の手順でマージ済みのローカルブランチを削除し、不要なリモート追跡参照を掃除してください。

# 引数の解決

`ARGUMENT`は1つの引数を受け取ります。

- 第一引数: Base Branch名（未指定時は`main`）

以降の手順では`${BASE_BRANCH}`を解決した値に置き換えて実行してください。

# リモート情報の最新化

```bash
git fetch origin --prune
```

`--prune`を付けることで、fetchと同時にリモートで削除済みのブランチの追跡参照（`origin/feature/xxx`など）も掃除される。

# マージ済みローカルブランチの一覧取得

```bash
git branch --merged origin/BASE_BRANCH
```

出力から以下のブランチを除外してください：

- 現在チェックアウト中のブランチ（`*`が付いているもの）
- ブランチ名に`/`を含まないブランチ（`main`, `develop`, `staging`, `master`等の長寿命ブランチを保護するため）

除外後に残ったブランチが削除対象です。

# 削除対象の確認

削除対象のブランチ一覧をユーザーに表示してください。

削除対象が0件の場合は、マージ済みブランチがない旨を伝えて処理を終了してください。

# ブランチの削除

削除対象のブランチをまとめて削除してください。

```bash
git branch -d ブランチ名1 ブランチ名2 ...
```

# 結果の表示

削除完了後、以下のコマンドで残っているローカルブランチ一覧を表示してください。

```bash
git branch
```
