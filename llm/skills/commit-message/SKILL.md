---
description: "Generate commit message from staged changes and repository history, then commit"
argument-hint: "[--switch | --no-switch (default)]"
---

以下の手順でコミットメッセージを生成し、`git commit`を実行してください。

# 引数の解決

`ARGUMENT`は以下の引数を受け取ります。

```bash
# --switch: ブランチの作成を行う
# --no-switch: ブランチの作成をスキップ（デフォルト）
```

# ステージング内容の確認

```bash
git diff --cached
```

ステージされた変更がない場合は、その旨をユーザーに伝えて処理を終了してください。

# ブランチの作成

`--switch` が指定されていない場合、このステップをスキップしてください。

既存のブランチ名を確認して命名規則を把握します。

```bash
git branch -a
```

変更内容と命名規則を元に適切なブランチ名を生成し、新規ブランチを作成して切り替えます。

```bash
git switch -c 生成したブランチ名
```

# コミット履歴のスタイル確認

```bash
git log --oneline -20
```

取得したコミット履歴から、以下の観点でスタイルを分析してください：

- 言語（日本語 / 英語 / その他）
- プレフィックスの有無（例: `feat:`, `fix:` などの Conventional Commits 形式）
- 文体（動詞始まり / 名詞始まり / 文章形式 など）
- メッセージの長さの傾向（短文 / 詳細）

# コミットメッセージの生成

ステージされた差分と分析したスタイルを元に、コミットメッセージを生成してください。

- リポジトリの既存のコミットメッセージスタイルに合わせること
- 変更内容を正確に反映すること

# コミットの実行

```bash
git commit -m "生成したコミットメッセージ"
```

# ブランチ名とコミットメッセージの確認

コミット実行後、現在のブランチ名と直近のコミットメッセージをユーザーに表示してください。

```bash
git branch --show-current
git log --oneline -1
```
