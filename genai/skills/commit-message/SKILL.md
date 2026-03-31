---
name: "commit-message"
description: "Generate commit message from staged changes and repository history, then commit. Use this skill whenever the user wants to commit, save changes, or asks to generate a commit message — even casually like 'commit this' or 'save my changes'."
argument-hint: "[file ...]"
---

以下の手順でコミットメッセージを生成し、`git commit`を実行してください。

# 引数の解決

`ARGUMENT`は以下の引数を受け取ります。

```bash
# file ...: git add するファイルパス（複数指定可、省略可）
# スペース区切りまたはクォートで囲まれたパスの連結（例: 'path1''path2'）の両方を受け付ける
```

# ファイルのステージング

引数にファイルパスが指定されている場合、それらを `git add` でステージングしてください。

```bash
git add ファイルパス1 ファイルパス2 ...
```

ファイルパスが指定されていない場合、このステップをスキップしてください。

# ステージング内容の確認とコミット履歴のスタイル確認

以下の2つのコマンドは依存関係がないため、並列で実行してください。

```bash
git diff --cached
```

```bash
git log --oneline -20
```

ステージされた変更がない場合は、その旨をユーザーに伝えて処理を終了してください。

取得したコミット履歴から、以下の観点のみ分析してください：

- 言語（日本語 / 英語 / その他）
- 文体（動詞始まり / 名詞始まり / 文章形式 など）
- メッセージの長さの傾向（短文 / 詳細）

# コミットメッセージの生成

ステージされた差分を元に、Conventional Commits 形式でコミットメッセージを生成してください。

## フォーマット

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## type の選択基準

| type | 用途 |
|------|------|
| `feat` | 新機能の追加 |
| `fix` | バグ修正 |
| `docs` | ドキュメントのみの変更 |
| `style` | コードの意味に影響しない変更（空白、フォーマット、セミコロン等） |
| `refactor` | バグ修正でも機能追加でもないコード変更 |
| `perf` | パフォーマンス改善 |
| `test` | テストの追加・修正 |
| `build` | ビルドシステムや外部依存に関する変更 |
| `ci` | CI 設定ファイルやスクリプトの変更 |
| `chore` | 上記のいずれにも当てはまらない場合の最終手段 |

## ルール

- description の言語・文体はコミット履歴の分析結果に合わせること
- 変更内容を正確に反映すること
- 破壊的変更がある場合は type/scope の後に `!` を付与し、footer に `BREAKING CHANGE: <説明>` を記述すること
- scope は明確なモジュール構造を持つリポジトリでのみ使用し、基本的には省略すること

# コミットの実行

body や footer を含む複数行メッセージの場合、HEREDOCを使用してください。

```bash
git commit -m "$(cat <<'EOF'
<type>[optional scope]: <description>

<body>

<footer>
EOF
)"
```

1行メッセージの場合はそのまま `-m` で指定してください。

```bash
git commit -m "<type>[optional scope]: <description>"
```

# ブランチ名とコミットメッセージの確認

コミット実行後、以下の2つのコマンドを並列で実行し、現在のブランチ名と直近のコミットメッセージをユーザーに表示してください。

```bash
git branch --show-current
```

```bash
git log --oneline -1
```
