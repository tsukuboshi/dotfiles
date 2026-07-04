---
name: genai-doctor
description: "Tune the entire ~/dotfiles/genai configuration (settings.json, rules, skills, hooks, permissions) by cross-checking the latest official Claude Code documentation and analyzing recent conversation history for recurring request patterns. Use when the user wants to audit, check, or tune their Claude Code setup as a whole — e.g. 'genai をチューニング', '設定を最新化', '設定の棚卸し', 'settings.json をチェック', '会話履歴から改善点を探して', 'スキルを提案して'. For a single targeted settings change (e.g. adding one permission or env var), use update-config instead."
argument-hint: "[days]"
---

# 引数の解決

`ARGUMENT`は以下の引数を受け取ります。

```
# days: 会話履歴分析の対象期間（日数）
# 省略時: 30 日をデフォルトとする
```

`~/dotfiles/genai` 配下の Claude Code 設定一式を、最新の公式ドキュメントとの突き合わせ、および会話履歴の分析に基づいて診断し、チューニング提案を行ってください。

# Step 1: 現状把握

`~/dotfiles/genai` 配下の構成を読み込んでください。

1. `settings.json` と、そこから参照されている関連ファイル
   - `statusLine.command` が指すスクリプト（例: `scripts/statusline.sh`）
   - `hooks` の各エントリが指すスクリプト（例: `hooks/*.sh`）
2. `rules/*.md`（全ルールファイル）
3. `skills/*/SKILL.md`（frontmatter の name と description のみで十分）
4. `apm/apm.yml`（外部スキルの導入状況）
5. `AGENTS.md`（エージェント共通指示）

# Step 2: 公式ドキュメントの取得

Step 2 と Step 3 は互いに独立しているため、それぞれのエージェントを**同一ターンで並列起動**してください（逐次実行すると数分余計にかかる）。

`claude-code-guide` エージェントに以下を問い合わせ、最新仕様を取得してください。

- settings.json で有効な全設定キーとその型・デフォルト値
- `env` で有効な環境変数の一覧（廃止されたものがあればその情報も）
- `permissions` / `hooks` / `statusLine` の最新仕様
- 最近追加された推奨設定項目

エージェントが利用できない場合のフォールバックとして、WebFetch で以下の公式ドキュメントを直接参照してください。

- <https://code.claude.com/docs/en/settings>
- <https://code.claude.com/docs/en/hooks>（hooks を使用している場合）
- <https://code.claude.com/docs/en/statusline>（statusLine を使用している場合）

# Step 3: 会話履歴の分析

`~/.claude/projects/*/` 配下の JSONL トランスクリプトから、指定期間内のユーザー依頼パターンを抽出してください。

分析手順:

1. `find ~/.claude/projects -name "*.jsonl" -mtime -<days>` で対象ファイルを特定する
2. プロジェクト群を 2〜3 系統に分け、Explore サブエージェントを並列起動して分析を委譲する
3. 各エージェントには抽出方法を指示する
   - ユーザー発話: `jq -r 'select(.type=="user") | .message.content | if type=="string" then . else (map(select(.type=="text") | .text) | join(" ")) end'`
   - `tool_use_id` を含む行（tool_result）はスキップ
   - JSONL は 1 ファイルで数 MB になり得るため、全文は読まず 1 ファイルあたり冒頭のユーザーメッセージ数件をサンプリングする（セッションの目的把握には十分で、サブエージェントのコンテキスト溢れを防ぐ）
   - スキル使用頻度: ユーザー発話中の `<command-name>` タグに加えて、自動発火分を `jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Skill") | .input.skill'` で集計する
   - 実行コマンド頻度（permissions 診断用）: `jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Bash") | .input.command' | awk '{print $1}' | sort | uniq -c | sort -rn` で Bash コマンドの先頭語を集計する
4. 以下を報告させる
   - 繰り返し登場する依頼パターン（3 回以上）
   - 毎回手動で指示している定型作業・方針
   - よく使われている / 全く使われていないスキル
   - 頻出する Bash コマンドの上位（permissions の allow 候補判断に使う）

# Step 4: 診断レポート

Step 1〜3 の結果を突き合わせ、以下の観点で表形式のレポートを提示してください。

| 観点 | 診断内容 |
|---|---|
| settings | 廃止・無効なキー / デフォルト値と同一の冗長なキー / 未導入の推奨設定 |
| permissions | Step 3 で集計した頻出 Bash コマンドのうち allow 未登録のもの（allow 追加候補）/ 履歴に登場しない allow エントリ |
| rules | 毎回口頭で指示している方針（rules/*.md への追記候補）/ 履歴と矛盾する既存ルール |
| skills | 繰り返し依頼パターンから導く新スキル候補（自作の前に既存の apm 配布スキルで代替できないか確認する）/ 期間内に一度も発火していないスキル |

診断時の注意:

- 仕様の確認が取れないキーは「無効」と断定せず「要確認」として、参照した出典（ドキュメント URL）とともに提示する
- 有効に機能している設定を誤って問題ありと報告しない（偽陽性の回避を優先する）
- 各指摘には根拠（公式ドキュメントの記述、または履歴上の頻度）を添える
- サブエージェントの回答を鵜呑みにしない。設定変更の根拠にする項目は、出典 URL の記述を WebFetch で裏取りしてから提案する（エージェントが有効なキーに誤った説明を付けるケースが実際にある）
- 新スキルを提案する前に、同等の機能を持つ公開スキルが既に存在しないか確認する。marketplace 登録済みなら `apm search <query>@<marketplace>` で、未登録なら WebSearch で GitHub 上のスキル集（`apm/apm.yml` で導入済みの mattpocock/skills など）を検索する。見つかった場合は自作ではなく apm での導入を提案する

# Step 5: 提案と適用

1. 診断結果に基づく変更案を、変更理由付きで優先度順に提示する
2. ユーザーが選択した項目のみ適用する
3. キーの削除・ルールの変更など既存動作に影響する変更は、項目ごとに個別確認を挟む
4. 新スキルの作成など規模の大きい提案は、このスキル内では実装せず plan mode での別途着手を提案する。既存の公開スキルで代替する場合は `apm/apm.yml` の dependencies に追記して `apm install -g`（または `genai/setup.sh -i`）の実行を提案する。permissions の allow を大量追加する場合は、組み込みの `fewer-permission-prompts` スキルへの委譲も選択肢として案内する
5. 適用後、変更内容のサマリ（変更前 → 変更後）を報告し、`genai/setup.sh` の再実行が必要な場合はその旨を案内する
