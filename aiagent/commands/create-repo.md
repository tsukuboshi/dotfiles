---
allowed-tools: Bash(gh:*), Bash(git:*)
description: "Create a new GitHub repository"
---

以下の手順で新しいGitHubリポジトリを作成してください。

1. Gitリポジトリの初期化
2. 新規リポジトリの作成及びリモートリポジトリの追加
3. メインブランチの設定
4. ファイルをステージングエリアに追加
5. 初回コミットの作成
6. リモートリポジトリへのプッシュ
7. 新規リポジトリのブラウザ確認

# Gitリポジトリの初期化

以下のコマンドを使用して、現在のディレクトリをGitリポジトリとして初期化します。

```bash
git init
```

# 新規リポジトリの作成及びリモートリポジトリの追加

現在のディレクトリ名を元に、以下のコマンドを使用して新規リポジトリを作成し、リモートリポジトリとして追加します。

```bash
pwd | xargs basename | xargs gh repo create --private | sed 's/$/.git/' | xargs git remote add origin
```

# メインブランチの設定

以下のコマンドを使用して、現在のブランチをmainブランチに設定します。

```bash
git branch -M main
```

# ファイルをステージングエリアに追加

以下のコマンドを使用して、全てのファイルをステージングエリアに追加します。

```bash
git add -A
```

# 初回コミットの作成

以下のコマンドを使用して、初回コミットを作成します。

```bash
git commit -m "first commit"
```

# リモートリポジトリへのプッシュ

以下のコマンドを使用して、ローカルのコミットをリモートリポジトリにプッシュします。

```bash
git push -u origin main
```

## 新規リポジトリのブラウザ確認

以下のコマンドを使用して、作成した新規リポジトリをブラウザで開きます。

```bash
gh repo view --web
```
