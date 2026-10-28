---
name: "sync-docs"
description: "Find the documents a change makes stale and update them (Diff Default: uncommitted changes, or the whole branch when it has commits ahead of its base). Use this skill before committing or opening a PR, or when the user asks whether the docs still match the code — e.g. 'ドキュメントの更新漏れを確認して', 'docs を同期して', 'sync the docs'. Narrows candidates with `sources` frontmatter when the project has it, and with Grep otherwise."
argument-hint: "[Base Branch]"
---

今の変更で古くなった（stale な）ドキュメントを探し、更新してください。
対象は今の変更に関係するドキュメントだけです。

# 差分の範囲を決める

```bash
git status --short; git log --oneline @{upstream}.. 2>/dev/null | head
```

- コミット前: 未コミットの変更（ステージ済み・未ステージの両方）を対象にする
- ブランチにベースより進んだコミットがある（PR 前）: `git diff BASE_BRANCH...HEAD` と未コミットの変更を合わせて対象にする。ベースブランチは引数で受け取り、未指定なら `open-pr` スキルと同じく reflog から求める

変更・追加・削除・リネームしたファイルの一覧と、差分の中身を把握したら次へ進む。

# 候補のドキュメントを集める

次の 3 つの経路で候補を集め、どの経路で挙がったかを候補ごとに控える。

1. **フロントマター**: `Grep` で `^sources:` を持つ Markdown を探す。見つかったら、変更したファイルが `sources` の glob に当てはまるドキュメントを候補にする。glob は `Glob` で展開して照合する
2. **文言**: 差分で消えた・変わった識別子（関数名・コマンド・オプション・設定キー・パス）と表示文言を、`README.md`・`docs/`・`CONTEXT.md`・`CLAUDE.md`・`AGENTS.md`・`.claude/` から `Grep` する。古い文言が残っているドキュメントを候補にする
3. **決まった連動先**:
   - CLI の引数・設定キー・ファイルの配置・セットアップ手順を変えた: `README.md`
   - 新しい用語・呼び方を入れた: `CONTEXT.md`（無ければ用語集）
   - やり直しのコストが大きい技術判断をした: `docs/adr/`
   - skills・rules・hooks・agents を足した・消した・リネームした: それを一覧にしている README

# 候補ごとに読み比べる

候補の該当箇所と差分を読み比べ、挙動・手順・配置・用語の説明が古くなっていないかを判断する。
実装の手段だけが変わり、説明が変わらないなら更新不要。
すべての候補に「更新する」か「更新不要（理由）」の判定がついたら次へ進む。

ADR が候補に挙がったら、あわせてステータスの対応を確かめる。

- 新しい ADR が古い ADR を置き換える・補足すると書いているのに、古い ADR のステータスが反映していない
- ステータスの `→ADR-XXXX` が指す ADR が実在しない、または置き換え・補足の内容を持っていない

ADR の本文は書き換えない。直すのはステータスだけにする。

# フロントマターを直す

`sources` を使うプロジェクトで、ファイルの追加・削除・リネームがあったときだけ行う。

- 削除・リネームしたファイルの古いパスが、どこかの `sources` に残っていないか
- 追加したファイルを説明しているドキュメントがあれば、その `sources` に足したか
- 追加したドキュメントにフロントマターがあるか

# 更新する

機械的な修正はそのまま行う: 古いパス・名前の置き換え、リンク切れ、一覧の過不足、ADR のステータス。
説明をどう書き換えるかが設計判断になるもの（何を削り何を足すか、仕様をどう表現するか）は、`AskUserQuestion` で 1 つずつユーザーに確認してから直す。
プロジェクトに一覧やリンクの検査スクリプトがあれば、更新後に実行する。

# 結果を伝える

次の 2 つを伝える。PR を作るときは、この内容を PR 本文に使う。

- 更新したドキュメントと、何を直したか
- 見直したが更新不要としたドキュメント。読み比べた見出しと理由を 1 行ずつ添える
