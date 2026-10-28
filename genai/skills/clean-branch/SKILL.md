---
name: "clean-branch"
description: "Delete local branches that have been merged or squash-merged into the base branch and prune stale remote tracking references. Use this skill when the user wants to clean up old branches, remove merged branches, tidy up their local git state, or prune remote references — even casually like 'clean up branches' or 'delete merged branches'."
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

# ブランチの分類

以下のコマンドで、ローカルブランチを1つずつ分類してください。

```bash
base=origin/BASE_BRANCH
git for-each-ref --format='%(refname:short)%09%(worktreepath)' refs/heads/ | while IFS=$'\t' read -r b wt; do
	case "$b" in */*) ;; *) continue ;; esac
	if [ -n "$wt" ]; then printf 'checked-out\t%s\t%s\n' "$b" "$wt"; continue; fi
	if git merge-base --is-ancestor "$b" "$base"; then printf 'merged\t%s\n' "$b"; continue; fi
	mb=$(git merge-base "$base" "$b") || { printf 'unrelated\t%s\n' "$b"; continue; }
	tmp=$(git commit-tree "$b^{tree}" -p "$mb" -m squash-check)
	case "$(git cherry "$base" "$tmp")" in -*) printf 'squashed\t%s\n' "$b" ;; *) printf 'unmerged\t%s\n' "$b" ;; esac
done
```

各行の1列目が分類です。

| 分類 | 意味 | 扱い |
| --- | --- | --- |
| `merged` | ブランチの先端が base に含まれる（マージコミットか fast-forward で取り込まれた） | `git branch -d`で削除する |
| `squashed` | ブランチの変更全体と同じ差分のコミットが base にある（squash マージされた） | 承認を得て`git branch -D`で削除する |
| `unmerged` | ブランチの変更が base に入っていない | 残す |
| `checked-out` | どこかの worktree（今の作業ツリーを含む）で開いている。3列目がその場所 | 残す（`git branch -d`/`-D`が拒否する） |
| `unrelated` | base と共通の祖先が無い | 残す |

`squashed`の判定は、ブランチの変更全体を1つのコミットにまとめ、`git cherry`で base の各コミットと差分（patch-id）を照合して行う。
リモートのブランチが消えたかどうかでは判定しない。PR を閉じただけでもリモートのブランチは消えるため。
squash マージの後に手元でコミットを足したブランチや、マージ時にコンフリクトを解消して差分が変わったブランチは、`unmerged`になって残る。消しすぎない側に倒すための判定である。

ブランチ名に`/`を含まないブランチ（`main`, `develop`, `staging`, `master`等の長寿命ブランチ）は、保護のため最初から対象外にしている。

# 削除対象の確認

「マージ済み（`merged`）」「squash マージ済み（`squashed`）」「残すもの（分類と理由）」の3つの一覧をユーザーに表示してください。

「マージ済み」と「squash マージ済み」がどちらも0件の場合は、マージ済みブランチがない旨を伝えて、最後の「結果の表示」へ進んでください。

「squash マージ済み」は Git から見ると未マージのため、`git branch -D`での削除になります。
この一覧に対して、`AskUserQuestion`で削除してよいかをユーザーに確認し、承認を得てから削除してください。ユーザーが除外を指示したブランチは外します。

# ブランチの削除

「マージ済み」をまとめて削除してください。

```bash
git branch -d ブランチ名1 ブランチ名2 ...
```

承認を得た「squash マージ済み」を、**1つのコマンドにブランチ名を具体的に並べて**削除してください。
変数やワイルドカードで組み立てないこと（承認ダイアログに、実際に消すブランチ名がすべて表示されるようにするため）。
0件なら実行しない。

```bash
git branch -D ブランチ名1 ブランチ名2 ...
```

一部のブランチだけ失敗しても他は削除されるため、出力の`Deleted branch …`とエラーをブランチごとに読み分けてください。

# 結果の表示

削除したブランチ、残したブランチ（理由付き）を伝えたうえで、以下のコマンドで残っているローカルブランチ一覧を表示してください。

```bash
git branch -vv
```
