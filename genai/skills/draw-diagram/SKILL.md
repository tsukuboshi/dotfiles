---
name: "draw-diagram"
description: "Draw a diagram as a .drawio file and export one editable .drawio.png per page that opens in the VS Code Draw.io extension, choosing the diagram type from the question the reader needs answered. Use this skill whenever you create or edit a .drawio file or are asked to draw an infrastructure / AWS architecture diagram (e.g. '構成図を描いて', 'AWS 構成図'), a logical architecture or system context diagram (e.g. '論理構成図', 'システムの全体像'), a business flow or swimlane (e.g. '業務フロー', '運用フローを図にして'), or a current-vs-future comparison (e.g. 'As-Is / To-Be', '現状と移行後'); also when reflecting edits made in a .drawio.png back into the .drawio, or when a .drawio.png opens blank in VS Code."
argument-hint: "[.drawio のパス または 描きたい図の説明] [ページごとの接尾辞（例: dev,ops）]"
---

# draw.io の図を描いて `.drawio.png` に書き出す

図は `.drawio` を正として編集し、ページごとの `.drawio.png` を派生物として書き出します。
`.drawio.png` は画像として資料に貼れるうえ、図データを埋め込むので draw.io や VS Code の拡張でそのまま開いて編集できます。

# 入力

| 入力 | 内容 | 未指定時 |
| --- | --- | --- |
| `.drawio` のパス、または描きたい図の説明 | 編集・書き出しする図 | このセッションで編集した `.drawio`。なければ AskUserQuestion で確認する |
| ページごとの接尾辞 | 出力名 `<stem>-<接尾辞>.drawio.png` の接尾辞を、ページ順にカンマ区切りで（1 ページの図では不要） | 既存の `.drawio.png` があればその接尾辞に揃え、なければページ名から短い英字で付ける（例: 「開発環境」「運用環境」→ `dev,ops`） |

# 0. 図の種類を決める

図の種類は、**読み手に答えたい問い**で決めます。種類を取り違えると、正しく描いても伝わらない図になります（例: 部品のつながりを示したいのに、矢印にデータ名を書く DFD の流儀で描く）。

| 読み手の問い | 種類 | 記法 |
| --- | --- | --- |
| どこで何が動き、どの経路で通信するか（AWS リソース、VPC、オンプレ接続） | インフラ構成図 | [`references/infrastructure.md`](references/infrastructure.md) |
| どの部品がどの手段でつながり、誰が持ち、どこまでが範囲か | 論理構成図（C4 のコンテナ図 / システムコンテキスト図） | [`references/logical.md`](references/logical.md) |
| 誰がどの手順を担い、どこで判断・承認するか | 業務フロー図（スイムレーン） | [`references/business-flow.md`](references/business-flow.md) |
| 何が変わるか | As-Is / To-Be（上のいずれかを現状と目標で並べる） | [`references/as-is-to-be.md`](references/as-is-to-be.md) と、並べる種類の記法 |

既存の `.drawio` を直すだけのときも、図の種類を判定して該当する記法を Read します。
判定が付かないときは、候補の種類と、それぞれで答えられる問いを示して AskUserQuestion で確認します。

**完成条件**: 種類が 1 つに決まり（As-Is / To-Be はもう 1 つの種類と組で）、その記法ファイルを Read している。

# 1. `.drawio` を編集する

図の変更は `.drawio`（XML）に対して行い、記法ファイルの決まりに従って描きます。
XML なので git の差分が読め、Edit でセル単位に直せます。
PNG を直接編集すると、次の書き出しで `.drawio` の内容に上書きされて変更が消えます。

## ユーザーが `.drawio.png` 側を編集したとき

「PNG の方が正しい」と言われたら、PNG に埋め込まれた図データを `.drawio` とセル単位で比べます。

```bash
python3 -I ~/.claude/skills/draw-diagram/scripts/diff_png_drawio.py <file.drawio.png> <file.drawio>
```

PNG は VS Code で開いたままの古いタブから保存されていることがあり、ユーザーが触っていない箇所まで古い版に戻っている場合があります。
`.drawio` へ取り込むのは、ユーザーが指した変更（とその変更に付随するセル）だけです。
それ以外の差分は古い版の名残とみなして取り込まず、手順 4 で一覧を報告し、意図した変更かを確認します。

# 2. 書き出す

インフラ構成図では、書き出す前に `references/infrastructure.md` の「AWS 構成を検証する」を済ませます。
手順 3 から戻って書き出し直すときは、判定表と比べて変わった主張だけを検証します。

```bash
python3 -I ~/.claude/skills/draw-diagram/scripts/export_drawio_png.py <file.drawio> --names <接尾辞,...>
```

- 複数ページの図では、入力の接尾辞を `--names` に渡す
- 1 ページの図では `--names` を省き、`<stem>.drawio.png` に書き出す
- 解像度は 2 倍、余白は 20px。等倍や余白なしだと、拡大したときに文字がぼやけ、端が切れて見える

スクリプトは drawio CLI で PNG を書き出した後、図データを `tEXt` チャンクの `mxfile` キーへ埋め込み直します。
CLI の `-e` は `zTXt` の `mxGraphModel` キーへ書き込み、VS Code の Draw.io 拡張はこれを読めず白紙の「ページ1」を開くため、`-e` の代わりにこの埋め込みを使います。

# 3. 見た目を確認する

書き出した PNG を 1 枚ずつ Read で目視し、次をすべて満たせば完了です。

- 各ページの内容が 1 枚ずつ、取り違えなく出ている（drawio CLI のページ番号は 1 始まり）
- 矢印の端が浮いていない・ラベルが重なっていない・枠から要素がはみ出していない
- `.drawio` で削除した要素が残っていない
- 記法ファイルの「確認」の項目を満たしている

崩れていれば手順 1 に戻って `.drawio` を直し、書き出し直します。

# 4. 報告

次を報告します。

- 図の種類と、その種類を選んだ理由（読み手の問い）
- 書き出した `.drawio.png` のパス一覧
- インフラ構成図で AWS 構成を検証した場合は、「条件付き」「未確認」の主張と、その条件・確認方法・出典。「不可」で図を直した場合は、何をどう直したか
- PNG 側の編集を取り込んだ場合は、取り込まなかった差分の一覧
- VS Code で `.drawio.png` を開いている場合は、タブを保存せずに閉じて開き直すこと。開いたままのタブは書き出し後も古い内容を表示し、そのまま保存すると書き出した PNG が古い版で上書きされる
