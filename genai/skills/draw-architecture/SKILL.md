---
name: "export-drawio"
description: "Export a draw.io diagram (.drawio) to one editable .drawio.png per page that opens in the VS Code Draw.io extension, verifying AWS architecture diagrams against AWS docs first. Use this skill whenever you create or edit a .drawio file, draw an architecture or system diagram (e.g. '構成図を描いて', '構成図を直して', 'drawio を PNG にして'), or a .drawio.png opens blank in VS Code."
argument-hint: "[.drawio のパス] [ページごとの接尾辞（例: dev,ops）]"
---

# draw.io の図を `.drawio.png` に書き出す

draw.io の図は `.drawio` を正として編集し、ページごとの `.drawio.png` を派生物として書き出します。
`.drawio.png` は画像として資料に貼れるうえ、図データを埋め込むので draw.io や VS Code の拡張でそのまま開いて編集できます。

# 入力

| 入力 | 内容 | 未指定時 |
| --- | --- | --- |
| `.drawio` のパス | 書き出す図 | このセッションで編集した `.drawio`。なければ AskUserQuestion で確認する |
| ページごとの接尾辞 | 出力名 `<stem>-<接尾辞>.drawio.png` の接尾辞を、ページ順にカンマ区切りで（1 ページの図では不要） | 既存の `.drawio.png` があればその接尾辞に揃え、なければページ名から短い英字で付ける（例: 「開発環境」「運用環境」→ `dev,ops`） |

# 1. `.drawio` を編集する

図の変更は `.drawio`（XML）に対して行います。
XML なので git の差分が読め、Edit でセル単位に直せます。
PNG を直接編集すると、次の書き出しで `.drawio` の内容に上書きされて変更が消えます。

# 2. AWS 構成を検証する

AWS のサービスを含む図では、書き出す前に、図が描いている内容が AWS の公式ドキュメントと合っているかを AWS Knowledge MCP で確かめます。
記憶にある仕様は古くなっていることがあり、存在しない連携や、そのリージョンで使えないサービスを描いたまま資料に載ると、お客様の前で訂正することになるためです。

検証の対象は、図から読み取れる主張のすべてです。

- 矢印で描いた連携（例: ALB → VPC Lattice のターゲット、CodePipeline → 自前の Git サーバー）が、その方向・その方式で実現できるか
- ラベルに書いた機能や設定（例: 「CodeDeploy 不要」「VPC オリジン」「jp. 推論プロファイル」）が実在し、書いたとおりに動くか
- リージョングループに置いたサービスが、そのリージョンで提供されているか
- VPC の中に置いたサービスが、VPC エンドポイントなど閉域の経路で届くか

ツールは次のように使い分けます。

| 確かめること | ツール |
| --- | --- |
| 連携・機能・設定の可否 | `mcp__aws-knowledge__aws___search_documentation` で探し、返ってきた本文の抜粋で判断する。抜粋で足りないときだけ `aws___read_documentation` で全文を読む |
| リージョンでの提供状況 | `mcp__aws-knowledge__aws___get_regional_availability` |

主張ごとに「可 / 条件付き / 不可 / 未確認」と出典 URL を控え、全件に判定が付いたら完了です。
「不可」は手順 1 に戻って `.drawio` を直します。
「条件付き」と「未確認」は図のままにして、手順 5 で条件や確認方法を添えて報告します。
図と同じディレクトリに構成の補足資料（`*-notes.md` など）があれば、判定と出典をそちらの実現可能性の一覧にも反映します。

# 3. 書き出す

```bash
python3 -I ~/.claude/skills/draw-architecture/scripts/export_drawio_png.py <file.drawio> --names <接尾辞,...>
```

- 複数ページの図では、入力の接尾辞を `--names` に渡す
- 1 ページの図では `--names` を省き、`<stem>.drawio.png` に書き出す
- 解像度は 2 倍、余白は 20px。等倍や余白なしだと、拡大したときに文字がぼやけ、端が切れて見える

スクリプトは drawio CLI で PNG を書き出した後、図データを `tEXt` チャンクの `mxfile` キーへ埋め込み直します。
CLI の `-e` は `zTXt` の `mxGraphModel` キーへ書き込み、VS Code の Draw.io 拡張はこれを読めず白紙の「ページ1」を開くため、`-e` の代わりにこの埋め込みを使います。

# 4. 見た目を確認する

書き出した PNG を 1 枚ずつ Read で目視し、次をすべて満たせば完了です。

- 各ページの内容が 1 枚ずつ、取り違えなく出ている（drawio CLI のページ番号は 1 始まり）
- 矢印の端が浮いていない・ラベルが重なっていない・枠から要素がはみ出していない
- `.drawio` で削除した要素が残っていない

崩れていれば手順 1 に戻って `.drawio` を直し、書き出し直します。

# 5. 報告

次を報告します。

- 書き出した `.drawio.png` のパス一覧
- AWS 構成を検証した場合は、「条件付き」「未確認」の主張と、その条件・確認方法・出典。「不可」で図を直した場合は、何をどう直したか
